namespace Tarrock.WorldState;

/// <summary>
/// The four Minor Arcana suits the Fool holds per-suit Renown with
/// (progression.md §Renown). Order is fixed; values double as the index into the
/// service's renown storage, so do not reorder without migrating saved renown.
/// </summary>
public enum Suit
{
    Cups = 0,
    Swords = 1,
    Wands = 2,
    Coins = 3,
}
