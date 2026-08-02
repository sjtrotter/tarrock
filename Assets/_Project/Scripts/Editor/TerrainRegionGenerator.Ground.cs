namespace Tarrock.Editor
{

    using UnityEditor;
    using UnityEngine;

    // Partial of TerrainRegionGenerator: GROUND SURFACING.
    // Owns the turf palette and grass-band constants, the terrain painterly material, and
    // the rock material derived from it.
    public static partial class TerrainRegionGenerator
    {

        // -------------------------------------------------------------------------------------
        // Scene dressing
        // -------------------------------------------------------------------------------------

        // -- The turf palette and the grass band -------------------------------------------------
        // SHARED SURFACE, deliberately declared once here and consumed twice. The ground material
        // paints turf with these colours inside this band; BuildGrassDetails scatters tufts with
        // the same band and tints the tuft base toward the same soil. Round 1 shipped the two
        // sides as unrelated magic numbers, and the result was measurable: the ground stopped
        // being turf on a hard line while the tufts kept going, so the tufts read as decals on
        // lino. One fact, one place — if these move, both sides move together.
        //
        // Colours are authored as ordinary picker swatches — the same convention every other
        // material palette in this file uses, so ground and tufts speak the same numbers.
        //
        // ROUND-3: the turf moved into the GREEN family. Round 2's soil was (0.26, 0.21, 0.14) — a
        // brown card sitting under green blades, which the gauntlet measured in round2/v3 as
        // "out-of-family brown dirt with grass decals on it". The mat a blade grows out of is not
        // soil seen from above; it is shadowed leaf litter and dead blade, which is green-black. The
        // ochre survives as the SCOUR patch (see the shader's turf block), which is what
        // "wind-scoured green" actually describes: green mat, worn through in patches.
        //
        // BuildGrassDetails reads TurfSoil back off the material to tint the tuft base, so this
        // change moves the tuft roots to green in the same stroke — which is the point. One fact,
        // one place.
        // ROUND-6 — THE BLUE FLOOR. These four are read back by BuildGrassDetails and passed into
        // every tuft material, so they set the blue channel of the largest population of pixels in
        // the frame. Round 5's ochre was linear (0.212, 0.144, 0.041): R/B 5.2 before a single
        // photon touched it, and blue at 4% of the surface. A surface whose blue starts at 0.041
        // cannot survive a lamp at linear R/B 2.92 and a grade that then boosts saturation 16% —
        // the blue goes NEGATIVE in the LUT and URP's max(0) clamps it to a hard zero. That is
        // where round 5's "median blue 0, saturation 1.000 over 75.9% of the lit meadow" came from.
        //
        // The ochre is now a dry BUFF (linear 0.229, 0.187, 0.100 — R/B 2.3) rather than an
        // orange, and every triple carries a real blue. Nothing here has moved in hue family:
        // "wind-scoured green" is still green mat worn through to a dry patch. What changed is
        // that the dry patch is now the colour of dry grass instead of the colour of the light
        // that happens to be falling on it. The gold belongs to the lamp — see
        // TerrainRegionGenerator.Lighting.cs.
        internal static readonly Color TurfSoil = new Color(0.17f, 0.20f, 0.15f);   // damp root shadow
        internal static readonly Color TurfBlade = new Color(0.25f, 0.34f, 0.23f);  // living blade mat
        internal static readonly Color TurfOchre = new Color(0.52f, 0.48f, 0.36f);  // dry buff scour
        internal static readonly Color MeadowGreen = new Color(0.29f, 0.38f, 0.26f); // wind-scoured

        // The band tufts live in. BOTH sides feather it now (round-2 integration): the ground
        // shader fades its turf across _TurfFeatherDeg/_TurfFeatherM either side of these numbers,
        // and BuildGrassDetails' density map smoothsteps its own slope/height gates across the same
        // centres instead of the hard `steep > 24 || h < 13 || h > 52` cut that drew the grass
        // boundary as a traceable contour line.
        internal const float GrassBandSteepMaxDeg = 24f;
        internal const float GrassBandHeightLow = 13f;
        internal const float GrassBandHeightHigh = 52f;
        // Turf patch field: the wavelength at which the ground shader breaks its turf layer into
        // clumps. It is a STAND-IN at the same order as the density map's own clumping (which is a
        // three-octave field owned by BuildGrassDetails and far too expensive to port into HLSL),
        // NOT the same field — so turf blotches and tuft stands agree in scale, not in phase. It
        // only modulates turf strength, so the mismatch reads as natural variation.
        internal const float GrassPatchFrequency = 0.045f;
        internal const float GrassPatchScaleMetres = 1f / GrassPatchFrequency;

        // -- The brushmark family (round 4, narrowed in round 5) ---------------------------------
        // Aspect spread turns some cells into drawn-out strokes and others into blobs; size spread
        // gives the family a range of brush widths. Both exist because jittering a Worley cell's
        // CENTRE hides the lattice's phase and NOTHING else — the marks stay one circle at one
        // radius on one pitch, which is what the round-4 critique read at 2 m as "one stamped decal
        // repeated at one size on a visible cadence".
        //
        // ROUND-5 NARROWED THE SCOPE, and the shared-surface note that used to sit here is gone
        // with it. These now feed the TERRAIN shader only, and only at the scales where a single
        // mark is legible as a mark: the 6 m meadow dab, the 16 m clump, the 2.8 m turf dab. Every
        // jittered-cell field FINER than that has been removed from both shaders, because a Worley
        // F1 is a min() over nine cells and a min() creases along every cell wall — a fold, which
        // modelled alone measured a directional anisotropy of 17.2 against a reference-plate band
        // of 1.6-5.7. Fine marks are now sparse mark fields instead (the shaders' TkFleckBand),
        // and the "one paint, two shaders" rule is carried there: the terrain and the stones run
        // the same construct at the same coverages.
        internal const float MeadowDabAniso = 0.55f;
        internal const float MeadowDabSize = 0.45f;

        // -- THE MARK FRAME (round 7) -----------------------------------------------------------
        // SHARED SURFACE, declared once and consumed twice — the terrain and the free-standing
        // stones must be painted by the same hand, in the same direction, at the same distances,
        // or a boulder reads as a prop dropped onto the hillside instead of a lump of it.
        //
        // WHAT THESE ANSWER. Round 6 stretched every mark along ONE world axis, everywhere. That
        // killed the round-5 contour lock (the marks no longer follow the landform) and replaced it
        // with wallpaper: measured on the round-6 captures with this round's implementation, the
        // block-wise stroke direction over v1's meadow collapsed to a single lean — nine of nine
        // blocks inside 63-97 degrees, spread 0.146 -> 0.022. A painter's strokes turn with the
        // passage of ground they describe; they do not all lean the same way across a valley.
        //
        // The axis is now chosen by a TWO-OCTAVE world field and the second octave is the part that
        // is easy to get wrong. A single 24 m field is right for a wide shot and useless for the
        // close frames: a two-metre crop of a wall samples ONE value of it and comes back with one
        // lean again, which is exactly how round 6's fault survived a world-space rewrite. 1.9 m is
        // 30 marks across at the 6 cm grit band — coarse enough that the turn is a passage of
        // stone rather than a per-mark jitter, fine enough that a close crop contains several.
        //
        // The same four fields carry the rest of the round-6 "one size, one lean, one value"
        // finding: SIZE scales every band's wavelength, VALUE scales every band's contrast, and
        // DENSITY shifts every band's threshold (the shaders compensate the mean-preserving
        // divisor for the coverage that shift buys, or a denser patch would also be a darker one).
        internal const float MarkAniso = 2.2f;
        internal const float MarkTurnScale = 24f;
        internal const float MarkTurnScaleFine = 1.9f;
        internal const float MarkTurnSpread = 1.15f;   // radians, peak to peak (~66 degrees)
        internal const float MarkSizeSpread = 0.33f;
        internal const float MarkValueSpread = 0.36f;
        internal const float MarkDensitySpread = 0.045f;

        // -- THE SUN BLEACH (round 7) -----------------------------------------------------------
        // These three were sitting at their SHADER DEFAULTS through round 6 — never written by the
        // generator, invisible in the diff, and therefore hidden state of exactly the kind this
        // project's conventions forbid. They are written here now, for both materials.
        //
        // They are also RE-PITCHED, and the arithmetic is the point. The shader ramps the bleach
        // over smoothstep(_BleachStart, 1, lit), and `lit` is the wrapped lambert: at SunEuler's
        // 12 degrees, flat sunlit ground sits at (sin 12 + 0.40)/1.40 = 0.434 and NOTHING on the
        // floor of this region ever approaches 1. With the round-6 start of 0.28 the term
        // evaluated to 0.059 on the lit meadow — a control that was doing nothing at all. At 0.06
        // the same ground takes 0.20 and a face square to the beam takes the full amount, so the
        // effect is proportional to how much beam a surface actually receives.
        //
        // THE TINT IS THE ROUND'S WARMTH, AND IT IS LOCAL BY CONSTRUCTION. Round 6 bought its clean
        // palette with a global desaturation and the frame came back cool and empty; round 7 must
        // put the warmth back without putting the clipping back. This is the lever that cannot
        // clip: the tint is normalised to luminance 1 inside the shader, so it moves CHROMA and
        // never exposure, it is multiplied by `lit` so it cannot touch a shadow, and — modelled
        // through the full chain — it moves the lit meadow's blue UP, not down, because it
        // desaturates a green toward a warm grey. "Pale dawn gold in the LIGHT, wind-scoured
        // green" (art-audio.md), with the gold arriving on the surfaces the beam reaches and
        // nowhere else. Authored as a swatch a hair cooler than the lamp's own (1.00, 0.91, 0.78):
        // the light is the gold, this is what the light does to the paint.
        internal const float SunBleach = 0.55f;
        internal const float BleachStart = 0.06f;
        internal static readonly Color BleachTint = new Color(1.00f, 0.92f, 0.78f);

        private static Material BuildTerrainMaterial(Shader shader)
        {
            var material = AssetDatabase.LoadAssetAtPath<Material>(TerrainMaterialPath);
            if (material == null)
            {
                material = new Material(shader);
                AssetDatabase.CreateAsset(material, TerrainMaterialPath);
            }
            else
            {
                material.shader = shader;
            }

            // EVERY property is set explicitly, never left to the shader default. A material asset
            // keeps whatever was serialised into it, so re-running against an existing .mat would
            // otherwise silently preserve stale values while the shader's defaults appear to change.
            //
            // Cliff palette (art-audio.md §Region color scripts owns per-region tinting: "pale dawn
            // gold, wind-scoured green"). The plateau's GOLD lives in the dawn LIGHT, not the albedo
            // (director call 2026-07-26), so nothing here ramps toward white — the warm notes are
            // dry grass and warm stone, which are colours, not brightness.
            //
            // The four meadow hues are the round-2 answer to the gauntlet finding that the ground
            // measured monochrome (one hue at two brightnesses) where fable-05/08 carry a real hue
            // swing. See the shader header for the full finding list.
            // ROUND 6 restores the second half of that director call, which round 5 lost: the gold
            // lives in the LIGHT, so the albedo's warm notes must be DRY GRASS and WARM STONE and
            // not a gold of their own. Round 5's straw was linear (0.397, 0.297, 0.078) — R/B 5.1,
            // an orange, and the same colour the lamp was already painting on top of it. It is now
            // (0.397, 0.342, 0.164), R/B 2.4: still the warmest note on the floor, still clearly
            // straw beside the green, and no longer competing with the dawn for the same job.
            // The scuff loses its orange for the same reason. _MeadowCool is untouched — it was
            // the only member of this chord round 5 did not warm, and it is what keeps the hollows
            // reading cool.
            material.SetColor("_MeadowGreen", MeadowGreen);
            material.SetColor("_MeadowStraw", new Color(0.66f, 0.62f, 0.44f));
            material.SetColor("_MeadowScuff", new Color(0.43f, 0.36f, 0.28f));
            material.SetColor("_MeadowCool", new Color(0.27f, 0.35f, 0.36f));
            material.SetFloat("_MeadowMacroScale", 38f);
            material.SetFloat("_MeadowHueScale", 21f);
            material.SetFloat("_MeadowDabScale", 6f);
            material.SetFloat("_MeadowGrainScale", 0.34f);
            material.SetFloat("_MeadowDabWarp", 0.55f);
            material.SetFloat("_MeadowDabEdge", 0.10f);
            // ROUND-4: the brushmark family's shape spread, now feeding the legible-mark scales
            // only (see the constants' own header). The rock material no longer takes these — its
            // jittered-cell band was the finer of the two and round 5 removed it.
            material.SetFloat("_MeadowDabAniso", MeadowDabAniso);
            material.SetFloat("_MeadowDabSize", MeadowDabSize);
            material.SetFloat("_MeadowStrawAmount", 0.85f);
            material.SetFloat("_MeadowScuffAmount", 0.55f);
            material.SetFloat("_MeadowCoolAmount", 0.70f);
            material.SetFloat("_MeadowFineStraw", 0.28f);
            material.SetFloat("_MeadowGrain", 0.13f);
            // _DetailFadeStart/_DetailFadeRange now gate only the CAVITY term. Round 4 hung every
            // fine term off them, and the round-5 measurement is what that cost: mid-distance
            // mottle fell from round 3's 19.6% relative amplitude to 12.7%, and the far hill sat at
            // 3.3% where the reference plates run 13-20%. The detail stack below is distance-
            // compensated per octave against the pixel footprint instead — see the shader's
            // TkDetailFbm — so these two numbers no longer decide whether the ground has a surface.
            material.SetFloat("_DetailFadeStart", 10f);
            material.SetFloat("_DetailFadeRange", 28f);

            // -- THE DETAIL STACK (round 5) ------------------------------------------------------
            // Replaces round 4's fine Worley layers on both the meadow and the stone. Every number
            // here was solved in a numpy transcription of this shader, measured with one metric
            // against the round-4 captures and the reference plates; the shader's TkDetailFbm and
            // TkFleckBand headers carry the derivation and the caveats.
            //
            // WHAT WAS WRONG. v5's near-vertical rock crop measured 20 distinct luma levels (the
            // reference plates run 149-230), 2.5% relative high-pass amplitude at the 2-4 cm scale
            // (reference band 10-16%), and a directional anisotropy of 12.7 (reference 1.6-5.7).
            // At v5's own geometry — 2.61 m out, 45° vertical fov, 1080 px — the ground sample
            // distance is 2.0 mm per pixel, and the finest term the stone branch owned was a 0.62 m
            // dab: 310 pixels across. Nothing varied inside a third of a metre.
            //
            // Base scale is the COARSEST octave and the finest is base/2.71³, so 0.60 m puts the
            // finest rock octave at 3.0 cm and 0.95 m puts the meadow's at 4.8 cm — the 2-4 cm band
            // the critique asked for, and the band the reference plates carry their speckle in.
            material.SetFloat("_DetailBaseScale", 0.42f);
            material.SetFloat("_MeadowDetailScale", 0.72f);

            // The mark frame, shared with the stones (constants above).
            material.SetFloat("_MarkAniso", MarkAniso);
            material.SetFloat("_MarkTurnScale", MarkTurnScale);
            material.SetFloat("_MarkTurnScaleFine", MarkTurnScaleFine);
            material.SetFloat("_MarkTurnSpread", MarkTurnSpread);
            material.SetFloat("_MarkSizeSpread", MarkSizeSpread);
            material.SetFloat("_MarkValueSpread", MarkValueSpread);
            material.SetFloat("_MarkDensitySpread", MarkDensitySpread);

            // ROCK. Modelled at v5's 2.0 mm/px: 2.6 / 5.9 / 10.8 / 15.2 percent relative amplitude
            // at high-pass sigma 2/4/8/16 px, 54 luma levels, anisotropy 1.81 — against round 4's
            // measured 1.3 / 1.8 / 2.5 / 3.4, 20 levels, anisotropy 12.7. Held across distance:
            // 10.8 / 16.9 / 13.2 / 12.4 / 17.8 percent at 3 / 12 / 40 / 100 / 200 m.
            // ROUND 7 — THE GAINS ARE RETIRED (critique finding 5a). Round 6's shader multiplied
            // every one of these eight by a `k*Gain` constant that lived in the HLSL, because the
            // two files were owned by different builders that round. Both move together now, so
            // the gains are gone from the shaders and these numbers are the EFFECTIVE amounts. For
            // anyone reading a round-6 capture, the retired mapping was:
            //
            //     property              r6 value  x r6 gain  = r6 effective  -> r7 value
            //     _RockGrainAmount        0.40      1.65         0.66            0.80
            //     _RockFleckFine          0.58      1.48         0.86            0.88
            //     _RockFleckMid           0.46      1.78         0.82            0.80
            //     _RockFleckCoarse        0.34      1.88         0.64            0.50  (THINNED)
            //     _MeadowDetailAmount     0.52      1.19         0.62            0.72
            //     _MeadowFleckFine        0.72      1.11         0.80            0.88
            //     _MeadowFleckMid         0.58      1.24         0.72            0.84
            //     _MeadowFleckCoarse      0.48      1.25         0.60            0.78
            //
            // There is now exactly ONE number per band and it is this one. A gain folded into the
            // shader is what made the round-6 arithmetic unauditable; do not reintroduce it.
            //
            // ROCK, and the ladder is a rung longer at both ends. The round-6 measurement on the
            // v5 wall crop is the brief: 20.1% of the surface inside dark blobs of 150 px or more
            // (the leopard spots), 0.2% of the crop's spectral energy below 8 px against round 5's
            // 4.7% (nothing where a brush leaves tooth), and one mark value — dark. So:
            //   * a 2.4 cm TOOTH rung under the 6 cm grit, which the geometric-mean footprint in
            //     the shader finally admits on a raked face;
            //   * the 56 cm patch band THINNED HARD, which is the "thin it hard on rocks" note:
            //     amount 0.64 -> 0.50 with its threshold raised and its coverage cut by 28%;
            //   * two LIGHT bands, so a face carries pale grit as well as dark pitting.
            // Modelled through lighting, fog and the Neutral tonemap at the wall's fitted footprint
            // (4 x 3 mm a pixel): lit relative amplitude 6.8 -> 9.9 per cent against the round-6
            // critique's >= 10 target, blob coverage 0.201 -> 0.059.
            material.SetFloat("_RockGrainAmount", 0.80f);
            material.SetFloat("_RockFleckGrit", 0.88f);
            material.SetFloat("_RockFleckFine", 0.88f);
            material.SetFloat("_RockFleckMid", 0.80f);
            material.SetFloat("_RockFleckCoarse", 0.50f);
            material.SetFloat("_RockFleckLight", 0.78f);
            material.SetFloat("_RockFleckLightMid", 0.44f);

            // MEADOW, pushed harder than rock on purpose. Near turf measured 9.5% against reference
            // plates at 17.8 (fable-08), 28.8 (fable-01) and 36.7 (fable-07), and the critique's
            // reading is that the cadence was already right and only the amplitude was missing.
            // Modelled at 5.0 mm/px: 5.3 / 10.8 / 17.3 / 22.4, 54 levels, anisotropy 1.70.
            // Deliberately stopped in the lower third of that reference band: past about 0.6
            // continuous amount the model's marks stop being separable and the ground reads as
            // static rather than as paint, and no metric settles that — the next capture does.
            // ROUND 7 also fills the meadow's own hole: round 6's rungs were 5 / 32 / 210 cm, so
            // between 32 cm and 2.1 m — nearly three octaves, and most of what the eye reads at
            // 8-25 m — there was nothing. The ladder is now 5 / 16 / 56 / 210 cm plus a 7.5 cm
            // LIGHT band, and _MeadowFleckStand is the 2.1 m rung that _MeadowFleckCoarse used to
            // be (the name follows the wavelength, so the four read in order).
            material.SetFloat("_MeadowDetailAmount", 0.72f);
            material.SetFloat("_MeadowFleckFine", 0.88f);
            material.SetFloat("_MeadowFleckMid", 0.84f);
            material.SetFloat("_MeadowFleckCoarse", 0.78f);
            material.SetFloat("_MeadowFleckStand", 0.72f);
            material.SetFloat("_MeadowFleckLight", 0.58f);

            // THE CLUMP OCTAVE (round 4) — the band that carries the ground from 40 m to the
            // horizon, where round 3 had nothing but smooth fbm and the hills read as olive
            // gradients. 16 m is a stand of vegetation, not a hillside: coarse enough to still
            // subtend ~9° at 100 m, fine enough that a hill carries a dozen of them. Nothing here is
            // distance-faded — that is the whole point of the octave.
            material.SetFloat("_MeadowClumpScale", 16f);
            material.SetFloat("_MeadowClumpWarp", 0.85f);
            material.SetFloat("_MeadowClumpAmount", 0.90f);
            material.SetFloat("_MeadowClumpEdge", 0.11f);

            // Turf — the layer the tuft fields grow out of (shared constants above). GREEN family
            // now; the ochre is a scour PATCH rather than half of the base ramp.
            material.SetColor("_TurfSoil", TurfSoil);
            material.SetColor("_TurfBlade", TurfBlade);
            material.SetColor("_TurfOchre", TurfOchre);
            material.SetFloat("_TurfScale", 2.8f);
            material.SetFloat("_TurfAmount", 0.78f);
            material.SetFloat("_TurfContact", 0.20f);
            // The scour field is decorrelated from every other meadow field and an order coarser
            // than the turf dab, so bald patches are patches — a few metres across — rather than a
            // per-dab speckle that would just re-brown the whole mat by another route.
            material.SetFloat("_TurfScourScale", 9.5f);
            material.SetFloat("_TurfScourAmount", 0.85f);
            material.SetFloat("_TurfPatchScale", GrassPatchScaleMetres);
            material.SetFloat("_TurfSteepMax", GrassBandSteepMaxDeg);
            material.SetFloat("_TurfFeatherDeg", 8f);
            material.SetFloat("_TurfHeightLow", GrassBandHeightLow);
            material.SetFloat("_TurfHeightHigh", GrassBandHeightHigh);
            material.SetFloat("_TurfFeatherM", 6f);

            // Stone: warm grey beds against cooler grey beds with sage lichen, then the cool slate
            // refusing face. Round 1 had two greys a few levels apart and read as an extension of
            // the meadow gradient.
            material.SetColor("_RockWarm", new Color(0.56f, 0.51f, 0.42f));
            material.SetColor("_RockCool", new Color(0.40f, 0.41f, 0.45f));
            material.SetColor("_RockLichen", new Color(0.35f, 0.40f, 0.26f));
            material.SetColor("_CliffColor", new Color(0.30f, 0.31f, 0.35f));
            material.SetFloat("_RockMottleScale", 6.5f);
            // Close-range paint on the hillside's own stone is now the detail stack above; round
            // 4's 0.62 m face dab is gone, and _RockMottleScale survives only as what it always
            // was — the 6.5 m blotch field the bedding roughness and the lichen mask read from.
            // Down from round 2's 0.85. The hue swing now turns over per FORMATION (every ~3 beds)
            // instead of per bed, so the same swing at the old amount would read as a barcode.
            material.SetFloat("_RockBedTint", 0.55f);
            material.SetFloat("_RockLichenAmount", 0.40f);

            // Slope thresholds in steepness (1 - N.y): rock from ~35°, owning the surface by ~50°;
            // the refusing face from ~60°, owning it by ~74°. Rock used to start at ~46°, which put
            // every mid slope in the meadow ramp and is half of why nothing read as slope-responsive.
            material.SetFloat("_SlopeStart", SteepnessFromDegrees(35f));
            material.SetFloat("_SlopeEnd", SteepnessFromDegrees(50f));
            material.SetFloat("_CliffStart", SteepnessFromDegrees(60f));
            material.SetFloat("_CliffEnd", SteepnessFromDegrees(74f));
            material.SetFloat("_SlopeJitter", 0.13f);
            material.SetFloat("_BlendFieldScale", 14f);

            // BEDDING (round 3). Gravity-aligned, because sediment is laid down flat — the full
            // reasoning is in the shader header and is not restated here. Two numbers carry the
            // round-2 lesson and must be read together:
            //   * _BeddingSpacing 2.6 m is the mean bed thickness.
            //   * _BeddingWarp 0.55 m is 21% of a bed, and the shader hard-caps it at 30% anyway.
            // Round 2 ran a 6.5 m wander against a 3.4 m bed — 1.9 BED THICKNESSES — at which point
            // the bedding coordinate is the wander field rather than world Y, and the partings
            // become that field's level sets, which are closed loops. Those loops are the worm veins
            // the gauntlet measured on every slope in round2/v1 and v8. The ratio is the fault, not
            // the axis: keep warp well under half a bed and the beds stay beds.
            //
            // The dip is a ~3.4°/2.6° gradient. Enough that the beds are not a spirit-level ruling;
            // far too little to reach the level-set regime.
            material.SetFloat("_BeddingSpacing", 2.6f);
            material.SetVector("_BeddingDip", new Vector4(0.060f, 0f, -0.045f, 0f));
            material.SetFloat("_BeddingWarp", 0.55f);
            material.SetFloat("_BeddingRough", 0.22f);
            material.SetFloat("_BeddingLineWidth", 0.085f);
            material.SetFloat("_BeddingWidthJitter", 0.60f);
            material.SetFloat("_BeddingDarken", 0.36f);
            material.SetFloat("_BeddingLip", 0.20f);
            material.SetFloat("_BedValueJitter", 0.09f);
            material.SetFloat("_BedFormRate", 0.34f);
            // Bedding is drawn on STEEP FACES ONLY, and this is the structural guard on round 2's
            // one real win (no contour banding). The ring was never caused by banding on world Y; it
            // was caused by banding on GENTLE ground, where a horizontal slab meets the surface over
            // an enormous on-surface width and its edge necessarily traces a heightmap contour. Fade
            // the whole construct out below the angle where a bed cuts a thin line and the ring
            // cannot be drawn at all. Authored in degrees, like every other slope threshold here.
            //
            // ROUND-4 RE-GATE, 35/48 -> 50/62, plus an AND against the rock classification in the
            // shader. MEASURED, not eyed: over this generator's own 513² heightfield with Unity's
            // central-difference normals, the landform filling v1's left third (x 140-218, z 30-88,
            // the valley's SOUTH permitting ramp) runs a median slope of 31.5° across a 12.6-48.6°
            // quartile range — a dune. 43.8% of it fell inside the old fade and drew beds; a
            // horizontal plane cutting a rounded hill traces a CONTOUR, so those beds wrapped the
            // form, which is precisely the round-4 finding. At 50/62 the same box drops to 22.2%
            // touched, every cell under 50° takes exactly zero, and what keeps its strata is the
            // north refusing wall (55-65°) and the broken edge (~70°) — true rock, where a 2.6 m bed
            // meets the surface over 3.0 m instead of 5.2 m and can be a line rather than a shade.
            material.SetFloat("_BeddingSlopeStart", 50f);
            material.SetFloat("_BeddingSlopeEnd", 62f);

            // CAVITY — concavity darkening as its own AO-like term, deliberately NOT baked into the
            // bedding marks. It selects a filled REGION (where the fine relief sits below the broad
            // form) rather than a band around a field's midpoint, which is the structural reason it
            // cannot draw the worms the round-2 crevice term drew.
            material.SetFloat("_CavityScale", 3.4f);
            material.SetFloat("_CavityContrast", 4.5f);
            material.SetFloat("_CavityDarken", 0.34f);
            material.SetFloat("_CavityGroundDarken", 0.16f);

            // SHADING NORMAL — the facet fix. 0.30 m of relief over a 3.4 m field is a gentle
            // undulation, not a bumpy surface; it is sized to break the Gouraud Mach band at a
            // triangle edge, which is a metres-scale artefact, and nothing finer would touch it.
            // Faded out past 45 m, where the facets are sub-pixel anyway and an unfaded
            // high-frequency normal would only generate shimmer.
            material.SetFloat("_NormalDetailHeight", 0.30f);
            material.SetFloat("_NormalDetailStrength", 1f);
            material.SetFloat("_NormalDetailFadeStart", 45f);
            material.SetFloat("_NormalDetailFadeRange", 55f);
            // ...and MORE of it on stone (round 4). The 0.30 m figure is sized for the meadow's
            // near-flat triangles; on a 65° face the same triangles are edge-on and the ndotl step
            // across each Gouraud kink is several times larger, which is why v5's rock face read as
            // sliver triangles. 2.2x lands ~11° of shading tilt on stone and leaves the meadow
            // untouched. Costs nothing: the same relief height, amplified before it is differentiated.
            material.SetFloat("_RockNormalBoost", 2.2f);

            material.SetFloat("_HeightLow", 8f);
            material.SetFloat("_HeightHigh", 48f);
            // Up from round 2's 0.30. Wrapping compresses the ndotl gradient, and a compressed
            // gradient means a smaller value step across a facet edge — the cheap half of the facet
            // fix, and it costs the storybook falloff nothing because a softer terminator is the
            // house look anyway (Visual pillar 1).
            material.SetFloat("_ShadeWrap", 0.40f);
            material.SetFloat("_AmbientBoost", 1f);
            // ROUND 6 — COLOUR IN THE SHADOWS, the other half of the law the sun bleach implements
            // on the grass side. This tint is the terrain's only chroma-versus-value lever, and the
            // shade is where the meadow's blue is allowed to live: 1.06 → 1.11 in blue, 0.80 → 0.78
            // in red. It cannot touch the lit read — `lerp(_ShadowTint, 1, lit)` resolves to 1 on
            // ground the beam reaches.
            material.SetColor("_ShadowTint", new Color(0.78f, 0.88f, 1.11f));
            material.SetColor("_AmbientFloor", new Color(0.10f, 0.11f, 0.15f));
            // THE PENUMBRA, in metres of half-width on the ground (round 5; the derivation is in
            // TerrainPainterly's Frag lighting block). 1.0 m is the middle of the 0.45-1.8 m band a
            // 0.53° sun throws through forms standing 10-40 m from what they shade, once the 12°
            // rake has stretched it. Written here rather than left to the shader default because
            // it is a LIGHTING number: it is derived from SunEuler's elevation and belongs beside
            // the lamp, not in a property sheet.
            material.SetFloat("_ShadowPenumbra", 1.0f);
            // The sun bleach, written rather than left at the shader default (constants above).
            material.SetFloat("_SunBleach", SunBleach);
            material.SetFloat("_BleachStart", BleachStart);
            material.SetColor("_BleachTint", BleachTint);

            // OPAQUE, pinned. The shader states its own blend state explicitly, but a .mat that has
            // ever carried a custom queue keeps it across a shader reassignment, and a ground in the
            // transparent queue is one of the two shapes the round-2 "you can see through the cliff"
            // read could have had. -1 means "use the shader's queue" (Geometry, 2000).
            material.renderQueue = -1;
            material.SetOverrideTag("RenderType", "Opaque");
            EditorUtility.SetDirty(material);
            return material;
        }

        private static Material BuildRockMaterial(Shader rockShader, Material terrainMaterial)
        {
            var material = AssetDatabase.LoadAssetAtPath<Material>(RockMaterialPath);
            if (material == null)
            {
                material = new Material(rockShader);
                AssetDatabase.CreateAsset(material, RockMaterialPath);
            }
            else
            {
                material.shader = rockShader;
            }

            // The palette is READ off the ground, never restated: a boulder must be made of the same
            // stone the hillside is shaded with (BuildTerrainMaterial owns those colours), and
            // copying the numbers here is how a prop ends up a different rock from its own cliff.
            // The fallbacks exist only so a renamed terrain property degrades to "close enough and
            // loud in the log" instead of to Unity's silent Color.clear, i.e. black rocks.
            //
            // ROUND-2 INTEGRATION NOTE: the ground pass split its stone into alternating warm and
            // cool BEDS with sage lichen (_RockWarm / _RockCool / _RockLichen) where it used to have
            // one _RockColor and one _MossColor. Tarrock/RockPainterly still lights a boulder with a
            // single stone colour plus a moss, so the mapping is warm bed → stone, lichen → moss.
            // The cool bed is deliberately NOT read: a boulder sitting on a hillside is a lump of
            // the sunny bed that fell off it, and mixing both here would grey the prop out of the
            // cliff it came from. The fallbacks are the ground pass's own numbers.
            // ROUND 4 — THE WEATHERING STEP. The HUE is still the ground's, read and not restated;
            // what is added is one VALUE decision, and it is the difference between a foreground
            // mass and a pale lump. The critique was that the near stones are brighter than the
            // hazed distance behind them, which is an anchor upside down, and the numbers were
            // blunt: at the hillside's own value a free-standing block in cast shadow renders at
            // luminance 0.300 against shaded meadow at 0.181 — a LIGHT shape on dark ground, where
            // every reference plate's foreground rock is a dark shape on light ground.
            // 0.82 of the bedding's value is where the two constraints meet, and both were solved
            // rather than eyed:
            //   - a block in cast shadow lands at 0.236, so it reads 2.1:1 against the light lane
            //     behind it and 3.1:1 against the far haze — it anchors;
            //   - a face square to the beam still reaches 1.20 linear against the bloom threshold's
            //     0.90, so sun-struck stone is still what carries the frame's brightest pixels
            //     (round 3's doctrine, and it survives the step with a 33% margin).
            // It is also true: the hillside colour is FRESH bedding in a cut face. A block that has
            // sat in wet turf long enough for the grass to climb it is weathered and lichened and
            // is not the colour of the quarry it fell out of. _CliffColor and the lichen are NOT
            // scaled — the refusing faces are hillside, and the lichen is already the dark note.
            Color bedding = PaletteColour(terrainMaterial, "_RockWarm", new Color(0.56f, 0.51f, 0.42f));
            // Scaled channel by channel rather than with Color's own operator*, which would take the
            // alpha down with it — an opaque shader would not care today and would care the day
            // someone reads it.
            material.SetColor(
                "_RockColor",
                new Color(
                    bedding.r * RockWeathering,
                    bedding.g * RockWeathering,
                    bedding.b * RockWeathering,
                    bedding.a));
            material.SetColor("_CliffColor", PaletteColour(terrainMaterial, "_CliffColor", new Color(0.30f, 0.31f, 0.35f)));
            material.SetColor("_MossColor", PaletteColour(terrainMaterial, "_RockLichen", new Color(0.35f, 0.40f, 0.26f)));
            material.SetColor("_ShadowTint", PaletteColour(terrainMaterial, "_ShadowTint", new Color(0.78f, 0.88f, 1.11f)));
            material.SetColor("_AmbientFloor", PaletteColour(terrainMaterial, "_AmbientFloor", new Color(0.10f, 0.11f, 0.15f)));

            // Every remaining property explicit (same rule as the other materials — a reused .mat
            // keeps stale serialised values while the shader's defaults appear to change). These are
            // the ROCK's own numbers: finer mottle than the ground's (a boulder is read at 2 m, not
            // at 40), a finer bed, and a harder posterise so near stones hold a few flat values and
            // stay legible as a dark shape.
            material.SetFloat("_MossAmount", 0.42f);
            material.SetFloat("_MossStart", 0.28f);
            material.SetFloat("_RockVariation", 1.5f);
            material.SetFloat("_RockContrast", 1.8f);
            material.SetFloat("_RockDetailAmount", 0.13f);
            material.SetFloat("_FormationTint", 0.55f);

            // ROUND-5 detail stack, replacing round 4's 0.20 m jittered-cell marks. One paint
            // recipe, two shaders — the terrain took the same change in BuildTerrainMaterial above,
            // and the numbers only differ where the SUBJECT does: a boulder is a metre tall and is
            // looked at from closer than a hillside, so its base octave is 0.45 m against the
            // terrain's 0.60 m, putting its finest octave at 2.3 cm.
            //
            // Round 4's marks failed twice over, and both are measured in the shader's property
            // header: 0.20 m is 100 pixels across at the ground sample distance the close vantage
            // resolves, so it could not be the finest term; and being a Worley F1 it creased along
            // its cell walls, which measured as a directional anisotropy of 17.2 against a
            // reference-plate band of 1.6-5.7. They also faded out by 16 m on camDist, which is the
            // same fault that left the far hills at 3.3% relative amplitude — nothing in the
            // replacement fades on distance, because each octave and each mark band carries its own
            // weight against the pixel footprint instead.
            // ROUND 7 — the same recipe as the hillside's stone (see BuildTerrainMaterial for the
            // measurement and for the retired gain mapping), one step finer throughout because a
            // boulder is read from closer than a cliff: base 0.32 m against the terrain's 0.42, and
            // a 1.6 cm tooth rung against the terrain's 2.4 cm. The gains that used to sit in
            // RockPainterly.shader are gone; these are the effective amounts.
            //
            // ROUND-7 FOLLOW-UP — THE FRAMING MASSES (NEARMASS-FINISH's near mass, 7.1 x 2.3 x 7.3 m
            // at 6-13 m and ~11.5% of v8, and the broken jamb, 5.7 x 3.8 x 3.6 m at 1.7-2.5 m).
            // Their finding was that a 6-7 m mass reads as a flat card at 1.3% mark contrast where
            // the reference board's dark near masses run 8-12%, and their proposed cause was that
            // this ladder is pitched for a 1 m boulder.
            //
            // MEASURED, THE CAUSE IS THE OTHER DIRECTION, and the numbers are in the round-7
            // report. Round 6's footprint gate was max(major axis), and a close mass is a RAKED
            // mass: modelled at the jamb's fitted footprint the round-6 stack put 17.2% of the
            // face inside blobs of 150 px or more with a median mark of 123 px — the leopard spots
            // in the round-6 capture — because every rung under the coarsest was switched off.
            // The round-7 geometric-mean gate alone moves that face from 16.0% to 28.2% contrast
            // and drops blob coverage to 5.2% with a median mark of 8.8 px. The ladder is not
            // mis-pitched; it was being gated off.
            //
            // So NOTHING here is re-pitched UPWARD. A coarser rung would land on top of
            // NEARMASS's own spall sub-facets (0.15-0.5 m on the jamb, 0.5-0.9 m on the near mass)
            // — duplicating a register they already supply — and it would re-draw the leopard
            // spots on 11.5% of the frame, which their brief rightly says would be worse than the
            // flat card. What IS added is the one rung the close end was missing: a sub-centimetre
            // dark/light pair, which the octave gate switches off everywhere it is not wanted.
            material.SetFloat("_DetailBaseScale", 0.32f);
            material.SetFloat("_RockGrainAmount", 0.80f);
            material.SetFloat("_RockFleckTooth", 0.88f);
            material.SetFloat("_RockFleckToothLight", 0.72f);
            material.SetFloat("_RockFleckGrit", 0.88f);
            material.SetFloat("_RockFleckFine", 0.88f);
            material.SetFloat("_RockFleckMid", 0.80f);
            material.SetFloat("_RockFleckCoarse", 0.50f);
            material.SetFloat("_RockFleckLight", 0.78f);
            material.SetFloat("_RockFleckLightMid", 0.44f);

            // The mark frame, IDENTICAL to the terrain's — one hand, one direction, one family of
            // brush widths across the whole region (constants at the top of this file).
            material.SetFloat("_MarkAniso", MarkAniso);
            material.SetFloat("_MarkTurnScale", MarkTurnScale);
            material.SetFloat("_MarkTurnScaleFine", MarkTurnScaleFine);
            material.SetFloat("_MarkTurnSpread", MarkTurnSpread);
            material.SetFloat("_MarkSizeSpread", MarkSizeSpread);
            material.SetFloat("_MarkValueSpread", MarkValueSpread);
            material.SetFloat("_MarkDensitySpread", MarkDensitySpread);

            // The sun bleach, written rather than left at the shader default.
            material.SetFloat("_SunBleach", SunBleach);
            material.SetFloat("_BleachStart", BleachStart);
            material.SetColor("_BleachTint", BleachTint);

            // BEDDING (round 3) — the same construct as the ground's, an order finer because a
            // boulder is a metre tall and wants three or four beds, not one. Round 2 drew
            // posterise(sin(bedding * pi)) here, i.e. a wide soft sinusoid lerping the whole albedo
            // between two stone colours, which is why the round-2 boulders read as stacks of pale
            // tonal slabs. A bed is a thin parting between two masses of one colour.
            //
            // _BeddingWarp 0.09 m against a 0.34 m bed is 26%, and the shader caps it at 30%: the
            // same ratio discipline as the ground, for the same reason (see BuildTerrainMaterial).
            material.SetFloat("_BeddingSpacing", 0.34f);
            material.SetVector("_BeddingDip", new Vector4(0.070f, 0f, -0.050f, 0f));
            material.SetFloat("_BeddingWarp", 0.09f);
            material.SetFloat("_BeddingLineWidth", 0.10f);
            material.SetFloat("_BeddingWidthJitter", 0.60f);
            material.SetFloat("_BeddingDarken", 0.30f);
            material.SetFloat("_BeddingLip", 0.18f);
            material.SetFloat("_BedValueJitter", 0.10f);
            material.SetFloat("_BedFormRate", 0.30f);
            // Measured on 1 - |N.y| rather than on slope degrees, because a boulder has a flat TOP
            // and a flat underside and a horizontal bed blobs across both. Same physics as the
            // ground's slope gate.
            material.SetFloat("_BeddingFaceStart", 0.18f);
            material.SetFloat("_BeddingFaceEnd", 0.46f);

            // CAVITY — the hollows, as their own term. Scaled to the block (0.55 m) rather than to
            // the hillside, so it reads as pitting in the stone and not as the ground's shading
            // arriving on a prop.
            material.SetFloat("_CavityScale", 0.55f);
            material.SetFloat("_CavityContrast", 4.5f);
            material.SetFloat("_CavityDarken", 0.30f);

            material.SetFloat("_BrushSteps", 4f);
            material.SetFloat("_BrushSoftness", 0.32f);
            material.SetFloat("_ShadeWrap", 0.22f);
            material.SetFloat("_AmbientBoost", 1f);
            material.enableInstancing = true;

            // OPAQUE, pinned — same reasoning as BuildTerrainMaterial.
            material.renderQueue = -1;
            material.SetOverrideTag("RenderType", "Opaque");
            EditorUtility.SetDirty(material);
            return material;
        }

        /// <summary>Reads one colour off the ground's material so the rock family cannot drift from
        /// the palette that owns it, warning (rather than silently going black) if it is gone.</summary>
        private static Color PaletteColour(Material source, string property, Color fallback)
        {
            if (source != null && source.HasProperty(property))
            {
                return source.GetColor(property);
            }

            Debug.LogWarning(
                $"[Tarrock] Terrain material has no '{property}'; rock outcrops fell back to their " +
                "own copy of the Cliff palette. Re-sync BuildRockMaterial with BuildTerrainMaterial.");
            return fallback;
        }
    }
}
