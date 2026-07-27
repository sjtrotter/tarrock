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
        private const string DeadTreeMeshPath = "Assets/_Project/Art/DeadTree.asset";
        private const string DeadTreeMaterialPath = MaterialDir + "/DeadTreeBark.mat";
        private const string TuftMeshPath = "Assets/_Project/Art/GrassTuft.asset";
        private const string TuftMaterialPath = MaterialDir + "/GrassTuft.mat";
        private const string TuftPrefabPath = "Assets/_Project/Art/GrassTuft.prefab";
        private const string MoteMaterialPath = MaterialDir + "/SuspendedMotes.mat";
        private const string TerrainDataPath = "Assets/_Project/Art/TerrainProto.asset";
        private const string TerrainDataDir = "Assets/_Project/Art";
        private const string ShaderName = "Tarrock/TerrainPainterly";

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
            terrain.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;

            BuildGrassDetails(terrainData, terrain);
            BuildLighting();
            BuildCloudSea();
            BuildDeadTree();
            BuildMotes();
            BuildRegionWind();

            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, ScenePath);
            AssetDatabase.SaveAssets();

            // Reuse the real rig + orbit camera rather than a second copy that would drift from it.
            KayKitCharacterInstaller.InstallInto(ScenePath, SpawnHint, SpawnFacing);
            PipInstaller.Install();

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
            float centreZ = 118f
                + 24f * Mathf.Sin(x * 0.0195f)
                + 10f * Mathf.Sin(x * 0.052f + 0.8f);

            // -- 2. Width pinches and bulges (rule 6): tight passes that compress, open bulges that
            //       release. Never one constant width.
            float halfWidth = SoftMax(9f, 17f
                + 8f * Mathf.Sin(x * 0.031f + 1.2f)
                + 4.5f * Mathf.Sin(x * 0.079f + 2.1f), 1.5f);

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
            // Cliff palette (art-audio.md region colour script owns per-region tinting): green
            // meadow with wind-scoured ochre patches — the plateau's GOLD lives in the dawn light,
            // not the albedo (director call 2026-07-26) — warm ochre rock, cool slate cliffs.
            material.SetColor("_GrassLow", new Color(0.24f, 0.33f, 0.18f));
            material.SetColor("_GrassHigh", new Color(0.58f, 0.62f, 0.30f));
            material.SetColor("_GrassDry", new Color(0.56f, 0.48f, 0.24f));
            material.SetFloat("_GrassMacroScale", 34f);
            material.SetFloat("_GrassMesoScale", 4.5f);
            material.SetFloat("_GrassMicroScale", 0.55f);
            material.SetFloat("_GrassHueScale", 26f);
            material.SetFloat("_GrassMacroAmount", 0.55f);
            material.SetFloat("_GrassMesoAmount", 0.70f);
            material.SetFloat("_GrassDryAmount", 1.8f);
            material.SetFloat("_GrassGrain", 0.06f);
            material.SetFloat("_GrassBias", 0.30f);
            material.SetColor("_RockColor", new Color(0.50f, 0.44f, 0.35f));
            material.SetColor("_CliffColor", new Color(0.29f, 0.30f, 0.34f));
            material.SetFloat("_RockVariation", 5f);
            material.SetFloat("_SlopeStart", 0.30f);
            material.SetFloat("_SlopeEnd", 0.62f);
            material.SetFloat("_HeightLow", 8f);
            material.SetFloat("_HeightHigh", 48f);
            material.SetFloat("_StrataStrength", 0.18f);
            material.SetFloat("_StrataScale", 5.5f);
            material.SetFloat("_ShadeWrap", 0.30f);
            material.SetFloat("_AmbientBoost", 1f);
            material.SetColor("_ShadowTint", new Color(0.80f, 0.88f, 1.06f));
            material.SetColor("_AmbientFloor", new Color(0.10f, 0.11f, 0.14f));
            EditorUtility.SetDirty(material);
            return material;
        }

        // The sky's horizon colour, LINEAR (material colours are consumed raw). The fog colour is
        // DERIVED from it below via .gamma — RenderSettings colours are gamma-decoded, so the same
        // float triple means two different colours in the two places. Deriving one from the other
        // keeps ground and sky married at the horizon; hand-copying the numbers is how they drift.
        private static readonly Color HorizonLinear = new Color(0.80f, 0.70f, 0.50f);

        private static void BuildLighting()
        {
            // FROZEN DAWN (canon: art-audio.md gives the Cliff "pale dawn gold"; MQ00 opens at
            // dawn). Sun at 16° elevation aimed nearly down the valley axis so the Fool walks toward
            // the light: long raking shadows reveal the terraces, slopes separate by value (the
            // north/south grammar becomes readable), ridges gain rim light. The 2026-07-26 audit
            // found the old 42° near-midday sun was flattening every read the landform authors.
            // Director call (same audit): the plateau's gold lives in the LIGHT — the ground stays
            // green meadow, dawn paints it.
            var lightGo = new GameObject("Directional Light");
            lightGo.transform.rotation = Quaternion.Euler(16f, 78f, 0f);
            var light = lightGo.AddComponent<Light>();
            light.type = LightType.Directional;
            light.color = new Color(1.00f, 0.90f, 0.72f);
            light.intensity = 1.25f;
            light.shadows = LightShadows.Soft;

            // Trilight ambient. GOTCHA (audit finding 3): RenderSettings colours are gamma-decoded
            // in a Linear project, so these triples are authored gamma-encoded to land at the
            // intended linear values. The old triples were authored as if linear — the ground pole
            // landed at 4.7% linear, a light trap that took every shadowed face to near-black.
            // Storybook wants luminous shadows: uniformly cool sky/equator, only the ground bounce
            // warm — that opposition to the warm sun IS the painterly warm-light/cool-shadow split.
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.62f, 0.70f, 0.82f);
            RenderSettings.ambientEquatorColor = new Color(0.60f, 0.62f, 0.66f);
            RenderSettings.ambientGroundColor = new Color(0.52f, 0.47f, 0.40f);

            // The project's own gradient sky — NOT Skybox/Procedural, whose Rayleigh remap produces
            // an acid-green horizon band at any blue-shifted tint (measured G exceeding the R/B mean
            // by 45 sRGB levels) and renders the whole below-horizon hemisphere as one flat colour:
            // the literal diorama-on-a-table read the hex retirement was meant to end.
            Shader gradient = Shader.Find("Tarrock/GradientSky");
            var sky = new Material(gradient != null ? gradient : Shader.Find("Skybox/Procedural"));
            if (gradient != null)
            {
                sky.SetColor("_HorizonColor", HorizonLinear);                    // pale dawn gold
                sky.SetColor("_ZenithColor", new Color(0.34f, 0.44f, 0.60f));    // cool grey-blue
                sky.SetColor("_GroundColor", new Color(0.44f, 0.41f, 0.35f));    // muted haze below rim
                sky.SetFloat("_Exponent", 1.25f);
                sky.SetFloat("_HorizonHeight", 0.0f);
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

            // Exponential² fog in the sky's horizon colour: aerial perspective from the first metres
            // (18% at 100 m, ~72% at 250 m) instead of the old linear 150 m dead zone, which left the
            // whole playable depth with zero atmospheric separation and then hit a mismatched tan
            // wall. Aerial perspective CREATES the elevation read; it does not flatten it.
            RenderSettings.fog = true;
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogDensity = 0.0045f;
            RenderSettings.fogColor = HorizonLinear.gamma;
            DynamicGI.UpdateEnvironment();

            BuildPostVolume();
        }

        // The grade: without it the image is raw untonemapped shader output — the single loudest
        // "unfinished" signal the audit found. Neutral tonemapping (ACES desaturates and crushes,
        // fighting "saturated but never garish"), a gentle warm/cool split in the grade, storybook
        // vignette. Regenerates deterministically like everything else in this file.
        private static void BuildPostVolume()
        {
            var profile = ScriptableObject.CreateInstance<UnityEngine.Rendering.VolumeProfile>();
            AssetDatabase.DeleteAsset(PostProfilePath);
            AssetDatabase.CreateAsset(profile, PostProfilePath);

            var tone = profile.Add<UnityEngine.Rendering.Universal.Tonemapping>();
            tone.mode.Override(UnityEngine.Rendering.Universal.TonemappingMode.Neutral);

            var adjust = profile.Add<UnityEngine.Rendering.Universal.ColorAdjustments>();
            adjust.postExposure.Override(0.15f);
            adjust.contrast.Override(8f);
            adjust.saturation.Override(6f);
            adjust.colorFilter.Override(new Color(1.00f, 0.985f, 0.955f));

            var smh = profile.Add<UnityEngine.Rendering.Universal.ShadowsMidtonesHighlights>();
            smh.shadows.Override(new Vector4(0.88f, 0.95f, 1.10f, 0f));   // cool shadows
            smh.highlights.Override(new Vector4(1.06f, 1.02f, 0.94f, 0f)); // warm highlights

            var balance = profile.Add<UnityEngine.Rendering.Universal.WhiteBalance>();
            balance.temperature.Override(8f);
            balance.tint.Override(2f);

            var bloom = profile.Add<UnityEngine.Rendering.Universal.Bloom>();
            bloom.threshold.Override(1.10f);
            bloom.intensity.Override(0.35f);
            bloom.scatter.Override(0.65f);

            var vignette = profile.Add<UnityEngine.Rendering.Universal.Vignette>();
            vignette.intensity.Override(0.18f);
            vignette.smoothness.Override(0.40f);

            EditorUtility.SetDirty(profile);

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
        // Bound-state canon: the tufts are MOTIONLESS (Tarrock/GrassTuft carries no sway).
        private static void BuildGrassDetails(TerrainData terrainData, Terrain terrain)
        {
            Shader tuftShader = Shader.Find("Tarrock/GrassTuft");
            if (tuftShader == null)
            {
                Debug.LogWarning("[Tarrock] Tarrock/GrassTuft not found; grass details skipped.");
                return;
            }

            Mesh tuft = BuildTuftMesh();
            AssetDatabase.DeleteAsset(TuftMeshPath);
            AssetDatabase.CreateAsset(tuft, TuftMeshPath);

            var grassMat = AssetDatabase.LoadAssetAtPath<Material>(TuftMaterialPath);
            if (grassMat == null)
            {
                grassMat = new Material(tuftShader);
                AssetDatabase.CreateAsset(grassMat, TuftMaterialPath);
            }
            else
            {
                grassMat.shader = tuftShader;
            }

            grassMat.SetColor("_BaseColor", new Color(0.42f, 0.50f, 0.24f));
            grassMat.SetFloat("_ShadeWrap", 0.35f);
            grassMat.SetFloat("_AmbientBoost", 1f);
            grassMat.enableInstancing = true;
            EditorUtility.SetDirty(grassMat);

            // Detail prototypes want a PREFAB carrying the mesh + material.
            var temp = new GameObject("GrassTuft");
            temp.AddComponent<MeshFilter>().sharedMesh = tuft;
            temp.AddComponent<MeshRenderer>().sharedMaterial = grassMat;
            GameObject prefab = PrefabUtility.SaveAsPrefabAsset(temp, TuftPrefabPath);
            Object.DestroyImmediate(temp);

            var prototype = new DetailPrototype
            {
                prototype = prefab,
                usePrototypeMesh = true,
                useInstancing = true,
                renderMode = DetailRenderMode.VertexLit,
                // Scale factors on the 0.35 m tuft mesh. Ankle-to-shin height against the 1.7 m
                // Fool — the first pass shipped 0.7-1.4 and the meadow read as waist-high shrubs.
                minWidth = 0.45f,
                maxWidth = 0.8f,
                minHeight = 0.4f,
                maxHeight = 0.75f,
                noiseSpread = 0.15f,
                healthyColor = Color.white,
                dryColor = Color.white,
            };
            terrainData.detailPrototypes = new[] { prototype };

            const int DetailRes = 512;
            terrainData.SetDetailResolution(DetailRes, 32);
            // CRITICAL: Unity 6 defaults to CoverageMode, where layer values are 0-255 COVERAGE —
            // a painted "4" means 4/255 ≈ 2% and renders as one tuft per field (cost a debug
            // session, 2026-07-27). Our density map means instances per cell; say so. Must be set
            // BEFORE SetDetailLayer — both this and SetDetailResolution clear existing layers.
            terrainData.SetDetailScatterMode(DetailScatterMode.InstanceCountMode);

            // Density from the landform: grass on gentle green ground only (steepness under the
            // shader's rock threshold, above the cloud band, below the bleached tops), thinned by
            // broad noise so the meadow is patchy rather than a carpet.
            var density = new int[DetailRes, DetailRes];
            for (int dz = 0; dz < DetailRes; dz++)
            {
                float nz = (dz + 0.5f) / DetailRes;
                for (int dx = 0; dx < DetailRes; dx++)
                {
                    float nx = (dx + 0.5f) / DetailRes;
                    float steep = terrainData.GetSteepness(nx, nz);
                    float h = terrainData.GetInterpolatedHeight(nx, nz);
                    if (steep > 24f || h < 13f || h > 52f)
                    {
                        continue;
                    }

                    float wx = nx * TerrainSize;
                    float wz = nz * TerrainSize;
                    // 0-2 instances per half-metre cell (up to ~8/m²) — the live test showed 2/cell
                    // reads as a lush meadow; the noise thins it to patches so it breathes.
                    float patch = Fbm(wx * 0.045f + 5f, wz * 0.045f + 11f); // -1..1
                    int amount = Mathf.RoundToInt(Mathf.Lerp(0f, 2.2f, Mathf.InverseLerp(-0.15f, 0.75f, patch)));
                    density[dz, dx] = amount;
                }
            }

            terrainData.SetDetailLayer(0, 0, 0, density);
            terrain.detailObjectDistance = 90f;
            terrain.detailObjectDensity = 1f;
        }

        /// <summary>Three quads crossed at 60°, ~0.35 m, vertex-coloured dark base → light tip,
        /// tips leaning slightly outward. Solid stylised blades — no texture, no cutout.</summary>
        private static Mesh BuildTuftMesh()
        {
            var verts = new List<Vector3>();
            var cols = new List<Color>();
            var tris = new List<int>();
            var baseCol = new Color(0.55f, 0.62f, 0.42f);
            var tipCol = new Color(1.15f, 1.18f, 0.85f);

            for (int i = 0; i < 3; i++)
            {
                float a = i * Mathf.PI / 3f;
                var right = new Vector3(Mathf.Cos(a), 0f, Mathf.Sin(a)) * 0.16f;
                var lean = new Vector3(Mathf.Sin(a), 0f, -Mathf.Cos(a)) * 0.05f;
                int s = verts.Count;
                verts.Add(-right);
                verts.Add(right);
                verts.Add(-right * 0.55f + Vector3.up * 0.35f + lean);
                verts.Add(right * 0.55f + Vector3.up * 0.35f + lean);
                cols.Add(baseCol);
                cols.Add(baseCol);
                cols.Add(tipCol);
                cols.Add(tipCol);
                tris.AddRange(new[] { s, s + 2, s + 1, s + 1, s + 2, s + 3 });
            }

            var mesh = new Mesh { name = "GrassTuft" };
            mesh.SetVertices(verts);
            mesh.SetColors(cols);
            mesh.SetTriangles(tris, 0);
            mesh.RecalculateNormals();
            mesh.RecalculateBounds();
            return mesh;
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

        // The sea of cloud (world.md §The Cliff — island in cloud, director-blessed 2026-07-26).
        // A vast plane below every lip: the horizon is cloud-top, the drop is "lost in haze", the
        // knife-cut tile boundary is hidden below the deck, and the leap has something to fall INTO.
        // Motionless while bound, per canon. PROTO NOTE: the plane keeps its collider as a walkable
        // catch so a director who hops an edge isn't stuck falling — the real unscripted-fall
        // behaviour is the defeat loop (combat.md §Defeat) and wires up with the interaction layer.
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
            material.SetColor("_CloudBright", new Color(0.98f, 0.94f, 0.86f));
            material.SetColor("_CloudShade", new Color(0.78f, 0.76f, 0.74f));
            material.SetFloat("_MottleScale", 60f);
            material.SetFloat("_MottleScale2", 17f);
            material.SetColor("_HorizonColor", HorizonLinear);
            material.SetFloat("_HorizonStart", 220f);
            material.SetFloat("_HorizonEnd", 900f);
            EditorUtility.SetDirty(material);

            GameObject deck = GameObject.CreatePrimitive(PrimitiveType.Plane);
            deck.name = "CloudSea";
            // Unity's Plane is 10 m; ×300 → a 3 km deck. At y=11: high enough to swallow the sheer
            // faces quickly (director note 2026-07-27 — the drop must vanish into cloud, not slide
            // down to it), below the lowest walkable floor (west mouth ≈ 17 m; edges fall to 1.5).
            deck.transform.position = new Vector3(TerrainSize * 0.5f, 11.0f, TerrainSize * 0.5f);
            deck.transform.localScale = new Vector3(300f, 1f, 300f);
            deck.GetComponent<MeshRenderer>().sharedMaterial = material;
            deck.isStatic = true;

            // Clouds are an ending, not a floor (director note 2026-07-27 — you must not be able
            // to walk on the deck). The render surface loses its collider; a trigger slab just
            // beneath it catches fallen bodies and returns them to the spawn — the defeat-loop
            // stand-in (see CloudFallCatch).
            Object.DestroyImmediate(deck.GetComponent<MeshCollider>());
            var catchVolume = deck.AddComponent<BoxCollider>();
            catchVolume.isTrigger = true;
            catchVolume.center = new Vector3(0f, -0.4f, 0f);
            catchVolume.size = new Vector3(10f, 0.6f, 10f); // local; deck scale ×300 → 3 km slab

            var fallCatch = deck.AddComponent<CloudFallCatch>();
            var serialized = new SerializedObject(fallCatch);
            serialized.FindProperty("_respawnPoint").vector3Value =
                new Vector3(SpawnHint.x, SpawnHint.y, SpawnHint.z);
            serialized.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void BuildRegionWind()
        {
            // The Cliff is BOUND at the start of the game, so wind rests at 0 and the region holds its
            // breath (art-audio.md §The world-state is the art direction). The director scrub on
            // RegionWind is how you feel the unbound state without firing a flag.
            var windGo = new GameObject("RegionWind");
            windGo.AddComponent<RegionWind>();
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
