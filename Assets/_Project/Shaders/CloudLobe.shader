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
    //
    // ROUND 4 (2026-07-31, against gauntlet/round3/v3 and v4). Two findings, and the second one
    // explains the first:
    //
    //   * "A DECK LOBE SPANS 8 LUMINANCE POINTS CROWN-TO-BASE AND MATCHES THE SHEET BEHIND IT."
    //     Measured on round3/v3 the small heads run 180→198 sRGB — 18 points at best, 8 typical.
    //     That is NOT a palette failure: the round-3 ladder (crown 1.02,0.97,0.86 → belly
    //     0.30,0.35,0.48) is worth 78 sRGB points through this project's grade. It is FOG. The
    //     region's exp² fog at density 0.0044 keeps exp(−(d·0.0044)²) of any surface's own
    //     contrast, and round 3's near row stood at 200-300 m, where that is 0.46 down to 0.18.
    //     78 × 0.18 = 14 points. The capture is the arithmetic, exactly.
    //     So this pass does BOTH halves: the ladder widens to ~100 points (a genuinely dark base,
    //     see _LobeUnder), and the masses that have to carry value move inside 150 m — see
    //     TerrainRegionGenerator §CloudLobeAnchors, where every anchor now records the fog factor
    //     it will be seen through.
    //
    //   * "THE BIG FORM LEFT-OF-CENTRE IS HARD-FACETED WITH A VERTICAL BEVEL HIGHLIGHT." That was
    //     THREE flat washes of a raw N·L, terraced at 85% strength over 0.10 of softness. With the
    //     sun 12° up, the iso-N·L contours on a rounded head are near-vertical great circles, so an
    //     85% terrace of them draws hard vertical stripes down the mass — a bevel. The band edges
    //     were doing the modelling and the form was not.
    //
    // WHAT SHADES A LOBE NOW, and none of it is a raw N·L quantised:
    //   1. WRAPPED sun. Cloud scatters light round its own limb, so the terminator is a wide soft
    //      band, not an edge; (N·L + w)/(1 + w) is the standard wrap and it is what stops the head
    //      reading as a stone lit by a torch.
    //   2. SKY. A cumulus top takes the whole dome and its underside takes almost none of it. This
    //      is the term that gives the mass a top and a bottom, and it is the one round 3 refused on
    //      the grounds that top-bright/bottom-dark "would read as a row of dumplings". The dumplings
    //      came from having no dark base and no scallops — not from knowing which way is up.
    //   3. HEIGHT IN THE MASS, painted. A cumulus base is dark because there is a kilometre of
    //      cloud above it, not because the surface points down; round 3 asked saturate(−N.y) for the
    //      base and got almost nothing, because from any camera standing on the island the only
    //      down-facing surface you can see is the sliver of overhang at the waterline. The base is
    //      now drawn from the mass's own object-space height, which is what a painter does.
    //   4. THICKNESS = DARKNESS, from the object's world scale. Same rule the vault masses already
    //      obey (SkyGradient.hlsl §THE DARK ANCHOR): the big near masses get the deep base and the
    //      18 m nubs stay light, with nothing hand-flagged and no per-instance data — the radius is
    //      already in unity_ObjectToWorld, and reading it there survives instancing.
    // The terrace stays, because storybook cloud is washes — but four of them at 0.55 over 0.22 of
    // softness, which is the sky's own brush, not a stencil.
    //
    // ROUND 9 (2026-08-02, against gauntlet/round8 and the reference board). Three changes, all of
    // them one finding: this row was drawing an EVEN mass — even outline, even edge, even interior.
    //   1. §ONE NOISE FAMILY. The silhouette/tooth term and the paint term used two unrelated sets
    //      of frequencies, so the edge and the interior were drawn by different hands. One ladder
    //      now, sampled once, shared — and the crumple's finest octave finally gets the Nyquist
    //      fade the brush always had.
    //   2. §THE ACCENT, WHICH IS NOT A RIM. A pow(1 − |N·V|) band is constant-width by
    //      construction, because N·V goes to zero all the way round a closed mass. The accent is
    //      now gated by how far the limb turns toward the sun, widened by the mass's own
    //      cauliflower, and broken into strokes by it. Measured on the offline lobe model: mean
    //      added luminance 0.0116 → 0.0072 linear, carried by 19.2% → 6.5% of a mass, peak
    //      0.748 → 1.647.
    //   3. The mesh's scallop becomes INTERMITTENT (TerrainRegionGenerator.Sky.cs
    //      §CloudLobeScallopFactor) — calm shoulders and crisp bites instead of one amplitude
    //      everywhere.
    // Scored with critic 5's own estimator on the near hero of v3 (perimeter/√area of a
    // luma > 72nd-percentile mask): 14.48 → 18.18, against a board band of 21.1–334. Ghost-contour
    // index 0.29 → 0.10 on that mass and 0.67 → 0.24 on the second. VERIFIED OFFLINE, not in
    // Unity: scratchpad round9/builderC/lobe.py ports this whole file, and val2.py shows it
    // reproducing round-8 lobe pixels to a mean of 11–31 sRGB levels with the hue within 6.
    //
    // WHAT ROUND 9 STILL DOES NOT TAKE, and it is now the top of the list rather than a deferral:
    // the DOME term (SkyGradient.hlsl §TARROCK_CLOUD_SKYFILL). The round-8 note below refused it
    // because "the offline model this round is solved against covers the skybox, not the lobe
    // meshes". That model now exists. These masses still read as STONE — opaque, hard-terminated,
    // with a near-black base — and the cool sky light on their shaded flanks is the missing half
    // of the storybook law. It is not taken here only because it needs _LobeShade, _LobeMid and
    // _LobeUnder re-solved against it, which is a second variable and this round already spends
    // its one.
    Properties
    {
        // ROUND 5: THREE named washes, not two plus a belly. See the fragment's §THE THREE-BAND
        // RAMP — _LobeShade is now the SHADOW CORE at the bottom of the ramp and _LobeMid is the
        // body between it and the crown. Authored in the same convention as every other colour in
        // this project: Material.SetColor treats a plain Color property as sRGB and converts it to
        // linear on upload, so these numbers are sRGB however the generator's constants are named.
        // ROUND 8, (1.10, 1.01, 0.84) → (0.885, 0.870, 0.779), and the crown does not move a level.
        // TARROCK_CLOUD_SUNWARM goes 0.22 → 0.70 this round (SkyGradient.hlsl — the disc carries the
        // warm half of the storybook law now, instead of it being pre-mixed into the paint), and
        // this row shares that constant on purpose: the near masses and the vault masses cannot be
        // lit by different suns. So the PAINT gives back exactly what the LIGHT gains —
        //     round 7 crown = g2l(1.10,1.01,0.84) + 0.22·sunGlow = (1.448, 1.162, 0.723) linear
        //     round 8 crown = g2l(0.885,0.870,0.779) + 0.70·sunGlow = (1.448, 1.162, 0.723) linear
        // — which is "white in the light" stated properly: a near-neutral pigment with the dawn
        // arriving as illumination, so a later grade can no longer invert it. The half-lit body
        // gains the difference at a quarter weight (litWash² at form's middle plateau), which is
        // the one place this row genuinely warms, and it warms toward the sun.
        _LobeLit ("Lobe - sunlit crown", Color) = (0.885, 0.870, 0.779, 1)
        _LobeMid ("Lobe - body", Color) = (0.57, 0.60, 0.70, 1)
        _LobeShade ("Lobe - shadow core", Color) = (0.22, 0.27, 0.43, 1)
        _LobeUnder ("Lobe - belly", Color) = (0.13, 0.18, 0.33, 1)
        _LobeMidPoint ("Lobe - shadow/body split", Range(0.2, 0.8)) = 0.46
        // How far the mass's own cauliflower crumples the ramp parameter before it is terraced.
        // 0.30 on a three-octave field of std 0.26 moves a wash boundary about a third of a wash.
        _LobeCrumple ("Lobe - wash crumple", Range(0, 0.8)) = 0.30
        _LobeBands ("Lobe - painted washes", Range(2, 8)) = 3
        _LobeBandStrength ("Lobe - wash strength", Range(0, 1)) = 0.92
        _LobeBandSoftness ("Lobe - wash softness", Range(0.005, 0.5)) = 0.030
        _LobeFormGain ("Lobe - light gain", Range(0.2, 4)) = 1.45
        _LobeFormBias ("Lobe - light bias", Range(-1, 1)) = -0.12
        // How wide the terminator wraps round the limb. 0 is a hard N·L edge (a stone); 1 puts the
        // terminator halfway round the far side (a paper lantern). 0.55 is a cumulus.
        _LobeWrap ("Lobe - light wrap", Range(0, 1)) = 0.55
        // Sun against sky. 1 is pure N·L — round 3, and a vertical-terminator bevel; 0 is pure
        // top-lighting — a dumpling. The reference plates are between, nearer the sun.
        _LobeSunWeight ("Lobe - sun vs. sky", Range(0, 1)) = 0.68
        _LobeUnderDepth ("Lobe - belly depth", Range(0, 1)) = 0.90
        // How far the painted base climbs above the cloud sea, in RADII, and how fast it falls off.
        // 0.42 on a 30 m mass is 12.6 m of dark base standing out of the deck.
        _LobeBaseRise ("Lobe - base rise (radii)", Range(0.05, 1.2)) = 0.42
        _LobeBasePower ("Lobe - base falloff", Range(0.5, 6)) = 1.7
        // The cloud sea's world Y. Only used to find each mass's own waterline — see the fragment.
        _LobeDeckLevel ("Lobe - deck level (world Y)", Float) = 11.0
        // Thickness reads as darkness: the metre radius at which a mass earns its full dark base,
        // and the one below which it earns none. Read from the transform, so the scatter's own size
        // roll drives it.
        _LobeThinRadius ("Lobe - no base below (m)", Float) = 14.0
        _LobeThickRadius ("Lobe - full base above (m)", Float) = 24.0
        // ROUND 9: these two now drive THE ACCENT, not a rim — see the fragment's §THE ACCENT,
        // WHICH IS NOT A RIM. _LobeRimPower is the accent's BASE tightness, which the mass's own
        // cauliflower then widens by up to 3.2x where a lobe bulges into the light; _LobeRim is its
        // strength where it actually lands, which is a small sunward fraction of the limb rather
        // than the whole of it. The strength therefore goes UP (1.1 -> 2.6) while the total light
        // this term adds to a mass goes DOWN: measured on the model over anchor A's whole mask,
        // mean added luminance 0.0116 -> 0.0072 linear, the pixels that carry any of it fall from
        // 19.2% of the mask to 6.5%, and the PEAK goes 0.748 -> 1.647. That is the trade the board
        // plates draw — a few genuinely
        // bright marks instead of an even wash — and it is board-legal to let those marks run hot:
        // fable-03 clips 16.08% of its frame, fable-06 3.83%, and our whole round-8 set maxes at
        // 0.051%, so a locally clipped sunlit crown is 75x inside what the board does.
        _LobeRim ("Lobe - dawn accent", Range(0, 4)) = 2.6
        _LobeRimPower ("Lobe - dawn accent tightness", Range(1, 16)) = 6

        _SkyBlendStart ("Sky blend start (m)", Float) = 430.0
        _SkyBlendEnd ("Sky blend end (m)", Float) = 820.0

        // The sky description, identical to Tarrock/GradientSky's and Tarrock/CloudSea's. All
        // three are written from the same C# constants by TerrainRegionGenerator.ApplySkyDescription;
        // if they ever disagree, a lobe grows a halo where it resolves.
        _HorizonColor ("Sky - horizon", Color) = (1.00, 0.80, 0.46, 1)
        _MidColor ("Sky - low band", Color) = (0.40, 0.51, 0.75, 1)
        _ZenithColor ("Sky - zenith", Color) = (0.15, 0.29, 0.60, 1)
        _HazeColor ("Sky - haze below horizon", Color) = (0.94, 0.93, 0.89, 1)
        _SunGlowColor ("Sky - blaze tint", Color) = (1.00, 0.82, 0.52, 1)
        _SunDirection ("Direction TO the sun (xyz)", Vector) = (-0.94, 0.276, -0.2, 0)
        _MidHeight ("Sky - mid band height", Range(0.05, 0.95)) = 0.32
        _HazeDepth ("Sky - below-horizon fade depth", Range(0.01, 0.6)) = 0.09
        _GlowFalloff ("Sky - blaze falloff", Range(1, 30)) = 7
        _GlowBroad ("Sky - blaze broad", Range(0, 2)) = 0.30
        _GlowBroadPower ("Sky - blaze broad tightness", Range(1, 16)) = 5
        _GlowCore ("Sky - blaze core", Range(0, 4)) = 0.55
        _GlowCorePower ("Sky - blaze core tightness", Range(8, 400)) = 120
        _BandCount ("Sky - painted bands", Range(2, 24)) = 7
        _BandStrength ("Sky - band strength", Range(0, 1)) = 0.30
        _BandSoftness ("Sky - band softness", Range(0.02, 0.5)) = 0.22
        _HorizonHeight ("Sky - horizon height", Range(-0.2, 0.2)) = 0.0
        _BearingRise ("Sky - lean toward the sun", Range(0, 2)) = 1.15
        _BearingPower ("Sky - lean tightness", Range(0.2, 6)) = 1.3
        _BearingTilt ("Sky - anti-sun ramp steepening", Range(0, 6)) = 5.2
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
        _VaultCloud1 ("Sky - vault cloud 1", Vector) = (358, 7.5, 11.0, 0.82)
        _VaultCloud2 ("Sky - vault cloud 2", Vector) = (234, 25.0, 24.0, 0.26)
        _VaultCloud3 ("Sky - vault cloud 3", Vector) = (77, 10.5, 15.0, 0.82)
        _VaultCloud4 ("Sky - vault cloud 4", Vector) = (36, 4.5, 14.0, 0.88)
        _VaultCloudLit ("Sky - vault cloud lit", Color) = (1.03, 0.98, 0.88, 1)
        _VaultCloudShade ("Sky - vault cloud shade", Color) = (0.505, 0.560, 0.685, 1)
        _VaultCloudShadow ("Sky - vault cloud belly", Color) = (0.145, 0.205, 0.415, 1)
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
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "SkyGradient.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _LobeLit;
                float4 _LobeMid;
                float4 _LobeShade;
                float4 _LobeUnder;
                float _LobeMidPoint;
                float _LobeCrumple;
                float _LobeBands;
                float _LobeBandStrength;
                float _LobeBandSoftness;
                float _LobeFormGain;
                float _LobeFormBias;
                float _LobeWrap;
                float _LobeSunWeight;
                float _LobeUnderDepth;
                float _LobeBaseRise;
                float _LobeBasePower;
                float _LobeDeckLevel;
                float _LobeThinRadius;
                float _LobeThickRadius;
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
                float _BearingRise;
                float _BearingPower;
                float _BearingTilt;
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
                float3 normalOS : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float fogCoord : TEXCOORD2;
                // (object height, radius in metres, waterline in object units). Height because a
                // cumulus base is painted from how far down the mass a pixel sits, not from which
                // way its surface points (see the header); radius because thickness reads as
                // darkness. Both come off the instanced transform, and they are read HERE rather
                // than in the fragment because unity_ObjectToWorld only means the right instance
                // after UNITY_SETUP_INSTANCE_ID, which is a vertex-stage call.
                float3 lobeParams : TEXCOORD3;
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
                // The lobes are placed with a uniform scale (PlaceCloudLobe), so any basis column's
                // length is the radius in metres. Column 1 rather than 0: the yaw spin is about Y,
                // so the Y column is exactly the scale whatever the rotation is doing.
                float radius = length(float3(
                    unity_ObjectToWorld._m01, unity_ObjectToWorld._m11, unity_ObjectToWorld._m21));
                // The deck plane, in this mass's own object units. PlaceCloudLobe puts the centre at
                // deckLevel − radius·sink, so this is exactly the sink the anchor chose — which is
                // how the painted base below stays anchored to the cloud sea while each mass is
                // free to stand more or less proud of it.
                float waterline = (_LobeDeckLevel - unity_ObjectToWorld._m13) / max(radius, 0.01);
                output.lobeParams = float3(input.positionOS.y, radius, waterline);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float3 normalWS = normalize(input.normalWS);
                float3 sunDirWS = normalize(_SunDirection.xyz);
                float lobeY = input.lobeParams.x;
                float lobeRadius = input.lobeParams.y;
                float waterline = input.lobeParams.z;

                // -------------------------------------------------------------------------------
                // THE LIGHT — wrapped, not raw. Round 3 terraced a raw N·L at 85% strength, and
                // with the sun 12° up the iso-N·L contours on a rounded head are near-vertical
                // great circles: the bands came out as hard vertical stripes down the mass, which
                // is the bevel the critic named. Wrapping is the fix and it is also the physics —
                // a cumulus is a scattering body, so light carries a long way round its own limb
                // and the terminator is a wide soft band. At _LobeWrap 0.55 the surface stops
                // receiving anything only past N·L = −0.55, i.e. 33° round the back.
                // -------------------------------------------------------------------------------
                float ndl = dot(normalWS, sunDirWS);
                float wrapped = saturate((ndl + _LobeWrap) / (1.0 + _LobeWrap));

                // THE SKY. A cumulus crown sees the whole dome and its underside sees almost none
                // of it. Round 3 refused this term on the grounds that top-bright/bottom-dark reads
                // as a row of dumplings — but the dumpling read came from having no dark base and no
                // scallops, and refusing it is what left the masses with no top and no bottom at
                // all. Weighted UNDER the sun (_LobeSunWeight 0.68), so the dawn still decides which
                // flank is gold; the sky only decides which way is up.
                float skyT = saturate(normalWS.y * 0.5 + 0.5);

                float form = saturate(lerp(skyT, wrapped, saturate(_LobeSunWeight))
                                      * _LobeFormGain + _LobeFormBias);

                // -------------------------------------------------------------------------------
                // ROUND 5 — THE CRUMPLE, and it is the reason round 4's terrace measured as nothing
                // at all. Modelled through the URP LUT chain over a 615×300 mass, round 4's lobe
                // came out with interior gradient median 0.12 and 0.00% of its pixels above
                // gradient-magnitude 8; the reference cumulus (ghibli totoro's two banks) run 1.66
                // and 4.6-5.2%. A terrace laid on a SMOOTH form does not draw edges — it draws
                // clean latitude contours whose steps are spread over tens of pixels, and on a
                // wrapped-light sphere those contours are so nearly parallel to the silhouette that
                // they vanish into it.
                //
                // Three octaves of the mass's own cauliflower over (azimuth of the world normal ×
                // the vertex's own object-space height), added to the ramp PARAMETER before
                // terracing. Both coordinates belong to the SURFACE, not to the screen, so the
                // boundaries are nailed to the lobe and read as painted form; a screen-space
                // posterize would swim across it as the camera moved. The azimuth is taken from the
                // world normal rather than the object one — the fragment has no object normal, and
                // the yaw each mass is spun by (PlaceCloudLobe) then gives instances of the same
                // mesh different crumple, which is a variation this row wants anyway.
                // 1 : 0.52 : 0.26 over frequencies 3.4 / 8.1 / 19 is one lobe, its sub-lobes and
                // their rims — the same 1 : 0.45 proportion the vault's silhouette scallop uses.
                // -------------------------------------------------------------------------------
                float azi = atan2(normalWS.x, normalWS.z);

                // -------------------------------------------------------------------------------
                // ROUND 9 — ONE NOISE FAMILY, SAMPLED ONCE, AND IT IS THE ROUND'S SECOND FINDING.
                //
                // Through round 8 this shader drew its masses with TWO unrelated noise fields. The
                // silhouette/tooth term sampled (3.4, 5.2), (toothFreq, toothFreq·1.53) and
                // (11.0, 17.0); the brush term below sampled (4.5, 6.8), (14.0, 21.0) and
                // (32.0, 48.0) — different frequencies, different lattice offsets, therefore
                // different marks. Two critics converged on the picture that follows from that: the
                // EDGE of a mass and its INTERIOR are drawn by different hands, so the interior's
                // texture never resolves into the lobes the edge is describing, and the terminator
                // has a texture on the lit side that does not continue onto the shadow side. A
                // painter loads one brush and uses it for the contour and the modelling both.
                //
                // Four octaves on ONE ladder, sampled once and shared. Every frequency here is a
                // round-8 frequency kept (n0, n1 and n2 are the old crumple's three octaves,
                // unchanged to the third significant figure), so this is a UNIFICATION and not a
                // re-tune: what changes is that the brush is now built from n0, n1 and n2 as well,
                // plus one finer octave of the same family, instead of from three strangers.
                // The 1.53 anisotropy in height is the family's own — it is what the round-6 tooth
                // already used — and it is now carried by the shared coordinate rather than being
                // re-derived per term.
                //
                // AND THE THIRD OCTAVE GETS THE NYQUIST FADE IT NEVER HAD. Round 8's crumple ran
                // (11.0, 17.0) with no footprint fade at all while its brush faded every octave —
                // so on the 18 m scatter nubs the wash boundaries aliased while the paint on them
                // did not. One family, one fade schedule, and the small masses now shed edge detail
                // and interior detail together, which is what makes them recede instead of sparkle.
                // -------------------------------------------------------------------------------
                float2 nuv = float2(azi, lobeY * 1.53);
                // ROUND 6 — THE TOOTH SCALE VARIES, the same correction the vault masses take (see
                // SkyGradient.hlsl §TarrockVaultCloud). A fixed high octave draws one tooth size
                // along every wash boundary on every mass, which reads as a filter rather than as a
                // hand; a slow selector stretches it and lightens it as it gets finer.
                float toothSel = TarrockGradNoise01(float2(azi * 1.1, lobeY * 1.7 + 2.3));
                float toothFreq = 5.6 + 8.0 * toothSel;
                float toothWeight = 0.34 + 0.36 * (1.0 - toothSel);
                // The footprint, measured once for the whole family. The azimuth footprint is
                // clamped because atan2's branch cut makes fwidth() meaningless on the one seam
                // meridian — the same guard the round-6 brush carried, now shared.
                float foot = min(fwidth(azi), 0.05) + fwidth(lobeY);
                float fade2 = saturate(1.0 - foot * 18.0);
                float fade3 = saturate(1.0 - foot * 41.0);
                float n0 = TarrockGradNoise(float2(nuv.x * 3.4, nuv.y * 3.4 + 11.0));
                float n1 = TarrockGradNoise(float2(nuv.x * toothFreq + 4.0,
                                                   nuv.y * toothFreq + 3.0));
                float n2 = TarrockGradNoise(float2(nuv.x * 11.0 + 9.0, nuv.y * 11.0 + 7.0));
                float n3 = TarrockGradNoise(float2(nuv.x * 26.0 + 21.3, nuv.y * 26.0 + 21.3));
                float crumple = n0 + n1 * toothWeight + n2 * 0.26 * fade2;
                // ...and its TAILS ARE CAPPED before it moves the terrace. ROUND 6, and this is the
                // dark-speck fix. `form` saturates at 1.0 over a lit crown, and with three washes
                // the top boundary sits 1/6 below that, so any crumple minimum past −0.55 punches
                // an isolated island of the body wash into the middle of the crown — the 8–15 px
                // specks the round-5 critics found on v3 and v4. The soft saturation (the same
                // x·rsqrt form the cloud bank uses on its crest) leaves the field's working range
                // almost untouched — one standard deviation, 0.26, is preserved to 89% — while
                // bounding it at ±0.50, so `capped * 0.30` can never exceed 0.15 of the 0.1667 it
                // would need. The crown cannot be punctured, by arithmetic rather than by luck,
                // and the boundaries still wander exactly as much as they did.
                float capped = 0.50 * crumple * rsqrt(0.25 + crumple * crumple);
                form = saturate(form + capped * _LobeCrumple);

                // ...and then terraced, HARD. Round 4 spent 0.22 of softness over four washes,
                // which puts a band edge across ~13 px of a 300 px mass: a 20-point step over 13 px
                // is |grad| 1.5 and the measurement found exactly that. Three washes at 0.92 over
                // 0.030 spend the same step over ~3 px, which is |grad| 8 — the reference figure.
                // It is not the round-3 bevel coming back: that was a raw N·L terraced at 0.85,
                // whose iso-contours under a 12° sun are near-vertical great circles. This is a
                // wrapped-plus-sky form with a crumpled parameter, so the edges wander.
                form = TarrockSoftBand(form, _LobeBands, _LobeBandStrength, _LobeBandSoftness);

                // THE THREE-BAND RAMP. Round 4 lerped shade → lit and left _LobeUnder reachable
                // only through the belly term, which is scaled by the mass's own radius — so the
                // small masses had no dark end whatever and the big ones only found it below the
                // waterline. Three named colours on one ramp: the shadow core owns the bottom 46%,
                // and every unlit flank of every lobe lands in it. Modelled at anchor B (100 m,
                // fog 0.0059) this takes crown-to-base from 44.3 sRGB points to 70.7.
                float3 color = form < _LobeMidPoint
                    ? lerp(_LobeShade.rgb, _LobeMid.rgb, saturate(form / max(_LobeMidPoint, 0.01)))
                    : lerp(_LobeMid.rgb, _LobeLit.rgb,
                           saturate((form - _LobeMidPoint) / max(1.0 - _LobeMidPoint, 0.01)));

                // ROUND 6 — THE PAPER TOOTH, the same brush the vault masses now carry and for the
                // same finding: "the bands are dead plateaus, 97.8% of the lit crown sits at
                // gradient < 1; references run 0.8–50%". The reference (animation-04's cloud bank)
                // keeps 26% of its pixels under gradient 1 even after an 0.8 px blur, so the
                // structure is real, fine, and survives to 2–3 px — gouache on toothed paper.
                // It multiplies the wash's OWN colour rather than moving the ramp parameter, so it
                // varies value inside a band and never invents a boundary (a form-space version was
                // built first and came out as blue-on-cream confetti). The hue tilt makes a loaded
                // stroke warmer and a dry one cooler, which is the same warm-light/cool-shade law
                // the washes obey. Two octaves, each faded out analytically as it nears its own
                // Nyquist so a 60 m mass close in gets the tooth and an 18 m nub at 400 m drops it
                // rather than aliasing — the azimuth footprint is clamped because atan2's branch
                // cut makes fwidth() meaningless on the one seam meridian.
                // ROUND 7 — FEWER, LARGER, SOFTER MARKS. The round-6 critique of the cloud
                // interiors was that the incident reads as an ORDERED DITHER rather than as
                // painting, and on these masses it was literal: the azimuth of a lobe's normal
                // sweeps about pi radians across ~615 px of silhouette, so 34 turns put a feature
                // every 5.8 px and 78 turns every 2.5 px. Every frequency here drops to 0.4 of what
                // it was (a mark every ~14 px and ~6 px instead), the Nyquist fades drop with them
                // so the small masses still shed the fine octave rather than aliasing it, and the
                // amplitude goes 0.30 -> 0.42 because a bigger mark carries more paint. Measured on
                // the vault masses, which take the same change through the same brush: stroke blobs
                // 1.7 per 10k px at 311 px each -> 0.8 per 10k at 682 px.
                // ROUND 8 MOVES THE TOOTH AFTER THE LIGHT and gives it a coarse third octave — the
                // same two changes the vault masses take, for the same reasons. See §THE TOOTH GOES
                // ON LAST below, where it now runs.

                // -------------------------------------------------------------------------------
                // THE BASE, PAINTED. A cumulus base is dark because there is a great depth of cloud
                // standing on it — not because its surface points downward. Round 3 asked
                // saturate(−N.y) for this and got almost nothing: from any camera on the island the
                // only down-facing surface in view is the sliver of overhang at the waterline, so
                // the masses had no dark end and the row read as white dumplings on a white sheet.
                // Drawing it from the mass's own height is what a painter does, and it is what puts
                // a value anchor at the horizon.
                //
                // THICKNESS READS AS DARKNESS — the same rule the vault masses obey (SkyGradient
                // §THE DARK ANCHOR). The weight comes from the instance's own radius, so the big
                // near anchors carry the anchor and the 18 m scatter nubs stay light, with nothing
                // hand-flagged. It also survives instancing: the radius is in the transform.
                // -------------------------------------------------------------------------------
                float thick = saturate((lobeRadius - _LobeThinRadius)
                                       / max(_LobeThickRadius - _LobeThinRadius, 0.01));
                // The base gradient is measured from the WATERLINE (computed in Vert), not from the
                // mesh's bottom: everything below the deck plane is occluded by the deck and never
                // seen, so a ramp anchored to the mesh spends its whole dark end out of sight and
                // leaves the visible part of the mass uniformly pale — which is round 3 exactly.
                float rise = max(_LobeBaseRise, 0.01);
                float depth = pow(saturate((waterline + rise - lobeY) / rise),
                                  max(_LobeBasePower, 0.5));
                // The true overhang still counts for its own share: where the surface really does
                // face down it is darker than the painted gradient alone would make it.
                float under = saturate(-normalWS.y);
                float belly = saturate(depth * (1.0 + 0.45 * under)) * (1.0 - form * 0.30);
                color = lerp(color, _LobeUnder.rgb, saturate(belly * thick) * _LobeUnderDepth);

                // ROUND 7 — THE DISC, ON THE LIT WASHES ONLY. The same lighting rule the vault
                // masses now carry (SkyGradient.hlsl, the constants are shared from there so the
                // two rows of cloud cannot be lit by different suns), and it is the answer to the
                // round-6 finding that a near mass came back WARMER in its shadow than in its own
                // crown. That finding is really about the fog: exp-squared fog at density 0.0059
                // mixes a warm haze into everything at range, so no paint on this shader can make a
                // far shadow cool, and re-painting the washes to chase it (rounds 4 and 5 both
                // tried) only moves the whole mass. What CAN be fixed is the relationship, and the
                // relationship is a lighting one: warmth belongs where the form says the sun lands.
                // Squaring the ramp's upper half puts it on the crown, a little on the half-lit
                // body and none in the shade, and saturate(ndl) keeps the flank the disc faces the
                // gold one — so crown-minus-shadow R-B opens instead of the shadow being repainted.
                float litWash = saturate((form - _LobeMidPoint) / max(1.0 - _LobeMidPoint, 0.01));
                color += _SunGlowColor.rgb * (TARROCK_CLOUD_SUNWARM * litWash * litWash
                         * (TARROCK_CLOUD_SUNWARM_BASE
                            + (1.0 - TARROCK_CLOUD_SUNWARM_BASE) * saturate(ndl)));

                // WHAT THIS ROW DELIBERATELY DOES *NOT* TAKE FROM ROUND 8, and why it is a decision
                // rather than an oversight: the vault masses gain a DOME term this round
                // (SkyGradient.hlsl §TARROCK_CLOUD_SKYFILL — the sky's own light on the shaded
                // washes, which is the cool half of the law). Carried onto the near row as authored,
                // 1.20 × the sky's mid band is (0.160, 0.268, 0.627) linear against a shadow core
                // that is painted at (0.040, 0.058, 0.150): it would make these lobes' shade FOUR
                // TIMES lighter, and round 7's true dark on the near cloud sea is a protected win.
                // Making it fit means re-solving _LobeShade, _LobeMid and _LobeUnder against a
                // near-field mass seen through 30-70% fog, and that cannot be validated the way the
                // vault masses can — the offline model this round is solved against covers the
                // skybox, not the lobe meshes. It is the next round's work, with a capture to check
                // it against. Until then this row keeps its painted shade and shares only the light
                // it can be held to: the disc above, at a level the paint gives back exactly.

                // §THE TOOTH GOES ON LAST (round 8). It used to multiply the washes and then have
                // the disc's warmth added over the top, so wherever the light was strong the tooth
                // was diluted — a textured core inside a smooth outer slab, which is half of what
                // made the round-7 masses read as stacked cards. The tooth is the paper; everything
                // laid on the paper takes it. The third octave is the middle tier of structure the
                // round-7 critique measured missing (E16 3.2-5.8 against the board's 11.4-14.0),
                // and the amplitude goes 0.42 → 0.55 to pay for it.
                // ROUND 9 — and it is the SAME FOUR OCTAVES the crumple above is built from, which
                // is the whole point (see §ONE NOISE FAMILY). n0 carries the loaded stroke, n1 is
                // the mass's own tooth so a wash boundary and the paint inside it are made of one
                // mark, n2 is the fine cauliflower, and n3 — one octave finer than anything the
                // crumple uses — is the paper. The old brush's coarse octave sat at 4.5 against the
                // crumple's 3.4: close enough to beat against it, far enough that the two never
                // agreed on where a lobe was.
                float brush = n0 * 1.4 + n1 * toothWeight + n2 * fade2 + n3 * 0.6 * fade3;
                color = max(color * (1.0 + brush * 0.55 * float3(1.22, 1.02, 0.80)), 0.0);

                // -------------------------------------------------------------------------------
                // ROUND 9 — THE ACCENT, WHICH IS NOT A RIM. The round's third finding, and the
                // measurement behind it is unambiguous.
                //
                // What stood here was
                //     grazing = pow(saturate(1 - abs(dot(N, V))), 6);  color += glow*grazing*ndl*1.1
                // — a view-dependent term applied uniformly around the limb. dot(N, V) goes to zero
                // ALL THE WAY ROUND a closed mass, so that draws a band of constant angular width
                // round the entire silhouette and calls it a rim. Two independent critics measured
                // what that looks like from outside: a saturation halo (+0.018 of S in the 5-10 px
                // ring against the far field, where every blue-sky board plate runs NEGATIVE:
                // totoro −0.008, fable-06 −0.041, fable-08 −0.048), and a silhouette that scores
                // 13.7 on perimeter/√area against a board band of 21.5-65.1 — a mass with an even
                // outline and an even edge, which is a decal, not a cloud.
                //
                // A painted cloud's bright edge is where the FORM TURNS TOWARD THE SUN. So the
                // grazing term stays, but only to say WHERE a silhouette is; three things decide
                // whether it lights up there, and none of them is the camera:
                //
                //   * TURN. limbDir is the surface's outward direction projected into the picture
                //     plane — on the silhouette it is exactly the direction the outline is facing.
                //     sunPlane is the sun in that same plane. Their dot is +1 on the sunward quarter
                //     of the limb and negative on the anti-sun side, and the cube spends it fast, so
                //     the accent lives on the sun's flank of a mass and nowhere else. This is the
                //     term that makes the rim stop being constant-width: it is not width that varies
                //     round the limb, it is EXISTENCE.
                //   * WIDTH, from the mass's own cauliflower. Where the family's coarse octave
                //     bulges outward the accent broadens; where it bites in, the exponent triples
                //     and the accent narrows to nothing. Same field as the silhouette and the paint
                //     (§ONE NOISE FAMILY), so the accent is wide exactly on the lobes that are
                //     standing out into the light.
                //   * STROKE. The accent is broken into marks by the same family again, so it runs
                //     as a chain of catchlights along the sunward outline rather than as a ribbon
                //     round it. This is the "crisp accents against soft interiors" the board plates
                //     draw (fable-03's windmill cloud, animation-04's two banks) — the crispness is
                //     LOCAL, and everything between the accents is left soft.
                //
                // saturate(ndl + 0.25) rather than saturate(ndl): a cumulus limb keeps a little
                // light a few degrees past its own terminator, and with turn³ already gating the
                // azimuth, the hard N·L cut was cutting the accent twice on the same meridian.
                // -------------------------------------------------------------------------------
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - input.positionWS);
                float ndv = dot(normalWS, viewDirWS);
                float3 limbDir = normalize(normalWS - viewDirWS * ndv + 1e-5);
                float3 sunPlane = normalize(sunDirWS - viewDirWS * dot(sunDirWS, viewDirWS) + 1e-5);
                float turn = saturate(dot(limbDir, sunPlane));
                float width = max(_LobeRimPower, 1.0) * (1.0 + 2.2 * saturate(0.5 - 0.5 * crumple));
                float limb = pow(saturate(1.0 - abs(ndv)), width);
                float stroke = saturate(0.15 + 1.45 * (0.5 + 0.5 * (crumple + brush * 0.35)));
                float accent = limb * turn * turn * turn * stroke * saturate(ndl + 0.25);
                color += _SunGlowColor.rgb * accent * _LobeRim;

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
