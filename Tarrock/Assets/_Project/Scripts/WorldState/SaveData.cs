namespace Tarrock.WorldState;

using System;
using System.Collections.Generic;

/// <summary>
/// The serializable save model: a schema <see cref="Version"/> plus the mutable world state
/// as stable string ids only (never whole definitions — technical.md §Save system). Fired
/// states are stored in fire order as an append-only list; <c>READING_ORDER</c> is derived
/// from the unbinding entries rather than stored twice (single source of truth). Uses
/// <c>List&lt;T&gt;</c> of entry structs, not dictionaries, to stay JsonUtility-compatible.
/// </summary>
[Serializable]
public sealed class SaveData
{
    public int Version;
    public List<FiredStateEntry> FiredStates;
    public List<RenownEntry> Renown;

    public SaveData()
    {
        FiredStates = new List<FiredStateEntry>();
        Renown = new List<RenownEntry>();
    }
}
