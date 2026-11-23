Shader "Custom/URP_CharacterOutline"
{
    // Two Render Objects features, same material: pass 0 (mask) first, then pass 1 (outline)
    Properties
    {
        [HDR] _ColorA ("Color A", Color) = (0.1, 1.2, 1.6, 1)
        [HDR] _ColorB ("Color B", Color) = (1.6, 0.1, 1.2, 1)
        [HDR] _ColorC ("Color C", Color) = (1.6, 1.0, 0.2, 1)

        _ScrollSpeed ("Scroll speed", Range(-3, 3)) = 0.1
        _Frequency ("Band frequency", Range(0.1, 12)) = 1
        _ScrollDir ("Scroll direction", Vector) = (0, 1, 0.3, 0)
        [IntRange] _DirCycles ("Hue cycles around silhouette", Range(0, 4)) = 1
        _Softness ("Band softness", Range(0.05, 1)) = 0.35
        [Enum(Follows Character, 0, World Space, 1)] _PatternSpace ("Color pattern anchored to", Float) = 0

        _DirBias ("Favor one side", Range(0, 1)) = 0
        _RimAngle ("Favored side angle", Range(0, 360)) = 135
        _BreakupAmount ("Breakup amount", Range(0, 1)) = 0
        _BreakupScale ("Breakup scale", Range(0.5, 30)) = 6
        _MinAlpha ("Min opacity", Range(0, 1)) = 0.1

        _OutlineWidthPx ("Width (px)", Range(0, 8)) = 1.0
        _ReferenceHeight ("Reference screen height", Float) = 1080
        _WorldScale ("Shrink with distance", Range(0, 1)) = 0
        _RefDistance ("Distance where width is exact", Float) = 5
        _DepthPush ("Push toward camera", Range(0, 1)) = 0.15

        [Enum(UnityEngine.Rendering.CullMode)] _Cull ("Shell culling", Float) = 0
        [IntRange] _StencilRef ("Stencil ref", Range(1, 255)) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Outline stencil test", Float) = 6
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="Geometry" }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            half4 _ColorA;
            half4 _ColorB;
            half4 _ColorC;
            float _ScrollSpeed;
            float _Frequency;
            float4 _ScrollDir;
            float _DirCycles;
            float _Softness;
            float _PatternSpace;
            float _DirBias;
            float _RimAngle;
            float _BreakupAmount;
            float _BreakupScale;
            float _MinAlpha;
            float _OutlineWidthPx;
            float _ReferenceHeight;
            float _WorldScale;
            float _RefDistance;
            float _DepthPush;
            float _Cull;
            float _StencilRef;
            float _StencilComp;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Name "Mask"
            Tags { "LightMode"="SRPDefaultUnlit" }

            Cull Back
            ZWrite Off
            ZTest Always
            ColorMask 0

            Stencil
            {
                Ref [_StencilRef]
                Comp Always
                Pass Replace
            }

            HLSLPROGRAM
            #pragma vertex vertMask
            #pragma fragment fragMask

            float4 vertMask(float4 positionOS : POSITION) : SV_POSITION
            {
                return TransformObjectToHClip(positionOS.xyz);
            }

            half4 fragMask() : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            Tags { "LightMode"="SRPDefaultUnlit" }

            Cull [_Cull]
            ZWrite Off
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha

            Stencil
            {
                Ref [_StencilRef]
                Comp [_StencilComp]
                Pass Keep
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 patternPos : TEXCOORD0;
                float2 dirSS      : TEXCOORD1;
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 nrmWS = TransformObjectToWorldNormal(IN.normalOS);

                float3 originWS   = TransformObjectToWorld(float3(0, 0, 0));
                float3 patternPos = lerp(posWS - originWS, posWS, _PatternSpace);

                // slides along the view ray, so only the depth changes
                posWS += normalize(GetWorldSpaceViewDir(posWS)) * _DepthPush;

                float4 posCS = TransformWorldToHClip(posWS);

                float2 nrmCS  = mul((float3x3)GetWorldToHClipMatrix(), nrmWS).xy;
                float2 pixDir = nrmCS * _ScreenParams.xy;
                pixDir /= max(length(pixDir), 1e-5);

                float resScale = _ReferenceHeight > 0.0 ? _ScreenParams.y / _ReferenceHeight : 1.0;
                float wMul = lerp(posCS.w, _RefDistance, _WorldScale);

                posCS.xy += pixDir * (_OutlineWidthPx * resScale * 2.0 / _ScreenParams.xy) * wMul;

                OUT.positionCS = posCS;
                OUT.patternPos = patternPos;
                OUT.dirSS = pixDir;
                return OUT;
            }

            float3 Palette(float t, float soft)
            {
                float s   = frac(t) * 3.0;
                float seg = floor(s);
                float f   = smoothstep(0.5 - soft * 0.5, 0.5 + soft * 0.5, frac(s));
                float3 c0 = seg < 1.0 ? _ColorA.rgb : (seg < 2.0 ? _ColorB.rgb : _ColorC.rgb);
                float3 c1 = seg < 1.0 ? _ColorB.rgb : (seg < 2.0 ? _ColorC.rgb : _ColorA.rgb);
                return lerp(c0, c1, f);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float phase = dot(IN.patternPos, normalize(_ScrollDir.xyz)) * _Frequency
                              - _Time.y * _ScrollSpeed;

                float ang = atan2(IN.dirSS.y, IN.dirSS.x) * (1.0 / 6.2831853);
                phase += ang * _DirCycles;

                float2 dir = IN.dirSS / max(length(IN.dirSS), 1e-5);
                float2 rimDir = float2(cos(radians(_RimAngle)), sin(radians(_RimAngle)));
                float facing = dot(dir, rimDir) * 0.5 + 0.5;
                float dirMask = lerp(1.0, smoothstep(0.35, 0.95, facing), _DirBias);

                float p = IN.patternPos.y * _BreakupScale
                          + sin(IN.patternPos.x * _BreakupScale * 1.7 + IN.patternPos.z * _BreakupScale * 1.3) * 2.0
                          + _Time.y * 0.5;
                float n = sin(p) * 0.5 + 0.5;
                float breakup = lerp(1.0, smoothstep(0.25, 0.75, n), _BreakupAmount);

                float alpha = lerp(_MinAlpha, 1.0, dirMask * breakup);

                return half4(Palette(phase, _Softness), alpha);
            }
            ENDHLSL
        }
    }
}
