namespace Tarrock.Editor
{

    using UnityEditor;
    using UnityEngine;

    // Partial of TerrainRegionGenerator: LIGHTING.
    // Owns the scene's lamp, ambient and fog setup, and the post-processing volume profile
    // (tonemapping, colour grading, bloom, vignette) written beside it.
    public static partial class TerrainRegionGenerator
    {

        // THE FAR PLANE'S COOL (round 6). LINEAR, like every colour in the atmosphere description
        // this pulls against — Sky.cs's HazeLinear owns the warm end and this file only ever
        // blends toward this one, never restates it. See the fog block in BuildLighting for the
        // measurement off the reference board and for why the share is deliberately small.
        private static readonly Color FarCoolLinear = new Color(0.72f, 0.80f, 0.92f);
        private const float FarCoolShare = 0.20f;

        private static void BuildLighting()
        {
            // FROZEN DAWN (canon: art-audio.md §Region color scripts gives the Cliff "pale dawn
            // gold, wind-scoured green"; MQ00 opens at dawn). Director call (2026-07-26 audit): the
            // plateau's gold lives in the LIGHT — the ground stays green meadow, dawn paints it.
            // Two decisions live in this one rotation:
            //
            // ELEVATION 12°, and rounds 1-3 are the argument for every part of that number.
            // Round 1 came down from a 42° near-midday sun to 17° and the pixel audit of round1/v1,v2
            // still measured NO raking: the meadow sat in a 0.23–0.41 luminance band (σ 0.06) with no
            // lit-crest-against-shadowed-trough anywhere, and the warm key never landed on a walkable
            // surface — gold stayed in the sky while the ground read grey-olive. 17° is still high
            // enough that a metre of relief throws only 3.3 m of shadow, which the meadow's own gentle
            // grain swallows. Round 2 went to 7°, where a form throws 8.1× its height and the relief
            // that is actually there starts casting: the fine grain on the valley floor (≈0.6 m at a
            // 5 m wavelength — SampleHeight step 8) puts ±20° of tilt on the walkable surface, which
            // is the difference between a lit facet and a self-shadowed one. That was right, and it
            // is kept.
            //
            // WHAT 7° GOT WRONG, and round 3 did not catch because it was measuring the grade and not
            // the geometry: THE BEAM NEVER REACHED THE PLAYER. Ray-traced against this file's own
            // heightfield, the elevation of the horizon toward the sun is 26.2° from the spawn mark,
            // 21.2° from the v1 lens and 17.2° from the v2 lens — the valley's north refusing wall,
            // 16 m of it standing 30 m away on exactly the sun's bearing. At a 7° sun that wall
            // shadows 100% of the ground within 15 m of the Fool, 79% of the whole spawn bowl, and
            // 100% of everything v2 can see. The round-3 critique measured the consequence exactly:
            // one flat value at four depths across the walkable field, and no lit tier at all in v2.
            // No grade can fix a surface the light does not land on.
            //
            // 12° IS DERIVED, not dialled. It is the lowest elevation at which the col cut through
            // that wall (ApplyLandformEvents, "the dawn breach") lets the beam onto the meadow inside
            // 10 m of the v1 lens: at 11° the same col leaves the lit boundary 25 m out, at 12° it
            // lands at 8.4 m — the near ground stays in shade and the lane opens just beyond the
            // Fool. (ROUND 5 widened that col rather than moving this number, so the lit boundary is
            // now 4.75 m from the lens and the Fool stands IN the light with the shaded band behind
            // him; the elevation and every bearing derived from it are untouched. The current
            // figures live at the col, in ApplyLandformEvents.)
            // A raise on its own could not do it (the sun would have to reach 26° — midday) and
            // a col on its own could not either (at 7° the same lit boundary needs a 55 m trench
            // through the rim, 8400 m³ against this one's 1030). The landform and the lamp each do
            // the half they are good at.
            // The dawn survives the raise: a form still throws 4.7× its height, and the MODULATION
            // that does the modelling is untouched — σ(N·L) over the walkable floor 0.0844 → 0.0829.
            // Everything else in this block exists to pay for the low sun: at 12° flat ground still
            // receives only sin(12°) ≈ 0.21 of the beam, so intensity stays high and the fill low.
            //
            // AZIMUTH 152° — light TRAVELS south-south-east, so the sun disc sits NNW (compass 332°),
            // 62° off the axis of the west-facing wake frame. Round 1's 117° left the disc only 27°
            // off that axis: still essentially contre-jour, where every surface facing the camera is
            // lit at the same grazing angle and the frame resolves into silhouettes rather than
            // modelled form. Swung to a true cross-light the rake does three jobs at once, and the
            // direction is chosen so the light says what the landform already says (rule 5):
            //   - the SHALLOW south wall that invites faces north, into the light, and takes the gold;
            //   - the STEEP north wall that refuses faces south, away, and goes dark and cool beneath
            //     a rim-lit crest;
            //   - WEST-facing terrace risers catch N·L = cos(7°)·cos(62°) ≈ 0.47 against treads at
            //     0.12 — a ~4:1 stripe, which is what finally makes the terraces count as terraces
            //     from the spawn, and they face the v1 camera so the stripe is read side-on.
            // The spawn bowl's sheer back wall faces west and so takes light too: the ground that
            // refuses behind the player reads as a wall rather than a void.
            //
            // KNOCK-ON, deliberate: v2-spawn-side (view yaw 348°) was round 1's raking frame at 51°
            // off the sun; it is now 16° off and becomes the near-contre-jour one — a low blaze with
            // everything rim-lit, which is the fable-03 windmill-sunburst frame and no loss. v1, the
            // wake frame, is the one that had to be right.
            var lightGo = new GameObject("Directional Light");
            // SunEuler, not a literal: the sky's blaze and the cloud deck's banks read the same
            // constant, so the sun cannot be in two places at once.
            lightGo.transform.rotation = Quaternion.Euler(SunEuler);
            var light = lightGo.AddComponent<Light>();
            light.type = LightType.Directional;
            // Dawn gold, one step warmer than round 1's (1.00, 0.87, 0.68). Authored gamma
            // (Light.color is gamma-decoded like any inspector colour), so this lands near
            // (1.00, 0.67, 0.34) LINEAR — 3:1 red to blue. A 7° sun has travelled through far more
            // atmosphere than a 17° one and is genuinely this orange; more to the point, the audit's
            // complaint was that lit ground read "hue-97 grey-olive" while gold stayed in the sky,
            // and a key this warm makes lit meadow resolve to (0.55, 0.48, 0.24) linear — gold-green
            // — against blue-teal shade. Further than this and the warm white balance and warm
            // highlights in the grade below double-count it into sodium.
            //
            // ROUND 6 PULLS IT BACK TO (1.00, 0.91, 0.78) — linear (1.00, 0.807, 0.571), R/B 1.75
            // instead of 2.92 — and this is a canon fix, not a taste call. The comment above ends
            // with its own warning ("further than this and the warm white balance and warm
            // highlights double-count it into sodium") and round 5 crossed that line: the measured
            // lit meadow came back with a median BLUE OF 0 and saturation 1.000 over 75.9% of its
            // pixels, and the whole frame's hue circmean sat at 33.9° (orange) against the colour
            // script's "pale dawn gold, wind-scoured green" and round 4's 42.8°.
            //
            // THE MULTIPLICATION IS THE PROBLEM, and it is why no single stage looked guilty. Blue
            // is divided FOUR TIMES on its way to the frame: by the albedo (round 5's straw dry
            // pole, linear R/B 7.99), by this lamp (2.92), by the blade's own gold vertex tip
            // (1.28) and by the grade's gold highlight bucket (1.30) — a compound R/B of 38.8. The
            // round-5 critic measured 26x on the grass floor and only 1.3-2.3x from the grade, and
            // was right about both: the grade was never where the crush lived.
            //
            // WHAT KILLS THE CHANNEL is what happens next. ColorAdjustments.saturation is
            // c = luma + s·(c − luma), and URP clamps the result with max(0). At an R/B that
            // large, blue sits so far below the pixel's own luminance that s = 1.16 drives it
            // NEGATIVE and the clamp writes a hard zero — not a dark blue, zero. That is the
            // 75.9%, and it is why the same pixels also measure saturation exactly 1.000.
            //
            // Luminance is held constant so nothing downstream moves: the lamp's linear luminance
            // was 0.719 × 6.71 = 4.826 and is now 0.831 × 5.80 = 4.821, a 0.1% difference. Every
            // exposure number in the block below therefore still holds. The dawn is still gold —
            // the gold is now in the LIGHT and in the grade's warm white point, which is where the
            // director's 2026-07-26 call put it, instead of being pre-mixed into the albedo as
            // well and then multiplied by itself.
            //
            // ROUND 7 PUTS A THIRD OF IT BACK: (1.00, 0.91, 0.78) → (1.00, 0.885, 0.760), linear
            // R/B 1.751 → 1.862. This is the round's central move and it is chosen BECAUSE the lamp
            // is the only warm lever in the whole rig that is LOCAL.
            //
            // WHY THE LAMP AND NOT THE GRADE. Round 6 rescued the palette with a single GLOBAL
            // desaturation — measured on this round's own implementation, five materials moved by
            // the same 0.427-0.478 ratio — and the result is a frame that is clean, cool and empty:
            // frame R/B 1.20-1.30 against fable-01's 1.909, top-1% chroma 0.26-0.32 against the
            // board's 0.42-0.70, and no pixel under 0.10 luma in v6 or v7 at all. The fix cannot be
            // a global un-desaturation, because that is the same mistake with the sign flipped. It
            // has to be warmth WHERE THE LIGHT LANDS and nowhere else, and this line is that:
            //   - the sky and the cloud deck are UNLIT materials (GradientSky/CloudLobe take no
            //     main light), so this cannot move a single sky pixel — verified by inspection;
            //   - RenderSettings.fogColor is a constant, so the far plane is untouched;
            //   - cast shadow keeps only shadowStrength's 10% of it, so the shade stays round 6's.
            // Modelled through the full grass → fog → vignette → grade → tonemap chain (the model
            // is validated against the round-6 captures on six control surfaces, RMS 11.8 sRGB
            // levels): the LIT meadow's R/B goes 1.79 → 1.93 and the shaded meadow moves by under
            // a level. The reference board's two sun-side dawn plates sit at lit R/B 1.82
            // (fable-01) and 1.86 (fable-04); this lands between them.
            //
            // AND IT STOPS THERE, DELIBERATELY. Round 5's lamp was linear R/B 2.92 and it crushed
            // blue to a hard zero over three quarters of the lit meadow. Two things make 1.86 safe
            // where 2.92 was not, and BOTH have to stay true: the albedo is no longer pre-mixed
            // gold (the straw pole is R/B 2.04, not 7.99) and the grade's highlight bucket no
            // longer cuts blue. Modelled, the lit meadow's blue arrives at 3.0x the level where
            // ColorAdjustments.saturation's max(0) clamp bites, and the predicted share of pixels
            // at blue ≤ 2 is 0.000% in every frame — the round-6 blue-crush fix is not spent here.
            // The rest of the round's warmth is on the SURFACES, where a painter puts it: see
            // _BleachTint in Tarrock/GrassTuft (the grass) and _BleachTint in Tarrock/
            // TerrainPainterly (the ground). This lamp is deliberately short of the target on its
            // own so that the three together do not overshoot into round 5.
            //
            // ROUND 8 — (1.00, 0.885, 0.760) → (1.00, 0.870, 0.715), linear R/B 1.862 → 2.129 —
            // AND THE FINDING IS NOT THE NUMBER. Rounds 6 and 7 both wrote "the gold is in the
            // LIGHT" and both then spent it as a GLOBAL ADDITIVE. Measured on the round-7 captures,
            // on the v6 floor, populations taken at the same percentiles in both rounds:
            //     LIT band     R/B 1.6807 → 1.6522   (the light COOLED by 0.029)
            //     SHADE band   R/B 1.5321 → 1.6382   (the shade WARMED by 0.106)
            // The round warmed the one place canon forbids warmth and cooled the one place it
            // asks for it. The mechanism is two lines below this one, not in this line at all.
            //
            // WHY A WARMER LAMP DID NOT WARM THE LIGHT. shadowStrength 0.9 leaves 10% of the key
            // inside every cast shadow, and 10% of a key this strong is not a trace: modelled on
            // the round-7 rig, LEAKED SUN WAS 35.4% OF THE LUMINANCE OF A CAST SHADOW and 47.2% of
            // its RED. So the lamp's hue reached the lit meadow at ~95% strength and the shade at
            // ~35% — and the sRGB encode then AMPLIFIES the shade's share, because d(sRGB)/d(linear)
            // at shadow level is about twice what it is at lit level. Net, a hue move on this line
            // arrived in the shadows at roughly the same displayed strength as in the light. That is
            // the whole of the "global additive" complaint, and it is fixed at shadowStrength below,
            // which takes the leak's luma share 0.354 → 0.163.
            //
            // WHAT THIS LINE COSTS, CHECKED AGAINST ROUND 5's DISASTER. Round 5's lamp was linear
            // R/B 2.92 and crushed blue to a hard zero over 75.9% of the lit meadow. 2.129 is safe
            // for the same two reasons round 7's 1.86 was, both of which still hold: the albedo is
            // not pre-mixed gold, and the grade's highlight bucket no longer cuts blue. Modelled
            // through the full chain, flat lit fescue's blue arrives at sRGB 53 and flat lit straw
            // at 119 — 26x and 60x the level where ColorAdjustments.saturation's max(0) clamp
            // bites — and the predicted share of pixels at blue ≤ 2 is unchanged from round 7 in
            // every frame. The round-6 blue-crush fix is not spent here either.
            light.color = new Color(1.00f, 0.870f, 0.715f);
            // ROUND 3, 2.90 → 8.00, and this one number is most of the exposure fix.
            //
            // Round 2 set 2.90 from an arithmetic that DROPPED THE ALBEDO. Its comment claimed "a
            // surface square to the beam reaches ~1.07 linear... flat lit meadow lands ~0.55
            // linear". Both are the light's own value, not the surface's: the shader returns
            // albedo × (direct + ambient) × shade, and the meadow's blend-weighted albedo is
            // gamma (0.36, 0.39, 0.24) = LINEAR (0.105, 0.130, 0.046). So flat lit meadow actually
            // landed at 0.072 linear (a seventh of the claim) and even the pale limestone square
            // to the beam only reached 0.80. Nothing on the ground could clip, which is exactly
            // what the round-2 critique measured: no pixel over 0.85, no sparkle anywhere.
            //
            // The number is now set by where MID-GREY should land, and mid-grey is the one level
            // the rest of the chain is built around (the LogC contrast pivot below sits at linear
            // 0.2249). Flat lit meadow must arrive there:
            //     intensity = 0.20 / (wrapped 0.325 × albedo_G 0.130 × shade 0.83) ≈ 8.0
            // Consequences, all measured through the full shader→bloom→vignette→LUT chain:
            //   - flat LIT meadow 0.197 linear → sRGB 0.50 near, 0.55 at 80 m (target 0.5–0.6);
            //   - flat CAST-SHADOW meadow 0.025 linear → sRGB 0.17 (target 0.12–0.18);
            //   - limestone square to the beam 2.68 linear → red clips at 1.0 and blooms. THAT is
            //     the handful of near-white pixels the frame has never had, and it costs nothing
            //     elsewhere because character and meadow albedos are half the rock's.
            // It also fixes the ground-versus-sky complaint directly. The sky and the cloud deck
            // are UNLIT materials (GradientSky/CloudSea take no main light), so this raises the
            // ground alone: horizon-to-lit-ground closes from 7.9:1 to 2.7:1. Gold stops being a
            // thing that only happens in the sky.
            //
            // ROUND 4, 8.00 → 6.71, and this is a CONSEQUENCE of the elevation raise, not a new
            // opinion about brightness. Round 3's target — flat lit meadow arriving on the LogC
            // contrast pivot, linear luminance 0.2249 — is kept exactly; the raise simply delivers
            // more of the beam to flat ground, so the lamp must give back the difference or the
            // whole grade slides off its own pivot. Solved rather than scaled, because the ambient
            // term does not move with the lamp:
            //     albedo·(key·wrapped(sin 12°) + ambient)·shade = 0.2249   →   intensity 6.713
            // (the naive ratio 8.00 × wrapped(7°)/wrapped(12°) = 6.87 overshoots by 2.4%).
            // Modelled through the full shader → fog → bloom → vignette → LUT chain, every round-3
            // landing point therefore holds to within a sRGB level or two:
            //     flat LIT meadow           0.497 (round 3: 0.497)
            //     flat CAST-SHADOW meadow   0.181 (round 3: 0.182)
            //     near lit : near shade     2.74:1 — the board is 2.4:1 to 4.1:1
            // What changes is not the values but HOW MUCH OF THE FRAME IS AT THEM: v1's lit ground
            // goes 22% → 43%, v2's 0% → 14%.
            // ROUND 6: 6.71 → 5.80, and this is NOT an exposure change — it is the compensation for
            // the lamp's hue move above, solved to hold the linear luminance the derivation in this
            // comment block landed on (4.826 → 4.821, 0.1%). Every "flat LIT meadow 0.497" style
            // number above is still the number this rig produces.
            // ROUND 7: 5.80 → 6.06, and like round 6's move this is NOT an exposure change. It is
            // the compensation for the hue move above, solved on the same constraint the whole
            // chain is built on — hold the lamp's LINEAR LUMINANCE, so every landing point in this
            // block still stands:
            //     round 6  lum(1.00, 0.91,  0.78 ) = 0.8309 x 5.80 = 4.8194
            //     round 7  lum(1.00, 0.885, 0.760) = 0.7953 x 6.06 = 4.8196   (+0.004%)
            // ROUND 8: 6.06 → 7.35, and for the third round running this is NOT an exposure change.
            // It is the compensation for a change to _ShadeWrap in Tarrock/GrassTuft (0.55 → 0.36 —
            // see TerrainRegionGenerator.Grass.cs for the argument), solved on the SAME invariant
            // every round since round 3 has been solved on: hold what FLAT LIT MEADOW receives, so
            // that it still arrives on the LogC contrast pivot and every landing point in this block
            // still stands. The wrap is inside the term this file's arithmetic calls "wrapped":
            //     round 7  wrapped(sin 12°) at wrap 0.55 = 0.4890,  lamp lum 0.7953 × 6.06 = 4.8196
            //     round 8  wrapped(sin 12°) at wrap 0.36 = 0.4176,  lamp lum 0.7681 × 7.35 = 5.6456
            //     flat-lit DIRECT, green channel:  2.2463 → 2.2377   (−0.4%)
            // So the meadow the player walks on receives what it received; what changes is how much
            // of the beam a surface TURNED AWAY from the sun collects, which is the point.
            // The one real cost is at the top: a surface square to the beam now takes 17% more, so
            // the handful of clipping pixels round 3 deliberately bought widens a little. Modelled,
            // limestone square to the beam goes 2.98 → 3.55 linear and still resolves to sRGB
            // (255, 252, 215) against round 7's (255, 248, 219) — the same signature, not a new one.
            light.intensity = 7.35f;
            light.shadows = LightShadows.Soft;
            // NOT 1.0. At this elevation shadow covers most of the frame, and full-strength shadow
            // over a cool ambient is exactly how "luminous cool shade" becomes mud. The direct
            // light left inside shadow keeps shadowed ground reading as coloured, not vacant —
            // the same instinct as the shader's _ShadowTint/_AmbientFloor pair.
            //
            // ROUND 8 — 0.9 → 0.97, AND THIS IS THE ROUND'S CENTRAL MOVE. Everything above about
            // not going to 1.0 is kept; what is corrected is the SIZE of the leak, which was never
            // checked against what else is in a shadow. Modelled on the round-7 rig, flat cast
            // shadow decomposes as:
            //     leaked sun   35.4% of the shadow's LUMINANCE and 47.2% of its RED
            //     ambient SH + the grass shade fill   the rest
            // A tenth of the key is a tenth of a very strong key, and against an ambient deliberately
            // kept low since round 2 it was the largest single term in the shade — AND THE ONLY WARM
            // ONE. That is why two rounds of warm passes warmed the shadows: they were not global,
            // they were LOCAL TO A TERM THAT WAS ALSO IN THE SHADOWS. At 0.97 the same decomposition
            // reads 16.3% of luminance and 23.5% of red, and the shade's own light goes R/B 0.7036 →
            // 0.6434 — cooler, at a warmer lamp.
            //
            // WHY 0.97 AND NOT 1.0, still. 3% of this key is 0.092 linear in red against an ambient
            // red of ~0.13: enough that cast shadow on TERRAIN — which carries no shade fill, only
            // SampleSH — keeps a lit term at all and does not fall to an ambient-only flat. The
            // grass has Tarrock/GrassTuft's _ShadeFill and would survive 1.0; the ground does not,
            // and the ground is not this round's file to change.
            //
            // WHAT IT BUYS, measured as the round's own locality gate — the ground's LIT-band
            // warmth delta against its SHADOW-band delta, computed on flat lit ground versus the
            // same flat ground in cast shadow, swept over all seven meadow albedos:
            //     mean ΔLIT  +0.4115 R/B      mean ΔSHADE  −0.0295 R/B
            // The light warms by 0.41 and the shadow COOLS. There is no albedo in the palette for
            // which the shadow warms by more than +0.023 against a lit warming of +0.355.
            light.shadowStrength = 0.97f;

            // Trilight ambient. GOTCHA (audit finding 3): RenderSettings colours are gamma-decoded
            // in a Linear project, so these triples are authored gamma-encoded to land at the
            // intended linear values. The old triples were authored as if linear — the ground pole
            // landed at 4.7% linear, a light trap that took every shadowed face to near-black.
            // Storybook wants luminous shadows: cool sky/equator, only the ground bounce warm — that
            // opposition to the warm sun IS the painterly warm-light/cool-shadow split.
            //
            // Round 1 fixed the trap's DIRECTION (cool sky, warm bounce, chroma over grey) and this
            // pass keeps all of that. What it changes is the LEVEL, and that is the single biggest
            // reason nothing in round1/v1,v2 separated. Do the arithmetic on those numbers: the sky
            // pole at gamma (0.52, 0.64, 0.88) is LINEAR (0.23, 0.37, 0.75), while the key delivered
            // 1.55 × sin(17°) = 0.45 to flat ground. In blue, the FILL beat the KEY four to one. An
            // up-facing surface — i.e. the whole meadow, lit and shadowed alike — was therefore an
            // ambient-driven surface with a little gold on top, which is precisely the measured
            // result: a 0.23–0.41 band with σ 0.06 and the warm key nowhere on the ground.
            //
            // Round 2 quartered the fill so the sun would do the lighting and the sky only the
            // shade. That direction was right and it stays. ROUND 3 gives back about 45% of it in
            // linear terms, because the constraint that forced the cut has gone: the audit's
            // failure was the FILL BEATING THE KEY in blue (0.75 fill against a 0.45 key), and
            // against an 8.00 lamp flat ground now takes a 0.89 blue key against a 0.42 blue fill.
            // The key wins in every channel, comfortably, at the level the fill needs to be for
            // cast shadow to sit at sRGB 0.17 with all three channels alive rather than at the
            // floor. Shade that is dark AND coloured is a fill job; no grade can invent chroma
            // that the render never produced.
            //
            // The sky pole is also a little WARMER and a little less blue than round 2's, and that
            // is measured off the bar rather than reasoned from the convention. Sampled across the
            // darkest quartile of the near ground, fable-01/02/05/07 all put their shade at
            // R > G > B (R−G between +0.019 and +0.038, B−G between −0.009 and −0.037) — the
            // painterly "cool shadow" is cool RELATIVE TO THE KEY, not actually blue. Round 2's
            // fill was blue enough that shaded meadow rendered CYAN — B above R — which is a hue no
            // frame on the reference board contains. (It never reached the screen: the toe and the
            // contrast below took it to black first. Lift those off round 2 and the cyan is what
            // is underneath.) At these values cast-shadow meadow lands at
            // sRGB (0.151, 0.173, 0.139): B now sits below G exactly as the references do, and it
            // reads as deep warm olive against gold-green light — the fable-01 read the grade
            // below is written for, the HUE MOVING WITH THE VALUE.
            // How far this can go is capped by the meadow, not by the fill: the palette's albedo
            // is linear (0.105, 0.130, 0.046), so green outruns red by 24% no matter what falls on
            // it, and R can only pass G if the fill is as warm as the sun — which would spend the
            // warm-key/cool-fill opposition entirely. Getting the last step to a genuinely
            // brown-warm shade is a MEADOW PALETTE change (more straw and scuff in _MeadowGreen's
            // neighbourhood), which belongs to the ground builder, not here.
            // The ground bounce moves least: it is the only warmth in the fill and it reaches
            // almost nothing but downward faces and the undersides of grass.
            //
            // CORRECTION to the round-2 comment: the terrain shader's _AmbientFloor does NOT
            // backstop at "(0.10, 0.11, 0.14) linear". It is a shader Color property, so it is
            // gamma-decoded like everything else here and lands at linear (0.010, 0.012, 0.017) —
            // an order of magnitude under the trilight ground pole, i.e. inert on every terrain
            // normal. Nothing below depends on it; it is left alone deliberately (the ground
            // builder owns the rest of that SetColor block) but the claim should not be repeated.
            //
            // ROUND 4 moves the SKY POLE ONLY, (0.44, 0.49, 0.64) → (0.49, 0.485, 0.565), and it is
            // the last measurable step of the same argument round 3 was making. The round-3 critique
            // measured near-ground shade as olive with blue only ~10 levels under the top channel,
            // where the board's shade quartiles run warmer; the board's own figure is R−B between
            // +0.013 and +0.082 in sRGB. Round 3 landed at +0.024. Solved against that target rather
            // than nudged, holding shade luminance constant so nothing else in the grade shifts:
            //     cast-shadow meadow  round 3 (0.170, 0.187, 0.147)  Y 0.181  R−B +0.024
            //                         round 4 (0.179, 0.186, 0.131)  Y 0.181  R−B +0.048
            // The fill is still COOL AGAINST THE KEY, which is the whole point of the opposition and
            // is what "cool shadow" means on a painted plate — the key's linear R/B is 2.92 and the
            // fill's is 0.75 — it has simply stopped being a saturated blue of its own. The key still
            // beats the fill in every channel and by more in the one that mattered: per-channel
            // key/fill on flat ground 8.9/5.0/1.5 → 7.4/5.1/1.9.
            // A bonus, and it removes the one place round 3 was flirting with the LogC clip: the
            // refusing north wall's red, the darkest large surface in any frame, goes from sRGB
            // 0.0015 (a hair off zero) to 0.0075.
            // ROUND 6 WITHDRAWS THE "R > G IN THE SHADE" ASK that stood here. It read: the meadow
            // albedo is linear (0.105, 0.130, 0.047), green outruns red by 24%, and only a
            // straw-warmer _MeadowGreen can close that. Round 5 acted on it, and the result was
            // the gold drift — the meadow's whole colour family walked to orange (hue circmean
            // 42.8° → 33.9°, green-band saturated pixels 6.09% → 0.70%) chasing a warmth that was
            // never the shade's job to carry. The board does not support the ask either: it was
            // derived from the darkest quartile of frames whose deepest ink is bounce off sunlit
            // GROUND, and the Cliff's meadow is grass standing in its own sky-lit shade, which is
            // cool on every plate. What the shade needed was CHROMA, not red, and it now gets it
            // from the grade's shadow bucket and Tarrock/GrassTuft's _ShadeFill.
            // The equator and ground poles are deliberately untouched.
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            // ROUND 6: (0.49, 0.485, 0.565) → (0.47, 0.50, 0.58). The sky pole is the fill on every
            // up-facing surface in the frame — which is every square metre of meadow — and it was
            // the one ambient term with RED ABOVE GREEN. A dawn sky dome seen from under it is not
            // red-biased, and letting it be one meant even the meadow's shaded fill was pushing the
            // frame's hue toward orange. It is very nearly a hue-only move: linear luminance goes
            // 0.2071 → 0.2143, +3.5% on the AMBIENT term, which is about 7% of a lit fragment's
            // irradiance at this rig — so lit ground moves +0.25% and shade +3.5%, both under a
            // sRGB level. The distinction the round-5 comment below insists on (hue without level)
            // therefore holds to the precision it was arguing at.
            // ROUND 8 — THE FILL COMES DOWN, AND THE BOUNCE STAYS. Sky (0.47, 0.50, 0.58) →
            // (0.38, 0.41, 0.49) and equator (0.42, 0.44, 0.55) → (0.35, 0.37, 0.47), a 32% cut in
            // linear terms; the ground bounce goes the other way, (0.40, 0.34, 0.26) →
            // (0.41, 0.35, 0.27). Two separate arguments, and they are not the same argument.
            //
            // (1) THE CUT. The round-8 brief's reading of v6 was that the meadow's greens are
            //     already in the albedo and are being washed out by an ambient that never lets
            //     anything go dark, and re-rendering v6's floor pixel by pixel confirms it exactly:
            //     with this cut (and the wrap, which does most of the work — see Grass.cs) the
            //     GREEN-BAND SHARE OF COLOURED FLOOR PIXELS GOES 0.141 → 0.338, with not one albedo
            //     table touched. The meadow was never short of green. It was short of dark.
            //     The cost is priced, not guessed: the sky pole is ~7% of a lit fragment's
            //     irradiance at this rig, so lit ground moves −2.4% and shade −32%, which is the
            //     whole point of moving it. Modelled on v6's floor: lit/shadow ratio 2.21 → 2.78,
            //     share under 0.10 luma 0.196% → 0.824%.
            //
            // (2) WHY THE BOUNCE IS NOT CUT WITH IT, and this is where round 5's finding is kept
            //     rather than reversed. Over the darkest quartile of the near ground six of the
            //     eight fable plates run R above B, because THE LAST LIGHT TO REACH THE BOTTOM OF A
            //     MEADOW IS BOUNCE OFF SUNLIT GROUND, NOT SKY. Cutting the blue fill and the warm
            //     bounce together would have taken the deepest shade straight to cyan — which is
            //     precisely what the first pass of this round's sweep did (deepest-shadow R/B fell
            //     to 0.89 with the shade's median hue at 110°, and no plate on the reference board
            //     contains that hue). Cutting the sky and holding the bounce lands it at 1.59 on
            //     the same measure against round 7's 1.69: the shadow stops warming, and stops
            //     there. The deep shade cools in VALUE and holds its hue.
            RenderSettings.ambientSkyColor = new Color(0.38f, 0.41f, 0.49f);
            RenderSettings.ambientEquatorColor = new Color(0.35f, 0.37f, 0.47f);
            RenderSettings.ambientGroundColor = new Color(0.41f, 0.35f, 0.27f);

            // The project's own gradient sky — NOT Skybox/Procedural, whose Rayleigh remap produces
            // an acid-green horizon band at any blue-shifted tint (measured G exceeding the R/B mean
            // by 45 sRGB levels) and renders the whole below-horizon hemisphere as one flat colour:
            // the literal diorama-on-a-table read the hex retirement was meant to end.
            Shader gradient = Shader.Find("Tarrock/GradientSky");
            var sky = new Material(gradient != null ? gradient : Shader.Find("Skybox/Procedural"));
            if (gradient != null)
            {
                ApplySkyDescription(sky);
                sky.SetFloat("_Dither", SkyDither);
            }
            else
            {
                Debug.LogWarning("[Tarrock] Tarrock/GradientSky not found; using Procedural fallback.");
                sky.SetColor("_SkyTint", new Color(0.60f, 0.62f, 0.72f));
                sky.SetColor("_GroundColor", new Color(0.70f, 0.64f, 0.52f));
            }

            AssetDatabase.DeleteAsset(SkyMaterialPath);
            AssetDatabase.CreateAsset(sky, SkyMaterialPath);
            RenderSettings.skybox = sky;
            RenderSettings.sun = light;

            // Exponential² fog in the CLOUD SEA's colour, not the sky's horizon band: aerial
            // perspective from the first metres (22% at 100 m, ~79% at 250 m) instead of the old
            // linear 150 m dead zone. Two changes from the 07-27 pass, both from wave2_knoll:
            //   - the colour is HazeLinear, so a far ridge fades toward the value of the deck it
            //     stands in rather than toward a duller tan than the deck — that mismatch is why
            //     the rim rock stayed a crisp dark shape on a bright plane;
            //   - the density is nudged up so the far rim (200 m+ across a 256 m region) actually
            //     dies, which is what sells "island", not "valley".
            // Aerial perspective CREATES the elevation read; it does not flatten it.
            //
            // ROUND 2, the density only (the colour is the sky pass's constant and stays married to
            // the deck): 0.0050 → 0.0044. The audit's finding was that the distant massifs came out
            // as uniform lavender slabs — "haze does the depth work that value should". Half of that
            // is fixed above and in the shadow settings, by giving those massifs a lit side and a
            // dark side to ramp in the first place; this is the other half. At 0.0050 the mid-far
            // band was already 43% hazed at 150 m and 63% at 200 m, so a ridge's own light/dark
            // structure was being compressed into a third of its range before it ever reached the
            // eye — the haze was arriving before the value did. At 0.0044 that band reads 35% / 54%,
            // which hands the 120–180 m depths (exactly the range the new 180 m shadow distance now
            // reaches) back to value, while the last 60 m still dies: 70% at 250 m, so the far rim
            // goes on dissolving into the deck and the region still reads as an island, not a valley.
            // Near stays darker and saturated, far lifts and desaturates — a ramp, not a wash.
            //
            // ROUND 5, 0.0044 → 0.0059, and the mode stays EXPONENTIAL² for a reason worth writing
            // down because the round-5 critique asked for a curve that only plain exponential can
            // draw ("a 60 m surface should land 50-60% of the way toward sky, 120 m at 85-90%").
            // Modelled on the round-4 captures with real per-pixel depth — the frames re-fogged
            // through the shader → grade → tonemap chain, band by band — plain exponential at the
            // density that hits those two figures (ρ 0.0090-0.0150) does this:
            //     near cast shadow at 0-10 m   sRGB 0.14 → 0.27 (ρ.0090) / 0.33 (ρ.0150)
            //     mid-ground gold, lit : shade    4.0:1 → 1.38:1 / 1.20:1
            //     mid-ground gold, 1 − B/R        0.715 → 0.527 / 0.436
            // i.e. it fogs the first TEN METRES, and it takes the frame's subject — the gold band at
            // 35-55 m, 15.6% of v1 — below the reference board's own ground-contrast floor (2.4:1,
            // fable-07) and strips a third of its saturation. Exponential² is flat near zero, which
            // is exactly why this region uses it: the same lift at range costs the foreground
            // nothing (0-10 m shade 0.14 → 0.14 at ANY density in this range).
            //
            // THE DENSITY IS PINNED BY TWO CONSTRAINTS THAT ALMOST MEET, so it is derived rather
            // than dialled:
            //   (a) ISLAND, NOT VALLEY. The rim at 200 m must lose three quarters of itself, or the
            //       region reads as a valley with a haze on it: 1 − exp(−(200ρ)²) ≥ 0.75 → ρ ≥ 0.00589.
            //   (b) THE CLOUD ROW MUST SURVIVE. The eight lobe anchors above record the fog
            //       transmittance each was placed for and the sRGB crown-to-base range it buys; the
            //       round-3 failure line was "a deck lobe spans 8 luminance points". Holding every
            //       VALUE-CARRYING mass at ≥ 25 points, the binding one is F at 170 m (40 points at
            //       T 0.57), which needs T ≥ 0.356 → ρ ≤ 0.00598.
            // 0.0059 satisfies both, and the mid-ground check passes with room: the gold band's
            // lit:shade goes 4.01:1 → 3.04:1, inside the board's 2.4-4.1, and 1 − B/R 0.715 → 0.695.
            //
            // WHAT IT BUYS — the aerial staircase the critique asked for, measured on v1's shaded
            // ground (sRGB luminance, by true distance band):
            //     0-10 m  0.14 → 0.14      55-80 m   0.36 → 0.43
            //    20-35 m  0.17 → 0.21      80-120 m  0.39 → 0.56
            //    35-55 m  0.16 → 0.23     120-180 m  0.51 → 0.65
            //                             180-400 m  0.63 → 0.74
            // Round 4's ladder actually went DOWN between 20-35 m and 35-55 m (0.17 → 0.16); every
            // step now rises. The v8 depth reversal shrinks with it: that frame's far mesa (~80 m
            // by ray-trace, not the ~120 m the critique estimated) goes 0.32 → 0.52 against a 45 m
            // dome face that stays at 0.65, so it is no longer the darkest thing in the frame — it
            // sits where a receding form should, between the near shade and the near light.
            //
            // THE TRADE, AND IT IS A REAL ONE. Every cloud anchor loses contrast: transmittance
            // 0.82 → 0.70 (B, 100 m, the hero — 62 → 53 points), 0.66 → 0.51 (E, 138 m — 48 → 37),
            // 0.59 → 0.40 (G, 165 m — 44 → 30), 0.57 → 0.37 (F, 170 m — 40 → 30), 0.51 → 0.28
            // (A, 185 m — 35 → 22), 0.46 → 0.24 (D, 200 m — 31 → 19), and the two masses the table
            // already calls silhouettes (C at 300 m, H at 251 m) go to 2-6 points, which is their
            // job. The anchors are NOT moved to compensate: they were placed by back-projecting a
            // wanted screen position through named frustums, and re-solving eight hand-placed
            // composition anchors is a cloud-pass job with a capture in front of it, not a fog-pass
            // side effect. If round 5's v3/v4 read flat, pulling A and D in by the factor that
            // restores their round-4 transmittance (×0.746) is the first thing to try.
            //
            // ROUND 6 — THE FAR PLANE GETS A COOL. The round-5 critique's fourth finding: the fog
            // is warm-only, so it buys distance without buying cool, and every board frame buys
            // both. MEASURED, near band (bottom 15% of rows) against far band (rows 38-50%):
            //     fable-06  sat 0.281 → 0.169   R/B 1.32 → 1.12   (far / near R/B = 0.85)
            //     fable-08  sat 0.313 → 0.238   R/B 1.27 → 1.13   (0.88)
            //     fable-01  sat 0.488 → 0.440   R/B 1.77 → 1.87   (1.05, and it is a forest
            //                                                      interior looking INTO the sun)
            //     ghibli-04 sat 0.321 → 0.364   R/B 0.83 → 0.92   (already cool everywhere)
            // The relationship, not the literal colour: the far plane loses 0.05-0.11 saturation
            // and its red-over-blue falls to about 0.87 of the near ground's.
            //
            // Round 5's fog rendered its far plane at sRGB R/B 1.319. With the round-6 grade and a
            // 20% pull toward FarCoolLinear it lands at 1.160, against the board's far-band
            // 1.12-1.13, and the whole move costs 1.4% of the fog colour's linear luminance —
            // small enough that the cloud-deck contract below is not visibly broken.
            //
            // WHY ONLY 20%, AND THE CROSS-OWNERSHIP NOTE. HazeLinear is the CLOUD SEA's colour and
            // it is shared on purpose: a far ridge dies INTO the deck instead of silhouetting
            // against it only while the fog and the deck carry the same number (see
            // TerrainRegionGenerator.Sky.cs, which owns HazeLinear). This pull is deliberately kept
            // small enough to stay inside that tolerance rather than being taken further and
            // breaking it. If a future round wants the far plane properly cool, HazeLinear and the
            // deck must move WITH it, and that is a change to Sky.cs, not to this file.
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogDensity = 0.0059f;
            // ---- ROUND 7, THE FOG COLOUR ONLY (sky builder; the grade block below is untouched).
            // The round-6 critique's ninth finding: RenderSettings.fogColor and the sky's own
            // _HazeColor are documented as the ONE value far ridges die into and were 20 sRGB levels
            // and a hue apart — modelled through the graded chain, fog (213, 210, 198) at R−B +15
            // against haze (208, 199, 171) at R−B +37. The cause was a convention slip: Unity
            // gamma-decodes RenderSettings.fogColor exactly as Material.SetColor does, so writing
            // the encode here landed the FOG on the triple read as linear while the SKY landed on
            // its sRGB decode (the `.gamma` this line used to carry). One expression now feeds both — TerrainRegionGenerator.Sky.cs
            // §FarFieldLinear — and both consumers decode it identically, so they cannot drift.
            // The shader-side fog colour is UNCHANGED to the bit: FarFieldLinear's constant is
            // solved backwards so that its decode is round 6's (0.864, 0.840, 0.776) linear. That
            // is deliberate — this round's ground/rock builders are working against the round-6 far
            // plane, and unifying must not move it under them.
            RenderSettings.fogColor = FarFieldLinear;
            DynamicGI.UpdateEnvironment();

            BuildPostVolume();
        }

        /// <summary>
        /// Adds a volume override to <paramref name="profile"/> AND PERSISTS IT.
        ///
        /// THE TRAP (this cost the whole grade once — TerrainProtoPost.asset shipped serialising six
        /// components as <c>{fileID: 0}</c>): <c>VolumeProfile.Add&lt;T&gt;()</c> only
        /// <c>CreateInstance</c>s the component and appends it to the profile's list. The instance
        /// belongs to no asset file, so on save Unity writes a null reference for each one and the
        /// profile reloads with six empty slots — a volume that grades nothing, silently, while the
        /// code that authored it reads as if it worked. The component only becomes real when it is
        /// added to the profile's asset file as a sub-asset, which is what Unity's own
        /// VolumeProfileFactory does and what this helper exists to make unskippable. Every override
        /// in <see cref="BuildPostVolume"/> goes through here; never call <c>profile.Add</c> direct.
        /// </summary>
        private static T AddPersistedOverride<T>(UnityEngine.Rendering.VolumeProfile profile)
            where T : UnityEngine.Rendering.VolumeComponent
        {
            T component = profile.Add<T>();
            // Belt and braces: recent URP sets both itself inside Add, older versions do not, and a
            // sub-asset without HideInHierarchy shows up as loose clutter under the profile.
            component.name = typeof(T).Name;
            component.hideFlags = HideFlags.HideInHierarchy | HideFlags.HideInInspector;
            AssetDatabase.AddObjectToAsset(component, profile);
            return component;
        }

        // The grade — the wake frame's first impression, and until this build it had never actually
        // run (see AddPersistedOverride: the profile's six overrides were serialised as null, so
        // every screenshot to date is raw untonemapped shader output. That, not the landform, is
        // most of what reads as "unfinished" in Assets/Screenshots/wave2_*.png).
        //
        // What the grade is FOR (reference board, fable-01/02/04): dawn light that is gold where it
        // lands and blue-grey where it doesn't, values that separate, colour that stays saturated
        // but never garish (art-audio.md §Visual pillars). The frame arrives here already warm from
        // the sun and already cool in the fill; the grade's job is to widen that gap, not to invent
        // it, and to keep a hand-painted image out of a video-camera look — so no film grain, no
        // chromatic aberration, no lens dirt. Regenerates deterministically like everything else.
        //
        // ROUND 3 — the exposure rebalance. Round 2 got the RAKE right (hard cast-shadow diagonals,
        // gold on the south wall) and that is kept untouched; what it got wrong was the level, and
        // three independent overshoots landed on top of each other: a quartered fill, a log
        // contrast of 22 whose pivot sat four stops above the picture, and a −0.03 additive toe.
        // Together they took the walkable foreground to LITERAL BLACK — mean luminance 0.0026,
        // red and green clipped to zero over most of the frame — while nothing anywhere exceeded
        // 0.85, so there was no sparkle either. Near-to-far read as an inverted 200:1 cliff rather
        // than a ramp.
        //
        // WHERE ROUND 3 LANDS (sRGB display luminance, modelled end-to-end through the terrain
        // shader → fog → bloom → vignette → the URP LUT chain in the order LutBuilderHdr actually
        // applies it, then checked against the round-2 captures — the model reproduces round 2's
        // measured near-ground mean, its channel-clipping signature and its 213:1 near/far cliff,
        // and predicts its brightest pixel to within 0.005):
        //     near cast-shadow meadow   0.17   (was 0.003)   all three channels alive
        //     near lit meadow           0.45   (was 0.126)
        //     lit meadow at 80 m        0.55   (was 0.38)
        //     far lit meadow at 200 m   0.72
        //     limestone square to beam  0.89   red clipping at 1.0, and blooming
        //     darkest channel in frame  0.008  (was 0.000 across 60–96% of the frame)
        //     rake, near lit : shade    2.7:1  — the reference board's own ground contrast is
        //                                        2.4:1 (fable-07) to 4.1:1 (fable-02)
        //     ramp, far lit : near shade 4.3:1 the right way round
        // Every number below that changed was derived, not dialled. If a future pass moves the
        // lamp, the contrast pivot arithmetic in ColorAdjustments has to be re-checked with it:
        // those two are a pair, and round 2 came apart because they were moved independently.
        // ROUND 7 — NOT ONE NUMBER IN THIS METHOD MOVES, AND THAT IS THE FINDING.
        //
        // The round-6 critique's brief for this round was "put round 5's warmth on round 6's value
        // structure": restore chroma LOCALLY — dawn gold near the sun and on lit surfaces, one true
        // dark and one high-chroma accent per frame — without restoring round 5's clip. The reflex
        // is to spend it here, on saturation and on the highlight bucket. Modelled end to end, that
        // is the wrong instrument twice over:
        //
        // (1) EVERY OVERRIDE IN THIS METHOD IS GLOBAL IN SPACE. ColorAdjustments.saturation,
        //     colorFilter and WhiteBalance act on the shade as hard as on the light, which is how
        //     round 6 ended up grey EVERYWHERE from one number; ShadowsMidtonesHighlights is local
        //     in VALUE but not in MATERIAL, so it cannot tell the lit meadow from the sky, which
        //     sits in the same highlight bucket at twice the luminance. "Local warmth" is a thing
        //     only the lamp and the surfaces can do. Both were used instead: the lamp above, and
        //     _BleachTint in Tarrock/GrassTuft and Tarrock/TerrainPainterly.
        //
        // (2) THE SKY IS DOWNSTREAM OF THREE OF THESE KNOBS AND WAS REBUILT THIS ROUND. The sky
        //     pass's whole solve assumes this grade: its output sits at linear 0.3-1.0, entirely
        //     inside the highlightsStart 0.10 bucket, so smh.highlights, adjust.saturation and
        //     adjust.colorFilter are the three values that move its numbers most — a saturation
        //     raise here would have amplified the new sky chroma and pushed its peak red from a
        //     predicted 251 into the clip. Re-running the sky pass's own model against this
        //     profile confirms the contract holds: 0.000% of pixels at or over 254 and 0.000% at
        //     blue <= 2 in all four sky views. That check is only meaningful because nothing here
        //     changed; if a future round moves saturation, colorFilter or the highlight triple, it
        //     MUST re-run that model rather than trust the number.
        //
        // What the round asked this method for and got from elsewhere, with the predicted movement:
        //     lit-zone R/B      1.79 -> 1.93   the lamp, plus the two surfaces' bleach tints
        //     true dark         0.001 -> 0.069 share of frame under 0.10 luma (v1), from the
        //                                      grass mat's root darkening and blade gradient
        //     high-chroma accent 0.35 -> 0.45  top-1% chroma, from the scoured drift's gold
        //     per-material sat   x1.00 to x1.18 by material, where round 6 moved five materials
        //                                      by one ratio of 0.427-0.478
        //
        // ROUND 8 — NOT ONE NUMBER IN THIS METHOD MOVES EITHER, and this time there are three
        // reasons rather than two.
        //
        // (1) Round 7's argument stands unchanged: every override here is GLOBAL IN SPACE, and this
        //     round's whole thesis is that the previous two rounds' warmth failed BECAUSE it was
        //     spent on terms that were not local to the light. Spending it here would be the same
        //     mistake a third time.
        //
        // (2) THE SKY IS BEING REBUILT IN THIS ROUND BY ANOTHER PASS. smh.highlights,
        //     adjust.saturation and adjust.colorFilter are the three values the sky's numbers move
        //     most, and its solve is being run against THIS profile while this file is being
        //     edited. Moving any of them here would invalidate that solve silently. If a future
        //     round wants them, it must own both passes or sequence them.
        //
        // (3) THE ROUND'S TWO GRADE-SHAPED ASKS DO NOT NEED IT. The brief asked for the sky's share
        //     of top-1% chroma to be capped (round 7 measured 78% in v2 against fable-01's 0%) and
        //     for the high-chroma accent to come back. Both are SHARES OF THE FRAME, so both are
        //     answered by giving the GROUND its chroma back rather than by taking the sky's away:
        //     re-rendered on v6, chroma p99 goes 0.281 → 0.345 and the peak-chroma population goes
        //     0.000% → 0.58% from the lamp and the two surface tints alone. A saturation raise here
        //     would have moved the sky's chroma up alongside the ground's and left the share where
        //     it was.
        private static void BuildPostVolume()
        {
            var profile = ScriptableObject.CreateInstance<UnityEngine.Rendering.VolumeProfile>();
            AssetDatabase.DeleteAsset(PostProfilePath);
            AssetDatabase.CreateAsset(profile, PostProfilePath);

            // NEUTRAL, not ACES. ACES is the reflex choice and the wrong one here: it desaturates
            // mids, crushes toe contrast, and skews bright warm light toward white — it would eat
            // the gold out of the dawn and the green out of the meadow, which are the two colours
            // the Cliff's colour script actually names. Neutral rolls the highlights off without
            // arguing with the palette, which is what a hand-painted image wants from a tonemapper.
            var tone = AddPersistedOverride<UnityEngine.Rendering.Universal.Tonemapping>(profile);
            tone.mode.Override(UnityEngine.Rendering.Universal.TonemappingMode.Neutral);

            // EXPOSURE 0. The lamp above carries the level now, and it is the only lever that can:
            // post exposure multiplies the unlit sky and the unlit cloud deck along with the
            // ground, so buying the meadow's brightness here would have kept the 7.9:1 sky-over-
            // ground ratio and simply pushed the far haze (already sRGB 0.72) to white. Neutral is
            // the correct value for a grade whose render arrives correctly exposed.
            //
            // CONTRAST 22 → 14, and this is the second half of the round-2 crush. URP does
            // contrast in LogC about ACEScc mid-grey, which decodes to LINEAR 0.2249. Round 2 put
            // the whole walkable frame four to five stops under that pivot, where log contrast is
            // not an expander but a divider — and worse, LogC's toe is a straight line through
            // (linear 0, logC 0.0928), so past a certain darkness the pivot map returns a NEGATIVE
            // logC value and the decode gives negative linear. The clip point is exact:
            //     linear_min = (0.4136 − 0.32078/c − 0.092819) / 5.301883
            // At c = 1.22 that is 0.0109 linear. Round 2's shadowed meadow rendered at 0.011–0.016
            // linear, i.e. straddling it — which is why the measured foreground was not "dark" but
            // literally zero in red and green. At c = 1.14 the clip point is 0.0074, and the
            // darkest large surface in frame (the refusing north wall, red 0.0085 linear) clears
            // it. Nothing the player has to read is legislated out of the picture any more.
            // The over-0.9 end the audit asked for is the lamp's job, not this one.
            // Saturation 18 → 16: the shadows/highlights split below now actually fires on the
            // ground (it never did in round 2 — see its ranges), so chroma arrives from the split
            // rather than from a global boost that lifts the haze along with everything else.
            var adjust = AddPersistedOverride<UnityEngine.Rendering.Universal.ColorAdjustments>(profile);
            adjust.postExposure.Override(0f);
            adjust.contrast.Override(14f);
            // SATURATION 16 → 6, AND THIS IS THE STAGE THAT ACTUALLY WROTE THE ZEROS.
            //
            // URP applies it as c = luma + s·(c − luma) and then clamps with max(0). It is a
            // multiplier on the DISTANCE from luminance, so on a pixel whose blue already sits far
            // below its own luma it does not darken blue, it drives blue NEGATIVE and the clamp
            // writes a hard zero — which is why round 5's lit meadow measured median blue 0 AND
            // saturation exactly 1.000 over 75.9% of its pixels. The threshold is exact: blue
            // survives the multiply only while B > luma·(s − 1)/s, i.e. 13.8% of the pixel's own
            // luminance at s = 1.16 and 5.7% at s = 1.06.
            //
            // The inputs are fixed upstream (lamp hue, albedo family, the blade's tip, the sun
            // bleach in Tarrock/GrassTuft), so the meadow no longer arrives anywhere near that
            // threshold. But 16 was also doing something the reference board never does: it is a
            // GLOBAL boost, applied equally to the shade and to the light, and the board's frames
            // run their saturation DOWN as luma goes UP. Chroma now comes from where it comes from
            // in a painting — the shadow bucket below, the cool ambient, and the surfaces' own
            // colour — and the highlight end is allowed to go pale.
            adjust.saturation.Override(6f);
            // ROUND 6: the filter loses its blue cut. At (1.00, 0.975, 0.945) this was a fifth
            // warm multiply stacked on a chain that already had four, and it acted on the WHOLE
            // image including the shade, which is the one place the frame has left to be cool.
            // (0.998, 1.000, 0.970) is the same idea at a third of the strength and with green no
            // longer pulled under red — the meadow's family is green and the filter should not be
            // quietly voting against it. The dawn's warmth is the lamp's job, above.
            adjust.colorFilter.Override(new Color(0.998f, 1.000f, 0.970f));

            // The warm-light/cool-shadow separation, and the single most load-bearing override here.
            // Study fable-01: the shadowed ground is not dark green, it is blue-grey, and the lit
            // ground is not bright green, it is gold — the hue MOVES with the value. Shadows take a
            // clear blue lift; highlights take gold and drop blue.
            //
            // TWO ROUND-2 BUGS ARE FIXED HERE, and between them they explain why the split never
            // reached the picture at all.
            //
            // (1) THE TRIPLES ARE GAMMA-DECODED. ColorUtils.PrepareShadowsMidtonesHighlights runs
            //     every component through Mathf.GammaToLinearSpace before it reaches the shader, so
            //     round 2's shadows (0.82, 0.92, 1.16) arrived as a multiplier of
            //     (0.638, 0.828, 1.386) — a 36% cut in red, not the ~18% the number reads as, and
            //     applied at full strength over the whole ground. That is most of why red was the
            //     first channel to die. The values below are authored through the INVERSE
            //     (Mathf.LinearToGammaSpace) so the number in the source and the number the shader
            //     multiplies by finally agree: shadows land on (1.00, 0.96, 1.08) and highlights on
            //     (1.14, 1.04, 0.88). Do not "tidy" these back to round numbers — round numbers
            //     here mean an unintended multiplier.
            //     The shadow tint is also gentler than round 2 read as intending, and deliberately:
            //     it no longer cuts red at all. A red cut on a green meadow under a cool fill is
            //     how shade turns cyan, and no frame on the reference board has cyan shade. The
            //     blue lift stays, so the tint is still cool — it just stops fighting the key. It
            //     costs the lit side nothing: this bucket ends at luminance 0.10 and lit meadow
            //     arrives at 0.17, so every lit probe is bit-identical with or without it.
            //
            // (2) THE RANGES WERE ABOVE THE PICTURE. shadowsEnd 0.35 / highlightsStart 0.50 are
            //     luminances in the graded linear image, and round 2's SUNLIT meadow arrived at
            //     that stage with a luminance of 0.17. Both the lit meadow and the shade were
            //     therefore inside the SHADOWS bucket: the sunlit ground was being tinted cool and
            //     the gold half of the split never fired on any walkable surface in the frame. It
            //     shows in the capture — round2/v1's brightest meadow band measures
            //     (0.148, 0.172, 0.160), which is not gold, it is grey. With the lamp above, cast
            //     shadow reaches this stage at 0.020 and lit meadow at 0.17, so the ranges are set
            //     to straddle THAT: shade sits ~91% in the cool bucket, lit meadow takes about a
            //     third of the gold and the sunlit south wall takes all of it. highlightsEnd comes
            //     down from its 1.0 default for the same reason — left there, the smoothstep would
            //     have handed the meadow 19% of a tint it needs at full strength.
            var smh = AddPersistedOverride<UnityEngine.Rendering.Universal.ShadowsMidtonesHighlights>(profile);
            // ROUND 6 — WHITE IN THE LIGHT, COLOUR IN THE SHADOWS, and round 5 had this exactly
            // inverted. Its highlight bucket resolved to (1.14, 1.04, 0.88): it CUT BLUE by 12% on
            // the brightest surfaces in the frame, which is the third multiply in the chain that
            // ended at a hard zero, and it means the sky beside the sun rendered as a saturated
            // (227, 200, 148) where every plate on the board takes that region to a near-colourless
            // cream. Measured on the board: top-luma-decile saturation runs 0.08-0.34 and falls
            // monotonically from the mid deciles; round 5's frame ran 0.43 and RISING from decile 6.
            //
            // A per-channel multiplier cannot desaturate, so the two ends split the job: the
            // highlight bucket stops adding chroma and simply carries a whisper of the dawn's
            // warmth (resolved (1.051, 1.030, 1.009) — every channel at or above 1, blue no longer
            // cut), and the SHADE takes the chroma the picture used to buy globally (resolved
            // (0.935, 0.982, 1.152) — a real cool, up from 1.08 in blue and now with a red cut,
            // which round 3 was right to fear on a green meadow under a cool fill and which is
            // safe now that the meadow's albedo is no longer starved of blue).
            // The actual desaturation of the lit end is done at the surface, where a painter does
            // it — see _SunBleach in Tarrock/GrassTuft.
            smh.shadows.Override(new Vector4(0.971f, 0.992f, 1.064f, 0f));    // → (0.94, 0.98, 1.15) cool shade
            smh.highlights.Override(new Vector4(1.022f, 1.013f, 1.004f, 0f)); // → (1.05, 1.03, 1.01) pale light
            smh.shadowsStart.Override(0f);
            smh.shadowsEnd.Override(0.10f);
            smh.highlightsStart.Override(0.10f);
            smh.highlightsEnd.Override(0.30f);

            // THE FLOOR — and in round 2 this was the toe, and the toe is what ate the picture.
            //
            // Lift's w is an ADDITIVE offset in linear pre-tonemap space, and the rgb triple is
            // luminance-normalised around it (ColorUtils.PrepareLiftGammaGain), so round 2's
            // (0.96, 0.99, 1.06, −0.03) resolved to a constant subtraction of
            // (−0.0395, −0.0296, −0.0057) from every pixel in the frame. Set that beside what
            // actually reached it: after the round-2 contrast had finished with the shadowed
            // meadow it was at 0.004 linear. The toe took away eight times the whole signal. Red
            // and green went negative and clipped; blue survived only because the "blue-black"
            // hue tilt made its offset seven times smaller — which is precisely the signature the
            // critique measured, red and green at literal zero over 60–96% of the frame with blue
            // still readable. The intent (a storybook page's deepest shade is blue-black, never a
            // neutral crush) was right; the sign and the magnitude were not.
            //
            // ROUND 3 inverts it. w = +0.0025 is a small POSITIVE floor: nothing anywhere in the
            // frame can now reach zero in every channel, which is the ask — cast shadow keeps its
            // hue. It is invisible where the picture lives (1% of the lit meadow, 0.3% of the
            // haze) and decisive where it does not: the refusing north wall's red, which contrast
            // alone leaves at 0.005, and the crevices and rock undersides, which land at sRGB
            // 0.01–0.04 — still the darkest thing in frame, still near-black, but ink on paper
            // rather than a hole in it. The reference board agrees: fable-01/05/07 hold their
            // fifth-percentile min-channel at 0.047–0.051 and never bottom out across the
            // walkable ground.
            // The triple keeps the hue job and nothing else. Pulled in from 3 sRGB points of tilt
            // to 1.5, it resolves to (−0.0016, +0.0001, +0.0034): the tilt is now a fifth of the
            // darkest value it acts on instead of eight times it.
            //
            // ROUND 5 REVERSES THE TILT — blue-black to WARM-BLACK — and this one number is the
            // whole of the warm-shade fix. Rounds 3 and 4 both wrote "the deepest shade is
            // blue-black" as a storybook convention and never checked it against the bar. Checked:
            // over the DARKEST QUARTILE of the near ground (the pixels the convention is about),
            // six of the eight fable plates run R above B by +0.033 to +0.095 sRGB, and fable-01/02/
            // 07 run R > G > B outright — (34, 24, 14) on fable-01. The deepest ink on those plates
            // is a warm brown-black, because the last light to reach the bottom of a meadow is
            // bounce off sunlit ground, not sky. Round 4 measured −0.001 there and this file's own
            // arithmetic said +0.048, because that arithmetic was for flat cast-shadow TERRAIN and
            // the near ground is mostly GRASS TUFTS — Tarrock/GrassTuft carries no _ShadowTint and
            // its hollow tint is a blue-green, so the darkest quartile is the one population the
            // terrain derivation never covered. Measured on round4/v1 it came out at
            // (18.5, 27.1, 33.1) sRGB: blue on top by 15 levels, which is the one hue no frame on
            // the board contains.
            //
            // WHY THE LIFT AND NOT THE FILL. The requirement was warmth WITHOUT MOVING EXPOSURE, and
            // lift's w is additive in linear pre-tonemap space, so it is the only lever in the
            // chain that acts on the bottom decade and nothing else. The three alternatives were
            // modelled on the round-4 frames and rejected with numbers:
            //   - ambient EQUATOR warmer: moves the darkest quartile by 0.0002. Those pixels are
            //     up-facing, so they see the sky pole, not the equator.
            //   - ambient SKY POLE warmer: it is the fill for every shaded surface in the frame, so
            //     it cannot be moved without moving the whole shade tier's level as well as its hue.
            //   - terrain _ShadowTint warm-neutral: lands +0.016 but lifts frame luminance 5.8% and
            //     lit ground from 0.463 to 0.487 — at a 12° sun almost nothing reaches wrapped 1.0,
            //     so `lerp(_ShadowTint, 1, lit)` is still tinting the LIT ground. Not exposure-safe.
            // Reversing the tilt lands it in one move, and the cool half of the split is untouched:
            // this offset is 0.6% of the lit meadow's own value and the 25-50% quartile stays where
            // round 4 put it.
            //     round4/v1 darkest quartile  (18.5, 27.1, 33.1)  R−B −0.057  →  (31, 28, 22)  +0.036
            //     round4/v2 darkest quartile  (26.6, 31.4, 29.2)  R−B −0.010  →  (37, 32, 17)  +0.077
            //     frame mean luminance  v1 0.3560 → 0.3561,  lit ground 0.463 → 0.462 (unmoved)
            // w goes 0.0025 → 0.0030 for one reason: with the tilt reversed the resolved offsets are
            // (+0.0057, +0.0024, +0.0007) and BLUE is now the first channel to leave, so w has to
            // carry blue's floor instead of red's. At 0.0025 blue's offset is +0.0002, which is no
            // floor at all; at 0.0030 it is +0.0007 and round 3's rule — nothing in frame reaches
            // zero in every channel — still holds, now with the deepest shade reading warm.
            var floor = AddPersistedOverride<UnityEngine.Rendering.Universal.LiftGammaGain>(profile);
            floor.lift.Override(new Vector4(1.010f, 1.000f, 0.995f, 0.0030f));

            // Warm dawn white balance — kept modest ON PURPOSE. Temperature is global: it warms the
            // shade as readily as the light, so a heavy hand here would spend the cool half of the
            // split the override above just bought. Enough to say "dawn", not enough to say "filter".
            // Tint a touch toward magenta pulls the meadow's mass off acid green into olive-gold.
            var balance = AddPersistedOverride<UnityEngine.Rendering.Universal.WhiteBalance>(profile);
            // ROUND 6. Temperature 8 → 5 for the same reason the colour filter came down: it was
            // one of five warm multiplies and it is the one that warms the SHADE hardest.
            //
            // TINT +3 → −2, and this reverses a round-5 decision by name. The comment above says
            // the magenta "pulls the meadow's mass off acid green into olive-gold" — that is a
            // description of the gold drift the round-5 critique then measured: green-band
            // saturated pixels 6.09% → 0.70%, blue-band 14.55% → 0.07%, hue circmean 42.8° → 33.9°.
            // The Cliff's colour script says wind-scoured GREEN; a global magenta is a standing
            // vote against it. Modelled through the whole chain, this one number is worth about
            // 2.5° of frame hue circmean and 2 percentage points of green-band pixels — small, but
            // it is the difference between a meadow whose family is green and one whose family is
            // gold, and it costs the dawn nothing that the lamp is not already paying for.
            balance.temperature.Override(5f);
            balance.tint.Override(-2f);

            // Bloom for the low sun: threshold just under 1 so it catches the rim-lit crests, the
            // backlit grass and the horizon band and NOTHING else — bloom on a storybook frame is
            // the glow around a light source, not a haze over the picture. Wide scatter keeps it
            // soft-edged (a painted glow, not a lens artefact) and the gold tint means the light
            // that spills is the same light that fell. HQ filtering left off: this scene has a
            // Mobile renderer target, and scatter buys the same softness for free.
            // ROUND 3: threshold 1.05 → 0.90. Round 2 set 1.05 to keep "a great deal of ordinary
            // lit grass" out of the bloom, but that fear was based on the same dropped-albedo
            // arithmetic as the lamp: against a 2.90 lamp the brightest thing on the ground was
            // 0.80 linear, so a 1.05 threshold caught nothing at all outside the sky and the frame
            // ended up with no sparkle whatsoever. Against the 8.00 lamp the numbers are real, and
            // 0.90 is chosen from them by margin on both sides:
            //     limestone square to the beam    2.69 linear   blooms
            //     the sky's blaze core            1.75 linear   blooms
            //     the sky's horizon band          0.79 linear   does not — a 14% margin, so the
            //                                                   glow stays around the light source
            //                                                   and never becomes a veil over it
            //     flat lit meadow at 80 m         0.29 linear   does not, by a factor of three
            // So bloom lands on exactly what it is for — the blaze, sun-square rock, rim-lit
            // crests and backlit grass — and it is what carries those pixels the last step to
            // white. Intensity, scatter and tint are unchanged; they were never the problem.
            var bloom = AddPersistedOverride<UnityEngine.Rendering.Universal.Bloom>(profile);
            bloom.threshold.Override(0.90f);
            bloom.intensity.Override(0.45f);
            bloom.scatter.Override(0.72f);
            bloom.tint.Override(new Color(1.00f, 0.93f, 0.80f));

            // Storybook vignette: the corners settle and the eye is pushed down the valley, but
            // soft enough to stay unnoticed. The colour is a deep blue-grey rather than black — a
            // black vignette punches a hole in an illustration, where a cool one reads as the
            // page's own edge falling into shade.
            // ROUND 3 backs 0.24 out to 0.18 and softens 0.45 → 0.50. URP scales these by 3 and 5
            // respectively, so 0.24/0.45 was multiplying the bottom-centre foreground by 0.82 and
            // the corners by 0.54 — a second darkening laid over the near ground, which is the one
            // region of the frame this pass exists to make readable. At 0.18/0.50 the same points
            // take 0.88 and 0.70: still a settled edge, no longer a tax on the walkable floor.
            var vignette = AddPersistedOverride<UnityEngine.Rendering.Universal.Vignette>(profile);
            vignette.intensity.Override(0.18f);
            vignette.smoothness.Override(0.50f);
            vignette.color.Override(new Color(0.05f, 0.06f, 0.10f));

            EditorUtility.SetDirty(profile);
            AssetDatabase.SaveAssets();

            var volumeGo = new GameObject("PostVolume");
            var volume = volumeGo.AddComponent<UnityEngine.Rendering.Volume>();
            volume.isGlobal = true;
            volume.sharedProfile = profile;
        }
    }
}
