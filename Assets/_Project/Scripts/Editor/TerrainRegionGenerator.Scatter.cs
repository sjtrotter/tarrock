namespace Tarrock.Editor
{

    using System.Collections.Generic;
    using UnityEditor;
    using UnityEngine;

    // Partial of TerrainRegionGenerator: SCATTERED DRESSING.
    // Owns the dead tree, the suspended motes, and the rock outcrops (anchors, placement
    // rules and meshes) scattered across the region.
    public static partial class TerrainRegionGenerator
    {

        // -------------------------------------------------------------------------------------
        // Wave 2 dressing: the dead tree, the grass, the motes
        // -------------------------------------------------------------------------------------

        // The one dead tree, on the knoll — the Cliff's signature visual (art-audio.md §Region
        // colour scripts: "the one tree on the plateau that visibly dies"; MQ00 puts it on a
        // modest knoll). The ONLY object that breaks the skyline alone: it converts the green
        // field into a destination (rule 5, the landmark clause). Deterministic bare-branch mesh —
        // no leaves; the leaves' mid-fall moment is a later held-breath dressing pass. It leans
        // west, wind-combed toward the light and the leap.
        private static void BuildDeadTree()
        {
            Physics.SyncTransforms();
            var origin = new Vector3(KnollCentre.x, 200f, KnollCentre.y);
            if (!Physics.Raycast(origin, Vector3.down, out RaycastHit hit, 400f))
            {
                Debug.LogWarning("[Tarrock] Dead-tree raycast missed the knoll; tree skipped.");
                return;
            }

            Mesh mesh = BuildDeadTreeMesh();
            AssetDatabase.DeleteAsset(DeadTreeMeshPath);
            AssetDatabase.CreateAsset(mesh, DeadTreeMeshPath);

            // Bark on the house foliage shader with the sway nearly zeroed: a dead tree barely
            // creaks even when the wind returns, and while the region is bound the global wind is
            // 0 and it holds perfectly still (canon).
            Shader foliage = Shader.Find("Tarrock/FoliageWind");
            var bark = AssetDatabase.LoadAssetAtPath<Material>(DeadTreeMaterialPath);
            if (bark == null)
            {
                bark = new Material(foliage != null ? foliage : Shader.Find("Universal Render Pipeline/Lit"));
                AssetDatabase.CreateAsset(bark, DeadTreeMaterialPath);
            }
            else if (foliage != null)
            {
                bark.shader = foliage;
            }

            bark.SetColor("_BaseColor", new Color(0.23f, 0.19f, 0.16f)); // weathered near-black bark
            bark.SetFloat("_SwayAmplitude", 0.02f);
            bark.SetFloat("_FlutterAmplitude", 0.004f);
            EditorUtility.SetDirty(bark);

            var tree = new GameObject("DeadTree");
            tree.transform.position = hit.point;
            // ~11 m overall: the landmark must CREST the knoll from the spawn frame 70 m away —
            // an 8 m tree read as a twig at that range.
            tree.transform.localScale = Vector3.one * 1.35f;
            var filter = tree.AddComponent<MeshFilter>();
            filter.sharedMesh = mesh;
            var renderer = tree.AddComponent<MeshRenderer>();
            renderer.sharedMaterial = bark;
            renderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
            // Trunk collider only — branches are visual. Sized to the mesh's ~0.5 m trunk.
            var trunkCollider = tree.AddComponent<CapsuleCollider>();
            trunkCollider.center = new Vector3(0f, 2.6f, 0f);
            trunkCollider.height = 5.2f;
            trunkCollider.radius = 0.32f;
        }

        /// <summary>One gnarled bare tree, ~8 m: a kinked leaning trunk and seven tapered limbs,
        /// each limb an 8-vert tapered prism appended to one mesh. Hardcoded (art-directed), not
        /// randomised — the landmark should be a drawing, not a dice roll.</summary>
        private static Mesh BuildDeadTreeMesh()
        {
            var verts = new List<Vector3>();
            var cols = new List<Color>();
            var tris = new List<int>();

            // Limbs as (base, tip, baseRadius, tipRadius). The trunk is three stacked segments
            // with a westward lean and a kink; branches fork high, biased west.
            AddLimb(verts, cols, tris, new Vector3(0f, 0f, 0f), new Vector3(-0.25f, 2.2f, 0.05f), 0.50f, 0.36f);
            AddLimb(verts, cols, tris, new Vector3(-0.25f, 2.1f, 0.05f), new Vector3(-0.75f, 4.3f, -0.10f), 0.36f, 0.24f);
            AddLimb(verts, cols, tris, new Vector3(-0.75f, 4.2f, -0.10f), new Vector3(-0.95f, 5.6f, 0.05f), 0.24f, 0.10f);
            AddLimb(verts, cols, tris, new Vector3(-0.85f, 5.4f, 0.00f), new Vector3(-2.6f, 7.6f, 0.5f), 0.13f, 0.03f);  // crown W
            AddLimb(verts, cols, tris, new Vector3(-0.80f, 5.2f, 0.00f), new Vector3(0.6f, 7.9f, -0.4f), 0.12f, 0.03f);  // crown E
            AddLimb(verts, cols, tris, new Vector3(-0.60f, 4.6f, -0.05f), new Vector3(-2.9f, 5.9f, -1.6f), 0.11f, 0.03f); // mid SW
            AddLimb(verts, cols, tris, new Vector3(-0.55f, 4.4f, 0.00f), new Vector3(-1.9f, 5.3f, 1.9f), 0.10f, 0.03f);   // mid NW
            AddLimb(verts, cols, tris, new Vector3(-0.35f, 3.0f, 0.00f), new Vector3(1.4f, 3.6f, 0.9f), 0.09f, 0.025f);   // low E
            AddLimb(verts, cols, tris, new Vector3(-0.15f, 1.6f, 0.00f), new Vector3(0.9f, 1.9f, -0.7f), 0.08f, 0.03f);   // the stub

            var mesh = new Mesh { name = "DeadTree" };
            mesh.SetVertices(verts);
            mesh.SetColors(cols);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            return mesh;
        }

        private static void AddLimb(
            List<Vector3> verts, List<Color> cols, List<int> tris,
            Vector3 baseP, Vector3 tipP, float baseR, float tipR)
        {
            Vector3 axis = (tipP - baseP).normalized;
            Vector3 side = Vector3.Cross(axis, Mathf.Abs(axis.y) > 0.9f ? Vector3.forward : Vector3.up).normalized;
            Vector3 side2 = Vector3.Cross(axis, side);
            int start = verts.Count;

            // Square cross-sections (low-poly woodcut read — visual pillar 2's confident edges).
            for (int corner = 0; corner < 4; corner++)
            {
                float a = (corner + 0.5f) * Mathf.PI * 0.5f;
                Vector3 dir = side * Mathf.Cos(a) + side2 * Mathf.Sin(a);
                verts.Add(baseP + dir * baseR);
                cols.Add(new Color(0.9f, 0.9f, 0.9f));   // base slightly darker via tint below
                verts.Add(tipP + dir * tipR);
                cols.Add(new Color(1.1f, 1.05f, 1.0f));  // tips catch the light
            }

            for (int corner = 0; corner < 4; corner++)
            {
                int b0 = start + corner * 2;
                int t0 = b0 + 1;
                int b1 = start + ((corner + 1) % 4) * 2;
                int t1 = b1 + 1;
                tris.AddRange(new[] { b0, t0, b1, b1, t0, t1 });
            }

            // Cap the tip.
            int tip0 = start + 1;
            tris.AddRange(new[] { tip0, start + 5, start + 3, tip0, start + 7, start + 5 });
        }

        // Suspended motes — "the one particulate allowed while bound: dust/pollen hanging nearly
        // motionless in light — stasis made visible, not weather" (art-audio.md §The world-state
        // is the art direction). THE mood asset that separates "held breath" from "empty".
        // Particles are the RIGHT tool here (sparse, floating, unattached to ground — everything
        // grass isn't). Uses the house Tarrock/DustParticle shader: code-created stock particle
        // materials render unreliably in URP on this box.
        private static void BuildMotes()
        {
            Shader dust = Shader.Find("Tarrock/DustParticle");
            if (dust == null)
            {
                Debug.LogWarning("[Tarrock] Tarrock/DustParticle not found; motes skipped.");
                return;
            }

            var moteMat = AssetDatabase.LoadAssetAtPath<Material>(MoteMaterialPath);
            if (moteMat == null)
            {
                moteMat = new Material(dust);
                AssetDatabase.CreateAsset(moteMat, MoteMaterialPath);
            }
            else
            {
                moteMat.shader = dust;
            }

            // THE v8 SQUARE. round1/v8 of the 07-31 gauntlet caught the motes as a plain white
            // square hanging in the sky beside the dead tree's silhouette. Cause: this material
            // was created with no sprite, and an unassigned texture property does not sample as
            // nothing — it samples Unity's built-in white, alpha 1 across the entire billboard, so
            // every mote drew as its own untextured quad. Tarrock/DustParticle now carries a
            // procedural soft dot for exactly this case; asking for it means the motes depend on
            // no texture asset at all and cannot regress into a square if one goes missing again.
            moteMat.SetFloat("_SoftDot", 1f);
            EditorUtility.SetDirty(moteMat);

            var go = new GameObject("SuspendedMotes");
            go.transform.position = new Vector3(TerrainSize * 0.5f, 30f, 100f);
            var system = go.AddComponent<ParticleSystem>();

            ParticleSystem.MainModule main = system.main;
            main.loop = true;
            main.prewarm = true;
            main.startLifetime = 30f;
            main.startSpeed = 0.015f;                       // hanging, not falling
            main.startSize = new ParticleSystem.MinMaxCurve(0.025f, 0.07f);
            main.startColor = new Color(0.95f, 0.90f, 0.75f, 0.30f); // pale gold in the dawn light
            main.maxParticles = 900;
            main.simulationSpace = ParticleSystemSimulationSpace.World;

            ParticleSystem.EmissionModule emission = system.emission;
            emission.rateOverTime = 28f;

            ParticleSystem.ShapeModule shape = system.shape;
            shape.shapeType = ParticleSystemShapeType.Box;
            shape.scale = new Vector3(210f, 34f, 150f);     // the valley air, spawn bowl to mouth

            // The tiniest drift — suspended, not still-frame; a mote may cross a hand-width in a
            // minute. Noise instead of velocity so nothing ever reads as wind direction.
            ParticleSystem.NoiseModule noise = system.noise;
            noise.enabled = true;
            noise.strength = 0.015f;
            noise.frequency = 0.08f;
            noise.scrollSpeed = 0.01f;

            var moteRenderer = go.GetComponent<ParticleSystemRenderer>();
            moteRenderer.sharedMaterial = moteMat;
            moteRenderer.renderMode = ParticleSystemRenderMode.Billboard;
            moteRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
        }

        // -------------------------------------------------------------------------------------
        // Rock outcrops (round-2 composition pass, near-lens rework in round 3)
        //
        // THE FINDING this answers (round-1 critique of gauntlet/round1/v1, v8): there is no
        // foreground layer — the bottom third of the frame is smooth empty ground, and the darkest,
        // highest-detail mass sits in the MIDDLE distance. Every reference plate does the opposite:
        // fable-01 crops dark rock into the frame's edges a few metres from the lens, fable-06 puts
        // the two nearest masses hard against both sides. Something dark and near is what gives the
        // frame a foreground to read the rest against.
        //
        // ROUND 3, on the same finding re-measured against gauntlet/round2/v1, v8: it is still true.
        // Round 2 built the family and put the anchors at the right screen POSITION and the wrong
        // DISTANCE — 8.5 m to v1's lens, 12.0 m to v8's — so the dark layer reads as midground, not
        // as foreground. The three changes are set out beside RockVariants below.
        //
        // THREE POPULATIONS, ONE FAMILY. Most stones are SCATTERED by rule — deterministic, derived
        // from the landform itself, so the region keeps its logic if the sculpt moves: stone lies in
        // the thin turf everywhere, breaks out where the ground breaks (21-47 degrees), rings the
        // island's rim, strews the valley's banks, and gathers on the spawn bowl's floor. A few of
        // those stand rather than sit (variants 4-5), where the ground already breaks. And a short
        // list of ANCHORS is placed by hand, exactly like the dead tree, because composition is not
        // a rule: those are the stones that crop v1's edges, fill v8's bottom-left corner, crown the
        // knoll beside the tree and lean off the knoll's notch. Each anchor was projected into the
        // vantage frustums before it was written down (see the table).
        //
        // The scatter never buries a camera or occludes a subject. Re-measured over all eight
        // vantages after the round-4 change (anchors and scatter together, against the round-4
        // heightfield): the closest any stone's SURFACE comes to a camera is 2.08 m (v1's new
        // foreground mass, which is meant to crowd that lens), the median is 4.3 m, and no stone
        // stands on any camera's sight line to its subject at a height that could reach it — all
        // seven aimed vantages measure clear. The nearest stone to the spawn mark is 3.6 m away.
        // -------------------------------------------------------------------------------------
        // ROUND 3 — THE NEAR-LENS LAYER. The critic's measurement on round2/v1 and v8 was that the
        // darkest mass in the frame still sits ~30 m out (measured here: the nearest stone to v1's
        // lens was 8.5 m and to v8's 12.0 m), while every reference plate puts something within a
        // couple of metres of the lens, cropped by a frame edge. Three things changed:
        //
        //  1. DENSITY. The lattice pitch drops 5 m → 3 m and a baseline "scoured pan" chance now
        //     applies to ordinary gentle ground, so the plateau HAS a near layer everywhere rather
        //     than only at slope breaks. This is not decoration: the Cliff is wind-scoured (see
        //     art-audio.md §Region colour scripts, "wind-scoured green"), and wind-scoured turf is
        //     thin turf with the bedrock showing through it. The stone lying in the grass is the
        //     island's bones. Measured over 120 random standing points on walkable ground, the mean
        //     distance to the nearest stone falls from 12.2 m (round 2, 103 stones) to 4.7 m
        //     (round 3, ~560). That one number IS the near-lens layer; everything else is framing.
        //     ROUND-4 CORRECTION, and it is a correction of the REASONING, not of the pitch: an even
        //     4.7 m everywhere is not a near layer, it is wallpaper — see the gathering field at the
        //     end of AcceptsRock for what replaced it, and for why the near-lens job belongs to the
        //     anchors instead. The lattice pitch and the zone chances below are untouched.
        //
        //  2. SIZE-AWARE CLEARANCES. Round 2 kept EVERY stone 5.5 m off the travelled line, which
        //     is why nothing could ever be near the lens — the lens looks down the travelled line.
        //     A stone's berth now scales with the stone (1.4 + 1.35 × scale), so a 3 m boulder
        //     keeps more room than it used to and ankle-high rubble may lie in the grass where the
        //     Fool walks over it. That threshold is the same one that decides colliders in
        //     PlaceRock: if it is too small to collide with, it is too small to need a corridor.
        //
        //  3. A STANDING FAMILY. Variants 4 and 5 are tall and thin — a leaning finger and a
        //     tilted slab — because a boulder cannot break a frame's bottom edge from 3 m when the
        //     camera is looking UP (v8's frame bottom sits 3.9° ABOVE the horizontal; nothing under
        //     2 m tall is even in that picture). They are also the only shape that can carry the
        //     lit edge: see BeddingDipBearing.
        //
        //  4. ROUND 5 — ARCHETYPES, because six meshes was still one drawing. The round-5 critique:
        //     "every rock is one striped cone at six scales". True, and the profiles say why — 0-3
        //     were four tapering cones of different steepness and 4-5 were the same cone stood up.
        //     A hillside sheds more shapes than that, and the ones it sheds are the ones that read:
        //     a PLATE lying flat in the grass (a bedding surface stripped of its turf), a block that
        //     came apart and did not move (a SPLIT MASS — two lobes with a joint between them), and
        //     a boulder the turf has climbed to its shoulder (HALF-BURIED, wide at the base and low).
        //     Those three are the sitting family's 4, 5 and 6; 9 is a leaning monolith reserved for
        //     the anchors. The dip also stopped being one number — see BeddingDipJitter.
        private const int RockVariants = 10;
        private const int StandingFirstVariant = 7;   // variants 7-9 stand; 0-6 sit
        /// <summary>Variant 9 is ANCHOR-ONLY. It is the leaning monolith, and a monolith is a
        /// composition decision — the scatter may never sprinkle one, or the region acquires
        /// monuments it has not earned (the same rule the standing family already lives under).</summary>
        private const int AnchorOnlyVariant = 9;
        private const float RockCell = 3f;   // scatter lattice pitch, metres

        // THE CLIFF'S BEDDING. Every stone in the family leans the same way, by the same law: the
        // strata dip toward bearing 152° and their broken faces therefore look up-sun, toward the
        // dawn disc at bearing 332° (BuildLighting's SunEuler is 12°/152°; every sky vector in this
        // file derives from it). This is one line of geology doing three jobs at once:
        //   - it is TRUE — a bedded island has one dip, not a per-prop random tilt;
        //   - it ties the whole rock family into one formation instead of scattered props; and
        //   - it is what makes a near mass READ. At a 12° sun a horizontal top plane takes
        //     sin 12° = 0.21 of the key light and stays about as dark as the ground it sits on.
        //     Tip a stone's up-sun face 14° back and that face takes cos 2° ≈ 1.00 — nearly five
        //     times the light — while its top cap falls into shadow. (At round 3's 7° sun the same
        //     dip bought cos 7° = 0.99 against sin 7° = 0.12, a factor of eight; the raise costs
        //     this edge some of its bite and the weathering step in BuildRockMaterial gives it
        //     back, by darkening the cap rather than by brightening the face.) The hard bright-to-dark line where they
        //     meet is the lit top edge the round-2 critique asked for, and it is exactly the
        //     confident edge art-bible.md wants: two flat values and one clean boundary.
        // Standing stones lean further (they are the slabs the scarp shed, stood on their ends),
        // and their broad face is yawed to front the disc rather than spun at random.
        /// <summary>How much of the hillside's own stone value a free-standing block keeps (see
        /// BuildRockMaterial): the weathering step that lets a near mass anchor the frame.</summary>
        private const float RockWeathering = 0.82f;

        private const float BeddingDipBearing = 152f;
        private const float BeddingDipDegrees = 14f;
        private const float StandingDipDegrees = 24f;
        private const float SunwardBearing = 332f;

        /// <summary>Per-stone wander on the dip ANGLE, degrees either way. The BEARING does not
        /// wander — it is the light decision above and every lit edge in the region derives from it —
        /// but a single dip angle is what made a hundred stones read as a hundred copies of one
        /// prop. Real bedding undulates; ±5° keeps the formation legible (the family still leans one
        /// way) while giving each stone its own lit-edge angle. Measured against the 12° disc, ±5° of
        /// dip swings the up-sun face's key from cos 3° = 0.999 to cos 7° = 0.993 — the read is
        /// untouched — while the top cap's own shading moves enough to break the copy-paste.</summary>
        private const float BeddingDipJitter = 5f;

        /// <summary>One art-directed stone: where, how big, which of the four meshes.</summary>
        private readonly struct RockAnchor
        {
            public RockAnchor(float x, float z, float scale, int variant)
            {
                X = x;
                Z = z;
                Scale = scale;
                Variant = variant;
            }

            public float X { get; }

            public float Z { get; }

            public float Scale { get; }

            public int Variant { get; }
        }

        // The composition anchors, in the order the frames need them. Coordinates were chosen by
        // back-projecting the wanted screen position through each vantage's frustum onto the ground
        // — and, in round 3, by re-solving that projection for the DISTANCE as well, which is the
        // thing round 2 got wrong. Every one of these was also checked against all eight cameras:
        // no anchor is closer than 3 m to any of them, and none lies on any camera's sight line to
        // its subject.
        private static readonly RockAnchor[] RockAnchors =
        {
            // The bowl stones, north side. ROUND 3 RE-SITED THESE. Round 2 put them at 8.5-15 m and
            // at screen u +1.05..+1.77 — which is to say two of the three were entirely OUTSIDE the
            // frame and the third was a chip on the horizon. Re-solved for distance as well as for
            // column, they now stack at 7.1 / 7.5 / 10.7 m and read as three overlapping steps down
            // v1's right edge, the nearest cropping it (u +0.86..+1.31) and rising from below the
            // frame to a sixth above centre. Overlap is the whole point: one mass in front of
            // another is the only thing in a frame that states depth without any atmosphere at all.
            new RockAnchor(214.4f, 96.1f, 2.2f, 0),
            new RockAnchor(213.4f, 95.5f, 1.9f, 3),
            new RockAnchor(210.3f, 96.6f, 2.9f, 1),

            // ...and the south side, deliberately NOT a mirror. The near one is the closest thing to
            // v1's lens, and ROUND 4 REBUILT IT because round 3's was a chip and not a mass: at
            // 1.5 × the low-brow mesh it reached only v −0.40, so it filled the bottom-left corner
            // and stopped, and the critique read the frame as having no near-lens anchor at all.
            // Re-solved for the two things a foreground mass has to do — CROP TWO EDGES and hold a
            // real slice of the frame — it now stands 3.0 m from the lens across u −1.48…−0.36 and
            // v −2.43…−0.03: off the left edge, off the bottom edge, and up to the frame's own
            // mid-line. It is 0.29 clear of the Fool's screen box (u ±0.07) so it crowds him
            // without touching him, and 2.1 m clear of the lens so nothing is buried.
            // IT IS DARK BY GEOMETRY, NOT BY PIGMENT: the ground it stands on is in the north wall's
            // cast shadow (verified against the beam, which now lands 4.75 m out — round 5 widened
            // the dawn breach; this stone stands at 3.0 m and was re-traced against the widened col,
            // still in shade), so the whole stone sits at ambient while the lane behind it is lit.
            // The rock family's albedo is the ground's, read not restated, and it does not move.
            // It is also v2's near layer, cropping THAT frame's right edge (u +0.48…+1.45) from 3.9 m.
            new RockAnchor(217.09f, 89.07f, 2.2f, 1),
            new RockAnchor(211.6f, 86.0f, 2.4f, 1),
            new RockAnchor(206.5f, 84.3f, 2.6f, 1),
            new RockAnchor(209.0f, 82.6f, 1.5f, 3),

            // The south-wall outcrop. From v8 this group reads as the midground step at 15-21 m,
            // and on v1's left at 35 m as the layer beyond that. Unchanged from round 2 — with the
            // pair below now in front of it, it finally has something to be BEHIND.
            new RockAnchor(190.4f, 68.2f, 3.2f, 0),
            new RockAnchor(188.2f, 66.4f, 2.4f, 1),
            new RockAnchor(192.6f, 70.0f, 1.8f, 2),

            // v8's NEAR MASS. ROUND 5 REBUILT THIS, and the reason is the most useful measurement
            // in this file.
            //
            // WHAT WAS WRONG. Round 3 and round 4 both put a stone here (2.4 at (199.0, 81.6)) and
            // both comments claim it crops v8's bottom-left corner. PROJECTED through v8's actual
            // frustum, it is not in the frame at all: it spans u −15.56…−1.70, i.e. entirely off the
            // left edge, and its partner at (196.24, 85.37) spanned u +1.09…+52.92, entirely off the
            // right. The nearest stone v8 could actually see was 15.8 m away. That is exactly why
            // the round-4 critique reads "v8 has no near dark anchor" — it hasn't got one.
            //
            // WHY THE FRAME EATS NEAR STONES, and this is the rule to keep: v8's lens is PITCHED UP
            // 28.5° (it aims at the tree's crown, 25 m above the lens, from 56 m away). A point near
            // the ground therefore has a very small camera-space forward distance, and u = xc/(zc·t)
            // divides by exactly that — so a low stone at 3 m is thrown tens of frames off the edge
            // no matter how wide it is. In THIS vantage a near mass must be TALL before it is wide:
            // nothing whose top fails to reach the lens's own height is in the picture.
            //
            // THE MASS. A split block 3.8 m from the lens, standing 4.16 m proud — the
            // "landform-scale" register the reference board asks for (fable-06's pass is flanked by
            // rock several times the figure's height; fairytale-03's bridge holds a third of its
            // frame). Projected through v8's frustum:
            //     coverage        21.9% of the 1920×1080 frame
            //     spans           u −1.000…−0.188, pixels x 0-780, y 28-1076
            //     crops           the LEFT edge and the BOTTOM edge, both, as asked
            //     nearest surface 2.22 m from the lens
            // and it stops at u −0.188, which leaves the whole crest event reading ABOVE it: checked
            // column by column across u −0.30…−0.12, the mass's own top row is BELOW the skyline row
            // in every column the crest occupies (at u −0.24 the horn reads at row 662 and the mass
            // tops at row 812; at u −0.12 the col floor reads 757 against a mass top of 1056).
            //
            // IT IS DARK BY GEOMETRY AND BY SHADOW. Measured on gauntlet/round4/v8 in linear
            // luminance: lit ground reads 0.457, a lit rock face 0.310, a cast-shadowed rock 0.062,
            // the shadow side of a hill 0.111. Orientation alone will not do it here — the sun sits
            // 89.5° to the RIGHT of this view's axis, so a stone LEFT of centre turns a partly lit
            // face to the lens (N·L = 0.62 at this bearing). What darkens it is the stone up-sun of
            // it: this mass sits 5.38 m down-sun of the anchor below at bearing 154.9°, and the
            // sun's own shadow bearing is 152°, so it stands in that stone's shadow. Traced against
            // the 12° disc, that shadow's ceiling clears 67% of this mass's height, which puts it at
            // 0.67 × 0.062 + 0.33 × 0.310 = 0.145 linear — inside the 0.15 the round-5 brief asks
            // for, and against ground the same frame carries at 0.457 it is a 3.1:1 anchor.
            // That pairing is what the brief means by a shadow-side outcrop GROUP, and the mass is a
            // SPLIT block for the same reason the group exists: two lobes with a joint between them
            // are an overlap, and an overlap is the one thing in a frame that states depth with no
            // atmosphere at all.
            new RockAnchor(198.52f, 80.50f, 5.0f, 5),

            // ...and OPPOSITE it, the round-4 addition: v8's dark near mass, on the RIGHT.
            //
            // THE FINDING was that v8's near stones read PALE — brighter than the hazed distance
            // behind them, which is an anchor upside down. The cause is orientation, not albedo, and
            // it is worth stating as a rule because it decides where a near mass can go in any
            // frame: a stone's camera-facing side points at (bearing from the lens + 180°), and it
            // takes the key only while that is within 90° of the sun's 332°. In v8 (axis 242.5°,
            // half-width 39.7°) that splits the frame down the middle — every near stone LEFT of
            // centre is lit and every one RIGHT of centre is not. Round 3 put both of v8's near
            // stones on the left. This one stands at bearing 290° from the lens, so its near face
            // points 110°, a full 138° off the sun: ambient only, and it renders at sRGB ≈ 0.16
            // against ground the same frame lifts to 0.59 — a 3.7:1 anchor.
            // Geometry: 4.0 m from the lens, crossing the RIGHT edge (u +0.68 outward) and the
            // BOTTOM edge, topping at v −0.27, and 2.4 m clear of the camera. It stops well short of
            // the dead tree (u ±0.05) and of the new knoll notch (u +0.22…+0.30) — it frames them
            // rather than arguing with them. It replaces round 3's second left-hand stone: two pale
            // masses in one corner is not a foreground, it is clutter.
            // In v1 the same stone reads as the 24 m midground layer on the left (u −0.33…−0.20).
            // ROUND 5 GROWS IT 3.2 → 5.0 AND MOVES IT NOWHERE, because it turned out to be doing two
            // jobs badly and both of them want the same metre. Projected at 3.2 it was NOT crossing
            // v8's right edge — it sat wholly outside at u +1.09 — and it was not tall enough to
            // shade the near mass above it either. At 5.0 it stands 4.07 m proud and:
            //   - it crosses v8's RIGHT edge for real, u +0.60…+1.00, 9.7% of the frame, at 4.0 m,
            //     with its camera-facing side at bearing 110° — 138° off the sun, so ambient only:
            //     the dark right-hand jamb this frame never had; and
            //   - its shadow, thrown 4.07/tan 12° = 19.1 m down-sun along bearing 152°, now clears
            //     67% of the height of the near mass 5.38 m away, which is what makes that mass dark.
            // It stays v1's 24 m left midground layer, in the same slot: projected into v1 it spans
            // u −0.37…−0.17 against round 4's −0.33…−0.20 — one register larger, not relocated.
            // Beyond 5.0 it starts closing v8 from the right as hard as the near mass closes it from
            // the left (5.4 measures 14.3% of the frame), which is a jamb becoming a wall, so this
            // is chosen at the top of the useful range rather than past it.
            new RockAnchor(196.24f, 85.37f, 5.0f, 1),

            // The knoll's crown tor, beside the dead tree — unchanged from round 2.
            new RockAnchor(158.4f, 64.8f, 2.6f, 1),
            new RockAnchor(156.2f, 65.6f, 1.9f, 2),
            new RockAnchor(152.0f, 63.5f, 1.8f, 0),

            // THE NOTCH HORN: the leaning counter-element of the skyline event cut in
            // ApplyLandformEvents. Three slabs standing on the horn beyond the notch — MOVED WITH
            // THE NOTCH in round 4, because the round-4 cut goes through the ground round 3 stood
            // them on and a slab left there would have filled the very V it exists to answer.
            // On the new horn their tops read at v −0.219, −0.232 and −0.248 across u +0.41…+0.47:
            // 0.25-0.28 above the notch floor and 0.06-0.07 clear of the horn's own shelf, so the
            // shoulder reads summit → cut → three dark leaning verticals → falls away. The ground
            // under them measures 3.4-8.4°; the scarp west of them is left bare, because a slab
            // does not perch.
            new RockAnchor(146.8f, 77.8f, 3.2f, 7),
            new RockAnchor(146.0f, 78.6f, 2.6f, 8),
            new RockAnchor(147.4f, 77.2f, 2.2f, 7),

            // THE SOUTH-EAST COL'S LEANING PAIR — the counter-element of the round-5 crest cut in
            // ApplyLandformEvents, and the answer to "make it landform-scale, and NEVER a tree".
            //
            // WHERE. The cut leaves a level floor where nothing on this flank was level before:
            // sampled across it the col floor measures 2.6-9.4° while the ground either side runs
            // 53-71°, so this is the only footing on the knoll's south-east side that a slab can
            // stand on at all. The pair stands on it, at 49 m and 51 m from v8's lens.
            //
            // HOW BIG. The reference board's named scale for this is fable-06 (a pass flanked by
            // rock masses several times the figure) and fairytale-03 (one built mass holding a third
            // of the frame, read against open sky). Not a prop. The big slab stands 5.66 m proud —
            // it needs scale 9.0 to do it, because a standing stone is set 0.30 × scale into the
            // ground by PlaceRock and a slab that is not footed falls over. Projected into v8:
            //     big slab    u −0.246…−0.121, rows 680-936  (a 256 px vertical)
            //     companion   u −0.154…−0.092, rows 740-876  (3.31 m proud)
            // so the big one's top reads 77 px above the col floor (row 757) and within 18 px of the
            // horn (662), and the smaller one leans across it lower and to the right. A PAIR, and
            // overlapping — a lone vertical on a crest is a monument; two leaning together are the
            // shed of a scarp, which is what this is.
            //
            // AND IT IS BLACK. Traced along the sun's own vector against the finished heightfield,
            // 100% of both stones' height stands in cast shadow — the col's north-west wall is
            // between them and a 12° disc. Two dark verticals in a bright notch, with the knoll's
            // far rim 27 m behind them showing through the gap.
            new RockAnchor(158.4f, 54.8f, 9.0f, 9),
            new RockAnchor(156.9f, 56.2f, 5.0f, 9),
        };

        private static void BuildRockOutcrops(TerrainData terrainData, Material terrainMaterial)
        {
            Shader rockShader = Shader.Find(RockShaderName);
            if (rockShader == null)
            {
                Debug.LogWarning($"[Tarrock] {RockShaderName} not found; rock outcrops skipped.");
                return;
            }

            var meshes = new Mesh[RockVariants];
            for (int variant = 0; variant < RockVariants; variant++)
            {
                Mesh mesh = BuildRockMesh(variant);
                string path = string.Format(RockMeshPathFormat, variant);
                AssetDatabase.DeleteAsset(path);
                AssetDatabase.CreateAsset(mesh, path);
                meshes[variant] = mesh;
            }

            Material rock = BuildRockMaterial(rockShader, terrainMaterial);
            var root = new GameObject("RockOutcrops");

            foreach (RockAnchor anchor in RockAnchors)
            {
                PlaceRock(root.transform, meshes, rock, terrainData,
                    anchor.X, anchor.Z, anchor.Scale, anchor.Variant,
                    Hash21(anchor.X * 0.37f, anchor.Z * 0.71f));
            }

            int scattered = 0;
            int cells = Mathf.FloorToInt(TerrainSize / RockCell);
            for (int gz = 0; gz < cells; gz++)
            {
                for (int gx = 0; gx < cells; gx++)
                {
                    float jitterX = Hash21(gx + 0.37f, gz + 9.11f);
                    float jitterZ = Hash21(gx + 53.70f, gz + 2.29f);
                    float pick = Hash21(gx + 88.10f, gz + 41.30f);
                    float sizeRoll = Hash21(gx + 12.90f, gz + 67.50f);
                    float spinRoll = Hash21(gx + 71.30f, gz + 23.90f);
                    float variantRoll = Hash21(gx + 31.70f, gz + 95.10f);
                    float standRoll = Hash21(gx + 64.50f, gz + 7.70f);
                    float pairRoll = Hash21(gx + 39.90f, gz + 51.10f);

                    float x = (gx + 0.15f + 0.70f * jitterX) * RockCell;
                    float z = (gz + 0.15f + 0.70f * jitterZ) * RockCell;

                    // SIZE IS DECIDED BEFORE ACCEPTANCE, because in round 3 the clearances depend on
                    // it (see AcceptsRock): a boulder needs a corridor, rubble does not, and you
                    // cannot apply that rule to a stone whose size you have not rolled yet.
                    //
                    // Power-2.2 roll: most stones are small, a few are big — a flat size distribution
                    // reads as gravel of one grade, which is the tell of a scatter tool. Size, spin,
                    // shape and stance come off FOUR independent hashes; sharing one would tie every
                    // big stone to the same mesh at the same angle.
                    float standSteep = terrainData.GetSteepness(x / TerrainSize, z / TerrainSize);
                    bool standing = standRoll > 0.88f && standSteep > 16f && standSteep < 44f;
                    float scale = standing
                        ? 1.6f + 1.4f * sizeRoll
                        : 0.40f + 2.9f * Mathf.Pow(sizeRoll, 2.2f);

                    // SIZE HIERARCHY (round 4). A gathering's stones are not all one grade: the
                    // block that broke first is the biggest and the rest are its debris. Sitting
                    // stones therefore take 72% of their rolled size out in the clears and 128% in
                    // a core, which is enough to give every group a head. Measured over the finished
                    // field, the largest stone in a three-plus group is 1.78× the second largest,
                    // and mean scale runs 1.61 in the cores against 1.04 in the clears. Standing
                    // stones are exempt: a slab is the size the scarp shed, not the size of the
                    // company it keeps.
                    if (!standing)
                    {
                        scale *= 0.725f + 0.55f * RockCluster(x, z);
                    }

                    if (!AcceptsRock(terrainData, x, z, pick, scale))
                    {
                        continue;
                    }

                    // Standing stones only ever come from the standing family, and only ever stand
                    // where the ground already breaks — a menhir in the middle of a flat meadow is
                    // a monument, and this region has not earned one.
                    // The scatter draws from variants 7 and 8 standing and 0-6 sitting; 9 is
                    // anchor-only (see AnchorOnlyVariant).
                    int variant = standing
                        ? StandingFirstVariant + (variantRoll > 0.5f ? 1 : 0)
                        : Mathf.Clamp(
                            Mathf.FloorToInt(variantRoll * StandingFirstVariant), 0, StandingFirstVariant - 1);
                    PlaceRock(root.transform, meshes, rock, terrainData, x, z, scale, variant, spinRoll);
                    scattered++;

                    // -- THE COMPANION (round 5). The other half of the round-5 rock critique was
                    //    "isolated singletons": the gathering field decides WHERE stone lies, but at
                    //    a 3 m lattice pitch a gathering still comes out as separate stones sitting
                    //    apart, and a block that came apart does not leave its pieces apart. So one
                    //    stone in three drops a smaller piece against its own flank, at 0.55-0.95 of
                    //    the parent's radius — close enough that the two silhouettes OVERLAP rather
                    //    than merely stand near each other, which is the whole point: an overlap is
                    //    depth, adjacency is clutter. The companion is 42-68% of the parent, always
                    //    a sitting variant (debris does not stand on end), and it takes no clearance
                    //    test of its own — it lives inside its parent's, which has already passed.
                    if (pairRoll > 0.66f && scale > 0.9f)
                    {
                        float leanAngle = Hash21(gx + 17.30f, gz + 58.90f) * 360f;
                        float leanDist = scale * (0.55f + 0.40f * Hash21(gx + 44.10f, gz + 3.30f));
                        float cx = x + Mathf.Sin(leanAngle * Mathf.Deg2Rad) * leanDist;
                        float cz = z + Mathf.Cos(leanAngle * Mathf.Deg2Rad) * leanDist;
                        float companionScale = scale * (0.42f + 0.26f * Hash21(gx + 6.70f, gz + 82.10f));
                        int companionVariant = Mathf.Clamp(
                            Mathf.FloorToInt(Hash21(gx + 25.10f, gz + 63.70f) * StandingFirstVariant),
                            0, StandingFirstVariant - 1);
                        PlaceRock(root.transform, meshes, rock, terrainData,
                            cx, cz, companionScale, companionVariant, Hash21(cx * 0.37f, cz * 0.71f));
                        scattered++;
                    }
                }
            }

            Debug.Log(
                $"[Tarrock] Rock outcrops: {RockAnchors.Length} art-directed + {scattered} scattered.");
        }

        private static bool AcceptsRock(TerrainData terrainData, float x, float z, float pick, float scale)
        {
            // A margin, so no stone straddles the tile boundary the cloud deck is hiding.
            if (x < 8f || x > TerrainSize - 8f || z < 8f || z > TerrainSize - 8f)
            {
                return false;
            }

            float height = terrainData.GetInterpolatedHeight(x / TerrainSize, z / TerrainSize);
            float steep = terrainData.GetSteepness(x / TerrainSize, z / TerrainSize);

            // Below 13.5 m is the drop into cloud and above 56 m is nothing this region has; past
            // 52 degrees a boulder would hang on the face rather than sit on it.
            if (height < 13.5f || height > 56f || steep > 52f)
            {
                return false;
            }

            // The travelled line stays clear — but by an amount that SCALES WITH THE STONE. Round 2
            // held every stone, from a 0.75 m cobble to a 3.25 m boulder, 5.5 m off the centreline,
            // and that single number is most of why the opening frame had no foreground: the lens
            // looks down the travelled line, so a blanket corridor is a blanket ban on near-lens
            // masses. A boulder now keeps MORE berth than it used to and ankle-high rubble may lie
            // in the grass, which is where rubble lies. The crossover is the same 1 m that decides
            // colliders in PlaceRock: too small to collide with is too small to route around.
            float offset = Mathf.Abs(z - CentreZ(x));
            if (offset < 1.4f + 1.35f * scale)
            {
                return false;
            }

            var point = new Vector2(x, z);
            var spawnXz = new Vector2(SpawnHint.x, SpawnHint.z);
            float fromSpawn = Vector2.Distance(point, spawnXz);
            if (fromSpawn < 1.2f + 1.0f * scale)
            {
                return false;   // the Fool wakes on grass, not on a stone
            }

            if (Vector2.Distance(point, KnollCentre) < 2.6f)
            {
                return false;   // the dead tree's own ground
            }

            foreach (RockAnchor anchor in RockAnchors)
            {
                // Scaled with the anchor too: an anchor is a composition and the scatter must not
                // silt up around it, but a 1.5 m anchor does not need the same moat as a 3.2 m one.
                if (Vector2.Distance(point, new Vector2(anchor.X, anchor.Z)) < 3.5f + anchor.Scale)
                {
                    return false;
                }
            }

            // Five zones, in ascending priority.
            //
            // THE PAN is the round-3 addition and the one that makes the near layer exist at all:
            // ordinary ground, anywhere, carries stone. On a wind-scoured plateau the turf is thin
            // and the bedrock is right underneath it, so plates and low brows show through the
            // grass everywhere — which is both true and the only rule that can put something dark
            // within a few metres of a camera standing in the open. The other four are where stone
            // GATHERS: bedrock surfaces at slope breaks, the island's broken edge shows its bones,
            // the valley's banks are strewn (the same band the tussocks dress, so the two
            // populations edge the path together instead of arguing about where it is), and the
            // spawn bowl's floor collects what its steep rim sheds — densest in the apron at the
            // foot of that rim, which is the arc the opening frame looks across.
            float chance = 0.10f;
            if (steep > 21f && steep < 47f)
            {
                chance = Mathf.Max(chance, 0.16f);
            }

            float inboard = RimInboard(x, z);
            if (inboard > 5f && inboard < 24f)
            {
                chance = Mathf.Max(chance, 0.13f);
            }

            float halfWidth = HalfWidth(x);
            if (offset > halfWidth - 3f && offset < halfWidth + 12f)
            {
                chance = Mathf.Max(chance, 0.22f);
            }

            if (fromSpawn > 3f && fromSpawn < 30f)
            {
                chance = Mathf.Max(chance, 0.26f);
            }

            if (fromSpawn > 15f && fromSpawn < 28f)
            {
                chance = Mathf.Max(chance, 0.36f);
            }

            // -- THE GATHERING FIELD (round 4), applied last so it modulates every zone above.
            //
            // THE FINDING (art lead, on gauntlet/round3/v1): the boulders read as an even confetti
            // sprinkle. The numbers agree — round 3's field put a stone within 4.3 m of the average
            // standing point on walkable ground and left only 8% of that ground more than 8 m from
            // one. Stone was everywhere, so stone meant nothing, and with nothing to be sparse
            // against a group could not read as a group.
            //
            // Stone does not lie evenly. It gathers where a block came apart and it is absent in
            // between, and the eye reads the ABSENCE — the open meadow is what makes the cluster a
            // cluster. So the zone chances above (which say where stone BELONGS) are multiplied by a
            // field that says where it GATHERED, and that multiplier is deliberately brutal at both
            // ends: 0.06 in the clears, up to 4.56 in a core, which saturates the lattice so a core
            // fills at the 3 m cell pitch and comes out as a knot of touching stones.
            // Measured over the finished field, against round 3:
            //     stones                     582  →  341   (and the near-lens layer is unhurt: it
            //                                              was never the scatter's job, it is the
            //                                              anchors' — see RockAnchors)
            //     density CV, 10 m discs    0.55  →  0.92
            //     ground > 8 m from a stone   8%  →   32%   the clears
            //     ground > 12 m               1%  →   11%
            //     groups (6 m single link)   219  →  140, of which 41 are the 2-4 stone gatherings
            //                                              the brief asks for and 18 are larger
            // The field is TWO octaves on purpose: the ~19 m octave decides where a gathering is,
            // the ~9 m one breaks each gathering into knots so a core is not a disc of gravel.
            chance *= 0.06f + 4.5f * RockCluster(x, z);

            return pick <= chance;
        }

        /// <summary>Where stone GATHERED, 0 in the open meadow and 1 in the core of a group. Shared
        /// by <see cref="AcceptsRock"/> (how many) and <see cref="BuildRockOutcrops"/> (how big), so
        /// the two cannot disagree about where a gathering is.</summary>
        private static float RockCluster(float x, float z)
        {
            float broad = Fbm(x * 0.052f + 31f, z * 0.052f + 13f);
            float knots = Fbm(x * 0.115f + 7f, z * 0.115f + 41f);
            float field = 0.5f + 0.5f * ((0.68f * broad) + (0.32f * knots));
            // A LINEAR clamp, not a smoothstep: the smoothstep's flat shoulders would widen both the
            // saturated cores and the dead clears, and the measured figures below are this ramp's.
            return Mathf.InverseLerp(0.50f, 0.66f, field);
        }

        /// <summary>Metres inboard of the nearest broken edge (negative once past the lip). The edge
        /// lines are the ones SampleHeight step 7 uses.</summary>
        private static float RimInboard(float x, float z)
        {
            float edgeN = 209f + 7f * Mathf.Sin(x * 0.043f) + 3f * Mathf.Sin(x * 0.11f);
            float edgeS = 22f + 7f * Mathf.Sin(x * 0.037f + 1.3f) + 3f * Mathf.Sin(x * 0.09f + 0.5f);
            float edgeE = 246f + 7f * Mathf.Sin(z * 0.041f + 2.2f) + 3f * Mathf.Sin(z * 0.10f + 1.1f);
            float edgeW = 12f + 7f * Mathf.Sin(z * 0.045f + 0.7f) + 3f * Mathf.Sin(z * 0.12f + 2.4f);
            return Mathf.Min(Mathf.Min(edgeN - z, z - edgeS), Mathf.Min(edgeE - x, x - edgeW));
        }

        /// <summary>
        /// The direction a bedded stone's own "up" points: vertical tipped <paramref name="dip"/>
        /// degrees toward <see cref="BeddingDipBearing"/>. Leaning DOWN-sun is deliberate and is the
        /// whole trick — it swings the stone's broken up-sun face back toward the 7° disc (that face
        /// goes from taking cos 83° to taking cos 7° of the key light) while the top cap rolls into
        /// shadow, so the stone gains the hard lit edge a near mass needs to read against the sky.
        /// Leaning the other way would light the cap a little and the face not at all.
        /// </summary>
        private static Vector3 BeddingUp(float dip)
        {
            float dipRadians = dip * Mathf.Deg2Rad;
            float bearingRadians = BeddingDipBearing * Mathf.Deg2Rad;
            float lean = Mathf.Sin(dipRadians);
            return new Vector3(
                Mathf.Sin(bearingRadians) * lean,
                Mathf.Cos(dipRadians),
                Mathf.Cos(bearingRadians) * lean).normalized;
        }

        private static void PlaceRock(
            Transform parent, Mesh[] meshes, Material material, TerrainData terrainData,
            float x, float z, float scale, int variant, float roll)
        {
            float nx = x / TerrainSize;
            float nz = z / TerrainSize;
            float ground = terrainData.GetInterpolatedHeight(nx, nz);
            float steep = terrainData.GetSteepness(nx, nz);
            Vector3 normal = terrainData.GetInterpolatedNormal(nx, nz);

            bool standing = variant >= StandingFirstVariant;

            // Sunk, and sunk MORE on steep ground: a stone that merely touches the surface reads as
            // dropped, and on a slope it reads as rolling. Bedrock is buried. A standing stone is
            // set deeper still, because a slab on its end that is not footed falls over.
            float sink = (0.16f + 0.34f * Mathf.Clamp01(steep / 60f)) * scale;
            if (standing)
            {
                sink += 0.14f * scale;
            }
            else
            {
                // PARTIAL BURIAL (round 4). Stones in a gathering have been there long enough for
                // the turf to climb them, and they have not settled equally: squaring the roll means
                // most stones take almost none of this and a few are set in to the shoulder, which
                // is what stops a group reading as a handful of pebbles tipped out on the grass.
                // Squared and capped at 0.26, so the most deeply set stone still stands 0.56 × scale
                // proud on the flat and 0.29 × on the steepest ground the scatter accepts — buried,
                // never swallowed. Standing stones are exempt: their footing is already deeper, and
                // a half-sunk slab is a step, not a slab.
                float burial = Hash21(x * 0.77f + 3.1f, z * 0.53f + 8.6f);
                sink += 0.26f * scale * burial * burial;
            }

            var go = new GameObject("Rock");
            go.transform.SetParent(parent, worldPositionStays: false);
            go.transform.position = new Vector3(x, ground - sink, z);

            // REST is PART of the way toward the ground normal: fully aligned reads as decal, fully
            // upright reads as furniture. 55% is the angle at which a slab looks like it was left
            // there by the hill rather than placed on it. Then the whole thing is leaned again
            // toward the region's bedding (see BeddingDipBearing), which is what turns the up-sun
            // face into the lit edge — hard, and hardest for the standing family, which is bedding
            // stood on end and therefore takes the dip almost entirely.
            Vector3 rest = Vector3.Slerp(Vector3.up, normal, 0.55f).normalized;
            // The dip ANGLE wanders per stone (see BeddingDipJitter); the dip BEARING never does.
            float dip = (standing ? StandingDipDegrees : BeddingDipDegrees)
                + (Hash21(x * 0.61f + 4.4f, z * 0.29f + 12.7f) - 0.5f) * 2f * BeddingDipJitter;
            Vector3 bedded = Vector3.Slerp(
                rest, BeddingUp(dip),
                standing ? 0.85f : 0.5f).normalized;
            Quaternion tilt = Quaternion.FromToRotation(Vector3.up, bedded);

            // Yaw: sitting stones spin freely, standing stones do NOT. A slab's broad face is the
            // face the dawn has to find, so it is turned to front the disc (±22° of hash wander, so
            // a row of them is a bedding plane and not a parade), and the mesh is built with its
            // broad faces on local ±Z for exactly this.
            float yaw = standing
                ? SunwardBearing + (roll - 0.5f) * 44f
                : roll * 360f;
            go.transform.rotation = tilt * Quaternion.Euler(0f, yaw, 0f);

            // Non-uniform in plan, so many instances of six meshes never read as many copies. The
            // standing family is squashed HARD on one axis on purpose: a slab is a plate, and a
            // finger is a column, and neither survives being drawn as a lumpy cylinder.
            float squashX = 0.82f + 0.42f * Hash21(x * 0.13f, z * 0.29f);
            float squashZ = 0.82f + 0.42f * Hash21(x * 0.41f + 5f, z * 0.17f + 3f);
            if (standing)
            {
                // Three stances, not two. The finger (7) is a column; the tilted plate (8) is a wide
                // thin plate; the monolith (9) is neither — a slab meant to be read from 40-60 m as a
                // silhouette, so it is narrowed on BOTH axes rather than flattened on one. At the
                // scale 9.0 the south-east col's slab is placed at, 0.78/0.30 gives a stone ~5 m
                // across its broad face and ~1.5 m through: a slab. The tilted-plate ratio would
                // have given a 10 m wall.
                switch (variant)
                {
                    case StandingFirstVariant:
                        squashX *= 0.62f;
                        squashZ *= 0.55f;
                        break;
                    case AnchorOnlyVariant:
                        squashX *= 0.78f;
                        squashZ *= 0.30f;
                        break;
                    default:
                        squashX *= 1.15f;
                        squashZ *= 0.34f;
                        break;
                }
            }

            go.transform.localScale = new Vector3(scale * squashX, scale, scale * squashZ);

            Mesh mesh = meshes[Mathf.Clamp(variant, 0, meshes.Length - 1)];
            go.AddComponent<MeshFilter>().sharedMesh = mesh;
            var renderer = go.AddComponent<MeshRenderer>();
            renderer.sharedMaterial = material;
            renderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;

            // Only stones the Fool could not step over get a collider: a metre-high boulder is a
            // wall, ankle-high rubble is scenery and colliding with it only snags movement.
            if (scale >= 1.0f)
            {
                var box = go.AddComponent<BoxCollider>();
                box.center = mesh.bounds.center;
                box.size = mesh.bounds.size;
            }

            go.isStatic = true;
        }

        /// <summary>
        /// One faceted stone, 1 m tall and about 0.9 m across at scale 1: five rings of a 6-8 sided
        /// prism with a hash-jittered radius per ring and per side, leaned off vertical, capped top
        /// and bottom, and emitted with HARD facets (every quad carries its own vertices and its own
        /// normal). Hard facets are the point — a smooth-shaded blob is the "undesigned dome"
        /// problem at prop scale, and the reference boards' rock is always a few flat planes with a
        /// clean edge between them (art-bible.md, confident edges).
        /// </summary>
        private static Mesh BuildRockMesh(int variant)
        {
            // The RADIUS profile is what makes a boulder a boulder and a slab a slab; the ring
            // HEIGHTS differ only for the standing family, which needs its mass low and its taper
            // late so it reads as something stood up rather than something grown. The bottom ring
            // sits below the origin so the stone can be sunk without ever showing its open base.
            float[] ringHeight = RockRingHeights(variant);
            float[] ringRadius = RockProfile(variant);
            int sides = RockSides(variant);
            float leanX = (Hash21(variant * 3.7f, 1.9f) - 0.5f) * 0.22f;
            float leanZ = (Hash21(variant * 5.1f, 7.3f) - 0.5f) * 0.22f;

            var verts = new List<Vector3>();
            var cols = new List<Color>();
            var tris = new List<int>();

            // LOBES (round 5). Every stone until now was ONE prism, which is why the family read as
            // one drawing at six scales: a prism is a cone whatever you do to its profile. A lobe is
            // an offset copy of the ring stack with its own seed, its own radius factor and its own
            // height factor, and it is how the SPLIT MASS is built — a block that came apart along a
            // joint and did not move, two masses touching with a shadowed seam between them. That is
            // the only shape in this family whose silhouette is not convex, and a non-convex
            // silhouette is worth more than another profile curve. Everything else has one lobe and
            // is byte-for-byte what it was.
            Lobe[] lobes = RockLobes(variant);
            Lobe lobe = lobes[0];

            Vector3 RingPoint(int ring, int side)
            {
                float angle = side * Mathf.PI * 2f / sides;
                float jitter = 0.80f + 0.42f * Hash21(
                    side + variant * 13.7f + lobe.Seed, ring + variant * 7.3f + lobe.Seed);
                float r = ringRadius[ring] * jitter * 0.46f * lobe.Radius;
                float t = Mathf.Clamp01(ringHeight[ring] * lobe.Height);
                var lean = new Vector3(leanX, 0f, leanZ) * (t * t);
                return new Vector3(
                    (Mathf.Cos(angle) * r) + (lobe.OffsetX * lobe.Radius),
                    ringHeight[ring] * lobe.Height,
                    (Mathf.Sin(angle) * r) + (lobe.OffsetZ * lobe.Radius)) + lean;
            }

            // Value per facet, darkening toward the buried base: the contact shadow is painted into
            // the mesh rather than left to an AO the pipeline does not run at this scale.
            Color FacetColour(int ring, int side, float centreHeight)
            {
                float v = 0.86f + 0.26f * Hash21(side * 3.1f + ring * 7.7f, variant * 5.3f + 2.1f);
                float bury = Mathf.Lerp(0.52f, 1f, Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(centreHeight)));
                float c = v * bury;
                return new Color(c, c, c, 1f);
            }

            void AddQuad(Vector3 a, Vector3 b, Vector3 c, Vector3 d, Color colour)
            {
                int s = verts.Count;
                verts.Add(a);
                verts.Add(b);
                verts.Add(c);
                verts.Add(d);
                for (int i = 0; i < 4; i++)
                {
                    cols.Add(colour);
                }

                tris.AddRange(new[] { s, s + 2, s + 1, s, s + 3, s + 2 });
            }

            for (int lobeIndex = 0; lobeIndex < lobes.Length; lobeIndex++)
            {
                lobe = lobes[lobeIndex];
                for (int ring = 0; ring < ringHeight.Length - 1; ring++)
                {
                    for (int side = 0; side < sides; side++)
                    {
                        int next = (side + 1) % sides;
                        Vector3 a = RingPoint(ring, side);
                        Vector3 b = RingPoint(ring, next);
                        Vector3 c = RingPoint(ring + 1, next);
                        Vector3 d = RingPoint(ring + 1, side);
                        float mid = (ringHeight[ring] + ringHeight[ring + 1]) * 0.5f * lobe.Height;
                        AddQuad(a, b, c, d, FacetColour(ring, side, mid));
                    }
                }

                AddCap(ringHeight.Length - 1, upward: true);
                AddCap(0, upward: false);
            }

            // Caps: a fan to a centre vertex, so the silhouette gets a top plane to catch the dawn
            // light and the shadow caster has a closed hull.
            void AddCap(int ring, bool upward)
            {
                var centre = Vector3.zero;
                for (int side = 0; side < sides; side++)
                {
                    centre += RingPoint(ring, side);
                }

                centre /= sides;
                centre.y = (ringHeight[ring] * lobe.Height) + (upward ? 0.06f : -0.04f);
                Color colour = FacetColour(ring + 11, 3, upward ? 1f : 0f);
                for (int side = 0; side < sides; side++)
                {
                    int next = (side + 1) % sides;
                    Vector3 a = RingPoint(ring, side);
                    Vector3 b = RingPoint(ring, next);
                    int s = verts.Count;
                    // Winding: Unity's front face is clockwise seen from the front, so a triangle
                    // (v0,v1,v2) faces Cross(v1-v0, v2-v0). Rings run anticlockwise in XZ, which
                    // makes (centre, b, a) face UP and (centre, a, b) face DOWN.
                    verts.Add(centre);
                    verts.Add(upward ? b : a);
                    verts.Add(upward ? a : b);
                    cols.Add(colour);
                    cols.Add(colour);
                    cols.Add(colour);
                    tris.AddRange(new[] { s, s + 1, s + 2 });
                }
            }

            var mesh = new Mesh { name = $"RockOutcrop{variant}" };
            mesh.SetVertices(verts);
            mesh.SetColors(cols);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateNormals();   // per-facet, because no vertex is shared between quads
            mesh.RecalculateBounds();
            return mesh;
        }

        /// <summary>Radius per ring for each stone in the family: a squat boulder, a tapering slab,
        /// a low brow, a small shard — and, standing, a leaning finger and a tilted plate.
        /// Hand-authored — six drawings, not six dice rolls.</summary>
        private static float[] RockProfile(int variant)
        {
            switch (variant)
            {
                case 0: return new[] { 0.92f, 1.00f, 0.94f, 0.70f, 0.30f };   // boulder
                case 1: return new[] { 0.86f, 0.82f, 0.70f, 0.54f, 0.34f };   // outcrop slab
                case 2: return new[] { 1.00f, 0.98f, 0.74f, 0.40f, 0.14f };   // low brow
                case 3: return new[] { 0.72f, 0.64f, 0.50f, 0.32f, 0.12f };   // shard
                // Round-5 archetypes. The flat slab is WIDER than it is anything else (radius over
                // 1.0, i.e. broader than the boulder) because a stripped bedding surface is a plate
                // in the grass, not a lump; the split mass keeps its radius nearly constant to the
                // top so the joint between its two lobes stays a joint instead of closing into a
                // point; the half-buried boulder is widest at its base and dies out early, so what
                // shows above the turf is a shoulder.
                case 4: return new[] { 1.24f, 1.30f, 1.16f, 0.86f, 0.40f };   // flat slab
                case 5: return new[] { 0.96f, 1.02f, 0.86f, 0.78f, 0.62f };   // split mass
                case 6: return new[] { 1.16f, 1.10f, 0.86f, 0.52f, 0.20f };   // half-buried boulder
                case 7: return new[] { 0.40f, 0.44f, 0.40f, 0.31f, 0.15f };   // leaning finger
                case 8: return new[] { 0.86f, 0.94f, 0.90f, 0.76f, 0.46f };   // tilted plate
                default: return new[] { 0.74f, 0.80f, 0.76f, 0.66f, 0.42f };  // leaning monolith
            }
        }

        /// <summary>The lobes a variant is built from: an offset, a radius factor, a height factor
        /// and a seed shift, in mesh-local units. One lobe for every stone except the split mass —
        /// see the note in <see cref="BuildRockMesh"/>.</summary>
        private static Lobe[] RockLobes(int variant)
        {
            if (variant != 5)
            {
                return SingleLobe;
            }

            // The split: a head at 80% radius and full height, and a shoulder at 62% radius and 70%
            // height set 0.52 away in plan — far enough that the two silhouettes read as two masses
            // and near enough that they still touch. The seed shift is what stops the shoulder being
            // a scale copy of the head: it re-rolls every per-side radius jitter in the ring stack.
            return SplitLobes;
        }

        private static readonly Lobe[] SingleLobe = { new Lobe(0f, 0f, 1f, 1f, 0f) };

        private static readonly Lobe[] SplitLobes =
        {
            new Lobe(0.22f, 0.05f, 0.80f, 1.00f, 0f),
            new Lobe(-0.30f, -0.12f, 0.62f, 0.70f, 4f),
        };

        /// <summary>One mass of a multi-lobed stone (see <see cref="RockLobes"/>).</summary>
        private readonly struct Lobe
        {
            public Lobe(float offsetX, float offsetZ, float radius, float height, float seed)
            {
                OffsetX = offsetX;
                OffsetZ = offsetZ;
                Radius = radius;
                Height = height;
                Seed = seed;
            }

            public float OffsetX { get; }

            public float OffsetZ { get; }

            public float Radius { get; }

            public float Height { get; }

            public float Seed { get; }
        }

        /// <summary>Ring heights per variant. The sitting family shares one set; a standing stone
        /// carries its bulk in the lower half and keeps its taper for the last ring, so the shape
        /// against the sky is a shoulder and a broken tip rather than a cone.</summary>
        private static float[] RockRingHeights(int variant)
        {
            switch (variant)
            {
                // The flat slab is 0.26 tall against the family's 1.00: at the scales the scatter
                // rolls that is 0.2-0.8 m of stone lying in the grass, which is what a stripped
                // bedding plane is. It is the one archetype meant to be walked over, not around.
                case 4: return new[] { -0.10f, 0.06f, 0.14f, 0.21f, 0.26f };
                // The split mass carries its bulk high — the joint has to be visible above the turf
                // line or the stone is just a boulder with a dent.
                case 5: return new[] { -0.10f, 0.24f, 0.52f, 0.78f, 1.00f };
                // The half-buried boulder starts 0.30 BELOW the origin and tops out at 0.56, so
                // PlaceRock's sink puts most of it under the turf and the shoulder is what shows.
                case 6: return new[] { -0.30f, 0.02f, 0.22f, 0.40f, 0.56f };
                default:
                    if (variant < StandingFirstVariant)
                    {
                        return new[] { -0.08f, 0.20f, 0.48f, 0.76f, 1.00f };
                    }

                    return new[] { -0.14f, 0.26f, 0.58f, 0.84f, 1.00f };
            }
        }

        /// <summary>Side count per variant. Fewer sides on the standing family on purpose: a slab is
        /// four big planes with a clean edge between them (art-bible.md, confident edges), and a
        /// near-lens mass that is going to be read as a silhouette wants the fewest facets that
        /// still describe it.</summary>
        private static int RockSides(int variant)
        {
            switch (variant)
            {
                case 4: return 5;   // flat slab — a plate is a pentagon, not a disc
                case 5: return 7;   // split mass — odd, so no lobe face mirrors the other's
                case 6: return 8;   // half-buried boulder — the one round shape in the family
                case 7: return 5;   // leaning finger
                case 8: return 4;   // tilted plate
                case 9: return 4;   // leaning monolith — four planes, read at 50 m as a silhouette
                default: return 6 + (variant % 3);
            }
        }
    }
}
