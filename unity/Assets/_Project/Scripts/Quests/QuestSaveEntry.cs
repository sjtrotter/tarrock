namespace Tarrock.Quests
{

    using System;
    using System.Collections.Generic;

    /// <summary>
    /// One quest's mutable progress as stored in the save model: the quest id (a stable string,
    /// never a whole definition — technical.md §Save system), its <see cref="QuestState"/>, how
    /// far the ordered required steps have advanced (<see cref="CurrentStepIndex"/>, counted over
    /// required steps only), and the ids of any optional steps already completed. A plain
    /// <see cref="Serializable"/> class with public fields, as JsonUtility requires; the
    /// encapsulation rule targets components and definitions, not save DTOs (mirrors
    /// <c>FiredStateEntry</c> / <c>RenownEntry</c> in the WorldState save model).
    /// </summary>
    [Serializable]
    public sealed class QuestSaveEntry
    {
        public string QuestId;
        public QuestState State;
        public int CurrentStepIndex;
        public List<string> CompletedOptionalStepIds;

        /// <summary>JsonUtility constructor.</summary>
        public QuestSaveEntry()
        {
            CompletedOptionalStepIds = new List<string>();
        }

        public QuestSaveEntry(string questId, QuestState state, int currentStepIndex, List<string> completedOptionalStepIds)
        {
            QuestId = questId;
            State = state;
            CurrentStepIndex = currentStepIndex;
            CompletedOptionalStepIds = completedOptionalStepIds ?? new List<string>();
        }
    }
}
