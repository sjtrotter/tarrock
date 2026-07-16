namespace Tarrock.Player
{

    using UnityEngine;

    /// <summary>
    /// Third-person locomotion for the Fool (combat.md §Philosophy: "readable and deliberate"
    /// movement). Camera-relative walk/sprint on a <see cref="CharacterController"/>, with smooth
    /// rotation toward the move direction and simple gravity + grounded handling so the Cliff's
    /// real west edge (CliffGreyboxGenerator: "the ground simply stops — no wall") can actually
    /// be walked off. There is no jump this phase — combat.md's kit has none, and the block-step
    /// hop arrives with the combat milestone.
    ///
    /// This is the single owner of <see cref="CharacterController.Move"/>. During a roll it hands
    /// horizontal control to <see cref="PlayerDodge"/> (reading its velocity) while still applying
    /// gravity, so the two never issue competing moves.
    /// </summary>
    [RequireComponent(typeof(CharacterController))]
    public sealed class PlayerMotor : MonoBehaviour
    {
        private const float MoveInputThresholdSqr = 0.01f;

        [SerializeField] private PlayerInputReader _input;
        [SerializeField] private PlayerDodge _dodge;
        [SerializeField] private Transform _cameraTransform;

        [Header("Speeds (m/s)")]
        // Director retune for the 0.7m miniature (sandbox playtest): the default gait is a travel
        // JOG (Running_A in the animator), not a walk; Shift held = sprint. The serialized field
        // name stays "_walkSpeed" so older scenes keep their own tuned values.
        [SerializeField] private float _walkSpeed = 3.0f; // default gait: travel jog
        [SerializeField] private float _sprintSpeed = 4.8f;

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
            }
        }

        private void OnDisable()
        {
            if (_input != null)
            {
                _input.CrouchPressed -= OnCrouchPressed;
            }
        }

        private void Update()
        {
            // A dodge always stands the Fool up (dodging out of a sneak reads as a commit).
            if (_crouched && _dodge != null && _dodge.IsDodging)
            {
                SetCrouched(false);
            }

            Vector3 horizontal = (_dodge != null && _dodge.IsDodging)
                ? _dodge.CurrentVelocity
                : ComputeLocomotion();

            _currentPlanarSpeed = new Vector2(horizontal.x, horizontal.z).magnitude;

            ApplyGravity();

            Vector3 velocity = horizontal;
            velocity.y = _verticalVelocity;
            _controller.Move(velocity * Time.deltaTime);
        }

        private Vector3 ComputeLocomotion()
        {
            bool sprinting = _input != null && _input.SprintHeld;
            if (sprinting && _crouched)
            {
                SetCrouched(false); // sprint input always stands the Fool up
            }

            Vector2 move = _input != null ? _input.MoveInput : Vector2.zero;
            Vector3 worldDir = CameraRelative(move);

            if (worldDir.sqrMagnitude <= MoveInputThresholdSqr)
            {
                return Vector3.zero;
            }

            worldDir.Normalize();
            RotateToward(worldDir);

            float speed = _crouched ? _crouchSpeed : (sprinting ? _sprintSpeed : _walkSpeed);
            return worldDir * speed;
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
            if (_controller.isGrounded && _verticalVelocity < 0f)
            {
                _verticalVelocity = _groundedStickForce;
            }
            else
            {
                _verticalVelocity += _gravity * Time.deltaTime;
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
