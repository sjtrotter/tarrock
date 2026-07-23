namespace Tarrock.Editor
{

    using System.IO;
    using System.Linq;
    using Tarrock.Companion;
    using Tarrock.Player;
    using UnityEditor;
    using UnityEditor.SceneManagement;
    using UnityEngine;

    /// <summary>
    /// Editor command that installs (and idempotently re-installs) Pip — the Fool's white dog
    /// companion (characters.md §Pip) — into the currently open scene, beside the player rig.
    /// Mirrors <see cref="PlayerRigInstaller"/> / <see cref="KayKitCharacterInstaller"/>: one
    /// idempotent static entry point on the "Tarrock/Setup" menu, safe to run repeatedly.
    ///
    /// It builds a small <see cref="CharacterController"/> "Pip" carrying <see cref="PipController"/>
    /// (wired to the player transform) and <see cref="PipAnimatorLink"/>, plus a PLACEHOLDER visual
    /// (two spheres + a capsule, plain white — art-audio.md §Current build). The real Quaternius
    /// Shiba model swaps in later through this same pattern; nothing here names a clip, per the
    /// animation contract (art-audio.md rule 4).
    /// </summary>
    public static class PipInstaller
    {
        private const string PipRootName = "Pip";
        private const string PlayerRootName = "PlayerRig";
        private const string VisualName = "Visual";

        // Small dog on the 0.7 m game-piece miniature (art-audio.md scale contract).
        private const float ControllerHeight = 0.35f;
        private const float ControllerRadius = 0.18f;
        private const float SideOffset = 0.5f; // spawn beside the Fool, not inside him

        private const string MaterialDir = "Assets/_Project/Materials";
        private const string PipMaterialPath = MaterialDir + "/PipWhite.mat";

        [MenuItem("Tarrock/Setup/Install Pip Beside Player")]
        public static void Install()
        {
            UnityEngine.SceneManagement.Scene scene = EditorSceneManager.GetActiveScene();

            Transform player = ResolvePlayer(scene);
            if (player == null)
            {
                Debug.LogError(
                    "[Tarrock] Cannot install Pip: no player found in the open scene (looked for a " +
                    $"'{PlayerRootName}' root or a PlayerMotor). Install the player rig first.");
                return;
            }

            RemoveExisting(scene);

            GameObject pip = BuildPip(player);

            EditorSceneManager.MarkSceneDirty(scene);
            if (!string.IsNullOrEmpty(scene.path))
            {
                EditorSceneManager.SaveScene(scene);
            }

            AssetDatabase.SaveAssets();
            Selection.activeGameObject = pip;

            Debug.Log(
                $"[Tarrock] Installed '{PipRootName}' beside '{player.name}' at {pip.transform.position} " +
                "(placeholder white visual; PipController wired to the player, PipAnimatorLink attached).");
        }

        [MenuItem("Tarrock/Setup/Select Pip")]
        public static void SelectPip()
        {
            GameObject pip = FindRoot(EditorSceneManager.GetActiveScene(), PipRootName);
            if (pip == null)
            {
                Debug.LogWarning($"[Tarrock] No '{PipRootName}' found in the open scene.");
                return;
            }

            Selection.activeGameObject = pip;
            EditorGUIUtility.PingObject(pip);
        }

        // ---------------------------------------------------------------------------------

        private static Transform ResolvePlayer(UnityEngine.SceneManagement.Scene scene)
        {
            GameObject rig = FindRoot(scene, PlayerRootName);
            if (rig != null)
            {
                return rig.transform;
            }

            // Fallback: the player rig root carrying the motor, whatever it is named.
            PlayerMotor motor = Object.FindFirstObjectByType<PlayerMotor>();
            return motor != null ? motor.transform : null;
        }

        private static void RemoveExisting(UnityEngine.SceneManagement.Scene scene)
        {
            foreach (GameObject root in scene.GetRootGameObjects())
            {
                if (root.name == PipRootName)
                {
                    Object.DestroyImmediate(root);
                }
            }
        }

        private static GameObject BuildPip(Transform player)
        {
            Vector3 side = player.right;
            side.y = 0f;
            side = side.sqrMagnitude > 0.0001f ? side.normalized : Vector3.right;
            Vector3 position = player.position + (side * SideOffset);

            var pip = new GameObject(PipRootName);
            pip.transform.SetPositionAndRotation(position, player.rotation);

            var controller = pip.AddComponent<CharacterController>();
            controller.height = ControllerHeight;
            controller.radius = ControllerRadius;
            controller.center = new Vector3(0f, ControllerHeight * 0.5f, 0f);
            controller.stepOffset = 0.15f;

            BuildPlaceholderVisual(pip.transform);

            var pipController = pip.AddComponent<PipController>();
            var animatorLink = pip.AddComponent<PipAnimatorLink>();

            SetObjectReference(pipController, "_followTarget", player);
            SetObjectReference(animatorLink, "_controller", pipController);

            return pip;
        }

        // Placeholder body: a capsule trunk plus a head sphere and a hindquarters sphere, all plain
        // white. Cosmetic only (the CharacterController is the collider), so every primitive collider
        // is stripped. Swapped for the Quaternius Shiba model later via this same installer pattern.
        private static void BuildPlaceholderVisual(Transform parent)
        {
            var visual = new GameObject(VisualName);
            visual.transform.SetParent(parent, false);
            visual.transform.localPosition = Vector3.zero;

            Material white = GetOrCreatePipMaterial();

            // Trunk: a capsule laid along the body's forward (Z) axis.
            GameObject trunk = MakePrimitive(PrimitiveType.Capsule, visual.transform, white);
            trunk.name = "Trunk";
            trunk.transform.localRotation = Quaternion.Euler(90f, 0f, 0f); // long axis Y → Z
            trunk.transform.localScale = new Vector3(0.24f, 0.2f, 0.24f);   // ~0.12 r, ~0.4 long
            trunk.transform.localPosition = new Vector3(0f, ControllerHeight * 0.5f, 0f);

            // Head sphere at the front.
            GameObject head = MakePrimitive(PrimitiveType.Sphere, visual.transform, white);
            head.name = "Head";
            head.transform.localScale = Vector3.one * 0.18f;
            head.transform.localPosition = new Vector3(0f, ControllerHeight * 0.62f, 0.22f);

            // Hindquarters sphere at the rear.
            GameObject rear = MakePrimitive(PrimitiveType.Sphere, visual.transform, white);
            rear.name = "Hindquarters";
            rear.transform.localScale = Vector3.one * 0.16f;
            rear.transform.localPosition = new Vector3(0f, ControllerHeight * 0.5f, -0.2f);
        }

        private static GameObject MakePrimitive(PrimitiveType type, Transform parent, Material material)
        {
            GameObject go = GameObject.CreatePrimitive(type);

            Collider collider = go.GetComponent<Collider>();
            if (collider != null)
            {
                Object.DestroyImmediate(collider);
            }

            go.transform.SetParent(parent, false);

            var renderer = go.GetComponent<MeshRenderer>();
            if (renderer != null)
            {
                renderer.sharedMaterial = material;
            }

            return go;
        }

        private static Material GetOrCreatePipMaterial()
        {
            var existing = AssetDatabase.LoadAssetAtPath<Material>(PipMaterialPath);
            if (existing != null)
            {
                return existing;
            }

            Directory.CreateDirectory(MaterialDir);
            Shader shader = Shader.Find("Universal Render Pipeline/Lit");
            var material = new Material(shader) { name = "PipWhite" };
            material.SetColor("_BaseColor", new Color(0.95f, 0.95f, 0.95f)); // scrappy white dog (characters.md §Pip)
            AssetDatabase.CreateAsset(material, PipMaterialPath);
            return material;
        }

        private static GameObject FindRoot(UnityEngine.SceneManagement.Scene scene, string name)
        {
            return scene.IsValid()
                ? scene.GetRootGameObjects().FirstOrDefault(go => go.name == name)
                : null;
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
