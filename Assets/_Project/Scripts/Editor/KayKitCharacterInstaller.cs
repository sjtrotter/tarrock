namespace Tarrock.Editor
{

    using System.Collections.Generic;
    using System.IO;
    using System.Linq;
    using Tarrock.Player;
    using Unity.Cinemachine;
    using UnityEditor;
    using UnityEditor.Animations;
    using UnityEditor.SceneManagement;
    using UnityEngine;
    using UnityEngine.InputSystem;

    /// <summary>
    /// Editor command that makes the Hexagon sandbox scene (<c>HexPrototype.unity</c>) playable with
    /// the KayKit Adventurers Rogue_Hooded stand-in and the KayKit Character Animations. Mirrors
    /// <see cref="QuaterniusCharacterInstaller"/> / <see cref="PlayerRigInstaller"/>: one idempotent,
    /// headless-runnable (<c>-executeMethod</c>) entry point. Five jobs:
    ///
    /// 1. <b>Import config</b> — Rogue_Hooded.fbx becomes a Generic rig with an avatar built from its
    ///    own skeleton; the KayKit animation FBXs (MovementBasic/MovementAdvanced/General) become
    ///    Generic and CopyFromOther that avatar so every clip binds to the one shared Rig_Medium
    ///    skeleton (bone hierarchies verified identical). Locomotion clips are loop-timed.
    /// 2. <b>Animator</b> — builds <c>RogueKayKit.controller</c>: an Idle→Jog→Sprint 1D blend tree on
    ///    the <c>Speed</c> float (default gait is a travel jog per the director's sandbox retune),
    ///    <c>Crouched</c>-gated CrouchMove/CrouchIdle states (the crouch-walk cycle; the idle is a
    ///    frozen frame of it — see the crouch-clip-role constants), and a <c>Dodge</c>-gated 4-way directional
    ///    dodge blend (Dodge_Forward/Backward/Left/Right on <c>DodgeX</c>/<c>DodgeY</c>), driven at
    ///    runtime by <c>Tarrock.Player.PlayerAnimationDriver</c> (the shared parameter contract).
    /// 3. <b>Player rig</b> — installs (idempotently) a CharacterController "PlayerRig" carrying
    ///    Motor/Dodge/Input/CursorLock + a Cinemachine third-person orbit "CameraRig", with Rogue_Hooded
    ///    at the diorama scale contract (0.30, matching the decorative seated figure), spawned near the
    ///    camp facing the funnel corridor (south).
    /// 4. <b>Colliders</b> — adds sharedMesh MeshColliders to the terrain and rampart geometry so the
    ///    player is contained (props under Deco / Secret_Placeholder are left walk-through for now).
    /// 5. <b>Set-dressing rename</b> — renames the decorative seated "Rogue" to "Rogue_Seated" so it is
    ///    never confused with the playable visual. That object is left otherwise untouched.
    ///
    /// The clip choice is an installer concern (art-audio.md §Current build, swap rule 4): gameplay
    /// addresses animation by logical state through the Animator, never by asset name.
    /// </summary>
    public static class KayKitCharacterInstaller
    {
        // -- Vendored KayKit assets -----------------------------------------------------------
        private const string CharactersDir = "Assets/ThirdParty/KayKit/Adventurers/Characters";
        public const string CharacterModelPath = CharactersDir + "/Rogue_Hooded.fbx";

        private const string AnimationDir = "Assets/ThirdParty/KayKit/Adventurers/Animations/Rig_Medium";
        private static readonly string[] AnimationLibraryPaths =
        {
            AnimationDir + "/Rig_Medium_MovementBasic.fbx",   // Walking_*, Running_*, Jump_*
            AnimationDir + "/Rig_Medium_MovementAdvanced.fbx", // Dodge_* (roll)
            AnimationDir + "/Rig_Medium_General.fbx",          // Idle_A/B, Interact, ...
        };

        private const string CharacterArtDir = "Assets/_Project/Art/Characters";
        public const string ControllerPath = CharacterArtDir + "/RogueKayKit.controller";

        private const string ScenePath = "Assets/_Project/Scenes/Sandbox/HexPrototype.unity";
        private const string InputAssetPath = "Assets/_Project/Input/TarrockActions.inputactions";

        // -- Scene object names ---------------------------------------------------------------
        private const string PlayerRootName = "PlayerRig";
        private const string CameraRootName = "CameraRig";
        private const string VisualName = "Visual";
        private const string MainCameraName = "Main Camera";
        private const string FollowCameraName = "PlayerFollowCamera";
        private const string IslandRootName = "HexIsland";
        private const string DecorativeRogueName = "Rogue";
        private const string DecorativeRogueRenamed = "Rogue_Seated";
        private const string PlayerTag = "Player";
        private const string MainCameraTag = "MainCamera";
        private const string LookActionName = "Look";

        // -- Animator parameters — kept in lockstep with Tarrock.Player.PlayerAnimationDriver.
        private const string SpeedParameter = "Speed";
        private const string DodgeParameter = "Dodge";
        private const string CrouchedParameter = "Crouched";
        private const string DodgeXParameter = "DodgeX";
        private const string DodgeYParameter = "DodgeY";

        // Blend thresholds map to PlayerMotor's jog (3.0) / sprint (4.8) / crouch (1.2) speeds so the
        // blend tracks the actual planar speed the driver feeds in (avoids the "gliding" mismatch).
        private const float JogThreshold = 3.0f;    // must track PlayerMotor._walkSpeed (default jog)
        private const float SprintThreshold = 4.8f; // must track PlayerMotor._sprintSpeed

        // KayKit locomotion cycles are authored for a leisurely full-size gait; crank the cadence so
        // the feet do not visibly lag the ground at the motor's speeds on the 0.30-scale miniature.
        // DIRECTOR-TUNABLE: foot-slide cannot be fully eliminated at this scale, only made to read well.
        private const float JogClipTimeScale = 1.3f;
        private const float SprintClipTimeScale = 1.5f;

        // -- Crouch clip roles (director round 4) ----------------------------------------------
        // KayKit ships NO true crouch-idle: both crouch clips are stepping cycles with the same
        // ~0.45m stride pattern (verified by sampling toe travel) — "Crouching" (1.07s) is the
        // livelier crouch-walk, "Sneaking" (2.13s) the same creep at half cadence. So crouch
        // MOVEMENT uses the livelier Crouching cycle, and crouch IDLE is a frozen frame of that
        // same cycle ("should just be a paused walking animation").
        private const string CrouchMoveClipName = "Crouching";
        private const float CrouchMoveClipTimeScale = 1.0f;

        // Normalized time of the frozen idle stance — forward toe planted, rear heel down; reads
        // as "holding still mid-sneak", not mid-step-teeter (verified by pose screenshots across
        // 0.10–0.25; the stance is stable throughout that window).
        private const float CrouchIdleFrozenNormalizedTime = 0.2f;

        // A/B toggle for the director: true = frozen-frame crouch idle (new); false = the
        // previous behavior (the crouch cycle playing while standing still — sneaking on the
        // spot). readonly, not const, so the compiler keeps both branches alive.
        private static readonly bool CrouchIdleFrozenWalk = true;

        // Speed split between the crouch idle and crouch move states (PlayerMotor's crouch speed
        // is 0.8; the damped Speed param crosses this quickly in both directions).
        private const float CrouchMoveSpeedThreshold = 0.3f;

        // PlayerDodge's movement window; the dodge clips are time-scaled to fit it.
        private const float DodgeMovementSeconds = 0.6f; // must track PlayerDodge._dodgeDuration

        // Locomotion clip families that must loop; dodges and one-shots stay as imported.
        private static readonly string[] LoopingFamilies = { "idle", "walk", "run", "strafe", "sneak", "crouch" };

        // -- Diorama scale contract (art-audio.md §Current build, swap rule 3): the playable Fool is
        // sized to the scene's decorative seated Rogue, 0.30. This is the director's in-scene choice.
        private const float VisualScale = 0.30f;

        // -- Spawn: open ground by the camp, facing the funnel corridor (south, −Z).
        private static readonly Vector3 SpawnPosition = new Vector3(10f, 0f, -9f);
        private static readonly Vector3 SpawnFacing = Vector3.back;

        // -- Camera feel (director round 3, item 4) — kept in lockstep with CliffHexGenerator so both
        // the sandbox and CliffHex share the same orbit rig: pivot at head (not chest), pulled back,
        // and a far wider vertical tilt so the Fool can look up into open sky / down onto himself.
        private const float CamPivotFactor = 0.92f;   // was 0.78 (chest) → ~head height
        private const float CamRadiusFactor = 3.3f;   // was 2.8 → ~18% further back
        // Full look-up: −12° grazes the camera just above the ground looking up past the Fool's head
        // (mostly sky). Lower puts the orbit under the floor; the deoccluder pull-in then fills the
        // frame with the Fool's back (play-tested in CliffHex at −26/−34).
        private const float CamVerticalMin = -12f;
        private const float CamVerticalMax = 70f;     // full look-down: the Fool seen from above
        private const float CamVerticalDefault = 16f; // resting tilt, a touch higher than the old 10

        // Set-dressing subtrees left walk-through for the playtest (containment is what matters; the
        // terrain + rampart carry it). Colliders are still cheap to add here later if the director asks.
        private static readonly string[] SkipColliderRoots = { "Deco", "Secret_Placeholder" };

        [MenuItem("Tarrock/Setup/Install KayKit Fool In Hex Scene")]
        public static void Install()
        {
            if (AssetImporter.GetAtPath(CharacterModelPath) is not ModelImporter)
            {
                Debug.LogError($"[Tarrock] KayKit Rogue_Hooded FBX not found at {CharacterModelPath}; aborting.");
                return;
            }

            EnsurePlayerTag();

            Avatar avatar = ConfigureCharacterModel();
            foreach (string path in AnimationLibraryPaths)
            {
                ConfigureAnimationLibrary(path, avatar);
            }

            bool animatorReady = BuildAnimatorController();
            if (!animatorReady)
            {
                Debug.LogError("[Tarrock] RogueKayKit.controller was not built; aborting scene install.");
                return;
            }

            InstallIntoScene();
        }

        // ---------------------------------------------------------------------------------
        // 1. Import configuration
        // ---------------------------------------------------------------------------------

        /// <summary>
        /// Configures Rogue_Hooded.fbx as a Generic rig with an avatar built from its own skeleton.
        /// The model imports already textured (URP/Lit "rogue" material), so materials are left alone.
        /// Returns the generated Avatar (null if none) for the animation FBXs to copy.
        /// </summary>
        private static Avatar ConfigureCharacterModel()
        {
            var importer = (ModelImporter)AssetImporter.GetAtPath(CharacterModelPath);
            importer.animationType = ModelImporterAnimationType.Generic;
            importer.avatarSetup = ModelImporterAvatarSetup.CreateFromThisModel;
            importer.importAnimation = true;
            importer.SaveAndReimport();

            Avatar avatar = AssetDatabase.LoadAllAssetsAtPath(CharacterModelPath).OfType<Avatar>().FirstOrDefault();
            Debug.Log(
                $"[Tarrock] {CharacterModelPath} configured (Generic). " +
                $"Avatar {(avatar != null ? "'" + avatar.name + "' valid=" + avatar.isValid : "MISSING")}.");
            return avatar;
        }

        /// <summary>
        /// Configures a KayKit animation FBX as Generic and — preferring CopyFromOther the Rogue's
        /// avatar so its clips bind to the one shared skeleton — reimports it, looping the locomotion
        /// clips. Falls back to CreateFromThisModel if the avatar is absent (path-based Generic
        /// bindings still play on the identical Rig_Medium skeleton either way).
        /// </summary>
        private static void ConfigureAnimationLibrary(string path, Avatar avatar)
        {
            if (AssetImporter.GetAtPath(path) is not ModelImporter importer)
            {
                Debug.LogWarning($"[Tarrock] Animation FBX not found at {path}; skipping.");
                return;
            }

            importer.animationType = ModelImporterAnimationType.Generic;
            importer.importAnimation = true;

            bool copied = false;
            if (avatar != null)
            {
                importer.avatarSetup = ModelImporterAvatarSetup.CopyFromOther;
                importer.sourceAvatar = avatar;
                copied = importer.sourceAvatar == avatar;
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
                $"avatar {(copied ? "CopyFromOther Rogue" : "CreateFromThisModel")}).");
        }

        /// <summary>
        /// FBX clips import with looping OFF, freezing at the end of a cycle. Loop every cyclic
        /// locomotion clip (idle/walk/run/strafe families); leave one-shots (dodge/jump/hit/death)
        /// as imported.
        /// </summary>
        private static void ConfigureClipLooping(ModelImporter importer)
        {
            ModelImporterClipAnimation[] clips = importer.clipAnimations is { Length: > 0 }
                ? importer.clipAnimations
                : importer.defaultClipAnimations;

            foreach (ModelImporterClipAnimation clip in clips)
            {
                string name = clip.name.ToLowerInvariant();
                if (name.Contains("dodge") || name.Contains("jump"))
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

        // ---------------------------------------------------------------------------------
        // 2. Animator controller (Idle→Jog→Sprint blend + crouch/sneak + 4-way directional dodge)
        // ---------------------------------------------------------------------------------

        private static bool BuildAnimatorController()
        {
            List<AnimationClip> clips = LoadLibraryClips();
            if (clips.Count == 0)
            {
                Debug.LogWarning("[Tarrock] No clips loaded from the KayKit animation FBXs; skipping controller.");
                return false;
            }

            AnimationClip idle = FindClip(clips, "Idle_A") ?? FindClip(clips, "Idle_B");
            // Default gait is a travel jog (director's sandbox retune); the always-walk gait is gone.
            AnimationClip jog = FindClip(clips, "Running_A") ?? FindClip(clips, "Running_B");
            // Sprint reads best as a distinct cycle; fall back to the jog clip (the higher
            // SprintClipTimeScale still differentiates it) when Running_B is absent.
            AnimationClip sprint = FindClip(clips, "Running_B") ?? jog;
            AnimationClip crouchWalk = FindClip(clips, CrouchMoveClipName);
            AnimationClip dodgeF = FindClip(clips, "Dodge_Forward");
            AnimationClip dodgeB = FindClip(clips, "Dodge_Backward");
            AnimationClip dodgeL = FindClip(clips, "Dodge_Left");
            AnimationClip dodgeR = FindClip(clips, "Dodge_Right");

            if (idle == null && jog == null)
            {
                Debug.LogWarning("[Tarrock] Could not resolve Idle/Jog clips; skipping controller.");
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
            controller.AddParameter(CrouchedParameter, AnimatorControllerParameterType.Bool);
            controller.AddParameter(DodgeXParameter, AnimatorControllerParameterType.Float);
            controller.AddParameter(DodgeYParameter, AnimatorControllerParameterType.Float);

            AnimatorStateMachine sm = controller.layers[0].stateMachine;

            // -- Standing locomotion: Idle → Jog (default gait) → Sprint ------------------------
            AnimatorState locomotion = controller.CreateBlendTreeInController("Locomotion", out BlendTree tree, 0);
            tree.blendType = BlendTreeType.Simple1D;
            tree.blendParameter = SpeedParameter;
            tree.useAutomaticThresholds = false;
            if (idle != null)
            {
                tree.AddChild(idle, 0f);
            }

            if (jog != null)
            {
                tree.AddChild(jog, JogThreshold);
            }

            if (sprint != null)
            {
                tree.AddChild(sprint, SprintThreshold);
            }

            ApplyLocomotionTimeScales(tree);
            sm.defaultState = locomotion;

            // -- Crouch: CrouchMove (the walk cycle) + CrouchIdle (frozen frame of the same) ----
            AnimatorState[] crouchStates = BuildCrouchStates(sm, locomotion, crouchWalk);

            // -- Dodge: 4-way directional blend on DodgeX/DodgeY, gated by the Dodge bool -------
            AnimatorState dodge = BuildDodgeState(sm, locomotion, crouchStates, dodgeF, dodgeB, dodgeL, dodgeR);

            EditorUtility.SetDirty(controller);
            AssetDatabase.SaveAssets();

            Debug.Log(
                $"[Tarrock] Built {ControllerPath}: locomotion [Idle={Name(idle)}, Jog={Name(jog)}@{JogThreshold}, " +
                $"Sprint={Name(sprint)}@{SprintThreshold}], crouch [move={Name(crouchWalk)}x{CrouchMoveClipTimeScale}, " +
                $"idle={(CrouchIdleFrozenWalk ? $"frozen@{CrouchIdleFrozenNormalizedTime}" : "cycle (old A/B)")}]" +
                $"{(crouchStates.Length > 0 ? string.Empty : " (SKIPPED)")}, dodge 4-way " +
                $"[F={Name(dodgeF)}, B={Name(dodgeB)}, L={Name(dodgeL)}, R={Name(dodgeR)}]" +
                $"{(dodge != null ? string.Empty : " (SKIPPED)")}.");
            return true;
        }

        // AddChild has no timeScale parameter; child motions must be rewritten after the fact. The
        // jog child gets JogClipTimeScale and the sprint child SprintClipTimeScale (matched by
        // threshold, not clip identity, because jog and sprint may share a clip).
        private static void ApplyLocomotionTimeScales(BlendTree tree)
        {
            ChildMotion[] children = tree.children;
            for (int i = 0; i < children.Length; i++)
            {
                if (Mathf.Approximately(children[i].threshold, JogThreshold))
                {
                    children[i].timeScale = JogClipTimeScale;
                }
                else if (Mathf.Approximately(children[i].threshold, SprintThreshold))
                {
                    children[i].timeScale = SprintClipTimeScale;
                }
            }

            tree.children = children;
        }

        /// <summary>
        /// Adds the two crouch states, both driven by the SAME crouch-walk cycle (the pack has no
        /// true crouch-idle — see the crouch-clip-role constants):
        ///
        /// - <b>CrouchMove</b> — the cycle playing at <see cref="CrouchMoveClipTimeScale"/>;
        /// - <b>CrouchIdle</b> — the cycle FROZEN (state speed 0) at
        ///   <see cref="CrouchIdleFrozenNormalizedTime"/>, entered via transition offset, so
        ///   standing still holds a stable mid-sneak stance instead of sneaking on the spot.
        ///   Flip <see cref="CrouchIdleFrozenWalk"/> to A/B the old playing-cycle idle.
        ///
        /// The two are split on the damped Speed param at <see cref="CrouchMoveSpeedThreshold"/>;
        /// both enter from and exit to standing locomotion on the Crouched bool. Returns the
        /// states (empty if the clip is missing) so the dodge state can wire its own entries.
        /// </summary>
        private static AnimatorState[] BuildCrouchStates(
            AnimatorStateMachine sm, AnimatorState locomotion, AnimationClip crouchWalk)
        {
            if (crouchWalk == null)
            {
                Debug.LogWarning($"[Tarrock] '{CrouchMoveClipName}' clip missing; crouch states skipped.");
                return new AnimatorState[0];
            }

            AnimatorState move = sm.AddState("CrouchMove");
            move.motion = crouchWalk;
            move.speed = CrouchMoveClipTimeScale;

            AnimatorState idle = sm.AddState("CrouchIdle");
            idle.motion = crouchWalk;
            idle.speed = CrouchIdleFrozenWalk ? 0f : 1f;
            float idleEntryOffset = CrouchIdleFrozenWalk ? CrouchIdleFrozenNormalizedTime : 0f;

            // Standing locomotion → crouch, split by current Speed.
            AnimatorStateTransition standToIdle = locomotion.AddTransition(idle);
            standToIdle.hasExitTime = false;
            standToIdle.duration = 0.15f;
            standToIdle.offset = idleEntryOffset;
            standToIdle.AddCondition(AnimatorConditionMode.If, 0f, CrouchedParameter);
            standToIdle.AddCondition(AnimatorConditionMode.Less, CrouchMoveSpeedThreshold, SpeedParameter);

            AnimatorStateTransition standToMove = locomotion.AddTransition(move);
            standToMove.hasExitTime = false;
            standToMove.duration = 0.15f;
            standToMove.AddCondition(AnimatorConditionMode.If, 0f, CrouchedParameter);
            standToMove.AddCondition(AnimatorConditionMode.Greater, CrouchMoveSpeedThreshold, SpeedParameter);

            // Idle ↔ move while crouched.
            AnimatorStateTransition idleToMove = idle.AddTransition(move);
            idleToMove.hasExitTime = false;
            idleToMove.duration = 0.15f;
            idleToMove.AddCondition(AnimatorConditionMode.Greater, CrouchMoveSpeedThreshold, SpeedParameter);

            AnimatorStateTransition moveToIdle = move.AddTransition(idle);
            moveToIdle.hasExitTime = false;
            moveToIdle.duration = 0.15f;
            moveToIdle.offset = idleEntryOffset;
            moveToIdle.AddCondition(AnimatorConditionMode.Less, CrouchMoveSpeedThreshold, SpeedParameter);

            // Crouch → standing on un-crouch.
            AnimatorStateTransition idleToStand = idle.AddTransition(locomotion);
            idleToStand.hasExitTime = false;
            idleToStand.duration = 0.15f;
            idleToStand.AddCondition(AnimatorConditionMode.IfNot, 0f, CrouchedParameter);

            AnimatorStateTransition moveToStand = move.AddTransition(locomotion);
            moveToStand.hasExitTime = false;
            moveToStand.duration = 0.15f;
            moveToStand.AddCondition(AnimatorConditionMode.IfNot, 0f, CrouchedParameter);

            return new[] { idle, move };
        }

        /// <summary>
        /// Adds the directional dodge state — a 2D simple-directional blend of the four Dodge_*
        /// clips on DodgeX/DodgeY (the roll direction in character-local space, latched at dodge
        /// start by <c>PlayerAnimationDriver</c>) — entered from standing or crouched locomotion
        /// on the Dodge bool and exiting to standing (a dodge always stands the Fool up). The
        /// state is time-scaled to the dodge's movement window. Returns null if no dodge clip
        /// exists.
        /// </summary>
        private static AnimatorState BuildDodgeState(
            AnimatorStateMachine sm, AnimatorState locomotion, AnimatorState[] crouchStates,
            AnimationClip dodgeF, AnimationClip dodgeB, AnimationClip dodgeL, AnimationClip dodgeR)
        {
            AnimationClip reference = dodgeF ?? dodgeB ?? dodgeL ?? dodgeR;
            if (reference == null)
            {
                Debug.LogWarning("[Tarrock] No Dodge_* clips found; dodge state skipped.");
                return null;
            }

            AnimatorState dodge = sm.AddState("Dodge");
            var tree = new BlendTree
            {
                name = "DodgeDirectional",
                blendType = BlendTreeType.SimpleDirectional2D,
                blendParameter = DodgeXParameter,
                blendParameterY = DodgeYParameter,
                hideFlags = HideFlags.HideInHierarchy,
            };
            AssetDatabase.AddObjectToAsset(tree, AssetDatabase.GetAssetPath(sm));

            if (dodgeF != null)
            {
                tree.AddChild(dodgeF, new Vector2(0f, 1f));
            }

            if (dodgeB != null)
            {
                tree.AddChild(dodgeB, new Vector2(0f, -1f));
            }

            if (dodgeL != null)
            {
                tree.AddChild(dodgeL, new Vector2(-1f, 0f));
            }

            if (dodgeR != null)
            {
                tree.AddChild(dodgeR, new Vector2(1f, 0f));
            }

            dodge.motion = tree;

            // Fit the dodge into the movement window; never slow below authored speed (an
            // under-cranked dodge reads floaty). Snappier is the safer error.
            if (reference.length > 0.01f)
            {
                dodge.speed = Mathf.Clamp(reference.length / DodgeMovementSeconds, 0.9f, 1.4f);
            }

            AnimatorStateTransition toDodge = locomotion.AddTransition(dodge);
            toDodge.hasExitTime = false;
            toDodge.duration = 0.05f;
            toDodge.AddCondition(AnimatorConditionMode.If, 0f, DodgeParameter);

            foreach (AnimatorState crouchState in crouchStates)
            {
                AnimatorStateTransition crouchToDodge = crouchState.AddTransition(dodge);
                crouchToDodge.hasExitTime = false;
                crouchToDodge.duration = 0.05f;
                crouchToDodge.AddCondition(AnimatorConditionMode.If, 0f, DodgeParameter);
            }

            // A dodge exits crouch (PlayerMotor stands the Fool up), so always return to standing.
            AnimatorStateTransition fromDodge = dodge.AddTransition(locomotion);
            fromDodge.hasExitTime = false;
            fromDodge.duration = 0.1f;
            fromDodge.AddCondition(AnimatorConditionMode.IfNot, 0f, DodgeParameter);

            return dodge;
        }

        private static List<AnimationClip> LoadLibraryClips()
        {
            var clips = new List<AnimationClip>();
            foreach (string path in AnimationLibraryPaths)
            {
                clips.AddRange(AssetDatabase.LoadAllAssetsAtPath(path)
                    .OfType<AnimationClip>()
                    .Where(c => !c.name.StartsWith("__preview__")));
            }

            return clips;
        }

        private static AnimationClip FindClip(IEnumerable<AnimationClip> clips, string name)
        {
            return clips.FirstOrDefault(c => string.Equals(c.name, name, System.StringComparison.OrdinalIgnoreCase));
        }

        private static string Name(AnimationClip clip)
        {
            return clip != null ? clip.name : "-";
        }

        // ---------------------------------------------------------------------------------
        // 3. Scene install (rig + camera + colliders + set-dressing rename)
        // ---------------------------------------------------------------------------------

        private static void InstallIntoScene()
        {
            if (!File.Exists(ScenePath))
            {
                Debug.LogError($"[Tarrock] Sandbox scene missing at {ScenePath}; cannot install the rig.");
                return;
            }

            // Operate on the already-open scene when possible (avoids a reload); else open it.
            UnityEngine.SceneManagement.Scene scene = EditorSceneManager.GetActiveScene();
            if (scene.path != ScenePath)
            {
                scene = EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
            }

            RenameDecorativeRogue(scene);
            RemoveExisting(scene);

            int colliders = AddTerrainColliders(scene);
            Physics.SyncTransforms();

            var inputAsset = AssetDatabase.LoadAssetAtPath<InputActionAsset>(InputAssetPath);
            if (inputAsset == null)
            {
                Debug.LogError($"[Tarrock] Input asset missing at {InputAssetPath}; cannot install the rig.");
                return;
            }

            InputActionReference lookReference = FindActionReference(InputAssetPath, LookActionName);

            Vector3 spawn = ResolveGroundedSpawn();
            Quaternion facing = Quaternion.LookRotation(SpawnFacing, Vector3.up);

            GameObject playerRig = BuildPlayerRig(spawn, facing, inputAsset, out float visualHeight);
            GameObject mainCamera = BuildCameraRig(playerRig.transform, lookReference, visualHeight);

            // Match the live camera to the vcam's start pose so play mode opens composed.
            Transform vcamTransform = mainCamera.transform.parent.Find(FollowCameraName);
            if (vcamTransform != null)
            {
                mainCamera.transform.SetPositionAndRotation(vcamTransform.position, vcamTransform.rotation);
            }

            WireCameraTransform(playerRig, mainCamera.transform);

            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene, ScenePath);
            AssetDatabase.SaveAssets();

            Debug.Log(
                $"[Tarrock] KayKit Fool installed into {ScenePath}: '{PlayerRootName}' at {spawn} " +
                $"(height {visualHeight:F2}m, scale {VisualScale}) + '{CameraRootName}' orbit camera, " +
                $"{colliders} terrain/rampart collider(s)" +
                (lookReference != null ? ", Look wired." : ", Look reference NOT found (camera look inert)."));
        }

        // The decorative seated Rogue is set dressing (art-audio.md diorama). Rename it so it is never
        // mistaken for the playable visual; leave it otherwise untouched.
        private static void RenameDecorativeRogue(UnityEngine.SceneManagement.Scene scene)
        {
            GameObject seated = FindRoot(scene, DecorativeRogueName);
            if (seated != null && seated.transform.Find(VisualName) == null) // not a PlayerRig
            {
                seated.name = DecorativeRogueRenamed;
                EditorUtility.SetDirty(seated);
                Debug.Log($"[Tarrock] Renamed decorative '{DecorativeRogueName}' to '{DecorativeRogueRenamed}'.");
            }
        }

        private static void RemoveExisting(UnityEngine.SceneManagement.Scene scene)
        {
            foreach (GameObject root in scene.GetRootGameObjects())
            {
                if (root.name == PlayerRootName || root.name == CameraRootName)
                {
                    Object.DestroyImmediate(root);
                }
            }

            // Strip any stray camera so the new rig's camera is unambiguous (one AudioListener).
            foreach (Camera cam in Object.FindObjectsByType<Camera>(FindObjectsSortMode.None))
            {
                if (cam != null)
                {
                    Object.DestroyImmediate(cam.gameObject);
                }
            }
        }

        // ---------------------------------------------------------------------------------
        // 3a. Colliders — sharedMesh MeshColliders on terrain + rampart (props left walk-through)
        // ---------------------------------------------------------------------------------

        private static int AddTerrainColliders(UnityEngine.SceneManagement.Scene scene)
        {
            GameObject island = FindRoot(scene, IslandRootName);
            if (island == null)
            {
                Debug.LogWarning($"[Tarrock] '{IslandRootName}' not found; no terrain colliders added.");
                return 0;
            }

            int added = 0;
            foreach (MeshFilter mf in island.GetComponentsInChildren<MeshFilter>(true))
            {
                if (mf.sharedMesh == null || IsUnderSkipRoot(mf.transform, island.transform))
                {
                    continue;
                }

                if (mf.GetComponent<MeshCollider>() != null)
                {
                    continue; // idempotent re-run
                }

                var collider = mf.gameObject.AddComponent<MeshCollider>();
                collider.sharedMesh = mf.sharedMesh; // non-convex static ground/wall
                added++;
            }

            Debug.Log($"[Tarrock] Added {added} MeshCollider(s) to terrain/rampart under '{IslandRootName}'.");
            return added;
        }

        private static bool IsUnderSkipRoot(Transform t, Transform islandRoot)
        {
            for (Transform c = t; c != null && c != islandRoot; c = c.parent)
            {
                if (SkipColliderRoots.Contains(c.name))
                {
                    return true;
                }
            }

            return false;
        }

        // ---------------------------------------------------------------------------------
        // 3b. Player rig
        // ---------------------------------------------------------------------------------

        private static GameObject BuildPlayerRig(
            Vector3 position, Quaternion rotation, InputActionAsset inputAsset, out float visualHeight)
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

            var animationDriver = playerRig.AddComponent<PlayerAnimationDriver>();
            SetObjectReference(animationDriver, "_animator", animator);
            SetObjectReference(animationDriver, "_motor", motor);
            SetObjectReference(animationDriver, "_dodge", dodge);

            return playerRig;
        }

        /// <summary>
        /// Builds the "Visual" child from Rogue_Hooded at the diorama scale (0.30), facing +Z (KayKit
        /// authors the model facing +Z, matching PlayerMotor's forward), wires the RogueKayKit
        /// controller, and disables the weapon attachment props. Returns the Animator and the visual's
        /// measured world height so the caller can size the CharacterController + camera to it.
        /// </summary>
        private static Animator BuildCharacterVisual(Transform parent, out float visualHeight)
        {
            var model = AssetDatabase.LoadAssetAtPath<GameObject>(CharacterModelPath);
            var visual = (GameObject)PrefabUtility.InstantiatePrefab(model);
            visual.name = VisualName;
            visual.transform.SetParent(parent, false);
            visual.transform.localPosition = Vector3.zero; // model origin at feet → controller bottom
            visual.transform.localRotation = Quaternion.identity; // KayKit faces +Z
            visual.transform.localScale = Vector3.one * VisualScale;

            DisableAttachmentProps(visual);
            visualHeight = MeasureHeight(visual);

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
                Debug.LogWarning($"[Tarrock] {ControllerPath} absent; the body will render but not animate.");
            }

            return animator;
        }

        // KayKit character FBXs ship weapon/prop meshes parented to the hand slots, all visible by
        // default. The Fool carries the Bindle, not an armory: disable every renderer under a hand slot.
        private static void DisableAttachmentProps(GameObject visual)
        {
            int disabled = 0;
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
                        disabled++;
                    }
                }
            }

            if (disabled > 0)
            {
                Debug.Log($"[Tarrock] Disabled {disabled} weapon attachment prop(s) on the visual.");
            }
        }

        private static float MeasureHeight(GameObject visual)
        {
            Renderer[] renderers = visual.GetComponentsInChildren<Renderer>();
            if (renderers.Length == 0)
            {
                return VisualScale; // degenerate fallback
            }

            Bounds bounds = renderers[0].bounds;
            for (int i = 1; i < renderers.Length; i++)
            {
                bounds.Encapsulate(renderers[i].bounds);
            }

            return Mathf.Max(0.1f, bounds.size.y);
        }

        // Raycast down onto the freshly added terrain colliders so the rig's feet land on the ground.
        private static Vector3 ResolveGroundedSpawn()
        {
            var origin = new Vector3(SpawnPosition.x, SpawnPosition.y + 20f, SpawnPosition.z);
            if (Physics.Raycast(origin, Vector3.down, out RaycastHit hit, 60f))
            {
                return new Vector3(SpawnPosition.x, hit.point.y + 0.02f, SpawnPosition.z);
            }

            Debug.LogWarning("[Tarrock] Spawn ground raycast missed; using y=0.05 fallback.");
            return new Vector3(SpawnPosition.x, 0.05f, SpawnPosition.z);
        }

        // ---------------------------------------------------------------------------------
        // 3c. Camera rig (Cinemachine 3.x) — offsets scaled to the diorama-sized player
        // ---------------------------------------------------------------------------------

        // Feel ratios lifted from PlayerRigInstaller's playtest-tuned human rig (offset ≈ 0.78×height,
        // radius ≈ 2.8×height) and applied to this scene's ~0.70m player so framing matches.
        private static GameObject BuildCameraRig(
            Transform followTarget, InputActionReference lookReference, float playerHeight)
        {
            var cameraRig = new GameObject(CameraRootName);

            var mainCameraGo = new GameObject(MainCameraName) { tag = MainCameraTag };
            mainCameraGo.transform.SetParent(cameraRig.transform, false);
            var camera = mainCameraGo.AddComponent<Camera>();
            mainCameraGo.AddComponent<AudioListener>();
            mainCameraGo.AddComponent<CinemachineBrain>();
            AddUrpCameraData(mainCameraGo);
            camera.nearClipPlane = 0.05f; // small player → let the camera get close

            float pivotHeight = playerHeight * CamPivotFactor;
            float orbitRadius = playerHeight * CamRadiusFactor;

            var vcamGo = new GameObject(FollowCameraName);
            vcamGo.transform.SetParent(cameraRig.transform, false);
            var vcam = vcamGo.AddComponent<CinemachineCamera>();
            vcam.Follow = followTarget;
            vcam.LookAt = followTarget;
            vcam.Lens.FieldOfView = 55f;

            var orbital = vcamGo.AddComponent<CinemachineOrbitalFollow>();
            orbital.TargetOffset = new Vector3(0f, pivotHeight, 0f);
            orbital.Radius = orbitRadius;
            orbital.HorizontalAxis.Wrap = true;
            // OrbitalFollow's horizontal axis is world-locked: value 0 seats the camera on the world
            // −Z side. The Fool spawns facing −Z (the corridor), so 180° puts the camera on the +Z
            // side — behind the player, looking down the corridor (W then drives forward, not backward).
            orbital.HorizontalAxis.Value = 180f;
            orbital.HorizontalAxis.Center = 180f;
            orbital.VerticalAxis.Value = CamVerticalDefault;
            orbital.VerticalAxis.Center = CamVerticalDefault;
            orbital.VerticalAxis.Range = new Vector2(CamVerticalMin, CamVerticalMax);

            vcamGo.AddComponent<CinemachineRotationComposer>();

            // The wide tilt range (CamVerticalMin) can sweep the camera toward the ground; the
            // deoccluder nudges it out of geometry instead of letting it clip under the terrain.
            var deoccluder = vcamGo.AddComponent<CinemachineDeoccluder>();
            deoccluder.CollideAgainst = 1; // Default layer: terrain + rampart colliders
            deoccluder.IgnoreTag = PlayerTag;
            deoccluder.AvoidObstacles.Enabled = true;
            deoccluder.AvoidObstacles.CameraRadius = 0.1f;
            deoccluder.AvoidObstacles.DistanceLimit = orbitRadius;
            // Slide around obstacles at range rather than zooming into the Fool's back.
            deoccluder.AvoidObstacles.Strategy =
                CinemachineDeoccluder.ObstacleAvoidance.ResolutionStrategy.PreserveCameraDistance;

            // Start behind the player so the first frame is composed (no glide-in).
            Vector3 lookPoint = followTarget.position + new Vector3(0f, pivotHeight, 0f);
            Vector3 startPos = lookPoint - (followTarget.forward * orbitRadius) + (Vector3.up * playerHeight * 0.6f);
            Quaternion startRot = Quaternion.LookRotation(lookPoint - startPos, Vector3.up);
            vcamGo.transform.SetPositionAndRotation(startPos, startRot);

            var axisController = vcamGo.AddComponent<CinemachineInputAxisController>();
            axisController.ScanRecursively = true;
            axisController.SynchronizeControllers();
            WireLookAxes(axisController, lookReference);

            return mainCameraGo;
        }

        private static void AddUrpCameraData(GameObject cameraGo)
        {
            System.Type urpDataType = System.Type.GetType(
                "UnityEngine.Rendering.Universal.UniversalAdditionalCameraData, Unity.RenderPipelines.Universal.Runtime");
            if (urpDataType != null && cameraGo.GetComponent(urpDataType) == null)
            {
                cameraGo.AddComponent(urpDataType);
            }
        }

        private static void WireLookAxes(CinemachineInputAxisController axisController, InputActionReference lookReference)
        {
            if (lookReference == null)
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
                    controller.Input.InputAction = lookReference;
                    controller.Input.Gain = 4f;
                }
                else if (controller.Name.Contains("Orbit Y"))
                {
                    controller.Input.InputAction = lookReference;
                    controller.Input.Gain = -2.5f;
                }
            }
        }

        private static void WireCameraTransform(GameObject playerRig, Transform cameraTransform)
        {
            SetObjectReference(playerRig.GetComponent<PlayerMotor>(), "_cameraTransform", cameraTransform);
            SetObjectReference(playerRig.GetComponent<PlayerDodge>(), "_cameraTransform", cameraTransform);
        }

        // ---------------------------------------------------------------------------------
        // Shared helpers
        // ---------------------------------------------------------------------------------

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

        private static GameObject FindRoot(UnityEngine.SceneManagement.Scene scene, string name)
        {
            return scene.GetRootGameObjects().FirstOrDefault(go => go.name == name);
        }

        private static InputActionReference FindActionReference(string assetPath, string actionName)
        {
            InputActionReference hiddenMatch = null;
            foreach (Object asset in AssetDatabase.LoadAllAssetsAtPath(assetPath))
            {
                if (asset is not InputActionReference reference)
                {
                    continue;
                }

                InputAction action = reference.action;
                string resolvedName = action != null ? action.name : null;
                bool matches = resolvedName == actionName
                    || reference.name == actionName
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

                hiddenMatch ??= reference;
            }

            if (hiddenMatch == null)
            {
                Debug.LogWarning($"[Tarrock] No InputActionReference for '{actionName}' in {assetPath}; camera look inert.");
            }

            return hiddenMatch;
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
