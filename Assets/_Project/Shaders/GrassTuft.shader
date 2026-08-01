Shader "Tarrock/GrassTuft"
{
    // Instanced grass-tuft shader for Unity Terrain DETAIL meshes (the built-in grass system —
    // per-patch culling, painted/programmatic density, GPU instancing; the right tool for meadow
    // grass where a particle system would pay unmanaged overdraw). The tuft meshes are built by
    // TerrainRegionGenerator.BuildTuftMesh — one per SPECIES, four of them — and every one carries
    // the same five channels this shader depends on:
    //
    //   POSITION   blades fanned around the tuft centre, each arcing over
    //   NORMAL     biased hard toward +Y (a blade's true normal is horizontal, which lights a
    //              meadow as a field of dark spikes; up-biased normals make the tufts shade with
    //              the ground they grow out of — the hand-painted read, art-bible.md §Materials)
    //   COLOR.rgb  dark base -> pale tip gradient, with a small per-blade value jitter
    //   COLOR.a    LEAN MASK: 0 at every blade's base, rising to 1 at the tallest blade's tip,
    //              already scaled by that blade's share of the tuft height
    //   TEXCOORD0  x = per-blade seed (0..1), y = height above the tuft base as a fraction of the
    //              prototype mesh height (_TuftHeight)
    //   TEXCOORD1  the vertex's object-space XZ offset from the tuft root, so the tuft can be
    //              widened with view distance without reading the object matrix's translation
    //
    // WHY THE MASK LIVES IN THE MESH: the previous foliage sway (Tarrock/FoliageWind) masks by
    // world height above unity_ObjectToWorld's translation, which STATIC BATCHING silently
    // destroys — batching bakes vertices into world space and hands every renderer an identity
    // matrix, so the mask blew up and the sway vanished (fixed once already, commit 48712b9).
    // Here the mask and the height are VERTEX ATTRIBUTES: they are correct under GPU instancing,
    // under static batching, and under any object scale. The only things read from the instance
    // matrix are (a) the vertical scale, and (b) the tuft's world origin used to seed colour
    // variation — both of which degrade to "uniform but harmless" rather than to breakage.
    //
    // MOTION / CANON (director ruling 2026-07-31, art-audio.md §The world-state is the art
    // direction). Three separate things, and keeping them separate is the whole design:
    //
    //   1. COMB — a STATIC lean along _WindAxis. "Wind-combed" is a SHAPE, not a movement: it is
    //      the pose the last wind left in a meadow that has not moved since. It is applied in
    //      world space regardless of the random Y rotation Unity gives each detail instance, which
    //      is what makes a meadow read combed instead of randomly bristled. The lean is stronger on
    //      exposed, scoured ground and gentler in the hollows, and its direction wanders a few
    //      degrees over tens of metres so the field is combed rather than sheared.
    //
    //      ROUND-3 FIX — THE FOLD. Round 2 leaned every blade of a tuft by the same amount, and the
    //      gauntlet review found the meadow still read as "symmetric radial fans": translating a
    //      radially symmetric star sideways leaves a radially symmetric star. A real combed stand is
    //      ASYMMETRIC — the upwind side of a tuft is folded over its own crown and the downwind side
    //      is drawn out — so _CombFold scales each blade's lean by where that blade sits relative to
    //      the axis (upwind blades lean HARDER, over the crown; downwind blades lean less because
    //      they are already lying out that way), and _CombDrift shifts the whole crown downwind on
    //      top of it. The blade's own direction comes from TEXCOORD1 rotated into world space, so
    //      the fold is measured against the instance's actual orientation — it survives the random
    //      Y rotation the terrain gives every detail, which an object-space azimuth bias baked into
    //      the mesh would not (it would be rotated to a different bearing per instance and average
    //      out to nothing across the field).
    //   2. AMBIENT SWAY — gated ENTIRELY on _TarrockWindStrength. At the bound value (0) there is
    //      no motion at rest whatsoever; the meadow holds its breath with everything else. The
    //      round-1 build carried a small always-on sway baseline; the director removed it. Sway is
    //      now what the region GAINS when its Arcanum is unbound, which is what the canon says.
    //   3. DISPLACEMENT RESPONSE — the bound world still yields to TOUCH. Tarrock.Regions.
    //      GrassBender (on the Fool's rig and on Pip) publishes bend centres into the
    //      _TarrockBender* globals; the grass pushes radially away from each and settles back as
    //      the bender's wake fades. The stasis is the world's, not the Fool's.
    //
    //      ROUND-3 FIX — THE RING HAS TO READ IN A STILL. Round 2's falloff was a smoothstep from
    //      the centre outward: mathematically a dish, optically a vague thinning that the gauntlet
    //      review could not find in the frame at all. _BendCoreShare holds the inner share of the
    //      radius fully laid over and spends the whole falloff on the outer rim instead, which is a
    //      flattened DISC with an edge — the shape a body standing in grass actually leaves, and
    //      the shape a still photograph can show. Roots stay anchored either way: the lean is
    //      scaled by COLOR.a, which is 0 at every blade's base.
    //
    // ROUND-4 PASS (2026-07-31 gauntlet critique of round3/v6, v7). Three findings:
    //
    //   i.   ONE BEARING, NOT TWO. "Teal stubble splays symmetric while tall yellow blades lean
    //        left." True, and no lean value could have fixed it: round 3 combs by translating a
    //        tip, which a tall thin species notices and a short broad one does not (a sedge splays
    //        0.19 m and leans 0.055 m). _CombRake rakes the FAN instead of the tip, so every layer
    //        is drawn out on one bearing regardless of how radial its blade layout is.
    //   ii.  THE RING THAT WAS ALWAYS THERE. Re-projected through v6's own vantage, the stand-in's
    //        feet land at pixel (960, 999) and the 0.72 m ring spans 723-1169 px — and it IS in the
    //        frame, as a clean disc with no upright blades in it. The bend coordinates were never
    //        wrong. Blades laid to exactly flat simply read as blades that are not there, so the
    //        ring photographed as one more bald patch. _BendLayDegrees and _BendDarken give it a
    //        silhouette and a value.
    //   iii. THE MAT. "Discrete brown starburst cards lying BESIDE tufts on smooth untextured
    //        terrain." That is the thatch prototype, and the fix is on the generator's side of the
    //        contract — see TerrainRegionGenerator's SpeciesThatch and SpeciesScuff.
    //
    // THE THATCH. A fifth prototype (TerrainRegionGenerator's SpeciesThatch) shares this shader: a
    // 2-5 cm mat of near-horizontal cards, tinted to the ground shader's own turf palette and
    // darkened at the root by _RootDarken. It is not decoration — round 2's meadow was tufts
    // standing as isolated plants on naked terrain, because between two neighbouring tufts there
    // was nothing but the ground pass. The mat is what buries their bases. It needs no special
    // casing here; it is a species whose blades are short, wide and splayed nearly flat.
    //
    // MUST support instancing: Terrain renders mesh details via GPU instancing (useInstancing on
    // the DetailPrototype); a shader without it renders nothing or falls back per-object.
    Properties
    {
        [Header(Colour)]
        // Three tints on ONE dryness axis, not two: hollows run cool blue-green, the meadow body
        // runs mid green, scoured ground runs dry gold-straw. The round-1 build lerped green->gold
        // only and the whole meadow measured inside a 10-degree hue band (62-72 deg) — one note,
        // played everywhere. The cool end is what turns that band into a chord.
        _CoolColor ("Hollow Blue-Green Tint", Color) = (0.22, 0.46, 0.42, 1)
        _BaseColor ("Green Tint", Color) = (0.33, 0.54, 0.22, 1)
        _DryColor ("Dry Gold-Straw Tint", Color) = (0.82, 0.70, 0.34, 1)
        _DryBias ("Dry Bias", Range(0, 1)) = 0.5
        _PatchScale ("Dry Patch Scale (m)", Float) = 26
        _TuftVariation ("Tuft Hue Variation", Range(0, 1)) = 0.55
        _ValueVariation ("Tuft Value Variation", Range(0, 0.5)) = 0.18

        [Header(Turf blend)]
        // The ground builder owns the turf albedo; the generator passes its palette in here so the
        // tuft's ROOTS can be tinted toward the ground they grow out of. Without this the tufts sit
        // on the floor like stickers and the gap between them reads as blank painted ground.
        _GroundColor ("Turf Colour", Color) = (0.30, 0.36, 0.22, 1)
        _GroundDryColor ("Turf Dry Colour", Color) = (0.55, 0.47, 0.28, 1)
        _BaseBlend ("Base Blend To Turf", Range(0, 1)) = 0.6
        _BaseBlendHeight ("Base Blend Height (share of tuft)", Range(0.05, 1)) = 0.5
        // Contact shade. A blade lit the same at its root as at its tip is a sticker; real ground
        // cover is in its own shadow down there. 1 = off (round-2 behaviour exactly), and the
        // thatch runs it hardest because the thatch IS the layer everything else sits in.
        _RootDarken ("Root Darken (multiplier at the root)", Range(0.3, 1)) = 1.0

        [Header(Lighting)]
        _ShadeWrap ("Shade Wrap", Range(0, 1)) = 0.55
        _AmbientBoost ("Ambient Boost", Range(0, 2)) = 1.0

        // THE SHADE FILL (round 5). Round 4's shaded grass lost its texture completely: measured
        // against the round-4 captures, shadowed mat detail ran at 0.269 of the lit mat's in v1 and
        // 0.281 in v7, where seven reference-board frames run 0.485-0.931 (median 0.673). The cause
        // is not the detail — it is the exposure. Frag's colour is albedo x (direct + ambient), so
        // in shadow the ONLY term left is SampleSH, which at this rig measures about 7% of the
        // direct term: shaded grass sat at 0.175 of the lit mat's luminance where the same seven
        // references run 0.21-0.49 (median 0.37). Detail that is multiplied by a seventh of the
        // light is a seventh as visible, and no amount of contrast in the albedo can survive it.
        //
        // So the fix is light, not texture. _ShadeFill is the dawn SKY DOME — a large, cool, purely
        // ambient source that the sun's own beam swamps in the open and that is left holding the
        // frame wherever the beam does not reach. It is gated to the shaded side (see Frag), so it
        // cannot touch the lit meadow's pale dawn gold: the lit read is unchanged by construction.
        // At 1.0 the model puts shaded mat at 0.296 of lit luminance and shadowed detail at 0.501
        // of lit — both inside the reference band — and drops shaded saturation from 0.906 to 0.826
        // on the way, which is the same move the references make (their shade is cool, not grey).
        _ShadeFill ("Shade Fill (dawn sky dome)", Color) = (0.42, 0.52, 0.72, 1)
        _ShadeFillStrength ("Shade Fill Strength", Range(0, 2)) = 1.0

        // Sky occlusion down the blade. The fill above would be a flat wash on its own, and a flat
        // wash is the round-3 failure with the lights turned up. The sky is ABOVE the mat, so a
        // card lying on the floor sees a sliver of it and a tip standing clear sees all of it —
        // which gives the shaded mat a root-to-tip value swing that is its own, rather than a copy
        // of the lit one. It multiplies ONLY the ambient path, so it is nearly invisible in the sun
        // (where direct dominates) and is most of the picture in shade: measured relative contrast
        // stays at 1.69x the lit mat's, inside the references' 1.39-3.24.
        _SkyOcclusionRoot ("Sky Occlusion At The Root", Range(0, 1)) = 0.45

        [Header(Wind combed pose)]
        _TuftHeight ("Tuft Mesh Height (m)", Float) = 0.3
        _WindAxis ("Comb Axis (XZ)", Vector) = (1, 0.35, 0, 0)
        _CombLean ("Comb Lean (share of height)", Range(0, 1)) = 0.34
        _CombHollowLean ("Comb Lean In Hollows (share of full)", Range(0, 1)) = 0.42
        _CombWanderLength ("Comb Wander Length (m)", Float) = 46
        _CombWanderDegrees ("Comb Wander (deg)", Range(0, 45)) = 14
        // The asymmetry. Fold scales a blade's lean by which side of the tuft it grew on (upwind
        // blades fold over the crown); drift shifts the whole crown downwind regardless. 0 on both
        // reproduces round 2's symmetric translation.
        _CombFold ("Comb Fold (upwind blades over the crown)", Range(0, 1)) = 0.5
        _CombDrift ("Comb Crown Drift (share of height)", Range(0, 0.6)) = 0.12
        // ROUND-4 — THE RAKE, and the fix for "ONE lean bearing across ALL layers". Round 3's comb
        // leans a blade by TRANSLATING its tip along the axis, scaled by that blade's height. That
        // works on a tall thin species, whose tip travels further than its own splay, and it does
        // almost nothing to a short broad one: the sedge stands 0.22 m tall and splays 0.19 m, so a
        // 0.36 lean moves its tips 5.5 cm against a 19 cm radial fan and the tuft stays a symmetric
        // star ("teal stubble splays symmetric while tall yellow blades lean left" — round-4
        // critique of v6/v7). No lean value fixes that, because the fault is in the FAN, not the tip.
        //
        // The rake works on the fan itself: the vertex's offset from its own root is stretched along
        // the comb axis and squeezed across it, so every species' silhouette is drawn out on ONE
        // bearing no matter how radial its blade layout is. It is a static change of shape — the
        // pose the last wind left — never an animation, and it is applied in world space off
        // TEXCOORD1 rotated by the instance matrix, so it survives the random Y rotation Unity gives
        // each detail instance (an object-space version would point somewhere different per tuft and
        // average to nothing across the field).
        _CombRake ("Comb Rake (fan stretched along the axis)", Range(0, 1)) = 0.5

        [Header(Unbound wind)]
        // Zero-at-bound by construction: every term below is multiplied by _TarrockWindStrength.
        _SwayStrength ("Unbound Sway (share of height)", Range(0, 1)) = 0.34
        _SwaySpeed ("Sway Speed (rad per s)", Float) = 0.85
        _SwayWavelength ("Sway Wave Length (m)", Float) = 14
        _WindResponse ("Unbound Wind Response", Range(0, 4)) = 1.0

        [Header(Displacement response)]
        // Above 1 the blade simply reaches flat before the falloff does, which is what makes the
        // middle of a bend ring a laid patch rather than a dimple. It cannot go further: the arc
        // clamps it (see ShapeTuft), so there is no value here that pushes a tip through the ground.
        _BendStrength ("Bend Strength (share of height)", Range(0, 3)) = 1.15
        _BendHeightRange ("Bend Height Range (m)", Float) = 1.8
        // Share of the bend radius held fully laid over before the rim falloff starts. 0 restores
        // round 2's centre-to-rim smoothstep; anything above it turns the dish into a disc with an
        // edge you can see in a still frame.
        _BendCoreShare ("Bend Core (share of radius held flat)", Range(0, 0.9)) = 0.5
        // ROUND-4, and the two lines that decide whether the ring photographs at all.
        //
        // THE RING WAS ALWAYS THERE. Re-projecting round3/v6 through its own vantage puts the
        // stand-in's feet at pixel (960, 999) and the 0.72 m ring at 723-1169 px across — and the
        // crop shows it: a clean disc of ground under him with no upright blades in it. The bend
        // coordinates were never wrong. What was wrong is that a blade laid FLAT is not a laid
        // blade to the eye, it is an absent one: the ring rendered as a bald patch, identical in
        // value and silhouette to the bare ground the critique has been calling a fault for three
        // rounds. So the ring was invisible for the same reason bare ground is ugly.
        //
        //   _BendLayDegrees stops the press at ~70-75° from vertical instead of 90°, so a pressed
        //   blade keeps a third of its height and lies OUTWARD as a visible radial spoke. This is
        //   what a body actually leaves — grass laid over, not grass deleted.
        //   _BendDarken gives the pressed area its own value. Crushed ground cover is darker: the
        //   blades lie over their own root shadow and stop catching the sun edge-on. A still frame
        //   reads an area by its value before it reads it by its silhouette.
        _BendLayDegrees ("Bend Lay Angle (deg from vertical)", Range(30, 90)) = 72
        _BendDarken ("Bend Darken (multiplier inside the ring)", Range(0.4, 1)) = 0.78

        // ROUND 5: THE RING READS AS A SMUDGE, AND THE REASON IS THAT IT IS ONE.
        //
        // Round 4's ring measures correctly in the radial direction (the critic's R = 0.215) and
        // still photographs as a soft dark patch. Two faults, and neither is the radius.
        //
        //   IT IS TOO WIDE, AND ITS EDGE IS SPENT. With _BendCoreShare at 0.58 the held floor of the
        //   Fool's 0.72 m ring is 0.418 m in radius — 0.835 m across against a 0.45 m shoulder, or
        //   1.86x shoulder width, which is the 1.5-1.8x the critic measured. Worse, the whole
        //   falloff is spent on a 0.302 m skirt, so the ring has no edge anywhere: it is a gradient
        //   from the middle to the grass. The species tables now run a 0.375 core, which puts the
        //   clearing at 0.540 m across = 1.20x shoulder, exactly the brief's target, and hands the
        //   remaining 0.45 m to a rim that can be shaped rather than merely crossed.
        //
        //   IT IS THE SAME TERM AS A SHADOW. _BendDarken multiplies albedo and nothing else, so
        //   "parted grass" and "something is casting a shadow here" are, to the renderer and to the
        //   eye, literally the same signal. Two terms separate them. _BendTurfPull moves the pressed
        //   area's HUE toward the floor it has been pressed into (you are seeing mat and blade
        //   undersides, not a darker version of the canopy) — a shadow never changes hue like that.
        //   _RingRimLift puts a narrow BRIGHT band on the contact line, where the blades that were
        //   shoved outward stand shouldered-up and catch the low sun on their flanks. A value BREAK
        //   at the boundary is the one cue a still frame reads as an edge, and a shadow cannot have
        //   one: shadows have soft dark edges, parted grass has a bright shoulder.
        _BendTurfPull ("Bend Turf Pull (pressed area toward the floor colour)", Range(0, 1)) = 0.45
        _RingRimLift ("Ring Rim Lift (brightness at the contact line)", Range(0, 1)) = 0.34
        _RingRimWidth ("Ring Rim Width (share of radius)", Range(0.02, 0.5)) = 0.16

        [Header(Distance handling)]
        _WidenStart ("Widen Start (m)", Float) = 18
        _WidenEnd ("Widen End (m)", Float) = 70
        _WidenMax ("Widen Max", Range(1, 4)) = 2.4
        _FadeStart ("Fade Start (m)", Float) = 78
        _FadeEnd ("Fade End (m)", Float) = 114
        _FadeMinScale ("Fade Min Height", Range(0, 1)) = 0.08
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
        Cull Off // blades are single-sided strips and read from both sides

        // Shared across every pass so the UnityPerMaterial layout and the displacement are defined
        // once — the SRP Batcher requires an identical per-material CBUFFER in all passes, and the
        // depth vertex MUST use the SAME displacement as the forward vertex or the depth prepass
        // (PC_RPAsset requires a depth texture; PC_Renderer's SSAO samples it) disagrees with what
        // is drawn.
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        // MUST match Tarrock.Regions.GrassBender.MaxSlots. The loop is unrolled over the whole
        // array and empty slots carry a zero radius, so a shorter C# array would leave stale
        // benders live and a longer one would be silently truncated.
        #define TARROCK_MAX_BENDERS 8

        CBUFFER_START(UnityPerMaterial)
            float4 _CoolColor;
            float4 _BaseColor;
            float4 _DryColor;
            float _DryBias;
            float _PatchScale;
            float _TuftVariation;
            float _ValueVariation;
            float4 _GroundColor;
            float4 _GroundDryColor;
            float _BaseBlend;
            float _BaseBlendHeight;
            float _RootDarken;
            float _ShadeWrap;
            float _AmbientBoost;
            float4 _ShadeFill;
            float _ShadeFillStrength;
            float _SkyOcclusionRoot;
            float _TuftHeight;
            float4 _WindAxis;
            float _CombLean;
            float _CombHollowLean;
            float _CombWanderLength;
            float _CombWanderDegrees;
            float _CombFold;
            float _CombDrift;
            float _CombRake;
            float _SwayStrength;
            float _SwaySpeed;
            float _SwayWavelength;
            float _WindResponse;
            float _BendStrength;
            float _BendHeightRange;
            float _BendCoreShare;
            float _BendLayDegrees;
            float _BendDarken;
            float _BendTurfPull;
            float _RingRimLift;
            float _RingRimWidth;
            float _WidenStart;
            float _WidenEnd;
            float _WidenMax;
            float _FadeStart;
            float _FadeEnd;
            float _FadeMinScale;
        CBUFFER_END

        // GLOBALS — deliberately OUTSIDE UnityPerMaterial so Shader.SetGlobal* reaches them and one
        // write sweeps every grass material at once. A global inside the per-material CBUFFER would
        // neither receive the value nor be SRP-Batcher-legal.
        //
        //   _TarrockWindStrength   0 while the region is bound, rising when it unbinds
        //                          (Tarrock.Regions.RegionWind)
        //   _TarrockBenderData     xyz = bend centre in world space, w = radius in metres
        //   _TarrockBenderPower    x   = strength 0..1; a wake point decays this to 0 as the grass
        //                          stands back up. Kept as float4 rather than a float array so the
        //                          upload is one SetGlobalVectorArray with no per-platform
        //                          scalar-array padding to reason about.
        //   _TarrockBenderBounds   xyz = centre, w = radius of a sphere enclosing every live
        //                          bender, so the whole loop can be rejected with one test. w = 0
        //                          means "nobody is touching the grass" and rejects everywhere.
        float _TarrockWindStrength;
        float4 _TarrockBenderData[TARROCK_MAX_BENDERS];
        float4 _TarrockBenderPower[TARROCK_MAX_BENDERS];
        float4 _TarrockBenderBounds;

        struct Attributes
        {
            float4 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 color : COLOR;
            float2 uv : TEXCOORD0;
            float2 rootOffsetOS : TEXCOORD1;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct ShapedTuft
        {
            float3 positionWS;
            float3 normalWS;
            float3 albedo;
            // How much of the sky dome this vertex can see, 0 at the mat floor to 1 at a free tip.
            // Carried to the fragment because it modulates only the AMBIENT path (see Frag) — it is
            // a property of where the vertex sits in the mat, not of its albedo, and baking it into
            // albedo would darken the sunlit meadow for no reason.
            float skyOcclusion;
        };

        // Cheap deterministic hash of a world XZ position — used only for per-tuft scatter, so a
        // little banding on exotic hardware is invisible. World coordinates stay inside the 256 m
        // tile, well within the range where sin-hashing is stable.
        float HashXZ(float2 p, float2 k)
        {
            return frac(sin(dot(p, k)) * 43758.5453);
        }

        // The broad dryness/exposure drift, 0 (hollow, sheltered, cool) .. 1 (scoured, exposed,
        // dry). Three non-harmonic sines — cheaper than a texture fetch and with no wrap seam.
        // _PatchScale is the drift's WAVELENGTH in metres, hence the 2*pi: the three sines land at
        // roughly 26 m, 31 m and 19 m, which is the scale a scoured hillside actually goes gold at.
        // ONE field drives colour AND comb strength on purpose — a meadow's gold patches are its
        // exposed patches, so the same ground that goes dry is the ground the wind lies flattest.
        float ExposureDrift(float2 positionXZ)
        {
            float2 p = positionXZ * (6.2831853 / max(_PatchScale, 0.5));
            float drift = sin(p.x + 1.7)
                        + sin(p.y * 0.83 - 0.4)
                        + sin((p.x * 0.61 + p.y * 0.79) * 1.37 + 2.9);
            return saturate(0.5 + drift * 0.19);
        }

        // Total sideways push at one vertex, in metres, from every live bender. Radial and outward:
        // grass is shoved AWAY from the body, never toward it, so the ring around a standing figure
        // opens rather than closing on him.
        // ROUND 5: `rim` comes back alongside the push — 1 exactly on the contact line, falling to 0
        // on both sides of it within _RingRimWidth. It has to be produced HERE because it is a fact
        // about the radial profile (where t crosses the core edge), and by the time ShapeTuft has a
        // push vector that information has been summed away across benders and cannot be recovered.
        float2 BenderPush(float3 positionWS, out float rim)
        {
            rim = 0.0;
            // One test rejects the whole meadow when nobody is near it (and always, when nobody is
            // bending at all — the bounds radius is exactly 0 then, which is the sentinel and why
            // the inflation below is conditional rather than added unconditionally).
            //
            // The sphere the CPU sends covers the benders' RADII; the height gate below reaches a
            // further _BendHeightRange vertically, so the test has to be inflated by it or the
            // early-out would clip the push to zero part-way down a slope and leave a hard rim.
            float reach = _TarrockBenderBounds.w > 0.0 ? _TarrockBenderBounds.w + _BendHeightRange : 0.0;
            float3 toField = positionWS - _TarrockBenderBounds.xyz;
            if (dot(toField, toField) > reach * reach)
            {
                return float2(0.0, 0.0);
            }

            float2 push = float2(0.0, 0.0);

            [unroll]
            for (int i = 0; i < TARROCK_MAX_BENDERS; i++)
            {
                float4 bender = _TarrockBenderData[i];
                float power = _TarrockBenderPower[i].x;

                float2 delta = positionWS.xz - bender.xz;
                float spread = length(delta);

                // Radial profile: the inner _BendCoreShare of the radius is held at FULL press and
                // the whole smooth falloff is spent on the rim outside it. Round 2 ran the
                // smoothstep from the centre (which is this with a core share of 0, and is exactly
                // what the identity 1 - smoothstep(t) == smoothstep(1 - t) says); the result was a
                // gentle dish that the gauntlet review could not locate in the frame. A laid patch
                // with an EDGE is what a still can show, and it is also the truer shape: a body
                // does not press grass proportionally harder as it approaches its own centre — it
                // stands on it, and the grass at the rim is what is merely leaned on.
                // (The 0.95 cap is not cosmetic: smoothstep's own edges must not meet, or the rim
                // divides by zero.)
                float t = spread / max(bender.w, 0.01);
                float core = min(saturate(_BendCoreShare), 0.95);
                float radial = 1.0 - smoothstep(core, 1.0, t);

                // Height gate: a bender on the clifftop must not press the meadow seven metres
                // below it. Grass is ankle-high, so the band only has to cover a body's own stride.
                float vertical = 1.0 - saturate(abs(positionWS.y - bender.y) / max(_BendHeightRange, 0.1));

                // The contact line is where the held floor ends and the grass begins to stand back
                // up — t == core. A triangular window around it, carrying this bender's own gates so
                // a settling wake loses its shoulder as it closes rather than leaving a bright ring
                // behind, and so a bender overhead leaves none at all. Rims accumulate by max(), not
                // by sum: two overlapping rings share one shoulder where they touch, and summing
                // would double it into a seam.
                float rimHalf = max(_RingRimWidth, 0.02);
                rim = max(rim, saturate(1.0 - abs(t - core) / rimHalf) * vertical * power);

                push += (delta / max(spread, 1e-4)) * (radial * vertical * power);
            }

            // More than one bender overlapping should deepen the dish, not launch the blade — cap
            // the combined push at one full bend.
            float magnitude = length(push);
            return magnitude > 1.0 ? push / magnitude : push;
        }

        // The whole per-vertex job: pose, comb, sway, bend, distance-squash and tint one vertex.
        ShapedTuft ShapeTuft(Attributes input)
        {
            ShapedTuft o = (ShapedTuft)0;

            float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
            o.normalWS = TransformObjectToWorldNormal(input.normalOS);

            // Vertical scale of THIS instance (Unity randomises detail height between the
            // prototype's min/max), taken from the Y column of the instance matrix. Under static
            // batching this reads 1, which simply means "prototype size" — bounded, never broken.
            float scaleY = length(float3(unity_ObjectToWorld._m01, unity_ObjectToWorld._m11, unity_ObjectToWorld._m21));
            float tuftHeight = _TuftHeight * max(scaleY, 1e-3);
            float heightAboveBase = input.uv.y * tuftHeight;

            // colour.a is the mesh-baked lean mask; multiplying by tuftHeight turns the unitless
            // mask into "how many metres of blade are above this vertex's anchor".
            float leanMetres = input.color.a * tuftHeight;

            float viewDistance = length(positionWS - GetCameraPositionWS());

            // Blades are ~3 cm wide, which is right underfoot and sub-pixel by 30 m — thin enough
            // to shimmer and to let the meadow dissolve into speckle at mid range. Widen the tuft
            // about its own root with distance so coverage holds and the far meadow resolves into
            // soft ground cover instead of noise. The offset comes from TEXCOORD1 (object space),
            // not from the matrix translation, so this is correct under batching too.
            float widen = lerp(1.0, _WidenMax,
                smoothstep(_WidenStart, max(_WidenEnd, _WidenStart + 1.0), viewDistance));
            float3 rootOffsetWS = mul((float3x3)unity_ObjectToWorld, float3(input.rootOffsetOS.x, 0.0, input.rootOffsetOS.y));

            // -- 1. The comb: a STATIC lean, the shape the last wind left.
            // The axis WANDERS by a few degrees over tens of metres. A single constant direction
            // across a whole region is a shear, not a wind: real combed ground curves around the
            // landform, and the eye reads the curvature as air having moved through.
            //
            // The axis is resolved BEFORE the tuft is widened or raked (round 4), because both of
            // those are measured against it. It is taken off the tuft's un-widened world position,
            // which moves by centimetres at most — the wander is a 46 m field, so nothing here can
            // notice.
            float2 axis = normalize(_WindAxis.xy + float2(1e-5, 0.0));
            float wander = sin(dot(positionWS.xz, float2(0.71, 0.70)) * (6.2831853 / max(_CombWanderLength, 1.0)))
                         * radians(_CombWanderDegrees);
            float wanderSin, wanderCos;
            sincos(wander, wanderSin, wanderCos);
            axis = float2(axis.x * wanderCos - axis.y * wanderSin, axis.x * wanderSin + axis.y * wanderCos);

            // THE RAKE (round 4, see the header). The fan itself is stretched along the comb axis
            // and squeezed across it, which is the only construct here that puts a SHORT BROAD
            // species on the same bearing as a tall thin one — a tip translation cannot, because a
            // sedge's splay is three times its own lean. Distance widening rides in the same
            // expression (it is a uniform scale of the same offset), so the vertex is displaced
            // once rather than twice.
            //
            // The across term shrinks by 0.6 of the rake rather than by the whole of it: squeezing
            // a fan to a line is a fin, not a combed tuft, and grass keeps some width across the
            // wind even after three hundred years of it.
            float2 lateral = rootOffsetWS.xz * widen;
            float alongLength = dot(lateral, axis);
            float2 acrossVec = lateral - (axis * alongLength);
            float2 raked = (axis * (alongLength * (1.0 + _CombRake)))
                         + (acrossVec * (1.0 - _CombRake * 0.6));
            positionWS.xz += raked - rootOffsetWS.xz;

            float exposure = ExposureDrift(positionWS.xz);

            // Exposed ground was scoured flatter than sheltered ground: the hollows keep more of
            // their stand. Same field as the dry tint, so gold ground and flattened ground agree.
            float combField = lerp(_CombHollowLean, 1.0, exposure);

            // THE FOLD (see the header). Which side of its own tuft did this blade grow on? The
            // answer is TEXCOORD1 — the blade's XZ offset from the root — rotated into world space,
            // which is the one direction available here that carries the instance's random Y
            // rotation. dot() against the comb axis is +1 for a blade already lying downwind and -1
            // for one pointing into the wind; the upwind blade is the one that gets folded back
            // over the crown, so the lean is scaled UP on the negative side.
            //
            // Without this, comb is a rigid translation of a radially symmetric fan and the fan
            // stays symmetric — the exact finding round 2 came back with. Measured on the RAKED
            // offset so the fold and the rake agree about which side of the tuft a blade is on.
            float rootReach = length(raked);
            float alongAxis = rootReach > 1e-4 ? dot(raked / rootReach, axis) : 0.0;
            float fold = 1.0 - (_CombFold * alongAxis);

            // The crown drift is NOT folded: it is the whole tuft carried downwind, which is what
            // stops a folded tuft from merely being a lopsided star centred on its own root.
            float comb = (_CombLean * fold + _CombDrift) * combField;

            // -- 2. Ambient sway: zero while bound, by construction.
            float windAmount = saturate(_TarrockWindStrength) * _WindResponse;
            float sway = 0.0;
            if (windAmount > 1e-4)
            {
                // A travelling wave: the phase is read from the vertex's WORLD position, so the
                // same crest visits neighbouring tufts a moment apart and the meadow moves in bands
                // instead of pulsing in lockstep. World position is batching- and instancing-proof.
                float travel = dot(positionWS.xz, axis) / max(_SwayWavelength, 0.5);
                float time = _Time.y * _SwaySpeed;
                float phase = input.uv.x * 6.2831853;
                float wave = sin(time - travel + phase * 0.30)
                           + 0.22 * sin(time * 2.17 - travel * 1.63 + phase);
                sway = wave * 0.82 * _SwayStrength * windAmount;
            }

            // -- 3. Displacement response: the world yields to touch even while it is bound.
            float ringRim;
            float2 rawPush = BenderPush(positionWS, ringRim);
            // How hard this vertex is being pressed, before the species' own strength multiplies
            // it — 0 outside every ring, 1 in a held core. Used for the ring's albedo below.
            float pressed = saturate(length(rawPush));
            float2 bend = rawPush * _BendStrength;

            // EXACT pendulum arc, not the small-angle approximation. A blade is a rigid length
            // pivoting at its anchor: lean it sideways by s and the vertical shortens to
            // sqrt(L^2 - s^2), so the tip travels a circle. The round-1 build used the s^2/2L
            // approximation, which is fine for the ~0.3 comb it carried but sends a tip UNDERGROUND
            // once the displacement response can lay a blade right over — s is clamped here for the
            // same reason: a leaning blade is not a stretched one.
            //
            // ROUND-4: the clamp is now _BendLayDegrees rather than a flat 90°. A blade laid to
            // exactly flat has no silhouette and no height, and the ring it makes is optically
            // identical to bare ground — which is why three rounds of review could not find a ring
            // that was, measurably, right there (see the property). At 72° a pressed blade keeps
            // 31% of its height and points outward as a readable spoke.
            float2 offset = (axis * ((comb + sway) * leanMetres)) + (bend * leanMetres);
            float leanLength = max(leanMetres, 1e-4);
            float layLimit = sin(radians(clamp(_BendLayDegrees, 20.0, 90.0)));
            float sideways = min(length(offset), leanLength * layLimit);
            positionWS.xz += (offset / max(length(offset), 1e-4)) * sideways;
            positionWS.y -= leanLength - sqrt(max((leanLength * leanLength) - (sideways * sideways), 0.0));

            // Distance fade — squash tufts INTO the ground over the last stretch of the detail
            // draw distance instead of letting Unity's per-patch cull draw a hard line across the
            // meadow. Height-squash (not alpha) because the pass is opaque, and it doubles as an
            // overdraw/aliasing win at range. Keep _FadeEnd under Terrain.detailObjectDistance so
            // the tufts are already flat by the time the patch is culled.
            float fade = 1.0 - smoothstep(_FadeStart, max(_FadeEnd, _FadeStart + 1.0), viewDistance);
            positionWS.y -= heightAboveBase * (1.0 - lerp(_FadeMinScale, 1.0, fade));

            // -- Tint. Fine variation comes from the instance origin, so it is genuinely per tuft.
            float2 pivotXZ = float2(unity_ObjectToWorld._m03, unity_ObjectToWorld._m23);
            float hueHash = HashXZ(pivotXZ, float2(12.9898, 78.233));
            float valueHash = HashXZ(pivotXZ, float2(39.3468, 11.1359));

            float dryness = saturate(_DryBias + (exposure - 0.5) * 1.4 + (hueHash - 0.5) * _TuftVariation);
            // Two-sided ramp about the middle: cool blue-green in the hollows, green through the
            // body of the meadow, gold-straw where the wind has scoured it.
            float3 tint = dryness < 0.5
                ? lerp(_CoolColor.rgb, _BaseColor.rgb, saturate(dryness * 2.0))
                : lerp(_BaseColor.rgb, _DryColor.rgb, saturate((dryness - 0.5) * 2.0));
            tint *= 1.0 + (valueHash - 0.5) * 2.0 * _ValueVariation;

            float3 albedo = input.color.rgb * tint;

            // Roots dissolve into the turf. The ground's own dryness is read from the SAME drift,
            // so a tuft standing on gold ground has a gold root and a tuft in a green hollow has a
            // green one — the tufts grow out of the floor instead of being stuck onto it.
            float3 turf = lerp(_GroundColor.rgb, _GroundDryColor.rgb, exposure);
            float rootWeight = 1.0 - smoothstep(0.0, max(_BaseBlendHeight, 0.05), input.uv.y);
            albedo = lerp(albedo, turf, rootWeight * _BaseBlend);

            // Contact shade — the base of ground cover sits in its own shadow. Baked into albedo
            // rather than lit for it: this grass has no shadow-caster pass on purpose (see below),
            // so nothing else in the frame is going to darken a tuft's own root for us, and a mat
            // of thatch lit evenly from root to tip is a sheet of paper. This is also what makes
            // the thatch read as a layer WITH depth that the tufts stand in, rather than a second
            // flat colour laid beside the ground pass.
            albedo *= lerp(1.0, saturate(_RootDarken), rootWeight);

            // THE RING'S OWN VALUE (round 4). Crushed ground cover is darker than standing cover:
            // the blades lie over their own root shadow, they stop catching a low sun edge-on, and
            // what was a lit vertical face becomes a shaded horizontal one. Baked into albedo
            // because the lighting cannot know — the blade's normal is deliberately biased to +Y
            // and barely moves when the blade goes over, which is right for the meadow at large and
            // exactly wrong for a pressed disc. A still frame reads an area by its value first.
            albedo *= lerp(1.0, saturate(_BendDarken), pressed);

            // ROUND 5, AND THE PART THAT MAKES IT A RING RATHER THAN A STAIN. The line above is a
            // pure value multiply, which is exactly what a shadow is — so for four rounds the ring
            // has been rendering the one signal the eye is guaranteed to read as "something above
            // is blocking the light". Two terms give it an identity of its own.
            //
            // HUE, not just value: pressed grass shows the mat it was pressed into and the pale
            // undersides of its own blades, so the area moves toward the FLOOR's colour. A cast
            // shadow never changes hue — it scales every channel by the same light. This is what
            // makes the disc read as parted rather than as darkened.
            float3 pressedTurf = lerp(_GroundColor.rgb, _GroundDryColor.rgb, exposure);
            albedo = lerp(albedo, albedo * 0.62 + pressedTurf * 0.38, pressed * _BendTurfPull);

            // A VALUE BREAK ON THE CONTACT LINE. The blades at the boundary were shoved outward and
            // are standing shouldered-up against the ones still upright, catching a 12° sun on their
            // flanks. A narrow BRIGHT band is the one cue a still frame reads as an edge, and it is
            // a cue a shadow structurally cannot produce: shadow edges are soft and dark on the
            // inside. This is why the round-4 ring measured right radially (R = 0.215) and still
            // photographed as a smudge — it had a profile but no boundary.
            albedo *= 1.0 + ringRim * _RingRimLift;

            // Sky visibility down the blade. uv.y is the vertex's share of its own mesh height, so
            // this is "how clear of the mat am I" — and the mat is the thatch, which is why the
            // thatch runs the deepest occlusion of the six species. A blade laid over by the bend
            // ring has climbed DOWN into the mat, so the press closes it toward the root value too;
            // that is what keeps the pressed disc from lighting up as a bright hole in shade.
            float sky = lerp(saturate(_SkyOcclusionRoot), 1.0, input.uv.y);
            o.skyOcclusion = lerp(sky, saturate(_SkyOcclusionRoot), pressed * 0.7);

            o.positionWS = positionWS;
            o.albedo = albedo;
            return o;
        }
        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            #pragma target 3.0
            #pragma multi_compile_instancing
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                // .w carries the sky occlusion rather than spending a whole interpolator on one
                // scalar — this pass is already at four and mobile wants them back.
                float4 positionWS : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 albedo : TEXCOORD2;
                float fogCoord : TEXCOORD3;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings Vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                ShapedTuft tuft = ShapeTuft(input);
                output.positionCS = TransformWorldToHClip(tuft.positionWS);
                output.positionWS = float4(tuft.positionWS, tuft.skyOcclusion);
                output.normalWS = tuft.normalWS;
                output.albedo = tuft.albedo;
                output.fogCoord = ComputeFogFactor(output.positionCS.z);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);

                // NO VFACE flip: the mesh normals are deliberately biased toward +Y, so they are
                // valid from both sides. Flipping them for backfaces would put half the meadow in
                // shadow at any given camera angle — exactly the dark, spiky read we removed.
                float3 normalWS = normalize(input.normalWS);

                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS.xyz);
                Light mainLight = GetMainLight(shadowCoord);

                float ndotl = dot(normalWS, mainLight.direction);
                float wrapped = saturate((ndotl + _ShadeWrap) / (1.0 + _ShadeWrap));
                float lightReach = wrapped * mainLight.shadowAttenuation;
                float3 direct = mainLight.color * lightReach;

                // THE SHADE FILL (round 5) — see the property block for the measurements. This is
                // gated on how little of the beam reaches the surface, so it is worth nothing in the
                // open meadow and is holding the whole picture inside a shadow. Gating it this way,
                // rather than adding it to ambient outright, is deliberate: the lit meadow's pale
                // dawn gold is canon and a uniform fill would wash it. The lit read is unchanged.
                //
                // The 0.35 knee, not 1.0: a surface only half-reached by the beam is already reading
                // as shade to the eye, and running the fill in over the whole terminator instead of
                // the last sliver of it is what stops the boundary snapping into a visible line.
                float shadeMix = 1.0 - smoothstep(0.0, 0.35, lightReach);
                float3 fill = _ShadeFill.rgb * (_ShadeFillStrength * shadeMix);

                // Sky occlusion multiplies the AMBIENT path only. In sun this is a rounding error
                // against `direct`; in shade it is the entire root-to-tip value swing, which is what
                // keeps the mat reading as blades rather than as a flat dark patch. Measured on the
                // model: shaded detail rises from 0.320 to 0.501 of the lit mat's (references run
                // 0.485-0.931) and relative contrast holds at 1.69x lit (references 1.39-3.24).
                float3 ambient = (SampleSH(normalWS) * _AmbientBoost + fill) * input.positionWS.w;

                float3 color = input.albedo * (direct + ambient);
                color = MixFog(color, input.fogCoord);
                return half4(color, 1.0);
            }
            ENDHLSL
        }

        // Depth only — the SAME displacement as the forward vertex, so the depth prepass that
        // PC_RPAsset requires (and PC_Renderer's SSAO samples) agrees with the posed geometry.
        // Deliberately NO ShadowCaster pass, and the Fallback is Off: ankle-height grass casting
        // per-blade shadows is a cost with almost no picture in it, and a fallback-supplied
        // ShadowCaster would carry neither the comb nor the bend and would detach every shadow
        // from its blade.
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma vertex DepthVert
            #pragma fragment DepthFrag
            #pragma target 3.0
            #pragma multi_compile_instancing

            struct DepthVaryings
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            DepthVaryings DepthVert(Attributes input)
            {
                DepthVaryings output = (DepthVaryings)0;
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);

                ShapedTuft tuft = ShapeTuft(input);
                output.positionCS = TransformWorldToHClip(tuft.positionWS);
                return output;
            }

            half4 DepthFrag(DepthVaryings input) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                return 0;
            }
            ENDHLSL
        }
    }

    FallBack Off
}
