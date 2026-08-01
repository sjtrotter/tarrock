Shader "Tarrock/RockPainterly"
{
    // Painterly stone for the scattered rock-outcrop family (TerrainRegionGenerator.BuildRockOutcrops).
    //
    // WHY A SHADER AND NOT Tarrock/FoliageWind. The only mesh shader the region had was the foliage
    // one, which lights a mesh with a single flat _BaseColor and ignores COLOR.rgb — a boulder drawn
    // with it is one untextured lump, which is exactly the "smooth empty mass" the round-1 critique
    // is about. Stone needs three things the ground already has and foliage does not: mottle that
    // survives on near-vertical faces, bedding that gives a block a top and a grain, and a POSTERISED
    // light ramp so a rock reads as a few laid-down values rather than a smooth gradient
    // (art-bible.md brush economy). All three are lifted from Tarrock/TerrainPainterly deliberately:
    // a rock sitting on the ground must be made of the same paint as the ground, or the frame gains
    // a prop instead of a landform. The palette is not restated here — the generator READS
    // _RockColor / _CliffColor / _MossColor off the terrain material and writes them onto the rock
    // material, so there is exactly one place those colours are chosen.
    //
    // ROUND-3 REWRITE, in step with Tarrock/TerrainPainterly's. Read that shader's header first; the
    // reasoning is there and is not restated. Three changes here:
    //
    //   a. THE BEDDING IS REBUILT to the same grammar as the ground's: a gravity-aligned world-Y
    //      lattice with per-bed position/thickness/value jitter, a thin dark parting and a thin
    //      sunlit lip, a warp CAPPED to a fraction of a bed, and analytic anti-aliasing off the
    //      lattice's own screen footprint. Round 2 drew `posterise(sin(bedding * pi))`, which is a
    //      WIDE SOFT sinusoid lerping the whole albedo between two stone colours — that is why the
    //      round-2 boulders read as a stack of pale tonal slabs rather than as a bedded block. A bed
    //      is a thin parting between two masses of one colour, not a colour that oscillates.
    //
    //   b. A CAVITY TERM, the same AO-like construct the ground uses: the FILLED region where the
    //      fine relief sits below the broad form. It replaces nothing (round 2 had no occlusion at
    //      all) and it is deliberately not folded into the bedding — the boulder must still have
    //      hollows with the bedding turned off.
    //
    //   c. STRICTLY OPAQUE render state, stated rather than inherited, for the same reason the
    //      ground states it: it should take four lines to verify, not an argument from absent syntax.
    //
    // The rock's HARD FACETS are left alone on purpose. The ground's facets are a fault (a Gouraud
    // artefact on a surface that is meant to be smooth); a boulder's facets are the art direction
    // (BuildRockMesh emits per-quad normals so the stone reads as a few flat planes with confident
    // edges, art-bible.md). Do not add the ground's per-pixel shading normal here.
    //
    // NO WIND. Rock does not move, bound or unbound, so this shader carries no sway and never reads
    // _TarrockWindStrength. (It is also therefore safe under static batching, which is what ate the
    // object-space foliage sway in commit 48712b9 — nothing here is object-space.)
    Properties
    {
        [Header(Palette)]
        _RockColor ("Rock (warm grey)", Color) = (0.52, 0.49, 0.44, 1)
        _CliffColor ("Cliff (pale cool grey)", Color) = (0.45, 0.47, 0.49, 1)
        _MossColor ("Moss (upward faces)", Color) = (0.19, 0.24, 0.13, 1)
        _MossAmount ("Moss Amount", Range(0, 1)) = 0.45
        _MossStart ("Moss Normal Start", Range(-1, 1)) = 0.25

        [Header(Surface)]
        _RockVariation ("Mottle Scale (m)", Float) = 1.6
        _RockContrast ("Mottle Contrast", Range(0.5, 4)) = 1.7
        _RockDetailAmount ("Detail Amount", Range(0, 0.5)) = 0.12
        // ROUND-4 (gauntlet critique of round3/v5, "no surface detail at 2 m"): a jittered-cell
        // value band under the mottle, so the block reads as laid marks at arm's length instead of
        // one wash between two partings. Same construct and the same per-cell rotation/aspect/size
        // spread as Tarrock/TerrainPainterly's TkDabShaped — the ground and the stones sitting on
        // it must be made of the same paint. Sampled on the FACE'S own frame (strike across, world
        // Y up) so it costs ONE lookup rather than a triplanar's three, and faded out past a few
        // metres because a sub-pixel mark at range is a shimmer generator.
        _RockDabScale ("Dab Scale (m)", Float) = 0.20
        _RockDabTone ("Dab Tone", Range(0, 0.5)) = 0.17
        _RockDabAniso ("Dab Aspect Spread", Range(0, 0.9)) = 0.55
        _RockDabSize ("Dab Size Spread", Range(0, 0.9)) = 0.45
        _RockDabFadeStart ("Dab Fade Start (m)", Float) = 6.0
        _RockDabFadeRange ("Dab Fade Range (m)", Float) = 10.0
        // How far the block's own colour drifts between formations. It is a HUE swing between two
        // stone colours applied per formation, not a value oscillation applied per pixel.
        _FormationTint ("Formation Hue Swing", Range(0, 1)) = 0.55

        [Header(Bedding)]
        // Gravity-aligned, same grammar as the ground (see Tarrock/TerrainPainterly §Bedding). A
        // boulder is about a metre tall, so the spacing is an order finer than the cliff's.
        _BeddingSpacing ("Bedding - mean bed thickness (m)", Float) = 0.34
        _BeddingDip ("Bedding - dip gradient (XZ)", Vector) = (0.070, 0.0, -0.050, 0)
        _BeddingWarp ("Bedding - warp (m, capped to 0.30 bed)", Float) = 0.09
        _BeddingLineWidth ("Bedding - parting half width (bed fraction)", Range(0.01, 0.3)) = 0.10
        _BeddingWidthJitter ("Bedding - per-bed thickness jitter", Range(0, 0.9)) = 0.60
        _BeddingDarken ("Bedding - parting darken", Range(0, 1)) = 0.30
        _BeddingLip ("Bedding - sunlit lip", Range(0, 1)) = 0.18
        _BedValueJitter ("Bedding - per-bed value jitter", Range(0, 0.4)) = 0.10
        _BedFormRate ("Bedding - formations per bed", Range(0.05, 1)) = 0.30
        // A horizontal bed cuts a thin line across a STEEP face and an enormous blob across a
        // near-horizontal one, so the flat tops and undersides of a boulder take no bedding. Same
        // physics as the ground's slope gate, measured on |N.y| because a boulder has both.
        _BeddingFaceStart ("Bedding - face fade in (1 - abs N.y)", Range(0, 1)) = 0.18
        _BeddingFaceEnd ("Bedding - face full (1 - abs N.y)", Range(0, 1)) = 0.46

        [Header(Cavity)]
        _CavityScale ("Cavity Scale (m)", Float) = 0.55
        _CavityContrast ("Cavity Contrast", Range(0.5, 10)) = 4.5
        _CavityDarken ("Cavity Darken", Range(0, 1)) = 0.30

        [Header(Brush economy)]
        _BrushSteps ("Value Steps", Range(2, 10)) = 4
        _BrushSoftness ("Step Softness", Range(0.02, 1)) = 0.35

        [Header(Lighting)]
        _ShadeWrap ("Shade Wrap", Range(0, 1)) = 0.25
        _AmbientBoost ("Ambient Boost", Range(0, 2)) = 1.0
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
            "IgnoreProjector" = "True"
        }
        LOD 200
        Cull Back

        // One shared block: the SRP Batcher requires an identical UnityPerMaterial layout in every
        // pass, and the noise helpers are wanted by the forward pass only but cost nothing here.
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _RockColor;
            float4 _CliffColor;
            float4 _MossColor;
            float _MossAmount;
            float _MossStart;
            float _RockVariation;
            float _RockContrast;
            float _RockDetailAmount;
            float _RockDabScale;
            float _RockDabTone;
            float _RockDabAniso;
            float _RockDabSize;
            float _RockDabFadeStart;
            float _RockDabFadeRange;
            float _FormationTint;
            float _BeddingSpacing;
            float4 _BeddingDip;
            float _BeddingWarp;
            float _BeddingLineWidth;
            float _BeddingWidthJitter;
            float _BeddingDarken;
            float _BeddingLip;
            float _BedValueJitter;
            float _BedFormRate;
            float _BeddingFaceStart;
            float _BeddingFaceEnd;
            float _CavityScale;
            float _CavityContrast;
            float _CavityDarken;
            float _BrushSteps;
            float _BrushSoftness;
            float _ShadeWrap;
            float _AmbientBoost;
            float4 _ShadowTint;
            float4 _AmbientFloor;
        CBUFFER_END

        // The same hash / noise / cavity / posterise family Tarrock/TerrainPainterly uses. Copied
        // rather than shared through an .hlsl on purpose: these functions are the region's paint
        // recipe and the two shaders must agree, but a rock is not a terrain and the include would
        // drag the terrain's splat plumbing with it. If the ground's recipe changes, change it here.
        float TkHash21(float2 p)
        {
            p = frac(p * float2(123.34, 456.21));
            p += dot(p, p + 45.32);
            return frac(p.x * p.y);
        }

        float2 TkHash22(float2 p)
        {
            float3 p3 = frac(p.xyx * float3(0.1031, 0.1030, 0.0973));
            p3 += dot(p3, p3.yzx + 33.33);
            return frac((p3.xx + p3.yz) * p3.zy);
        }

        float TkValueNoise(float2 p)
        {
            float2 i = floor(p);
            float2 f = frac(p);
            float2 u = f * f * (3.0 - 2.0 * f);
            float a = TkHash21(i);
            float b = TkHash21(i + float2(1.0, 0.0));
            float c = TkHash21(i + float2(0.0, 1.0));
            float d = TkHash21(i + float2(1.0, 1.0));
            return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
        }

        float TkFbm(float2 p)
        {
            p = fmod(p, 512.0);
            float sum = 0.0;
            float amp = 0.5;
            float norm = 0.0;
            for (int i = 0; i < 3; i++)
            {
                sum += TkValueNoise(p) * amp;
                norm += amp;
                p *= 2.03;
                p += 17.3;
                amp *= 0.5;
            }
            return sum / norm;
        }

        // .x is the broad form, .y the same form plus one finer octave, both mean 0.5. Their
        // difference is positive exactly in the HOLLOWS — a filled region, never a level set. See
        // Tarrock/TerrainPainterly's TkCavityPair for why that distinction is the whole ballgame.
        float2 TkCavityPair(float2 p)
        {
            float broad = TkValueNoise(p);
            float fine = TkValueNoise(p * 2.71 + 19.7);
            return float2(broad, broad * 0.68 + fine * 0.32);
        }

        // Triplanar, because a boulder is mostly NOT facing up: a planar xz projection smears the
        // mottle into vertical stripes on exactly the faces that read against the sky.
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

        float2 TkTriplanarCavityPair(float3 worldPos, float3 normal, float scaleMetres)
        {
            float3 blend = pow(abs(normal), 4.0);
            blend /= max(blend.x + blend.y + blend.z, 1e-4);
            float inv = 1.0 / max(scaleMetres, 0.01);
            return TkCavityPair(worldPos.zy * inv) * blend.x
                 + TkCavityPair(worldPos.xz * inv) * blend.y
                 + TkCavityPair(worldPos.xy * inv) * blend.z;
        }

        // The ground's round-4 brushmark field, copied under the same rule as everything else in
        // this block: the rock and the ground must be made of one paint recipe. See
        // Tarrock/TerrainPainterly's TkDabShaped for why a per-cell rotation, aspect and radius are
        // what stop a jittered-cell field reading as one stamp on a visible pitch.
        float3 TkDabShaped(float2 p, float aniso, float sizeJitter)
        {
            float2 cell = floor(p);
            float2 f = p - cell;
            float best = 8.0;
            float bestTone = 0.0;
            float bestId = 0.0;

            [unroll]
            for (int y = -1; y <= 1; y++)
            {
                [unroll]
                for (int x = -1; x <= 1; x++)
                {
                    float2 g = float2(x, y);
                    float2 h = TkHash22(cell + g);
                    float2 s = TkHash22(cell + g + 37.19);
                    float2 d = g + h - f;

                    float sn, cs;
                    sincos(s.x * 6.2831853, sn, cs);
                    float2 r = float2(d.x * cs - d.y * sn, d.x * sn + d.y * cs);

                    float stretch = max(1.0 + aniso * (s.y - 0.5) * 2.0, 0.25);
                    r.x /= stretch;
                    r.y *= stretch;

                    float radius = max(1.0 + sizeJitter * (frac(s.x * 7.31 + s.y * 3.17) - 0.5) * 2.0, 0.25);
                    float sq = dot(r, r) / (radius * radius);

                    bestTone = sq < best ? frac(h.x * 3.71 + h.y * 7.13) : bestTone;
                    bestId = sq < best ? frac(s.x * 5.17 + s.y * 9.43) : bestId;
                    best = min(best, sq);
                }
            }

            return float3(saturate(sqrt(best)), bestTone, bestId);
        }

        float TkContrast(float x, float k)
        {
            return saturate((x - 0.5) * k + 0.5);
        }

        float TkSoftPosterize(float x, float steps, float softness)
        {
            float soft = clamp(softness, 0.02, 1.0) * 0.5;
            float s = x * steps;
            float level = floor(s);
            float f = s - level;
            float e = smoothstep(0.5 - soft, 0.5 + soft, f);
            return saturate((level + e) / max(steps, 1.0));
        }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            // STRICTLY OPAQUE, stated rather than inherited — see the header.
            Blend One Zero
            ZWrite On
            ZTest LEqual
            Cull Back

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
                float4 color      : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float4 color      : TEXCOORD2;
                float fogCoord    : TEXCOORD3;
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
                output.color = input.color;
                output.fogCoord = ComputeFogFactor(positions.positionCS.z);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float3 positionWS = input.positionWS;
                float3 normalWS = normalize(input.normalWS);

                // -- Mottle: the block's own patchiness. Contrast-pushed for the same reason the
                //    ground's is — three octaves of value noise sit in a narrow band around the mean
                //    and read as an airbrush until they are pushed apart. It doubles as the bedding
                //    warp field below, which is why it is computed before the bedding and not after.
                float mottle = TkContrast(
                    TkTriplanarFbm(positionWS, normalWS, _RockVariation), _RockContrast);

                // -- Cavity: the FILLED hollows, an AO-like term of its own. Also supplies the
                //    texel-scale tone that round 2 took from a second triplanar fbm, so the extra
                //    hollow costs three taps rather than nine.
                float2 relief = TkTriplanarCavityPair(positionWS, normalWS, _CavityScale);
                float cavity = saturate((relief.x - relief.y) * _CavityContrast);

                // -- Bedding, gravity-aligned, same grammar as the ground -------------------------
                // Gated to the STEEP faces of the block: a horizontal bed cuts a thin line across a
                // vertical face and an enormous blob across a flat top.
                float faceMask = smoothstep(_BeddingFaceStart, _BeddingFaceEnd,
                    1.0 - abs(normalWS.y));

                float spacing = max(_BeddingSpacing, 0.02);
                // Capped to well under a bed, so the lattice stays world Y and the partings stay
                // horizontal lines instead of becoming the warp field's closed level sets. This cap
                // is the round-2 worm fix and it is structural, not a taste setting.
                float warpM = min(abs(_BeddingWarp), spacing * 0.30);
                float bedRaw = (positionWS.y
                    + _BeddingDip.x * positionWS.x + _BeddingDip.z * positionWS.z
                    + (mottle - 0.5) * 2.0 * warpM) / spacing;

                float bedIndex = floor(bedRaw);
                float f = bedRaw - bedIndex;

                float2 bedHash = TkHash22(float2(bedIndex, 3.7));
                float bedTone = TkHash21(float2(bedIndex * 0.71 + 4.3, 9.1));
                float partAt = lerp(0.12, 0.88, bedHash.x);
                float halfW = _BeddingLineWidth
                    * lerp(1.0 - _BeddingWidthJitter, 1.0 + _BeddingWidthJitter, bedHash.y);

                // Analytic AA off the lattice's own screen footprint: soften so a mark never falls
                // under a pixel and crawls, and fade the mark out entirely once a whole bed is
                // thinner than about two and a half pixels. A scatter of a few hundred boulders is
                // exactly where a sub-pixel hard line would shimmer.
                float bedAA = max(fwidth(positionWS.y), 1e-5) / spacing;
                float w = max(halfW, bedAA * 0.80);
                float aaFade = 1.0 - smoothstep(0.125, 0.40, bedAA);

                float d = abs(f - partAt);
                float parting = 1.0 - smoothstep(w * 0.30, w, d);

                float lipD = partAt - f;
                float lip = saturate(1.0 - lipD / max(w * 2.6, 1e-5))
                          * saturate(lipD / max(w * 0.9, 1e-5));

                float lineAmount = faceMask * aaFade;

                // Hue by FORMATION, not by bed — a stack of partings that share a colour.
                float formIndex = floor(bedRaw * _BedFormRate);
                float formRand = TkHash21(float2(formIndex, formIndex * 0.37 + 11.0));

                float3 albedo = lerp(_RockColor.rgb, _CliffColor.rgb,
                    saturate(formRand * 1.35 - 0.18) * _FormationTint * faceMask);
                albedo *= lerp(0.88, 1.12, mottle);
                albedo *= 1.0 + (relief.y - 0.5) * 2.0 * _RockDetailAmount;
                albedo *= 1.0 + (bedTone - 0.5) * 2.0 * _BedValueJitter * faceMask;
                albedo *= 1.0 - parting * _BeddingDarken * lineAmount;
                albedo *= 1.0 + lip * _BeddingLip * lineAmount;
                albedo *= 1.0 - cavity * _CavityDarken;

                // -- Close-range brushmarks (round-4 finding on v5). Nothing above this line works
                //    below ~0.35 m, so a boulder at arm's length was one flat wash between two
                //    partings. Marks with EDGES are the house economy (art-bible.md); a smooth
                //    field here would only be a second airbrush.
                float dabFade = 1.0 - smoothstep(_RockDabFadeStart,
                    max(_RockDabFadeStart + _RockDabFadeRange, _RockDabFadeStart + 0.01),
                    distance(positionWS, _WorldSpaceCameraPos));
                if (dabFade > 0.004)
                {
                    float2 strike = normalize(float2(-normalWS.z, normalWS.x) + 1e-4);
                    float2 faceUV = float2(dot(positionWS.xz, strike), positionWS.y)
                        / max(_RockDabScale, 0.01);
                    float3 dab = TkDabShaped(faceUV, _RockDabAniso, _RockDabSize);
                    albedo *= 1.0 + (dab.y - 0.5) * 2.0 * _RockDabTone * dabFade;
                }

                // -- Moss on ledges: only where the face turns upward AND the hollows say damp, so
                //    it lands in patches instead of coating every horizontal facet.
                float ledge = saturate((normalWS.y - _MossStart) / max(1.0 - _MossStart, 1e-3));
                float moss = _MossAmount * ledge * ledge * (0.35 + cavity * 0.65);
                albedo = lerp(albedo, _MossColor.rgb, saturate(moss));

                // -- Per-facet value baked into the mesh: the hand-laid variation between one face
                //    and the next, plus the darkening toward the buried base that makes a rock sit
                //    IN the ground instead of on it. (See BuildRockMesh.)
                albedo *= input.color.rgb;

                // -- Lighting: wrapped lambert POSTERISED into a few values (brush economy), a cool
                //    tint on the shaded side and a floor under ambient so shadow stays luminous.
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                Light mainLight = GetMainLight(shadowCoord);

                float ndotl = dot(normalWS, mainLight.direction);
                float wrapped = saturate((ndotl + _ShadeWrap) / (1.0 + _ShadeWrap));
                float stepped = TkSoftPosterize(wrapped, _BrushSteps, _BrushSoftness);
                float lit = stepped * mainLight.shadowAttenuation;
                float3 direct = mainLight.color * lit;
                float3 ambient = max(SampleSH(normalWS) * _AmbientBoost, _AmbientFloor.rgb);
                float3 shade = lerp(_ShadowTint.rgb, float3(1.0, 1.0, 1.0), saturate(lit));

                float3 color = albedo * (direct + ambient) * shade;
                color = MixFog(color, input.fogCoord);
                return half4(color, 1.0);
            }
            ENDHLSL
        }

        // Rocks must cast: the near outcrops' shadows are half of what makes them read as near.
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

        // Depth-only, so the depth prepass (PC_RPAsset requires it; SSAO samples it) sees the rocks.
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ZTest LEqual
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
