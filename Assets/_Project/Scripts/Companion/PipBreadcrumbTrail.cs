namespace Tarrock.Companion
{

    using UnityEngine;

    /// <summary>
    /// Pure breadcrumb ring-buffer for Pip's steering-follow (no NavMesh — see PipController).
    /// Records the followed transform's grounded positions as a fixed-capacity ring of crumbs and
    /// answers "where is the point <c>trailingDistance</c> metres back along the recorded path?",
    /// which is how <see cref="PipController"/> keeps Pip a settled distance behind the Fool while
    /// following his actual route rather than cutting corners.
    ///
    /// Deliberately free of any <c>UnityEngine.Object</c> dependency (Vector3 math only) so the
    /// trail arithmetic — spacing gate, ring wrap, heel-target walk-back — is EditMode-testable
    /// without a scene, per technical.md §Testing ("pure data + transitions ... testable without
    /// a scene"). The MonoBehaviour that owns it feeds it positions and reads targets; it never
    /// touches a Transform itself.
    /// </summary>
    public sealed class PipBreadcrumbTrail
    {
        private readonly Vector3[] _crumbs;
        private readonly float _spacing;

        // Index of the next slot to write. The newest crumb is one step behind it.
        private int _writeIndex;
        private int _count;

        /// <summary>
        /// Creates a trail holding at most <paramref name="capacity"/> crumbs, dropping a fresh
        /// crumb only once the source has moved at least <paramref name="spacing"/> metres from the
        /// last one. Capacity is clamped to a minimum of two (a head plus one trailing crumb, the
        /// least a heel-target walk-back needs); spacing to a small positive epsilon.
        /// </summary>
        public PipBreadcrumbTrail(int capacity, float spacing)
        {
            _crumbs = new Vector3[Mathf.Max(2, capacity)];
            _spacing = Mathf.Max(0.0001f, spacing);
        }

        /// <summary>Number of crumbs currently recorded (0 up to <see cref="Capacity"/>).</summary>
        public int Count => _count;

        /// <summary>Maximum crumbs the ring holds before the oldest is overwritten.</summary>
        public int Capacity => _crumbs.Length;

        /// <summary>Minimum distance (m) the source must travel before a new crumb is dropped.</summary>
        public float Spacing => _spacing;

        /// <summary>True while no crumbs have been recorded (or since the last <see cref="Clear"/>).</summary>
        public bool IsEmpty => _count == 0;

        /// <summary>
        /// The most recently dropped crumb — the head of the trail, i.e. roughly where the source
        /// is now. Returns <see cref="Vector3.zero"/> when empty.
        /// </summary>
        public Vector3 Newest => _count == 0 ? Vector3.zero : FromNewest(0);

        /// <summary>
        /// The oldest surviving crumb — the far tail of the recorded path. Returns
        /// <see cref="Vector3.zero"/> when empty.
        /// </summary>
        public Vector3 Oldest => _count == 0 ? Vector3.zero : FromNewest(_count - 1);

        /// <summary>
        /// Records <paramref name="position"/> as a new crumb, but only if the trail is empty or the
        /// position is at least <see cref="Spacing"/> metres from the current head — so a stationary
        /// source never floods the ring. Overwrites the oldest crumb once the ring is full.
        /// </summary>
        /// <returns><c>true</c> if a crumb was actually dropped this call.</returns>
        public bool TryDrop(Vector3 position)
        {
            if (_count > 0)
            {
                Vector3 head = FromNewest(0);
                if ((position - head).sqrMagnitude < _spacing * _spacing)
                {
                    return false;
                }
            }

            _crumbs[_writeIndex] = position;
            _writeIndex = (_writeIndex + 1) % _crumbs.Length;
            if (_count < _crumbs.Length)
            {
                _count++;
            }

            return true;
        }

        /// <summary>Empties the trail (used on a teleport-catchup so Pip does not re-walk a stale path).</summary>
        public void Clear()
        {
            _count = 0;
            _writeIndex = 0;
        }

        /// <summary>
        /// Returns the crumb <paramref name="stepsBack"/> steps behind the head (0 = the newest
        /// crumb, 1 = the one before it, …). <paramref name="stepsBack"/> is clamped into range;
        /// an empty trail yields <see cref="Vector3.zero"/>.
        /// </summary>
        public Vector3 CrumbFromNewest(int stepsBack)
        {
            if (_count == 0)
            {
                return Vector3.zero;
            }

            int clamped = Mathf.Clamp(stepsBack, 0, _count - 1);
            return FromNewest(clamped);
        }

        /// <summary>
        /// Walks back from the head along the recorded path, accumulating segment lengths, and
        /// returns the point exactly <paramref name="trailingDistance"/> metres behind the head —
        /// interpolated within the segment it lands in. If the whole trail is shorter than the
        /// requested distance, returns the oldest crumb. This is the heel target: the spot that
        /// keeps Pip a fixed distance behind the Fool along his real route.
        /// </summary>
        /// <returns><c>false</c> (and <paramref name="target"/> = zero) only when the trail is empty.</returns>
        public bool TryGetHeelTarget(float trailingDistance, out Vector3 target)
        {
            if (_count == 0)
            {
                target = Vector3.zero;
                return false;
            }

            Vector3 head = FromNewest(0);
            target = head;

            if (trailingDistance <= 0f || _count == 1)
            {
                return true;
            }

            float remaining = trailingDistance;
            Vector3 previous = head;

            for (int step = 1; step < _count; step++)
            {
                Vector3 current = FromNewest(step);
                float segment = Vector3.Distance(previous, current);

                if (segment >= remaining)
                {
                    Vector3 direction = segment > 0.0001f ? (current - previous) / segment : Vector3.zero;
                    target = previous + (direction * remaining);
                    return true;
                }

                remaining -= segment;
                previous = current;
                target = current;
            }

            // The trail is shorter than the requested distance: settle for the far tail.
            return true;
        }

        // Maps a "steps behind the head" index onto the underlying ring slot. Slot (_writeIndex - 1)
        // is the newest; each further step walks one slot older, wrapping around the array.
        private Vector3 FromNewest(int stepsBack)
        {
            int index = (_writeIndex - 1 - stepsBack) % _crumbs.Length;
            if (index < 0)
            {
                index += _crumbs.Length;
            }

            return _crumbs[index];
        }
    }
}
