namespace Tarrock.WorldState;

using System;

/// <summary>
/// One fired world-state flag as stored in the save model and replayed in fire order:
/// the <c>WS_*</c> id plus whether it was an unbinding (so <c>READING_ORDER</c> can be
/// derived on load without storing it twice — technical.md §Save system). A plain
/// serializable data-transfer struct with public fields, as JsonUtility requires; the
/// encapsulation rule targets MonoBehaviours and ScriptableObjects, not save DTOs.
/// </summary>
[Serializable]
public struct FiredStateEntry
{
    public string Id;
    public bool IsUnbinding;

    public FiredStateEntry(string id, bool isUnbinding)
    {
        Id = id;
        IsUnbinding = isUnbinding;
    }
}
