Shader "Custom/HalftoneOverlay"
{
    Properties
    {
        [HDR] _DotColor ("Dot Color", Color) = (1, 1, 1, 1)
        _DotStrength ("Dot Opacity", Range(0, 1)) = 0.6
        _LightTintAmount ("Tint Dots By Light Colour", Range(0, 1)) = 0

        _DotSpacing ("Dot Spacing", Range(0.02, 1)) = 0.125
        _DotSize ("Dot Size", Range(0.05, 0.7)) = 0.35
        _EdgeSoftness ("Dot Edge Softness", Range(0, 0.3)) = 0.05

        _OffsetX ("Move Dots X", Range(0, 1)) = 0
        _OffsetY ("Move Dots Y", Range(0, 1)) = 0
        _OffsetZ ("Move Dots Z", Range(0, 1)) = 0

        _LightGain ("Light Gain", Range(0.5, 3)) = 1.5
        _LightBias ("Light Bias", Range(0, 1)) = 0
        _LightThreshold ("Light Needed For Dots", Range(0, 1)) = 0.1
        _LightSoftness ("Light Fade Width", Range(0.01, 1)) = 0.3
        _LightSizeInfluence ("Light Shrinks Dots", Range(0, 1)) = 0

        _TriSharp ("Triplanar Sharpness", Range(1, 16)) = 4
        [Toggle] _ObjectSpace ("Stick Dots To Object", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
        }

        Pass
        {
            Name "HalftoneOverlay"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            Offset -1, -1 // stops z-fighting with the surface underneath

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _FORWARD_PLUS
            #pragma shader_feature_local _OBJECTSPACE_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _DotColor;
                float _DotStrength;
                float _LightTintAmount;
                float _DotSpacing;
                float _DotSize;
                float _EdgeSoftness;
                float _OffsetX;
                float _OffsetY;
                float _OffsetZ;
                float _LightGain;
                float _LightBias;
                float _LightThreshold;
                float _LightSoftness;
                float _LightSizeInfluence;
                float _TriSharp;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionOS : TEXCOORD2;
                float3 normalOS : TEXCOORD3;
            };

            Varyings vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs pos = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs nrm = GetVertexNormalInputs(input.normalOS);

                output.positionCS = pos.positionCS;
                output.positionWS = pos.positionWS;
                output.normalWS = nrm.normalWS;
                output.positionOS = input.positionOS.xyz;
                output.normalOS = input.normalOS;
                return output;
            }

            // One dot per grid cell. Size and softness are in cell units,
            // so they don't depend on the lighting.
            float DotMask(float2 uv, float radius)
            {
                float dist = length(frac(uv) - 0.5);
                float soft = max(_EdgeSoftness, 0.001);
                return 1.0 - smoothstep(radius - soft, radius + soft, dist);
            }

            // Project the grid along all three axes and blend by surface normal
            float TriplanarDots(float3 pos, float3 normal, float radius)
            {
                float3 weights = pow(abs(normal), _TriSharp);
                weights /= dot(weights, 1.0) + 1e-5;

                float3 p = pos / max(_DotSpacing, 0.001) + float3(_OffsetX, _OffsetY, _OffsetZ);

                return DotMask(p.zy, radius) * weights.x
                     + DotMask(p.xz, radius) * weights.y
                     + DotMask(p.xy, radius) * weights.z;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float3 normalWS = normalize(input.normalWS);

                // Add up the light hitting this pixel
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(input.positionWS));
                float3 lightColor = mainLight.color
                    * saturate(dot(normalWS, mainLight.direction))
                    * mainLight.shadowAttenuation
                    * mainLight.distanceAttenuation;

                #if defined(_ADDITIONAL_LIGHTS) || USE_FORWARD_PLUS
                    InputData inputData = (InputData)0;
                    inputData.positionWS = input.positionWS;
                    inputData.normalWS = normalWS;
                    inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(input.positionCS);

                    uint lightCount = GetAdditionalLightsCount();
                    LIGHT_LOOP_BEGIN(lightCount)
                        Light light = GetAdditionalLight(lightIndex, input.positionWS);
                        lightColor += light.color
                            * saturate(dot(normalWS, light.direction))
                            * light.distanceAttenuation
                            * light.shadowAttenuation;
                    LIGHT_LOOP_END
                #endif

                float brightness = dot(lightColor, float3(0.299, 0.587, 0.114));
                float lit = saturate(brightness * _LightGain + _LightBias);

                // Dots get smaller in weaker light if Light Shrinks Dots is turned up
                float radius = _DotSize * lerp(1.0, lit, _LightSizeInfluence);

                #if defined(_OBJECTSPACE_ON)
                    float shape = TriplanarDots(input.positionOS, normalize(input.normalOS), radius);
                #else
                    float shape = TriplanarDots(input.positionWS, normalWS, radius);
                #endif

                // Lighting is per pixel, so dots on a light gradient end up half faded
                float fade = smoothstep(_LightThreshold, _LightThreshold + _LightSoftness, lit);

                float3 lightTint = normalize(lightColor + 1e-4) * 0.5 + 0.5;
                float3 color = _DotColor.rgb * lerp(1.0, lightTint, _LightTintAmount);

                return float4(color, shape * fade * _DotStrength);
            }
            ENDHLSL
        }
    }
}
