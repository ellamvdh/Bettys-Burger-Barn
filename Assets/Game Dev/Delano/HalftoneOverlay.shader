// Halftone dot overlay for URP.
// Put it in a second material slot; the original material renders as usual
// and this draws lit dots on top.
//
// Dot Space decides how the dot grid is laid out:
//   World Triplanar  - grid fixed in the world, projected from 3 axes (stretches on curves)
//   Object Triplanar - same, but the grid moves with the object
//   Screen (Object)  - perfect round dots, centred on the object and scaled with distance
//   Screen (Fixed)   - perfect round dots fixed to the screen (objects slide through them)
//   UV               - dots follow the mesh UVs (only even if the UVs are)
Shader "Custom/HalftoneOverlay"
{
    Properties
    {
        [KeywordEnum(WorldTriplanar, ObjectTriplanar, ScreenObject, ScreenFixed, UV)]
        _DotSpace ("Dot Space", Float) = 0

        [HDR] _DotColor ("Dot Color", Color) = (1, 1, 1, 1)
        _DotStrength ("Dot Opacity", Range(0, 1)) = 0.6
        _LightTintAmount ("Tint Dots By Light Colour", Range(0, 1)) = 0

        // World/Object/Screen (Object): world units. Screen (Fixed): fraction of screen height. UV: fraction of UV space.
        _DotSpacing ("Dot Spacing", Range(0.02, 1)) = 0.125
        _DotSize ("Dot Size", Range(0.05, 0.7)) = 0.35
        _EdgeSoftness ("Dot Edge Softness", Range(0, 0.3)) = 0.05

        _OffsetX ("Move Dots X", Range(0, 1)) = 0
        _OffsetY ("Move Dots Y", Range(0, 1)) = 0
        _OffsetZ ("Move Dots Z (triplanar only)", Range(0, 1)) = 0

        _LightGain ("Light Gain", Range(0.5, 3)) = 1.5
        _LightBias ("Light Bias", Range(0, 1)) = 0
        _LightThreshold ("Light Needed For Dots", Range(0, 1)) = 0.1
        _LightSoftness ("Light Fade Width", Range(0.01, 1)) = 0.3
        _LightSizeInfluence ("Light Shrinks Dots", Range(0, 1)) = 0

        _TriSharp ("Triplanar Sharpness", Range(1, 16)) = 4
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
            #pragma shader_feature_local _DOTSPACE_WORLDTRIPLANAR _DOTSPACE_OBJECTTRIPLANAR _DOTSPACE_SCREENOBJECT _DOTSPACE_SCREENFIXED _DOTSPACE_UV

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
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 positionOS : TEXCOORD2;
                float3 normalOS : TEXCOORD3;
                float2 uv : TEXCOORD4;
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
                output.uv = input.uv;
                return output;
            }

            // One dot per grid cell. Size and softness are in cell units,
            // so they don't depend on the lighting.
            float DotMask(float2 grid, float radius)
            {
                float dist = length(frac(grid) - 0.5);
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

            // Screen position with the screen height as 1 unit, x corrected for aspect ratio
            float2 ScreenCoords(float2 screenUV)
            {
                return float2(screenUV.x * _ScreenParams.x / _ScreenParams.y, screenUV.y);
            }

            // Grid centred on the object's origin. Scaled by the object's depth so
            // dots keep the same size relative to the object as the camera moves.
            float2 ScreenObjectGrid(float2 screenUV)
            {
                float3 originWS = UNITY_MATRIX_M._m03_m13_m23;
                float2 originUV = ComputeNormalizedDeviceCoordinatesWithZ(originWS, UNITY_MATRIX_VP).xy;

                float viewHeight;
                if (unity_OrthoParams.w > 0.5)
                {
                    viewHeight = 2.0 * unity_OrthoParams.y;
                }
                else
                {
                    float depth = -TransformWorldToView(originWS).z;
                    viewHeight = 2.0 * depth / unity_CameraProjection._m11;
                }

                float2 offsetFromOrigin = ScreenCoords(screenUV) - ScreenCoords(originUV);
                return offsetFromOrigin * viewHeight / max(_DotSpacing, 0.001) + float2(_OffsetX, _OffsetY);
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

                float2 screenUV = GetNormalizedScreenSpaceUV(input.positionCS);
                float shape;

                #if defined(_DOTSPACE_OBJECTTRIPLANAR)
                    shape = TriplanarDots(input.positionOS, normalize(input.normalOS), radius);
                #elif defined(_DOTSPACE_SCREENOBJECT)
                    shape = DotMask(ScreenObjectGrid(screenUV), radius);
                #elif defined(_DOTSPACE_SCREENFIXED)
                    shape = DotMask(ScreenCoords(screenUV) / max(_DotSpacing, 0.001) + float2(_OffsetX, _OffsetY), radius);
                #elif defined(_DOTSPACE_UV)
                    shape = DotMask(input.uv / max(_DotSpacing, 0.001) + float2(_OffsetX, _OffsetY), radius);
                #else
                    shape = TriplanarDots(input.positionWS, normalWS, radius);
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
