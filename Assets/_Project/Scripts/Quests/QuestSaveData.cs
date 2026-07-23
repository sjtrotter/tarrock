namespace Tarrock.Quests
{

    using System;
    using System.Collections.Generic;

    /// <summary>
    /// The serializable save block for quest progress: a schema <see cref="Version"/> plus the
    /// per-quest <see cref="QuestSaveEntry"/> list. This is a <em>parallel</em> block to the
    /// WorldState feature's <c>SaveData</c>, deliberately owned by <c>Tarrock.Quests</c> rather
    /// than folded into <c>SaveData</c>: <c>SaveData</c> lives in <c>Tarrock.WorldState</c>, and
    /// <c>Tarrock.Quests</c> references <c>Tarrock.WorldState</c> (never the reverse), so a
    /// <c>SaveData</c> field of type <see cref="QuestSaveEntry"/> would require a cyclic asmdef
    /// dependency. Keeping quest persistence here respects the feature boundary while mirroring
    /// the WorldState save shape exactly (versioned JSON, <c>List&lt;T&gt;</c> of entries for
    /// JsonUtility compatibility, an explicit migrator — see <see cref="QuestSaveMigrator"/>).
    /// </summary>
    [Serializable]
    public sealed class QuestSaveData
    {
        public int Version;
        public List<QuestSaveEntry> Quests;

        public QuestSaveData()
        {
            Quests = new List<QuestSaveEntry>();
        }
    }
}
