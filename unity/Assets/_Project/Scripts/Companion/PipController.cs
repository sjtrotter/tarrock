namespace Tarrock.Companion
{

    using System;
    using UnityEngine;

    /// <summary>
    /// Pip's steering-follow companion controller (characters.md §Pip — the white dog who is
    /// "entirely present ... the story's steady hand"). Deliberately <b>NavMesh-free</b>: Pip is a
    /// <see cref="CharacterController"/> that chases a breadcrumb trail of the Fool's grounded
    /// positions (<see cref="PipBreadcrumbTrail"/>), so he follows the Fool's actual route rather
    /// than cutting corners through it.
    ///
    /// Loosely coupled to the player on purpose: the only link is a <see cref="Transform"/> follow
    /// target (wired by the installer), so this assembly never depends on Tarrock.Player. It is also
    /// combat-free — the command wheel (combat.md §Pip: Fetch/Harry) lives elsewhere; this owns only
    /// the follow/traversal state machine.
    ///
    /// State machine (<see cref="PipState"/>): <b>Heel</b> follows the trail a settled distance
    /// behind with a lateral offset so Pip pads along <i>beside</i> the Fool; <b>RangeAhead</b>
    /// wanders near the Fool once he stands idle in a safe space, snapping back to Heel the moment
    /// he moves; <b>Seek</b> paths straight to a point with a single sphere-cast obstacle nudge and
    /// raises <see cref="StateCompleted"/> on arrival; <b>Dig</b>/<b>Sit</b> park on a spot and hold
    /// (the animator plays the beat); <b>Retreat</b> is a reserved stub. Every transition runs
    /// through <see cref="SetState"/> and raises <see cref="StateChanged"/>.
    ///
    /// All feel values are <c>[SerializeField]</c> so the director tunes them in the inspector,
    /// mirroring PlayerMotor's convention. Tuned against the 0.7 m game-piece miniature
    /// (art-audio.md §Current build scale contract).
    /// </summary>
    [RequireComponent(typeof(CharacterController))]
    public sealed class PipController : MonoBehaviour
    {
        private const float MoveThresholdSqr = 0.0004f;

        [Header("Follow target (the Fool — wired by the installer, kept loose via Transform)")]
        [SerializeField] private Transform _followTarget;

        [Header("Breadcrumb trail")]
        [Tooltip("A crumb of the Fool's grounded position is dropped each time he moves this far (m).")]
        [SerializeField] private float _crumbSpacing = 0.35f;
        [Tooltip("Ring-buffer size. Trail length ≈ capacity × spacing — long enough to cover the teleport distance and then some.")]
        [SerializeField] private int _crumbCapacity = 64;

        [Header("Heel (default follow)")]
        [Tooltip("How far back along the Fool's trail Pip aims to sit (m).")]
        [SerializeField] private float _heelDistance = 1.0f;
        [Tooltip("Lateral offset from the trail toward the Fool's side, so Pip settles BESIDE not into him (m).")]
        [SerializeField] private float _heelLateralOffset = 0.4f;
        [Tooltip("Within this distance of the heel spot Pip is considered arrived and eases to a stop (m).")]
        [SerializeField] private float _arrivalRadius = 0.2f;
        [Tooltip("Distance band over which speed damps to zero on arrival, so he settles rather than jitters (m).")]
        [SerializeField] private float _arrivalDampBand = 0.6f;

        [Header("Speed bands (distance-matched gait, m/s)")]
        [Tooltip("Gentle walk used when Pip is essentially in position.")]
        [SerializeField] private float _walkSpeed = 2.0f;
        [Tooltip("Travel trot used at a moderate lag.")]
        [SerializeField] private float _trotSpeed = 3.2f;
        [Tooltip("Sprint used to close a large gap (a touch above the Fool's sprint so he can catch up).")]
        [SerializeField] private float _sprintSpeed = 5.2f;
        [Tooltip("At or below this lag Pip walks; above it he trots (m).")]
        [SerializeField] private float _trotDistance = 1.4f;
        [Tooltip("At or above this lag Pip sprints (m).")]
        [SerializeField] private float _sprintDistance = 2.8f;

        [Header("Turning")]
        [Tooltip("Approximate time, in seconds, to settle a turn toward the move direction.")]
        [SerializeField] private float _turnSmoothTime = 0.1f;

        [Header("Gravity")]
        [SerializeField] private float _gravity = -25f;
        [Tooltip("Small downward pull kept while grounded so isGrounded stays reliable on slopes.")]
        [SerializeField] private float _groundedStickForce = -3f;

        [Header("Teleport catch-up")]
        [Tooltip("If Pip falls further than this from the Fool he is snapped to the heel spot (m). TODO: skip when camera-visible.")]
        [SerializeField] private float _teleportDistance = 8f;

        [Header("RangeAhead (loose exploratory lead)")]
        [Tooltip("Seconds the Fool must stand idle before Pip drifts into a RangeAhead wander.")]
        [SerializeField] private float _idleSecondsToRange = 4f;
        [Tooltip("Planar speed (m/s) below which the Fool counts as idle for RangeAhead.")]
        [SerializeField] private float _idleSpeedThreshold = 0.2f;
        [Tooltip("Radius around the Fool within which RangeAhead wander points are sampled (m).")]
        [SerializeField] private float _rangeRadius = 3f;
        [Tooltip("Seconds before a reached (or unreachable) wander point is abandoned for a new one.")]
        [SerializeField] private float _rangeRepathSeconds = 2.5f;
        [Tooltip("Arrival radius for a RangeAhead wander point (m).")]
        [SerializeField] private float _rangeArrivalRadius = 0.4f;
        [Tooltip("Layers treated as ground when sampling a wander point / seek marker.")]
        [SerializeField] private LayerMask _groundMask = ~0;

        [Header("Seek (path to a point with a single obstacle nudge)")]
        [Tooltip("Arrival radius at a Seek/Dig target (m).")]
        [SerializeField] private float _seekArrivalRadius = 0.35f;
        [Tooltip("Forward sphere-cast probe distance for the obstacle nudge (m).")]
        [SerializeField] private float _obstacleProbeDistance = 0.8f;
        [Tooltip("Forward sphere-cast probe radius for the obstacle nudge (m).")]
        [SerializeField] private float _obstacleProbeRadius = 0.2f;
        [Tooltip("Height above Pip's feet the probe is cast from (m).")]
        [SerializeField] private float _obstacleProbeHeight = 0.2f;
        [Tooltip("How hard the nudge steers Pip around a blocked path (0 = none, 1 = a full perpendicular blend).")]
        [SerializeField] private float _obstacleSteer = 1f;
        [Tooltip("Layers the obstacle nudge sphere-cast tests against.")]
        [SerializeField] private LayerMask _obstacleMask = ~0;

        private CharacterController _controller;
        private PipBreadcrumbTrail _trail;
        private PipState _state = PipState.Heel;

        private float _verticalVelocity;
        private float _turnVelocity;
        private float _currentPlanarSpeed;

        private Vector3 _lastFollowPosition;
        private bool _hasLastFollow;
        private float _followIdleTime;

        private Vector3 _actionTarget;
        private bool _hasActionTarget;
        private Vector3 _wanderTarget;
        private float _wanderTimer;

        /// <summary>Fired whenever the state changes, carrying the new state. Installers/UI subscribe.</summary>
        public event Action<PipState> StateChanged;

        /// <summary>
        /// Fired when a goal-directed state finishes its job — a Seek reaches its point, a Dig arrives
        /// at its marker — carrying the state that completed. Consumers (quests, the command wheel)
        /// react to it; the controller itself falls back to <see cref="PipState.Heel"/>.
        /// </summary>
        public event Action<PipState> StateCompleted;

        /// <summary>The state Pip is currently in.</summary>
        public PipState CurrentState => _state;

        /// <summary>
        /// Pip's current planar (XZ) speed in metres/second — read by <see cref="PipAnimatorLink"/>
        /// to drive the locomotion blend. Zero while parked (Sit/Dig/Retreat) or settled at heel.
        /// </summary>
        public float CurrentPlanarSpeed => _currentPlanarSpeed;

        /// <summary>The Fool's transform Pip is following, if wired.</summary>
        public Transform FollowTarget
        {
            get => _followTarget;
            set => _followTarget = value;
        }

        // ---------------------------------------------------------------------------------
        // Public command API (the command wheel / quests drive Pip through these).
        // ---------------------------------------------------------------------------------

        /// <summary>Returns Pip to the default follow behaviour.</summary>
        public void Heel()
        {
            _hasActionTarget = false;
            SetState(PipState.Heel);
        }

        /// <summary>Sends Pip to <paramref name="target"/>, nudging around obstacles; raises
        /// <see cref="StateCompleted"/> on arrival (combat.md §Pip — Seek).</summary>
        public void Seek(Vector3 target)
        {
            _actionTarget = target;
            _hasActionTarget = true;
            SetState(PipState.Seek);
        }

        /// <summary>Sends Pip to <paramref name="marker"/> and, once there, holds while the dig plays.</summary>
        public void Dig(Vector3 marker)
        {
            _actionTarget = marker;
            _hasActionTarget = true;
            SetState(PipState.Dig);
        }

        /// <summary>Digs where Pip already stands (no travel).</summary>
        public void Dig()
        {
            _hasActionTarget = false;
            SetState(PipState.Dig);
        }

        /// <summary>Sits Pip on the spot to hold.</summary>
        public void Sit()
        {
            _hasActionTarget = false;
            SetState(PipState.Sit);
        }

        /// <summary>Reserved: the combat retreat/yelp beat (combat.md §Pip). Currently just holds.</summary>
        public void Retreat()
        {
            _hasActionTarget = false;
            SetState(PipState.Retreat);
        }

        // ---------------------------------------------------------------------------------

        private void Awake()
        {
            _controller = GetComponent<CharacterController>();
            _trail = new PipBreadcrumbTrail(_crumbCapacity, _crumbSpacing);
        }

        private void Update()
        {
            float dt = Time.deltaTime;

            if (_followTarget == null)
            {
                // No leash yet: hold position, but keep gravity so Pip rests on the ground.
                _currentPlanarSpeed = 0f;
                MoveWithGravity(Vector3.zero, dt);
                return;
            }

            UpdateFollowKinematics(dt);
            MaybeAutoRange();
            MaybeTeleport();

            Vector3 horizontal = ComputeStateVelocity(dt);
            _currentPlanarSpeed = new Vector2(horizontal.x, horizontal.z).magnitude;

            MoveWithGravity(horizontal, dt);
        }

        // Drop a crumb at the Fool's grounded position, and track how long he has stood still so
        // RangeAhead knows when to kick in.
        private void UpdateFollowKinematics(float dt)
        {
            Vector3 followPosition = _followTarget.position;
            _trail.TryDrop(followPosition);

            if (_hasLastFollow && dt > 0f)
            {
                Vector3 delta = followPosition - _lastFollowPosition;
                delta.y = 0f;
                float followSpeed = delta.magnitude / dt;
                if (followSpeed > _idleSpeedThreshold)
                {
                    _followIdleTime = 0f;
                }
                else
                {
                    _followIdleTime += dt;
                }
            }

            _lastFollowPosition = followPosition;
            _hasLastFollow = true;
        }

        // Enter RangeAhead after the Fool has been idle long enough in a safe space; leave it the
        // instant he moves again. (Safety is always-true for now — combat has no hook here yet: TODO.)
        private void MaybeAutoRange()
        {
            if (_state == PipState.Heel && _followIdleTime >= _idleSecondsToRange)
            {
                PickWanderTarget();
                SetState(PipState.RangeAhead);
            }
            else if (_state == PipState.RangeAhead && _followIdleTime < _idleSecondsToRange)
            {
                SetState(PipState.Heel);
            }
        }

        // TODO: also require the respawn crumb to be off-camera before snapping (visibility nicety).
        private void MaybeTeleport()
        {
            if (_state != PipState.Heel && _state != PipState.RangeAhead)
            {
                return;
            }

            Vector3 flat = _followTarget.position - transform.position;
            flat.y = 0f;
            if (flat.magnitude <= _teleportDistance)
            {
                return;
            }

            Vector3 respawn = _trail.TryGetHeelTarget(_heelDistance, out Vector3 heel)
                ? heel + HeelLateral()
                : _followTarget.position;

            TeleportTo(respawn);

            // Re-seed the trail from the Fool's current spot so Pip doesn't re-walk the stale path.
            _trail.Clear();
            _trail.TryDrop(_followTarget.position);
        }

        private Vector3 ComputeStateVelocity(float dt)
        {
            switch (_state)
            {
                case PipState.Heel:
                    return ComputeHeel();
                case PipState.RangeAhead:
                    return ComputeRangeAhead(dt);
                case PipState.Seek:
                    return ComputeSeek();
                case PipState.Dig:
                    return ComputeParkAtTarget();
                case PipState.Sit:
                case PipState.Retreat: // reserved stub — hold in place
                default:
                    return Vector3.zero;
            }
        }

        // Chase the heel target (a fixed distance back along the Fool's trail, offset to his side),
        // matching gait to how far behind Pip is, easing to a stop on arrival.
        private Vector3 ComputeHeel()
        {
            if (!_trail.TryGetHeelTarget(_heelDistance, out Vector3 heel))
            {
                return Vector3.zero;
            }

            Vector3 desired = heel + HeelLateral();
            return SteerTo(desired);
        }

        // The lateral component that keeps Pip beside the Fool: his right vector scaled by the
        // offset (flattened). Sign is fixed (his right) so Pip has a consistent "side".
        private Vector3 HeelLateral()
        {
            Vector3 right = _followTarget.right;
            right.y = 0f;
            if (right.sqrMagnitude < 0.0001f)
            {
                return Vector3.zero;
            }

            return right.normalized * _heelLateralOffset;
        }

        private Vector3 ComputeRangeAhead(float dt)
        {
            _wanderTimer += dt;

            Vector3 flat = _wanderTarget - transform.position;
            flat.y = 0f;
            if (flat.magnitude <= _rangeArrivalRadius || _wanderTimer >= _rangeRepathSeconds)
            {
                PickWanderTarget();
            }

            return SteerTo(_wanderTarget, _trotSpeed);
        }

        private Vector3 ComputeSeek()
        {
            if (!_hasActionTarget)
            {
                RaiseCompletedAndHeel(PipState.Seek);
                return Vector3.zero;
            }

            Vector3 flat = _actionTarget - transform.position;
            flat.y = 0f;
            if (flat.magnitude <= _seekArrivalRadius)
            {
                RaiseCompletedAndHeel(PipState.Seek);
                return Vector3.zero;
            }

            Vector3 direction = ObstacleNudged(flat.normalized);
            RotateToward(direction);
            return direction * _trotSpeed;
        }

        // Dig with a marker travels to it first, then holds (the animator plays the dig). Dig in
        // place (no marker) just holds.
        private Vector3 ComputeParkAtTarget()
        {
            if (!_hasActionTarget)
            {
                return Vector3.zero;
            }

            Vector3 flat = _actionTarget - transform.position;
            flat.y = 0f;
            if (flat.magnitude <= _seekArrivalRadius)
            {
                _hasActionTarget = false; // arrived — hold and let the beat play
                RaiseCompleted(PipState.Dig);
                return Vector3.zero;
            }

            return SteerTo(_actionTarget, _trotSpeed);
        }

        // Steer toward a world position, choosing a distance-matched gait and easing to a stop on
        // arrival (arrival damping so Pip settles rather than bumping the Fool).
        private Vector3 SteerTo(Vector3 worldTarget)
        {
            Vector3 flat = worldTarget - transform.position;
            flat.y = 0f;
            float distance = flat.magnitude;

            if (distance <= _arrivalRadius)
            {
                return Vector3.zero;
            }

            float speed = SpeedForDistance(distance);

            // Arrival damping: fade speed toward zero across the damp band as Pip nears the target.
            if (distance < _arrivalRadius + _arrivalDampBand && _arrivalDampBand > 0.0001f)
            {
                float t = (distance - _arrivalRadius) / _arrivalDampBand;
                speed *= Mathf.Clamp01(t);
            }

            Vector3 direction = flat / distance;
            RotateToward(direction);
            return direction * speed;
        }

        // Fixed-gait variant (RangeAhead / Seek / Dig travel), still easing to a stop on arrival.
        private Vector3 SteerTo(Vector3 worldTarget, float speed)
        {
            Vector3 flat = worldTarget - transform.position;
            flat.y = 0f;
            float distance = flat.magnitude;

            if (distance <= _arrivalRadius)
            {
                return Vector3.zero;
            }

            if (distance < _arrivalRadius + _arrivalDampBand && _arrivalDampBand > 0.0001f)
            {
                float t = (distance - _arrivalRadius) / _arrivalDampBand;
                speed *= Mathf.Clamp01(t);
            }

            Vector3 direction = flat / distance;
            RotateToward(direction);
            return direction * speed;
        }

        private float SpeedForDistance(float distance)
        {
            if (distance >= _sprintDistance)
            {
                return _sprintSpeed;
            }

            return distance > _trotDistance ? _trotSpeed : _walkSpeed;
        }

        // A single forward sphere-cast: if the straight path is blocked, blend in the perpendicular
        // direction that clears the obstacle. No pathfinding — just enough to slip past a pillar.
        private Vector3 ObstacleNudged(Vector3 direction)
        {
            Vector3 origin = transform.position + (Vector3.up * _obstacleProbeHeight);
            if (!Physics.SphereCast(origin, _obstacleProbeRadius, direction, out RaycastHit hit,
                    _obstacleProbeDistance, _obstacleMask, QueryTriggerInteraction.Ignore))
            {
                return direction;
            }

            Vector3 side = Vector3.Cross(Vector3.up, direction);
            if (side.sqrMagnitude < 0.0001f)
            {
                return direction;
            }

            side.Normalize();
            // Steer toward whichever side the obstacle's face points away from (the open side).
            float sign = Vector3.Dot(hit.normal, side) >= 0f ? 1f : -1f;
            Vector3 nudged = direction + (side * sign * _obstacleSteer);
            nudged.y = 0f;
            return nudged.sqrMagnitude > 0.0001f ? nudged.normalized : direction;
        }

        private void PickWanderTarget()
        {
            _wanderTimer = 0f;

            Vector2 disc = UnityEngine.Random.insideUnitCircle * _rangeRadius;
            Vector3 candidate = _followTarget.position + new Vector3(disc.x, 0f, disc.y);

            // Drop the candidate onto the ground beneath it; fall back to the Fool's spot if nothing hits.
            Vector3 rayOrigin = candidate + (Vector3.up * 2f);
            if (Physics.Raycast(rayOrigin, Vector3.down, out RaycastHit hit, 6f, _groundMask,
                    QueryTriggerInteraction.Ignore))
            {
                _wanderTarget = hit.point;
            }
            else
            {
                _wanderTarget = _followTarget.position;
            }
        }

        private void RotateToward(Vector3 worldDir)
        {
            worldDir.y = 0f;
            if (worldDir.sqrMagnitude <= MoveThresholdSqr)
            {
                return;
            }

            worldDir.Normalize();
            float targetAngle = Mathf.Atan2(worldDir.x, worldDir.z) * Mathf.Rad2Deg;
            float angle = Mathf.SmoothDampAngle(
                transform.eulerAngles.y, targetAngle, ref _turnVelocity, _turnSmoothTime);
            transform.rotation = Quaternion.Euler(0f, angle, 0f);
        }

        private void MoveWithGravity(Vector3 horizontal, float dt)
        {
            if (_controller.isGrounded && _verticalVelocity < 0f)
            {
                _verticalVelocity = _groundedStickForce;
            }
            else
            {
                _verticalVelocity += _gravity * dt;
            }

            Vector3 velocity = horizontal;
            velocity.y = _verticalVelocity;
            _controller.Move(velocity * dt);
        }

        // CharacterController.Move can't teleport (it integrates), so disable it, set the transform,
        // and re-enable — the standard idiom for hard-repositioning a CharacterController.
        private void TeleportTo(Vector3 position)
        {
            _controller.enabled = false;
            transform.position = position;
            _controller.enabled = true;
            _verticalVelocity = 0f;
        }

        private void RaiseCompletedAndHeel(PipState completed)
        {
            RaiseCompleted(completed);
            Heel();
        }

        private void RaiseCompleted(PipState completed)
        {
            StateCompleted?.Invoke(completed);
        }

        private void SetState(PipState next)
        {
            if (_state == next)
            {
                return;
            }

            _state = next;
            StateChanged?.Invoke(next);
        }
    }
}
