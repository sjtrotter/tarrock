namespace Tarrock.Editor
{

    using Tarrock.Player;
    using Unity.Cinemachine;
    using UnityEditor;
    using UnityEngine;

    /// <summary>
    /// Single source of truth for the Cliff/Sandbox camera-rig obstacle tuning, shared by
    /// <see cref="KayKitCharacterInstaller"/> and <see cref="CliffHexGenerator"/> so both scenes build
    /// an identical wall-response rig (SPEC A). Owns: the <see cref="CinemachineDeoccluder"/> retune
    /// (PullCameraForward + the min-distance clamp + the CameraTransparent foliage layer), the added
    /// <see cref="CinemachineDecollider"/> safety guard, and the wiring of the
    /// <see cref="CameraWallResponse"/> staged controller + its <see cref="CharacterFade"/>.
    /// </summary>
    internal static class CameraRigConfig
    {
        /// <summary>Layer for foliage/grass/small-deco colliders that must NOT pull the camera in.</summary>
        public const string CameraTransparentLayerName = "CameraTransparent";

        // -- Deoccluder (Stage 1 + Stage 5 clamp) ---------------------------------------------
        private const CinemachineDeoccluder.ObstacleAvoidance.ResolutionStrategy DeoStrategy =
            CinemachineDeoccluder.ObstacleAvoidance.ResolutionStrategy.PullCameraForward;
        private const float DeoCameraRadius = 0.1f;
        private const float DeoDamping = 0f;
        private const float DeoDampingWhenOccluded = 0.3f;
        private const float DeoSmoothingTime = 0.2f;
        private const float DeoMinimumOcclusionTime = 0.1f;
        private const int DeoMaximumEffort = 4;
        private const float DeoMinimumDistanceFromTarget = 1.0f; // occluders nearer than this are ignored

        // -- Decollider (Stage 5 "can't sit inside a wall") -----------------------------------
        private const float DecolliderCameraRadius = 0.15f;

        /// <summary>
        /// Configures the deoccluder + decollider on the vcam and wires the <see cref="CameraWallResponse"/>
        /// (adding a <see cref="CharacterFade"/> to the player rig). Identical for both scenes.
        /// </summary>
        public static void Apply(
            GameObject vcamGo, CinemachineOrbitalFollow orbital, CinemachineCamera vcam,
            GameObject playerRig, float orbitRadius, string ignoreTag)
        {
            int transparentLayer = EnsureCameraTransparentLayer();
            int transparentMask = 1 << transparentLayer;

            var deoccluder = vcamGo.GetComponent<CinemachineDeoccluder>();
            if (deoccluder == null)
            {
                deoccluder = vcamGo.AddComponent<CinemachineDeoccluder>();
            }

            // Collide against Default + the transparent layer, then mark the transparent layer
            // transparent so the resolved raycast (CollideAgainst & ~TransparentLayers) is Default only:
            // foliage/grass never pulls the camera in, walls/terrain still do.
            deoccluder.CollideAgainst = 1 | transparentMask;
            deoccluder.TransparentLayers = transparentMask;
            deoccluder.IgnoreTag = ignoreTag;
            deoccluder.MinimumDistanceFromTarget = DeoMinimumDistanceFromTarget;
            deoccluder.AvoidObstacles.Enabled = true;
            deoccluder.AvoidObstacles.Strategy = DeoStrategy;
            deoccluder.AvoidObstacles.CameraRadius = DeoCameraRadius;
            deoccluder.AvoidObstacles.DistanceLimit = orbitRadius;
            deoccluder.AvoidObstacles.MaximumEffort = DeoMaximumEffort;
            deoccluder.AvoidObstacles.MinimumOcclusionTime = DeoMinimumOcclusionTime;
            deoccluder.AvoidObstacles.SmoothingTime = DeoSmoothingTime;
            deoccluder.AvoidObstacles.Damping = DeoDamping;
            deoccluder.AvoidObstacles.DampingWhenOccluded = DeoDampingWhenOccluded;

            // Decollider: the last-ditch guard so the camera can still never sit inside a wall once the
            // deoccluder's min-distance clamp lets close occluders through. Decollision on, terrain-ride off.
            var decollider = vcamGo.GetComponent<CinemachineDecollider>();
            if (decollider == null)
            {
                decollider = vcamGo.AddComponent<CinemachineDecollider>();
            }

            decollider.CameraRadius = DecolliderCameraRadius;
            decollider.Decollision.Enabled = true;
            decollider.Decollision.ObstacleLayers = 1; // Default: walls/terrain
            decollider.TerrainResolution.Enabled = false;

            // Character fade (Stage 3) lives on the player rig; add if missing and point it at the Visual.
            var fade = playerRig.GetComponent<CharacterFade>();
            if (fade == null)
            {
                fade = playerRig.AddComponent<CharacterFade>();
            }

            Transform visual = playerRig.transform.Find("Visual");
            if (visual != null)
            {
                SetObjectReference(fade, "_visualRoot", visual);
            }

            // The staged wall response replaces the old up-and-over CameraOcclusionLift. Never drives
            // pitch — only horizontal bias (whiskers), pivot height (framing), and the fade.
            var wall = vcamGo.GetComponent<CameraWallResponse>();
            if (wall == null)
            {
                wall = vcamGo.AddComponent<CameraWallResponse>();
            }

            SetObjectReference(wall, "_orbital", orbital);
            SetObjectReference(wall, "_composer", vcamGo.GetComponent<CinemachineRotationComposer>());
            SetObjectReference(wall, "_vcam", vcam);
            SetObjectReference(wall, "_player", playerRig.transform);
            SetObjectReference(wall, "_input", playerRig.GetComponent<PlayerInputReader>());
            SetObjectReference(wall, "_motor", playerRig.GetComponent<PlayerMotor>());
            SetObjectReference(wall, "_fade", fade);
        }

        /// <summary>
        /// Ensures the <see cref="CameraTransparentLayerName"/> user layer exists (first free slot at
        /// index ≥ 6) and returns its index. Idempotent.
        /// </summary>
        public static int EnsureCameraTransparentLayer()
        {
            Object[] assets = AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset");
            if (assets == null || assets.Length == 0)
            {
                return 0;
            }

            var tagManager = new SerializedObject(assets[0]);
            SerializedProperty layers = tagManager.FindProperty("layers");
            if (layers == null)
            {
                return 0;
            }

            for (int i = 0; i < layers.arraySize; i++)
            {
                if (layers.GetArrayElementAtIndex(i).stringValue == CameraTransparentLayerName)
                {
                    return i;
                }
            }

            // First empty user slot (indices 0-5 are Unity builtins / reserved).
            for (int i = 6; i < layers.arraySize; i++)
            {
                SerializedProperty slot = layers.GetArrayElementAtIndex(i);
                if (string.IsNullOrEmpty(slot.stringValue))
                {
                    slot.stringValue = CameraTransparentLayerName;
                    tagManager.ApplyModifiedPropertiesWithoutUndo();
                    return i;
                }
            }

            Debug.LogWarning("[Tarrock] No free user layer slot for CameraTransparent; foliage layering skipped.");
            return 0;
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
