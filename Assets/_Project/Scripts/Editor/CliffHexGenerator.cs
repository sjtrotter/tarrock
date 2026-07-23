namespace Tarrock.Editor
{

    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using Tarrock.Player;
    using Tarrock.Regions;
    using Unity.Cinemachine;
    using UnityEditor;
    using UnityEditor.SceneManagement;
    using UnityEngine;
    using UnityEngine.InputSystem;

    /// <summary>
    /// Builds the Cliff region as a KayKit hex-diorama scene (<c>CliffHex.unity</c>), the real
    /// tutorial region that will replace the flat greybox <c>Cliff.unity</c>. Deterministic: the
    /// whole plateau is derived from the explicit constants and shape functions in this file, not
    /// from unseeded randomness, so re-running produces the identical scene.
    ///
    /// Canon this honours (docs/design/world.md §The Cliff, docs/design/art-audio.md §Current build,
    /// docs/quests/main/MQ00-the-leap.md):
    /// - A high meadow plateau at the world's broken edge; a valley funnels the Fool west
    ///   (terrain grammar: cliffs refuse, slopes permit, landmarks pull — art-audio swap rule 5).
    /// - Scale contract: one hex ≈ 4 m flat-to-flat (KayKit tile is 2 m, parent scaled ×2).
    /// - Marker ids carry over verbatim from the flat Cliff (swap discipline: gameplay references
    ///   markers, not meshes). Their world XZ are the flat-Cliff values compressed ×<see cref="Compress"/>
    ///   about the origin — the director shrank the region ~45% (traversal time is the design
    ///   variable, not footprint); relative layout is preserved, so quest references are safe.
    ///
    /// The valley is NOT a corridor (art-audio §Current build rule 6, "No uniform corridors"). It is a
    /// wandering chain of unequal spaces: a trail polyline that BENDS at every campsite, with the
    /// corridor half-width pinching (the Blank ambush sits at the tightest point) and bulging along
    /// its length; the floor climbs to a bench and drops into a hollow (every level change reached by
    /// a ramp — slopes permit); the flanking ridges rise and fall 1–3 steps with a few low saddles
    /// that show sky; and three off-trail pockets reward stepping aside.
    ///
    /// - The single dead tree is the ONLY dead thing on the plateau (the thesis in miniature), on its
    ///   north knoll. The Waystation is a wayside shrine on a rise. The west rim past the Waystation is
    ///   the broken edge, where the LeapOfFaith trigger sits over floating cloud.
    ///
    /// Two entry points, mirroring the greybox generator + rig installer pattern:
    ///   Tarrock/Setup/Generate Cliff Hex Terrain — terrain, dressing, markers, lighting.
    ///   Tarrock/Setup/Install Player In Cliff Hex — the playable KayKit rig + orbit camera.
    /// </summary>
    public static class CliffHexGenerator
    {
        // -- Vendored assets ------------------------------------------------------------------
        private const string HexDir = "Assets/ThirdParty/KayKit/Hexagon/tiles/base";
        private const string HexGrass = HexDir + "/hex_grass.fbx";
        private const string HexBottom = HexDir + "/hex_grass_bottom.fbx";
        private const string HexSlope = HexDir + "/hex_grass_sloped_high.fbx";

        private const string DecoDir = "Assets/ThirdParty/KayKit/Hexagon/decoration";
        private const string BuildDir = "Assets/ThirdParty/KayKit/Hexagon/buildings";
        private const string ForestDir = "Assets/ThirdParty/KayKit/ForestNature";
        private const string QuatDir = "Assets/ThirdParty/Quaternius/StylizedNature";
        private const string DeadTreeAsset = QuatDir + "/DeadTree_3.fbx";

        private const string SceneDir = "Assets/_Project/Scenes/Regions";
        private const string CliffHexScenePath = SceneDir + "/CliffHex.unity";

        // -- Rig / animation assets (built by KayKitCharacterInstaller; reused here) -----------
        private const string CharacterModelPath =
            "Assets/ThirdParty/KayKit/Adventurers/Characters/Rogue_Hooded.fbx";
        private const string ControllerPath = "Assets/_Project/Art/Characters/RogueKayKit.controller";
        private const string InputAssetPath = "Assets/_Project/Input/TarrockActions.inputactions";
        private const float VisualScale = 0.30f; // diorama contract (~0.7 m Fool)

        // -- Hex grid geometry (world metres) -------------------------------------------------
        // Parent CliffTerrain is scaled ×2, so a tile authored at local width 2 reads as 4 m.
        private const float ParentScale = 2f;
        private const float ColDX = 4f;                    // column spacing (flat-to-flat width)
        private const float RowDZ = 3.4641016f;            // row spacing = 3/4 × pointy height
        // Grid tightened to the compressed footprint (director shrank the region ~45%).
        private const float ZNorth = 50f;                  // world z of grid row 0 (north edge)
        private const float XWest0 = -74f;                 // world x of grid column 0
        private const int Rows = 25;
        private const int Cols = 34;
        private const float StepWorld = 2f;                // one elevation step in world metres

        // Director revision: shrink the region ~45% by compressing every marker/landmark XZ about the
        // origin by this single factor. Marker ids and relative layout are unchanged.
        private const float Compress = 0.55f;

        // -- Seam policy (director playtest round 3, items 1 & 2) ------------------------------
        // Elevated tiles overlap the level below so no exact-meeting edge or void ever shows: walls
        // drop this far INTO the floor they sit on; under-skirts sink this far PAST the lowest
        // neighbour's surface. 0.25 m ≈ 0.2-0.3 world units as the director asked.
        private const float SeamSink = 0.25f;

        // -- Camera feel (director round 3, item 4) -------------------------------------------
        // Pivot at the head (not chest), pulled back, and a far wider vertical tilt so the Fool can
        // look up into open sky and down onto himself from above. Mirrored in KayKitCharacterInstaller.
        private const float CamPivotFactor = 0.92f;    // was 0.78 (chest) → ~head height
        private const float CamRadiusFactor = 3.3f;    // was 2.8 → ~18% further back
        // Full look-up: −12° grazes the camera just above the grass looking up past the Fool's head —
        // mostly sky above him. Lower would put the orbit under the meadow floor and the deoccluder
        // pull-in makes the boots fill the frame (play-tested at −26/−34).
        private const float CamVerticalMin = -12f;
        private const float CamVerticalMax = 70f;      // full look-down: the Fool seen from above
        private const float CamVerticalDefault = 16f;  // resting tilt, a touch higher than the old 10
        // Third-person field of view (director round 4, item 5). Raised from the Cinemachine default
        // 55 to open up the cramped diorama read. Named so the director can also tune the
        // CinemachineCamera lens live in the inspector. Tried 62–65; 64 reads open without fisheye.
        private const float CamFieldOfView = 64f;

        // -- Atmosphere assets (mood pass, docs/design/art-audio.md) --------------------------
        private const string AtmoDir = "Assets/_Project/Art/Atmosphere";
        private const string GradientSkyShader = "Tarrock/GradientSky";

        // -- Dressing materials (final dressing pass) -----------------------------------------
        // Persisted colour materials the dressing pass tints props with (created once per run,
        // like the sky/mote materials, so the scene's renderer references survive a rebuild).
        //   WhiteRose — the White Rose stand-in reads WHITE/cream, not the flower atlas's blue
        //               (GLOSSARY §The White Rose / world.md §The Cliff: the Rose regrows here).
        //   DisturbedEarth — flat earthy brown for the keepsake dig mound and the bare ground in
        //               the dead tree's shade (MQ00: "nothing grows in its shade").
        private const string MatDir = "Assets/_Project/Art/Materials";
        private static Material s_dirtMat; // cached: one asset, referenced by several decals

        // Double-sided TERRAIN materials (FIX 2, prong b): the wall/floor tiles share the KayKit hex
        // atlas material, whose backfaces are culled — so when the wall camera is pushed hard against a
        // wall and its final position grazes the undesigned tile interior, it would see THROUGH the wall
        // (backface holes). A Cull-Off (Render Face = Both) variant of each terrain material is created
        // once per run and used for every tile, so any residual interior view reads as solid ground-
        // coloured geometry, never a see-through hole. Props/characters keep their own materials (this
        // only touches the tile meshes built by MakeTile), so their silhouettes are unaffected.
        //
        // Keyed by source material NAME, not instance: the grass/bottom/slope FBXs each ship their OWN
        // copy of the shared "hexagons_medieval" atlas material (same name, different instances). Keying
        // by name means one variant asset is created and reused for all of them — keying by instance
        // made three variants collide on one asset path, and each DeleteAsset+CreateAsset destroyed the
        // previous variant, leaving earlier tiles pointing at a deleted (magenta) material.
        private static readonly Dictionary<string, Material> s_doubleSidedTerrain =
            new Dictionary<string, Material>();

        // -- Bound-state ambience (art-audio.md §world-state rules) ----------------------------
        // The bound world holds its breath: a short, near-static air bed whose loop is *allowed*
        // to be audible (NOT wind gusts). 2D, gentle, always on.
        private const string AudioDir = "Assets/_Project/Audio/Ambience";
        private const string CliffAmbienceClipPath = AudioDir + "/CliffBoundAmbience.wav";
        private const float AmbienceVolume = 0.35f;

        // -- Prop-collider policy (director round 4) ------------------------------------------
        // ONE central rule, applied uniformly so every object feels the same (the director's single
        // source of truth: the hitbox matches the geometry). Categories are few and absolute:
        //   1 SOLID  — the visible convex mesh IS the hitbox (rocks, stones, menhirs, boulders,
        //              barrels, crates, buckets, sacks, lumber, resource stone, well, tent, flag,
        //              firestones, cairns). A convex MeshCollider off the object's OWN render mesh;
        //              no fitted boxes with corners poking past round rock.
        //   2 TREE   — trunk-only capsule (living + dead). Radius is MEASURED from the actual trunk
        //              (horizontal ray-rings cast into the low trunk band), not inferred, so a thin
        //              sapling gets a thin hitbox and a fat trunk a fat one, and the canopy/leaves
        //              NEVER collide. Each capsule is then VERIFIED against the visual trunk.
        //   3 BUSH   — resolved by MEASURED world height into two tiers (director round 5): a TALL
        //              bush (> 60% of player height) becomes SOLID (its own convex mesh, like a rock);
        //              a SHORT bush gets no blocker but a foliage-drag TRIGGER that slows the walk.
        //   0 NONE   — grass, flowers, tufts and clouds: walk straight through.
        // Each Place() records its instance + category; BuildPropColliders resolves them AFTER all
        // dressing (so post-Place rescales are final). SOLID colliders live on the prop's own mesh
        // child (exact geometry under any rotation/non-uniform scale); TREE capsules and SHORT-bush
        // foliage triggers live upright in world-scale-1 roots. Then WalkabilitySweep nudges any
        // BLOCKING collider (not the soft foliage triggers) out of a walkable lane. Convex limit is
        // 255 tris — meshes over that get a hull-simplified fallback (reported).
        private static Transform s_propColliders;
        private static Transform s_foliageTriggers; // world scale 1: soft SHORT-bush drag volumes

        private sealed class PropRec
        {
            public GameObject Root;
            public int Category;                                  // 1 solid, 2 tree, 3 bush
            public readonly List<GameObject> ColliderObjs = new List<GameObject>(); // external (tree/bush)
        }

        private static readonly List<PropRec> s_props = new List<PropRec>();
        private static readonly Dictionary<Collider, PropRec> s_colliderToRec =
            new Dictionary<Collider, PropRec>();
        private static readonly List<string> s_colliderNotes = new List<string>();
        private static readonly List<string> s_treeMeasureLog = new List<string>();
        private static readonly List<Vector3> s_rampCenters = new List<Vector3>();
        private static int s_sweepBefore, s_sweepAfter, s_sweepNudged;
        private static int s_bushShort, s_bushTall, s_treePass, s_treeFail;
        private static int s_groundChecked, s_groundCorrected;
        private static readonly List<string> s_groundLog = new List<string>();

        // Player capsule dimensions for the walkability sweep (must match the CharacterController in
        // BuildPlayerRig: height 0.71 m, radius 0.16 m).
        private const float PlayerHeight = 0.71f;
        private const float PlayerRadius = 0.16f;

        // Bush tiers (director round 5): a bush taller than 60% of the player is a SOLID obstacle;
        // shorter bushes are soft (walk-through with a drag).
        private const float TallBushHeight = 0.60f * PlayerHeight; // 0.426 m

        // Trunk measurement (director round 5): sample the trunk cross-section at these fractions of
        // the player's height above the tree's base (≈0.11 / 0.25 / 0.39 m), inside the trunk zone
        // and below any canopy, casting 16 inward rays per height. Radius = max hit + this skin.
        private static readonly float[] TrunkSampleFractions = { 0.15f, 0.35f, 0.55f };
        private const int TrunkRayCount = 16;
        private const float TrunkSkin = 0.02f;

        // The Waystation is a landmark the player arrives AT (a shrine on a rise), not a lane to keep
        // clear — its solid well/flags are protected from the sweep within this radius so the shrine is
        // never evicted off its mark. (WaystationXZ is referenced live in the sweep, not here, because
        // static field initializers run top-to-bottom and WaystationXZ is declared further down.)
        private const float WaystationKeepout = 4.5f;

        // -- Region roots ---------------------------------------------------------------------
        private const string TerrainRootName = "CliffTerrain";
        private const string TilesGroupName = "Tiles";
        private const string DecoGroupName = "Deco";
        private const string MarkersRootName = "RegionMarkers";
        private const string PlayerRootName = "PlayerRig";
        private const string CameraRootName = "CameraRig";
        private const string PlayerSpawnName = "PlayerSpawn_Campfire";
        private const string PlayerTag = "Player";

        // -- Landmark world XZ (flat-Cliff values × Compress; see CliffMarkerIds / MQ00) ------
        private static readonly Vector2 WaystationXZ = new Vector2(-55f, 0f);      // -100 × .55
        private static readonly Vector2 DeadTreeXZ = new Vector2(-5.5f, 35.75f);   // (-10,65) × .55
        private static readonly Vector2 SpawnXZ = new Vector2(44.825f, 0f);        //  81.5 × .55
        private static readonly Vector2 CliffEdgeXZ = new Vector2(-65.45f, 0f);    // -119 × .55
        private static readonly Vector2 KeepsakeXZ = new Vector2(1.76f, 6.16f);    // (3.2,11.2) × .55
        private static readonly Vector2 AmbushXZ = new Vector2(-41.25f, 0f);       //  -75 × .55
        private static readonly Vector3 LeapTriggerPos = new Vector3(-68.75f, -8f, 0f); // xz × .55, y kept
        private static readonly Vector3 LeapTriggerSize = new Vector3(5.5f, 20f, 132f); // x,z × .55, y kept

        // The six old campsites (world XZ, compressed). The trail BENDS through them: this zigzag IS
        // the corridor axis, not decoration laid over a straight cut.
        private static readonly Vector2[] CampXZ =
        {
            new Vector2(44f, 0f),     // 1 — the wake campfire (holds the spawn); open bulge
            new Vector2(30.8f, -9.9f),// 2 — trail swings south
            new Vector2(20.9f, 7.7f), // 3 — on a small rise (bench, +1)
            new Vector2(11.55f, -8.8f),// 4 — bench, trail swings south again
            new Vector2(1.65f, 6.6f), // 5 — largest; the keepsake dig spot, sunk in a hollow (−1)
            new Vector2(-7.7f, -3.3f),// 6 — recent; tucked against a rock outcrop
        };

        // Standing stones flank the trail at the pinch just before the ambush (MQ00 "path narrows
        // between two standing stones"). Flat Cliff put them at x -50, z ±8 → compressed.
        private static readonly Vector2[] StandingStoneXZ =
        {
            new Vector2(-27.5f, 4.4f),
            new Vector2(-27.5f, -4.4f),
        };

        // ------------------------------------------------------------------------------------
        // Trail: a bending polyline of unequal spaces (art-audio rule 6). Each waypoint carries a
        // floor level (integer steps) and a corridor half-width in metres. Consecutive levels never
        // differ by more than one step, so every transition is a single walkable ramp.
        // ------------------------------------------------------------------------------------
        private static readonly Vector2[] TrailXZ =
        {
            new Vector2(44.8f, 0f),   //  0 spawn / camp1
            new Vector2(30.8f, -9.9f),//  1 camp2
            new Vector2(20.9f, 7.7f), //  2 camp3  (bench)
            new Vector2(11.55f, -8.8f),// 3 camp4  (bench)
            new Vector2(6.6f, -1.1f), //  4 step-down off the bench
            new Vector2(1.65f, 6.6f), //  5 camp5  (hollow)
            new Vector2(-7.7f, -3.3f),//  6 camp6  (outcrop)
            new Vector2(-27.5f, 0f),  //  7 standing stones (pinch)
            new Vector2(-41.25f, 0f), //  8 ambush (pinch)
            new Vector2(-55f, 0f),    //  9 waystation (rise)
            new Vector2(-65.45f, 0f), // 10 cliff edge (broken rim)
        };

        private static readonly int[] TrailLevelArr = { 0, 0, 1, 1, 0, -1, 0, 0, 0, 1, 0 };

        // Half-widths alternate pinch (≈1–2 hexes) and bulge (≈5–6 hexes); the two pinches at the
        // stones and the ambush form a narrow gorge into the staged fight.
        private static readonly float[] TrailHalfW = { 11f, 8f, 10f, 7f, 7f, 12f, 8f, 4f, 4f, 10f, 9f };

        // North knoll peninsula holding the one dead tree (a raised finger, +1). Reached from the
        // valley by the neck ramp below.
        private static readonly Vector2 KnollC = new Vector2(-5.5f, 25f);
        private const float KnollRx = 13f;
        private const float KnollRz = 14f;

        // Off-trail pockets (set dressing only, no new canon): a grove hollow, a stone circle, and a
        // rim overlook. Each is a small walkable blob that opens onto the trail and is walled behind.
        private static readonly Vector2[] PocketC =
        {
            new Vector2(18f, 14f),   // A — grove hollow, dips off the bench's north edge
            new Vector2(-16f, -13f), // B — stone circle, south of the mid trail
            new Vector2(-60f, -8f),  // C — rim overlook, on the broken edge over cloud
        };
        private static readonly float[] PocketR = { 6.5f, 5.5f, 5.5f };
        private static readonly int[] PocketLvl = { 0, 0, 0 };
        private static readonly string[] PocketName =
        {
            "Pocket_A_GroveHollow", "Pocket_B_StoneCircle", "Pocket_C_RimOverlook",
        };

        // A few deliberate low saddles in the flanking ridge — the wall dips to one step so the
        // elevated camera glimpses sky/cloud beyond (still sealed: one step is unclimbable).
        private static readonly Vector2[] SaddleXZ =
        {
            new Vector2(26f, 22f),   // north wall, above the bench
            new Vector2(0f, -17f),   // south wall, beside the hollow
            new Vector2(-40f, 10f),  // north wall, above the ambush gorge
        };
        private const float SaddleR = 7.5f;

        // ------------------------------------------------------------------------------------
        // Menu entry: terrain + dressing + markers + lighting
        // ------------------------------------------------------------------------------------

        [MenuItem("Tarrock/Setup/Generate Cliff Hex Terrain")]
        public static void Generate()
        {
            if (EditorApplication.isPlaying)
            {
                Debug.LogError("[Tarrock] Exit play mode before generating the Cliff hex terrain.");
                return;
            }

            Mesh grassMesh = MeshOf(HexGrass, out Material[] grassMats);
            Mesh bottomMesh = MeshOf(HexBottom, out Material[] bottomMats);
            Mesh slopeMesh = MeshOf(HexSlope, out Material[] slopeMats);
            if (grassMesh == null || bottomMesh == null || slopeMesh == null)
            {
                Debug.LogError("[Tarrock] KayKit hex base tiles not found; aborting Cliff hex build.");
                return;
            }

            UnityEngine.SceneManagement.Scene scene =
                EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            var terrain = new GameObject(TerrainRootName);
            terrain.transform.localScale = Vector3.one * ParentScale;
            var tiles = new GameObject(TilesGroupName);
            tiles.transform.SetParent(terrain.transform, false);
            var deco = new GameObject(DecoGroupName);
            deco.transform.SetParent(terrain.transform, false);

            s_doubleSidedTerrain.Clear(); // FIX 2b: terrain Cull-Off variants rebuilt this run (before tiles)

            // 1) Walkable cells (valley floor, pockets, knoll) and their floor levels.
            var walkable = new Dictionary<(int, int), Vector2>();
            var floorLvl = new Dictionary<(int, int), int>();
            for (int r = 0; r < Rows; r++)
            {
                for (int c = 0; c < Cols; c++)
                {
                    Vector2 xz = CellXZ(r, c);
                    if (Walkable(xz.x, xz.y))
                    {
                        walkable[(r, c)] = xz;
                        floorLvl[(r, c)] = FloorLevelAt(xz.x, xz.y);
                    }
                }
            }

            // 2) Seal the walkable region with a 2-ring wall of raised, undulating grass — except the
            //    broken west rim, which is left open over the void. Wall height is 1–3 steps above the
            //    floor it borders, dropping to one step at the saddles.
            var present = new Dictionary<(int, int), Vector2>(walkable);
            var wallLvl = new Dictionary<(int, int), int>();
            var refLevel = new Dictionary<(int, int), int>(floorLvl);
            List<(int, int)> frontier = walkable.Keys.ToList();
            for (int ring = 1; ring <= 2; ring++)
            {
                var next = new List<(int, int)>();
                foreach ((int, int) cell in frontier)
                {
                    int fr = refLevel[cell];
                    foreach ((int, int) nb in HexNeighbours(cell.Item1, cell.Item2))
                    {
                        if (!InGrid(nb) || present.ContainsKey(nb))
                        {
                            continue;
                        }

                        Vector2 nxz = CellXZ(nb.Item1, nb.Item2);
                        if (nxz.x < -60f)
                        {
                            continue; // west opening: no wall beyond the broken rim
                        }

                        int steps = SaddleNear(nxz) ? 1 : WallSteps(nb.Item1, nb.Item2);
                        present[nb] = nxz;
                        wallLvl[nb] = fr + steps;
                        refLevel[nb] = fr;
                        next.Add(nb);
                    }
                }

                frontier = next;
            }

            int tileCount = 0, wallCount = 0, rampCount = 0, slabCount = 0;
            s_rampCenters.Clear();
            foreach (KeyValuePair<(int, int), Vector2> kv in present)
            {
                (int r, int c) = kv.Key;
                Vector2 xz = kv.Value;
                bool isWall = wallLvl.ContainsKey((r, c));
                bool boundary = IsBoundary(r, c, present);
                bool westRim = boundary && xz.x < -58f;
                int level = isWall ? wallLvl[(r, c)] : floorLvl[(r, c)];
                float groundY = level * StepWorld;
                // Walls drop SeamSink into the floor they sit on so no seam line shows where wall
                // meets floor (item 2). Walkable tiles keep their true surface height (grounding +
                // marker heights unchanged).
                float topY = isWall ? groundY - SeamSink : groundY;

                if (isWall)
                {
                    MakeTile(grassMesh, grassMats, new Vector3(xz.x, topY, xz.y), 0f, tiles.transform,
                        $"wall_{r}_{c}");
                    wallCount++;
                }
                else if (!westRim && TryFloorRamp((r, c), xz, floorLvl, walkable, out float rampYaw))
                {
                    // A walkable tile that meets a higher walkable neighbour becomes a slope up to it
                    // (slopes permit; cliffs — the walls above — refuse).
                    MakeTile(slopeMesh, slopeMats, new Vector3(xz.x, topY, xz.y), rampYaw, tiles.transform,
                        $"ramp_{r}_{c}");
                    s_rampCenters.Add(new Vector3(xz.x, topY, xz.y));
                    rampCount++;
                }
                else
                {
                    MakeTile(grassMesh, grassMats, new Vector3(xz.x, topY, xz.y), 0f, tiles.transform,
                        $"hex_{r}_{c}");
                }

                tileCount++;

                // Under-skirt: fill every downward face so no void shows between elevations (item 1),
                // sinking SeamSink past the lowest neighbour's surface (no exact-meeting edge). Boundary
                // cells additionally float the plateau on a ragged underside (diorama-on-a-table read),
                // and carved interior holes read as deliberate broken openings with dirt skirts inside.
                int minNb = level;
                foreach ((int, int) nb in HexNeighbours(r, c))
                {
                    if (present.ContainsKey(nb))
                    {
                        int nlvl = wallLvl.ContainsKey(nb) ? wallLvl[nb] : floorLvl[nb];
                        if (nlvl < minNb)
                        {
                            minNb = nlvl;
                        }
                    }
                }

                float skirtTop = topY - StepWorld; // the tile body already reaches down to here
                float target = skirtTop;
                if (minNb < level && (isWall || level - minNb >= 2))
                {
                    target = Mathf.Min(target, (minNb * StepWorld) - SeamSink);
                }

                if (boundary)
                {
                    float depthSteps = westRim ? 3f : (Hash01(r, c) > 0.5f ? 3f : 2f);
                    target = Mathf.Min(target, topY - (depthSteps * StepWorld));
                }

                slabCount += FillSkirt(bottomMesh, bottomMats, tiles.transform, xz, skirtTop, target,
                    $"skirt_{r}_{c}");
            }

            s_props.Clear();
            s_colliderToRec.Clear();
            s_colliderNotes.Clear();
            s_treeMeasureLog.Clear();
            s_bushShort = s_bushTall = s_treePass = s_treeFail = 0;
            s_groundChecked = s_groundCorrected = 0;
            s_groundLog.Clear();
            s_dirtMat = null; // rebuilt on first dressing use this run
            s_propColliders = new GameObject("PropColliders").transform; // world scale 1, unrotated
            s_foliageTriggers = new GameObject("FoliageTriggers").transform; // world scale 1, soft drag volumes

            DressCampsites(deco.transform);
            DressStandingStones(deco.transform);
            DressWaystation(deco.transform);
            DressDeadTree(deco.transform);
            DressGroves(deco.transform);
            DressPockets(deco.transform);
            DressLeapEdge(deco.transform);
            DressClouds(deco.transform);

            int propColliders = BuildPropColliders(out int solidCols, out int treeCols);
            GroundDressing(tiles.transform);
            WalkabilitySweep(deco.transform);

            BuildMarkers();
            BuildLighting();
            BuildAtmosphere();
            BuildAmbience();

            Directory.CreateDirectory(SceneDir);
            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, CliffHexScenePath);
            AssetDatabase.SaveAssets();

            string notes = s_colliderNotes.Count == 0 ? "none" : string.Join("; ", s_colliderNotes);
            Debug.Log($"[Tarrock] Cliff hex terrain built into {CliffHexScenePath}: {tileCount} tiles " +
                $"({wallCount} sealed as walls, {rampCount} ramps), {slabCount} underside/skirt slabs. " +
                $"Prop colliders: {solidCols} SOLID convex-mesh, {treeCols} TREE trunk-capsules " +
                $"({propColliders} total). Bush tiers: {s_bushShort} SHORT (foliage-drag triggers), " +
                $"{s_bushTall} TALL (solid). Tree verify: {s_treePass} pass, {s_treeFail} fail. " +
                $"Convex-limit fallbacks: {notes}. " +
                $"Walkability sweep: {s_sweepBefore} violations before, {s_sweepAfter} after " +
                $"({s_sweepNudged} props nudged). Run 'Install Player In Cliff Hex' next.");

            Debug.Log($"[Tarrock] Grounding audit (FIX 3): {s_groundChecked} dressing units checked, " +
                $"{s_groundCorrected} floaters lowered onto the terrain" +
                (s_groundLog.Count == 0 ? " (none floating)." : ":\n  " + string.Join("\n  ", s_groundLog)));

            Debug.Log("[Tarrock] Tree trunk measurement table (radius m, verify): " +
                (s_treeMeasureLog.Count == 0 ? "no trees" : "\n  " + string.Join("\n  ", s_treeMeasureLog)));
        }

        // Stacks bottom-mesh slabs downward from <paramref name="topY"/> to at least
        // <paramref name="bottomY"/> (each slab is one StepWorld tall, top-anchored at its position),
        // closing a downward face with dirt so no void shows. Returns the slab count.
        private static int FillSkirt(Mesh mesh, Material[] mats, Transform parent, Vector2 xz,
            float topY, float bottomY, string name)
        {
            int n = 0;
            for (float y = topY; y > bottomY + 0.05f; y -= StepWorld)
            {
                MakeTile(mesh, mats, new Vector3(xz.x, y, xz.y), 0f, parent, $"{name}_{n}");
                n++;
            }

            return n;
        }

        // ------------------------------------------------------------------------------------
        // Plateau shape + elevation (trail-driven)
        // ------------------------------------------------------------------------------------

        // World XZ centre of the pointy-top offset cell at (row, col).
        private static Vector2 CellXZ(int r, int c)
        {
            float x = XWest0 + (c * ColDX) + ((r & 1) * (ColDX * 0.5f));
            float z = ZNorth - (r * RowDZ);
            return new Vector2(x, z);
        }

        // A cell is walkable floor if it lies within the trail corridor (whose half-width varies), or
        // inside a pocket, the knoll, or the knoll neck. The corridor stops at the broken west rim.
        private static bool Walkable(float x, float z)
        {
            if (x < -66f)
            {
                return false; // west of the broken edge is void
            }

            if (InEllipse(x, z, KnollC.x, KnollC.y, KnollRx, KnollRz) || InNeck(x, z))
            {
                return true;
            }

            for (int i = 0; i < PocketC.Length; i++)
            {
                if (InEllipse(x, z, PocketC[i].x, PocketC[i].y, PocketR[i], PocketR[i]))
                {
                    return true;
                }
            }

            TrailQuery(x, z, out int seg, out float t, out float dist);
            return dist <= Mathf.Lerp(TrailHalfW[seg], TrailHalfW[seg + 1], t);
        }

        // Integer floor level of any walkable point. Pockets/knoll/neck declare their own level; the
        // corridor takes the level of its nearest trail waypoint (bands that meet at single-step
        // ramps).
        private static int FloorLevelAt(float x, float z)
        {
            if (InEllipse(x, z, KnollC.x, KnollC.y, KnollRx, KnollRz))
            {
                return 1;
            }

            for (int i = 0; i < PocketC.Length; i++)
            {
                if (InEllipse(x, z, PocketC[i].x, PocketC[i].y, PocketR[i], PocketR[i]))
                {
                    return PocketLvl[i];
                }
            }

            if (InNeck(x, z))
            {
                return z >= 8f ? 1 : 0;
            }

            TrailQuery(x, z, out int seg, out float t, out float _);
            return TrailLevelArr[t < 0.5f ? seg : seg + 1];
        }

        // Nearest point on the trail polyline: segment index, parameter along it, perpendicular dist.
        private static void TrailQuery(float x, float z, out int seg, out float t, out float dist)
        {
            var p = new Vector2(x, z);
            seg = 0;
            t = 0f;
            float best = float.MaxValue;
            for (int i = 0; i < TrailXZ.Length - 1; i++)
            {
                Vector2 a = TrailXZ[i];
                Vector2 ab = TrailXZ[i + 1] - a;
                float len2 = ab.sqrMagnitude;
                float tt = len2 > 1e-6f ? Mathf.Clamp01(Vector2.Dot(p - a, ab) / len2) : 0f;
                float d = Vector2.Distance(p, a + (ab * tt));
                if (d < best)
                {
                    best = d;
                    seg = i;
                    t = tt;
                }
            }

            dist = best;
        }

        // The knoll neck: a short walkable throat joining the valley (level 0) to the knoll (level 1),
        // stepping up at z = 8 so the transition is a single ramp.
        private static bool InNeck(float x, float z)
        {
            return x >= -10f && x <= -1f && z >= 3f && z <= 11f;
        }

        private static bool InEllipse(float x, float z, float cx, float cz, float rx, float rz)
        {
            float nx = (x - cx) / rx;
            float nz = (z - cz) / rz;
            return (nx * nx) + (nz * nz) <= 1f;
        }

        // Wall height above the floor it borders: 1–3 steps, undulating over ~3-cell blocks so ridges
        // rise and fall rather than jitter per cell.
        private static int WallSteps(int r, int c)
        {
            return 1 + Mathf.FloorToInt(Hash01(FloorDiv(r, 3), FloorDiv(c, 3)) * 2.999f);
        }

        private static bool SaddleNear(Vector2 xz)
        {
            foreach (Vector2 s in SaddleXZ)
            {
                if (Vector2.Distance(xz, s) <= SaddleR)
                {
                    return true;
                }
            }

            return false;
        }

        // A walkable tile becomes a ramp when a walkable neighbour sits exactly one step higher; the
        // slope's high edge is turned to face that neighbour. Walls (not in the walkable set) are
        // never ramp targets, so they stay unclimbable cliffs.
        private static bool TryFloorRamp((int, int) cell, Vector2 xz, Dictionary<(int, int), int> floorLvl,
            Dictionary<(int, int), Vector2> walkable, out float yaw)
        {
            yaw = 0f;
            int level = floorLvl[cell];
            Vector2 dir = Vector2.zero;
            int n = 0;
            foreach ((int, int) nb in HexNeighbours(cell.Item1, cell.Item2))
            {
                if (walkable.ContainsKey(nb) && floorLvl[nb] == level + 1)
                {
                    dir += CellXZ(nb.Item1, nb.Item2) - xz;
                    n++;
                }
            }

            if (n == 0)
            {
                return false;
            }

            dir /= n;
            yaw = YawForHighEdge(dir.x, dir.y);
            return true;
        }

        // The slope tile's high edge points at local −X (verified). Solve the yaw that rotates that
        // edge to face direction (dx, dz): −cos θ = dx, sin θ = dz → θ = atan2(dz, −dx).
        private static float YawForHighEdge(float dx, float dz)
        {
            return Mathf.Atan2(dz, -dx) * Mathf.Rad2Deg;
        }

        private static (int, int)[] HexNeighbours(int r, int c)
        {
            int e = r & 1;
            return new[]
            {
                (r, c - 1), (r, c + 1),
                (r - 1, c - 1 + e), (r - 1, c + e),
                (r + 1, c - 1 + e), (r + 1, c + e),
            };
        }

        private static bool InGrid((int, int) rc)
        {
            return rc.Item1 >= 0 && rc.Item1 < Rows && rc.Item2 >= 0 && rc.Item2 < Cols;
        }

        private static bool IsBoundary(int r, int c, Dictionary<(int, int), Vector2> present)
        {
            foreach ((int, int) n in HexNeighbours(r, c))
            {
                if (!present.ContainsKey(n))
                {
                    return true;
                }
            }

            return false;
        }

        // ------------------------------------------------------------------------------------
        // Tile construction (lightweight shared-mesh GameObjects, static, collidable)
        // ------------------------------------------------------------------------------------

        private static GameObject MakeTile(Mesh mesh, Material[] mats, Vector3 worldTop, float yaw,
            Transform parent, string name)
        {
            var go = new GameObject(name);
            go.transform.SetParent(parent, false); // parent is scaled ×2
            go.transform.localPosition = worldTop / ParentScale;
            go.transform.localRotation = Quaternion.Euler(0f, yaw, 0f);
            go.transform.localScale = Vector3.one;

            go.AddComponent<MeshFilter>().sharedMesh = mesh;
            go.AddComponent<MeshRenderer>().sharedMaterials = DoubleSidedTerrain(mats);
            go.AddComponent<MeshCollider>().sharedMesh = mesh;
            go.isStatic = true;
            return go;
        }

        // ------------------------------------------------------------------------------------
        // Dressing
        // ------------------------------------------------------------------------------------

        // Human-scale extras register for the camps (MQ00: "a bootless boot, a bent tin cup, a
        // walking-stick standing upright" — the pack's nearest reads).
        private static readonly string[] CampExtras =
        {
            "props/barrel.fbx", "props/crate_A_small.fbx", "props/sack.fbx",
            "props/bucket_empty.fbx", "props/resource_lumber.fbx",
        };

        // The six old campsites, each a distinct micro-story of a Fool long gone (all cold, all
        // abandoned — no living fire, nothing in use). MQ00 §The Old Campsites: "None of the
        // campsites are the same age… one, tucked under an overhang, looks recent." Arrangement is
        // ours; the register (cold, weathered, wordless) is canon.
        private static void DressCampsites(Transform parent)
        {
            var camps = new GameObject("Campsites");
            camps.transform.SetParent(parent, false);

            for (int i = 0; i < CampXZ.Length; i++)
            {
                Vector2 xz = CampXZ[i];
                float gy = FloorLevelAt(xz.x, xz.y) * StepWorld;
                var rnd = new System.Random(4100 + i);
                var camp = new GameObject($"Camp{i + 1}");
                camp.transform.SetParent(camps.transform, false);
                camp.transform.localPosition = new Vector3(xz.x, gy, xz.y) / ParentScale;

                switch (i)
                {
                    case 0: DressCampSpawn(camp.transform, rnd); break;      // wake camp — stays as-is
                    case 1: DressCampOrderly(camp.transform, rnd); break;    // someone tidy
                    case 2: DressCampCollapsed(camp.transform, rnd); break;  // tent collapsed, half-buried
                    case 3: DressCampScattered(camp.transform, rnd); break;  // left in a hurry
                    case 4: DressCampReclaimed(camp.transform, rnd); break;  // largest, grass-reclaimed
                    case 5: DressCampOutcrop(camp.transform, rnd); break;    // recent, sheltered, a cairn
                }
            }

            // The keepsake dig spot at MQ00_KEEPSAKE_DIGSPOT: a subtle DISTURBED-EARTH read so a
            // player who reaches it sees something diggable (MQ00: "a patch of disturbed earth near
            // the largest campsite" where Pip digs up the whittled dog). Non-colliding earth (it sits
            // on the trail centreline — the dig interaction, and the sweep, must not fight it).
            var dig = new GameObject("KeepsakeDigMound");
            dig.transform.SetParent(camps.transform, false);
            float digY = FloorLevelAt(KeepsakeXZ.x, KeepsakeXZ.y) * StepWorld;
            dig.transform.localPosition = new Vector3(KeepsakeXZ.x, digY, KeepsakeXZ.y) / ParentScale;
            Material dirt = DirtMaterial();
            // A rounded brown mound of freshly-turned earth (rock_single_B scaled to a ~0.8 m lump)
            // ringed by a few loose clods — reads as diggable without shouting.
            PlaceDecal(dig.transform, DecoDir + "/nature/rock_single_B.fbx", new Vector3(0f, 0f, 0f),
                new Vector3(0f, 20f, 0f), new Vector3(1.4f, 1.2f, 1.5f), dirt, "dirt_mound");
            var dr = new System.Random(4290);
            for (int k = 0; k < 4; k++)
            {
                float a = dr.Next(0, 360) * Mathf.Deg2Rad;
                float rad = 0.5f + (float)dr.NextDouble() * 0.4f;
                PlaceDecal(dig.transform, DecoDir + "/nature/rock_single_B.fbx",
                    new Vector3(Mathf.Cos(a) * rad, 0.0f, Mathf.Sin(a) * rad),
                    new Vector3(0f, dr.Next(0, 360), 0f), new Vector3(0.55f, 0.5f, 0.55f), dirt, $"clod_{k}");
            }
        }

        // Cold fire-ring: small stones, no flame (long abandoned).
        private static void ColdFireRing(Transform camp, System.Random rnd, int stones, float radius, float scale)
        {
            for (int s = 0; s < stones; s++)
            {
                float ang = (s / (float)stones) * Mathf.PI * 2f;
                var lp = new Vector3(Mathf.Cos(ang) * radius, 0f, Mathf.Sin(ang) * radius);
                Place(camp, DecoDir + "/nature/rock_single_A.fbx", lp,
                    new Vector3(0f, rnd.Next(0, 360), 0f), scale, $"firestone_{s}", true);
            }
        }

        private static void ScatterExtras(Transform camp, System.Random rnd, int n, float minR, float maxR, bool tipAll)
        {
            for (int p = 0; p < n; p++)
            {
                string prop = CampExtras[rnd.Next(CampExtras.Length)];
                float ang = rnd.Next(0, 360);
                float rad = minR + ((float)rnd.NextDouble() * (maxR - minR));
                var lp = new Vector3(Mathf.Cos(ang * Mathf.Deg2Rad) * rad, 0f,
                    Mathf.Sin(ang * Mathf.Deg2Rad) * rad);
                float tip = tipAll || rnd.NextDouble() > 0.5 ? 90f : 0f;
                Place(camp, DecoDir + "/" + prop, lp,
                    new Vector3(tip, rnd.Next(0, 360), 0f), 1.5f, $"prop_{p}", true);
            }
        }

        // Camp 1 — the wake campfire holding the player spawn (kept as-is: cold ring + weathered tent
        // + a couple of props). The tent sits well clear of the spawn so the Fool never wakes inside
        // its (solid) collider.
        private static void DressCampSpawn(Transform camp, System.Random rnd)
        {
            ColdFireRing(camp, rnd, 6, 0.45f, 0.65f);
            Place(camp, DecoDir + "/props/tent.fbx", new Vector3(1.5f, 0f, 0.9f),
                new Vector3(0f, rnd.Next(0, 360), 3f), 1.6f, "tent", true);
            ScatterExtras(camp, rnd, 1 + rnd.Next(0, 3), 0.7f, 1.3f, false);
        }

        // Camp 2 — someone orderly: a neat, even fire-ring and a tidy row of bedroll-like sacks, one
        // crate squared up beside them. Nothing tipped.
        private static void DressCampOrderly(Transform camp, System.Random rnd)
        {
            ColdFireRing(camp, rnd, 8, 0.5f, 0.6f);
            for (int j = 0; j < 3; j++)
            {
                Place(camp, DecoDir + "/props/sack.fbx", new Vector3(0.95f, 0f, -0.6f + j * 0.6f),
                    new Vector3(0f, 90f, 0f), 1.4f, $"bedroll_{j}", true);
            }

            Place(camp, DecoDir + "/props/crate_A_small.fbx", new Vector3(1.6f, 0f, 0f),
                new Vector3(0f, 0f, 0f), 1.4f, "crate_squared", true);
            Place(camp, DecoDir + "/props/bucket_empty.fbx", new Vector3(-0.85f, 0f, 0.8f),
                new Vector3(0f, rnd.Next(0, 360), 0f), 1.4f, "bucket", true);
        }

        // Camp 3 — the tent has collapsed and is half-buried, the camp mostly given back to the turf.
        private static void DressCampCollapsed(Transform camp, System.Random rnd)
        {
            ColdFireRing(camp, rnd, 6, 0.45f, 0.6f);
            Place(camp, DecoDir + "/props/tent.fbx", new Vector3(0.6f, -0.35f, 0.5f),
                new Vector3(82f, 40f, 6f), 1.6f, "tent_collapsed", true);
            Place(camp, DecoDir + "/props/crate_A_small.fbx", new Vector3(-0.7f, -0.12f, -0.5f),
                new Vector3(18f, 30f, 14f), 1.4f, "crate_halfburied", true);
            Place(camp, DecoDir + "/props/resource_lumber.fbx", new Vector3(1.0f, 0f, -0.8f),
                new Vector3(0f, 70f, 90f), 1.4f, "pole_fallen", true);
        }

        // Camp 4 — left in a hurry: gear flung wide, everything knocked over, the tent toppled.
        private static void DressCampScattered(Transform camp, System.Random rnd)
        {
            ColdFireRing(camp, rnd, 6, 0.5f, 0.6f);
            Place(camp, DecoDir + "/props/tent.fbx", new Vector3(1.2f, 0f, -0.9f),
                new Vector3(88f, rnd.Next(0, 360), 0f), 1.6f, "tent_toppled", true);
            ScatterExtras(camp, rnd, 4, 1.0f, 2.2f, true);
        }

        // Camp 5 — the largest and oldest, sunk in the hollow and nearly reclaimed by grass and bush:
        // a faint ring, a rotted bedroll, foliage creeping over it. (The keepsake dig mound sits at
        // its edge, built separately at the marker.)
        private static void DressCampReclaimed(Transform camp, System.Random rnd)
        {
            ColdFireRing(camp, rnd, 5, 0.5f, 0.55f);
            Place(camp, DecoDir + "/props/sack.fbx", new Vector3(0.8f, -0.08f, 0.4f),
                new Vector3(10f, rnd.Next(0, 360), 0f), 1.4f, "bedroll_rotted", true);
            // Foliage taking the camp back: two short (walk-through) bushes and one tall solid one.
            PlaceBush(camp, ShortBushes[rnd.Next(ShortBushes.Length)], new Vector3(-0.9f, 0f, 0.9f),
                rnd.Next(0, 360), ShortBushWorldHeight, "bush_short_0");
            PlaceBush(camp, ShortBushes[rnd.Next(ShortBushes.Length)], new Vector3(1.1f, 0f, -0.7f),
                rnd.Next(0, 360), ShortBushWorldHeight, "bush_short_1");
            PlaceBush(camp, TallBushes[rnd.Next(TallBushes.Length)], new Vector3(-1.3f, 0f, -0.9f),
                rnd.Next(0, 360), TallBushWorldHeight, "bush_tall_0");
        }

        // Camp 6 — the most recent (MQ00: "tucked under an overhang, looks recent"): sheltered against
        // a rock outcrop, tent still standing, and a small cairn a Fool started but never finished.
        private static void DressCampOutcrop(Transform camp, System.Random rnd)
        {
            ColdFireRing(camp, rnd, 6, 0.45f, 0.62f);
            Place(camp, DecoDir + "/props/tent.fbx", new Vector3(0.9f, 0f, 0.4f),
                new Vector3(0f, rnd.Next(0, 360), -4f), 1.6f, "tent", true);
            ScatterExtras(camp, rnd, 1 + rnd.Next(0, 2), 0.8f, 1.3f, false);
            BuildCairn(camp, new Vector3(1.1f, 0f, -0.7f), 4265, 3, 0.8f, "cairn");

            // The rock outcrop it shelters against (north flank), so the last camp reads sheltered.
            var orn = new System.Random(4211);
            string[] boulders =
            {
                DecoDir + "/nature/rock_single_D.fbx", DecoDir + "/nature/rock_single_E.fbx",
                DecoDir + "/nature/rock_single_C.fbx",
            };
            for (int b = 0; b < 4; b++)
            {
                float a = b * 1.4f;
                var lp = new Vector3(-1.5f + Mathf.Cos(a) * (0.9f + b * 0.35f), 0f, 3.2f + Mathf.Sin(a) * 0.7f);
                GameObject g = Place(camp, boulders[orn.Next(boulders.Length)], lp,
                    new Vector3(0f, orn.Next(0, 360), 0f), 1f, $"boulder_{b}", false);
                if (g != null)
                {
                    g.transform.localScale = new Vector3(2.4f + b * 0.4f, 3.2f + b * 0.6f, 2.4f + b * 0.4f);
                }
            }
        }

        private static void DressStandingStones(Transform parent)
        {
            var group = new GameObject("StandingStones");
            group.transform.SetParent(parent, false);
            for (int i = 0; i < StandingStoneXZ.Length; i++)
            {
                Vector2 xz = StandingStoneXZ[i];
                float gy = FloorLevelAt(xz.x, xz.y) * StepWorld;
                GameObject g = Place(group.transform, DecoDir + "/nature/rock_single_D.fbx",
                    new Vector3(xz.x, gy, xz.y) / ParentScale, new Vector3(0f, i * 40f, i == 0 ? 5f : -6f),
                    1f, $"Stone_{i}", false);
                if (g != null)
                {
                    g.transform.localScale = new Vector3(1.4f, 7f, 1.4f); // menhir proportions
                }
            }
        }

        private static void DressWaystation(Transform parent)
        {
            var group = new GameObject("Waystation");
            group.transform.SetParent(parent, false);
            float gy = FloorLevelAt(WaystationXZ.x, WaystationXZ.y) * StepWorld;
            group.transform.localPosition = new Vector3(WaystationXZ.x, gy, WaystationXZ.y) / ParentScale;

            // The shrine's core silhouette (a walled basin structure), visible from the trail. Canon
            // palette is pale dawn gold / wind-scoured green (world.md §The Cliff) — the yellow ("dawn
            // gold") KayKit set, never the blue variant, so the whole shrine reads warm not cold.
            Place(group.transform, BuildDir + "/yellow/building_well_yellow.fbx", Vector3.zero,
                new Vector3(0f, 15f, 0f), 1.8f, "shrine_basin", false);
            // Flanking flags for verticality — pale dawn gold, matching the shrine palette.
            Place(group.transform, DecoDir + "/props/flag_yellow.fbx", new Vector3(-1.3f, 0f, 0.8f),
                new Vector3(0f, 20f, 0f), 3f, "flag_left", false);
            Place(group.transform, DecoDir + "/props/flag_yellow.fbx", new Vector3(1.3f, 0f, 0.8f),
                new Vector3(0f, -160f, 0f), 3f, "flag_right", false);
            // Old offerings gone to moss.
            Place(group.transform, DecoDir + "/nature/rock_single_C.fbx", new Vector3(0.9f, 0f, -0.9f),
                new Vector3(0f, 40f, 0f), 1.1f, "offering_stone_a", false);
            Place(group.transform, DecoDir + "/nature/rock_single_E.fbx", new Vector3(-1f, 0f, -0.7f),
                new Vector3(0f, 200f, 0f), 1f, "offering_stone_b", false);
            // One further humble offering — a small stacked cairn a pilgrim left at the basin foot.
            Place(group.transform, DecoDir + "/props/resource_stone.fbx", new Vector3(0.1f, 0f, -1.25f),
                new Vector3(0f, 25f, 0f), 0.8f, "offering_cairn", false);
            // The White Rose stand-in regrows at the basin (GLOSSARY §The White Rose; world.md §The
            // Cliff). It must read WHITE, not the flower atlas's blue — so it is tinted with a flat
            // cream material. Sits just in front of the well basin: small, but noticeable.
            // Quaternius prefabs bake a 100× root scale, so these need large absolute scales
            // (unlike the natural-scale-1 KayKit props).
            GameObject rose = Place(group.transform, QuatDir + "/Flower_1_Clump.fbx",
                new Vector3(0.12f, 0f, 0.85f), new Vector3(270f, 0f, 0f), 50f, "WhiteRose_StandIn", false);
            if (rose != null)
            {
                Material white = BuildWhiteRoseMaterial();
                foreach (MeshRenderer mr in rose.GetComponentsInChildren<MeshRenderer>())
                {
                    Material[] arr = mr.sharedMaterials;
                    for (int i = 0; i < arr.Length; i++)
                    {
                        arr[i] = white;
                    }

                    mr.sharedMaterials = arr;
                }
            }
        }

        private static void DressDeadTree(Transform parent)
        {
            float gy = FloorLevelAt(DeadTreeXZ.x, DeadTreeXZ.y) * StepWorld;
            // The one dead tree on the whole plateau (world.md §The Cliff — the thesis in miniature: the
            // only thing here that visibly *dies*, so it must COMMAND its knoll, not read as a twig).
            // DeadTree_3 has the widest gnarled crown of bare branches of the Quaternius set (canopy ≈
            // height, versus the pole-like DeadTree_1/2). Quaternius model stands up under X=270 and
            // bakes a 100× root scale; the Place() scale overrides it, and under the ×2 CliffTerrain
            // parent scale 90 lands ≈ 8.9 m tall / ≈ 8 m canopy — dwarfing the 2.4–3.4 m living groves.
            // NOTHING else grows on its knoll (see DressGroves' knoll exclusion).
            GameObject t = Place(parent, DeadTreeAsset,
                new Vector3(DeadTreeXZ.x, gy, DeadTreeXZ.y) / ParentScale, new Vector3(270f, 35f, 0f),
                90f, "DeadTree_Centerpiece", false);
            if (t == null)
            {
                Debug.LogWarning("[Tarrock] Dead-tree asset missing; the Cliff's signature visual is absent.");
            }

            // "Nothing grows in its shade" (MQ00 §The Dead Tree): the knoll top around the tree reads
            // sparser and browner than the green meadow — a few flat bare-earth patches and one or two
            // fallen dead branches. This is the ONLY dead ground on the plateau (the region's thesis;
            // the meadow everywhere else stays aggressively alive). Green tufts/groves are already
            // excluded from the knoll in DressGroves.
            var baseGrp = new GameObject("DeadTree_Base");
            baseGrp.transform.SetParent(parent, false);
            baseGrp.transform.localPosition = new Vector3(DeadTreeXZ.x, gy, DeadTreeXZ.y) / ParentScale;
            Material dirt = DirtMaterial();
            var drnd = new System.Random(6100);
            for (int i = 0; i < 7; i++)
            {
                float a = drnd.Next(0, 360) * Mathf.Deg2Rad;
                float rad = 0.3f + ((float)drnd.NextDouble() * 1.5f);
                PlaceDecal(baseGrp.transform, DecoDir + "/nature/rock_single_A.fbx",
                    new Vector3(Mathf.Cos(a) * rad, -0.02f, Mathf.Sin(a) * rad),
                    new Vector3(0f, drnd.Next(0, 360), 0f), new Vector3(1.8f, 0.5f, 1.8f), dirt,
                    $"bare_earth_{i}");
            }

            for (int i = 0; i < 2; i++)
            {
                float a = drnd.Next(0, 360) * Mathf.Deg2Rad;
                float rad = 1.0f + ((float)drnd.NextDouble() * 0.8f);
                Place(baseGrp.transform, DecoDir + "/props/resource_lumber.fbx",
                    new Vector3(Mathf.Cos(a) * rad, 0f, Mathf.Sin(a) * rad),
                    new Vector3(0f, drnd.Next(0, 360), 92f), 1.0f, $"fallen_branch_{i}", true);
            }
        }

        // Bush tier model pools (director round 5): visually distinct SHORT vs TALL so the measured
        // tier matches what the eye reads. SHORT = the pack's small dome bushes; TALL = the big round
        // ones. Each is placed at a target WORLD height (via PlaceBush) that lands cleanly on its side
        // of TallBushHeight, so the height classifier in BuildPropColliders is never a coin-flip.
        private static readonly string[] ShortBushes =
        {
            ForestDir + "/Bush_1_A_Color1.fbx", ForestDir + "/Bush_4_A_Color1.fbx",
        };

        private static readonly string[] TallBushes =
        {
            ForestDir + "/Bush_2_B_Color1.fbx", ForestDir + "/Bush_2_C_Color1.fbx",
        };

        private const float ShortBushWorldHeight = 0.34f; // clearly under TallBushHeight (~0.43 m)
        private const float TallBushWorldHeight = 1.05f;   // clearly over — a solid round bush

        // Living-tree clusters (KayKit ForestNature). Wind-scoured meadow → clustered and sparse,
        // never on the dead-tree knoll (which stays bare) or the rim.
        private static readonly Vector2[] GroveXZ =
        {
            new Vector2(28.6f, 8.8f), new Vector2(16.5f, -7.15f), new Vector2(-17.6f, 6.6f),
            new Vector2(-33f, -7.15f), new Vector2(6.6f, 13.2f), new Vector2(36.3f, -5.5f),
            new Vector2(25.3f, -8.8f), new Vector2(13.2f, -8.25f),
        };

        private static void DressGroves(Transform parent)
        {
            var group = new GameObject("Groves");
            group.transform.SetParent(parent, false);
            // Single-trunk models only: a grove is a jittered clump of individual trees, each of which
            // gets its own MEASURED trunk capsule (director round 5). The baked multi-trunk clump
            // models are excluded — one capsule cannot honestly fit a clump (it would be a 2 m solid
            // wall that fails trunk verification), and a clump of singles reads the same or better.
            string[] trees =
            {
                DecoDir + "/nature/tree_single_A.fbx", DecoDir + "/nature/tree_single_B.fbx",
            };
            var rnd = new System.Random(90210);
            int idx = 0;
            foreach (Vector2 g in GroveXZ)
            {
                // Never dress the bare dead-tree knoll.
                if (Vector2.Distance(g, DeadTreeXZ) < 8f)
                {
                    continue;
                }

                float gy = FloorLevelAt(g.x, g.y) * StepWorld;
                int per = 3 + rnd.Next(0, 3);
                for (int i = 0; i < per; i++)
                {
                    float jx = ((float)rnd.NextDouble() * 2f - 1f) * 3.2f;
                    float jz = ((float)rnd.NextDouble() * 2f - 1f) * 3.2f;
                    Place(group.transform, trees[rnd.Next(trees.Length)],
                        new Vector3(g.x + jx, gy, g.y + jz) / ParentScale,
                        new Vector3(0f, rnd.Next(0, 360), 0f),
                        1.0f + ((float)rnd.NextDouble() * 0.5f), $"tree_{idx++}", false);
                }

                // One TALL (solid) and one SHORT (foliage-drag) bush per grove, so both tiers read
                // side by side across the meadow (director round 5).
                float tjx = ((float)rnd.NextDouble() * 2f - 1f) * 3.5f;
                float tjz = ((float)rnd.NextDouble() * 2f - 1f) * 3.5f;
                PlaceBush(group.transform, TallBushes[rnd.Next(TallBushes.Length)],
                    new Vector3(g.x + tjx, gy, g.y + tjz) / ParentScale, rnd.Next(0, 360),
                    TallBushWorldHeight, $"bush_tall_{idx++}");

                float sjx = ((float)rnd.NextDouble() * 2f - 1f) * 3.5f;
                float sjz = ((float)rnd.NextDouble() * 2f - 1f) * 3.5f;
                PlaceBush(group.transform, ShortBushes[rnd.Next(ShortBushes.Length)],
                    new Vector3(g.x + sjx, gy, g.y + sjz) / ParentScale, rnd.Next(0, 360),
                    ShortBushWorldHeight, $"bush_short_{idx++}");
            }

            // A thin scatter of grass tufts across the walkable valley (wind-scoured, so sparse).
            int placed = 0, attempts = 0;
            while (placed < 26 && attempts < 400)
            {
                attempts++;
                float x = -64f + ((float)rnd.NextDouble() * 108f);
                float z = -14f + ((float)rnd.NextDouble() * 30f);
                if (!Walkable(x, z) || Vector2.Distance(new Vector2(x, z), DeadTreeXZ) < 10f)
                {
                    continue;
                }

                // Leave the last stretch to the leap edge bare — a worn approach where the grass
                // thins out toward the step-off (leap-edge framing; the void does the talking).
                if (x < -52f)
                {
                    continue;
                }

                float gy = FloorLevelAt(x, z) * StepWorld;
                // Quaternius (100× baked root scale) → large absolute scale for a knee-high tuft.
                Place(group.transform, QuatDir + "/Grass_Small.fbx",
                    new Vector3(x, gy, z) / ParentScale, new Vector3(270f, rnd.Next(0, 360), 0f),
                    45f + ((float)rnd.NextDouble() * 25f), $"tuft_{idx++}", false);
                placed++;
            }
        }

        // Three off-trail pockets — reward for stepping aside (art-audio rule 6). Set dressing only.
        private static void DressPockets(Transform parent)
        {
            var group = new GameObject("Pockets");
            group.transform.SetParent(parent, false);

            // A — grove hollow: a denser stand than the wind-scoured valley, sunk off the bench.
            {
                Vector2 c = PocketC[0];
                float gy = FloorLevelAt(c.x, c.y) * StepWorld;
                var pk = new GameObject(PocketName[0]);
                pk.transform.SetParent(group.transform, false);
                pk.transform.localPosition = new Vector3(c.x, gy, c.y) / ParentScale;
                var rnd = new System.Random(7001);
                string[] trees =
                {
                    DecoDir + "/nature/tree_single_A.fbx", DecoDir + "/nature/tree_single_B.fbx",
                };
                for (int i = 0; i < 7; i++)
                {
                    float a = (float)rnd.NextDouble() * Mathf.PI * 2f;
                    float rad = (float)rnd.NextDouble() * 3.4f;
                    var lp = new Vector3(Mathf.Cos(a) * rad, 0f, Mathf.Sin(a) * rad);
                    Place(pk.transform, trees[rnd.Next(trees.Length)], lp,
                        new Vector3(0f, rnd.Next(0, 360), 0f), 1.1f + (float)rnd.NextDouble() * 0.5f,
                        $"tree_{i}", false);
                }

                // A denser hollow: two short foliage bushes and one tall solid one (director round 5).
                for (int i = 0; i < 3; i++)
                {
                    float a = (float)rnd.NextDouble() * Mathf.PI * 2f;
                    var lp = new Vector3(Mathf.Cos(a) * 2.6f, 0f, Mathf.Sin(a) * 2.6f);
                    bool tall = i == 0;
                    PlaceBush(pk.transform,
                        (tall ? TallBushes : ShortBushes)[rnd.Next(tall ? TallBushes.Length : ShortBushes.Length)],
                        lp, rnd.Next(0, 360), tall ? TallBushWorldHeight : ShortBushWorldHeight,
                        tall ? $"bush_tall_{i}" : $"bush_short_{i}");
                }

                // A lone cold campsite remnant tucked in the hollow — a faint fire-ring and a rotted
                // sack, one more Fool long gone (the region's theme; invents no lore). A small reward
                // for the player who steps off the trail into the grove.
                var remnant = new Vector3(2.3f, 0f, -1.6f);
                var rr = new System.Random(7050);
                for (int s = 0; s < 5; s++)
                {
                    float a = (s / 5f) * Mathf.PI * 2f;
                    Place(pk.transform, DecoDir + "/nature/rock_single_A.fbx",
                        remnant + new Vector3(Mathf.Cos(a) * 0.5f, 0f, Mathf.Sin(a) * 0.5f),
                        new Vector3(0f, rr.Next(0, 360), 0f), 0.55f, $"remnant_stone_{s}", true);
                }

                Place(pk.transform, DecoDir + "/props/sack.fbx", remnant + new Vector3(0.6f, -0.05f, 0.4f),
                    new Vector3(18f, 45f, 0f), 1.3f, "remnant_sack", true);
            }

            // B — stone circle: a ring of small menhirs, a quiet ruin off the mid trail.
            {
                Vector2 c = PocketC[1];
                float gy = FloorLevelAt(c.x, c.y) * StepWorld;
                var pk = new GameObject(PocketName[1]);
                pk.transform.SetParent(group.transform, false);
                pk.transform.localPosition = new Vector3(c.x, gy, c.y) / ParentScale;
                int stones = 7;
                for (int s = 0; s < stones; s++)
                {
                    float a = (s / (float)stones) * Mathf.PI * 2f;
                    var lp = new Vector3(Mathf.Cos(a) * 2.6f, 0f, Mathf.Sin(a) * 2.6f);
                    GameObject g = Place(pk.transform, DecoDir + "/nature/rock_single_D.fbx", lp,
                        new Vector3(0f, s * 51f, s % 3 == 0 ? 8f : -6f), 1f, $"menhir_{s}", false);
                    if (g != null)
                    {
                        g.transform.localScale = new Vector3(1.1f, 3.6f + (s % 3), 1.1f);
                    }
                }

                // A small offering cairn at the centre of the circle — the deliberate touch that reads
                // the ring as tended, not just fallen stones.
                BuildCairn(pk.transform, Vector3.zero, 7120, 4, 1.0f, "offering_cairn");
            }

            // C — rim overlook: a couple of flat seats and a marker stone on the broken edge, looking
            // out over the cloud (world.md §The Cliff — the edge that "simply stops").
            {
                Vector2 c = PocketC[2];
                float gy = FloorLevelAt(c.x, c.y) * StepWorld;
                var pk = new GameObject(PocketName[2]);
                pk.transform.SetParent(group.transform, false);
                pk.transform.localPosition = new Vector3(c.x, gy, c.y) / ParentScale;
                GameObject seat = Place(pk.transform, DecoDir + "/nature/rock_single_C.fbx",
                    new Vector3(0.6f, 0f, 0.4f), new Vector3(0f, 30f, 0f), 1f, "seat_a", false);
                if (seat != null)
                {
                    seat.transform.localScale = new Vector3(2.4f, 1.1f, 1.8f);
                }

                GameObject marker = Place(pk.transform, DecoDir + "/nature/rock_single_D.fbx",
                    new Vector3(-1.4f, 0f, -0.6f), new Vector3(0f, 12f, 4f), 1f, "marker_stone", false);
                if (marker != null)
                {
                    marker.transform.localScale = new Vector3(1.2f, 4.2f, 1.2f);
                }

                Place(pk.transform, DecoDir + "/nature/rock_single_A.fbx", new Vector3(1.6f, 0f, -1f),
                    new Vector3(0f, 80f, 0f), 1.1f, "seat_b", false);

                // A tiny cairn by the seats — a small marker someone left at the overlook, giving the
                // pocket a reason-to-linger read without inventing any lore.
                BuildCairn(pk.transform, new Vector3(-0.3f, 0f, 1.3f), 7230, 3, 0.65f, "tiny_cairn");
            }
        }

        private static void DressClouds(Transform parent)
        {
            var group = new GameObject("Clouds");
            group.transform.SetParent(parent, false);
            var rnd = new System.Random(31337);
            // Floating below the broken west rim and drifting south.
            for (int i = 0; i < 14; i++)
            {
                bool big = rnd.Next(0, 2) == 0;
                string path = DecoDir + (big ? "/nature/cloud_big.fbx" : "/nature/cloud_small.fbx");
                float x = -78f + ((float)rnd.NextDouble() * 14f);   // beyond/below the west rim
                float z = -30f + ((float)rnd.NextDouble() * 62f);
                float y = -6f - ((float)rnd.NextDouble() * 12f);
                Place(group.transform, path, new Vector3(x, y, z) / ParentScale,
                    new Vector3(0f, rnd.Next(0, 360), 0f), 1.4f + ((float)rnd.NextDouble() * 0.6f),
                    $"cloud_w{i}", false);
            }

            // A couple of clouds glimpsed through the north/south saddles (sky beyond the breach).
            Vector2[] beyond = { new Vector2(26f, 31f), new Vector2(0f, -26f) };
            for (int i = 0; i < beyond.Length; i++)
            {
                Place(group.transform, DecoDir + "/nature/cloud_big.fbx",
                    new Vector3(beyond[i].x, -5f, beyond[i].y) / ParentScale,
                    new Vector3(0f, rnd.Next(0, 360), 0f), 1.5f, $"cloud_s{i}", false);
            }
        }

        // Leap-edge framing (west rim at MQ00_CLIFF_EDGE): the step-off must read INTENTIONAL — a worn
        // approach. Two modest cairns flank the last few metres before the grass ends, framing the
        // step-off point; the bare last stretch (grass thinned in DressGroves) and the void + clouds
        // beyond do the rest. NO signage/text (canon: nothing built, nothing labelled — MQ00 §The
        // Cliff's Edge).
        private static void DressLeapEdge(Transform parent)
        {
            var group = new GameObject("LeapEdge");
            group.transform.SetParent(parent, false);
            const float x = -64.5f; // right at the grass edge (~x -66) — the last thing before the drop
            for (int i = 0; i < 2; i++)
            {
                float z = i == 0 ? 1.8f : -1.8f; // a narrow ~3.6 m gate the worn approach steps through
                float gy = FloorLevelAt(x, z) * StepWorld;
                BuildCairn(group.transform, new Vector3(x, gy, z) / ParentScale, 8300 + i, 4, 1.1f,
                    $"leap_cairn_{i}");
            }
        }

        // A small deliberate cairn: a short stack of decreasing stones. SOLID (per the collider policy)
        // — each stone gets its own convex mesh collider. Kept clear of protected walk lanes by its
        // callers, so the walkability sweep never topples it.
        private static void BuildCairn(Transform parent, Vector3 localPos, int seed, int stones,
            float baseScale, string name)
        {
            var g = new GameObject(name);
            g.transform.SetParent(parent, false);
            g.transform.localPosition = localPos;
            var rnd = new System.Random(seed);
            // resource_stone is a chunky stone pile (native ~0.28 m tall) — stacking a few, each a
            // little smaller and nested down into the one below, reads as a deliberate cairn. (Work in
            // LOCAL units: the ×2 parent scale doubles everything into world.)
            const float stoneNativeH = 0.28f;
            float y = 0f;
            for (int i = 0; i < stones; i++)
            {
                float s = baseScale * (1f - (i * 0.16f));
                float localH = stoneNativeH * s;
                var jitter = new Vector3(((float)rnd.NextDouble() - 0.5f) * 0.09f, y + (localH * 0.5f),
                    ((float)rnd.NextDouble() - 0.5f) * 0.09f);
                Place(g.transform, DecoDir + "/props/resource_stone.fbx", jitter,
                    new Vector3(0f, rnd.Next(0, 360), 0f), s, $"stone_{i}", false);
                y += localH * 0.62f; // nest each stone down into the last
            }
        }

        // Places a flat, walk-through decal-like prop (a dirt mound / clod / bare-earth patch), tinted
        // with a colour material and NON-colliding (removed from the sweep's prop set) — so it can sit
        // on a marker or the trail centreline without blocking the player or fighting the sweep.
        private static GameObject PlaceDecal(Transform parent, string assetPath, Vector3 localPos,
            Vector3 euler, Vector3 localScale, Material mat, string name)
        {
            GameObject g = Place(parent, assetPath, localPos, euler, 1f, name, false);
            if (g == null)
            {
                return null;
            }

            g.transform.localScale = localScale;
            s_props.RemoveAll(p => p.Root == g); // walk-through: no collider, never swept
            if (mat != null)
            {
                foreach (MeshRenderer mr in g.GetComponentsInChildren<MeshRenderer>())
                {
                    Material[] arr = mr.sharedMaterials;
                    for (int i = 0; i < arr.Length; i++)
                    {
                        arr[i] = mat;
                    }

                    mr.sharedMaterials = arr;
                }
            }

            return g;
        }

        // Cached earthy-brown material for disturbed earth / bare ground (built once per run so the
        // several decals that share it keep a live reference through the scene save).
        private static Material DirtMaterial()
        {
            if (s_dirtMat == null)
            {
                s_dirtMat = BuildLitColorMaterial("DisturbedEarth", new Color(0.34f, 0.25f, 0.17f), 0.05f);
            }

            return s_dirtMat;
        }

        // Returns Cull-Off (double-sided) persisted variants of the given terrain materials (FIX 2b),
        // one per distinct source material, cached for the run. URP/Lit renders its pass with
        // Cull [_Cull]; _Cull = 0 is Render Face = Both. doubleSidedGI keeps lightmap/GI consistent.
        private static Material[] DoubleSidedTerrain(Material[] mats)
        {
            if (mats == null)
            {
                return null;
            }

            var outp = new Material[mats.Length];
            for (int i = 0; i < mats.Length; i++)
            {
                Material src = mats[i];
                if (src == null)
                {
                    outp[i] = null;
                    continue;
                }

                if (!s_doubleSidedTerrain.TryGetValue(src.name, out Material ds))
                {
                    Directory.CreateDirectory(MatDir);
                    ds = new Material(src) { name = src.name + "_Terrain2Sided" };
                    if (ds.HasProperty("_Cull"))
                    {
                        ds.SetFloat("_Cull", (float)UnityEngine.Rendering.CullMode.Off); // Render Face = Both
                    }

                    ds.doubleSidedGI = true;
                    string path = MatDir + "/" + ds.name + ".mat";
                    AssetDatabase.DeleteAsset(path);
                    AssetDatabase.CreateAsset(ds, path);
                    s_doubleSidedTerrain[src.name] = ds;
                }

                outp[i] = ds;
            }

            return outp;
        }

        private static Material BuildWhiteRoseMaterial()
        {
            // Warm cream white — reads as a white rose in the dawn-gold light, never the atlas's blue.
            return BuildLitColorMaterial("WhiteRoseStandIn", new Color(0.97f, 0.95f, 0.90f), 0.22f);
        }

        // A persisted flat-colour URP Lit material (no albedo map — so a textured prop's baked colour
        // is fully overridden). Delete-then-create so a rebuild refreshes it deterministically.
        private static Material BuildLitColorMaterial(string assetName, Color color, float smoothness)
        {
            Directory.CreateDirectory(MatDir);
            Shader lit = Shader.Find("Universal Render Pipeline/Lit");
            var m = new Material(lit != null ? lit : Shader.Find("Standard")) { name = assetName };
            if (m.HasProperty("_BaseColor"))
            {
                m.SetColor("_BaseColor", color);
            }

            if (m.HasProperty("_Color"))
            {
                m.SetColor("_Color", color);
            }

            if (m.HasProperty("_BaseMap"))
            {
                m.SetTexture("_BaseMap", null);
            }

            if (m.HasProperty("_Smoothness"))
            {
                m.SetFloat("_Smoothness", smoothness);
            }

            if (m.HasProperty("_Glossiness"))
            {
                m.SetFloat("_Glossiness", smoothness);
            }

            string path = MatDir + "/" + assetName + ".mat";
            AssetDatabase.DeleteAsset(path);
            AssetDatabase.CreateAsset(m, path);
            return m;
        }

        // Bound-state ambience (art-audio.md §world-state rules): a 2D air bed, always on, gently
        // looping. The clip is a short seamless loop whose repetition is *allowed* to be audible — the
        // bound world's audible stasis, not wind. Unbinding a region would swap this for a layered bed.
        private static void BuildAmbience()
        {
            var clip = AssetDatabase.LoadAssetAtPath<AudioClip>(CliffAmbienceClipPath);
            if (clip == null)
            {
                Debug.LogWarning($"[Tarrock] Cliff bound-ambience clip missing: {CliffAmbienceClipPath}");
                return;
            }

            var go = new GameObject("CliffAmbience");
            var src = go.AddComponent<AudioSource>();
            src.clip = clip;
            src.loop = true;
            src.playOnAwake = true;
            src.spatialBlend = 0f; // 2D bed
            src.volume = AmbienceVolume;
            src.priority = 128;
        }

        // Instantiate a vendored prefab under a (×2-scaled) parent at a local transform. Returns the
        // instance (null if the asset is missing). Optionally strips colliders — dressing is
        // walk-through; containment is the terrain's job.
        private static GameObject Place(Transform parent, string assetPath, Vector3 localPos,
            Vector3 euler, float scale, string name, bool _unused)
        {
            var src = AssetDatabase.LoadAssetAtPath<GameObject>(assetPath);
            if (src == null)
            {
                Debug.LogWarning($"[Tarrock] Dressing asset missing: {assetPath}");
                return null;
            }

            var g = (GameObject)PrefabUtility.InstantiatePrefab(src);
            g.transform.SetParent(parent, false);
            g.transform.localPosition = localPos;
            g.transform.localRotation = Quaternion.Euler(euler);
            g.transform.localScale = Vector3.one * scale;
            g.name = name;
            // Dressing props never move at runtime (the bound world holds its breath) — static-flag
            // them for batching. The editor-time walkability sweep may still nudge a few; that is a
            // pre-save edit, not runtime motion, so the static flag stays valid.
            g.isStatic = true;

            int category = ColliderCategory(assetPath);
            if (category != 0)
            {
                s_props.Add(new PropRec { Root = g, Category = category });
            }

            return g;
        }

        // Places a bush and rescales it to a TARGET WORLD HEIGHT, so its measured tier (SHORT/TALL,
        // resolved in BuildPropColliders) is deterministic regardless of the model's native size.
        private static GameObject PlaceBush(
            Transform parent, string assetPath, Vector3 localPos, float yaw, float targetWorldHeight, string name)
        {
            GameObject g = Place(parent, assetPath, localPos, new Vector3(0f, yaw, 0f), 1f, name, false);
            if (g == null)
            {
                return null;
            }

            float h = MeasuredWorldHeight(g);
            if (h > 0.0001f)
            {
                g.transform.localScale = Vector3.one * (targetWorldHeight / h);
            }

            return g;
        }

        // The single source of truth for what a dressing asset collides as (0 none / 1 solid / 2 tree).
        // Absolute categories, decided by asset kind — not by a per-prop fitted guess. Foliage and sky
        // never collide; anything with a trunk collides on the trunk only; everything else physical is
        // its own convex mesh.
        private static int ColliderCategory(string path)
        {
            // BUSHES: resolved by measured height into TALL (solid) / SHORT (foliage-drag trigger).
            if (path.Contains("Bush"))
            {
                return 3;
            }

            // SOFT foliage + sky: grass, flowers, tufts, clouds — walk straight through.
            if (path.Contains("Grass") || path.Contains("Flower") || path.Contains("cloud"))
            {
                return 0;
            }

            // TREES (living KayKit + dead Quaternius): trunk capsule only; canopy/leaves pass.
            if (path.Contains("tree") || path.Contains("Tree"))
            {
                return 2;
            }

            // SOLID: rocks, stones, menhirs, boulders, barrels, crates, sacks, buckets, lumber,
            // resource stone, the well, tents, flags, firestones, cairns — the visible mesh is the box.
            return 1;
        }

        // Resolves every recorded prop into its category collider. Runs after all dressing so props the
        // caller rescales post-Place (menhirs, boulders, seats) have final transforms. SOLID props get a
        // convex MeshCollider on their OWN mesh child (exact geometry under any rotation / non-uniform
        // scale); TREE props get an upright trunk capsule in the world-scale-1 PropColliders root.
        // Returns the total collider count and reports per-category counts + convex-limit fallbacks.
        private static int BuildPropColliders(out int solidCount, out int treeCount)
        {
            solidCount = 0;
            treeCount = 0;

            // Foliage (tree trunks + bush colliders) goes on the CameraTransparent layer so the wall
            // camera (SPEC A) never pulls in on grass/trees — only terrain/rampart/rock still occlude.
            // The player still collides with them (layer collision matrix is unchanged).
            int foliageLayer = CameraRigConfig.EnsureCameraTransparentLayer();

            foreach (PropRec rec in s_props)
            {
                if (rec.Root == null)
                {
                    continue;
                }

                if (rec.Category == 1)
                {
                    solidCount += BuildSolidMeshColliders(rec);
                }
                else if (rec.Category == 2)
                {
                    GameObject cap = BuildTrunkCapsule(rec.Root);
                    if (cap != null)
                    {
                        cap.transform.SetParent(s_propColliders, false);
                        cap.layer = foliageLayer; // tree trunk: foliage, camera-transparent
                        rec.ColliderObjs.Add(cap);
                        foreach (Collider c in cap.GetComponents<Collider>())
                        {
                            s_colliderToRec[c] = rec;
                        }

                        treeCount++;
                    }
                }
                else if (rec.Category == 3)
                {
                    // Bush tier by MEASURED world height (director round 5).
                    float height = MeasuredWorldHeight(rec.Root);
                    if (height > TallBushHeight)
                    {
                        // TALL bush → SOLID, same policy as a rock; swept out of lanes. Foliage layer
                        // so the wall camera glides past it (still a solid obstacle to the player).
                        solidCount += BuildSolidMeshColliders(rec);
                        SetCollidersLayer(rec.Root, foliageLayer);
                        s_bushTall++;
                    }
                    else
                    {
                        // SHORT bush → soft foliage-drag trigger; NOT swept (walking through it is the point).
                        BuildFoliageTrigger(rec.Root);
                        s_bushShort++;
                    }
                }
            }

            // solidCount already includes every TALL-bush solid; the total is blocking colliders only.
            return solidCount + treeCount;
        }

        // A convex MeshCollider on each mesh child (the visible mesh IS the hitbox). Shared by SOLID
        // props (rocks, stones…) and the TALL bush tier. Returns the collider count and registers each
        // in the sweep map. Meshes over the 255-tri convex cook limit get a reported hull fallback.
        private static int BuildSolidMeshColliders(PropRec rec)
        {
            int count = 0;
            foreach (MeshFilter mf in rec.Root.GetComponentsInChildren<MeshFilter>())
            {
                Mesh mesh = mf.sharedMesh;
                if (mesh == null)
                {
                    continue;
                }

                var mc = mf.gameObject.AddComponent<MeshCollider>();
                mc.sharedMesh = mesh;
                mc.convex = true;
                int tris = mesh.triangles.Length / 3;
                if (tris > 255)
                {
                    s_colliderNotes.Add($"{rec.Root.name} ({mesh.name}, {tris} tris) → convex hull simplified to ≤255 faces");
                }

                mf.gameObject.isStatic = true;
                s_colliderToRec[mc] = rec;
                count++;
            }

            return count;
        }

        // Puts every collider-carrying object under a prop on the given layer (used to mark foliage
        // solids CameraTransparent — see BuildPropColliders). Only touches objects that actually
        // carry a collider so the visual meshes' render layer is left alone.
        private static void SetCollidersLayer(GameObject prop, int layer)
        {
            foreach (Collider c in prop.GetComponentsInChildren<Collider>(true))
            {
                c.gameObject.layer = layer;
            }
        }

        // World-space rendered height of a prop (max encapsulated renderer bounds).
        private static float MeasuredWorldHeight(GameObject prop)
        {
            Renderer[] renderers = prop.GetComponentsInChildren<Renderer>();
            if (renderers.Length == 0)
            {
                return 0f;
            }

            Bounds b = renderers[0].bounds;
            for (int i = 1; i < renderers.Length; i++)
            {
                b.Encapsulate(renderers[i].bounds);
            }

            return b.size.y;
        }

        // A SHORT bush's soft drag volume (combat.md §Focus foliage note): a trigger sphere sized to
        // the bush, carrying FoliageDrag, in the world-scale-1 FoliageTriggers root (so the bush's
        // non-uniform prop scale never distorts it). Deliberately NOT registered in the sweep map —
        // a short bush is meant to sit on the path and slow the Fool, not be evicted from it.
        private static void BuildFoliageTrigger(GameObject bush)
        {
            Renderer[] renderers = bush.GetComponentsInChildren<Renderer>();
            if (renderers.Length == 0)
            {
                return;
            }

            Bounds b = renderers[0].bounds;
            for (int i = 1; i < renderers.Length; i++)
            {
                b.Encapsulate(renderers[i].bounds);
            }

            var go = new GameObject($"foliage_{bush.name}");
            go.transform.SetParent(s_foliageTriggers, false);
            go.transform.position = b.center;
            var sphere = go.AddComponent<SphereCollider>();
            sphere.isTrigger = true;
            // Cover the bush's footprint; the player's capsule dips in as they walk through.
            sphere.radius = Mathf.Max(0.15f, 0.5f * Mathf.Max(b.size.x, b.size.z));
            go.AddComponent<FoliageDrag>();
        }

        // Fits an upright trunk-only capsule to a tree by PHYSICALLY MEASURING the trunk (director
        // round 5: "measure, don't infer"). A temporary non-convex MeshCollider is put on the tree's
        // own mesh; horizontal ray-rings (16 inward rays) are cast at three low heights inside the
        // trunk zone (below any canopy); the hit points give the trunk's true centroid (some trees
        // lean, so this is NOT the prefab pivot) and cross-section radius. The capsule is then VERIFIED
        // with four probe rays against the visual trunk before the temp collider is removed. Works for
        // both Y-up KayKit trees and the X-rotated Quaternius dead tree because everything is measured
        // in WORLD space.
        private static GameObject BuildTrunkCapsule(GameObject prop)
        {
            var worldVerts = new List<Vector3>();
            float minY = float.MaxValue, maxY = float.MinValue;
            foreach (MeshFilter mf in prop.GetComponentsInChildren<MeshFilter>())
            {
                Mesh mesh = mf.sharedMesh;
                if (mesh == null)
                {
                    continue;
                }

                Matrix4x4 l2w = mf.transform.localToWorldMatrix;
                foreach (Vector3 v in mesh.vertices)
                {
                    Vector3 w = l2w.MultiplyPoint3x4(v);
                    worldVerts.Add(w);
                    minY = Mathf.Min(minY, w.y);
                    maxY = Mathf.Max(maxY, w.y);
                }
            }

            if (worldVerts.Count == 0 || maxY <= minY)
            {
                return null;
            }

            // Vertex-based first guess (centroid + extent) of the low trunk band, purely to size and
            // seat the ray-rings so they start OUTSIDE the trunk and aim at its axis.
            float bandTop = minY + (TrunkSampleFractions[TrunkSampleFractions.Length - 1] * PlayerHeight) + 0.05f;
            double gx = 0, gz = 0;
            int gn = 0;
            foreach (Vector3 w in worldVerts)
            {
                if (w.y <= bandTop)
                {
                    gx += w.x;
                    gz += w.z;
                    gn++;
                }
            }

            var estCentroid = gn > 0 ? new Vector2((float)(gx / gn), (float)(gz / gn))
                                     : new Vector2(prop.transform.position.x, prop.transform.position.z);
            float estExtent = 0.05f;
            foreach (Vector3 w in worldVerts)
            {
                if (w.y <= bandTop)
                {
                    estExtent = Mathf.Max(estExtent, Vector2.Distance(new Vector2(w.x, w.z), estCentroid));
                }
            }

            float ringR = estExtent + 0.3f; // ray origins sit this far out, aimed inward at the axis

            // Temporary non-convex MeshCollider(s) on the tree's own geometry for the measurement +
            // verification rays; removed before returning so only the fitted capsule remains.
            var tempColliders = new HashSet<Collider>();
            foreach (MeshFilter mf in prop.GetComponentsInChildren<MeshFilter>())
            {
                if (mf.sharedMesh == null || mf.GetComponent<Collider>() != null)
                {
                    continue;
                }

                var temp = mf.gameObject.AddComponent<MeshCollider>();
                temp.sharedMesh = mf.sharedMesh; // non-convex
                tempColliders.Add(temp);
            }

            Physics.SyncTransforms();

            // Cast the ray-rings and gather trunk-surface hit points.
            var hitPts = new List<Vector2>();
            foreach (float frac in TrunkSampleFractions)
            {
                float y = minY + (frac * PlayerHeight);
                for (int k = 0; k < TrunkRayCount; k++)
                {
                    float ang = (k / (float)TrunkRayCount) * Mathf.PI * 2f;
                    var outward = new Vector2(Mathf.Cos(ang), Mathf.Sin(ang));
                    var origin = new Vector3(estCentroid.x + (outward.x * ringR), y, estCentroid.y + (outward.y * ringR));
                    var dir = new Vector3(-outward.x, 0f, -outward.y);
                    if (NearestHitOnSet(origin, dir, ringR * 2f, tempColliders, out RaycastHit hit))
                    {
                        hitPts.Add(new Vector2(hit.point.x, hit.point.z));
                    }
                }
            }

            Vector2 centroid;
            float radius;
            if (hitPts.Count >= 3)
            {
                double cx = 0, cz = 0;
                foreach (Vector2 h in hitPts)
                {
                    cx += h.x;
                    cz += h.y;
                }

                centroid = new Vector2((float)(cx / hitPts.Count), (float)(cz / hitPts.Count));
                float maxR = 0f;
                foreach (Vector2 h in hitPts)
                {
                    maxR = Mathf.Max(maxR, Vector2.Distance(h, centroid));
                }

                radius = Mathf.Max(0.04f, maxR + TrunkSkin);
            }
            else
            {
                // Degenerate (rays found nothing): fall back to the vertex-band extent.
                centroid = estCentroid;
                radius = Mathf.Max(0.04f, estExtent + TrunkSkin);
            }

            float height = maxY - minY;
            var go = new GameObject($"trunk_{prop.name}");
            go.transform.position = new Vector3(centroid.x, (minY + maxY) * 0.5f, centroid.y);
            go.transform.rotation = Quaternion.identity;
            go.isStatic = true;
            var capsule = go.AddComponent<CapsuleCollider>();
            capsule.direction = 1; // world +Y (unrotated object)
            capsule.height = height;
            capsule.radius = Mathf.Min(radius, height * 0.5f);
            capsule.center = Vector3.zero;

            Physics.SyncTransforms();

            bool pass = VerifyTrunkCapsule(prop.name, centroid, ringR, minY, tempColliders, capsule, radius);
            if (pass)
            {
                s_treePass++;
            }
            else
            {
                s_treeFail++;
            }

            foreach (Collider temp in tempColliders)
            {
                if (temp != null)
                {
                    Object.DestroyImmediate(temp);
                }
            }

            Physics.SyncTransforms();
            return go;
        }

        // Verify (director round 5): four horizontal probe rays at trunk height, from outside inward,
        // must hit the FINAL capsule where they hit the visual trunk. A ray fails if the capsule is not
        // hit at all (mis-centred capsule) or the capsule surface sits BEHIND the visual trunk surface
        // (the trunk pokes out of its hitbox — the "walk through it" bug). Logs a table row per tree.
        private static bool VerifyTrunkCapsule(
            string name, Vector2 centroid, float ringR, float minY,
            HashSet<Collider> visualColliders, Collider capsule, float radius)
        {
            float y = minY + (0.35f * PlayerHeight);
            Vector2[] dirs = { Vector2.up, Vector2.down, Vector2.left, Vector2.right };
            bool pass = true;
            float worstGap = 0f;
            var single = new HashSet<Collider> { capsule };

            foreach (Vector2 d in dirs)
            {
                var origin = new Vector3(centroid.x + (d.x * ringR), y, centroid.y + (d.y * ringR));
                var dir = new Vector3(-d.x, 0f, -d.y);
                bool capHit = NearestHitOnSet(origin, dir, ringR * 2f, single, out RaycastHit capRay);
                bool visHit = NearestHitOnSet(origin, dir, ringR * 2f, visualColliders, out RaycastHit visRay);

                if (!capHit)
                {
                    pass = false; // capsule absent in this direction → off-centre / undersized
                    continue;
                }

                if (visHit)
                {
                    // Positive gap = capsule surface behind the trunk surface (trunk pokes out): bad.
                    float gap = capRay.distance - visRay.distance;
                    worstGap = Mathf.Max(worstGap, gap);
                    if (gap > 0.03f)
                    {
                        pass = false;
                    }
                }
            }

            s_treeMeasureLog.Add($"{name}: r={radius:F3} verify={(pass ? "PASS" : "FAIL")} (worstGap={worstGap:F3}m)");
            return pass;
        }

        // Nearest raycast hit whose collider is in the given set (ignores every other collider on the
        // ray). Used for both the trunk-surface measurement and the capsule verification so neighbouring
        // props never contaminate a reading.
        private static bool NearestHitOnSet(
            Vector3 origin, Vector3 direction, float maxDistance, HashSet<Collider> set, out RaycastHit nearest)
        {
            nearest = default;
            float best = float.MaxValue;
            bool found = false;
            foreach (RaycastHit h in Physics.RaycastAll(origin, direction, maxDistance, ~0, QueryTriggerInteraction.Ignore))
            {
                if (set.Contains(h.collider) && h.distance < best)
                {
                    best = h.distance;
                    nearest = h;
                    found = true;
                }
            }

            return found;
        }

        // ------------------------------------------------------------------------------------
        // Grounding audit (FIX 3) — the recent rock/stone dressing (cairns, offering stones, boulders)
        // read as FLOATING above the meadow. Cause: props are placed at localPosition.y = FloorLevelAt·
        // StepWorld — the LOGICAL floor level — while the rendered tile surface a prop actually rests on
        // can sit lower (a prop whose model pivot is above its own base ends up hovering; benches/knoll/
        // hollows amplify it). Rather than re-derive every constant, this snaps each dressing unit onto
        // the real terrain: a downward ray to the TILE colliders finds the surface under the unit's
        // footprint, and the unit is lowered so its bounds.min sits on the surface (a −0.005 m embed
        // kills z-fighting). Only FLOATERS are corrected (downward) — deliberately half-buried dressing
        // (collapsed tents, sunk crates, sunk offerings) is left where it was placed, never raised.
        // Runs AFTER colliders (so trunk capsules move with their tree) and BEFORE the walkability sweep
        // (which only nudges XZ), so the sweep resolves against final, grounded geometry.
        //
        // Granularity: each SOLID/TREE/TALL-bush prop is grounded as a whole; a cairn (a deliberate
        // vertical STACK of stones) is grounded by its container so the stack is not flattened — its
        // member stones are skipped as individual units. Non-colliding decals (flat earth patches) and
        // clouds (canon: floating below the rim) are never touched.
        // ------------------------------------------------------------------------------------
        private static void GroundDressing(Transform tiles)
        {
            Physics.SyncTransforms();

            var tileColliders = new HashSet<Collider>();
            foreach (MeshCollider mc in tiles.GetComponentsInChildren<MeshCollider>())
            {
                tileColliders.Add(mc);
            }

            // Assemble grounding units: non-cairn props (moved with their external colliders) plus each
            // distinct cairn container (moved whole).
            var unitRoots = new List<GameObject>();
            var unitExternals = new List<List<GameObject>>();
            var cairnContainers = new HashSet<GameObject>();

            foreach (PropRec rec in s_props)
            {
                if (rec.Root == null)
                {
                    continue;
                }

                GameObject cairn = CairnAncestor(rec.Root.transform);
                if (cairn != null)
                {
                    cairnContainers.Add(cairn);
                    continue;
                }

                unitRoots.Add(rec.Root);
                unitExternals.Add(rec.ColliderObjs);
            }

            foreach (GameObject c in cairnContainers)
            {
                unitRoots.Add(c);
                unitExternals.Add(null);
            }

            for (int i = 0; i < unitRoots.Count; i++)
            {
                GameObject root = unitRoots[i];
                if (root == null || !TryBounds(root, out Bounds b))
                {
                    continue;
                }

                s_groundChecked++;

                // Ray from just above the unit's base, straight down onto the tiles: the nearest tile hit
                // is the surface the unit rests on (starting below the unit's top avoids catching an
                // overhead/adjacent wall crown).
                var origin = new Vector3(b.center.x, b.min.y + 2f, b.center.z);
                if (!NearestTileHit(origin, tileColliders, out float surfaceY))
                {
                    continue;
                }

                float shift = (surfaceY - 0.005f) - b.min.y;
                if (shift >= -0.01f)
                {
                    continue; // grounded or intentionally embedded — leave it (never raise a buried prop)
                }

                var delta = new Vector3(0f, shift, 0f);
                root.transform.position += delta;
                if (unitExternals[i] != null)
                {
                    foreach (GameObject co in unitExternals[i])
                    {
                        if (co != null && !co.transform.IsChildOf(root.transform))
                        {
                            co.transform.position += delta;
                        }
                    }
                }

                s_groundCorrected++;
                s_groundLog.Add($"{root.name}: Δy={shift:F3} m (was floating)");
            }

            Physics.SyncTransforms();
        }

        // The cairn container an object belongs to (a deliberate vertical stack — see BuildCairn), or
        // null. Walks ancestors for a name containing "cairn"; the stack is grounded whole, not per-stone.
        private static GameObject CairnAncestor(Transform t)
        {
            for (Transform c = t; c != null; c = c.parent)
            {
                if (c.name.IndexOf("cairn", System.StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    return c.gameObject;
                }
            }

            return null;
        }

        // Combined world renderer bounds of a prop (false if it has none).
        private static bool TryBounds(GameObject go, out Bounds bounds)
        {
            Renderer[] renderers = go.GetComponentsInChildren<Renderer>();
            if (renderers.Length == 0)
            {
                bounds = default;
                return false;
            }

            bounds = renderers[0].bounds;
            for (int i = 1; i < renderers.Length; i++)
            {
                bounds.Encapsulate(renderers[i].bounds);
            }

            return true;
        }

        // Highest tile-collider surface directly below the origin (false if the ray hits no tile).
        private static bool NearestTileHit(Vector3 origin, HashSet<Collider> tileColliders, out float surfaceY)
        {
            surfaceY = 0f;
            float best = float.NegativeInfinity;
            foreach (RaycastHit h in Physics.RaycastAll(origin, Vector3.down, 60f, ~0, QueryTriggerInteraction.Ignore))
            {
                if (tileColliders.Contains(h.collider) && h.point.y > best)
                {
                    best = h.point.y;
                }
            }

            if (best > float.NegativeInfinity)
            {
                surfaceY = best;
                return true;
            }

            return false;
        }

        // ------------------------------------------------------------------------------------
        // Walkability sweep — the other half of "feels right". Sweeps a player-sized capsule along
        // every walk lane (trail corridor, ramps) and nudges any intruding prop collider outward so a
        // lane the eye reads as open is never choked. Deterministic: fixed sample order, fixed 0.2 m
        // steps, each prop moved at most once per pass. Landmarks (the Waystation shrine) are exempt.
        // ------------------------------------------------------------------------------------
        private static void WalkabilitySweep(Transform deco)
        {
            Physics.SyncTransforms();
            List<Vector3> samples = BuildSweepSamples(out List<Vector3> pushFrom);

            s_sweepBefore = CountViolations(samples);

            var everMoved = new HashSet<PropRec>();
            const float stepDist = 0.2f;
            const int maxPasses = 40;
            for (int pass = 0; pass < maxPasses; pass++)
            {
                var movedThisPass = new HashSet<PropRec>();
                for (int si = 0; si < samples.Count; si++)
                {
                    Vector3 s = samples[si];
                    Vector3 origin = pushFrom[si]; // the lane centre this sample belongs to
                    Vector3 p0 = s + (Vector3.up * PlayerRadius);
                    Vector3 p1 = s + (Vector3.up * (PlayerHeight - PlayerRadius));
                    Collider[] hits = Physics.OverlapCapsule(p0, p1, PlayerRadius);
                    foreach (Collider h in hits)
                    {
                        if (!s_colliderToRec.TryGetValue(h, out PropRec rec) || rec.Root == null
                            || movedThisPass.Contains(rec))
                        {
                            continue;
                        }

                        // Push away from the LANE CENTRE (not the individual sample) so a prop escapes
                        // the whole corridor/ramp radially in one consistent direction — no oscillating
                        // between a ramp's ring of samples.
                        Vector3 rp = rec.Root.transform.position;
                        var dir = new Vector2(rp.x - origin.x, rp.z - origin.z);
                        dir = dir.sqrMagnitude < 1e-4f ? new Vector2(1f, 0f) : dir.normalized;
                        var delta = new Vector3(dir.x, 0f, dir.y) * stepDist;

                        rec.Root.transform.position += delta;
                        foreach (GameObject co in rec.ColliderObjs)
                        {
                            if (co != null && !co.transform.IsChildOf(rec.Root.transform))
                            {
                                co.transform.position += delta;
                            }
                        }

                        Physics.SyncTransforms();
                        movedThisPass.Add(rec);
                        everMoved.Add(rec);
                    }
                }

                if (movedThisPass.Count == 0)
                {
                    break;
                }
            }

            Physics.SyncTransforms();
            s_sweepAfter = CountViolations(samples);
            s_sweepNudged = everMoved.Count;
        }

        // Player-stance sample points along every protected walk lane. Trail corridor: stepped along
        // each segment, spread across the readable-open middle (wider through the narrow gorge/pinch,
        // just the centreline in the open bulges). Ramps: full tile width. Samples inside a landmark
        // keep-out (the Waystation) are dropped so its shrine is never treated as a choke.
        private static List<Vector3> BuildSweepSamples(out List<Vector3> pushFrom)
        {
            var samples = new List<Vector3>();
            pushFrom = new List<Vector3>();

            for (int seg = 0; seg < TrailXZ.Length - 1; seg++)
            {
                Vector2 a = TrailXZ[seg];
                Vector2 b = TrailXZ[seg + 1];
                Vector2 ab = b - a;
                float len = ab.magnitude;
                if (len < 1e-4f)
                {
                    continue;
                }

                var perp = new Vector2(-ab.y, ab.x).normalized;
                int steps = Mathf.Max(1, Mathf.CeilToInt(len / 0.75f));
                for (int i = 0; i <= steps; i++)
                {
                    float t = i / (float)steps;
                    Vector2 c = Vector2.Lerp(a, b, t);
                    float halfW = Mathf.Lerp(TrailHalfW[seg], TrailHalfW[seg + 1], t);
                    // Narrow gorge/pinch: keep the whole slim lane open. Open bulge: only clear the
                    // centre path (props are free to decorate the edges).
                    float protect = halfW <= 5f ? Mathf.Min(halfW - 0.4f, 2.2f) : 0.5f;
                    float cy = FloorLevelAt(c.x, c.y) * StepWorld;
                    var centre = new Vector3(c.x, cy, c.y);
                    for (float off = -protect; off <= protect + 1e-3f; off += 0.4f)
                    {
                        Vector2 xz = c + (perp * off);
                        if (InLandmarkKeepout(xz))
                        {
                            continue;
                        }

                        samples.Add(new Vector3(xz.x, FloorLevelAt(xz.x, xz.y) * StepWorld, xz.y));
                        pushFrom.Add(centre); // push perpendicular off the trail centreline
                    }
                }
            }

            foreach (Vector3 rc in s_rampCenters)
            {
                var cxz = new Vector2(rc.x, rc.z);
                if (!InLandmarkKeepout(cxz))
                {
                    samples.Add(rc);
                    pushFrom.Add(rc);
                }

                for (int k = 0; k < 6; k++)
                {
                    float ang = k * (Mathf.PI / 3f);
                    var o = new Vector2(Mathf.Cos(ang), Mathf.Sin(ang)) * 1.6f;
                    if (!InLandmarkKeepout(cxz + o))
                    {
                        samples.Add(new Vector3(rc.x + o.x, rc.y, rc.z + o.y));
                        pushFrom.Add(rc); // push radially out of the ramp disc
                    }
                }
            }

            return samples;
        }

        private static bool InLandmarkKeepout(Vector2 xz)
        {
            return Vector2.Distance(xz, WaystationXZ) <= WaystationKeepout;
        }

        private static int CountViolations(List<Vector3> samples)
        {
            var bad = new HashSet<PropRec>();
            foreach (Vector3 s in samples)
            {
                Vector3 p0 = s + (Vector3.up * PlayerRadius);
                Vector3 p1 = s + (Vector3.up * (PlayerHeight - PlayerRadius));
                foreach (Collider h in Physics.OverlapCapsule(p0, p1, PlayerRadius))
                {
                    if (s_colliderToRec.TryGetValue(h, out PropRec rec) && rec.Root != null)
                    {
                        bad.Add(rec);
                    }
                }
            }

            return bad.Count;
        }

        // ------------------------------------------------------------------------------------
        // Markers, spawn, leap trigger, lighting
        // ------------------------------------------------------------------------------------

        private static void BuildMarkers()
        {
            var root = new GameObject(MarkersRootName);

            AddMarker(root.transform, CliffMarkerIds.CliffEdge, GroundPoint(CliffEdgeXZ));
            AddMarker(root.transform, CliffMarkerIds.KeepsakeDigSpot, GroundPoint(KeepsakeXZ) + new Vector3(0f, 0.02f, 0f));
            AddMarker(root.transform, CliffMarkerIds.DeadTree, GroundPoint(DeadTreeXZ));
            AddMarker(root.transform, CliffMarkerIds.Waystation, GroundPoint(WaystationXZ));
            AddMarker(root.transform, CliffMarkerIds.BlankAmbush, GroundPoint(AmbushXZ) + new Vector3(0f, 0.5f, 0f));

            // Player spawn at the wake campfire, facing west down the trail (carried from the flat Cliff).
            var spawn = new GameObject(PlayerSpawnName);
            spawn.transform.SetParent(root.transform, false);
            spawn.transform.position = GroundPoint(SpawnXZ) + new Vector3(0f, 0.05f, 0f);
            spawn.transform.rotation = Quaternion.LookRotation(Vector3.left, Vector3.up); // −X = west
            spawn.AddComponent<PlayerSpawnPoint>();

            // Leap-of-faith trigger, over the void past the west rim (flat-Cliff placement, compressed).
            var leap = new GameObject("Leap_Trigger");
            leap.transform.SetParent(root.transform, false);
            leap.transform.position = LeapTriggerPos;
            var box = leap.AddComponent<BoxCollider>();
            box.isTrigger = true;
            box.size = LeapTriggerSize;
            leap.AddComponent<LeapOfFaithTrigger>();
        }

        private static void AddMarker(Transform parent, string id, Vector3 pos)
        {
            var go = new GameObject($"Marker_{id}");
            go.transform.SetParent(parent, false);
            go.transform.position = pos;
            InteractionMarker marker = go.AddComponent<InteractionMarker>();
            var so = new SerializedObject(marker);
            so.FindProperty("_markerId").stringValue = id;
            so.ApplyModifiedPropertiesWithoutUndo();
        }

        private static Vector3 GroundPoint(Vector2 xz)
        {
            return new Vector3(xz.x, FloorLevelAt(xz.x, xz.y) * StepWorld, xz.y);
        }

        private static void BuildLighting()
        {
            var go = new GameObject("Directional_Light_Dawn");
            var light = go.AddComponent<Light>();
            light.type = LightType.Directional;
            light.color = new Color(1f, 0.84f, 0.60f); // pale dawn gold, a touch deeper (held-breath dawn)
            light.intensity = 1.15f;
            light.shadows = LightShadows.Soft;
            light.shadowStrength = 0.85f; // slightly stronger long shadows, still mournful not gloomy
            // Low, warm, from the east — the Fool enters dawn-side (world.md §The Spread). Lower
            // elevation (22°) rakes long dawn shadows across the meadow.
            go.transform.rotation = Quaternion.Euler(22f, 265f, 0f);

            // Ambient dialled DOWN from the flat-Cliff values (play-tested): the meadow read midday
            // with brighter fill; these keep the shadows dawn-deep without going gloomy.
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.50f, 0.55f, 0.68f);   // cool grey-blue sky bounce
            RenderSettings.ambientEquatorColor = new Color(0.56f, 0.52f, 0.43f); // warm horizon bounce
            RenderSettings.ambientGroundColor = new Color(0.24f, 0.23f, 0.20f);
        }

        // Mood pass (docs/design/art-audio.md — region palette "pale dawn gold, wind-scoured green";
        // §world-state rules — the bound world holds its breath: suspended motes are canon-permitted,
        // living drift like fireflies is NOT). Builds a dawn gradient skybox, matched warm distance
        // fog, and one sparse, near-motionless golden mote system over the trail corridor. Everything
        // is regenerated each run so it survives a rebuild.
        private static void BuildAtmosphere()
        {
            Directory.CreateDirectory(AtmoDir);

            // -- Dawn gradient skybox: warm pale-gold horizon → cool grey-blue zenith --------------
            Shader gradient = Shader.Find(GradientSkyShader);
            Material sky;
            if (gradient != null)
            {
                sky = new Material(gradient);
                sky.SetColor("_HorizonColor", new Color(0.96f, 0.87f, 0.66f)); // pale dawn gold
                sky.SetColor("_ZenithColor", new Color(0.32f, 0.40f, 0.54f));  // cool grey-blue
                // Below the horizon reads as pale cloud-haze (the plateau floats over cloud), not
                // dark earth — play-tested against the aerial vista.
                sky.SetColor("_GroundColor", new Color(0.68f, 0.63f, 0.53f));
                sky.SetFloat("_Exponent", 1.35f);
            }
            else
            {
                // Fallback: tuned procedural (still warm-horizon / cool-zenith), if the shader is absent.
                sky = new Material(Shader.Find("Skybox/Procedural"));
                sky.SetColor("_SkyTint", new Color(0.55f, 0.62f, 0.80f));
                sky.SetColor("_GroundColor", new Color(0.80f, 0.72f, 0.56f));
                sky.SetFloat("_AtmosphereThickness", 1.25f);
                sky.SetFloat("_Exposure", 1.1f);
            }

            string skyPath = AtmoDir + "/CliffDawnSky.mat";
            AssetDatabase.DeleteAsset(skyPath);
            AssetDatabase.CreateAsset(sky, skyPath);
            RenderSettings.skybox = sky;

            // -- Fog: subtle, warm; the far rim melts into the dawn sky ---------------------------
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.Linear;
            RenderSettings.fogColor = new Color(0.84f, 0.77f, 0.64f); // warm pale grey-gold
            RenderSettings.fogStartDistance = 40f;
            RenderSettings.fogEndDistance = 155f;
            DynamicGI.UpdateEnvironment();

            BuildMotes();
        }

        // ONE sparse, near-motionless golden dust-mote system over the trail corridor. Suspended, not
        // alive: tiny drift only, no wind gusts (canon: the bound world holds its breath). "You notice
        // them when you stop moving."
        private static void BuildMotes()
        {
            // Soft radial dot texture (persisted so the mote material survives a reload).
            const int res = 32;
            var dot = new Texture2D(res, res, TextureFormat.RGBA32, false) { name = "MoteDot" };
            var half = new Vector2((res - 1) * 0.5f, (res - 1) * 0.5f);
            for (int y = 0; y < res; y++)
            {
                for (int x = 0; x < res; x++)
                {
                    float d = Vector2.Distance(new Vector2(x, y), half) / (res * 0.5f);
                    float a = Mathf.Clamp01(1f - d);
                    a *= a; // soft falloff
                    dot.SetPixel(x, y, new Color(1f, 1f, 1f, a));
                }
            }

            dot.Apply();
            string dotPath = AtmoDir + "/MoteDot.asset";
            AssetDatabase.DeleteAsset(dotPath);
            AssetDatabase.CreateAsset(dot, dotPath);

            Shader particle = Shader.Find("Universal Render Pipeline/Particles/Unlit");
            var mat = new Material(particle != null ? particle : Shader.Find("Sprites/Default"))
            {
                name = "MoteMaterial",
            };
            if (particle != null)
            {
                mat.SetFloat("_Surface", 1f); // transparent
                mat.SetFloat("_Blend", 0f);
                mat.SetFloat("_SrcBlend", (float)UnityEngine.Rendering.BlendMode.SrcAlpha);
                mat.SetFloat("_DstBlend", (float)UnityEngine.Rendering.BlendMode.One); // additive glow
                mat.SetFloat("_ZWrite", 0f);
                mat.EnableKeyword("_SURFACE_TYPE_TRANSPARENT");
                mat.renderQueue = 3100;
                if (mat.HasProperty("_BaseMap"))
                {
                    mat.SetTexture("_BaseMap", dot);
                }

                if (mat.HasProperty("_BaseColor"))
                {
                    mat.SetColor("_BaseColor", Color.white);
                }
            }

            mat.mainTexture = dot;
            string matPath = AtmoDir + "/MoteMaterial.mat";
            AssetDatabase.DeleteAsset(matPath);
            AssetDatabase.CreateAsset(mat, matPath);

            var motes = new GameObject("SuspendedMotes");
            motes.transform.position = new Vector3(-10f, 3.4f, 0f); // over the trail corridor volume
            var ps = motes.AddComponent<ParticleSystem>();

            ParticleSystem.MainModule main = ps.main;
            main.loop = true;
            main.prewarm = true; // motes already suspended on frame 0 (the money shot)
            main.simulationSpace = ParticleSystemSimulationSpace.World;
            main.startLifetime = 16f;
            main.startSpeed = new ParticleSystem.MinMaxCurve(0.03f, 0.10f);
            // Size/alpha play-tested: below this the motes vanish entirely at the diorama camera
            // distance; at this they read as faint specks against shadowed walls only.
            main.startSize = new ParticleSystem.MinMaxCurve(0.09f, 0.20f);
            main.startColor = new Color(1f, 0.9f, 0.62f, 0.42f); // low-alpha golden dust
            main.maxParticles = 150;
            main.gravityModifier = 0f;

            ParticleSystem.EmissionModule emission = ps.emission;
            emission.rateOverTime = 9f; // sparse over the whole corridor volume

            ParticleSystem.ShapeModule shape = ps.shape;
            shape.enabled = true;
            shape.shapeType = ParticleSystemShapeType.Box;
            shape.scale = new Vector3(120f, 7f, 34f); // spans spawn → rim, valley height, corridor width

            ParticleSystem.VelocityOverLifetimeModule vel = ps.velocityOverLifetime;
            vel.enabled = true;
            vel.space = ParticleSystemSimulationSpace.World;
            vel.x = new ParticleSystem.MinMaxCurve(-0.05f, 0.05f);
            vel.y = new ParticleSystem.MinMaxCurve(-0.02f, 0.03f); // barely rising, no gusts
            vel.z = new ParticleSystem.MinMaxCurve(-0.05f, 0.05f);

            var psr = motes.GetComponent<ParticleSystemRenderer>();
            psr.renderMode = ParticleSystemRenderMode.Billboard;
            psr.sharedMaterial = mat;
        }

        // ------------------------------------------------------------------------------------
        // Player footfall dust (first VFX pass) — a persisted soft-dot texture + alpha-blended
        // material for PlayerDustPuffs. Reuses the MoteDot radial-alpha approach, but alpha-blended
        // (dust settles, it does not glow) and tinted warm to sit in the pale-gold palette.
        // ------------------------------------------------------------------------------------
        private static Material BuildDustAssets()
        {
            Directory.CreateDirectory(AtmoDir);

            const int res = 48;
            var dot = new Texture2D(res, res, TextureFormat.RGBA32, false) { name = "DustPuff" };
            var half = new Vector2((res - 1) * 0.5f, (res - 1) * 0.5f);
            for (int y = 0; y < res; y++)
            {
                for (int x = 0; x < res; x++)
                {
                    float d = Vector2.Distance(new Vector2(x, y), half) / (res * 0.5f);
                    // Fuller than the MoteDot (which squares the falloff to a tiny bright core): a broad
                    // opaque body with a soft edge, so a dust puff reads as a cloud, not a pinpoint.
                    float a = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01((1f - d) * 1.8f));
                    dot.SetPixel(x, y, new Color(1f, 1f, 1f, a));
                }
            }

            dot.Apply();
            string dotPath = AtmoDir + "/DustPuff.asset";
            AssetDatabase.DeleteAsset(dotPath);
            AssetDatabase.CreateAsset(dot, dotPath);

            // Custom Tarrock/DustParticle shader (URP renders the legacy/programmatic particle materials
            // unreliably): rgb from the particle colour, alpha = particle alpha × sprite alpha.
            Shader particle = Shader.Find("Tarrock/DustParticle");
            var mat = new Material(particle != null ? particle : Shader.Find("Sprites/Default")) { name = "DustMaterial" };
            mat.mainTexture = dot;
            if (mat.HasProperty("_MainTex"))
            {
                mat.SetTexture("_MainTex", dot);
            }

            string matPath = AtmoDir + "/DustMaterial.mat";
            AssetDatabase.DeleteAsset(matPath);
            AssetDatabase.CreateAsset(mat, matPath);
            return mat;
        }

        // ------------------------------------------------------------------------------------
        // Menu entry: install the playable KayKit rig + orbit camera
        // ------------------------------------------------------------------------------------

        [MenuItem("Tarrock/Setup/Install Player In Cliff Hex")]
        public static void InstallPlayer()
        {
            if (EditorApplication.isPlaying)
            {
                Debug.LogError("[Tarrock] Exit play mode before installing the player rig.");
                return;
            }

            if (!File.Exists(CliffHexScenePath))
            {
                Debug.LogError($"[Tarrock] {CliffHexScenePath} not found; run 'Generate Cliff Hex Terrain' first.");
                return;
            }

            EnsurePlayerTag();

            UnityEngine.SceneManagement.Scene scene = EditorSceneManager.GetActiveScene();
            if (scene.path != CliffHexScenePath)
            {
                scene = EditorSceneManager.OpenScene(CliffHexScenePath, OpenSceneMode.Single);
            }

            // Clear any prior rig/camera (idempotent re-run).
            foreach (GameObject root in scene.GetRootGameObjects())
            {
                if (root.name == PlayerRootName || root.name == CameraRootName)
                {
                    Object.DestroyImmediate(root);
                }
            }

            if (!ResolveSpawn(out Vector3 spawnPos, out Quaternion spawnRot))
            {
                Debug.LogError("[Tarrock] No PlayerSpawnPoint found in the scene; cannot place the Fool.");
                return;
            }

            Physics.SyncTransforms();
            Vector3 grounded = GroundedSpawn(spawnPos);

            var inputAsset = AssetDatabase.LoadAssetAtPath<InputActionAsset>(InputAssetPath);
            InputActionReference lookRef = FindActionReference(InputAssetPath, "Look");

            GameObject playerRig = BuildPlayerRig(grounded, spawnRot, inputAsset, out float visualHeight);
            GameObject mainCamera = BuildCameraRig(playerRig.transform, lookRef, visualHeight, spawnRot);

            Transform vcam = mainCamera.transform.parent.Find("PlayerFollowCamera");
            if (vcam != null)
            {
                mainCamera.transform.SetPositionAndRotation(vcam.position, vcam.rotation);
            }

            SetObjectReference(playerRig.GetComponent<PlayerMotor>(), "_cameraTransform", mainCamera.transform);
            SetObjectReference(playerRig.GetComponent<PlayerDodge>(), "_cameraTransform", mainCamera.transform);

            // Wire the Focus stance to the vcam it steers (holds the orbit behind + tightens FOV).
            FocusStance focusStance = playerRig.GetComponent<FocusStance>();
            if (focusStance != null && vcam != null)
            {
                SetObjectReference(focusStance, "_vcam", vcam.GetComponent<CinemachineCamera>());
                SetObjectReference(focusStance, "_orbital", vcam.GetComponent<CinemachineOrbitalFollow>());
            }

            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, CliffHexScenePath);
            AssetDatabase.SaveAssets();

            Debug.Log($"[Tarrock] Player installed in {CliffHexScenePath} at {grounded} " +
                $"(height {visualHeight:F2} m), orbit camera wired.");
        }

        private static bool ResolveSpawn(out Vector3 pos, out Quaternion rot)
        {
            PlayerSpawnPoint sp = Object.FindFirstObjectByType<PlayerSpawnPoint>();
            if (sp != null)
            {
                pos = sp.transform.position;
                rot = sp.transform.rotation;
                return true;
            }

            // Headless fallback: the MonoBehaviour stub may not bind — scan by name.
            foreach (GameObject go in EditorSceneManager.GetActiveScene().GetRootGameObjects())
            {
                Transform found = FindByNamePrefix(go.transform, "PlayerSpawn");
                if (found != null)
                {
                    pos = found.position;
                    rot = found.rotation;
                    return true;
                }
            }

            pos = Vector3.zero;
            rot = Quaternion.identity;
            return false;
        }

        private static Transform FindByNamePrefix(Transform t, string prefix)
        {
            if (t.name.StartsWith(prefix))
            {
                return t;
            }

            foreach (Transform child in t)
            {
                Transform r = FindByNamePrefix(child, prefix);
                if (r != null)
                {
                    return r;
                }
            }

            return null;
        }

        private static Vector3 GroundedSpawn(Vector3 spawn)
        {
            // Ground against TERRAIN TILES only — the prop colliders (tents, crates…) also sit under
            // this ray, and grounding on one of those perches the Fool on a tent roof.
            var origin = new Vector3(spawn.x, spawn.y + 30f, spawn.z);
            RaycastHit[] hits = Physics.RaycastAll(origin, Vector3.down, 80f);
            float best = float.MinValue;
            foreach (RaycastHit hit in hits)
            {
                Transform parent = hit.collider.transform.parent;
                if (parent != null && parent.name == TilesGroupName && hit.point.y > best)
                {
                    best = hit.point.y;
                }
            }

            if (best > float.MinValue)
            {
                return new Vector3(spawn.x, best + 0.02f, spawn.z);
            }

            Debug.LogWarning("[Tarrock] Spawn ground raycast missed the tiles; using the marker's own y.");
            return spawn;
        }

        // -- Rig + camera (ported from KayKitCharacterInstaller; the Fool at the diorama scale) --

        private static GameObject BuildPlayerRig(Vector3 position, Quaternion rotation,
            InputActionAsset inputAsset, out float visualHeight)
        {
            var playerRig = new GameObject(PlayerRootName) { tag = PlayerTag };
            playerRig.transform.SetPositionAndRotation(position, rotation);

            Animator animator = BuildCharacterVisual(playerRig.transform, out visualHeight);

            var controller = playerRig.AddComponent<CharacterController>();
            controller.height = visualHeight;
            controller.radius = Mathf.Min(0.16f, visualHeight * 0.28f);
            controller.center = new Vector3(0f, visualHeight * 0.5f, 0f);
            controller.stepOffset = Mathf.Min(0.18f, visualHeight * 0.28f);
            // Unity's default 0.08 m skin is ~half this miniature controller's radius — it rests the
            // capsule that far above the ground. Shrink it to a small fraction of the radius so the
            // rest gap is negligible (FIX 3 — hero zero), then drop the Visual by exactly that skin so
            // the boots meet the true ground contact (the CC bottom always floats skinWidth up).
            controller.skinWidth = controller.radius * 0.1f;
            DropVisualBySkin(playerRig.transform, controller.skinWidth);

            var inputReader = playerRig.AddComponent<PlayerInputReader>();
            PlayerDodge dodge = playerRig.AddComponent<PlayerDodge>();
            PlayerMotor motor = playerRig.AddComponent<PlayerMotor>();
            playerRig.AddComponent<CursorLock>();

            SetObjectReference(inputReader, "_actions", inputAsset);
            SetObjectReference(dodge, "_input", inputReader);
            SetObjectReference(dodge, "_motor", motor);
            SetObjectReference(motor, "_input", inputReader);
            SetObjectReference(motor, "_dodge", dodge);

            var driver = playerRig.AddComponent<PlayerAnimationDriver>();
            SetObjectReference(driver, "_animator", animator);
            SetObjectReference(driver, "_motor", motor);
            SetObjectReference(driver, "_dodge", dodge);

            // Footfall dust (first VFX pass): the puff/ring systems build themselves at runtime; wire
            // the persisted DustMaterial so the pooled particles share one alpha-blended dust sprite.
            var dust = playerRig.AddComponent<PlayerDustPuffs>();
            SetObjectReference(dust, "_dustMaterial", BuildDustAssets());
            SetObjectReference(dodge, "_dust", dust);
            SetObjectReference(motor, "_dust", dust);

            // Focus stance camera (combat.md §Focus): holds behind + FOV tighten. The vcam refs are
            // wired in InstallPlayer once the camera rig exists.
            FocusStance focusStance = playerRig.AddComponent<FocusStance>();
            SetObjectReference(focusStance, "_input", inputReader);
            SetObjectReference(focusStance, "_player", playerRig.transform);
            return playerRig;
        }

        private static Animator BuildCharacterVisual(Transform parent, out float visualHeight)
        {
            var model = AssetDatabase.LoadAssetAtPath<GameObject>(CharacterModelPath);
            var visual = (GameObject)PrefabUtility.InstantiatePrefab(model);
            visual.name = "Visual";
            visual.transform.SetParent(parent, false);
            visual.transform.localPosition = Vector3.zero;
            visual.transform.localRotation = Quaternion.identity; // KayKit faces +Z
            visual.transform.localScale = Vector3.one * VisualScale;

            foreach (Transform t in visual.GetComponentsInChildren<Transform>(true))
            {
                if (!t.name.StartsWith("handslot", System.StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                foreach (Transform prop in t)
                {
                    if (prop.gameObject.activeSelf && prop.GetComponent<Renderer>() != null)
                    {
                        prop.gameObject.SetActive(false);
                    }
                }
            }

            visualHeight = MeasureHeight(visual);
            AlignFeetToOrigin(visual, parent);

            Animator animator = visual.GetComponent<Animator>() ?? visual.AddComponent<Animator>();
            var controller = AssetDatabase.LoadAssetAtPath<RuntimeAnimatorController>(ControllerPath);
            if (controller != null)
            {
                animator.runtimeAnimatorController = controller;
            }
            else
            {
                Debug.LogWarning($"[Tarrock] {ControllerPath} absent; the Fool will render but not animate.");
            }

            return animator;
        }

        // Plants the Fool's feet on the ground (FIX 3 — "check the player's zero"): the Rogue_Hooded
        // model's lowest rendered point sits a little below its own pivot, so with the Visual at local
        // zero the feet clipped ~0.05 m into the terrain. Align the visual's bounds.min (the feet) to
        // the rig origin — which is the CharacterController's bottom — so the feet rest exactly on the
        // ground contact point in play, neither hovering nor sinking. Model-measured, so it stays
        // correct if the visual scale changes.
        private static void AlignFeetToOrigin(GameObject visual, Transform rig)
        {
            Renderer[] renderers = visual.GetComponentsInChildren<Renderer>();
            if (renderers.Length == 0)
            {
                return;
            }

            Bounds b = renderers[0].bounds;
            for (int i = 1; i < renderers.Length; i++)
            {
                b.Encapsulate(renderers[i].bounds);
            }

            float footOffset = b.min.y - rig.position.y; // <0 when the feet dip below the rig origin
            Vector3 lp = visual.transform.localPosition;
            visual.transform.localPosition = new Vector3(lp.x, lp.y - footOffset, lp.z);
        }

        // Lowers the Visual by the controller's skin width so the feet — already aligned to the CC
        // bottom by AlignFeetToOrigin — render at the true ground contact (the CC bottom rests skinWidth
        // above the surface). FIX 3, hero zero.
        private static void DropVisualBySkin(Transform rig, float skin)
        {
            Transform visual = rig.Find("Visual");
            if (visual == null)
            {
                return;
            }

            Vector3 lp = visual.localPosition;
            visual.localPosition = new Vector3(lp.x, lp.y - skin, lp.z);
        }

        private static float MeasureHeight(GameObject visual)
        {
            Renderer[] renderers = visual.GetComponentsInChildren<Renderer>();
            if (renderers.Length == 0)
            {
                return VisualScale;
            }

            Bounds bounds = renderers[0].bounds;
            for (int i = 1; i < renderers.Length; i++)
            {
                bounds.Encapsulate(renderers[i].bounds);
            }

            return Mathf.Max(0.1f, bounds.size.y);
        }

        private static GameObject BuildCameraRig(Transform followTarget, InputActionReference lookRef,
            float playerHeight, Quaternion facing)
        {
            var cameraRig = new GameObject(CameraRootName);

            var mainCameraGo = new GameObject("Main Camera") { tag = "MainCamera" };
            mainCameraGo.transform.SetParent(cameraRig.transform, false);
            var camera = mainCameraGo.AddComponent<Camera>();
            mainCameraGo.AddComponent<AudioListener>();
            mainCameraGo.AddComponent<CinemachineBrain>();
            AddUrpCameraData(mainCameraGo);
            camera.nearClipPlane = 0.05f;

            float pivotHeight = playerHeight * CamPivotFactor;
            float orbitRadius = playerHeight * CamRadiusFactor;

            var vcamGo = new GameObject("PlayerFollowCamera");
            vcamGo.transform.SetParent(cameraRig.transform, false);
            var vcam = vcamGo.AddComponent<CinemachineCamera>();
            vcam.Follow = followTarget;
            vcam.LookAt = followTarget;
            vcam.Lens.FieldOfView = CamFieldOfView;

            var orbital = vcamGo.AddComponent<CinemachineOrbitalFollow>();
            orbital.TargetOffset = new Vector3(0f, pivotHeight, 0f);
            orbital.Radius = orbitRadius;
            orbital.HorizontalAxis.Wrap = true;
            // OrbitalFollow's horizontal axis is world-locked; the value equals the player's facing
            // yaw to seat the camera directly behind the Fool (W then drives down the trail).
            float behindYaw = facing.eulerAngles.y;
            orbital.HorizontalAxis.Value = behindYaw;
            orbital.HorizontalAxis.Center = behindYaw;
            orbital.VerticalAxis.Value = CamVerticalDefault;
            orbital.VerticalAxis.Center = CamVerticalDefault;
            orbital.VerticalAxis.Range = new Vector2(CamVerticalMin, CamVerticalMax);

            vcamGo.AddComponent<CinemachineRotationComposer>();

            // Wall response (SPEC A): the deoccluder pulls the camera forward and clamps at 1 m, a
            // decollider keeps it out of walls, and CameraWallResponse stages the whisker bias, the
            // head-top framing shift and the character fade. Never drives pitch (no more up-and-over).
            // Configured identically to KayKitCharacterInstaller via the shared CameraRigConfig helper.
            CameraRigConfig.Apply(vcamGo, orbital, vcam, followTarget.gameObject, orbitRadius, PlayerTag);

            Vector3 lookPoint = followTarget.position + new Vector3(0f, pivotHeight, 0f);
            Vector3 startPos = lookPoint - (followTarget.forward * orbitRadius) + (Vector3.up * playerHeight * 0.6f);
            vcamGo.transform.SetPositionAndRotation(startPos, Quaternion.LookRotation(lookPoint - startPos, Vector3.up));

            var axisController = vcamGo.AddComponent<CinemachineInputAxisController>();
            axisController.ScanRecursively = true;
            axisController.SynchronizeControllers();
            WireLookAxes(axisController, lookRef);
            return mainCameraGo;
        }

        private static void AddUrpCameraData(GameObject cameraGo)
        {
            System.Type urp = System.Type.GetType(
                "UnityEngine.Rendering.Universal.UniversalAdditionalCameraData, Unity.RenderPipelines.Universal.Runtime");
            if (urp != null && cameraGo.GetComponent(urp) == null)
            {
                cameraGo.AddComponent(urp);
            }
        }

        private static void WireLookAxes(CinemachineInputAxisController axisController, InputActionReference lookRef)
        {
            if (lookRef == null)
            {
                return;
            }

            foreach (CinemachineInputAxisController.Controller controller in axisController.Controllers)
            {
                if (controller?.Name == null)
                {
                    continue;
                }

                if (controller.Name.Contains("Orbit X"))
                {
                    controller.Input.InputAction = lookRef;
                    controller.Input.Gain = 4f;
                }
                else if (controller.Name.Contains("Orbit Y"))
                {
                    controller.Input.InputAction = lookRef;
                    controller.Input.Gain = -2.5f;
                }
            }
        }

        // ------------------------------------------------------------------------------------
        // Shared helpers
        // ------------------------------------------------------------------------------------

        private static Mesh MeshOf(string fbxPath, out Material[] mats)
        {
            mats = null;
            var src = AssetDatabase.LoadAssetAtPath<GameObject>(fbxPath);
            if (src == null)
            {
                return null;
            }

            MeshFilter mf = src.GetComponentInChildren<MeshFilter>();
            if (mf == null)
            {
                return null;
            }

            MeshRenderer mr = mf.GetComponent<MeshRenderer>();
            mats = mr != null ? mr.sharedMaterials : new Material[0];
            return mf.sharedMesh;
        }

        private static int FloorDiv(int a, int b)
        {
            int q = a / b;
            if ((a % b != 0) && ((a < 0) != (b < 0)))
            {
                q--;
            }

            return q;
        }

        private static float Hash01(int a, int b)
        {
            unchecked
            {
                int h = (a * 73856093) ^ (b * 19349663);
                h = (h ^ (h >> 13)) * 1274126177;
                return ((h & 0x7fffffff) % 10000) / 10000f;
            }
        }

        private static void EnsurePlayerTag()
        {
            Object[] assets = AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset");
            if (assets == null || assets.Length == 0)
            {
                return;
            }

            var tagManager = new SerializedObject(assets[0]);
            SerializedProperty tags = tagManager.FindProperty("tags");
            if (tags == null)
            {
                return;
            }

            for (int i = 0; i < tags.arraySize; i++)
            {
                if (tags.GetArrayElementAtIndex(i).stringValue == PlayerTag)
                {
                    return;
                }
            }

            tags.InsertArrayElementAtIndex(tags.arraySize);
            tags.GetArrayElementAtIndex(tags.arraySize - 1).stringValue = PlayerTag;
            tagManager.ApplyModifiedPropertiesWithoutUndo();
        }

        private static InputActionReference FindActionReference(string assetPath, string actionName)
        {
            InputActionReference hidden = null;
            foreach (Object asset in AssetDatabase.LoadAllAssetsAtPath(assetPath))
            {
                if (asset is not InputActionReference reference)
                {
                    continue;
                }

                InputAction action = reference.action;
                string resolved = action != null ? action.name : null;
                bool matches = resolved == actionName || reference.name == actionName
                    || (reference.name != null &&
                        (reference.name.EndsWith("/" + actionName) || reference.name.EndsWith(":" + actionName)));
                if (!matches)
                {
                    continue;
                }

                if ((reference.hideFlags & HideFlags.HideInHierarchy) == 0)
                {
                    return reference;
                }

                hidden ??= reference;
            }

            return hidden;
        }

        private static void SetObjectReference(Object target, string fieldName, Object value)
        {
            if (target == null)
            {
                return;
            }

            var serialized = new SerializedObject(target);
            SerializedProperty property = serialized.FindProperty(fieldName);
            if (property == null)
            {
                Debug.LogWarning($"[Tarrock] Field '{fieldName}' not found on {target.GetType().Name}.");
                return;
            }

            property.objectReferenceValue = value;
            serialized.ApplyModifiedPropertiesWithoutUndo();
        }
    }
}
