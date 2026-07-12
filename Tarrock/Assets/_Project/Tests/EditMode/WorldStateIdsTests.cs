namespace Tarrock.Tests.EditMode;

using System.Linq;
using NUnit.Framework;
using Tarrock.WorldState;

/// <summary>
/// Drift canary against world.md §World-state matrix: the constants surface must hold exactly
/// 25 ids — the 21 <c>*_UNBOUND</c> Arcana flags plus the 4 branch flags — and no duplicates.
/// If the matrix and the code diverge, this test fails loudly rather than silently.
/// </summary>
[TestFixture]
public sealed class WorldStateIdsTests
{
    private const int ExpectedTotal = 25;
    private const int ExpectedUnbindings = 21;
    private const int ExpectedBranches = 4;

    [Test]
    public void All_ContainsExactlyTwentyFiveIds()
    {
        Assert.AreEqual(ExpectedTotal, WorldStateIds.All.Count);
    }

    [Test]
    public void All_IdsAreUnique()
    {
        Assert.AreEqual(WorldStateIds.All.Count, WorldStateIds.All.Distinct().Count());
    }

    [Test]
    public void All_SplitsIntoTwentyOneUnbindingsAndFourBranches()
    {
        int unbindings = WorldStateIds.All.Count(id => id.EndsWith("_UNBOUND"));
        int branches = WorldStateIds.All.Count(id => !id.EndsWith("_UNBOUND"));

        Assert.AreEqual(ExpectedUnbindings, unbindings);
        Assert.AreEqual(ExpectedBranches, branches);
    }

    [Test]
    public void All_EveryIdUsesWsPrefix()
    {
        Assert.IsTrue(WorldStateIds.All.All(id => id.StartsWith("WS_")));
    }

    [Test]
    public void All_ContainsTheKnownBranchFlags()
    {
        CollectionAssert.Contains(WorldStateIds.All, WorldStateIds.TroupeTraveling);
        CollectionAssert.Contains(WorldStateIds.All, WorldStateIds.TroupeSettled);
        CollectionAssert.Contains(WorldStateIds.All, WorldStateIds.DivideEastMarried);
        CollectionAssert.Contains(WorldStateIds.All, WorldStateIds.DivideWestMarried);
    }
}
