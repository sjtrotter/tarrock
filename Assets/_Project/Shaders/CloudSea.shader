Shader "Tarrock/CloudSea"
{
    // The sea of cloud below the Cliff's broken edge (world.md §The Cliff: "an island in a sea of
    // cloud ... the drop lost in a bright, motionless cloud deck"). A bright, MOTIONLESS deck —
    // while the region is bound it does not drift, per art-audio.md §The world-state is the art
    // direction (stasis made visible); drift is an unbound-state job for later, driven like the
    // foliage wind.
    //
    // 2026-07-31 look pass. Three things this shader now has to do that it did not before:
    //
    //  1. NO SEAM AT THE SKY. The deck is 3 km across and the camera's far clip is 1 km, so the
    //     deck is ALWAYS cut by the clip plane and the cut is always a dead-straight line a few
    //     degrees under the horizon. It is invisible only if the deck has already resolved to the
    //     colour the skybox draws along the same ray — so past _SkyBlendEnd this shader evaluates
    //     the shared SkyGradient.hlsl for the view ray and returns exactly that. The seam is
    //     removed analytically, not by eye-matched constants.
    //
    //  2. NO SEAM IN THE DECK ITSELF. The old mottle wrapped its coordinates with fmod(p, 512),
    //     which over a 3 km plane repeats the noise six times per axis AND leaves a hard value
    //     step at every wrap. It also used value noise, which the 2026-07-26 terrain audit showed
    //     folds on every lattice edge. Both are gone: coordinates are metres from the deck centre
    //     (small enough for the hash without wrapping) and the noise is gradient noise.
    //
    //  3. NOT A GLOSSY PLANE. Wind-aligned stretch, a domain warp so the banks billow instead of
    //     tiling, octaves that drop out with distance (grazing angles otherwise alias into
    //     shimmer), warm/cool shaping across each billow, and a crest term that reads the deck
    //     mesh's own gentle relief. Still not a lighting model — the deck is light, not a lit
    //     surface — but it now has form.
    //
    // ROUND 2 (2026-07-31, against Assets/Screenshots/gauntlet/round1/v3). The critic measured the
    // deck surface at one value, std 7.5, with zero internal form — and (2) and (3) above were
    // both already in. Two causes, both fixed here:
    //
    //    * THE OCTAVES WERE THE WRONG SIZE, AND THERE WERE TOO FEW. v3's camera stands 6.3 m above
    //      the deck, and a plane seen from 6.3 m up compresses savagely: half the frame's deck is
    //      inside 100 m and the nearest is ten metres away. A 300 m bank scale put the ENTIRE
    //      visible near field inside one noise cell, and one cell is one value. Every scale is
    //      roughly halved, a fourth 5 m octave is added for the deck seen from arm's length, and
    //      the octaves are now summed SIGNED with a gain — averaging the 0..1 form of gradient
    //      noise never leaves the middle of the range whatever you stack on it.
    //    * THE SKY BLEND STARTED AT 170 m. Everything past that was being erased toward the sky
    //      before it could show any of the form this shader spends its whole budget computing.
    //      It now starts at 430 m, which the geometry says is safe: from a low camera the whole
    //      430 m→1 km range occupies about a dozen pixels of screen, and from the high vantages
    //      it still resolves fully (820 m) well inside the 1 km far clip.
    //
    // ROUND 3 (2026-07-31, against Assets/Screenshots/gauntlet/round2/v3 and v4). Round 2 gave the
    // deck octaves at the right sizes and it still photographed as "a flat-shaded fill with no
    // light-to-shadow separation". The octaves were never the whole problem: a noise field mapped
    // straight to colour has PATTERN and no LIGHT, and a cloud sea with no light in it is a
    // textured floor. So the two low octaves are now a HEIGHT FIELD — finite-differenced in world
    // xz into a normal and shaded against the same sun as everything else in the region — and
    // the curd and fleece octaves demote from being the washes to texturing them. The furrow
    // colour also comes down (0.58,0.62,0.74 → 0.47,0.52,0.66 linear, set in the generator) so the
    // shaded flanks are a value step and not a hue step.
    //
    // What is deliberately NOT here, and still is not: the deck's skyline. A plane below the
    // camera has a straight horizon however hard its mesh billows, so the lumpy cloud skyline is
    // painted at infinity in SkyGradient.hlsl (the far cloud bank) and this shader inherits it
    // through the same sky convergence that hides the clip-plane cut. What the deck DOES now get
    // is a third dimension standing on it: Tarrock/CloudLobe draws real cumulus geometry rising
    // out of the deck near the island, which is the only way anything can OCCLUDE — see that
    // shader and TerrainRegionGenerator §The cloud lobes.
    //
    // ROUND 4 (2026-07-31, against gauntlet/round3/v3 and v4, and following the sun from 7° to 12°).
    // Two things, and the second is the answer to "the deck sheet has no top-surface relief crossing
    // the mid-field — airbrushed streaks only":
    //
    //   * THE SHADING MODEL IS RE-SOLVED FOR THE NEW SUN. Every number in the relief block below is
    //     traced rather than tuned; the short version is that 26 m of virtual relief self-shadowed
    //     at 7° and cannot at 12°, so it goes to 46 m and the ramp is re-fitted around it. The
    //     furrow colour comes down again with it (0.47,0.52,0.66 → 0.34,0.39,0.54 linear, set in the
    //     generator), which takes the deck's own ladder from 45 sRGB points to 70.
    //   * THE MID-FIELD RELIEF IS NOT THIS SHADER'S TO GIVE, and saying so plainly is the round-4
    //     lesson. A shading field on a plane can put light and shade on the deck — it cannot put one
    //     part of the deck IN FRONT OF another, and "lobed rises crossing the mid-field" is an
    //     occlusion read, not a value read. Two things now supply it, both geometry: the deck mesh's
    //     own billow, which round 4 grades finer and brings in to the island's edge, and a band of
    //     low wide swells standing in the open sea just off the rim (TerrainRegionGenerator §THE
    //     SWELL BAND). This shader's job is the light on that surface, and only that.
    Properties
    {
        _CloudBright ("Cloud - lit tops", Color) = (0.97, 0.93, 0.85, 1)
        _CloudShade ("Cloud - furrows (cool)", Color) = (0.58, 0.62, 0.74, 1)

        _BroadScale ("Bank scale (m)", Float) = 130.0
        _MidScale ("Billow scale (m)", Float) = 48.0
        _FineScale ("Curd scale (m)", Float) = 15.0
        // A fourth octave, for the deck seen from ARM'S LENGTH. At the western rim the player
        // stands 6 m above the cloud and the nearest deck is ten metres away; a 15 m feature is
        // the size of the whole near field there, so without this the closest — and largest —
        // part of the frame is one flat value again, just one octave down from round 1.
        _CurdScale ("Fleece scale (m)", Float) = 5.0
        // ROUND 3: this now gains the CURD AND FLEECE octaves only. The two low octaves stopped
        // being colour and became a height field for the lighting below, and a height field wants
        // its own amplitude in metres (_ReliefHeight), not a colour gain. Gradient noise sits at
        // ±0.2 in practice, so the high octaves still need multiplying by several times before
        // they are visible as surface texture at all.
        _MottleContrast ("Fine-octave gain", Range(0.4, 12)) = 4.5

        // The deck is PAINTED, not rendered: quantising the mottle into a few washes with soft
        // edges is what turns a smooth noise field into flat storybook shapes with boundaries.
        // Same TarrockSoftBand the sky terraces with, so deck and sky are brushed alike.
        _MottleBands ("Mottle - painted washes", Range(2, 12)) = 5
        _MottleBandStrength ("Mottle - wash strength", Range(0, 1)) = 0.42
        _MottleBandSoftness ("Mottle - wash softness", Range(0.02, 0.5)) = 0.17

        _WarpScale ("Domain warp scale (m)", Float) = 95.0
        _WarpAmount ("Domain warp amount (m)", Float) = 26.0
        _StreakAxis ("Streak axis (xz, normalised, points at the sun)", Vector) = (-0.978, -0.208, 0, 0)
        _StreakStretch ("Streak stretch", Range(1, 8)) = 2.2

        // ROUND 3. The deck is now LIT, not tinted. The two low octaves are read as a height field,
        // finite-differenced in world xz into a normal, and shaded against the region's one sun —
        // then terraced into the same painted washes. Round 2 added a single warm/cool tint off a
        // one-sided difference of the bank octave, which is a hue shift, not a light-to-shadow
        // separation, and the critic measured exactly that: "a flat-shaded fill".
        _SunFormColor ("Form warmth", Color) = (1.00, 0.84, 0.58, 1)
        _SunFormStrength ("Lit-wash gold", Range(0, 3)) = 1.1
        // Where the gold starts, on the terraced ramp. A CONSTANT 0.72 through round 3, which was
        // fine while the ramp's 98th percentile sat at 0.74 — at the round-4 sun the same ramp runs
        // to 0.86 and a hardcoded 0.72 would pour the highlight over a third of the sea.
        _SunFormThreshold ("Lit-wash gold - onset", Range(0, 1)) = 0.80
        _SlopeStep ("Relief sampling step (m)", Float) = 14.0
        // Metres of VIRTUAL relief on a mathematically flat plane. The deck mesh billows ±7 m, but
        // that is a 1° swell at 400 m and it can never shade anything; the surface's readable form
        // has to come from the shading field itself.
        //
        // ROUND 4: 26 → 46 m, and the sun's raise from 7° to 12° is the whole reason. Traced over a
        // 1 km square of the field, 26 m of relief over a 130 m bank puts a mean flank tilt of 7.8°
        // on the deck (95th percentile 15.1°). At a 7° sun that is enough for a lee flank to turn
        // away from the disc entirely — the measured 2nd percentile of N·L was 0.0007, i.e. the
        // deck genuinely self-shadowed. At 12° the same field's 2nd percentile is +0.081: NOTHING
        // on the deck turns away any more, the dark end of the range is simply gone, and the whole
        // ramp shifts up 0.22 and clips 4.4% of the surface flat white at the top. 46 m restores
        // it — mean tilt 13.5°, 95th percentile 25.4°, 3.0% of the deck back at or below N·L 0 —
        // and a 25° flank on a cloud bank is gentle by the standards of the thing it is drawing.
        _ReliefHeight ("Relief height (m)", Float) = 46.0
        // Solved, not dialled: at 46 m the field's N·L runs −0.061 (1st pct) to +0.412 (99th), so
        // gain 2.03 / bias +0.09 maps that band onto 0.03-0.93 with nothing clipped at either end.
        _FormGain ("Light gain", Range(0.5, 8)) = 2.03
        _FormBias ("Light bias", Range(-1, 1)) = 0.09
        _ReliefWeight ("Light vs. altitude", Range(0, 1)) = 0.66
        // How hard the ALTITUDE term is worked. The relief field sits at std 0.144, so round 3's
        // 1.35 left the altitude half of the mix spanning only 0.19-0.81 — it was quietly narrowing
        // the very range the light half had just been widened to reach.
        _HeightGain ("Altitude gain", Range(0.5, 4)) = 2.05

        _DeckLevel ("Deck level (world Y)", Float) = 11.0
        _CrestRange ("Crest range (m)", Float) = 7.0
        _CrestLift ("Crest lift", Range(0, 0.6)) = 0.14

        _DeckCentre ("Deck centre (xz)", Vector) = (128, 128, 0, 0)
        _CurdFadeStart ("Fleece fade start (m)", Float) = 30.0
        _CurdFadeEnd ("Fleece fade end (m)", Float) = 80.0
        _FineFadeStart ("Curd fade start (m)", Float) = 100.0
        _FineFadeEnd ("Curd fade end (m)", Float) = 220.0
        _MidFadeStart ("Billow fade start (m)", Float) = 250.0
        _MidFadeEnd ("Billow fade end (m)", Float) = 560.0
        _SkyBlendStart ("Sky blend start (m)", Float) = 430.0
        _SkyBlendEnd ("Sky blend end (m)", Float) = 820.0

        // The sky description, identical to Tarrock/GradientSky's. Both are written from the same
        // C# constants in TerrainRegionGenerator; if they ever disagree the deck grows a horizon.
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
        _VaultCloudBaseLump ("Sky - vault cloud base wander", Range(0, 0.25)) = 0.075
        _VaultCloudSoftness ("Sky - vault cloud softness", Range(0.005, 0.3)) = 0.030
        _VaultCloudLump ("Sky - vault cloud cauliflower", Range(0, 0.4)) = 0.090
        _VaultCloudLift ("Sky - vault cloud wash lift", Range(0, 2)) = 0.58
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
            #include "SkyGradient.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _CloudBright;
                float4 _CloudShade;
                float _BroadScale;
                float _MidScale;
                float _FineScale;
                float _CurdScale;
                float _MottleContrast;
                float _MottleBands;
                float _MottleBandStrength;
                float _MottleBandSoftness;
                float _WarpScale;
                float _WarpAmount;
                float4 _StreakAxis;
                float _StreakStretch;
                float4 _SunFormColor;
                float _SunFormStrength;
                float _SunFormThreshold;
                float _SlopeStep;
                float _ReliefHeight;
                float _FormGain;
                float _FormBias;
                float _ReliefWeight;
                float _HeightGain;
                float _DeckLevel;
                float _CrestRange;
                float _CrestLift;
                float4 _DeckCentre;
                float _CurdFadeStart;
                float _CurdFadeEnd;
                float _FineFadeStart;
                float _FineFadeEnd;
                float _MidFadeStart;
                float _MidFadeEnd;
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
                float _VaultCloudBaseLump;
                float _VaultCloudSoftness;
                float _VaultCloudLump;
                float _VaultCloudLift;
            CBUFFER_END

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

            // Cloud banks are drawn out by the wind that made them, so the noise domain is
            // stretched along the region's wind/light axis before anything samples it.
            float2 CsStreak(float2 p, float2 axis, float stretch)
            {
                float2 perp = float2(-axis.y, axis.x);
                return float2(dot(p, axis) / max(stretch, 1.0), dot(p, perp));
            }

            // The deck's RELIEF: the two low octaves, read as a signed height field. This is what
            // gets differentiated into a normal, so it deliberately excludes the curd and fleece
            // octaves — their slopes are steeper than anything a cloud has and they would shade as
            // gravel. Sampled three times per pixel (centre and two world-axis steps), which is why
            // it is a function and why the domain warp is passed in already computed: the warp
            // moves over 95 m and the step is 14, so re-warping each tap would buy nothing and cost
            // four more noise evaluations per pixel on a surface that can own a third of the frame.
            float CsRelief(float2 p, float2 axis, float stretch, float2 warpOffset, float midFade)
            {
                float2 q = CsStreak(p, axis, stretch) + warpOffset;
                return TarrockGradNoise(q / max(_BroadScale, 1.0)) * 0.62
                     + TarrockGradNoise(q / max(_MidScale, 1.0) + float2(19.4, 7.2)) * 0.38 * midFade;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float3 positionWS = input.positionWS;
                float dist = distance(positionWS, _WorldSpaceCameraPos);

                // Octaves die with distance. At the grazing angles the deck is ALWAYS seen from,
                // a 15 m feature is a pixel and a half by ~250 m and turns into shimmer; the
                // fade distances in TerrainRegionGenerator are derived from that, not guessed.
                float curdFade = 1.0 - smoothstep(_CurdFadeStart, _CurdFadeEnd, dist);
                float fineFade = 1.0 - smoothstep(_FineFadeStart, _FineFadeEnd, dist);
                float midFade = 1.0 - smoothstep(_MidFadeStart, _MidFadeEnd, dist);

                // Metres from the deck centre. NO fmod wrap: the old guard tiled the deck every
                // 512 m and left a hard step at each wrap. +-1500 m stays inside the hash's honest
                // precision at these octave scales.
                float2 p = positionWS.xz - _DeckCentre.xy;
                float2 axis = normalize(_StreakAxis.xy + float2(1e-5, 0.0));
                float2 q = CsStreak(p, axis, _StreakStretch);

                // Domain warp: without it the banks read as a lattice of blobs however soft the
                // noise is. With it they curl. Computed once, in the streaked frame, and then
                // shared by all three relief taps below.
                float2 warp = float2(
                    TarrockGradNoise(q / max(_WarpScale, 1.0) + float2(11.3, 5.7)),
                    TarrockGradNoise(q / max(_WarpScale, 1.0) + float2(71.9, 33.1)));
                float2 warpOffset = warp * _WarpAmount;
                q += warpOffset;

                // -------------------------------------------------------------------------------
                // THE DECK IS LIT. Round 2's deck was measured as "a flat-shaded fill with no
                // light-to-shadow separation", and it was: the noise field was mapped straight to
                // colour, so the deck had PATTERN but no light in it — a cloud sea painted from
                // above with a flat brush. It is now shaded like everything else in the region,
                // from the one sun, by treating the two low octaves as a height field on a
                // mathematically flat plane. Two world-axis taps give the gradient; the normal
                // follows; N·L against the 7° dawn does the rest.
                //
                // ROUND 4, and this is the number the sun's raise moved. Traced over a 1 km square
                // of the field: at 26 m of relief and a 7° sun, N·L ran 0.123 ± 0.064 with its 2nd
                // percentile at 0.0007 — the lee flanks turned away from the disc entirely and the
                // deck genuinely self-shadowed. At 12° the same field gives 0.209 ± 0.063 with its
                // 2nd percentile at +0.081: nothing turns away, the dark end is gone, and the ramp
                // clips 4.4% of the surface flat white at the other end. 46 m of relief puts the
                // 1st-99th percentile band back at −0.061…+0.412, which gain 2.03 / bias 0.09 maps
                // onto 0.03-0.93. The result is what the reference plates do: the sunward flank of
                // every bank catches gold and its lee goes cool blue-grey, in flat washes.
                // -------------------------------------------------------------------------------
                // reliefStep, not step: step() is an HLSL intrinsic and shadowing it in a function
                // that also uses smoothstep is a compile error waiting for a different compiler.
                float reliefStep = max(_SlopeStep, 1.0);
                float r0 = CsRelief(p, axis, _StreakStretch, warpOffset, midFade);
                float rx = CsRelief(p + float2(reliefStep, 0.0), axis, _StreakStretch, warpOffset, midFade);
                float rz = CsRelief(p + float2(0.0, reliefStep), axis, _StreakStretch, warpOffset, midFade);

                float3 normalWS = normalize(float3(
                    -(rx - r0) * _ReliefHeight / reliefStep,
                    1.0,
                    -(rz - r0) * _ReliefHeight / reliefStep));
                float3 sunDirWS = normalize(_SunDirection.xyz);
                float lightT = saturate(dot(normalWS, sunDirWS) * _FormGain + _FormBias);

                // Altitude, mixed in beside the light: cloud tops are brighter than cloud troughs
                // whatever the sun is doing, and mixing the two keeps the washes reading as ONE
                // billowing surface instead of as stripes running across it.
                float heightT = saturate(r0 * _HeightGain + 0.5);
                float mottle = lerp(heightT, lightT, saturate(_ReliefWeight));

                // The high octaves stay, but as TEXTURE on the washes rather than as the washes.
                // 5 m at arm's length over the rim and 15 m at a stone's throw: without them the
                // largest — and nearest — part of the frame is one flat value, which was round 1's
                // finding and is still true.
                float curd = TarrockGradNoise(q / max(_FineScale, 1.0) + float2(47.1, 63.5));
                float fleece = TarrockGradNoise(q / max(_CurdScale, 0.5) + float2(83.7, 12.9));
                mottle += (curd * 0.115 * fineFade + fleece * 0.085 * curdFade) * _MottleContrast * 0.25;

                // A soft KNEE, not the round-2 soft saturation. Hard clipping gives the brightest
                // banks dead flat tops, which is how a cloud stops looking like a cloud — but a
                // full x·rsqrt(1+x²) applied to a ramp that is already inside 0..1 (which this one
                // is, now that it comes from two saturated terms rather than from a signed octave
                // sum) only squeezes the range back out of it: it would map 0..1 to 0.15..0.85 and
                // hand back the flat deck this pass exists to remove. Gain 2.4 with a 0.55 knee
                // steepens the middle and rolls off only the last fifth; the 0.896 divisor is
                // f(1.2) for that knee, so full ramp still lands on full ramp.
                float centred = (mottle - 0.5) * 2.4;
                mottle = saturate(centred * rsqrt(1.0 + centred * centred * 0.55) * 0.558 + 0.5);
                // ...and then terraced. Storybook cloud is a handful of flat washes with soft
                // boundaries, not a gradient; quantising the RAMP rather than the colour keeps the
                // washes following the billow instead of cutting across it.
                mottle = TarrockSoftBand(mottle, _MottleBands, _MottleBandStrength, _MottleBandSoftness);

                float3 color = lerp(_CloudShade.rgb, _CloudBright.rgb, mottle);

                // Gold on the top wash only. The region's grade is warm LIGHT on cool material, so
                // the warmth belongs where the light lands and nowhere else; spreading it over the
                // whole surface (round 2) is how the deck ended up one tinted value.
                color += _SunFormColor.rgb * saturate(mottle - _SunFormThreshold) * _SunFormStrength;

                // The deck mesh carries a gentle billow of its own beyond the plateau (see
                // TerrainRegionGenerator.BuildCloudDeckMesh). Reading its height keeps shading and
                // silhouette telling the same story instead of fighting.
                float crest = clamp((positionWS.y - _DeckLevel) / max(_CrestRange, 0.01), -1.0, 1.0);
                color += _SunFormColor.rgb * crest * _CrestLift;

                color = MixFog(color, input.fogCoord);

                // ...and then, at range, the deck simply becomes the sky. Fog first, sky second:
                // the sky blend has to be LAST so that at _SkyBlendEnd the result is exactly
                // TarrockSkyColor for this ray and the far-clip cut has nothing to show.
                TarrockSkyDesc sky;
                TARROCK_FILL_SKY_DESC(sky)

                float3 rayDir = positionWS - _WorldSpaceCameraPos;
                float3 skyColor = TarrockSkyColor(rayDir, sky);
                color = lerp(color, skyColor, smoothstep(_SkyBlendStart, _SkyBlendEnd, dist));

                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Unlit"
}
