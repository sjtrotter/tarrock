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

        // -- Atmosphere assets (mood pass, docs/design/art-audio.md) --------------------------
        private const string AtmoDir = "Assets/_Project/Art/Atmosphere";
        private const string GradientSkyShader = "Tarrock/GradientSky";

        // -- Prop-collider staging (item 3) ---------------------------------------------------
        // Dressing props are walk-through by default; the director wants solid props. Each Place()
        // that warrants collision registers a job here (kind: 1 box, 2 trunk/post capsule, 3 well box);
        // BuildPropColliders resolves them AFTER all dressing (so post-Place rescales are final) into
        // one PropColliders root at world scale 1 (bounds map straight through). Grass tufts, tiny
        // flowers and clouds never register — walking through those is correct.
        private static Transform s_propColliders;
        private static readonly List<(GameObject go, int kind)> s_colliderJobs =
            new List<(GameObject, int)>();

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

            s_colliderJobs.Clear();
            s_propColliders = new GameObject("PropColliders").transform; // world scale 1, unrotated

            DressCampsites(deco.transform);
            DressStandingStones(deco.transform);
            DressWaystation(deco.transform);
            DressDeadTree(deco.transform);
            DressGroves(deco.transform);
            DressPockets(deco.transform);
            DressClouds(deco.transform);

            int propColliders = BuildPropColliders();

            BuildMarkers();
            BuildLighting();
            BuildAtmosphere();

            Directory.CreateDirectory(SceneDir);
            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, CliffHexScenePath);
            AssetDatabase.SaveAssets();

            Debug.Log($"[Tarrock] Cliff hex terrain built into {CliffHexScenePath}: {tileCount} tiles " +
                $"({wallCount} sealed as walls, {rampCount} ramps), {slabCount} underside/skirt slabs, " +
                $"{propColliders} prop colliders. Run 'Install Player In Cliff Hex' next.");
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
                float gy = FloorLevelAt(xz.x, xz.y) * StepWorld;
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

                // A tent, canted and weathered. Camp 1 holds the player spawn ~0.4 hex west of the
                // fire — its tent sits a step further out so the spawn never lands inside the tent's
                // (now solid) collider.
                Vector3 tentPos = i == 0 ? new Vector3(1.5f, 0f, 0.9f) : new Vector3(0.9f, 0f, 0.4f);
                Place(camp.transform, DecoDir + "/" + tents[0], tentPos,
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

            // Camp 6's micro-setting: a rock outcrop it is tucked against (north flank), so the last
            // camp reads as sheltered rather than sitting in the open.
            Vector2 c6 = CampXZ[5];
            float oy = FloorLevelAt(c6.x, c6.y) * StepWorld;
            var outcrop = new GameObject("Camp6_Outcrop");
            outcrop.transform.SetParent(camps.transform, false);
            outcrop.transform.localPosition = new Vector3(c6.x - 1.5f, oy, c6.y + 3.2f) / ParentScale;
            var orn = new System.Random(4211);
            string[] boulders =
            {
                DecoDir + "/nature/rock_single_D.fbx", DecoDir + "/nature/rock_single_E.fbx",
                DecoDir + "/nature/rock_single_C.fbx",
            };
            for (int b = 0; b < 4; b++)
            {
                float a = b * 1.4f;
                var lp = new Vector3(Mathf.Cos(a) * (0.9f + b * 0.35f), 0f, Mathf.Sin(a) * 0.7f);
                GameObject g = Place(outcrop.transform, boulders[orn.Next(boulders.Length)], lp,
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
            // The White Rose stand-in regrows at the basin (progression.md §The White Rose).
            // Quaternius prefabs bake a 100× root scale, so these need large absolute scales
            // (unlike the natural-scale-1 KayKit props).
            Place(group.transform, QuatDir + "/Flower_1_Clump.fbx", new Vector3(0.2f, 0f, 1.1f),
                new Vector3(270f, 0f, 0f), 32f, "WhiteRose_StandIn", false);
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
        }

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
                    DecoDir + "/nature/trees_A_medium.fbx",
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

                for (int i = 0; i < 3; i++)
                {
                    float a = (float)rnd.NextDouble() * Mathf.PI * 2f;
                    var lp = new Vector3(Mathf.Cos(a) * 2.6f, 0f, Mathf.Sin(a) * 2.6f);
                    Place(pk.transform, ForestDir + "/Bush_2_A_Color1.fbx", lp,
                        new Vector3(0f, rnd.Next(0, 360), 0f), 1.2f, $"bush_{i}", false);
                }
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

            int kind = ColliderKind(assetPath);
            if (kind != 0 && s_colliderJobs != null)
            {
                s_colliderJobs.Add((g, kind));
            }

            return g;
        }

        // Which collider a dressing asset gets (0 = none/walk-through). The director walked through
        // everything; trees/posts collide on the trunk only, the well/tents get boxes, everything
        // solid gets a shrunk box, and ground scatter (grass, flowers, drifting cloud) stays passable.
        private static int ColliderKind(string path)
        {
            if (path.Contains("Grass") || path.Contains("Flower") || path.Contains("cloud"))
            {
                return 0;
            }

            if (path.Contains("tree") || path.Contains("Tree") || path.Contains("flag"))
            {
                return 2; // trunk / flagpole capsule — collide the trunk, walk under the canopy
            }

            if (path.Contains("building_well"))
            {
                return 3; // the well: box, minimal shrink
            }

            return 1; // bushes, rocks, stones, tents, barrels, crates, sacks, buckets, lumber, cairns
        }

        // Resolves every staged collider job into the PropColliders root. Runs after all dressing so
        // props that the caller rescales post-Place (menhirs, boulders, seats) have final bounds.
        private static int BuildPropColliders()
        {
            int made = 0;
            foreach ((GameObject go, int kind) in s_colliderJobs)
            {
                if (go == null)
                {
                    continue;
                }

                Renderer[] rs = go.GetComponentsInChildren<Renderer>();
                if (rs.Length == 0)
                {
                    continue;
                }

                Bounds b = rs[0].bounds;
                for (int i = 1; i < rs.Length; i++)
                {
                    b.Encapsulate(rs[i].bounds);
                }

                if (b.size.x <= 0.001f && b.size.y <= 0.001f && b.size.z <= 0.001f)
                {
                    continue;
                }

                var col = new GameObject($"col_{go.name}");
                col.transform.SetParent(s_propColliders, false);
                col.transform.position = b.center;
                col.transform.rotation = Quaternion.identity;
                col.transform.localScale = Vector3.one;
                col.isStatic = true;

                if (kind == 2)
                {
                    // Trunk / post capsule: radius a fraction of the footprint (trunk, not canopy).
                    var cap = col.AddComponent<CapsuleCollider>();
                    cap.direction = 1; // world +Y (col is unrotated)
                    cap.radius = Mathf.Max(0.05f, Mathf.Min(b.size.x, b.size.z) * 0.16f);
                    cap.height = b.size.y;
                    cap.center = Vector3.zero;
                }
                else
                {
                    var box = col.AddComponent<BoxCollider>();
                    box.size = b.size * (kind == 3 ? 0.92f : 0.85f); // ×0.85 → forgiving to brush past
                    box.center = Vector3.zero;
                }

                made++;
            }

            return made;
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

            float pivotHeight = playerHeight * CamPivotFactor;
            float orbitRadius = playerHeight * CamRadiusFactor;

            var vcamGo = new GameObject("PlayerFollowCamera");
            vcamGo.transform.SetParent(cameraRig.transform, false);
            var vcam = vcamGo.AddComponent<CinemachineCamera>();
            vcam.Follow = followTarget;
            vcam.LookAt = followTarget;
            vcam.Lens.FieldOfView = 55f;

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

            // The wide tilt range (CamVerticalMin) can sweep the camera toward the meadow floor or
            // the gorge walls; the deoccluder nudges it out of geometry instead of letting it clip
            // under the grass when the player looks fully up.
            var deoccluder = vcamGo.AddComponent<CinemachineDeoccluder>();
            deoccluder.CollideAgainst = 1; // Default layer: terrain, walls, prop colliders
            deoccluder.IgnoreTag = PlayerTag;
            deoccluder.AvoidObstacles.Enabled = true;
            deoccluder.AvoidObstacles.CameraRadius = 0.1f;
            deoccluder.AvoidObstacles.DistanceLimit = orbitRadius;
            // Slide around obstacles at range rather than zooming into the Fool's back.
            deoccluder.AvoidObstacles.Strategy =
                CinemachineDeoccluder.ObstacleAvoidance.ResolutionStrategy.PreserveCameraDistance;

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
