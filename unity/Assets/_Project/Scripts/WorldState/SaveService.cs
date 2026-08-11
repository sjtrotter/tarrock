namespace Tarrock.WorldState
{

    using UnityEngine;

    /// <summary>
    /// Serialises world state to and from the versioned JSON save model (technical.md
    /// §Save system). A plain C# object: capture/restore and the JSON layer are exercised in
    /// EditMode without touching disk. File persistence is delegated to <see cref="SaveFileStore"/>
    /// so the JSON boundary stays testable in isolation.
    /// </summary>
    public sealed class SaveService
    {
        /// <summary>Current save-schema version stamped into every captured <see cref="SaveData"/>.</summary>
        public const int CurrentVersion = 1;

        private static readonly Suit[] Suits = { Suit.Cups, Suit.Swords, Suit.Wands, Suit.Coins };

        /// <summary>Snapshots a live service into a versioned save model (fired states in order + Renown).</summary>
        public SaveData Capture(WorldStateService service)
        {
            var data = new SaveData { Version = CurrentVersion };

            foreach (FiredStateEntry entry in service.FiredStates)
            {
                data.FiredStates.Add(entry);
            }

            foreach (Suit suit in Suits)
            {
                data.Renown.Add(new RenownEntry(suit, service.GetRenown(suit)));
            }

            return data;
        }

        /// <summary>
        /// Rebuilds a service from save data, migrating it to the current version first and
        /// preserving fire order (and therefore the derived reading order).
        /// </summary>
        public WorldStateService Restore(SaveData data)
        {
            SaveData migrated = SaveMigrator.Migrate(data);
            return new WorldStateService(migrated.FiredStates, migrated.Renown);
        }

        /// <summary>Serialises save data to JSON.</summary>
        public string ToJson(SaveData data) => JsonUtility.ToJson(data);

        /// <summary>Deserialises save data from JSON.</summary>
        public SaveData FromJson(string json) => JsonUtility.FromJson<SaveData>(json);
    }
}
