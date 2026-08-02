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
    // ROUND-8 PASS (gauntlet critique of round7: MATERIAL IDENTITY). One finding with one
    // structural cause, and the cause is measurable in this file's own history.
    //
    //   i. EVERY SURFACE IS MADE OF THE SAME STUFF. Minimum pairwise material-spectrum cosine
    //      over the v8 surfaces (jamb / near mass / knoll / near ground / far hill) went 0.49 in
    //      round 6 to 0.77 in round 7, against reference plates that diverge to 0.75. At the same
    //      time the mean same-sign run length of the high pass — the width of a MARK — collapsed
    //      from 6.8-10.3 px to 2.2-2.6 px against a board band of 5.4-7.8, the 1-4 px band energy
    //      rose from 0.5-5.3 to 6.4-17.9 against a board 2.0-5.1, and the patch-to-patch variation
    //      of that energy fell from 0.55-1.08 to 0.16-0.68 against a board 0.42-0.95.
    //
    //      THOSE ARE ONE FAULT, NOT FOUR, AND ROUND 7 NAMED IT ITSELF. The footprint gate moved
    //      from max(major axis) to sqrt(minor*major) — see the pixelM block below, which called
    //      the cost "real and paid knowingly". Write the finest fully-drawn wavelength in DISPLAY
    //      pixels: L_px = kDetailPxHi * (major/minor)^t, with t = 1 in round 6 and t = 1/2 in
    //      round 7. Solving the rake ratio R = major/minor per surface from the two rounds'
    //      measured run lengths (R = (runlen6/runlen7)^2) gives R = 1.2 to 18.8 across these
    //      frames — so at t = 1/2 EVERY surface, whatever its rake, draws its finest mark at
    //      about two pixels. One mark width for the whole world is one material for the whole
    //      world, and the spectra duly converged. The mark width, the fine-band energy, the
    //      density variation AND the material sameness are all the same number seen four ways.
    //
    //      Round 8 sets t = 0.72 (kFootprintLean) and lifts the window to 2.5/5.0 px. It does not
    //      return to max(): max() is what emptied the close raked wall (round 6's v5 measured 0.45
    //      of 1-4 px energy — the surface was gone). What fills that register instead is a
    //      vocabulary of its own, below.
    //
    //   j. PER-MATERIAL VOCABULARIES. One field served as every material because one field WAS
    //      every material: a turned, stretched fbm plus five to eight threshold-mark bands, the
    //      same construct on ground, knoll, cliff, jamb and stone with only the wavelengths
    //      differing. Round 8 gives each material marks of its own KIND, not of its own size:
    //        * GROUND — non-directional. The continuous field keeps the turning frame and loses
    //          the anisotropic STRETCH, so ground has no fibre; the concentric F1 rings around the
    //          dab, clump and turf cells (the marbled curl) are cut to a quarter; the texel grain
    //          is gone; and a soft two-octave FORM field blocks in broad shadow shapes.
    //        * STONE — chunky planar facets. Flat tone per polygonal cell, no distance field at
    //          all, band-limited to 45-500 px so a facet is always legible AS a facet. See
    //          TkFacetTone: it is the read "cut planes catching light", and it is what pays for
    //          not going back to max() on the raked faces.
    //        * THE KNOLL — its own treatment, keyed to height (the summit is capped at 50 m
    //          against _HeightHigh 48, so heightT saturates there and nowhere on the floor does).
    //          Upland ground is wind-scoured: bigger marks, more bare ground, less continuous
    //          field. It read as felt because it was the floor's field on a hill.
    //
    //   k. THE ARTIST STOPS SOMEWHERE. rest_frac — the share of 16 px patches whose fine energy
    //      is under 40% of the local median — measured 0.000 on three of eleven surfaces, and a
    //      procedural field that covers 100% of a surface at constant density is the reason.
    //      TkRestField is a FILLED REGION below a threshold (never a band around a midpoint —
    //      that is TkCavityPair's standing rule) whose low tail multiplies every mark amount to
    //      zero. It is a term, not a tuning: "the artist leaves areas at rest" is canon.
    //
    // NOT CHANGED, DELIBERATELY: every one of the seven mark-frame constants (_MarkAniso,
    // _MarkTurnScale, _MarkTurnScaleFine, _MarkTurnSpread, _MarkSizeSpread, _MarkValueSpread,
    // _MarkDensitySpread) is byte-identical to round 7. Orientation VARIATION is a protected
    // round-7 win and nothing here reduces it: the only term that leaves the stretched frame is
    // the meadow's continuous field, and it keeps the TURN.
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
        _MeadowDabWarp ("Meadow Dab Warp", Range(0,1.5)) = 0.55
        // ROUND 8 — THE CONCENTRIC FAMILY, CUT TO A QUARTER. TkDabShaped's .x is the F1 distance
        // to the cell centre, i.e. a RING inside every cell, and this shader drew three of them
        // (dab 6 m, clump 16 m, turf 2.8 m). Nested rings around scattered centres is precisely
        // the marbled curl the round-7 critique read on the ground. What actually carries the
        // round-4 "the eye reads clumps from BOUNDARIES" win is the per-cell FLAT TONE, whose
        // discontinuity at the cell wall IS the boundary — that is untouched. Only the vignette
        // inside each cell is cut: 0.10 -> 0.025 here, 0.11 -> 0.028 on the clump, and 0.55 ->
        // 0.13 on the turf blob (a shader constant, in the turf block).
        _MeadowDabEdge ("Meadow Dab Edge Darken", Range(0,0.4)) = 0.025
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
        _MeadowFineStraw ("Meadow Fine Straw Flecks", Range(0,1)) = 0.16
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
        _MeadowClumpEdge ("Meadow Clump Edge Darken", Range(0,0.35)) = 0.028

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
        // ROUND 7 — the amounts below are now the EFFECTIVE amounts. The eight `kMarkGain`
        // constants that used to multiply them inside this file are gone and the generator writes
        // the product (finding 5a; the mapping is recorded in Ground.cs).
        // ROUND 8 — THE FIBRE RUNGS ARE RETIRED. _RockFleckGrit (2.4 cm) and _RockFleckLight
        // (3.8 cm) were the two bands that landed at the sampling limit under round 7's gate, and
        // a threshold-mark field drawn two pixels wide is not grit, it is hash. Stone's close-range
        // register is now carried by TkFacetTone (cut planes), which is a different KIND of mark
        // and not merely a coarser one — that is the whole of the material-identity finding.
        _RockGrainAmount ("Detail - rock continuous amount", Range(0, 0.8)) = 0.34
        _RockFleckFine ("Detail - rock fleck 6 cm (grit)", Range(0, 0.9)) = 0.60
        _RockFleckMid ("Detail - rock fleck 17 cm (weathering)", Range(0, 0.9)) = 0.72
        _RockFleckCoarse ("Detail - rock fleck 56 cm (patches)", Range(0, 0.9)) = 0.62
        // LIGHT marks. Round 6 had exactly one mark VALUE on every surface — dark — which is half
        // of the round-6 confetti finding ("one size, one lean, one value"). These two bands run
        // the identical construct with the sign flipped, so a lit face carries pale grit catching
        // the rake as well as dark pitting, and the mean-preserving divisor still holds.
        _RockFleckLightMid ("Detail - rock LIGHT fleck 14.5 cm", Range(0, 0.9)) = 0.50

        // MEADOW. Pushed harder than rock on purpose: near turf measured 9.47% against a
        // reference band of 17.8-36.7 (fable-08 17.76, fable-01 28.81, fable-07 36.69), and the
        // round-4 critique's note is that the CADENCE is already right and only the amplitude is
        // missing. Modelled at 5.0 mm/px: 6.30/12.19/18.44/22.96, 53 levels, anisotropy 1.61.
        // Predicted in capture ~21%, i.e. the lower third of the reference band. Deliberately not
        // further: past about 0.6 continuous amount the model's marks stop being separable and the
        // ground reads as static rather than as paint, and that is a judgement no metric settles.
        // ROUND 8. The 5 cm litter rung is retired with the micro grain for the same reason as
        // the rock's tooth rungs: under the round-7 gate both drew at the sample grid. The
        // continuous amount drops because losing the two finest octaves RAISES the surviving
        // field's variance (fewer decorrelated octaves in the mean), so holding 0.72 would have
        // pushed the mid-band grain index out of the board band it already sits in.
        _MeadowDetailAmount ("Detail - meadow continuous amount", Range(0, 0.8)) = 0.46
        _MeadowFleckMid ("Detail - meadow fleck 16 cm (tussock)", Range(0, 0.9)) = 0.62
        _MeadowFleckCoarse ("Detail - meadow fleck 56 cm (tufts)", Range(0, 0.9)) = 0.70
        _MeadowFleckStand ("Detail - meadow fleck 2.1 m (stands)", Range(0, 0.9)) = 0.72
        _MeadowFleckLight ("Detail - meadow LIGHT fleck 24 cm", Range(0, 0.9)) = 0.52

        // -- THE MARK FRAME (round 7, finding 1) ---------------------------------------------
        // Round 6 stretched every mark along world horizontal by ONE constant, which fixed the
        // contour lock and replaced it with wallpaper: the block-wise stroke direction over the
        // meadow collapsed to a single lean (measured spread 0.15 -> 0.02 on v1 with this round's
        // implementation). A painter's strokes turn with the passage of ground they are
        // describing. The mark frame is therefore ROTATED by a two-octave world field — coarse for
        // a wide shot, fine so that a two-metre wall crop varies inside one frame — and the same
        // pair of fields also drives per-region mark SIZE, VALUE and DENSITY (finding 2).
        //
        // It is still WORLD-LOCKED and still cannot trace a contour: nothing here reads the
        // surface normal, the strike, or any projection. The round-6 win is structural and is kept.
        _MarkAniso ("Mark - stretch along the frame axis", Range(1, 4)) = 2.2
        _MarkTurnScale ("Mark - turn field coarse (m)", Float) = 24.0
        _MarkTurnScaleFine ("Mark - turn field fine (m)", Float) = 1.9
        _MarkTurnSpread ("Mark - turn spread (radians, peak to peak)", Range(0, 3.2)) = 1.15
        _MarkSizeSpread ("Mark - per-region size spread", Range(0, 0.8)) = 0.33
        _MarkValueSpread ("Mark - per-region value spread", Range(0, 0.8)) = 0.36
        _MarkDensitySpread ("Mark - per-region threshold shift", Range(0, 0.15)) = 0.045

        [Header(Facets    the stone vocabulary)]
        // CHUNKY PLANAR FACETS (round 8). A flat tone per jittered POLYGONAL cell and nothing
        // else: no distance field, no ring, no frame. A cell wall is a perpendicular bisector, so
        // its edges are straight and its interior is one value — the read is a cut plane catching
        // the rake, which is what stone is and what fibre is not. Three rungs a factor 3.3 apart,
        // each BAND-LIMITED in pixels (TkFacetWindow) so a facet is only ever drawn while it is
        // between 45 and 500 px: below that it is aliasing, above it is a flat wash. At any one
        // footprint one or two rungs are in window, which is why this reads at the jamb's 1.5 mm
        // a pixel AND on a standing stone at thirty metres.
        _FacetBaseScale ("Facet - finest cell (m)", Float) = 0.12
        _FacetRatio ("Facet - rung ratio", Float) = 3.30
        _FacetAmount ("Facet - value swing", Range(0, 0.5)) = 0.20

        [Header(Rest    where the artist stopped)]
        // "The artist leaves areas at rest" is canon and round 7 had none: rest_frac measured
        // 0.000 on three of eleven surfaces because a procedural field covers everything at
        // constant density. Two soft octaves; the LOW TAIL multiplies every mark amount to zero.
        // A filled region below a threshold, never a band around a midpoint — TkCavityPair's rule
        // — so this cannot draw a worm. The same field, mean-centred, doubles as the broad soft
        // FORM SHADOW the reference plates block in before they lay a single mark.
        _RestMeadowScale ("Rest - meadow fine octave (m)", Float) = 0.75
        _RestRockScale ("Rest - stone fine octave (m)", Float) = 0.30
        _RestRatio ("Rest - coarse octave multiple", Float) = 3.2
        _RestLow ("Rest - fully at rest below", Range(0, 0.5)) = 0.33
        _RestHigh ("Rest - fully worked above", Range(0, 0.8)) = 0.45
        _FormShadow ("Form shadow - broad soft value swing", Range(0, 0.2)) = 0.055

        [Header(Upland    the knoll)]
        // THE KNOLL'S OWN TREATMENT. It read as felt because it was the valley floor's field on a
        // hill. The summit is capped at 50 m (Landform step 6c) against _HeightHigh 48, so heightT
        // saturates on the knoll and on nothing the player walks on down in the bowl — that is the
        // handle, and it is a landform property rather than a per-object one. Upland ground is
        // wind-scoured: the marks grow, more of it is left bare, and the continuous field thins.
        _UplandStart ("Upland - begins (heightT)", Range(0,1)) = 0.62
        _UplandEnd ("Upland - full (heightT)", Range(0,1)) = 0.95
        _UplandSize ("Upland - extra mark size", Range(0,2)) = 1.10
        _UplandRest ("Upland - extra rest", Range(0,0.8)) = 0.24

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

        // -- THE SUN BLEACH (round 6) -----------------------------------------------------------
        // "White in the light, colour in the shadows" is canon, and a multiply-only shader runs it
        // BACKWARDS: albedo x light makes the brightest fragment the most saturated one. The same
        // mechanism Builder PALETTE put on GrassTuft.shader is copied here verbatim so ground and
        // grass bleach identically — the albedo is drawn toward its own luminance times a
        // near-colourless cream in proportion to how much of the beam actually lands on it.
        //
        // The tint is normalised by its OWN luminance in the fragment, which makes this a PURE
        // CHROMA move: at bleach 1.0 the fragment's luminance is unchanged to within the tint's
        // rounding, so none of the lamp/exposure arithmetic and none of round 6's amplitude
        // arithmetic (which is measured on luma) is disturbed by it at any setting.
        _SunBleach ("Sun Bleach (chroma removed at full beam)", Range(0, 1)) = 0.5
        _BleachStart ("Sun Bleach Start (light reach)", Range(0, 1)) = 0.28
        _BleachTint ("Sun Bleach Tint (normalised to luma 1)", Color) = (0.98, 0.96, 0.94, 1)
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
            float _MeadowDabWarp;
            float _MeadowDabEdge;
            float _MeadowDabAniso;
            float _MeadowDabSize;
            float _MeadowStrawAmount;
            float _MeadowScuffAmount;
            float _MeadowCoolAmount;
            float _MeadowFineStraw;
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
            float _RockFleckLightMid;
            float _MeadowDetailAmount;
            float _MeadowFleckMid;
            float _MeadowFleckCoarse;
            float _MeadowFleckStand;
            float _MeadowFleckLight;
            float _MarkAniso;
            float _MarkTurnScale;
            float _MarkTurnScaleFine;
            float _MarkTurnSpread;
            float _MarkSizeSpread;
            float _MarkValueSpread;
            float _MarkDensitySpread;
            float _FacetBaseScale;
            float _FacetRatio;
            float _FacetAmount;
            float _RestMeadowScale;
            float _RestRockScale;
            float _RestRatio;
            float _RestLow;
            float _RestHigh;
            float _FormShadow;
            float _UplandStart;
            float _UplandEnd;
            float _UplandSize;
            float _UplandRest;
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
            float _SunBleach;
            float _BleachStart;
            float4 _BleachTint;
        CBUFFER_END

        // The penumbra tap ring (see the Frag lighting block). Unit offsets in the light's own frame:
        // x runs ALONG the sun's compass bearing, y across it. Across the beam the soft band is the
        // sun's raw 0.53°; along it, that band stretched by the rake, so the ring is an ellipse and
        // kPenumbraAcross is sin(12°) — SunEuler's elevation, quoted rather than derived, because
        // the shading normal here has already been perturbed by the relief term and is no longer a
        // safe place to read the lamp's angle from.
        static const float kPenumbraAcross = 0.21;

        // -- ROUND 6: WHAT WAS ACTUALLY WRONG WITH THE RING -------------------------------------
        // The round-5 critique's hypothesis was that the taps land inside one shadow texel. THAT IS
        // NOT TRUE, and the arithmetic is worth writing down so nobody re-tests it. The near cascade
        // is 2048 texels over ~18 m = 8.8 mm a texel (this file's own round-5 note). The offsets are
        // in WORLD METRES and go straight into TransformWorldToShadowCoord, so:
        //
        //     offset 1.00 m along the bearing = 114 texels
        //     offset 0.50 m along the bearing =  57 texels
        //     offset 0.71 x 0.21 = 0.149 m across = 17 texels
        //
        // The taps are 17 to 114 texels apart. They were sampling completely different parts of the
        // map. The fault is the RING'S SHAPE, not its scale:
        //
        //   * FIVE OF THE NINE TAPS (the centre plus the four pure-along taps) sat at EXACTLY ZERO
        //     across-offset. A kernel that is 56 per cent delta function does almost nothing to an
        //     edge no matter how wide the remaining 44 per cent reaches.
        //   * The remaining four spanned +-0.149 m across the bearing — and a 12 deg sun's shadows
        //     are long and thin, so their DOMINANT edges (the long sides) run ALONG the bearing.
        //     The ellipse's long axis was parallel to the very edges it was built to soften; all it
        //     could soften was the short leading and trailing ends.
        //
        // Rebuilt as a proper elliptical ring: eight taps, none at zero across-offset, none
        // duplicating another's across-offset, and the across-coverage sampled evenly at
        // +-1.00, +-0.66 and +-0.33 of the half-width. The along-axis still carries the rake
        // stretch (kPenumbraAcross = sin 12 deg), so the physics is unchanged — the sun's 0.53 deg
        // across the beam, that band raked out by 1/sin(12 deg) along it. Only the SAMPLING changed.
        static const float2 kPenumbraTaps[8] =
        {
            float2( 0.92,  0.33), float2(-0.92, -0.33),
            float2( 0.38, -1.00), float2(-0.38,  1.00),
            float2( 0.71, -0.66), float2(-0.71,  0.66),
            float2( 0.15,  0.98), float2(-0.15, -0.98)
        };

        // -- Hashes -----------------------------------------------------------------------------
        // Hash-based so the surface is deterministic in world space: the same metre of ground gets
        // the same mottling every run, and re-generating a region cannot reshuffle its look.
        // ROUND-6, MEASURED FAULT. The old form was `frac(p * float2(123.34, 456.21))`, and it was
        // handed LATTICE INDICES, not world metres: TkValueNoise floors its argument first, so at a
        // 3 cm band the index at the Cliff's own world coordinates (x,z ≈ 150-215 m) is ~6700, and
        // 6700 * 456.21 = 3.06e6. float32 has 24 bits of mantissa, so the ULP at 3e6 is 0.25 and
        // frac() of it can only land on four values. A numpy transcription in float32 counted the
        // DISTINCT hash values over 400 consecutive cells:
        //
        //     band            world 60 m   world 200 m   world 512 m
        //     rock fine 3 cm       55            16            8       (of 400 possible)
        //     meadow fine 4.5 cm  106            32            8
        //
        // Every fine field in this shader was therefore drawing a short repeating ramp, not noise —
        // and a hash that has collapsed along one axis draws STRIPES, which is half of what the
        // round-5 critique measured as directional grain. The multiplier is the whole bug: keep the
        // product small and the mantissa survives. This is the same small-multiplier construction
        // TkHash22 below has always used (0.1031 / 0.1030 / 0.0973), so the two are now consistent.
        // Re-measured with the form below: 357-392 distinct values of 400 at every world coordinate.
        float TkHash21(float2 p)
        {
            float3 p3 = frac(float3(p.x, p.y, p.x) * float3(0.1031, 0.1030, 0.0973));
            p3 += dot(p3, p3.yzx + 33.33);
            return frac((p3.x + p3.y) * p3.z);
        }

        // 3-D companion, same construction. It exists so the mark fields below can live in WORLD
        // SPACE with no projection and no frame at all — see the round-6 note on TkFleckBand3.
        float TkHash31(float3 p)
        {
            float3 p3 = frac(p * float3(0.1031, 0.1030, 0.0973));
            p3 += dot(p3, p3.yzx + 33.33);
            return frac((p3.x + p3.y) * p3.z);
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

        // -- 3-D value noise (round 6) ------------------------------------------------------------
        // Eight hashes a tap against the 2-D version's four, and it REPLACES a triplanar, which is
        // three 2-D taps (twelve hashes) — so the stone stack gets cheaper, not dearer, at the same
        // time as it gets correct. What it buys is that a 3-D field has NO PROJECTION and therefore
        // NO FRAME: nothing about it can rotate with the surface normal, so nothing about it can
        // lock to a contour. See the round-6 header note on the strike frame.
        float TkValueNoise3(float3 p)
        {
            float3 i = floor(p);
            float3 f = p - i;
            float3 u = f * f * (3.0 - 2.0 * f);
            float a000 = TkHash31(i + float3(0, 0, 0));
            float a100 = TkHash31(i + float3(1, 0, 0));
            float a010 = TkHash31(i + float3(0, 1, 0));
            float a110 = TkHash31(i + float3(1, 1, 0));
            float a001 = TkHash31(i + float3(0, 0, 1));
            float a101 = TkHash31(i + float3(1, 0, 1));
            float a011 = TkHash31(i + float3(0, 1, 1));
            float a111 = TkHash31(i + float3(1, 1, 1));
            float c00 = lerp(a000, a100, u.x);
            float c10 = lerp(a010, a110, u.x);
            float c01 = lerp(a001, a101, u.x);
            float c11 = lerp(a011, a111, u.x);
            return lerp(lerp(c00, c10, u.y), lerp(c01, c11, u.y), u.z);
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
        // ROUND 8 — THE MARK HAS A FLOOR WIDTH. At 1.6/3.2 a band was fully drawn the moment it
        // spanned 3.2 px, and combined with round 7's geometric-mean footprint that put the mean
        // same-sign run length of the high pass at 2.2-2.6 px across every surface in every frame,
        // against a reference-board band of 5.4-7.8. A mark two pixels wide is not a mark; it is
        // the sampling grid wearing the material's name. 2.5/5.0 is a 1.56x lift, and it is the
        // smaller half of the fix — the other half is kFootprintLean below.
        static const float kDetailPxLo = 2.5;
        static const float kDetailPxHi = 5.0;

        // THE FOOTPRINT LEAN (round 8). pixelM = minor^(1-lean) * major^lean. Round 6 used
        // lean = 1 (max, the honest anti-aliasing bound) and emptied every raked face; round 7
        // used lean = 0.5 (the geometric mean, sqrt of the footprint area) and put every surface's
        // finest mark at the same two pixels regardless of its rake — which is the material-
        // sameness finding, because L_px = kDetailPxHi * (major/minor)^lean and at lean = 0.5 the
        // measured rake ratios 1.2-18.8 collapse to a spread of one octave and a half instead of
        // four. 0.72 restores three quarters of that spread. The residual undersampling along the
        // major axis is (major/minor)^(1-lean) = at most 2.0x at R = 18.8, against round 7's 4.3x,
        // so this is also STRICTLY less aliasing than what shipped.
        static const float kFootprintLean = 0.72;

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

        // -- ROUND 6: THE FRAME, WHICH IS THE WHOLE OF THE CONTOUR LOCK ---------------------------
        //
        // Round 5 replaced the stone branch's noise wholesale and the chevron / wood-grain artifact
        // SURVIVED IT, because the noise was never what was oriented. Two constructs oriented it:
        //
        //   1. the triplanar blend below, whose three weights are a function of the surface normal,
        //      so the field's effective projection ROTATES with the landform; and, far worse,
        //   2. `faceUV = float2(dot(gp3.xz, strike), gp3.y)` in the stone branch, where `strike` is
        //      the horizontal direction lying in the surface — i.e. THE CONTOUR DIRECTION ITSELF.
        //
        // (2) is not a stylistic slip, it is an arithmetic one, and it can be written down exactly.
        // dot(P.xz, strike) is only an arclength coordinate if the surface is a plane. Step a
        // distance ds along the surface horizontally and
        //
        //     d(faceUV.x)/ds = 1 - kappa * (P . n)
        //
        // where kappa is the face's horizontal curvature and (P . n) is the world position resolved
        // on the normal. The Cliff sits at world x,z ≈ 150-215 m, so (P . n) is 150-250 m, while a
        // wall's curvature radius is 10-60 m — the second term is 3 to 18 times the first and it
        // SETS THE SIGN. Evaluated over a family of walls at the region's own coordinates the
        // derivative runs -17.8, -15.0, -8.6, -7.2, -3.6, -2.4 ... and passes through zero on any
        // face where kappa*(P.n) = 1. Where it is large the marks are crushed; where it crosses zero
        // they are infinitely elongated ALONG THE CONTOUR. That is the wood grain, that is why it is
        // immune to changing the noise, and that is why it got worse as the region moved away from
        // the world origin.
        //
        // The fix is to have no frame. TkDetailFbm3 and TkFleckBand3 take a WORLD-SPACE 3-D
        // position: no projection, no normal, no strike, nothing that can rotate. They cost eight
        // hashes a tap where the triplanar cost twelve, so the stone stack is cheaper afterwards.
        //
        // ANISOTROPY IS KEPT, BUT WORLD-LOCKED. Painterly rock is not isotropic mush and the
        // reference plates are not either (measured structure-tensor coherence 0.27-0.55 on my
        // implementation over fable-01/03/06/07 and kena-01). The 3-D lookup divides ONE horizontal
        // component by _MarkAniso, which stretches every mark along a horizontal axis — weathering
        // runs along a bed — and that axis cannot trace a contour, because it is a function of
        // world position and of nothing else. On a curving nose the marks keep their lean while the
        // contour turns, which is what the reference plates show.
        // Modelled at the v8 wall's footprint: coherence 0.14 at aniso 1.0, 0.55 at 2.2, 0.47 at 2.0.
        // ROUND 7 REPLACES THE CONSTANT WITH A FIELD, and the constant is exactly what the round-6
        // critique measured: one stretch axis over the whole region is one lean over the whole
        // frame. `_MarkAniso` is now the stretch AMOUNT and the stretch AXIS turns with a
        // two-octave world field (`_MarkTurnScale` ~ a region, `_MarkTurnScaleFine` ~ a passage of
        // wall you can see all of at two metres). Both octaves are functions of world XZ ONLY, so
        // the round-6 contour-lock fix is untouched: nothing here can rotate with a surface normal.
        //
        // The same four fields carry the rest of finding 2. `TkMarkVary` returns four decorrelated
        // slow randoms and the caller spends them on TURN, SIZE, VALUE and DENSITY, so no two
        // patches of the same rock carry the same mark family — which is the whole difference
        // between paint and a stamp.
        struct TkMarkFrame
        {
            float2 turn;      // cos/sin of this region's stroke angle
            float size;       // wavelength multiplier
            float value;      // contrast multiplier
            float shift;      // threshold shift (negative = denser)
        };

        float4 TkMarkVary(float2 p)
        {
            float sc = 1.0 / max(_MarkTurnScale, 0.01);
            float fc = 1.0 / max(_MarkTurnScaleFine, 0.01);
            // 60/40 coarse to fine: the coarse octave is what a wide shot reads, the fine octave is
            // what a two-metre crop reads, and a wall crop that samples one value of a 24 m field
            // is precisely how round 6's "one lean" survived a world-space rewrite.
            float4 v;
            v.x = 0.60 * TkValueNoise(p * sc) + 0.40 * TkValueNoise(p * fc);
            v.y = 0.60 * TkValueNoise(p * sc + 71.3) + 0.40 * TkValueNoise(p * fc + 71.3);
            v.z = 0.60 * TkValueNoise(p * sc * 0.61 + 143.9)
                + 0.40 * TkValueNoise(p * fc * 0.61 + 143.9);
            v.w = 0.60 * TkValueNoise(p * sc * 1.37 + 211.7)
                + 0.40 * TkValueNoise(p * fc * 1.37 + 211.7);
            return v;
        }

        TkMarkFrame TkBuildMarkFrame(float2 worldXZ)
        {
            float4 v = TkMarkVary(worldXZ);
            float ang = (v.x - 0.5) * _MarkTurnSpread;
            float sn, cs;
            sincos(ang, sn, cs);
            TkMarkFrame f;
            f.turn = float2(cs, sn);
            f.size = 1.0 + _MarkSizeSpread * (v.y - 0.5) * 2.0;
            f.value = 1.0 + _MarkValueSpread * (v.z - 0.5) * 2.0;
            f.shift = _MarkDensitySpread * (v.w - 0.5) * 2.0;
            return f;
        }

        // Density is moved by shifting the mark thresholds, so the mean-preserving divisor has to
        // be told what that did to the coverage. kCoverageSlope is d(coverage)/d(-shift) measured
        // over the shipped fields' own population (a 0.045 shift moves coverage by ~16% of itself);
        // without it a denser region would also be a DARKER region and the density variation would
        // read as blotching.
        static const float kCoverageSlope = 3.6;

        float TkMarkCoverage(float coverage, float shift)
        {
            return max(coverage * (1.0 + shift * kCoverageSlope), 0.0);
        }

        // The frameless mark space, now turned. Horizontal is rotated into the region's stroke
        // axis and THAT axis is the one stretched; world Y is untouched, so a bed still reads
        // horizontal on a wall and the stretch is a lean rather than a shear.
        float3 TkMarkSpace(float3 worldPos, TkMarkFrame f)
        {
            float2 h = float2(worldPos.x * f.turn.x - worldPos.z * f.turn.y,
                              worldPos.x * f.turn.y + worldPos.z * f.turn.x);
            h.x /= max(_MarkAniso, 1.0);
            return float3(h.x, worldPos.y, h.y);
        }

        // The meadow's twin: the ground is read from above, so its marks live in the horizontal
        // plane and the same turn/stretch applies in 2-D.
        float2 TkMarkSpace2(float2 worldXZ, TkMarkFrame f)
        {
            float2 h = float2(worldXZ.x * f.turn.x - worldXZ.y * f.turn.y,
                              worldXZ.x * f.turn.y + worldXZ.y * f.turn.x);
            h.x /= max(_MarkAniso, 1.0);
            return h;
        }

        // -- MARK CONTRAST: THE GAINS ARE RETIRED (round 7, finding 5a) ---------------------------
        // Round 6 carried eight `k*Gain` constants here because the generator was owned by another
        // builder that round and a shader default could not reach the render. Both files move
        // together this round, so the gains are GONE and the generator writes the product it used
        // to write the factor of. The retired mapping, for anyone reading a round-6 capture:
        //
        //     property              r6 generator  x r6 gain   = r7 generator value
        //     _RockGrainAmount           0.40       1.65           0.66  -> re-solved to 0.80
        //     _RockFleckFine             0.58       1.48           0.86  -> re-solved to 0.88
        //     _RockFleckMid              0.46       1.78           0.82  -> re-solved to 0.80
        //     _RockFleckCoarse           0.34       1.88           0.64  -> THINNED to 0.50
        //     _MeadowDetailAmount        0.52       1.19           0.62  -> re-solved to 0.72
        //     _MeadowFleckFine           0.72       1.11           0.80  -> re-solved to 0.88
        //     _MeadowFleckMid            0.58       1.24           0.72  -> re-solved to 0.84
        //     _MeadowFleckCoarse         0.48       1.25           0.60  -> re-solved to 0.78
        //
        // There is now exactly one number per band and it lives in Ground.cs. Do not reintroduce a
        // gain here: a factor folded in silently is what made round 6's arithmetic unauditable.

        // Clamped, because a mark amount above 1 makes (1 - mark*amount) negative at the centre of
        // a mark and paints a black hole. 0.90 is the properties' own Range maximum. The per-region
        // VALUE multiplier is applied here so the clamp sees it, and the sign is preserved so the
        // same helper serves the light bands (which pass a negative amount).
        float TkMarkAmount(float property, float regionValue)
        {
            float a = property * max(regionValue, 0.0);
            return min(a, 0.90);
        }

        float TkDetailFbm3(float3 p, float baseM, float pixelM)
        {
            float lam = max(baseM, 1e-4);
            float3 q = p / lam;

            float w = TkOctaveWeight(lam, pixelM);
            float sum = TkValueNoise3(q) * w;
            float tot = w;

            q = float3(TkTurn(q.xy * 2.71 + 17.3, kTurn1), q.z * 2.71 + 11.9); lam /= 2.71;
            w = TkOctaveWeight(lam, pixelM) * 0.80;
            sum += TkValueNoise3(q) * w; tot += w;

            q = float3(TkTurn(q.xy * 2.71 + 17.3, kTurn2), q.z * 2.71 + 11.9); lam /= 2.71;
            w = TkOctaveWeight(lam, pixelM) * 0.64;
            sum += TkValueNoise3(q) * w; tot += w;

            q = float3(TkTurn(q.xy * 2.71 + 17.3, kTurn3), q.z * 2.71 + 11.9); lam /= 2.71;
            w = TkOctaveWeight(lam, pixelM) * 0.512;
            sum += TkValueNoise3(q) * w; tot += w;

            return tot > 1e-4 ? sum / tot : 0.5;
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

        // The frameless twin (round 6). Identical construct, 3-D lookups, world space, and the
        // caller passes an already-anisotropy-scaled position (TkMarkSpace) so the mark family has
        // ONE fixed shape everywhere in the region. The coverages are re-measured for the new
        // wavelengths and thresholds over the same 40 m population sample.
        float2 TkFleckBand3(float3 p, float lamA, float lamB, float2 thr,
                            float coverage, float amount, float pixelM)
        {
            float w = TkOctaveWeight(lamA, pixelM);
            UNITY_BRANCH
            if (w <= 0.002) return float2(1.0, 0.0);
            float a = TkValueNoise3(p / max(lamA, 1e-4));
            float b = TkValueNoise3(p / max(lamB, 1e-4) + 11.3);
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

        // -- CHUNKY PLANAR FACETS (round 8) — the STONE vocabulary -------------------------------
        // The winning cell's FLAT TONE and nothing else. TkDabShaped's own header and round 5's
        // detail-stack note both warn that a Worley field creases along every cell wall; that
        // warning is about the F1 DISTANCE, which is a radial gradient inside each cell and
        // therefore both a ring and a crease network. The TONE is piecewise constant: its only
        // discontinuity IS the cell wall, and a cell wall is a perpendicular bisector — a straight
        // edge between two flat values, which is a cut plane. The aspect and size jitter are kept
        // modest on purpose (0.35 / 0.40 against the meadow dab's 0.55 / 0.45): a stretched cell is
        // a stringy cell, and stringy is the fibre this term exists to replace.
        float TkFacetTone(float2 p)
        {
            float2 cell = floor(p);
            float2 f = p - cell;
            float best = 8.0;
            float tone = 0.0;

            [unroll]
            for (int y = -1; y <= 1; y++)
            {
                [unroll]
                for (int x = -1; x <= 1; x++)
                {
                    float2 g = float2(x, y);
                    float2 h = TkHash22(cell + g);
                    float2 sj = TkHash22(cell + g + 37.19);
                    float2 d = g + h - f;

                    float sn, cs;
                    sincos(sj.x * 6.2831853, sn, cs);
                    float2 r = float2(d.x * cs - d.y * sn, d.x * sn + d.y * cs);
                    float stretch = max(1.0 + 0.35 * (sj.y - 0.5) * 2.0, 0.25);
                    r.x /= stretch;
                    r.y *= stretch;
                    float radius = max(1.0 + 0.40 * (frac(sj.x * 7.31 + sj.y * 3.17) - 0.5) * 2.0, 0.25);
                    float sq = dot(r, r) / (radius * radius);

                    tone = sq < best ? frac(h.x * 3.71 + h.y * 7.13) : tone;
                    best = min(best, sq);
                }
            }
            return tone;
        }

        // A facet is only a facet between about 45 and 500 pixels. Below the lower edge a hard
        // tone step is aliasing (this term has no soft edge to fade, so it is BRANCHED away rather
        // than merely weighted); above the upper edge it is a flat wash that says nothing and
        // costs nine hashes. Band-limiting in PIXELS is what lets one ladder serve the jamb at
        // 1.5 mm a pixel and a standing stone at thirty metres.
        float TkFacetWindow(float lambdaM, float pixelM)
        {
            float n = lambdaM / max(pixelM, 1e-6);
            return smoothstep(45.0, 90.0, n) * (1.0 - smoothstep(320.0, 560.0, n));
        }

        // -- REST (round 8) ----------------------------------------------------------------------
        // Two soft octaves of value noise, mean 0.5. The returned .x is the WORKED weight: 0 in the
        // low tail (the artist stopped here), 1 above _RestHigh. The returned .y is the raw field,
        // which the callers use mean-centred as a broad soft FORM SHADOW — the block-in a painter
        // does before laying a mark, and the 100-300 px value shape the reference plates all have
        // and this material had none of.
        //
        // STRUCTURAL NOTE, and it is the same one TkCavityPair's header makes: this selects a
        // FILLED REGION below a threshold. It is not a band around the field's midpoint, so it
        // cannot draw a level set, so it cannot draw a worm. Do not rewrite it as 1 - |2f - 1|.
        float2 TkRestField(float2 p, float fineM, float ratio)
        {
            float a = TkValueNoise(p / max(fineM, 1e-3));
            float b = TkValueNoise(p / max(fineM * ratio, 1e-3) + 37.7);
            float f = 0.55 * a + 0.45 * b;
            return float2(smoothstep(_RestLow, _RestHigh, f), f);
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
                //
                // ROUND 6 — READ THIS BEFORE QUOTING A NUMBER OFF THIS QUANTITY. max() is the MAJOR
                // axis of an anisotropic footprint, and on RAKED ground the major axis is not
                // alpha*d, it is alpha*d^2/h. At the v6 camera (h = 1.65 m, 45 deg over 1080 px):
                //
                //     distance      minor        major (= pixelM)      ratio
                //        5 m       3.8 mm            11.6 mm            3.0
                //       12 m       9.2 mm            66.9 mm            7.3
                //       40 m      30.7 mm           743.8 mm           24.2
                //      100 m      76.7 mm          4648.9 mm           60.6
                //
                // Round 5's detail-stack model quoted its amplitudes at pixelM = alpha*d — the
                // FACE-ON footprint — and so claimed 11.5 per cent at 40 m where the real footprint
                // is 24x larger and every octave is switched off. That is the whole of why a
                // complete rewrite of the meadow branch moved the measurement 11.89 -> 11.66.
                //
                // max() STAYS, and it is not the bug. min() would keep marks that are undersampled
                // by up to 24x along the major axis, which is aliasing, not detail: a band is fully
                // drawn at lambda/pixelM >= kDetailPxHi = 3.2, so a footprint of hi/k admits marks
                // down to lambda = 3.2*hi/k, and Nyquist needs lambda >= 2*hi — safe only for
                // k <= 1.6. The gate is right; the LADDER was wrong, and both ladders below have
                // been re-pitched to wavelengths that survive at the distances these frames contain.
                //
                // ROUND 7 TAKES THE MIDDLE, AND IT IS THE WHOLE OF FINDING 3. max() is the honest
                // anti-aliasing bound and it is also why the close raked wall in v5 had NOTHING
                // below its coarsest band: measured on the round-6 capture, the wall crop's power
                // spectrum carries 2.4e-3 of its energy below 8 px against round 5's 4.7e-2 — a
                // twenty-fold collapse — and the metric that reads "confetti" reads exactly that.
                // The gate here is the GEOMETRIC MEAN of the two axes, i.e. sqrt of the footprint's
                // AREA, which is what a single filtered tap of a band-limited field actually
                // resolves; it is the same quantity a mip selector would pick for an isotropic
                // approximation of an anisotropic footprint. Bands between the minor axis and the
                // geometric mean are drawn and are undersampled ALONG ONE AXIS ONLY, by at most
                // sqrt(major/minor) — 2.7x at 12 m, 4.9x at 40 m on the v6 camera. That is a real
                // cost and it is paid knowingly: the world is BOUND, nothing in it moves, and a
                // still frame that has a surface beats a still frame that shimmers in a future one.
                // If a later round adds motion and this shimmers, the fix is a second tap along
                // the major axis, not a return to max().
                //
                // ROUND 8 REPLACES THE GEOMETRIC MEAN WITH A LEAN (see kFootprintLean). The note
                // above is right that max() left the raked wall empty and wrong that the middle is
                // free: measured across rounds 6 and 7, moving from max() to the geometric mean is
                // what took the mark width from 6.8-10.3 px to 2.2-2.6 px, took the 1-4 px band
                // from 0.5-5.3 to 6.4-17.9, and — because it gives every surface in the frame the
                // same mark width in pixels whatever its rake — is what collapsed the material
                // spectra together. The register max() emptied is now filled by a mark of a
                // different KIND (TkFacetTone) rather than by admitting a finer one of the same.
                float pixelMajor = max(max(length(dpdx), length(dpdy)), 1e-5);
                float pixelMinor = max(min(length(dpdx), length(dpdy)), 1e-5);
                float pixelM = pow(pixelMinor, 1.0 - kFootprintLean) * pow(pixelMajor, kFootprintLean);

                // The region's mark frame — turn, size, value, density — built ONCE, outside both
                // branches, and shared by the meadow and the stone so a boulder and the turf it
                // sits in are painted by the same hand in the same direction (round 7, findings 1
                // and 2). It is a function of world XZ only.
                TkMarkFrame markFrame = TkBuildMarkFrame(gp);

                // THE KNOLL'S HANDLE (round 8). Landform step 6c caps the knoll's summit at 50 m
                // against _HeightHigh 48, so heightT saturates up there and reaches nothing on the
                // bowl floor. This is therefore a LANDFORM property, not an object reference, and
                // it is the only thing in this file that gives one hill a treatment of its own.
                float upland = smoothstep(_UplandStart, _UplandEnd, heightT);

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
                    // ROUND 8: 0.55 -> 0.13. (1 - turfDab.x) is the F1 distance again, i.e. a
                    // concentric blob centred in every turf cell — the third and largest member of
                    // the curl family this material was drawing. Cut to a quarter, not to zero: the
                    // mat and the meadow are still the same plant at two densities, they are just
                    // no longer joined by a ring.
                    turf = lerp(turf, _MeadowGreen.rgb, saturate((1.0 - turfDab.x) * 0.13));

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
                    // ROUND 7: the meadow's marks are laid in the region's own stroke frame too.
                    // On raked ground an isotropic world field projects to a screen field that is
                    // horizontally streaked EVERYWHERE, which is the second half of the wallpaper
                    // finding — the lean was constant because foreshortening, not the shader, was
                    // choosing it. Turning and stretching the frame per region is what puts a
                    // different angle in a different patch of floor.
                    // ROUND 8 — REST AND FORM, before a single mark is laid. The broad field is
                    // mean-centred and applied as a value shape (the block-in); its low tail is
                    // carried into every mark amount below as `worked`, and the upland is left
                    // barer still because wind-scoured ground is exactly what has less on it.
                    float2 restM = TkRestField(gp, _RestMeadowScale, _RestRatio);
                    float worked = saturate(restM.x - _UplandRest * upland);
                    ground *= 1.0 + (restM.y - 0.5) * 2.0 * _FormShadow;

                    float2 mgp = TkMarkSpace2(gp, markFrame);
                    // The knoll's marks are BIGGER. Same ladder, one landform, a coarser hand.
                    float mSize = max(markFrame.size, 0.35) * (1.0 + _UplandSize * upland);

                    // THE GROUND'S CONTINUOUS FIELD IS NON-DIRECTIONAL (round 8). It keeps the
                    // region's TURN — that is the protected round-7 win and removing it would be
                    // round 6's wallpaper again — and loses only the anisotropic STRETCH, by
                    // passing an unstretched frame. Ground seen from above is not fibrous; a
                    // stretched fbm under five stretched mark bands is what made it read as one.
                    // The mark bands below keep the stretch, so the STROKES still lean and still
                    // turn with the passage of ground; only the tone underneath them is isotropic.
                    TkMarkFrame flatFrame = markFrame;
                    float2 igp = float2(gp.x * flatFrame.turn.x - gp.y * flatFrame.turn.y,
                                        gp.x * flatFrame.turn.y + gp.y * flatFrame.turn.x);
                    float detail = TkDetailFbm(igp, _MeadowDetailScale * mSize, pixelM);
                    ground *= 1.0 + (detail - 0.5) * 2.0
                        * TkMarkAmount(_MeadowDetailAmount, markFrame.value) * worked;

                    // THE LADDER IS RE-PITCHED (round 6, finding 3 — see the pixelM note above
                    // for the proof that round 5's rungs were switched off in the frames that were
                    // measured). Ground is seen RAKED, and the footprint that decides whether a
                    // mark is drawable grows as alpha*d^2/h, not alpha*d. Rungs at 4.5 / 17 / 90 cm
                    // are all off by 30-45 m; the meadow then has nothing between the 90 cm rung and
                    // the 6 m dab, which is exactly the band the middle distance is made of.
                    //
                    // Moved to 5 / 32 / 210 cm the ladder covers, at the v6 camera height:
                    //   5 cm   0-8 m      32 cm   0-14 m      210 cm   0-45 m      6 m dab  to 75 m
                    // Modelled albedo relative amplitude, shipped -> re-pitched, against distance:
                    //   12 m 14.7 -> 21.6     20 m 20.8 -> 23.9     30 m 21.9 -> 28.9
                    //   45 m  0.0 -> 4.6      (45 m was six exact no-ops before this change)
                    // Coverages re-measured for the new wavelengths over the same 40 m sample.
                    //
                    // ROUND 7 ADDS A RUNG AND A SECOND VALUE. Round 6 left a hole between 32 cm and
                    // 2.1 m — nearly three octaves — which is most of what the eye reads at 8-25 m,
                    // and every mark it did draw was DARK. The ladder is 5 / 16 / 56 / 210 cm plus a
                    // 7.5 cm LIGHT band, all five wavelengths scaled per region by markFrame.size
                    // and all five thresholds shifted per region by markFrame.shift, so no two
                    // patches of meadow carry the same mark size or the same mark density.
                    //
                    // ROUND 8 DROPS THE 5 cm RUNG AND MOVES THE PALE BAND UP. Under the new gate a
                    // 5 cm mark is under 2.5 px at any distance these frames contain past about
                    // four metres, so it was a hash generator rather than litter; the pale band
                    // moves 7.5 -> 24 cm for the same reason. What is left is 16 / 56 / 210 cm dark
                    // and 24 cm light, all four still scaled by markFrame.size (and by the upland),
                    // all four still threshold-shifted per region, and all four now multiplied by
                    // `worked` so the whole ladder stops where the artist stopped.
                    float2 thrB = float2(0.48, 0.78) - markFrame.shift;
                    float2 thrC = float2(0.50, 0.79) - markFrame.shift;
                    float2 thrD = float2(0.52, 0.81) - markFrame.shift;
                    float2 thrL = float2(0.52, 0.82) - markFrame.shift;
                    float2 fleckMid = TkFleckBand(mgp + 53.1, 0.160 * mSize, 0.265 * mSize, thrB,
                        TkMarkCoverage(0.120, markFrame.shift),
                        TkMarkAmount(_MeadowFleckMid, markFrame.value) * worked, pixelM);
                    float2 fleckTuft = TkFleckBand(mgp + 131.9, 0.560 * mSize, 0.925 * mSize, thrC,
                        TkMarkCoverage(0.103, markFrame.shift),
                        TkMarkAmount(_MeadowFleckCoarse, markFrame.value) * worked, pixelM);
                    float2 fleckWide = TkFleckBand(mgp + 217.7, 2.100 * mSize, 3.470 * mSize, thrD,
                        TkMarkCoverage(0.083, markFrame.shift),
                        TkMarkAmount(_MeadowFleckStand, markFrame.value) * worked, pixelM);
                    // The pale band. Same construct, amount NEGATED: (1 + mark*a) over a divisor
                    // that grows with it, so it is still mean-preserving and still cannot clip.
                    float2 fleckLight = TkFleckBand(mgp + 401.3, 0.240 * mSize, 0.397 * mSize, thrL,
                        TkMarkCoverage(0.082, markFrame.shift),
                        -TkMarkAmount(_MeadowFleckLight, markFrame.value) * worked, pixelM);
                    ground *= fleckMid.x * fleckTuft.x * fleckWide.x * fleckLight.x;

                    // The finest band also carries HUE, kept from round 4: dry strands and grit
                    // read as colour at texel scale, not as one more brightness wobble. Suppressed
                    // inside the turf, where the ground is damp and shaded by the blades above it.
                    // ROUND 8: the straw hue rides the 16 cm rung now that the 5 cm one is gone,
                    // and at roughly half the amount, because a 16 cm mark carrying 0.28 of straw
                    // is a patch of straw rather than a strand of it.
                    ground = lerp(ground, _MeadowStraw.rgb,
                        fleckMid.y * _MeadowFineStraw * (1.0 - turfMask * 0.6));

                    // THE MICRO GRAIN IS GONE (round 8). A 0.34 m field with no threshold and no
                    // sparsity covered one hundred per cent of the ground at constant density —
                    // the exact construct the rest_frac finding is about — and under the round-7
                    // gate it was drawn down to a pixel and a half. Nothing replaces it: the point
                    // of the finding is that a surface does not need tooth everywhere.

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
                    // ROUND 6: NO FRAME AT ALL. Both the triplanar that was here and the
                    // `dot(gp3.xz, strike)` face frame below it were functions of the surface
                    // normal, which is the terrain gradient, which is the contour. The derivation
                    // and the measured numbers are in the TkDetailFbm3 header; the short version is
                    // that d(faceUV.x)/ds = 1 - kappa*(P.n), which at this region's world
                    // coordinates runs -2 to -18 and passes through zero, so the mark bands were
                    // being sampled at a rate set by the LANDFORM and elongated along its contours.
                    // These four lookups are 3-D and world-space. They also cost less: four 3-D taps
                    // (32 hashes) where the triplanar was twelve 2-D taps (48).
                    // ROUND 8: rest and form on stone too, off its OWN field (a different fine
                    // octave, 0.30 m against the meadow's 0.75) so the two materials do not share
                    // a rest pattern any more than they share a mark.
                    float2 restS = TkRestField(gp3.xz + gp3.y, _RestRockScale, _RestRatio);
                    float workedS = restS.x;
                    stone *= 1.0 + (restS.y - 0.5) * 2.0 * _FormShadow;

                    float3 markPos = TkMarkSpace(gp3, markFrame);
                    float rSize = max(markFrame.size, 0.35);
                    // The continuous field KEEPS its stretch — a bed weathers along its own strike
                    // and stone is legitimately anisotropic (the reference plates measure 0.27-0.55
                    // structure-tensor coherence). What drops is its AMOUNT, 0.80 -> 0.34: it was
                    // the fibre carrier, and the facets below are what stone is made of now.
                    float rockDetail = TkDetailFbm3(markPos, _DetailBaseScale * rSize, pixelM);
                    stone *= 1.0 + (rockDetail - 0.5) * 2.0
                        * TkMarkAmount(_RockGrainAmount, markFrame.value) * workedS;

                    // THE LADDER IS RE-PITCHED (round 6, finding 4). Round 5's rungs were 3 / 11.5 /
                    // 85 cm, and at the v8 wall's measured footprint (1.7 cm a pixel) the 3 cm rung
                    // sits at 1.76 pixels — under kDetailPxLo, so it draws at weight 0.06 — while
                    // the 85 cm rung is 50 pixels across, which a high-pass reads as flat field, not
                    // as texture. Exactly ONE rung of three was doing measurable work. Moved to
                    // 6 / 16.5 / 56 cm the wall gets three: 3.5, 9.7 and 33 pixels. Modelled albedo
                    // relative amplitude at that footprint goes 15.0 -> 25.5 per cent.
                    // Coverages re-measured for the new wavelengths and thresholds.
                    //
                    // ROUND 7 — THE CONFETTI PASS (findings 2, 3 and 4). Measured on the round-6
                    // capture of v5, this branch put 20.1% of the wall inside dark blobs of 150 px
                    // or more and carried 0.2% of its energy below 8 px: one mark size, one mark
                    // value, and nothing at all where a brush leaves tooth. Three changes, each
                    // aimed at one of those numbers:
                    //   * A 2.4 cm TOOTH rung under the 6 cm grit, which is the band the geometric
                    //     -mean footprint above finally admits on a raked face.
                    //   * The 56 cm patch band THINNED HARD — amount 0.64 -> 0.50, threshold
                    //     0.52/0.81 -> 0.56/0.86 and coverage 0.086 -> 0.062. It is the band the
                    //     leopard spots were, and it is now the quietest of the five.
                    //   * Two LIGHT bands, so a face carries pale grit as well as dark pitting.
                    // Modelled through lighting, fog and tonemap at the v5 wall's fitted footprint:
                    // lit relative amplitude 6.8 -> 9.9 per cent, blob coverage 0.201 -> 0.059.
                    //
                    // ROUND 8 RETIRES THE TWO FIBRE RUNGS (2.4 cm dark, 3.8 cm light) and thins
                    // what is left. Both sat at the sampling grid under the round-7 footprint, and
                    // a threshold-mark band drawn two pixels wide contributes hash, not grit — it
                    // is most of why this branch's 1-4 px energy measured 6.4-17.9 against a board
                    // of 2.0-5.1. Stone keeps PITTING (three dark bands, one pale) because pitting
                    // is a real and different thing from a cut plane; the cut planes are below.
                    float2 rThrA = float2(0.46, 0.76) - markFrame.shift;
                    float2 rThrB = float2(0.50, 0.79) - markFrame.shift;
                    float2 rThrC = float2(0.56, 0.86) - markFrame.shift;
                    float2 rockFine = TkFleckBand3(markPos, 0.062 * rSize, 0.103 * rSize,
                        rThrA, TkMarkCoverage(0.140, markFrame.shift),
                        TkMarkAmount(_RockFleckFine, markFrame.value) * workedS, pixelM);
                    float2 rockMid = TkFleckBand3(markPos + 61.7, 0.170 * rSize, 0.281 * rSize,
                        rThrB, TkMarkCoverage(0.106, markFrame.shift),
                        TkMarkAmount(_RockFleckMid, markFrame.value) * workedS, pixelM);
                    float2 rockWide = TkFleckBand3(markPos + 193.1, 0.560 * rSize, 0.925 * rSize,
                        rThrC, TkMarkCoverage(0.062, markFrame.shift),
                        TkMarkAmount(_RockFleckCoarse, markFrame.value) * workedS, pixelM);
                    float2 rockLightMid = TkFleckBand3(markPos + 457.9, 0.145 * rSize, 0.240 * rSize,
                        rThrC, TkMarkCoverage(0.045, markFrame.shift),
                        -TkMarkAmount(_RockFleckLightMid, markFrame.value) * workedS, pixelM);
                    stone *= rockFine.x * rockMid.x * rockWide.x * rockLightMid.x;

                    // -- THE CUT PLANES (round 8) -----------------------------------------------
                    // Three rungs a factor _FacetRatio apart, each drawn only while it is between
                    // 45 and 500 px, so the near jamb and a standing stone at thirty metres are
                    // both served without either drawing the other's facets. Flat tone per cell,
                    // mean 0.5, so the term is mean-preserving to the field's own rounding and
                    // cannot move the region's authored value. World XZ+Y planar rather than the
                    // mark frame: a facet is a plane in the rock, not a stroke of the brush, and
                    // giving it the strokes' frame is exactly how one vocabulary became five.
                    float facetScale = _FacetBaseScale;
                    float2 facetUV = float2(dot(gp3.xz, float2(0.8944, 0.4472)), gp3.y);
                    [unroll]
                    for (int fi = 0; fi < 3; fi++)
                    {
                        float fw = TkFacetWindow(facetScale, pixelM);
                        UNITY_BRANCH
                        if (fw > 0.002)
                        {
                            float ft = TkFacetTone(facetUV / facetScale + 13.1 * fi);
                            stone *= 1.0 + (ft - 0.5) * 2.0 * _FacetAmount * fw;
                        }
                        facetScale *= _FacetRatio;
                    }

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


                // THE SUN BLEACH (round 6) — see the property block. Pure chroma: the tint is
                // divided by its own luminance, so this cannot move the exposure or the measured
                // amplitude, only the saturation of the lit end.
                float3 bleachTint = _BleachTint.rgb
                    / max(dot(_BleachTint.rgb, float3(0.2126, 0.7152, 0.0722)), 1e-4);
                float bleach = _SunBleach * smoothstep(_BleachStart, 1.0, lit);
                albedo = lerp(albedo,
                    dot(albedo, float3(0.2126, 0.7152, 0.0722)) * bleachTint,
                    bleach);

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
