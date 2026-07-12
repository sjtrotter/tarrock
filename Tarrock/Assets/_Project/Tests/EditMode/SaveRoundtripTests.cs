namespace Tarrock.Tests.EditMode;

using NUnit.Framework;
using Tarrock.WorldState;

/// <summary>
/// Verifies the save round-trip (Capture → ToJson → FromJson → Restore) preserves the fired
/// set, fire order, derived reading order, and Renown, that the schema version is stamped,
/// and that the v1 migration is a passthrough (technical.md §Testing: "save migrations").
/// </summary>
[TestFixture]
public sealed class SaveRoundtripTests
{
    private static WorldStateService BuildPopulatedService()
    {
        var service = new WorldStateService();
        service.Fire(WorldStateIds.MagicianUnbound, isUnbinding: true);
        service.Fire(WorldStateIds.TroupeSettled, isUnbinding: false);
        service.Fire(WorldStateIds.StarUnbound, isUnbinding: true);
        service.Fire(WorldStateIds.SunUnbound, isUnbinding: true);
        service.AddRenown(Suit.Cups, 42);
        service.AddRenown(Suit.Coins, 7);
        return service;
    }

    [Test]
    public void Capture_StampsCurrentVersion()
    {
        var save = new SaveService();
        SaveData data = save.Capture(new WorldStateService());

        Assert.AreEqual(SaveService.CurrentVersion, data.Version);
    }

    [Test]
    public void Roundtrip_PreservesFiredSetOrderReadingOrderAndRenown()
    {
        var save = new SaveService();
        WorldStateService original = BuildPopulatedService();

        SaveData captured = save.Capture(original);
        string json = save.ToJson(captured);
        SaveData parsed = save.FromJson(json);
        WorldStateService restored = save.Restore(parsed);

        // Fired set.
        Assert.IsTrue(restored.IsFired(WorldStateIds.MagicianUnbound));
        Assert.IsTrue(restored.IsFired(WorldStateIds.TroupeSettled));
        Assert.IsTrue(restored.IsFired(WorldStateIds.StarUnbound));
        Assert.IsTrue(restored.IsFired(WorldStateIds.SunUnbound));
        Assert.IsFalse(restored.IsFired(WorldStateIds.MoonUnbound));

        // Fire order (all fired states, in order).
        CollectionAssert.AreEqual(
            new[]
            {
                WorldStateIds.MagicianUnbound,
                WorldStateIds.TroupeSettled,
                WorldStateIds.StarUnbound,
                WorldStateIds.SunUnbound,
            },
            System.Linq.Enumerable.Select(restored.FiredStates, e => e.Id));

        // Derived reading order — unbindings only, in order (branch flag excluded).
        CollectionAssert.AreEqual(
            new[]
            {
                WorldStateIds.MagicianUnbound,
                WorldStateIds.StarUnbound,
                WorldStateIds.SunUnbound,
            },
            restored.ReadingOrder);

        // Renown.
        Assert.AreEqual(42, restored.GetRenown(Suit.Cups));
        Assert.AreEqual(7, restored.GetRenown(Suit.Coins));
        Assert.AreEqual(0, restored.GetRenown(Suit.Swords));
    }

    [Test]
    public void Migrate_V1IsPassthrough()
    {
        var save = new SaveService();
        SaveData data = save.Capture(BuildPopulatedService());
        int firedBefore = data.FiredStates.Count;

        SaveData migrated = SaveMigrator.Migrate(data);

        Assert.AreEqual(SaveService.CurrentVersion, migrated.Version);
        Assert.AreSame(data, migrated);
        Assert.AreEqual(firedBefore, migrated.FiredStates.Count);
    }
}
