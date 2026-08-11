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
        [SerializeField] private PlayerDustPuffs _dust;

        [Header("Roll shape")]
        // was 9 — the miniature covered ~5.4m per roll ("way too far", director playtest);
        // half the ground over the same window keeps Fool's Chance timing feel unchanged.
        [SerializeField] private float _dodgeSpeed = 4.5f;
        [SerializeField] private float _dodgeDuration = 0.6f; // was 0.45 — UAL roll clip needs the room (playtest: "way too fast")
        [SerializeField] private float _cooldownDuration = 0.15f;

        [Header("Side-hop window (director round 5: SHORT window, FAST clip)")]
        // Round 4 stretched the hop LEG animation (timeScale ≈ 0.74) to fill the roll's 0.6s window —
        // the opposite of intent. The director wants the hop SNAPPY and over quickly: the clip stays
        // fast and the hop's own dodge window is cut to match it. Hops get their own window + cooldown,
        // separate from rolls/backflips (which keep _dodgeDuration / _cooldownDuration).
        [Tooltip("Movement-window length for the Focus strafe-hops (left/right) — shorter than a roll so the hop is over quickly. The hop leg clip is time-scaled to this in KayKitCharacterInstaller (HopWindowSeconds must track this value).")]
        [SerializeField] private float _hopWindowSeconds = 0.42f;
        [Tooltip("Cooldown after a hop before another dodge is allowed. Near-zero so chained hops fire immediately (director round 5: 'dodge→dodge right away'); rolls keep the longer _cooldownDuration.")]
        [SerializeField] private float _hopCooldownDuration = 0.02f;

        [Tooltip("How long a dodge press stays buffered waiting for the dodge to come off cooldown.")]
        [SerializeField] private float _inputBufferSeconds = 0.25f;

        [Tooltip("Distance multiplier for the Focus strafe-hops (left/right) vs. a full roll — a crisp sidestep, not a leap. Director round 3: 0.38x (was 0.45x, 'soft/slow'; the hop wants JARRING and shorter).")]
        [SerializeField] private float _hopDistanceScale = 0.38f;

        [Tooltip("Front-loads the strafe-hop's displacement so it reads as a sharp burst, not a soft glide: this velocity-scale curve is sampled over the hop's normalised progress (0→1) and normalised to unit area, so the total hop distance stays _hopDistanceScale but most of it lands in the first ~40% of the window. Only the side-hops use it; rolls/backflips keep constant speed.")]
        [SerializeField] private AnimationCurve _hopSpeedCurve = new AnimationCurve(
            new Keyframe(0f, 2.4f), new Keyframe(0.4f, 0.35f), new Keyframe(1f, 0f));

        [Header("Invincibility window (seconds into the roll)")]
        [SerializeField] private float _invulnerableStartOffset = 0.05f;
        [SerializeField] private float _invulnerableDuration = 0.3f;

        private DodgeState _state;
        private Vector3 _dodgeDirection = Vector3.forward;
        private DodgeVariant _variant = DodgeVariant.Roll;
        private float _currentSpeedScale = 1f;
        private float _dodgeBufferedUntil = float.NegativeInfinity;
        private float _hopCurveMean = 1f;
        private float _hopDistanceCompensation = 1f;
        private bool _wasDodgingForDust;

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
        public Vector3 CurrentVelocity
        {
            get
            {
                if (!IsDodging)
                {
                    return Vector3.zero;
                }

                float scale = _dodgeSpeed * _currentSpeedScale;

                // Side-hops burst front-loaded (director round 3: "sharp burst, not a soft glide");
                // the unit-area curve redistributes the total distance toward the first ~40%. The
                // distance-compensation (round 5) multiplies by _dodgeDuration/_hopWindowSeconds so the
                // hop still covers its full 0.38×-of-roll distance even though the window is now shorter —
                // the same ground crossed faster (a higher peak burst), not less ground.
                if (_variant == DodgeVariant.HopLeft || _variant == DodgeVariant.HopRight)
                {
                    scale *= HopSpeedFactor(Progress) * _hopDistanceCompensation;
                }

                return _dodgeDirection * scale;
            }
        }

        // The hop's velocity-scale at a given progress, normalised so the curve's mean is 1 — the
        // shape front-loads the burst while the mean keeps total distance = _dodgeSpeed·scale·duration.
        // Clamped non-negative so a smooth-tangent overshoot can never briefly reverse the hop.
        private float HopSpeedFactor(float progress)
        {
            float raw = Mathf.Max(0f, _hopSpeedCurve.Evaluate(progress));
            return _hopCurveMean > 0.0001f ? raw / _hopCurveMean : 1f;
        }

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
            _hopCurveMean = ComputeCurveMean(_hopSpeedCurve);

            // Preserve the hop's total distance (0.38× a roll = _dodgeSpeed·_hopDistanceScale·_dodgeDuration)
            // when it is delivered over the shorter _hopWindowSeconds: velocity is scaled up by the window
            // ratio so distance = velocity·window stays put. Guarded against a zero/negative window.
            _hopDistanceCompensation = _hopWindowSeconds > 0.0001f ? _dodgeDuration / _hopWindowSeconds : 1f;

            if (_input == null)
            {
                _input = GetComponent<PlayerInputReader>();
            }

            if (_motor == null)
            {
                _motor = GetComponent<PlayerMotor>();
            }

            if (_dust == null)
            {
                _dust = GetComponent<PlayerDustPuffs>();
            }

            if (_cameraTransform == null && Camera.main != null)
            {
                _cameraTransform = Camera.main.transform;
            }
        }

        // Numerically integrates the (clamped) hop curve over [0,1] so HopSpeedFactor can divide by
        // it and preserve total hop distance regardless of the authored curve's shape.
        private static float ComputeCurveMean(AnimationCurve curve)
        {
            if (curve == null || curve.length == 0)
            {
                return 1f;
            }

            const int samples = 48;
            float sum = 0f;
            for (int i = 0; i < samples; i++)
            {
                sum += Mathf.Max(0f, curve.Evaluate((i + 0.5f) / samples));
            }

            return sum / samples;
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

            // Dust at the feet when a dodge ENDS (the start puff fires in BeginDodgeIfReady). A roll,
            // hop or backflip all kick up a small puff as they plant.
            bool dodging = IsDodging;
            if (!dodging && _wasDodgingForDust && _dust != null)
            {
                _dust.EmitFootPuff(0.8f);
            }

            _wasDodgingForDust = dodging;
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

            // Side-hops run a SHORTER, near-cooldownless window (director round 5) so the hop is snappy
            // and chains immediately; rolls/backflips keep the default roll window + cooldown.
            bool isHop = variant == DodgeVariant.HopLeft || variant == DodgeVariant.HopRight;
            float window = isHop ? _hopWindowSeconds : _dodgeDuration;
            float cooldown = isHop ? _hopCooldownDuration : _cooldownDuration;

            if (_state.TryStartDodge(window, cooldown))
            {
                _dodgeDirection = direction;
                _variant = variant;
                _currentSpeedScale = speedScale;

                if (_dust != null)
                {
                    _dust.EmitFootPuff(1f); // a small puff at the feet on the dodge commit
                }
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
