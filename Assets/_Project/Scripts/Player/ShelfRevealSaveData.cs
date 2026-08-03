namespace Tarrock.Player
{

    using System;

    /// <summary>
    /// Ordinary per-save presentation state for the shelf reveal. This is deliberately not a
    /// <c>WS_*</c> flag: seeing a camera presentation changes neither the Cliff nor quest canon.
    /// </summary>
    [Serializable]
    public sealed class ShelfRevealSaveData
    {
        public int Version;
        public bool HasPlayed;
    }
}
