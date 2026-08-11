Shader "Tarrock/CharacterFadeDither"
{
    // Screen-door DITHER fade for the Fool's visual (CharacterFade, Stage 3 of CameraWallResponse).
    // Built explicitly because URP renders a RUNTIME opaque->transparent surface swap of URP/Lit
    // unreliably here — the switched material draws nothing (verified in play mode; same class of
    // problem as the DustParticle shader's note). This stays OPAQUE (which renders reliably) and
    // dissolves the character by CLIPPING pixels on a 4x4 Bayer pattern as _Fade drops 1->0, so no
    // alpha blending / sorting is involved. Lighting is a simple main-light lambert + SH ambient —
    // close enough to the diorama's flat URP/Lit look for the brief moment the character is fading.
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        _Fade ("Fade (1=opaque, 0=gone)", Range(0,1)) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "Queue" = "Geometry"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float _Fade;
            CBUFFER_END

            static const float BayerMatrix[16] =
            {
                0.0,  8.0,  2.0, 10.0,
                12.0, 4.0, 14.0,  6.0,
                3.0, 11.0,  1.0,  9.0,
                15.0, 7.0, 13.0,  5.0
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionHCS = positions.positionCS;
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.screenPos = ComputeScreenPos(positions.positionCS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Screen-door dither: clip pixels whose Bayer threshold exceeds the fade amount.
                float2 screenUV = IN.screenPos.xy / max(IN.screenPos.w, 1e-4);
                float2 pixel = screenUV * _ScreenParams.xy;
                int2 cell = int2(fmod(pixel, 4.0));
                float threshold = (BayerMatrix[cell.y * 4 + cell.x] + 0.5) / 16.0;
                clip(_Fade - threshold);

                half4 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv) * _BaseColor;

                float3 normalWS = normalize(IN.normalWS);
                Light mainLight = GetMainLight();
                float ndotl = saturate(dot(normalWS, mainLight.direction));
                float3 lighting = mainLight.color * (ndotl * mainLight.shadowAttenuation) + SampleSH(normalWS);

                return half4(baseTex.rgb * lighting, 1.0);
            }
            ENDHLSL
        }
    }

    Fallback Off
}
