namespace Tarrock.Player
{

    using System.Collections.Generic;
    using UnityEngine;

    /// <summary>
    /// Fades the Fool's visual out when the camera is pinned too close to see it well (Stage 3 of
    /// <see cref="CameraWallResponse"/>). The character's "rogue" material is opaque URP/Lit, and a
    /// <see cref="MaterialPropertyBlock"/> alpha would do nothing on an opaque surface. A runtime
    /// opaque->transparent surface swap of URP/Lit was tried first and rendered NOTHING here (URP does
    /// not reliably build the transparent variant from a runtime <c>SetFloat</c>; same class of problem
    /// as the DustParticle shader). So the robust path is a <b>screen-door dither</b>: the first time a
    /// fade is requested, one shared material on the <c>Tarrock/CharacterFadeDither</c> shader (a
    /// reliable OPAQUE shader that clips pixels on a Bayer pattern) is assigned to every renderer and
    /// its <c>_Fade</c> is driven 1->0. Once the fade returns to fully opaque the original shared
    /// material is restored, so there is zero cost during normal play.
    ///
    /// Purely cosmetic — it never touches gameplay state or the <see cref="CharacterController"/>.
    /// </summary>
    public sealed class CharacterFade : MonoBehaviour
    {
        private const string DitherShaderName = "Tarrock/CharacterFadeDither";
        private const string BaseMapProperty = "_BaseMap";
        private const string BaseMapStProperty = "_BaseMap_ST";
        private const string BaseColorProperty = "_BaseColor";
        private const string FadeProperty = "_Fade";
        private const float OpaqueThreshold = 0.999f;

        [Tooltip("Root of the character visual whose renderers are faded. Defaults to a child named 'Visual', else this object.")]
        [SerializeField] private Transform _visualRoot;

        private readonly List<Renderer> _renderers = new List<Renderer>();
        private Material _opaqueSource;
        private Material _ditherMaterial;
        private bool _initialized;
        private bool _fadedMaterialActive;
        private float _currentAlpha = 1f;

        /// <summary>
        /// Sets the character's opacity, 1 = fully opaque (original material restored), 0 = invisible.
        /// Idempotent per value; only touches the renderers when the alpha actually changes state.
        /// </summary>
        public void SetAlpha(float alpha)
        {
            EnsureInitialized();
            if (_renderers.Count == 0 || _opaqueSource == null)
            {
                return;
            }

            alpha = Mathf.Clamp01(alpha);
            if (Mathf.Approximately(alpha, _currentAlpha) && (alpha >= OpaqueThreshold) == !_fadedMaterialActive)
            {
                return;
            }

            _currentAlpha = alpha;

            if (alpha >= OpaqueThreshold)
            {
                RestoreOpaque();
                return;
            }

            ApplyTransparent(alpha);
        }

        private void EnsureInitialized()
        {
            if (_initialized)
            {
                return;
            }

            _initialized = true;

            Transform root = _visualRoot;
            if (root == null)
            {
                Transform found = transform.Find("Visual");
                root = found != null ? found : transform;
            }

            foreach (Renderer renderer in root.GetComponentsInChildren<Renderer>(true))
            {
                // Skip particle systems (the runtime dust) — only skinned/mesh body renderers fade.
                if (renderer is ParticleSystemRenderer)
                {
                    continue;
                }

                _renderers.Add(renderer);
                if (_opaqueSource == null && renderer.sharedMaterial != null)
                {
                    _opaqueSource = renderer.sharedMaterial;
                }
            }
        }

        private void ApplyTransparent(float alpha)
        {
            if (_ditherMaterial == null)
            {
                _ditherMaterial = BuildDitherMaterial(_opaqueSource);
            }

            if (_ditherMaterial != null && _ditherMaterial.HasProperty(FadeProperty))
            {
                _ditherMaterial.SetFloat(FadeProperty, alpha);
            }

            if (!_fadedMaterialActive && _ditherMaterial != null)
            {
                foreach (Renderer renderer in _renderers)
                {
                    renderer.sharedMaterial = _ditherMaterial;
                }

                _fadedMaterialActive = true;
            }
        }

        private void RestoreOpaque()
        {
            if (!_fadedMaterialActive)
            {
                return;
            }

            foreach (Renderer renderer in _renderers)
            {
                renderer.sharedMaterial = _opaqueSource;
            }

            _fadedMaterialActive = false;
        }

        // Builds the dither-fade material, copying the source's base texture + tint so the character
        // reads identically until the screen-door clip dissolves it. Uses the reliable OPAQUE
        // Tarrock/CharacterFadeDither shader (URP's runtime transparent swap rendered nothing here).
        private static Material BuildDitherMaterial(Material source)
        {
            Shader shader = Shader.Find(DitherShaderName);
            if (shader == null)
            {
                Debug.LogWarning($"[Tarrock] Shader '{DitherShaderName}' not found; character fade disabled.");
                return null;
            }

            var mat = new Material(shader) { name = source.name + "_Dither" };

            // URP/Lit exposes its albedo as _BaseMap / _BaseColor; copy them across (fall back to the
            // legacy _MainTex slot if present) so the dithered character keeps its texture and tint.
            if (source.HasProperty(BaseMapProperty) && mat.HasProperty(BaseMapProperty))
            {
                mat.SetTexture(BaseMapProperty, source.GetTexture(BaseMapProperty));
                if (source.HasProperty(BaseMapStProperty))
                {
                    mat.SetVector(BaseMapStProperty, source.GetVector(BaseMapStProperty));
                }
            }
            else if (source.mainTexture != null)
            {
                mat.SetTexture(BaseMapProperty, source.mainTexture);
            }

            if (source.HasProperty(BaseColorProperty) && mat.HasProperty(BaseColorProperty))
            {
                mat.SetColor(BaseColorProperty, source.GetColor(BaseColorProperty));
            }

            mat.SetFloat(FadeProperty, 1f);
            return mat;
        }

        private void OnDestroy()
        {
            if (_ditherMaterial != null)
            {
                Destroy(_ditherMaterial);
            }
        }
    }
}
