namespace Tarrock.Tests.EditMode
{

    using System.Collections.Generic;
    using System.Linq;
    using NUnit.Framework;
    using Tarrock.WorldState;

    /// <summary>
    /// Verifies the WorldState service's mutation contract — fire/query, idempotence,
    /// append-only reading order, act thresholds, confession, and Renown tiers
    /// (technical.md §Testing: "world-state transitions ... the game's single mutation contract").
    /// </summary>
    [TestFixture]
    public sealed class WorldStateServiceTests
    {
        private static IReadOnlyList<string> UnbindingIds =>
            WorldStateIds.All.Where(id => id.EndsWith("_UNBOUND")).ToList();

        [Test]
        public void Fire_SetsIsFired()
        {
            var service = new WorldStateService();
            Assert.IsFalse(service.IsFired(WorldStateIds.MagicianUnbound));

            service.Fire(WorldStateIds.MagicianUnbound, isUnbinding: true);

            Assert.IsTrue(service.IsFired(WorldStateIds.MagicianUnbound));
        }

        [Test]
        public void Fire_IsIdempotent_EventRaisedOnce()
        {
            var service = new WorldStateService();
            int raisedCount = 0;
            service.StateFired += _ => raisedCount++;

            service.Fire(WorldStateIds.SunUnbound, isUnbinding: true);
            service.Fire(WorldStateIds.SunUnbound, isUnbinding: true);
            service.Fire(WorldStateIds.SunUnbound, isUnbinding: true);

            Assert.AreEqual(1, raisedCount);
            Assert.AreEqual(1, service.UnbindingCount);
            Assert.AreEqual(1, service.FiredStates.Count);
        }

        [Test]
        public void ReadingOrder_RecordsOnlyUnbindings_InOrder()
        {
            var service = new WorldStateService();

            service.Fire(WorldStateIds.StarUnbound, isUnbinding: true);
            service.Fire(WorldStateIds.TroupeSettled, isUnbinding: false);   // branch — excluded
            service.Fire(WorldStateIds.SunUnbound, isUnbinding: true);
            service.Fire(WorldStateIds.DivideEastMarried, isUnbinding: false); // branch — excluded

            CollectionAssert.AreEqual(
                new[] { WorldStateIds.StarUnbound, WorldStateIds.SunUnbound },
                service.ReadingOrder);
            Assert.AreEqual(2, service.UnbindingCount);
        }

        [Test]
        public void CurrentAct_ActIThroughSixUnbindings()
        {
            var service = new WorldStateService();
            Assert.AreEqual(ActState.ActI, service.CurrentAct); // 0 unbound

            FireUnbindings(service, 6);
            Assert.AreEqual(ActState.ActI, service.CurrentAct); // upper edge of Act I
        }

        [Test]
        public void CurrentAct_ActIIFromSevenThroughFourteen()
        {
            var service = new WorldStateService();

            FireUnbindings(service, 7);
            Assert.AreEqual(ActState.ActII, service.CurrentAct); // lower edge of Act II

            FireUnbindings(service, 14);
            Assert.AreEqual(ActState.ActII, service.CurrentAct); // upper edge of Act II
        }

        [Test]
        public void CurrentAct_ActIIIFromFifteen()
        {
            var service = new WorldStateService();

            FireUnbindings(service, 15);
            Assert.AreEqual(ActState.ActIII, service.CurrentAct);
        }

        [Test]
        public void IsConfessed_FlipsOnDeathUnbound()
        {
            var service = new WorldStateService();
            Assert.IsFalse(service.IsConfessed);

            service.Fire(WorldStateIds.DeathUnbound, isUnbinding: true);

            Assert.IsTrue(service.IsConfessed);
        }

        [Test]
        public void AddRenown_AccumulatesAndClampsAtZero()
        {
            var service = new WorldStateService();

            service.AddRenown(Suit.Cups, 25);
            Assert.AreEqual(25, service.GetRenown(Suit.Cups));

            service.AddRenown(Suit.Cups, -100);
            Assert.AreEqual(0, service.GetRenown(Suit.Cups));

            // Renown is per-suit and independent.
            Assert.AreEqual(0, service.GetRenown(Suit.Swords));
        }

        [Test]
        public void GetRenownTier_AtLadderBoundaries()
        {
            var service = new WorldStateService();
            Assert.AreEqual(1, service.GetRenownTier(Suit.Wands)); // Stranger at 0

            service.AddRenown(Suit.Wands, WorldStateService.Tier2Threshold);
            Assert.AreEqual(2, service.GetRenownTier(Suit.Wands));

            service.AddRenown(Suit.Wands, WorldStateService.Tier3Threshold - WorldStateService.Tier2Threshold);
            Assert.AreEqual(3, service.GetRenownTier(Suit.Wands));

            service.AddRenown(Suit.Wands, WorldStateService.Tier4Threshold - WorldStateService.Tier3Threshold);
            Assert.AreEqual(4, service.GetRenownTier(Suit.Wands));

            service.AddRenown(Suit.Wands, WorldStateService.Tier5Threshold - WorldStateService.Tier4Threshold);
            Assert.AreEqual(5, service.GetRenownTier(Suit.Wands));
        }

        [Test]
        public void GetRenownTier_JustBelowBoundaryStaysLowerTier()
        {
            var service = new WorldStateService();
            service.AddRenown(Suit.Coins, WorldStateService.Tier2Threshold - 1);
            Assert.AreEqual(1, service.GetRenownTier(Suit.Coins));
        }

        private static void FireUnbindings(WorldStateService service, int count)
        {
            IReadOnlyList<string> ids = UnbindingIds;
            for (int i = 0; i < count; i++)
            {
                service.Fire(ids[i], isUnbinding: true);
            }
        }
    }
}
