namespace Tarrock.WorldState;

using System;
using System.Collections.Generic;

/// <summary>
/// The single mutation path for world-state flags, the Fool's Reading, the act, and Renown
/// (technical.md §The WorldState service). A plain C# object with no Unity scene dependency
/// so the whole contract is EditMode-testable. Permanence is enforced by construction: the
/// only write is <see cref="Fire"/> (append-only, idempotent) — there is deliberately no
/// un-fire method to call (world.md §World-state matrix: "No unbinding is reversible").
/// </summary>
public sealed class WorldStateService
{
    // --- Renown tier thresholds (progression.md §Renown, five-tier ladder) ---------------
    // Minimum accumulated Renown to reach each tier. Tier 1 (Stranger) is the floor at 0.
    // TODO(tuning): placeholder values — retune once Renown-earning deeds are designed.
    public const int Tier2Threshold = 10;   // Known
    public const int Tier3Threshold = 30;   // Welcome
    public const int Tier4Threshold = 70;   // Honored
    public const int Tier5Threshold = 150;  // Fabled

    private const int SuitCount = 4;

    private readonly List<FiredStateEntry> _fired = new();
    private readonly HashSet<string> _firedIds = new();
    private readonly List<string> _readingOrder = new();
    private readonly int[] _renown = new int[SuitCount];

    /// <summary>Raised once per successful (first-time) fire, carrying the fired id.</summary>
    public event Action<string> StateFired;

    /// <summary>Constructs an empty world state (a new game).</summary>
    public WorldStateService()
    {
    }

    /// <summary>
    /// Reconstructs world state from saved data, preserving fire order and thereby the
    /// derived reading order. Renown is applied directly. Used by the save/restore path.
    /// </summary>
    public WorldStateService(IReadOnlyList<FiredStateEntry> firedStates, IReadOnlyList<RenownEntry> renown)
    {
        if (firedStates != null)
        {
            foreach (FiredStateEntry entry in firedStates)
            {
                Fire(entry.Id, entry.IsUnbinding);
            }
        }

        if (renown != null)
        {
            foreach (RenownEntry entry in renown)
            {
                _renown[(int)entry.Suit] = entry.Value;
            }
        }
    }

    /// <summary>Whether the given <c>WS_*</c> flag has been fired in this save.</summary>
    public bool IsFired(string id) => _firedIds.Contains(id);

    /// <summary>
    /// Commits a world-state flag. Idempotent: firing an already-fired id is a no-op (no
    /// duplicate entry, no second event). <paramref name="isUnbinding"/> records whether the
    /// flag is one of the 21 Arcana unbindings, which appends it to the Fool's Reading.
    /// </summary>
    public void Fire(string id, bool isUnbinding)
    {
        if (string.IsNullOrEmpty(id))
        {
            throw new ArgumentException("World-state id must be non-empty.", nameof(id));
        }

        if (!_firedIds.Add(id))
        {
            return;
        }

        _fired.Add(new FiredStateEntry(id, isUnbinding));
        if (isUnbinding)
        {
            _readingOrder.Add(id);
        }

        StateFired?.Invoke(id);
    }

    /// <summary>
    /// Every fired flag in fire order (append-only). Consumed by the save layer's capture.
    /// </summary>
    public IReadOnlyList<FiredStateEntry> FiredStates => _fired;

    /// <summary>
    /// The Fool's Reading: the ordered ids of unbindings only, in the order they occurred
    /// (world.md §Global states, <c>READING_ORDER</c>). Append-only; never reordered or removed.
    /// </summary>
    public IReadOnlyList<string> ReadingOrder => _readingOrder;

    /// <summary>How many of the 21 Arcana have been unbound.</summary>
    public int UnbindingCount => _readingOrder.Count;

    /// <summary>The current act, derived from <see cref="UnbindingCount"/> (world.md thresholds).</summary>
    public ActState CurrentAct
    {
        get
        {
            int count = UnbindingCount;
            if (count <= 6)
            {
                return ActState.ActI;
            }

            return count <= 14 ? ActState.ActII : ActState.ActIII;
        }
    }

    /// <summary>
    /// Whether the Fool has confessed — MQ13's Death unbinding (world.md §Global states,
    /// <c>CONFESSED</c>), which activates post-confession dialogue variants world-wide.
    /// </summary>
    public bool IsConfessed => IsFired(WorldStateIds.DeathUnbound);

    /// <summary>Current Renown value with the given suit.</summary>
    public int GetRenown(Suit suit) => _renown[(int)suit];

    /// <summary>
    /// Adjusts Renown with a suit by <paramref name="amount"/> (may be negative). Renown is a
    /// standing, not a morality meter (progression.md §Renown); it is clamped at zero so a
    /// suit's standing never goes below Stranger.
    /// </summary>
    public void AddRenown(Suit suit, int amount)
    {
        int updated = _renown[(int)suit] + amount;
        _renown[(int)suit] = updated < 0 ? 0 : updated;
    }

    /// <summary>
    /// The suit's current tier on the five-tier ladder (1 = Stranger … 5 = Fabled),
    /// per progression.md §Renown.
    /// </summary>
    public int GetRenownTier(Suit suit)
    {
        int value = GetRenown(suit);
        if (value >= Tier5Threshold)
        {
            return 5;
        }

        if (value >= Tier4Threshold)
        {
            return 4;
        }

        if (value >= Tier3Threshold)
        {
            return 3;
        }

        return value >= Tier2Threshold ? 2 : 1;
    }
}
