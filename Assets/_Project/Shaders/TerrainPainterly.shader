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
    // Slope does the storytelling: flat ground takes the meadow ramp, steep ground takes stratified
    // rock, and the steepest takes the bare refusing face — so "cliffs refuse, slopes permit"
    // (swap rule 5) is legible in COLOUR as well as in shape, before a single prop is placed.
    //
    // ROUND-3 REWRITE (2026-07-31 gauntlet critique of round2/v1, v3, v5, v8). Round 2 fixed the
    // monochrome ground and the contour banding and then introduced two worse faults of its own.
    // Both are named here with the construct that caused them, because the next pass will be
    // tempted to reintroduce them:
    //
    //   a. THE WORM VEINS ("dark squiggles crawl across every slope"). Two separate constructs were
    //      drawing the LEVEL SET of a 2-D noise field, and the level set of a smooth 2-D field is a
    //      closed loop — a worm — every single time:
    //        * The strata. _StrataWander was 6.5 m against a _StrataScale of 3.4 m: a peak-to-peak
    //          swing of 1.9 BED THICKNESSES (±0.96 beds) at a 14 m wavelength. Along the bedding's
    //          own STRIKE direction the dipping plane term is constant BY DEFINITION, so along every
    //          such line the wander was the only thing moving `bedCoord` — and a ±0.96-bed swing
    //          crosses the parting again and again. The partings were therefore drawing the contours
    //          of the 14 m wander field, and `floor(bedCoord)` — which picks the bed's hue — became a
    //          random blotch map at 14 m, which is the SECOND fault below.
    //        * The crevices. `smoothstep(1-w-soft, 1-w+soft, 1-|2f-1|)` is by construction a band
    //          around the field's midpoint, i.e. again a level set. Measured, its mean coverage was
    //          0.102 — the old header's "roughly a tenth" was right about the AREA and wrong about
    //          why that was safe. Ten per cent of a surface arranged as scattered dots is texture;
    //          ten per cent arranged as a single connected curve is a drawing. `crackSoft` then
    //          smeared the curve's edge (the fraction of visibly-touched pixels rose from 0.132 at
    //          the camera to 0.206 at 60 m), which is why the worms got FATTER with distance instead
    //          of fading — the exact opposite of what a detail term should do.
    //      Round 3 deletes both. Bedding is now a gravity-aligned lattice in world Y (below), which
    //      cannot produce a closed loop because its level sets are horizontal planes. Concavity
    //      darkening is now a FILLED region (a blob below a threshold), not a band around a
    //      midpoint — the structural difference that stops it drawing lines.
    //
    //   b. THE TRANSPARENT CLIFF ("you can see the far hills through the near cliff"). There is no
    //      alpha anywhere in this material and there never was; the render state below is now
    //      explicit so that stays true. The read was caused by (a): the strata hue blotches and the
    //      crevice loops are WORLD-space triplanar fields, so a near cliff and the far hill behind it
    //      carry the same passage of pattern at the same phase and the same apparent scale. A pattern
    //      that runs continuously across a silhouette edge is the classic cue for "that surface is
    //      transparent", and the eye takes it every time. Killing the ghost pattern kills the ghost.
    //
    //   c. THE FACETS. Unity terrain hands this shader a Gouraud-interpolated vertex normal. The
    //      interpolation is C0 but not C1, so the ndotl gradient KINKS at every triangle edge and a
    //      7° sun makes each kink a visible Mach band — the terrain reads as triangles. The fix here
    //      is a per-pixel shading normal: the same mid-scale height field the cavity term uses is
    //      differentiated in screen space (Mikkelsen surface gradient) and perturbs the normal, so
    //      the shading has real high-frequency content of its own and the linear ramps stop being
    //      readable as ramps. NOTE for the next pass: this camouflages the kink rather than removing
    //      it. Removing it needs a genuine per-pixel normal off the heightmap, which means either
    //      Unity's `_TerrainNormalmapTexture` (only bound in instanced draw, which a non-splatmap
    //      material cannot use) or a normal texture baked by the generator from SampleHeight. That is
    //      a real asset and a real piece of machinery, so it is left as an explicit next step rather
    //      than smuggled in.
    //
    //   d. THE BROWN TURF. The mat under the meadow was built from `lerp(brown soil, ochre thatch)`,
    //      which is an out-of-family brown card sitting under green blades — round2/v3 reads as dirt
    //      with grass decals on it. The turf now lives in the GREEN family (damp root shadow to
    //      living blade green) and the ochre is kept as a SCOUR PATCH off its own field, in the top
    //      tail only, which is what "wind-scoured green" actually describes.
    //
    // Round 2's real win is kept: NO CONTOUR BANDING. It is kept structurally, not by luck. The only
    // world-Y construct on the surface is the bedding, and the bedding is gated off entirely below
    // ~35° of slope — because the contour ring was never caused by using world Y, it was caused by
    // drawing a WIDE SOFT band on GENTLE ground, where a horizontal slab meets the surface over an
    // enormous on-surface width and its edge necessarily traces a level set of the heightmap. On a
    // steep face the same horizontal slab cuts a thin near-straight line, which is what bedding
    // looks like in the world and on the reference board.
    //
    // The economy rule underneath all of it: fbm is smooth everywhere by construction, so an fbm
    // surface can only ever be airbrush. Painted-dab economy needs marks with EDGES — hence the
    // jittered-cell (Worley) fields, whose cells each take one flat tone, and the thin hard bedding
    // partings (visual pillar 2, woodcut linework) instead of wide soft bands.
    //
    // House style mirrored from Tarrock/FoliageWind: minimal URP, hand-rolled main-light lambert +
    // SH ambient (NOT the full URP/Lit include, which has rendered unreliably on this box for our
    // runtime-built materials), SRP-Batcher-compatible CBUFFER.
    Properties
    {
        [Header(Meadow hues)]
        // FOUR hues, deliberately spread around the wheel rather than one hue at two brightnesses:
        // wind-scoured green (the Cliff's canon ground colour, art-audio.md §Region color scripts),
        // warm straw, brown scuff where the turf has worn through, and a cool blue-grey note for
        // sheltered ground. That spread is what fable-05/08 have and round 1 did not.
        // The plateau's GOLD still lives in the LIGHT, not the albedo (director call 2026-07-26) —
        // the straw here is dry grass, not a brightness ramp toward white.
        _MeadowGreen ("Meadow - wind-scoured green", Color) = (0.28, 0.36, 0.20, 1)
        _MeadowStraw ("Meadow - warm straw", Color) = (0.66, 0.58, 0.31, 1)
        _MeadowScuff ("Meadow - bare-earth scuff", Color) = (0.42, 0.32, 0.21, 1)
        _MeadowCool ("Meadow - cool sheltered", Color) = (0.27, 0.35, 0.36, 1)

        [Header(Meadow fields)]
        // Three decorrelated frequency bands with three different JOBS. MACRO drifts field to
        // field (the 40 m read). The DAB band is the one the player reads at the 4-6 m gameplay
        // camera and it is a jittered-cell mosaic, so it has edges. FINE is texel-scale tooth,
        // distance-faded so it can never alias into shimmer at range.
        _MeadowMacroScale ("Meadow Macro Scale (m)", Float) = 38.0
        _MeadowHueScale ("Meadow Hue Field Scale (m)", Float) = 21.0
        _MeadowDabScale ("Meadow Dab Scale (m)", Float) = 6.0
        _MeadowFineScale ("Meadow Fine Dab Scale (m)", Float) = 0.95
        _MeadowGrainScale ("Meadow Grain Scale (m)", Float) = 0.34
        _MeadowDabWarp ("Meadow Dab Warp", Range(0,1.5)) = 0.55
        _MeadowDabEdge ("Meadow Dab Edge Darken", Range(0,0.4)) = 0.10
        _MeadowStrawAmount ("Meadow Straw Amount", Range(0,2)) = 0.85
        _MeadowScuffAmount ("Meadow Scuff Amount", Range(0,2)) = 0.55
        _MeadowCoolAmount ("Meadow Cool Amount", Range(0,2)) = 0.70
        _MeadowFineTone ("Meadow Fine Dab Tone", Range(0,0.5)) = 0.16
        _MeadowFineStraw ("Meadow Fine Straw Flecks", Range(0,1)) = 0.28
        _MeadowGrain ("Meadow Micro Grain", Range(0,0.4)) = 0.13
        _DetailFadeStart ("Detail Fade Start (m)", Float) = 10.0
        _DetailFadeRange ("Detail Fade Range (m)", Float) = 28.0

        [Header(Turf under the tuft fields)]
        // The layer the grass grows OUT of, and therefore a GREEN-family layer: damp root shadow
        // between the blades, living blade green at the dab centres. Its mask is the SAME band the
        // terrain detail-density map uses (steepness / height / patch noise) — the generator feeds
        // both from one set of constants — but FEATHERED, which is the fix for round 1's hard
        // "grass stops here" line. The ochre is a SCOUR patch, not half of the base ramp.
        _TurfSoil ("Turf - damp root shadow", Color) = (0.17, 0.20, 0.13, 1)
        _TurfBlade ("Turf - living blade mat", Color) = (0.25, 0.33, 0.19, 1)
        _TurfOchre ("Turf - dry ochre scour", Color) = (0.50, 0.42, 0.23, 1)
        _TurfScale ("Turf Mottle Scale (m)", Float) = 2.8
        _TurfAmount ("Turf Amount", Range(0,1)) = 0.78
        _TurfContact ("Turf Contact Shade", Range(0,0.5)) = 0.20
        _TurfScourScale ("Turf Scour Patch Scale (m)", Float) = 9.5
        _TurfScourAmount ("Turf Scour Amount", Range(0,1)) = 0.85
        _TurfPatchScale ("Turf Patch Scale (m)", Float) = 22.2
        _TurfSteepMax ("Turf - steepness limit (deg)", Float) = 24.0
        _TurfFeatherDeg ("Turf - steepness feather (deg)", Float) = 8.0
        _TurfHeightLow ("Turf - lowest height (m)", Float) = 13.0
        _TurfHeightHigh ("Turf - highest height (m)", Float) = 52.0
        _TurfFeatherM ("Turf - height feather (m)", Float) = 6.0

        [Header(Stone)]
        // Warm grey against cooler grey, formation by formation, with sage lichen as the third hue.
        // Grey on grey is what made round 1's rock read as an extension of the meadow gradient.
        _RockWarm ("Rock - warm bed", Color) = (0.56, 0.51, 0.42, 1)
        _RockCool ("Rock - cool bed", Color) = (0.40, 0.41, 0.45, 1)
        _RockLichen ("Rock - lichen", Color) = (0.35, 0.40, 0.26, 1)
        _CliffColor ("Cliff - refusing face", Color) = (0.30, 0.31, 0.35, 1)
        _RockMottleScale ("Rock Mottle Scale (m)", Float) = 6.5
        _RockBedTint ("Rock Formation Hue Swing", Range(0,1)) = 0.55
        _RockLichenAmount ("Rock Lichen Amount", Range(0,1)) = 0.40

        [Header(Bedding)]
        // GRAVITY-ALIGNED. Sediment is laid down flat, so the band coordinate is world Y with only a
        // few degrees of dip — _BeddingDip is an XZ gradient, and at 0.06 it is a 3.4° dip, enough
        // that the beds are not a spirit-level ruling and far too little to wander into the level
        // sets of anything. The warp is likewise CAPPED to a fraction of a bed inside the shader:
        // that cap is the whole lesson of round 2's worms and it is not a tuning value.
        //
        // Measured at these defaults over 600k samples of the region's own coordinate range: the
        // warp swings 0.21 of a bed (round 2's strata swung 1.91), partings are 0.10–0.35 m thick on
        // a 2.6 m bed, they cover 0.117 of a steep face, the sunlit lip covers 0.076, and the whole
        // construct holds full strength out past 250 m before the AA fade takes it. "Marks, not a
        // bruise" is a measurement here, not a hope.
        _BeddingSpacing ("Bedding - mean bed thickness (m)", Float) = 2.6
        _BeddingDip ("Bedding - dip gradient (XZ)", Vector) = (0.060, 0.0, -0.045, 0)
        _BeddingWarp ("Bedding - warp (m, capped to 0.30 bed)", Float) = 0.55
        _BeddingRough ("Bedding - edge roughness (m, capped to 0.12 bed)", Float) = 0.22
        _BeddingLineWidth ("Bedding - parting half width (bed fraction)", Range(0.01,0.3)) = 0.085
        _BeddingWidthJitter ("Bedding - per-bed thickness jitter", Range(0,0.9)) = 0.60
        _BeddingDarken ("Bedding - parting darken", Range(0,1)) = 0.36
        _BeddingLip ("Bedding - sunlit lip", Range(0,1)) = 0.20
        _BedValueJitter ("Bedding - per-bed value jitter", Range(0,0.4)) = 0.09
        _BedFormRate ("Bedding - formations per bed", Range(0.05,1)) = 0.34
        // Below this slope a horizontal bed meets the ground over an enormous on-surface width and
        // its edge has no choice but to trace a heightmap contour — which is exactly the round-1
        // ring. Above it the same bed cuts a thin near-straight line across the face.
        _BeddingSlopeStart ("Bedding - slope fade in (deg)", Float) = 35.0
        _BeddingSlopeEnd ("Bedding - slope full (deg)", Float) = 48.0

        [Header(Cavity)]
        // Concavity darkening, AO-like and DELIBERATELY SEPARATE from any line drawing: it is the
        // FILLED region where the fine relief sits below the broad form, not a band around a field's
        // midpoint. A filled region is a blob; a band around a midpoint is a contour line. Round 2
        // used the second and got worms.
        _CavityScale ("Cavity Scale (m)", Float) = 3.4
        _CavityContrast ("Cavity Contrast", Range(0.5,10)) = 4.5
        _CavityDarken ("Cavity Darken - stone", Range(0,1)) = 0.34
        _CavityGroundDarken ("Cavity Darken - meadow", Range(0,1)) = 0.16

        [Header(Shading normal)]
        // Per-pixel shading normal off the cavity height field (see header note c). Faded out with
        // distance: past the fade the terrain is small enough that the facet kink is sub-pixel
        // anyway, and an unfaded high-frequency normal at range is a shimmer generator.
        _NormalDetailHeight ("Shading Normal - relief (m)", Float) = 0.30
        _NormalDetailStrength ("Shading Normal - strength", Range(0,3)) = 1.0
        _NormalDetailFadeStart ("Shading Normal - fade start (m)", Float) = 45.0
        _NormalDetailFadeRange ("Shading Normal - fade range (m)", Float) = 55.0

        [Header(Slope blending)]
        // Steepness = 1 - N.y. Rock takes over from about 35° (0.18) and owns the surface by 50°
        // (0.36); the refusing face begins at 60° (0.50). Keep these in loose sympathy with the
        // CharacterController's slope limit so what LOOKS unclimbable IS unclimbable — the grammar
        // lies to the player otherwise.
        _SlopeStart ("Slope - meadow ends", Range(0,1)) = 0.18
        _SlopeEnd ("Slope - rock owns it", Range(0,1)) = 0.36
        _CliffStart ("Slope - refusing face begins", Range(0,1)) = 0.50
        _CliffEnd ("Slope - refusing face owns it", Range(0,1)) = 0.72
        _SlopeJitter ("Slope Boundary Jitter", Range(0,0.4)) = 0.13
        _BlendFieldScale ("Blend Field Scale (m)", Float) = 14.0

        [Header(Height)]
        // A gentle lift only — the high ground is drier and more wind-scoured, not brighter.
        _HeightLow ("Height - low (world Y)", Float) = 8.0
        _HeightHigh ("Height - high (world Y)", Float) = 48.0

        [Header(Shading)]
        // Wrapped lambert — soft storybook falloff rather than a hard terminator (Visual pillar 1).
        // Raised from round 2's 0.30: wrapping compresses the ndotl gradient, and a compressed
        // gradient is a smaller step across a facet edge, so this is half of the facet fix and it
        // costs nothing.
        _ShadeWrap ("Shade Wrap", Range(0,1)) = 0.40
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
            // The ground is never a projector receiver — nothing in this region projects, and the
            // tag rules out the one remaining way an overlay could reach this surface.
            "IgnoreProjector" = "True"
            // Terrain renders with a plain material here (no splatmap control textures), so it is
            // deliberately NOT tagged "TerrainCompatible" — Unity's splat painting is unused by design.
        }
        LOD 200

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _MeadowGreen;
            float4 _MeadowStraw;
            float4 _MeadowScuff;
            float4 _MeadowCool;
            float _MeadowMacroScale;
            float _MeadowHueScale;
            float _MeadowDabScale;
            float _MeadowFineScale;
            float _MeadowGrainScale;
            float _MeadowDabWarp;
            float _MeadowDabEdge;
            float _MeadowStrawAmount;
            float _MeadowScuffAmount;
            float _MeadowCoolAmount;
            float _MeadowFineTone;
            float _MeadowFineStraw;
            float _MeadowGrain;
            float _DetailFadeStart;
            float _DetailFadeRange;
            float4 _TurfSoil;
            float4 _TurfBlade;
            float4 _TurfOchre;
            float _TurfScale;
            float _TurfAmount;
            float _TurfContact;
            float _TurfScourScale;
            float _TurfScourAmount;
            float _TurfPatchScale;
            float _TurfSteepMax;
            float _TurfFeatherDeg;
            float _TurfHeightLow;
            float _TurfHeightHigh;
            float _TurfFeatherM;
            float4 _RockWarm;
            float4 _RockCool;
            float4 _RockLichen;
            float4 _CliffColor;
            float _RockMottleScale;
            float _RockBedTint;
            float _RockLichenAmount;
            float _BeddingSpacing;
            float4 _BeddingDip;
            float _BeddingWarp;
            float _BeddingRough;
            float _BeddingLineWidth;
            float _BeddingWidthJitter;
            float _BeddingDarken;
            float _BeddingLip;
            float _BedValueJitter;
            float _BedFormRate;
            float _BeddingSlopeStart;
            float _BeddingSlopeEnd;
            float _CavityScale;
            float _CavityContrast;
            float _CavityDarken;
            float _CavityGroundDarken;
            float _NormalDetailHeight;
            float _NormalDetailStrength;
            float _NormalDetailFadeStart;
            float _NormalDetailFadeRange;
            float _SlopeStart;
            float _SlopeEnd;
            float _CliffStart;
            float _CliffEnd;
            float _SlopeJitter;
            float _BlendFieldScale;
            float _HeightLow;
            float _HeightHigh;
            float _ShadeWrap;
            float _AmbientBoost;
            float4 _ShadowTint;
            float4 _AmbientFloor;
        CBUFFER_END

        // -- Hashes -----------------------------------------------------------------------------
        // Hash-based so the surface is deterministic in world space: the same metre of ground gets
        // the same mottling every run, and re-generating a region cannot reshuffle its look.
        float TkHash21(float2 p)
        {
            p = frac(p * float2(123.34, 456.21));
            p += dot(p, p + 45.32);
            return frac(p.x * p.y);
        }

        // Two-channel hash for the jittered-cell fields: .xy is the cell's jitter offset, and it
        // doubles as the cell's own identity (see TkDab). Deliberately NOT sin-based — sin of a
        // large argument loses precision differently per GPU, and this surface must be identical
        // between the capture rig and the editor.
        float2 TkHash22(float2 p)
        {
            float3 p3 = frac(p.xyx * float3(0.1031, 0.1030, 0.0973));
            p3 += dot(p3, p3.yzx + 33.33);
            return frac((p3.xx + p3.yz) * p3.zy);
        }

        // -- Value noise ------------------------------------------------------------------------
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

        // Both fbm variants are RENORMALISED to a full 0..1 range with a 0.5 mean, so a threshold
        // written against one reads the same against the other and the mix amounts below are
        // comparable. (Round 1's raw 3-octave sum had a 0.4375 mean, which is where every one of
        // its magic 0.4375 constants came from.)
        //
        // NOTE: these stay VALUE noise deliberately — for a colour field the lattice fold lines are
        // invisible (the 2026-07-26 audit measured them below perceptual threshold in albedo) and
        // value noise is cheaper per pixel. The GEOMETRY noise in TerrainRegionGenerator switched to
        // gradient noise because there the folds cast shadows; the "surface and shading agree"
        // pairing is therefore approximate, not exact, by design.
        //
        // Per-octave lacunarity is non-integer and each octave is offset, so octaves never share a
        // feature at the origin and no octave alignment is visible.
        float TkFbm2(float2 p)
        {
            float sum = TkValueNoise(p) * 0.5;
            p = p * 2.03 + 17.3;
            sum += TkValueNoise(p) * 0.25;
            return sum / 0.75;
        }

        float TkFbm3(float2 p)
        {
            float sum = TkValueNoise(p) * 0.5;
            p = p * 2.03 + 17.3;
            sum += TkValueNoise(p) * 0.25;
            p = p * 2.03 + 17.3;
            sum += TkValueNoise(p) * 0.125;
            return sum / 0.875;
        }

        // -- The cavity / relief pair -------------------------------------------------------------
        // .x is the BROAD form and .y is the same form with one finer octave folded in, weighted so
        // BOTH have a mean of 0.5. Their difference is therefore a mean-zero signal that is positive
        // exactly where the fine relief dips below the broad form — a HOLLOW. Thresholding that gives
        // a FILLED blob (light failed to arrive in this dip), which is what an AO term should be.
        //
        // This is the single structural lesson of the round-2 worms. `1 - |2f - 1|` thresholded near
        // 1 also "finds dark places", but it finds the set where f ≈ 0.5, and the set where a smooth
        // 2-D field equals a constant is a CLOSED CURVE. Any construct of that shape draws worms, no
        // matter what it is called. A cavity term must select a REGION, never a level set.
        //
        // .y doubles as the shading-normal relief field, which is why it is two octaves and not one:
        // the facet kink it has to hide lives at metres, and one octave at _CavityScale plus one at
        // ~1/2.7 of it covers that band without paying for a third tap per projection.
        float2 TkCavityPair(float2 p)
        {
            float broad = TkValueNoise(p);
            float fine = TkValueNoise(p * 2.71 + 19.7);
            return float2(broad, broad * 0.68 + fine * 0.32);
        }

        // Triplanar so cliff faces get mottling too — a planar-only projection smears to stripes on
        // anything near-vertical, which is exactly where the refusing cliffs are. The meadow fields
        // below are deliberately PLANAR: meadow only exists on near-flat ground, so paying three
        // projections for it bought nothing but cost two thirds of the ground's noise budget.
        float2 TkTriplanarCavityPair(float3 worldPos, float3 normal, float scaleMetres)
        {
            float3 blend = pow(abs(normal), 4.0);
            blend /= max(blend.x + blend.y + blend.z, 1e-4);
            float inv = 1.0 / max(scaleMetres, 0.01);
            return TkCavityPair(worldPos.zy * inv) * blend.x
                 + TkCavityPair(worldPos.xz * inv) * blend.y
                 + TkCavityPair(worldPos.xy * inv) * blend.z;
        }

        float TkTriplanarFbm2(float3 worldPos, float3 normal, float scaleMetres)
        {
            float3 blend = pow(abs(normal), 4.0);
            blend /= max(blend.x + blend.y + blend.z, 1e-4);
            float inv = 1.0 / max(scaleMetres, 0.01);
            return TkFbm2(worldPos.zy * inv) * blend.x
                 + TkFbm2(worldPos.xz * inv) * blend.y
                 + TkFbm2(worldPos.xy * inv) * blend.z;
        }

        // -- Painted dabs -----------------------------------------------------------------------
        // Jittered-cell (Worley) field. Returns .x = distance to the nearest dab centre and
        // .y = that dab's OWN random tone. The tone is the point of the whole construct: every
        // cell takes one flat value, so the ground reads as marks laid side by side, with edges
        // between them. No amount of fbm can do that — fbm is C1 smooth by construction, which is
        // exactly why round 1's meadow measured as an airbrush.
        float2 TkDab(float2 p)
        {
            float2 cell = floor(p);
            float2 f = p - cell;
            float best = 8.0;
            float bestTone = 0.0;

            [unroll]
            for (int y = -1; y <= 1; y++)
            {
                [unroll]
                for (int x = -1; x <= 1; x++)
                {
                    float2 g = float2(x, y);
                    float2 h = TkHash22(cell + g);
                    float2 d = g + h - f;
                    float sq = dot(d, d);
                    bestTone = sq < best ? frac(h.x * 3.71 + h.y * 7.13) : bestTone;
                    best = min(best, sq);
                }
            }

            return float2(saturate(sqrt(best)), bestTone);
        }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            // STRICTLY OPAQUE, stated rather than inherited. The round-2 critique read the near
            // cliff as a semi-transparent sheet; the cause was pattern continuity across silhouette
            // edges (see header note b) and not blending, but "the material cannot possibly be
            // blending" should be a fact anyone can check in four lines instead of an argument from
            // absent syntax. It also survives a stale .mat, which the shader defaults do not.
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
                // The GEOMETRIC normal. Every classification decision — which layer, how steep, how
                // to blend the triplanar projections — is taken off this one, so layer boundaries
                // stay as stable as the landform. Only the LIGHTING uses the perturbed normal below.
                float3 normalWS = normalize(input.normalWS);

                // Mantissa guard, applied in WORLD space BEFORE any division by a scale. The hash
                // does frac(big * 123.34); past ~57000 there is no mantissa left and the noise goes
                // blocky. Round 1 wrapped the already-divided coordinate instead, which put a hard
                // seam wherever a scale was fine enough to push the divided coordinate past 512 —
                // at the 0.34 m grain scale that is a visible line every 174 m.
                float3 gp3 = fmod(positionWS, 512.0);
                float2 gp = gp3.xz;

                float camDist = distance(positionWS, _WorldSpaceCameraPos);
                float heightT = saturate((positionWS.y - _HeightLow)
                    / max(_HeightHigh - _HeightLow, 0.01));
                float steepDeg = degrees(acos(saturate(normalWS.y)));

                // -- Everything that needs a SCREEN DERIVATIVE is computed here, at the top, outside
                //    every branch. ddx/ddy inside non-uniform flow control is undefined — the quad's
                //    other three lanes may have taken the other branch — and the two UNITY_BRANCHes
                //    below are as non-uniform as flow control gets (they straddle the meadow/rock
                //    boundary along its entire length).
                float3 dpdx = ddx(positionWS);
                float3 dpdy = ddy(positionWS);
                // World metres of Y crossed per pixel. This is the bedding lattice's screen
                // footprint directly, because the lattice IS world Y (the dip and the capped warp
                // move it by well under a bed).
                float pixelY = max(fwidth(positionWS.y), 1e-5);

                // -- Cavity + relief, shared by both layers and by the shading normal --------------
                // One field, three jobs: hollows darken, the same hollows are where lichen takes,
                // and its gradient is the per-pixel shading relief that hides the facet kink.
                float2 relief = TkTriplanarCavityPair(gp3, normalWS, _CavityScale);
                float detailFade = 1.0 - saturate((camDist - _DetailFadeStart)
                    / max(_DetailFadeRange, 0.01));
                float cavityFade = 1.0 - saturate((camDist - _DetailFadeStart * 3.0)
                    / max(_DetailFadeRange * 3.0, 0.01));
                float cavity = saturate((relief.x - relief.y) * _CavityContrast)
                    * lerp(0.35, 1.0, cavityFade);

                // -- Per-pixel shading normal (header note c) --------------------------------------
                // Mikkelsen surface gradient: differentiate the relief height in screen space and
                // project it back onto the surface through the two tangent bivectors. No tangent
                // frame, no UVs, no extra noise taps — the height is already in hand.
                float reliefH = (relief.y - 0.5) * _NormalDetailHeight;
                float3 r1 = cross(dpdy, normalWS);
                float3 r2 = cross(normalWS, dpdx);
                float det = dot(dpdx, r1);
                // det is the pixel's world footprint area and legitimately goes to ~1e-6 under the
                // Fool's feet, so the guard has to be tiny; the numerator shrinks with it, which is
                // why the RATIO stays sane. What is not sane is a grazing pixel where det collapses
                // faster than the numerator, so the perturbation is length-clamped below rather than
                // trusted — an unclamped surface gradient there flips the normal and puts a black
                // speckle on every silhouette.
                float3 surfGrad = sign(det) * (ddx(reliefH) * r1 + ddy(reliefH) * r2)
                    / max(abs(det), 1e-8);
                float normalFade = 1.0 - saturate((camDist - _NormalDetailFadeStart)
                    / max(_NormalDetailFadeRange, 0.01));
                float3 delta = surfGrad * (_NormalDetailStrength * normalFade);
                delta -= normalWS * dot(delta, normalWS);            // tangential only
                delta /= max(1.0, length(delta) / 0.85);             // never tilt past ~40°
                float3 shadingNormalWS = normalize(normalWS - delta);

                // One shared mid-scale field, used four times over: it jitters the meadow/rock
                // boundary into a ragged natural edge, warps the bedding, picks where lichen has
                // taken, and drifts the turf scour. Computing it once outside both branches is what
                // pays for the richer per-layer work below.
                float blendField = TkTriplanarFbm2(gp3, normalWS, _BlendFieldScale);

                float steepness = 1.0 - saturate(normalWS.y);
                float jitter = (blendField - 0.5) * _SlopeJitter;
                float rockT = smoothstep(_SlopeStart, _SlopeEnd, steepness + jitter);
                float cliffT = smoothstep(_CliffStart, _CliffEnd, steepness + jitter * 0.6);

                float3 ground = _MeadowGreen.rgb;
                float3 stone = _RockWarm.rgb;

                // -- Meadow + turf --------------------------------------------------------------
                UNITY_BRANCH
                if (rockT < 0.999)
                {
                    float macro = TkFbm3(gp / max(_MeadowMacroScale, 0.01));
                    float hue = TkFbm2((gp + 173.0) / max(_MeadowHueScale, 0.01));

                    // The dab lattice is domain-warped by the two low-frequency fields, so dabs are
                    // irregular organic marks rather than a Voronoi mosaic that reads as cracked mud.
                    float2 warp = float2(macro - 0.5, hue - 0.5) * _MeadowDabWarp;
                    float2 dab = TkDab(gp / max(_MeadowDabScale, 0.01) + warp);
                    float dabTone = dab.y;
                    float dabEdge = smoothstep(0.45, 0.92, dab.x);

                    // Three selectors off three decorrelated sources. Scuff is applied LAST because
                    // bare earth is the strongest read on the ground and should win where it shows.
                    // Height feeds only the straw: the high ground is drier and more wind-scoured,
                    // not brighter (the gold is in the light, not the albedo).
                    //
                    // The thresholds are set against the fields' actual distributions (both fbms
                    // are renormalised, mean 0.5, sigma ≈ 0.14): green is the meadow's ground state
                    // and every other hue enters as PATCHES off a tail — straw over roughly a third
                    // of the ground, cool in the sheltered dips, scuff only in the top tail, which
                    // is the balance "wind-scoured green" asks for. A threshold at the mean would
                    // paint half the meadow that colour and lose the region's palette.
                    float strawT = saturate((hue - 0.50) * _MeadowStrawAmount * 3.4
                        + (dabTone - 0.55) * 0.8 + heightT * 0.18);
                    float scuffT = saturate((macro - 0.66) * _MeadowScuffAmount * 5.0
                        + (dabTone - 0.64) * 0.8);
                    float coolT = saturate((0.44 - macro) * _MeadowCoolAmount * 4.0
                        + (0.5 - dabTone) * 0.6);

                    ground = lerp(ground, _MeadowCool.rgb, coolT);
                    ground = lerp(ground, _MeadowStraw.rgb, strawT);
                    ground = lerp(ground, _MeadowScuff.rgb, scuffT);
                    ground *= 1.0 - dabEdge * _MeadowDabEdge;   // the visible edge of each mark

                    // Turf mask = the detail-density band, feathered. The steepness and height
                    // thresholds are the SAME constants BuildGrassDetails scatters tufts with (the
                    // generator writes both from one place), so ground colour and tuft coverage
                    // cannot drift apart; the feather is what dissolves round 1's hard
                    // grass-stops-here line.
                    // The patch term is a same-WAVELENGTH stand-in, not the same field: the density
                    // map's clumping noise is the generator's five-octave gradient fbm, and porting
                    // it here would cost twenty sin/cos pairs a pixel to make two soft fields agree
                    // where they do not need to. It only modulates turf strength between 0.45 and 1
                    // in any case — thinner grass does not stop the ground being ground.
                    float bandSteep = 1.0 - smoothstep(_TurfSteepMax - _TurfFeatherDeg,
                        _TurfSteepMax + _TurfFeatherDeg, steepDeg);
                    float bandHeight =
                        smoothstep(_TurfHeightLow - _TurfFeatherM,
                                   _TurfHeightLow + _TurfFeatherM, positionWS.y)
                        * smoothstep(_TurfHeightHigh + _TurfFeatherM,
                                     _TurfHeightHigh - _TurfFeatherM, positionWS.y);
                    float patch = TkFbm2((gp + 61.0) / max(_TurfPatchScale, 0.01));
                    float turfMask = bandSteep * bandHeight * lerp(0.45, 1.0,
                        smoothstep(0.34, 0.66, patch));

                    // THE TURF IS GREEN (header note d). It is the mat the blades come out of, so
                    // its two poles are damp root shadow and living blade green — a brown card under
                    // green blades is what made round2/v3 read as dirt with grass decals on it. The
                    // dab centres keep the meadow's own green so the mat and the meadow are the same
                    // plant seen at two densities.
                    float2 turfDab = TkDab(gp / max(_TurfScale, 0.01) + warp * 0.6);
                    float3 turf = lerp(_TurfSoil.rgb, _TurfBlade.rgb,
                        saturate(turfDab.y * 1.20 - 0.05));
                    turf = lerp(turf, _MeadowGreen.rgb, saturate((1.0 - turfDab.x) * 0.55));

                    // The ochre SCOUR survives, as the patch it always should have been: dry thatch
                    // where the wind has worn the mat through. Off its own field and thresholded in
                    // the TOP TAIL, so it is a scatter of bald patches across a green mat rather
                    // than half of the base ramp. (Against sigma ≈ 0.14 a 0.58 threshold takes
                    // roughly a quarter of the turf and 0.86 takes almost none — the smoothstep
                    // between them is the patch and its soft edge.)
                    float scourField = TkFbm2((gp + 311.0) / max(_TurfScourScale, 0.01));
                    float scour = smoothstep(0.58, 0.86, scourField + (dabTone - 0.5) * 0.25);
                    turf = lerp(turf, _TurfOchre.rgb, scour * _TurfScourAmount);

                    ground = lerp(ground, turf, turfMask * _TurfAmount);
                    // Contact shade — light does not reach the floor of a dense tuft field. More
                    // than any colour, this is what stops the tufts reading as decals on lino.
                    ground *= 1.0 - turfMask * _TurfContact;

                    UNITY_BRANCH
                    if (detailFade > 0.004)
                    {
                        float2 fine = TkDab(gp / max(_MeadowFineScale, 0.01));
                        float grain = TkValueNoise(gp / max(_MeadowGrainScale, 0.01));
                        float tooth = 1.0 + (fine.y - 0.5) * 2.0 * _MeadowFineTone
                            + (grain - 0.5) * _MeadowGrain;
                        ground *= lerp(1.0, tooth, detailFade);

                        // Dab CORES take a straw fleck — dry strands and grit read as hue at texel
                        // scale, not as one more brightness wobble. Suppressed inside the turf,
                        // where the ground is damp and shaded by the blades above it.
                        float fleck = smoothstep(0.78, 0.97, 1.0 - fine.x);
                        ground = lerp(ground, _MeadowStraw.rgb,
                            fleck * _MeadowFineStraw * detailFade * (1.0 - turfMask * 0.6));
                    }

                    // Hollows in the mat, mildly — the meadow is soft and its dips hold shade.
                    ground *= 1.0 - cavity * _CavityGroundDarken;
                }

                // -- Stone ----------------------------------------------------------------------
                UNITY_BRANCH
                if (rockT > 0.001)
                {
                    float mottle = TkTriplanarFbm2(gp3, normalWS, _RockMottleScale);

                    // -- Bedding, gravity-aligned -------------------------------------------------
                    // Only on faces steep enough for a horizontal bed to cut a thin line across
                    // them. Below the fade-in a horizontal slab meets the ground over an enormous
                    // on-surface width and its edge has no choice but to trace a heightmap contour;
                    // that is round 1's ring, and slope is the honest gate against it.
                    float beddingMask = smoothstep(_BeddingSlopeStart, _BeddingSlopeEnd, steepDeg);

                    float spacing = max(_BeddingSpacing, 0.05);
                    // The warp and the edge roughness are CAPPED as fractions of a bed. This is the
                    // one line that stops the worms coming back: once the warp exceeds about half a
                    // bed, the lattice stops being world Y and becomes the warp field, and the
                    // partings become that field's level sets — closed loops. Round 2 ran at 1.9
                    // beds. The cap is structural, not a taste setting.
                    float warpM = min(abs(_BeddingWarp), spacing * 0.30);
                    float roughM = min(abs(_BeddingRough), spacing * 0.12);
                    // Both fields are already in hand: blendField (14 m) gives the gentle undulation
                    // along the face, mottle (6.5 m) roughs the parting's own edge so it is a drawn
                    // line and not a wire.
                    float bedRaw = (gp3.y
                        + _BeddingDip.x * gp3.x + _BeddingDip.z * gp3.z
                        + (blendField - 0.5) * 2.0 * warpM
                        + (mottle - 0.5) * 2.0 * roughM) / spacing;

                    float bedIndex = floor(bedRaw);
                    float f = bedRaw - bedIndex;

                    // Per-bed jitter off the bed's own index: WHERE the parting sits inside the bed
                    // and how thick that parting is. A stack of unequal beds is a rock face; an
                    // evenly ruled one is a barcode. Three decorrelated channels, because tying
                    // thickness to value would make every thin bed a dark bed.
                    float2 bedHash = TkHash22(float2(bedIndex, 3.7));
                    float bedTone = TkHash21(float2(bedIndex * 0.71 + 4.3, 9.1));
                    float partAt = lerp(0.12, 0.88, bedHash.x);
                    float halfW = _BeddingLineWidth
                        * lerp(1.0 - _BeddingWidthJitter, 1.0 + _BeddingWidthJitter, bedHash.y);

                    // Analytic anti-aliasing off the lattice's own screen footprint, replacing round
                    // 2's camDist fudge. Two separate jobs, and conflating them is what silted the
                    // far hills up with dark: the SOFTNESS grows so a mark never falls under a pixel
                    // and crawls, and the STRENGTH fades to nothing once a whole bed is thinner than
                    // about two and a half pixels, because past that point the beds are no longer
                    // resolvable and drawing them can only add noise.
                    float bedAA = pixelY / spacing;
                    float w = max(halfW, bedAA * 0.80);
                    float aaFade = 1.0 - smoothstep(0.125, 0.40, bedAA);

                    float d = abs(f - partAt);
                    float parting = 1.0 - smoothstep(w * 0.30, w, d);

                    // The sunlit lip: the top face of the bed BELOW the parting. At a 7° dawn sun a
                    // near-horizontal ledge top is the brightest thing on a cliff, and it is the
                    // mark that makes a bed read as a STEP rather than as a stripe.
                    // It is deliberately CLIPPED at the bed boundary rather than wrapped into the
                    // cell below: the cell below has its own partAt, and reaching across for it
                    // would make the lip's length depend on two beds at once. A short lip under a
                    // low parting is a lip; a lip that changes length for reasons the surface cannot
                    // show is a bug waiting to be re-diagnosed.
                    float lipD = partAt - f;
                    float lip = saturate(1.0 - lipD / max(w * 2.6, 1e-5))
                              * saturate(lipD / max(w * 0.9, 1e-5));

                    float lineAmount = beddingMask * aaFade;

                    // Hue changes by FORMATION, not by bed: a formation is a stack of partings that
                    // share a colour, and swapping hue at every parting reads as a barcode. At the
                    // default rate the colour turns over roughly every three beds.
                    float formIndex = floor(bedRaw * _BedFormRate);
                    float formRand = TkHash21(float2(formIndex, formIndex * 0.37 + 11.0));

                    stone = lerp(_RockWarm.rgb, _RockCool.rgb,
                        saturate(formRand * 1.35 - 0.18) * _RockBedTint * beddingMask);
                    stone *= lerp(0.88, 1.12, mottle);
                    stone *= 1.0 + (bedTone - 0.5) * 2.0 * _BedValueJitter * beddingMask;
                    stone *= 1.0 - parting * _BeddingDarken * lineAmount;
                    stone *= 1.0 + lip * _BeddingLip * lineAmount;

                    // Concavity, as its OWN term (see TkCavityPair). Nothing above writes into it and
                    // it writes into nothing above: the bedding can be turned off and the rock still
                    // has hollows, which is the test that the two are actually separate.
                    stone *= 1.0 - cavity * _CavityDarken;

                    // Lichen takes in the damp: the darker mottle patches, the up-facing ledges,
                    // and the hollows. Third stone hue, and the reason the rock is not grey on grey.
                    float lichen = saturate((0.60 - mottle) * 3.2)
                        * saturate(normalWS.y * 1.6)
                        * (0.35 + cavity * 0.65);
                    stone = lerp(stone, _RockLichen.rgb, saturate(lichen) * _RockLichenAmount);

                    // The refusing faces go cool slate: "cliffs refuse, slopes permit" reads in
                    // colour temperature as well as in shape.
                    stone = lerp(stone, _CliffColor.rgb * lerp(0.92, 1.08, mottle), cliffT);
                }

                // When rockT >= 0.999 the meadow branch is skipped and `ground` is still the flat
                // fallback colour — harmless, because the lerp below gives it a weight under 0.001.
                float3 albedo = lerp(ground, stone, rockT);

                // -- Lighting: wrapped lambert + SH ambient, with the shade AUTHORED — a cool tint
                //    multiplies the shadowed side and a floor keeps ambient off black. Storybook
                //    shadows are luminous and cool, never pits.
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                Light mainLight = GetMainLight(shadowCoord);

                float ndotl = dot(shadingNormalWS, mainLight.direction);
                float wrapped = saturate((ndotl + _ShadeWrap) / (1.0 + _ShadeWrap));
                float lit = wrapped * mainLight.shadowAttenuation;
                float3 direct = mainLight.color * lit;
                float3 ambient = max(SampleSH(shadingNormalWS) * _AmbientBoost, _AmbientFloor.rgb);
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
