namespace Tarrock.Player
{

    using Unity.Cinemachine;
    using UnityEngine;

    /// <summary>
    /// Quiet, once-per-save camera presentation of MQ00's dead tree from the west shelf. A region
    /// trigger asks this component to begin; it eases the existing orbit/composer toward the marker,
    /// holds, and restores the player's pose. Any look input cancels immediately.
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class ShelfRevealCameraNudge : MonoBehaviour
    {
        // This is authoring data shared with GauntletCapture's v10 builder. Round 10/11 geometry and
        // the shipped v9 pixels agree that aiming 3 m above the dead-tree marker puts the nearest
        // crown tip 2.5° (about 56 px at 1080p/55° rectilinear vertical FOV) inside the top edge.
        public const float AuthoredApexTargetLift = 3f;

        [SerializeField] private CinemachineOrbitalFollow _orbital;
        [SerializeField] private CinemachineRotationComposer _composer;
        [SerializeField] private PlayerInputReader _input;
        [SerializeField] private Transform _player;
        [SerializeField] private Transform _deadTreeMarker;

        [Header("Quiet reveal timing")]
        [Tooltip("Seconds to drift from the player's current pose to the tree presentation.")]
        [SerializeField] private float _driftDuration = 2f;
        [Tooltip("Seconds the tree presentation rests before returning control.")]
        [SerializeField] private float _holdDuration = 0.75f;
        [Tooltip("Seconds to ease back to the pose present at trigger entry.")]
        [SerializeField] private float _returnDuration = 0.45f;
        [Tooltip("Look-input magnitude that immediately dismisses the presentation.")]
        [SerializeField] private float _lookReleaseThreshold = 0.05f;

        [Header("Apex pose")]
        [Tooltip("Aim height in metres above the MQ00 dead-tree marker. Measured v9 solution: 3 m.")]
        [SerializeField] private float _apexTargetLift = AuthoredApexTargetLift;

        private ShelfRevealState _state;
        private float _entryHorizontal;
        private Vector3 _entryTargetOffset;
        private float _apexHorizontal;
        private Vector3 _apexTargetOffset;
        private Vector3 _apexWorldAim;

        public bool HasPlayed => State.HasPlayed;

        public ShelfRevealSaveData CaptureState() => State.Capture();

        public void RestoreState(ShelfRevealSaveData data) => State.Restore(data);

        public bool TryBeginReveal()
        {
            if (_orbital == null || _composer == null || _player == null || _deadTreeMarker == null)
            {
                return false;
            }

            if (!State.TryStart())
            {
                return false;
            }

            _entryHorizontal = _orbital.HorizontalAxis.Value;
            _entryTargetOffset = _composer.TargetOffset;

            _apexWorldAim = _deadTreeMarker.position + (Vector3.up * _apexTargetLift);
            Vector3 planar = _apexWorldAim - _player.position;
            _apexHorizontal = Mathf.Atan2(planar.x, planar.z) * Mathf.Rad2Deg;
            _apexTargetOffset = _player.InverseTransformPoint(_apexWorldAim);
            return true;
        }

        private ShelfRevealState State => _state ??= new ShelfRevealState(
            _driftDuration, _holdDuration, _returnDuration);

        private void Update()
        {
            if (!State.IsActive)
            {
                return;
            }

            if (_input != null && _input.LookInput.magnitude >= _lookReleaseThreshold)
            {
                State.ReleaseForLookInput();
                _orbital.HorizontalAxis.Value = _entryHorizontal;
                _composer.TargetOffset = _entryTargetOffset;
                return;
            }

            State.Tick(Time.deltaTime);
            float weight = State.RevealWeight;
            // Composer offsets are player-local while orbital yaw is world-space. Re-resolve the
            // fixed world aim each frame so turning or moving cannot split the channels.
            Vector3 planar = _apexWorldAim - _player.position;
            _apexHorizontal = Mathf.Atan2(planar.x, planar.z) * Mathf.Rad2Deg;
            _apexTargetOffset = _player.InverseTransformPoint(_apexWorldAim);
            _orbital.HorizontalAxis.Value = Mathf.LerpAngle(_entryHorizontal, _apexHorizontal, weight);
            _composer.TargetOffset = Vector3.Lerp(_entryTargetOffset, _apexTargetOffset, weight);
        }
    }
}
