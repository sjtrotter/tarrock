Shader "Tarrock/CloudSea"
{
    // The sea of cloud below the Cliff's broken edge (world.md §The Cliff: an island in a sea of
    // cloud; MQ00: "the drop beneath it lost in haze"). A bright, MOTIONLESS deck — while the
    // region is bound it does not drift, per art-audio.md §The world-state is the art direction
    // (stasis made visible); drift is an unbound-state job for later, driven like the foliage wind.
    //
    // Deliberately unlit-plus-mottle: the deck reads as light itself (the "wall of light" the north
    // edge wants), so it takes no lambert term — just a broad two-tone mottle, a distance fade
    // toward the horizon colour, and scene fog. House style per FoliageWind/TerrainPainterly:
    // minimal URP, SRP-Batcher-compatible CBUFFER, no external includes beyond Core.
    Properties
    {
        _CloudBright ("Cloud - lit tops", Color) = (0.98, 0.94, 0.86, 1)
        _CloudShade ("Cloud - furrows", Color) = (0.78, 0.76, 0.74, 1)
        _MottleScale ("Mottle Scale (m)", Float) = 60.0
        _MottleScale2 ("Mottle Detail Scale (m)", Float) = 17.0
        // Beyond this distance the deck settles toward _HorizonColor so it melts into the sky
        // instead of tiling to the horizon.
        _HorizonColor ("Horizon Color", Color) = (0.80, 0.70, 0.50, 1)
        _HorizonStart ("Horizon Fade Start (m)", Float) = 220.0
        _HorizonEnd ("Horizon Fade End (m)", Float) = 900.0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }
        LOD 100

        Pass
        {
            Name "Unlit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.0
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _CloudBright;
                float4 _CloudShade;
                float _MottleScale;
                float _MottleScale2;
                float4 _HorizonColor;
                float _HorizonStart;
                float _HorizonEnd;
            CBUFFER_END

            float CsHash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float CsValueNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);
                float a = CsHash21(i);
                float b = CsHash21(i + float2(1.0, 0.0));
                float c = CsHash21(i + float2(0.0, 1.0));
                float d = CsHash21(i + float2(1.0, 1.0));
                return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
            }

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float fogCoord : TEXCOORD1;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                VertexPositionInputs positions = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positions.positionCS;
                output.positionWS = positions.positionWS;
                output.fogCoord = ComputeFogFactor(positions.positionCS.z);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                // Two mottle octaves; guard the hash against large-coordinate precision loss the
                // same way TerrainPainterly does (the plane is kilometres wide).
                float2 p = fmod(input.positionWS.xz, 512.0);
                float broad = CsValueNoise(p / max(_MottleScale, 0.01));
                float fine = CsValueNoise(p / max(_MottleScale2, 0.01) + 31.7);
                float mottle = saturate(broad * 0.7 + fine * 0.3);
                float3 color = lerp(_CloudShade.rgb, _CloudBright.rgb, mottle);

                // Melt into the horizon long before the plane's edge can read.
                float dist = distance(input.positionWS, _WorldSpaceCameraPos);
                float horizonT = smoothstep(_HorizonStart, _HorizonEnd, dist);
                color = lerp(color, _HorizonColor.rgb, horizonT);

                color = MixFog(color, input.fogCoord);
                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
