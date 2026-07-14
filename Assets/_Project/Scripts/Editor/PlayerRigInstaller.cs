namespace Tarrock.Editor
{

    using System.IO;
    using Tarrock.Player;
    using Tarrock.Regions;
    using Unity.Cinemachine;
    using UnityEditor;
    using UnityEditor.SceneManagement;
    using UnityEngine;
    using UnityEngine.InputSystem;

    /// <summary>
    /// Editor command that installs (and idempotently re-installs) the Fool's playable rig into
    /// the Cliff greybox scene: a <see cref="CharacterController"/>-driven "PlayerRig" carrying
    /// <see cref="PlayerMotor"/>/<see cref="PlayerDodge"/>/<see cref="PlayerInputReader"/> at the
    /// scene's <see cref="PlayerSpawnPoint"/>, plus a "CameraRig" with a Cinemachine 3.x
    /// third-person orbit camera driven by the Look action. Mirrors
    /// <see cref="CliffGreyboxGenerator"/>'s pattern — one public static entry point usable from
    /// the menu or headlessly via <c>-executeMethod</c>, safe to run repeatedly.
    /// </summary>
    public static class PlayerRigInstaller
    {
        private const string ScenePath = "Assets/_Project/Scenes/Regions/Cliff.unity";
        private const string InputAssetPath = "Assets/_Project/Input/TarrockActions.inputactions";
        private const string ArtDirectory = "Assets/_Project/Art/Greybox";
        private const string PlayerMaterialPath = ArtDirectory + "/Player.mat";

        // Vendored KayKit stand-in (StandInArtInstaller prepares these); absence falls back to the capsule.
        private const string CharacterModelPath = StandInArtInstaller.CharacterModelPath;
        private const string CharacterControllerPath = StandInArtInstaller.CharacterControllerPath;

        private const string PlayerRootName = "PlayerRig";
        private const string CameraRootName = "CameraRig";
        private const string MainCameraName = "Main Camera";
        private const string FollowCameraName = "PlayerFollowCamera";
        private const string PlayerTag = "Player";
        private const string MainCameraTag = "MainCamera";
        private const string LookActionName = "Look";

        // CharacterController capsule (combat.md: a humanoid Fool; greybox proportions).
        private const float ControllerHeight = 1.8f;
        private const float ControllerRadius = 0.35f;

        [MenuItem("Tarrock/Setup/Install Player Rig In Cliff Scene")]
        public static void Install()
        {
            if (!File.Exists(ScenePath))
            {
                Debug.LogError(
                    $"[Tarrock] Cannot install player rig: scene missing at {ScenePath}. " +
                    "Run \"Tarrock/Setup/Generate Cliff Greybox\" first.");
                return;
            }

            EnsurePlayerTag();

            AssetDatabase.ImportAsset(InputAssetPath, ImportAssetOptions.ForceUpdate);

            UnityEngine.SceneManagement.Scene scene =
                EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);

            RemoveExisting(scene);

            (Vector3 position, Quaternion rotation) = ResolveSpawn(scene);

            // Load the asset handles *after* opening the scene: a pending reimport queued above
            // can otherwise invalidate an earlier-loaded handle mid-open, serialising it as null.
            var inputAsset = AssetDatabase.LoadAssetAtPath<InputActionAsset>(InputAssetPath);
            if (inputAsset == null)
            {
                Debug.LogError($"[Tarrock] Cannot install player rig: input asset missing at {InputAssetPath}.");
                return;
            }

            InputActionReference lookReference = FindActionReference(InputAssetPath, LookActionName);

            GameObject playerRig = BuildPlayerRig(position, rotation, inputAsset);
            GameObject mainCamera = BuildCameraRig(playerRig.transform, lookReference);

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
                $"[Tarrock] Installed player rig into {ScenePath}: '{PlayerRootName}' at " +
                $"{position} (tag '{PlayerTag}') + '{CameraRootName}' third-person orbit camera" +
                (lookReference != null ? " (Look wired)." : " (Look reference NOT found — camera look inert)."));
        }

        // ---------------------------------------------------------------------------------
        // Player tag (the one sanctioned ProjectSettings write — LeapOfFaithTrigger needs it)
        // ---------------------------------------------------------------------------------

        private static void EnsurePlayerTag()
        {
            Object[] assets = AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset");
            if (assets == null || assets.Length == 0)
            {
                Debug.LogWarning("[Tarrock] Could not open TagManager.asset to ensure the 'Player' tag.");
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
                    return; // already present — idempotent
                }
            }

            tags.InsertArrayElementAtIndex(tags.arraySize);
            tags.GetArrayElementAtIndex(tags.arraySize - 1).stringValue = PlayerTag;
            tagManager.ApplyModifiedPropertiesWithoutUndo();
            Debug.Log("[Tarrock] Added missing 'Player' tag to the project's TagManager.");
        }

        // ---------------------------------------------------------------------------------
        // Idempotent teardown
        // ---------------------------------------------------------------------------------

        private static void RemoveExisting(UnityEngine.SceneManagement.Scene scene)
        {
            foreach (GameObject root in scene.GetRootGameObjects())
            {
                if (root.name == PlayerRootName || root.name == CameraRootName)
                {
                    Object.DestroyImmediate(root);
                }
            }

            // Defensive: strip any stray camera left in the greybox scene so the new rig's
            // camera is unambiguous (brief: "Remove/disable any pre-existing camera").
            foreach (Camera cam in Object.FindObjectsByType<Camera>(FindObjectsSortMode.None))
            {
                if (cam != null)
                {
                    Object.DestroyImmediate(cam.gameObject);
                }
            }
        }

        private const string SpawnNamePrefix = "PlayerSpawn";

        private static (Vector3, Quaternion) ResolveSpawn(UnityEngine.SceneManagement.Scene scene)
        {
            PlayerSpawnPoint[] spawns = Object.FindObjectsByType<PlayerSpawnPoint>(FindObjectsSortMode.None);
            Transform t = spawns.Length > 0 ? spawns[0].transform : FindSpawnByName(scene);

            if (t == null)
            {
                Debug.LogWarning(
                    "[Tarrock] No PlayerSpawnPoint found in the Cliff scene; placing PlayerRig at origin.");
                return (Vector3.zero, Quaternion.identity);
            }

            Vector3 forward = t.forward;
            forward.y = 0f;
            Quaternion facing = forward.sqrMagnitude > 0.0001f
                ? Quaternion.LookRotation(forward.normalized, Vector3.up)
                : t.rotation;
            return (t.position, facing);
        }

        // Fallback for headless batch loads, where a scene's pre-existing MonoBehaviour saved as
        // an inline MonoScript stub can fail to bind to its concrete type (so FindObjectsByType
        // misses it). The greybox spawn object is named with the SpawnNamePrefix.
        private static Transform FindSpawnByName(UnityEngine.SceneManagement.Scene scene)
        {
            foreach (GameObject root in scene.GetRootGameObjects())
            {
                foreach (Transform child in root.GetComponentsInChildren<Transform>(true))
                {
                    if (child.name.StartsWith(SpawnNamePrefix))
                    {
                        return child;
                    }
                }
            }

            return null;
        }

        // ---------------------------------------------------------------------------------
        // Player rig
        // ---------------------------------------------------------------------------------

        private static GameObject BuildPlayerRig(Vector3 position, Quaternion rotation, InputActionAsset inputAsset)
        {
            var playerRig = new GameObject(PlayerRootName)
            {
                tag = PlayerTag,
            };
            playerRig.transform.SetPositionAndRotation(position, rotation);

            var controller = playerRig.AddComponent<CharacterController>();
            controller.height = ControllerHeight;
            controller.radius = ControllerRadius;
            controller.center = new Vector3(0f, ControllerHeight * 0.5f, 0f);
            controller.stepOffset = 0.3f;

            Animator characterAnimator = BuildCharacterVisual(playerRig.transform);

            var inputReader = playerRig.AddComponent<PlayerInputReader>();
            PlayerDodge dodge = playerRig.AddComponent<PlayerDodge>();
            PlayerMotor motor = playerRig.AddComponent<PlayerMotor>();

            SetObjectReference(inputReader, "_actions", inputAsset);
            SetObjectReference(dodge, "_input", inputReader);
            SetObjectReference(motor, "_input", inputReader);
            SetObjectReference(motor, "_dodge", dodge);

            // Animation driver only when a real character (Animator) is present — the capsule
            // fallback has none, so we simply skip it and the rig stays valid.
            if (characterAnimator != null)
            {
                var animationDriver = playerRig.AddComponent<PlayerAnimationDriver>();
                SetObjectReference(animationDriver, "_animator", characterAnimator);
                SetObjectReference(animationDriver, "_motor", motor);
                SetObjectReference(animationDriver, "_dodge", dodge);
            }

            return playerRig;
        }

        /// <summary>
        /// Builds the "Visual" child. Prefers the vendored KayKit RogueHooded model (returning its
        /// <see cref="Animator"/> for the animation driver to consume); falls back to the primitive
        /// capsule (returning null) whenever Assets/ThirdParty is absent, so the installer never
        /// breaks on a checkout without the art.
        /// </summary>
        private static Animator BuildCharacterVisual(Transform parent)
        {
            var model = AssetDatabase.LoadAssetAtPath<GameObject>(CharacterModelPath);
            if (model == null)
            {
                Debug.LogWarning(
                    $"[Tarrock] Vendored character model absent at {CharacterModelPath}; " +
                    "using the capsule stand-in. Run \"Tarrock/Setup/Install Stand-In Art\" first.");
                BuildCapsuleVisual(parent);
                return null;
            }

            var visual = (GameObject)PrefabUtility.InstantiatePrefab(model);
            visual.name = "Visual";
            visual.transform.SetParent(parent, false);
            visual.transform.localPosition = Vector3.zero; // model origin at feet → controller bottom
            visual.transform.localRotation = Quaternion.identity; // faces +Z

            ScaleVisualToHeight(visual, ControllerHeight);

            Animator animator = visual.GetComponent<Animator>();
            if (animator == null)
            {
                animator = visual.AddComponent<Animator>();
            }

            var controller = AssetDatabase.LoadAssetAtPath<RuntimeAnimatorController>(CharacterControllerPath);
            if (controller != null)
            {
                animator.runtimeAnimatorController = controller;
            }
            else
            {
                Debug.LogWarning(
                    $"[Tarrock] Character AnimatorController absent at {CharacterControllerPath}; " +
                    "the character will render but not animate. Run \"Install Stand-In Art\".");
            }

            return animator;
        }

        // Normalise the model to the controller's height (KayKit rigs are ~1.8 units already, so
        // this is usually a no-op) using its combined renderer bounds, keeping feet at the origin.
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
            if (Mathf.Abs(scale - 1f) > 0.05f)
            {
                visual.transform.localScale *= scale;
            }
        }

        private static void BuildCapsuleVisual(Transform parent)
        {
            GameObject visual = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            visual.name = "Visual";

            // The CharacterController is the collider; the visual is cosmetic only.
            Object.DestroyImmediate(visual.GetComponent<Collider>());

            visual.transform.SetParent(parent, false);
            visual.transform.localPosition = new Vector3(0f, ControllerHeight * 0.5f, 0f);
            // Default capsule is 2m tall, radius 0.5m — scale to the controller's proportions.
            visual.transform.localScale = new Vector3(
                ControllerRadius / 0.5f, ControllerHeight / 2f, ControllerRadius / 0.5f);

            var renderer = visual.GetComponent<MeshRenderer>();
            if (renderer != null)
            {
                renderer.sharedMaterial = GetOrCreatePlayerMaterial();
            }
        }

        private static Material GetOrCreatePlayerMaterial()
        {
            var existing = AssetDatabase.LoadAssetAtPath<Material>(PlayerMaterialPath);
            if (existing != null)
            {
                return existing;
            }

            Directory.CreateDirectory(ArtDirectory);
            Shader shader = Shader.Find("Universal Render Pipeline/Lit");
            var material = new Material(shader) { name = "Player" };
            material.SetColor("_BaseColor", new Color(0.85f, 0.7f, 0.45f)); // warm greybox stand-in
            AssetDatabase.CreateAsset(material, PlayerMaterialPath);
            return material;
        }

        // ---------------------------------------------------------------------------------
        // Camera rig (Cinemachine 3.x)
        // ---------------------------------------------------------------------------------

        private static GameObject BuildCameraRig(Transform followTarget, InputActionReference lookReference)
        {
            var cameraRig = new GameObject(CameraRootName);

            // Unity Camera + CinemachineBrain + AudioListener + (URP camera data, added
            // reflectively so the Editor assembly need not depend on the URP assembly).
            var mainCameraGo = new GameObject(MainCameraName)
            {
                tag = MainCameraTag,
            };
            mainCameraGo.transform.SetParent(cameraRig.transform, false);
            var camera = mainCameraGo.AddComponent<Camera>();
            mainCameraGo.AddComponent<AudioListener>();
            mainCameraGo.AddComponent<CinemachineBrain>();
            AddUrpCameraData(mainCameraGo);
            camera.nearClipPlane = 0.1f;

            // Cinemachine virtual camera: third-person orbit that follows the player.
            var vcamGo = new GameObject(FollowCameraName);
            vcamGo.transform.SetParent(cameraRig.transform, false);
            var vcam = vcamGo.AddComponent<CinemachineCamera>();
            vcam.Follow = followTarget;
            vcam.LookAt = followTarget;

            var orbital = vcamGo.AddComponent<CinemachineOrbitalFollow>();
            orbital.TargetOffset = new Vector3(0f, 1.4f, 0f); // shoulder height on the greybox capsule
            orbital.Radius = 6f;

            // Position control alone never turns the camera toward the target (a CM3 camera
            // with no rotation-control behaviour keeps whatever rotation it starts with — the
            // player walks straight out of a frozen frame). The RotationComposer is what makes
            // this an actual third-person camera.
            vcamGo.AddComponent<CinemachineRotationComposer>();

            // Start both the vcam and the live camera at a sensible pose behind the player so
            // the first frame is already composed (no snap/glide-in from the rig's origin).
            Vector3 lookPoint = followTarget.position + new Vector3(0f, 1.4f, 0f);
            Vector3 startPos = lookPoint - (followTarget.forward * 6f) + (Vector3.up * 1.1f);
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

                // OrbitalFollow exposes "Look Orbit X" (pan), "Look Orbit Y" (tilt), and
                // "Orbit Scale" (radial). Bind Look to pan/tilt only; leave the radial unbound.
                if (controller.Name.Contains("Orbit X"))
                {
                    controller.Input.InputAction = lookReference;
                    controller.Input.Gain = 1f;
                }
                else if (controller.Name.Contains("Orbit Y"))
                {
                    controller.Input.InputAction = lookReference;
                    controller.Input.Gain = -1f; // invert tilt so pushing up looks up
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

        private static InputActionReference FindActionReference(string assetPath, string actionName)
        {
            InputActionReference hiddenMatch = null;
            var seen = new System.Collections.Generic.List<string>();

            foreach (Object asset in AssetDatabase.LoadAllAssetsAtPath(assetPath))
            {
                if (asset is not InputActionReference reference)
                {
                    continue;
                }

                InputAction action = reference.action;
                string resolvedName = action != null ? action.name : null;
                bool visible = (reference.hideFlags & HideFlags.HideInHierarchy) == 0;
                seen.Add($"{reference.name}(action={resolvedName ?? "<null>"},visible={visible})");

                // The importer names references by display name (e.g. "Player/Look"); match on the
                // resolved action name first, then fall back to the reference's own name.
                bool matches = resolvedName == actionName
                    || reference.name == actionName
                    || (reference.name != null &&
                        (reference.name.EndsWith("/" + actionName) || reference.name.EndsWith(":" + actionName)));
                if (!matches)
                {
                    continue;
                }

                if (visible)
                {
                    return reference;
                }

                hiddenMatch ??= reference;
            }

            if (hiddenMatch != null)
            {
                return hiddenMatch;
            }

            Debug.LogWarning(
                $"[Tarrock] Could not find an InputActionReference for '{actionName}' in {assetPath}; " +
                $"camera look will be inert. References present: [{string.Join(", ", seen)}]");
            return null;
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
