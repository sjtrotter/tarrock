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
    public static partial class TerrainRegionGenerator
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

        /// <summary>Slope thresholds are authored in DEGREES (which is how the terrain grammar and
        /// the CharacterController's slope limit are both discussed) and consumed by the ground
        /// shader as steepness = 1 - N.y. Converting here keeps the readable number at the call
        /// site instead of a table of unexplained decimals.</summary>
        private static float SteepnessFromDegrees(float degrees)
        {
            return 1f - Mathf.Cos(degrees * Mathf.Deg2Rad);
        }

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
