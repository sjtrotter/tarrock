Shader "Tarrock/GrassTuft"
{
    // Instanced grass-tuft shader for Unity Terrain DETAIL meshes (the built-in grass system —
    // per-patch culling, painted/programmatic density, GPU instancing; the right tool for meadow
    // grass where a particle system would pay unmanaged overdraw). The tuft mesh carries vertex
    // colour (dark base → light tip); this shader tints it and lights it with the same wrapped
    // lambert + SH house style as Tarrock/TerrainPainterly, so blades sit in the ground's light.
    //
    // Deliberately WINDLESS for now: the Cliff is bound and holds its breath (art-audio.md §The
    // world-state is the art direction) — motionless grass IS the canon state. When an unbound
    // region needs waving grass, add the FoliageWind-style sway keyed to _TarrockWindStrength.
    //
    // MUST support instancing: Terrain renders mesh details via GPU instancing (useInstancing on
    // the DetailPrototype); a shader without it renders nothing or falls back per-object.
    Properties
    {
        _BaseColor ("Tint", Color) = (1, 1, 1, 1)
        _ShadeWrap ("Shade Wrap", Range(0,1)) = 0.35
        _AmbientBoost ("Ambient Boost", Range(0,2)) = 1.0
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
        Cull Off // crossed quads read from both sides

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.0
            #pragma multi_compile_instancing
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _ShadeWrap;
                float _AmbientBoost;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float4 color : COLOR;
                float fogCoord : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings Vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs positions = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positions.positionCS;
                output.positionWS = positions.positionWS;
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.color = input.color;
                output.fogCoord = ComputeFogFactor(positions.positionCS.z);
                return output;
            }

            half4 Frag(Varyings input, half facing : VFACE) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float3 normalWS = normalize(input.normalWS) * (facing > 0 ? 1.0 : -1.0);
                float3 albedo = input.color.rgb * _BaseColor.rgb;

                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                Light mainLight = GetMainLight(shadowCoord);

                float ndotl = dot(normalWS, mainLight.direction);
                float wrapped = saturate((ndotl + _ShadeWrap) / (1.0 + _ShadeWrap));
                float3 direct = mainLight.color * (wrapped * mainLight.shadowAttenuation);
                float3 ambient = SampleSH(normalWS) * _AmbientBoost;

                float3 color = albedo * (direct + ambient);
                color = MixFog(color, input.fogCoord);
                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
