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
        //  5. ROUND 6 — TWO MASSES THAT ARE NOT PROPS. The round-5 critique landed hardest on the
        //     two stones that frame v8, and on a fault the whole family shares. Variants 10 and 11
        //     answer them; see RockValue, RockAzimuthJitter and RockRingJog for the three mesh
        //     changes that go with them.
        private const int RockVariants = 12;
        private const int StandingFirstVariant = 7;   // variants 7-11 stand; 0-6 sit
        /// <summary>Variant 9 is ANCHOR-ONLY. It is the leaning monolith, and a monolith is a
        /// composition decision — the scatter may never sprinkle one, or the region acquires
        /// monuments it has not earned (the same rule the standing family already lives under).</summary>
        private const int AnchorOnlyVariant = 9;

        /// <summary>THE NEAR MASS (round 6). Anchor-only. A strike-jointed wall: the slab a bedded
        /// island sheds along the joint set at right angles to its dip, stood on its edge at the
        /// lens. See the anchor comment for why the orientation — not the pigment — is what makes
        /// it dark, and <see cref="RockValue"/> for the pigment that gives the margin.</summary>
        private const int NearMassVariant = 10;

        /// <summary>THE BROKEN JAMB (round 6). Anchor-only. The same stone v8 already had on its
        /// right edge, rebuilt with a silhouette a hillside could have made: eight rings instead of
        /// five, so no single straight segment can own more than a seventh of its height.</summary>
        private const int BrokenJambVariant = 11;

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

        // -- THE THREE MESH CHANGES OF ROUND 6, all of them answers to measurements ---------------
        //
        // (a) AZIMUTH JITTER. Every ring in this family was a REGULAR polygon: side k sat at exactly
        //     k·360/n.
        //     A CORRECTION TO THE FIRST DRAFT OF THIS NOTE, because it was wrong and the measurement
        //     is worth keeping: the obvious reading is that variants 8 and 9 are four-sided, so they
        //     carry four exact 90° corners in plan, and that this is where "right-angle corners read
        //     as masonry" comes from. Measured, it is not. PlaceRock's non-uniform squash gets there
        //     first — the monolith's plan turns measure 42/142/48/128° and the tilted plate's
        //     34/146/29/151°, and across the four biggest stones in round 5 exactly ONE corner sits
        //     within 12° of a right angle. The masonry read is the BOOLEANS, and it is answered by
        //     the single-hull near mass and the separated anchors, not here.
        //     What this term is actually for is the other half of the same critique — outlines a
        //     hillside could not have made. Equal sectors mean every stone's plan is the same figure
        //     at a different size, so a hundred instances share one outline vocabulary. ±0.28 of a
        //     sector of wander gives each stone its own, at no cost: the prism is still a prism, it
        //     is simply not a regular one, which is what a broken block is. Keyed per SIDE and not
        //     per ring, so the vertical edges stay coherent lines of one block rather than twisting
        //     into a spiral.
        private const float RockAzimuthJitter = 0.28f;

        // (b) RING JOG. The other half of "a dead-vertical 390 px edge plus a straight bevel reads as
        //     a black card". A five-ring stack gives a silhouette FOUR straight segments long, so a
        //     quarter of a stone's outline is a straight line by construction, and at the scale the
        //     framing masses are placed at that quarter is hundreds of pixels. Each ring above the
        //     base is now offset bodily in plan, weighted from 0 at the buried ring to full at the
        //     top, so consecutive segments no longer share a line: the outline staircases the way a
        //     jointed block does. Kept small against the ~0.46 mesh radius — this is a stagger, not
        //     a stack of dinner plates.
        private const float RockRingJog = 0.045f;
        private const float RockRingJogAnchor = 0.075f;   // the two framing masses take more

        // (d) SPALL — ROUND 7, and it is the answer to "the dark jamb carries one TENTH the surface
        //     detail of any near mass on the board". Measured with a gradient detail metric (mean
        //     |Δ sRGB luma| per pixel at 1 px and 3 px, run identically on our captures and on the
        //     board): round5/v8's jamb 0.0046, round6/v8's jamb 0.0011, board near masses 0.0115
        //     (fable-06's left mass) to 0.0267 (fable-05's near bank). Round 6 DARKENED the jamb to
        //     sRGB 0.12 and thereby destroyed 76% of the detail it had, because detail measured in
        //     absolute luma scales with the value of the surface carrying it: the rock material's
        //     dabs and flecks are multiplicative, so a 17% mark on a 0.12 surface is a 0.015 mark and
        //     a 0.005 gradient. The value is not up for negotiation (it is a round-6 win), so the
        //     detail has to come from somewhere that does not need it: GEOMETRY.
        //
        //     A quad of the two framing masses is now subdivided into steps² sub-quads, each with its
        //     own facet value, and the INTERIOR grid vertices are displaced along the face normal.
        //     Three properties make this safe rather than noise:
        //       - THE BOUNDARY NEVER MOVES. Only interior vertices take relief, so every quad's
        //         outline is byte-for-byte what it was: the silhouette round 6 rebuilt (eight rings,
        //         seven sides, no straight segment longer than a seventh of the height) is untouched,
        //         the seams between quads stay watertight, and the projected AREA — and so the mass's
        //         weight in the frame — is unchanged.
        //       - THE VALUE DOES NOT MOVE. The relief is written as a SLOPE budget rather than as a
        //         depth: a sub-facet's tilt is at most atan(RockSpallSlope) = 11.9° whatever the
        //         subdivision, because the amplitude is divided by the step count. The jamb's
        //         camera-facing faces sit at N·L −0.43…−0.73 against a _ShadeWrap of 0.22; 11.9° of
        //         tilt moves N·L by at most sin 11.9° = 0.21, so no sub-facet crosses the wrap
        //         threshold and no key light leaks onto a mass whose whole job is to be at ambient.
        //         Modelled through the fitted transfer, the jamb's mean sRGB luma moves 0.1409 →
        //         0.1386 across this change: it holds its round-6 value.
        //       - IT IS THE TRUE THING. A broken face is not a plane. A hillside's shed block spalls,
        //         and the relief this puts on it is exactly what fable-06's flanking masses carry:
        //         their separation from the pass behind them is bedding detail, not blackness.
        //     Only the framing masses take it. The scatter's stones are read at tens of pixels, where
        //     a subdivision is 25× the triangles for nothing.
        //
        //     AND THE HONEST LIMIT, written down because the next round should not spend itself
        //     here: this closes only part of the gap. Rendered through the fitted transfer and
        //     measured with the same metric, the jamb's MESH-BORNE detail goes 0.00013 → 0.00041,
        //     while the round-6 capture measures 0.00155 — i.e. the detail in the picture is already
        //     mostly the material's marks, not the mesh's facets, and it is bounded by the surface's
        //     own value: for a multiplicative mark of relative contrast c on a surface at luma Y,
        //     the absolute gradient is ≈ 0.455·c·Y. The board's dark near masses carry c ≈ 8-12% per
        //     pixel-pair (fable-05 0.0267 on a 0.283 mean, fable-07 0.0147 on 0.182, fable-01 0.0237
        //     on 0.195); ours carries 1.3%. Six to nine times the mark contrast is a MATERIAL
        //     decision and it lives in RockPainterly.shader, not here. What this file can do it has
        //     done: 3× the mesh detail, and a near mass whose value (0.237) is 2.0× the jamb's, so
        //     the same marks land at twice the absolute contrast on the frame's other framing mass.
        private const int RockSpallSteps = 5;
        private const float RockSpallSlope = 0.21f;   // tan of the steepest sub-facet tilt: 11.9°

        /// <summary>Per-facet value wander, as a ± fraction of <see cref="RockFacetMean"/>. The
        /// family's own 0.13 reproduces the 0.86 + 0.26·hash the whole scatter has always used, to
        /// the bit. The two framing masses take 0.29 — the SAME MEAN, so no value moves, and 2.2× the
        /// spread, because a mass read at 250 000 pixels needs its facets to differ from each other
        /// and a mass read at 200 does not.</summary>
        private const float RockFacetMean = 0.99f;
        private const float RockFacetSpread = 0.13f;
        private const float RockFacetSpreadAnchor = 0.29f;

        /// <summary>
        /// (c) VALUE PER VARIANT, and it is the round-6 headline. The near mass rendered at sRGB
        /// luma 0.545 against a ≤ 0.20 target — measured on gauntlet/round5/v8, not modelled — and
        /// the reason it did is ORIENTATION, not pigment: at that position its camera-facing side
        /// takes N·L ≈ 0.62 of the key, and the frame's own right-hand jamb, the SAME material at
        /// the SAME distance with its face 138° off the sun, renders at 0.107. That is a 17.4:1
        /// lit-to-ambient ratio measured inside one frame, and it is the whole budget: no albedo a
        /// stone could honestly carry closes a 17× gap, because the tonemap lifts the dark end at an
        /// effective exponent of ~0.52 — cutting the albedo fivefold buys only 2.3× on screen.
        /// So the near mass is turned to face the light away (see its anchor), and this scalar is
        /// the MARGIN on top of that, not the mechanism: 0.62 of the family's value, which is the
        /// dark bed a wet-turfed block weathers to rather than a coat of black paint. It multiplies
        /// the per-facet mesh colour, so it reaches the shader as `input.color.rgb` — the term the
        /// fragment applies BEFORE the sun-bleach block, which is where a darkening has to sit if
        /// the bleach is to read the final albedo rather than the other way round.
        /// </summary>
        private static float RockValue(int variant)
        {
            return variant == NearMassVariant ? 0.62f : 1f;
        }

        /// <summary>One art-directed stone: where, how big, which mesh, and — for the two framing
        /// masses — which way it is turned. YAW IS A COMPOSITION DECISION for those two, exactly as
        /// their coordinates are: the standing family's default is to front the dawn disc (see
        /// <see cref="SunwardBearing"/>), and a mass whose job is to be dark must do the opposite.
        /// <see cref="YawDegrees"/> is NaN for every stone that keeps the family's default.</summary>
        private readonly struct RockAnchor
        {
            public RockAnchor(float x, float z, float scale, int variant)
                : this(x, z, scale, variant, float.NaN)
            {
            }

            public RockAnchor(float x, float z, float scale, int variant, float yawDegrees)
            {
                X = x;
                Z = z;
                Scale = scale;
                Variant = variant;
                YawDegrees = yawDegrees;
            }

            public float X { get; }

            public float Z { get; }

            public float Scale { get; }

            public int Variant { get; }

            public float YawDegrees { get; }
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
            // ROUND 6, and it is one of the two BOOLEAN SEAMS the critique found. These first two
            // sat 1.17 m apart with plan radii of 1.20 and 0.74 — the smaller stone was 105% of its
            // own radius INSIDE the larger, so what the frame showed was not two stones but one
            // stone with a hard intersection curve cut across it, which is exactly the masonry read.
            // The screen stack was never the problem and is kept: the second stone is pushed 1.0 m
            // further ALONG the line the two already made, which is very nearly v1's sight line, so
            // the pair still overlaps in the picture (that overlap is the depth cue the round-3 note
            // is about) while ceasing to overlap in space. 2.15 m centres against a 1.94 m radius
            // sum: they touch, they do not interpenetrate.
            new RockAnchor(214.4f, 96.1f, 2.2f, 0),
            new RockAnchor(212.56f, 94.99f, 1.9f, 3),
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
            // THE MASS, as round 5 built it and as the round-6 note below supersedes it. A split
            // block 3.8 m from the lens, standing 4.16 m proud — the
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
            // ROUND 6 REBUILT IT AGAIN, and this time the correction is to the METHOD.
            //
            // WHAT ROUND 5 GOT WRONG. The paragraph that used to stand here reasoned in ALBEDO —
            // "0.67 × 0.062 + 0.33 × 0.310 = 0.145 linear, inside the 0.15 the brief asks for" —
            // and the frame it produced measures sRGB luma 0.545 over the mass, against a ≤ 0.20
            // target. It missed by 3.4×, and it missed for two separate reasons, both worth keeping
            // written down because they are the two ways this kind of number goes wrong:
            //   1. IT IGNORED THE TONEMAP. Those figures are scene-linear; the picture is the far
            //      end of bloom → vignette → white balance → LogC contrast → colour filter →
            //      shadows/midtones/highlights → lift → saturation → Neutral tonemap → sRGB. That
            //      chain LIFTS THE DARK END HARD: measured through it, d ln(sRGB luma)/d ln(scene
            //      linear) is only 0.61 down at sRGB 0.16 and 0.52 over the range this mass moves
            //      in. Albedo-space arithmetic cannot predict a rendered value, in either direction.
            //   2. THE SHADOW DID NOT LAND. The mass was placed 5.38 m down-sun of the jamb below
            //      and 70% of its height was traced as shadowed. It renders at a full key anyway.
            //      Re-measured against the capture: this mass reads 0.2840 in scene linear and the
            //      jamb — the SAME material, the same distance, ambient only — reads 0.0163. That
            //      is 17.4:1, which is a lit surface, not a shadowed one. The umbra of a 2 m-wide
            //      stone does not cover a 4.6 m-wide one 5 m away, and a shadow is in any case a
            //      thing that can be missed by a metre; an orientation cannot.
            //
            // SO THE MASS IS TURNED, NOT PAINTED. The geometry of this vantage is fixed and it is
            // the whole argument. The lens sees this stone from bearing 22.9°; the dawn disc stands
            // at 332°. A face is VISIBLE from the lens while its normal is within 90° of 22.9°, and
            // it is UNLIT while N·L ≤ −_ShadeWrap, which for this material is every normal outside
            // 75°…229°. The two conditions overlap over exactly 75°…113° of bearing — a real
            // window, and a narrow one, and the whole reason the frame's right-hand jamb is already
            // dark at 0.107 while this stone is not. A face on bearing 80° sits in the middle of it:
            // N·L = −0.30, cos 51.7° = 0.62 of its area still turned to the lens.
            //
            // AND 80° IS NOT AN ARBITRARY ANGLE — IT IS THE ISLAND'S OWN JOINT SET. The strata dip
            // toward 152° (see BeddingDipBearing), so the joints at right angles to the dip strike
            // 62°/242°, and the face a bedded island sheds along them looks very nearly along 80°.
            // This mass is that slab, stood on its edge: a wall of rock running bearing 170°/350°
            // down the left of the lens, presenting the strike face to the camera and the dip face
            // to the sun. It is a SINGLE hull, not the round-5 split block, because two
            // interpenetrating lobes at this size are the boolean seam the critique names.
            //
            // ROUND 7 MOVED IT, AND THE REASON IS THE WHOLE ROUND. Everything above is sound
            // reasoning about a stone that IS NOT IN THE PICTURE.
            //
            // THE MEASUREMENT, and it is a geometric fact, not a judgement. v8's lens sits at
            // (200, 84) and aims at the knoll at (150, 58), so its axis runs bearing 242.5° and its
            // horizontal half-angle is atan(tan 25° × 16/9) = 39.66°: the frame spans bearings
            // 202.9°…282.2°. The round-6 mass stands at (198.60, 78.60) — bearing 194.5° from the
            // lens — and every corner of it, projected through the real frustum against the real
            // heightfield, lands off the LEFT edge except one base corner at bearing 230.7°, which
            // is 3.6 m below the lens at 2.4 m and therefore far below a frame whose bottom edge sits
            // 3.5° ABOVE the horizontal. Rasterised: ZERO pixels. Round 6 re-yawed it, re-profiled
            // it, thinned it to 0.18 and gave it a value scalar, and not one of those decisions ever
            // reached the picture. (The re-yaw DID reach the jamb below, which is why that half of
            // round 6 measured and this half did not.) The same fact explains why v8's near field
            // measures BRIGHTER than its midground: ray-marched against the heightfield, the nearest
            // TERRAIN v8 can see is 16.7 m away, so the frame has no near field at all on the left —
            // the 12-22 m bowl rim is doing the job, lit, at sRGB luma 0.558 against a 25-70 m
            // midground of 0.503.
            //
            // WHERE IT GOES: bearing 230° from the lens at 7.5 m — (194.26, 79.18) — which is inside
            // the frame by 27° and puts the mass across u −1.000…−0.456, rows 474-1079: it crops the
            // LEFT edge and the BOTTOM edge, holds 11.51% of the frame (the jamb opposite holds
            // 12.72%, so the two read as a pair rather than as a wall and a chip), tops out above
            // the frame's own mid-line, and stops 157 px short of the crown tor at x 679 — the
            // shoulder still reads summit → tree → cut → slabs → tor with nothing of this mass in
            // it, and the tree's own isolation is untouched (measured on the round-6 capture and on
            // the predicted round-7 composite: the same 107 px of clear sky to its left).
            // Its nearest surface is 6.0 m from the lens and its footprint clears the jamb's by
            // 0.8 m — they do not touch, which is the round-6 boolean-seam rule.
            //
            // AND IT IS NOT BLACK, WHICH IS A REVERSAL OF ROUND 6 AND IS ARGUED FROM THE BOARD.
            // Near-mass separation is DARKNESS in most of the board, but in the three plates nearest
            // this frame's problem — fable-05, fable-06 (the named scale for this vantage: a pass
            // flanked by rock several times the figure's height) and fable-07 — the near masses are
            // MID-VALUE and separate by detail and by a value STEP across a clean edge. Measured on
            // those plates, near-mass mean sRGB luma runs 0.18-0.69, never the 0.12 round 6 drove
            // the jamb to. So the yaw is pinned at 88° rather than 80°: the broad strike face turns
            // its normal to bearing 88°, 116° off the disc, so N·L = −0.43 against a _ShadeWrap of
            // 0.22 and it takes NO key at all — while the slab's north END, 1.2 m wide and turned
            // 52° from the lens, takes a full key and reads as one lit plane against it. Through the
            // pipeline transfer fitted on this frame's own rock facets (see the round-7 note on
            // RockSpallSteps for the fit), that is: mean 0.238, 10th percentile 0.095, 90th 0.355,
            // against a midground the same frame measures at 0.503 and a jamb it measures at 0.120.
            // Darker than the midground by 0.26 and twice the jamb's value, with 0.26 of range
            // inside it — the two flat values and one boundary art-bible.md asks for, and NOT the
            // black card the critique named. Depth-banded across the whole frame (near = anything
            // inside 22 m, mid = 25-70 m, both read off a ray-march of the finished heightfield),
            // near − mid goes +0.040 in round 5 and +0.055 in round 6 to −0.061 here: the near field
            // stops being the brightest thing in the picture.
            // Scale 11.5 with squash (0.55, 0.18) — 7.1 m along the strike, 2.3 m through, 7.3 m
            // proud on 11.5° ground. The mass grows and the plan SHORTENS because a 7.55 m wall
            // running north from here would have gone through the jamb; this is the same slab, stood
            // on the same joint, cut to a length the composition can hold.
            new RockAnchor(194.26f, 79.18f, 11.5f, NearMassVariant, 88f),

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
            // ROUND 6 KEEPS ITS VALUE AND REBUILDS ITS SHAPE. The critique is precise and it is not
            // about the light: this jamb is value-correct — it measures sRGB luma 0.107 on round5/v8
            // and it is the control surface the near mass above is now solved against — but its
            // outline is a dead-vertical straight edge 390 px long finished with one straight bevel,
            // which reads as a black card laid over the frame rather than as rock. That is a
            // GENERATOR fault, not a placement one, and it has two causes:
            //   - FIVE RINGS. A five-ring stack draws its silhouette with four straight segments, so
            //     a quarter of any stone's outline is a straight line by construction. On a mass
            //     5.97 m tall filling the frame's right edge, a quarter is hundreds of pixels.
            //   - A REGULAR POLYGON. Side k sat at exactly k·360/n, so the vertical edges were the
            //     evenly spaced corners of a regular prism — and a prism corner projects to a
            //     perfectly straight line however the prism is turned.
            // It is now the eight-ring, seven-sided BrokenJambVariant, with the family's new azimuth
            // jitter and a doubled ring jog: seven silhouette segments instead of four, none of them
            // sharing a line with its neighbour, and a top ring that is offset rather than concentric
            // so the "bevel" is a broken corner. Measured on the outline, deviation from its own
            // straight-line fit rises from 16.3% of the mass's height to 19.1%, and the longest
            // segment that CAN be straight falls from 1/4 of the height to 1/7.
            // The value is protected: the yaw is pinned at 286° so the face it turns to the lens is
            // still 138° off the sun — modelled mean `lit` 0.010 against the round-5 build's 0.105,
            // i.e. the same ambient-only read, and RockValue leaves its pigment alone. Scale 5.0 →
            // 5.4 and a fuller profile keep the frame coverage the round-5 note solved for, which
            // the extra rings would otherwise have narrowed.
            new RockAnchor(196.24f, 85.37f, 5.4f, BrokenJambVariant, 286f),

            // THE CROWN TOR — MOVED OFF THE SUMMIT IN ROUND 6, and this is the round's clearest
            // finding: it was crowding the dead tree at the focal point.
            //
            // THE MEASUREMENT. Projected into v8, the three stones stood at screen u +0.057, +0.099
            // and +0.091 while the tree's own crown spans u −0.03…+0.05. On the capture they are the
            // dark spikes at x 1000-1060 breaking the summit ridge immediately right of the trunk,
            // and the tree's lowest limb and the nearest spike share a row. Zero clearance. The one
            // tree is the Cliff's signature — art-audio.md §Region colour scripts, and the landmark
            // clause the dead tree's own comment cites at the top of this file — and a signature
            // silhouette that has three stones growing out of its ankles is not a silhouette.
            //
            // WHERE THEY GO. Not far, and not to a new idea: down the knoll's south-east flank onto
            // the shoulder the round-5 col cut, which is the ground the col SHED and therefore the
            // ground its debris belongs on. Screen-left of the tree by 12-14 m of world, they land at
            // u −0.274, −0.270 and −0.293 — a quarter-frame of clear sky between them and the trunk,
            // and beyond the col's own leaning pair at u −0.16…−0.11, so the shoulder now reads
            // summit → tree alone → cut → the two slabs → the tor falling away. Scales come down
            // (2.6/1.9/1.8 → 2.2/1.7/1.5) because a stone on a flank is debris and a stone on a
            // summit is a monument, and this group has just stopped being the second.
            // CAVEAT, honestly: their footing was chosen by projection, not by sampling the finished
            // heightfield — the flank either side of the col runs steep, and if the capture shows one
            // of them perched rather than sitting, the fix is a metre further out, not a new idea.
            new RockAnchor(164.8f, 54.2f, 2.2f, 1),
            new RockAnchor(167.2f, 56.4f, 1.7f, 2),
            new RockAnchor(162.9f, 51.6f, 1.5f, 0),

            // THE NOTCH HORN: the leaning counter-element of the skyline event cut in
            // ApplyLandformEvents. Three slabs standing on the horn beyond the notch — MOVED WITH
            // THE NOTCH in round 4, because the round-4 cut goes through the ground round 3 stood
            // them on and a slab left there would have filled the very V it exists to answer.
            // On the new horn their tops read at v −0.219, −0.232 and −0.248 across u +0.41…+0.47:
            // 0.25-0.28 above the notch floor and 0.06-0.07 clear of the horn's own shelf, so the
            // shoulder reads summit → cut → three dark leaning verticals → falls away. The ground
            // under them measures 3.4-8.4°; the scarp west of them is left bare, because a slab
            // does not perch.
            // ROUND 6 SPACES THEM — the second of the two boolean seams. The 3.2 finger stood 1.13 m
            // from the 2.6 plate whose plan radius is 1.17, so it was 111% of its own radius inside
            // it, and the third slab stood 0.28 m from the first: three stones, one welded lump with
            // two intersection curves cut across it. They are re-laid on the horn as a spaced line —
            // 2.48 m and 2.09 m off the plate against a 1.69 m radius sum, and 4.56 m between the two
            // fingers — so the shoulder reads THREE dark verticals with the horn's own shelf showing
            // between them, which is what the round-4 note was already asking for. On the new
            // footings they read at u +0.434, +0.482 and +0.523 against round 5's +0.41…+0.47: the
            // same register, one stone's width wider, and now countable.
            new RockAnchor(147.85f, 76.95f, 3.2f, 7),
            new RockAnchor(146.0f, 78.6f, 2.6f, 8),
            new RockAnchor(144.55f, 80.10f, 2.2f, 7),

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
                    Hash21(anchor.X * 0.37f, anchor.Z * 0.71f), anchor.YawDegrees);
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
                    bool standing = standRoll > 0.88f && standSteep > 16f && standSteep < 44f
                        && StandsAlone(terrainData, gx, gz, standRoll);
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
                    //
                    //    ROUND 6 BARS IT FROM THE STANDING FAMILY, and the round-5 critique is why:
                    //    "the left cluster merged into one mass — six stones reading as four
                    //    silhouettes". Both halves of that sentence are this rule's doing. A SITTING
                    //    stone with a piece against its flank is two low lumps overlapping, and the
                    //    overlap is depth, which is what round 5 wanted. A STANDING stone with a
                    //    piece against its flank is two verticals read against open sky with their
                    //    outlines touching, and touching outlines against sky do not read as two
                    //    things — they weld. The silhouette IS the whole of a standing stone's
                    //    contribution; nothing else about it survives being 30 m away. So debris
                    //    gathers at the foot of a boulder and never at the foot of a slab.
                    if (pairRoll > 0.66f && scale > 0.9f && !standing)
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

        /// <summary>
        /// ROUND 6 — THE OTHER HALF OF THE MERGED CLUSTER. True of a standing stone and of nothing
        /// else in this family: it is read as a SILHOUETTE against sky, so two of them within a few
        /// metres do not read as two stones, they read as one lumpy one. Measured on round5/v1, the
        /// left group put six slabs into four silhouettes.
        ///
        /// The scatter cannot ask "what did I place last time" — it is a pure function of position,
        /// which is the property that lets the region be regenerated — so the thinning is done as a
        /// LOCAL MAXIMUM instead: a cell may raise a standing stone only if no cell within two of it
        /// wants one more strongly. That is decided by re-running the same predicates on the
        /// neighbours, so it needs no state and cannot disagree with the caller. It guarantees a
        /// clear cell ring around every slab — at the 3 m lattice pitch, no two standing stones
        /// closer than about 6 m — which at the 24-35 m the v1 group is seen from is sky and ground
        /// showing between every pair. The sitting family is untouched: a boulder is read as a mass,
        /// not as an outline, and boulders are supposed to gather.
        /// </summary>
        private static bool StandsAlone(TerrainData terrainData, int gx, int gz, float standRoll)
        {
            int cells = Mathf.FloorToInt(TerrainSize / RockCell);
            for (int dz = -2; dz <= 2; dz++)
            {
                for (int dx = -2; dx <= 2; dx++)
                {
                    if (dx == 0 && dz == 0)
                    {
                        continue;
                    }

                    int nx = gx + dx;
                    int nz = gz + dz;
                    if (nx < 0 || nz < 0 || nx >= cells || nz >= cells)
                    {
                        continue;
                    }

                    float neighbourRoll = Hash21(nx + 64.50f, nz + 7.70f);
                    if (neighbourRoll <= standRoll || neighbourRoll <= 0.88f)
                    {
                        continue;
                    }

                    float jitterX = Hash21(nx + 0.37f, nz + 9.11f);
                    float jitterZ = Hash21(nx + 53.70f, nz + 2.29f);
                    float px = (nx + 0.15f + 0.70f * jitterX) * RockCell;
                    float pz = (nz + 0.15f + 0.70f * jitterZ) * RockCell;
                    float steep = terrainData.GetSteepness(px / TerrainSize, pz / TerrainSize);
                    if (steep > 16f && steep < 44f)
                    {
                        return false;   // a neighbour wants it more; this cell yields
                    }
                }
            }

            return true;
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

            // THE TREE'S OWN GROUND, 2.6 m → 9 m in round 6, and it does two jobs.
            //
            // THE SILHOUETTE. The one tree is the Cliff's signature and it has to stand ALONE: the
            // crown tor has just been moved off the summit for crowding it (see RockAnchors), and it
            // would be a poor joke to move three art-directed stones away and let the scatter put
            // five more back. 9 m clears the whole summit crown — from v8, 56 m out, that is ±0.16
            // of screen either side of the trunk with nothing in it.
            //
            // THE SLIVER. It also fixes the placement artifact the critique caught at (933, 587) on
            // round5/v8: a needle of dark stone protruding a few pixels through the knoll's shoulder
            // silhouette just below the tree. That is what a stone does when it lands on a steep
            // shoulder — PlaceRock sinks it by steepness, the uphill side goes under, and what shows
            // is a wedge with no mass behind it. The summit shoulder is exactly the band that
            // produces it, and it is now off limits to the scatter.
            if (Vector2.Distance(point, KnollCentre) < 9f)
            {
                return false;   // the dead tree's own ground
            }

            // THE WEST SHOULDER'S TREAD (round 9). Landform.cs §THE KNOLL APPROACH cuts the one
            // walkable line to the dead tree — a 4.4-6 m tread at 23.3° maximum — and a boulder
            // standing on a 5 m tread is not dressing, it is a closed route. Only stones big enough
            // to CARRY A COLLIDER are turned away (PlaceRock's own 1 m threshold, the same crossover
            // the travelled line's corridor above uses): ankle-high rubble may lie on a path, which
            // is where rubble lies, and the shoulder would read as swept if it could not.
            // The gate is the shelf's own blend weight rather than a second copy of the spiral
            // geometry, so it can never drift from the landform it is protecting: > 0.5 is the
            // tread plus the inner half of its batter — 6.1 m either side of the line at the foot,
            // 3.6 m at the lip, which is the width a walked line needs kept clear.
            if (scale >= 1.0f && ApproachShelf(x, z, out _) > 0.5f)
            {
                return false;   // the way up
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
            float x, float z, float scale, int variant, float roll, float yawOverride = float.NaN)
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
            // ROUND 6: an anchor may PIN its yaw, and the two framing masses do. The default above
            // exists to make a slab catch the dawn; a mass whose job is to be the dark shape the
            // frame is read against needs the opposite, and it needs it to the degree — the window
            // of bearings that are both turned to the lens and turned away from the sun is only 38°
            // wide (see the near mass's anchor). That is a composition decision of exactly the same
            // kind as the anchor's coordinates, so it is written down beside them rather than
            // derived from a hash.
            float yaw = !float.IsNaN(yawOverride)
                ? yawOverride
                : standing
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

                    // THE NEAR MASS is a SLAB ON EDGE, and its proportions are load-bearing in both
                    // senses. The hash wander is dropped for these two — a stone whose exact
                    // thickness is the difference between a dark frame and a lit one is not left to
                    // a dice roll. Thin on local Z because that is the axis the broad faces are
                    // built on, and the broad face is the strike face the yaw turns away from the
                    // sun; the lit sliver that remains is the slab's north END, and its share of the
                    // projected area is what the thickness ratio sets. Measured facet by facet in
                    // round 6: 0.30 leaves mean `lit` at 0.114, 0.24 at 0.105, 0.18 at 0.081.
                    // ROUND 7 SHORTENS THE PLAN, 1.00 → 0.55, and KEEPS 0.18. At the anchor's new
                    // station the mass is 27° inside the frame instead of 8° outside it, and a slab
                    // 0.56 × 11.5 = 6.4 m from its centre would have run its north end through the
                    // jamb 5.8 m away — the boolean seam round 6 spent two anchors removing. 0.55
                    // gives a 7.1 m strike face against a 2.3 m thickness (a 3:1 slab, which is what
                    // a joint set sheds) and holds the footprint 0.8 m clear of the jamb's.
                    // The lit end is NO LONGER something to buy down: see the anchor — it is the one
                    // lit plane that keeps this mass from reading as the jamb's black card.
                    case NearMassVariant:
                        squashX = 0.55f;
                        squashZ = 0.18f;
                        break;

                    // THE BROKEN JAMB stays much the block it was — it was never the wrong shape in
                    // the mass, only in the outline, and the outline is fixed in the mesh.
                    case BrokenJambVariant:
                        squashX = 0.95f;
                        squashZ = 0.62f;
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

            // Round 6: the jog is stronger on the two framing masses, which are the stones whose
            // outlines are read at hundreds of pixels rather than tens.
            bool framing = variant == NearMassVariant || variant == BrokenJambVariant;
            float ringJog = framing ? RockRingJogAnchor : RockRingJog;
            int lastRing = ringHeight.Length - 1;

            Vector3 RingPoint(int ring, int side)
            {
                // AZIMUTH JITTER (round 6): the sector each side occupies wanders, so the prism is
                // irregular rather than regular and its plan corners are no longer 360/n apart. Keyed
                // on the side and the lobe and NOT on the ring, so a vertical edge stays one straight
                // line of one block instead of corkscrewing up the stone.
                float sector = Mathf.PI * 2f / sides;
                float angle = (side * sector)
                    + ((Hash21(side * 2.7f + variant * 4.1f + lobe.Seed, 91.3f) - 0.5f)
                        * 2f * RockAzimuthJitter * sector);
                float jitter = 0.80f + 0.42f * Hash21(
                    side + variant * 13.7f + lobe.Seed, ring + variant * 7.3f + lobe.Seed);
                float r = ringRadius[ring] * jitter * 0.46f * lobe.Radius;
                float t = Mathf.Clamp01(ringHeight[ring] * lobe.Height);
                var lean = new Vector3(leanX, 0f, leanZ) * (t * t);

                // RING JOG (round 6): each ring is offset bodily in plan, so consecutive silhouette
                // segments do not share a line and a long straight edge cannot form. Weighted to
                // zero at the buried ring — a jogged base ring would swing the stone's foot sideways
                // out of the ground it was sunk into.
                float jogWeight = lastRing > 0 ? ring / (float)lastRing : 0f;
                var jog = new Vector3(
                    (Hash21(ring * 5.9f + variant * 2.3f + lobe.Seed, 17.1f) - 0.5f) * 2f,
                    0f,
                    (Hash21(ring * 8.3f + variant * 6.7f + lobe.Seed, 43.9f) - 0.5f) * 2f)
                    * (ringJog * jogWeight);

                return new Vector3(
                    (Mathf.Cos(angle) * r) + (lobe.OffsetX * lobe.Radius),
                    ringHeight[ring] * lobe.Height,
                    (Mathf.Sin(angle) * r) + (lobe.OffsetZ * lobe.Radius)) + lean + jog;
            }

            // Value per facet, darkening toward the buried base: the contact shadow is painted into
            // the mesh rather than left to an AO the pipeline does not run at this scale.
            Color FacetColour(int ring, int side, float centreHeight)
            {
                return FacetTone((side * 3.1f) + (ring * 7.7f), centreHeight);
            }

            Color FacetTone(float key, float centreHeight)
            {
                float spread = framing ? RockFacetSpreadAnchor : RockFacetSpread;
                float v = (RockFacetMean - spread) + (2f * spread * Hash21(key, variant * 5.3f + 2.1f));
                float bury = Mathf.Lerp(0.52f, 1f, Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(centreHeight)));
                // RockValue is the round-6 per-variant value step (see its summary). It rides here,
                // on the mesh, rather than on the material, for two reasons: the rock material is
                // shared by every stone in the region and is written by BuildRockMaterial, which is
                // not this pass's file; and the vertex colour reaches the fragment as
                // `input.color.rgb`, which is applied BEFORE the sun-bleach block — so a darkening
                // put here is a darkening the bleach then reads, which is the required order.
                float c = v * bury * RockValue(variant);
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

            // SPALL (round 7, framing masses only — see RockSpallSteps). The quad (a,b,c,d) runs
            // a→b along the ring and a→d up it; the grid keeps that parameterisation, so every
            // sub-quad is wound exactly as the quad it replaces and the facet normals stay outward.
            void AddSpalledQuad(Vector3 a, Vector3 b, Vector3 c, Vector3 d, int ring, int side, float mid)
            {
                // Outward normal of the quad: (v0,v1,v2) faces Cross(v1-v0, v2-v0) in Unity's
                // convention (see AddCap), and the diagonals give the same side for the whole quad.
                Vector3 face = Vector3.Cross(d - b, c - a);
                if (RockSpallSteps <= 1 || face.sqrMagnitude < 1e-10f)
                {
                    AddQuad(a, b, c, d, FacetColour(ring, side, mid));
                    return;
                }

                Vector3 normal = face.normalized;
                // Amplitude off the SHORT edge, divided by the step count: a sub-facet's tilt is its
                // displacement over its OWN width, so writing the budget as a slope keeps the tilt —
                // and therefore the key-leak margin — independent of how finely the quad is cut.
                float shortest = Mathf.Min(
                    Mathf.Min((b - a).magnitude, (c - b).magnitude),
                    Mathf.Min((d - c).magnitude, (a - d).magnitude));
                float amplitude = shortest * (RockSpallSlope / RockSpallSteps);

                Vector3 Grid(int i, int j)
                {
                    float u = i / (float)RockSpallSteps;
                    float v = j / (float)RockSpallSteps;
                    Vector3 p = Vector3.Lerp(Vector3.Lerp(a, b, u), Vector3.Lerp(d, c, u), v);

                    // The boundary NEVER moves: the outline, the silhouette and the seam with the
                    // neighbouring quad are byte-for-byte what they were before this pass existed.
                    if (i == 0 || j == 0 || i == RockSpallSteps || j == RockSpallSteps)
                    {
                        return p;
                    }

                    float relief = (Hash21(
                        (i * 3.7f) + (side * 11.3f) + (ring * 5.9f) + (variant * 2.7f),
                        (j * 6.1f) + (side * 4.3f) + (ring * 9.7f)) - 0.5f) * 2f * amplitude;
                    return p + (normal * relief);
                }

                for (int j = 0; j < RockSpallSteps; j++)
                {
                    for (int i = 0; i < RockSpallSteps; i++)
                    {
                        AddQuad(
                            Grid(i, j), Grid(i + 1, j), Grid(i + 1, j + 1), Grid(i, j + 1),
                            FacetTone(
                                (side * 3.1f) + (ring * 7.7f) + (i * 1.9f) + (j * 13.1f), mid));
                    }
                }
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
                        if (framing)
                        {
                            AddSpalledQuad(a, b, c, d, ring, side, mid);
                        }
                        else
                        {
                            AddQuad(a, b, c, d, FacetColour(ring, side, mid));
                        }
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
                case AnchorOnlyVariant:
                    return new[] { 0.74f, 0.80f, 0.76f, 0.66f, 0.42f };       // leaning monolith
                // ROUND-6 FRAMING MASSES. Six and eight rings against the family's five, because
                // the silhouette of a stone that fills a third of a frame is drawn with segments and
                // the segments have to be short. The near mass swells at ring 2 and dies back to a
                // broken tip; the jamb carries its bulk almost to the top and then breaks off, which
                // is what a wall of rock cropped by a frame edge does — it does not taper politely
                // to a point, or it reads as a cone and not as a jamb.
                case NearMassVariant:
                    return new[] { 0.78f, 0.88f, 0.96f, 0.86f, 0.70f, 0.44f };
                case BrokenJambVariant:
                    return new[] { 0.80f, 0.92f, 1.00f, 0.94f, 0.86f, 0.74f, 0.58f, 0.34f };
                // The fallback keeps the family's FIVE rings on purpose: RockRingHeights' own
                // fallback is five long, and the two arrays are indexed together in BuildRockMesh —
                // a variant id that ran past both tables and picked up eight radii against five
                // heights would not look wrong, it would throw.
                default:
                    return new[] { 0.86f, 0.82f, 0.70f, 0.54f, 0.34f };
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
                // The round-6 framing masses (see RockProfile): six and eight rings, so their
                // outlines are drawn with five and seven segments instead of four. The longest run
                // of silhouette that CAN be a straight line falls from a quarter of the stone's
                // height to a fifth and a seventh — which, with the ring jog moving each one off its
                // neighbour's line, is the whole of the "dead-vertical 390 px edge" finding.
                case NearMassVariant:
                    return new[] { -0.14f, 0.14f, 0.36f, 0.58f, 0.80f, 1.00f };
                case BrokenJambVariant:
                    return new[] { -0.12f, 0.10f, 0.26f, 0.42f, 0.58f, 0.72f, 0.86f, 1.00f };
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
                // Six on the near mass: it is looked at from three metres, where four planes are
                // four flat acres of one value, and the azimuth jitter needs sides to scatter.
                case NearMassVariant: return 6;
                case BrokenJambVariant: return 7;   // odd, so no face is parallel to the one opposite
                default: return 6 + (variant % 3);
            }
        }
    }
}
