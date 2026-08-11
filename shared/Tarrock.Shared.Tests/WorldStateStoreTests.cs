using System;
using System.Linq;
using NUnit.Framework;

namespace Tarrock.Shared.Tests
{
    [TestFixture]
    public class WorldStateStoreTests
    {
        [Test]
        public void Fire_ReturnsTrue_TheFirstTimeAFlagFires()
        {
            var store = new WorldStateStore();

            Assert.That(store.Fire("WS_CLIFF_LEFT"), Is.True);
            Assert.That(store.IsFired("WS_CLIFF_LEFT"), Is.True);
        }

        [Test]
        public void Fire_ReturnsFalse_AndChangesNothing_WhenTheFlagAlreadyFired()
        {
            var store = new WorldStateStore();
            store.Fire("WS_CLIFF_LEFT");

            Assert.That(store.Fire("WS_CLIFF_LEFT"), Is.False);
            Assert.That(store.Fired.Count, Is.EqualTo(1));
            Assert.That(store.ReadingOrder, Is.EqualTo(new[] { "WS_CLIFF_LEFT" }));
        }

        [Test]
        public void AFiredFlagStaysFired_ThereIsNoWayToUnfireIt()
        {
            var store = new WorldStateStore();
            store.Fire("WS_CONFESSED");

            // Canon: WS_* flags can never be un-fired, so the type must expose no
            // clear/unset/remove/reset operation at all.
            var unfireLikeMembers = typeof(WorldStateStore)
                .GetMethods(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance)
                .Select(m => m.Name)
                .Where(n => n.Contains("Clear")
                            || n.Contains("Unset")
                            || n.Contains("Remove")
                            || n.Contains("Reset")
                            || n.Contains("Unfire")
                            || n.Contains("UnFire"))
                .ToArray();

            Assert.That(unfireLikeMembers, Is.Empty, "WorldStateStore must not expose an un-fire operation.");

            // Repeated firing is a no-op, never a toggle.
            store.Fire("WS_CONFESSED");
            store.Fire("WS_CONFESSED");
            Assert.That(store.IsFired("WS_CONFESSED"), Is.True);
        }

        [Test]
        public void ReadingOrder_PreservesFireOrder_AndIgnoresRepeats()
        {
            var store = new WorldStateStore();

            store.Fire("WS_THREE");
            store.Fire("WS_ONE");
            store.Fire("WS_TWO");
            store.Fire("WS_ONE"); // repeat: must not re-order or duplicate

            Assert.That(store.ReadingOrder, Is.EqualTo(new[] { "WS_THREE", "WS_ONE", "WS_TWO" }));
            Assert.That(store.Fired.Count, Is.EqualTo(3));
        }

        [Test]
        public void IsFired_IsFalse_ForAFlagThatNeverFired()
        {
            var store = new WorldStateStore();
            store.Fire("WS_ONE");

            Assert.That(store.IsFired("WS_TWO"), Is.False);
        }

        [Test]
        public void FlagIds_AreCaseSensitive()
        {
            var store = new WorldStateStore();
            store.Fire("WS_ONE");

            Assert.That(store.IsFired("ws_one"), Is.False);
        }

        [TestCase(null)]
        [TestCase("")]
        [TestCase("   ")]
        public void Fire_RejectsEmptyFlagIds(string flagId)
        {
            var store = new WorldStateStore();

            Assert.Throws<ArgumentException>(() => store.Fire(flagId));
            Assert.Throws<ArgumentException>(() => store.IsFired(flagId));
        }
    }
}
