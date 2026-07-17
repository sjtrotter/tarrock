namespace Tarrock.Player
{

    using UnityEngine;

    /// <summary>
    /// Drives the Fool's dodge roll (combat.md §Defense) on top of the pure
    /// <see cref="DodgeState"/> timing machine. On a Dodge input it captures a burst direction —
    /// camera-relative when the player is steering, or straight backward from the character's
    /// facing on neutral stick — and produces a horizontal velocity for the roll's duration.
    ///
    /// This component owns the dodge <em>decision</em> and <em>motion vector</em>; the single
    /// <see cref="CharacterController"/> mover lives in <see cref="PlayerMotor"/>, which reads
    /// <see cref="IsDodging"/> and <see cref="CurrentVelocity"/> so the roll and normal
    /// locomotion never fight over the controller. <see cref="IsInvulnerable"/> is exposed for
    /// the future combat layer (Fool's Chance, damage) — combat.md's i-frame window, surfaced
    /// but not yet consumed this phase.
    /// </summary>
    public sealed class PlayerDodge : MonoBehaviour
    {
        private const float NeutralInputThresholdSqr = 0.04f; // ~0.2 magnitude deadzone

        [SerializeField] private PlayerInputReader _input;
        [SerializeField] private PlayerMotor _motor;
        [SerializeField] private Transform _cameraTransform;

        [Header("Roll shape")]
        // was 9 — the miniature covered ~5.4m per roll ("way too far", director playtest);
        // half the ground over the same window keeps Fool's Chance timing feel unchanged.
        [SerializeField] private float _dodgeSpeed = 4.5f;
        [SerializeField] private float _dodgeDuration = 0.6f; // was 0.45 — UAL roll clip needs the room (playtest: "way too fast")
        [SerializeField] private float _cooldownDuration = 0.15f;

        [Tooltip("How long a dodge press stays buffered waiting for the dodge to come off cooldown.")]
        [SerializeField] private float _inputBufferSeconds = 0.25f;

        [Tooltip("Distance multiplier for the Focus strafe-hops (left/right) vs. a full roll — a crisp sidestep, not a leap. Director round: 0.45x of the roll (was 0.7x, 'too much').")]
        [SerializeField] private float _hopDistanceScale = 0.45f;

        [Header("Invincibility window (seconds into the roll)")]
        [SerializeField] private float _invulnerableStartOffset = 0.05f;
        [SerializeField] private float _invulnerableDuration = 0.3f;

        private DodgeState _state;
        private Vector3 _dodgeDirection = Vector3.forward;
        private DodgeVariant _variant = DodgeVariant.Roll;
        private float _currentSpeedScale = 1f;
        private float _dodgeBufferedUntil = float.NegativeInfinity;

        /// <summary>True while a roll is active and driving movement.</summary>
        public bool IsDodging => _state != null && _state.IsDodging;

        /// <summary>
        /// True while the i-frame window is open. Read by the combat layer once it exists;
        /// harmless to poll before then.
        /// </summary>
        public bool IsInvulnerable => _state != null && _state.IsInvulnerable;

        /// <summary>
        /// Horizontal world-space velocity the roll wants applied this frame, or zero when not
        /// dodging. Consumed by <see cref="PlayerMotor"/>. Scaled by the per-dodge distance factor
        /// so a Focus strafe-hop covers less ground than a full roll.
        /// </summary>
        public Vector3 CurrentVelocity => IsDodging ? _dodgeDirection * (_dodgeSpeed * _currentSpeedScale) : Vector3.zero;

        /// <summary>
        /// World-space direction of the current (or most recent) roll. Read by
        /// <see cref="PlayerAnimationDriver"/> to pick the directional dodge clip and to orient
        /// the procedural tumble; stable for the whole roll (captured once at dodge start).
        /// </summary>
        public Vector3 CurrentDirection => _dodgeDirection;

        /// <summary>
        /// Which directional variant the active (or most recent) dodge is — roll, side-hop, or
        /// backflip (combat.md §Focus). Latched once at dodge start. Read by
        /// <see cref="PlayerAnimationDriver"/> to gate and orient the procedural tumble.
        /// </summary>
        public DodgeVariant CurrentVariant => _variant;

        /// <summary>
        /// Normalised progress through the active roll, 0 at start, 1 at end (and 1 while not
        /// rolling). Drives the procedural tumble in <see cref="PlayerAnimationDriver"/>.
        /// </summary>
        public float Progress => _state != null ? _state.DodgeProgress : 1f;

        private void Awake()
        {
            _state = new DodgeState(_dodgeDuration, _cooldownDuration, _invulnerableStartOffset, _invulnerableDuration);

            if (_input == null)
            {
                _input = GetComponent<PlayerInputReader>();
            }

            if (_motor == null)
            {
                _motor = GetComponent<PlayerMotor>();
            }

            if (_cameraTransform == null && Camera.main != null)
            {
                _cameraTransform = Camera.main.transform;
            }
        }

        private void OnEnable()
        {
            if (_input != null)
            {
                _input.DodgePressed += OnDodgePressed;
            }
        }

        private void OnDisable()
        {
            if (_input != null)
            {
                _input.DodgePressed -= OnDodgePressed;
            }
        }

        private void Update()
        {
            // Input buffering: a press stays valid for a short window instead of being
            // consumed (and lost) the frame it arrives — pressing during a dodge or its
            // cooldown fires the moment the dodge is ready again. Without this, rhythmic
            // presses land in the lockout and feel like dead input.
            if (Time.time <= _dodgeBufferedUntil && _state.CanDodge)
            {
                _dodgeBufferedUntil = float.NegativeInfinity;
                BeginDodgeIfReady();
            }

            _state.Tick(Time.deltaTime);
        }

        private void OnDodgePressed()
        {
            // Only the Focus stance turns the dodge input into a dodge; out of Focus the same press
            // is a jump, owned by PlayerMotor (combat.md §Focus). Buffering only while Focus is held
            // keeps an out-of-Focus press from being consumed here and lost.
            if (_input == null || !_input.FocusHeld)
            {
                return;
            }

            _dodgeBufferedUntil = Time.time + _inputBufferSeconds;
        }

        private void BeginDodgeIfReady()
        {
            if (!_state.CanDodge)
            {
                return;
            }

            // A roll/hop/flip is a grounded commit — never mid-air (combat.md §Focus: dodge is
            // unavailable while airborne; the jump owns the air).
            if (_motor != null && _motor.IsAirborne)
            {
                return;
            }

            ResolveDodge(out Vector3 direction, out DodgeVariant variant, out float speedScale);
            if (_state.TryStartDodge())
            {
                _dodgeDirection = direction;
                _variant = variant;
                _currentSpeedScale = speedScale;
            }
        }

        // Resolves the directional Focus dodge (combat.md §Focus): forward/neutral = roll,
        // left/right = strafe-hop (shorter), backward = backflip. Direction is camera-relative so the
        // hop tracks the strafing frame, not the character's facing.
        private void ResolveDodge(out Vector3 direction, out DodgeVariant variant, out float speedScale)
        {
            Vector2 move = _input != null ? _input.MoveInput : Vector2.zero;
            speedScale = 1f;

            if (move.sqrMagnitude <= NeutralInputThresholdSqr)
            {
                // Neutral = the dodge roll FORWARD along the Fool's facing (combat.md §Focus:
                // "forward or neutral = the dodge roll"). This previously rolled backward
                // (-transform.forward), which selected the Dodge_Backward clip and read as a
                // backflip — the pre-Focus backstep default. Only explicit back input is a backflip.
                direction = transform.forward;
                variant = DodgeVariant.Roll;
                return;
            }

            if (Mathf.Abs(move.y) >= Mathf.Abs(move.x))
            {
                // Fore/aft dominant.
                if (move.y >= 0f)
                {
                    direction = CameraRelative(new Vector2(0f, 1f));
                    variant = DodgeVariant.Roll;
                }
                else
                {
                    direction = CameraRelative(new Vector2(0f, -1f));
                    variant = DodgeVariant.Backflip;
                }
            }
            else
            {
                // Lateral dominant: a shorter strafe-hop.
                float sign = move.x >= 0f ? 1f : -1f;
                direction = CameraRelative(new Vector2(sign, 0f));
                variant = sign >= 0f ? DodgeVariant.HopRight : DodgeVariant.HopLeft;
                speedScale = _hopDistanceScale;
            }

            direction = direction.sqrMagnitude > 0.0001f ? direction.normalized : transform.forward;
        }

        private Vector3 CameraRelative(Vector2 move)
        {
            if (_cameraTransform == null)
            {
                return new Vector3(move.x, 0f, move.y);
            }

            Vector3 forward = _cameraTransform.forward;
            Vector3 right = _cameraTransform.right;
            forward.y = 0f;
            right.y = 0f;
            forward.Normalize();
            right.Normalize();

            return (forward * move.y) + (right * move.x);
        }
    }
}
