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
    /// - A high meadow plateau at the world's broken edge; a gentle valley funnels the Fool west
    ///   (terrain grammar: cliffs refuse, slopes permit, landmarks pull — art-audio swap rule 5).
    /// - Scale contract: one hex ≈ 4 m flat-to-flat (KayKit tile is 2 m, parent scaled ×2).
    /// - Marker ids and world XZ carry over verbatim from the flat Cliff (swap discipline: gameplay
    ///   references markers, not meshes). Y is re-seated onto the new terrain.
    /// - The single dead tree is the ONLY dead thing on the plateau (the thesis in miniature). The
    ///   Waystation is a wayside shrine on a rise. The west rim past the Waystation is the broken
    ///   edge, where the LeapOfFaith trigger sits over floating cloud.
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
        private const float ZNorth = 75f;                  // world z of grid row 0 (north edge)
        private const float XWest0 = -116f;                // world x of grid column 0
        private const int Rows = 35;
        private const int Cols = 54;
        private const float StepWorld = 2f;                // one elevation step in world metres

        // -- Region roots ---------------------------------------------------------------------
        private const string TerrainRootName = "CliffTerrain";
        private const string TilesGroupName = "Tiles";
        private const string DecoGroupName = "Deco";
        private const string MarkersRootName = "RegionMarkers";
        private const string PlayerRootName = "PlayerRig";
        private const string CameraRootName = "CameraRig";
        private const string PlayerSpawnName = "PlayerSpawn_Campfire";
        private const string PlayerTag = "Player";

        // -- Landmark world XZ (carried over from the flat Cliff; see CliffMarkerIds / MQ00) ---
        private static readonly Vector2 WaystationXZ = new Vector2(-100f, 0f);
        private static readonly Vector2 DeadTreeXZ = new Vector2(-10f, 65f);
        private static readonly Vector2 SpawnXZ = new Vector2(81.5f, 0f);
        private static readonly Vector2 CliffEdgeXZ = new Vector2(-119f, 0f);
        private static readonly Vector2 KeepsakeXZ = new Vector2(3.2f, 11.2f);
        private static readonly Vector2 AmbushXZ = new Vector2(-75f, 0f);
        private static readonly Vector3 LeapTriggerPos = new Vector3(-125f, -8f, 0f);
        private static readonly Vector3 LeapTriggerSize = new Vector3(10f, 20f, 240f);

        // The six old campsites forming the westward trail (world XZ).
        private static readonly Vector2[] CampXZ =
        {
            new Vector2(80f, 0f),   // 1 — the wake campfire (holds the spawn)
            new Vector2(56f, -18f), // 2
            new Vector2(38f, 14f),  // 3
            new Vector2(21f, -16f), // 4
            new Vector2(3f, 12f),   // 5 — largest; the keepsake dig spot
            new Vector2(-14f, -6f), // 6 — recent
        };

        // Standing stones flank the trail just before the ambush (MQ00 "path narrows between two
        // standing stones"); the flat Cliff put them at x -50, z ±8.
        private static readonly Vector2[] StandingStoneXZ =
        {
            new Vector2(-50f, 8f),
            new Vector2(-50f, -8f),
        };

        // Living-tree clusters (KayKit ForestNature). Wind-scoured meadow → clustered and sparse,
        // never near the dead-tree knoll (which stays bare) or the rim.
        private static readonly Vector2[] GroveXZ =
        {
            new Vector2(52f, 16f), new Vector2(30f, -13f), new Vector2(-32f, 12f),
            new Vector2(-60f, -13f), new Vector2(12f, 24f), new Vector2(66f, -10f),
            // Two more clustered stands on the south valley flank between campsites 2–4, so the
            // mid-trail isn't bare (still clustered, never sprinkled — the meadow stays wind-scoured).
            new Vector2(46f, -16f), new Vector2(24f, -15f),
        };

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

            var present = ComputePresentTiles();
            int tileCount = 0, wallCount = 0, rampCount = 0, slabCount = 0;

            foreach (KeyValuePair<(int, int), Vector2> kv in present)
            {
                (int r, int c) = kv.Key;
                Vector2 xz = kv.Value;
                int level = LevelAt(xz.x, xz.y);
                bool boundary = IsBoundary(r, c, present);
                bool westRim = boundary && xz.x < -104f;

                // Seal non-rim boundaries with a lip; leave the west rim low so the Fool can walk off.
                if (boundary && !westRim && level < 1)
                {
                    level = 1;
                    wallCount++;
                }

                float groundY = level * StepWorld;

                // Ramps: a valley tile that meets a raised neighbour becomes a walkable slope
                // (slopes permit). Everything else that steps up is a cliff (cliffs refuse).
                if (level == 0 && TryRampYaw(xz.x, xz.y, out float rampYaw))
                {
                    MakeTile(slopeMesh, slopeMats, new Vector3(xz.x, groundY, xz.y), rampYaw, tiles.transform,
                        $"ramp_{r}_{c}");
                    rampCount++;
                }
                else
                {
                    MakeTile(grassMesh, grassMats, new Vector3(xz.x, groundY, xz.y), 0f, tiles.transform,
                        $"hex_{r}_{c}");
                }

                tileCount++;

                // Underside slabs float the plateau (diorama-on-a-table read); the broken west rim
                // gets a deeper, raggeder stack.
                if (boundary)
                {
                    MakeTile(bottomMesh, bottomMats, new Vector3(xz.x, groundY - StepWorld, xz.y), 0f,
                        tiles.transform, $"under1_{r}_{c}");
                    slabCount++;
                    if (westRim || Hash01(r, c) > 0.5f)
                    {
                        MakeTile(bottomMesh, bottomMats, new Vector3(xz.x, groundY - (2f * StepWorld), xz.y), 0f,
                            tiles.transform, $"under2_{r}_{c}");
                        slabCount++;
                    }
                }
            }

            DressCampsites(deco.transform);
            DressStandingStones(deco.transform);
            DressWaystation(deco.transform);
            DressDeadTree(deco.transform);
            DressGroves(deco.transform);
            DressClouds(deco.transform);

            BuildMarkers();
            BuildLighting();

            Directory.CreateDirectory(SceneDir);
            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, CliffHexScenePath);
            AssetDatabase.SaveAssets();

            Debug.Log($"[Tarrock] Cliff hex terrain built into {CliffHexScenePath}: {tileCount} tiles " +
                $"({wallCount} sealed as walls, {rampCount} ramps), {slabCount} underside slabs. " +
                "Run 'Install Player In Cliff Hex' next.");
        }

        // ------------------------------------------------------------------------------------
        // Plateau shape + elevation
        // ------------------------------------------------------------------------------------

        // World XZ centre of the pointy-top offset cell at (row, col).
        private static Vector2 CellXZ(int r, int c)
        {
            float x = XWest0 + (c * ColDX) + ((r & 1) * (ColDX * 0.5f));
            float z = ZNorth - (r * RowDZ);
            return new Vector2(x, z);
        }

        // Union of a few overlapping ellipses gives an organic, non-rectangular outline; a stable
        // per-cell hash raggeds the boundary. Returns the present cells keyed by (row, col).
        private static Dictionary<(int, int), Vector2> ComputePresentTiles()
        {
            var present = new Dictionary<(int, int), Vector2>();
            for (int r = 0; r < Rows; r++)
            {
                for (int c = 0; c < Cols; c++)
                {
                    Vector2 xz = CellXZ(r, c);
                    if (InsidePlateau(xz.x, xz.y, r, c))
                    {
                        present[(r, c)] = xz;
                    }
                }
            }

            return present;
        }

        private static bool InsidePlateau(float x, float z, int r, int c)
        {
            float v = Mathf.Min(
                Ellipse(x, z, -12f, 0f, 112f, 27f),   // main meadow body (E–W lozenge)
                Mathf.Min(
                    Ellipse(x, z, -10f, 50f, 22f, 33f),   // north knoll peninsula
                    Mathf.Min(
                        Ellipse(x, z, -55f, -18f, 42f, 17f),  // SW bulge
                        Ellipse(x, z, 46f, 12f, 32f, 16f)))); // NE bulge
            float noise = (Hash01(r, c) * 0.12f) - 0.06f;
            return v < 1f + noise;
        }

        private static float Ellipse(float x, float z, float cx, float cz, float rx, float rz)
        {
            float nx = (x - cx) / rx;
            float nz = (z - cz) / rz;
            return (nx * nx) + (nz * nz);
        }

        // Elevation in integer steps. Valley floor 0; flanking ridges, the north peninsula, and the
        // Waystation rise sit at step 1 (a 2 m cliff the Fool cannot climb — only descend).
        private static int LevelAt(float x, float z)
        {
            if (Sqr(x - WaystationXZ.x) + Sqr(z - WaystationXZ.y) <= Sqr(11f))
            {
                return 1; // Waystation rise
            }

            if (z >= 20f)
            {
                return 1; // north ridge + knoll peninsula
            }

            if (z <= -20f)
            {
                return 1; // south ridge
            }

            return 0;
        }

        // A level-0 tile that should be a ramp instead of flat ground, plus the yaw that turns the
        // slope's default −X high edge toward the uphill neighbour.
        private static bool TryRampYaw(float x, float z, out float yaw)
        {
            yaw = 0f;

            // Knoll approach: valley → north peninsula, high edge faces +Z.
            if (Mathf.Abs(x - DeadTreeXZ.x) <= 4f && z >= 16.5f && z <= 20f)
            {
                yaw = YawForHighEdge(0f, 1f);
                return true;
            }

            // Waystation east foot: valley → the rise, high edge faces the shrine (−X-ish).
            float d = Mathf.Sqrt(Sqr(x - WaystationXZ.x) + Sqr(z - WaystationXZ.y));
            if (d > 11f && d <= 14f && Mathf.Abs(z) <= 5f)
            {
                yaw = YawForHighEdge(WaystationXZ.x - x, WaystationXZ.y - z);
                return true;
            }

            return false;
        }

        // The slope tile's high edge points at local −X (verified). Solve the yaw that rotates that
        // edge to face direction (dx, dz): −cos θ = dx, sin θ = dz → θ = atan2(dz, −dx).
        private static float YawForHighEdge(float dx, float dz)
        {
            return Mathf.Atan2(dz, -dx) * Mathf.Rad2Deg;
        }

        private static bool IsBoundary(int r, int c, Dictionary<(int, int), Vector2> present)
        {
            // Pointy-top offset neighbours differ for even/odd rows.
            int e = r & 1;
            (int, int)[] neighbours =
            {
                (r, c - 1), (r, c + 1),
                (r - 1, c - 1 + e), (r - 1, c + e),
                (r + 1, c - 1 + e), (r + 1, c + e),
            };
            foreach ((int, int) n in neighbours)
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
            go.AddComponent<MeshRenderer>().sharedMaterials = mats;
            go.AddComponent<MeshCollider>().sharedMesh = mesh;
            go.isStatic = true;
            return go;
        }

        // ------------------------------------------------------------------------------------
        // Dressing
        // ------------------------------------------------------------------------------------

        private static void DressCampsites(Transform parent)
        {
            var camps = new GameObject("Campsites");
            camps.transform.SetParent(parent, false);
            string[] tents = { "props/tent.fbx" };
            string[] extras =
            {
                "props/barrel.fbx", "props/crate_A_small.fbx", "props/sack.fbx",
                "props/bucket_empty.fbx", "props/resource_lumber.fbx",
            };

            for (int i = 0; i < CampXZ.Length; i++)
            {
                Vector2 xz = CampXZ[i];
                float gy = LevelAt(xz.x, xz.y) * StepWorld;
                var rnd = new System.Random(4100 + i);
                var camp = new GameObject($"Camp{i + 1}");
                camp.transform.SetParent(camps.transform, false);
                camp.transform.localPosition = new Vector3(xz.x, gy, xz.y) / ParentScale;

                // Cold fire-ring: small stones, no flame (long abandoned).
                int stones = 6;
                for (int s = 0; s < stones; s++)
                {
                    float ang = (s / (float)stones) * Mathf.PI * 2f;
                    var lp = new Vector3(Mathf.Cos(ang) * 0.45f, 0f, Mathf.Sin(ang) * 0.45f);
                    Place(camp.transform, DecoDir + "/nature/rock_single_A.fbx", lp,
                        new Vector3(0f, rnd.Next(0, 360), 0f), 0.65f, $"firestone_{s}", true);
                }

                // A tent, canted and weathered.
                Place(camp.transform, DecoDir + "/" + tents[0], new Vector3(0.9f, 0f, 0.4f),
                    new Vector3(0f, rnd.Next(0, 360), i % 2 == 0 ? 3f : -4f), 1.6f, "tent", true);

                // One-to-three human-scale props, some tipped over.
                int n = 1 + rnd.Next(0, 3);
                for (int p = 0; p < n; p++)
                {
                    string prop = extras[rnd.Next(extras.Length)];
                    float ang = rnd.Next(0, 360);
                    float rad = 0.7f + ((float)rnd.NextDouble() * 0.6f);
                    var lp = new Vector3(Mathf.Cos(ang * Mathf.Deg2Rad) * rad, 0f,
                        Mathf.Sin(ang * Mathf.Deg2Rad) * rad);
                    float tip = rnd.NextDouble() > 0.5 ? 90f : 0f; // some knocked over
                    Place(camp.transform, DecoDir + "/" + prop, lp,
                        new Vector3(tip, rnd.Next(0, 360), 0f), 1.5f, $"prop_{p}", true);
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
                float gy = LevelAt(xz.x, xz.y) * StepWorld;
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
            float gy = LevelAt(WaystationXZ.x, WaystationXZ.y) * StepWorld;
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
            // The White Rose stand-in regrows at the basin (progression.md §The White Rose).
            // Quaternius prefabs bake a 100× root scale, so these need large absolute scales
            // (unlike the natural-scale-1 KayKit props).
            Place(group.transform, QuatDir + "/Flower_1_Clump.fbx", new Vector3(0.2f, 0f, 1.1f),
                new Vector3(270f, 0f, 0f), 32f, "WhiteRose_StandIn", false);
        }

        private static void DressDeadTree(Transform parent)
        {
            float gy = LevelAt(DeadTreeXZ.x, DeadTreeXZ.y) * StepWorld;
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
        }

        private static void DressGroves(Transform parent)
        {
            var group = new GameObject("Groves");
            group.transform.SetParent(parent, false);
            string[] trees =
            {
                DecoDir + "/nature/tree_single_A.fbx", DecoDir + "/nature/tree_single_B.fbx",
                DecoDir + "/nature/trees_A_medium.fbx", DecoDir + "/nature/trees_B_small.fbx",
            };
            string[] bushes =
            {
                ForestDir + "/Bush_2_A_Color1.fbx", ForestDir + "/Bush_1_C_Color1.fbx",
            };
            var rnd = new System.Random(90210);
            int idx = 0;
            foreach (Vector2 g in GroveXZ)
            {
                // Never dress the bare dead-tree knoll.
                if (Vector2.Distance(g, DeadTreeXZ) < 14f)
                {
                    continue;
                }

                float gy = LevelAt(g.x, g.y) * StepWorld;
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

                for (int i = 0; i < 2; i++)
                {
                    float jx = ((float)rnd.NextDouble() * 2f - 1f) * 3.5f;
                    float jz = ((float)rnd.NextDouble() * 2f - 1f) * 3.5f;
                    Place(group.transform, bushes[rnd.Next(bushes.Length)],
                        new Vector3(g.x + jx, gy, g.y + jz) / ParentScale,
                        new Vector3(0f, rnd.Next(0, 360), 0f),
                        1.1f + ((float)rnd.NextDouble() * 0.5f), $"bush_{idx++}", false);
                }
            }

            // A thin scatter of grass tufts across the valley (wind-scoured, so sparse).
            for (int i = 0; i < 24; i++)
            {
                float x = -90f + ((float)rnd.NextDouble() * 150f);
                float z = -16f + ((float)rnd.NextDouble() * 32f);
                if (Vector2.Distance(new Vector2(x, z), DeadTreeXZ) < 12f)
                {
                    continue;
                }

                // Quaternius (100× baked root scale) → large absolute scale for a knee-high tuft.
                Place(group.transform, QuatDir + "/Grass_Small.fbx",
                    new Vector3(x, 0f, z) / ParentScale, new Vector3(270f, rnd.Next(0, 360), 0f),
                    45f + ((float)rnd.NextDouble() * 25f), $"tuft_{idx++}", false);
            }
        }

        private static void DressClouds(Transform parent)
        {
            var group = new GameObject("Clouds");
            group.transform.SetParent(parent, false);
            var rnd = new System.Random(31337);
            // Floating below the broken west rim and drifting south — clone the sandbox's read.
            for (int i = 0; i < 14; i++)
            {
                bool big = rnd.Next(0, 2) == 0;
                string path = DecoDir + (big ? "/nature/cloud_big.fbx" : "/nature/cloud_small.fbx");
                float x = -128f + ((float)rnd.NextDouble() * 26f);   // beyond/below the west rim
                float z = -35f + ((float)rnd.NextDouble() * 110f);
                float y = -8f - ((float)rnd.NextDouble() * 14f);
                Place(group.transform, path, new Vector3(x, y, z) / ParentScale,
                    new Vector3(0f, rnd.Next(0, 360), 0f), 1.4f + ((float)rnd.NextDouble() * 0.6f),
                    $"cloud_{i}", false);
            }
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
            return g;
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

            // Leap-of-faith trigger, verbatim from the flat Cliff (over the void past the west rim).
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
            return new Vector3(xz.x, LevelAt(xz.x, xz.y) * StepWorld, xz.y);
        }

        private static void BuildLighting()
        {
            var go = new GameObject("Directional_Light_Dawn");
            var light = go.AddComponent<Light>();
            light.type = LightType.Directional;
            light.color = new Color(1f, 0.93f, 0.78f); // pale dawn gold
            light.intensity = 1.2f;
            light.shadows = LightShadows.Soft;
            // Low, warm, from the east — the Fool enters dawn-side (world.md §The Spread).
            go.transform.rotation = Quaternion.Euler(25f, 265f, 0f);

            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.66f, 0.74f, 0.86f);
            RenderSettings.ambientEquatorColor = new Color(0.62f, 0.66f, 0.58f);
            RenderSettings.ambientGroundColor = new Color(0.34f, 0.34f, 0.30f);
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
            var origin = new Vector3(spawn.x, spawn.y + 30f, spawn.z);
            if (Physics.Raycast(origin, Vector3.down, out RaycastHit hit, 80f))
            {
                return new Vector3(spawn.x, hit.point.y + 0.02f, spawn.z);
            }

            Debug.LogWarning("[Tarrock] Spawn ground raycast missed; using the marker's own y.");
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

            var inputReader = playerRig.AddComponent<PlayerInputReader>();
            PlayerDodge dodge = playerRig.AddComponent<PlayerDodge>();
            PlayerMotor motor = playerRig.AddComponent<PlayerMotor>();
            playerRig.AddComponent<CursorLock>();

            SetObjectReference(inputReader, "_actions", inputAsset);
            SetObjectReference(dodge, "_input", inputReader);
            SetObjectReference(motor, "_input", inputReader);
            SetObjectReference(motor, "_dodge", dodge);

            var driver = playerRig.AddComponent<PlayerAnimationDriver>();
            SetObjectReference(driver, "_animator", animator);
            SetObjectReference(driver, "_motor", motor);
            SetObjectReference(driver, "_dodge", dodge);
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

            float chestHeight = playerHeight * 0.78f;
            float orbitRadius = playerHeight * 2.8f;

            var vcamGo = new GameObject("PlayerFollowCamera");
            vcamGo.transform.SetParent(cameraRig.transform, false);
            var vcam = vcamGo.AddComponent<CinemachineCamera>();
            vcam.Follow = followTarget;
            vcam.LookAt = followTarget;
            vcam.Lens.FieldOfView = 55f;

            var orbital = vcamGo.AddComponent<CinemachineOrbitalFollow>();
            orbital.TargetOffset = new Vector3(0f, chestHeight, 0f);
            orbital.Radius = orbitRadius;
            orbital.HorizontalAxis.Wrap = true;
            // OrbitalFollow's horizontal axis is world-locked; the value equals the player's facing
            // yaw to seat the camera directly behind the Fool (W then drives down the trail).
            float behindYaw = facing.eulerAngles.y;
            orbital.HorizontalAxis.Value = behindYaw;
            orbital.HorizontalAxis.Center = behindYaw;
            orbital.VerticalAxis.Value = 10f;
            orbital.VerticalAxis.Center = 10f;
            orbital.VerticalAxis.Range = new Vector2(-5f, 35f);

            vcamGo.AddComponent<CinemachineRotationComposer>();

            Vector3 lookPoint = followTarget.position + new Vector3(0f, chestHeight, 0f);
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

        private static float Sqr(float v) => v * v;

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
