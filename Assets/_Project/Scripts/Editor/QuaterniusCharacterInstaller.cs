namespace Tarrock.Editor
{

    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using Tarrock.Player;
    using UnityEditor;
    using UnityEditor.Animations;
    using UnityEditor.SceneManagement;
    using UnityEngine;

    /// <summary>
    /// Editor command that swaps the Fool's stand-in over to the Quaternius Universal Base Character
    /// (adult-proportioned CC0 body) driven by the Quaternius Universal Animation Library. The
    /// director rejected both the KayKit chibi and the primitive-built Fool; this is the new
    /// playtest stand-in. Idempotent and headless-runnable via <c>-executeMethod</c>, mirroring
    /// <see cref="StandInArtInstaller"/> / <see cref="PlayerRigInstaller"/>. Four jobs:
    ///
    /// 1. <b>Model import</b> — configures the body FBX (Generic rig, avatar CreateFromThisModel) and
    ///    the two UAL animation FBXs (Generic, CopyFromOther the body's avatar so all clips bind to
    ///    the one skeleton), remaps the body's materials onto a single URP/Lit skin material, loops
    ///    the locomotion clips, and logs every embedded clip name.
    /// 2. <b>Animator</b> — builds <c>FoolV2.controller</c>: an Idle→Walk→Run 1D blend tree on the
    ///    <c>Speed</c> float plus a <c>Dodge</c>-gated roll state, driven at runtime by
    ///    <c>Tarrock.Player.PlayerAnimationDriver</c> (same contract as the KayKit controller).
    /// 3. <b>Visual swap</b> — in the Cliff scene, replaces PlayerRig's "Visual" child with the
    ///    Quaternius body (scaled to 1.8m, facing +Z) and rewires the animation driver's animator,
    ///    leaving motor/dodge/input untouched.
    /// 4. <b>Cleanup</b> — deletes the throwaway lineup objects (KayKit rogue + adult mannequin).
    ///
    /// To revert to the KayKit stand-in, re-run "Tarrock/Setup/Install Player Rig In Cliff Scene"
    /// after deleting Assets/_Project/Art/Characters/FoolV2.controller (the rig installer prefers
    /// the Quaternius body only while that controller exists).
    /// </summary>
    public static class QuaterniusCharacterInstaller
    {
        // -- Vendored Quaternius assets -------------------------------------------------------
        private const string QuaterniusDir = "Assets/ThirdParty/Quaternius";
        public const string BodyModelPath = QuaterniusDir + "/UniversalBaseCharacters/Superhero_Male_FullBody.fbx";
        private const string Ual1Path = QuaterniusDir + "/UniversalAnimationLibrary/UAL1_Standard.fbx";
        private const string Ual2Path = QuaterniusDir + "/UniversalAnimationLibrary/UAL2_Standard.fbx";

        private const string TextureDir = QuaterniusDir + "/UniversalBaseCharacters/Textures";
        private const string BodyBaseMapPath = TextureDir + "/T_Superhero_Male_Ligh.png";
        private const string BodyNormalMapPath = TextureDir + "/Normals Unity - Godot/T_Superhero_Male_Normal.png";

        private const string CharacterArtDir = "Assets/_Project/Art/Characters";
        public const string BodyMaterialPath = CharacterArtDir + "/QuaterniusFool.mat";
        public const string ControllerPath = CharacterArtDir + "/FoolV2.controller";

        // -- Modular outfit (Male Peasant body + Ranger hood) ----------------------------------
        // The Fool is a humble storybook wanderer — a traveler, not a warrior — so the outfit is
        // peasant body/arms/legs/feet plus the ranger HOOD, and no pauldrons
        // (docs/design/characters.md §The Fool). These FBXs are skinned to the SAME universal rig
        // as the body, so each piece rides the body's skeleton by name-matched bone rebinding.
        private const string OutfitDir = QuaterniusDir + "/ModularOutfitsFantasy";
        private static readonly string[] OutfitPieces =
        {
            OutfitDir + "/Male_Peasant_Body.fbx",
            OutfitDir + "/Male_Peasant_Legs.fbx",
            OutfitDir + "/Male_Peasant_Feet.fbx",
            OutfitDir + "/Male_Peasant_Arms.fbx",
            OutfitDir + "/Male_Ranger_Head_Hood.fbx",
        };

        // Attached piece objects are named "Outfit_<fbx>" under the Visual, so undressing is
        // "delete every Visual child whose name starts with this prefix" (also the idempotency key).
        internal const string OutfitObjectPrefix = "Outfit_";
        private const string ArmatureName = "Armature";

        private const string PeasantTexDir = OutfitDir + "/Textures/Peasant";
        private const string RangerTexDir = OutfitDir + "/Textures/Ranger";
        private const string PeasantBaseMapPath = PeasantTexDir + "/T_Peasant_BaseColor.png";
        private const string PeasantNormalMapPath = PeasantTexDir + "/T_Peasant_Normal.png";
        private const string RangerBaseMapPath = RangerTexDir + "/T_Ranger_BaseColor.png";
        private const string RangerNormalMapPath = RangerTexDir + "/T_Ranger_Normal.png";
        public const string PeasantMaterialPath = CharacterArtDir + "/QuaterniusPeasant.mat";
        public const string HoodMaterialPath = CharacterArtDir + "/QuaterniusRangerHood.mat";

        private const string ScenePath = "Assets/_Project/Scenes/Regions/Cliff.unity";
        private const string PlayerRootName = "PlayerRig";
        private const string VisualName = "Visual";
        private const float TargetHeight = 1.8f;

        // The Quaternius base mesh is authored facing −Z (not +X as first guessed — that yaw made
        // the character face 90° right of travel, playtest-confirmed); the rig (PlayerMotor) drives
        // forward as +Z, so the Visual is yawed 180° about Y. Verified by front-view screenshot:
        // face/chest toward the rig's forward axis.
        internal const float ModelForwardYawFix = 180f;

        // Throwaway comparison props to purge from the Cliff scene.
        private static readonly string[] LineupObjectNames = { "Lineup_KayKitRogue", "Lineup_AdultMannequin" };

        // Animator parameters — kept in lockstep with Tarrock.Player.PlayerAnimationDriver.
        private const string SpeedParameter = "Speed";
        private const string DodgeParameter = "Dodge";

        // Blend thresholds map to PlayerMotor's walk (4.5) / sprint (7) speeds.
        private const float WalkThreshold = 2.8f; // must track PlayerMotor._walkSpeed
        private const float RunThreshold = 7f;

        // PlayerDodge's movement window; the roll clip is time-scaled to fit it.
        private const float DodgeMovementSeconds = 0.6f; // must track PlayerDodge._dodgeDuration

        // Locomotion clip families that must loop; roll/dodge stay one-shot.
        private static readonly string[] LoopingFamilies = { "idle", "walk", "run", "jog", "strafe" };

        // DIRECTOR-TUNABLE WALK CLIP — one-line swap point for the locomotion walk cycle.
        // Value is the clip's short name (the segment after the last '|'). Default is the natural
        // UAL1 "Walk_Loop"; the director rejected the stiff "Walk_Formal_Loop" march. UAL2 adds no
        // plain walk (only "Walk_Carry_Loop" and "Zombie_Walk_Fwd_Loop"). Change ONLY with director
        // signoff — PickWalk falls back to fuzzy matching if this exact clip is absent.
        internal const string WalkClipShortName = "Walk_Loop";

        private static readonly int BaseMapId = Shader.PropertyToID("_BaseMap");
        private static readonly int MainTexId = Shader.PropertyToID("_MainTex");
        private static readonly int BaseColorId = Shader.PropertyToID("_BaseColor");
        private static readonly int BumpMapId = Shader.PropertyToID("_BumpMap");

        [MenuItem("Tarrock/Setup/Install Quaternius Fool")]
        public static void Install()
        {
            if (AssetImporter.GetAtPath(BodyModelPath) is not ModelImporter)
            {
                Debug.LogError(
                    $"[Tarrock] Quaternius body FBX not found at {BodyModelPath}; aborting install.");
                return;
            }

            Avatar bodyAvatar = ConfigureBodyModel();
            ConfigureAnimationLibrary(Ual1Path, bodyAvatar);
            ConfigureAnimationLibrary(Ual2Path, bodyAvatar);
            ConfigureOutfitModels();

            List<AnimationClip> clips = LoadLibraryClips();
            LogClips("UAL1_Standard", Ual1Path);
            LogClips("UAL2_Standard", Ual2Path);

            bool animatorReady = BuildAnimatorController(clips);
            bool swapped = SwapPlayerVisual();

            Debug.Log(
                "[Tarrock] Quaternius Fool installed: " +
                $"animator {(animatorReady ? "built" : "SKIPPED")}, " +
                $"visual {(swapped ? "swapped" : "NOT swapped")}. " +
                "Revert to KayKit via \"Install Player Rig In Cliff Scene\" after deleting FoolV2.controller.");
        }

        // ---------------------------------------------------------------------------------
        // 1. Model import configuration
        // ---------------------------------------------------------------------------------

        /// <summary>
        /// Configures the body FBX as a Generic rig with an avatar built from its own skeleton, then
        /// remaps its embedded materials onto a single URP/Lit skin material. Returns the generated
        /// Avatar (null if none was produced) so the animation FBXs can copy it.
        /// </summary>
        private static Avatar ConfigureBodyModel()
        {
            var importer = (ModelImporter)AssetImporter.GetAtPath(BodyModelPath);
            importer.animationType = ModelImporterAnimationType.Generic;
            importer.avatarSetup = ModelImporterAvatarSetup.CreateFromThisModel;
            importer.importAnimation = true;
            importer.materialImportMode = ModelImporterMaterialImportMode.ImportStandard;
            importer.SaveAndReimport();

            Material skin = CreateBodyMaterial();
            RemapModelMaterials(importer, skin);

            Avatar avatar = AssetDatabase.LoadAllAssetsAtPath(BodyModelPath).OfType<Avatar>().FirstOrDefault();
            Debug.Log(
                $"[Tarrock] Body {BodyModelPath} configured (Generic). " +
                $"Avatar {(avatar != null ? "'" + avatar.name + "'" : "MISSING")}.");
            return avatar;
        }

        /// <summary>
        /// Configures a UAL animation FBX as Generic and — preferring CopyFromOther the body's avatar
        /// so its clips bind to the one skeleton — reimports it, then loops the locomotion clips.
        /// Falls back to CreateFromThisModel if the body avatar is absent or fails to assign (the rig
        /// is universal, so path-based Generic bindings play either way).
        /// </summary>
        private static void ConfigureAnimationLibrary(string path, Avatar bodyAvatar)
        {
            if (AssetImporter.GetAtPath(path) is not ModelImporter importer)
            {
                Debug.LogWarning($"[Tarrock] Animation FBX not found at {path}; skipping.");
                return;
            }

            importer.animationType = ModelImporterAnimationType.Generic;
            importer.importAnimation = true;

            bool copied = false;
            if (bodyAvatar != null)
            {
                importer.avatarSetup = ModelImporterAvatarSetup.CopyFromOther;
                importer.sourceAvatar = bodyAvatar;
                copied = importer.sourceAvatar == bodyAvatar;
            }

            if (!copied)
            {
                importer.avatarSetup = ModelImporterAvatarSetup.CreateFromThisModel;
                importer.sourceAvatar = null;
            }

            ConfigureClipLooping(importer);
            importer.SaveAndReimport();
            Debug.Log(
                $"[Tarrock] {Path.GetFileName(path)} configured (Generic, " +
                $"avatar {(copied ? "CopyFromOther body" : "CreateFromThisModel")}).");
        }

        /// <summary>
        /// FBX clips import with looping OFF by default, freezing at the end of a cycle. Loop every
        /// cyclic locomotion clip (idle/walk/run/jog/strafe families); leave one-shots (roll/dodge/
        /// attacks/hits) as imported.
        /// </summary>
        private static void ConfigureClipLooping(ModelImporter importer)
        {
            ModelImporterClipAnimation[] clips = importer.clipAnimations is { Length: > 0 }
                ? importer.clipAnimations
                : importer.defaultClipAnimations;

            foreach (ModelImporterClipAnimation clip in clips)
            {
                string name = clip.name.ToLowerInvariant();
                if (name.Contains("roll") || name.Contains("dodge"))
                {
                    continue;
                }

                if (LoopingFamilies.Any(family => name.Contains(family)))
                {
                    clip.loopTime = true;
                }
            }

            importer.clipAnimations = clips;
        }

        private static Material CreateBodyMaterial()
        {
            Directory.CreateDirectory(CharacterArtDir);

            Material material = AssetDatabase.LoadAssetAtPath<Material>(BodyMaterialPath);
            if (material == null)
            {
                material = new Material(Shader.Find("Universal Render Pipeline/Lit")) { name = "QuaterniusFool" };
                AssetDatabase.CreateAsset(material, BodyMaterialPath);
            }

            material.SetColor(BaseColorId, Color.white);

            var baseMap = AssetDatabase.LoadAssetAtPath<Texture2D>(BodyBaseMapPath);
            if (baseMap != null)
            {
                material.SetTexture(BaseMapId, baseMap);
                material.SetTexture(MainTexId, baseMap);
            }
            else
            {
                // No atlas — fall back to a flat skin tone so the body still reads on-screen.
                material.SetColor(BaseColorId, new Color(0.82f, 0.63f, 0.5f));
                Debug.LogWarning($"[Tarrock] Body base map missing at {BodyBaseMapPath}; using flat skin tone.");
            }

            if (EnsureNormalMap(BodyNormalMapPath) is { } normal)
            {
                material.SetTexture(BumpMapId, normal);
                material.EnableKeyword("_NORMALMAP");
            }

            EditorUtility.SetDirty(material);
            AssetDatabase.SaveAssets();
            return material;
        }

        // Textures import as color maps by default; a normal map must be flagged so URP reads it.
        private static Texture2D EnsureNormalMap(string path)
        {
            if (AssetImporter.GetAtPath(path) is TextureImporter texImporter &&
                texImporter.textureType != TextureImporterType.NormalMap)
            {
                texImporter.textureType = TextureImporterType.NormalMap;
                texImporter.SaveAndReimport();
            }

            return AssetDatabase.LoadAssetAtPath<Texture2D>(path);
        }

        private static void RemapModelMaterials(ModelImporter importer, Material target)
        {
            int remapped = 0;
            foreach (Object obj in AssetDatabase.LoadAllAssetsAtPath(BodyModelPath))
            {
                if (obj is Material sourceMaterial)
                {
                    importer.AddRemap(
                        new AssetImporter.SourceAssetIdentifier(typeof(Material), sourceMaterial.name), target);
                    remapped++;
                }
            }

            importer.SaveAndReimport();
            Debug.Log($"[Tarrock] Remapped {remapped} embedded body material slot(s) onto {BodyMaterialPath}.");
        }

        private static void LogClips(string label, string path)
        {
            List<AnimationClip> clips = LoadClips(path);
            Debug.Log(
                $"[Tarrock] {label}.fbx clips ({clips.Count}): " +
                string.Join(", ", clips.Select(c => c.name)));
        }

        private static List<AnimationClip> LoadLibraryClips()
        {
            var clips = new List<AnimationClip>();
            clips.AddRange(LoadClips(Ual1Path));
            clips.AddRange(LoadClips(Ual2Path));
            return clips;
        }

        private static List<AnimationClip> LoadClips(string path)
        {
            return AssetDatabase.LoadAllAssetsAtPath(path)
                .OfType<AnimationClip>()
                .Where(c => !c.name.StartsWith("__preview__"))
                .OrderBy(c => c.name)
                .ToList();
        }

        // ---------------------------------------------------------------------------------
        // 2. Animator controller (Idle→Walk→Run blend + Dodge roll)
        // ---------------------------------------------------------------------------------

        private static bool BuildAnimatorController(List<AnimationClip> clips)
        {
            if (clips.Count == 0)
            {
                Debug.LogWarning("[Tarrock] No clips loaded from the UAL FBXs; skipping FoolV2.controller.");
                return false;
            }

            AnimationClip idle = PickIdle(clips);
            AnimationClip walk = PickWalk(clips);
            AnimationClip run = PickRun(clips);
            AnimationClip roll = PickRoll(clips);

            if (idle == null && walk == null && run == null)
            {
                Debug.LogWarning("[Tarrock] Could not resolve Idle/Walk/Run from the UAL; skipping FoolV2.controller.");
                return false;
            }

            Directory.CreateDirectory(CharacterArtDir);
            if (File.Exists(ControllerPath))
            {
                AssetDatabase.DeleteAsset(ControllerPath);
            }

            AnimatorController controller = AnimatorController.CreateAnimatorControllerAtPath(ControllerPath);
            controller.AddParameter(SpeedParameter, AnimatorControllerParameterType.Float);
            controller.AddParameter(DodgeParameter, AnimatorControllerParameterType.Bool);

            AnimatorStateMachine sm = controller.layers[0].stateMachine;

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

            sm.defaultState = locomotion;

            if (roll != null)
            {
                WireRollState(sm, locomotion, roll);
            }

            EditorUtility.SetDirty(controller);
            AssetDatabase.SaveAssets();

            Debug.Log(
                $"[Tarrock] Built {ControllerPath}: blend [" +
                $"Idle={Name(idle)}, Walk={Name(walk)}, Run={Name(run)}] + roll={Name(roll)}.");
            return true;
        }

        private static void WireRollState(AnimatorStateMachine sm, AnimatorState locomotion, AnimationClip roll)
        {
            AnimatorState rollState = sm.AddState("Roll");
            rollState.motion = roll;

            // Fit the whole roll into the dodge's movement window (PlayerDodge, 0.45s); never slow
            // below authored speed (an under-cranked roll reads as a floaty hop).
            if (roll.length > 0.01f)
            {
                // Play near authored speed: 2x+ sped-up rolls read as a glitch (playtest).
                rollState.speed = Mathf.Clamp(roll.length / DodgeMovementSeconds, 0.9f, 1.4f);
            }

            AnimatorStateTransition toRoll = locomotion.AddTransition(rollState);
            toRoll.hasExitTime = false;
            toRoll.duration = 0.05f;
            toRoll.AddCondition(AnimatorConditionMode.If, 0f, DodgeParameter);

            AnimatorStateTransition fromRoll = rollState.AddTransition(locomotion);
            fromRoll.hasExitTime = false;
            fromRoll.duration = 0.1f;
            fromRoll.AddCondition(AnimatorConditionMode.IfNot, 0f, DodgeParameter);
        }

        // -- Clip pickers (short-name priority, then fuzzy) -----------------------------------
        // UAL clips are named "Armature|<Core>_Loop"; we match the <Core> segment (after the last
        // '|') so a canonical Idle_Loop wins over Crouch_Idle_Loop, and the natural Walk_Loop wins
        // over the stiff Walk_Formal_Loop (the director's exact complaint about the KayKit march).

        private static AnimationClip PickIdle(IEnumerable<AnimationClip> clips)
        {
            return ByPriority(clips, "Idle_Loop", "Idle", "Idle_No_Loop")
                ?? FirstContaining(clips, "idle", exclude: new[]
                {
                    "crouch", "sitting", "zombie", "spell", "pistol", "sword", "shield", "rail",
                    "lantern", "torch", "talking", "phone", "fold", "driving", "swim", "ninja",
                });
        }

        private static AnimationClip PickWalk(IEnumerable<AnimationClip> clips)
        {
            return ByPriority(clips, WalkClipShortName, "Walk")
                ?? FirstContaining(clips, "walk", exclude: new[]
                {
                    "formal", "carry", "back", "left", "right", "strafe", "turn", "zombie",
                });
        }

        private static AnimationClip PickRun(IEnumerable<AnimationClip> clips)
        {
            return ByPriority(clips, "Jog_Fwd_Loop", "Run_Loop", "Run", "Sprint_Loop", "Jog")
                ?? FirstContaining(clips, "jog", exclude: new[] { "back", "left", "right", "strafe", "turn" })
                ?? FirstContaining(clips, "run", exclude: new[] { "back", "left", "right", "strafe", "turn" })
                ?? FirstContaining(clips, "sprint");
        }

        private static AnimationClip PickRoll(IEnumerable<AnimationClip> clips)
        {
            return ByPriority(clips, "Roll", "Roll_Fwd", "Dodge_Forward", "Dodge")
                ?? FirstContaining(clips, "roll", exclude: new[] { "back", "left", "right" })
                ?? FirstContaining(clips, "dodge", exclude: new[] { "back", "left", "right" });
        }

        // Returns the first clip whose short name (after the last '|') equals one of the candidate
        // core names, in candidate order — an earlier candidate always beats a later one.
        private static AnimationClip ByPriority(IEnumerable<AnimationClip> clips, params string[] candidates)
        {
            List<AnimationClip> list = clips as List<AnimationClip> ?? clips.ToList();
            foreach (string candidate in candidates)
            {
                AnimationClip match = list.FirstOrDefault(
                    c => string.Equals(ShortName(c.name), candidate, System.StringComparison.OrdinalIgnoreCase));
                if (match != null)
                {
                    return match;
                }
            }

            return null;
        }

        private static string ShortName(string clipName)
        {
            int bar = clipName.LastIndexOf('|');
            return bar >= 0 ? clipName.Substring(bar + 1) : clipName;
        }

        private static AnimationClip FirstContaining(IEnumerable<AnimationClip> clips, string token, string[] exclude = null)
        {
            return clips.FirstOrDefault(c =>
            {
                string n = c.name.ToLowerInvariant();
                if (!n.Contains(token))
                {
                    return false;
                }

                return exclude == null || !exclude.Any(x => n.Contains(x));
            });
        }

        private static string Name(AnimationClip clip)
        {
            return clip != null ? clip.name : "-";
        }

        // ---------------------------------------------------------------------------------
        // 2b. Modular outfit (skinned attachment onto the shared universal rig)
        // ---------------------------------------------------------------------------------

        /// <summary>
        /// Configures each outfit FBX as a Generic, animation-free model. The pieces are skinned to
        /// the same universal rig as the body; they need no avatar of their own because
        /// <see cref="AttachOutfitPieces"/> rebinds every bone onto the body's skeleton by name.
        /// Embedded materials import normally (their names — MI_Peasant / MI_Regular_Male / MI_Ranger
        /// — drive per-slot material assignment at attach time).
        /// </summary>
        private static void ConfigureOutfitModels()
        {
            foreach (string path in OutfitPieces)
            {
                if (AssetImporter.GetAtPath(path) is not ModelImporter importer)
                {
                    Debug.LogWarning($"[Tarrock] Outfit FBX not found at {path}; skipping import config.");
                    continue;
                }

                importer.animationType = ModelImporterAnimationType.Generic;
                importer.importAnimation = false;
                importer.avatarSetup = ModelImporterAvatarSetup.NoAvatar;
                importer.SaveAndReimport();
            }
        }

        /// <summary>
        /// Attaches the Peasant body + Ranger hood to the given Visual so the clothing animates with
        /// the body. For each piece: instantiate and unpack it under the Visual, rebind every
        /// <see cref="SkinnedMeshRenderer"/>'s <c>bones</c>/<c>rootBone</c> onto the body's skeleton
        /// by name-matching, remap material slots by family (Peasant cloth / Ranger hood / bare skin),
        /// then delete the piece's own duplicate armature so only the renderers ride the shared rig.
        /// Idempotent: removes any previously attached "Outfit_*" children first, so re-running the
        /// installer re-dresses cleanly. Also invoked by <c>PlayerRigInstaller</c> so a rig reinstall
        /// keeps the clothes.
        /// </summary>
        internal static void AttachOutfitPieces(GameObject visual)
        {
            if (visual == null)
            {
                return;
            }

            Transform armature = visual.transform.Find(ArmatureName);
            if (armature == null)
            {
                Debug.LogWarning(
                    $"[Tarrock] Visual '{visual.name}' has no '{ArmatureName}' skeleton; cannot attach the outfit.");
                return;
            }

            // Name → Transform over the body's skeleton (bone names are unique on this rig).
            var boneMap = new Dictionary<string, Transform>();
            foreach (Transform t in armature.GetComponentsInChildren<Transform>(true))
            {
                boneMap[t.name] = t;
            }

            Material peasant = CreateOutfitMaterial(
                PeasantMaterialPath, "QuaterniusPeasant", PeasantBaseMapPath, PeasantNormalMapPath);
            Material hood = CreateOutfitMaterial(
                HoodMaterialPath, "QuaterniusRangerHood", RangerBaseMapPath, RangerNormalMapPath);
            Material skin = AssetDatabase.LoadAssetAtPath<Material>(BodyMaterialPath);

            RemoveAttachedOutfit(visual);

            int attached = 0;
            int totalMatched = 0;
            int totalMissed = 0;
            foreach (string path in OutfitPieces)
            {
                var model = AssetDatabase.LoadAssetAtPath<GameObject>(path);
                if (model == null)
                {
                    Debug.LogWarning($"[Tarrock] Outfit piece missing at {path}; skipping.");
                    continue;
                }

                var piece = (GameObject)PrefabUtility.InstantiatePrefab(model);
                // Unpack so the piece's own armature child can be deleted (prefab-owned children
                // cannot be removed from a connected instance).
                PrefabUtility.UnpackPrefabInstance(
                    piece, PrefabUnpackMode.Completely, InteractionMode.AutomatedAction);

                piece.name = OutfitObjectPrefix + Path.GetFileNameWithoutExtension(path);
                piece.transform.SetParent(visual.transform, false);
                piece.transform.localPosition = Vector3.zero;
                piece.transform.localRotation = Quaternion.identity;
                piece.transform.localScale = Vector3.one;

                foreach (SkinnedMeshRenderer smr in piece.GetComponentsInChildren<SkinnedMeshRenderer>(true))
                {
                    RebindToBody(smr, boneMap, ref totalMatched, ref totalMissed);
                    AssignOutfitMaterials(smr, peasant, hood, skin);
                    // Bounds are authored against the piece's own armature; skip culling so a
                    // re-parented, re-bound piece never blinks out at oblique camera angles.
                    smr.updateWhenOffscreen = true;
                }

                Transform ownArmature = piece.transform.Find(ArmatureName);
                if (ownArmature != null)
                {
                    Object.DestroyImmediate(ownArmature.gameObject);
                }

                attached++;
            }

            Debug.Log(
                $"[Tarrock] Attached {attached} outfit piece(s) to '{visual.name}' " +
                $"(bones matched {totalMatched}, unmatched {totalMissed}).");
        }

        private static void RemoveAttachedOutfit(GameObject visual)
        {
            var stale = new List<GameObject>();
            foreach (Transform child in visual.transform)
            {
                if (child.name.StartsWith(OutfitObjectPrefix, System.StringComparison.Ordinal))
                {
                    stale.Add(child.gameObject);
                }
            }

            foreach (GameObject go in stale)
            {
                Object.DestroyImmediate(go);
            }
        }

        // Rebuild the renderer's bone array (and rootBone) so it points at the body's skeleton
        // transforms of the same names — the standard modular-character bind.
        private static void RebindToBody(
            SkinnedMeshRenderer smr, Dictionary<string, Transform> boneMap, ref int matched, ref int missed)
        {
            Transform[] source = smr.bones;
            var rebound = new Transform[source.Length];
            for (int i = 0; i < source.Length; i++)
            {
                if (source[i] != null && boneMap.TryGetValue(source[i].name, out Transform mapped))
                {
                    rebound[i] = mapped;
                    matched++;
                }
                else
                {
                    missed++;
                }
            }

            smr.bones = rebound;

            if (smr.rootBone != null && boneMap.TryGetValue(smr.rootBone.name, out Transform root))
            {
                smr.rootBone = root;
            }
        }

        // Assign per slot by the embedded material's family: Ranger → hood, Regular → bare skin
        // (the Arms piece's hands), everything else (MI_Peasant) → the peasant cloth material.
        private static void AssignOutfitMaterials(
            SkinnedMeshRenderer smr, Material peasant, Material hood, Material skin)
        {
            Material[] source = smr.sharedMaterials;
            var mapped = new Material[source.Length];
            for (int i = 0; i < source.Length; i++)
            {
                string name = source[i] != null ? source[i].name : string.Empty;
                if (name.IndexOf("Ranger", System.StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    mapped[i] = hood;
                }
                else if (name.IndexOf("Regular", System.StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    mapped[i] = skin != null ? skin : peasant;
                }
                else
                {
                    mapped[i] = peasant;
                }
            }

            smr.sharedMaterials = mapped;
        }

        private static Material CreateOutfitMaterial(
            string materialPath, string materialName, string baseMapPath, string normalMapPath)
        {
            Directory.CreateDirectory(CharacterArtDir);

            Material material = AssetDatabase.LoadAssetAtPath<Material>(materialPath);
            if (material == null)
            {
                material = new Material(Shader.Find("Universal Render Pipeline/Lit")) { name = materialName };
                AssetDatabase.CreateAsset(material, materialPath);
            }

            material.SetColor(BaseColorId, Color.white);

            var baseMap = AssetDatabase.LoadAssetAtPath<Texture2D>(baseMapPath);
            if (baseMap != null)
            {
                material.SetTexture(BaseMapId, baseMap);
                material.SetTexture(MainTexId, baseMap);
            }
            else
            {
                Debug.LogWarning($"[Tarrock] Outfit base map missing at {baseMapPath}; {materialName} left untextured.");
            }

            if (EnsureNormalMap(normalMapPath) is { } normal)
            {
                material.SetTexture(BumpMapId, normal);
                material.EnableKeyword("_NORMALMAP");
            }

            EditorUtility.SetDirty(material);
            AssetDatabase.SaveAssets();
            return material;
        }

        // ---------------------------------------------------------------------------------
        // 3. Player visual swap (Cliff scene)
        // ---------------------------------------------------------------------------------

        private static bool SwapPlayerVisual()
        {
            if (!File.Exists(ScenePath))
            {
                Debug.LogError($"[Tarrock] Cliff scene missing at {ScenePath}; cannot swap the player visual.");
                return false;
            }

            UnityEngine.SceneManagement.Scene scene =
                EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);

            DeleteLineups(scene);

            GameObject playerRig = FindRoot(scene, PlayerRootName);
            if (playerRig == null)
            {
                Debug.LogError($"[Tarrock] '{PlayerRootName}' not found in the Cliff scene; run the player rig installer first.");
                return false;
            }

            // Delete the old Visual child (KayKit model + primitive Fool_* pieces) wholesale.
            Transform oldVisual = playerRig.transform.Find(VisualName);
            if (oldVisual != null)
            {
                Object.DestroyImmediate(oldVisual.gameObject);
            }

            var model = AssetDatabase.LoadAssetAtPath<GameObject>(BodyModelPath);
            if (model == null)
            {
                Debug.LogError($"[Tarrock] Body model absent at {BodyModelPath}; cannot build the new visual.");
                return false;
            }

            var visual = (GameObject)PrefabUtility.InstantiatePrefab(model);
            visual.name = VisualName;
            visual.transform.SetParent(playerRig.transform, false);
            visual.transform.localPosition = Vector3.zero; // feet at controller bottom
            visual.transform.localRotation = Quaternion.Euler(0f, ModelForwardYawFix, 0f); // model +X → rig +Z
            ScaleVisualToHeight(visual, TargetHeight);
            AttachOutfitPieces(visual);

            Animator animator = visual.GetComponent<Animator>();
            if (animator == null)
            {
                animator = visual.AddComponent<Animator>();
            }

            var controller = AssetDatabase.LoadAssetAtPath<RuntimeAnimatorController>(ControllerPath);
            if (controller != null)
            {
                animator.runtimeAnimatorController = controller;
            }
            else
            {
                Debug.LogWarning($"[Tarrock] FoolV2.controller absent at {ControllerPath}; the body will render but not animate.");
            }

            RewireAnimationDriver(playerRig, animator);

            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, ScenePath);
            AssetDatabase.SaveAssets();
            Debug.Log($"[Tarrock] Swapped PlayerRig/Visual to the Quaternius body and rewired PlayerAnimationDriver.");
            return true;
        }

        private static void DeleteLineups(UnityEngine.SceneManagement.Scene scene)
        {
            int deleted = 0;
            foreach (string name in LineupObjectNames)
            {
                GameObject root = FindRoot(scene, name);
                if (root != null)
                {
                    Object.DestroyImmediate(root);
                    deleted++;
                }
            }

            if (deleted > 0)
            {
                Debug.Log($"[Tarrock] Deleted {deleted} throwaway lineup object(s) from the Cliff scene.");
            }
        }

        private static void RewireAnimationDriver(GameObject playerRig, Animator animator)
        {
            var driver = playerRig.GetComponent<PlayerAnimationDriver>();
            if (driver == null)
            {
                driver = playerRig.AddComponent<PlayerAnimationDriver>();
                SetObjectReference(driver, "_motor", playerRig.GetComponent<PlayerMotor>());
                SetObjectReference(driver, "_dodge", playerRig.GetComponent<PlayerDodge>());
            }

            SetObjectReference(driver, "_animator", animator);
        }

        private static GameObject FindRoot(UnityEngine.SceneManagement.Scene scene, string name)
        {
            return scene.GetRootGameObjects().FirstOrDefault(go => go.name == name);
        }

        // Normalise the model to the target height from its combined renderer bounds, feet at origin.
        private static void ScaleVisualToHeight(GameObject visual, float targetHeight)
        {
            Renderer[] renderers = visual.GetComponentsInChildren<Renderer>();
            if (renderers.Length == 0)
            {
                return;
            }

            Bounds bounds = renderers[0].bounds;
            for (int i = 1; i < renderers.Length; i++)
            {
                bounds.Encapsulate(renderers[i].bounds);
            }

            float height = bounds.size.y;
            if (height <= 0.001f)
            {
                return;
            }

            float scale = targetHeight / height;
            if (Mathf.Abs(scale - 1f) > 0.02f)
            {
                visual.transform.localScale *= scale;
            }
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
