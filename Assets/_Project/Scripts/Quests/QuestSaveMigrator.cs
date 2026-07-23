namespace Tarrock.Quests
{

    using System;

    /// <summary>
    /// Applies quest-save-schema migrations in sequence until a <see cref="QuestSaveData"/>
    /// reaches <see cref="QuestService.CurrentSaveVersion"/> (technical.md §Save system). Mirrors
    /// the WorldState feature's <c>SaveMigrator</c> exactly: no best-effort or implicit migration
    /// — a missing migration for an intermediate version throws rather than guessing, so the gap
    /// surfaces immediately. At schema version 1 there is nothing to do and the data is returned
    /// unchanged.
    /// </summary>
    public static class QuestSaveMigrator
    {
        /// <summary>
        /// Upgrades <paramref name="data"/> to the current schema version, mutating and returning
        /// it. Throws <see cref="NotSupportedException"/> if a required migration step is missing.
        /// </summary>
        public static QuestSaveData Migrate(QuestSaveData data)
        {
            if (data == null)
            {
                throw new ArgumentNullException(nameof(data));
            }

            while (data.Version < QuestService.CurrentSaveVersion)
            {
                switch (data.Version)
                {
                    // Each future version bump adds an explicit case here, e.g.:
                    // case 1: MigrateV1ToV2(data); data.Version = 2; break;
                    default:
                        throw new NotSupportedException(
                            $"No quest-save migration defined from schema version {data.Version}.");
                }
            }

            return data;
        }
    }
}
