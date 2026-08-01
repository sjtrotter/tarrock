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
    // ROUND-4 PASS (2026-07-31 gauntlet critique of round3/v1, v5, v8). Four findings, each answered
    // at the place that caused it; the detail is at each property and each construct below.
    //
    //   e. THE RULED DUNES. "Perfectly parallel horizontal bands wrap ENTIRE rounded grass-topped
    //      landforms." Round 3's slope gate opened at 35°, and the landform filling v1's left third
    //      — the valley's SOUTH permitting ramp — measures a median of 31.5° over a 12.6-48.6°
    //      quartile range (513² samples of this generator's own heightfield, Unity's central-
    //      difference normals). 43.8% of it therefore drew beds, a horizontal plane cutting a
    //      rounded hill traces a CONTOUR, and so the beds wrapped the form. The gate is now 50→62°
    //      AND the rock classification, ANDed — see _BeddingSlopeStart.
    //   f. THE DEAD HORIZON. "Mid-distance mottle dies by ~40 m; the hills become flat olive
    //      gradients." Everything that survived past 40 m was fbm, and fbm integrates to a gradient.
    //      A new jittered-cell CLUMP octave at ~16 m carries the 40-150 m band, and it is not
    //      distance-faded — see _MeadowClumpScale.
    //   g. THE STAMPED DECAL. "Close mottle is one stamped decal repeated at one size on a visible
    //      cadence." Jittering a Worley cell's CENTRE hides the lattice's phase and nothing else;
    //      the marks were still one circle at one radius on one pitch. Every dab now carries its
    //      own rotation, aspect and radius (TkDabShaped), and the texel band runs two warped
    //      layers at a non-harmonic ratio.
    //   h. THE SLIVER TRIANGLES. "The rock face at 2 m is hard-faceted sliver triangles with no
    //      surface detail." Two faults: the shading-normal relief was sized for near-flat meadow
    //      triangles (_RockNormalBoost), and the stone branch had nothing at all below a metre.
    //      Round 4 answered the second with a 0.62 m face dab, which round 5 measured as still
    //      310 pixels across at the distance the complaint was made from — see the detail stack.

    // ROUND 5 amends the economy rule stated below, and the amendment is load-bearing. "Marks with
    // EDGES" is right about what reads as paint and wrong about what it costs: a Worley field is a
    // min() over nine cells, so it CREASES along every cell wall, and stacked at three scales those
    // creases measured as a directional anisotropy of 17.2 against a reference-plate band of
    // 1.6-5.7 — the wood-grain read over the whole of round-4's v5. Edges are still how a surface
    // reads as painted; they are now bought with SPARSE MARK FIELDS (TkFleckBand), which have real
    // edges at low coverage and no crease network, and the Worley dabs are kept only at the scales
    // where an individual mark is legible as a mark (the 6 m meadow dab, the 16 m clump).
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
        _MeadowGrainScale ("Meadow Grain Scale (m)", Float) = 0.34
        _MeadowDabWarp ("Meadow Dab Warp", Range(0,1.5)) = 0.55
        _MeadowDabEdge ("Meadow Dab Edge Darken", Range(0,0.4)) = 0.10
        // ROUND-4 (gauntlet critique of round3/v1, v5): "close mottle is one stamped decal repeated
        // at one size on a visible cadence". It was: TkDab returned the ISOTROPIC distance to a
        // jittered cell centre, so every mark in the field was a circle of the same radius on a
        // lattice of the same pitch, and at 2 m the eye reads that pitch straight off. These two
        // give every cell its own ASPECT (some marks are strokes, some are blobs) and its own
        // RADIUS (a family of brush widths, not one stamp) on top of the rotation TkDabShaped now
        // applies per cell — see that function.
        _MeadowDabAniso ("Meadow Dab Aspect Spread", Range(0,0.9)) = 0.55
        _MeadowDabSize ("Meadow Dab Size Spread", Range(0,0.9)) = 0.45
        _MeadowStrawAmount ("Meadow Straw Amount", Range(0,2)) = 0.85
        _MeadowScuffAmount ("Meadow Scuff Amount", Range(0,2)) = 0.55
        _MeadowCoolAmount ("Meadow Cool Amount", Range(0,2)) = 0.70
        _MeadowFineStraw ("Meadow Fine Straw Flecks", Range(0,1)) = 0.28
        _MeadowGrain ("Meadow Micro Grain", Range(0,0.4)) = 0.13
        _DetailFadeStart ("Detail Fade Start (m)", Float) = 10.0
        _DetailFadeRange ("Detail Fade Range (m)", Float) = 28.0

        [Header(Meadow clumps    the horizon octave)]
        // ROUND-4 (gauntlet critique of round3/v1): "mid-distance mottle dies by ~40 m — the hills
        // become flat olive gradients, where fable-01/05 keep clump structure to the horizon".
        //
        // WHY IT DIED, structurally. Everything that survived past 40 m was fbm — macro at 38 m and
        // hue at 21 m — and fbm is C1 smooth by construction, so at range it integrates to a
        // GRADIENT. The two fields that had edges were the 6 m dab and the 0.95 m fine dab, and both
        // are inside _DetailFade or are simply too fine to resolve at 60 m+. A surface whose only
        // long-range content is smooth cannot read as clumped ground no matter how much hue swing it
        // carries: the eye reads clumps from BOUNDARIES.
        //
        // THE FIX is one more jittered-cell octave, sized at the scale a stand of vegetation
        // actually clumps at (~16 m), carrying its own flat tone per cell and its own edge darken —
        // and DELIBERATELY NOT distance-faded, because its whole job is the 40-150 m band. It costs
        // one TkDabShaped in the meadow branch. At 100 m a 16 m clump still subtends ~9°, which is
        // hundreds of pixels: it is resolvable exactly where the fbm has stopped saying anything.
        _MeadowClumpScale ("Meadow Clump Scale (m)", Float) = 16.0
        _MeadowClumpWarp ("Meadow Clump Warp", Range(0,2)) = 0.85
        _MeadowClumpAmount ("Meadow Clump Hue Amount", Range(0,2)) = 0.90
        _MeadowClumpEdge ("Meadow Clump Edge Darken", Range(0,0.35)) = 0.11

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
        // ROUND-4 (gauntlet critique of round3/v5): "the rock face at 2 m is hard-faceted sliver
        // triangles with no surface detail". Two separate faults, answered separately.
        //
        //   * NO SURFACE DETAIL. The stone branch carried mottle at 6.5 m, bedding at 2.6 m and
        //     cavity at 3.4 m — nothing at all below a metre — so at a 2 m camera the whole face was
        //     one flat wash between two partings. The meadow has had a texel-scale band since round
        //     2 and the rock never did. These give stone the same painted tooth, on the FACE'S OWN
        //     coordinate frame (strike across, world Y up), which is one dab lookup rather than the
        //     three a triplanar would cost — and it is the right frame anyway: paint on a rock face
        //     runs along the face, not through it.
        //   * THE FACETS. See _RockNormalBoost under Shading normal.

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
        //
        // ROUND-4 RE-GATE, 35/48 -> 50/62 (gauntlet critique of round3/v1, v8): "perfectly parallel
        // horizontal bands wrap ENTIRE rounded grass-topped landforms". They did, and the round-3
        // gate is why. Measured off this generator's own heightfield (513² samples, Unity's own
        // central-difference normals), the landform filling v1's left third — x 140-218, z 30-88,
        // the valley's SOUTH permitting ramp — runs a median of 31.5° with a quartile range of
        // 12.6-48.6°: it is a dune, not a cliff, and 43.8% of it sat inside the old 35-48° fade.
        // A 12% mask on a 0.36 darken is only a 4% step, but 4% laid as a continuous curve across a
        // smooth pale slope is a Mach band, and a horizontal plane cutting a rounded hill traces a
        // CONTOUR — so the bands wrapped the form. At 50/62 that same box drops to 22.2% touched and
        // every cell under 50° gets EXACTLY zero, which is the whole of the fix.
        //
        // The number is not taste, it is the geometry: a 2.6 m bed meets a 30° slope over 5.20 m of
        // surface and a 60° slope over 3.00 m. Beds have to be thin lines or they are shading.
        _BeddingSlopeStart ("Bedding - slope fade in (deg)", Float) = 50.0
        _BeddingSlopeEnd ("Bedding - slope full (deg)", Float) = 62.0

        [Header(Cavity)]
        // Concavity darkening, AO-like and DELIBERATELY SEPARATE from any line drawing: it is the
        // FILLED region where the fine relief sits below the broad form, not a band around a field's
        // midpoint. A filled region is a blob; a band around a midpoint is a contour line. Round 2
        // used the second and got worms.
        // -- The detail stack (round 5) ----------------------------------------------------------
        // See TkDetailFbm / TkFleckBand in the HLSL block for the derivation. Every number here was
        // solved in a numpy transcription of this shader measured against the round-4 captures and
        // the reference plates with one metric, and is quoted as (modelled -> predicted in the
        // capture, the round-4 residue added in quadrature).
        //
        // Base scale is the COARSEST octave; the finest is base/2.71^3, so 0.60 m gives a finest
        // octave of 3.0 cm and 0.95 m gives 4.8 cm — the 2-4 cm band the round-4 critique asked
        // for on the ground, and the band the reference plates carry their speckle in.
        _DetailBaseScale ("Detail - rock base scale (m)", Float) = 0.60
        _MeadowDetailScale ("Detail - meadow base scale (m)", Float) = 0.95

        // ROCK. Modelled at 2.0 mm/px (v5's own geometry): 2.61/5.92/10.82/15.19 percent relative
        // amplitude at high-pass sigma 2/4/8/16 px, 54 luma levels, anisotropy 1.81.
        // Round 4 measured 1.26/1.78/2.47/3.36, 20 levels, anisotropy 12.73.
        // Predicted in capture at the 2-4 cm scale: ~11.0%, against the critique's 10-16% band.
        _RockGrainAmount ("Detail - rock continuous amount", Range(0, 0.8)) = 0.40
        _RockFleckFine ("Detail - rock fleck 3 cm (grit)", Range(0, 0.9)) = 0.58
        _RockFleckMid ("Detail - rock fleck 12 cm (weathering)", Range(0, 0.9)) = 0.46
        _RockFleckCoarse ("Detail - rock fleck 85 cm (patches)", Range(0, 0.9)) = 0.34

        // MEADOW. Pushed harder than rock on purpose: near turf measured 9.47% against a
        // reference band of 17.8-36.7 (fable-08 17.76, fable-01 28.81, fable-07 36.69), and the
        // round-4 critique's note is that the CADENCE is already right and only the amplitude is
        // missing. Modelled at 5.0 mm/px: 6.30/12.19/18.44/22.96, 53 levels, anisotropy 1.61.
        // Predicted in capture ~21%, i.e. the lower third of the reference band. Deliberately not
        // further: past about 0.6 continuous amount the model's marks stop being separable and the
        // ground reads as static rather than as paint, and that is a judgement no metric settles.
        _MeadowDetailAmount ("Detail - meadow continuous amount", Range(0, 0.8)) = 0.52
        _MeadowFleckFine ("Detail - meadow fleck 4.5 cm (litter)", Range(0, 0.9)) = 0.72
        _MeadowFleckMid ("Detail - meadow fleck 17 cm (tussock)", Range(0, 0.9)) = 0.58
        _MeadowFleckCoarse ("Detail - meadow fleck 90 cm (stands)", Range(0, 0.9)) = 0.48

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
        // ROUND-4: the relief that camouflages the Gouraud facet kink is sized for the MEADOW, where
        // the terrain triangles are ~0.5 m of nearly flat ground and 0.30 m over a 3.4 m field is
        // plenty. On a 65° face the same triangles are edge-on, the ndotl step across each kink is
        // several times larger, and 0.30 m of relief measured ~5° of tilt — not enough to break it,
        // which is why v5 read as sliver triangles. Rock therefore gets the relief scaled up by
        // this, weighted by rockT, for ~11° of tilt on stone and nothing at all on the meadow. It
        // costs no extra taps: the same relief height is simply amplified before it is differentiated.
        _RockNormalBoost ("Shading Normal - rock relief multiplier", Range(1,4)) = 2.2

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
        // ROUND-5: THE PENUMBRA, in metres of half-width on the ground. See the Frag lighting block —
        // the sun has an angular diameter and a 12° sun stretches the resulting soft band by ~4.8×
        // along its own bearing, which is a metre-scale edge that no shadowmap filter in URP can
        // produce at this map resolution.
        _ShadowPenumbra ("Shadow Penumbra (m on the ground)", Range(0,3)) = 1.0
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
            float _MeadowGrainScale;
            float _MeadowDabWarp;
            float _MeadowDabEdge;
            float _MeadowDabAniso;
            float _MeadowDabSize;
            float _MeadowStrawAmount;
            float _MeadowScuffAmount;
            float _MeadowCoolAmount;
            float _MeadowFineStraw;
            float _MeadowGrain;
            float _DetailFadeStart;
            float _DetailFadeRange;
            float _MeadowClumpScale;
            float _MeadowClumpWarp;
            float _MeadowClumpAmount;
            float _MeadowClumpEdge;
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
            float _DetailBaseScale;
            float _MeadowDetailScale;
            float _RockGrainAmount;
            float _RockFleckFine;
            float _RockFleckMid;
            float _RockFleckCoarse;
            float _MeadowDetailAmount;
            float _MeadowFleckFine;
            float _MeadowFleckMid;
            float _MeadowFleckCoarse;
            float _CavityScale;
            float _CavityContrast;
            float _CavityDarken;
            float _CavityGroundDarken;
            float _NormalDetailHeight;
            float _NormalDetailStrength;
            float _NormalDetailFadeStart;
            float _NormalDetailFadeRange;
            float _RockNormalBoost;
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
            float _ShadowPenumbra;
        CBUFFER_END

        // The penumbra tap ring (see the Frag lighting block). Unit offsets in the light's own frame:
        // x runs ALONG the sun's compass bearing, y across it. Across the beam the soft band is the
        // sun's raw 0.53°; along it, that band stretched by the rake, so the ring is an ellipse and
        // kPenumbraAcross is sin(12°) — SunEuler's elevation, quoted rather than derived, because
        // the shading normal here has already been perturbed by the relief term and is no longer a
        // safe place to read the lamp's angle from.
        static const float kPenumbraAcross = 0.21;
        static const float2 kPenumbraTaps[8] =
        {
            float2( 1.00,  0.00), float2(-1.00,  0.00),
            float2( 0.50,  0.00), float2(-0.50,  0.00),
            float2( 0.71,  0.71), float2(-0.71, -0.71),
            float2( 0.71, -0.71), float2(-0.71,  0.71)
        };

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

        // -- Turning the domain between octaves ---------------------------------------------------
        // Value noise lives on an AXIS-ALIGNED lattice and its smoothstep interpolant kinks at
        // every cell wall. Stack octaves on the same axes and those kinks COINCIDE into a
        // rectilinear crease network — which is what the round-4 capture of v5 measured as a
        // directional anisotropy of 12.7 on near-vertical rock, against a reference-plate band of
        // 1.6-5.7 (fable-01 1.64, fable-06-L 5.72). Turning each octave by a golden-ratio angle
        // costs two multiplies and no taps, and no two octaves share an axis again.
        //
        // The angles are 0.618034*pi*n: 111.25, 222.50, 333.75 degrees. Quoted as cos/sin pairs
        // rather than computed, because these are constants and a sincos per octave per
        // projection is twelve transcendentals a pixel for a number that never changes.
        static const float2 kTurn1 = float2(-0.36327, 0.93169);   // 111.25 deg
        static const float2 kTurn2 = float2(-0.73593, -0.67705);  // 222.50 deg
        static const float2 kTurn3 = float2( 0.89685, -0.44234);  // 333.75 deg

        float2 TkTurn(float2 p, float2 cs)
        {
            return float2(p.x * cs.x - p.y * cs.y, p.x * cs.y + p.y * cs.x);
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
            // ROUND-5: the fine octave is TURNED as well as scaled (see kTurn1). Both octaves sat
            // on the same axis-aligned lattice, so their interpolant kinks lined up — and this
            // pair's DIFFERENCE is read by two things at once, the cavity term and the shading
            // normal, so that crease network was being drawn twice over. Two multiplies on a tap
            // that was already being taken.
            float fine = TkValueNoise(TkTurn(p * 2.71 + 19.7, kTurn1));
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

        // -- The detail stack (round 5) -----------------------------------------------------------
        // WHY THIS EXISTS, in the numbers that produced it. Round 4's v5 measured 20 distinct luma
        // levels over a 600x550 crop of near-vertical rock at ~2 m, where the reference plates run
        // 149 (fable-01) to 230 (fable-06); relative high-pass amplitude at the 2-4 cm scale was
        // 2.5% against a reference band of 10-16%; anisotropy 12.7 against 1.6-5.7.
        //
        // The cause is arithmetic, not taste. GauntletCapture puts v5's camera 2.61 m from its
        // target at a 45 deg VERTICAL fov over 1080 px, so the ground sample distance there is
        // 2*2.61*tan(22.5)/1080 = 2.0 mm per pixel. The FINEST term the stone branch owned was the
        // 0.62 m rock dab — 310 pixels across. Nothing in the material varied inside a third of a
        // metre. A numpy transcription of the whole round-4 chain reproduces the capture (modelled
        // 1.40% relative amplitude vs 2.47% measured, 14 levels vs 20, anisotropy 16.4 vs 12.7)
        // and shows the 6.5 m mottle and the 3.4 m cavity contributing EXACTLY ZERO at every scale
        // a 1.2 m crop can measure. They are not weak there; they are absent.
        //
        // Two constructs, because neither can do the job alone.
        //
        //   * TkDetailFbm — the continuous field. Four octaves, lacunarity 2.71, gain 0.80, turned
        //     between octaves. Gain 0.80 and not the conventional 0.5 because a gain-0.5 stack
        //     buries its energy in its COARSEST octave, which is the one the eye already has: the
        //     model measured 0.62% relative amplitude at gain 0.5 against 2.14% at gain 1.0 for
        //     the same total swing. NON-FOLDING throughout — no abs(), no min(), no saturate() of
        //     a coarse field. Each of those draws a LEVEL SET, and the level set of a smooth 2-D
        //     field is a closed curve; that is the lesson TkCavityPair's header already records,
        //     and the nested chevrons over the whole lower right of round-4's v5 are what it looks
        //     like when it is forgotten.
        //
        //   * TkFleck — the sparse field, and the term that actually closes the gap. A smooth fbm
        //     CANNOT reach the reference band at any sane amplitude: the model needed a 280%
        //     albedo swing to put the 2-4 cm figure at 12%, because a smooth field spreads its
        //     variance over every scale at once. The reference plates get there because their fine
        //     energy is SPECKLE — lichen, grit, blade litter — a few strong marks over a small
        //     fraction of the surface. A mark field of coverage p and contrast c has
        //     rms = c*sqrt(p*(1-p)), so 13% coverage at 0.52 contrast buys 17% relative amplitude
        //     while every individual mark stays a mark. That is brush economy written as a number.
        //
        // DISTANCE IS SOLVED BY RENORMALISATION, NOT BY FADING. Round 4 faded every fine term to
        // nothing by 38 m (_DetailFadeStart + _DetailFadeRange) and the far hill duly measured
        // 5.4% against a reference mid/far band of 15.5-28%; mid-distance mottle REGRESSED from
        // round 3's 19.6% to 12.7%. Here each octave carries its own weight, keyed to whether its
        // wavelength still spans more than about two pixels, and the sum is divided by the weights
        // that SURVIVED. An octave that has fallen under the pixel grid stops contributing and the
        // octaves above it inherit its share, so the surface holds its amplitude instead of
        // dissolving into its own mean. Modelled at 3 / 12 / 40 / 100 / 200 m the relative
        // amplitude reads 9.6 / 14.9 / 11.5 / 10.9 / 15.6 percent — flat to within a factor of 1.6
        // across two decades of distance, and in band at every one of them.
        //
        // WHAT THE MODEL DOES NOT PREDICT, stated so the next round does not over-trust it: it is
        // an ALBEDO model. It has no lighting, no shadow terminator, no grass tufts, no fog and no
        // tonemapper, and the capture crops contain all five. Calibrated against round 4 the other
        // contributors add about 2.0% of independent energy on rock and 9.1% on near ground, so
        // the shipped numbers below are quoted as (modelled -> predicted in capture) with those
        // added in quadrature. Anything outside that is a finding for round 6, not a rounding
        // error.

        // Below about two pixels an octave stops being a feature and becomes aliasing, and drawing
        // it costs contrast at every other scale as well as crawling under camera motion. The
        // window is quoted in PIXELS because that is the quantity that decides it; the metres it
        // corresponds to change with every step the Fool takes.
        static const float kDetailPxLo = 1.6;
        static const float kDetailPxHi = 3.2;

        float TkOctaveWeight(float wavelengthM, float pixelM)
        {
            return smoothstep(kDetailPxLo, kDetailPxHi, wavelengthM / max(pixelM, 1e-6));
        }

        float TkDetailFbm(float2 p, float baseM, float pixelM)
        {
            float lam = max(baseM, 1e-4);
            float2 q = p / lam;

            float w = TkOctaveWeight(lam, pixelM);
            float sum = TkValueNoise(q) * w;
            float tot = w;

            q = TkTurn(q * 2.71 + 17.3, kTurn1); lam /= 2.71;
            w = TkOctaveWeight(lam, pixelM) * 0.80;
            sum += TkValueNoise(q) * w; tot += w;

            q = TkTurn(q * 2.71 + 17.3, kTurn2); lam /= 2.71;
            w = TkOctaveWeight(lam, pixelM) * 0.64;
            sum += TkValueNoise(q) * w; tot += w;

            q = TkTurn(q * 2.71 + 17.3, kTurn3); lam /= 2.71;
            w = TkOctaveWeight(lam, pixelM) * 0.512;
            sum += TkValueNoise(q) * w; tot += w;

            // Mean 0.5 whatever survived, so an amplitude constant below means the same thing at
            // 2 m as at 200 m. When every octave has fallen under the pixel — a hillside at the
            // fog line — the guard returns the field's own mean and the surface goes flat, which
            // is the correct answer: there is nothing left there to draw.
            return tot > 1e-4 ? sum / tot : 0.5;
        }

        // Triplanar, for the same reason TkTriplanarCavityPair is: a planar projection smears to
        // stripes on anything near-vertical, and near-vertical rock is exactly the surface this
        // construct was written for.
        float TkTriplanarDetail(float3 worldPos, float3 normal, float baseM, float pixelM)
        {
            float3 blend = pow(abs(normal), 4.0);
            blend /= max(blend.x + blend.y + blend.z, 1e-4);
            return TkDetailFbm(worldPos.zy, baseM, pixelM) * blend.x
                 + TkDetailFbm(worldPos.xz, baseM, pixelM) * blend.y
                 + TkDetailFbm(worldPos.xy, baseM, pixelM) * blend.z;
        }

        // Two decorrelated fields, ANDed. The AND is the whole construct: each field alone crosses
        // its threshold over roughly a third of the ground, and their PRODUCT lands at 13% — at
        // neither field's pitch, so the marks scatter instead of tiling. The second field runs at
        // a non-integer multiple of the first's wavelength and is offset, so the two beat patterns
        // never come back into phase inside the mantissa guard's 512 m.
        //
        // Self-gating on its own wavelength: a fleck under a couple of pixels is salt-and-pepper
        // and nothing else, so it is not merely faded but BRANCHED AWAY, which is what pays for
        // the detail stack's cost on the far hills. Safe under UNITY_BRANCH because nothing in
        // here takes a screen derivative.
        // Returns .x = a MEAN-PRESERVING multiplier, .y = the raw mark (for terms that want the
        // mark's hue as well as its value).
        //
        // Mean-preserving matters more than it sounds. A mark field of coverage p at contrast c
        // multiplies the surface mean by (1 - p*c), and three bands at the meadow's shipped
        // settings compound to 0.85 — a 15% darkening of the whole meadow, arriving as a side
        // effect of a texture change. The region's palette is canon ("pale dawn gold in the LIGHT,
        // wind-scoured green"; the gold is in the light, not the albedo), so the marks divide
        // their own expected mean back out and change the surface's VARIANCE without touching its
        // value. The coverages are measured, not derived — a smoothstep pair over two value-noise
        // fields has no closed form — over a 40 x 36 m population sample of the shipped fields.
        //
        // The divisor carries the SAME octave weight the mark does. Without that, a band that has
        // faded out below the pixel goes on compensating for marks it is no longer drawing, and
        // the far hills brighten: measured at +18% at 100 m before the weight was folded in.
        float2 TkFleckBand(float2 p, float lamA, float lamB, float2 thr,
                           float coverage, float amount, float pixelM)
        {
            float w = TkOctaveWeight(lamA, pixelM);
            UNITY_BRANCH
            if (w <= 0.002) return float2(1.0, 0.0);
            float a = TkValueNoise(p / max(lamA, 1e-4));
            float b = TkValueNoise(p / max(lamB, 1e-4) + 11.3);
            float mark = smoothstep(thr.x, thr.y, a)
                       * smoothstep(thr.x - 0.06, thr.y - 0.06, b) * w;
            return float2((1.0 - mark * amount) / max(1.0 - coverage * amount * w, 0.05), mark);
        }

        // -- Painted dabs -----------------------------------------------------------------------
        // Jittered-cell (Worley) field. Returns .x = distance to the nearest dab centre in that
        // dab's OWN metric, .y = that dab's flat tone, .z = a second decorrelated per-dab random.
        // The tone is the point of the whole construct: every cell takes one flat value, so the
        // ground reads as marks laid side by side, with edges between them. No amount of fbm can do
        // that — fbm is C1 smooth by construction, which is exactly why round 1's meadow measured
        // as an airbrush.
        //
        // ROUND-4: EVERY DAB IS ITS OWN BRUSHMARK. Round 3 took the plain isotropic distance to the
        // jittered centre, which means every mark in the field was a CIRCLE of the SAME radius on a
        // lattice of the SAME pitch. Jittering the centres hides the lattice's phase and nothing
        // else — the mark family is still one stamp, and at a 2 m camera the eye reads the pitch
        // straight off it ("one stamped decal repeated at one size on a visible cadence", round-4
        // critique of v1/v5). Three per-cell channels off a SECOND hash fix it at the source:
        //   * ROTATION   — the mark's long axis points somewhere new in every cell, so no two
        //                  neighbours share a stroke direction and there is no readable grain.
        //   * ASPECT     — `aniso` turns some cells into drawn-out strokes and others into blobs.
        //   * RADIUS     — `sizeJitter` gives the family a range of brush widths, which is what
        //                  makes a cadence impossible: a rhythm needs marks the same size.
        // The shape hash is offset far from the position hash so a cell's shape and its position
        // are uncorrelated — otherwise every mark that sat left in its cell would also be the same
        // shape, and the field would gain a new regularity in place of the one removed.
        //
        // The anisotropic metric is deliberately NOT a true Voronoi: a stretched cell can fail to
        // claim ground its neighbour also fails to claim, which leaves small unowned gaps where the
        // distance runs high. That is a feature — it is where the ground shows between the marks.
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
                // WORLD METRES PER PIXEL, which is what the detail stack's per-octave weighting
                // needs (see TkOctaveWeight). Taken off the derivatives already in hand, so it
                // costs nothing new, and it is the honest quantity: it already carries distance,
                // fov, resolution and the grazing angle of this particular pixel, none of which a
                // camDist fade knows about. Round 4 faded detail on camDist alone, which is why a
                // near-vertical face raking away from the camera lost its surface at the same
                // metre as flat ground facing it.
                float pixelM = max(max(length(dpdx), length(dpdy)), 1e-5);

                // -- Cavity + relief, shared by both layers and by the shading normal --------------
                // One field, three jobs: hollows darken, the same hollows are where lichen takes,
                // and its gradient is the per-pixel shading relief that hides the facet kink.
                float2 relief = TkTriplanarCavityPair(gp3, normalWS, _CavityScale);
                // ROUND-5: the fine-detail fade off this pair is GONE, and only the cavity's own
                // (three times longer) fade survives. Round 4 hung every texel-scale term on
                // _DetailFadeStart/_DetailFadeRange, so the whole surface was flat by 38 m; the
                // measurement is that mid-distance mottle fell from round 3's 19.6% relative
                // amplitude to 12.7% and the far hill sat at 3.3% against reference plates running
                // 13-20%. Distance now belongs to the detail stack, per octave, against the pixel
                // footprint. These two properties are kept for the cavity alone — it is a metre-
                // scale shading term, not a texel one, and it has always wanted a fade of its own.
                float cavityFade = 1.0 - saturate((camDist - _DetailFadeStart * 3.0)
                    / max(_DetailFadeRange * 3.0, 0.01));
                // ROUND-5: smoothstep, not saturate. saturate(d * contrast) CLAMPS, and the set
                // where a smooth field first reaches its clamp is a LEVEL SET — a closed contour
                // with a hard C1 break along it. Over the lower right of round-4's v5 that contour
                // is visible as nested chevrons, because the level set of an axis-aligned
                // value-noise lattice is a polyline that kinks at every cell wall; it is a
                // straight-line contributor to that crop measuring 20 luma levels against a
                // reference 149-230. Same term, same field, no clamp edge for a contour to be
                // drawn along. The 1.35 widens the ramp so the mean cavity strength lands within a
                // few percent of what the clamp gave (a smoothstep averages 0.5 across its ramp
                // where saturate averages ~0.74 across the same reach) — matched by intent, not to
                // three figures, because the term is a soft shade and not a threshold.
                float cavity = smoothstep(0.0, 1.35 / max(_CavityContrast, 0.5),
                        relief.x - relief.y)
                    * lerp(0.35, 1.0, cavityFade);

                // One shared mid-scale field, used five times over: it jitters the meadow/rock
                // boundary into a ragged natural edge, warps the bedding, picks where lichen has
                // taken, drifts the turf scour, and (round 4) tells the shading normal whether this
                // pixel is stone. Computing it once outside both branches is what pays for the
                // richer per-layer work below.
                //
                // HOISTED ABOVE THE SHADING NORMAL in round 4, deliberately and safely: rockT now
                // scales the relief height that the surface gradient differentiates, so it has to
                // exist first. Nothing in this block takes a screen derivative, so moving it changes
                // no result — the ddx/ddy rule the header states is about the two UNITY_BRANCHes
                // further down, and both are still below every derivative in this function.
                float blendField = TkTriplanarFbm2(gp3, normalWS, _BlendFieldScale);

                float steepness = 1.0 - saturate(normalWS.y);
                float jitter = (blendField - 0.5) * _SlopeJitter;
                float rockT = smoothstep(_SlopeStart, _SlopeEnd, steepness + jitter);
                float cliffT = smoothstep(_CliffStart, _CliffEnd, steepness + jitter * 0.6);

                // -- Per-pixel shading normal (header note c) --------------------------------------
                // Mikkelsen surface gradient: differentiate the relief height in screen space and
                // project it back onto the surface through the two tangent bivectors. No tangent
                // frame, no UVs, no extra noise taps — the height is already in hand.
                // ROCK GETS MORE OF IT (round-4 finding on v5). Same field, same taps, amplitude
                // scaled by rockT: 0.30 m of relief over 3.4 m is ~5° of tilt, which hides the
                // Gouraud kink on the meadow's near-flat triangles and does nothing at all on a 65°
                // face, where the triangles are edge-on and the ndotl step across each kink is
                // several times larger. At the boost this is ~11° on stone, which does break it.
                float reliefH = (relief.y - 0.5) * _NormalDetailHeight
                    * lerp(1.0, _RockNormalBoost, rockT);
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
                    float3 dab = TkDabShaped(gp / max(_MeadowDabScale, 0.01) + warp,
                        _MeadowDabAniso, _MeadowDabSize);
                    float dabTone = dab.y;
                    float dabEdge = smoothstep(0.45, 0.92, dab.x);

                    // THE CLUMP OCTAVE — the one band that has to survive to the horizon. Its scale
                    // is an order above the dab and an order below the macro field, which is the gap
                    // round 3 had nothing in but smooth fbm; and unlike every other term here it is
                    // never distance-faded, because 40-150 m is precisely its job. Warped by the
                    // macro field so the clumps drift with the ground's own broad drying rather than
                    // sitting on their own independent lattice.
                    float3 clump = TkDabShaped(
                        (gp + 519.0) / max(_MeadowClumpScale, 0.01)
                            + float2(macro - 0.5, hue - 0.5) * _MeadowClumpWarp,
                        _MeadowDabAniso, _MeadowDabSize);
                    float clumpTone = clump.y;
                    float clumpEdge = smoothstep(0.40, 0.95, clump.x);

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
                    // ROUND-4: each selector gains a CLUMP term. The clump field is the only one of
                    // the three that still has edges at 60 m+, so putting it into the hue choice —
                    // not merely into a value wobble — is what keeps a distant hillside reading as
                    // stands of straw among stands of green instead of as an olive gradient. The
                    // straw and cool terms take the clump's TONE and the scuff takes its second,
                    // decorrelated channel, so bare patches do not simply coincide with gold ones.
                    float strawT = saturate((hue - 0.50) * _MeadowStrawAmount * 3.4
                        + (clumpTone - 0.50) * _MeadowClumpAmount * 2.2
                        + (dabTone - 0.55) * 0.8 + heightT * 0.18);
                    float scuffT = saturate((macro - 0.66) * _MeadowScuffAmount * 5.0
                        + (clump.z - 0.74) * _MeadowClumpAmount * 2.4
                        + (dabTone - 0.64) * 0.8);
                    float coolT = saturate((0.44 - macro) * _MeadowCoolAmount * 4.0
                        + (0.46 - clumpTone) * _MeadowClumpAmount * 2.0
                        + (0.5 - dabTone) * 0.6);

                    ground = lerp(ground, _MeadowCool.rgb, coolT);
                    ground = lerp(ground, _MeadowStraw.rgb, strawT);
                    ground = lerp(ground, _MeadowScuff.rgb, scuffT);
                    ground *= 1.0 - dabEdge * _MeadowDabEdge;   // the visible edge of each mark
                    // ...and the clump's own edge, which is the mark the far hills are made of.
                    ground *= 1.0 - clumpEdge * _MeadowClumpEdge;

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
                    float3 turfDab = TkDabShaped(gp / max(_TurfScale, 0.01) + warp * 0.6,
                        _MeadowDabAniso, _MeadowDabSize);
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

                    // -- The detail stack on the meadow (round 5) --------------------------------
                    // Replaces round 4's two TkDabShaped fine layers, and is DELIBERATELY NOT
                    // gated on detailFade. That gate is the round-4 regression itself: it faded
                    // every fine term to nothing by 38 m (_DetailFadeStart + _DetailFadeRange), and
                    // mid-distance mottle duly fell from round 3's 19.6% to 12.7% while the far
                    // hill sat at 3.3% against reference plates running 13-20%. Distance is now
                    // handled octave by octave inside the field, against the pixel footprint rather
                    // than against camDist — see TkDetailFbm.
                    //
                    // The two dab layers are not mourned. They were a Worley F1 distance, and a
                    // Worley F1 is a min() over nine cells: it CREASES along every cell wall, which
                    // is a fold by another name. Modelled on its own it measured an anisotropy of
                    // 17.2 against a reference band of 1.6-5.7, and it was the largest single
                    // contributor to round-4's directional wood-grain read. The meadow keeps its
                    // brushmarks where brushmarks are legible — the 6 m dab and the 16 m clump
                    // above, both untouched — and gets a non-folding field underneath them.
                    float detail = TkDetailFbm(gp, _MeadowDetailScale, pixelM);
                    ground *= 1.0 + (detail - 0.5) * 2.0 * _MeadowDetailAmount;

                    // Three mark bands an order apart, so the ground has speckle at every distance
                    // the camera can stand at: blade litter underfoot, tussock shade at a few
                    // metres, stands of drier growth on the hillsides. The wavelength pairs and
                    // thresholds are model constants and should move together if they move at all
                    // — they set the COVERAGE (measured 0.137 / 0.103 / 0.083 over a 40 m sample),
                    // and coverage is what the whole amplitude argument rests on.
                    float2 fleckFine = TkFleckBand(gp, 0.045, 0.075, float2(0.46, 0.76),
                        0.1371, _MeadowFleckFine, pixelM);
                    float2 fleckMid = TkFleckBand(gp + 53.1, 0.170, 0.280, float2(0.50, 0.79),
                        0.1028, _MeadowFleckMid, pixelM);
                    float2 fleckWide = TkFleckBand(gp + 217.7, 0.900, 1.500, float2(0.52, 0.81),
                        0.0834, _MeadowFleckCoarse, pixelM);
                    ground *= fleckFine.x * fleckMid.x * fleckWide.x;

                    // The finest band also carries HUE, kept from round 4: dry strands and grit
                    // read as colour at texel scale, not as one more brightness wobble. Suppressed
                    // inside the turf, where the ground is damp and shaded by the blades above it.
                    ground = lerp(ground, _MeadowStraw.rgb,
                        fleckFine.y * _MeadowFineStraw * (1.0 - turfMask * 0.6));

                    // The micro grain survives as the one term below the finest mark — half a
                    // centimetre of tooth on the paint. On its own weight, so it leaves quietly
                    // rather than aliasing: at 0.34 m it is the first thing to fall under the
                    // pixel, and it is worth nothing once it has.
                    float grain = TkValueNoise(gp / max(_MeadowGrainScale, 0.01));
                    ground *= 1.0 + (grain - 0.5) * _MeadowGrain
                        * TkOctaveWeight(_MeadowGrainScale, pixelM);

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
                    //
                    // ROUND-4: TWO gates, ANDed, and the second is not redundant. The slope gate is
                    // taken off the GEOMETRIC normal and the rock gate off the same steepness PLUS
                    // the ±0.065 boundary jitter, so a face can be classified as stone by a jitter
                    // excursion while measuring under 50° — and drawing beds on ground the jitter
                    // merely painted grey is exactly how a dune ends up ruled. Requiring both means
                    // strata appear only where the surface is BOTH steep and stone. Every cell under
                    // 50° now takes exactly zero bedding, which is the round-4 finding's whole ask.
                    float beddingMask = smoothstep(_BeddingSlopeStart, _BeddingSlopeEnd, steepDeg)
                        * smoothstep(0.55, 0.95, rockT);

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
                    // ROUND-4: the formation swing rides on beddingMask, and beddingMask is now
                    // zero below 50°, so the 35-50° APRON — the scree-and-soil band between meadow
                    // and cliff — would have lost its only hue variation along with its (wrongly
                    // drawn) beds. It gets a broad drift of its own instead, off the mottle field
                    // already in hand and weighted by exactly what the bedding gave up. Patches,
                    // not stripes: this is a 6.5 m blotch field, so it cannot draw a contour.
                    stone = lerp(stone, _RockCool.rgb,
                        saturate((mottle - 0.55) * 2.2) * _RockBedTint * 0.55 * (1.0 - beddingMask));
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

                    // -- The detail stack on stone (round 5) ------------------------------------
                    // This replaces round 4's single 0.62 m face dab, which was the finest thing
                    // the stone branch owned and is why v5's rock crop measured 20 luma levels and
                    // 2.5% relative amplitude: at 2.0 mm per pixel that dab is 310 pixels across,
                    // so between two partings there was one flat wash and nothing else. The dab
                    // also cost what it could not pay for — a Worley F1 creases along every cell
                    // wall, and modelled alone it measured an anisotropy of 17.2 against a
                    // reference band of 1.6-5.7.
                    //
                    // TRIPLANAR here, where the meadow's is planar, and the asymmetry is the point:
                    // meadow only exists on near-flat ground, but this term exists FOR near-vertical
                    // rock, and a planar projection smears to vertical stripes on exactly that
                    // surface. Twelve taps is the honest price of the one place in the frame the
                    // round-4 critique called the biggest gap.
                    //
                    // The three mark bands stay on the FACE'S own frame — x along the face's strike
                    // (the horizontal direction lying in the surface), y world height. Cheap, and
                    // right: paint and weathering on a rock face run ALONG the face. The frame
                    // degenerates on an up-facing pixel where normalWS.xz vanishes; the epsilon
                    // keeps it defined, and such pixels have almost no rockT to spend anyway.
                    float rockDetail = TkTriplanarDetail(gp3, normalWS, _DetailBaseScale, pixelM);
                    stone *= 1.0 + (rockDetail - 0.5) * 2.0 * _RockGrainAmount;

                    float2 strike = normalize(float2(-normalWS.z, normalWS.x) + 1e-4);
                    float2 faceUV = float2(dot(gp3.xz, strike), gp3.y);
                    // Grit and lichen at 3 cm, weathering at 12 cm, damp patches at 85 cm.
                    // Coverages measured over a 40 m population sample: 0.117 / 0.088 / 0.069.
                    float2 rockFine = TkFleckBand(faceUV, 0.030, 0.052, float2(0.48, 0.78),
                        0.1166, _RockFleckFine, pixelM);
                    float2 rockMid = TkFleckBand(faceUV + 61.7, 0.115, 0.190, float2(0.52, 0.80),
                        0.0878, _RockFleckMid, pixelM);
                    float2 rockWide = TkFleckBand(faceUV + 193.1, 0.850, 1.400, float2(0.54, 0.82),
                        0.0688, _RockFleckCoarse, pixelM);
                    stone *= rockFine.x * rockMid.x * rockWide.x;

                    // MOSS, NOT GRIME (the region's standing rule). The damp bands take the lichen
                    // hue rather than merely going darker, so the speckle that carries the surface
                    // amplitude is also the thing that keeps the rock from being grey on grey.
                    stone = lerp(stone, _RockLichen.rgb,
                        rockMid.y * _RockLichenAmount * 0.45 * saturate(normalWS.y * 1.6 + 0.25));
                }

                // When rockT >= 0.999 the meadow branch is skipped and `ground` is still the flat
                // fallback colour — harmless, because the lerp below gives it a weight under 0.001.
                float3 albedo = lerp(ground, stone, rockT);

                // -- Lighting: wrapped lambert + SH ambient, with the shade AUTHORED — a cool tint
                //    multiplies the shadowed side and a floor keeps ambient off black. Storybook
                //    shadows are luminous and cool, never pits.
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                Light mainLight = GetMainLight(shadowCoord);

                // -- THE PENUMBRA (round-5 light pass). The round-4 critique measured the cast-shadow
                //    terminator on flat ground as ONE PIXEL hard, where every plate on the reference
                //    board carries a visibly soft edge. It is one pixel because the shadowmap is too
                //    GOOD: the PC quality level runs a 4096 map over a 180 m shadow distance with 4
                //    cascades, so the near cascade resolves 18 m across 2048 texels — 8.8 mm a texel
                //    — and URP's soft-shadow filter is a fixed tap pattern a few TEXELS wide, i.e. a
                //    2.6 cm penumbra. Nothing in the pipeline's own settings can widen that: raising
                //    the filter quality moves texels, not metres, and dropping the map resolution to
                //    buy metres is what round 3 raised it FROM (a 12° sun's long thin shadows die in
                //    the far cascade).
                //
                //    So it is done here, in metres, from the physics the shadowmap threw away. The
                //    sun subtends 0.53° (0.00925 rad), so an occluder D metres away casts a penumbra
                //    D·0.00925 wide across the beam — and on ground raked at 12° that band is
                //    stretched by 1/sin(12°) = 4.81× ALONG THE SUN'S BEARING. The forms that throw
                //    this region's shadows stand 10-40 m from what they shade, which is a soft edge
                //    0.45-1.8 m wide on the ground: _ShadowPenumbra 1.0 m of half-width is the
                //    middle of that range, and it is why the offsets are an ELLIPSE elongated along
                //    the light and not a disc — a real low-sun penumbra is a smear, not a blur.
                //
                //    Nine taps, so the ramp carries nine steps rather than the two it has now. They
                //    are cheap (the shadowmap is already resident and this pass is one texture fetch
                //    per tap) and they are the only place in this file that spends anything on the
                //    shadow edge.
                float3 sunAxis = float3(mainLight.direction.x, 0.0, mainLight.direction.z);
                float axisLength = length(sunAxis);
                sunAxis = axisLength > 1e-4 ? sunAxis / axisLength : float3(1.0, 0.0, 0.0);
                float3 sunSide = float3(-sunAxis.z, 0.0, sunAxis.x);
                float penumbra = max(_ShadowPenumbra, 0.0);
                float atten = mainLight.shadowAttenuation;
                // NOT in the screen-space variant: there MainLightRealtimeShadow reads a full-screen
                // texture and treats shadowCoord.xy as a SCREEN uv, so offsetting a world position
                // and re-transforming it would sample eight unrelated pixels. This project ships no
                // ScreenSpaceShadows renderer feature (PC_Renderer carries only SSAO), so the branch
                // is dead today; it is written down so it stays correct if one is ever added.
                #if !defined(_MAIN_LIGHT_SHADOWS_SCREEN)
                if (penumbra > 1e-3)
                {
                    [unroll]
                    for (int tap = 0; tap < 8; tap++)
                    {
                        float3 offsetWS = positionWS
                            + sunAxis * (kPenumbraTaps[tap].x * penumbra)
                            + sunSide * (kPenumbraTaps[tap].y * penumbra * kPenumbraAcross);
                        atten += MainLightRealtimeShadow(TransformWorldToShadowCoord(offsetWS));
                    }
                    atten *= (1.0 / 9.0);
                }
                #endif

                float ndotl = dot(shadingNormalWS, mainLight.direction);
                float wrapped = saturate((ndotl + _ShadeWrap) / (1.0 + _ShadeWrap));
                float lit = wrapped * atten;
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
