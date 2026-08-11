namespace Tarrock.Companion
{

    using System.Collections.Generic;
    using UnityEngine;

    /// <summary>
    /// Translates <see cref="PipController"/> state + planar speed into Animator parameters by
    /// logical name (art-audio.md §Current build rule 4: gameplay addresses animation by logical
    /// state, and which clip fills a state is an installer/rig concern — so this component never
    /// names a clip). Purely visual and read-only with respect to gameplay, exactly like
    /// PlayerAnimationDriver.
    ///
    /// Parameters pushed: <c>Speed</c> (float) each frame from the controller's planar speed;
    /// <c>Dig</c> (trigger) on entering <see cref="PipState.Dig"/>; <c>Sit</c> (bool) tracking
    /// <see cref="PipState.Sit"/>. During the placeholder phase there is often no Animator (the
    /// capsule/sphere stand-in has none) or a controller missing these parameters, so every write
    /// is guarded: the presence of each parameter is scanned once and cached, and a missing
    /// Animator makes the whole component a quiet no-op. It never throws.
    /// </summary>
    public sealed class PipAnimatorLink : MonoBehaviour
    {
        // Single source of truth for the logical parameter names shared with the rig's
        // AnimatorController (built by the Pip installer / a future Shiba installer).
        private const string SpeedParameter = "Speed";
        private const string DigParameter = "Dig";
        private const string SitParameter = "Sit";

        private static readonly int SpeedHash = Animator.StringToHash(SpeedParameter);
        private static readonly int DigHash = Animator.StringToHash(DigParameter);
        private static readonly int SitHash = Animator.StringToHash(SitParameter);

        [SerializeField] private PipController _controller;
        [SerializeField] private Animator _animator;

        [Tooltip("Damping (seconds) on the Speed float so the locomotion blend eases rather than snaps.")]
        [SerializeField] private float _speedDampTime = 0.1f;

        private readonly HashSet<int> _presentParameters = new();
        private bool _parametersCached;

        private void Awake()
        {
            if (_controller == null)
            {
                _controller = GetComponentInParent<PipController>();
            }

            if (_animator == null)
            {
                _animator = GetComponentInChildren<Animator>();
            }
        }

        private void OnEnable()
        {
            if (_controller != null)
            {
                _controller.StateChanged += OnStateChanged;
            }
        }

        private void OnDisable()
        {
            if (_controller != null)
            {
                _controller.StateChanged -= OnStateChanged;
            }
        }

        private void Update()
        {
            if (_animator == null || _animator.runtimeAnimatorController == null)
            {
                return;
            }

            EnsureParameterCache();

            float speed = _controller != null ? _controller.CurrentPlanarSpeed : 0f;
            if (_presentParameters.Contains(SpeedHash))
            {
                _animator.SetFloat(SpeedHash, speed, _speedDampTime, Time.deltaTime);
            }
        }

        private void OnStateChanged(PipState state)
        {
            if (_animator == null || _animator.runtimeAnimatorController == null)
            {
                return;
            }

            EnsureParameterCache();

            if (state == PipState.Dig && _presentParameters.Contains(DigHash))
            {
                _animator.SetTrigger(DigHash);
            }

            if (_presentParameters.Contains(SitHash))
            {
                _animator.SetBool(SitHash, state == PipState.Sit);
            }
        }

        // Scan the Animator's declared parameters once and remember which of ours exist, so writes
        // to an absent parameter (a placeholder controller, a swapped rig) are silently skipped
        // rather than logging Unity's "parameter does not exist" warning every frame.
        private void EnsureParameterCache()
        {
            if (_parametersCached || _animator == null)
            {
                return;
            }

            _presentParameters.Clear();
            foreach (AnimatorControllerParameter parameter in _animator.parameters)
            {
                _presentParameters.Add(parameter.nameHash);
            }

            _parametersCached = true;
        }
    }
}
