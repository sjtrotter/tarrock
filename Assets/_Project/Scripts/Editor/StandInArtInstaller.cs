namespace Tarrock.Editor
{

    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using UnityEditor;
    using UnityEditor.Animations;
    using UnityEngine;

    /// <summary>
    /// Editor command that wires the vendored CC0 stand-in art into the Cliff greybox (director
    /// feedback: "way too bland, can't tell if I'm moving, no animation"). Three jobs, all
    /// idempotent and headless-runnable via <c>-executeMethod</c>, mirroring
    /// <see cref="CliffGreyboxGenerator"/> / <see cref="PlayerRigInstaller"/>:
    ///
    /// 1. <b>Character import</b> — configures <c>RogueHooded.fbx</c> (KayKit Adventurers, the
    ///    Fool's stand-in) as a Generic rig, remaps its materials onto a single URP/Lit material
    ///    fed by the pack's atlas texture, and logs the embedded animation clips.
    /// 2. <b>Animator</b> — builds <c>RogueHooded.controller</c>: an Idle→Walk→Run 1D blend tree on
    ///    a <c>Speed</c> float plus a <c>Dodge</c>-gated roll state, driven at runtime by
    ///    <c>Tarrock.Player.PlayerAnimationDriver</c>.
    /// 3. <b>Greybox texturing</b> — stamps Kenney prototype grid textures onto the Grass/Stone/
    ///    Marker (and Void) materials so motion reads. The grid mapping in <see cref="GridConfigs"/>
    ///    is the single source of truth, shared with <see cref="CliffGreyboxGenerator"/> via
    ///    <see cref="TryApplyGridTexture"/> so a from-scratch regenerate produces identical output.
    ///
    /// Character <em>placement</em> into the scene lives in <see cref="PlayerRigInstaller"/> (it owns
    /// the rig); this command only prepares the assets those installers consume.
    /// </summary>
    public static class StandInArtInstaller
    {
        // -- Vendored KayKit character --------------------------------------------------------
        public const string CharacterModelPath = "Assets/ThirdParty/KayKit/Adventurers/RogueHooded.fbx";
        public const string CharacterTexturePath = "Assets/ThirdParty/KayKit/Adventurers/rogue_texture.png";

        private const string CharacterArtDir = "Assets/_Project/Art/Characters";
        public const string CharacterMaterialPath = CharacterArtDir + "/RogueHooded.mat";
        public const string CharacterControllerPath = CharacterArtDir + "/RogueHooded.controller";

        // -- Vendored Kenney prototype grid textures ------------------------------------------
        private const string KenneyDir = "Assets/ThirdParty/Kenney/PrototypeTextures";
        private const string GreenGridPath = KenneyDir + "/green_grid.png";
        private const string StoneGridPath = KenneyDir + "/stone_grid.png";
        private const string MarkerGridPath = KenneyDir + "/marker_grid.png";
        private const string LightGridPath = KenneyDir + "/light_grid.png";

        private const string GreyboxArtDir = "Assets/_Project/Art/Greybox";

        // Animator parameters — kept in lockstep with Tarrock.Player.PlayerAnimationDriver.
        private const string SpeedParameter = "Speed";
        private const string DodgeParameter = "Dodge";

        // Blend thresholds map to PlayerMotor's walk (4.5) / sprint (7) speeds so the blend tracks
        // the actual planar speed the driver feeds in.
        private const float WalkThreshold = 4.5f;
        private const float RunThreshold = 7f;

        // URP/Lit shader property ids.
        private static readonly int BaseMapId = Shader.PropertyToID("_BaseMap");
        private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");
        private static readonly int ColorId = Shader.PropertyToID("_Color");

        private static readonly Color NearWhite = new(0.9f, 0.9f, 0.9f);

        /// <summary>
        /// Grid-texturing recipe per greybox material name — the SSOT consumed by both this
        /// installer (patching existing <c>.mat</c> assets) and <see cref="CliffGreyboxGenerator"/>
        /// (fresh material creation). Base colours go near-white so the texture reads true.
        /// </summary>
        private static readonly Dictionary<string, GridConfig> GridConfigs = new()
        {
            // 240 m ground, tiled x60 → a readable 4 m grid cell (motion becomes legible).
            ["Grass"] = new GridConfig(GreenGridPath, new Vector2(60f, 60f), NearWhite),
            // Stone props (standing stones, waystation, campsite rings) — dark grey grid.
            ["Stone"] = new GridConfig(StoneGridPath, new Vector2(4f, 4f), NearWhite),
            // Interaction markers — orange grid.
            ["Marker"] = new GridConfig(MarkerGridPath, new Vector2(2f, 2f), NearWhite),
            // The far catch-slab below the cliff — light grid so the leap reads as motion.
            ["VoidGround"] = new GridConfig(LightGridPath, new Vector2(120f, 120f), NearWhite),
        };

        [MenuItem("Tarrock/Setup/Install Stand-In Art")]
        public static void Install()
        {
            bool modelReady = ConfigureCharacterModel();
            bool animatorReady = modelReady && BuildAnimatorController();
            int textured = ApplyGreyboxTextures();

            Debug.Log(
                "[Tarrock] Stand-in art installed: " +
                $"character model {(modelReady ? "configured" : "MISSING")}, " +
                $"animator {(animatorReady ? "built" : "skipped")}, " +
                $"{textured} greybox material(s) grid-textured. " +
                "Run \"Install Player Rig In Cliff Scene\" to place the character into the scene.");
        }

        // ---------------------------------------------------------------------------------
        // 1. Character model import configuration
        // ---------------------------------------------------------------------------------

        /// <summary>
        /// Configures RogueHooded.fbx as a Generic rig and remaps its material(s) onto a single
        /// URP/Lit material fed by the pack's atlas texture. Logs the embedded animation clips.
        /// Returns false (with a warning) if the vendored FBX is absent.
        /// </summary>
        private static bool ConfigureCharacterModel()
        {
            var importer = AssetImporter.GetAtPath(CharacterModelPath) as ModelImporter;
            if (importer == null)
            {
                Debug.LogWarning(
                    $"[Tarrock] Character model not found at {CharacterModelPath}; " +
                    "skipping character import (capsule fallback remains).");
                return false;
            }

            // KayKit rigs are Generic-friendly; a Generic avatar built from the model itself
            // carries the 75 embedded clips without humanoid retargeting.
            importer.animationType = ModelImporterAnimationType.Generic;
            importer.avatarSetup = ModelImporterAvatarSetup.CreateFromThisModel;
            importer.importAnimation = true;
            importer.materialImportMode = ModelImporterMaterialImportMode.ImportStandard;
            importer.SaveAndReimport();

            Material characterMaterial = CreateCharacterMaterial();
            RemapModelMaterials(importer, characterMaterial);

            LogEmbeddedClips();
            return true;
        }

        private static Material CreateCharacterMaterial()
        {
            Directory.CreateDirectory(CharacterArtDir);

            var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(CharacterTexturePath);
            Material material = AssetDatabase.LoadAssetAtPath<Material>(CharacterMaterialPath);
            if (material == null)
            {
                material = new Material(Shader.Find("Universal Render Pipeline/Lit")) { name = "RogueHooded" };
                AssetDatabase.CreateAsset(material, CharacterMaterialPath);
            }

            material.SetColor(BaseColorId, Color.white);
            if (texture != null)
            {
                material.SetTexture(BaseMapId, texture);
                material.SetTexture(MainTexId, texture);
            }
            else
            {
                Debug.LogWarning($"[Tarrock] Character atlas texture missing at {CharacterTexturePath}.");
            }

            EditorUtility.SetDirty(material);
            AssetDatabase.SaveAssets();
            return material;
        }

        private static void RemapModelMaterials(ModelImporter importer, Material target)
        {
            Object[] embedded = AssetDatabase.LoadAllAssetsAtPath(CharacterModelPath);
            int remapped = 0;
            foreach (Object obj in embedded)
            {
                if (obj is Material sourceMaterial)
                {
                    importer.AddRemap(
                        new AssetImporter.SourceAssetIdentifier(typeof(Material), sourceMaterial.name), target);
                    remapped++;
                }
            }

            importer.SaveAndReimport();
            Debug.Log($"[Tarrock] Remapped {remapped} embedded FBX material slot(s) onto {CharacterMaterialPath}.");
        }

        private static void LogEmbeddedClips()
        {
            List<AnimationClip> clips = LoadCharacterClips();
            Debug.Log(
                $"[Tarrock] RogueHooded.fbx embedded animation clips ({clips.Count}): " +
                string.Join(", ", clips.Select(c => c.name)));
        }

        private static List<AnimationClip> LoadCharacterClips()
        {
            return AssetDatabase.LoadAllAssetsAtPath(CharacterModelPath)
                .OfType<AnimationClip>()
                .Where(c => !c.name.StartsWith("__preview__"))
                .OrderBy(c => c.name)
                .ToList();
        }

        // ---------------------------------------------------------------------------------
        // 2. Animator controller (Idle→Walk→Run blend + Dodge roll)
        // ---------------------------------------------------------------------------------

        /// <summary>
        /// (Re)builds RogueHooded.controller from the FBX's embedded clips: a 1D <c>Speed</c> blend
        /// tree (Idle→Walk→Run) plus a <c>Dodge</c>-gated roll state. Returns false if the model has
        /// no usable clips.
        /// </summary>
        private static bool BuildAnimatorController()
        {
            List<AnimationClip> clips = LoadCharacterClips();
            if (clips.Count == 0)
            {
                Debug.LogWarning("[Tarrock] No animation clips on RogueHooded.fbx; skipping AnimatorController.");
                return false;
            }

            AnimationClip idle = FindClip(clips, "Idle");
            AnimationClip walk = FindClip(clips, "Walking_A") ?? FindClip(clips, "Walking_B") ?? FindClip(clips, "Walk");
            AnimationClip run = FindClip(clips, "Running_A") ?? FindClip(clips, "Running_B") ?? FindClip(clips, "Run");
            AnimationClip roll = FindClip(clips, "Dodge_Forward") ?? FindClip(clips, "Roll") ?? FindClip(clips, "Dodge");

            if (idle == null && walk == null && run == null)
            {
                Debug.LogWarning("[Tarrock] Could not resolve Idle/Walk/Run clips; skipping AnimatorController.");
                return false;
            }

            Directory.CreateDirectory(CharacterArtDir);
            if (File.Exists(CharacterControllerPath))
            {
                AssetDatabase.DeleteAsset(CharacterControllerPath);
            }

            AnimatorController controller = AnimatorController.CreateAnimatorControllerAtPath(CharacterControllerPath);
            controller.AddParameter(SpeedParameter, AnimatorControllerParameterType.Float);
            controller.AddParameter(DodgeParameter, AnimatorControllerParameterType.Bool);

            AnimatorStateMachine rootStateMachine = controller.layers[0].stateMachine;

            AnimatorState locomotion = controller.CreateBlendTreeInController("Locomotion", out BlendTree tree, 0);
            tree.blendType = BlendTreeType.Simple1D;
            tree.blendParameter = SpeedParameter;
            tree.useAutomaticThresholds = false;
            if (idle != null)
            {
                tree.AddChild(idle, 0f);
            }

            if (walk != null)
            {
                tree.AddChild(walk, WalkThreshold);
            }

            if (run != null)
            {
                tree.AddChild(run, RunThreshold);
            }

            rootStateMachine.defaultState = locomotion;

            if (roll != null)
            {
                WireRollState(rootStateMachine, locomotion, roll);
            }

            EditorUtility.SetDirty(controller);
            AssetDatabase.SaveAssets();

            Debug.Log(
                $"[Tarrock] Built {CharacterControllerPath}: blend tree [" +
                $"Idle={(idle != null ? idle.name : "-")}, Walk={(walk != null ? walk.name : "-")}, " +
                $"Run={(run != null ? run.name : "-")}] + roll={(roll != null ? roll.name : "none")}.");
            return true;
        }

        private static void WireRollState(AnimatorStateMachine sm, AnimatorState locomotion, AnimationClip roll)
        {
            AnimatorState rollState = sm.AddState("Roll");
            rollState.motion = roll;

            AnimatorStateTransition toRoll = locomotion.AddTransition(rollState);
            toRoll.hasExitTime = false;
            toRoll.duration = 0.05f;
            toRoll.AddCondition(AnimatorConditionMode.If, 0f, DodgeParameter);

            AnimatorStateTransition fromRoll = rollState.AddTransition(locomotion);
            fromRoll.hasExitTime = false;
            fromRoll.duration = 0.1f;
            fromRoll.AddCondition(AnimatorConditionMode.IfNot, 0f, DodgeParameter);
        }

        private static AnimationClip FindClip(IEnumerable<AnimationClip> clips, string name)
        {
            return clips.FirstOrDefault(c => string.Equals(c.name, name, System.StringComparison.OrdinalIgnoreCase));
        }

        // ---------------------------------------------------------------------------------
        // 3. Greybox grid texturing (SSOT shared with CliffGreyboxGenerator)
        // ---------------------------------------------------------------------------------

        private static int ApplyGreyboxTextures()
        {
            int count = 0;
            foreach (string materialName in GridConfigs.Keys)
            {
                string path = $"{GreyboxArtDir}/{materialName}.mat";
                var material = AssetDatabase.LoadAssetAtPath<Material>(path);
                if (material != null && TryApplyGridTexture(material, materialName))
                {
                    count++;
                }
            }

            if (count > 0)
            {
                AssetDatabase.SaveAssets();
            }

            return count;
        }

        /// <summary>
        /// Stamps the Kenney grid texture (tiling + near-white base colour) for the given greybox
        /// material name onto <paramref name="material"/>. Returns false — leaving the material's
        /// plain fallback colour untouched — when the name has no grid mapping or the vendored
        /// texture is absent. The single texturing entry point shared with
        /// <see cref="CliffGreyboxGenerator"/> so the generator and the on-disk assets never drift.
        /// </summary>
        public static bool TryApplyGridTexture(Material material, string greyboxMaterialName)
        {
            if (material == null || !GridConfigs.TryGetValue(greyboxMaterialName, out GridConfig config))
            {
                return false;
            }

            var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(config.TexturePath);
            if (texture == null)
            {
                return false; // ThirdParty absent — keep the greybox fallback colour.
            }

            material.SetTexture(BaseMapId, texture);
            material.SetTextureScale(BaseMapId, config.Tiling);
            material.SetTexture(MainTexId, texture);
            material.SetTextureScale(MainTexId, config.Tiling);
            material.SetColor(BaseColorId, config.BaseColor);
            material.SetColor(ColorId, config.BaseColor);
            EditorUtility.SetDirty(material);
            return true;
        }

        private readonly struct GridConfig
        {
            public readonly string TexturePath;
            public readonly Vector2 Tiling;
            public readonly Color BaseColor;

            public GridConfig(string texturePath, Vector2 tiling, Color baseColor)
            {
                TexturePath = texturePath;
                Tiling = tiling;
                BaseColor = baseColor;
            }
        }
    }
}
