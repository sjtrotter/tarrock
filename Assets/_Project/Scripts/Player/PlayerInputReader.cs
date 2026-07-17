namespace Tarrock.Player
{

    using System;
    using UnityEngine;
    using UnityEngine.InputSystem;

    /// <summary>
    /// The single seam between the Input System and the rest of the player code
    /// (technical.md §Port-readiness rules 1: "All gameplay code reads from Input System
    /// actions, never raw device state ... a 'Dodge' action, not a 'spacebar'"). No other
    /// Tarrock type references <c>UnityEngine.InputSystem</c>; motor, dodge and camera all
    /// consume the plain C# surface exposed here, so re-binding or a new device backend is a
    /// change to this one class and the action asset.
    ///
    /// Reads from a serialized <see cref="InputActionAsset"/> (the project's
    /// <c>TarrockActions</c> asset), resolving actions by their stable "Map/Action" paths and
    /// enabling/disabling the Player map with the component's own lifetime.
    /// </summary>
    public sealed class PlayerInputReader : MonoBehaviour
    {
        private const string PlayerMap = "Player";
        private const string MoveActionPath = "Player/Move";
        private const string LookActionPath = "Player/Look";
        private const string SprintActionPath = "Player/Sprint";
        private const string DodgeActionPath = "Player/Dodge";
        private const string CrouchActionPath = "Player/Crouch";
        private const string FocusActionPath = "Player/Focus";

        [SerializeField] private InputActionAsset _actions;

        private InputAction _moveAction;
        private InputAction _lookAction;
        private InputAction _sprintAction;
        private InputAction _dodgeAction;
        private InputAction _crouchAction;
        private InputAction _focusAction;
        private bool _resolved;

        /// <summary>Raised once each time the Dodge action is performed (a discrete press).</summary>
        public event Action DodgePressed;

        /// <summary>Raised once each time the Crouch action is performed (a discrete press; the crouch itself toggles).</summary>
        public event Action CrouchPressed;

        /// <summary>Current movement stick / WASD vector, range roughly [-1, 1] per axis.</summary>
        public Vector2 MoveInput => _moveAction != null ? _moveAction.ReadValue<Vector2>() : Vector2.zero;

        /// <summary>Current look delta (mouse delta or right-stick), consumed by the camera rig.</summary>
        public Vector2 LookInput => _lookAction != null ? _lookAction.ReadValue<Vector2>() : Vector2.zero;

        /// <summary>True while the Sprint action is held.</summary>
        public bool SprintHeld => _sprintAction != null && _sprintAction.IsPressed();

        /// <summary>
        /// True while the Focus action is held (RMB / left trigger). Focus is the combat stance
        /// (combat.md §Focus): the Fool drops to a ready-crouch, movement becomes camera-relative
        /// strafing, and the dodge input becomes directional. Out of Focus the same dodge input is a
        /// jump. Read by the motor, dodge and camera stance.
        /// </summary>
        public bool FocusHeld => _focusAction != null && _focusAction.IsPressed();

        private void Awake()
        {
            ResolveActions();
        }

        private void OnEnable()
        {
            ResolveActions();

            if (_dodgeAction != null)
            {
                _dodgeAction.performed += OnDodgePerformed;
            }

            if (_crouchAction != null)
            {
                _crouchAction.performed += OnCrouchPerformed;
            }

            _actions?.FindActionMap(PlayerMap, throwIfNotFound: false)?.Enable();
        }

        private void OnDisable()
        {
            if (_dodgeAction != null)
            {
                _dodgeAction.performed -= OnDodgePerformed;
            }

            if (_crouchAction != null)
            {
                _crouchAction.performed -= OnCrouchPerformed;
            }

            _actions?.FindActionMap(PlayerMap, throwIfNotFound: false)?.Disable();
        }

        private void ResolveActions()
        {
            if (_resolved)
            {
                return;
            }

            if (_actions == null)
            {
                Debug.LogError(
                    "[Tarrock] PlayerInputReader has no InputActionAsset assigned; input will be inert. " +
                    "Wire the TarrockActions asset (Tarrock/Setup/Install Player Rig In Cliff Scene does this).",
                    this);
                return;
            }

            _moveAction = _actions.FindAction(MoveActionPath, throwIfNotFound: false);
            _lookAction = _actions.FindAction(LookActionPath, throwIfNotFound: false);
            _sprintAction = _actions.FindAction(SprintActionPath, throwIfNotFound: false);
            _dodgeAction = _actions.FindAction(DodgeActionPath, throwIfNotFound: false);
            _crouchAction = _actions.FindAction(CrouchActionPath, throwIfNotFound: false);
            _focusAction = _actions.FindAction(FocusActionPath, throwIfNotFound: false);
            _resolved = true;
        }

        private void OnDodgePerformed(InputAction.CallbackContext context)
        {
            DodgePressed?.Invoke();
        }

        private void OnCrouchPerformed(InputAction.CallbackContext context)
        {
            CrouchPressed?.Invoke();
        }
    }
}
