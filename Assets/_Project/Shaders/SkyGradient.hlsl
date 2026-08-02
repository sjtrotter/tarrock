#ifndef TARROCK_SKY_GRADIENT_INCLUDED
#define TARROCK_SKY_GRADIENT_INCLUDED

// The Cliff's dawn sky, evaluated in ONE place.
//
// Two shaders include this file: Tarrock/GradientSky (the skybox) and Tarrock/CloudSea (the deck
// below every lip). That is not tidiness, it is the mechanism that removes the deck's horizon
// seam: past its fade distance the deck resolves to EXACTLY the colour the skybox would have
// drawn along the same ray, so the camera's far-clip cut through the 3 km deck has no value step
// left to reveal. Hand-matched numbers in two shaders drift; a shared function cannot.
//
// Canon: world.md §The Cliff — "an island in a sea of cloud … the drop lost in a bright,
// motionless cloud deck"; art-audio.md §Region color scripts — the Cliff is "pale dawn gold,
// wind-scoured green", with the gold living in the LIGHT, not the albedo.
//
// House style: no external includes, plain HLSL intrinsics only, so the file is legal inside both
// a CGPROGRAM skybox pass and a URP HLSLPROGRAM pass.
//
// 2026-07-31 ROUND 2. The round-1 captures (Assets/Screenshots/gauntlet/round1, v3 and v4) were
// pixel-measured and the verdict was that the cloud sea did not read as cloud and the island did
// not read as an island: the deck's top edge was a dead-level line across all 1920 px, the sky
// vault held not one cloud shape, and the brightest zone in the frame sat directly on the
// second-brightest with no value anchor between them. Two things were added here, and they are
// added HERE rather than in the deck shader on purpose:
//
//   * THE CLOUD BANK — a lumpy ribbon of far cloud standing ON the horizon, its crest line rising
//     and falling tens of pixels, with a sunlit rim over a cool shaded body. That shaded body IS
//     the missing value anchor: gold sky above it, the bank a clear step darker, the near deck
//     bright again below. Geometry can never supply this — the deck is a plane BELOW the camera,
//     so its silhouette is a straight line at eye level no matter how much the mesh billows. The
//     skyline of a cloud sea has to be painted, which is also how Wolfwalkers and Fable paint it.
//
//   * THE VAULT CLOUDS — up to four DESIGNED masses (a fixed four-lobe cumulus alphabet on a flat
//     base, placed by bearing/elevation/size, shaded in three flat washes), not a noise field.
//
// Because the deck already resolves to TarrockSkyColor at range, putting both in this function
// means the deck inherits the bank for free and the join stays analytically seamless. Anything
// painted into the sky by hand in the deck shader would have to be hand-matched here, and
// hand-matched numbers in two shaders drift — the same argument that created this file.
//
// 2026-07-31 ROUND 3 (against Assets/Screenshots/gauntlet/round2/v3, v4). The bank survived the
// critic intact — v3's crest reads as a line of distant island silhouettes, which is the island-
// in-an-archipelago read the region wants — so it is UNTOUCHED below. The vault clouds did not:
// "one blurred lozenge instead of designed clouds", and "nothing in the upper 60% of frame is
// darker than mid-value, so the dawn light has no dark anchor". Three causes, all fixed here:
//
//   * THE ALPHABET WAS SQUASHED FLAT. Round 2 measured elevation in units of halfWidth·aspect
//     with aspect 0.40, so every circular lobe of the alphabet came out 2.5× wider than it was
//     tall. Four flat ellipses in a row IS a lozenge — the capture is the alphabet working
//     exactly as written. Both axes are now in half-widths (a circle in the alphabet is a circle
//     in the sky) and the mass gets its cumulus proportion from the ARRANGEMENT of six lobes and
//     a flat base instead of from a global squash.
//
//   * THE MASSES HAD NO INTERNAL LIGHT. One smoothstep ramp across the whole mass gives one
//     gradient, so however many lobes the alphabet has, the eye sees a single soft blob. The
//     shading is now the SAME alphabet evaluated twice more, stepped toward the sun: where the
//     stepped mass still covers a pixel, that pixel's lobe faces the dawn. Two steps give three
//     flat washes with a terminator PER LOBE, which is what makes the silhouette's scallops
//     legible as form rather than as edge noise.
//
//   * NOTHING WAS DARK. cloudShade sat at luminance 0.66 linear, lighter than the sky it was
//     drawn over in places. A new cloudShadow (≈0.23 linear, the darkest value the region owns)
//     paints the belly of a mass, weighted by the mass's own half-width: a 20°-wide cumulus at
//     this hour is deep enough for a dark base and a 7° one is not, so the composition's largest
//     cloud becomes its value anchor with nothing hand-flagged.
//
// 2026-07-31 ROUND 4 (against gauntlet/round3/v3, v4, and following the sun from 7° to 12°). The
// bank survived a second critic and is UNTOUCHED again. v3's vault masses read. v4's did not:
// "one edge-to-edge bank of same-size same-altitude flat-bottomed lobes shaded on a horizontal
// axis that contradicts the sun" — four separate complaints in one sentence, and all four were
// fair. Three of them are answered in this file and the fourth (the sizes and altitudes) in
// TerrainRegionGenerator §THE VAULT CLOUDS:
//
//   * ONE SILHOUETTE, FIVE TIMES. The six-lobe alphabet was a stamp. It now has two handwritings
//     and each mass is authored somewhere between them — see TarrockCumulusField.
//   * A RULER FOR A BASE. Every mass cut its base at the same fraction of its own half width, so a
//     row of them drew one horizontal line across the sky. The base now wanders, one octave along
//     the mass's own x, exactly as the far bank's base already did and for the same reason.
//   * A WASH THAT CONTRADICTS THE SUN. This one is worth the space it gets at the terminator code
//     below: a mass more than a few degrees round the compass from the disc has a sun vector that
//     comes out almost perfectly horizontal in its own flat frame, so the three washes stepped
//     sideways and gave the mass no top and no bottom. The wash direction is now tilted up off the
//     sun vector; the disc still decides which flank is gold.

// 2026-08-01 ROUND 7 (against gauntlet/round6, all eight frames). Round 6 fixed round 5's clipping
// with a GLOBAL desaturation and left the sky clean, cool and EMPTY: measured with this pass's own
// implementation (scratchpad round7/sky-warmth/measure_sky.py), the eight frames' sky boxes lost
// 25.6 sRGB points of R−B on average and their HSL saturation fell from 0.28 to 0.16, while the
// reference board carries TWO skies at once — fable-01/04's sun side at S 0.29-0.49 / R−B +47..+60
// and fable-06/animation-04's anti-sun side at S 0.28-0.45 / R−B −45..−47. Round 6 sat at the
// average of the two, which is grey. Four changes here, and they are all one idea — PUT THE COLOUR
// BACK LOCALLY, AS LIGHT, and leave the value structure round 6 bought alone:
//
//   * THE TILT LEARNS THE BEARING (TARROCK_BEARING_TILT_POWER). Round 5's tilt is linear in
//     (1 − bearing), so steepening the anti-sun ramps enough to reach a real blue at 130° off the
//     sun ALSO killed the gold at 55-70° off — and 55-70° is where six of the eight review frames
//     look. Raising (1 − bearing) to a power leaves the mid angles nearly untilted and spends the
//     whole steepening past 90°: modelled over the graded chain, 55°/el 6° goes R−B +36 → +54 while
//     130°/el 13° goes −11 → −48.
//   * THE DAWN WASH DIES SLOWER WITH HEIGHT (TARROCK_BEARING_FALL 2.2 → 1.5) and is stronger
//     (bearingRise 0.45 → 1.15 at the C# end). Together they are the ~30 R−B points every round-6
//     critic measured missing.
//   * ...AND SO THE AIR-PATH BLOCK HAS TO TIGHTEN WITH IT (TARROCK_WASH_BLOCK 0.85 → 0.94). Round
//     6's §THE WASH IS AIR left a sixth of the wash on the masses on purpose. At round 7's wash
//     strength that sixth is 2.4× what it was, and it lands on the shadows: modelled, the v3 hero's
//     darkest-quintile R−B comes out +7.2 at 0.85 and −8.8 at 0.94.
//   * THE SUN LIGHTS THE LIT WASHES (TARROCK_CLOUD_SUNWARM). A cumulus crown is warm because the
//     DISC is on it, not because the air in front of it glows — so the warmth that round 6 correctly
//     took off the whole mass comes back only where the form says the sun reaches, weighted by how
//     sunward the mass sits. That is what kills round 6's hue-260 cold flip (v1's mass: blue-band
//     pixels 73.2% → 25.2%, lit-quintile R−B +20.3 → +33.5) without touching the shadow.
//
// The paper tooth is also re-scaled — see §THE PAPER TOOTH — because at 55 and 126 turns per half
// width it was 8 px and 3.5 px on the hero, which is a dither, not a brush.

// ---------------------------------------------------------------------------------------------
// Round-7 constants. DELIBERATELY #defines and not material properties: the fill macro at the foot
// of this file is expanded by three shaders, one of which (Tarrock/CloudSea) is another builder's
// file this round, and a new uniform in the macro would fail to compile there. A constant costs
// nothing and cannot drift between the three.
// ---------------------------------------------------------------------------------------------
#define TARROCK_BEARING_TILT_POWER 2.8   // how sharply the anti-sun ramp steepening turns on
#define TARROCK_BEARING_FALL       1.5   // how fast the dawn wash dies with elevation
#define TARROCK_WASH_BLOCK         1.00  // how much of the air-path wash a mass stands in front of
#define TARROCK_CLOUD_SUNWARM      0.70  // the disc's own warmth, on the lit washes only
#define TARROCK_CLOUD_SUNWARM_BASE 0.25  // ...of which this much survives round the anti-sun side

// 2026-08-02 ROUND 8 (against gauntlet/round7). Four constants, and three of them are one idea.
//
// THE LAW THE BOARD OBEYS AND WE DID NOT. Measured with critic 2's own cloudmass.py, the
// round-7 masses swing 10-33 sRGB points of R−B from their lit quintile to their dark one;
// animation-04's cloud bank swings 132 (shadow −66.5, lit +25.1). Round 7 read that gap as a
// paint problem and re-authored the shadow colour; it is a LIGHT problem, and it has two
// halves that no painted triple can supply:
//
//   * THE SHADE IS SKY LIGHT (TARROCK_CLOUD_SKYFILL). The only source reaching an unlit flank
//     of a cumulus is the dome, and at this hour the dome is blue. Round 7 had NO term for it:
//     the shaded washes were lit by nothing at all and then had a sixth of a warm air-path
//     wash added on top, so they came out near-neutral and, on two masses of three, warm. The
//     fill is weighted (1 − form)², i.e. it is strongest exactly where the disc is absent, so
//     it cannot touch the crown. Tinted with the sky's own MID band rather than its zenith: a
//     cumulus at 12-30° of elevation sees mostly the pale low sky, and zenith-tinted fill
//     measured (and rendered) as a royal-blue cut-out — the "bruise" round 6 warned about.
//   * THE LIGHT IS WARM (TARROCK_CLOUD_SUNWARM 0.22 → 0.70). With the shade finally cool, the
//     disc term is free to carry the warm half of the law at a strength that reads.
//   * ...AND THE AIR-PATH WASH COMES OFF THE MASSES ENTIRELY (TARROCK_WASH_BLOCK 0.94 → 1.00).
//     Round 7 kept a sixth of it on purpose, so the masses would not unstick from the sky. That
//     job now belongs to the sky fill, which mixes real sky colour into the shade — a better
//     answer to the same worry, because it hazes the mass with the sky's HUE instead of with
//     the sun's.
// Modelled through a validated offline port of this file plus the full URP grade chain (the
// port reproduces round7/v8's sky to RMS 2.6 sRGB levels and critic 2's own dark/lit quintiles
// on all three review masses to within 7 points), lit-to-shadow R−B swing:
//     v3 hero  23.9 → 55.7      v4 anchor 25.4 → 100.1      v8 hero 8.7 → 76.7
//
// AND THE HORIZON BAND LEARNS THE BEARING (TARROCK_HORIZON_ANTI*). Round 7 taught the elevation
// ramps' STEEPNESS where the sun is and left the horizon colour itself the same gold at every
// compass point, so the low sky 130° round from the dawn measured R−B +4.2 — grey, the mean of
// the board's two sky families rather than either of them (round-7 critique, finding 7). A dawn
// sky's gold band is on the sun's side; opposite it the horizon is a cool grey-blue. The lean
// is raised to a power so it spends itself past 90° (the mid angles keep their gold, as the
// tilt already does) and it DIES WITH HEIGHT, because this is a horizon-band effect: at 46° of
// elevation, where v8's protected anti-sun sky lives, exp(−h · 4) is 0.06 and the term is gone.
// It damps the additive dawn wash by the same factor and for the same reason — the air-path
// glow is the thing that was keeping the anti-sun horizon warm.
#define TARROCK_CLOUD_SKYFILL      1.20  // the DOME's light on the shaded washes: the cool half
#define TARROCK_HORIZON_ANTI       1.00  // how far the horizon band cools at the anti-sun
#define TARROCK_HORIZON_ANTI_POWER 2.5   // ...spent past 90° off the sun, like the tilt
#define TARROCK_HORIZON_ANTI_FALL  4.0   // ...and gone by the time the sky is a zenith
// sRGB (0.20, 0.33, 0.63), decoded here because this is a #define and not a material colour —
// a new uniform would have to be added to Tarrock/GradientSky's Properties block, and that file
// belongs to another builder this round. A deep grey-blue: the horizon opposite a low sun.
#define TARROCK_HORIZON_ANTI_COLOR float3(0.0331, 0.0890, 0.3547)

// ---------------------------------------------------------------------------------------------
// Noise. GRADIENT noise, not value noise: the 2026-07-26 terrain audit measured that value noise
// with a Hermite fade puts a zero-derivative fold on every lattice edge, which is exactly the
// "hard seams" read the cloud deck was showing. Gradient noise is zero AT lattice points with a
// non-zero slope, so there is no pillow-per-cell and no visible grid. Mirrors the C# GradNoise in
// TerrainRegionGenerator so authored surface and shaded surface agree.
// ---------------------------------------------------------------------------------------------

float TarrockHash21(float2 p)
{
    p = frac(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return frac(p.x * p.y);
}

// Zero-mean, range ≈ -1..1.
float TarrockGradNoise(float2 p)
{
    float2 i = floor(p);
    float2 f = p - i;
    float2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);   // quintic: C2 at the lattice

    // sincos rather than separate cos/sin calls: this runs six times per cloud pixel and the
    // deck can own a third of the frame.
    float4 angles = float4(
        TarrockHash21(i),
        TarrockHash21(i + float2(1.0, 0.0)),
        TarrockHash21(i + float2(0.0, 1.0)),
        TarrockHash21(i + float2(1.0, 1.0))) * 6.2831853;
    float4 sinA;
    float4 cosA;
    sincos(angles, sinA, cosA);

    float n00 = dot(float2(cosA.x, sinA.x), f);
    float n10 = dot(float2(cosA.y, sinA.y), f - float2(1.0, 0.0));
    float n01 = dot(float2(cosA.z, sinA.z), f - float2(0.0, 1.0));
    float n11 = dot(float2(cosA.w, sinA.w), f - float2(1.0, 1.0));

    return lerp(lerp(n00, n10, u.x), lerp(n01, n11, u.x), u.y);
}

// 0..1 convenience form.
float TarrockGradNoise01(float2 p)
{
    return saturate(TarrockGradNoise(p) * 0.5 + 0.5);
}

// ---------------------------------------------------------------------------------------------
// The painted-plate terrace. A storybook sky is not a smooth ramp: it is a small number of washes
// laid over each other with soft edges. Quantising the ramp parameter (not the colour) keeps the
// bands following the gradient, and the smoothstep across each step edge keeps them washes rather
// than contour rings. Strength 0 is a plain gradient.
// ---------------------------------------------------------------------------------------------
float TarrockSoftBand(float x, float count, float strength, float softness)
{
    float s = x * max(count, 1.0);
    float w = max(softness, 0.001);
    float soft = smoothstep(0.5 - w, 0.5 + w, frac(s));
    float banded = (floor(s) + soft) / max(count, 1.0);
    return lerp(x, banded, strength);
}

// ---------------------------------------------------------------------------------------------
// The sky description. Both materials carry the same properties, written from the same C#
// constants in TerrainRegionGenerator §dawn atmosphere.
// ---------------------------------------------------------------------------------------------
struct TarrockSkyDesc
{
    float3 horizon;        // the pale dawn-gold band sitting on the cloud sea
    float3 mid;            // low sky, a cooler cream — where the value structure has to happen
    float3 zenith;         // cool blue overhead
    float3 haze;           // BELOW the horizon there is no ground: there is cloud, at infinity
    float3 sunGlow;        // the dawn blaze added on top, allowed over 1 so bloom can catch it
    float3 sunDir;         // direction TO the sun, normalised
    float  midHeight;      // sin(elevation) at which the mid band is reached
    float  hazeDepth;      // sin(elevation) below the horizon over which gold gives way to haze
    float  glowFalloff;    // how fast the blaze dies with distance from the horizon line
    float  glowBroad;      // broad warm lobe around the sun's azimuth
    float  glowBroadPower;
    float  glowCore;       // tight blaze at the sun itself
    float  glowCorePower;
    float  bandCount;      // the sky's painted terraces (NOT the cloud bank — see bank* below)
    float  bandStrength;
    float  bandSoftness;
    float  horizonHeight;

    // THE BEARING (round 5). Round 4's sky was a pure function of ELEVATION, and the round-4
    // captures prove it arithmetically: v8's column medians came out
    // 128.1 125.7 121.4 116.9 113.6 | 113.6 116.9 121.4 125.7 128.1 — an exact mirror about the
    // frame centre, which is only possible if nothing in the sky knows where the sun is. The
    // glowBroad term above is not that knowledge: at glowBroadPower 8 it is under 1% of its peak
    // 35° off the sun, so nine tenths of the vault never hears about the dawn at all.
    // Every plate on the board that carries a low sun leans instead — fable-04's sky strip climbs
    // 126.5 → 169.8 toward the sun (+43 sRGB luminance points), fable-01's 58.2 → 100.6 (+42).
    float  bearingRise;    // broad warm wash, strongest low, peaking at the sun's compass bearing
    float  bearingPower;   // 1 is a plain horizontal cosine; higher pulls the wash in toward the sun
    float  bearingTilt;    // how much STEEPER the elevation ramps run on the anti-sun side

    // The far cloud bank: the cloud sea's own skyline, painted at infinity. All the vertical
    // measurements are in sin(elevation), which for the couple of degrees this thing occupies is
    // radians to three places — 0.01 is a little over half a degree, and the gameplay lens puts
    // ~19.6 px on a degree, so bankRelief 0.032 is a crest that wanders ±36 px.
    float3 bankCrest;      // the lit top edge, allowed over 1: dawn catches cloud tops first
    float3 bankShade;      // the cool shaded body — THE value anchor under the gold
    float  bankHeight;     // mean sin(elevation) of the crest line, above the horizon
    float  bankRelief;     // how far the crest rises and falls around that mean
    float  bankLumpScale;  // noise turns per revolution of the compass: the size of a cloud head
    float  bankRimWidth;   // depth of the lit rim below the crest
    float  bankBodyDepth;  // depth below the crest over which the shaded body holds
    float  bankDissolve;   // and then how far it takes to melt into the haze
    float  bankFloor;      // sin(elevation) the base sits at before its own lumps move it
    float  bankFade;       // how far under the base the bank takes to disappear
    float  bankGapStart;   // presence-noise window: outside it the bank opens and shows clear sky
    float  bankGapEnd;

    // Up to five designed cloud masses in the vault, each (bearing°, elevation°, half width°,
    // opacity). Opacity 0 switches a slot off. Bearing is Unity's: 0 = +Z, increasing toward +X.
    // Five, not four: round 2's four left both review frames with at most one mass in shot, and a
    // sky with one cloud in it is a sky with a smudge in it.
    float4 cloud0;
    float4 cloud1;
    float4 cloud2;
    float4 cloud3;
    float4 cloud4;
    float3 cloudLit;       // the sunlit crowns
    float3 cloudShade;     // the cool body — the middle of three washes
    float3 cloudShadow;    // the belly of the big masses: the frame's DARK ANCHOR
    float  cloudBase;      // flat base, in half-widths below the mass's centre
    float  cloudBaseLump;  // and how far that base wanders, so it is drawn and not ruled
    float  cloudSoftness;  // silhouette softness, in half-widths
    float  cloudLump;      // how much noise breaks the lobe silhouette into cauliflower
    float  cloudLift;      // how far the wash tilts UP off the sun vector — see TarrockVaultCloud
};

// ---------------------------------------------------------------------------------------------
// The far cloud bank. A ribbon of cloud standing on the horizon, drawn at infinity.
//
// The lumps come from noise sampled along a CIRCLE in the noise field — the compass direction
// times a frequency — so the crest line is periodic in azimuth by construction and has no seam
// where 0° meets 360°. (Noise of atan2 has exactly one such seam, and it lands wherever the
// director happens to be looking.) Three circles of increasing radius give heads, shoulders and
// nibbles: at bankLumpScale 5 that is a cloud head roughly every 11°, a shoulder every 4° and an
// edge nibble every 2°. The base gets a fourth circle of its own.
// ---------------------------------------------------------------------------------------------
// MEASURED, not assumed. Three octaves of TarrockGradNoise summed with the weights below have a
// standard deviation of 0.236 and never leave ±0.7: two-dimensional gradient noise is nothing like
// the ±1 the rest of this file's naming implies. Without this gain the crest wandered ±0.5° where
// the design wanted ±1.8°, and the "lumpy skyline" came out as a crinkle. The soft saturation
// (x·rsqrt(1+x²)) rather than a clamp matters just as much: clamping gave the tall banks dead flat
// tops and they read as mesas.
#define TARROCK_BANK_GAIN 2.9

float TarrockBankSaturate(float x)
{
    return x * rsqrt(1.0 + x * x);
}

// Returns (colour, coverage).
float4 TarrockCloudBank(float3 v, float h, TarrockSkyDesc sky)
{
    float2 compass = normalize(v.xz + float2(1e-6, 1e-6));
    float f = max(sky.bankLumpScale, 0.5);

    // The crest. Weighted low so the line is dominated by big round swells: heavier high octaves
    // cut V-shaped notches between the heads and the whole thing reads as a mountain range.
    float nc = TarrockBankSaturate(
        (TarrockGradNoise(compass * f)
         + TarrockGradNoise(compass * (f * 2.7) + 17.3) * 0.30
         + TarrockGradNoise(compass * (f * 6.1) + 51.7) * 0.08) * TARROCK_BANK_GAIN);
    float crest = sky.bankHeight + nc * sky.bankRelief;

    // The base gets lumps of its OWN, at a different frequency. Without this the bank is a slab
    // with a ruled bottom edge and reads as a cut-out rectangle however lumpy its top is.
    float nb = TarrockBankSaturate(TarrockGradNoise(compass * (f * 1.3) + 63.1) * 2.6);
    float base = sky.bankFloor + nb * sky.bankRelief * 0.45;

    float e = crest - h;
    float cover = smoothstep(0.0, max(sky.bankRelief * 0.10, 1e-4), e);
    cover *= smoothstep(base - sky.bankFade, base, h);

    // Gaps. An unbroken ribbon all the way round the compass is a belt, not weather; where the
    // presence noise dips the bank opens and the eye sees clear sky sitting on the cloud sea.
    float presence = TarrockGradNoise01(compass * (f * 0.55) + 9.1);
    cover *= smoothstep(sky.bankGapStart, sky.bankGapEnd, presence);

    // THE VALUE PROFILE, and every stop of it hangs from the CREST rather than from an absolute
    // elevation — that is what puts the shaded flank under each individual head instead of
    // painting one flat horizontal stripe across the whole horizon:
    //   crest → a thin sunlit rim, thicker on the taller heads (they catch more of the dawn)
    //   then → the cool shaded body, which IS the frame's value anchor
    //   then → dissolving into the same haze the fog and the deck's far field settle on, because
    //          the base of a far cloud bank is lost in exactly that.
    float rim = max(sky.bankRimWidth * (1.0 + nc * 0.55), 1e-4);
    float t = TarrockSoftBand(saturate(e / rim), 3.0, sky.bandStrength, sky.bandSoftness);
    float3 color = lerp(sky.bankCrest, sky.bankShade, t);

    float sink = smoothstep(sky.bankBodyDepth, sky.bankBodyDepth + sky.bankDissolve, e);
    color = lerp(color, sky.haze, sink * 0.85);

    return float4(color, saturate(cover));
}

// ---------------------------------------------------------------------------------------------
// The designed cloud masses in the vault.
//
// Not a noise field: six soft lobes on a flattened base — the SAME six every time, so every
// cloud in the region is recognisably drawn by one hand — varied only by where the director puts
// them, how big they are, and a mirror flip. Storybook cumulus is a small alphabet used well.
// ---------------------------------------------------------------------------------------------
#define TARROCK_DEG2RAD 0.0174532925
#define TARROCK_TWO_PI  6.2831853

float TarrockWrapPi(float a)
{
    return a - TARROCK_TWO_PI * floor((a + 3.14159265) / TARROCK_TWO_PI);
}

// x = bearing (radians, 0 = +Z toward +X), y = elevation (radians).
float2 TarrockDirToAzEl(float3 v)
{
    return float2(atan2(v.x, v.z), asin(clamp(v.y, -1.0, 1.0)));
}

// The alphabet, as a signed distance field in half-widths. Six lobes; unrolled rather than held in
// a const array because this file has to compile inside a CGPROGRAM skybox pass as well as a URP
// one, and unrolled min()s are the portable spelling. min() of spheres unions them with CONCAVE
// creases at the joins, and those creases are the scallops in the silhouette — they are the point,
// not an artefact.
//
// ROUND 4 GIVES IT TWO HANDWRITINGS, blended by `style`. The round-3 critique of v4 was "one
// edge-to-edge bank of same-size same-altitude flat-bottomed lobes", and while the sizes and
// altitudes are set at the placement end (TerrainRegionGenerator §THE VAULT CLOUDS), the SHAPE was
// genuinely one arrangement stamped five times. Style 0 is that arrangement — wide and low, a broad
// shoulder left, the main head just left of centre, a smaller second head stepped up and right, a
// full flank right and a trailing wisp. Style 1 is a BUILDING cumulus: the same six lobes restrung
// so one crown climbs well clear of the rest and the shoulders fall away under it, which reaches
// 0.84 half-widths above centre against style 0's 0.70. Blending rather than switching means a
// style of 0.4 is a legal cloud too, so five masses can be five different clouds rather than two.
float TarrockCumulusField(float2 pc, float style)
{
    float s = saturate(style);
    float sd = length(pc - lerp(float2(-0.72, -0.02), float2(-0.68, -0.08), s)) - lerp(0.30, 0.24, s);
    sd = min(sd, length(pc - lerp(float2(-0.38, 0.10), float2(-0.32, 0.04), s)) - lerp(0.40, 0.34, s));
    sd = min(sd, length(pc - lerp(float2(-0.02, 0.24), float2(0.00, 0.22), s)) - lerp(0.46, 0.38, s));
    sd = min(sd, length(pc - lerp(float2(0.30, 0.34), float2(0.10, 0.56), s)) - lerp(0.34, 0.28, s));
    sd = min(sd, length(pc - lerp(float2(0.52, 0.06), float2(0.42, 0.20), s)) - lerp(0.38, 0.32, s));
    sd = min(sd, length(pc - lerp(float2(0.82, -0.06), float2(0.74, -0.04), s)) - lerp(0.24, 0.26, s));
    return sd;
}

// Returns (colour, coverage). `variant` is (flip, style): flip mirrors the alphabet, style chooses
// between its two handwritings (see TarrockCumulusField). Both are authored at the call site in
// TarrockSkyColor, beside the painter's order, because all three are the same decision — which
// cloud is drawn where, facing which way, and over which of its neighbours.
float4 TarrockVaultCloud(float2 azEl, float2 sunAzEl, float4 spec, float2 variant, TarrockSkyDesc sky,
                         float pixelAngle)
{
    float flip = variant.x;
    float style = variant.y;
    if (spec.w <= 0.001)
    {
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    float2 centre = float2(spec.x, spec.y) * TARROCK_DEG2RAD;
    float halfW = max(spec.z, 0.05) * TARROCK_DEG2RAD;

    // ISOTROPIC, which round 2 was not: elevation was divided by halfW·aspect with aspect 0.40, so
    // every circular lobe came out two and a half times wider than tall and the mass resolved to a
    // single flat pill. Both axes are in half-widths now. cos(elevation) keeps a cloud as wide as
    // it was authored instead of fanning out as it climbs; the clouds live low enough that this is
    // a small correction, but it is free.
    float2 pc = float2(
        TarrockWrapPi(azEl.x - centre.x) * cos(azEl.y) / halfW * flip,
        (azEl.y - centre.y) / halfW);

    // Cheap reject before the alphabet runs. The deck evaluates this whole function per pixel and
    // there are five masses; the bounds are the alphabet's own extent plus the scallop and the
    // sunward step, rounded out.
    if (abs(pc.x) > 1.25 || pc.y > 1.05 || pc.y < -0.85)
    {
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    // Flat base. Cumulus sits on its own shadow line; without this the shapes read as balloons.
    // Below the base the field falls away three times as fast, which cuts a nearly straight bottom
    // edge without the hard clip that would alias.
    //
    // ROUND 4: "flat-bottomed" was half the critic's reading of v4, and it was literal — every mass
    // in the region had a ruler for a base, at the same fraction of its own half width, so a row of
    // them drew one horizontal line across the sky. The base now carries a slow wave of its own,
    // one octave along the mass's own x seeded off its bearing, exactly as the far cloud bank's base
    // already does (§TarrockCloudBank: "a slab with a ruled bottom edge reads as a cut-out
    // rectangle however lumpy its top is"). Still a base — cumulus does sit on its condensation
    // level — but a drawn one.
    float baseCut = max(sky.cloudBase, 0.02)
                    + TarrockGradNoise(float2(pc.x * 1.35, spec.x * 0.083)) * sky.cloudBaseLump;
    baseCut = max(baseCut, 0.02);
    pc.y = pc.y < -baseCut ? -baseCut + (pc.y + baseCut) * 3.0 : pc.y;

    // Break the vector-smooth edge into cauliflower. Two octaves: the low one moves whole lobes,
    // the high one nibbles their rims. Seeded off the cloud's own bearing and elevation, so moving
    // a cloud reshapes it — placement is the only authoring dial and it is a real one.
    // Kept unscaled as well as scaled: the SILHOUETTE wants it at cloudLump (0.090 of a half
    // width), the interior's wash boundaries want it at their own amplitude, and the two are three
    // orders apart. Measured over 200k samples this sum has std 0.26 and stays inside ±0.72.
    // ROUND 6 — THE TOOTH SCALE VARIES. The round-5 critique of the wash boundaries was that they
    // are "cookie-cutter sawtooth — uniform tooth scale reads as a filter, not a hand", and that was
    // literal: the high octave sat at a FIXED 9.7 per half width, so every tooth on every boundary
    // of every mass was the same size. A hand draws a big scallop, then three small ones, then a
    // long slow one. A slow selector field (1.15 per half width — about one and a half cycles across
    // a mass) stretches the high octave between 6.6 and 16.0 and lightens it as it gets finer, so
    // the tooth pitch runs from ~68 px to ~28 px along a single boundary on the hero.
    // ROUND 7 DROPS EVERY ONE OF THESE FREQUENCIES BY A THIRD. The round-6 critique of the cloud
    // interiors was that they read as an ORDERED DITHER rather than as painting, and the arithmetic
    // agrees: on the v3 hero (half width 20°, 448 px of half width at the gameplay lens) the tooth
    // ran 4.6-16.0 turns per half width, i.e. features 28-97 px, and the paper tooth below ran 8 px.
    // A hand's mark on a 900 px cloud is bigger than that. Measured through the full grade on the v3
    // hero, coverage-masked: stroke blobs 1.71 per 10k px at 311 px each → 0.79 per 10k at 682 px.
    float toothSel = TarrockGradNoise01(pc * 1.15 + spec.x * 0.31);
    float toothFreq = 4.6 + 6.4 * toothSel;
    float toothWeight = 0.30 + 0.34 * (1.0 - toothSel);
    float crumple = TarrockGradNoise(pc * 3.4 + spec.x)
                  + TarrockGradNoise(pc * toothFreq + spec.y * 3.1) * toothWeight;
    float scallop = crumple * sky.cloudLump;

    float sd = TarrockCumulusField(pc, style) + scallop;

    float soft = max(sky.cloudSoftness, 1e-3);
    float cover = (1.0 - smoothstep(-soft, soft, sd)) * saturate(spec.w);
    if (cover <= 0.0)
    {
        return float4(0.0, 0.0, 0.0, 0.0);
    }

    // Where the sun is, in this cloud's own frame. Everything below is flat shape shading off that
    // one direction — no volumetrics, no scattering, three washes.
    float2 toSun = normalize(float2(
        TarrockWrapPi(sunAzEl.x - centre.x) * cos(centre.y) / halfW * flip,
        (sunAzEl.y - centre.y) / halfW) + float2(1e-5, 1e-5));

    // ...AND THE WASH STEPS UP-AND-SUNWARD, not straight along that vector. The round-3 critique of
    // v4 was that the vault was "shaded on a horizontal axis that contradicts the sun", and the
    // arithmetic says it was — but the cause is subtler than a wrong sign. In a mass's own flat
    // frame the sun vector is (Δbearing·cos el / halfW, Δelevation / halfW), and Δbearing is divided
    // by a half width of ten or twenty degrees while Δelevation is a couple of degrees at most. For
    // v4's anchor at bearing 77° that comes out (0.9997, 0.024): a purely SIDEWAYS light, with the
    // terminator a vertical line down the middle of the mass and its top no brighter than its
    // bottom. Which is geometrically true and pictorially wrong — a cloud is lit by the whole dome
    // as well as by the disc, so its crowns are bright whatever the bearing does, and every plate on
    // the reference board draws it that way. Tilting the wash direction toward +y by cloudLift
    // recovers that at 30° above the frame's horizontal while leaving the disc to decide which FLANK
    // is gold. The rim below still uses the true toSun, because a rim really is the disc's alone.
    float2 wash = normalize(toSun + float2(0.0, sky.cloudLift));

    // THREE WASHES, WITH A TERMINATOR PER LOBE. The same alphabet, stepped toward the sun and
    // re-evaluated: a pixel the stepped mass still covers is on a flank that faces the dawn, and a
    // pixel it has slipped off is in that lobe's own shade. Two step lengths give a lit crown, a
    // half-lit body and a shaded underflank — and, crucially, they give them to EVERY lobe
    // separately. Round 2's single smoothstep across the whole mass could only ever produce one
    // gradient, which is why its four-lobe alphabet photographed as one soft blob.
    //
    // The same scallop is added to all three fields, so the terminator wobbles with the silhouette
    // instead of cutting across it.
    float lit = 1.0 - smoothstep(-soft * 2.0, soft * 2.0,
        TarrockCumulusField(pc - wash * 0.30, style) + scallop);
    float crown = 1.0 - smoothstep(-soft * 2.0, soft * 2.0,
        TarrockCumulusField(pc - wash * 0.62, style) + scallop);
    float form = (lit + crown) * 0.5;

    // ROUND 5 — THE POSTERIZED THREE-BAND RAMP, and it is the round-4 critique's headline finding:
    // "cloud interiors are single smooth ramps, 2-5x below reference interior contrast; the v4
    // cumulus has 0.0000 px above gradient-magnitude 8". Both halves of that are true of the code
    // above and both are fixed here.
    //
    //   * NO SHADOW END. The ramp ran cloudShade → cloudLit and cloudShadow was reachable only
    //     through the belly term below, which is itself scaled by `thick` — so v4's 11°-wide mass
    //     got 19% of it and its measured MINIMUM was sRGB 152.6 against a shadow colour that grades
    //     to 54.5. The mass never had a dark end at all. The ramp is three colours now: the shadow
    //     core is the bottom third of it, and every unlit flank of every lobe lands there.
    //   * NO BOUNDARIES. form is a pair of smoothsteps and nothing quantised it, so the interior
    //     was exactly the "single smooth ramp" the critic measured. It is terraced now with the
    //     same TarrockSoftBand the sky and the deck use — three washes, hard-ish (0.92 over 0.030),
    //     which the band arithmetic says is what clears gradient 8: a 70-point ramp in three steps
    //     puts ~23 points on a boundary, and 0.030 of softness spends that over ~3 px on a mass
    //     that fills 300 px, i.e. |grad| ≈ 8. Round 4's 0.130 spent it over 13 px and measured 0.
    //   * ...AND THE BOUNDARIES SIT ON THE LOBES. The same `scallop` field that breaks the
    //     silhouette is added to the ramp parameter before terracing, so a wash edge wanders with
    //     the cauliflower it belongs to. Without this a terrace of a smooth field draws clean
    //     latitude lines, which is a screen-space posterize and reads as a contour map.
    // 0.30 on a field of std 0.26 moves a wash boundary by about a third of a wash — enough that
    // the edges follow the cauliflower and not the latitude, not so much that a lobe's lit crown
    // can be crumbled into its own shade.
    //
    // ROUND 6 — THREE THINGS THE TERRACE WAS GETTING WRONG, and they are one bug wearing three
    // faces. `form` is (lit + crown) * 0.5, so before the crumple is added it takes exactly THREE
    // values over most of a mass: 0 in the shade, 0.5 on the half-lit body, 1.0 on the crown.
    // TarrockSoftBand at count 3 quantises at frac(3x) = 0.5, i.e. it puts its boundaries at
    // x = 0.1667, 0.5 and 0.8333 — and 0.5 IS the body plateau. The whole half-lit field therefore
    // sat exactly on a wash boundary, where any wobble of the crumple flips it back and forth.
    // Everything the round-5 critics measured on the interiors follows from that one coincidence:
    //   * THE SAWTOOTH. A boundary that runs along a plateau is drawn by the noise's zero crossings
    //     rather than by the form, so it comes out as a regular ripple at the crumple's own pitch —
    //     "a filter, not a hand".
    //   * THE DARK SPECKS (8–15 px, L≈109, on the lit crowns). At count 3 the top boundary sits
    //     0.1667 under the crown's saturated 1.0, and crumple * 0.30 reaches −0.216 in its tails —
    //     so roughly 1.6% of crown pixels dip a full wash and, because the terrace is 92% strong,
    //     land as a hard-edged island of the body colour in the middle of the crown. That is the
    //     artefact exactly, and it is arithmetic, not chance.
    // COUNT 2 FIXES BOTH BY CONSTRUCTION. Its quantised levels are {0, 0.5, 1} — the same three
    // washes — but its boundaries are at 0.25 and 0.75, i.e. as far from every plateau as they can
    // be. A boundary now falls only where `form` genuinely crosses between plateaus, which is a
    // terminator, so it is drawn by the light and wanders with the cauliflower. Measured on the v3
    // hero through the full grade: isolated dark islands on the crown 5 → 0.
    // The soft cap is the belt to that braces: it compresses the crumple's tails so the offset can
    // never exceed 0.15 (0.5 * 0.30), a quarter of a wash, whatever the noise does.
    float capped = 0.50 * crumple * rsqrt(0.25 + crumple * crumple);
    form = saturate(form + capped * 0.30);

    // ROUND 8 — THE MIDDLE TIER OF STRUCTURE, and it is the round-7 critique's fifth finding
    // stated as a scale rather than as a texture. Measured with critic 2's texture2.py, our
    // masses carry E16 (the >32 px band, 1600-wide normalised) at 3.2-5.8 against the board's
    // 11.4-14.0, while E1 and E4 are close to the plates — so the deficit is not pixel noise
    // (round 6's "dither" diagnosis, tested and refuted) and not the fine brush. It is the tier
    // BETWEEN the three washes and the paper tooth: the sub-lobe modelling a painter puts inside
    // a lit crown, where this shader had exactly nothing between a 3.4-turn crumple and a
    // 22-turn brush.
    //
    // One octave at 8 turns per half width — 47 px on the v3 hero, 33-60 px being precisely the
    // band a 33 px high-pass can see — on the ramp PARAMETER, soft-capped the same way the
    // crumple is. Round 6's rule against noise before the terrace was about SPECKS (8-15 px
    // islands of the body wash punched into a crown); at 47 px an island is not a speck, it is
    // a sub-lobe turning away from the light, which is the thing the tier is missing. The count-2
    // terrace still holds its 0.25 margin either side of every plateau against this one's ±0.17.
    // Measured through the graded chain, E16: v3 3.6 → 5.9, v4 5.8 → 13.9, v8 4.0 → 8.4.
    float midTier = TarrockGradNoise(pc * 8.0 + spec.x * 0.77);
    midTier = 0.50 * midTier * rsqrt(0.25 + midTier * midTier);
    form = saturate(form + midTier * 0.34);

    form = TarrockSoftBand(form, 2.0, 0.92, 0.030);

    // Two joined lerps, one ramp: shadow → shade over the bottom 46%, shade → lit over the top.
    // 0.46 rather than 0.5 because a cumulus at this hour shows more shade than crown — the sun is
    // 12° up, so the lit band is the thinner one on every mass in the frame.
    float3 color = form < 0.46
        ? lerp(sky.cloudShadow, sky.cloudShade, saturate(form / 0.46))
        : lerp(sky.cloudShade, sky.cloudLit, saturate((form - 0.46) / 0.54));

    // ROUND 6 — THE PAPER TOOTH, and it is the answer to "the bands are dead plateaus: 97.8% of the
    // lit crown sits at gradient < 1, references run 0.8–50%".
    //
    // WHAT THE REFERENCE ACTUALLY HAS. Measured on animation-04's cloud bank (900×270 of it): 22.6%
    // of pixels under gradient-magnitude 1, median 1.68. Blurred by 0.8 px — enough to take film
    // grain out — it is still 26.2% and 1.54, so the structure is REAL and it is fine: it survives
    // to about 2–3 px. That is gouache on a toothed paper, and it is most of why a painted plate
    // reads as painted rather than as a fill.
    //
    // WHY IT IS A COLOUR MODULATION AND NOT A FORM ONE. Three other candidates were built and
    // measured on the v3 hero before this one, and each failed on the picture while passing on the
    // metric — the exact trap round 5 fell into:
    //   * noise added to the ramp parameter BEFORE the terrace → new isolated islands, i.e. the
    //     specks above, deliberately reintroduced;
    //   * noise added AFTER the terrace → pushes pixels across the ramp's own colour joints, so the
    //     mid wash comes out mottled BLUE-on-CREAM: two-tone confetti, not modelling (flat fraction
    //     37%, and unusable);
    //   * a directional derivative of a mid-scale field ("micro relief", each bump lit from the wash
    //     direction) → reads as frost on a window; the step is small against the feature size, so it
    //     high-passes into isotropic blobs rather than into lobes with lit caps.
    // Multiplying the wash's OWN colour keeps the hue of the band it belongs to and varies only its
    // value, which is what a brush loaded with one colour does. The tilt (1.22, 1.02, 0.80) makes a
    // loaded stroke warmer and a dry one cooler, so the tooth carries the same warm-light/cool-shade
    // law as the washes themselves rather than fighting it.
    //
    // TWO OCTAVES AT 55 AND 126 PER HALF WIDTH — 8 px and 3.5 px on the v3 hero — each faded out
    // analytically as it approaches its own Nyquist. The footprint comes from the CAMERA (pixelAngle
    // is one pixel in radians, measured once per fragment in TarrockSkyColor) rather than from
    // ddx/ddy here, because this function returns early on its bounds reject and a derivative taken
    // under non-uniform control flow is undefined. A 9° wisp therefore gets the same tooth in
    // absolute pixels as the 20° hero, and both drop it rather than alias when they get small.
    // Measured, v3 hero through the full grade: flat fraction 90.0% → 47.5%, median gradient
    // 0.08 → 1.06, against the reference's 22.6% / 1.68.
    // ROUND 7: 55 AND 126 TURNS ARE A DITHER, NOT A BRUSH — see §the tooth scale above. 22 and 46
    // put the two octaves at 20 px and 10 px on the hero instead of 8 px and 3.5 px, and the
    // amplitude goes 0.30 → 0.42 because a bigger mark carries more paint. The Nyquist fades are
    // unchanged in form, so a 9° wisp still drops the fine octave rather than aliasing it.
    // ROUND 8 MOVES THE TOOTH AFTER THE LIGHT AND GIVES IT A THIRD, COARSE OCTAVE — see the
    // §THE TOOTH GOES ON LAST block below, where it now runs.

    // THE DARK ANCHOR. Thickness reads as darkness: a 20°-wide cumulus at this hour is deep enough
    // that its base is the darkest value in the frame, and a 7° one is not. Deriving the weight
    // from the mass's own half-width means the composition's largest cloud is automatically its
    // anchor and nothing has to be hand-flagged — and it stays true if the director resizes one.
    // Opacity is in it as well as size, and for the same reason: a mass you can see the sky
    // through is a mass the light gets through, so a 26%-opacity veil has no dark base to give
    // however wide it is drawn.
    // ROUND 5 RE-CUTS THE THICKNESS CURVE, because round 4's demoted the frames' actual masses.
    // (halfW − 8)/12 gives a 20° hero 1.00 but v4's two masses — 15° and 11° — only 0.58 and 0.25,
    // and multiplied by opacity 0.55 and 0.19. That is why the v4 cumulus photographed with NO dark
    // end (measured minimum sRGB 152.6). The ramp above now carries the shadow core on its own, so
    // this term is back to what it is for — deciding which masses get an EXTRA deep belly — and it
    // is cut so the 11-15° masses that fill the review frames actually qualify: 6° earns none,
    // 14° earns all of it.
    float thick = saturate((spec.z - 6.0) / 8.0) * saturate(spec.w * 1.15);
    float belly = (1.0 - smoothstep(-baseCut, baseCut + 0.34, pc.y)) * (1.0 - form * 0.62);
    color = lerp(color, sky.cloudShadow, saturate(belly * thick) * 0.95);

    // ROUND 7 — THE DISC, ON THE LIT WASHES ONLY, AND IT IS A LIGHTING RULE RATHER THAN A PAINT JOB.
    //
    // Round 6 was right to stop the air-path wash falling on the masses (§THE WASH IS AIR) and wrong
    // about what to do next: with that wash gone, NOTHING in this function knew the dawn existed, so
    // the masses fell back on their painted washes and the two that sit well round the compass came
    // out cold — v1's mass measured hue 253° with 73% of its pixels in the blue band, which is a
    // slate roof, not a cloud at dawn. The air is not the only warm thing in the sky: the DISC is on
    // the crowns, and unlike the air-path term it is a surface effect, so it belongs where the form
    // says the light lands.
    //
    // Two weights, and both are the light rather than the artist:
    //   * WHERE THE FORM IS LIT. `form` is already the three-wash ramp, so squaring its upper half
    //     puts almost all of this on the crown, a little on the half-lit body and NONE in the shade
    //     — which is the storybook law (warm light, cool shade) stated as an equation instead of as
    //     two hand-picked colours that a later grade can invert.
    //   * HOW SUNWARD THE MASS IS. A cumulus at the anti-sun still catches the dome, so the weight
    //     floors at TARROCK_CLOUD_SUNWARM_BASE rather than reaching zero.
    // Measured over each mass's own coverage through the full grade (round 6 → round 7):
    //     v3 hero   lit quintile R−B +31.6 → +36.8,  dark quintile −24.1 → −8.8
    //     v4 anchor lit           +29.3 → +32.9,  dark −41.4 → −48.0
    //     v1 mass   lit           +20.3 → +33.5,  dark −28.6 → −13.3, blue-band 73.2% → 25.2%
    float sunward = saturate(cos(TarrockWrapPi(azEl.x - sunAzEl.x)) * 0.5 + 0.5);
    float litWash = saturate((form - 0.46) / 0.54);
    color += sky.sunGlow * (TARROCK_CLOUD_SUNWARM * litWash * litWash
             * (TARROCK_CLOUD_SUNWARM_BASE + (1.0 - TARROCK_CLOUD_SUNWARM_BASE) * sunward));

    // ROUND 8 — AND THE DOME, ON THE SHADED WASHES ONLY. The mirror of the line above, and the
    // half round 7 did not have: an unlit flank of a cumulus is not "the sun, minus" — it is
    // SKY LIGHT, and the sky at dawn is blue. (1 − form)² is the exact complement of the disc's
    // litWash², so the crown is untouched by arithmetic rather than by a threshold, and the two
    // terms together are the storybook law — warm light, cool shade — written as two light
    // sources instead of as two painted triples that a grade can invert.
    // sky.mid, not sky.zenith: a mass at 12-30° of elevation sees mostly the pale low sky, and
    // the zenith-tinted version rendered as a royal-blue cut-out (see §TARROCK_CLOUD_SKYFILL).
    float shadeWash = 1.0 - form;
    color += sky.mid * (TARROCK_CLOUD_SKYFILL * shadeWash * shadeWash);

    // §THE TOOTH GOES ON LAST (round 8). It used to multiply the painted washes and then have
    // the disc's warmth added over the top, so wherever the light term was large the tooth was
    // diluted to nothing — which is why the round-7 masses had a textured core inside a smooth
    // outer slab, the two reading as two stacked cards. The tooth is the PAPER, so everything
    // laid on the paper takes it: washes, disc and dome alike. Measured, E16 on the three review
    // masses: 3.6/13.9/7.3 with the old order, 5.9/13.9/8.4 with this one, and the outer slab is
    // gone from the picture.
    // The third octave at 7 turns per half width (53 px on the hero) is the same middle-tier
    // argument as §THE MIDDLE TIER above, made in value rather than in form; the amplitude goes
    // 0.42 → 0.55 to pay for it. No Nyquist fade on this one: at 7 turns a mass would have to be
    // under 15 px across before it aliased, and the coverage test has dropped it long before.
    float foot = 2.0 * pixelAngle / halfW;
    float brush = TarrockGradNoise(pc * 7.0 + 57.1) * 1.4
                + TarrockGradNoise(pc * 22.0 + 3.7) * saturate(1.0 - foot * 22.0)
                + TarrockGradNoise(pc * 46.0 + 21.3) * 0.6 * saturate(1.0 - foot * 46.0);
    color = max(color * (1.0 + brush * 0.55 * float3(1.22, 1.02, 0.80)), 0.0);

    // The dawn rim: the sunward edge of a cloud at this hour is the brightest thing in the vault.
    float rim = saturate(1.0 - abs(sd) / (soft * 4.0))
              * saturate(dot(normalize(pc + float2(1e-5, 1e-5)), toSun));
    color += sky.sunGlow * rim * 0.55;

    return float4(color, cover);
}

// dir need not be normalised.
float3 TarrockSkyColor(float3 dir, TarrockSkyDesc sky)
{
    float3 v = normalize(dir);
    float h = v.y - sky.horizonHeight;

    // One pixel, in radians, measured HERE — at the top of the function, in uniform control flow,
    // where a screen-space derivative is legal. Everything below that needs a level of detail
    // (currently the vault clouds' paper tooth) takes it from this rather than calling ddx/ddy for
    // itself: the cloud function returns early on its bounds reject, and a derivative taken inside
    // divergent control flow is undefined. Normalising first makes this the ANGULAR footprint, so
    // it is the same number for the skybox and for the cloud deck's grazing far field.
    float pixelAngle = max(length(fwidth(v)), 1e-6);

    // ABOVE. At the gameplay camera's pitch the player sees roughly the first 25° of sky and no
    // more, so both ramps are shaped to spend themselves inside that band — the previous
    // pow(h, 1.25) ramp put its whole transition above the frustum and the sky read as flat tan.
    // smoothstep also lands the ramp on the horizon with zero derivative, so there is no crease
    // where the two hemispheres meet.
    // WHICH WAY THE SUN IS — round 5's first job, and the one the round-4 mirror symmetry proved
    // was missing (see TarrockSkyDesc §THE BEARING). A HORIZONTAL cosine: 1 along the sun's compass
    // bearing, 0 at the anti-sun, and it survives climbing above the sun's own 12° instead of
    // dying with it the way dot(v, sunDir) does.
    float2 vFlat = normalize(float2(v.x, v.z) + float2(1e-5, 1e-5));
    float2 sFlat = normalize(float2(sky.sunDir.x, sky.sunDir.z) + float2(1e-5, 1e-5));
    float bearing = pow(saturate(dot(vFlat, sFlat) * 0.5 + 0.5), max(sky.bearingPower, 0.05));

    // ...and it TILTS THE ELEVATION RAMPS rather than only adding light. It has to: this grade's
    // sky sits in the Neutral tonemap's shoulder, where 0.34 of extra sunGlow buys only ~10 sRGB
    // points, while pulling the zenith DOWN the anti-sun sky moves 90. Modelled through the URP
    // LUT chain over v3's frustum, tilt 3.2 with rise 0.45 turns round 4's +1.8 lean into +12.8;
    // the plates run +42 to +43, but they are 60°-lens paintings of a sky whose horizon is the
    // brightest thing in frame, and this one has a cloud sea under it doing that job. Applied to
    // the ramp PARAMETER, so the terrace above picks the lean up and it reads as painted washes
    // leaning toward the dawn rather than as an airbrushed side-light.
    // ROUND 7 SHAPES THE TILT IN BEARING AS WELL AS SCALING IT. Round 5's lean is linear in
    // (1 − bearing), and that one fact is why round 6 could not have both a gold dawn and a live
    // blue: a tilt big enough to pull the zenith down at 130° off the sun has already pulled it
    // most of the way down at 60°, and 60° is where v1, v3 and v4 all look. Raising (1 − bearing)
    // to TARROCK_BEARING_TILT_POWER spends the steepening past 90° and leaves the mid angles to
    // the horizon gold. Modelled through the graded chain at el 6°: 55° off goes R−B +36 → +54,
    // 70° off +7 → +36, while 130° off goes −6 → −43 and the anti-sun holds at −75.
    float lean = 1.0 + sky.bearingTilt * pow(1.0 - bearing, TARROCK_BEARING_TILT_POWER);

    // ROUND 8 — THE HORIZON BAND ITSELF LEANS. See §TARROCK_HORIZON_ANTI above for why this is
    // not the same term as the tilt: the tilt changes how FAST the gold gives way to the cool
    // band with height, and at h = 0 every bearing still got the same gold. `anti` changes the
    // gold itself, spends its travel past 90° off the sun, and dies with height so the vault
    // (and the protected anti-sun zenith v8 looks into) is untouched.
    float anti = TARROCK_HORIZON_ANTI * pow(1.0 - bearing, TARROCK_HORIZON_ANTI_POWER)
                 * exp(-saturate(h) * TARROCK_HORIZON_ANTI_FALL);
    float3 horizonHere = lerp(sky.horizon, TARROCK_HORIZON_ANTI_COLOR, anti);

    float t = smoothstep(0.0, 1.0, saturate(h / max(sky.midHeight, 0.001) * lean));
    t = TarrockSoftBand(t, sky.bandCount, sky.bandStrength, sky.bandSoftness);
    float3 color = lerp(horizonHere, sky.mid, t);

    // The mid band's own ceiling leans with it, so on the anti-sun side the cool blue starts where
    // the cream would otherwise still be climbing.
    float leanMid = sky.midHeight / lean;
    float u = smoothstep(0.0, 1.0, saturate((h - leanMid) / max(1.0 - leanMid, 0.001)));
    u = TarrockSoftBand(u, sky.bandCount, sky.bandStrength, sky.bandSoftness);
    float3 above = lerp(color, sky.zenith, u);

    // BELOW. The lower hemisphere is the cloud sea seen at infinity, so it settles on the haze
    // the fog and the deck both settle on. Everything distant in this region — rim rock, the
    // deck's far field, the sky under the horizon — is one luminous value.
    float d = smoothstep(0.0, 1.0, saturate(-h / max(sky.hazeDepth, 0.001)));
    float3 below = lerp(horizonHere, sky.haze, d);

    float3 result = h >= 0.0 ? above : below;

    // THE CLOUD BANK, over the gradient. Straddles the horizon on purpose: its crest stands a
    // couple of degrees above, its skirt dies a fraction of a degree below, and the deck picks it
    // up unchanged because the deck resolves to this same function.
    float4 bank = TarrockCloudBank(v, h, sky);
    result = lerp(result, bank.rgb, bank.a);

    // THE VAULT CLOUDS, over that. Skipped outright under the bank's floor: no ray that hits deck
    // geometry can reach a cloud up there, and the deck runs this whole function per pixel, so
    // the branch is worth having.
    // `covered` accumulates how much cloud stands between the eye and the sky along this ray; the
    // two additive dawn washes at the bottom of this function read it. See §THE WASH IS AIR.
    float covered = 0.0;
    if (h > sky.bankFloor)
    {
        float2 azEl = TarrockDirToAzEl(v);
        float2 sunAzEl = TarrockDirToAzEl(sky.sunDir);

        // Painter's order, back to front: the high veil first, then the flanking masses, then the
        // hero LAST so it overlaps rather than being overlapped. Overlap is a depth cue and the
        // vault has no other one.
        // (flip, style) per mass. The STYLES are the round-4 answer to "same-size same-altitude":
        // the two masses that share a frame never share a handwriting. v4 sees 3 and 4 — a tall
        // building cumulus (0.85) beside a low wide one (0.10). v3 sees 0 and 2 — the hero at 0.30,
        // mostly the wide arrangement because it is the frame's broad shape, and the high veil at
        // 0.55 so it is neither.
        float4 c2 = TarrockVaultCloud(azEl, sunAzEl, sky.cloud2, float2(1.0, 0.55), sky, pixelAngle);
        result = lerp(result, c2.rgb, c2.a);
        covered += (1.0 - covered) * c2.a;
        float4 c4 = TarrockVaultCloud(azEl, sunAzEl, sky.cloud4, float2(1.0, 0.10), sky, pixelAngle);
        result = lerp(result, c4.rgb, c4.a);
        covered += (1.0 - covered) * c4.a;
        float4 c1 = TarrockVaultCloud(azEl, sunAzEl, sky.cloud1, float2(-1.0, 0.70), sky, pixelAngle);
        result = lerp(result, c1.rgb, c1.a);
        covered += (1.0 - covered) * c1.a;
        float4 c3 = TarrockVaultCloud(azEl, sunAzEl, sky.cloud3, float2(-1.0, 0.85), sky, pixelAngle);
        result = lerp(result, c3.rgb, c3.a);
        covered += (1.0 - covered) * c3.a;
        float4 c0 = TarrockVaultCloud(azEl, sunAzEl, sky.cloud0, float2(1.0, 0.30), sky, pixelAngle);
        result = lerp(result, c0.rgb, c0.a);
        covered += (1.0 - covered) * c0.a;
    }

    // The dawn blaze, LAST, so it lies over cloud as well as over sky — which is what makes the
    // sun side of the frame hold together instead of showing where each layer stops. Straddles
    // the horizon by using abs(h), so the deck's far field catches the same warmth as the sky
    // directly above it and the join stays invisible on the sun side.
    // §THE WASH IS AIR — ROUND 6, and this one line is the whole of the cloud-shadow fix.
    //
    // THE FINDING. Round 5's cloud shadows came out WARMER than the sky they sit in (R−B +49
    // against the sky's +25) and one mass's shadow was warmer than its own lit crown. Round 4 hit
    // +1.4 at identical fog, so the fog was never the culprit — and the difference between the two
    // rounds is THIS FUNCTION'S LAST TWO LINES. Both were added in round 5 (the bearing lean), both
    // are ADDITIVE, and both were laid over the clouds as well as over the sky. Do the arithmetic at
    // the v3 hero — bearing 288°, 44° off the sun, elevation 12°:
    //     rise = 0.45 · 0.822 · exp(−0.208 · 2.2) = 0.234, times sunGlow (1.00, 0.68, 0.29) linear
    //          = +(0.234, 0.159, 0.069) added to EVERY pixel of that cloud.
    // The shadow core is authored at linear (0.023, 0.038, 0.140). Add that wash and it arrives at
    // (0.257, 0.197, 0.209): red now above blue, i.e. a warm brown-grey. A cool colour cannot
    // survive an additive warm term four times its own size, and no amount of re-authoring the
    // shadow can outrun it — which is why round 5's blue-slate intent measured as brown.
    //
    // WHY BLOCKING IT IS RIGHT AND NOT A DODGE. The rise is an AIR-PATH term: it is the dawn light
    // scattered toward the eye by the atmosphere between here and the sky's depth, which is why it
    // dies with height (exp(−h · 2.2)) and peaks on the sun's bearing. A cumulus is an opaque
    // surface in the middle of that path. The air in front of it still glows, the air behind it is
    // hidden — so the term should be scaled by how much path is left, which is exactly (1 − cover).
    // The same argument applies to the horizon blaze's broad lobe. The disc's own CORE is left
    // alone: it is the light source, not the air, and no mass in any review frame sits on it.
    // 0.85 rather than 1.0 keeps a sixth of the wash on the clouds on purpose — a cumulus at dawn IS
    // hazed by the air in front of it, and at 1.0 the masses unstick from the sky they hang in.
    //
    // WHAT IT BUYS, measured on the v3 hero through the round-6 grade (and re-checked under round
    // 5's, because the grade moved under this pass): darkest-quintile R−B +49.7 → −22.7, and the
    // hue slope d(R−B)/dL +0.128 → +0.538 — the reference plate (animation-04) runs +0.82.
    // The lit crown loses almost nothing: its own quintile only goes +35 → +44 R−B, because the
    // crown was never getting its warmth from the wash. The sky is untouched: cover is 0 there.
    float washPath = 1.0 - covered * TARROCK_WASH_BLOCK;
    float sunDot = saturate(dot(v, sky.sunDir));
    float horizonGlow = exp(-abs(h) * sky.glowFalloff);
    float broad = pow(sunDot, max(sky.glowBroadPower, 1.0));
    float core = pow(sunDot, max(sky.glowCorePower, 1.0));
    result += sky.sunGlow * (sky.glowBroad * broad * horizonGlow * washPath + sky.glowCore * core);

    // ...and the BROAD BEARING WASH, over everything, dying with height the way an air-path
    // brightening does. This is the half of the lean that adds rather than takes: it is what makes
    // the sunward third of the frame the warm end instead of merely the less-blue end.
    // ROUND 8 damps it by the same (1 − anti) as the horizon band above. The wash IS the reason
    // the anti-sun horizon measured warm: at 130° off the sun the bearing cosine has already
    // fallen to 0.11, but 1.15 × 0.11 of a gold that grades into the tonemap's shoulder is still
    // enough to hold the low sky at R−B +4. Damping it there rather than lowering bearingRise
    // (round 7's central win) leaves the sun side exactly as it was: at 39° off, `anti` is 0.008.
    result += sky.sunGlow * (sky.bearingRise * bearing * (1.0 - anti)
                             * exp(-saturate(h) * TARROCK_BEARING_FALL) * washPath);

    return result;
}

// ---------------------------------------------------------------------------------------------
// Filling the description from material properties.
//
// Both shaders declare the SAME uniform names — they have to, because TerrainRegionGenerator's
// ApplySkyDescription writes both materials with one set of SetColor/SetFloat calls. So the
// assignment list lives here as a macro rather than being typed out twice: a description with
// thirty-odd fields copied by hand in two files is a drift waiting to happen, and a drifted field
// grows a horizon seam on the deck. Macro, not a function, so it works whether the uniforms sit
// loose (the CGPROGRAM skybox) or inside a CBUFFER (the URP deck), and whether it is expanded
// before or after they are declared.
// ---------------------------------------------------------------------------------------------
#define TARROCK_FILL_SKY_DESC(sky)                          \
    sky.horizon = _HorizonColor.rgb;                        \
    sky.mid = _MidColor.rgb;                                \
    sky.zenith = _ZenithColor.rgb;                          \
    sky.haze = _HazeColor.rgb;                              \
    sky.sunGlow = _SunGlowColor.rgb;                        \
    sky.sunDir = normalize(_SunDirection.xyz);              \
    sky.midHeight = _MidHeight;                             \
    sky.hazeDepth = _HazeDepth;                             \
    sky.glowFalloff = _GlowFalloff;                         \
    sky.glowBroad = _GlowBroad;                             \
    sky.glowBroadPower = _GlowBroadPower;                   \
    sky.glowCore = _GlowCore;                               \
    sky.glowCorePower = _GlowCorePower;                     \
    sky.bandCount = _BandCount;                             \
    sky.bandStrength = _BandStrength;                       \
    sky.bandSoftness = _BandSoftness;                       \
    sky.horizonHeight = _HorizonHeight;                     \
    sky.bearingRise = _BearingRise;                         \
    sky.bearingPower = _BearingPower;                       \
    sky.bearingTilt = _BearingTilt;                         \
    sky.bankCrest = _BankCrestColor.rgb;                    \
    sky.bankShade = _BankShadeColor.rgb;                    \
    sky.bankHeight = _BankHeight;                           \
    sky.bankRelief = _BankRelief;                           \
    sky.bankLumpScale = _BankLumpScale;                     \
    sky.bankRimWidth = _BankRimWidth;                       \
    sky.bankBodyDepth = _BankBodyDepth;                     \
    sky.bankDissolve = _BankDissolve;                       \
    sky.bankFloor = _BankFloor;                             \
    sky.bankFade = _BankFade;                               \
    sky.bankGapStart = _BankGapStart;                       \
    sky.bankGapEnd = _BankGapEnd;                           \
    sky.cloud0 = _VaultCloud0;                              \
    sky.cloud1 = _VaultCloud1;                              \
    sky.cloud2 = _VaultCloud2;                              \
    sky.cloud3 = _VaultCloud3;                              \
    sky.cloud4 = _VaultCloud4;                              \
    sky.cloudLit = _VaultCloudLit.rgb;                      \
    sky.cloudShade = _VaultCloudShade.rgb;                  \
    sky.cloudShadow = _VaultCloudShadow.rgb;                \
    sky.cloudBase = _VaultCloudBase;                        \
    sky.cloudBaseLump = _VaultCloudBaseLump;                \
    sky.cloudSoftness = _VaultCloudSoftness;                \
    sky.cloudLump = _VaultCloudLump;                        \
    sky.cloudLift = _VaultCloudLift;

// The property block both materials must carry, so the two lists cannot fall out of step either.
// Included verbatim by Tarrock/GradientSky and Tarrock/CloudSea.
// (Kept as a comment rather than a shared .cginc Properties fragment: Unity has no include
// mechanism for Properties blocks, so the two lists are duplicated by necessity — this macro at
// least guarantees the CODE reading them is identical.)

#endif // TARROCK_SKY_GRADIENT_INCLUDED
