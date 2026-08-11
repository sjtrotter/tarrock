namespace Tarrock.Regions
{

    using Tarrock.WorldState;
    using UnityEngine;

    /// <summary>
    /// Owns the single global foliage-wind scalar for the region it lives in, realising the art
    /// direction canon (art-audio.md §The world-state is the art direction): a BOUND region holds
    /// its breath — no wind; once its Arcana is UNBOUND, motion returns — wind rises in the foliage.
    /// <para>
    /// The value is pushed to <c>Shader.SetGlobalFloat("_TarrockWindStrength", …)</c>, the one global
    /// the <c>Tarrock/FoliageWind</c> shader multiplies all vertex displacement by, so a single write
    /// per frame sweeps every foliage material in the region at once (no per-material bookkeeping).
    /// </para>
    /// <para>
    /// World-state integration uses the real service API (technical.md §The WorldState service):
    /// <see cref="WorldStateService.IsFired"/> for the initial read (order-independent — the region
    /// can load after its flag already fired) and <see cref="WorldStateService.StateFired"/> for the
    /// live transition. The service is reached through the sanctioned composition root
    /// (<see cref="CompositionRoot.Instance"/>); when it is absent — a region scene opened directly in
    /// the editor with no Bootstrap — the component falls back to the inspector override so the
    /// director can still scrub wind. See <see cref="SetUnbound"/> for the manual entry point.
    /// </para>
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class RegionWind : MonoBehaviour
    {
        private static readonly int WindStrengthId = Shader.PropertyToID("_TarrockWindStrength");

        [Header("World-state binding")]
        [Tooltip("The WS_* flag whose firing unbinds this region's Arcana. Must match a " +
                 "Tarrock.WorldState.WorldStateIds constant (world.md §World-state matrix).")]
        [SerializeField] private string _regionStateId = string.Empty;

        [Header("Wind strengths")]
        [Tooltip("Global wind while the region is bound (holds its breath). Canon: 0.")]
        [SerializeField] private float _boundStrength = 0f;
        [Tooltip("Global wind once the region is unbound (motion returns).")]
        [SerializeField] private float _unboundStrength = 1f;
        [Tooltip("Seconds to cross a full unit of wind strength when the target changes.")]
        [SerializeField] private float _transitionSeconds = 8f;

        [Header("Editor / director scrub")]
        [Tooltip("When on, ignore world state and drive wind directly from Override Strength — " +
                 "lets the director feel the sway in play mode without firing a flag.")]
        [SerializeField] private bool _editorOverride = false;
        [SerializeField] private float _overrideStrength = 1f;

        private WorldStateService _service;
        private bool _isUnbound;
        private float _currentStrength;

        private void OnEnable()
        {
            _service = CompositionRoot.Instance != null ? CompositionRoot.Instance.WorldState : null;

            if (!string.IsNullOrEmpty(_regionStateId))
            {
                WarnIfUnknownId();
            }

            if (_service != null)
            {
                // Order-independent initial read: the flag may already have fired before this region
                // streamed in. Then subscribe for the live unbind moment.
                _isUnbound = !string.IsNullOrEmpty(_regionStateId) && _service.IsFired(_regionStateId);
                _service.StateFired += OnStateFired;
            }

            // Start already-settled at the resolved target so a bound region shows no wind on load
            // and an already-unbound region loads with wind up (no visible ramp on stream-in).
            _currentStrength = ResolveTarget();
            Shader.SetGlobalFloat(WindStrengthId, _currentStrength);
        }

        private void OnDisable()
        {
            if (_service != null)
            {
                _service.StateFired -= OnStateFired;
                _service = null;
            }
        }

        private void Update()
        {
            float target = ResolveTarget();
            if (!Mathf.Approximately(_currentStrength, target))
            {
                // Constant-rate transition: _transitionSeconds is the time to cross one unit of
                // strength, so the bound→unbound ramp reads the same regardless of the endpoints.
                float rate = _transitionSeconds > Mathf.Epsilon ? 1f / _transitionSeconds : float.MaxValue;
                _currentStrength = Mathf.MoveTowards(_currentStrength, target, rate * Time.deltaTime);
            }

            Shader.SetGlobalFloat(WindStrengthId, _currentStrength);
        }

        /// <summary>
        /// Forces the bound/unbound wind target without world state — the manual extension point for
        /// callers that drive the transition themselves (cutscenes, tests, tools). World-state firing
        /// already routes here via <see cref="WorldStateService.StateFired"/>; this is the override.
        /// </summary>
        public void SetUnbound(bool unbound) => _isUnbound = unbound;

        private float ResolveTarget()
        {
            if (_editorOverride)
            {
                return _overrideStrength;
            }

            return _isUnbound ? _unboundStrength : _boundStrength;
        }

        private void OnStateFired(string id)
        {
            if (!string.IsNullOrEmpty(_regionStateId) && id == _regionStateId)
            {
                _isUnbound = true;
            }
        }

        // Ties the serialised id back to the canonical constant surface at runtime (no-magic-strings
        // spirit: the id is data entered in the inspector, validated against WorldStateIds — the one
        // place WS_* literals live — rather than trusted blind).
        private void WarnIfUnknownId()
        {
            foreach (string known in WorldStateIds.All)
            {
                if (known == _regionStateId)
                {
                    return;
                }
            }

            Debug.LogWarning(
                $"[Tarrock] RegionWind region-state id '{_regionStateId}' is not a known WorldStateIds " +
                "constant (world.md §World-state matrix); wind will never transition to unbound.", this);
        }
    }
}
