namespace Tarrock.WorldState;

/// <summary>
/// The global act, derived from how many Arcana have been unbound
/// (world.md §Global states): Act I = 0–6, Act II = 7–14, Act III = 15–21.
/// This is a computed view of world state, never stored or fired as a flag.
/// </summary>
public enum ActState
{
    ActI,
    ActII,
    ActIII,
}
