namespace Tarrock.Quests
{

    /// <summary>
    /// The runtime lifecycle state of a quest instance (docs/quests/README.md §Status workflow
    /// is the doc-authoring workflow; this is the play-time machine). Only these three states
    /// exist at runtime: a quest is <see cref="Inactive"/> until its requirements are met and it
    /// is activated, <see cref="Active"/> while the Fool works through its steps, and
    /// <see cref="Complete"/> once its terminal step is reached and its fired flags are committed.
    /// Per-step progress is tracked separately (see <see cref="QuestSaveEntry"/>), not folded into
    /// this enum. <see cref="Inactive"/> is the zero value so a fresh save reads as "nothing begun".
    /// </summary>
    public enum QuestState
    {
        Inactive = 0,
        Active = 1,
        Complete = 2,
    }
}
