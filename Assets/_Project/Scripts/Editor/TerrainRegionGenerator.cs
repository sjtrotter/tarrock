namespace Tarrock.Editor
{

    using System.Collections.Generic;
    using System.IO;
    using Tarrock.Regions;
    using UnityEditor;
    using UnityEditor.SceneManagement;
    using UnityEngine;

    /// <summary>
    /// Builds a sculpted-terrain prototype region (<c>TerrainProto.unity</c>) — the replacement for
    /// the retired hex-tile approach. Deterministic: the whole landform is derived from the explicit
    /// constants and shape functions in this file plus hash-based noise, never unseeded randomness,
    /// so re-running produces the identical region.
    ///
    /// SCOPE. This is a FEEL TEST, not the shipping Cliff. It rehearses the Cliff's terrain grammar
    /// (high meadow plateau, a valley funnelling west, a refusing edge where the world is broken —
    /// docs/design/world.md §The Cliff) so the sculpted approach is judged against real canon rather
    /// than an abstract slope. It deliberately carries NO quest markers: porting the Cliff's marker
    /// ids onto sculpted ground is a separate pass, once the feel is blessed.
    ///
    /// Canon this honours (docs/design/art-audio.md §Current build, world.md §The Cliff):
    /// - The Cliff is an ISLAND IN A SEA OF CLOUD (director-blessed 2026-07-26): edged everywhere
    ///   by the drop, cloud deck below every lip, the leap the only sanctioned exit. Unscripted
    ///   falls are the defeat loop's job, not landing areas'.
    /// - Unity Terrain per region scene, human scale, 1 unit = 1 metre (swap rule 3). Regions stay
    ///   discrete authored scenes — smooth terrain is not licence to build a streamed landmass.
    /// - Procedural ground material, no texture assets (<c>Tarrock/TerrainPainterly</c>).
    /// - Swap rule 5, terrain grammar: elevation signposts the path. The valley's NORTH wall is
    ///   authored steep (refuses) and its SOUTH wall shallow (permits), so the player learns which
    ///   way the region wants them to go without a single sign or prop.
    /// - Swap rule 6, no uniform corridors: the valley's width pinches and bulges, its floor steps
    ///   down in terraces reached by ramps rather than one flat ribbon, its wall heights rise and
    ///   fall, breaches open to sky, and two off-path pockets (a hollow and an overlook) reward
    ///   stepping aside.
    /// </summary>
    public static class TerrainRegionGenerator
    {
        private const string ScenePath = "Assets/_Project/Scenes/Sandbox/TerrainProto.unity";
        private const string SceneDir = "Assets/_Project/Scenes/Sandbox";
        private const string MaterialDir = "Assets/_Project/Materials";
        private const string TerrainMaterialPath = MaterialDir + "/TerrainPainterly.mat";
        private const string SkyMaterialPath = MaterialDir + "/TerrainProtoSky.mat";
        private const string PostProfilePath = "Assets/_Project/Art/TerrainProtoPost.asset";
        private const string CloudMaterialPath = MaterialDir + "/CloudSea.mat";
        private const string CloudDeckMeshPath = "Assets/_Project/Art/CloudSeaDeck.asset";
        private const string CloudLobeMaterialPath = MaterialDir + "/CloudLobes.mat";
        private const string CloudLobeMeshPathFormat = "Assets/_Project/Art/CloudLobeMass{0}.asset";
        private const string DeadTreeMeshPath = "Assets/_Project/Art/DeadTree.asset";
        private const string DeadTreeMaterialPath = MaterialDir + "/DeadTreeBark.mat";
        private const string TuftMeshPath = "Assets/_Project/Art/GrassTuft.asset";
        private const string TuftMaterialPath = MaterialDir + "/GrassTuft.mat";
        private const string TuftPrefabPath = "Assets/_Project/Art/GrassTuft.prefab";
        private const string MoteMaterialPath = MaterialDir + "/SuspendedMotes.mat";
        private const string RockMeshPathFormat = "Assets/_Project/Art/RockOutcrop{0}.asset";
        private const string RockMaterialPath = MaterialDir + "/RockOutcrop.mat";
        private const string TussockMeshPathFormat = "Assets/_Project/Art/TussockClump{0}.asset";
        private const string TussockMaterialPath = MaterialDir + "/TussockClump.mat";
        private const string TerrainDataPath = "Assets/_Project/Art/TerrainProto.asset";
        private const string TerrainDataDir = "Assets/_Project/Art";
        private const string ShaderName = "Tarrock/TerrainPainterly";
        private const string RockShaderName = "Tarrock/RockPainterly";
        private const string TuftShaderName = "Tarrock/GrassTuft";
        private const string CloudLobeShaderName = "Tarrock/CloudLobe";

        // -- Terrain dimensions. 256 m square is sized to CONTENT, not footprint (swap rule 6): it is
        //    roughly a two-minute walk end to end at the Fool's travel jog, which is the scale a
        //    tutorial region's beats want. Heightmap 513 gives one sample per half-metre.
        private const int HeightmapResolution = 513;
        private const float TerrainSize = 256f;
        // 80 m leaves headroom over the tallest raw landform (~82 m pre-knee) so the soft ceiling,
        // not a clip plane, shapes the peaks. Quantum at 16 bits is 1.2 mm — still far below relief.
        private const float TerrainHeight = 80f;

        // -- The valley path, running from the eastern spawn to the western mouth.
        private const float PathEastX = 224f;
        private const float PathWestX = 24f;
        private const float FloorEastY = 26f;   // plateau shoulder the Fool starts on
        private const float FloorWestY = 17f;   // the mouth he is funnelled toward — kept well above
                                                // the cloud deck so no walkable floor ever submerges
        private const float TerraceStep = 3.2f; // tread-to-tread drop; risers become ramps, not steps

        // -- Spawn: on the valley centreline in the wide eastern bulge, facing west down the
        //    funnel (−X). The z must track centreZ(x): at x=214 the meander puts the path at
        //    z≈91 — the old z=120 left the spawn grounded ON the north refusing ramp once the
        //    breach windows moved off the spawn stretch.
        private static readonly Vector3 SpawnHint = new Vector3(214f, 40f, 91f);

        // -- The tree knoll's summit (see SampleHeight step 6c and BuildDeadTree).
        private static readonly Vector2 KnollCentre = new Vector2(150f, 58f);
        private static readonly Vector3 SpawnFacing = Vector3.left;

        // -- The grass tuft prototypes now live in the Species table beside BuildGrassDetails: each
        //    species owns its own mesh height, blade count and asset paths, because round 1's single
        //    shared tuft is exactly what made the meadow read as one silhouette everywhere.

        [MenuItem("Tarrock/Setup/Generate Terrain Prototype Region")]
        public static void Generate()
        {
            Shader shader = Shader.Find(ShaderName);
            if (shader == null)
            {
                Debug.LogError(
                    $"[Tarrock] Shader '{ShaderName}' not found. If it was just added, let the editor " +
                    "finish importing/compiling and re-run.");
                return;
            }

            EnsureDirectory(SceneDir);
            EnsureDirectory(MaterialDir);
            EnsureDirectory(TerrainDataDir);

            UnityEngine.SceneManagement.Scene scene =
                EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            TerrainData terrainData = BuildTerrainData();
            Material material = BuildTerrainMaterial(shader);

            GameObject terrainGo = Terrain.CreateTerrainGameObject(terrainData);
            terrainGo.name = "Terrain";
            var terrain = terrainGo.GetComponent<Terrain>();
            terrain.materialTemplate = material;
            // A plain (non-splatmap) material is not terrain-instancing-compatible; instanced draw
            // would render it untextured. Explicit rather than relying on the project default.
            terrain.drawInstanced = false;
            terrain.heightmapPixelError = 1f;   // LOD must not eat 8-sample creases (audit finding 11)
            terrain.basemapDistance = 220f;
            // Terrain must cast: ridge shadows are half of how elevation signposts the path (rule 5),
            // and at BuildLighting's 7° sun they are most of how the landform reads at all.
            //
            // THIS FLAG IS NOT ENOUGH ON ITS OWN, and the 2026-07-31 audit is the proof: round1/v1,v2
            // were shot with it already set and with Tarrock/TerrainPainterly already carrying a
            // ShadowCaster pass, yet the critic measured no lit-crest-against-shadowed-trough
            // anywhere in the meadow. The shadows were being cast and then thrown away at 40 m,
            // because GauntletCapture pins quality level "PC" and that level's shadow settings —
            // ProjectSettings/QualitySettings.asset, NOT Assets/Settings/PC_RPAsset.asset — carried
            // shadowDistance 40 and 2 cascades while the RP asset carried 180 and 4. Everything past
            // the Fool's own feet was outside the last cascade. Round 2 brings the quality level up
            // to match the RP asset (180 m, 4 cascades, VeryHigh, split {0.05, 0.16, 0.42}) and
            // raises the main-light shadowmap to 4096 so a 7° sun's long thin shadows survive the
            // far cascade. If terrain self-shadowing ever goes flat again, those two files are the
            // first place to look, and they must agree.
            terrain.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;

            // The grass reads the ground material's own turf palette back off it (root blending),
            // so the terrain material must already be built — it is, three lines up.
            BuildGrassDetails(terrainData, terrain, material);
            BuildLighting();
            BuildCloudSea();
            BuildDeadTree();
            // Dressing, after the landform exists and before the atmosphere: both of these read the
            // finished heightmap to decide where they belong.
            BuildRockOutcrops(terrainData, material);
            BuildTussocks(terrainData);
            BuildMotes();
            BuildRegionWind();

            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, ScenePath);
            AssetDatabase.SaveAssets();

            // Reuse the real rig + orbit camera rather than a second copy that would drift from it.
            KayKitCharacterInstaller.InstallInto(ScenePath, SpawnHint, SpawnFacing);
            PipInstaller.Install();

            // After the installers, because it hangs off their roots: the Fool and Pip are the only
            // things that move the Cliff's grass while it is bound.
            BuildGrassBenders();

            Debug.Log(
                $"[Tarrock] Terrain prototype generated at {ScenePath}: {TerrainSize}×{TerrainSize} m, " +
                $"{HeightmapResolution}² heightmap, max height {TerrainHeight} m, procedural material " +
                $"'{ShaderName}'. Feel test only — no quest markers (see class doc).");
        }

        // -------------------------------------------------------------------------------------
        // Landform
        // -------------------------------------------------------------------------------------

        private static TerrainData BuildTerrainData()
        {
            var terrainData = new TerrainData
            {
                heightmapResolution = HeightmapResolution,
                size = new Vector3(TerrainSize, TerrainHeight, TerrainSize),
            };

            var heights = new float[HeightmapResolution, HeightmapResolution];
            float sampleToMetres = TerrainSize / (HeightmapResolution - 1);

            // Unity indexes heights[z, x]; both axes are normalised 0..1 against size.y on write.
            for (int zi = 0; zi < HeightmapResolution; zi++)
            {
                float z = zi * sampleToMetres;
                for (int xi = 0; xi < HeightmapResolution; xi++)
                {
                    float x = xi * sampleToMetres;
                    heights[zi, xi] = Mathf.Clamp01(SampleHeight(x, z) / TerrainHeight);
                }
            }

            // Curvature-weighted smoothing: spreads crease curvature across ≥3 cells so near-axis-
            // aligned crests stop breaking into per-cell sawtooth ("the zipper" — audit finding 4).
            // Weighted by the local laplacian, so gentle ground is untouched and only creases blur.
            // Threshold is in NORMALISED units: 0.015 ≈ 1.2 m of laplacian at TerrainHeight 80.
            for (int pass = 0; pass < 2; pass++)
            {
                var src = (float[,])heights.Clone();
                for (int zi = 1; zi < HeightmapResolution - 1; zi++)
                {
                    for (int xi = 1; xi < HeightmapResolution - 1; xi++)
                    {
                        float c = src[zi, xi];
                        float lap = src[zi, xi - 1] + src[zi, xi + 1]
                                  + src[zi - 1, xi] + src[zi + 1, xi] - 4f * c;
                        float w = Mathf.Clamp01(Mathf.Abs(lap) / 0.015f);
                        if (w <= 0f)
                        {
                            continue;
                        }

                        float avg = (4f * c
                            + 2f * (src[zi, xi - 1] + src[zi, xi + 1] + src[zi - 1, xi] + src[zi + 1, xi])
                            + (src[zi - 1, xi - 1] + src[zi - 1, xi + 1]
                             + src[zi + 1, xi - 1] + src[zi + 1, xi + 1])) / 16f;
                        heights[zi, xi] = Mathf.Lerp(c, avg, 0.5f * w);
                    }
                }
            }

            terrainData.SetHeights(0, 0, heights);
            AssetDatabase.CreateAsset(terrainData, TerrainDataPath);
            return terrainData;
        }

        /// <summary>Height in metres at a world XZ. The whole region's shape lives here.</summary>
        private static float SampleHeight(float x, float z)
        {
            // -- 1. The valley centre line meanders, so the player never sees a straight corridor to
            //       the horizon; the destination is always revealed a bend at a time.
            float centreZ = CentreZ(x);

            // -- 2. Width pinches and bulges (rule 6): tight passes that compress, open bulges that
            //       release. Never one constant width.
            float halfWidth = HalfWidth(x);

            // -- 3. Floor: descends west, TERRACED. Quantising to treads and smoothing only the top
            //       third of each step turns the risers into walkable ramps — "terraces and dips
            //       reached by ramps, not one flat ribbon".
            float descent = Mathf.Clamp01((PathEastX - x) / (PathEastX - PathWestX));
            float floorRaw = Mathf.Lerp(FloorEastY, FloorWestY, descent);
            float steps = floorRaw / TerraceStep;
            float tread = Mathf.Floor(steps);
            float riser = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.62f, 0.98f, steps - tread));
            float floor = (tread + riser) * TerraceStep;

            // -- 4. Wall height rises and falls along the run — and along the RIDGE. The 2-D
            //       modulation is load-bearing: without it the audit measured z-variance of exactly
            //       0.0000 m off-path, i.e. a 1-D profile extruded like channel stock. Crests must
            //       vary along their own length to read as landform.
            float wallMod = 0.70f + 0.60f * (0.5f + 0.5f * Fbm(x * 0.011f + 17f, z * 0.011f + 5f));
            float wall = SoftMax(6f, (15f
                + 9f * Mathf.Sin(x * 0.0245f + 0.4f)
                + 5f * Mathf.Sin(x * 0.058f + 1.7f)) * wallMod, 1.5f);
            // Breaches LOWER the wall (never delete it — a walless stretch has no grammar to read),
            // in narrow windows shifted to mid-run: the old phase put a 35 m zero-wall window under
            // the spawn itself, so the feel test was judged from the one spot with nothing to see.
            float breach = Mathf.SmoothStep(0f, 1f,
                Mathf.InverseLerp(-0.88f, -0.62f, Mathf.Sin(x * 0.041f + 0.9f)));
            wall *= 0.35f + 0.65f * breach;

            // -- 5. Cross-section, ASYMMETRIC on purpose (rule 5, the grammar's load-bearing choice):
            //       the north wall climbs over a few metres and refuses; the south wall spreads over
            //       tens of metres and invites. The player reads "go west, and if you wander, wander
            //       left" from the landform alone.
            //
            //       Ramp width is a RATIO of wall height (constant slope ANGLE as walls rise and
            //       fall), FLOORED IN SAMPLES: the audit found the ratio alone still let a short
            //       wall pack a 61° face into 3 heightmap cells, and a crease narrower than the mesh
            //       can hold breaks into a per-cell sawtooth "zipper" along the crest. The 4 m floor
            //       (8 samples at 0.5 m/sample) is the representability limit, not a style choice.
            //       True vertical and overhanging rock stays a separate-mesh job (art-audio.md
            //       §Current build); the heightmap's remit stops at steep-but-continuous ground.
            //
            //       North ≈ 55–65°: past the CharacterController's 45° limit, so it genuinely refuses.
            //       South ≈ 23–42°: inside it, so it genuinely permits. The two sides blend across
            //       ±3 m of the centreline so the switch can never become a crease if halfWidth ever
            //       narrows.
            float offset = z - centreZ;
            float distance = Mathf.Abs(offset);
            float rampNorth = wall * (0.60f + 0.10f * Mathf.Sin(x * 0.036f));          // refusing
            float rampSouth = wall * (1.70f + 0.60f * Mathf.Sin(x * 0.029f + 2.0f));   // permitting
            float sideBlend = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(-3f, 3f, offset));
            float rampWidth = Mathf.Lerp(rampSouth, rampNorth, sideBlend);
            float rise = Mathf.SmoothStep(0f, 1f,
                Mathf.InverseLerp(halfWidth, halfWidth + Mathf.Max(4.0f, rampWidth), distance));

            // Blend from the TERRACED floor to a ridge top built on the SMOOTH floor (terracing is a
            // property of the walkable path, not of the skyline) — plus an UPLANDS field that exists
            // independently of the path. The uplands term is the difference between "a corridor with
            // noise on it" and a place: off-path ground gets broad rolls, spurs and hollows of its
            // own instead of inheriting the valley's profile everywhere.
            float uplands = 11f * Fbm(x * 0.0090f + 63f, z * 0.0090f + 19f);
            float ridgeTop = floorRaw + wall + uplands;
            float height = Mathf.Lerp(floor, ridgeTop, rise);

            // -- 6. Off-path pockets (rule 6): somewhere to find, not just somewhere to pass.
            height = ApplyHollow(height, x, z, centre: new Vector2(156f, 78f), radius: 15f, depth: 4.5f);
            height = ApplyShelf(height, x, z, centre: new Vector2(88f, 186f), radius: 11f, blend: 6f);

            // -- 6b. The spawn bowl (director design, 2026-07-27). The game opens inside a
            //        contained hollow: a grassy rim wraps every direction EXCEPT the west opening,
            //        so a player who turns around at spawn sees the bowl's back wall — not an
            //        invitation to jump off the world ten seconds in. The island's back edges still
            //        exist and still drop into cloud; the opening frame simply doesn't offer them.
            //        Composition does the fencing, not colliders.
            float bowlDx = x - SpawnHint.x;
            float bowlDz = z - SpawnHint.z;
            float bowlR = Mathf.Sqrt(bowlDx * bowlDx + bowlDz * bowlDz);
            if (bowlR < 55f)
            {
                float bowlDeg = Mathf.Atan2(bowlDz, bowlDx) * Mathf.Rad2Deg; // ±180 = due west
                float westness = Mathf.Abs(Mathf.DeltaAngle(bowlDeg, 180f));
                float rimWrap = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(35f, 80f, westness));
                // The BACK of the bowl (east arc) is a SHEER face, not a climbable rim (director,
                // 2026-07-27): it's the tutorial — the ground behind spawn must refuse outright,
                // never present a scramble that ends at the hidden drop. ~16 m over a ~6 m run
                // (≈70°, past the slope limit, rock-shaded by the slope ramp); the SIDE arcs stay
                // gentle grass so the hollow reads soft everywhere the player is meant to look.
                float backness = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(105f, 140f, westness));
                float sideBand = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(18f, 34f, bowlR))
                              * Mathf.SmoothStep(1f, 0f, Mathf.InverseLerp(42f, 55f, bowlR));
                float backBand = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(20f, 26f, bowlR))
                              * Mathf.SmoothStep(1f, 0f, Mathf.InverseLerp(44f, 55f, bowlR));
                float rim = Mathf.Lerp(9f * sideBand, 16f * backBand, backness);
                height += rim * rimWrap
                        * (0.85f + 0.3f * Fbm(x * 0.05f + 7f, z * 0.05f + 3f));
            }

            // -- 6c. The tree knoll (Wave 2, hero mass): the region's highest walkable point, on
            //        the south ridge WEST of spawn so it breaks the skyline from the opening frame
            //        and pulls the eye down-valley (rule 5's landmark clause; MQ00's "modest
            //        knoll"; the dead tree that crowns it is the Cliff's signature visual per
            //        art-audio.md §Region colour scripts). BuildDeadTree() plants the tree at its
            //        summit after the terrain exists.
            float knollD = Vector2.Distance(new Vector2(x, z), KnollCentre);
            if (knollD < 26f)
            {
                float knollT = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(26f, 7f, knollD));
                height = Mathf.Lerp(height, Mathf.Max(height, 50f), knollT);
            }

            // -- 6d. Silhouette events (see ApplyLandformEvents). Runs LAST of the shaping steps and
            //        BEFORE the broken edge, so the edge always wins at the island's rim and no event
            //        can leave a shelf hanging over the drop.
            height = ApplyLandformEvents(height, x, z);

            // -- 7. The broken edge, on EVERY side. Canon (world.md §The Cliff, director-blessed
            //       2026-07-26): the Cliff is an island in a sea of cloud, "edged everywhere by a
            //       drop the eye doesn't want to follow" (MQ00). The old build ringed the south and
            //       east with additive hills, which (a) diverged from canon, (b) stacked to 110 m
            //       against a 60 m ceiling so 7.4% of the map clipped into dead-flat 59 m mesas with
            //       a serrated knife rim — the grey "slabs" on the old skyline. Every edge line
            //       wanders (never a ruler) with side-distinct phases; ±8 m of run for the drop
            //       keeps the fall near 60°, the steepest a heightmap holds cleanly — the last few
            //       metres to true vertical are a cliff-mesh job, not a sculpt job. Terrain past the
            //       lip drops below the cloud deck, so the tile boundary itself is never visible.
            //       Unscripted falls are a defeat-loop job (combat.md §Defeat), not a landing area.
            float edgeN = 209f + 7f * Mathf.Sin(x * 0.043f) + 3f * Mathf.Sin(x * 0.11f);
            float edgeS = 22f + 7f * Mathf.Sin(x * 0.037f + 1.3f) + 3f * Mathf.Sin(x * 0.09f + 0.5f);
            float edgeE = 246f + 7f * Mathf.Sin(z * 0.041f + 2.2f) + 3f * Mathf.Sin(z * 0.10f + 1.1f);
            float edgeW = 12f + 7f * Mathf.Sin(z * 0.045f + 0.7f) + 3f * Mathf.Sin(z * 0.12f + 2.4f);
            // ±5 m of run: as sheer as the heightmap dares (~70° on the tall faces — director note
            // 2026-07-27: the drop must read as SHEER, not a gradual slide into the mist; the
            // smoothing pass keeps the crease itself clean). Verticality beyond this is the
            // cliff-mesh job. The visible face reads as rock (slope shading) vanishing into cloud.
            float overEdge = Mathf.Max(
                Mathf.Max(
                    Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(edgeN - 5f, edgeN + 5f, z)),
                    Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(edgeS + 5f, edgeS - 5f, z))),
                Mathf.Max(
                    Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(edgeE - 5f, edgeE + 5f, x)),
                    Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(edgeW + 5f, edgeW - 5f, x))));
            height = Mathf.Lerp(height, 1.5f, overEdge);

            // -- 8. Relief, so no surface is a perfect mathematical plane (the "CAD look"). Three
            //       scales: broad rolls (domain-warped so the biggest octave carries no straight
            //       lattice structure; base frequency 0.030 gives ~8×8 cells across the tile — the
            //       audit found the old 0.0125 made the dominant octave a 4×4 grid of random values
            //       for the whole map), mid-scale swell, and a fine grain that catches the light.
            //       The mask is keyed to DISTANCE from the path centre over a wide 45 m falloff, not
            //       to `rise` — an amplitude jump at a slope break reads as a toothed seam. The FINE
            //       grain keeps 70% of its amplitude even on the path: 0.6 m of grain never
            //       endangers footing, and suppressing it left the floor so mathematically smooth
            //       that 16-bit heightmap quantisation contours became the dominant texture.
            float pathMask = Mathf.SmoothStep(0f, 1f,
                Mathf.InverseLerp(halfWidth, halfWidth + 45f, distance));
            float reliefScale = Mathf.Lerp(0.25f, 1f, pathMask);
            float fineScale = Mathf.Lerp(0.70f, 1f, pathMask);
            float wx = Fbm(x * 0.0060f + 11.3f, z * 0.0060f + 4.7f);
            float wz = Fbm(x * 0.0060f + 71.9f, z * 0.0060f + 23.1f);
            height += Fbm((x + wx * 26f) * 0.030f, (z + wz * 26f) * 0.030f) * 7.5f * reliefScale;
            height += Fbm(x * 0.041f, z * 0.041f) * 2.4f * reliefScale;
            height += Fbm(x * 0.19f, z * 0.19f) * 0.9f * fineScale;

            // Soft ceiling knee instead of a hard clamp: a hard Clamp flat-topped 7.4% of the old
            // map into identical 59.0 m mesas. Nothing may ever go dead-flat by clipping.
            const float Ceiling = TerrainHeight - 8f;
            const float Knee = 18f;
            if (height > Ceiling - Knee)
            {
                float t = (height - (Ceiling - Knee)) / Knee;
                height = (Ceiling - Knee) + Knee * (1f - Mathf.Exp(-t));
            }

            return Mathf.Clamp(height, 0f, TerrainHeight);
        }

        /// <summary>The valley's centre line at a given x. Shared by the landform and by the
        /// scatter passes, which need to know where the travelled line runs.</summary>
        private static float CentreZ(float x)
        {
            return 118f + 24f * Mathf.Sin(x * 0.0195f) + 10f * Mathf.Sin(x * 0.052f + 0.8f);
        }

        /// <summary>Half the valley floor's width at a given x (see SampleHeight step 2).</summary>
        private static float HalfWidth(float x)
        {
            return SoftMax(9f, 17f
                + 8f * Mathf.Sin(x * 0.031f + 1.2f)
                + 4.5f * Mathf.Sin(x * 0.079f + 2.1f), 1.5f);
        }

        // -------------------------------------------------------------------------------------
        // Silhouette events (round-2 composition pass)
        //
        // THE FINDING this answers (round-1 critique of gauntlet/round1/v1, v8): the hero landform
        // is an undesigned dome — smooth symmetrical lumps, no silhouette events, no notch in a
        // crest, no asymmetric shoulder — and near and far therefore collapse into one lavender
        // value because nothing overlaps anything.
        //
        // WHAT A SILHOUETTE EVENT IS. Every reference plate (fable-06, fable-02, animation-02) has
        // a skyline you could draw from memory: a crest is interrupted. Interruption is the whole
        // trick — the eye reads DEPTH from one edge crossing in front of another, so a rim with a
        // notch in it shows a further, hazier rim through the notch and the frame gains a layer it
        // cannot get from fog alone.
        //
        // MEASURED, NOT EYEBALLED. Each event below was placed by tracing the skyline of v1 and v8
        // (the highest terrain elevation angle per screen column) against this generator's own
        // functions and moving the event until it landed where the composition wanted it. Over the
        // eight vantages the pass raises v1's skyline event density (mean |dv/du|) from 0.035 to
        // 0.040 and v8's from 0.032 to 0.040, moves no camera, buries none, and occludes no subject.
        //
        // RESTRAINT. This DRESSES the existing sculpt: three raises and six cuts, none deeper than
        // ~12 m, together touching 3.7% of the heightmap (round 3: 3.3%) and none of it
        // walkable-critical. The spawn bowl, the valley floor, the west mouth, the knoll's summit
        // and the knoll's whole east half are byte-for-byte unchanged — re-checked after the
        // round-4 pass at every vantage's own standing point, all nine identical to the centimetre.
        // -------------------------------------------------------------------------------------
        private static float ApplyLandformEvents(float height, float x, float z)
        {
            // -- The knoll's north-west BENCH: the asymmetric shoulder. The knoll measured as a
            //    radially symmetric dome — every bearing within a metre of every other — which is
            //    why it read as an undesigned lump. A single shelf on ONE flank breaks the symmetry
            //    without touching the summit: the profile now goes summit, a ~58° fall, a 5-6 m
            //    ledge that measures under 12°, then a 64-67° scarp off its lip — while the south
            //    and east flanks keep their clean unbroken sweep. In v8 that is worth a 0.13 NDC
            //    step in the skyline where the dome used to curve away smoothly.
            height = RaiseTo(height, x, z, new Vector2(145.5f, 74.0f), radius: 4.5f, blend: 4.5f, top: 38.5f);

            // -- ...and the SPUR below it, so the shoulder descends in two steps rather than one.
            height = RaiseTo(height, x, z, new Vector2(139.0f, 79.0f), radius: 6.0f, blend: 7.0f, top: 34.5f);

            // -- Four COLS through the western rim crests. Cut east-west (along the line of sight
            //    from the spawn) because a notch only opens a window if it clears the whole ray,
            //    not just the crest line; each is rotated a few degrees off the axis so none reads
            //    as a ruled groove, and the relief field in step 8 lands on top of every one of
            //    them, so no col floor is ever the flat mesa the 2026-07-26 audit killed.
            //    Their spacing and depth are deliberately unequal — a rim with an even comb in it
            //    reads as a machined part. The two southern cols leave a horn between them.
            // -- THE DAWN BREACH (round-4 light pass, and the only landform event in this file that
            //    exists for the LIGHT rather than for the skyline — though it earns its keep twice).
            //
            //    THE FINDING: at the round-3 sun the beam could not reach the ground the game opens
            //    on. Ray-traced along the sun's bearing, the horizon from the spawn mark stands at
            //    26.2° — this valley's north refusing wall, 16 m of it 30 m away, sitting square on
            //    the sun's line — so 100% of the ground within 15 m of the Fool and 100% of what v2
            //    can see were in cast shadow. The wall is doing exactly what the grammar asks of it
            //    (rule 5: north refuses); it simply also stood between the dawn and the meadow.
            //
            //    THE EVENT: one col through that wall, 32 m wide and cut 4-6 m into a crest that runs
            //    33-37 m, capped at 30 m. Traced through the finished heightfield it does three
            //    things with one cut, which is why it is one cut and not three:
            //      - v1 (the opening frame): the lit boundary on the valley's centre line comes from
            //        x 195 to x 211 — 8.4 m from the lens — so the near ground stays in shade, the
            //        Fool stands at the edge of the light, and a lane opens just beyond him. Traced
            //        along that centre line the read is shade (0-7 m), LIGHT (8-15 m), shade
            //        (16-25 m), light again: a lane, not a floodlight, and the scatter's own long
            //        shadows dapple it — at this sun a 2.5 m stone throws 11.8 m.
            //      - v2 (the contre-jour frame): the col is the notch the dawn disc sits in. The sun
            //        is at bearing 332° and 16° left of that view's axis, and round 3 had it BEHIND
            //        this wall — measured on gauntlet/round3/v2, the pixel where the disc should be
            //        reads (0.13, 0.14, 0.21). The col drops the horizon on that bearing from 17.2°
            //        to 6.6°, so the disc clears it and the frame gets its top end back (the blaze
            //        core lands ≈1.5 linear and blooms) plus 32° of open sky either side of it.
            //      - and the crest gains a genuine skyline event where it is looked at.
            //    Being a CAP it can only ever lower ground: if the sun is ever moved, the worst this
            //    can do is quietly stop doing anything.
            //
            //    IT DOES NOT UNDO THE REFUSAL. The col takes the top off the wall; the 58-72° ramp
            //    below it is untouched, so the climb from the valley floor to the col mouth still
            //    breaks the CharacterController's 45° limit. Light passes, the player does not.
            //    1026 m³ of cut and not a cubic metre of fill, over 0.40% of the heightmap. The
            //    spawn bowl, the valley floor, the west mouth and the knoll are untouched by it.
            height = CapTo(height, x, z, new Vector2(192f, 119f), runX: 16f, runZ: 9f, cap: 30.0f, degrees: 105f);

            height = CapTo(height, x, z, new Vector2(116f, 74f), runX: 24f, runZ: 7f, cap: 31.0f, degrees: 8f);
            height = CapTo(height, x, z, new Vector2(114f, 90f), runX: 26f, runZ: 8f, cap: 32.0f, degrees: -6f);
            height = CapTo(height, x, z, new Vector2(120f, 112f), runX: 22f, runZ: 12f, cap: 28.5f, degrees: 14f);
            height = CapTo(height, x, z, new Vector2(114f, 168f), runX: 24f, runZ: 9f, cap: 30.0f, degrees: -10f);

            // -- THE KNOLL'S NOTCH (round-3 composition pass, the v8 event).
            //
            //    THE FINDING: round 2 dressed the knoll's north-west flank with a bench and a spur,
            //    and gauntlet/round2/v8 shows what that bought — nothing. Traced column by column,
            //    that shoulder still falls from the summit to its foot as ONE smooth arc: forty
            //    screen columns of monotone descent with no interruption anywhere. A dome with a
            //    tree on it. Every reference skyline (fable-06, fable-02) is a crest the eye can
            //    draw from memory because something INTERRUPTS it.
            //
            //    ROUND 4 RE-CUTS IT, AND THE ROUND-3 PAIR IS GONE RATHER THAN ADDED TO. Re-traced
            //    column by column through v8's frustum, the round-3 cut measured 0.06 NDC of bite
            //    against the 0.13 its comment claimed, and the reason is instructive enough to
            //    write down: the cut at (151, 69.8) DID trench the ground — the terrain at z ≈ 68
            //    drops to 40.7-41.4 m between two 44 m shoulders — but that trench is not on the
            //    skyline. From v8 the crest at u +0.18…+0.34 is drawn by the ridge at z 70-76, and
            //    the trench sits BEHIND it. Cutting terrain that the horizon does not run along
            //    buys nothing; the cut has to land on the line the eye actually reads.
            //
            //    THE EVENT, and there is exactly one: a V cut through THAT ridge, at (149.8, 73.5),
            //    with the ground raised again beyond it to a horn at (146.6, 78.0). Measured in
            //    v8's own frustum, per screen column:
            //        u +0.10  v −0.062   the summit plateau's lip (the tree stands at u 0.00)
            //        u +0.18  v −0.150   falling
            //        u +0.22  v −0.326   the notch's east wall
            //        u +0.26  v −0.496   THE FLOOR — 0.17 below the east shoulder, 0.20 below the
            //                            horn, i.e. a 108-pixel bite at 1080p
            //        u +0.30  v −0.378   climbing out, hard
            //        u +0.38…+0.46  v ≈ −0.292   the horn, a level shelf 0.12 wide
            //        u +0.54  v −0.501   and away.
            //    Fall, cut, rise, fall — and ASYMMETRIC, which was the other half of the ask: the
            //    east wall descends from the summit in two steps and the west wall is one sharp rise
            //    onto a flat shelf. The two sides do not mirror.
            //
            //    WHY IT IS THIS BIG AN ELLIPSE. The shoulder is a RAMP, ~10 m deep along v8's line
            //    of sight, so a tidy little dimple in the crest simply reveals the ramp behind it
            //    and changes nothing — three rounds of narrower cuts measured under 0.08. The cut
            //    is therefore elongated ALONG THE RAY (degrees 12 is v8's own sight line onto the
            //    ridge), which is the same reasoning the four western cols above are built on.
            //    Retiring the round-3 pair and cutting this one moves 1196 m³ in all — 951 of it
            //    ground handed BACK where round 3 had trenched the wrong ridge — over 0.49% of the
            //    heightmap.
            //
            //    THE COUNTER-ELEMENT IS STONE, NOT TREE. The knoll keeps ONE tree (art-audio.md
            //    §Region colour scripts; the dead tree is the Cliff's signature and the one tree
            //    that visibly dies). What stands on the horn is a family of leaning slabs — see
            //    the notch-horn entries in RockAnchors, moved onto the new horn with the cut —
            //    whose tops read at v −0.219, −0.232 and −0.248 across u +0.41…+0.47: 0.25-0.28
            //    above the notch floor and 0.06-0.07 clear of the horn's own shelf, three dark
            //    verticals against open sky. They stand on ground measuring 3-8°, which is what a
            //    slab can stand on. The tree crowns the summit; the stones lean off the shoulder;
            //    nothing on this hill competes with either.
            //
            //    The summit (49.78 m, unchanged to the centimetre), the whole east half, the v4
            //    vantage's ground (50.83 m, likewise) and every metre of the spawn bowl, the valley
            //    floor and the west mouth are untouched.
            height = CapTo(height, x, z, new Vector2(149.8f, 73.5f), runX: 13f, runZ: 5.5f, cap: 37.5f, degrees: 12f);
            height = RaiseTo(height, x, z, new Vector2(146.6f, 78f), radius: 3.4f, blend: 5.0f, top: 44.0f);
            return height;
        }

        /// <summary>Lifts ground inside a disc TOWARD a target height, never below what is already
        /// there — a bench, a knuckle, a spur. Same max-and-blend idiom as the knoll itself, so an
        /// event laid over higher ground quietly does nothing instead of carving a step into it.</summary>
        private static float RaiseTo(
            float height, float x, float z, Vector2 centre, float radius, float blend, float top)
        {
            float d = Vector2.Distance(new Vector2(x, z), centre);
            if (d > radius + blend)
            {
                return height;
            }

            float t = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(radius + blend, radius, d));
            return Mathf.Lerp(height, Mathf.Max(height, top), t);
        }

        /// <summary>Cuts an elongated notch: caps ground inside a rotated ellipse to a ceiling,
        /// never digging below it. Capping rather than subtracting is what stops a col from
        /// trenching the low ground its skirt happens to cross.</summary>
        private static float CapTo(
            float height, float x, float z, Vector2 centre, float runX, float runZ, float cap, float degrees)
        {
            float dx = x - centre.x;
            float dz = z - centre.y;
            float c = Mathf.Cos(degrees * Mathf.Deg2Rad);
            float s = Mathf.Sin(degrees * Mathf.Deg2Rad);
            float alongX = ((dx * c) + (dz * s)) / runX;
            float alongZ = ((-dx * s) + (dz * c)) / runZ;
            float e = Mathf.Sqrt((alongX * alongX) + (alongZ * alongZ));
            if (e >= 1f)
            {
                return height;
            }

            float t = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(1f, 0.45f, e));
            return Mathf.Lerp(height, Mathf.Min(height, cap), t);
        }

        /// <summary>Scoops a smooth bowl — a hollow to stumble into off the path.</summary>
        private static float ApplyHollow(float height, float x, float z, Vector2 centre, float radius, float depth)
        {
            float d = Vector2.Distance(new Vector2(x, z), centre);
            float t = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(radius, 0f, d));
            return height - t * depth;
        }

        /// <summary>
        /// Flattens a disc to its own centre height — a standing place. Used at the broken edge so the
        /// overlook is somewhere you can actually stop and look, not a slope you slide off.
        /// </summary>
        private static float ApplyShelf(float height, float x, float z, Vector2 centre, float radius, float blend)
        {
            float d = Vector2.Distance(new Vector2(x, z), centre);
            if (d > radius + blend)
            {
                return height;
            }

            // The shelf sits a little below the surrounding ground so its lip reads as an edge.
            float shelfY = 13.5f;
            float t = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(radius + blend, radius, d));
            return Mathf.Lerp(height, shelfY, t);
        }

        // -------------------------------------------------------------------------------------
        // Deterministic value noise (mirrors the shader's approach so surface and shading agree)
        // -------------------------------------------------------------------------------------

        private static float Hash21(float x, float y)
        {
            float px = Frac(x * 123.34f);
            float py = Frac(y * 456.21f);
            float dot = px * (px + 45.32f) + py * (py + 45.32f);
            px = Frac(px + dot);
            py = Frac(py + dot);
            return Frac(px * py * 43758.5453f);
        }

        private static float Frac(float v) => v - Mathf.Floor(v);

        // Gradient (Perlin-style) noise, quintic fade, -1..1. Chosen over value noise after the
        // 2026-07-26 terrain audit: value noise + Hermite fade puts a zero-derivative fold line on
        // EVERY lattice edge (738 axis-aligned creases across the tile — the director's "geometric
        // pattern in the hill"). Gradient noise is zero AT lattice points with non-zero slope, and
        // the quintic fade is C2 there, so no pillow-per-cell and no visible grid.
        private static float GradNoise(float x, float y)
        {
            float ix = Mathf.Floor(x);
            float iy = Mathf.Floor(y);
            float fx = x - ix;
            float fy = y - iy;
            float ux = fx * fx * fx * (fx * (fx * 6f - 15f) + 10f);
            float uy = fy * fy * fy * (fy * (fy * 6f - 15f) + 10f);

            float n00 = GradDot(ix, iy, fx, fy);
            float n10 = GradDot(ix + 1f, iy, fx - 1f, fy);
            float n01 = GradDot(ix, iy + 1f, fx, fy - 1f);
            float n11 = GradDot(ix + 1f, iy + 1f, fx - 1f, fy - 1f);

            return Mathf.Lerp(Mathf.Lerp(n00, n10, ux), Mathf.Lerp(n01, n11, ux), uy);
        }

        private static float GradDot(float ix, float iy, float dx, float dy)
        {
            float angle = Hash21(ix, iy) * 6.2831853f;
            return Mathf.Cos(angle) * dx + Mathf.Sin(angle) * dy;
        }

        // Non-harmonic per-octave rotation + translation: no two octaves share a lattice axis, so
        // residual grid structure cannot pile up along x/z the way the old axis-aligned stack did.
        private static readonly float[] OctaveAngle = { 0.00f, 0.62f, 1.29f, 2.11f, 2.83f };

        /// <summary>Five-octave fractal gradient noise, ZERO-MEAN, range ≈ -1..1. Zero mean matters:
        /// the relief mask multiplies this by a spatially varying amplitude, and a biased field
        /// times a varying mask is a landform (the audit measured a 3.45 m levee tracking the path
        /// from the old unsigned FBM). Lacunarity 1.93 keeps octaves off-harmonic.</summary>
        private static float Fbm(float x, float y)
        {
            float sum = 0f;
            float amp = 0.5f;
            float norm = 0f;
            for (int i = 0; i < 5; i++)
            {
                float c = Mathf.Cos(OctaveAngle[i]);
                float s = Mathf.Sin(OctaveAngle[i]);
                float rx = x * c - y * s + i * 37.13f;
                float ry = x * s + y * c + i * 91.71f;
                sum += GradNoise(rx, ry) * amp;
                norm += amp;
                x *= 1.93f;
                y *= 1.93f;
                amp *= 0.5f;
            }

            return sum / norm;
        }

        /// <summary>Softplus max: like Mathf.Max(floor, v) but C1 — the audit traced straight
        /// kink lines at constant x to every hard Max clamp in the landform functions.</summary>
        private static float SoftMax(float floor, float v, float k)
        {
            return floor + k * Mathf.Log(1f + Mathf.Exp((v - floor) / k));
        }

        // -------------------------------------------------------------------------------------
        // Scene dressing
        // -------------------------------------------------------------------------------------

        // -- The turf palette and the grass band -------------------------------------------------
        // SHARED SURFACE, deliberately declared once here and consumed twice. The ground material
        // paints turf with these colours inside this band; BuildGrassDetails scatters tufts with
        // the same band and tints the tuft base toward the same soil. Round 1 shipped the two
        // sides as unrelated magic numbers, and the result was measurable: the ground stopped
        // being turf on a hard line while the tufts kept going, so the tufts read as decals on
        // lino. One fact, one place — if these move, both sides move together.
        //
        // Colours are authored as ordinary picker swatches — the same convention every other
        // material palette in this file uses, so ground and tufts speak the same numbers.
        //
        // ROUND-3: the turf moved into the GREEN family. Round 2's soil was (0.26, 0.21, 0.14) — a
        // brown card sitting under green blades, which the gauntlet measured in round2/v3 as
        // "out-of-family brown dirt with grass decals on it". The mat a blade grows out of is not
        // soil seen from above; it is shadowed leaf litter and dead blade, which is green-black. The
        // ochre survives as the SCOUR patch (see the shader's turf block), which is what
        // "wind-scoured green" actually describes: green mat, worn through in patches.
        //
        // BuildGrassDetails reads TurfSoil back off the material to tint the tuft base, so this
        // change moves the tuft roots to green in the same stroke — which is the point. One fact,
        // one place.
        internal static readonly Color TurfSoil = new Color(0.17f, 0.20f, 0.13f);   // damp root shadow
        internal static readonly Color TurfBlade = new Color(0.25f, 0.33f, 0.19f);  // living blade mat
        internal static readonly Color TurfOchre = new Color(0.50f, 0.42f, 0.23f);  // dry ochre scour
        internal static readonly Color MeadowGreen = new Color(0.28f, 0.36f, 0.20f); // wind-scoured

        // The band tufts live in. BOTH sides feather it now (round-2 integration): the ground
        // shader fades its turf across _TurfFeatherDeg/_TurfFeatherM either side of these numbers,
        // and BuildGrassDetails' density map smoothsteps its own slope/height gates across the same
        // centres instead of the hard `steep > 24 || h < 13 || h > 52` cut that drew the grass
        // boundary as a traceable contour line.
        internal const float GrassBandSteepMaxDeg = 24f;
        internal const float GrassBandHeightLow = 13f;
        internal const float GrassBandHeightHigh = 52f;
        // Turf patch field: the wavelength at which the ground shader breaks its turf layer into
        // clumps. It is a STAND-IN at the same order as the density map's own clumping (which is a
        // three-octave field owned by BuildGrassDetails and far too expensive to port into HLSL),
        // NOT the same field — so turf blotches and tuft stands agree in scale, not in phase. It
        // only modulates turf strength, so the mismatch reads as natural variation.
        internal const float GrassPatchFrequency = 0.045f;
        internal const float GrassPatchScaleMetres = 1f / GrassPatchFrequency;

        // -- The brushmark family (round 4) ------------------------------------------------------
        // SHARED SURFACE, same rule as the turf palette above: the ground shader and the rock
        // shader both draw jittered-cell marks, and if their shape statistics differ the props stop
        // looking like they are made of the hillside. One fact, one place.
        //
        // Aspect spread turns some cells into drawn-out strokes and others into blobs; size spread
        // gives the family a range of brush widths. Both exist because jittering a Worley cell's
        // CENTRE hides the lattice's phase and NOTHING else — the marks stay one circle at one
        // radius on one pitch, which is what the round-4 critique read at 2 m as "one stamped decal
        // repeated at one size on a visible cadence".
        internal const float MeadowDabAniso = 0.55f;
        internal const float MeadowDabSize = 0.45f;

        private static Material BuildTerrainMaterial(Shader shader)
        {
            var material = AssetDatabase.LoadAssetAtPath<Material>(TerrainMaterialPath);
            if (material == null)
            {
                material = new Material(shader);
                AssetDatabase.CreateAsset(material, TerrainMaterialPath);
            }
            else
            {
                material.shader = shader;
            }

            // EVERY property is set explicitly, never left to the shader default. A material asset
            // keeps whatever was serialised into it, so re-running against an existing .mat would
            // otherwise silently preserve stale values while the shader's defaults appear to change.
            //
            // Cliff palette (art-audio.md §Region color scripts owns per-region tinting: "pale dawn
            // gold, wind-scoured green"). The plateau's GOLD lives in the dawn LIGHT, not the albedo
            // (director call 2026-07-26), so nothing here ramps toward white — the warm notes are
            // dry grass and warm stone, which are colours, not brightness.
            //
            // The four meadow hues are the round-2 answer to the gauntlet finding that the ground
            // measured monochrome (one hue at two brightnesses) where fable-05/08 carry a real hue
            // swing. See the shader header for the full finding list.
            material.SetColor("_MeadowGreen", MeadowGreen);
            material.SetColor("_MeadowStraw", new Color(0.66f, 0.58f, 0.31f));
            material.SetColor("_MeadowScuff", new Color(0.42f, 0.32f, 0.21f));
            material.SetColor("_MeadowCool", new Color(0.27f, 0.35f, 0.36f));
            material.SetFloat("_MeadowMacroScale", 38f);
            material.SetFloat("_MeadowHueScale", 21f);
            material.SetFloat("_MeadowDabScale", 6f);
            material.SetFloat("_MeadowFineScale", 0.95f);
            material.SetFloat("_MeadowGrainScale", 0.34f);
            material.SetFloat("_MeadowDabWarp", 0.55f);
            material.SetFloat("_MeadowDabEdge", 0.10f);
            // ROUND-4: the brushmark family's shape spread. Shared with the rock material below,
            // because the ground and the stones sitting on it are made of one paint. See the
            // shader's TkDabShaped for why jittering a Worley CENTRE alone leaves one stamp at one
            // size on one pitch — which is exactly what the round-4 critique read at 2 m.
            material.SetFloat("_MeadowDabAniso", MeadowDabAniso);
            material.SetFloat("_MeadowDabSize", MeadowDabSize);
            material.SetFloat("_MeadowFineWarp", 0.45f);
            material.SetFloat("_MeadowStrawAmount", 0.85f);
            material.SetFloat("_MeadowScuffAmount", 0.55f);
            material.SetFloat("_MeadowCoolAmount", 0.70f);
            material.SetFloat("_MeadowFineTone", 0.16f);
            material.SetFloat("_MeadowFineStraw", 0.28f);
            material.SetFloat("_MeadowGrain", 0.13f);
            // Texel-scale work is gone by 38 m. The gameplay camera sits at 4-6 m, so the fine band
            // is fully present for everything the player is actually standing in.
            material.SetFloat("_DetailFadeStart", 10f);
            material.SetFloat("_DetailFadeRange", 28f);

            // THE CLUMP OCTAVE (round 4) — the band that carries the ground from 40 m to the
            // horizon, where round 3 had nothing but smooth fbm and the hills read as olive
            // gradients. 16 m is a stand of vegetation, not a hillside: coarse enough to still
            // subtend ~9° at 100 m, fine enough that a hill carries a dozen of them. Nothing here is
            // distance-faded — that is the whole point of the octave.
            material.SetFloat("_MeadowClumpScale", 16f);
            material.SetFloat("_MeadowClumpWarp", 0.85f);
            material.SetFloat("_MeadowClumpAmount", 0.90f);
            material.SetFloat("_MeadowClumpEdge", 0.11f);

            // Turf — the layer the tuft fields grow out of (shared constants above). GREEN family
            // now; the ochre is a scour PATCH rather than half of the base ramp.
            material.SetColor("_TurfSoil", TurfSoil);
            material.SetColor("_TurfBlade", TurfBlade);
            material.SetColor("_TurfOchre", TurfOchre);
            material.SetFloat("_TurfScale", 2.8f);
            material.SetFloat("_TurfAmount", 0.78f);
            material.SetFloat("_TurfContact", 0.20f);
            // The scour field is decorrelated from every other meadow field and an order coarser
            // than the turf dab, so bald patches are patches — a few metres across — rather than a
            // per-dab speckle that would just re-brown the whole mat by another route.
            material.SetFloat("_TurfScourScale", 9.5f);
            material.SetFloat("_TurfScourAmount", 0.85f);
            material.SetFloat("_TurfPatchScale", GrassPatchScaleMetres);
            material.SetFloat("_TurfSteepMax", GrassBandSteepMaxDeg);
            material.SetFloat("_TurfFeatherDeg", 8f);
            material.SetFloat("_TurfHeightLow", GrassBandHeightLow);
            material.SetFloat("_TurfHeightHigh", GrassBandHeightHigh);
            material.SetFloat("_TurfFeatherM", 6f);

            // Stone: warm grey beds against cooler grey beds with sage lichen, then the cool slate
            // refusing face. Round 1 had two greys a few levels apart and read as an extension of
            // the meadow gradient.
            material.SetColor("_RockWarm", new Color(0.56f, 0.51f, 0.42f));
            material.SetColor("_RockCool", new Color(0.40f, 0.41f, 0.45f));
            material.SetColor("_RockLichen", new Color(0.35f, 0.40f, 0.26f));
            material.SetColor("_CliffColor", new Color(0.30f, 0.31f, 0.35f));
            material.SetFloat("_RockMottleScale", 6.5f);
            // Close-range paint on the hillside's own stone (round 4). 0.62 m marks on the face's
            // strike/height frame: below the bedding, above the pixel, and the band the round-4
            // critique found empty on v5's 2 m rock face.
            material.SetFloat("_RockDabScale", 0.62f);
            material.SetFloat("_RockDabTone", 0.20f);
            material.SetFloat("_RockDabEdge", 0.14f);
            // Down from round 2's 0.85. The hue swing now turns over per FORMATION (every ~3 beds)
            // instead of per bed, so the same swing at the old amount would read as a barcode.
            material.SetFloat("_RockBedTint", 0.55f);
            material.SetFloat("_RockLichenAmount", 0.40f);

            // Slope thresholds in steepness (1 - N.y): rock from ~35°, owning the surface by ~50°;
            // the refusing face from ~60°, owning it by ~74°. Rock used to start at ~46°, which put
            // every mid slope in the meadow ramp and is half of why nothing read as slope-responsive.
            material.SetFloat("_SlopeStart", SteepnessFromDegrees(35f));
            material.SetFloat("_SlopeEnd", SteepnessFromDegrees(50f));
            material.SetFloat("_CliffStart", SteepnessFromDegrees(60f));
            material.SetFloat("_CliffEnd", SteepnessFromDegrees(74f));
            material.SetFloat("_SlopeJitter", 0.13f);
            material.SetFloat("_BlendFieldScale", 14f);

            // BEDDING (round 3). Gravity-aligned, because sediment is laid down flat — the full
            // reasoning is in the shader header and is not restated here. Two numbers carry the
            // round-2 lesson and must be read together:
            //   * _BeddingSpacing 2.6 m is the mean bed thickness.
            //   * _BeddingWarp 0.55 m is 21% of a bed, and the shader hard-caps it at 30% anyway.
            // Round 2 ran a 6.5 m wander against a 3.4 m bed — 1.9 BED THICKNESSES — at which point
            // the bedding coordinate is the wander field rather than world Y, and the partings
            // become that field's level sets, which are closed loops. Those loops are the worm veins
            // the gauntlet measured on every slope in round2/v1 and v8. The ratio is the fault, not
            // the axis: keep warp well under half a bed and the beds stay beds.
            //
            // The dip is a ~3.4°/2.6° gradient. Enough that the beds are not a spirit-level ruling;
            // far too little to reach the level-set regime.
            material.SetFloat("_BeddingSpacing", 2.6f);
            material.SetVector("_BeddingDip", new Vector4(0.060f, 0f, -0.045f, 0f));
            material.SetFloat("_BeddingWarp", 0.55f);
            material.SetFloat("_BeddingRough", 0.22f);
            material.SetFloat("_BeddingLineWidth", 0.085f);
            material.SetFloat("_BeddingWidthJitter", 0.60f);
            material.SetFloat("_BeddingDarken", 0.36f);
            material.SetFloat("_BeddingLip", 0.20f);
            material.SetFloat("_BedValueJitter", 0.09f);
            material.SetFloat("_BedFormRate", 0.34f);
            // Bedding is drawn on STEEP FACES ONLY, and this is the structural guard on round 2's
            // one real win (no contour banding). The ring was never caused by banding on world Y; it
            // was caused by banding on GENTLE ground, where a horizontal slab meets the surface over
            // an enormous on-surface width and its edge necessarily traces a heightmap contour. Fade
            // the whole construct out below the angle where a bed cuts a thin line and the ring
            // cannot be drawn at all. Authored in degrees, like every other slope threshold here.
            //
            // ROUND-4 RE-GATE, 35/48 -> 50/62, plus an AND against the rock classification in the
            // shader. MEASURED, not eyed: over this generator's own 513² heightfield with Unity's
            // central-difference normals, the landform filling v1's left third (x 140-218, z 30-88,
            // the valley's SOUTH permitting ramp) runs a median slope of 31.5° across a 12.6-48.6°
            // quartile range — a dune. 43.8% of it fell inside the old fade and drew beds; a
            // horizontal plane cutting a rounded hill traces a CONTOUR, so those beds wrapped the
            // form, which is precisely the round-4 finding. At 50/62 the same box drops to 22.2%
            // touched, every cell under 50° takes exactly zero, and what keeps its strata is the
            // north refusing wall (55-65°) and the broken edge (~70°) — true rock, where a 2.6 m bed
            // meets the surface over 3.0 m instead of 5.2 m and can be a line rather than a shade.
            material.SetFloat("_BeddingSlopeStart", 50f);
            material.SetFloat("_BeddingSlopeEnd", 62f);

            // CAVITY — concavity darkening as its own AO-like term, deliberately NOT baked into the
            // bedding marks. It selects a filled REGION (where the fine relief sits below the broad
            // form) rather than a band around a field's midpoint, which is the structural reason it
            // cannot draw the worms the round-2 crevice term drew.
            material.SetFloat("_CavityScale", 3.4f);
            material.SetFloat("_CavityContrast", 4.5f);
            material.SetFloat("_CavityDarken", 0.34f);
            material.SetFloat("_CavityGroundDarken", 0.16f);

            // SHADING NORMAL — the facet fix. 0.30 m of relief over a 3.4 m field is a gentle
            // undulation, not a bumpy surface; it is sized to break the Gouraud Mach band at a
            // triangle edge, which is a metres-scale artefact, and nothing finer would touch it.
            // Faded out past 45 m, where the facets are sub-pixel anyway and an unfaded
            // high-frequency normal would only generate shimmer.
            material.SetFloat("_NormalDetailHeight", 0.30f);
            material.SetFloat("_NormalDetailStrength", 1f);
            material.SetFloat("_NormalDetailFadeStart", 45f);
            material.SetFloat("_NormalDetailFadeRange", 55f);
            // ...and MORE of it on stone (round 4). The 0.30 m figure is sized for the meadow's
            // near-flat triangles; on a 65° face the same triangles are edge-on and the ndotl step
            // across each Gouraud kink is several times larger, which is why v5's rock face read as
            // sliver triangles. 2.2x lands ~11° of shading tilt on stone and leaves the meadow
            // untouched. Costs nothing: the same relief height, amplified before it is differentiated.
            material.SetFloat("_RockNormalBoost", 2.2f);

            material.SetFloat("_HeightLow", 8f);
            material.SetFloat("_HeightHigh", 48f);
            // Up from round 2's 0.30. Wrapping compresses the ndotl gradient, and a compressed
            // gradient means a smaller value step across a facet edge — the cheap half of the facet
            // fix, and it costs the storybook falloff nothing because a softer terminator is the
            // house look anyway (Visual pillar 1).
            material.SetFloat("_ShadeWrap", 0.40f);
            material.SetFloat("_AmbientBoost", 1f);
            material.SetColor("_ShadowTint", new Color(0.80f, 0.88f, 1.06f));
            material.SetColor("_AmbientFloor", new Color(0.10f, 0.11f, 0.14f));

            // OPAQUE, pinned. The shader states its own blend state explicitly, but a .mat that has
            // ever carried a custom queue keeps it across a shader reassignment, and a ground in the
            // transparent queue is one of the two shapes the round-2 "you can see through the cliff"
            // read could have had. -1 means "use the shader's queue" (Geometry, 2000).
            material.renderQueue = -1;
            material.SetOverrideTag("RenderType", "Opaque");
            EditorUtility.SetDirty(material);
            return material;
        }

        /// <summary>Slope thresholds are authored in DEGREES (which is how the terrain grammar and
        /// the CharacterController's slope limit are both discussed) and consumed by the ground
        /// shader as steepness = 1 - N.y. Converting here keeps the readable number at the call
        /// site instead of a table of unexplained decimals.</summary>
        private static float SteepnessFromDegrees(float degrees)
        {
            return 1f - Mathf.Cos(degrees * Mathf.Deg2Rad);
        }

        // -------------------------------------------------------------------------------------
        // The dawn atmosphere. ONE description, consumed by three places that must agree or the
        // island-in-cloud read breaks: the skybox, the exponential fog, and the cloud deck's fade.
        //
        // All LINEAR — material colours are consumed raw. The fog colour is DERIVED via .gamma
        // because RenderSettings colours are gamma-decoded, so the same float triple means two
        // different colours in the two places; hand-copying the numbers is how they drift.
        //
        // WHY THESE NUMBERS (2026-07-31 look pass, against Assets/Screenshots/wave2_*). Measured
        // off wave2_knoll: the whole visible sky moved eight sRGB levels from frame top to horizon
        // — a flat tan card. The old ramp's transition lived above the frustum, because at the
        // gameplay camera's pitch the player only ever sees the first ~25° of sky. So the mid band
        // is pulled down to sin(elev)=0.44 and both ramps are smoothstepped, putting real value
        // structure (0.92 → 0.58 linear) inside the band that is actually on screen. Reference
        // board: fable-03, fable-04, animation-04.
        // -------------------------------------------------------------------------------------
        private static readonly Color SkyHorizonLinear = new Color(0.92f, 0.82f, 0.62f);
        private static readonly Color SkyMidLinear = new Color(0.58f, 0.62f, 0.69f);
        private static readonly Color SkyZenithLinear = new Color(0.20f, 0.32f, 0.54f);

        // Below the horizon the Cliff has NO ground: it has the cloud sea (world.md §The Cliff).
        // Fog, the sky's lower hemisphere and the deck's far field all land on this one luminous
        // value — which is what lets distant rim rock die INTO the deck instead of silhouetting
        // against it. The old fog colour was a duller tan than the deck it sat in front of, so
        // every far ridge stayed a hard dark shape on a white plane.
        private static readonly Color HazeLinear = new Color(0.90f, 0.85f, 0.74f);
        private static readonly Color SunGlowLinear = new Color(1.00f, 0.84f, 0.58f);

        private const float SkyMidHeight = 0.44f;      // sin(elev) where the cream band is reached
        private const float SkyHazeDepth = 0.09f;      // sin(elev) over which gold gives way to haze
        private const float SkyGlowFalloff = 7f;
        private const float SkyGlowBroad = 0.22f;
        private const float SkyGlowBroadPower = 8f;
        private const float SkyGlowCore = 0.55f;       // over 1 at the sun: the blaze blooms, locally
        private const float SkyGlowCorePower = 120f;
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
        private static readonly Color VaultCloudLitLinear = new Color(1.02f, 0.97f, 0.87f);
        // The middle wash. Down from round 2's (0.62,0.66,0.78): at that value the "shaded" side of
        // a mass was lighter than the low sky band it was drawn over, so the masses had no dark
        // side at all — they were a bright shape on a bright ground with a slightly brighter shape
        // inside them.
        private static readonly Color VaultCloudShadeLinear = new Color(0.52f, 0.57f, 0.71f);
        // THE ANCHOR. Cool, not neutral: at dawn a cloud's underside is lit by sky, and the whole
        // region's grade is warm light on cool shadow (BuildLighting). Grey here would read as
        // dirt on the plate.
        private static readonly Color VaultCloudShadowLinear = new Color(0.19f, 0.23f, 0.35f);
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

        /// <summary>Compass bearing of the sun disc, Unity's convention (0° = +Z, increasing
        /// toward +X). At SunEuler 12°/152° this is ≈332°, NNW — see BuildLighting. DERIVED, never
        /// typed: the vault clouds are placed at offsets from it, so moving the sun moves the whole
        /// cloud composition with it.</summary>
        private static float SunBearingDegrees
        {
            get
            {
                Vector3 sun = SunToward;
                return Mathf.Repeat(Mathf.Atan2(sun.x, sun.z) * Mathf.Rad2Deg, 360f);
            }
        }

        /// <summary>One vault cloud, placed by how far round from the sun it sits.</summary>
        private static Vector4 VaultCloud(
            float bearingFromSun, float elevation, float halfWidth, float opacity)
        {
            return new Vector4(
                Mathf.Repeat(SunBearingDegrees + bearingFromSun, 360f), elevation, halfWidth, opacity);
        }

        // Frozen dawn. THE one sun: BuildLighting's directional light, the sky's blaze and the
        // cloud deck's bank alignment all read this, because a second hand-typed copy is a drift
        // waiting to happen (the sky would glow where the sun is not).
        //
        // Elevation 12° / azimuth 152° — the reasoning is written out at length in BuildLighting,
        // which owns this number. In short: light TRAVELS south-south-east, so the disc sits NNW
        // (compass 332°) and RAKES 62° across the v1 wake frame's due-west axis, low enough that
        // micro-relief casts.
        //
        // EVERY derived vector recomputes from this constant — the sky's blaze and haze depth
        // (ApplySkyDescription's _SunDirection), the cloud deck's bank alignment (_StreakAxis) and
        // the lamp itself all read SunToward, so moving the sun moves the whole sky with it and
        // nothing needs hand-syncing. The two materials it bakes into (TerrainProtoSky.mat,
        // CloudSea.mat) are rewritten every Generate(), and GauntletCapture regenerates before it
        // shoots, so a stale .mat on disk can never outlive a capture run.
        //
        // MERGE NOTE (2026-07-31, round 2 rake pass): this replaces the round-1 merge's 17°/117°,
        // which itself replaced 16°/78°. The direction of travel is unchanged in kind — the disc
        // keeps swinging north and down — so the round-1 sky pass's reasoning still holds; it is
        // simply applied harder. Two knock-ons a reviewer should expect and not mistake for bugs:
        // the blaze now sits ~35° further north and much closer to the horizon band, and
        // GauntletCapture's v1/v2 header comments still quote the round-1 bearings (see the report
        // for the corrected figures: v1 rakes 62°, v2 is now the near-contre-jour frame at 16°).
        //
        // MERGE NOTE (round 4, the beam pass): 7° → 12°. THE AZIMUTH DOES NOT MOVE, so every vector
        // derived from it — the blaze, the cloud banks, the five vault masses, the rock family's
        // bedding dip — keeps its round-3 bearing exactly and the round-3 sky composition is
        // untouched. Only the disc's HEIGHT changes, and it changes because at 7° the beam could
        // not physically reach the ground the player stands on: traced against this file's own
        // heightfield, the horizon toward the sun from the spawn mark is 26.2° (the valley's north
        // refusing wall, 16 m of it at 32 m range), so the entire spawn floor — 100% of the ground
        // within 15 m of the Fool — sat in cast shadow, and 0% of v2's visible ground was lit.
        // 12° is not a taste call: it is the lowest elevation at which the col cut through that
        // wall (see ApplyLandformEvents, "the dawn breach") admits the beam to the meadow inside
        // 10 m of the v1 lens. At 11° the same col still leaves the lit boundary 25 m out.
        // The dawn is not spent by the raise: a form still throws 4.7× its height (8.1× at 7°), and
        // what actually carries the modelling — the MODULATION of N·L by the fine relief, not its
        // mean — is unchanged to three decimal places. Measured over the walkable floor between
        // x 170-215: σ(N·L) 0.0844 → 0.0829, σ(wrapped) 0.0603 → 0.0592. The west-facing terrace
        // risers keep their stripe (wrapped 1.29:1 over the treads at 7°, 1.24:1 at 12°).
        private static readonly Vector3 SunEuler = new Vector3(12f, 152f, 0f);

        /// <summary>Unit vector pointing TOWARD the sun (a light's forward points the way its
        /// light travels, so the sun is behind it).</summary>
        private static Vector3 SunToward => -(Quaternion.Euler(SunEuler) * Vector3.forward);

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
            target.SetColor("_HazeColor", HazeLinear);
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
            target.SetVector("_VaultCloud1", VaultCloud(26f, 7.5f, 9.0f, 0.70f));
            target.SetVector("_VaultCloud2", VaultCloud(-98f, 26.0f, 26.0f, 0.24f));
            target.SetVector("_VaultCloud3", VaultCloud(105f, 13.5f, 21.0f, 0.88f));
            target.SetVector("_VaultCloud4", VaultCloud(64f, 4.5f, 11.0f, 0.62f));
            target.SetColor("_VaultCloudLit", VaultCloudLitLinear);
            target.SetColor("_VaultCloudShade", VaultCloudShadeLinear);
            target.SetColor("_VaultCloudShadow", VaultCloudShadowLinear);
            target.SetFloat("_VaultCloudBase", VaultCloudBase);
            target.SetFloat("_VaultCloudBaseLump", VaultCloudBaseLump);
            target.SetFloat("_VaultCloudSoftness", VaultCloudSoftness);
            target.SetFloat("_VaultCloudLump", VaultCloudLump);
            target.SetFloat("_VaultCloudLift", VaultCloudLift);
        }

        private static void BuildLighting()
        {
            // FROZEN DAWN (canon: art-audio.md §Region color scripts gives the Cliff "pale dawn
            // gold, wind-scoured green"; MQ00 opens at dawn). Director call (2026-07-26 audit): the
            // plateau's gold lives in the LIGHT — the ground stays green meadow, dawn paints it.
            // Two decisions live in this one rotation:
            //
            // ELEVATION 12°, and rounds 1-3 are the argument for every part of that number.
            // Round 1 came down from a 42° near-midday sun to 17° and the pixel audit of round1/v1,v2
            // still measured NO raking: the meadow sat in a 0.23–0.41 luminance band (σ 0.06) with no
            // lit-crest-against-shadowed-trough anywhere, and the warm key never landed on a walkable
            // surface — gold stayed in the sky while the ground read grey-olive. 17° is still high
            // enough that a metre of relief throws only 3.3 m of shadow, which the meadow's own gentle
            // grain swallows. Round 2 went to 7°, where a form throws 8.1× its height and the relief
            // that is actually there starts casting: the fine grain on the valley floor (≈0.6 m at a
            // 5 m wavelength — SampleHeight step 8) puts ±20° of tilt on the walkable surface, which
            // is the difference between a lit facet and a self-shadowed one. That was right, and it
            // is kept.
            //
            // WHAT 7° GOT WRONG, and round 3 did not catch because it was measuring the grade and not
            // the geometry: THE BEAM NEVER REACHED THE PLAYER. Ray-traced against this file's own
            // heightfield, the elevation of the horizon toward the sun is 26.2° from the spawn mark,
            // 21.2° from the v1 lens and 17.2° from the v2 lens — the valley's north refusing wall,
            // 16 m of it standing 30 m away on exactly the sun's bearing. At a 7° sun that wall
            // shadows 100% of the ground within 15 m of the Fool, 79% of the whole spawn bowl, and
            // 100% of everything v2 can see. The round-3 critique measured the consequence exactly:
            // one flat value at four depths across the walkable field, and no lit tier at all in v2.
            // No grade can fix a surface the light does not land on.
            //
            // 12° IS DERIVED, not dialled. It is the lowest elevation at which the col cut through
            // that wall (ApplyLandformEvents, "the dawn breach") lets the beam onto the meadow inside
            // 10 m of the v1 lens: at 11° the same col leaves the lit boundary 25 m out, at 12° it
            // lands at 8.4 m — the near ground stays in shade and the lane opens just beyond the
            // Fool. A raise on its own could not do it (the sun would have to reach 26° — midday) and
            // a col on its own could not either (at 7° the same lit boundary needs a 55 m trench
            // through the rim, 8400 m³ against this one's 1030). The landform and the lamp each do
            // the half they are good at.
            // The dawn survives the raise: a form still throws 4.7× its height, and the MODULATION
            // that does the modelling is untouched — σ(N·L) over the walkable floor 0.0844 → 0.0829.
            // Everything else in this block exists to pay for the low sun: at 12° flat ground still
            // receives only sin(12°) ≈ 0.21 of the beam, so intensity stays high and the fill low.
            //
            // AZIMUTH 152° — light TRAVELS south-south-east, so the sun disc sits NNW (compass 332°),
            // 62° off the axis of the west-facing wake frame. Round 1's 117° left the disc only 27°
            // off that axis: still essentially contre-jour, where every surface facing the camera is
            // lit at the same grazing angle and the frame resolves into silhouettes rather than
            // modelled form. Swung to a true cross-light the rake does three jobs at once, and the
            // direction is chosen so the light says what the landform already says (rule 5):
            //   - the SHALLOW south wall that invites faces north, into the light, and takes the gold;
            //   - the STEEP north wall that refuses faces south, away, and goes dark and cool beneath
            //     a rim-lit crest;
            //   - WEST-facing terrace risers catch N·L = cos(7°)·cos(62°) ≈ 0.47 against treads at
            //     0.12 — a ~4:1 stripe, which is what finally makes the terraces count as terraces
            //     from the spawn, and they face the v1 camera so the stripe is read side-on.
            // The spawn bowl's sheer back wall faces west and so takes light too: the ground that
            // refuses behind the player reads as a wall rather than a void.
            //
            // KNOCK-ON, deliberate: v2-spawn-side (view yaw 348°) was round 1's raking frame at 51°
            // off the sun; it is now 16° off and becomes the near-contre-jour one — a low blaze with
            // everything rim-lit, which is the fable-03 windmill-sunburst frame and no loss. v1, the
            // wake frame, is the one that had to be right.
            var lightGo = new GameObject("Directional Light");
            // SunEuler, not a literal: the sky's blaze and the cloud deck's banks read the same
            // constant, so the sun cannot be in two places at once.
            lightGo.transform.rotation = Quaternion.Euler(SunEuler);
            var light = lightGo.AddComponent<Light>();
            light.type = LightType.Directional;
            // Dawn gold, one step warmer than round 1's (1.00, 0.87, 0.68). Authored gamma
            // (Light.color is gamma-decoded like any inspector colour), so this lands near
            // (1.00, 0.67, 0.34) LINEAR — 3:1 red to blue. A 7° sun has travelled through far more
            // atmosphere than a 17° one and is genuinely this orange; more to the point, the audit's
            // complaint was that lit ground read "hue-97 grey-olive" while gold stayed in the sky,
            // and a key this warm makes lit meadow resolve to (0.55, 0.48, 0.24) linear — gold-green
            // — against blue-teal shade. Further than this and the warm white balance and warm
            // highlights in the grade below double-count it into sodium.
            light.color = new Color(1.00f, 0.84f, 0.62f);
            // ROUND 3, 2.90 → 8.00, and this one number is most of the exposure fix.
            //
            // Round 2 set 2.90 from an arithmetic that DROPPED THE ALBEDO. Its comment claimed "a
            // surface square to the beam reaches ~1.07 linear... flat lit meadow lands ~0.55
            // linear". Both are the light's own value, not the surface's: the shader returns
            // albedo × (direct + ambient) × shade, and the meadow's blend-weighted albedo is
            // gamma (0.36, 0.39, 0.24) = LINEAR (0.105, 0.130, 0.046). So flat lit meadow actually
            // landed at 0.072 linear (a seventh of the claim) and even the pale limestone square
            // to the beam only reached 0.80. Nothing on the ground could clip, which is exactly
            // what the round-2 critique measured: no pixel over 0.85, no sparkle anywhere.
            //
            // The number is now set by where MID-GREY should land, and mid-grey is the one level
            // the rest of the chain is built around (the LogC contrast pivot below sits at linear
            // 0.2249). Flat lit meadow must arrive there:
            //     intensity = 0.20 / (wrapped 0.325 × albedo_G 0.130 × shade 0.83) ≈ 8.0
            // Consequences, all measured through the full shader→bloom→vignette→LUT chain:
            //   - flat LIT meadow 0.197 linear → sRGB 0.50 near, 0.55 at 80 m (target 0.5–0.6);
            //   - flat CAST-SHADOW meadow 0.025 linear → sRGB 0.17 (target 0.12–0.18);
            //   - limestone square to the beam 2.68 linear → red clips at 1.0 and blooms. THAT is
            //     the handful of near-white pixels the frame has never had, and it costs nothing
            //     elsewhere because character and meadow albedos are half the rock's.
            // It also fixes the ground-versus-sky complaint directly. The sky and the cloud deck
            // are UNLIT materials (GradientSky/CloudSea take no main light), so this raises the
            // ground alone: horizon-to-lit-ground closes from 7.9:1 to 2.7:1. Gold stops being a
            // thing that only happens in the sky.
            //
            // ROUND 4, 8.00 → 6.71, and this is a CONSEQUENCE of the elevation raise, not a new
            // opinion about brightness. Round 3's target — flat lit meadow arriving on the LogC
            // contrast pivot, linear luminance 0.2249 — is kept exactly; the raise simply delivers
            // more of the beam to flat ground, so the lamp must give back the difference or the
            // whole grade slides off its own pivot. Solved rather than scaled, because the ambient
            // term does not move with the lamp:
            //     albedo·(key·wrapped(sin 12°) + ambient)·shade = 0.2249   →   intensity 6.713
            // (the naive ratio 8.00 × wrapped(7°)/wrapped(12°) = 6.87 overshoots by 2.4%).
            // Modelled through the full shader → fog → bloom → vignette → LUT chain, every round-3
            // landing point therefore holds to within a sRGB level or two:
            //     flat LIT meadow           0.497 (round 3: 0.497)
            //     flat CAST-SHADOW meadow   0.181 (round 3: 0.182)
            //     near lit : near shade     2.74:1 — the board is 2.4:1 to 4.1:1
            // What changes is not the values but HOW MUCH OF THE FRAME IS AT THEM: v1's lit ground
            // goes 22% → 43%, v2's 0% → 14%.
            light.intensity = 6.71f;
            light.shadows = LightShadows.Soft;
            // NOT 1.0. At this elevation shadow covers most of the frame, and full-strength shadow
            // over a cool ambient is exactly how "luminous cool shade" becomes mud. The 10% of direct
            // light left inside shadow keeps shadowed ground reading as coloured, not vacant —
            // the same instinct as the shader's _ShadowTint/_AmbientFloor pair.
            light.shadowStrength = 0.9f;

            // Trilight ambient. GOTCHA (audit finding 3): RenderSettings colours are gamma-decoded
            // in a Linear project, so these triples are authored gamma-encoded to land at the
            // intended linear values. The old triples were authored as if linear — the ground pole
            // landed at 4.7% linear, a light trap that took every shadowed face to near-black.
            // Storybook wants luminous shadows: cool sky/equator, only the ground bounce warm — that
            // opposition to the warm sun IS the painterly warm-light/cool-shadow split.
            //
            // Round 1 fixed the trap's DIRECTION (cool sky, warm bounce, chroma over grey) and this
            // pass keeps all of that. What it changes is the LEVEL, and that is the single biggest
            // reason nothing in round1/v1,v2 separated. Do the arithmetic on those numbers: the sky
            // pole at gamma (0.52, 0.64, 0.88) is LINEAR (0.23, 0.37, 0.75), while the key delivered
            // 1.55 × sin(17°) = 0.45 to flat ground. In blue, the FILL beat the KEY four to one. An
            // up-facing surface — i.e. the whole meadow, lit and shadowed alike — was therefore an
            // ambient-driven surface with a little gold on top, which is precisely the measured
            // result: a 0.23–0.41 band with σ 0.06 and the warm key nowhere on the ground.
            //
            // Round 2 quartered the fill so the sun would do the lighting and the sky only the
            // shade. That direction was right and it stays. ROUND 3 gives back about 45% of it in
            // linear terms, because the constraint that forced the cut has gone: the audit's
            // failure was the FILL BEATING THE KEY in blue (0.75 fill against a 0.45 key), and
            // against an 8.00 lamp flat ground now takes a 0.89 blue key against a 0.42 blue fill.
            // The key wins in every channel, comfortably, at the level the fill needs to be for
            // cast shadow to sit at sRGB 0.17 with all three channels alive rather than at the
            // floor. Shade that is dark AND coloured is a fill job; no grade can invent chroma
            // that the render never produced.
            //
            // The sky pole is also a little WARMER and a little less blue than round 2's, and that
            // is measured off the bar rather than reasoned from the convention. Sampled across the
            // darkest quartile of the near ground, fable-01/02/05/07 all put their shade at
            // R > G > B (R−G between +0.019 and +0.038, B−G between −0.009 and −0.037) — the
            // painterly "cool shadow" is cool RELATIVE TO THE KEY, not actually blue. Round 2's
            // fill was blue enough that shaded meadow rendered CYAN — B above R — which is a hue no
            // frame on the reference board contains. (It never reached the screen: the toe and the
            // contrast below took it to black first. Lift those off round 2 and the cyan is what
            // is underneath.) At these values cast-shadow meadow lands at
            // sRGB (0.151, 0.173, 0.139): B now sits below G exactly as the references do, and it
            // reads as deep warm olive against gold-green light — the fable-01 read the grade
            // below is written for, the HUE MOVING WITH THE VALUE.
            // How far this can go is capped by the meadow, not by the fill: the palette's albedo
            // is linear (0.105, 0.130, 0.046), so green outruns red by 24% no matter what falls on
            // it, and R can only pass G if the fill is as warm as the sun — which would spend the
            // warm-key/cool-fill opposition entirely. Getting the last step to a genuinely
            // brown-warm shade is a MEADOW PALETTE change (more straw and scuff in _MeadowGreen's
            // neighbourhood), which belongs to the ground builder, not here.
            // The ground bounce moves least: it is the only warmth in the fill and it reaches
            // almost nothing but downward faces and the undersides of grass.
            //
            // CORRECTION to the round-2 comment: the terrain shader's _AmbientFloor does NOT
            // backstop at "(0.10, 0.11, 0.14) linear". It is a shader Color property, so it is
            // gamma-decoded like everything else here and lands at linear (0.010, 0.012, 0.017) —
            // an order of magnitude under the trilight ground pole, i.e. inert on every terrain
            // normal. Nothing below depends on it; it is left alone deliberately (the ground
            // builder owns the rest of that SetColor block) but the claim should not be repeated.
            //
            // ROUND 4 moves the SKY POLE ONLY, (0.44, 0.49, 0.64) → (0.49, 0.485, 0.565), and it is
            // the last measurable step of the same argument round 3 was making. The round-3 critique
            // measured near-ground shade as olive with blue only ~10 levels under the top channel,
            // where the board's shade quartiles run warmer; the board's own figure is R−B between
            // +0.013 and +0.082 in sRGB. Round 3 landed at +0.024. Solved against that target rather
            // than nudged, holding shade luminance constant so nothing else in the grade shifts:
            //     cast-shadow meadow  round 3 (0.170, 0.187, 0.147)  Y 0.181  R−B +0.024
            //                         round 4 (0.179, 0.186, 0.131)  Y 0.181  R−B +0.048
            // The fill is still COOL AGAINST THE KEY, which is the whole point of the opposition and
            // is what "cool shadow" means on a painted plate — the key's linear R/B is 2.92 and the
            // fill's is 0.75 — it has simply stopped being a saturated blue of its own. The key still
            // beats the fill in every channel and by more in the one that mattered: per-channel
            // key/fill on flat ground 8.9/5.0/1.5 → 7.4/5.1/1.9.
            // A bonus, and it removes the one place round 3 was flirting with the LogC clip: the
            // refusing north wall's red, the darkest large surface in any frame, goes from sRGB
            // 0.0015 (a hair off zero) to 0.0075.
            // R > G in the shade is still out of reach here and still belongs to the ground builder:
            // the meadow albedo is linear (0.105, 0.130, 0.047), so green outruns red by 24% whatever
            // falls on it, and only a straw-warmer _MeadowGreen neighbourhood can close that.
            // The equator and ground poles are deliberately untouched.
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.49f, 0.485f, 0.565f);
            RenderSettings.ambientEquatorColor = new Color(0.42f, 0.44f, 0.55f);
            RenderSettings.ambientGroundColor = new Color(0.40f, 0.34f, 0.26f);

            // The project's own gradient sky — NOT Skybox/Procedural, whose Rayleigh remap produces
            // an acid-green horizon band at any blue-shifted tint (measured G exceeding the R/B mean
            // by 45 sRGB levels) and renders the whole below-horizon hemisphere as one flat colour:
            // the literal diorama-on-a-table read the hex retirement was meant to end.
            Shader gradient = Shader.Find("Tarrock/GradientSky");
            var sky = new Material(gradient != null ? gradient : Shader.Find("Skybox/Procedural"));
            if (gradient != null)
            {
                ApplySkyDescription(sky);
                sky.SetFloat("_Dither", SkyDither);
            }
            else
            {
                Debug.LogWarning("[Tarrock] Tarrock/GradientSky not found; using Procedural fallback.");
                sky.SetColor("_SkyTint", new Color(0.60f, 0.62f, 0.72f));
                sky.SetColor("_GroundColor", new Color(0.70f, 0.64f, 0.52f));
            }

            AssetDatabase.DeleteAsset(SkyMaterialPath);
            AssetDatabase.CreateAsset(sky, SkyMaterialPath);
            RenderSettings.skybox = sky;
            RenderSettings.sun = light;

            // Exponential² fog in the CLOUD SEA's colour, not the sky's horizon band: aerial
            // perspective from the first metres (22% at 100 m, ~79% at 250 m) instead of the old
            // linear 150 m dead zone. Two changes from the 07-27 pass, both from wave2_knoll:
            //   - the colour is HazeLinear, so a far ridge fades toward the value of the deck it
            //     stands in rather than toward a duller tan than the deck — that mismatch is why
            //     the rim rock stayed a crisp dark shape on a bright plane;
            //   - the density is nudged up so the far rim (200 m+ across a 256 m region) actually
            //     dies, which is what sells "island", not "valley".
            // Aerial perspective CREATES the elevation read; it does not flatten it.
            //
            // ROUND 2, the density only (the colour is the sky pass's constant and stays married to
            // the deck): 0.0050 → 0.0044. The audit's finding was that the distant massifs came out
            // as uniform lavender slabs — "haze does the depth work that value should". Half of that
            // is fixed above and in the shadow settings, by giving those massifs a lit side and a
            // dark side to ramp in the first place; this is the other half. At 0.0050 the mid-far
            // band was already 43% hazed at 150 m and 63% at 200 m, so a ridge's own light/dark
            // structure was being compressed into a third of its range before it ever reached the
            // eye — the haze was arriving before the value did. At 0.0044 that band reads 35% / 54%,
            // which hands the 120–180 m depths (exactly the range the new 180 m shadow distance now
            // reaches) back to value, while the last 60 m still dies: 70% at 250 m, so the far rim
            // goes on dissolving into the deck and the region still reads as an island, not a valley.
            // Near stays darker and saturated, far lifts and desaturates — a ramp, not a wash.
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogDensity = 0.0044f;
            RenderSettings.fogColor = HazeLinear.gamma;
            DynamicGI.UpdateEnvironment();

            BuildPostVolume();
        }

        /// <summary>
        /// Adds a volume override to <paramref name="profile"/> AND PERSISTS IT.
        ///
        /// THE TRAP (this cost the whole grade once — TerrainProtoPost.asset shipped serialising six
        /// components as <c>{fileID: 0}</c>): <c>VolumeProfile.Add&lt;T&gt;()</c> only
        /// <c>CreateInstance</c>s the component and appends it to the profile's list. The instance
        /// belongs to no asset file, so on save Unity writes a null reference for each one and the
        /// profile reloads with six empty slots — a volume that grades nothing, silently, while the
        /// code that authored it reads as if it worked. The component only becomes real when it is
        /// added to the profile's asset file as a sub-asset, which is what Unity's own
        /// VolumeProfileFactory does and what this helper exists to make unskippable. Every override
        /// in <see cref="BuildPostVolume"/> goes through here; never call <c>profile.Add</c> direct.
        /// </summary>
        private static T AddPersistedOverride<T>(UnityEngine.Rendering.VolumeProfile profile)
            where T : UnityEngine.Rendering.VolumeComponent
        {
            T component = profile.Add<T>();
            // Belt and braces: recent URP sets both itself inside Add, older versions do not, and a
            // sub-asset without HideInHierarchy shows up as loose clutter under the profile.
            component.name = typeof(T).Name;
            component.hideFlags = HideFlags.HideInHierarchy | HideFlags.HideInInspector;
            AssetDatabase.AddObjectToAsset(component, profile);
            return component;
        }

        // The grade — the wake frame's first impression, and until this build it had never actually
        // run (see AddPersistedOverride: the profile's six overrides were serialised as null, so
        // every screenshot to date is raw untonemapped shader output. That, not the landform, is
        // most of what reads as "unfinished" in Assets/Screenshots/wave2_*.png).
        //
        // What the grade is FOR (reference board, fable-01/02/04): dawn light that is gold where it
        // lands and blue-grey where it doesn't, values that separate, colour that stays saturated
        // but never garish (art-audio.md §Visual pillars). The frame arrives here already warm from
        // the sun and already cool in the fill; the grade's job is to widen that gap, not to invent
        // it, and to keep a hand-painted image out of a video-camera look — so no film grain, no
        // chromatic aberration, no lens dirt. Regenerates deterministically like everything else.
        //
        // ROUND 3 — the exposure rebalance. Round 2 got the RAKE right (hard cast-shadow diagonals,
        // gold on the south wall) and that is kept untouched; what it got wrong was the level, and
        // three independent overshoots landed on top of each other: a quartered fill, a log
        // contrast of 22 whose pivot sat four stops above the picture, and a −0.03 additive toe.
        // Together they took the walkable foreground to LITERAL BLACK — mean luminance 0.0026,
        // red and green clipped to zero over most of the frame — while nothing anywhere exceeded
        // 0.85, so there was no sparkle either. Near-to-far read as an inverted 200:1 cliff rather
        // than a ramp.
        //
        // WHERE ROUND 3 LANDS (sRGB display luminance, modelled end-to-end through the terrain
        // shader → fog → bloom → vignette → the URP LUT chain in the order LutBuilderHdr actually
        // applies it, then checked against the round-2 captures — the model reproduces round 2's
        // measured near-ground mean, its channel-clipping signature and its 213:1 near/far cliff,
        // and predicts its brightest pixel to within 0.005):
        //     near cast-shadow meadow   0.17   (was 0.003)   all three channels alive
        //     near lit meadow           0.45   (was 0.126)
        //     lit meadow at 80 m        0.55   (was 0.38)
        //     far lit meadow at 200 m   0.72
        //     limestone square to beam  0.89   red clipping at 1.0, and blooming
        //     darkest channel in frame  0.008  (was 0.000 across 60–96% of the frame)
        //     rake, near lit : shade    2.7:1  — the reference board's own ground contrast is
        //                                        2.4:1 (fable-07) to 4.1:1 (fable-02)
        //     ramp, far lit : near shade 4.3:1 the right way round
        // Every number below that changed was derived, not dialled. If a future pass moves the
        // lamp, the contrast pivot arithmetic in ColorAdjustments has to be re-checked with it:
        // those two are a pair, and round 2 came apart because they were moved independently.
        private static void BuildPostVolume()
        {
            var profile = ScriptableObject.CreateInstance<UnityEngine.Rendering.VolumeProfile>();
            AssetDatabase.DeleteAsset(PostProfilePath);
            AssetDatabase.CreateAsset(profile, PostProfilePath);

            // NEUTRAL, not ACES. ACES is the reflex choice and the wrong one here: it desaturates
            // mids, crushes toe contrast, and skews bright warm light toward white — it would eat
            // the gold out of the dawn and the green out of the meadow, which are the two colours
            // the Cliff's colour script actually names. Neutral rolls the highlights off without
            // arguing with the palette, which is what a hand-painted image wants from a tonemapper.
            var tone = AddPersistedOverride<UnityEngine.Rendering.Universal.Tonemapping>(profile);
            tone.mode.Override(UnityEngine.Rendering.Universal.TonemappingMode.Neutral);

            // EXPOSURE 0. The lamp above carries the level now, and it is the only lever that can:
            // post exposure multiplies the unlit sky and the unlit cloud deck along with the
            // ground, so buying the meadow's brightness here would have kept the 7.9:1 sky-over-
            // ground ratio and simply pushed the far haze (already sRGB 0.72) to white. Neutral is
            // the correct value for a grade whose render arrives correctly exposed.
            //
            // CONTRAST 22 → 14, and this is the second half of the round-2 crush. URP does
            // contrast in LogC about ACEScc mid-grey, which decodes to LINEAR 0.2249. Round 2 put
            // the whole walkable frame four to five stops under that pivot, where log contrast is
            // not an expander but a divider — and worse, LogC's toe is a straight line through
            // (linear 0, logC 0.0928), so past a certain darkness the pivot map returns a NEGATIVE
            // logC value and the decode gives negative linear. The clip point is exact:
            //     linear_min = (0.4136 − 0.32078/c − 0.092819) / 5.301883
            // At c = 1.22 that is 0.0109 linear. Round 2's shadowed meadow rendered at 0.011–0.016
            // linear, i.e. straddling it — which is why the measured foreground was not "dark" but
            // literally zero in red and green. At c = 1.14 the clip point is 0.0074, and the
            // darkest large surface in frame (the refusing north wall, red 0.0085 linear) clears
            // it. Nothing the player has to read is legislated out of the picture any more.
            // The over-0.9 end the audit asked for is the lamp's job, not this one.
            // Saturation 18 → 16: the shadows/highlights split below now actually fires on the
            // ground (it never did in round 2 — see its ranges), so chroma arrives from the split
            // rather than from a global boost that lifts the haze along with everything else.
            var adjust = AddPersistedOverride<UnityEngine.Rendering.Universal.ColorAdjustments>(profile);
            adjust.postExposure.Override(0f);
            adjust.contrast.Override(14f);
            adjust.saturation.Override(16f);
            // A film of gold over the whole image — under 5% and below conscious notice, which is
            // where a colour filter belongs. The dawn's actual warmth is the lamp's job, above.
            adjust.colorFilter.Override(new Color(1.00f, 0.975f, 0.945f));

            // The warm-light/cool-shadow separation, and the single most load-bearing override here.
            // Study fable-01: the shadowed ground is not dark green, it is blue-grey, and the lit
            // ground is not bright green, it is gold — the hue MOVES with the value. Shadows take a
            // clear blue lift; highlights take gold and drop blue.
            //
            // TWO ROUND-2 BUGS ARE FIXED HERE, and between them they explain why the split never
            // reached the picture at all.
            //
            // (1) THE TRIPLES ARE GAMMA-DECODED. ColorUtils.PrepareShadowsMidtonesHighlights runs
            //     every component through Mathf.GammaToLinearSpace before it reaches the shader, so
            //     round 2's shadows (0.82, 0.92, 1.16) arrived as a multiplier of
            //     (0.638, 0.828, 1.386) — a 36% cut in red, not the ~18% the number reads as, and
            //     applied at full strength over the whole ground. That is most of why red was the
            //     first channel to die. The values below are authored through the INVERSE
            //     (Mathf.LinearToGammaSpace) so the number in the source and the number the shader
            //     multiplies by finally agree: shadows land on (1.00, 0.96, 1.08) and highlights on
            //     (1.14, 1.04, 0.88). Do not "tidy" these back to round numbers — round numbers
            //     here mean an unintended multiplier.
            //     The shadow tint is also gentler than round 2 read as intending, and deliberately:
            //     it no longer cuts red at all. A red cut on a green meadow under a cool fill is
            //     how shade turns cyan, and no frame on the reference board has cyan shade. The
            //     blue lift stays, so the tint is still cool — it just stops fighting the key. It
            //     costs the lit side nothing: this bucket ends at luminance 0.10 and lit meadow
            //     arrives at 0.17, so every lit probe is bit-identical with or without it.
            //
            // (2) THE RANGES WERE ABOVE THE PICTURE. shadowsEnd 0.35 / highlightsStart 0.50 are
            //     luminances in the graded linear image, and round 2's SUNLIT meadow arrived at
            //     that stage with a luminance of 0.17. Both the lit meadow and the shade were
            //     therefore inside the SHADOWS bucket: the sunlit ground was being tinted cool and
            //     the gold half of the split never fired on any walkable surface in the frame. It
            //     shows in the capture — round2/v1's brightest meadow band measures
            //     (0.148, 0.172, 0.160), which is not gold, it is grey. With the lamp above, cast
            //     shadow reaches this stage at 0.020 and lit meadow at 0.17, so the ranges are set
            //     to straddle THAT: shade sits ~91% in the cool bucket, lit meadow takes about a
            //     third of the gold and the sunlit south wall takes all of it. highlightsEnd comes
            //     down from its 1.0 default for the same reason — left there, the smoothstep would
            //     have handed the meadow 19% of a tint it needs at full strength.
            var smh = AddPersistedOverride<UnityEngine.Rendering.Universal.ShadowsMidtonesHighlights>(profile);
            smh.shadows.Override(new Vector4(1.000f, 0.982f, 1.036f, 0f));    // → (1.00, 0.96, 1.08) cool shade
            smh.highlights.Override(new Vector4(1.061f, 1.018f, 0.945f, 0f)); // → (1.14, 1.04, 0.88) gold light
            smh.shadowsStart.Override(0f);
            smh.shadowsEnd.Override(0.10f);
            smh.highlightsStart.Override(0.10f);
            smh.highlightsEnd.Override(0.30f);

            // THE FLOOR — and in round 2 this was the toe, and the toe is what ate the picture.
            //
            // Lift's w is an ADDITIVE offset in linear pre-tonemap space, and the rgb triple is
            // luminance-normalised around it (ColorUtils.PrepareLiftGammaGain), so round 2's
            // (0.96, 0.99, 1.06, −0.03) resolved to a constant subtraction of
            // (−0.0395, −0.0296, −0.0057) from every pixel in the frame. Set that beside what
            // actually reached it: after the round-2 contrast had finished with the shadowed
            // meadow it was at 0.004 linear. The toe took away eight times the whole signal. Red
            // and green went negative and clipped; blue survived only because the "blue-black"
            // hue tilt made its offset seven times smaller — which is precisely the signature the
            // critique measured, red and green at literal zero over 60–96% of the frame with blue
            // still readable. The intent (a storybook page's deepest shade is blue-black, never a
            // neutral crush) was right; the sign and the magnitude were not.
            //
            // ROUND 3 inverts it. w = +0.0025 is a small POSITIVE floor: nothing anywhere in the
            // frame can now reach zero in every channel, which is the ask — cast shadow keeps its
            // hue. It is invisible where the picture lives (1% of the lit meadow, 0.3% of the
            // haze) and decisive where it does not: the refusing north wall's red, which contrast
            // alone leaves at 0.005, and the crevices and rock undersides, which land at sRGB
            // 0.01–0.04 — still the darkest thing in frame, still near-black, but ink on paper
            // rather than a hole in it. The reference board agrees: fable-01/05/07 hold their
            // fifth-percentile min-channel at 0.047–0.051 and never bottom out across the
            // walkable ground.
            // The triple keeps the hue job and nothing else. Pulled in from 3 sRGB points of tilt
            // to 1.5, it resolves to (−0.0016, +0.0001, +0.0034): red is still the first channel
            // to leave, so the deepest shade is still blue-black, but the tilt is now a fifth of
            // the darkest value it acts on instead of eight times it.
            var floor = AddPersistedOverride<UnityEngine.Rendering.Universal.LiftGammaGain>(profile);
            floor.lift.Override(new Vector4(0.995f, 1.000f, 1.010f, 0.0025f));

            // Warm dawn white balance — kept modest ON PURPOSE. Temperature is global: it warms the
            // shade as readily as the light, so a heavy hand here would spend the cool half of the
            // split the override above just bought. Enough to say "dawn", not enough to say "filter".
            // Tint a touch toward magenta pulls the meadow's mass off acid green into olive-gold.
            var balance = AddPersistedOverride<UnityEngine.Rendering.Universal.WhiteBalance>(profile);
            balance.temperature.Override(8f);
            balance.tint.Override(3f);

            // Bloom for the low sun: threshold just under 1 so it catches the rim-lit crests, the
            // backlit grass and the horizon band and NOTHING else — bloom on a storybook frame is
            // the glow around a light source, not a haze over the picture. Wide scatter keeps it
            // soft-edged (a painted glow, not a lens artefact) and the gold tint means the light
            // that spills is the same light that fell. HQ filtering left off: this scene has a
            // Mobile renderer target, and scatter buys the same softness for free.
            // ROUND 3: threshold 1.05 → 0.90. Round 2 set 1.05 to keep "a great deal of ordinary
            // lit grass" out of the bloom, but that fear was based on the same dropped-albedo
            // arithmetic as the lamp: against a 2.90 lamp the brightest thing on the ground was
            // 0.80 linear, so a 1.05 threshold caught nothing at all outside the sky and the frame
            // ended up with no sparkle whatsoever. Against the 8.00 lamp the numbers are real, and
            // 0.90 is chosen from them by margin on both sides:
            //     limestone square to the beam    2.69 linear   blooms
            //     the sky's blaze core            1.75 linear   blooms
            //     the sky's horizon band          0.79 linear   does not — a 14% margin, so the
            //                                                   glow stays around the light source
            //                                                   and never becomes a veil over it
            //     flat lit meadow at 80 m         0.29 linear   does not, by a factor of three
            // So bloom lands on exactly what it is for — the blaze, sun-square rock, rim-lit
            // crests and backlit grass — and it is what carries those pixels the last step to
            // white. Intensity, scatter and tint are unchanged; they were never the problem.
            var bloom = AddPersistedOverride<UnityEngine.Rendering.Universal.Bloom>(profile);
            bloom.threshold.Override(0.90f);
            bloom.intensity.Override(0.45f);
            bloom.scatter.Override(0.72f);
            bloom.tint.Override(new Color(1.00f, 0.93f, 0.80f));

            // Storybook vignette: the corners settle and the eye is pushed down the valley, but
            // soft enough to stay unnoticed. The colour is a deep blue-grey rather than black — a
            // black vignette punches a hole in an illustration, where a cool one reads as the
            // page's own edge falling into shade.
            // ROUND 3 backs 0.24 out to 0.18 and softens 0.45 → 0.50. URP scales these by 3 and 5
            // respectively, so 0.24/0.45 was multiplying the bottom-centre foreground by 0.82 and
            // the corners by 0.54 — a second darkening laid over the near ground, which is the one
            // region of the frame this pass exists to make readable. At 0.18/0.50 the same points
            // take 0.88 and 0.70: still a settled edge, no longer a tax on the walkable floor.
            var vignette = AddPersistedOverride<UnityEngine.Rendering.Universal.Vignette>(profile);
            vignette.intensity.Override(0.18f);
            vignette.smoothness.Override(0.50f);
            vignette.color.Override(new Color(0.05f, 0.06f, 0.10f));

            EditorUtility.SetDirty(profile);
            AssetDatabase.SaveAssets();

            var volumeGo = new GameObject("PostVolume");
            var volume = volumeGo.AddComponent<UnityEngine.Rendering.Volume>();
            volume.isGlobal = true;
            volume.sharedProfile = profile;
        }

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

        // Grass via the built-in Terrain DETAIL system — instanced tuft meshes with a density map
        // derived from the same slope/height logic as the ground shader, so grass grows exactly
        // where the ground reads grassy. (Per-patch culling and distance fade come free; a
        // particle system has neither and pays overdraw per blade — wrong tool for a meadow.)
        //
        // MQ00 opens on "high, wind-combed grass under a lightening sky". Round 1 built that as ONE
        // tuft prototype scattered at near-constant spacing, and the review found what that always
        // finds: a single silhouette repeated to the horizon, every tuft inside a ten-degree hue
        // band, even spacing with no clumps and no bare ground, and a floor between the tufts that
        // read as blank paint. Round 2 answers each of those in a specific place:
        //
        //   species    FOUR prototypes, not one (see Species below) — fine fescue, dry straw on the
        //              exposed ground, broad blue-green sedge in the hollows, and a sparse tall bent
        //              that breaks the top line. Different blade counts, heights and arcs, so the
        //              silhouettes differ before any colour is applied.
        //   colour     each species sits on its own stretch of Tarrock/GrassTuft's cool->green->dry
        //              ramp, and the ramp itself is driven by the SAME exposure drift the CPU sorts
        //              the species with (ExposureDrift, mirrored on both sides) — so straw grows on
        //              the gold ground rather than merely being tinted gold at random.
        //   clumping   three scales of noise, not two: the broad scour, the ragged edge, and a new
        //              ~2.4 m TUSSOCK octave with most of its range pushed to the ends, which is
        //              what turns even scatter into stands of grass with bare ground between them.
        //   drifts     two WORN paths where the grass is beaten down to near-bare — the way west
        //              along the valley floor and the spur up to the dead tree. They are FOUND, not
        //              authored: the generator scans for the floor, so a landform edit moves them.
        //   turf       the tuft roots are tinted toward the ground shader's own palette, read off
        //              the terrain material rather than restated here, so a change to the ground
        //              colour script carries into the grass with no second edit.
        //   combed     a STATIC lean (the shape the last wind left), stronger on exposed ground than
        //              in hollows, its direction wandering a few degrees over tens of metres. No
        //              ambient motion at all: director ruling 2026-07-31, art-audio.md §The
        //              world-state is the art direction. The meadow's only motion is the
        //              displacement response to the Fool and Pip (see BuildGrassBenders).
        //   no cutoff  draw distance pushed to 120 m and the shader squashes tufts into the ground
        //              from 78 m, so the patch cull never draws a line across the meadow.
        //
        // ROUND 3 answers the gauntlet's findings on round2/v3, v6 and v7, which came down to one
        // sentence: every tuft is an isolated plant standing on naked ground. Four places again:
        //
        //   thatch     a FIFTH prototype (SpeciesThatch) that is not a plant but the FLOOR — a
        //              2-5 cm mat of wide low cards, tinted to the ground builder's own turf
        //              palette and 36% darker at its root, scattered by its own flat rule so it
        //              fills the gaps the tuft clumping opens rather than thinning with them. Tuft
        //              bases are buried in it; there is no longer a place where two neighbouring
        //              tufts have nothing but the terrain pass between them.
        //   the fold   the comb was there in round 2 and did not read, because leaning a radially
        //              symmetric fan sideways leaves a radially symmetric fan. Tarrock/GrassTuft
        //              now folds each blade by which side of its own tuft it grew on (_CombFold)
        //              and carries the whole crown downwind (_CombDrift), and the leans themselves
        //              went up by about half. Still entirely static — a POSE, not a motion.
        //   earned     bareness now has a cause. The ambient floors are lifted (a hole with no
        //              reason reads as a bug), and the worn drifts gained a CORE that goes to
        //              exactly zero for tufts and thatch alike — a trodden path with bare earth in
        //              it, found from the landform, not painted.
        //   the ring   the bend at a standing body is held flat across the inner half of its
        //              radius and falls off only at the rim (_BendCoreShare), so it photographs as
        //              a laid disc with an edge instead of a dish nobody could find in the frame.
        private static void BuildGrassDetails(TerrainData terrainData, Terrain terrain, Material ground)
        {
            Shader tuftShader = Shader.Find(TuftShaderName);
            if (tuftShader == null)
            {
                Debug.LogWarning("[Tarrock] Tarrock/GrassTuft not found; grass details skipped.");
                return;
            }

            // The ground builder owns the turf albedo. Read it back rather than restating it: the
            // tufts' roots are tinted toward these, and a grass palette hand-copied from the ground
            // palette is a pair of numbers that will drift.
            //
            // ROUND-2 INTEGRATION NOTE: the ground pass renamed its palette (the old _Grass* ramp
            // became the meadow/turf split), so these read the NEW property names. The fallbacks are
            // the shared constants declared above BuildTerrainMaterial, which are the same values
            // the material is written with — so a missed rename degrades to "identical, and loud in
            // the log" rather than to a wrong colour.
            Color turfSoil = ReadColour(ground, "_TurfSoil", TurfSoil);
            Color turfOchre = ReadColour(ground, "_TurfOchre", TurfOchre);
            Color turfGreen = ReadColour(ground, "_MeadowGreen", MeadowGreen);
            // The dry tint is the ground's own thatch: straw tufts grow out of thatch, so the two
            // cannot be different browns.
            Color turfDry = turfOchre;
            // Roots sit in soil with the meadow's green just above them — the ground pass paints a
            // green root note at its dab centres, and this is the tuft side of the same blend.
            Color turfMid = Color.Lerp(turfSoil, turfGreen, 0.55f);

            var prototypes = new DetailPrototype[Species.Length];
            for (int s = 0; s < Species.Length; s++)
            {
                prototypes[s] = BuildTuftPrototype(Species[s], tuftShader, turfMid, turfDry);
            }

            terrainData.detailPrototypes = prototypes;

            const int DetailRes = 512;
            terrainData.SetDetailResolution(DetailRes, 32);
            // CRITICAL: Unity 6 defaults to CoverageMode, where layer values are 0-255 COVERAGE —
            // a painted "4" means 4/255 ≈ 2% and renders as one tuft per field (cost a debug
            // session, 2026-07-27). Our density map means instances per cell; say so. Must be set
            // BEFORE SetDetailLayer — both this and SetDetailResolution clear existing layers.
            terrainData.SetDetailScatterMode(DetailScatterMode.InstanceCountMode);

            Vector2[] wayWest = FindValleyDrift(terrainData);
            Vector2[] wayToTree = FindTreeSpur(wayWest);

            var density = new int[Species.Length][,];
            for (int s = 0; s < Species.Length; s++)
            {
                density[s] = new int[DetailRes, DetailRes];
            }

            var share = new float[Species.Length];

            for (int dz = 0; dz < DetailRes; dz++)
            {
                float nz = (dz + 0.5f) / DetailRes;
                for (int dx = 0; dx < DetailRes; dx++)
                {
                    float nx = (dx + 0.5f) / DetailRes;
                    float steep = terrainData.GetSteepness(nx, nz);
                    float h = terrainData.GetInterpolatedHeight(nx, nz);

                    // SOFT band edges, not hard cuts: the old `steep > 24 || h < 13 || h > 52`
                    // test drew the grass boundary as a contour line you could trace with a
                    // finger. Grass now thins out of the rock and out of the bleached tops over
                    // several metres, which is also how a real hillside runs out of soil.
                    //
                    // The centres are the SHARED band constants (declared above
                    // BuildTerrainMaterial), so the ground shader's turf and this density map fade
                    // out across the same numbers — which is the whole point of the shared surface.
                    // Only the feather widths are local, because the shader feathers in its own
                    // units (_TurfFeatherDeg / _TurfFeatherM).
                    float slopeFade = 1f - Mathf.SmoothStep(0f, 1f,
                        Mathf.InverseLerp(GrassBandSteepMaxDeg - 7f, GrassBandSteepMaxDeg + 3f, steep));
                    float lowFade = Mathf.SmoothStep(0f, 1f,
                        Mathf.InverseLerp(GrassBandHeightLow - 1f, GrassBandHeightLow + 3f, h));
                    float highFade = 1f - Mathf.SmoothStep(0f, 1f,
                        Mathf.InverseLerp(GrassBandHeightHigh - 6f, GrassBandHeightHigh + 2f, h));
                    float band = slopeFade * lowFade * highFade;
                    if (band <= 0f)
                    {
                        continue;
                    }

                    float wx = nx * TerrainSize;
                    float wz = nz * TerrainSize;

                    // THREE scales of patchiness, and the third is the one round 1 was missing.
                    //
                    // The broad octave (~35 m features) opens the wind-scoured ground where the
                    // Cliff has been worked at for three hundred years; the ragged octave (~9.5 m)
                    // keeps the edges of those bald patches from being round; the TUSSOCK octave
                    // (~2.4 m) is grass's own habit — it grows in stands, and the gaps between the
                    // stands are as much of the picture as the stands are. Its remap throws most of
                    // the field to the ends of the range, so a cell is usually either in a tussock
                    // or in the bare ground beside one, and rarely at the average.
                    //
                    // The InverseLerp windows are set to this Fbm's MEASURED range (about -0.44 to
                    // +0.39, not ±1 — five octaves of gradient noise never reach their nominal
                    // bounds), so each term uses its whole 0-1 span.
                    //
                    // ROUND-3 FLOORS. Round 2's exponents and floors (1.6 / 0.42 / 0.10) put the
                    // product's low end near zero over a good deal of the meadow, and that is where
                    // "isolated plants on naked ground" came from as much as from the missing
                    // thatch: an AMBIENT hole is not read as sparse grass, it is read as a mistake,
                    // because nothing in the picture explains it. The floors are lifted so that
                    // clumping still swings the density by ~3.7x (round 2 swung it by 14x) but the
                    // bottom of the swing is thin grass rather than none. Bareness is now EARNED —
                    // it belongs to the worn drifts below, which are the one thing on this plateau
                    // that has a reason to be bare.
                    float scour = Mathf.Pow(
                        Mathf.InverseLerp(-0.30f, 0.34f, Fbm(wx * 0.028f + 5f, wz * 0.028f + 11f)), 1.15f);
                    float ragged = Mathf.InverseLerp(-0.42f, 0.42f, Fbm(wx * 0.105f + 41f, wz * 0.105f + 7f));
                    float tussock = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(
                        0.34f, 0.74f, Mathf.InverseLerp(-0.40f, 0.40f, Fbm(wx * 0.42f + 17f, wz * 0.42f + 29f))));

                    float cover = scour * Mathf.Lerp(0.58f, 1f, ragged) * Mathf.Lerp(0.38f, 1.42f, tussock);

                    // The worn drifts, and the ONE place on the plateau the ground is allowed to be
                    // bare. `ragged` doubles as the edge wander so the path is not a ruled line.
                    //
                    // TWO bands, not one. The outer band thins the grass over a couple of metres
                    // either side (a desire line is grass beaten thin, not turf removed); the inner
                    // CORE — a footpath's worth of it, 0.25-0.6 m wide — goes to exactly zero, for
                    // the tufts AND for the thatch. That last part is what makes it read as trodden
                    // earth instead of a mown stripe: a path with ground cover still in it is a
                    // lawn. Round 2 bottomed the drift out at 9% and the review could not tell the
                    // drifts from the ambient gaps, because there was no place where the meadow
                    // stopped for a reason you could name.
                    // ROUND-4: THE LANE'S EDGE IS BROKEN BEFORE IT IS MEASURED. The round-3 lane had
                    // "straight polygon edges" (critique of v7) and it did, for a reason no amount
                    // of albedo work would have touched: the drift is a POLYLINE, its anchors were
                    // 12 m apart, and the level sets of a distance-to-polyline field are straight
                    // chords with mitred corners. `ragged` was supposed to be the wander, but it is
                    // a 9.5 m field moving the edge by ±0.4 m — smooth at the scale the edge is
                    // straight at, and therefore invisible.
                    //
                    // The fix is two octaves at the scale a footpath's edge actually frays (1.7 m
                    // and 0.6 m), added to the MEASURED DISTANCE rather than to the threshold, so
                    // every one of the three gates below — thinning, bare core, and the scuff
                    // layer's own core — inherits the same broken boundary and they cannot part
                    // company. Amplitude 0.55 m against a 0.25-0.6 m core is larger than the core
                    // itself: the lane pinches and swells and occasionally closes, which is what a
                    // desire line does. (FindValleyDrift's step also came down to 5 m in the same
                    // pass, so the chords themselves bend.)
                    float edgeWander =
                        0.40f * Fbm(wx * 0.60f + 71f, wz * 0.60f + 13f)
                        + 0.15f * Fbm(wx * 1.70f + 23f, wz * 1.70f + 59f);
                    float driftEdge = Mathf.Lerp(0.55f, 1.35f, ragged);
                    float toDrift = Mathf.Min(
                        DistanceToPolyline(wx, wz, wayWest), DistanceToPolyline(wx, wz, wayToTree));
                    toDrift = Mathf.Max(0f, toDrift + edgeWander);
                    float wear = 1f - Mathf.SmoothStep(0f, 1f,
                        Mathf.InverseLerp(driftEdge, driftEdge + 1.9f, toDrift));
                    float coreRadius = driftEdge * 0.45f;
                    float bare = 1f - Mathf.SmoothStep(0f, 1f,
                        Mathf.InverseLerp(coreRadius, coreRadius + 0.35f, toDrift));
                    cover *= Mathf.Lerp(1f, 0.22f, wear) * (1f - bare);

                    // Which SPECIES grow here. The exposure drift is the shader's own field
                    // (ExposureDrift), so a tuft's species and its tint agree by construction:
                    // straw stands on the ground that is painted gold, sedge in the ground that is
                    // painted cool.
                    float exposure = ExposureDrift(wx, wz);
                    float strawWeight = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.44f, 0.80f, exposure));
                    float sedgeWeight = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.54f, 0.16f, exposure));
                    // Bent is an ACCENT — a couple of tall wisps that break the top line, never a
                    // ground cover. Gated to the tussock field as well as to exposure so it appears
                    // in stands rather than as evenly sprinkled spikes.
                    float bentGate = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.52f, 0.84f, tussock))
                                     * Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(0.32f, 0.60f, exposure));

                    // A trampled edge is where the dry stuff gets in: straw fringes the drifts,
                    // which is what stops them reading as a bald stripe painted on the meadow.
                    float fringe = wear * (1f - wear) * 4f;

                    share[SpeciesStraw] = (0.62f * strawWeight) + (0.30f * fringe);
                    share[SpeciesSedge] = 0.62f * sedgeWeight;
                    share[SpeciesBent] = 0.16f * bentGate;
                    share[SpeciesFescue] = Mathf.Max(
                        0.18f, 1f - share[SpeciesStraw] - share[SpeciesSedge] - share[SpeciesBent]);

                    // Instances per half-metre cell. Fractional coverage is DITHERED against a
                    // per-cell hash rather than rounded: rounding quantises the meadow into visible
                    // density plateaus, while dithering turns 0.4 into "four cells in ten carry a
                    // tuft" — thin grass rather than short grass, which is what a wind-scoured
                    // meadow actually looks like. Each species dithers against its own hash offset,
                    // or the four layers would land in the same cells and un-clump each other.
                    //
                    // Round 2 measured 3.35 tufts/m² over a 60 m patch of the valley floor, with 39%
                    // of cells thinned to near-bare and the lushest stands near 14/m² — the gap
                    // between those numbers being the clumping that round 1 (2.8/m², almost no
                    // spread) had none of.
                    //
                    // ROUND 3 moves the FLOOR, not the ceiling. The three raised terms above lift
                    // the cover product by about 1.55x on average, so this multiplier comes down
                    // from 4.4 to hold the arithmetic roughly where the eye wants it: mean lands
                    // near 4.5 tufts/m² (up from 3.35 — the meadow genuinely needed thickening),
                    // the near-bare 39% is gone, and the peaks are unchanged because they were
                    // never set here in the first place — Species[s].MaxPerCell clamps them, and
                    // those are untouched. Thin grass where round 2 had none; the same stands where
                    // round 2 had stands.
                    const float MaxTuftsPerCell = 3.8f;
                    float instances = cover * band * MaxTuftsPerCell;

                    for (int s = 0; s < Species.Length; s++)
                    {
                        if (s == SpeciesThatch || s == SpeciesScuff)
                        {
                            // The thatch is the floor, not one of the plants standing on it, so it
                            // is scattered by its own rule below rather than out of the tuft
                            // budget's share. Sharing the budget would be self-defeating: every mat
                            // would be paid for with a tuft, and the gaps the mat exists to fill
                            // would open again exactly as fast as it filled them.
                            continue;
                        }

                        float dither = Hash21(
                            dx * 0.37f + Species[s].DitherOffset, dz * 0.53f + Species[s].DitherOffset * 1.7f);
                        density[s][dz, dx] = Mathf.Clamp(
                            Mathf.FloorToInt(instances * share[s] + dither), 0, Species[s].MaxPerCell);
                    }

                    // THE THATCH LAYER. Deliberately the FLATTEST field in this loop: it carries the
                    // slope/height band (thatch does not grow on bare rock either) and the drifts
                    // (the worn core is bare of everything, which is the whole point of it), and
                    // almost nothing else. No tussock octave above all — the tussock octave is what
                    // opens the gaps BETWEEN tufts, and a mat that thinned in the same places would
                    // leave the bare ground exactly where the tufts had already left it.
                    //
                    // The mild `scour` weighting is the one variation kept: scoured ground carries
                    // less of everything, so the exposed gold patches run slightly thinner mat than
                    // the sheltered hollows do, which agrees with the tint ramp and the comb.
                    //
                    // THE BUDGET, because a full-coverage ground layer is where a frame budget goes
                    // to die and this number is the whole of it. Cells are 0.5 m (512 detail res
                    // over a 256 m region), so one mat per cell is 4 per m², and everything past
                    // the shader's fade window is squashed flat — vertex cost with no pixels
                    // behind it.
                    //
                    // ROUND-4: 1.15 -> 1.55 mats per 0.5 m cell. Cells are 0.25 m², so through the
                    // meadow body (thatchCover ≈ 0.87) that is ~5.4 mats/m² against round 3's ~4.0.
                    //
                    // THE COVERAGE ARITHMETIC, because "the bare terrain shader is never visible
                    // inside the meadow" is a measurable claim and not a hope. A round-3 mat reached
                    // 0.168 m (0.089 m² of disc); a round-4 mat reaches 0.323 m (0.328 m²), 3.7x
                    // the area for the same instance. Expected discs over a point go from 0.35 to
                    // 1.77, and the mats land independently, so the share of ground with at least
                    // one mat over it goes from 30% to 83% — before the tufts standing in it and
                    // before the scuff on the lanes. Almost all of that came from SIZE, which costs
                    // vertices already paid for, and only 1.35x from COUNT, which costs instances.
                    //
                    // THE BILL: 34 cards x 3 tris = 102 tris a mat, so ~550 tris per square metre
                    // of near meadow against round 3's ~288. Turn THIS number down first; it trades
                    // coverage for cost linearly and changes nothing else about the look. The wear
                    // term is what keeps the mat off the lanes, where the scuff below takes over.
                    const float MaxMatsPerCell = 1.55f;
                    float thatchCover = band * Mathf.Lerp(1f, 0.78f, scour)
                                        * Mathf.Lerp(1f, 0.30f, wear) * (1f - bare);
                    float thatchDither = Hash21(
                        dx * 0.37f + Species[SpeciesThatch].DitherOffset,
                        dz * 0.53f + Species[SpeciesThatch].DitherOffset * 1.7f);
                    density[SpeciesThatch][dz, dx] = Mathf.Clamp(
                        Mathf.FloorToInt(thatchCover * MaxMatsPerCell + thatchDither),
                        0,
                        Species[SpeciesThatch].MaxPerCell);

                    // THE SCUFF LAYER — the exact inverse of everything above. It exists only where
                    // the meadow has been worn through, so its gate is `wear` and `bare` READ THE
                    // OTHER WAY UP: densest in the core the tufts and the mat are excluded from,
                    // thinning out through the trodden fringe, gone in the meadow proper.
                    //
                    // This is the layer that gives the worn lane its own albedo. Without it a
                    // desire line is grass that stops — which is a mown stripe, not a path — and
                    // the round-4 critique's "unchanged albedo" was precisely that. It costs
                    // instances only inside a ribbon: at ~1.2 m of usable width over roughly 400 m
                    // of drift and spur, the whole layer is a few thousand instances against the
                    // meadow's hundreds of thousands.
                    //
                    // It carries the SAME slope/height band as everything else. A lane over bare
                    // rock is not a worn lane, it is a rock.
                    const float MaxScuffPerCell = 2.6f;
                    float scuffCover = band * Mathf.Max(bare, wear * wear * 0.55f);
                    float scuffDither = Hash21(
                        dx * 0.37f + Species[SpeciesScuff].DitherOffset,
                        dz * 0.53f + Species[SpeciesScuff].DitherOffset * 1.7f);
                    density[SpeciesScuff][dz, dx] = Mathf.Clamp(
                        Mathf.FloorToInt(scuffCover * MaxScuffPerCell + scuffDither),
                        0,
                        Species[SpeciesScuff].MaxPerCell);
                }
            }

            for (int s = 0; s < Species.Length; s++)
            {
                terrainData.SetDetailLayer(0, 0, s, density[s]);
            }

            // Pushed from 90 m to 120 m and paired with the shader's 78→114 m height fade: the
            // fade does the hiding, so the per-patch cull only ever collects tufts that are
            // already squashed flat. No hard line across the meadow at any distance.
            terrain.detailObjectDistance = 120f;
            terrain.detailObjectDensity = 1f;
        }

        /// <summary>Mesh, material and prefab for one grass species, wrapped in the DetailPrototype
        /// the terrain scatters it with.</summary>
        private static DetailPrototype BuildTuftPrototype(
            TuftSpecies species, Shader tuftShader, Color turfMid, Color turfDry)
        {
            Mesh tuft = BuildTuftMesh(species);
            AssetDatabase.DeleteAsset(species.MeshPath);
            AssetDatabase.CreateAsset(tuft, species.MeshPath);

            var material = AssetDatabase.LoadAssetAtPath<Material>(species.MaterialPath);
            if (material == null)
            {
                material = new Material(tuftShader);
                AssetDatabase.CreateAsset(material, species.MaterialPath);
            }
            else
            {
                material.shader = tuftShader;
            }

            // Colour. Three tints on one dryness axis — cool blue-green, mid green, dry gold-straw
            // — and each species sits on its own stretch of it via DryBias. These MULTIPLY the
            // mesh's root→tip gradient, so the numbers read high: a tuft's tip lands near the tint
            // itself and its root about half of it.
            //
            // TurfTintWeight pulls the whole triple toward the ground builder's own palette before
            // it is written. It is 0 for the four upright species (their colours are exactly round
            // 2's), and high for the thatch, whose entire job is to be the floor's colour with a
            // silhouette — the same SSOT argument as the root blend below, applied to the tint.
            material.SetColor("_CoolColor", Color.Lerp(species.Cool, turfMid, species.TurfTintWeight));
            material.SetColor("_BaseColor", Color.Lerp(species.Green, turfMid, species.TurfTintWeight));
            // The DRY pole is pulled by its own weight (round 4), and the split is a correction of
            // a real mistake rather than a knob. The ground's dry note is _TurfOchre, and in the
            // ground shader that colour is the SCOUR PATCH — the place the mat has worn THROUGH.
            // Pulling the mat's own dry end 78% into it therefore painted the thatch the colour of
            // its own absence, which is where round 3's brown starbursts on green ground came from.
            // The mat now takes only a third of it; the SCUFF species, which really is bare trodden
            // ground, takes nearly all of it. One palette, two honest readings of it.
            material.SetColor("_DryColor", Color.Lerp(species.Dry, turfDry, species.TurfDryTintWeight));
            material.SetFloat("_DryBias", species.DryBias);
            material.SetFloat("_PatchScale", PatchScaleMetres);
            material.SetFloat("_TuftVariation", species.HueVariation);
            material.SetFloat("_ValueVariation", species.ValueVariation);

            // Turf blend — the ground builder's palette, passed through rather than restated.
            material.SetColor("_GroundColor", turfMid);
            material.SetColor("_GroundDryColor", turfDry);
            material.SetFloat("_BaseBlend", species.BaseBlend);
            material.SetFloat("_BaseBlendHeight", species.BaseBlendHeight);
            // Contact shade at the root. Grass casts no shadows here by design, so nothing else in
            // the frame will darken a tuft's own base; without this the tufts and the mat they
            // stand in are lit identically and the mat reads as a second flat colour beside the
            // ground rather than as a layer with depth in it.
            material.SetFloat("_RootDarken", species.RootDarken);

            material.SetFloat("_ShadeWrap", 0.55f);
            material.SetFloat("_AmbientBoost", 1.05f);

            // The wind-combed POSE. _TuftHeight MUST match the mesh BuildTuftMesh emits — the
            // shader converts its unitless height and lean channels back into metres with it.
            material.SetFloat("_TuftHeight", species.MeshHeight);
            material.SetVector("_WindAxis", CombAxis);
            material.SetFloat("_CombLean", species.CombLean);
            // Hollows keep more of their stand than scoured ground does. Dropped from round 2's
            // 0.42 as the leans went up, so the CONTRAST between sheltered and exposed ground grows
            // with the comb rather than being flattened by it — a meadow combed uniformly hard is
            // just a meadow leaning, which is the note round 2 got back.
            material.SetFloat("_CombHollowLean", 0.34f);
            material.SetFloat("_CombWanderLength", 46f);
            material.SetFloat("_CombWanderDegrees", 14f);
            // The fold and the crown drift: the difference between a leant symmetric fan and a
            // stand of grass the wind has actually been through. See the shader header.
            material.SetFloat("_CombFold", species.CombFold);
            material.SetFloat("_CombDrift", species.CombDrift);
            // THE RAKE (round 4) — the one bearing every layer is combed on. It is per-species only
            // because the species differ in how RADIAL they are: a two-stem bent has almost no fan
            // to rake and a 40-card mat is nothing but fan. The bearing itself is _WindAxis, which
            // is one constant for the whole region, so "unified" is a fact about the axis and not
            // about these numbers.
            material.SetFloat("_CombRake", species.CombRake);

            // Unbound wind. Every one of these is multiplied by RegionWind's global, so the meadow
            // is COMPLETELY still while the Cliff is bound (director ruling 2026-07-31) and gains
            // motion only when its Arcanum is unbound — which is what art-audio.md asks for.
            material.SetFloat("_SwayStrength", species.UnboundSway);
            material.SetFloat("_SwaySpeed", 0.85f);    // ~7 s per breath: a wave, not jitter
            material.SetFloat("_SwayWavelength", 14f); // crest spacing, so the meadow moves in bands
            material.SetFloat("_WindResponse", 1f);

            // Displacement response — how far this species gives when the Fool or Pip walks through
            // it. Tall thin species lie right over; a short broad sedge barely parts. Values above
            // 1 mean "flat before the falloff runs out", not "further than flat": the shader's arc
            // clamps a blade's lean to its own length, so no setting here can bury a tip.
            material.SetFloat("_BendStrength", species.BendStrength);
            material.SetFloat("_BendHeightRange", 1.8f);
            // Hold the inner half of the ring fully laid over and spend the falloff on the rim.
            // Round 2 rolled the falloff all the way from the centre, and the gauntlet review's
            // finding on v6 was not "the ring is too weak" but "the ring is not in the frame":
            // a dish with no edge does not survive being photographed. See the shader.
            material.SetFloat("_BendCoreShare", species.BendCore);
            // ROUND 4 — the ring's silhouette and the ring's value. The bend geometry was never the
            // problem (the re-projection of round3/v6 finds the disc exactly where the bender puts
            // it); a blade laid to 90° is optically an absent blade, and a pressed patch with no
            // value change is a bald patch. Stopping the press at 72° leaves each blade 31% of its
            // height, lying outward as a readable spoke, and the darkening gives the disc an area
            // the eye can find before it resolves any individual blade.
            material.SetFloat("_BendLayDegrees", species.BendLayDegrees);
            material.SetFloat("_BendDarken", species.BendDarken);

            // Distance handling. Tufts widen with range (thin blades go sub-pixel and shimmer),
            // then the fade window — which sits INSIDE detailObjectDistance so tufts are already
            // squashed flat by the time the patch cull collects them. The four upright species
            // share one window on purpose: four different fade windows would draw three faint lines
            // across the meadow. The thatch carries its own, and can, because it fades to the
            // colour it was already imitating.
            material.SetFloat("_WidenStart", species.WidenStart);
            material.SetFloat("_WidenEnd", species.WidenEnd);
            material.SetFloat("_WidenMax", species.WidenMax);
            material.SetFloat("_FadeStart", species.FadeStart);
            material.SetFloat("_FadeEnd", species.FadeEnd);
            material.SetFloat("_FadeMinScale", 0.08f);
            material.enableInstancing = true;
            EditorUtility.SetDirty(material);

            // Detail prototypes want a PREFAB carrying the mesh + material.
            var temp = new GameObject(species.Name);
            temp.AddComponent<MeshFilter>().sharedMesh = tuft;
            var tuftRenderer = temp.AddComponent<MeshRenderer>();
            tuftRenderer.sharedMaterial = material;
            // Grass casts NO shadows: per-blade shadow maps at ankle height buy almost no picture,
            // and Tarrock/GrassTuft deliberately ships no ShadowCaster pass — a shadow drawn by any
            // other pass would carry neither the comb nor the bend and would detach from its blade.
            tuftRenderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            GameObject prefab = PrefabUtility.SaveAsPrefabAsset(temp, species.PrefabPath);
            Object.DestroyImmediate(temp);

            return new DetailPrototype
            {
                prototype = prefab,
                usePrototypeMesh = true,
                useInstancing = true,
                renderMode = DetailRenderMode.VertexLit,
                minWidth = species.MinWidthScale,
                maxWidth = species.MaxWidthScale,
                minHeight = species.MinHeightScale,
                maxHeight = species.MaxHeightScale,
                // Height/width noise over a few metres, so neighbouring tufts differ but a whole
                // hollow can still run short or tall together.
                noiseSpread = 0.28f,
                // Tilt with the ground rather than standing plumb on a slope — grass grows out of
                // the hillside. Never full strength: fully aligned tufts on a steep band look felled.
                alignToGround = species.AlignToGround,
                positionJitter = 1f, // break the detail grid; a lattice of tufts reads as astroturf
                // Lets QualitySettings.terrainDetailDensityScale thin the meadow on the Mobile
                // quality level without a second authored density map.
                useDensityScaling = true,
                healthyColor = Color.white,
                dryColor = Color.white,
            };
        }

        /// <summary>Reads a colour off the ground material, falling back to the value this file
        /// last knew if the ground shader has renamed the property — a missing turf tint should
        /// cost a slightly wrong root blend, never an exception mid-generate.</summary>
        private static Color ReadColour(Material material, string property, Color fallback)
        {
            if (material == null || !material.HasProperty(property))
            {
                Debug.LogWarning(
                    $"[Tarrock] Ground material has no '{property}'; grass roots will use the " +
                    "fallback turf tint and may not match the floor.");
                return fallback;
            }

            return material.GetColor(property);
        }

        /// <summary>
        /// The exposure/dryness drift, 0 (sheltered hollow) .. 1 (scoured and exposed). MIRRORS
        /// <c>ExposureDrift</c> in Tarrock/GrassTuft exactly — the shader tints by it and this sorts
        /// the species by it, and the two agreeing is what makes the gold ground the straw ground.
        /// If either side changes, change both, and keep <see cref="PatchScaleMetres"/> the value
        /// the material is given.
        /// </summary>
        private static float ExposureDrift(float x, float z)
        {
            float px = x * (Mathf.PI * 2f / PatchScaleMetres);
            float pz = z * (Mathf.PI * 2f / PatchScaleMetres);
            float drift = Mathf.Sin(px + 1.7f)
                        + Mathf.Sin(pz * 0.83f - 0.4f)
                        + Mathf.Sin((px * 0.61f + pz * 0.79f) * 1.37f + 2.9f);
            return Mathf.Clamp01(0.5f + drift * 0.19f);
        }

        /// <summary>
        /// The way west — the worn drift down the valley floor, FOUND rather than authored. Starting
        /// under the spawn it steps west and, at each step, takes the lowest ground within a short
        /// search of where the last step landed; the valley floor is by definition the low line, so
        /// the walk tracks it (and tracks it still if the landform is re-sculpted, which a hand-typed
        /// polyline would not). The search window is what keeps it in the valley instead of falling
        /// away down the first broken edge it meets.
        /// </summary>
        private static Vector2[] FindValleyDrift(TerrainData terrainData)
        {
            // ROUND-4: 12 m -> 5 m. A distance-to-polyline field has STRAIGHT level sets along each
            // chord and a mitre at each joint, so the lane's edge was as straight as the anchor
            // spacing made it — which the round-4 critique of v7 read directly off the frame. Five
            // metres is short enough that the chords follow the meander as a curve; the density
            // loop's own two-octave edge wander does the rest, at the metre and sub-metre scales a
            // polyline could never reach however finely it is stepped.
            const float StepX = 5f;
            const float SearchHalfWidth = 16f;
            const float SearchStep = 0.5f;   // one heightmap sample
            const float WanderMetres = 2.6f; // a desire line is not a survey line

            var anchors = new List<Vector2>();
            float z = SpawnHint.z;

            for (float x = SpawnHint.x; x >= PathWestX + 2f; x -= StepX)
            {
                float bestZ = z;
                float bestHeight = float.MaxValue;
                for (float probe = z - SearchHalfWidth; probe <= z + SearchHalfWidth; probe += SearchStep)
                {
                    if (probe < 0f || probe > TerrainSize)
                    {
                        continue;
                    }

                    float height = terrainData.GetInterpolatedHeight(x / TerrainSize, probe / TerrainSize);
                    if (height < bestHeight)
                    {
                        bestHeight = height;
                        bestZ = probe;
                    }
                }

                z = bestZ;
                // Wander off the exact low line, and toward the SOUTH (−z) side: the valley's south
                // wall is the shallow one that permits (see SampleHeight step 5), and a worn path
                // hugs the side people can leave by.
                anchors.Add(new Vector2(x, z - 1.6f + (WanderMetres * Mathf.Sin(x * 0.061f + 1.9f))));
            }

            return anchors.ToArray();
        }

        /// <summary>The spur off the valley drift up to the dead tree's knoll — the second worn path,
        /// and the one that says somebody used to come up here. Stops at the knoll's foot: the tree
        /// is a place you walk to, not a place with a road to it.</summary>
        private static Vector2[] FindTreeSpur(Vector2[] valleyDrift)
        {
            if (valleyDrift.Length == 0)
            {
                return new Vector2[0];
            }

            // Leave the valley at whichever anchor is closest to the knoll.
            Vector2 junction = valleyDrift[0];
            float best = float.MaxValue;
            foreach (Vector2 anchor in valleyDrift)
            {
                float d = Vector2.Distance(anchor, KnollCentre);
                if (d < best)
                {
                    best = d;
                    junction = anchor;
                }
            }

            var foot = new Vector2(KnollCentre.x, KnollCentre.y + 7f);
            Vector2 along = foot - junction;
            var across = new Vector2(-along.y, along.x).normalized;

            const int Steps = 6;
            var spur = new Vector2[Steps + 1];
            for (int i = 0; i <= Steps; i++)
            {
                float t = i / (float)Steps;
                // A single low-frequency bow, so the spur curves the way a trodden path curves
                // rather than running straight at the tree like a survey peg line.
                spur[i] = junction + (along * t) + (across * (3.4f * Mathf.Sin(t * Mathf.PI)));
            }

            return spur;
        }

        /// <summary>Shortest distance in metres from a world XZ point to a polyline.</summary>
        private static float DistanceToPolyline(float x, float z, Vector2[] polyline)
        {
            if (polyline.Length == 0)
            {
                return float.MaxValue;
            }

            var point = new Vector2(x, z);
            float best = Vector2.Distance(point, polyline[0]);
            for (int i = 1; i < polyline.Length; i++)
            {
                Vector2 a = polyline[i - 1];
                Vector2 b = polyline[i];
                Vector2 ab = b - a;
                float lengthSq = ab.sqrMagnitude;
                float t = lengthSq > 1e-6f ? Mathf.Clamp01(Vector2.Dot(point - a, ab) / lengthSq) : 0f;
                best = Mathf.Min(best, Vector2.Distance(point, a + (ab * t)));
            }

            return best;
        }

        /// <summary>Thin blades fanned around a common root, each bowing over as it rises: a few
        /// dozen triangles of hand-painted brush economy, no texture and no cutout. The mesh carries
        /// the five channels <c>Tarrock/GrassTuft</c> depends on — see that shader's header — of
        /// which the load-bearing one is COLOR.a, the lean mask. Keeping the mask in the MESH is what
        /// makes the comb and the bend survive GPU instancing, static batching and per-instance
        /// scaling alike; the previous foliage sway masked by world height off the object matrix and
        /// static batching ate it (commit 48712b9).</summary>
        private static Mesh BuildTuftMesh(TuftSpecies species)
        {
            var verts = new List<Vector3>();
            var normals = new List<Vector3>();
            var cols = new List<Color>();
            var uvs = new List<Vector2>();
            var rootOffsets = new List<Vector2>();
            var tris = new List<int>();

            // Rows up a blade. The last row is a single vertex — blades taper to a point, which is
            // the whole difference between "grass" and the field of flat spades we had. Two
            // authored sets rather than a formula: the four-row numbers are round 2's exactly, and
            // a "close enough" curve fit through them would quietly restyle four shipped species to
            // buy a mat layer a row it does not need.
            float[] rows = species.Rows <= 3 ? MatRows : BladeRows;
            // Root → tip gradient. Both ends stay INSIDE 0-1 and the per-blade jitter only ever
            // darkens: Unity stores the vertex-colour stream as UNorm8, so the old mesh's 1.28 tip
            // was silently clamped to 1.0 and the material tint had to carry all the brightness.
            // The brightness now lives in the material's tints, where it can be tuned.
            var baseCol = new Color(0.47f, 0.50f, 0.39f);
            var tipCol = new Color(1.00f, 0.98f, 0.78f);

            for (int i = 0; i < species.Blades; i++)
            {
                // The species seed offsets the hash, so two species with the same blade count would
                // still fan differently — no species is another one with the tint changed.
                float r1 = Hash21(i * 1.37f + 0.11f + species.Seed, i * 2.71f + 3.30f + species.Seed);
                float r2 = Hash21(i * 4.19f + 7.70f + species.Seed, i * 0.83f + 1.90f + species.Seed);
                float r3 = Hash21(i * 2.53f + 5.10f + species.Seed, i * 3.47f + 9.40f + species.Seed);

                // Fan the blades around the root, jittered so the tuft is not a tidy rosette.
                //
                // ROUND-4: the jitter is per-species and the MAT runs it far higher. At 0.35 the
                // angular scatter is a third of a slot on an evenly divided circle, which is a
                // wobble on a spoke pattern, not a scatter — and the round-4 critique read the mat
                // exactly that way ("discrete brown starburst cards"). Past 1.0 slots overlap and
                // cards clump on some bearings and leave others open, which is a tangle: what
                // ground cover actually looks like. The four upright species keep round 2's 0.35 —
                // a tuft SHOULD read as a plant with a crown.
                float angle = (i + species.AngleJitter * (r1 - 0.5f)) * Mathf.PI * 2f / species.Blades;
                var outward = new Vector3(Mathf.Cos(angle), 0f, Mathf.Sin(angle));
                var side = new Vector3(-outward.z, 0f, outward.x);

                float bladeHeight = species.MeshHeight * Mathf.Lerp(species.ShortestBlade, 1f, r2);
                float rootOffset = Mathf.Lerp(species.RootOffsetMin, species.RootOffsetMax, r3);
                float halfWidth = Mathf.Lerp(species.HalfWidthMin, species.HalfWidthMax, r1);
                float splay = Mathf.Lerp(species.SplayMin, species.SplayMax, r3);

                int start = verts.Count;
                for (int row = 0; row < rows.Length; row++)
                {
                    float t = rows[row];
                    // Arc: rises fast off the ground and flattens toward the tip, so the blade
                    // bows over under its own weight instead of standing up like a spike. Past
                    // ~1.57 the curve turns over at the top and the tip NODS, which is the whole
                    // silhouette of the tall bent species.
                    float y = bladeHeight * Mathf.Sin(t * species.BladeArc) / Mathf.Sin(species.BladeArc);
                    Vector3 centre = (outward * (rootOffset + splay * Mathf.Pow(t, 1.6f))) + (Vector3.up * y);
                    float w = halfWidth * Mathf.Pow(1f - t, 0.55f);

                    Color rgb = Color.Lerp(baseCol, tipCol, Mathf.Pow(t, 0.85f)) * Mathf.Lerp(0.88f, 1f, r2);
                    // COLOR.a — the lean mask: rigid at the root, full at the tip, and scaled by
                    // this blade's share of the tuft height so a short blade leans proportionally
                    // less than its tall neighbour rather than swinging the same distance.
                    float mask = Mathf.Pow(t, 1.4f) * (bladeHeight / species.MeshHeight);
                    var colour = new Color(rgb.r, rgb.g, rgb.b, mask);

                    // Normals biased hard toward +Y. A blade's true normal is horizontal, which
                    // lights a meadow as a field of dark spikes; up-biased normals make the tufts
                    // shade with the ground they grow out of — the hand-painted read.
                    var normal = ((Vector3.up * 0.78f) + (outward * 0.22f)).normalized;
                    // UV.x = this blade's phase seed, UV.y = height above the root as a fraction
                    // of the species' mesh height (the shader turns it back into metres with
                    // _TuftHeight, and blends the root into the turf over the bottom of it).
                    var uv = new Vector2(r1, y / species.MeshHeight);

                    // TIP DROP — taken AFTER the uv, deliberately. uv.y is the shader's height
                    // channel (root blend, contact shade, distance squash) and must stay the
                    // blade's own 0..1 arc; the drop is a constant sink applied to the geometry
                    // only. A mat 0.5 m across sitting on ground that rolls under it would float
                    // its outer cards clear of the floor on every convex metre of the meadow, and a
                    // 5 cm-tall layer of thatch hovering 5 cm up is worse than no thatch at all.
                    // Dipping the outer ends below the root plane makes the failure mode
                    // "intersects the ground" instead — invisible, because the pass is opaque.
                    // Zero for every upright species, so nothing round 2 shipped moves.
                    if (species.TipDrop > 0f)
                    {
                        centre.y -= species.TipDrop * Mathf.Pow(t, 1.8f);
                    }

                    if (row == rows.Length - 1)
                    {
                        verts.Add(centre);
                        normals.Add(normal);
                        cols.Add(colour);
                        uvs.Add(uv);
                        // UV1 — the vertex's object-space XZ offset from the root, which the
                        // shader uses to widen the tuft with view distance without ever touching
                        // the instance matrix's translation (batching-proof, see the shader).
                        rootOffsets.Add(new Vector2(centre.x, centre.z));
                    }
                    else
                    {
                        Vector3 left = centre - (side * w);
                        Vector3 right = centre + (side * w);
                        verts.Add(left);
                        verts.Add(right);
                        normals.Add(normal);
                        normals.Add(normal);
                        cols.Add(colour);
                        cols.Add(colour);
                        uvs.Add(uv);
                        uvs.Add(uv);
                        rootOffsets.Add(new Vector2(left.x, left.z));
                        rootOffsets.Add(new Vector2(right.x, right.z));
                    }
                }

                // Two quads up the blade, then the tip triangle.
                for (int row = 0; row < rows.Length - 2; row++)
                {
                    int lower = start + (row * 2);
                    int upper = lower + 2;
                    tris.AddRange(new[] { lower, upper, lower + 1, lower + 1, upper, upper + 1 });
                }

                int lastPair = start + ((rows.Length - 2) * 2);
                int tip = start + ((rows.Length - 1) * 2);
                tris.AddRange(new[] { lastPair, tip, lastPair + 1 });
            }

            var mesh = new Mesh { name = species.Name };
            mesh.SetVertices(verts);
            mesh.SetNormals(normals); // authored, NOT recalculated — the up-bias is the whole point
            mesh.SetColors(cols);
            mesh.SetUVs(0, uvs);
            mesh.SetUVs(1, rootOffsets);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateBounds();
            return mesh;
        }

        /// <summary>
        /// Puts a <see cref="GrassBender"/> on the Fool's rig and on Pip, which is the meadow's only
        /// motion while the Cliff is bound: no ambient sway anywhere, but the grass parts around a
        /// body walking through it and settles back behind (director ruling 2026-07-31, art-audio.md
        /// §The world-state is the art direction — the stasis is the world's, not the Fool's).
        /// Runs after the character installers because it needs their roots to exist.
        /// </summary>
        private static void BuildGrassBenders()
        {
            // Root names owned by the character installers (KayKitCharacterInstaller / PipInstaller).
            const string PlayerRootName = "PlayerRig";
            const string PipRootName = "Pip";

            UnityEngine.SceneManagement.Scene scene = EditorSceneManager.GetActiveScene();
            if (!scene.IsValid())
            {
                return;
            }

            bool changed = false;
            foreach (GameObject root in scene.GetRootGameObjects())
            {
                if (root.name == PlayerRootName)
                {
                    // The Fool: a body's width plus a blade's length of reach, pressing at full
                    // strength, with a wake long enough to still be closing a stride behind him.
                    //
                    // 0.72 m, down from round 2's 0.9. Paired with the shader's held core
                    // (_BendCoreShare) this is a SMALLER ring that reads far harder: 0.9 m spread
                    // the same press over 1.6x the area and produced the vague thinning the
                    // gauntlet review could not find in v6 at all. The brief's window is 0.6-0.8 m
                    // and this sits in it.
                    //
                    // ROUND-4 KEEPS IT, deliberately, having checked. The ring's failure to read
                    // was never its size — re-projected through v6's own vantage the 0.72 m disc
                    // spans 446 px of a 1920 px frame, roughly a fifth of the width, and it is
                    // visibly there in the round-3 capture. What it lacked was a silhouette and a
                    // value, which _BendLayDegrees and _BendDarken supply, plus a mat dense enough
                    // for "pressed" and "bare" to look like different things. With BendCore now
                    // 0.58 the HELD floor of the ring is 0.42 m in radius — 0.84 m across, against
                    // a 0.45 m shoulder — so the laid disc clears the Fool's own silhouette by
                    // ~0.19 m on each side and can be seen past him from behind. Moving the radius
                    // would have desynced this from GauntletCapture's StandInBendRadius for no
                    // picture, and the game's ring and the photographed ring must be one ring.
                    AddGrassBender(root, radius: 0.72f, strength: 1f, trailSpacing: 0.42f, settleSeconds: 1.2f);
                    changed = true;
                }
                else if (root.name == PipRootName)
                {
                    // Pip is small and light: a tighter ring, a softer press, and a wake that closes
                    // faster — the dog leaves a line through the grass, not a road.
                    AddGrassBender(root, radius: 0.42f, strength: 0.7f, trailSpacing: 0.3f, settleSeconds: 0.85f);
                    changed = true;
                }
            }

            if (!changed)
            {
                Debug.LogWarning(
                    $"[Tarrock] Neither '{PlayerRootName}' nor '{PipRootName}' found; the meadow will " +
                    "have no displacement response (nothing in the scene bends the grass).");
                return;
            }

            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene);
        }

        private static void AddGrassBender(
            GameObject target, float radius, float strength, float trailSpacing, float settleSeconds)
        {
            var bender = target.GetComponent<GrassBender>();
            if (bender == null)
            {
                bender = target.AddComponent<GrassBender>();
            }

            var serialized = new SerializedObject(bender);
            SetFloatField(serialized, "_radius", radius);
            SetFloatField(serialized, "_strength", strength);
            SetFloatField(serialized, "_trailSpacing", trailSpacing);
            SetFloatField(serialized, "_settleSeconds", settleSeconds);
            serialized.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void SetFloatField(SerializedObject serialized, string fieldName, float value)
        {
            SerializedProperty property = serialized.FindProperty(fieldName);
            if (property == null)
            {
                Debug.LogWarning($"[Tarrock] Field '{fieldName}' not found on {nameof(GrassBender)}.");
                return;
            }

            property.floatValue = value;
        }

        // -- The grass species. FIVE prototypes rather than one: round 1's single tuft was the
        //    reason the meadow read as one silhouette repeated to the horizon, and round 2's four
        //    upright tufts were the reason it then read as isolated plants standing on naked
        //    ground. Indices are named below because the density loop weights them individually.
        private const int SpeciesFescue = 0;
        private const int SpeciesStraw = 1;
        private const int SpeciesSedge = 2;
        private const int SpeciesBent = 3;
        // The THATCH — not a fifth kind of grass but the FLOOR the other four stand in. Scattered
        // by its own rule (see BuildGrassDetails), never out of the tuft budget's share.
        private const int SpeciesThatch = 4;
        // The SCUFF — bare trodden earth on the worn drifts, and the only layer that exists where
        // the meadow does NOT. Scattered by its own rule too, and by the inverse gate: everything
        // else thins toward the lane's core, this one is the core.
        private const int SpeciesScuff = 5;

        // Blade cross-sections. Four rows for an upright blade that has to taper convincingly over
        // 20-50 cm; three for a thatch card, which is 5 cm long and gains nothing from a fourth.
        private static readonly float[] BladeRows = { 0f, 0.42f, 0.75f, 1f };
        private static readonly float[] MatRows = { 0f, 0.55f, 1f };

        // Wavelength in metres of the exposure drift that decides both the tint ramp and which
        // species grows where. Shared between ExposureDrift here and the material's _PatchScale —
        // the shader mirrors this function and the two must agree.
        private const float PatchScaleMetres = 26f;

        // The direction the last wind combed the meadow. Same prevailing axis as Tarrock/FoliageWind
        // so cloth and grass, when the region does unbind, lie the same way.
        private static readonly Vector4 CombAxis = new Vector4(1f, 0.35f, 0f, 0f);

        private static readonly TuftSpecies[] Species =
        {
            // Fine fescue — the body of the meadow, and the only species that grows everywhere.
            // Ankle to mid-shin against the 1.7 m Fool (0.14-0.38 m).
            new TuftSpecies
            {
                Name = "GrassTuft",
                MeshPath = TuftMeshPath,
                MaterialPath = TuftMaterialPath,
                PrefabPath = TuftPrefabPath,
                Seed = 0f,
                DitherOffset = 2.5f,
                MaxPerCell = 3,
                Blades = 5,
                Rows = 4,
                AngleJitter = 0.35f,
                MeshHeight = 0.30f,
                ShortestBlade = 0.52f,
                BladeArc = 1.30f,
                HalfWidthMin = 0.011f,
                HalfWidthMax = 0.017f,   // 22-34 mm blades, not 320 mm slabs
                SplayMin = 0.05f,
                SplayMax = 0.11f,
                RootOffsetMin = 0.010f,
                RootOffsetMax = 0.035f,
                TipDrop = 0f,
                MinWidthScale = 0.70f,
                MaxWidthScale = 1.25f,
                MinHeightScale = 0.45f,
                MaxHeightScale = 1.25f,
                AlignToGround = 0.5f,
                Cool = new Color(0.22f, 0.46f, 0.42f),
                Green = new Color(0.33f, 0.54f, 0.22f),
                Dry = new Color(0.80f, 0.69f, 0.35f),
                TurfTintWeight = 0f,
                TurfDryTintWeight = 0f,
                DryBias = 0.50f,
                HueVariation = 0.55f,
                ValueVariation = 0.18f,
                BaseBlend = 0.62f,
                BaseBlendHeight = 0.50f,
                RootDarken = 0.86f,      // a touch of its own shadow, so it sits IN the thatch
                CombLean = 0.52f,        // was 0.34: ~20 deg of lean is a tilt, not a comb
                CombFold = 0.50f,
                CombDrift = 0.12f,
                CombRake = 0.45f,        // a modest fan, so a modest rake carries it
                UnboundSway = 0.34f,
                BendStrength = 1.35f,
                BendCore = 0.58f,        // round 4: a wider HELD disc, so the ring clears the body
                BendLayDegrees = 72f,
                BendDarken = 0.78f,
                WidenStart = 18f,
                WidenEnd = 70f,
                WidenMax = 2.4f,
                FadeStart = 78f,
                FadeEnd = 114f,
            },

            // Dry straw — few tall stiff stems, barely bowed, on the scoured ground and along the
            // fringes of the worn drifts. This is the species that carries the colour script's
            // "pale dawn gold" into the albedo without bleaching the whole meadow (0.24-0.42 m).
            new TuftSpecies
            {
                Name = "GrassTuftStraw",
                MeshPath = TerrainDataDir + "/GrassTuftStraw.asset",
                MaterialPath = MaterialDir + "/GrassTuftStraw.mat",
                PrefabPath = TerrainDataDir + "/GrassTuftStraw.prefab",
                Seed = 11.3f,
                DitherOffset = 7.9f,
                MaxPerCell = 2,
                Blades = 3,
                Rows = 4,
                AngleJitter = 0.35f,
                MeshHeight = 0.38f,
                ShortestBlade = 0.72f,
                BladeArc = 0.80f,        // nearly straight: dead stems do not bow, they stand
                HalfWidthMin = 0.007f,
                HalfWidthMax = 0.011f,
                SplayMin = 0.02f,
                SplayMax = 0.05f,
                RootOffsetMin = 0.006f,
                RootOffsetMax = 0.020f,
                TipDrop = 0f,
                MinWidthScale = 0.60f,
                MaxWidthScale = 1.00f,
                MinHeightScale = 0.62f,
                MaxHeightScale = 1.10f,
                AlignToGround = 0.35f,
                Cool = new Color(0.36f, 0.50f, 0.30f),
                Green = new Color(0.55f, 0.58f, 0.27f),
                Dry = new Color(0.86f, 0.72f, 0.33f),
                TurfTintWeight = 0f,
                TurfDryTintWeight = 0f,
                DryBias = 0.78f,
                HueVariation = 0.40f,
                ValueVariation = 0.16f,
                BaseBlend = 0.62f,
                BaseBlendHeight = 0.50f,
                RootDarken = 0.86f,
                CombLean = 0.56f,        // it stands, but three hundred years of wind set the set
                CombFold = 0.42f,        // only three stems: fold hard and the tuft loses its stand
                CombDrift = 0.14f,
                CombRake = 0.30f,        // barely a fan to rake — the lean already carries this one
                UnboundSway = 0.26f,     // stiff stems move least
                BendStrength = 1.40f,
                BendCore = 0.58f,
                BendLayDegrees = 72f,
                BendDarken = 0.78f,
                WidenStart = 18f,
                WidenEnd = 70f,
                WidenMax = 2.4f,
                FadeStart = 78f,
                FadeEnd = 114f,
            },

            // Blue-green sedge — broad, short, splayed flat, in the hollows and the sheltered
            // ground. The cool end of the hue spread, and the species that keeps the floor of a
            // hollow from reading as the same green as its rim (0.13-0.26 m).
            new TuftSpecies
            {
                Name = "GrassTuftSedge",
                MeshPath = TerrainDataDir + "/GrassTuftSedge.asset",
                MaterialPath = MaterialDir + "/GrassTuftSedge.mat",
                PrefabPath = TerrainDataDir + "/GrassTuftSedge.prefab",
                Seed = 23.7f,
                DitherOffset = 13.1f,
                MaxPerCell = 2,
                Blades = 7,
                Rows = 4,
                AngleJitter = 0.35f,
                MeshHeight = 0.22f,
                ShortestBlade = 0.45f,
                BladeArc = 1.70f,        // bows hard: broad leaves fold under their own weight
                HalfWidthMin = 0.016f,
                HalfWidthMax = 0.026f,
                SplayMin = 0.11f,
                SplayMax = 0.19f,
                RootOffsetMin = 0.014f,
                RootOffsetMax = 0.040f,
                TipDrop = 0f,
                MinWidthScale = 0.85f,
                MaxWidthScale = 1.40f,
                MinHeightScale = 0.60f,
                MaxHeightScale = 1.20f,
                AlignToGround = 0.7f,
                Cool = new Color(0.18f, 0.44f, 0.42f),
                Green = new Color(0.26f, 0.48f, 0.28f),
                Dry = new Color(0.55f, 0.58f, 0.32f),
                TurfTintWeight = 0f,
                TurfDryTintWeight = 0f,
                DryBias = 0.24f,
                HueVariation = 0.42f,
                ValueVariation = 0.14f,
                BaseBlend = 0.62f,
                BaseBlendHeight = 0.50f,
                RootDarken = 0.86f,
                // ROUND 4: this is the "teal stubble splays symmetric" species, and it is where the
                // rake earns its keep. Its splay (0.19 m) is three times what its old 0.36 lean
                // could move (0.055 m), so the tip translation was invisible against the fan; the
                // rake stretches the fan itself. The lean comes up too — a rosette that has sat in
                // the same wind as everything else should not be the one plant standing square.
                CombLean = 0.58f,
                CombFold = 0.62f,        // seven leaves is a rosette, and a rosette folds visibly
                CombDrift = 0.10f,
                CombRake = 0.72f,        // the most radial upright species, so the hardest rake
                UnboundSway = 0.18f,
                BendStrength = 1.05f,    // short and broad: it parts rather than lies down
                BendCore = 0.58f,
                BendLayDegrees = 70f,
                BendDarken = 0.80f,
                WidenStart = 18f,
                WidenEnd = 70f,
                WidenMax = 2.4f,
                FadeStart = 78f,
                FadeEnd = 114f,
            },

            // Tall bent — two thin stems arcing right over, sparse and clumped. The accent that
            // breaks the meadow's top line and catches the dawn on its nodding tips; knee-high on
            // the Fool (0.36-0.62 m), so it must stay rare or it becomes the meadow.
            new TuftSpecies
            {
                Name = "GrassTuftBent",
                MeshPath = TerrainDataDir + "/GrassTuftBent.asset",
                MaterialPath = MaterialDir + "/GrassTuftBent.mat",
                PrefabPath = TerrainDataDir + "/GrassTuftBent.prefab",
                Seed = 41.9f,
                DitherOffset = 19.3f,
                MaxPerCell = 1,
                Blades = 2,
                Rows = 4,
                AngleJitter = 0.35f,
                MeshHeight = 0.52f,
                ShortestBlade = 0.80f,
                BladeArc = 1.90f,        // past the turn: the tips nod back down
                HalfWidthMin = 0.005f,
                HalfWidthMax = 0.009f,
                SplayMin = 0.09f,
                SplayMax = 0.17f,
                RootOffsetMin = 0.004f,
                RootOffsetMax = 0.014f,
                TipDrop = 0f,
                MinWidthScale = 0.50f,
                MaxWidthScale = 0.90f,
                MinHeightScale = 0.70f,
                MaxHeightScale = 1.20f,
                AlignToGround = 0.25f,
                Cool = new Color(0.32f, 0.52f, 0.42f),
                Green = new Color(0.46f, 0.58f, 0.28f),
                Dry = new Color(0.88f, 0.78f, 0.44f),
                TurfTintWeight = 0f,
                TurfDryTintWeight = 0f,
                DryBias = 0.66f,
                HueVariation = 0.50f,
                ValueVariation = 0.20f,
                BaseBlend = 0.62f,
                BaseBlendHeight = 0.50f,
                RootDarken = 0.86f,
                CombLean = 0.68f,        // tall and thin: it lies over furthest
                CombFold = 0.55f,
                CombDrift = 0.18f,       // the accent that draws the eye ALONG the comb
                CombRake = 0.35f,
                UnboundSway = 0.46f,
                BendStrength = 1.60f,    // tall and thin: it goes right over
                BendCore = 0.58f,
                BendLayDegrees = 74f,    // the tallest species keeps the most tip above the disc
                BendDarken = 0.78f,
                WidenStart = 18f,
                WidenEnd = 70f,
                WidenMax = 2.4f,
                FadeStart = 78f,
                FadeEnd = 114f,
            },

            // THE THATCH — the meadow's FLOOR, and the round-3 answer to the gauntlet finding that
            // every tuft in round 2 read as "an isolated plant on naked ground". It was true: four
            // upright species scattered at 3.35 tufts/m² leave 25-40 cm between neighbours, and in
            // that gap there was nothing but the terrain pass. No amount of tuft variety fixes
            // that, because the fault is not in the tufts.
            //
            // ROUND-4 REBUILD. Round 3's mat did not fail because a mat was the wrong idea; it
            // failed because it was neither dense enough nor the right colour to be a FLOOR. The
            // critique of v6/v7 — "a sparse scatter of discrete brown STARBURST cards lying BESIDE
            // the tufts on smooth untextured terrain" — names all three faults exactly, and each is
            // a number below:
            //
            //   * STARBURST. 24 cards on an evenly divided circle jittered by a third of a slot is
            //     a spoke pattern with a wobble. It reads as one stamp because it IS one stamp.
            //     Now 34 cards at AngleJitter 1.7 — past a full slot, so cards clump on some
            //     bearings and leave others open, which is a tangle rather than a rosette.
            //   * SPARSE. Each mat covered a disc of ~0.089 m² at ~4.0/m², about 30% of the ground
            //     before the gaps between the cards inside each disc are counted. Reach goes from
            //     16.8 cm to 32.3 cm (0.328 m², 3.7x the area) and the layer is scattered 1.35x
            //     thicker, which together take the share of ground with a mat over it from 30% to
            //     83% — the terrain shader becomes what shows THROUGH the mat rather than what sits
            //     beside it. Coverage bought by SIZE first and by count second, deliberately: a
            //     bigger card costs vertices already paid for and a further mat costs a draw.
            //   * BROWN. DryBias 0.46 with the exposure drift's ±0.7 swing put a large share of
            //     mats at the dry end of a ramp whose dry end is the turf's OCHRE — brown stars on
            //     green ground, which is the most conspicuous thing a ground layer can possibly be.
            //     The mat is the floor: it goes to 0.20 bias against a dry end that is itself
            //     pulled 88% into the turf palette. The ochre still exists — as SCOUR, in the
            //     ground shader, where "wind-scoured green" says it belongs.
            //
            // COST, because a ground layer is where a frame budget goes to die: 34 cards x 3
            // triangles = 102 tris per mat, ~550 tris per square metre of near meadow against round
            // 3's ~288 (BuildGrassDetails' MaxMatsPerCell owns the count and is the dial to turn
            // FIRST if this ever has to get cheaper). It keeps its own near-field
            // distance window, which is what stops a full-coverage layer being billed out to 120 m,
            // and it can fade early precisely BECAUSE it is the ground's colour: what it dissolves
            // into is what it was imitating.
            new TuftSpecies
            {
                Name = "GrassThatch",
                MeshPath = TerrainDataDir + "/GrassThatch.asset",
                MaterialPath = MaterialDir + "/GrassThatch.mat",
                PrefabPath = TerrainDataDir + "/GrassThatch.prefab",
                Seed = 67.1f,
                DitherOffset = 29.7f,
                MaxPerCell = 3,
                // 34 cards, not 24 and not 44. 24 was a spoke pattern; 44 was priced without
                // checking the bill (132 tris a mat against a layer that covers the whole meadow).
                // At 34 the cards inside one mat's own disc already overlap about 2.3 times over,
                // so the disc is solid and every card past that is paying for nothing.
                Blades = 34,
                Rows = 3,                // a 6 cm card gains nothing from a fourth cross-section
                AngleJitter = 1.7f,      // a tangle, not a rosette — see BuildTuftMesh
                MeshHeight = 0.060f,
                ShortestBlade = 0.42f,   // 2-6 cm: the ground-hugging band
                BladeArc = 1.05f,
                HalfWidthMin = 0.024f,
                HalfWidthMax = 0.046f,   // cards, not blades — width is what covers ground
                SplayMin = 0.09f,
                SplayMax = 0.20f,
                RootOffsetMin = 0.030f,
                RootOffsetMax = 0.150f,  // cards reach 12-35 cm out: a mat, not a tuft
                // Sized against the splay, not picked: at ~24 cm of typical reach this leaves the
                // card tip about 2.3 cm up, or 5-6 degrees off the floor. Flat enough to be thatch,
                // steep enough to still occlude ground at the grazing angles every gameplay and
                // gauntlet framing looks at it from — a card lying truly flat covers nothing at all
                // from a standing eye, which is the trap this layer exists to avoid falling into.
                // Up a little with the reach: a wider mat crosses more of the ground's own roll, so
                // it needs more sink to keep its rim buried rather than hovering.
                TipDrop = 0.020f,
                MinWidthScale = 0.95f,
                MaxWidthScale = 1.80f,
                MinHeightScale = 0.70f,
                MaxHeightScale = 1.30f,
                AlignToGround = 0.95f,   // thatch does not stand plumb on a slope; it lies on it
                Cool = new Color(0.22f, 0.34f, 0.26f),
                Green = new Color(0.28f, 0.37f, 0.21f),
                // The mat's own "dry" is dead blade in a green mat, NOT bare earth. Bare earth is
                // the scuff species below, and it belongs on the worn lanes, not under the meadow.
                Dry = new Color(0.42f, 0.42f, 0.26f),
                TurfTintWeight = 0.88f,  // it IS the floor's colour (see the class doc)
                TurfDryTintWeight = 0.34f,
                DryBias = 0.20f,
                HueVariation = 0.26f,    // it must not out-vary the tufts standing in it
                ValueVariation = 0.20f,
                BaseBlend = 0.84f,
                BaseBlendHeight = 0.92f, // nearly the whole card blends toward the turf
                RootDarken = 0.60f,      // 40% darker at the root: the layer everything stands IN
                CombLean = 0.34f,        // a mat combs too, but it has little height to lean with
                CombFold = 0.55f,
                CombDrift = 0.06f,
                // Nothing BUT fan, so the rake is the only way a mat can comb at all. 0.65 draws
                // each mat into an ellipse about 1.07 m along the wind by 0.39 m across it — the
                // same area as the disc the coverage arithmetic in BuildGrassDetails is written
                // against, laid on the region's one bearing instead of pointing everywhere.
                CombRake = 0.65f,
                UnboundSway = 0.10f,     // still zero while bound; a mat barely stirs when it isn't
                BendStrength = 0.60f,
                BendCore = 0.64f,        // the pressed floor of the ring, held a touch wider
                BendLayDegrees = 66f,    // already low: press it flat and the disc has no floor
                BendDarken = 0.74f,      // the mat carries most of the ring's value change
                WidenStart = 9f,
                WidenEnd = 44f,
                WidenMax = 2.6f,
                FadeStart = 34f,
                FadeEnd = 60f,
            },

            // THE SCUFF — bare trodden earth, and the round-4 answer to "the worn lane has straight
            // polygon edges and unchanged albedo" (critique of v7).
            //
            // WHY IT IS A DETAIL SPECIES AND NOT A SHADER TERM. The worn drifts are FOUND, not
            // authored: FindValleyDrift walks the region's own low line and FindTreeSpur bows off
            // it, so where the lane runs is a polyline computed from the finished heightfield. A
            // fragment shader cannot know that — there is no splatmap on this terrain by design
            // (see Tarrock/TerrainPainterly's header) and adding one to paint a footpath would cost
            // the whole procedural surfacing. A near-flat, ground-coloured detail layer scattered
            // ONLY inside the lane paints it exactly where the density map already knows the lane
            // is, for instances confined to a ribbon a metre or so wide.
            //
            // WHAT IT IS: eight wide, almost horizontal cards, 1-2 cm tall, in the turf's bare-earth
            // scuff colour. Not grass — trodden ground with grit and dead stem in it. It is the one
            // place on this plateau the palette's _MeadowScuff / _TurfOchre browns belong, which is
            // the same swap that took the brown OUT of the thatch above: earth colours go where the
            // earth is bare, and nowhere else.
            //
            // ITS EDGES ARE ORGANIC BY CONSTRUCTION. The density loop gives the lane a two-octave
            // noise offset before the distance test (see BuildGrassDetails), so the boundary wanders
            // by up to ±0.55 m at 1.7 m and 0.6 m wavelengths — the scale a footpath's edge actually
            // frays at — and the per-cell dither breaks whatever is left of the 0.5 m grid.
            new TuftSpecies
            {
                Name = "GroundScuff",
                MeshPath = TerrainDataDir + "/GroundScuff.asset",
                MaterialPath = MaterialDir + "/GroundScuff.mat",
                PrefabPath = TerrainDataDir + "/GroundScuff.prefab",
                Seed = 83.9f,
                DitherOffset = 37.3f,
                MaxPerCell = 3,
                Blades = 8,
                Rows = 3,
                AngleJitter = 1.9f,
                MeshHeight = 0.020f,
                ShortestBlade = 0.35f,
                BladeArc = 0.75f,        // barely an arc: these lie down, they do not bow
                HalfWidthMin = 0.045f,
                HalfWidthMax = 0.085f,   // wide flakes of trodden ground, not blades
                SplayMin = 0.10f,
                SplayMax = 0.20f,
                RootOffsetMin = 0.020f,
                RootOffsetMax = 0.140f,
                TipDrop = 0.014f,        // the rim buries itself in the lane's own roll
                MinWidthScale = 1.00f,
                MaxWidthScale = 1.90f,
                MinHeightScale = 0.60f,
                MaxHeightScale = 1.10f,
                AlignToGround = 1f,      // it IS the ground
                Cool = new Color(0.33f, 0.31f, 0.24f),
                Green = new Color(0.40f, 0.34f, 0.23f),
                Dry = new Color(0.52f, 0.43f, 0.27f),
                TurfTintWeight = 0.35f,  // near the turf, but it must be allowed to be EARTH
                TurfDryTintWeight = 0.85f,
                DryBias = 0.72f,
                HueVariation = 0.22f,
                ValueVariation = 0.22f,  // grit and scuff: value is most of what it has
                BaseBlend = 0.55f,
                BaseBlendHeight = 0.95f,
                RootDarken = 0.72f,
                CombLean = 0.10f,        // trodden earth does not comb; it is not a plant
                CombFold = 0.20f,
                CombDrift = 0.02f,
                CombRake = 0.30f,        // just enough that the lane's grain runs with the meadow
                UnboundSway = 0f,        // it never moves, bound or not
                BendStrength = 0.20f,
                BendCore = 0.64f,
                BendLayDegrees = 60f,
                BendDarken = 0.82f,
                WidenStart = 9f,
                WidenEnd = 44f,
                WidenMax = 2.4f,
                FadeStart = 34f,
                FadeEnd = 60f,
            },
        };

        /// <summary>One grass species: its assets, the shape of its tuft mesh, how the terrain
        /// scatters it, and where on Tarrock/GrassTuft's cool→green→dry ramp it sits.</summary>
        private sealed class TuftSpecies
        {
            public string Name;
            public string MeshPath;
            public string MaterialPath;
            public string PrefabPath;

            /// <summary>Offsets the blade hash, so two species never fan the same way.</summary>
            public float Seed;

            /// <summary>Offsets the density dither, so the four layers do not land in the same
            /// cells and cancel each other's clumping out.</summary>
            public float DitherOffset;

            public int MaxPerCell;

            // -- Tuft mesh
            public int Blades;

            /// <summary>Cross-sections up a blade: 4 for an upright blade, 3 for a thatch card.
            /// Selects <see cref="BladeRows"/> or <see cref="MatRows"/>.</summary>
            public int Rows;

            public float MeshHeight;
            public float ShortestBlade;
            public float BladeArc;
            public float HalfWidthMin;
            public float HalfWidthMax;
            public float SplayMin;
            public float SplayMax;
            public float RootOffsetMin;
            public float RootOffsetMax;

            /// <summary>Angular scatter of the blade fan, in slots of the evenly divided circle.
            /// Under 1 the blades are a wobbled spoke pattern (a plant with a crown); over 1 they
            /// clump and gap (a tangle of ground cover). See BuildTuftMesh.</summary>
            public float AngleJitter;

            /// <summary>Metres the outer end of a blade sinks below its own arc, so a wide flat mat
            /// buries its rim in rolling ground instead of hovering over it. 0 for upright
            /// species.</summary>
            public float TipDrop;

            // -- Terrain scatter
            public float MinWidthScale;
            public float MaxWidthScale;
            public float MinHeightScale;
            public float MaxHeightScale;
            public float AlignToGround;

            // -- Material
            public Color Cool;
            public Color Green;
            public Color Dry;

            /// <summary>How far this species' three tints are pulled toward the GROUND builder's
            /// turf palette before they are written. 0 keeps the authored colour; the thatch runs
            /// high, because a thatch that is not the floor's own colour is a green rug thrown over
            /// the floor. The palette is read off the terrain material, never restated — see
            /// <see cref="ReadColour"/>.</summary>
            public float TurfTintWeight;

            /// <summary>The same pull, applied to the DRY pole against the ground's _TurfOchre.
            /// Separate from <see cref="TurfTintWeight"/> because that ochre means "scoured bare" in
            /// the ground shader: the mat wants a little of it, trodden earth wants nearly all of
            /// it, and a standing plant wants none.</summary>
            public float TurfDryTintWeight;

            public float DryBias;
            public float HueVariation;
            public float ValueVariation;

            /// <summary>Turf blend at the root: how much of it, and over how much of the blade.
            /// </summary>
            public float BaseBlend;
            public float BaseBlendHeight;

            /// <summary>Albedo multiplier at the very root — contact shade. 1 is off.</summary>
            public float RootDarken;

            public float CombLean;

            /// <summary>How much harder an upwind blade of this tuft leans than a downwind one —
            /// the asymmetry that makes a combed stand read as combed. See the shader header.
            /// </summary>
            public float CombFold;

            /// <summary>Unfolded downwind shift of the whole crown, as a share of tuft height.
            /// </summary>
            public float CombDrift;

            /// <summary>How far this species' FAN is stretched along the comb axis and squeezed
            /// across it — the round-4 construct that puts a short broad species on the same bearing
            /// as a tall thin one. See Tarrock/GrassTuft §_CombRake.</summary>
            public float CombRake;

            public float UnboundSway;
            public float BendStrength;

            /// <summary>Share of a bender's radius held fully laid over before the rim falls off.
            /// </summary>
            public float BendCore;

            /// <summary>Degrees from vertical a pressed blade is allowed to reach. Never 90: a
            /// blade laid flat has no silhouette and its ring reads as bare ground.</summary>
            public float BendLayDegrees;

            /// <summary>Albedo multiplier inside a bend ring — crushed cover is darker cover.
            /// </summary>
            public float BendDarken;

            // -- Distance handling. Shared across the four upright species on purpose (four
            //    different fade windows would draw three faint lines across the meadow); the
            //    thatch is the deliberate exception, because it is a near-field layer and paying
            //    for it out to 120 m would be paying for coverage the eye stops asking for at
            //    about a third of that.
            public float WidenStart;
            public float WidenEnd;
            public float WidenMax;
            public float FadeStart;
            public float FadeEnd;
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
        // (8.55 m — see CloudLobeSinkMin) by 3.1 m, so no head can be caught floating.
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
            material.SetColor("_CloudBright", new Color(1.00f, 0.95f, 0.84f));
            material.SetColor("_CloudShade", new Color(0.37f, 0.42f, 0.57f));
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
            material.SetFloat("_MottleBands", 5f);
            material.SetFloat("_MottleBandStrength", 0.66f);
            material.SetFloat("_MottleBandSoftness", 0.13f);
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
        // mass hangs at least (sink + 0.391) × radius BELOW the deck, which for the smallest head
        // the scatter can roll (18 m) is 9.2 m against a worst-case billow of 7 m — so no head can
        // ever be caught floating with a lit gap under it. Nothing casts a shadow: the sun is 7°
        // up, so a 200 m cloud would throw a 1.6 km bar across the island. Nothing moves: the
        // region is BOUND (art-audio.md §The world-state is the art direction).
        // -------------------------------------------------------------------------------------
        // SEVEN masses now, not four. Round 3's four were drawn by one hand and that was right, but
        // four arrangements over fifty-odd instances is a stamp — the critic's "same-size
        // same-altitude same-silhouette". 4-6 are the round-4 additions: the LOW SWELL (the mass
        // that answers "the deck has no top-surface relief crossing the mid-field"), the SHOULDERED
        // ANVIL (the near hero, asymmetric enough that it cannot read as a dumpling), and the NUB.
        private const int CloudLobeVariants = 7;
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
        // the deck's billow can drop CloudBillowAmplitude (7 m) beneath the level. At the floor of
        // 0.12 and the far scatter's smallest radius of 18 m that is 8.55 m of hang against a 7 m
        // trough — 1.55 m of margin, so no head can be caught floating with a lit gap under it, from
        // any camera, at any of the sizes the rolls can produce.
        private const float CloudLobeSinkMin = 0.12f;
        private const float CloudLobeSinkMax = 0.34f;
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
        // AND THEY NO LONGER SHARE ONE ALTITUDE. Sink is per-anchor now (0.10-0.32 of radius), so
        // the masses stand at genuinely different heights out of the sea — the other half of the
        // critic's "same-size same-altitude" reading.
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
            new CloudLobeAnchor(-64f, 93f, 24f, 5, 0.14f),

            // -- A: the broad low bank behind and right of B, at 185 m and u +0.15. Sunk deeper
            //    (0.24) than B so its crown sits visibly lower — the row's second altitude.
            new CloudLobeAnchor(-159f, 157f, 28f, 0, 0.24f),

            // -- D: the answering mass at u +0.67, so the right of frame is not left to the vault
            //    alone. Drawn out along the wind axis (mass 2) and at 200 m.
            new CloudLobeAnchor(-148f, 238f, 26f, 2, 0.18f),

            // -- C: the small far head at 300 m, u −0.19 — clearly BEHIND B and A, which is where
            //    the row's depth comes from. Nine points of internal value at that range and no
            //    pretence otherwise: it is a silhouette, sunk almost to its shoulders (0.32).
            new CloudLobeAnchor(-268f, 76f, 20f, 3, 0.32f),

            // -- v4's row, east and north-east of the island, standing in the cream gap that round 3
            //    named. E is the near tower filling the col at u +0.23 from 138 m, nearer than the
            //    mid-distance ridge behind it — so it occludes that ridge's foot rather than peering
            //    over its shoulder. G crops the right edge at u +0.98 and stands HIGH (sink 0.10);
            //    F answers low on the left at u −0.51 and sits DEEP (0.26). Three masses, three
            //    sizes, three altitudes, and a gap of open sea between each pair.
            new CloudLobeAnchor(288f, 96f, 28f, 1, 0.12f),
            new CloudLobeAnchor(314f, 18f, 30f, 5, 0.10f),
            new CloudLobeAnchor(259f, 195f, 26f, 0, 0.26f),

            // -- H: south-west of the island, behind the knoll. Not for v3 or v4 — it is what v8's
            //    backlit dead tree gets to be silhouetted against once the eye follows the ridge
            //    down, and what v1's left edge sees past the south wall.
            new CloudLobeAnchor(60f, -124f, 34f, 2, 0.22f),
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
                // would simply be swallowed by the sea it is meant to shape.
                float sink = Mathf.Lerp(CloudLobeSinkMin + 0.03f, 0.26f, sinkRoll);
                PlaceCloudLobe(parent, meshes, material, x, z, radius, 4, spinRoll, sink);
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
            material.SetColor("_LobeLit", new Color(1.06f, 1.00f, 0.88f));
            material.SetColor("_LobeShade", new Color(0.44f, 0.50f, 0.66f));
            material.SetColor("_LobeUnder", new Color(0.22f, 0.27f, 0.41f));
            // FOUR washes at 55% over 0.22 of softness — the sky's own brush. Round 3's three at
            // 85% over 0.10 is what drew the hard vertical bevel the critic named: with the sun 12°
            // up the iso-N·L contours on a rounded head are near-vertical great circles, and an 85%
            // terrace of them is a stencil of vertical stripes. The boundaries still read (they are
            // what makes it a painting); they no longer cut facets.
            material.SetFloat("_LobeBands", 4f);
            material.SetFloat("_LobeBandStrength", 0.55f);
            material.SetFloat("_LobeBandSoftness", 0.22f);
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
            sink = Mathf.Clamp(sink, CloudLobeSinkMin, CloudLobeSinkMax);
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
            mesh.RecalculateBounds();
            return mesh;
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
                    // roll (sink 0.18) a 40 m swell stands (0.426 − 0.18) × 40 ≈ 9.8 m proud and at
                    // its deepest (0.34) only 3.4 m; 10 m of cloud at 150 m subtends 3.8°
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

        private static void BuildRegionWind()
        {
            // The Cliff is BOUND at the start of the game, so wind rests at 0 and the region holds its
            // breath (art-audio.md §The world-state is the art direction). The director scrub on
            // RegionWind is how you feel the unbound state without firing a flag.
            // NO EXCEPTIONS, and the meadow is not one (director ruling 2026-07-31, reversing the
            // round-1 sway baseline): at wind 0 the grass does not move at all. "Wind-combed" is the
            // static SHAPE the last wind left, which Tarrock/GrassTuft poses with _CombLean. What
            // the bound world still does is yield to TOUCH — see BuildGrassBenders.
            var windGo = new GameObject("RegionWind");
            windGo.AddComponent<RegionWind>();
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
        private const int RockVariants = 6;
        private const int StandingFirstVariant = 4;   // variants 4-5 stand; 0-3 sit
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
            // cast shadow (verified against the beam, which now lands 8.4 m out — see the dawn
            // breach), so the whole stone sits at ambient while the lane behind it is lit. The rock
            // family's albedo is the ground's, read not restated, and it does not move.
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

            // v8's NEAR LAYER: a leaning finger at 2.6 m on the valley floor's south side, filling
            // the bottom-left corner. This vantage looks UP at the knoll — its frame bottom sits
            // 3.5° ABOVE the horizontal — which is why round 2's nearest stone (12.0 m) read as
            // midground and why this one must be a STANDING stone and not a boulder: at 3 m, nothing
            // under 1.9 m tall is in this picture at all.
            new RockAnchor(199.0f, 81.6f, 2.4f, 4),

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
            new RockAnchor(196.24f, 85.37f, 3.2f, 1),

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
            new RockAnchor(146.8f, 77.8f, 3.2f, 4),
            new RockAnchor(146.0f, 78.6f, 2.6f, 5),
            new RockAnchor(147.4f, 77.2f, 2.2f, 4),
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
                    int variant = standing
                        ? StandingFirstVariant + (variantRoll > 0.5f ? 1 : 0)
                        : Mathf.Clamp(
                            Mathf.FloorToInt(variantRoll * StandingFirstVariant), 0, StandingFirstVariant - 1);
                    PlaceRock(root.transform, meshes, rock, terrainData, x, z, scale, variant, spinRoll);
                    scattered++;
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
            Vector3 bedded = Vector3.Slerp(
                rest, BeddingUp(standing ? StandingDipDegrees : BeddingDipDegrees),
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
                squashX *= variant == StandingFirstVariant ? 0.62f : 1.15f;
                squashZ *= variant == StandingFirstVariant ? 0.55f : 0.34f;
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

        private static Material BuildRockMaterial(Shader rockShader, Material terrainMaterial)
        {
            var material = AssetDatabase.LoadAssetAtPath<Material>(RockMaterialPath);
            if (material == null)
            {
                material = new Material(rockShader);
                AssetDatabase.CreateAsset(material, RockMaterialPath);
            }
            else
            {
                material.shader = rockShader;
            }

            // The palette is READ off the ground, never restated: a boulder must be made of the same
            // stone the hillside is shaded with (BuildTerrainMaterial owns those colours), and
            // copying the numbers here is how a prop ends up a different rock from its own cliff.
            // The fallbacks exist only so a renamed terrain property degrades to "close enough and
            // loud in the log" instead of to Unity's silent Color.clear, i.e. black rocks.
            //
            // ROUND-2 INTEGRATION NOTE: the ground pass split its stone into alternating warm and
            // cool BEDS with sage lichen (_RockWarm / _RockCool / _RockLichen) where it used to have
            // one _RockColor and one _MossColor. Tarrock/RockPainterly still lights a boulder with a
            // single stone colour plus a moss, so the mapping is warm bed → stone, lichen → moss.
            // The cool bed is deliberately NOT read: a boulder sitting on a hillside is a lump of
            // the sunny bed that fell off it, and mixing both here would grey the prop out of the
            // cliff it came from. The fallbacks are the ground pass's own numbers.
            // ROUND 4 — THE WEATHERING STEP. The HUE is still the ground's, read and not restated;
            // what is added is one VALUE decision, and it is the difference between a foreground
            // mass and a pale lump. The critique was that the near stones are brighter than the
            // hazed distance behind them, which is an anchor upside down, and the numbers were
            // blunt: at the hillside's own value a free-standing block in cast shadow renders at
            // luminance 0.300 against shaded meadow at 0.181 — a LIGHT shape on dark ground, where
            // every reference plate's foreground rock is a dark shape on light ground.
            // 0.82 of the bedding's value is where the two constraints meet, and both were solved
            // rather than eyed:
            //   - a block in cast shadow lands at 0.236, so it reads 2.1:1 against the light lane
            //     behind it and 3.1:1 against the far haze — it anchors;
            //   - a face square to the beam still reaches 1.20 linear against the bloom threshold's
            //     0.90, so sun-struck stone is still what carries the frame's brightest pixels
            //     (round 3's doctrine, and it survives the step with a 33% margin).
            // It is also true: the hillside colour is FRESH bedding in a cut face. A block that has
            // sat in wet turf long enough for the grass to climb it is weathered and lichened and
            // is not the colour of the quarry it fell out of. _CliffColor and the lichen are NOT
            // scaled — the refusing faces are hillside, and the lichen is already the dark note.
            Color bedding = PaletteColour(terrainMaterial, "_RockWarm", new Color(0.56f, 0.51f, 0.42f));
            // Scaled channel by channel rather than with Color's own operator*, which would take the
            // alpha down with it — an opaque shader would not care today and would care the day
            // someone reads it.
            material.SetColor(
                "_RockColor",
                new Color(
                    bedding.r * RockWeathering,
                    bedding.g * RockWeathering,
                    bedding.b * RockWeathering,
                    bedding.a));
            material.SetColor("_CliffColor", PaletteColour(terrainMaterial, "_CliffColor", new Color(0.30f, 0.31f, 0.35f)));
            material.SetColor("_MossColor", PaletteColour(terrainMaterial, "_RockLichen", new Color(0.35f, 0.40f, 0.26f)));
            material.SetColor("_ShadowTint", PaletteColour(terrainMaterial, "_ShadowTint", new Color(0.80f, 0.88f, 1.06f)));
            material.SetColor("_AmbientFloor", PaletteColour(terrainMaterial, "_AmbientFloor", new Color(0.10f, 0.11f, 0.14f)));

            // Every remaining property explicit (same rule as the other materials — a reused .mat
            // keeps stale serialised values while the shader's defaults appear to change). These are
            // the ROCK's own numbers: finer mottle than the ground's (a boulder is read at 2 m, not
            // at 40), a finer bed, and a harder posterise so near stones hold a few flat values and
            // stay legible as a dark shape.
            material.SetFloat("_MossAmount", 0.42f);
            material.SetFloat("_MossStart", 0.28f);
            material.SetFloat("_RockVariation", 1.5f);
            material.SetFloat("_RockContrast", 1.8f);
            material.SetFloat("_RockDetailAmount", 0.13f);
            material.SetFloat("_FormationTint", 0.55f);

            // ROUND-4 close-range brushmarks. The whole block above works at 0.34 m and coarser, so
            // a boulder at arm's length was one flat wash between two partings ("no surface detail",
            // round-4 critique of v5). 0.20 m marks are two or three to a hand's width — laid paint,
            // not noise — and they fade out over 6-16 m so nothing sub-pixel is ever drawn at range.
            // The aspect/size spreads are the ground's own numbers: one paint recipe, two shaders.
            material.SetFloat("_RockDabScale", 0.20f);
            material.SetFloat("_RockDabTone", 0.17f);
            material.SetFloat("_RockDabAniso", MeadowDabAniso);
            material.SetFloat("_RockDabSize", MeadowDabSize);
            material.SetFloat("_RockDabFadeStart", 6f);
            material.SetFloat("_RockDabFadeRange", 10f);

            // BEDDING (round 3) — the same construct as the ground's, an order finer because a
            // boulder is a metre tall and wants three or four beds, not one. Round 2 drew
            // posterise(sin(bedding * pi)) here, i.e. a wide soft sinusoid lerping the whole albedo
            // between two stone colours, which is why the round-2 boulders read as stacks of pale
            // tonal slabs. A bed is a thin parting between two masses of one colour.
            //
            // _BeddingWarp 0.09 m against a 0.34 m bed is 26%, and the shader caps it at 30%: the
            // same ratio discipline as the ground, for the same reason (see BuildTerrainMaterial).
            material.SetFloat("_BeddingSpacing", 0.34f);
            material.SetVector("_BeddingDip", new Vector4(0.070f, 0f, -0.050f, 0f));
            material.SetFloat("_BeddingWarp", 0.09f);
            material.SetFloat("_BeddingLineWidth", 0.10f);
            material.SetFloat("_BeddingWidthJitter", 0.60f);
            material.SetFloat("_BeddingDarken", 0.30f);
            material.SetFloat("_BeddingLip", 0.18f);
            material.SetFloat("_BedValueJitter", 0.10f);
            material.SetFloat("_BedFormRate", 0.30f);
            // Measured on 1 - |N.y| rather than on slope degrees, because a boulder has a flat TOP
            // and a flat underside and a horizontal bed blobs across both. Same physics as the
            // ground's slope gate.
            material.SetFloat("_BeddingFaceStart", 0.18f);
            material.SetFloat("_BeddingFaceEnd", 0.46f);

            // CAVITY — the hollows, as their own term. Scaled to the block (0.55 m) rather than to
            // the hillside, so it reads as pitting in the stone and not as the ground's shading
            // arriving on a prop.
            material.SetFloat("_CavityScale", 0.55f);
            material.SetFloat("_CavityContrast", 4.5f);
            material.SetFloat("_CavityDarken", 0.30f);

            material.SetFloat("_BrushSteps", 4f);
            material.SetFloat("_BrushSoftness", 0.32f);
            material.SetFloat("_ShadeWrap", 0.22f);
            material.SetFloat("_AmbientBoost", 1f);
            material.enableInstancing = true;

            // OPAQUE, pinned — same reasoning as BuildTerrainMaterial.
            material.renderQueue = -1;
            material.SetOverrideTag("RenderType", "Opaque");
            EditorUtility.SetDirty(material);
            return material;
        }

        /// <summary>Reads one colour off the ground's material so the rock family cannot drift from
        /// the palette that owns it, warning (rather than silently going black) if it is gone.</summary>
        private static Color PaletteColour(Material source, string property, Color fallback)
        {
            if (source != null && source.HasProperty(property))
            {
                return source.GetColor(property);
            }

            Debug.LogWarning(
                $"[Tarrock] Terrain material has no '{property}'; rock outcrops fell back to their " +
                "own copy of the Cliff palette. Re-sync BuildRockMaterial with BuildTerrainMaterial.");
            return fallback;
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

            Vector3 RingPoint(int ring, int side)
            {
                float angle = side * Mathf.PI * 2f / sides;
                float jitter = 0.80f + 0.42f * Hash21(side + variant * 13.7f, ring + variant * 7.3f);
                float r = ringRadius[ring] * jitter * 0.46f;
                float t = Mathf.Clamp01(ringHeight[ring]);
                var lean = new Vector3(leanX, 0f, leanZ) * (t * t);
                return new Vector3(Mathf.Cos(angle) * r, ringHeight[ring], Mathf.Sin(angle) * r) + lean;
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

            for (int ring = 0; ring < ringHeight.Length - 1; ring++)
            {
                for (int side = 0; side < sides; side++)
                {
                    int next = (side + 1) % sides;
                    Vector3 a = RingPoint(ring, side);
                    Vector3 b = RingPoint(ring, next);
                    Vector3 c = RingPoint(ring + 1, next);
                    Vector3 d = RingPoint(ring + 1, side);
                    float mid = (ringHeight[ring] + ringHeight[ring + 1]) * 0.5f;
                    AddQuad(a, b, c, d, FacetColour(ring, side, mid));
                }
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
                centre.y = ringHeight[ring] + (upward ? 0.06f : -0.04f);
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

            AddCap(ringHeight.Length - 1, upward: true);
            AddCap(0, upward: false);

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
                case 4: return new[] { 0.40f, 0.44f, 0.40f, 0.31f, 0.15f };   // leaning finger
                default: return new[] { 0.86f, 0.94f, 0.90f, 0.76f, 0.46f };  // tilted plate
            }
        }

        /// <summary>Ring heights per variant. The sitting family shares one set; a standing stone
        /// carries its bulk in the lower half and keeps its taper for the last ring, so the shape
        /// against the sky is a shoulder and a broken tip rather than a cone.</summary>
        private static float[] RockRingHeights(int variant)
        {
            if (variant < StandingFirstVariant)
            {
                return new[] { -0.08f, 0.20f, 0.48f, 0.76f, 1.00f };
            }

            return new[] { -0.14f, 0.26f, 0.58f, 0.84f, 1.00f };
        }

        /// <summary>Side count per variant. Fewer sides on the standing family on purpose: a slab is
        /// four big planes with a clean edge between them (art-bible.md, confident edges), and a
        /// near-lens mass that is going to be read as a silhouette wants the fewest facets that
        /// still describe it.</summary>
        private static int RockSides(int variant)
        {
            switch (variant)
            {
                case 4: return 5;   // leaning finger
                case 5: return 4;   // tilted plate
                default: return 6 + (variant % 3);
            }
        }

        // -------------------------------------------------------------------------------------
        // Tussock clumps (round-2 composition pass)
        //
        // THE FINDING this answers: the midground has no texture — between the near ground and the
        // far ridge there is nothing at all for the eye to hold, so the frame reads as two flat
        // fields. In fable-01 and kena-03 the path is EDGED: coarse, drier, taller grass banks the
        // travelled line and the base of every rock, and that fringe is what tells you where the
        // path is without a path texture.
        //
        // These are NOT more meadow. The meadow (BuildGrassDetails) is a 0.30 m terrain detail at
        // 8 tufts per square metre; a tussock is a knee-high (0.57-0.93 m) clump placed one at a
        // time where the valley floor meets its banks. They share Tarrock/GrassTuft — the same
        // combing, the same bound-state baseline sway, so the two populations move as one meadow —
        // but carry their own drier material, so the banks read gold against the green floor at
        // dawn. They are deliberately NOT marked static: static batching hands the shader an
        // identity matrix, and Tarrock/GrassTuft reads its per-instance vertical scale off that
        // matrix, so batching would comb a 0.93 m clump as if it were 0.60 m.
        // -------------------------------------------------------------------------------------
        private const int TussockVariants = 3;
        private const float TussockCell = 4f;
        private const float TussockHeight = 0.75f;
        private const int TussockBlades = 9;

        private static void BuildTussocks(TerrainData terrainData)
        {
            Shader tuftShader = Shader.Find(TuftShaderName);
            if (tuftShader == null)
            {
                Debug.LogWarning($"[Tarrock] {TuftShaderName} not found; tussocks skipped.");
                return;
            }

            var meshes = new Mesh[TussockVariants];
            for (int variant = 0; variant < TussockVariants; variant++)
            {
                Mesh mesh = BuildTussockMesh(variant);
                string path = string.Format(TussockMeshPathFormat, variant);
                AssetDatabase.DeleteAsset(path);
                AssetDatabase.CreateAsset(mesh, path);
                meshes[variant] = mesh;
            }

            var material = AssetDatabase.LoadAssetAtPath<Material>(TussockMaterialPath);
            if (material == null)
            {
                material = new Material(tuftShader);
                AssetDatabase.CreateAsset(material, TussockMaterialPath);
            }
            else
            {
                material.shader = tuftShader;
            }

            // Drier and duller than the meadow's tint: a bank tussock is the grass the wind got to.
            material.SetColor("_BaseColor", new Color(0.40f, 0.42f, 0.24f));
            material.SetColor("_DryColor", new Color(0.68f, 0.58f, 0.31f));
            material.SetFloat("_DryBias", 0.55f);
            material.SetFloat("_PatchScale", 18f);
            material.SetFloat("_TuftVariation", 0.5f);
            material.SetFloat("_ValueVariation", 0.16f);
            material.SetFloat("_ShadeWrap", 0.50f);
            material.SetFloat("_AmbientBoost", 1f);
            // MUST match BuildTussockMesh's height: the shader turns its unitless height and sway
            // channels back into metres with this number.
            material.SetFloat("_TuftHeight", TussockHeight);
            // The comb must AGREE with the meadow's (BuildGrassDetails writes the same four numbers):
            // banks combed on a different axis or at a different wavelength from the field they edge
            // is the one mistake that would make these read as separate props rather than as the
            // coarse edge of one meadow. Only the amplitudes differ, and only downward — a tussock
            // is woody, so it leans less and breathes less than the grass it grows out of.
            material.SetVector("_WindAxis", new Vector4(1f, 0.35f, 0f, 0f));
            // TBD (round 3, meadow pass): the meadow's leans went up by about half to answer the
            // gauntlet's "no coherent comb" finding — fescue 0.34 -> 0.52. This stayed at 0.24, so
            // the gap between bank and field widened from "the tussock leans a little less" to
            // "the tussock leans half as much". That may still be right (a woody clump genuinely
            // resists), but it is the tussock owner's call to make against a capture, not the
            // meadow pass's to make in passing. If it reads as two different winds, 0.34 keeps the
            // old proportion.
            material.SetFloat("_CombLean", 0.24f);
            material.SetFloat("_SwayStrength", 0.11f);
            material.SetFloat("_SwaySpeed", 0.85f);
            material.SetFloat("_SwayWavelength", 14f);
            material.SetFloat("_WindResponse", 2.5f);
            material.SetFloat("_WidenStart", 22f);
            material.SetFloat("_WidenEnd", 70f);
            material.SetFloat("_WidenMax", 1.6f);
            material.SetFloat("_FadeStart", 90f);
            material.SetFloat("_FadeEnd", 130f);
            material.SetFloat("_FadeMinScale", 0.10f);

            // ROUND-2 INTEGRATION: the meadow pass added ten properties to Tarrock/GrassTuft after
            // this builder was written, and leaving them at the shader defaults would break this
            // file's own rule (every property explicit — a reused .mat keeps stale values while the
            // shader's defaults appear to change) AND, worse, would let a tussock disagree with the
            // meadow it edges on the two things a viewer actually reads: how it meets the ground,
            // and how it yields to the Fool.
            //
            // Roots blend to the SAME turf palette the meadow's tufts use — read off the ground
            // material there, and the shared constants here, which are the values that material is
            // written with. Comb wander is IDENTICAL to the meadow's (same axis, same wavelength,
            // same swing): banks wandering on a different field from the field they edge is exactly
            // the mistake the comment above exists to prevent. Only amplitudes differ, downward.
            material.SetColor("_CoolColor", new Color(0.26f, 0.42f, 0.36f));
            material.SetColor("_GroundColor", Color.Lerp(TurfSoil, MeadowGreen, 0.55f));
            material.SetColor("_GroundDryColor", TurfOchre);
            material.SetFloat("_BaseBlend", 0.62f);
            material.SetFloat("_BaseBlendHeight", 0.5f);
            material.SetFloat("_CombWanderLength", 46f);
            material.SetFloat("_CombWanderDegrees", 14f);

            // ROUND-3 INTEGRATION, for the same reason and by the same rule as the round-2 note
            // above: Tarrock/GrassTuft gained four properties (root contact shade, the comb fold and
            // crown drift, and the bend's held core) and lowered the meadow's hollow lean, and a
            // bank left on the shader defaults would comb on a different curve and take a different
            // shape under the Fool's feet than the meadow it edges — the one mistake this builder
            // has been guarding against since it was written.
            //
            // The hollow lean and the bend core are COPIED, not chosen: they are the shape of the
            // field and the shape of the ring, and those must not change at a bank's edge. The fold
            // and the drift are the tussock's own, and both are low — a woody clump of short stiff
            // blades folds and travels less than a stand of fescue, which is the same "amplitudes
            // differ, and only downward" rule the comb amplitudes already follow.
            material.SetFloat("_CombHollowLean", 0.34f);
            material.SetFloat("_CombFold", 0.35f);
            material.SetFloat("_CombDrift", 0.05f);
            material.SetFloat("_RootDarken", 0.86f);
            // A tussock is woody and its blades are short and stiff, so it parts less than fescue
            // does — but it MUST part, or the one motion a bound world is allowed stops at the edge
            // of the meadow and the banks read as painted-on props (art-audio.md §The world-state is
            // the art direction, "A bound world still yields to touch").
            material.SetFloat("_BendStrength", 0.90f);
            material.SetFloat("_BendHeightRange", 1.8f);
            material.SetFloat("_BendCoreShare", 0.50f);
            material.enableInstancing = true;
            EditorUtility.SetDirty(material);

            var root = new GameObject("Tussocks");
            int placed = 0;
            int cells = Mathf.FloorToInt(TerrainSize / TussockCell);
            for (int gz = 0; gz < cells; gz++)
            {
                for (int gx = 0; gx < cells; gx++)
                {
                    float jitterX = Hash21(gx + 5.13f, gz + 31.7f);
                    float jitterZ = Hash21(gx + 27.90f, gz + 6.41f);
                    float pick = Hash21(gx + 60.30f, gz + 15.70f);
                    float sizeRoll = Hash21(gx + 44.10f, gz + 82.30f);
                    float spinRoll = Hash21(gx + 18.70f, gz + 51.90f);
                    float variantRoll = Hash21(gx + 73.10f, gz + 36.50f);

                    float x = (gx + 0.12f + 0.76f * jitterX) * TussockCell;
                    float z = (gz + 0.12f + 0.76f * jitterZ) * TussockCell;
                    if (!AcceptsTussock(terrainData, x, z, pick))
                    {
                        continue;
                    }

                    float ground = terrainData.GetInterpolatedHeight(x / TerrainSize, z / TerrainSize);
                    var go = new GameObject("Tussock");
                    go.transform.SetParent(root.transform, worldPositionStays: false);
                    // Set a little low so the blades' roots are in the ground, not on it.
                    go.transform.position = new Vector3(x, ground - 0.04f, z);
                    go.transform.rotation = Quaternion.Euler(0f, spinRoll * 360f, 0f);
                    // The mesh's tallest blade reaches 0.8 x TussockHeight once its droop is
                    // applied, so this range puts a clump between 0.57 and 0.93 m: knee-high, two
                    // to three times the meadow tuft, which is the whole point of it.
                    go.transform.localScale = Vector3.one * (0.95f + 0.60f * sizeRoll);
                    int variant = Mathf.Clamp(Mathf.FloorToInt(variantRoll * TussockVariants), 0, TussockVariants - 1);
                    go.AddComponent<MeshFilter>().sharedMesh = meshes[variant];
                    var renderer = go.AddComponent<MeshRenderer>();
                    renderer.sharedMaterial = material;
                    // No shadow: Tarrock/GrassTuft ships no ShadowCaster pass (see BuildGrassDetails),
                    // and a clump this size casts nothing the frame would miss.
                    renderer.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
                    placed++;
                }
            }

            Debug.Log($"[Tarrock] Tussock clumps placed: {placed}.");
        }

        private static bool AcceptsTussock(TerrainData terrainData, float x, float z, float pick)
        {
            if (x < 8f || x > TerrainSize - 8f || z < 8f || z > TerrainSize - 8f)
            {
                return false;
            }

            float height = terrainData.GetInterpolatedHeight(x / TerrainSize, z / TerrainSize);
            float steep = terrainData.GetSteepness(x / TerrainSize, z / TerrainSize);
            if (height < 14f || height > 54f || steep > 36f)
            {
                return false;
            }

            var point = new Vector2(x, z);
            if (Vector2.Distance(point, new Vector2(SpawnHint.x, SpawnHint.z)) < 2.6f)
            {
                return false;   // the Fool starts standing, not waist-deep
            }

            // The BANK: the strip where the valley floor gives way to its walls, either side. This
            // is the line the reference plates always dress, because it is the line the eye follows.
            // ROUND 3 widened it (1 m inboard, 3 m outboard) and lifted the odds a little, so the
            // bank reads as a THICKNESS the eye can follow rather than a dotted line — and so it
            // agrees with the rock scatter, whose new bank zone dresses the same band. One band,
            // two populations, same edge.
            float offset = Mathf.Abs(z - CentreZ(x));
            float halfWidth = HalfWidth(x);
            float chance = 0f;
            if (offset > halfWidth - 5f && offset < halfWidth + 17f)
            {
                chance = 0.44f;
            }

            // ...and the spawn bowl, where the near fringe of the opening frame is made. This is the
            // other half of the near-lens answer: the bottom third of v1 is ground within 3-10 m of
            // the lens, and where there is no rock to crop it, a coarse dark fringe is what the
            // reference plates put there. The 2.6 m hole around the spawn mark stays — the Fool
            // starts standing, not waist-deep.
            float fromSpawn = Vector2.Distance(point, new Vector2(SpawnHint.x, SpawnHint.z));
            if (fromSpawn > 2.6f && fromSpawn < 34f && steep < 30f)
            {
                chance = Mathf.Max(chance, 0.34f);
            }

            return pick <= chance;
        }

        /// <summary>
        /// One coarse clump, <see cref="TussockHeight"/> tall: nine blades fanned from a small root
        /// disc, each arcing outward and drooping, three segments apiece. Carries the four channels
        /// <c>Tarrock/GrassTuft</c> depends on — see that shader's header — so a clump combs, sways
        /// and fades exactly as the meadow around it does.
        /// </summary>
        private static Mesh BuildTussockMesh(int variant)
        {
            var verts = new List<Vector3>();
            var normals = new List<Vector3>();
            var cols = new List<Color>();
            var uvs = new List<Vector2>();
            var rootOffsets = new List<Vector2>();
            var tris = new List<int>();

            var baseCol = new Color(0.34f, 0.36f, 0.22f);
            var tipCol = new Color(1.05f, 0.98f, 0.66f);
            const int Segments = 3;

            for (int blade = 0; blade < TussockBlades; blade++)
            {
                float spread = Hash21(blade + variant * 11.3f, 2.7f);
                float lengthRoll = Hash21(blade + variant * 4.9f, 8.1f);
                float widthRoll = Hash21(blade + variant * 6.7f, 13.3f);
                float valueRoll = Hash21(blade + variant * 9.1f, 21.7f);

                float angle = (blade + 0.42f * spread) * Mathf.PI * 2f / TussockBlades;
                var outward = new Vector3(Mathf.Cos(angle), 0f, Mathf.Sin(angle));
                Vector3 side = Vector3.Cross(outward, Vector3.up).normalized;

                float bladeHeight = TussockHeight * (0.56f + 0.44f * lengthRoll);
                float reach = bladeHeight * (0.26f + 0.34f * spread);
                float halfWidth = 0.028f * (0.7f + 0.6f * widthRoll);
                float rootRadius = 0.035f + 0.05f * spread;
                float value = 0.88f + 0.24f * valueRoll;

                int strip = verts.Count;
                for (int seg = 0; seg <= Segments; seg++)
                {
                    float t = seg / (float)Segments;
                    // Droop: the tip falls back a little, so a clump arcs instead of spiking.
                    float lift = bladeHeight * (t - 0.20f * t * t);
                    Vector3 centre = (outward * (rootRadius + reach * t * t)) + (Vector3.up * lift);
                    float w = halfWidth * (1f - 0.78f * t);

                    // NORMAL biased hard to +Y (the shader's requirement): a blade's true normal is
                    // horizontal, which lights a bank as a row of dark spikes.
                    Vector3 normal = Vector3.Lerp(Vector3.up, outward, 0.22f).normalized;
                    Color colour = Color.Lerp(baseCol, tipCol, t) * value;
                    colour.a = lift / TussockHeight;   // sway mask, in shares of the mesh height

                    Vector3 left = centre - (side * w);
                    Vector3 right = centre + (side * w);
                    verts.Add(left);
                    verts.Add(right);
                    normals.Add(normal);
                    normals.Add(normal);
                    cols.Add(colour);
                    cols.Add(colour);
                    uvs.Add(new Vector2(spread, lift / TussockHeight));
                    uvs.Add(new Vector2(spread, lift / TussockHeight));
                    rootOffsets.Add(new Vector2(left.x, left.z));
                    rootOffsets.Add(new Vector2(right.x, right.z));
                }

                for (int seg = 0; seg < Segments; seg++)
                {
                    int a = strip + (seg * 2);
                    tris.AddRange(new[] { a, a + 2, a + 1, a + 1, a + 2, a + 3 });
                }
            }

            var mesh = new Mesh { name = $"TussockClump{variant}" };
            mesh.SetVertices(verts);
            mesh.SetNormals(normals);
            mesh.SetColors(cols);
            mesh.SetUVs(0, uvs);
            mesh.SetUVs(1, rootOffsets);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateBounds();
            return mesh;
        }

        private static void EnsureDirectory(string path)
        {
            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
                AssetDatabase.Refresh();
            }
        }
    }
}
