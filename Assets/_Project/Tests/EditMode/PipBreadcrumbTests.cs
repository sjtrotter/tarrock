namespace Tarrock.Tests.EditMode
{

    using NUnit.Framework;
    using Tarrock.Companion;
    using UnityEngine;

    /// <summary>
    /// Coverage of <see cref="PipBreadcrumbTrail"/>, the pure breadcrumb ring-buffer behind Pip's
    /// NavMesh-free follow (PipController). Verifies the spacing gate that stops a stationary Fool
    /// flooding the ring, the ring wrap that overwrites the oldest crumb, the heel-target walk-back
    /// that finds the point a set distance behind the head (interpolated, and clamped to the tail
    /// when the trail is short), and clear-on-teleport. Fixtures use round numbers on a straight
    /// line so the trailing-distance arithmetic is exact, mirroring DodgeStateTests' style.
    /// </summary>
    [TestFixture]
    public sealed class PipBreadcrumbTests
    {
        private const float Spacing = 1f;

        private static void AssertVector(Vector3 expected, Vector3 actual)
        {
            Assert.AreEqual(expected.x, actual.x, 1e-4f, "x");
            Assert.AreEqual(expected.y, actual.y, 1e-4f, "y");
            Assert.AreEqual(expected.z, actual.z, 1e-4f, "z");
        }

        // Drops crumbs at x = 0, 1, 2, ... (one Spacing apart), returning the trail.
        private static PipBreadcrumbTrail LineTrail(int capacity, int crumbs)
        {
            var trail = new PipBreadcrumbTrail(capacity, Spacing);
            for (int i = 0; i < crumbs; i++)
            {
                trail.TryDrop(new Vector3(i * Spacing, 0f, 0f));
            }

            return trail;
        }

        [Test]
        public void StartsEmpty()
        {
            var trail = new PipBreadcrumbTrail(8, Spacing);

            Assert.IsTrue(trail.IsEmpty);
            Assert.AreEqual(0, trail.Count);
            Assert.AreEqual(8, trail.Capacity);
        }

        [Test]
        public void CapacityClampedToMinimumOfTwo()
        {
            var trail = new PipBreadcrumbTrail(1, Spacing);

            Assert.AreEqual(2, trail.Capacity);
        }

        [Test]
        public void FirstCrumbAlwaysDrops()
        {
            var trail = new PipBreadcrumbTrail(8, Spacing);

            bool dropped = trail.TryDrop(new Vector3(5f, 0f, 5f));

            Assert.IsTrue(dropped);
            Assert.AreEqual(1, trail.Count);
            AssertVector(new Vector3(5f, 0f, 5f), trail.Newest);
        }

        [Test]
        public void DoesNotDrop_WithinSpacing()
        {
            var trail = new PipBreadcrumbTrail(8, Spacing);
            trail.TryDrop(Vector3.zero);

            bool dropped = trail.TryDrop(new Vector3(0.5f, 0f, 0f)); // < Spacing

            Assert.IsFalse(dropped);
            Assert.AreEqual(1, trail.Count);
        }

        [Test]
        public void Drops_AtOrBeyondSpacing()
        {
            var trail = new PipBreadcrumbTrail(8, Spacing);
            trail.TryDrop(Vector3.zero);

            bool dropped = trail.TryDrop(new Vector3(1f, 0f, 0f)); // == Spacing

            Assert.IsTrue(dropped);
            Assert.AreEqual(2, trail.Count);
        }

        [Test]
        public void NewestAndOldest_TrackTheEnds()
        {
            PipBreadcrumbTrail trail = LineTrail(8, 4); // x = 0..3

            AssertVector(new Vector3(3f, 0f, 0f), trail.Newest);
            AssertVector(new Vector3(0f, 0f, 0f), trail.Oldest);
        }

        [Test]
        public void RingWraps_OverwritingOldest()
        {
            PipBreadcrumbTrail trail = LineTrail(3, 5); // drop x = 0..4 into a ring of 3

            Assert.AreEqual(3, trail.Count); // capped at capacity
            AssertVector(new Vector3(4f, 0f, 0f), trail.Newest);
            AssertVector(new Vector3(2f, 0f, 0f), trail.Oldest); // 0 and 1 overwritten
        }

        [Test]
        public void HeelTarget_ReturnsCrumbAtTrailingDistance()
        {
            PipBreadcrumbTrail trail = LineTrail(16, 5); // x = 0..4, head at 4

            bool found = trail.TryGetHeelTarget(2f, out Vector3 target);

            Assert.IsTrue(found);
            AssertVector(new Vector3(2f, 0f, 0f), target);
        }

        [Test]
        public void HeelTarget_InterpolatesWithinSegment()
        {
            PipBreadcrumbTrail trail = LineTrail(16, 5); // head at 4

            trail.TryGetHeelTarget(1.5f, out Vector3 target);

            AssertVector(new Vector3(2.5f, 0f, 0f), target); // 1.5 back from x = 4
        }

        [Test]
        public void HeelTarget_ReturnsHead_AtZeroDistance()
        {
            PipBreadcrumbTrail trail = LineTrail(16, 5);

            trail.TryGetHeelTarget(0f, out Vector3 target);

            AssertVector(new Vector3(4f, 0f, 0f), target);
        }

        [Test]
        public void HeelTarget_ClampsToOldest_WhenTrailShorterThanDistance()
        {
            PipBreadcrumbTrail trail = LineTrail(16, 5); // total length 4

            trail.TryGetHeelTarget(100f, out Vector3 target);

            AssertVector(new Vector3(0f, 0f, 0f), target); // the far tail
        }

        [Test]
        public void HeelTarget_False_WhenEmpty()
        {
            var trail = new PipBreadcrumbTrail(8, Spacing);

            bool found = trail.TryGetHeelTarget(1f, out Vector3 target);

            Assert.IsFalse(found);
            AssertVector(Vector3.zero, target);
        }

        [Test]
        public void Clear_EmptiesTheTrail()
        {
            PipBreadcrumbTrail trail = LineTrail(8, 4);

            trail.Clear();

            Assert.IsTrue(trail.IsEmpty);
            Assert.AreEqual(0, trail.Count);
            Assert.IsFalse(trail.TryGetHeelTarget(1f, out _));
        }

        [Test]
        public void Clear_ThenDrop_RebuildsFromScratch()
        {
            PipBreadcrumbTrail trail = LineTrail(8, 4);
            trail.Clear();

            bool dropped = trail.TryDrop(new Vector3(10f, 0f, 0f));

            Assert.IsTrue(dropped); // first crumb after a clear always drops
            Assert.AreEqual(1, trail.Count);
            AssertVector(new Vector3(10f, 0f, 0f), trail.Newest);
        }

        [Test]
        public void CrumbFromNewest_WalksBackFromTheHead()
        {
            PipBreadcrumbTrail trail = LineTrail(16, 5); // x = 0..4

            AssertVector(new Vector3(4f, 0f, 0f), trail.CrumbFromNewest(0));
            AssertVector(new Vector3(3f, 0f, 0f), trail.CrumbFromNewest(1));
            AssertVector(new Vector3(0f, 0f, 0f), trail.CrumbFromNewest(10)); // clamped
        }
    }
}
