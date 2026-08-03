namespace Tarrock.Editor
{

    using System.Collections.Generic;
    using Tarrock.Regions;
    using UnityEditor;
    using UnityEngine;

    // Partial of TerrainRegionGenerator: SKY AND CLOUD.
    // Owns the sky gradient, cloud-bank and vault-cloud description written into the sky
    // material, the cloud sea deck, and the cloud lobe masses that ring the island.
    public static partial class TerrainRegionGenerator
    {

        // -------------------------------------------------------------------------------------
        // The dawn atmosphere. ONE description, consumed by three places that must agree or the
        // island-in-cloud read breaks: the skybox, the exponential fog, and the cloud deck's fade.
        //
        // THE COLOUR CONVENTION, corrected in round 6 — the old wording here said "all LINEAR,
        // material colours are consumed raw" and that was never true. This project renders in
        // LINEAR colour space (ProjectSettings m_ActiveColorSpace: 1), where Material.SetColor on a
        // plain (non-[Gamma]) Color property gamma-DECODES what it is handed. So every triple below
        // is authored sRGB and arrives at the shader as its linear decode:
        //     zenith   authored (0.20, 0.32, 0.54)  →  shader (0.033, 0.078, 0.258) linear
        //     haze     authored (0.90, 0.85, 0.74)  →  shader (0.787, 0.694, 0.513) linear
        // The values are NOT re-solved in this pass, because they are what round 5 was tuned on and
        // what round 5 measured: an offline port of SkyGradient.hlsl plus the full URP grade chain,
        // evaluated with exactly this decode, reproduces round5/v3's clean sky to an RMS of 1.27
        // sRGB levels and its hero cloud's darkest-quintile R−B to 0.1 of a level. Only the naming
        // was wrong; the render is what it says it is. The "…Linear" suffixes are kept ONLY because
        // TerrainRegionGenerator.Lighting.cs (a different builder's file) references HazeLinear by
        // name; renaming them belongs in the same change as that reference.
        //
        // THAT ONE MISMATCH IS FIXED IN ROUND 7. It was real rather than a naming slip:
        // RenderSettings.fogColor was written as (…).gamma, which Unity then gamma-decodes, so the
        // FOG landed on HazeLinear read as LINEAR while the sky's own haze landed on its sRGB
        // decode — 20 sRGB levels and 22 points of R−B apart, on the one value that is supposed to
        // be where every far ridge dies. Both are now written from FarFieldLinear below and both
        // decode it the same way. See that property and Lighting.cs §the fog colour.
        //
        // WHY THESE NUMBERS (2026-07-31 look pass, against Assets/Screenshots/wave2_*). Measured
        // off wave2_knoll: the whole visible sky moved eight sRGB levels from frame top to horizon
        // — a flat tan card. The old ramp's transition lived above the frustum, because at the
        // gameplay camera's pitch the player only ever sees the first ~25° of sky. So the mid band
        // is pulled down to sin(elev)=0.44 and both ramps are smoothstepped, putting real value
        // structure (0.92 → 0.58 linear) inside the band that is actually on screen. Reference
        // board: fable-03, fable-04, animation-04.
        // -------------------------------------------------------------------------------------
        // ROUND 7 — TWO SKIES IN ONE FRAME, which is what the reference board actually has and
        // what round 6 averaged away. Measured on the board with this round's own implementation
        // (scratchpad round7/sky-warmth/ref_sky.py): the sun-side plates (fable-01, fable-04) run
        // HSL saturation 0.29-0.49 at R−B +47..+60, and the anti-sun plates (fable-06,
        // animation-04) run 0.28-0.45 at R−B −45..−47. Ours ran 0.16 at R−B +3 — the mean of the
        // two, which is grey. So the horizon goes properly GOLD, the mid band stops being a cream
        // and becomes a real cool BLUE, and the zenith deepens; the bearing terms below then decide
        // which of the two any given part of the sky is looking at.
        // (The critic's "fable-01 S 0.66" is not chased: that plate is a forest interior measured
        // through canopy. Measured on its actual sky patch it is S 0.489 — inside this target.)
        // ROUND 10 DEEPENS THE MID BAND, (0.40, 0.51, 0.75) → (0.24, 0.36, 0.74), and it is the
        // paint half of this round's sky change (the light half is SkyBearingPower below). Two
        // board-validated gates were failing on the same fact — our sky is not blue enough and is
        // too bright — and both are this band, because at the gameplay pitches the mid band is most
        // of the visible vault:
        //     bluest bare sky R−B   board fable-06 −168.6, totoro −121.8;  round 9 v3 −39.7
        //     bright sky-mass share board ceiling 26.7% (fable-04);        round 9 v3 53.4%
        // The band keeps its blue-green ratio (it is the same hue, two values down and more
        // saturated), so the "two skies in one frame" structure round 7 built is untouched — what
        // changes is how far the cool sky is allowed to fall on the side of the frame away from the
        // dawn. The gold band and the far field are NOT moved: SkyHorizonLinear feeds FarFieldLinear,
        // which is a standing contract with Lighting.cs's fogColor, and "pale dawn gold" is the
        // Cliff's palette (art-audio.md §Region color scripts).
        // WHY THIS DEPTH AND NOT ONE STOP LESS. (0.30, 0.42, 0.74) was tried first, everything else
        // held equal; measured on the round-9 capture through the sky model's own delta
        // (scratchpad round10/builderS/sweep3.log and finalrun.log), (0.30…) → (0.24…) moves
        //     bluest bare sky R−B   v3 −85.7 → −97.9   v4 −96.9 → −112.0   v8 −102.0 → −110.8
        //     bright sky-mass       v3 37.4 → 35.2%    v4 20.0 → 19.5%     v8 17.2 → 13.6%
        // for 0.014 of luminance on v1's sky (0.599 → 0.585), v1 being the frame furthest along
        // the "keep the dawn" side of the trade. Nothing else in the eight moves by more than half
        // a point, so the deeper band is bought almost entirely off the anti-sun vault.
        private static readonly Color SkyHorizonLinear = new Color(1.00f, 0.80f, 0.46f);
        private static readonly Color SkyMidLinear = new Color(0.24f, 0.36f, 0.74f);
        private static readonly Color SkyZenithLinear = new Color(0.15f, 0.29f, 0.60f);

        // Below the horizon the Cliff has NO ground: it has the cloud sea (world.md §The Cliff).
        // Fog, the sky's lower hemisphere and the deck's far field all land on this one luminous
        // value — which is what lets distant rim rock die INTO the deck instead of silhouetting
        // against it. The old fog colour was a duller tan than the deck it sat in front of, so
        // every far ridge stayed a hard dark shape on a white plane.
        //
        // ROUND 7 UNIFIES IT WITH THE FOG, which is the round-6 critique's ninth finding: the fog
        // and the sky's own haze were 20 sRGB levels and a hue apart (modelled through the graded
        // chain: fog sRGB (213, 210, 198), R−B +15; sky haze (208, 199, 171), R−B +37) while being
        // documented as the one value far ridges die into. The mismatch was a CONVENTION bug —
        // Lighting.cs wrote fogColor as (…).gamma, so the fog landed on this triple read as LINEAR
        // while the sky landed on its sRGB decode.
        //
        // Unified ONTO THE FOG'S VALUE, not the sky's, for two reasons. It is the cooler of the two,
        // and re-warming the far plane is the last thing a round that has to keep cloud shadows cool
        // needs (§the vault washes below). And it is the number the other round-7 builders are
        // working against right now: expressed this way the fog's shader-side colour does not move
        // by a bit, so nothing on the ground has to be re-solved for it. The triple is therefore
        // solved backwards from that requirement — g2l(lerp(this, FarCoolLinear, FarCoolShare))
        // must equal round 6's fog (0.864, 0.840, 0.776) linear — and the one place both are now
        // written from is FarFieldLinear below.
        private static readonly Color HazeLinear = new Color(0.992f, 0.958f, 0.888f);
        private static readonly Color SunGlowLinear = new Color(1.00f, 0.82f, 0.52f);

        // ROUND 8 — THE FAR FIELD IS DERIVED FROM THE SKY IT SITS IN, and this is the fix for the
        // fog/haze seam that rounds 6 and 7 both ASSERTED and neither measured (round-7 critique,
        // finding 6: "delta R−B across the ridge seam is −45.5, and it got worse").
        //
        // WHAT THE SEAM ACTUALLY IS, measured rather than assumed. Critic 2's own seam bands were
        // reproduced in an offline port of SkyGradient.hlsl plus the full URP grade chain, with one
        // fitted scalar per band (how much of the band is fog-dominated surface); the fit lands on
        // 0.71 and 0.83 and the control reproduces round 7 to 2.3 and 1.7 sRGB points of R−B. With
        // that in hand the cause is unambiguous, and it is not a colour-space bug this time:
        //     * the SKY just above the horizon carries the dawn wash — sky.sunGlow × bearingRise ×
        //       bearing, which at 39° off the sun is +(0.95, 0.60, 0.22) LINEAR laid on top of the
        //       horizon gold. It grades to R−B +82.
        //     * the FAR FIELD carries none of it. Fog is a constant colour, so every ridge and
        //       every metre of deck past ~350 m resolved to a near-neutral cream at R−B +15.
        // Sixty-seven points of hue between two things the docs call one value. A cloud sea lit by
        // a dawn is at the far end of the SAME air path as the sky above it; the honest fix is to
        // bake a representative share of that path into the one constant that has to stand for it.
        //
        // The share is solved, not dialled: 0.65 puts the modelled seam at −5.4 (v3) and −2.4 (v4)
        // against the round-7 measurements of −45.5 and −29.0, with the gate at ±12. Below 0.60 v3
        // fails; above 0.80 both overshoot warm.
        //
        // AND THE VALUE IS HELD, because the aerial depth ramp is a protected round-7 win: the
        // sRGB-space lerp toward the gold costs luminance, so it is scaled back up until red sits
        // at 1.0 and no further. Modelled, the far field's graded luminance moves 205 → 197 in v3
        // and 200 → 189 in v4 — the depth ramp keeps its shape, only its hue turns.
        private const float FarFieldDawnShare = 0.65f;
        private const float FarFieldValueHold = 1.05f;

        /// <summary>THE far field: the single value the exponential fog, the sky's lower hemisphere
        /// and the cloud deck's far fade all land on. RenderSettings.fogColor (Lighting.cs) and the
        /// sky materials' _HazeColor are both written from THIS, so the round-6 finding that they
        /// were 20 sRGB levels and a hue apart cannot recur: there is one expression now, and both
        /// consumers gamma-decode it identically (Material.SetColor and RenderSettings.fogColor
        /// both convert a plain Color to linear in this project's linear colour space).
        /// ROUND 8: it is no longer an independent triple at all — it is the sky's own horizon band,
        /// cooled by the share of far-field air that never sees the dawn. See the block above.</summary>
        private static Color FarFieldLinear
        {
            get
            {
                Color cool = Color.Lerp(HazeLinear, FarCoolLinear, FarCoolShare);
                Color dawn = Color.Lerp(cool, SkyHorizonLinear, FarFieldDawnShare);
                return new Color(
                    Mathf.Min(dawn.r * FarFieldValueHold, 1f),
                    Mathf.Min(dawn.g * FarFieldValueHold, 1f),
                    Mathf.Min(dawn.b * FarFieldValueHold, 1f));
            }
        }

        private const float SkyMidHeight = 0.32f;      // sin(elev) where the cool band is reached
        // ROUND 8, 0.09 → 0.045, and it is the second half of the seam fix. Below the horizon this
        // region has no ground: it has the far field, and the docs say so (world.md §The Cliff).
        // At 0.09 the sky a mere 3° under the horizon was still 30% horizon GOLD while the ridge
        // in front of it was 100% fog, so v4's seam could not close however the fog was coloured —
        // the two sides moved together. At 0.045 (2.6°) everything below the horizon IS the far
        // field, which is what the doc claims and what makes the join seamless by construction
        // rather than by matching. Modelled, v4's seam goes −29.0 → −2.4 on this and the fog
        // derivation together, and neither alone reaches the gate.
        private const float SkyHazeDepth = 0.045f;     // sin(elev) over which gold gives way to haze
        private const float SkyGlowFalloff = 7f;
        private const float SkyGlowBroad = 0.30f;
        private const float SkyGlowBroadPower = 5f;
        private const float SkyGlowCore = 0.55f;       // over 1 at the sun: the blaze blooms, locally
        private const float SkyGlowCorePower = 120f;
        // ROUND 5 — THE SUN'S BEARING, which round 4's sky did not have. The proof is v8's column
        // medians: 128.1 125.7 121.4 116.9 113.6 | 113.6 116.9 121.4 125.7 128.1, an EXACT mirror
        // about the frame centre, which can only happen if the sky is a function of elevation
        // alone. SkyGlowBroad is not the missing term — at power 8 it is under 1% of its peak 35°
        // off the sun, so it lights a lozenge and leaves the rest of the vault ignorant of the dawn.
        //
        // The board leans instead, and the lean is the biggest single thing separating its skies
        // from ours: fable-04's sky strip climbs 126.5 → 169.8 toward the sun across ten column
        // bins (+43 sRGB luminance points) and fable-01's 58.2 → 100.6 (+42).
        //
        // Two terms, because one cannot do it. THE RISE is a broad warm wash peaking at the sun's
        // bearing; on its own it is nearly useless here, since this grade's sky sits in the Neutral
        // tonemap's shoulder where 0.34 of extra glow buys ~10 points. THE TILT is the one with
        // travel: it steepens the elevation ramps on the anti-sun side, so the cool mid and then
        // the zenith come DOWN that side of the sky while the gold climbs on the sun's side — and
        // the zenith is 90 points below the horizon band, so there is somewhere to go. Modelled
        // through the URP LUT chain over v3's frustum, rise 0.45 / power 1.3 / tilt 3.2 turns
        // round 4's +1.8 lean into +12.8 and gives v4 a −12.4 (its sun is behind the left shoulder,
        // so its lean runs the other way, which is the point). It stops short of the plates' +43
        // deliberately: those are 60°-lens paintings whose horizon is the brightest thing in frame,
        // and this frame has a lit cloud sea under the horizon doing that job instead.
        //
        // ROUND 7 TREBLES THE RISE AND RESHAPES THE TILT, and the second half is the one that
        // mattered. Round 5's lean is LINEAR in (1 − bearing): a tilt steep enough to pull a real
        // blue down at 130° off the sun has already spent most of itself at 60°, and 60-70° off is
        // where v1, v3 and v4 all look — so round 6's sky was cool everywhere the camera actually
        // pointed and gold only in a lobe nobody sees. SkyGradient.hlsl now raises (1 − bearing) to
        // TARROCK_BEARING_TILT_POWER, which spends the steepening past 90° and hands the mid angles
        // back to the horizon gold; TARROCK_BEARING_FALL slows the wash's death with height at the
        // same time. Modelled through the full graded chain at elevation 6°, R−B by angle off the
        // sun (round 6 → round 7):
        //       0°  +65 → +79      55°  +36 → +54      110°   +7 → −34
        //      30°  +64 → +71      70°   +7 → +36      130°   −6 → −56
        // ...and the anti-sun end holds its blue at −75 with HSL saturation 0.33 against round 6's
        // −14 at 0.07, which is the board's −45..−47 / 0.28-0.45 passed rather than missed.
        // ROUND 10 TIGHTENS THE BEARING COSINE, 1.3 → 3.0, and it is the single strongest lever
        // this file has on the two board-validated gates the round-9 capture failed. It is chosen
        // over lowering SkyBearingRise (which would cool the sun side too) precisely BECAUSE it is
        // surgical: `bearing` is pow(saturate(dot·0.5 + 0.5), this), so raising the exponent leaves
        // the dawn's own quarter of the compass almost exactly where round 7 put it and spends the
        // whole change on the angles away from it.
        //     angle off the sun    0°     19°     55°     64°    109°    130°
        //     bearing, power 1.3   1.000  0.965   0.727   0.647   0.245   0.129
        //     bearing, power 3.0   1.000  0.921   0.481   0.372   0.038   0.011
        // and everything downstream reads it: the elevation ramps' `lean` steepens off-sun (so the
        // cool mid and the zenith come DOWN that side of the sky), `anti` cools the horizon band
        // off-sun, and the additive dawn wash — the term that was holding the anti-sun sky at
        // R−B −40 instead of −120 — falls away with it.
        // Modelled on the round-9 capture with the sky model's own delta (scratchpad
        // round10/builderS/predict.py; the control reproduces round 9's gate numbers exactly), this
        // change together with the mid band above and the vault work:
        //     view   bright-sky-mass 53.4→35.2 (v3)  28.7→19.5 (v4)  29.5→13.6 (v8)
        //     bluest bare sky R−B    −39.7→−97.9     −63.9→−112.0    −65.8→−110.8
        // ...and critic 5's own halo estimator on the v8 hero, which is the series this round was
        // set to reverse: round 6 −0.019, round 7 −0.038, round 8 +0.018, round 9 +0.016,
        // round 10 −0.043, against a blue-sky board band of −0.008 (totoro) to −0.048 (fable-08).
        // WHAT IT COSTS, stated: v1 and v2 are the frames closest to the sun's bearing and they are
        // the least affected, but v1's sky does lose ~0.10 of luminance. See §the round-10 note in
        // the gauntlet report — this is the one interaction with the grade builder's white-point
        // pass, and it is a real one.
        private const float SkyBearingRise = 1.15f;
        private const float SkyBearingPower = 3.0f;
        private const float SkyBearingTilt = 5.2f;
        private const float SkyBandCount = 7f;         // the painted-plate terrace, not a smooth ramp
        private const float SkyBandStrength = 0.30f;
        private const float SkyBandSoftness = 0.22f;
        private const float SkyDither = 0.0035f;

        // -------------------------------------------------------------------------------------
        // THE FAR CLOUD BANK (round 2, 2026-07-31, against round1/v3+v4). The critic's two
        // structural findings about the horizon were: the deck's top edge is a pixel-straight
        // dead-level line across all 1920 px with a 2-step luminance delta to the sky, and there
        // is no dark value anchor there, so the brightest zone in the frame sits directly on the
        // second-brightest and the world reads as continuing forever rather than ENDING.
        //
        // The bank answers both, and it is painted into the sky rather than modelled, because
        // geometry cannot answer it: the deck is a plane BELOW the camera, so its silhouette is a
        // straight line at eye level no matter how hard the mesh billows (measured — a 7 m swell
        // at 400 m lifts the surface 1°, and the surface is still below the horizon). A cloud sea
        // gets its skyline from cloud standing up beyond it, which in a storybook frame is a
        // painted shape. Wolfwalkers and fable-03 both do exactly this.
        //
        // All heights are sin(elevation) — radians to three places at these angles. The gameplay
        // lens (55° vertical over 1080 px) puts 19.6 px on a degree, so:
        //   crest mean +0.020  → 1.15° above the horizon, ~22 px
        //   relief     ±0.032  → ±1.83°, a crest line that wanders through ~72 px
        //   floor      -0.010  → the bank is gone by 0.6° under the horizon, which from any
        //                        vantage in the region is past 4 km — i.e. entirely inside the
        //                        country the deck shader has already resolved to pure sky, so the
        //                        painted bank and the deck geometry can never contradict.
        private static readonly Color CloudBankCrestLinear = new Color(1.02f, 0.97f, 0.87f);
        // The value anchor: luminance ≈ 0.53 linear against the horizon gold's 0.83 and the
        // haze/deck's 0.85. Dark enough to anchor the horizon, light enough that it still reads as
        // cloud rather than as a mountain range — that line was found by offline-rendering the v3
        // vantage and walking the value down until the anchor appeared without the bank turning
        // into rock.
        private static readonly Color CloudBankShadeLinear = new Color(0.50f, 0.53f, 0.65f);
        private const float CloudBankHeight = 0.020f;
        // ±0.045 sin(elevation) = ±2.6°, and the gameplay lens puts 19.6 px on a degree: the crest
        // line rises and falls through roughly 100 px. (Verified against an offline port of the
        // shader — the measured crest wanders 0.4°..3.7° above the horizon.)
        private const float CloudBankRelief = 0.045f;
        private const float CloudBankLumpScale = 5f;   // ≈ a cloud head every 11° of compass
        private const float CloudBankRimWidth = 0.0060f;
        private const float CloudBankBodyDepth = 0.024f;
        private const float CloudBankDissolve = 0.034f;
        private const float CloudBankFloor = -0.012f;
        private const float CloudBankFade = 0.042f;
        // The gaps. Without them the bank is a belt round the horizon; with them there are open
        // stretches where the eye sees clear sky sitting straight on the cloud sea. This window is
        // narrow because the presence noise it gates on only spans ≈0.29–0.72 in practice; the
        // round-1-style window of 0.24–0.56 measured out as "never fully closes".
        private const float CloudBankGapStart = 0.36f;
        private const float CloudBankGapEnd = 0.46f;

        // -------------------------------------------------------------------------------------
        // THE VAULT CLOUDS. Designed masses, because round1 had "not one cloud shape" in the whole
        // sky vault. Each is (bearing°, elevation°, half width°, opacity); the shader draws them
        // from one fixed six-lobe cumulus alphabet on a flat base, so they are recognisably one
        // hand's drawing rather than a noise field.
        //
        // Placed RELATIVE TO THE SUN, not in absolute bearings. The composition is a composition
        // about the dawn — the hero mass just off the sun's shoulder, its companion on the far
        // side, a thin high veil well away from it — so if SunEuler ever moves the whole cloud
        // arrangement must move with it. Authoring the offsets and deriving the bearings is the
        // same discipline as the streak axis and the blaze vector: nothing needs hand-syncing.
        //
        // ROUND 3 (against round2/v3, v4). The critic's read was "one blurred lozenge instead of
        // designed clouds", and "nothing in the upper 60% of frame is darker than mid-value, so
        // the dawn light has no dark anchor". The shape half is fixed in SkyGradient.hlsl (round 2
        // divided elevation by halfWidth·0.40, which squashed every lobe of the alphabet into a
        // flat ellipse — see that file). The three answers that live HERE are:
        //
        //   * FIVE masses, not four, and sized so the two review frames each hold two of them.
        //     Round 2's four were placed well but left v3 with a single mass in shot and v4 with a
        //     single mass in shot, and a sky with one cloud in it is a sky with a smudge in it.
        //   * A HERO twice the old size (half width 20° against 13°), because the alphabet's
        //     scallops and its three washes are only legible above a few hundred pixels of screen.
        //   * A GENUINELY DARK BELLY. VaultCloudShadowLinear's luminance is 0.230 linear ≈ 0.51
        //     sRGB, against the horizon gold's 0.83 and the far bank's 0.53 — the darkest value the
        //     sky owns, and the only one under mid. The shader weights it by each mass's own half
        //     width (thickness reads as darkness), so the hero anchors the frame and the 8° wisps
        //     stay light without anything being hand-flagged.
        // -------------------------------------------------------------------------------------
        // ROUND 7 takes the last of the gold out of the crown and gives it to the LIGHT instead
        // (SkyGradient.hlsl §THE DISC, ON THE LIT WASHES ONLY). White stays in the light — the
        // board's law and round 6's one real win — so the painted crown is near-neutral and the
        // warmth arrives as a term the sun's bearing controls, which is also why it can no longer
        // be inverted by a grade.
        // -------------------------------------------------------------------------------------
        // THE VAULT CLOUD COLOURS — RE-SOLVED IN ROUND 10, and the three of them move together
        // because they are one finding. Two independent judges (critic 2, and a cross-model blind
        // judge given the round-9 plate cold) said the masses read as muddy translucent volumes
        // with blue contamination; the gate that states it as arithmetic is the fourth one:
        //
        //     board            cloud luminance 0.877   against a sky of 0.715
        //     round 9, v3      cloud luminance 0.545   against a sky of 0.660     INVERTED
        //
        // No daylight cumulus is darker than the sky behind it, and ours were — by 0.115 where the
        // board is ahead by 0.162. That is the single most alien thing about them, and it is not a
        // grade problem: it is these three triples plus two terms in SkyGradient.hlsl that were
        // spending a cumulus's whole value range below the sky's.
        //
        // WHY THE ROUND-8 TRIPLES ARE THE WAY THEY ARE, so this is a correction and not an erasure.
        // Round 8 added TARROCK_CLOUD_SKYFILL — the dome's light on the shaded washes — at 1.20 ×
        // sky.mid, i.e. +(0.160, 0.268, 0.627) linear. Against a shadow authored at (0.011, 0.024,
        // 0.165) linear that is not a fill, it is a REPLACEMENT: the deepest wash arrived at
        // (0.171, 0.292, 0.792), a bright royal blue. The painted triples were then pulled down and
        // blued to sit under it, which is why the shade and shadow below read as slate. With the
        // fill cut to 0.30 and gated to the mass's interior (SkyGradient.hlsl, this round), the
        // paint has to carry the cool half of the law again — so it is authored as a painter would:
        // a LIGHT cool grey for the body and a deeper cool grey-blue for the underside, both well
        // above the sky's own value.
        //
        // TARGETS, from the board through the round-9 gate estimator (margin.py route B):
        //     fable-06   cloud lit L 255.0  shadow L 198.0  shadow R−B −64.5
        //     totoro     cloud lit L 210.3  shadow L 147.6  shadow R−B −78.2
        //     round 9 v3 cloud lit L 180.2  shadow L 111.8  shadow R−B −20.2
        // The shadow keeps MORE hue than the board's lit end and less than its bluest sky, which is
        // what makes the MARGIN gate (cloud shadow warmer than the bluest bare sky) passable at the
        // same time as a genuinely blue sky: the two ends move apart instead of together.
        //
        // AND THE DARK ANCHOR IS NOT ABANDONED. Round 3's note above asks for one and it is right to;
        // it simply must not be the whole cloud. The shadow triple is still the bottom third of the
        // ramp and the belly still deepens the big masses' bases (TARROCK_CLOUD_BELLY), so the hero
        // still carries the darkest value in the vault — it is now the darkest value of a bright
        // object rather than a dark object in a bright sky.
        private static readonly Color VaultCloudLitLinear = new Color(1.03f, 0.99f, 0.90f);
        // The middle wash. Down from round 2's (0.62,0.66,0.78): at that value the "shaded" side of
        // a mass was lighter than the low sky band it was drawn over, so the masses had no dark
        // side at all — they were a bright shape on a bright ground with a slightly brighter shape
        // inside them.
        //
        // ROUND 6 pulls it to (0.48, 0.56, 0.74) — cooler and a touch darker. It is a small move and
        // it is the SECOND half of the cloud-shadow fix; the first half is in SkyGradient.hlsl
        // §THE WASH IS AIR, which stopped the additive dawn wash from being laid over the masses.
        // With that wash gone the shaded washes are finally free to be the colour they are painted,
        // so this is where the blue-slate the round-5 critique asked for actually gets authored.
        // ROUND 7 pulls the violet out of it, (0.48, 0.56, 0.74) → (0.505, 0.560, 0.685). Round 6
        // authored the body as a genuinely BLUE paint and then removed the only warm term acting on
        // it, and the two together are the hue-260 cold flip the round-6 critics found on v1 (mass
        // hue 253°, 73.2% of its pixels in the blue band — a slate roof, not cloud at dawn). The
        // body is a cool GREY now; the blue that carries the storybook law lives one wash below it,
        // in the shadow core, where the board puts it.
        // ROUND 8, (0.505, 0.560, 0.685) → (0.440, 0.525, 0.760). Round 7 pulled the violet out of
        // the body because the masses had NO warm light on them and a blue paint was the only thing
        // making them read cold; with the disc term at 0.70 and a sky-fill term that is explicitly
        // the dome (SkyGradient.hlsl §TARROCK_CLOUD_SKYFILL), the body is free to be the cool paint
        // it should have been all along — the LIGHT now decides which flank is warm, so a blue body
        // can no longer flip a mass cold the way round 6's did.
        // ROUND 10, (0.440, 0.525, 0.760) → see §THE VAULT CLOUD COLOURS above. The body of a
        // storybook cumulus is a LIGHT cool grey — the shaded side of a white object under a blue
        // dome — not a mid slate. Round 8's value is what a body has to be when a term four times
        // its size is about to be added on top of it; with that term cut to a fill, this is the
        // paint again.
        private static readonly Color VaultCloudShadeLinear = new Color(0.660f, 0.710f, 0.840f);
        // THE ANCHOR. Cool, not neutral: at dawn a cloud's underside is lit by sky, and the whole
        // region's grade is warm light on cool shadow (BuildLighting). Grey here would read as
        // dirt on the plate.
        //
        // ROUND 6, (0.19, 0.23, 0.35) → (0.16, 0.225, 0.425). BLUE-SLATE AT SOURCE, which is the
        // reference solution the round-5 critique named: animation-04's cloud bank swings from
        // R−B −59 in its shadow tiers to +8 in its lit quintile, a 67-point hue journey with the
        // LIGHT nearly neutral and the SHADOW carrying all the chroma — the storybook law (white in
        // the light, colour in the shadows) drawn exactly. Round 5's authored colour was already
        // cool; what it lacked was a render that let it stay cool (see the wash note above).
        // Solved against the two targets rather than dialled, through an offline port of this
        // shader plus the full URP grade chain, and CHECKED UNDER BOTH GRADES because the grade
        // moved under this pass (v3 hero, darkest quintile R−B / hue slope d(R−B)/dL):
        //     round 5 as shipped        +49.7   +0.128
        //     round 6, round-6 grade    −22.7   +0.538
        //     round 6, round-5 grade    −19.0   +0.714
        // Not pushed to the plate's −59: this is a dawn cumulus 44° off a 12° sun, and past about
        // −40 the shaded flank stops reading as cloud and starts reading as a bruise (rendered and
        // looked at, not assumed).
        // ROUND 7, (0.16, 0.225, 0.425) → (0.145, 0.205, 0.415): a little deeper, and it has to
        // be, because the dawn wash above it trebled. Measured over each mass's own coverage through
        // the full grade, darkest-quintile R−B (round 6 → round 7): v3 hero −24.1 → −8.8, v4 anchor
        // −41.4 → −48.0, v1 mass −28.6 → −13.3. The one mass that stays warm is the low 14° veil at
        // bearing 36° (+28.9 → +17.7), which hangs INSIDE the horizon gold band at 4.5° of elevation
        // and is 12% transparent; its crown-to-shadow spread still opens from 5.0 to 19.6 points,
        // i.e. the law holds on it even where the absolute sign cannot.
        // ROUND 8, (0.145, 0.205, 0.415) → (0.105, 0.170, 0.440). Deeper, because the shadow core is
        // no longer being asked to BE the shade — it is the cloud's own albedo under sky light now,
        // and the sky-fill term supplies the value. Measured over each mass's own coverage through
        // the graded chain, the dark-to-lit R−B swing (round 7 → round 8):
        //     v3 hero 23.9 → 55.7      v4 anchor 25.4 → 100.1      v8 hero 8.7 → 76.7
        // against the board's animation-04 at 91.6 by the same estimator.
        // ROUND 10, (0.105, 0.170, 0.440) → see §THE VAULT CLOUD COLOURS above. Same correction,
        // one wash deeper: the underside of a cumulus at this hour is sky-lit, so it is cool and it
        // is DIM, but the board's own shadow ends sit at sRGB luminance 148 (totoro) and 198
        // (fable-06) — nowhere near a value that grades to 0.51. It keeps its hue lead (R−B −0.26
        // authored, against the shade's −0.18) so the mass still swings cool-to-warm from base to
        // crown, which is the law round 8 was right about even where its magnitudes were not.
        private static readonly Color VaultCloudShadowLinear = new Color(0.400f, 0.470f, 0.660f);
        private const float VaultCloudBase = 0.22f;      // flat base, in half widths below centre
        // Crisper than round 2's 0.055. On the hero that is 0.030 × 20° = 0.6° ≈ 11 px of edge
        // ramp, which is a painted edge; 0.055 was 0.7° on a 13° mass and, combined with the
        // squash, is most of why the capture reads as a smudge rather than a shape.
        private const float VaultCloudSoftness = 0.030f;
        private const float VaultCloudLump = 0.090f;
        // ROUND 4. How far the mass's flat base is allowed to wander, in half widths. A ruler for a
        // base was half of the critic's "flat-bottomed" reading of v4 and it was literal — every
        // mass in the region cut its base at the same fraction of its own half width, so a row of
        // them drew one horizontal line across the sky. 0.075 on the 21° anchor is 1.6° of wander,
        // 31 px at the gameplay lens: a drawn edge, and still recognisably a condensation level.
        private const float VaultCloudBaseLump = 0.075f;
        // How far the shading wash tilts UP off the sun vector, in the mass's own flat frame. This
        // answers "shaded on a horizontal axis that contradicts the sun" — see the long note in
        // SkyGradient.hlsl §TarrockVaultCloud for why the sun vector goes horizontal for any mass
        // more than a few degrees round the compass from the disc, and why a cloud's crowns are
        // bright anyway. 0.58 against a unit sun vector puts the wash 30° above the frame's
        // horizontal, which leaves the disc deciding which FLANK is gold and the dome deciding
        // which end is up.
        private const float VaultCloudLift = 0.58f;

        /// <summary>One vault cloud, placed by how far round from the sun it sits.</summary>
        private static Vector4 VaultCloud(
            float bearingFromSun, float elevation, float halfWidth, float opacity)
        {
            return new Vector4(
                Mathf.Repeat(SunBearingDegrees + bearingFromSun, 360f), elevation, halfWidth, opacity);
        }

        /// <summary>Writes the one dawn-sky description onto a material that evaluates
        /// <c>SkyGradient.hlsl</c>. Both the skybox and the cloud deck do: the deck's far field
        /// resolves to exactly the sky colour along the same ray, which is the whole reason the
        /// camera's far-clip cut through the 3 km deck reveals no horizon seam. That trick only
        /// survives while the two materials carry identical numbers — hence one writer.</summary>
        private static void ApplySkyDescription(Material target)
        {
            Vector3 sun = SunToward;
            target.SetColor("_HorizonColor", SkyHorizonLinear);
            target.SetColor("_MidColor", SkyMidLinear);
            target.SetColor("_ZenithColor", SkyZenithLinear);
            target.SetColor("_HazeColor", FarFieldLinear);
            target.SetColor("_SunGlowColor", SunGlowLinear);
            target.SetVector("_SunDirection", new Vector4(sun.x, sun.y, sun.z, 0f));
            target.SetFloat("_MidHeight", SkyMidHeight);
            target.SetFloat("_HazeDepth", SkyHazeDepth);
            target.SetFloat("_GlowFalloff", SkyGlowFalloff);
            target.SetFloat("_GlowBroad", SkyGlowBroad);
            target.SetFloat("_GlowBroadPower", SkyGlowBroadPower);
            target.SetFloat("_GlowCore", SkyGlowCore);
            target.SetFloat("_GlowCorePower", SkyGlowCorePower);
            target.SetFloat("_BandCount", SkyBandCount);
            target.SetFloat("_BandStrength", SkyBandStrength);
            target.SetFloat("_BandSoftness", SkyBandSoftness);
            target.SetFloat("_HorizonHeight", 0f);
            target.SetFloat("_BearingRise", SkyBearingRise);
            target.SetFloat("_BearingPower", SkyBearingPower);
            target.SetFloat("_BearingTilt", SkyBearingTilt);

            target.SetColor("_BankCrestColor", CloudBankCrestLinear);
            target.SetColor("_BankShadeColor", CloudBankShadeLinear);
            target.SetFloat("_BankHeight", CloudBankHeight);
            target.SetFloat("_BankRelief", CloudBankRelief);
            target.SetFloat("_BankLumpScale", CloudBankLumpScale);
            target.SetFloat("_BankRimWidth", CloudBankRimWidth);
            target.SetFloat("_BankBodyDepth", CloudBankBodyDepth);
            target.SetFloat("_BankDissolve", CloudBankDissolve);
            target.SetFloat("_BankFloor", CloudBankFloor);
            target.SetFloat("_BankFade", CloudBankFade);
            target.SetFloat("_BankGapStart", CloudBankGapStart);
            target.SetFloat("_BankGapEnd", CloudBankGapEnd);

            // The five masses. Every one of these was projected into the review frustums before it
            // was written down — the sun sits at bearing 332°, v3 looks at 268° and v4 at 63°, and
            // the gameplay lens is 55° vertical / 85.6° horizontal, i.e. 22.4 px per degree
            // horizontally and 19.6 vertically at 1920×1080. Screen figures below are for the
            // frame each mass is FOR.
            //
            //  0 — THE HERO, 44° left of the sun (bearing 288°) and 12° up, half width 20°. v3's
            //      upper right: centre u ≈ +0.47, base at ≈293 px, top out of frame. The largest
            //      mass, so the shader gives it the full dark belly — that base IS v3's missing
            //      value anchor, floating over the gold band with the far bank below it.
            //  1 — its small companion 26° the other side of the sun (358°), low and stopping well
            //      short of the disc so the blaze core still reads. Serves v2, which looks at 348°.
            //  2 — a wide thin veil high and 98° off the sun (234°), at a quarter opacity: it
            //      breaks the empty vault above without competing with the hero. Enters v3's
            //      top-left corner, which round 2 left as bare gradient.
            //  3 — the anti-sun mass (bearing 77°), for the frames that look back east across the
            //      island. v4's upper right: centre u ≈ +0.27, spanning x 855-1660 with its base on
            //      row ≈208 — 108 px above that frame's horizon (row 316), so the belly sits IN the
            //      gold band rather than over it. Half width 18°, which is what buys it a belly at
            //      all: this is v4's anchor and the thickness weight is not generous below 15°.
            //  4 — a mid-size mass at bearing 36°, filling v4's left sky (centre u ≈ −0.53) with an
            //      8° gap of clear sky between it and mass 3. An unbroken belt is weather nobody
            //      believes; the gap is the composition.
            //
            // ROUND 4 RE-PITCHES THE TWO v4 MASSES, and leaves v3's alone because v3's read. The
            // critique of v4 was "one edge-to-edge bank of same-size same-altitude flat-bottomed
            // lobes". Three of those four words are answered in SkyGradient.hlsl (two alphabets, a
            // base that wanders, a wash that tilts up off the sun vector); the sizes and altitudes
            // are answered here, and they were fair comment — 3 and 4 sat 3.0° apart at half widths
            // of 18° and 13°, which at v4's lens is 59 px of separation between two masses of nearly
            // the same span. They are now 8.5° apart (167 px) at 21° and 11° — a tall wide anchor
            // high in the frame and a small low one sitting almost on the far bank, which is what a
            // dawn sky over a cloud sea actually looks like and what animation-02 draws.
            //     Mass 3 also gains its belly outright: the thickness weight in the shader is
            // saturate((halfWidth − 8)/12), so 18° took 83% of the dark anchor and 21° takes all of
            // it. v4's frame has had no value under mid-grey in the whole upper half for four
            // rounds; this is where it comes from.
            target.SetVector("_VaultCloud0", VaultCloud(-44f, 12.0f, 20.0f, 0.94f));
            target.SetVector("_VaultCloud1", VaultCloud(26f, 7.5f, 11.0f, 0.82f));
            // ROUND 8 — MASS 2 STOPS BEING A VEIL, AND THIS IS THE GHOST CARD.
            //
            // THE FINDING (round-7 critique, findings 1 and 2): v8's hero cloud is a translucent
            // smudge that measures DARKER than the sky it sits in (value step +0.036 → −0.014),
            // the ridge is visible through it, and a dark offset duplicate is stacked behind it.
            //
            // ALL FOUR ARE THE SAME OBJECT, and it is this line. v8 looks at bearing 242.5° with a
            // 50° lens, so its frame spans 203-282° — and mass 2 sat dead in the middle of it at
            // 234°, 26° of half width (a silhouette 1316 px wide) and 24% OPACITY. It was authored
            // in round 3 as "a wide thin veil high and 98° off the sun … it breaks the empty vault
            // above without competing with the hero", i.e. as scenery for v3's top-left corner.
            // Nobody checked what it became in the frame it dominates.
            //
            // THE GHOST IS THE SHADING CONSTRUCTION MADE VISIBLE. SkyGradient.hlsl shades a mass by
            // re-evaluating the SAME six-lobe alphabet twice more, stepped toward the sun by 0.30
            // and 0.62 half widths (§THREE WASHES, WITH A TERMINATOR PER LOBE). On an opaque mass
            // those steps draw a terminator; on a 24%-transparent one they draw three concentric
            // copies of one outline over the sky — a bright card, a mid card and, offset down-left
            // of both, the base silhouette painted in the shadow core. At 26° of half width the
            // 0.62 step is 16° of sky, 390 px: the "dark offset duplicate", full size, with the
            // ridge showing through it because the mass is three-quarters sky.
            //
            // KILLED BY MAKING IT A CLOUD. 19° and 93% opaque, raised 3° so it still fills the
            // texture band the critics measure: the outer outline becomes a cloud EDGE instead of
            // the boundary of a transparency, the inner one becomes a terminator, and the three
            // cards become one modelled mass. It also earns the full thickness-weighted belly for
            // the first time (the weight is saturate((halfWidth − 6)/8) × saturate(opacity × 1.15)),
            // which is where v8's missing value anchor comes from. Modelled through the graded
            // chain on v8: cloud-vs-sky value step −0.014 → +0.003, interior saturation 0.043 →
            // 0.203, dark-quintile R−B −0.2 → −38.6, internal luminance range 13.1 → 80.5.
            // v3's top-left corner keeps a mass in it (the silhouette still spans 210-258°).
            target.SetVector("_VaultCloud2", VaultCloud(-98f, 29.0f, 19.0f, 0.93f));
            target.SetVector("_VaultCloud3", VaultCloud(105f, 13.5f, 21.0f, 0.88f));
            // ROUND 7 THICKENS 1 AND 4. Both were thin enough to be half sky (opacity 0.70 and
            // 0.62) and narrow enough to earn almost none of the shader's thickness-weighted belly,
            // so with round 7's much warmer sky behind them they photographed as warm veils rather
            // than as masses — mass 4's darkest quintile measured +28.9 R−B in round 6, warmer than
            // its own crown, which is the round-6 critique's fifth finding in one number. At 14°
            // and 0.88 mass 4 takes the full belly (the weight is saturate((halfWidth − 6)/8)) and
            // only 12% of the sky behind it reaches the eye.
            // ROUND 8 LIFTS 4 OUT OF THE GOLD BAND. It is the mass v4's review rect actually holds
            // (that rect spans bearings 25-51° and mass 4 sits at 36°, while mass 3 at 77° is the
            // top-right one), and at 4.5° of elevation it hung INSIDE the horizon gold — so 12% of
            // a very warm sky came through it, the sky wrapped its silhouette on every side, and
            // its dark quintile measured +16.7 R−B against a gate of ≤ 0. Two degrees of elevation
            // is the whole difference: modelled, the dark quintile runs +3.1 at 4.5°, −29.0 at
            // 5.5° and −41.4 at 6.5°, because that is where the mass clears the band. 6.5° is two
            // degrees past the cliff rather than on it, and the extra half degree of width and the
            // 0.96 opacity buy the margin rather than the metric.
            target.SetVector("_VaultCloud4", VaultCloud(64f, 6.5f, 15.5f, 0.96f));
            target.SetColor("_VaultCloudLit", VaultCloudLitLinear);
            target.SetColor("_VaultCloudShade", VaultCloudShadeLinear);
            target.SetColor("_VaultCloudShadow", VaultCloudShadowLinear);
            target.SetFloat("_VaultCloudBase", VaultCloudBase);
            target.SetFloat("_VaultCloudBaseLump", VaultCloudBaseLump);
            target.SetFloat("_VaultCloudSoftness", VaultCloudSoftness);
            target.SetFloat("_VaultCloudLump", VaultCloudLump);
            target.SetFloat("_VaultCloudLift", VaultCloudLift);
        }

        // -- The cloud deck's surface. 3 km square at y=11.
        //
        //    ROUND 4 GRADES THE GRID AND RAISES IT. A uniform 128² over 3 km is 23.4 m per cell
        //    everywhere, and 23 m cells cannot carry relief the eye reads at 60-250 m — which is
        //    exactly the band the critic called "an airbrushed sheet with no top-surface relief
        //    crossing the mid-field". Two changes, and MEASURED rather than assumed:
        //      * the cell SIZE is graded. The vertex parameter runs -1..1 and the axis map is
        //        x = sign(u)·|u|^CloudDeckGridBias·halfSize, so spacing is
        //        bias·halfSize·|u|^(bias−1) · du. At bias 1.8 that is 6 m at 50 m from centre,
        //        10 m at 150 m, 14 m at 300 m and 28 m at the 1.5 km rim.
        //      * the grid goes 128 → 192. Grading alone buys a factor of two in the band that
        //        matters and no more (the useful budget is 64 cells per half axis however it is
        //        distributed), and 193² = 37 249 verts is still comfortably inside 16-bit indices
        //        for one static mesh. A 90 m swell is now nine vertices across at 150 m instead of
        //        four, which is the difference between a curve and a chevron.
        private const float CloudDeckHalfSize = 1500f;
        private const int CloudDeckGrid = 192;
        private const float CloudDeckGridBias = 1.8f;
        private const float CloudDeckLevel = 11.0f;
        private const float CloudBillowAmplitude = 7.0f;
        // The billow ramps in from OUTSIDE THE FOOTPRINT, not from a radius about the centre, and
        // that swap is most of what buys the mid-field its relief. The old rule held the deck dead
        // flat inside a 200 m circle so no swell could push cloud up through a walkable floor — but
        // the walkable floor is the 256 m SQUARE, and a circle that contains it swallows 20 m of
        // open sea off the west rim as well. v3's camera stands at x 25 and looks west: under the
        // old rule the whole first 175 m of its deck was inside the flat circle and could only ever
        // be shaded, never shaped. Measuring from the square instead keeps the guarantee exactly
        // (the deck is flat over every metre of terrain) and starts the swell where the island
        // stops.
        //
        // AND THE NEAR SWELL ONLY EVER FALLS. The lowest walkable floor is the west mouth at ~17 m
        // and the deck sits at 11, so a +7 m crest 30 m off the rim would be level with ground the
        // player walks on. Inside CloudBillowNearDamp the positive half of the swell is scaled to a
        // quarter, so the near sea can trough away from the island's foot but cannot rise to meet
        // it — which is also the truer picture: cloud falls away from a cliff, it does not lap it.
        private const float CloudBillowFlatMargin = 12f;
        private const float CloudBillowRampMargin = 220f;
        private const float CloudBillowNearDamp = 0.25f;
        // AND THE AMPLITUDE IS FINALLY WORTH WHAT IT SAYS. Three octaves of zero-mean gradient
        // noise summed at 0.54/0.30/0.16 have a standard deviation of 0.128 and never leave ±0.48,
        // so multiplying by a 7 m amplitude produced a deck whose typical relief was 0.9 m and whose
        // extremes were 3.4 — round 3's comment claimed "±7 m" and the mesh delivered less than
        // half of it. The sum is soft-saturated (x·rsqrt(1+x²), the same curve the far cloud bank
        // uses, and for the same reason: a hard clamp gives the tall swells dead flat tops and they
        // read as mesas) with a gain of 2.6, which maps the field onto ±0.78 at a standard deviation
        // of 0.307. MEASURED over the finished mesh: the deck is exactly 0.00000 m over every metre
        // of the footprint, runs ±1.7 m through the first 120 m of open sea, ±4.3 m from 120-300 m
        // and ±4.9 m beyond, with an overall standard deviation of 1.96 m against round 3's 0.9.
        // The deepest trough anywhere is −5.46 m, which still clears the shallowest lobe hang
        // (11.07 m at round 12's floors — see CloudLobeSinkMin) by 5.61 m, so no head can be caught
        // floating. Round 4's floor left 3.1 m here; raising the sinks only ever widens this.
        //     What that relief is worth on screen: from v3 the eye stands 6.3 m over the deck, so a
        // 1.5 m crest at 80 m lifts the surface from −4.50° to −3.43° — 21 px of the gameplay lens —
        // and a 4 m crest at 200 m lifts it from −1.80° to −0.66°, 22 px. The near sea gets a
        // readable, occluding undulation the whole way out, which is what "crossing the mid-field"
        // asks for and what no amount of shading a plane could supply.
        private const float CloudBillowGain = 2.6f;

        // The sea of cloud (world.md §The Cliff — island in cloud, director-blessed 2026-07-26).
        // A vast deck below every lip: the horizon is cloud-top, the drop is "lost in haze", the
        // knife-cut tile boundary is hidden below the deck, and the leap has something to fall INTO.
        // Motionless while bound, per canon. PROTO NOTE: the render surface carries NO walkable
        // collider — a trigger slab beneath it catches a director who hops an edge, standing in for
        // the real unscripted-fall behaviour (combat.md §Defeat), which wires up with the
        // interaction layer.
        private static void BuildCloudSea()
        {
            Shader cloudShader = Shader.Find("Tarrock/CloudSea");
            if (cloudShader == null)
            {
                Debug.LogWarning("[Tarrock] Tarrock/CloudSea shader not found; skipping the cloud deck.");
                return;
            }

            var material = AssetDatabase.LoadAssetAtPath<Material>(CloudMaterialPath);
            if (material == null)
            {
                material = new Material(cloudShader);
                AssetDatabase.CreateAsset(material, CloudMaterialPath);
            }
            else
            {
                material.shader = cloudShader;
            }

            // Every property explicit (same rule as BuildTerrainMaterial — a reused .mat keeps
            // stale serialized values while shader defaults appear to change).
            //
            // Tops bright and slightly cool of the haze so the near deck reads as luminous cloud;
            // furrows a COOL lavender-grey, not a grey step down from the tops. Warm light, cool
            // shadow is the region's grade everywhere else, and a cloud field is where it shows.
            //
            // ROUND 3: the furrow value comes DOWN, (0.58,0.62,0.74) → (0.47,0.52,0.66). Round 2's
            // two colours were 0.66 and 0.92 in luminance — a quarter of a stop apart, which after
            // the fog and the bloom is the "one value, std 7.5" the critic measured all over again.
            // 0.51 against 0.94 is a real light-to-shadow split, and the shader now has a real
            // light to apply it with (see CloudSea.shader §THE DECK IS LIT).
            //
            // ROUND 4 takes the furrow down once more, (0.47,0.52,0.66) → (0.37,0.42,0.57), and this
            // one is measured through the grade rather than argued in linear. Round 3's pair lands
            // at sRGB luminance 201 and 156 — a 45-point ladder — and the near deck owns a third of
            // v3's frame, so 45 points spread over a smooth low-frequency field is exactly the
            // "airbrushed sheet" reading. The new pair lands at 201 and 139: a 62-point ladder, 38%
            // wider, and the near field keeps 82-98% of it through the fog (the deck inside 100 m is
            // barely hazed at all). It stops there rather than at the 66 points a furrow of
            // (0.34,0.39,0.54) would buy, because the deck is canon-bound to read as a BRIGHT
            // motionless sea (world.md §The Cliff) and its own mean is what carries that — the
            // furrows are a step down from the light, not a second night.
            //
            // ROUND 5 MAKES IT THREE COLOURS, because a terrace on a two-colour ramp is still a
            // two-colour ramp — the deck had a light end and a shade end and no shadow core, which
            // is half of the critic's "airbrushed, 2-5x under the plates' interior contrast". The
            // furrow value stays where round 4 measured it and a BODY wash goes in between, so the
            // ramp reads shadow → body → crest rather than as one long dissolve.
            //
            // A NOTE ON THE COLOUR CONVENTION, because it is load-bearing and easy to get wrong.
            // These constants are named "…Linear" but Material.SetColor on a plain (non-[Gamma],
            // non-[HDR]) Color property treats the value as sRGB and converts it to linear on
            // upload, so what the shader receives is s2l(x), not x. That is not a bug to fix here:
            // every one of these numbers was solved against a capture through that conversion, and
            // RenderSettings.fogColor takes the SAME conversion (round 7 — see FarFieldLinear),
            // so the fog and this deck are one number again. Modelling the
            // chain the other way reproduces neither capture; modelling it this way predicts v3's
            // deck maximum at 217 against a measured 217.7 and v4's far-bank floor at 134.8
            // against a measured 130.1.
            material.SetColor("_CloudBright", new Color(1.00f, 0.95f, 0.84f));
            material.SetColor("_CloudMid", new Color(0.62f, 0.64f, 0.72f));
            material.SetColor("_CloudShade", new Color(0.37f, 0.42f, 0.57f));
            material.SetFloat("_CloudMidPoint", 0.46f);
            // THE MID-FIELD OCTAVE — the whole of the critic's "deck mid-field is a sheet". The
            // derivation is in CloudSea.shader §THE MID-FIELD OCTAVE: at 200 m the 130 m bank spans
            // 673 screen px and the 48 m billow 249, so a 15 px high-pass sees neither, and the two
            // octaves that would (15 m, 5 m) are correctly faded out by 220 m against aliasing.
            // 26 m is the size that fits the gap — 135 px across at 200 m, and still 4.6 px of
            // vertical extent at 300 m, above the shimmer floor the other fades are derived from.
            material.SetFloat("_SwellScale", 26f);
            material.SetFloat("_SwellWeight", 0.40f);
            material.SetFloat("_SwellFadeStart", 260f);
            material.SetFloat("_SwellFadeEnd", 420f);
            // ROUND 2 RESCALE. The 07-31 numbers were authored for a viewer far above the deck.
            // The vantage that actually meets the cloud sea is the western rim (round1/v3): eye
            // 1.6 m over ground at ~15.7 m, deck at 11 — SIX METRES of elevation over it. From
            // there the deck's apparent depth collapses; more than half the frame's deck lies
            // inside 100 m and effectively all of it inside 400 m, so a 300 m bank scale put the
            // whole visible near field inside ONE noise cell and the deck came out as one value
            // (measured std 7.5). Every scale is roughly halved to land features where the eye
            // can resolve them.
            material.SetFloat("_BroadScale", 130f);
            material.SetFloat("_MidScale", 48f);
            material.SetFloat("_FineScale", 15f);
            // A fourth octave, added after the halved scales measured out barely better than
            // round 1 (deck std 3.5 sRGB levels against round 1's 7.5). The western rim puts the
            // player six metres above the cloud with the nearest deck ten metres away, and at that
            // range even a 15 m feature is the whole near field — so the largest part of the frame
            // was STILL one noise cell. Five metres is the scale of the curdling you see when
            // cloud is close enough to touch.
            material.SetFloat("_CurdScale", 5f);
            material.SetFloat("_MottleContrast", 4.5f);
            // The painted washes. Hand-painted brush economy is what art-bible.md asks for and
            // what the reference board shows: a few flat values with soft boundaries, not a
            // continuous ramp. ROUND 3 takes them from five at 42% to four at 58%: with real light
            // in the ramp there is something worth terracing, and 42% of five washes over a
            // near-flat ramp was a rounding error — the boundaries the critic could not find were
            // never drawn.
            // ROUND 4: five washes at 0.66. With a 62-point ladder under it a four-wash terrace puts
            // 15 sRGB points on every boundary, which past the first is a poster; five at 0.66 gives
            // 12-point steps and one more of them, so the near deck reads as four or five flat
            // shapes with visible edges instead of two.
            // ROUND 5: EIGHT washes at 0.90 over 0.030 of softness. Round 4's five at 0.66 over
            // 0.13 could not draw a boundary the measurement could find — a 15-point step spread
            // over 13 screen pixels is |grad| 1.2, and the critic measured the deck's mid-field
            // high-pass std at 1.2-2.4 against the plates' 11-16. Softness is what fixes that and
            // it is arithmetic, not taste: the same step over 3 px is |grad| 5, and with the third
            // colour widening the ladder it clears 8 on the strong boundaries. Eight washes rather
            // than five because the ramp now spans further and 15-point posters are what five would
            // give. Modelled over the v3 frustum the pair takes mid-field high-pass 4.41 → 6.86 and
            // interior gradient median 0.67 → 1.76 (model units; the same model reads round 4 at
            // 4.41 where the capture reads 8.14, so it runs ~1.85× low — which puts the shipped
            // configuration at roughly 12.7 in capture units, inside the plates' 11-16).
            material.SetFloat("_MottleBands", 8f);
            material.SetFloat("_MottleBandStrength", 0.90f);
            material.SetFloat("_MottleBandSoftness", 0.030f);
            material.SetFloat("_WarpScale", 95f);
            material.SetFloat("_WarpAmount", 26f);
            // Banks drawn out along the sun/valley axis (the wind that made them is the wind that
            // is currently held). Sign is irrelevant to a stretch axis, so the XZ of SunToward
            // normalised is enough.
            Vector3 sun = SunToward;
            Vector2 streak = new Vector2(sun.x, sun.z).normalized;
            material.SetVector("_StreakAxis", new Vector4(streak.x, streak.y, 0f, 0f));
            // Less stretch than the 07-31 pass: the octaves it stretches are half the size now,
            // and 2.6 on a 130 m bank draws the banks out into streaks rather than banks.
            material.SetFloat("_StreakStretch", 2.2f);
            material.SetColor("_SunFormColor", SunGlowLinear);
            // Gold on the TOP WASH only now (round 2 tinted the whole surface by a signed slope,
            // which is a hue shift and not a light-to-shadow separation), so the strength comes
            // down to match: it is a highlight, not a grade.
            material.SetFloat("_SunFormStrength", 1.1f);
            // ...and the onset moves with the ramp. Round 3 hardcoded 0.72 in the shader while the
            // ramp's 98th percentile sat at 0.74, so the gold fell on the top 2% of the sea. The
            // re-solved round-4 ramp reaches 0.93, and 0.80 keeps the same discipline: the highlight
            // lands on the crests and nowhere else.
            material.SetFloat("_SunFormThreshold", 0.80f);
            // The finite-difference step for the relief normal. ~1/9 of the bank scale: small
            // enough that two taps still straddle one slope rather than two unrelated banks, large
            // enough that the difference is well clear of the noise's own precision floor.
            material.SetFloat("_SlopeStep", 14f);
            // THE VIRTUAL RELIEF. The deck mesh billows ±7 m, but ±7 m at 400 m is a 1° swell —
            // it can shape a silhouette (it does not: the deck's skyline is painted, see the bank)
            // and it can never shade anything. So the surface is shaded as though it carried 26 m
            // of relief over its 130 m banks: a 10-11° flank, which at a low dawn sun is exactly
            // the difference between catching the dawn and not. The mesh's own swell still
            // contributes through _CrestLift, so silhouette and shading do not contradict.
            // ROUND 4 ACTS ON THE NOTE THE BEAM PASS LEFT HERE. The sun came up from 7° to 12°, and
            // 26 m of relief over a 130 m bank is a 7.8° mean flank (95th percentile 15.1°): at 7°
            // that self-shadowed — traced over a 1 km square of the field, the 2nd percentile of
            // N·L was 0.0007 — and at 12° the same field's 2nd percentile is +0.081, so no flank on
            // the deck turns away from the disc at all. The dark end of the deck's range simply
            // stopped existing, and at the other end 4.4% of the surface clipped flat white.
            //     46 m puts it back: mean flank 13.5°, 95th percentile 25.4°, 3.0% of the deck at or
            // below N·L 0. A 25° flank is gentle for the thing this is drawing — cumulus tops are
            // far steeper — and the finite-difference step (14 m) is unchanged, so nothing about the
            // sampling gets noisier; only the amplitude it is asked to shade.
            material.SetFloat("_ReliefHeight", 46f);
            // Solved from that field, not dialled. At 46 m and 12° the N·L band runs −0.061 (1st
            // percentile) to +0.412 (99th), so gain 0.96/(hi−lo) = 2.03 with bias 0.02 − gain·lo =
            // +0.09 maps it onto 0.03-0.93 — the whole ramp used, nothing clipped at either end.
            material.SetFloat("_FormGain", 2.03f);
            material.SetFloat("_FormBias", 0.09f);
            // Light 66 / altitude 34. Pure N·L stripes the deck across the billows (the lit flank
            // of a trough looks like the lit flank of a crest); mixing the height back in keeps the
            // washes reading as one billowing surface. Round 3 weighted it 62/38, but its altitude
            // term was gained so gently (×1.35 on a field of std 0.144) that it only ever spanned
            // 0.19-0.81 — it was quietly narrowing the range the light half had just widened. The
            // gain goes to 2.05, which puts the altitude term on the same 0.03-0.97 as the light.
            material.SetFloat("_ReliefWeight", 0.66f);
            material.SetFloat("_HeightGain", 2.05f);
            material.SetFloat("_DeckLevel", CloudDeckLevel);
            material.SetFloat("_CrestRange", CloudBillowAmplitude);
            material.SetFloat("_CrestLift", 0.14f);
            material.SetVector("_DeckCentre",
                new Vector4(TerrainSize * 0.5f, TerrainSize * 0.5f, 0f, 0f));
            // Octave LOD, re-derived for the halved scales. A feature of length L on a plane seen
            // from height H at distance d subtends about 1123·L·H/d² px on the gameplay lens; at
            // H = 6.3 m the 15 m curd is 10.6 px at 100 m and 1.6 px at 260 m, so it has to be
            // gone by ~220 m or it aliases into shimmer. The 48 m billow reaches the same limit
            // around 550 m.
            material.SetFloat("_CurdFadeStart", 30f);
            material.SetFloat("_CurdFadeEnd", 80f);
            material.SetFloat("_FineFadeStart", 100f);
            material.SetFloat("_FineFadeEnd", 220f);
            material.SetFloat("_MidFadeStart", 250f);
            material.SetFloat("_MidFadeEnd", 560f);
            // ROUND 2: the blend was starting at 170 m, which erased the deck's form across most
            // of the frame before it could be seen. Pushed out to 430 m. The seam argument still
            // holds and is now tighter than before: fully resolved to sky by 820 m, well inside
            // the camera's 1 km far clip, so the clip plane's cut through the 3 km deck still
            // falls in country that is already pure sky.
            material.SetFloat("_SkyBlendStart", 430f);
            material.SetFloat("_SkyBlendEnd", 820f);
            ApplySkyDescription(material);
            EditorUtility.SetDirty(material);

            Mesh deckMesh = BuildCloudDeckMesh();
            AssetDatabase.DeleteAsset(CloudDeckMeshPath);
            AssetDatabase.CreateAsset(deckMesh, CloudDeckMeshPath);

            var deck = new GameObject("CloudSea");
            // A 3 km deck centred on the region. At y=11: high enough to swallow the sheer faces
            // quickly (director note 2026-07-27 — the drop must vanish into cloud, not slide down
            // to it), below the lowest walkable floor (west mouth ≈ 17 m; edges fall to 1.5).
            // 1500 m of half-extent minus the 181 m worst-case offset of a camera on the plateau
            // still leaves 1319 m, so the deck's own rim is ALWAYS beyond the 1 km far clip and can
            // never be seen as an edge — the only cut is the clip plane's, which the shader's sky
            // convergence hides.
            deck.transform.position = new Vector3(TerrainSize * 0.5f, CloudDeckLevel, TerrainSize * 0.5f);
            deck.AddComponent<MeshFilter>().sharedMesh = deckMesh;
            var deckRenderer = deck.AddComponent<MeshRenderer>();
            deckRenderer.sharedMaterial = material;
            deckRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            deckRenderer.receiveShadows = false;
            deck.isStatic = true;

            // Clouds are an ending, not a floor (director note 2026-07-27 — you must not be able
            // to walk on the deck). The render surface carries no walkable collider; a trigger slab
            // just beneath the deck's flat inner field catches fallen bodies and returns them to the
            // spawn — the defeat-loop stand-in (see CloudFallCatch). Same world dimensions as the
            // 07-27 build; only the transform's scale left (the mesh is authored in metres).
            var catchVolume = deck.AddComponent<BoxCollider>();
            catchVolume.isTrigger = true;
            catchVolume.center = new Vector3(0f, -0.4f, 0f);
            catchVolume.size = new Vector3(CloudDeckHalfSize * 2f, 0.6f, CloudDeckHalfSize * 2f);

            var fallCatch = deck.AddComponent<CloudFallCatch>();
            var serialized = new SerializedObject(fallCatch);
            serialized.FindProperty("_respawnPoint").vector3Value =
                new Vector3(SpawnHint.x, SpawnHint.y, SpawnHint.z);
            serialized.ApplyModifiedPropertiesWithoutUndo();

            // ...and the heads standing out of it. After the deck, because they are read as rising
            // FROM it: the deck level and the mesh's flat inner radius are both inputs to where
            // they sit and how deep they sink.
            BuildCloudLobes();
        }

        /// <summary>The deck's surface: a 3 km grid, dead flat across the whole terrain footprint
        /// and gently billowed beyond it. A perfectly flat deck is the single loudest reason the
        /// 07-27 build read as a glossy plate under the region rather than weather — the eye reads
        /// a ruler-straight far field as a floor. Two low octaves of the same gradient noise the
        /// landform uses (value noise folds on every lattice edge — 07-26 audit) give the far field
        /// a slow swell; ±7 m at 400 m is about a degree of arc, which is a large fraction of the
        /// few degrees of deck the gameplay camera ever sees.</summary>
        private static Mesh BuildCloudDeckMesh()
        {
            const int side = CloudDeckGrid + 1;
            var verts = new Vector3[side * side];
            // The shader shades from world position, so these UVs exist only so that marking the
            // deck static never produces a mesh Unity refuses to unwrap.
            var uvs = new Vector2[side * side];
            for (int z = 0; z < side; z++)
            {
                float wz = CloudDeckAxis(z);
                for (int x = 0; x < side; x++)
                {
                    float wx = CloudDeckAxis(x);
                    // Distance OUTSIDE the terrain square (Chebyshev), not radius from the centre —
                    // see the constants block. Negative inside the footprint, so the ramp is zero
                    // over every metre of walkable ground by construction.
                    float outside = Mathf.Max(Mathf.Abs(wx), Mathf.Abs(wz)) - TerrainSize * 0.5f;
                    float ramp = Mathf.SmoothStep(0f, 1f,
                        Mathf.InverseLerp(CloudBillowFlatMargin, CloudBillowRampMargin, outside));
                    // Zero-mean, so the deck's average height stays exactly at the deck level and
                    // the catch slab beneath it keeps meaning what it says. THREE octaves now: the
                    // 90 m one is the mid-field's own scale, and it is the octave the graded grid
                    // above exists to resolve (1.9 m cells at 100 m out, so a 90 m swell is 47
                    // vertices across rather than four).
                    float swell =
                        GradNoise(wx / 430f, wz / 430f) * 0.54f +
                        GradNoise(wx / 155f + 13.7f, wz / 155f + 41.3f) * 0.30f +
                        GradNoise(wx / 90f + 61.9f, wz / 90f + 7.4f) * 0.16f;
                    // Soft-saturated onto ±1 rather than left at the ±0.48 three octaves of
                    // gradient noise actually reach — see CloudBillowGain.
                    float gained = swell * CloudBillowGain;
                    swell = gained / Mathf.Sqrt(1f + gained * gained);
                    // Rises are damped near the island and troughs are not: the sea falls away from
                    // the cliff's foot, it never climbs to meet it (see CloudBillowNearDamp).
                    float lift = swell > 0f
                        ? swell * Mathf.Lerp(CloudBillowNearDamp, 1f, ramp)
                        : swell;
                    verts[z * side + x] = new Vector3(wx, lift * CloudBillowAmplitude * ramp, wz);
                    uvs[z * side + x] = new Vector2(x / (float)CloudDeckGrid, z / (float)CloudDeckGrid);
                }
            }

            var tris = new int[CloudDeckGrid * CloudDeckGrid * 6];
            int t = 0;
            for (int z = 0; z < CloudDeckGrid; z++)
            {
                for (int x = 0; x < CloudDeckGrid; x++)
                {
                    int v0 = z * side + x;
                    int v1 = v0 + 1;
                    int v2 = v0 + side;
                    int v3 = v2 + 1;
                    tris[t++] = v0; tris[t++] = v2; tris[t++] = v1;
                    tris[t++] = v1; tris[t++] = v2; tris[t++] = v3;
                }
            }

            var mesh = new Mesh { name = "CloudSeaDeck" };
            mesh.SetVertices(verts);
            mesh.SetUVs(0, uvs);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            return mesh;
        }

        /// <summary>The deck grid's graded axis: vertex index → world metres from the deck centre.
        /// Dense in the middle, coarse at the rim — see the constants block for why, and for the
        /// measured spacings. The map is odd and monotone, so the grid stays a well-formed quad
        /// mesh and the winding below is unaffected.</summary>
        private static float CloudDeckAxis(int index)
        {
            float u = (index / (float)CloudDeckGrid) * 2f - 1f;   // -1 .. +1
            return Mathf.Sign(u) * Mathf.Pow(Mathf.Abs(u), CloudDeckGridBias) * CloudDeckHalfSize;
        }

        // -------------------------------------------------------------------------------------
        // THE CLOUD LOBES (round 3, 2026-07-31, against gauntlet/round2/v3 and v4)
        //
        // THE FINDING this answers, in the critic's words: the deck's "top edge never OCCLUDES
        // anything so it reads as background wallpaper, not a sea the island sits in", and in v4
        // "the deck floats above the ridges with a cream gap — it reads at infinity".
        //
        // Neither is a shading problem, and two rounds of shading the deck have now proved it. A
        // horizontal plane BELOW the camera has its horizon at eye level and covers nothing that
        // stands on it; the painted far bank (SkyGradient.hlsl) is at infinity by construction and
        // covers nothing either. The only thing that can put cloud in front of a ridge is cloud
        // with depth. So: real geometry, cumulus heads standing 10-24 m proud of the deck plane,
        // close in around the island where the fog has not yet eaten them, writing depth like
        // anything else. Tarrock/CloudLobe shades them — three flat washes off the one sun, gold
        // on the bearing-332 flank, cool blue-grey opposite, a darker belly beneath.
        //
        // WHY THEY SIT WHERE THEY SIT. Every anchor below was PROJECTED into its frame before it
        // was written down — camera, deck level, mass height and the 55°/85.6° gameplay lens, at
        // 1920×1080 — and the rows quoted are the output of that arithmetic, not an impression:
        //
        //   v3 — camera (25, 17.3, 138) at bearing 268°, 6.3 m above the deck. Horizon on row 449;
        //        the painted far bank's crest wanders rows 381-442 (its own 0.4°-3.7° measurement,
        //        see §THE FAR CLOUD BANK). The near row is A, B, C, D — four heads at four sizes
        //        and four ranges, crowns on rows 400, 327, 430 and 392. THREE of them cross that
        //        crest band, which is the whole point: cloud in front of the distant islands is
        //        the only sentence in the frame that says "and this is a sea".
        //   v4 — camera (155, 53.6, 61) at bearing 63°, pitched 12.2° down. Horizon on row 316,
        //        bank crest rows 245-308, and rows ~308-490 were the flat cream gap the critic
        //        named. E, F and G stand at 161-232 m with crowns on rows 424, 458 and 437 and
        //        waterlines on rows 589, 537 and 509 — INSIDE that gap, in front of the far deck
        //        and in front of the mid-distance ridges' feet.
        //
        // WHAT KEEPS THEM HONEST. Nothing is placed inside the terrain footprint (0-256 m in both
        // axes); the scatter's inner radius clears the footprint's farthest corner outright. Every
        // mass hangs at least (sink + 0.355) × radius BELOW the deck, which at round 12's floors is
        // 11.07 m for the smallest head the far scatter can roll (18 m at sink 0.26) and 13.13 m for
        // the smallest swell (26 m at sink 0.15), against a worst-case billow of 7 m — so no head
        // can ever be caught floating with a lit gap under it. Nothing casts a shadow: the sun is 7°
        // up, so a 200 m cloud would throw a 1.6 km bar across the island. Nothing moves: the
        // region is BOUND (art-audio.md §The world-state is the art direction).
        // -------------------------------------------------------------------------------------
        // SEVEN masses now, not four. Round 3's four were drawn by one hand and that was right, but
        // four arrangements over fifty-odd instances is a stamp — the critic's "same-size
        // same-altitude same-silhouette". 4-6 are the round-4 additions: the LOW SWELL (the mass
        // that answers "the deck has no top-surface relief crossing the mid-field"), the SHOULDERED
        // ANVIL (the near hero, asymmetric enough that it cannot read as a dumpling), and the NUB.
        private const int CloudLobeVariants = 7;
        // The low swell (CloudLobeShape case 4). Named because its crown is the shallowest in the
        // shape set (+0.426) and the waterline rules therefore have to single it out — see
        // CloudLobeSwellSinkMin and the per-shape floor in PlaceCloudLobe.
        private const int CloudLobeSwellVariant = 4;
        // 72 × 40 rather than 48 × 26. The silhouette now carries a cauliflower displacement (see
        // BuildCloudLobeMesh §THE SCALLOP), and at round-3's tessellation a 24 m mass 100 m away
        // put 20 screen pixels on each meridian segment — a displaced silhouette at that spacing is
        // a polygon, which is the one thing this pass must not add. 2993 verts per mass, 21k for
        // the whole alphabet, still 16-bit.
        private const int CloudLobeMeridians = 72;
        private const int CloudLobeParallels = 40;
        // The mass's centre sits this fraction of its radius BELOW the deck, so the deck plane cuts
        // it and it reads as cloud RISING OUT of the sea rather than as a ball resting on it.
        // Cutting a little under the widest section (rather than at it, or above it) is what gives
        // a head the slight overhang a cumulus has over its own base.
        //
        // ROUND 4: this is now a RANGE, not the one value every mass used — sink is authored per
        // anchor and rolled per scattered head, because one sink for the whole region is one
        // altitude for the whole region, which is half of what the critic read as "same-size
        // same-altitude". The floor is the safety rule round 3 derived and it
        // still holds. The shallowest-keeled mass is the new swell, which reaches 0.355 of its radius
        // below its own centre, so at sink s a mass hangs (s + 0.355) × radius under the deck, and
        // the deck's billow can drop CloudBillowAmplitude (7 m) beneath the level. At the round-4
        // floor of 0.12 and the far scatter's smallest radius of 18 m that is 8.55 m of hang against
        // a 7 m trough — 1.55 m of margin, so no head can be caught floating with a lit gap under
        // it, from any camera, at any of the sizes the rolls can produce.
        //
        // ROUND 12 RAISES THE FLOOR 0.12 → 0.26, AND THE REASON IS THE WATERLINE, MEASURED. Round
        // 11's critic read the deck as "shallow water with rock islets, not cumulus"; the board
        // model is soft billowed bases SITTING IN the deck. Two numbers say the same thing, and
        // both are functions of sink alone:
        //
        //   CONTACT ANGLE — the angle at which a mass's surface meets the deck plane. The mesh is
        //   normalised into a unit ball, so a mass cut at height s×radius above its own centre
        //   meets the plane at 90° − asin(s). At the round-4 floor that is 83.1°: a sea stack
        //   rising vertically out of water, which is exactly the read the critic named. At 0.26 it
        //   is 74.9°, and the surface is leaning out over its own base the way a cumulus does.
        //
        //   ASPECT — crown height proud of the deck over half-width at the waterline. For a mass of
        //   crown +c (this file's own measured extents; see CloudLobeShape) that is
        //   (c − s) / halfWidth. The shouldered anvil (variant 5, crown +0.670, 1.56 × 0.97) at the
        //   round-4 hero sink of 0.14 gives 0.530 / 0.485 = 1.09 across its narrow axis — TALLER
        //   than it is half-wide, which is a rock. At 0.28 it is 0.80. MEASURED ON THE ROUND-11
        //   PICTURE, the near mass in v3 stands 70 rows proud on an 80-row half-width — aspect
        //   0.875 — and √((1−s)/(1+s)) inverts that to s ≈ 0.14, i.e. the frame and this table
        //   agree to two decimal places (scratchpad round12/builder4/BAND_v3-rim-west.jpg).
        //
        // THE CEILING DID NOT MOVE, and that is a constraint, not an omission. The far scatter can
        // draw variant 4, whose crown is only +0.426 — the shallowest crown in the shape set. At a
        // sink past ~0.40 that shape's crown is UNDER the deck, which is a failure mode this file
        // has no rule for (the safety rule below guards the keel, not the crown). 0.34 keeps every
        // variant proud: at the worst case, variant 4 at the ceiling on the far scatter's smallest
        // radius, the crown still stands (0.426 − 0.34) × 18 = 1.5 m out of the sea.
        //
        // AND THE SAFETY MARGIN ONLY IMPROVES, re-derived at the new floor: (0.26 + 0.355) × 18 =
        // 11.07 m of hang against the same 7 m trough — 4.07 m of margin where round 4 had 1.55 m.
        private const float CloudLobeSinkMin = 0.26f;
        private const float CloudLobeSinkMax = 0.34f;
        // THE SWELL BAND KEEPS ITS OWN FLOOR, and it must. Variant 4 is the low swell: crown +0.426
        // where the anvil's is +0.670, so the same sink number means something completely different
        // to it. It is ALREADY the billowed base this pass is asking the rest of the region to
        // become — at its own floor its aspect is (0.426 − 0.15) / 0.49 = 0.56 across its short axis
        // and 0.28 along its long one — and it is the only top-surface relief crossing the deck's
        // middle distance, which is the one thing standing between v3 and an unbroken flat sheet.
        // Sinking it further to satisfy a floor derived for the tall variants would delete the
        // region's answer to the critic in order to satisfy the critic. These two values are round
        // 4's swell band verbatim (it read CloudLobeSinkMin + 0.03 and 0.26); they are written out
        // here so the swell band no longer moves when the tall variants' floor does.
        // Its own safety margin, at its own floor and its own smallest radius: (0.15 + 0.355) × 26
        // = 13.13 m of hang against the 7 m trough — 6.13 m, the widest in the region.
        private const float CloudLobeSwellSinkMin = 0.15f;
        private const float CloudLobeSwellSinkMax = 0.26f;
        // THE SCALLOP. A metaball cluster has a vector-smooth silhouette, and a vector-smooth
        // silhouette is the one thing storybook cloud never has — Wolfwalkers and fable-03 both draw
        // cumulus as a chain of scallops, and the round-3 capture's big near mass reads as a dome
        // partly because its outline is a French curve. Radial displacement rather than a shading
        // trick, because the finding is about the SHAPE against the sky. Two octaves in the same
        // 1 : 0.4 proportion as the vault's own cauliflower (SkyGradient.hlsl §TarrockVaultCloud),
        // so near cloud and far cloud are broken by one hand. MEASURED over 200 000 directions, the
        // summed field has std 0.295 and stays inside ±0.97, so at amplitude 0.11 the radial
        // multiplier runs 0.89-1.10 with a 3.2% typical deviation: on a 24 m mass that is 0.8 m
        // typical and 2.5 m at the extremes, which at 100 m is a 1.4° bite — 28 px of the gameplay
        // lens. A drawn edge, and nowhere near enough to fold the surface back on itself.
        // At scale 2.6 the broad octave turns ~5 times round the silhouette and the nibble ~11,
        // which is 14 and 6 meridian segments per bump at the 72-meridian tessellation above.
        // ROUND 10 REVERTS ROUND 9's (7.0, 0.20) + `bite` OCTAVE TO (2.6, 0.11), and it is reverted
        // for a reason that is INDEPENDENT of the CloudLobe.shader revert it travels with: the
        // round-9 scallop is past the sampling limit of the mesh that carries it.
        //
        // THE ARITHMETIC THE ROUND-9 NOTE ABOVE GOT WRONG BY A FACTOR OF TWO. A GradNoise argument
        // dir.x·k sweeps −k → +k → −k once round the equator, so the field completes 2k cycles per
        // revolution, not k. Against the 72-meridian grid (Nyquist 36 turns), measured verbatim off
        // this file's own CloudLobeScallopFactor (scratchpad round10/builderS/facetmesh.py):
        //     round 8, k 2.6   broad  5.2 turns (13.9 verts/bump)   nibble 11.2 ( 6.4 verts/bump)
        //     round 9, k 7.0   broad 14.0 turns ( 5.1 verts/bump)   nibble 30.1 ( 2.4 verts/bump)
        //                      bite  64.7 turns ( 1.1 verts/bump)   <-- 1.8x OVER Nyquist
        // The `bite` octave cannot be represented at all; what the mesh draws in its place is alias.
        // Reconstructing the equator ring against a 4x-density evaluation of the same field, the
        // round-8 scallop loses 78% of its own std between vertices and the round-9 one loses 138% —
        // i.e. round 9's mesh carries less of the intended shape than none of it would.
        //
        // Round 4 already wrote this rule down at §CloudLobeMeridians — "a displaced silhouette at
        // that spacing is a polygon, which is the one thing this pass must not add" — and raised the
        // tessellation from 48x26 to 72x40 to honour it. Round 9 broke it from the other side, by
        // raising the displacement's frequency instead of the mesh's.
        //
        // AND THAT IS FACETING, MEASURED. Angle between adjacent quad normals round a unit mass,
        // scallop only: smooth blob 3.9° mean / 5.0° p95; round 8 13.6° / 29.1°; round 9 51.1° /
        // 101.0° / 135.5° max. A 101° p95 dihedral is a crumpled paper ball, and it is exactly
        // critic 2's round-9 finding ("faceted the lobes") stated in degrees.
        //
        // WHY THE ROUND-9 SWEEP COULD NOT SEE IT. It scored with critic 5's perimeter/√area of a
        // luma-threshold mask — an estimator that REWARDS fragmentation. Faceted normals fragment
        // a luma threshold, so the score rose (14.49 → 18.19) while the picture got worse. That is
        // the round-5 trap ("failed on the picture while passing on the metric") repeated: a
        // silhouette statistic cannot arbitrate a shading artefact.
        //
        // WHAT ACTUALLY BUYS THE ARTICULATION, deferred rather than dropped: the round-9 note's own
        // honest half is right — radial displacement of a star-shaped blob makes a bigger smooth
        // blob at any amplitude (isoperimetric ratio 1.11 → 1.12 across its whole sweep). The mass
        // has to be BROKEN — sub-lobes with their own silhouettes, or a second smaller mass
        // overlapping the first — which is a placement change, or the mesh has to be retessellated
        // to afford the frequency. Both are bigger than a constant.
        // At scale 2.6 the broad octave turns ~5 times round the silhouette and the nibble ~11,
        // which is 14 and 6 meridian segments per bump at the 72-meridian tessellation above.
        private const float CloudLobeScallop = 0.11f;
        private const float CloudLobeScallopScale = 2.6f;

        // -- THE SWELL BAND (round 4). The deck's own answer to "no top-surface relief crossing the
        //    mid-field": a ring of LOW, WIDE masses (variant 4) lying just off the island's edge,
        //    crowns only 6-12 m proud of the sea, which cross every rim vantage's middle distance
        //    and — being geometry — occlude the deck behind them. A shaded plane cannot do this at
        //    any relief height, which two rounds of shading the deck have now proved.
        //
        //    Placed by distance OUTSIDE THE FOOTPRINT rather than by radius from the region centre,
        //    which is what makes "mid-field" mean the same thing on every bearing: a ray on bearing
        //    θ leaves the 256 m square at 128 / max(|sin θ|, |cos θ|) from centre — 128 m on the
        //    axes, 181 m into the corners — and the band is measured from there. A centre-based ring
        //    at these distances would sit on the island.
        //
        //    THE BAND IS TUNED BY WHAT IT DELIVERS, not by taste. Simulated over the real hash rolls
        //    and the real anchor table, these numbers put 5 swells inside 220 m of the v3 lens (the
        //    nearest at 82 m), 4 inside 220 m of v4 (nearest 140), 3 for v8 and 4 for v1 — a mid
        //    distance with something standing in it from every vantage. The generous version (a
        //    45 m inner gap and 14 m of clearance round the anchors, tried first) left v3 with ONE
        //    swell inside 220 m and the rest past 235, where the fog has taken a third of everything
        //    and an occlusion edge no longer reads. The clearance is small on purpose: cumulus
        //    clusters, and a swell nestling against an anchor's foot is what a cluster looks like.
        private const int CloudLobeSwellCount = 44;
        private const float CloudLobeSwellInnerGap = 24f;   // metres of open sea beyond the rim
        private const float CloudLobeSwellOuterGap = 150f;
        private const float CloudLobeSwellMinRadius = 26f;
        private const float CloudLobeSwellSizeRange = 20f;
        private const float CloudLobeSwellClearance = 6f;

        // The far scatter that fills the rest of the compass. 300 m clears the terrain's farthest
        // corner (181 m from centre) and the swell band outside it; 700 m is where the shader's sky
        // convergence has taken over anyway. These are silhouette and aerial perspective — at 300 m
        // the fog leaves 18% of any mass's own contrast and at 500 m under 1%, so nothing out here
        // is asked to carry value.
        private const float CloudLobeScatterInner = 300f;
        private const float CloudLobeScatterOuter = 700f;
        private const int CloudLobeScatterCount = 40;
        private const float CloudLobeScatterMinRadius = 18f;
        private const float CloudLobeScatterSizeRange = 15f;

        /// <summary>One art-directed cumulus head standing out of the cloud sea: where it is, how
        /// big, which mass, and how deep it sits in the sea.</summary>
        private readonly struct CloudLobeAnchor
        {
            public CloudLobeAnchor(float x, float z, float radius, int variant, float sink)
            {
                X = x;
                Z = z;
                Radius = radius;
                Variant = variant;
                Sink = sink;
            }

            public float X { get; }

            public float Z { get; }

            /// <summary>Metres, and it is the mass's true half-extent: the mesh is normalised so
            /// the farthest vertex sits at exactly 1.</summary>
            public float Radius { get; }

            public int Variant { get; }

            /// <summary>Fractions of its own radius that this mass's centre sits BELOW the deck.
            /// ROUND 4: per-anchor, where round 3 had one constant for every mass in the region —
            /// which is most of why the critic read v4's cloud as "same-size same-altitude". Two
            /// masses of the same shape at 0.12 and 0.30 stand at quite different heights out of
            /// the sea, and a row that mixes them reads as weather rather than as a fence.
            /// Bounded by CloudLobeSinkMin: a mass must hang far enough under the deck that the
            /// deck's own billow can never expose a lit gap beneath it.</summary>
            public float Sink { get; }
        }

        // The composition anchors, in the order the frames need them. Coordinates were chosen by
        // back-projecting the wanted screen position through each vantage's frustum onto the deck.
        //
        // ROUND-5 WARNING, AND IT IS A DEBT: BuildLighting raised the fog density to 0.0059 to buy
        // the terrain's aerial ramp, so every transmittance and every crown-to-base figure in this
        // block is now OPTIMISTIC. Re-derived at 0.0059 the row reads B 0.70/53 points, E 0.51/37,
        // G 0.40/30, F 0.37/30, A 0.28/22, D 0.24/19, H 0.045/2, C 0.012/1 — the value carriers all
        // hold above the round-3 failure line (8 points), which is the constraint that PINNED the
        // new density from above, but A and D are thin. The anchors were deliberately not re-solved
        // in the fog pass (they are back-projected screen positions, and moving eight of them
        // blind is a cloud pass with a capture in front of it). If round 5's v3 reads flat, pulling
        // A and D in by ×0.746 restores their round-4 transmittance exactly.
        //
        // ROUND 5 HAS NOW DONE EXACTLY THAT, and only that — A and D, along their own sight lines
        // from the v3 lens, so not one screen position moves. The full crown-to-base table with the
        // round-5 palette, modelled at fog 0.0059 over a mass's visible surface through
        // shader → fog → the URP LUT chain:
        //
        //     anchor  d(r4)  span(r4 paint)  d(r5)  span(r5 paint)
        //       B      100        44.3        100        70.7   hero, unmoved
        //       E      138        28.9        138        43.0
        //       A      185        15.3        138        43.0   PULLED ×0.746
        //       D      200        12.2        149        36.9   PULLED ×0.746
        //       G      165        20.3        165        29.3
        //       F      170        19.0        170        27.2
        //       H      251         5.2        251         7.1   silhouette, and that is its job
        //       C      300         2.0        300         2.7   silhouette
        //
        // Every value-carrying mass now clears the 25-point line the fog note pins them to; F is
        // the thinnest at 27.2 and is the first candidate if a later round needs one more.
        //
        // ROUND 4 MOVED THEM IN, and the reason is one line of arithmetic. The region's exp² fog at
        // density 0.0044 leaves a surface exp(−(d·0.0044)²) of its own contrast, so a 100-point
        // value ladder is worth 82 points at 100 m, 66 at 150 m, 46 at 200 m and 18 at 300 m. Round
        // 3 stood its whole near row at 130-300 m and the critic measured the consequence — "a deck
        // lobe spans 8 luminance points". Every anchor below therefore records the RANGE it can
        // actually deliver in its own frame, modelled over the mass's visible surface through the
        // shader → fog → grade chain, and the ones whose job is value now stand inside 200 m:
        //
        //     anchor  frame   d(m)   fog   crown-to-base (sRGB luminance)
        //       B      v3      100   0.82        62      the hero, and the dark anchor
        //       A      v3      185   0.51        35
        //       D      v3      200   0.46        31
        //       C      v3      300   0.18         9      silhouette only, and that is its job
        //       E      v4      138   0.66        48      the near tower in the col
        //       G      v4      165   0.59        44
        //       F      v4      170   0.57        40
        //       H     v8/v1    251   0.30        14      silhouette
        //
        // AND THEY NO LONGER SHARE ONE ALTITUDE. Sink is per-anchor now, so the masses stand at
        // genuinely different heights out of the sea — the other half of the critic's "same-size
        // same-altitude" reading.
        //
        // ROUND 12 RAISES EVERY ONE OF THEM INTO [0.26, 0.34]. The round-4/5 row ran 0.10-0.32 and
        // its shallow end is the islet the round-11 critic read: at 0.10-0.14 a mass meets the deck
        // at 83-84° and stands taller than its own half-width. The order is preserved — the anchor
        // that stood highest still stands highest — but the whole row now sits IN the sea rather
        // than ON it. Crown heights are (crown − sink) × radius using this file's own measured
        // extents, so they can be checked:
        //
        // Old sinks are quoted as the region actually BUILT them, i.e. after PlaceCloudLobe's
        // clamp — which is why G's column starts at 0.12 and not at the 0.10 in its own row.
        //
        //     anchor  var  R    sink 4/5 → 12   contact °    crown proud (m)   visible cap area
        //       G      5   30    0.12 → 0.27    83.1 → 74.3   16.5 → 12.0       ×0.78
        //       E      1   28    0.12 → 0.26    83.1 → 74.9      —              ×0.79
        //       B      5   24    0.14 → 0.28    82.0 → 73.7   12.7 →  9.4       ×0.79
        //       D      2   24    0.18 → 0.30    79.6 → 72.5      —              ×0.81
        //       H      2   34    0.22 → 0.30    77.3 → 72.5      —              ×0.86
        //       A      0   25    0.24 → 0.32    76.1 → 71.3      —              ×0.86
        //       F      0   26    0.26 → 0.33    74.9 → 70.7      —              ×0.87
        //       C      3   20    0.32 → 0.34    71.3 → 70.1      —              ×0.96
        //
        // Row mean: ×0.841, i.e. the anchors give up 15.9% of their cloud area. The far scatter's
        // mean sink goes 0.193 → 0.287 for ×0.847; the swell band does not move at all.
        //
        // Crown heights are quoted only for variant 5, whose extents this file has measured
        // (+0.670 / −0.381 at §CloudLobeShape case 5). The other five arrangements' crowns have
        // never been written down, which is a real gap: without them the metres a sink buys can be
        // derived for two of the seven shapes and no more. TBD, and it is one editor-side print of
        // each variant's normalised bounds, not a design question.
        //
        // The visible-cap column is the fraction of screen area each mass keeps, from the segment
        // of its own projected disc standing above the waterline — area ∝ arccos(s) − s√(1−s²).
        // The row costs 4-22% of its cloud area, and it is spent on the waterline read. THE FIRST
        // STEP IS THE EFFICIENT ONE, which is why this pass takes it and stops: 0.12 → 0.26 buys
        // 8.2° of contact angle for 21% of the area, and 0.26 → 0.40 would buy the next 8.5° for
        // another 22% — so a second, deeper pass costs the same again and should not be taken
        // blind. Whether the deck wants it is a question for a capture, not for this file.
        //
        // G's authored sink WAS 0.10, which is under the round-4 floor of 0.12 and was silently
        // clamped by PlaceCloudLobe — so the comment below it ("stands HIGH (sink 0.10)") described
        // a mass the region never built. It stands highest here on its crown in METRES (12.0 m,
        // the tallest in the row) rather than on the shallowest sink, which is what "stands HIGH"
        // was always trying to say.
        private static readonly CloudLobeAnchor[] CloudLobeAnchors =
        {
            // -- B, and it is the one that does the work: v3's hero, and the frame's dark anchor at
            //    the horizon. 100 m out on bearing 243° from the v3 lens — 30 m nearer than round 3,
            //    which is the difference between 44 points of crown-to-base and 62. A SHOULDERED
            //    ANVIL (mass 5) rather than round 3's tower: one high crown, a long shoulder falling
            //    away from it, and a base wide enough to carry the dark. It spans x 135-750 px with
            //    its crown on row ≈343 and its waterline on row ≈520, so it still cuts the far
            //    bank's crest band and the left-hand island silhouettes' feet. Near cloud in front
            //    of far land is the only sentence in the frame that says "sea".
            new CloudLobeAnchor(-64f, 93f, 24f, 5, 0.28f),

            // -- A: the broad low bank behind and right of B, at 185 m and u +0.15. Sunk deeper
            //    (0.24) than B so its crown sits visibly lower — the row's second altitude.
            //
            //    ROUND 5 PULLS IT IN, which is the debt the round-4 fog pass wrote down above.
            //    185 m × 0.746 = 138 m, and the scale is taken ALONG THE RAY FROM THE v3 LENS
            //    (25, 138) rather than from the origin, so the screen position the anchor was
            //    back-projected to is preserved exactly: (25, 138) + 0.746 × (−184, +19) =
            //    (−112.3, 152.2), which is 138.0 m out on the same bearing. Modelled crown-to-base
            //    goes 19.8 → 38.6 sRGB points with the new palette; at 185 m it would have sat
            //    under the 25-point line the fog note pins the value carriers to.
            //    The radius comes down 28 → 25 to pay for the perspective: at 0.746 the distance a
            //    mass of unchanged size grows 34% on screen, which would take A from 63% of B's
            //    angular width to 85% and cost B its place as the hero. 25 m at 138 m is 76%, and
            //    it is still above _LobeThickRadius (24 m), so A keeps the full deep base.
            new CloudLobeAnchor(-112.3f, 152.2f, 25f, 0, 0.32f),

            // -- D: the answering mass at u +0.67, so the right of frame is not left to the vault
            //    alone. Drawn out along the wind axis (mass 2) and at 200 m.
            //
            //    ROUND 5 PULLS IT IN on the same rule: (25, 138) + 0.746 × (−173, +100) =
            //    (−104.1, 212.6), 149.1 m out on the unchanged bearing. Crown-to-base 15.7 → 33.1.
            //    Radius 26 → 24, which is exactly _LobeThickRadius, so D also keeps its full base.
            new CloudLobeAnchor(-104.1f, 212.6f, 24f, 2, 0.30f),

            // -- C: the small far head at 300 m, u −0.19 — clearly BEHIND B and A, which is where
            //    the row's depth comes from. Nine points of internal value at that range and no
            //    pretence otherwise: it is a silhouette, sunk almost to its shoulders (0.32).
            new CloudLobeAnchor(-268f, 76f, 20f, 3, 0.34f),

            // -- v4's row, east and north-east of the island, standing in the cream gap that round 3
            //    named. E is the near tower filling the col at u +0.23 from 138 m, nearer than the
            //    mid-distance ridge behind it — so it occludes that ridge's foot rather than peering
            //    over its shoulder. G crops the right edge at u +0.98 and stands HIGH (crown 12.0 m,
            //    the tallest in the row); F answers low on the left at u −0.51 and sits DEEP (0.33).
            //    Three masses, three sizes, three altitudes, and a gap of open sea between each
            //    pair. ROUND 12 raised all three — see the sink table above the anchor array; E and
            //    G were the two shallowest masses in the region and so the two that read hardest as
            //    islets.
            new CloudLobeAnchor(288f, 96f, 28f, 1, 0.26f),
            new CloudLobeAnchor(314f, 18f, 30f, 5, 0.27f),
            new CloudLobeAnchor(259f, 195f, 26f, 0, 0.33f),

            // -- H: south-west of the island, behind the knoll. Not for v3 or v4 — it is what v8's
            //    backlit dead tree gets to be silhouetted against once the eye follows the ridge
            //    down, and what v1's left edge sees past the south wall.
            new CloudLobeAnchor(60f, -124f, 34f, 2, 0.30f),
        };

        /// <summary>The cumulus heads standing out of the deck. Real geometry, because occlusion is
        /// the finding and only geometry occludes — see the section header above.</summary>
        private static void BuildCloudLobes()
        {
            Shader lobeShader = Shader.Find(CloudLobeShaderName);
            if (lobeShader == null)
            {
                Debug.LogWarning(
                    $"[Tarrock] {CloudLobeShaderName} not found; the cloud lobes are skipped and the " +
                    "deck reverts to an unoccluded plane.");
                return;
            }

            var meshes = new Mesh[CloudLobeVariants];
            for (int variant = 0; variant < CloudLobeVariants; variant++)
            {
                Mesh mesh = BuildCloudLobeMesh(variant);
                string path = string.Format(CloudLobeMeshPathFormat, variant);
                AssetDatabase.DeleteAsset(path);
                AssetDatabase.CreateAsset(mesh, path);
                meshes[variant] = mesh;
            }

            Material material = BuildCloudLobeMaterial(lobeShader);
            var root = new GameObject("CloudLobes");

            foreach (CloudLobeAnchor anchor in CloudLobeAnchors)
            {
                PlaceCloudLobe(root.transform, meshes, material, anchor.X, anchor.Z, anchor.Radius,
                    anchor.Variant, Hash21(anchor.X * 0.19f, anchor.Z * 0.53f), anchor.Sink);
            }

            var placed = new List<Vector3>();   // (x, z, radius) of everything already standing
            foreach (CloudLobeAnchor anchor in CloudLobeAnchors)
            {
                placed.Add(new Vector3(anchor.X, anchor.Z, anchor.Radius));
            }

            int swells = BuildCloudSwellBand(root.transform, meshes, material, placed);
            int scattered = BuildCloudFarScatter(root.transform, meshes, material, placed);

            Debug.Log($"[Tarrock] Cloud lobes: {CloudLobeAnchors.Length} art-directed + " +
                      $"{swells} mid-field swells + {scattered} far scattered.");
        }

        /// <summary>The mid-field swell band — low wide masses lying in the open sea just off the
        /// island, which is the only thing that can put top-surface relief across the deck's middle
        /// distance. See the constants block for why they are placed from the FOOTPRINT and not
        /// from the region centre.</summary>
        private static int BuildCloudSwellBand(
            Transform parent, Mesh[] meshes, Material material, List<Vector3> placed)
        {
            int built = 0;
            for (int i = 0; i < CloudLobeSwellCount; i++)
            {
                // Bearings walk the compass in equal steps with a jittered offset, rather than
                // coming off a hash: a hashed bearing clumps, and a clumped ring round an island
                // reads as three cloud banks and five holes.
                float bearing = (i + 0.5f) * (360f / CloudLobeSwellCount)
                                + (Hash21(i + 5.31f, 17.7f) - 0.5f) * 7.2f;
                float radians = bearing * Mathf.Deg2Rad;
                float sin = Mathf.Sin(radians);
                float cos = Mathf.Cos(radians);

                float sizeRoll = Hash21(i + 61.7f, 13.3f);
                float gapRoll = Hash21(i + 27.9f, 44.1f);
                float keepRoll = Hash21(i + 91.3f, 8.6f);
                float spinRoll = Hash21(i + 36.5f, 72.4f);
                float sinkRoll = Hash21(i + 14.2f, 55.8f);

                // Squared roll: most swells are modest and a few are broad. A flat size
                // distribution is the tell of a scatter tool, in cloud exactly as in stone.
                float radius = CloudLobeSwellMinRadius + CloudLobeSwellSizeRange * sizeRoll * sizeRoll;
                // Where this bearing's ray leaves the terrain square, plus open sea. The +radius
                // keeps the mass's NEAR EDGE outside the footprint by the full inner gap, so no
                // swell can ever overlap ground that stands above the deck.
                float exit = (TerrainSize * 0.5f) / Mathf.Max(Mathf.Abs(sin), Mathf.Abs(cos));
                float ring = exit + radius
                             + Mathf.Lerp(CloudLobeSwellInnerGap, CloudLobeSwellOuterGap, gapRoll * gapRoll);

                float x = TerrainSize * 0.5f + ring * sin;
                float z = TerrainSize * 0.5f + ring * cos;
                if (keepRoll > 0.74f || CloudLobeCrowds(placed, x, z, radius, CloudLobeSwellClearance))
                {
                    continue;   // gaps are composition; an unbroken ring is a belt
                }

                // A NARROWER sink range than the far scatter's: a swell already stands only 3-11 m
                // proud, and the deck's own billow now reaches 5.5 m, so a swell sunk past ~0.26
                // would simply be swallowed by the sea it is meant to shape. ROUND 12: the same two
                // numbers, but taken from the swell band's own constants rather than from the tall
                // variants' floor — see CloudLobeSwellSinkMin for why one floor cannot serve both.
                float sink = Mathf.Lerp(CloudLobeSwellSinkMin, CloudLobeSwellSinkMax, sinkRoll);
                PlaceCloudLobe(
                    parent, meshes, material, x, z, radius, CloudLobeSwellVariant, spinRoll, sink);
                placed.Add(new Vector3(x, z, radius));
                built++;
            }

            return built;
        }

        /// <summary>The far ring. Silhouette and aerial perspective only — at these ranges the fog
        /// leaves under a fifth of any mass's own contrast, so what these buy is the layered
        /// horizon, not value.</summary>
        private static int BuildCloudFarScatter(
            Transform parent, Mesh[] meshes, Material material, List<Vector3> placed)
        {
            int built = 0;
            for (int i = 0; i < CloudLobeScatterCount; i++)
            {
                float bearing = (i + 0.5f) * (360f / CloudLobeScatterCount)
                                + (Hash21(i + 3.17f, 11.9f) - 0.5f) * 5.6f;
                float radiusRoll = Hash21(i + 41.3f, 7.7f);
                float sizeRoll = Hash21(i + 88.9f, 23.1f);
                float keepRoll = Hash21(i + 12.7f, 61.5f);
                float spinRoll = Hash21(i + 55.1f, 34.9f);
                float variantRoll = Hash21(i + 70.3f, 5.2f);
                float sinkRoll = Hash21(i + 23.8f, 66.2f);

                // Biased inward (the squared roll), because the ring that still reads is the near
                // one and the far ones are mostly aerial perspective by the time the shader has
                // finished with them.
                float ring = Mathf.Lerp(CloudLobeScatterInner, CloudLobeScatterOuter,
                    radiusRoll * radiusRoll);
                float x = TerrainSize * 0.5f + ring * Mathf.Sin(bearing * Mathf.Deg2Rad);
                float z = TerrainSize * 0.5f + ring * Mathf.Cos(bearing * Mathf.Deg2Rad);

                float radius = CloudLobeScatterMinRadius
                               + CloudLobeScatterSizeRange * sizeRoll * sizeRoll;
                if (keepRoll > 0.68f || CloudLobeCrowds(placed, x, z, radius, 20f))
                {
                    continue;
                }

                // The nub (6) is drawn twice as often as the rest out here: at 300 m and beyond a
                // mass is a shape on the skyline, and a skyline of six identical anvils is a fence.
                int variant = variantRoll < 0.34f
                    ? 6
                    : Mathf.Clamp(Mathf.FloorToInt(variantRoll * CloudLobeVariants), 0, CloudLobeVariants - 1);
                float sink = Mathf.Lerp(CloudLobeSinkMin, CloudLobeSinkMax, sinkRoll * sinkRoll);
                PlaceCloudLobe(parent, meshes, material, x, z, radius, variant, spinRoll, sink);
                placed.Add(new Vector3(x, z, radius));
                built++;
            }

            return built;
        }

        /// <summary>An anchor is a composition and a swell is a shape; nothing placed later may
        /// crowd one or hide it. <paramref name="clearance"/> is the open sea demanded between two
        /// masses' edges.</summary>
        private static bool CloudLobeCrowds(
            List<Vector3> placed, float x, float z, float radius, float clearance)
        {
            var point = new Vector2(x, z);
            foreach (Vector3 other in placed)
            {
                if (Vector2.Distance(point, new Vector2(other.x, other.y)) < other.z + radius + clearance)
                {
                    return true;
                }
            }

            return false;
        }

        private static Material BuildCloudLobeMaterial(Shader lobeShader)
        {
            var material = AssetDatabase.LoadAssetAtPath<Material>(CloudLobeMaterialPath);
            if (material == null)
            {
                material = new Material(lobeShader);
                AssetDatabase.CreateAsset(material, CloudLobeMaterialPath);
            }
            else
            {
                material.shader = lobeShader;
            }

            // Every property explicit (same rule as the deck and the terrain — a reused .mat keeps
            // stale serialized values while shader defaults appear to change).
            //
            // ROUND 4 — THE LADDER, AND WHY IT WIDENS BY 22 sRGB POINTS. The round-3 critique was
            // "a deck lobe spans 8 luminance points crown-to-base and matches the sheet behind it".
            // Measured on round3/v3 the small heads run 180→198. That is not the palette's fault:
            // modelled through this project's grade, round 3's crown (1.02,0.97,0.86) lands at sRGB
            // luminance 202 and its belly (0.30,0.35,0.48) at 124 — a 78-point ladder. The loss is
            // FOG plus a base that was never drawn:
            //   * FOG. exp² at density 0.0044 keeps exp(−(d·0.0044)²) of a surface's own contrast:
            //     0.72 at 130 m, 0.43 at 210 m, 0.18 at 300 m. Round 3's row stood at 130-300 m, so
            //     78 × 0.18 = 14 points at the far end. The capture is the arithmetic exactly.
            //     (Round 5's density is 0.0059, which makes the same three figures 0.55 / 0.19 /
            //     0.04 — see the warning at CloudLobeAnchors. The argument is unchanged; the numbers
            //     it is made of moved, and this palette is not what pays for it.)
            //   * THE BASE. Round 3 drew the belly from saturate(−N.y), and from a camera standing
            //     on the island the only down-facing surface in view is the sliver of overhang at
            //     the waterline — so the masses had no dark end at all. The shader now paints the
            //     base from the mass's own height above the cloud sea (CloudLobe.shader §THE BASE).
            // Both are answered: the ladder widens to 100 points and the anchors move in (see
            // CloudLobeAnchors, where every entry carries the fog factor it will be seen through).
            //
            // The values themselves. Lit crown is the far bank's crest plus a touch — a near head
            // and a far one are the same weather in the same light. Shade sits at sRGB luminance
            // 153, below the far bank's body (which grades to 158) and below the deck's own furrows,
            // which is correct aerial perspective and is why the near row reads as near. The belly
            // is the new value: 105, within eleven points of the vault's own dark anchor (94), so
            // the horizon gets the same weight of dark that the sky already has.
            //
            // ROUND 5 — THREE NAMED WASHES, AND THE HAZE FLOOR THAT DECIDES WHERE THEY LAND.
            // The critic asked for lit ≈ L205 / R−B +55, mid ≈ L165, shadow core ≈ L110 / R−B −40,
            // and the last of those is ARITHMETICALLY UNREACHABLE at this fog density. exp² fog at
            // 0.0059 mixes fogColor — a warm haze at linear (0.90, 0.85, 0.74) — into everything at
            // 1 − exp(−(d·0.0059)²), so PERFECTLY BLACK PAINT photographs as:
            //
            //     d      fog T   darkest possible L   coolest possible R−B
            //     100 m  0.706        136.2                 +29.4
            //     138 m  0.515        167.0                 +32.7
            //     170 m  0.366        183.4                 +32.0
            //     200 m  0.248        193.3                 +31.1
            //
            // There is no paint that reaches L110 past about 30 m, and no paint that makes the HAZE
            // itself cool. (R−B can still be pulled down by adding blue, which raises L — the floor
            // is on luminance, not on hue — which is why the shadow below is a saturated blue-grey
            // rather than a neutral dark.) The three washes are therefore solved AGAINST that floor
            // at the hero's own range: modelled over a 615×300 mass at 100 m through fog → grade,
            // they land LIT L215.9 / R−B +46.4, MID L171.8, SHADOW L145.4 — nine points off the
            // absolute floor — for a crown-to-base of 70.7 sRGB points against round 4's modelled
            // 44.3. Reference for the shape of that ramp is ghibli-totoro's two cumulus banks
            // (LIT 206.5/+38.9, MID 121.1/−59.3, SHD 100.1/−55.5) and fable-06 (244.4, 168.2, 77.1).
            // The one number the fog cannot be argued out of is the shadow's HUE, and the report
            // says so rather than pretending otherwise.
            // ROUND 8, (1.10, 1.01, 0.84) → (0.885, 0.870, 0.779), and the crown does not move a
            // level. The disc's shared warmth trebles this round (SkyGradient.hlsl
            // §TARROCK_CLOUD_SUNWARM, 0.22 → 0.70) and the near row shares that constant because the
            // two rows of cloud cannot be lit by different suns; so the PAINT gives back exactly
            // what the LIGHT gains — g2l(1.10,1.01,0.84) + 0.22·sunGlow and
            // g2l(0.885,0.870,0.779) + 0.70·sunGlow are both (1.448, 1.162, 0.723) linear. The
            // pigment is near-neutral now and the gold is illumination, which is the same move
            // round 7 made on the vault's crown and the reason a grade can no longer invert it.
            // Kept in step with Tarrock/CloudLobe's own default for the same property.
            material.SetColor("_LobeLit", new Color(0.885f, 0.870f, 0.779f));
            material.SetColor("_LobeMid", new Color(0.57f, 0.60f, 0.70f));
            material.SetColor("_LobeShade", new Color(0.22f, 0.27f, 0.43f));
            material.SetColor("_LobeUnder", new Color(0.13f, 0.18f, 0.33f));
            material.SetFloat("_LobeMidPoint", 0.46f);
            // The crumple: how far the mass's own cauliflower moves a wash boundary before the
            // terrace cuts it. Without it a terrace of the smooth wrapped-light form draws clean
            // latitude contours — a screen-space posterize, not painted form — and the round-4
            // measurement of exactly 0.00% of interior pixels above gradient-magnitude 8 is what
            // that looks like. 0.30 on a three-octave field of std 0.26 is a third of a wash.
            material.SetFloat("_LobeCrumple", 0.30f);
            // FOUR washes at 55% over 0.22 of softness — the sky's own brush. Round 3's three at
            // 85% over 0.10 is what drew the hard vertical bevel the critic named: with the sun 12°
            // up the iso-N·L contours on a rounded head are near-vertical great circles, and an 85%
            // terrace of them is a stencil of vertical stripes. The boundaries still read (they are
            // what makes it a painting); they no longer cut facets.
            // ROUND 5: THREE washes at 0.92 over 0.030. Round 4's four at 0.55 over 0.22 measured as
            // no boundaries at all — 0.00% of interior pixels above gradient-magnitude 8, against
            // the plates' 4.6-5.2% — and the reason is arithmetic rather than taste. A band edge's
            // width in screen pixels is (2 × softness / bands) × (pixels the ramp spends itself
            // over); on a 300 px mass whose ramp runs top to bottom that is 33 px at 0.22 and 3 px
            // at 0.030. A 23-point step over 33 px is |grad| 0.7; over 3 px it is |grad| 8. This is
            // NOT round 3's bevel returning: that was a raw N·L terraced hard, whose iso-contours
            // under a 12° sun are near-vertical great circles down the mass. What is terraced here
            // is wrapped light mixed with a sky term and then CRUMPLED by the mass's own
            // cauliflower, so the edges wander with the lobes instead of ruling stripes across them.
            material.SetFloat("_LobeBands", 3f);
            material.SetFloat("_LobeBandStrength", 0.92f);
            material.SetFloat("_LobeBandSoftness", 0.030f);
            // The wrapped terminator and the sky term (see the shader header). Gain and bias are
            // solved rather than dialled. Sampled over a mass's VISIBLE surface — normals facing the
            // camera and above the waterline, weighted by projected area — the combined parameter
            // runs 0.185 to 0.815 (1st to 99th percentile) at v3's bearing and 0.188 to 0.884 at
            // v4's, so gain 1.45 / bias −0.12 maps v3's band onto 0.148-1.062: the whole ladder
            // used, with the top 6% rolling into the crown wash, which on a cumulus is a highlight
            // and is wanted. Round 3's gain 1.15 / bias +0.42 put the same surface at 0.21-1.00 on
            // a THREE-wash ladder at 85% terrace strength, which is why the bands showed and the
            // form did not.
            material.SetFloat("_LobeFormGain", 1.45f);
            material.SetFloat("_LobeFormBias", -0.12f);
            material.SetFloat("_LobeWrap", 0.55f);
            material.SetFloat("_LobeSunWeight", 0.68f);
            material.SetFloat("_LobeUnderDepth", 0.90f);
            // The painted base: full dark at the waterline, gone 0.42 radii above it — 10 m of dark
            // base on a 24 m mass, which is the proportion every cumulus on the reference board has.
            material.SetFloat("_LobeBaseRise", 0.42f);
            material.SetFloat("_LobeBasePower", 1.7f);
            material.SetFloat("_LobeDeckLevel", CloudDeckLevel);
            // THICKNESS READS AS DARKNESS, and these two numbers set which masses count as thick.
            // 24 m is where the anchors start (the smallest composition anchor is 24), so every
            // hand-placed mass earns the full anchor; 14 m is under the scatter's own floor of 18,
            // so a scatter nub earns 40% of it and stays light. Same rule, same reasoning, as the
            // vault's half-width weighting in SkyGradient.hlsl.
            material.SetFloat("_LobeThinRadius", 14f);
            material.SetFloat("_LobeThickRadius", 24f);
            // Tighter than round 3's power 4: on a mass that fills 500 px a power-4 grazing term is
            // not a rim, it is a wash over the whole limb, and it was part of what kept the round-3
            // heads pale all over.
            // ROUND 10 REVERTS 2.6 → 1.1 WITH THE SHADER, AND THIS ONE IS NOT OPTIONAL. Round 9
            // raised the strength because its accent spent itself on a sunward quarter of the limb
            // instead of round the whole of it (CloudLobe.shader §THE ACCENT, WHICH IS NOT A RIM,
            // reverted this round). The round-8 shader that is back in the tree multiplies
            // _SunGlowColor · pow(1 − |N·V|, 6) · saturate(N·L) by this number, and pow(1 − |N·V|)
            // is a constant-width band round the ENTIRE silhouette — so leaving 2.6 in place would
            // have shipped the halo term the round-9 note above was written to remove, at 2.4x its
            // round-8 strength. A half-revert here is strictly worse than either whole.
            material.SetFloat("_LobeRim", 1.1f);
            material.SetFloat("_LobeRimPower", 6f);
            // The same convergence numbers as the deck, so the near row and the sea it stands in
            // recede together instead of separating into two layers.
            material.SetFloat("_SkyBlendStart", 430f);
            material.SetFloat("_SkyBlendEnd", 820f);
            ApplySkyDescription(material);
            material.enableInstancing = true;
            EditorUtility.SetDirty(material);
            return material;
        }

        private static void PlaceCloudLobe(
            Transform parent, Mesh[] meshes, Material material,
            float x, float z, float radius, int variant, float spinRoll, float sink)
        {
            var go = new GameObject($"CloudLobe_{x:F0}_{z:F0}");
            go.transform.SetParent(parent, worldPositionStays: false);
            // Clamped, not trusted: the sink is what guarantees a mass hangs far enough under the
            // deck that the billow can never open a lit gap beneath it (see CloudLobeSinkMin).
            // ROUND 12: the floor is per-shape, because the shape set's crowns run +0.426 (the low
            // swell) to +0.670 (the anvil) and one fraction-of-radius floor therefore means a
            // billowed base to one and a submerged nothing to the other. Both floors are derived
            // against the same 7 m billow trough and both carry more margin than round 4's.
            float sinkFloor = variant == CloudLobeSwellVariant
                ? CloudLobeSwellSinkMin
                : CloudLobeSinkMin;
            sink = Mathf.Clamp(sink, sinkFloor, CloudLobeSinkMax);
            go.transform.position = new Vector3(x, CloudDeckLevel - radius * sink, z);
            // Yaw only. A cumulus has an up; rolling one puts its flat base in the air.
            go.transform.rotation = Quaternion.Euler(0f, spinRoll * 360f, 0f);
            go.transform.localScale = Vector3.one * radius;

            go.AddComponent<MeshFilter>().sharedMesh = meshes[variant];
            var renderer = go.AddComponent<MeshRenderer>();
            renderer.sharedMaterial = material;
            // A 12° sun turns a 30 m cloud into a 141 m bar of shadow laid across whatever is
            // downlight of it — which from these positions is the island. Cloud shadow on the
            // plateau is a real effect and a real decision, and it is not this pass's to make.
            renderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            // Nor does the island's shadow fall on the cloud: the deck does not receive either, and
            // a shadowed cumulus at 150 m would put a hard-edged terrain silhouette on the sea.
            renderer.receiveShadows = false;
            // NOT marked static: static batching merges the meshes and defeats the instancing the
            // material asks for, and forty-odd merged 1 250-vertex masses would be baked into the
            // scene file for no gain.
            go.isStatic = false;
        }

        /// <summary>One cumulus mass, as a closed blob mesh of unit radius.
        ///
        /// A metaball field, not a union of spheres: overlapping spheres leave a hard intersection
        /// crease exactly where two lobes meet, and a crease shades as a seam. Summing Wyvill
        /// kernels and finding the isosurface gives ONE watertight surface with continuous normals,
        /// so the boundary between two lobes reads as the soft valley a real cumulus has there. The
        /// surface is found by marching each vertex direction out from the centre and taking the
        /// LAST crossing, which needs the cluster to be star-shaped about its centre — every lobe
        /// below overlaps the centre by design, so it is.</summary>
        private static Mesh BuildCloudLobeMesh(int variant)
        {
            // The four masses. Each is a handful of lobes in unit space (offset, radius, weight);
            // like the vault's alphabet they are drawn by one hand, varied by arrangement rather
            // than by noise. 0 is the broad low bank, 1 the two-headed tower, 2 the long drawn-out
            // one (the wind that made it is the wind that is currently held), 3 the compact head.
            Vector4[] lobes = CloudLobeShape(variant);

            const int meridians = CloudLobeMeridians;
            const int parallels = CloudLobeParallels;
            var verts = new Vector3[(meridians + 1) * (parallels + 1)];
            var uvs = new Vector2[(meridians + 1) * (parallels + 1)];

            float maxExtent = 0f;
            for (int p = 0; p <= parallels; p++)
            {
                // Polar angle from +Y. The poles are degenerate rings, which is fine on a blob —
                // the top pole is inside the crown and the bottom is under the deck.
                float polar = Mathf.PI * p / parallels;
                float sinP = Mathf.Sin(polar);
                float cosP = Mathf.Cos(polar);

                for (int m = 0; m <= meridians; m++)
                {
                    float azimuth = 2f * Mathf.PI * m / meridians;
                    var dir = new Vector3(
                        sinP * Mathf.Sin(azimuth), cosP, sinP * Mathf.Cos(azimuth));

                    Vector3 v = dir * (CloudLobeSurface(lobes, dir) * CloudLobeScallopFactor(dir));
                    int index = p * (meridians + 1) + m;
                    verts[index] = v;
                    uvs[index] = new Vector2(m / (float)meridians, p / (float)parallels);
                    maxExtent = Mathf.Max(maxExtent, v.magnitude);
                }
            }

            // Normalise so "radius" at the call site means what it says: the mass's true half
            // extent in metres, which is what every screen projection in the anchor table assumed.
            if (maxExtent > 0.0001f)
            {
                float inverse = 1f / maxExtent;
                for (int i = 0; i < verts.Length; i++)
                {
                    verts[i] *= inverse;
                }
            }

            var tris = new int[meridians * parallels * 6];
            int t = 0;
            for (int p = 0; p < parallels; p++)
            {
                for (int m = 0; m < meridians; m++)
                {
                    // Wound so the surface faces OUT. Checked against the deck mesh, which is known
                    // to face up: there a quad is (v0, v0+row, v0+1) and cross(b−a, c−a) comes out
                    // +Y, so the same handedness here means the parallel step has to come SECOND.
                    // Get this backwards and RecalculateNormals inverts every normal, the lighting
                    // reads inside-out and backface culling eats the mass.
                    int v0 = p * (meridians + 1) + m;
                    int v1 = v0 + 1;
                    int v2 = v0 + meridians + 1;
                    int v3 = v2 + 1;
                    tris[t++] = v0; tris[t++] = v2; tris[t++] = v1;
                    tris[t++] = v1; tris[t++] = v2; tris[t++] = v3;
                }
            }

            var mesh = new Mesh { name = $"CloudLobeMass{variant}" };
            mesh.SetVertices(verts);
            mesh.SetUVs(0, uvs);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateNormals();
            WeldLobeNormals(mesh, meridians, parallels);
            mesh.RecalculateBounds();
            return mesh;
        }

        /// <summary>Repairs the two normal discontinuities a UV sphere grid always has, and which
        /// round 4 shipped: the round-4 captures show a hard crease running down every deck island
        /// and a straight faceted segment on the ghost mass in v4's col, and BOTH are this, not
        /// shading.
        ///
        /// <para>THE SEAM. The grid carries meridians+1 columns so the last one can hold u = 1, so
        /// column 0 and column <c>meridians</c> are two different VERTEX INDICES at the same
        /// position. <c>RecalculateNormals</c> averages the faces that share an index, so each of
        /// the pair sees only the half of the neighbourhood on its own side and the two normals
        /// come out different — a hard shading crease down one meridian of every mass in the
        /// region, at an azimuth that depends on nothing but where the mesh happened to start.
        /// Averaging the pair and writing it back to both is the whole fix.</para>
        ///
        /// <para>THE POLES. The top and bottom rings are meridians+1 coincident vertices, each of
        /// which gets the normal of its own two triangles — so the crown of every mass is a fan of
        /// slightly different normals, which under a hard terrace (round 5 runs the washes at 0.92
        /// over 0.030) reads as exactly the polygonal crown v4 shows. Averaging the ring gives the
        /// crown one normal, which is what a smooth blob's pole should have.</para>
        ///
        /// <para>This is a normal repair only: no vertex moves, the silhouette is untouched, and it
        /// costs one pass over ~3k vertices per variant at bake time.</para></summary>
        private static void WeldLobeNormals(Mesh mesh, int meridians, int parallels)
        {
            Vector3[] normals = mesh.normals;
            int stride = meridians + 1;

            // The wrap seam: column 0 and column `meridians` are the same point.
            for (int p = 0; p <= parallels; p++)
            {
                int first = p * stride;
                int last = first + meridians;
                Vector3 merged = normals[first] + normals[last];
                if (merged.sqrMagnitude > 1e-8f)
                {
                    merged.Normalize();
                    normals[first] = merged;
                    normals[last] = merged;
                }
            }

            // The two degenerate pole rings.
            for (int p = 0; p <= parallels; p += parallels)
            {
                var sum = Vector3.zero;
                int rowStart = p * stride;
                for (int m = 0; m < meridians; m++)
                {
                    sum += normals[rowStart + m];
                }

                if (sum.sqrMagnitude > 1e-8f)
                {
                    sum.Normalize();
                    for (int m = 0; m <= meridians; m++)
                    {
                        normals[rowStart + m] = sum;
                    }
                }

                if (parallels <= 0)
                {
                    break;
                }
            }

            mesh.normals = normals;
        }

        /// <summary>The seven cumulus arrangements, as (offset x, y, z, radius) with the weight
        /// folded into the radius. Every lobe overlaps the origin so the mass stays star-shaped
        /// about it — see BuildCloudLobeMesh.
        ///
        /// ROUND 4 adds 4-6 and re-cuts nothing else. The critic's reading of v4 was "one
        /// edge-to-edge bank of same-size same-altitude flat-bottomed lobes", and while the sizes
        /// and altitudes are fixed at the placement end (see CloudLobeAnchors), the SILHOUETTES were
        /// genuinely four arrangements over fifty instances, three of which are near-symmetric
        /// clusters of one core plus a ring — which resolve to a dome. The additions are the three
        /// shapes the region was missing: something long and low enough to read as a swell on the
        /// sea, something tall and frankly ASYMMETRIC for the near hero, and something small.
        /// </summary>
        private static Vector4[] CloudLobeShape(int variant)
        {
            switch (variant)
            {
                case 4:
                    // THE LOW SWELL — the mid-field band's mass, and the deck's only real
                    // top-surface relief. Eight lobes strung along its own x with the middle three
                    // lifted, so it lies ACROSS a frame rather than standing in it. Measured after
                    // normalisation: crown +0.426, keel −0.355, 1.97 long by 0.98 across — height
                    // 0.40 of width, which is a swell on the sea. At the swell band's shallowest
                    // roll (sink 0.15) a 40 m swell stands (0.426 − 0.15) × 40 ≈ 11.0 m proud and at
                    // its deepest (0.26) 6.6 m; 10 m of cloud at 150 m subtends 3.8°
                    // — 75 px of the gameplay lens, in front of everything behind it.
                    // The lobe RADII are large (0.44-0.70) on purpose: a lone Wyvill lobe of radius
                    // r has its 0.42 isosurface at only 0.50 r, so a chain built from small lobes
                    // pinches to a waist between them. Measured minimum radial extent 0.26, and it
                    // falls at the tips of the long axis where a taper belongs.
                    return new[]
                    {
                        new Vector4(0f, 0.06f, 0f, 0.70f),
                        new Vector4(0.50f, 0.00f, 0.08f, 0.62f),
                        new Vector4(-0.48f, -0.02f, -0.08f, 0.60f),
                        new Vector4(0.88f, -0.08f, -0.04f, 0.48f),
                        new Vector4(-0.86f, -0.06f, 0.06f, 0.46f),
                        new Vector4(0.16f, 0.20f, -0.30f, 0.50f),
                        new Vector4(-0.24f, 0.14f, 0.30f, 0.48f),
                        new Vector4(0.30f, -0.14f, 0.18f, 0.44f),
                    };
                case 5:
                    // THE SHOULDERED ANVIL — the near hero (v3's B, v4's G). ASYMMETRIC on purpose:
                    // one crown high and forward, a long shoulder falling away behind it, a heavy
                    // wide base under both. Round 3's tower was a core with a ring of satellites and
                    // it photographed as a smooth dome with a bevel down it; this one cannot, because
                    // its own mass is not centred on its own axis. Measured: crown +0.670, keel
                    // −0.381, 1.56 by 0.97, minimum radial extent 0.295 — so at sink 0.14 a 24 m
                    // anvil stands 12.7 m out of the sea and hangs 12.5 m under it.
                    return new[]
                    {
                        new Vector4(0f, -0.04f, 0f, 0.68f),
                        new Vector4(0.18f, 0.48f, -0.02f, 0.50f),
                        new Vector4(0.32f, 0.16f, 0.16f, 0.52f),
                        new Vector4(-0.26f, 0.20f, -0.18f, 0.46f),
                        new Vector4(-0.58f, 0.00f, 0.12f, 0.48f),
                        new Vector4(-0.88f, -0.14f, -0.04f, 0.40f),
                        new Vector4(0.40f, -0.16f, 0.28f, 0.44f),
                        new Vector4(-0.12f, -0.18f, -0.34f, 0.42f),
                    };
                case 6:
                    // THE NUB. Two lobes and nothing else — the small thing on a far skyline that
                    // stops the far ring reading as one repeated silhouette.
                    return new[]
                    {
                        new Vector4(0f, 0f, 0f, 0.66f),
                        new Vector4(0.30f, 0.14f, -0.18f, 0.40f),
                    };
                case 1:
                    // The two-headed tower: one crown up and forward, a lower shoulder behind it.
                    return new[]
                    {
                        new Vector4(0f, 0f, 0f, 0.62f),
                        new Vector4(0.16f, 0.42f, -0.10f, 0.46f),
                        new Vector4(-0.34f, 0.14f, 0.18f, 0.44f),
                        new Vector4(0.38f, -0.06f, 0.22f, 0.40f),
                        new Vector4(-0.10f, -0.18f, -0.36f, 0.42f),
                    };
                case 2:
                    // Drawn out along its own x: the wind that made this one is the wind the region
                    // is currently holding, and the deck's noise is stretched on the same axis.
                    return new[]
                    {
                        new Vector4(0f, 0f, 0f, 0.58f),
                        new Vector4(0.52f, 0.04f, 0.06f, 0.44f),
                        new Vector4(-0.50f, -0.02f, -0.08f, 0.42f),
                        new Vector4(0.14f, 0.30f, 0.10f, 0.38f),
                        new Vector4(-0.22f, 0.18f, 0.20f, 0.34f),
                    };
                case 3:
                    // The compact head: nearly one lobe, with three small ones breaking its rim.
                    return new[]
                    {
                        new Vector4(0f, 0.04f, 0f, 0.72f),
                        new Vector4(0.34f, 0.20f, 0.14f, 0.36f),
                        new Vector4(-0.30f, 0.06f, -0.22f, 0.34f),
                        new Vector4(0.06f, -0.24f, 0.34f, 0.32f),
                    };
                default:
                    // The broad low bank: wide, only modestly tall, the workhorse of the near row.
                    return new[]
                    {
                        new Vector4(0f, 0f, 0f, 0.60f),
                        new Vector4(0.44f, 0.10f, 0.12f, 0.46f),
                        new Vector4(-0.42f, 0.06f, -0.14f, 0.44f),
                        new Vector4(0.10f, 0.26f, -0.30f, 0.40f),
                        new Vector4(-0.16f, 0.16f, 0.36f, 0.38f),
                        new Vector4(0.26f, -0.14f, 0.30f, 0.34f),
                    };
            }
        }

        /// <summary>The cauliflower on a mass's rim, as a multiplier on its radial extent.
        ///
        /// A function of the DIRECTION only, so it is continuous everywhere on the sphere and has no
        /// seam at the meridian wrap or pinch at the poles — which noise of (azimuth, polar) would
        /// have at both. Two 2-D lookups on complementary component pairs is the portable way to get
        /// a direction-continuous field out of the same GradNoise the whole region is built from;
        /// summing them also keeps the result zero-mean, so the scallop never inflates a mass, it
        /// only breaks its edge.</summary>
        private static float CloudLobeScallopFactor(Vector3 dir)
        {
            const float fine = 2.15f;   // the second octave, as a multiple of the first
            float k = CloudLobeScallopScale;
            float broad =
                GradNoise(dir.x * k + 4.1f, dir.z * k + 9.7f) +
                GradNoise(dir.y * k + 31.3f, dir.x * k + 18.9f);
            float nibble =
                GradNoise(dir.z * k * fine + 57.2f, dir.y * k * fine + 12.4f) +
                GradNoise(dir.x * k * fine + 73.6f, dir.z * k * fine + 41.8f);

            // ROUND 10 REMOVES ROUND 9's INTERMITTENT `bite` OCTAVE. It ran at 2·k·2.15² = 64.7
            // turns per revolution against this mesh's 36-turn Nyquist — 1.1 vertices per bump —
            // so it never reached the picture as a bite; it reached it as alias, and the alias is
            // the faceting critic 2 measured. See §CloudLobeScallop above for the numbers and for
            // why the round-9 estimator scored it as an improvement.
            //
            // ANY future fine octave here has to be checked against 72 meridians / 40 parallels
            // FIRST, not against a screen-space model: lobe.py evaluates this per pixel, so it can
            // reproduce a frequency the shipped mesh cannot carry.
            return 1f + (broad + nibble * 0.4f) * CloudLobeScallop;
        }

        /// <summary>Distance from the cluster centre to the metaball isosurface along
        /// <paramref name="dir"/>. Coarse march to find the LAST crossing (the outermost surface,
        /// so an inner lobe's shell can never be mistaken for the silhouette), then bisection.
        /// </summary>
        private static float CloudLobeSurface(Vector4[] lobes, Vector3 dir)
        {
            const float threshold = 0.42f;
            const int marchSteps = 40;
            const int refineSteps = 12;
            const float reach = 2.0f;

            float lastInside = 0f;
            for (int i = 1; i <= marchSteps; i++)
            {
                float t = reach * i / marchSteps;
                if (CloudLobeField(lobes, dir * t) >= threshold)
                {
                    lastInside = t;
                }
            }

            // Everything past lastInside is outside; the crossing is between it and the next step.
            float firstOutside = Mathf.Min(reach, lastInside + reach / marchSteps);

            for (int i = 0; i < refineSteps; i++)
            {
                float mid = (lastInside + firstOutside) * 0.5f;
                if (CloudLobeField(lobes, dir * mid) >= threshold)
                {
                    lastInside = mid;
                }
                else
                {
                    firstOutside = mid;
                }
            }

            return (lastInside + firstOutside) * 0.5f;
        }

        /// <summary>Wyvill's (1 − t²)³ kernel, summed. Finite support, so a lobe influences only
        /// its own neighbourhood, and C2 at the boundary, so the blend between two lobes has no
        /// crease in it to shade as a seam.</summary>
        private static float CloudLobeField(Vector4[] lobes, Vector3 p)
        {
            float sum = 0f;
            foreach (Vector4 lobe in lobes)
            {
                float radius = Mathf.Max(lobe.w, 0.01f);
                float t = (p - new Vector3(lobe.x, lobe.y, lobe.z)).magnitude / radius;
                if (t >= 1f)
                {
                    continue;
                }

                float k = 1f - t * t;
                sum += k * k * k;
            }

            return sum;
        }
    }
}
