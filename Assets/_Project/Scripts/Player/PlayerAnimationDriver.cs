namespace Tarrock.Player
{

    using UnityEngine;

    /// <summary>
    /// Bridges the Fool's locomotion state to the character visual's <see cref="Animator"/>.
    /// Each frame it pushes:
    ///
    /// - <c>Speed</c> (float) — <see cref="PlayerMotor.CurrentPlanarSpeed"/>, driving the
    ///   Idle→Jog→Sprint 1D blend tree (and the Crouch-idle→Sneak tree while crouched);
    /// - <c>Dodge</c> (bool) — <see cref="PlayerDodge.IsDodging"/>, gating the dodge state;
    /// - <c>Crouched</c> (bool) — <see cref="PlayerMotor.IsCrouched"/>, gating the crouch tree;
    /// - <c>DodgeX</c>/<c>DodgeY</c> (floats) — the roll direction in the character's local
    ///   space, set once at dodge start, selecting Dodge_Left/Right/Forward/Backward in the
    ///   directional dodge blend tree.
    ///
    /// The parameter names are the single source of truth shared with the AnimatorController
    /// built by the character installers (KayKit/Quaternius/StandIn); keep them in sync.
    ///
    /// <b>Procedural tumble (experiment):</b> the KayKit pack has no roll clip, so while
    /// <see cref="_proceduralTumble"/> is on, the VISUAL root (never the CharacterController)
    /// is pitched 360° about the dodge's travel direction over the roll window, eased in/out,
    /// layered over the Dodge_* clip. Toggle the serialized bool in the inspector to A/B it.
    ///
    /// This component is purely visual and read-only with respect to gameplay — it never moves
    /// the character or touches the <see cref="CharacterController"/>. If no Animator is wired
    /// (e.g. the capsule fallback when the vendored model is absent) it quietly does nothing.
    /// </summary>
    public sealed class PlayerAnimationDriver : MonoBehaviour
    {
        // Shared with the AnimatorController's parameters (see the character installers).
        private const string SpeedParameter = "Speed";
        private const string DodgeParameter = "Dodge";
        private const string CrouchedParameter = "Crouched";
        private const string DodgeXParameter = "DodgeX";
        private const string DodgeYParameter = "DodgeY";
        private const string AirborneParameter = "Airborne";

        private static readonly int SpeedHash = Animator.StringToHash(SpeedParameter);
        private static readonly int DodgeHash = Animator.StringToHash(DodgeParameter);
        private static readonly int CrouchedHash = Animator.StringToHash(CrouchedParameter);
        private static readonly int DodgeXHash = Animator.StringToHash(DodgeXParameter);
        private static readonly int DodgeYHash = Animator.StringToHash(DodgeYParameter);
        private static readonly int AirborneHash = Animator.StringToHash(AirborneParameter);

        [SerializeField] private Animator _animator;
        [SerializeField] private PlayerMotor _motor;
        [SerializeField] private PlayerDodge _dodge;

        [Tooltip("Damping (seconds) applied to the Speed float so the locomotion blend eases rather than snaps.")]
        [SerializeField] private float _speedDampTime = 0.1f;

        [Header("Procedural tumble (experiment — no roll clip exists in the pack)")]
        [Tooltip("Pitch the visual 360° in the dodge's travel direction over the roll window. A/B toggle for the director.")]
        [SerializeField] private bool _proceduralTumble = true;

        [Tooltip("Height (m) of the tumble's rotation pivot above the rig's feet — roughly half the visual's height.")]
        [SerializeField] private float _tumblePivotHeight = 0.35f;

        private bool _wasDodging;
        private Transform _visual;
        private Vector3 _visualBasePosition;
        private Quaternion _visualBaseRotation;
        private bool _visualPoseCached;

        private void Awake()
        {
            if (_animator == null)
            {
                _animator = GetComponentInChildren<Animator>();
            }

            if (_motor == null)
            {
                _motor = GetComponent<PlayerMotor>();
            }

            if (_dodge == null)
            {
                _dodge = GetComponent<PlayerDodge>();
            }
        }

        private void Update()
        {
            if (_animator == null || _animator.runtimeAnimatorController == null)
            {
                return;
            }

            float speed = _motor != null ? _motor.CurrentPlanarSpeed : 0f;
            _animator.SetFloat(SpeedHash, speed, _speedDampTime, Time.deltaTime);

            // The Focus stance reuses the crouch pose (combat.md §Focus), so the Focus input folds
            // into the animator's Crouched gate alongside the Ctrl-toggled stealth crouch.
            _animator.SetBool(CrouchedHash, _motor != null && (_motor.IsCrouched || _motor.IsFocused));
            _animator.SetBool(AirborneHash, _motor != null && _motor.IsAirborne);

            bool dodging = _dodge != null && _dodge.IsDodging;
            _animator.SetBool(DodgeHash, dodging);

            // Latch the roll direction once, at dodge start, in the character's local space so
            // the directional blend picks the matching Dodge_* clip and holds it for the roll.
            if (dodging && !_wasDodging)
            {
                Vector3 local = transform.InverseTransformDirection(_dodge.CurrentDirection);
                _animator.SetFloat(DodgeXHash, local.x);
                _animator.SetFloat(DodgeYHash, local.z);
            }

            _wasDodging = dodging;
        }

        // The tumble runs in LateUpdate so it layers on top of whatever the Animator wrote this
        // frame. The Animator animates the skeleton under the visual root; the root's own local
        // pose belongs to us, so restoring the base pose every frame is safe and cheap.
        private void LateUpdate()
        {
            if (_animator == null)
            {
                return;
            }

            if (!_visualPoseCached)
            {
                _visual = _animator.transform;
                if (_visual == transform)
                {
                    return; // Animator sits on the rig itself — never rotate the controller.
                }

                _visualBasePosition = _visual.localPosition;
                _visualBaseRotation = _visual.localRotation;
                _visualPoseCached = true;
            }

            _visual.localPosition = _visualBasePosition;
            _visual.localRotation = _visualBaseRotation;

            if (!_proceduralTumble || _dodge == null || !_dodge.IsDodging)
            {
                return;
            }

            // Only the roll and the backflip tumble; the strafe-hops (left/right) stay upright
            // (combat.md §Focus). The backflip is the same spin reversed — pitch −360 about the
            // travel axis rather than +360.
            DodgeVariant variant = _dodge.CurrentVariant;
            if (variant == DodgeVariant.HopLeft || variant == DodgeVariant.HopRight)
            {
                return;
            }

            float direction = variant == DodgeVariant.Backflip ? -1f : 1f;

            Vector3 travel = _dodge.CurrentDirection;
            travel.y = 0f;
            if (travel.sqrMagnitude < 0.0001f)
            {
                return;
            }

            // Eased 0→360° pitch about the horizontal axis perpendicular to travel, so the
            // character tumbles head-over-heels in the direction of the roll. At progress 1 the
            // spin is a full turn — identity — so there is never a snap back to upright.
            float progress = _dodge.Progress;
            float eased = progress * progress * (3f - (2f * progress)); // smoothstep
            float angle = direction * 360f * eased;

            Vector3 axis = Vector3.Cross(Vector3.up, travel.normalized);
            Vector3 pivot = transform.position + (Vector3.up * _tumblePivotHeight);
            Quaternion spin = Quaternion.AngleAxis(angle, axis);

            _visual.rotation = spin * _visual.rotation;
            _visual.position = pivot + (spin * (_visual.position - pivot));
        }
    }
}
