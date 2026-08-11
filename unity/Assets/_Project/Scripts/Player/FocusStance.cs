namespace Tarrock.Player
{

    using Unity.Cinemachine;
    using UnityEngine;

    /// <summary>
    /// Camera side of the Focus stance (combat.md §Focus: "the camera squares up behind"). While
    /// the Focus input is held this:
    ///
    /// - <b>Swings behind the Fool</b> — damps the orbital rig's world-locked horizontal axis toward
    ///   the character's heading so the camera settles directly behind (OoT Z-target style: the
    ///   camera moves, not the character). It yields to active mouse/stick look (recentres only when
    ///   the look input is idle), so the player can still glance around in-stance; on release it
    ///   simply stops steering the axis. The motor holds the character's facing locked at focus-entry
    ///   (PlayerMotor §Focus), so this axis drive has a stable target to settle onto (no fight).
    /// - <b>Tightens the FOV</b> by <see cref="_focusFovDelta"/> (a slight zoom-in), damped both ways.
    ///
    /// Kept deliberately small and serialized — no lock-on target logic here (no enemies in the
    /// Cliff greybox yet); that arrives with the combat milestone.
    /// </summary>
    public sealed class FocusStance : MonoBehaviour
    {
        [SerializeField] private PlayerInputReader _input;
        [SerializeField] private Transform _player;
        [SerializeField] private CinemachineCamera _vcam;
        [SerializeField] private CinemachineOrbitalFollow _orbital;

        [Tooltip("Keep the camera damped behind the Fool while focused (yields to active look input).")]
        [SerializeField] private bool _holdBehind = true;

        [Tooltip("Approx. seconds to settle the camera behind the Fool while focused.")]
        [SerializeField] private float _recenterDampTime = 0.25f;

        [Tooltip("Look-input magnitude above which the behind-hold yields to the player's own look.")]
        [SerializeField] private float _lookYieldThreshold = 0.5f;

        [Tooltip("FOV offset applied while focused (negative = slight zoom-in). combat.md marks this optional.")]
        [SerializeField] private float _focusFovDelta = -4f;

        [Tooltip("Approx. seconds to settle the FOV toward its focused/normal target.")]
        [SerializeField] private float _fovDampTime = 0.15f;

        private float _baseFov;
        private bool _haveBase;
        private float _fovVelocity;
        private float _axisVelocity;

        private void Update()
        {
            if (_vcam == null)
            {
                return;
            }

            if (!_haveBase)
            {
                _baseFov = _vcam.Lens.FieldOfView;
                _haveBase = true;
            }

            bool focus = _input != null && _input.FocusHeld;

            float targetFov = focus ? _baseFov + _focusFovDelta : _baseFov;
            _vcam.Lens.FieldOfView = Mathf.SmoothDamp(
                _vcam.Lens.FieldOfView, targetFov, ref _fovVelocity, _fovDampTime);

            if (!focus || !_holdBehind || _orbital == null || _player == null)
            {
                return;
            }

            // Yield to the player's own look; otherwise ease the world-locked orbit behind the Fool.
            if (_input.LookInput.magnitude >= _lookYieldThreshold)
            {
                return;
            }

            float current = _orbital.HorizontalAxis.Value;
            float behind = _player.eulerAngles.y;
            _orbital.HorizontalAxis.Value = Mathf.SmoothDampAngle(
                current, behind, ref _axisVelocity, _recenterDampTime);
        }
    }
}
