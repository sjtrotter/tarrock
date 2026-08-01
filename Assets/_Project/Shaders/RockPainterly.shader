Shader "Tarrock/RockPainterly"
{
    // Painterly stone for the scattered rock-outcrop family (TerrainRegionGenerator.BuildRockOutcrops).
    //
    // WHY A SHADER AND NOT Tarrock/FoliageWind. The only mesh shader the region had was the foliage
    // one, which lights a mesh with a single flat _BaseColor and ignores COLOR.rgb — a boulder drawn
    // with it is one untextured lump, which is exactly the "smooth empty mass" the round-1 critique
    // is about. Stone needs three things the ground already has and foliage does not: mottle that
    // survives on near-vertical faces, bedding that gives a block a top and a grain, and a POSTERISED
    // light ramp so a rock reads as a few laid-down values rather than a smooth gradient
    // (art-bible.md brush economy). All three are lifted from Tarrock/TerrainPainterly deliberately:
    // a rock sitting on the ground must be made of the same paint as the ground, or the frame gains
    // a prop instead of a landform. The palette is not restated here — the generator READS
    // _RockColor / _CliffColor / _MossColor off the terrain material and writes them onto the rock
    // material, so there is exactly one place those colours are chosen.
    //
    // ROUND-3 REWRITE, in step with Tarrock/TerrainPainterly's. Read that shader's header first; the
    // reasoning is there and is not restated. Three changes here:
    //
    //   a. THE BEDDING IS REBUILT to the same grammar as the ground's: a gravity-aligned world-Y
    //      lattice with per-bed position/thickness/value jitter, a thin dark parting and a thin
    //      sunlit lip, a warp CAPPED to a fraction of a bed, and analytic anti-aliasing off the
    //      lattice's own screen footprint. Round 2 drew `posterise(sin(bedding * pi))`, which is a
    //      WIDE SOFT sinusoid lerping the whole albedo between two stone colours — that is why the
    //      round-2 boulders read as a stack of pale tonal slabs rather than as a bedded block. A bed
    //      is a thin parting between two masses of one colour, not a colour that oscillates.
    //
    //   b. A CAVITY TERM, the same AO-like construct the ground uses: the FILLED region where the
    //      fine relief sits below the broad form. It replaces nothing (round 2 had no occlusion at
    //      all) and it is deliberately not folded into the bedding — the boulder must still have
    //      hollows with the bedding turned off.
    //
    //   c. STRICTLY OPAQUE render state, stated rather than inherited, for the same reason the
    //      ground states it: it should take four lines to verify, not an argument from absent syntax.
    //
    // The rock's HARD FACETS are left alone on purpose. The ground's facets are a fault (a Gouraud
    // artefact on a surface that is meant to be smooth); a boulder's facets are the art direction
    // (BuildRockMesh emits per-quad normals so the stone reads as a few flat planes with confident
    // edges, art-bible.md). Do not add the ground's per-pixel shading normal here.
    //
    // NO WIND. Rock does not move, bound or unbound, so this shader carries no sway and never reads
    // _TarrockWindStrength. (It is also therefore safe under static batching, which is what ate the
    // object-space foliage sway in commit 48712b9 — nothing here is object-space.)
    Properties
    {
        [Header(Palette)]
        _RockColor ("Rock (warm grey)", Color) = (0.52, 0.49, 0.44, 1)
        _CliffColor ("Cliff (pale cool grey)", Color) = (0.45, 0.47, 0.49, 1)
        _MossColor ("Moss (upward faces)", Color) = (0.19, 0.24, 0.13, 1)
        _MossAmount ("Moss Amount", Range(0, 1)) = 0.45
        _MossStart ("Moss Normal Start", Range(-1, 1)) = 0.25

        [Header(Surface)]
        _RockVariation ("Mottle Scale (m)", Float) = 1.6
        _RockContrast ("Mottle Contrast", Range(0.5, 4)) = 1.7
        _RockDetailAmount ("Detail Amount", Range(0, 0.5)) = 0.12
        // ROUND-5. Round 4 answered "no surface detail at 2 m" with a 0.20 m jittered-cell band,
        // and round 5 measured what that actually bought. Two faults, both arithmetic:
        //   * TOO COARSE TO BE THE FINEST TERM. At the ground sample distance the gauntlet's close
        //     vantage resolves — 2.0 mm per pixel — a 0.20 m mark is 100 pixels across, so a stone
        //     at arm's length still had a flat wash INSIDE every mark.
        //   * IT FOLDED. A Worley F1 is a min() over nine cells, so it creases along every cell
        //     wall; modelled on its own that measured a directional anisotropy of 17.2 against a
        //     reference-plate band of 1.6-5.7, and it was the largest single source of the
        //     wood-grain read over round-4's v5.
        // The replacement is the same construct the terrain took: a turned, non-folding fbm down to
        // ~2 cm, plus sparse mark bands that buy amplitude at low coverage. See TkDetailFbm below.
        // Base scale is the COARSEST octave and the finest is base/2.71³, so 0.45 m puts the finest
        // at 2.3 cm — inside the 2-4 cm band the critique asked the ground for.
        _DetailBaseScale ("Detail - base scale (m)", Float) = 0.45
        _RockGrainAmount ("Detail - continuous amount", Range(0, 0.8)) = 0.40
        _RockFleckFine ("Detail - fleck 2 cm (grit)", Range(0, 0.9)) = 0.58
        _RockFleckMid ("Detail - fleck 9 cm (weathering)", Range(0, 0.9)) = 0.46
        _RockFleckCoarse ("Detail - fleck 60 cm (patches)", Range(0, 0.9)) = 0.34
        // How far the block's own colour drifts between formations. It is a HUE swing between two
        // stone colours applied per formation, not a value oscillation applied per pixel.
        _FormationTint ("Formation Hue Swing", Range(0, 1)) = 0.55

        [Header(Bedding)]
        // Gravity-aligned, same grammar as the ground (see Tarrock/TerrainPainterly §Bedding). A
        // boulder is about a metre tall, so the spacing is an order finer than the cliff's.
        _BeddingSpacing ("Bedding - mean bed thickness (m)", Float) = 0.34
        _BeddingDip ("Bedding - dip gradient (XZ)", Vector) = (0.070, 0.0, -0.050, 0)
        _BeddingWarp ("Bedding - warp (m, capped to 0.30 bed)", Float) = 0.09
        _BeddingLineWidth ("Bedding - parting half width (bed fraction)", Range(0.01, 0.3)) = 0.10
        _BeddingWidthJitter ("Bedding - per-bed thickness jitter", Range(0, 0.9)) = 0.60
        _BeddingDarken ("Bedding - parting darken", Range(0, 1)) = 0.30
        _BeddingLip ("Bedding - sunlit lip", Range(0, 1)) = 0.18
        _BedValueJitter ("Bedding - per-bed value jitter", Range(0, 0.4)) = 0.10
        _BedFormRate ("Bedding - formations per bed", Range(0.05, 1)) = 0.30
        // A horizontal bed cuts a thin line across a STEEP face and an enormous blob across a
        // near-horizontal one, so the flat tops and undersides of a boulder take no bedding. Same
        // physics as the ground's slope gate, measured on |N.y| because a boulder has both.
        _BeddingFaceStart ("Bedding - face fade in (1 - abs N.y)", Range(0, 1)) = 0.18
        _BeddingFaceEnd ("Bedding - face full (1 - abs N.y)", Range(0, 1)) = 0.46

        [Header(Cavity)]
        _CavityScale ("Cavity Scale (m)", Float) = 0.55
        _CavityContrast ("Cavity Contrast", Range(0.5, 10)) = 4.5
        _CavityDarken ("Cavity Darken", Range(0, 1)) = 0.30

        [Header(Brush economy)]
        _BrushSteps ("Value Steps", Range(2, 10)) = 4
        _BrushSoftness ("Step Softness", Range(0.02, 1)) = 0.35

        [Header(Lighting)]
        _ShadeWrap ("Shade Wrap", Range(0, 1)) = 0.25

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
        _AmbientBoost ("Ambient Boost", Range(0, 2)) = 1.0
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
            "IgnoreProjector" = "True"
        }
        LOD 200
        Cull Back

        // One shared block: the SRP Batcher requires an identical UnityPerMaterial layout in every
        // pass, and the noise helpers are wanted by the forward pass only but cost nothing here.
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _RockColor;
            float4 _CliffColor;
            float4 _MossColor;
            float _MossAmount;
            float _MossStart;
            float _RockVariation;
            float _RockContrast;
            float _RockDetailAmount;
            float _DetailBaseScale;
            float _RockGrainAmount;
            float _RockFleckFine;
            float _RockFleckMid;
            float _RockFleckCoarse;
            float _FormationTint;
            float _BeddingSpacing;
            float4 _BeddingDip;
            float _BeddingWarp;
            float _BeddingLineWidth;
            float _BeddingWidthJitter;
            float _BeddingDarken;
            float _BeddingLip;
            float _BedValueJitter;
            float _BedFormRate;
            float _BeddingFaceStart;
            float _BeddingFaceEnd;
            float _CavityScale;
            float _CavityContrast;
            float _CavityDarken;
            float _BrushSteps;
            float _BrushSoftness;
            float _ShadeWrap;
            float _AmbientBoost;
            float _SunBleach;
            float _BleachStart;
            float4 _BleachTint;
            float4 _ShadowTint;
            float4 _AmbientFloor;
        CBUFFER_END

        // The same hash / noise / cavity / posterise family Tarrock/TerrainPainterly uses. Copied
        // rather than shared through an .hlsl on purpose: these functions are the region's paint
        // recipe and the two shaders must agree, but a rock is not a terrain and the include would
        // drag the terrain's splat plumbing with it. If the ground's recipe changes, change it here.
        // ROUND 6, MEASURED FAULT (identical to TerrainPainterly's — the two recipes must agree).
        // The old form was handed LATTICE INDICES, and at a 2 cm band the index at the Cliff's own
        // world coordinates is ~10000; 10000 * 456.21 = 4.6e6, where float32's ULP is 0.5 and
        // frac() can land on two values. Counted in float32 over 400 consecutive cells, the old
        // form produced 8-55 distinct hash values; a hash that has collapsed along one axis draws
        // STRIPES. The small-multiplier construction (the one TkHash22 has always used) keeps the
        // product near 1750 and re-measures at 357-392 of 400.
        float TkHash21(float2 p)
        {
            float3 p3 = frac(float3(p.x, p.y, p.x) * float3(0.1031, 0.1030, 0.0973));
            p3 += dot(p3, p3.yzx + 33.33);
            return frac((p3.x + p3.y) * p3.z);
        }

        float TkHash31(float3 p)
        {
            float3 p3 = frac(p * float3(0.1031, 0.1030, 0.0973));
            p3 += dot(p3, p3.yzx + 33.33);
            return frac((p3.x + p3.y) * p3.z);
        }

        float2 TkHash22(float2 p)
        {
            float3 p3 = frac(p.xyx * float3(0.1031, 0.1030, 0.0973));
            p3 += dot(p3, p3.yzx + 33.33);
            return frac((p3.xx + p3.yz) * p3.zy);
        }

        float TkValueNoise(float2 p)
        {
            float2 i = floor(p);
            float2 f = frac(p);
            float2 u = f * f * (3.0 - 2.0 * f);
            float a = TkHash21(i);
            float b = TkHash21(i + float2(1.0, 0.0));
            float c = TkHash21(i + float2(0.0, 1.0));
            float d = TkHash21(i + float2(1.0, 1.0));
            return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
        }

        // 3-D value noise (round 6). Eight hashes a tap against a triplanar's twelve, and it has no
        // projection and therefore no frame that can rotate with the surface normal. See the
        // TkMarkSpace note below for why that is the whole of the contour-lock fix.
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

        float TkFbm(float2 p)
        {
            p = fmod(p, 512.0);
            float sum = 0.0;
            float amp = 0.5;
            float norm = 0.0;
            for (int i = 0; i < 3; i++)
            {
                sum += TkValueNoise(p) * amp;
                norm += amp;
                p *= 2.03;
                p += 17.3;
                amp *= 0.5;
            }
            return sum / norm;
        }

        // .x is the broad form, .y the same form plus one finer octave, both mean 0.5. Their
        // difference is positive exactly in the HOLLOWS — a filled region, never a level set. See
        // Tarrock/TerrainPainterly's TkCavityPair for why that distinction is the whole ballgame.
        // -- Turning the domain between octaves (round 5) -----------------------------------------
        // Value noise lives on an AXIS-ALIGNED lattice and its interpolant kinks at every cell
        // wall; octaves stacked on the same axes make those kinks coincide into a rectilinear
        // crease network. Measured on round-4's v5 terrain that read as a directional anisotropy of
        // 12.7 against a reference-plate band of 1.6-5.7, and the stones are made of the same paint
        // as the ground, so they take the same fix. Angles are 0.618034*pi*n, quoted as cos/sin
        // because they are constants and a sincos per octave per projection is twelve
        // transcendentals a pixel for a number that never changes.
        static const float2 kTurn1 = float2(-0.36327, 0.93169);   // 111.25 deg
        static const float2 kTurn2 = float2(-0.73593, -0.67705);  // 222.50 deg
        static const float2 kTurn3 = float2( 0.89685, -0.44234);  // 333.75 deg

        float2 TkTurn(float2 p, float2 cs)
        {
            return float2(p.x * cs.x - p.y * cs.y, p.x * cs.y + p.y * cs.x);
        }

        float2 TkCavityPair(float2 p)
        {
            float broad = TkValueNoise(p);
            // ROUND-5: the fine octave is TURNED as well as scaled, so the pair's difference — read
            // here by both the cavity term and the texel-scale tone — stops carrying the lattice's
            // own crease network.
            float fine = TkValueNoise(TkTurn(p * 2.71 + 19.7, kTurn1));
            return float2(broad, broad * 0.68 + fine * 0.32);
        }

        // -- The detail stack (round 5) -----------------------------------------------------------
        // The full derivation lives in Tarrock/TerrainPainterly's TkDetailFbm header; this is the
        // same construct at prop scale, because a boulder sitting on the hillside must be made of
        // the same paint as the hillside. The short version: round 4's finest term on this shader
        // was a 0.20 m Worley dab, and a Worley F1 is a min() over nine cells, so it CREASES along
        // every cell wall — a fold by another name, and modelled alone it measured an anisotropy of
        // 17.2. It is replaced by a non-folding turned fbm plus sparse mark bands, and distance is
        // handled per octave against the pixel footprint rather than by a camDist fade.
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

            // Renormalised by the weights that SURVIVED, so an octave falling under the pixel hands
            // its share to the octaves above it and the surface holds its amplitude with distance
            // instead of dissolving into its own mean.
            return tot > 1e-4 ? sum / tot : 0.5;
        }

        // -- ROUND 6: THE FRAME IS THE CONTOUR LOCK ----------------------------------------------
        // Two constructs here oriented the marks off the surface normal: this triplanar (whose three
        // weights rotate the effective projection with the landform) and, far worse,
        // `faceUV = float2(dot(positionWS.xz, strike), positionWS.y)` in the fragment, where
        // `strike` IS the contour direction. dot(P.xz, strike) is only an arclength coordinate on a
        // plane; on a curved face
        //
        //     d(faceUV.x)/ds = 1 - kappa * (P . n)
        //
        // and at this region's world coordinates (P . n) is 150-250 m against curvature radii of
        // 10-60 m, so the second term is 3-18x the first, sets the sign, and passes through zero on
        // some faces — where the marks become infinitely elongated ALONG the contour. That is the
        // wood grain, and it is why replacing the noise in round 5 changed nothing. The full
        // derivation and the measured derivative table live in Tarrock/TerrainPainterly.
        //
        // Replaced by frameless world-space 3-D lookups. Anisotropy is kept but WORLD-LOCKED: the
        // horizontal components are divided by kMarkAniso so every mark is stretched along world
        // horizontal by the same constant everywhere. A constant direction cannot trace a contour.
        static const float kMarkAniso = 2.0;

        float3 TkMarkSpace(float3 worldPos)
        {
            return float3(worldPos.x / kMarkAniso, worldPos.y, worldPos.z / kMarkAniso);
        }

        // CROSS-FILE DEBT: the four mark-amount properties are written by
        // TerrainRegionGenerator.Ground.cs, owned by another builder this round, so a shader default
        // cannot reach the render. The round-6 amplitude target needs ~1.5-1.9x round 5's values, so
        // the gain sits here and the property keeps its round-5 meaning:
        //   _RockGrainAmount 0.40 x1.65 -> 0.66   _RockFleckFine   0.58 x1.48 -> 0.86
        //   _RockFleckMid    0.46 x1.78 -> 0.82   _RockFleckCoarse 0.34 x1.88 -> 0.64
        // Fold these into Ground.cs and set them to 1.0 as soon as the two files can move together.
        static const float kRockGrainGain  = 1.65;
        static const float kRockFineGain   = 1.48;
        static const float kRockMidGain    = 1.78;
        static const float kRockCoarseGain = 1.88;

        float TkMarkAmount(float property, float gain)
        {
            return min(property * gain, 0.90);
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

        // Sparse marks. Returns .x = a MEAN-PRESERVING multiplier, .y = the raw mark. A smooth
        // field cannot reach the reference amplitude band at any sane swing; a mark field of
        // coverage p at contrast c has rms = c*sqrt(p*(1-p)), which is how a few strong marks buy
        // what an airbrush cannot. Dividing the expected mean back out matters because three bands
        // compound to a ~15% darkening otherwise, and the stone palette is authored, not emergent.
        float2 TkFleckBand(float2 p, float lamA, float lamB, float2 thr,
                           float coverage, float amount, float pixelM)
        {
            float w = TkOctaveWeight(lamA, pixelM);
            if (w <= 0.002) return float2(1.0, 0.0);
            float a = TkValueNoise(p / max(lamA, 1e-4));
            float b = TkValueNoise(p / max(lamB, 1e-4) + 11.3);
            float mark = smoothstep(thr.x, thr.y, a)
                       * smoothstep(thr.x - 0.06, thr.y - 0.06, b) * w;
            return float2((1.0 - mark * amount) / max(1.0 - coverage * amount * w, 0.05), mark);
        }

        // The frameless twin (round 6). Same construct, 3-D world-space lookups, caller supplies an
        // already-anisotropy-scaled position so the mark family has ONE fixed shape on every face.
        float2 TkFleckBand3(float3 p, float lamA, float lamB, float2 thr,
                            float coverage, float amount, float pixelM)
        {
            float w = TkOctaveWeight(lamA, pixelM);
            if (w <= 0.002) return float2(1.0, 0.0);
            float a = TkValueNoise3(p / max(lamA, 1e-4));
            float b = TkValueNoise3(p / max(lamB, 1e-4) + 11.3);
            float mark = smoothstep(thr.x, thr.y, a)
                       * smoothstep(thr.x - 0.06, thr.y - 0.06, b) * w;
            return float2((1.0 - mark * amount) / max(1.0 - coverage * amount * w, 0.05), mark);
        }

        // Triplanar, because a boulder is mostly NOT facing up: a planar xz projection smears the
        // mottle into vertical stripes on exactly the faces that read against the sky.
        float TkTriplanarFbm(float3 worldPos, float3 normal, float scaleMetres)
        {
            float3 blend = pow(abs(normal), 4.0);
            blend /= max(blend.x + blend.y + blend.z, 1e-4);
            float inv = 1.0 / max(scaleMetres, 0.01);
            float nx = TkFbm(worldPos.zy * inv);
            float ny = TkFbm(worldPos.xz * inv);
            float nz = TkFbm(worldPos.xy * inv);
            return nx * blend.x + ny * blend.y + nz * blend.z;
        }

        float2 TkTriplanarCavityPair(float3 worldPos, float3 normal, float scaleMetres)
        {
            float3 blend = pow(abs(normal), 4.0);
            blend /= max(blend.x + blend.y + blend.z, 1e-4);
            float inv = 1.0 / max(scaleMetres, 0.01);
            return TkCavityPair(worldPos.zy * inv) * blend.x
                 + TkCavityPair(worldPos.xz * inv) * blend.y
                 + TkCavityPair(worldPos.xy * inv) * blend.z;
        }

        // ROUND-5: TkDabShaped is gone from this shader. It was a Worley F1 — a min() over
        // nine cells — and a min() creases along every cell wall, which is a fold: modelled
        // alone it measured a directional anisotropy of 17.2 against a reference-plate band of
        // 1.6-5.7. The stones still share the ground's paint recipe; the recipe changed. Marks
        // with EDGES are now bought with sparse mark fields (TkFleckBand above), which have
        // real edges at low coverage and no crease network to draw.

        float TkContrast(float x, float k)
        {
            return saturate((x - 0.5) * k + 0.5);
        }

        float TkSoftPosterize(float x, float steps, float softness)
        {
            float soft = clamp(softness, 0.02, 1.0) * 0.5;
            float s = x * steps;
            float level = floor(s);
            float f = s - level;
            float e = smoothstep(0.5 - soft, 0.5 + soft, f);
            return saturate((level + e) / max(steps, 1.0));
        }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            // STRICTLY OPAQUE, stated rather than inherited — see the header.
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
                float4 color      : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float4 color      : TEXCOORD2;
                float fogCoord    : TEXCOORD3;
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
                output.color = input.color;
                output.fogCoord = ComputeFogFactor(positions.positionCS.z);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                float3 positionWS = input.positionWS;
                float3 normalWS = normalize(input.normalWS);

                // WORLD METRES PER PIXEL, taken at the top of the function and outside every
                // branch — ddx/ddy in non-uniform flow control is undefined, and the mark branch
                // below straddles the silhouette of every stone in the frame. This is what the
                // detail stack weights its octaves against: it already carries distance, fov,
                // resolution and this pixel's grazing angle, none of which a camDist fade knows.
                float pixelM = max(max(length(ddx(positionWS)), length(ddy(positionWS))), 1e-5);

                // -- Mottle: the block's own patchiness. Contrast-pushed for the same reason the
                //    ground's is — three octaves of value noise sit in a narrow band around the mean
                //    and read as an airbrush until they are pushed apart. It doubles as the bedding
                //    warp field below, which is why it is computed before the bedding and not after.
                float mottle = TkContrast(
                    TkTriplanarFbm(positionWS, normalWS, _RockVariation), _RockContrast);

                // -- Cavity: the FILLED hollows, an AO-like term of its own. Also supplies the
                //    texel-scale tone that round 2 took from a second triplanar fbm, so the extra
                //    hollow costs three taps rather than nine.
                float2 relief = TkTriplanarCavityPair(positionWS, normalWS, _CavityScale);
                // ROUND-5: smoothstep, not saturate. saturate(d * contrast) CLAMPS, and the set
                // where a smooth field first reaches its clamp is a LEVEL SET — a closed contour
                // with a hard C1 break along it, which is the artefact this construct's own header
                // says it exists to avoid. The 1.35 widens the ramp so the mean cavity strength
                // lands close to what the clamp gave.
                float cavity = smoothstep(0.0, 1.35 / max(_CavityContrast, 0.5),
                    relief.x - relief.y);

                // -- Bedding, gravity-aligned, same grammar as the ground -------------------------
                // Gated to the STEEP faces of the block: a horizontal bed cuts a thin line across a
                // vertical face and an enormous blob across a flat top.
                float faceMask = smoothstep(_BeddingFaceStart, _BeddingFaceEnd,
                    1.0 - abs(normalWS.y));

                float spacing = max(_BeddingSpacing, 0.02);
                // Capped to well under a bed, so the lattice stays world Y and the partings stay
                // horizontal lines instead of becoming the warp field's closed level sets. This cap
                // is the round-2 worm fix and it is structural, not a taste setting.
                float warpM = min(abs(_BeddingWarp), spacing * 0.30);
                float bedRaw = (positionWS.y
                    + _BeddingDip.x * positionWS.x + _BeddingDip.z * positionWS.z
                    + (mottle - 0.5) * 2.0 * warpM) / spacing;

                float bedIndex = floor(bedRaw);
                float f = bedRaw - bedIndex;

                float2 bedHash = TkHash22(float2(bedIndex, 3.7));
                float bedTone = TkHash21(float2(bedIndex * 0.71 + 4.3, 9.1));
                float partAt = lerp(0.12, 0.88, bedHash.x);
                float halfW = _BeddingLineWidth
                    * lerp(1.0 - _BeddingWidthJitter, 1.0 + _BeddingWidthJitter, bedHash.y);

                // Analytic AA off the lattice's own screen footprint: soften so a mark never falls
                // under a pixel and crawls, and fade the mark out entirely once a whole bed is
                // thinner than about two and a half pixels. A scatter of a few hundred boulders is
                // exactly where a sub-pixel hard line would shimmer.
                float bedAA = max(fwidth(positionWS.y), 1e-5) / spacing;
                float w = max(halfW, bedAA * 0.80);
                float aaFade = 1.0 - smoothstep(0.125, 0.40, bedAA);

                float d = abs(f - partAt);
                float parting = 1.0 - smoothstep(w * 0.30, w, d);

                float lipD = partAt - f;
                float lip = saturate(1.0 - lipD / max(w * 2.6, 1e-5))
                          * saturate(lipD / max(w * 0.9, 1e-5));

                float lineAmount = faceMask * aaFade;

                // Hue by FORMATION, not by bed — a stack of partings that share a colour.
                float formIndex = floor(bedRaw * _BedFormRate);
                float formRand = TkHash21(float2(formIndex, formIndex * 0.37 + 11.0));

                float3 albedo = lerp(_RockColor.rgb, _CliffColor.rgb,
                    saturate(formRand * 1.35 - 0.18) * _FormationTint * faceMask);
                albedo *= lerp(0.88, 1.12, mottle);
                albedo *= 1.0 + (relief.y - 0.5) * 2.0 * _RockDetailAmount;
                albedo *= 1.0 + (bedTone - 0.5) * 2.0 * _BedValueJitter * faceMask;
                albedo *= 1.0 - parting * _BeddingDarken * lineAmount;
                albedo *= 1.0 + lip * _BeddingLip * lineAmount;
                albedo *= 1.0 - cavity * _CavityDarken;

                // -- The detail stack (round 5) ---------------------------------------------------
                // Replaces round 4's 0.20 m face dab, on the same finding and for the same two
                // reasons as the terrain's: the dab was too COARSE to be the finest term (at the
                // 2.0 mm/px the gauntlet's close vantage resolves, 0.20 m is 100 pixels across, so
                // a stone at arm's length still had a flat wash inside every mark), and being a
                // Worley F1 it CREASED along its cell walls, which is a fold and measured as one.
                //
                // It was also fading on camDist — gone by 16 m — which is the same mistake that
                // left round 4's far hills at 3.3% relative amplitude against a reference 13-20%.
                // Nothing here fades on distance; the octaves and the mark bands each carry their
                // own weight against the pixel, so a stone keeps its surface for as long as its
                // surface is resolvable.
                // ROUND 6: NO FRAME. The triplanar and the `strike` face frame that used to be
                // here were both functions of the surface normal — see the TkMarkSpace header for
                // the derivation and the measured numbers. World-space 3-D lookups instead, which
                // also cost less: four 3-D taps (32 hashes) where the triplanar was twelve 2-D taps
                // (48), and six 3-D taps for the mark bands where the face frame took six 2-D.
                float3 markPos = TkMarkSpace(positionWS);
                float stoneDetail = TkDetailFbm3(markPos, _DetailBaseScale, pixelM);
                albedo *= 1.0 + (stoneDetail - 0.5) * 2.0
                    * TkMarkAmount(_RockGrainAmount, kRockGrainGain);

                // THE LADDER IS RE-PITCHED (round 6, finding 4), on the same reasoning as the
                // terrain's: round 5's finest rung fell under kDetailPxLo at the distances these
                // frames actually contain, so one rung of three was doing measurable work. A stone
                // is smaller and closer than a cliff, so its ladder sits one step below the
                // terrain's: 4 / 12 / 40 cm against the terrain's 6 / 16.5 / 56. Coverages
                // re-measured for the new wavelengths and thresholds.
                float2 stoneFine = TkFleckBand3(markPos, 0.040, 0.066, float2(0.46, 0.76),
                    0.140, TkMarkAmount(_RockFleckFine, kRockFineGain), pixelM);
                float2 stoneMid = TkFleckBand3(markPos + 61.7, 0.120, 0.198, float2(0.50, 0.79),
                    0.106, TkMarkAmount(_RockFleckMid, kRockMidGain), pixelM);
                float2 stoneWide = TkFleckBand3(markPos + 193.1, 0.400, 0.660, float2(0.52, 0.81),
                    0.086, TkMarkAmount(_RockFleckCoarse, kRockCoarseGain), pixelM);
                albedo *= stoneFine.x * stoneMid.x * stoneWide.x;

                // -- Moss on ledges: only where the face turns upward AND the hollows say damp, so
                //    it lands in patches instead of coating every horizontal facet.
                float ledge = saturate((normalWS.y - _MossStart) / max(1.0 - _MossStart, 1e-3));
                float moss = _MossAmount * ledge * ledge * (0.35 + cavity * 0.65);
                albedo = lerp(albedo, _MossColor.rgb, saturate(moss));

                // -- Per-facet value baked into the mesh: the hand-laid variation between one face
                //    and the next, plus the darkening toward the buried base that makes a rock sit
                //    IN the ground instead of on it. (See BuildRockMesh.)
                albedo *= input.color.rgb;

                // -- Lighting: wrapped lambert POSTERISED into a few values (brush economy), a cool
                //    tint on the shaded side and a floor under ambient so shadow stays luminous.
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                Light mainLight = GetMainLight(shadowCoord);

                float ndotl = dot(normalWS, mainLight.direction);
                float wrapped = saturate((ndotl + _ShadeWrap) / (1.0 + _ShadeWrap));
                float stepped = TkSoftPosterize(wrapped, _BrushSteps, _BrushSoftness);
                float lit = stepped * mainLight.shadowAttenuation;
                float3 direct = mainLight.color * lit;
                float3 ambient = max(SampleSH(normalWS) * _AmbientBoost, _AmbientFloor.rgb);
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

        // Rocks must cast: the near outcrops' shadows are half of what makes them read as near.
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

        // Depth-only, so the depth prepass (PC_RPAsset requires it; SSAO samples it) sees the rocks.
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
