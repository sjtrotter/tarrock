Shader "Tarrock/TerrainPainterly"
{
    // Procedural painterly ground for sculpted Unity Terrain — NO texture assets.
    // Canon (art-audio.md §Current build): the ground material is procedural Shader Graph-class
    // surfacing, "triplanar noise with slope and height blending into color ramps, not tiling
    // photo-splats". Two reasons this is the direction and not a shortcut:
    //   1. Visual pillar 1 (painterly storybook) — a noise-and-ramp surface reads hand-painted by
    //      default, where a tiling photo-splat fights the style the whole way.
    //   2. The bound/unbound world-state swap (art-audio.md §The world-state is the art direction)
    //      becomes a shader-parameter change instead of a second texture set across 22 regions.
    //
    // Slope does the storytelling: flat ground takes the meadow ramp, steep ground takes rock, and
    // the steepest takes bare cliff — so "cliffs refuse, slopes permit" (swap rule 5) is legible in
    // COLOUR as well as in shape, before a single prop is placed.
    //
    // House style mirrored from Tarrock/FoliageWind: minimal URP, hand-rolled main-light lambert +
    // SH ambient (NOT the full URP/Lit include, which has rendered unreliably on this box for our
    // runtime-built materials), SRP-Batcher-compatible CBUFFER.
    Properties
    {
        [Header(Meadow)]
        // Three explicit frequency bands. The 2026-07-26 audit measured the old single 11 m band at
        // ±2 sRGB levels at walking distance — a flat fill swatch. MESO is the band the player
        // actually reads at the 4-6 m gameplay camera; MICRO is brush tooth, distance-faded so it
        // cannot alias into shimmer at range. The DRY colour is a genuine third hue (wind-scoured
        // ochre), on a decorrelated field — hue variation, not just more value.
        _GrassLow ("Grass - low / sheltered", Color) = (0.24, 0.33, 0.18, 1)
        _GrassHigh ("Grass - high / sunlit", Color) = (0.58, 0.62, 0.30, 1)
        _GrassDry ("Grass - wind-scoured dry", Color) = (0.56, 0.48, 0.24, 1)
        _GrassMacroScale ("Grass Macro Scale (m)", Float) = 34.0
        _GrassMesoScale ("Grass Meso Scale (m)", Float) = 4.5
        _GrassMicroScale ("Grass Micro Scale (m)", Float) = 0.55
        _GrassHueScale ("Grass Hue Field Scale (m)", Float) = 26.0
        _GrassMacroAmount ("Grass Macro Amount", Float) = 0.55
        _GrassMesoAmount ("Grass Meso Amount", Float) = 0.70
        _GrassDryAmount ("Grass Dry Amount", Float) = 1.8
        _GrassGrain ("Grass Micro Grain", Range(0,0.2)) = 0.06
        _GrassBias ("Grass Mix Bias", Range(0,1)) = 0.30

        [Header(Stone)]
        _RockColor ("Rock - slope", Color) = (0.44, 0.42, 0.38, 1)
        _CliffColor ("Cliff - refusing face", Color) = (0.34, 0.31, 0.30, 1)
        _RockVariation ("Rock Variation Scale (m)", Float) = 5.0

        [Header(Slope blending)]
        // Steepness = 1 - N.y. Below _SlopeStart the ground is walkable meadow; above _SlopeEnd it is
        // bare cliff. Keep these in loose sympathy with the CharacterController's slope limit so what
        // LOOKS unclimbable IS unclimbable — the grammar lies to the player otherwise.
        _SlopeStart ("Slope - grass ends", Range(0,1)) = 0.30
        _SlopeEnd ("Slope - cliff begins", Range(0,1)) = 0.62

        [Header(Height blending)]
        _HeightLow ("Height - low (world Y)", Float) = 0.0
        _HeightHigh ("Height - high (world Y)", Float) = 40.0

        [Header(Strata)]
        // Thin horizontal banding on stone only — the woodcut-linework pillar read at terrain scale,
        // and it makes elevation change readable at a distance (rule 5: elevation signposts the path).
        _StrataStrength ("Strata Strength", Range(0,1)) = 0.18
        _StrataScale ("Strata Spacing (m)", Float) = 5.5

        [Header(Shading)]
        // Wrapped lambert — soft storybook falloff rather than a hard terminator (Visual pillar 1).
        _ShadeWrap ("Shade Wrap", Range(0,1)) = 0.30
        _AmbientBoost ("Ambient Boost", Range(0,2)) = 1.0
        // Authored shade, not emergent: shade cools toward the tint, ambient never reaches black.
        _ShadowTint ("Shadow Tint (cool)", Color) = (0.80, 0.88, 1.06, 1)
        _AmbientFloor ("Ambient Floor", Color) = (0.10, 0.11, 0.14, 1)
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
            // Terrain renders with a plain material here (no splatmap control textures), so it is
            // deliberately NOT tagged "TerrainCompatible" — Unity's splat painting is unused by design.
        }
        LOD 200

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _GrassLow;
            float4 _GrassHigh;
            float4 _GrassDry;
            float _GrassMacroScale;
            float _GrassMesoScale;
            float _GrassMicroScale;
            float _GrassHueScale;
            float _GrassMacroAmount;
            float _GrassMesoAmount;
            float _GrassDryAmount;
            float _GrassGrain;
            float _GrassBias;
            float4 _RockColor;
            float4 _CliffColor;
            float _RockVariation;
            float _SlopeStart;
            float _SlopeEnd;
            float _HeightLow;
            float _HeightHigh;
            float _StrataStrength;
            float _StrataScale;
            float _ShadeWrap;
            float _AmbientBoost;
            float4 _ShadowTint;
            float4 _AmbientFloor;
        CBUFFER_END

        // -- Value noise ------------------------------------------------------------------------
        // Hash-based so the surface is deterministic in world space: the same metre of ground gets
        // the same mottling every run, and re-generating a region cannot reshuffle its look.
        float TkHash21(float2 p)
        {
            p = frac(p * float2(123.34, 456.21));
            p += dot(p, p + 45.32);
            return frac(p.x * p.y);
        }

        float TkValueNoise(float2 p)
        {
            float2 i = floor(p);
            float2 f = frac(p);
            float2 u = f * f * (3.0 - 2.0 * f); // smoothstep interpolant
            float a = TkHash21(i);
            float b = TkHash21(i + float2(1.0, 0.0));
            float c = TkHash21(i + float2(0.0, 1.0));
            float d = TkHash21(i + float2(1.0, 1.0));
            return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
        }

        // Three octaves is enough for a painted read; more just adds noise the style does not want.
        // NOTE: this stays VALUE noise deliberately — for a colour-mottle field the lattice fold
        // lines are invisible (the audit measured them below perceptual threshold in albedo), and
        // value noise is cheaper per-pixel. The GEOMETRY noise in TerrainRegionGenerator switched
        // to gradient noise because there the folds cast shadows; the "surface and shading agree"
        // pairing is therefore approximate, not exact, by design.
        float TkFbm(float2 p)
        {
            // fmod guard: at fine scales over hundreds of metres the hash's frac(big * 123.34)
            // runs out of float mantissa (~8 bits left near 57000) and the noise goes blocky.
            p = fmod(p, 512.0);
            float sum = 0.0;
            float amp = 0.5;
            for (int i = 0; i < 3; i++)
            {
                sum += TkValueNoise(p) * amp;
                p *= 2.03;   // non-integer lacunarity avoids visible octave alignment
                p += 17.3;   // per-octave offset: octaves must not share a feature at the origin
                amp *= 0.5;
            }
            return sum;
        }

        // Triplanar so cliff faces get mottling too — a planar-only projection smears to stripes on
        // anything near-vertical, which is exactly where the refusing cliffs are.
        float TkTriplanarFbm(float3 worldPos, float3 normal, float scaleMetres)
        {
            float3 blend = pow(abs(normal), 4.0);
            blend /= max(blend.x + blend.y + blend.z, 1e-4);
            float inv = 1.0 / max(scaleMetres, 0.01);
            float nx = TkFbm(worldPos.zy * inv);
            float ny = TkFbm(worldPos.xz * inv);
            float nz = TkFbm(worldPos.xy * inv);
            return nx * blend.x + ny * blend.y + nz * blend.z;
        }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.0

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float fogCoord    : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings Vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                VertexPositionInputs positions = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normals = GetVertexNormalInputs(input.normalOS);

                output.positionCS = positions.positionCS;
                output.positionWS = positions.positionWS;
                output.normalWS = normals.normalWS;
                output.fogCoord = ComputeFogFactor(positions.positionCS.z);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float3 positionWS = input.positionWS;
                float3 normalWS = normalize(input.normalWS);

                // -- Meadow: three frequency bands + a third hue. Macro drifts field-to-field, MESO
                //    is the clump-scale band the player reads at the 4-6 m gameplay camera, micro is
                //    brush tooth faded out past 12-36 m so it never shimmers. Height still lifts the
                //    high ground, gently — the plateau's gold lives in the LIGHT, not the albedo
                //    (director call, 2026-07-26), so the ramp must not bleach the meadow.
                float macro = TkTriplanarFbm(positionWS, normalWS, _GrassMacroScale);
                float meso = TkTriplanarFbm(positionWS, normalWS, _GrassMesoScale);
                float micro = TkValueNoise(fmod(positionWS.xz, 512.0) / max(_GrassMicroScale, 0.01));

                float camDist = distance(positionWS, _WorldSpaceCameraPos);
                float microFade = 1.0 - saturate((camDist - 12.0) / 24.0);

                float heightT = saturate((positionWS.y - _HeightLow) / max(_HeightHigh - _HeightLow, 0.01));
                float grassMix = saturate(_GrassBias
                    + (macro - 0.4375) * _GrassMacroAmount
                    + (meso - 0.4375) * _GrassMesoAmount
                    + heightT * 0.35);
                float3 grass = lerp(_GrassLow.rgb, _GrassHigh.rgb, grassMix);

                // Hue variation on a DECORRELATED field: dry wind-scoured patches, a real third
                // colour ("pale dawn gold, wind-scoured green" — the ochre enters the ground here,
                // as patches, not as the height ramp).
                float hueField = TkTriplanarFbm(positionWS + 173.0, normalWS, _GrassHueScale);
                grass = lerp(grass, _GrassDry.rgb, saturate((hueField - 0.42) * _GrassDryAmount));

                // Micro grain: multiplicative tooth, distance-faded to a no-op.
                grass *= lerp(1.0, lerp(1.0 - _GrassGrain, 1.0 + _GrassGrain, micro), microFade);

                // -- Stone: warm ochre rock on slopes, COOL slate on the refusing faces — the
                //    slope→rock transition changes hue, not just value, so "cliffs refuse, slopes
                //    permit" reads in colour temperature as well as shape.
                float rockNoise = TkTriplanarFbm(positionWS, normalWS, _RockVariation);
                float steepness = 1.0 - saturate(normalWS.y);
                float cliffT = smoothstep(_SlopeEnd, min(_SlopeEnd + 0.22, 1.0), steepness);
                float3 stone = lerp(_RockColor.rgb, _CliffColor.rgb, cliffT);
                stone *= lerp(0.86, 1.14, rockNoise);

                // -- Slope blend, computed BEFORE strata so the strata can gate on it. The noise
                //    perturbs the transition so the grass/rock boundary is a ragged natural edge.
                float slopeT = smoothstep(_SlopeStart, _SlopeEnd, steepness + (macro - 0.4375) * 0.14);

                // Strata band the stone horizontally, heavily perturbed by a LOW-frequency drift so
                // the bands wander and vary in thickness like rock (an unperturbed frac() reads as
                // corduroy). Gated on slopeT — ALL exposed stone banding, not only the steepest
                // faces: this is the woodcut-linework pillar at terrain scale, and gating on cliffT
                // alone made it invisible (7% of nearly nothing).
                float strataDrift = TkTriplanarFbm(positionWS, normalWS, 34.0);
                float strata = frac((positionWS.y + strataDrift * 9.0) / max(_StrataScale, 0.01));
                float strataBand = smoothstep(0.0, 0.30, strata) * smoothstep(0.72, 0.42, strata);
                stone *= 1.0 - strataBand * _StrataStrength * saturate(slopeT * 1.2);

                float3 albedo = lerp(grass, stone, slopeT);

                // -- Lighting: wrapped lambert + SH ambient, with the shade AUTHORED — a cool tint
                //    multiplies the shadowed side and a floor keeps ambient off black. Storybook
                //    shadows are luminous and cool, never pits.
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                Light mainLight = GetMainLight(shadowCoord);

                float ndotl = dot(normalWS, mainLight.direction);
                float wrapped = saturate((ndotl + _ShadeWrap) / (1.0 + _ShadeWrap));
                float lit = wrapped * mainLight.shadowAttenuation;
                float3 direct = mainLight.color * lit;
                float3 ambient = max(SampleSH(normalWS) * _AmbientBoost, _AmbientFloor.rgb);
                float3 shade = lerp(_ShadowTint.rgb, float3(1.0, 1.0, 1.0), saturate(lit));

                float3 color = albedo * (direct + ambient) * shade;
                color = MixFog(color, input.fogCoord);
                return half4(color, 1.0);
            }
            ENDHLSL
        }

        // Terrain must cast: ridge shadows are half of how elevation signposts the path (rule 5).
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag
            #pragma target 3.0
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;

            struct ShadowAttributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct ShadowVaryings
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            ShadowVaryings ShadowVert(ShadowAttributes input)
            {
                ShadowVaryings output = (ShadowVaryings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                float4 positionCS = TransformWorldToHClip(
                    ApplyShadowBias(positionWS, normalWS, _LightDirection));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                output.positionCS = positionCS;
                return output;
            }

            half4 ShadowFrag(ShadowVaryings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }

        // Depth-only, so depth-prepass-dependent effects (SSAO, soft particles) see the ground.
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex DepthVert
            #pragma fragment DepthFrag
            #pragma target 3.0
            #pragma multi_compile_instancing

            struct DepthAttributes
            {
                float4 positionOS : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct DepthVaryings
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            DepthVaryings DepthVert(DepthAttributes input)
            {
                DepthVaryings output = (DepthVaryings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                return output;
            }

            half4 DepthFrag(DepthVaryings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Lit"
}
