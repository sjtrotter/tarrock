Shader "Tarrock/CloudLobe"
{
    // The cumulus heads standing out of the cloud sea, close in around the island.
    //
    // WHY THIS EXISTS (2026-07-31, round 3, against Assets/Screenshots/gauntlet/round2/v3 and v4).
    // The critic's finding was not that the deck was badly coloured — it was that "its top edge
    // never OCCLUDES anything, so it reads as background wallpaper, not a sea the island sits in",
    // and in v4 that "the deck floats above the ridges with a cream gap — it reads at infinity".
    // Neither is a shading problem and neither can be fixed by shading. A horizontal plane below
    // the camera has a straight horizon at eye level and covers nothing; a painted skyline (the
    // far cloud bank in SkyGradient.hlsl) is at infinity by construction and covers nothing
    // either. The ONLY thing that can put cloud in front of a ridge is cloud with depth — real
    // geometry, at a real distance, written into the depth buffer. That is this shader's whole
    // job: the deck says "there is a surface down there", these say "and it is BETWEEN you and
    // that ridge".
    //
    // It is a separate shader rather than a mode of Tarrock/CloudSea because the two shade from
    // different things. The deck has one normal (up) across three kilometres and gets its form
    // from a noise field; a lobe has a normal per pixel and gets its form from that. They share
    // what they must share — SkyGradient.hlsl, so a lobe at range resolves to exactly the sky
    // colour along its own ray, the same convergence that keeps the deck's far-clip cut invisible.
    //
    // MOTIONLESS, like everything else on the bound Cliff (art-audio.md §The world-state is the
    // art direction; world.md §The Cliff — "a bright, motionless cloud deck"). No scroll, no
    // billow, no _TarrockWindStrength. Drift is an unbound-state job for later.
    //
    // FLAT, not volumetric. Three washes off one direction, terraced with the same TarrockSoftBand
    // the sky and the deck are terraced with, so a lobe is painted by the same hand as everything
    // around it: sunlit gold on the bearing-332 flank, cool blue-grey opposite, a darker belly
    // underneath. Wolfwalkers and fable-03 both draw cloud exactly this way — value shapes, not
    // scattering.
    Properties
    {
        _LobeLit ("Lobe - sunlit crown", Color) = (1.02, 0.97, 0.86, 1)
        _LobeShade ("Lobe - cool shade", Color) = (0.42, 0.47, 0.62, 1)
        _LobeUnder ("Lobe - belly", Color) = (0.30, 0.35, 0.48, 1)
        _LobeBands ("Lobe - painted washes", Range(2, 8)) = 3
        _LobeBandStrength ("Lobe - wash strength", Range(0, 1)) = 0.85
        _LobeBandSoftness ("Lobe - wash softness", Range(0.02, 0.5)) = 0.10
        _LobeFormGain ("Lobe - light gain", Range(0.2, 4)) = 1.15
        _LobeFormBias ("Lobe - light bias", Range(-1, 1)) = 0.42
        _LobeUnderDepth ("Lobe - belly depth", Range(0, 1)) = 0.62
        _LobeRim ("Lobe - dawn rim", Range(0, 3)) = 0.9
        _LobeRimPower ("Lobe - dawn rim tightness", Range(1, 16)) = 4

        _SkyBlendStart ("Sky blend start (m)", Float) = 430.0
        _SkyBlendEnd ("Sky blend end (m)", Float) = 820.0

        // The sky description, identical to Tarrock/GradientSky's and Tarrock/CloudSea's. All
        // three are written from the same C# constants by TerrainRegionGenerator.ApplySkyDescription;
        // if they ever disagree, a lobe grows a halo where it resolves.
        _HorizonColor ("Sky - horizon", Color) = (0.92, 0.82, 0.62, 1)
        _MidColor ("Sky - low band", Color) = (0.58, 0.62, 0.69, 1)
        _ZenithColor ("Sky - zenith", Color) = (0.20, 0.32, 0.54, 1)
        _HazeColor ("Sky - haze below horizon", Color) = (0.90, 0.85, 0.74, 1)
        _SunGlowColor ("Sky - blaze tint", Color) = (1.00, 0.84, 0.58, 1)
        _SunDirection ("Direction TO the sun (xyz)", Vector) = (-0.94, 0.276, -0.2, 0)
        _MidHeight ("Sky - mid band height", Range(0.05, 0.95)) = 0.44
        _HazeDepth ("Sky - below-horizon fade depth", Range(0.01, 0.6)) = 0.09
        _GlowFalloff ("Sky - blaze falloff", Range(1, 30)) = 7
        _GlowBroad ("Sky - blaze broad", Range(0, 2)) = 0.22
        _GlowBroadPower ("Sky - blaze broad tightness", Range(1, 16)) = 8
        _GlowCore ("Sky - blaze core", Range(0, 4)) = 0.55
        _GlowCorePower ("Sky - blaze core tightness", Range(8, 400)) = 120
        _BandCount ("Sky - painted bands", Range(2, 24)) = 7
        _BandStrength ("Sky - band strength", Range(0, 1)) = 0.30
        _BandSoftness ("Sky - band softness", Range(0.02, 0.5)) = 0.22
        _HorizonHeight ("Sky - horizon height", Range(-0.2, 0.2)) = 0.0
        _BankCrestColor ("Sky - bank lit crest", Color) = (1.02, 0.97, 0.87, 1)
        _BankShadeColor ("Sky - bank shaded body", Color) = (0.50, 0.53, 0.65, 1)
        _BankHeight ("Sky - bank mean crest height", Range(-0.05, 0.15)) = 0.020
        _BankRelief ("Sky - bank crest rise and fall", Range(0, 0.12)) = 0.045
        _BankLumpScale ("Sky - bank heads per compass turn", Range(1, 24)) = 5
        _BankRimWidth ("Sky - bank lit rim depth", Range(0.001, 0.04)) = 0.0060
        _BankBodyDepth ("Sky - bank shaded body depth", Range(0.002, 0.1)) = 0.024
        _BankDissolve ("Sky - bank dissolve into haze", Range(0.002, 0.1)) = 0.034
        _BankFloor ("Sky - bank base", Range(-0.1, 0.05)) = -0.012
        _BankFade ("Sky - bank fade below the base", Range(0.005, 0.1)) = 0.042
        _BankGapStart ("Sky - bank gap window start", Range(0, 1)) = 0.36
        _BankGapEnd ("Sky - bank gap window end", Range(0, 1)) = 0.46
        _VaultCloud0 ("Sky - vault cloud 0", Vector) = (288, 12.0, 20.0, 0.94)
        _VaultCloud1 ("Sky - vault cloud 1", Vector) = (358, 8.5, 8.0, 0.72)
        _VaultCloud2 ("Sky - vault cloud 2", Vector) = (234, 25.0, 24.0, 0.26)
        _VaultCloud3 ("Sky - vault cloud 3", Vector) = (77, 10.5, 15.0, 0.82)
        _VaultCloud4 ("Sky - vault cloud 4", Vector) = (40, 7.0, 11.0, 0.66)
        _VaultCloudLit ("Sky - vault cloud lit", Color) = (1.02, 0.97, 0.87, 1)
        _VaultCloudShade ("Sky - vault cloud shade", Color) = (0.52, 0.57, 0.71, 1)
        _VaultCloudShadow ("Sky - vault cloud belly", Color) = (0.19, 0.23, 0.35, 1)
        _VaultCloudBase ("Sky - vault cloud flat base", Range(0.05, 0.6)) = 0.22
        _VaultCloudSoftness ("Sky - vault cloud softness", Range(0.005, 0.3)) = 0.030
        _VaultCloudLump ("Sky - vault cloud cauliflower", Range(0, 0.4)) = 0.090
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
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "SkyGradient.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _LobeLit;
                float4 _LobeShade;
                float4 _LobeUnder;
                float _LobeBands;
                float _LobeBandStrength;
                float _LobeBandSoftness;
                float _LobeFormGain;
                float _LobeFormBias;
                float _LobeUnderDepth;
                float _LobeRim;
                float _LobeRimPower;
                float _SkyBlendStart;
                float _SkyBlendEnd;
                float4 _HorizonColor;
                float4 _MidColor;
                float4 _ZenithColor;
                float4 _HazeColor;
                float4 _SunGlowColor;
                float4 _SunDirection;
                float _MidHeight;
                float _HazeDepth;
                float _GlowFalloff;
                float _GlowBroad;
                float _GlowBroadPower;
                float _GlowCore;
                float _GlowCorePower;
                float _BandCount;
                float _BandStrength;
                float _BandSoftness;
                float _HorizonHeight;
                float4 _BankCrestColor;
                float4 _BankShadeColor;
                float _BankHeight;
                float _BankRelief;
                float _BankLumpScale;
                float _BankRimWidth;
                float _BankBodyDepth;
                float _BankDissolve;
                float _BankFloor;
                float _BankFade;
                float _BankGapStart;
                float _BankGapEnd;
                float4 _VaultCloud0;
                float4 _VaultCloud1;
                float4 _VaultCloud2;
                float4 _VaultCloud3;
                float4 _VaultCloud4;
                float4 _VaultCloudLit;
                float4 _VaultCloudShade;
                float4 _VaultCloudShadow;
                float _VaultCloudBase;
                float _VaultCloudSoftness;
                float _VaultCloudLump;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float fogCoord : TEXCOORD2;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;
                UNITY_SETUP_INSTANCE_ID(input);
                VertexPositionInputs positions = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positions.positionCS;
                output.positionWS = positions.positionWS;
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.fogCoord = ComputeFogFactor(positions.positionCS.z);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float3 normalWS = normalize(input.normalWS);
                float3 sunDirWS = normalize(_SunDirection.xyz);

                // ONE direction, three washes. The sun sits 7° up, so a lobe is lit from the SIDE:
                // the terminator on each head runs nearly vertical and the gold lands on the
                // bearing-332 flank, not on the top. Shading these top-bright/bottom-dark — the
                // reflex — would read as a row of dumplings and would also fight the raking light
                // the whole region is graded to.
                float ndl = dot(normalWS, sunDirWS);
                float form = saturate(ndl * _LobeFormGain + _LobeFormBias);
                form = TarrockSoftBand(form, _LobeBands, _LobeBandStrength, _LobeBandSoftness);
                float3 color = lerp(_LobeShade.rgb, _LobeLit.rgb, form);

                // The belly. Downward-facing cloud gets nothing but bounce off the deck below it,
                // which at this hour is dim and cool — and a cumulus with a bright underside is a
                // cotton ball. This is also the deck row's share of the frame's dark anchor: the
                // vault's big masses own the sky's, these own the horizon's.
                float under = saturate(-normalWS.y);
                color = lerp(color, _LobeUnder.rgb, under * _LobeUnderDepth * (1.0 - form * 0.5));

                // The dawn rim: the silhouette edge on the sun side is the brightest thing a cloud
                // has at this hour. Grazing angle × sunward, so it lights the rim and not the face.
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - input.positionWS);
                float grazing = pow(saturate(1.0 - abs(dot(normalWS, viewDirWS))), max(_LobeRimPower, 1.0));
                color += _SunGlowColor.rgb * grazing * saturate(ndl) * _LobeRim;

                color = MixFog(color, input.fogCoord);

                // ...and then, at range, a lobe simply becomes the sky — the same convergence the
                // deck uses, with the same numbers, so the near row and the deck it stands in fade
                // together instead of separating into two layers as they recede.
                TarrockSkyDesc sky;
                TARROCK_FILL_SKY_DESC(sky)

                float3 rayDir = input.positionWS - _WorldSpaceCameraPos;
                float dist = length(rayDir);
                float3 skyColor = TarrockSkyColor(rayDir, sky);
                color = lerp(color, skyColor, smoothstep(_SkyBlendStart, _SkyBlendEnd, dist));

                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
