namespace Tarrock.Player
{

    using UnityEngine;

    /// <summary>
    /// Third-person locomotion for the Fool (combat.md §Philosophy: "readable and deliberate"
    /// movement). Camera-relative walk/sprint on a <see cref="CharacterController"/>, with smooth
    /// rotation toward the move direction and simple gravity + grounded handling so the Cliff's
    /// real west edge (CliffGreyboxGenerator: "the ground simply stops — no wall") can actually
    /// be walked off.
    ///
    /// This is the single owner of <see cref="CharacterController.Move"/>. During a roll it hands
    /// horizontal control to <see cref="PlayerDodge"/> (reading its velocity) while still applying
    /// gravity, so the two never issue competing moves.
    ///
    /// <b>Focus stance</b> (combat.md §Focus): while the Focus input is held the Fool strafes
    /// camera-relative without rotating to the move direction — the character keeps the facing it
    /// held at focus-entry (the OoT Z-target lock; the CAMERA swings behind, driven by
    /// <see cref="FocusStance"/>, not the character) — at <see cref="_focusSpeed"/>. <b>Jump:</b> out of Focus the
    /// dodge input is a vertical impulse (<see cref="_jumpSpeed"/>) instead of a roll, and the roll
    /// is unavailable while airborne. <b>Foliage drag:</b> while the capsule overlaps a short-bush
    /// trigger (<see cref="FoliageDrag"/>) the planar speed is clamped to <see cref="_foliageSpeed"/>.
    /// </summary>
    [RequireComponent(typeof(CharacterController))]
    public sealed class PlayerMotor : MonoBehaviour
    {
        private const float MoveInputThresholdSqr = 0.01f;

        [SerializeField] private PlayerInputReader _input;
        [SerializeField] private PlayerDodge _dodge;
        [SerializeField] private Transform _cameraTransform;
        [SerializeField] private PlayerDustPuffs _dust;

        [Header("Speeds (m/s)")]
        // Director retune for the 0.7m miniature (sandbox playtest): the default gait is a travel
        // JOG (Running_A in the animator), not a walk; Shift held = sprint. The serialized field
        // name stays "_walkSpeed" so older scenes keep their own tuned values.
        [SerializeField] private float _walkSpeed = 3.0f; // default gait: travel jog
        [SerializeField] private float _sprintSpeed = 4.8f;

        [Header("Focus stance (combat.md §Focus)")]
        [Tooltip("Planar strafe speed while the Focus input is held (camera-relative, no turn-to-move).")]
        [SerializeField] private float _focusSpeed = 2.0f;

        [Header("Foliage")]
        [Tooltip("Planar speed cap while the capsule overlaps a short-bush FoliageDrag trigger (walk tier).")]
        [SerializeField] private float _foliageSpeed = 1.5f;

        [Header("Jump (out-of-Focus dodge input)")]
        // apex = _jumpSpeed² / (2·|_gravity|); with _gravity −25 this gives ~0.54 m for the 0.7 m
        // miniature — the "reads right at jog speed" arc the director asked for (0.5-0.7 m). The 3.2
        // first guess only cleared ~0.2 m under this gravity, so it was tuned up.
        [Tooltip("Upward launch speed (m/s) of the jump — tuned for a ~0.5-0.7 m apex on the 0.7 m miniature.")]
        [SerializeField] private float _jumpSpeed = 5.2f;

        [Header("Grand backflip (crouched jump — combat.md §Focus)")]
        // Crouched + jump performs the GRAND BACKFLIP (canon: "a high, deliberately majestic backflip
        // — taller than a normal jump, carrying the Fool roughly 1.5 body-widths backward, finished
        // with an emphatic landing"). Distinct from the Focus back-dodge (a quick evasive flip). It
        // reuses the jump's vertical launch (scaled) and the procedural-flip machinery in
        // PlayerAnimationDriver, adding a constant backward planar drift over the airtime.
        [Tooltip("Apex height of the grand backflip as a multiple of the normal jump's apex (canon: ~1.6x, taller and majestic).")]
        [SerializeField] private float _grandBackflipApexScale = 1.6f;
        [Tooltip("Backward travel of the grand backflip, in metres (~1.5 body-widths at the 0.30-scale miniature ≈ 0.45 m).")]
        [SerializeField] private float _grandBackflipBackTravel = 0.45f;
        [Tooltip("Seconds over which the full backward 360° completes; kept a touch under the airtime so the flip is upright before the landing. Majestic = a hang, not a snap.")]
        [SerializeField] private float _grandBackflipRotationTime = 0.48f;

        [Header("Crouch")]
        [Tooltip("Planar speed while crouched (sneak tier).")]
        [SerializeField] private float _crouchSpeed = 0.8f; // was 1.2 — "still too fast" (director playtest)
        [Tooltip("CharacterController height multiplier while crouched (~40% reduction).")]
        [SerializeField] private float _crouchHeightScale = 0.6f;

        [Header("Turning")]
        [Tooltip("Approximate time, in seconds, to settle a turn toward the move direction.")]
        [SerializeField] private float _turnSmoothTime = 0.08f;

        [Header("Gravity")]
        [SerializeField] private float _gravity = -25f;
        [Tooltip("Small downward pull kept while grounded so isGrounded stays reliable on slopes.")]
        [SerializeField] private float _groundedStickForce = -3f;

        private CharacterController _controller;
        private float _verticalVelocity;
        private float _turnVelocity;
        private float _currentPlanarSpeed;
        private bool _crouched;
        private bool _airborne;
        private float _airborneTime;
        private bool _grandBackflip;
        private float _grandBackflipTime;
        private Vector3 _grandBackflipVelocity;
        private bool _wasFocused;
        private float _focusEntryYaw;
        private int _foliageOverlaps;
        private float _standingHeight;
        private Vector3 _standingCenter;

        /// <summary>
        /// The Fool's current planar (XZ) speed in metres/second — the actual movement applied
        /// this frame, whether from locomotion or a roll. Read by <see cref="PlayerAnimationDriver"/>
        /// to drive the locomotion blend; zero while standing still.
        /// </summary>
        public float CurrentPlanarSpeed => _currentPlanarSpeed;

        /// <summary>
        /// True while the Fool is crouched (Crouch input toggles; a dodge or sprint input stands
        /// the Fool back up). Read by <see cref="PlayerAnimationDriver"/> for the sneak states.
        /// </summary>
        public bool IsCrouched => _crouched;

        /// <summary>
        /// True while the Focus input is held — the combat stance (combat.md §Focus). Read by
        /// <see cref="PlayerAnimationDriver"/> (it folds into the crouch pose) and by the camera
        /// stance. Note this is the input state, distinct from the Ctrl-toggled stealth
        /// <see cref="IsCrouched"/>.
        /// </summary>
        public bool IsFocused => _input != null && _input.FocusHeld;

        /// <summary>
        /// True while the Fool is off the ground from a jump. Read by <see cref="PlayerDodge"/> to
        /// forbid a roll mid-air and by <see cref="PlayerAnimationDriver"/> for the jump states.
        /// </summary>
        public bool IsAirborne => _airborne;

        /// <summary>
        /// True while a grand backflip (crouched jump — combat.md §Focus) is in its airborne phase.
        /// Read by <see cref="PlayerAnimationDriver"/> to spin the procedural backflip and gate the
        /// GrandBackflip animator state; cleared the instant the Fool lands (handing off to the
        /// emphatic landing).
        /// </summary>
        public bool IsGrandBackflip => _grandBackflip;

        /// <summary>
        /// Normalised progress of the grand backflip's rotation, 0 at launch to 1 once the full
        /// backward turn has completed (which happens a hair before touchdown). Read by
        /// <see cref="PlayerAnimationDriver"/> to drive the majestic spin. 1 when not backflipping.
        /// </summary>
        public float GrandBackflipProgress =>
            _grandBackflip && _grandBackflipRotationTime > 0.0001f
                ? Mathf.Clamp01(_grandBackflipTime / _grandBackflipRotationTime)
                : 1f;

        /// <summary>Called by a <see cref="FoliageDrag"/> trigger when the capsule enters a short bush.</summary>
        public void EnterFoliage()
        {
            _foliageOverlaps++;
        }

        /// <summary>Called by a <see cref="FoliageDrag"/> trigger when the capsule leaves a short bush.</summary>
        public void ExitFoliage()
        {
            if (_foliageOverlaps > 0)
            {
                _foliageOverlaps--;
            }
        }

        private void Awake()
        {
            _controller = GetComponent<CharacterController>();
            _standingHeight = _controller.height;
            _standingCenter = _controller.center;

            if (_input == null)
            {
                _input = GetComponent<PlayerInputReader>();
            }

            if (_dodge == null)
            {
                _dodge = GetComponent<PlayerDodge>();
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

        private void OnEnable()
        {
            if (_input != null)
            {
                _input.CrouchPressed += OnCrouchPressed;
                _input.DodgePressed += OnDodgePressed;
            }
        }

        private void OnDisable()
        {
            if (_input != null)
            {
                _input.CrouchPressed -= OnCrouchPressed;
                _input.DodgePressed -= OnDodgePressed;
            }
        }

        // Out of Focus, the dodge input is a jump (combat.md §Focus). In Focus, PlayerDodge owns the
        // press (roll/hop/backflip) and the motor ignores it. No double-jump: grounded and not
        // already airborne, and never during a roll. Crouched + jump = the GRAND BACKFLIP.
        private void OnDodgePressed()
        {
            if (_input != null && _input.FocusHeld)
            {
                return;
            }

            bool rolling = _dodge != null && _dodge.IsDodging;
            if (_airborne || rolling || !_controller.isGrounded)
            {
                return;
            }

            if (_crouched)
            {
                BeginGrandBackflip();
            }
            else
            {
                _verticalVelocity = _jumpSpeed;
                _airborne = true;
                _airborneTime = 0f;
            }
        }

        // The grand backflip (combat.md §Focus): a taller, majestic backward flip launched from the
        // crouch. Reuses the jump's ballistic arc (apex scaled up) plus a constant backward drift so
        // the Fool travels ~1.5 body-widths back through the air; the 360° spin and the emphatic
        // landing are owned by PlayerAnimationDriver and the animator. Exits crouch on execution.
        private void BeginGrandBackflip()
        {
            SetCrouched(false);

            float g = Mathf.Abs(_gravity);
            float normalApex = (_jumpSpeed * _jumpSpeed) / (2f * g);
            float apex = normalApex * _grandBackflipApexScale;
            _verticalVelocity = Mathf.Sqrt(2f * g * apex);

            float airtime = 2f * _verticalVelocity / g;
            float backSpeed = airtime > 0.001f ? _grandBackflipBackTravel / airtime : 0f;
            _grandBackflipVelocity = -transform.forward * backSpeed;

            _airborne = true;
            _airborneTime = 0f;
            _grandBackflip = true;
            _grandBackflipTime = 0f;
        }

        private void Update()
        {
            // A dodge always stands the Fool up (dodging out of a sneak reads as a commit).
            if (_crouched && _dodge != null && _dodge.IsDodging)
            {
                SetCrouched(false);
            }

            Vector3 horizontal;
            if (_grandBackflip)
            {
                // The grand backflip owns horizontal motion while airborne: a constant backward drift.
                horizontal = _grandBackflipVelocity;
                _grandBackflipTime += Time.deltaTime;
            }
            else if (_dodge != null && _dodge.IsDodging)
            {
                horizontal = _dodge.CurrentVelocity;
            }
            else
            {
                horizontal = ComputeLocomotion();
            }

            _currentPlanarSpeed = new Vector2(horizontal.x, horizontal.z).magnitude;

            ApplyGravity();

            Vector3 velocity = horizontal;
            velocity.y = _verticalVelocity;
            _controller.Move(velocity * Time.deltaTime);
        }

        private Vector3 ComputeLocomotion()
        {
            bool focus = _input != null && _input.FocusHeld;
            bool sprinting = !focus && _input != null && _input.SprintHeld;
            if (sprinting && _crouched)
            {
                SetCrouched(false); // sprint input always stands the Fool up
            }

            Vector2 move = _input != null ? _input.MoveInput : Vector2.zero;
            Vector3 worldDir = CameraRelative(move);

            // Focus stance (combat.md §Focus, OoT Z-target grammar): the character LOCKS the facing
            // it held the instant Focus was entered and strafes camera-relative around it — no turn
            // toward the move direction, no snap to the camera. The CAMERA is what swings behind the
            // Fool (FocusStance drives the orbital axis toward this same yaw); the character never
            // chases the camera. Facing is held rigidly for the whole hold.
            if (focus)
            {
                if (!_wasFocused)
                {
                    _focusEntryYaw = transform.eulerAngles.y;
                    _turnVelocity = 0f;
                }

                transform.rotation = Quaternion.Euler(0f, _focusEntryYaw, 0f);
                _wasFocused = true;

                if (worldDir.sqrMagnitude <= MoveInputThresholdSqr)
                {
                    return Vector3.zero;
                }

                return worldDir.normalized * ClampToFoliage(_focusSpeed);
            }

            _wasFocused = false;

            if (worldDir.sqrMagnitude <= MoveInputThresholdSqr)
            {
                return Vector3.zero;
            }

            worldDir.Normalize();
            RotateToward(worldDir);

            float speed = _crouched ? _crouchSpeed : (sprinting ? _sprintSpeed : _walkSpeed);
            return worldDir * ClampToFoliage(speed);
        }

        // While standing in a short bush the walk speed is clamped to the walk tier (combat.md
        // §Focus foliage note); the roll/jump keep their own momentum, so this only touches
        // locomotion.
        private float ClampToFoliage(float speed)
        {
            return _foliageOverlaps > 0 ? Mathf.Min(speed, _foliageSpeed) : speed;
        }

        private void OnCrouchPressed()
        {
            SetCrouched(!_crouched);
        }

        // Resize the CharacterController in place, keeping its bottom where it was so a crouch
        // never pushes the capsule into (or out of) the ground.
        private void SetCrouched(bool value)
        {
            if (_crouched == value)
            {
                return;
            }

            _crouched = value;

            float bottom = _standingCenter.y - (_standingHeight * 0.5f);
            float height = value ? _standingHeight * _crouchHeightScale : _standingHeight;
            _controller.height = height;
            _controller.center = new Vector3(_standingCenter.x, bottom + (height * 0.5f), _standingCenter.z);
        }

        private void RotateToward(Vector3 worldDir)
        {
            float targetAngle = Mathf.Atan2(worldDir.x, worldDir.z) * Mathf.Rad2Deg;
            float angle = Mathf.SmoothDampAngle(
                transform.eulerAngles.y, targetAngle, ref _turnVelocity, _turnSmoothTime);
            transform.rotation = Quaternion.Euler(0f, angle, 0f);
        }

        private void ApplyGravity()
        {
            bool grounded = _controller.isGrounded;

            if (grounded && _verticalVelocity < 0f)
            {
                if (_airborne)
                {
                    OnLanded(); // landing edge — covers jumps, the grand backflip, AND walked-off falls
                }

                _verticalVelocity = _groundedStickForce;
                _airborne = false;
            }
            else
            {
                if (!grounded)
                {
                    // Off the ground for any reason (a jump, or the Cliff's real west edge walked off)
                    // counts as airborne, so the fall reads and its landing kicks up dust.
                    _airborne = true;
                    _airborneTime += Time.deltaTime;
                }

                _verticalVelocity += _gravity * Time.deltaTime;
            }
        }

        // Fired once on the frame the Fool returns to the ground. The grand backflip resolves into a
        // BIG dust ring (its emphatic finish); every other landing kicks up a small puff scaled by how
        // long the Fool was in the air (a longer fall lands harder).
        private void OnLanded()
        {
            float fallTime = _airborneTime;
            _airborneTime = 0f;

            if (_grandBackflip)
            {
                _grandBackflip = false;
                if (_dust != null)
                {
                    _dust.EmitGrandRing();
                }
            }
            else if (_dust != null)
            {
                _dust.EmitLandPuff(fallTime);
            }
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
