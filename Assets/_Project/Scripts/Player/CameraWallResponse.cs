namespace Tarrock.Player
{

    using Unity.Cinemachine;
    using UnityEngine;

    /// <summary>
    /// Staged camera response when the Fool backs into a wall — REPLACES the old up-and-over
    /// <c>CameraOcclusionLift</c>, which drove the orbit's vertical axis toward an overhead
    /// "look down at the boots" pose (director round 10: "never overhead, never feet"). This
    /// component NEVER touches pitch / the vertical axis. Its only outputs are:
    ///
    /// <list type="bullet">
    /// <item><b>Stage 0 — whisker pre-emption</b>: side spherecasts from the pivot detect a wall
    /// the camera is about to be shoved into and gently bias the orbital <em>horizontal</em> axis
    /// away from it (≤ <see cref="_maxYawBiasRate"/>°/s, damped), but only while the Fool is moving
    /// and the player is not actively swinging the camera (yields to look input and to Focus).</item>
    /// <item><b>Stage 2 — framing shift</b>: as the live camera-to-pivot distance drops from
    /// <see cref="_framingFarDistance"/> to <see cref="_framingNearDistance"/>, the tracking pivot
    /// (<see cref="CinemachineOrbitalFollow.TargetOffset"/> Y) lerps from its resting height up to
    /// head-top so a close camera frames head-and-shoulders instead of the feet. Eased both ways.</item>
    /// <item><b>Stage 3 — fade</b>: from <see cref="_fadeStartDistance"/> down to
    /// <see cref="_fadeEndDistance"/> the character visual is faded out via <see cref="CharacterFade"/>
    /// so a camera pinned against the wall never fills the frame with the Fool's back.</item>
    /// </list>
    ///
    /// Distance is read LIVE from the Cinemachine state each frame (post-deoccluder), so the framing
    /// and fade track where the camera actually is, not the nominal orbit radius. The distance
    /// clamp (occluders nearer than 1 m ignored) and the "can't sit inside a wall" guard are owned by
    /// the <see cref="CinemachineDeoccluder"/> / <see cref="CinemachineDecollider"/> on the rig; this
    /// component only reads the resulting distance.
    /// </summary>
    public sealed class CameraWallResponse : MonoBehaviour
    {
        [SerializeField] private CinemachineOrbitalFollow _orbital;
        [SerializeField] private CinemachineRotationComposer _composer;
        [SerializeField] private CinemachineCamera _vcam;
        [SerializeField] private Transform _player;
        [SerializeField] private PlayerInputReader _input;
        [SerializeField] private PlayerMotor _motor;
        [SerializeField] private CharacterFade _fade;

        [Header("Stage 0 — whisker pre-emption")]
        [Tooltip("Layers the side whiskers treat as walls (terrain/rampart/rock). Foliage on the CameraTransparent layer is deliberately excluded so grass/trees never bias the camera.")]
        [SerializeField] private LayerMask _whiskerMask = 1;

        [Tooltip("Yaw offsets (deg) either side of the camera line at which the side whiskers are cast (mirrored ±). Director spec: 25 and 50.")]
        [SerializeField] private float[] _whiskerAngles = { 25f, 50f };

        [Tooltip("Radius (m) of each whisker spherecast.")]
        [SerializeField] private float _whiskerRadius = 0.1f;

        [Tooltip("Maximum rate (deg/s) at which a whisker hit biases the orbital horizontal axis away from the wall.")]
        [SerializeField] private float _maxYawBiasRate = 30f;

        [Tooltip("Approx. seconds to ease the yaw-bias rate in/out so the nudge never snaps.")]
        [SerializeField] private float _biasDamp = 0.25f;

        [Tooltip("Planar speed (m/s) above which the Fool counts as 'moving' for the whisker gate.")]
        [SerializeField] private float _moveSpeedThreshold = 0.1f;

        [Tooltip("Look-input magnitude at/above which the whisker yields (the player is actively swinging the camera).")]
        [SerializeField] private float _lookYieldThreshold = 0.5f;

        [Header("Stage 2 — framing shift (head-and-shoulders as the camera closes)")]
        [Tooltip("Camera-to-pivot distance (m) at which the framing shift begins (aim still at its resting point).")]
        [SerializeField] private float _framingFarDistance = 1.6f;

        [Tooltip("Camera-to-pivot distance (m) at which the framing shift is complete (aim fully at head height).")]
        [SerializeField] private float _framingNearDistance = 1.0f;

        [Tooltip("Aim height (world m above the Fool's feet) the RotationComposer lifts to when the camera is close, so a close camera frames head-and-shoulders instead of the feet — head/neck at H=0.7m scale (~0.55). The resting aim offset is captured from the rig at start.")]
        [SerializeField] private float _headAimHeight = 0.55f;

        [Tooltip("Approx. seconds to ease the aim toward its target height (both directions).")]
        [SerializeField] private float _framingDamp = 0.2f;

        [Header("Stage 3 — character fade")]
        [Tooltip("Camera-to-pivot distance (m) at which the fade begins (fully opaque at/above this).")]
        [SerializeField] private float _fadeStartDistance = 1.0f;

        [Tooltip("Camera-to-pivot distance (m) at which the character is fully faded out.")]
        [SerializeField] private float _fadeEndDistance = 0.5f;

        [Tooltip("Hard floor (m): the character stays fully faded below this — documents the closest the camera should ever sit (the deoccluder/decollider enforce the physical clamp).")]
        [SerializeField] private float _hardFloorDistance = 0.45f;

        private float _baseAimY;
        private float _currentAimY;
        private bool _haveBase;
        private float _aimVelocity;
        private float _biasRate;
        private float _biasRateVelocity;

        private void Update()
        {
            if (_orbital == null || _player == null)
            {
                return;
            }

            if (!_haveBase)
            {
                _baseAimY = _composer != null ? _composer.TargetOffset.y : 0f;
                _currentAimY = _baseAimY;
                _haveBase = true;
            }

            float distance = CurrentCameraDistance();

            ApplyWhiskerBias(distance);
            ApplyFramingShift(distance);
            ApplyFade(distance);
        }

        // Live camera-to-pivot distance, read from the post-deoccluder Cinemachine state so it tracks
        // where the camera actually sits (not the nominal orbit radius). Falls back to the nominal
        // radius if the vcam state is unavailable.
        private float CurrentCameraDistance()
        {
            Vector3 pivot = _player.position + (Vector3.up * _orbital.TargetOffset.y);
            if (_vcam != null)
            {
                return Vector3.Distance(_vcam.State.GetCorrectedPosition(), pivot);
            }

            return _orbital.Radius;
        }

        // Stage 0: cast mirrored side whiskers along the camera line; when one side is blocked (and the
        // Fool is moving and the player is not swinging the camera or focusing) ease the horizontal axis
        // away from the more-occluded side. Never touches the vertical axis.
        private void ApplyWhiskerBias(float distance)
        {
            float desiredRate = 0f;

            bool moving = _motor != null && _motor.CurrentPlanarSpeed > _moveSpeedThreshold;
            bool lookIdle = _input == null || _input.LookInput.magnitude < _lookYieldThreshold;
            bool focusing = _input != null && _input.FocusHeld;

            if (moving && lookIdle && !focusing && _whiskerAngles != null && _whiskerAngles.Length > 0)
            {
                float pivotY = _orbital.TargetOffset.y;
                Vector3 pivot = _player.position + (Vector3.up * pivotY);
                float vert = _orbital.VerticalAxis.Value;
                float horiz = _orbital.HorizontalAxis.Value;
                float length = Mathf.Max(0.1f, distance);

                float rightWeight = 0f;
                float leftWeight = 0f;
                foreach (float angle in _whiskerAngles)
                {
                    if (WhiskerHits(pivot, vert, horiz + angle, length))
                    {
                        rightWeight += 1f;
                    }

                    if (WhiskerHits(pivot, vert, horiz - angle, length))
                    {
                        leftWeight += 1f;
                    }
                }

                float net = rightWeight - leftWeight; // > 0: the +angle side is more blocked
                if (Mathf.Abs(net) > 0.001f)
                {
                    // Bias the yaw toward the OPEN side (away from the more-occluded whiskers).
                    float magnitude = Mathf.Min(1f, Mathf.Abs(net) / _whiskerAngles.Length);
                    desiredRate = -Mathf.Sign(net) * magnitude * _maxYawBiasRate;
                }
            }

            _biasRate = Mathf.SmoothDamp(_biasRate, desiredRate, ref _biasRateVelocity, _biasDamp);
            if (Mathf.Abs(_biasRate) > 0.0001f)
            {
                _orbital.HorizontalAxis.Value += _biasRate * Time.deltaTime;
            }
        }

        private bool WhiskerHits(Vector3 pivot, float vert, float yaw, float length)
        {
            Vector3 dir = Quaternion.Euler(vert, yaw, 0f) * Vector3.back;
            return Physics.SphereCast(
                pivot, _whiskerRadius, dir, out _, length, _whiskerMask, QueryTriggerInteraction.Ignore);
        }

        // Stage 2: lift the RotationComposer's AIM point from its resting height (feet-ish) toward head
        // height as the camera closes, so a wall-pinned camera tilts up to frame head-and-shoulders
        // rather than looking down at the feet. Drives the composer aim — NOT the orbit centre — because
        // the composer frames the LookAt target, so raising the orbit centre alone would crop the head
        // above the frame. Eased both ways. Does nothing if no composer is wired.
        private void ApplyFramingShift(float distance)
        {
            if (_composer == null)
            {
                return;
            }

            float t = Mathf.Clamp01(Mathf.InverseLerp(_framingFarDistance, _framingNearDistance, distance));
            float targetAimY = Mathf.Lerp(_baseAimY, _headAimHeight, t);
            _currentAimY = Mathf.SmoothDamp(_currentAimY, targetAimY, ref _aimVelocity, _framingDamp);

            Vector3 offset = _composer.TargetOffset;
            offset.y = _currentAimY;
            _composer.TargetOffset = offset;
        }

        // Stage 3: fade the character out as the camera pushes past the fade band, so it never fills
        // the frame with the Fool's back. Fully faded below the hard floor.
        private void ApplyFade(float distance)
        {
            if (_fade == null)
            {
                return;
            }

            float clamped = Mathf.Max(distance, _hardFloorDistance);
            float alpha = Mathf.Clamp01(Mathf.InverseLerp(_fadeEndDistance, _fadeStartDistance, clamped));
            _fade.SetAlpha(alpha);
        }
    }
}
