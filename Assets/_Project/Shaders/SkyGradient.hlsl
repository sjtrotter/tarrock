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
float4 TarrockVaultCloud(float2 azEl, float2 sunAzEl, float4 spec, float2 variant, TarrockSkyDesc sky)
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
    float scallop = (TarrockGradNoise(pc * 4.3 + spec.x)
                   + TarrockGradNoise(pc * 9.7 + spec.y * 3.1) * 0.45) * sky.cloudLump;

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

    float3 color = lerp(sky.cloudShade, sky.cloudLit, form);

    // THE DARK ANCHOR. Thickness reads as darkness: a 20°-wide cumulus at this hour is deep enough
    // that its base is the darkest value in the frame, and a 7° one is not. Deriving the weight
    // from the mass's own half-width means the composition's largest cloud is automatically its
    // anchor and nothing has to be hand-flagged — and it stays true if the director resizes one.
    // Opacity is in it as well as size, and for the same reason: a mass you can see the sky
    // through is a mass the light gets through, so a 26%-opacity veil has no dark base to give
    // however wide it is drawn.
    float thick = saturate((spec.z - 8.0) / 12.0) * saturate(spec.w * 1.15);
    float belly = (1.0 - smoothstep(-baseCut, baseCut + 0.34, pc.y)) * (1.0 - form * 0.62);
    color = lerp(color, sky.cloudShadow, saturate(belly * thick) * 0.95);

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

    // ABOVE. At the gameplay camera's pitch the player sees roughly the first 25° of sky and no
    // more, so both ramps are shaped to spend themselves inside that band — the previous
    // pow(h, 1.25) ramp put its whole transition above the frustum and the sky read as flat tan.
    // smoothstep also lands the ramp on the horizon with zero derivative, so there is no crease
    // where the two hemispheres meet.
    float t = smoothstep(0.0, 1.0, saturate(h / max(sky.midHeight, 0.001)));
    t = TarrockSoftBand(t, sky.bandCount, sky.bandStrength, sky.bandSoftness);
    float3 color = lerp(sky.horizon, sky.mid, t);

    float u = smoothstep(0.0, 1.0, saturate((h - sky.midHeight) / max(1.0 - sky.midHeight, 0.001)));
    u = TarrockSoftBand(u, sky.bandCount, sky.bandStrength, sky.bandSoftness);
    float3 above = lerp(color, sky.zenith, u);

    // BELOW. The lower hemisphere is the cloud sea seen at infinity, so it settles on the haze
    // the fog and the deck both settle on. Everything distant in this region — rim rock, the
    // deck's far field, the sky under the horizon — is one luminous value.
    float d = smoothstep(0.0, 1.0, saturate(-h / max(sky.hazeDepth, 0.001)));
    float3 below = lerp(sky.horizon, sky.haze, d);

    float3 result = h >= 0.0 ? above : below;

    // THE CLOUD BANK, over the gradient. Straddles the horizon on purpose: its crest stands a
    // couple of degrees above, its skirt dies a fraction of a degree below, and the deck picks it
    // up unchanged because the deck resolves to this same function.
    float4 bank = TarrockCloudBank(v, h, sky);
    result = lerp(result, bank.rgb, bank.a);

    // THE VAULT CLOUDS, over that. Skipped outright under the bank's floor: no ray that hits deck
    // geometry can reach a cloud up there, and the deck runs this whole function per pixel, so
    // the branch is worth having.
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
        float4 c2 = TarrockVaultCloud(azEl, sunAzEl, sky.cloud2, float2(1.0, 0.55), sky);
        result = lerp(result, c2.rgb, c2.a);
        float4 c4 = TarrockVaultCloud(azEl, sunAzEl, sky.cloud4, float2(1.0, 0.10), sky);
        result = lerp(result, c4.rgb, c4.a);
        float4 c1 = TarrockVaultCloud(azEl, sunAzEl, sky.cloud1, float2(-1.0, 0.70), sky);
        result = lerp(result, c1.rgb, c1.a);
        float4 c3 = TarrockVaultCloud(azEl, sunAzEl, sky.cloud3, float2(-1.0, 0.85), sky);
        result = lerp(result, c3.rgb, c3.a);
        float4 c0 = TarrockVaultCloud(azEl, sunAzEl, sky.cloud0, float2(1.0, 0.30), sky);
        result = lerp(result, c0.rgb, c0.a);
    }

    // The dawn blaze, LAST, so it lies over cloud as well as over sky — which is what makes the
    // sun side of the frame hold together instead of showing where each layer stops. Straddles
    // the horizon by using abs(h), so the deck's far field catches the same warmth as the sky
    // directly above it and the join stays invisible on the sun side.
    float sunDot = saturate(dot(v, sky.sunDir));
    float horizonGlow = exp(-abs(h) * sky.glowFalloff);
    float broad = pow(sunDot, max(sky.glowBroadPower, 1.0));
    float core = pow(sunDot, max(sky.glowCorePower, 1.0));
    result += sky.sunGlow * (sky.glowBroad * broad * horizonGlow + sky.glowCore * core);

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
