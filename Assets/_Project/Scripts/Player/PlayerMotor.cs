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
        [SerializeField] private float _walkSpeed = 4.5f;
        [SerializeField] private float _sprintSpeed = 7f;

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

        /// <summary>
        /// The Fool's current planar (XZ) speed in metres/second — the actual movement applied
        /// this frame, whether from locomotion or a roll. Read by <see cref="PlayerAnimationDriver"/>
        /// to drive the locomotion blend; zero while standing still.
        /// </summary>
        public float CurrentPlanarSpeed => _currentPlanarSpeed;

        private void Awake()
        {
            _controller = GetComponent<CharacterController>();

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

        private void Update()
        {
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
            Vector2 move = _input != null ? _input.MoveInput : Vector2.zero;
            Vector3 worldDir = CameraRelative(move);

            if (worldDir.sqrMagnitude <= MoveInputThresholdSqr)
            {
                return Vector3.zero;
            }

            worldDir.Normalize();
            RotateToward(worldDir);

            bool sprinting = _input != null && _input.SprintHeld;
            float speed = sprinting ? _sprintSpeed : _walkSpeed;
            return worldDir * speed;
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
