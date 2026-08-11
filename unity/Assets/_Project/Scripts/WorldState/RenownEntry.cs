namespace Tarrock.WorldState
{

    using System;

    /// <summary>
    /// One suit's Renown value in the save model. JsonUtility-friendly key/value pair used in
    /// place of a dictionary (technical.md §Save system — "NO dictionaries"). Public fields as
    /// JsonUtility requires; this is a data-transfer struct, not an encapsulated component.
    /// </summary>
    [Serializable]
    public struct RenownEntry
    {
        public Suit Suit;
        public int Value;

        public RenownEntry(Suit suit, int value)
        {
            Suit = suit;
            Value = value;
        }
    }
}
