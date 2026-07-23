namespace Tarrock.Quests
{

    using System;
    using System.Collections.Generic;
    using Tarrock.WorldState;
    using UnityEngine;

    /// <summary>
    /// The runtime home of quest logic — a plain C# service with no Unity scene dependency, so
    /// the whole state machine is EditMode-testable (technical.md §Testing: "Quest logic is pure
    /// data + transitions ... quests are the only path that writes world state"). It mirrors the
    /// <c>WorldStateService</c> shape: constructed with its immutable definitions plus the
    /// <see cref="WorldStateService"/> it validates against and fires through, and it raises plain
    /// C# events toward gameplay (bridged onto event channels by a composition root, exactly as
    /// the WorldState service is). It is the single owner of quest mutation: definitions are read
    /// only, and world-state flags are committed <em>only</em> via <see cref="WorldStateService.Fire"/>,
    /// never touched directly.
    /// <para>
    /// Flow methods never throw for rejected calls — an out-of-order advance, an unmet
    /// requirement, or a double-complete returns <c>false</c> so callers branch on the result
    /// (exceptions are reserved for programmer error such as null construction arguments).
    /// </para>
    /// </summary>
    public sealed class QuestService
    {
        /// <summary>Current quest-save schema version stamped into every captured <see cref="QuestSaveData"/>.</summary>
        public const int CurrentSaveVersion = 1;

        // A fired flag is an Arcana unbinding iff its id ends with this suffix (world.md
        // §World-state matrix — the 21 *_UNBOUND flags). The same classifier the WorldState
        // test suite uses; keeps QuestDefinition.FiredStates a flat id list with no per-flag
        // bookkeeping. No MQ00 flag exercises this (MQ00 fires nothing), but later quests do.
        private const string UnbindingSuffix = "_UNBOUND";
        private const string WorldStatePrefix = "WS_";

        private readonly Dictionary<string, QuestDefinition> _definitions = new();
        private readonly Dictionary<string, QuestRuntime> _runtime = new();
        private readonly WorldStateService _worldState;

        /// <summary>Raised when a quest transitions to <see cref="QuestState.Active"/>, carrying its id.</summary>
        public event Action<string> QuestActivated;

        /// <summary>Raised on a successful step advance, carrying (questId, stepId).</summary>
        public event Action<string, string> StepAdvanced;

        /// <summary>Raised once when a quest reaches <see cref="QuestState.Complete"/>, carrying its id.</summary>
        public event Action<string> QuestCompleted;

        /// <summary>
        /// Constructs the service over its immutable <paramref name="definitions"/> and the
        /// <paramref name="worldState"/> it validates requirements against and fires flags through.
        /// </summary>
        public QuestService(IEnumerable<QuestDefinition> definitions, WorldStateService worldState)
        {
            _worldState = worldState ?? throw new ArgumentNullException(nameof(worldState));

            if (definitions == null)
            {
                throw new ArgumentNullException(nameof(definitions));
            }

            foreach (QuestDefinition definition in definitions)
            {
                if (definition == null || string.IsNullOrEmpty(definition.Id))
                {
                    continue;
                }

                _definitions[definition.Id] = definition;
            }
        }

        /// <summary>The current <see cref="QuestState"/> of a quest (<see cref="QuestState.Inactive"/> if untouched or unknown).</summary>
        public QuestState GetState(string questId)
        {
            return _runtime.TryGetValue(questId, out QuestRuntime runtime) ? runtime.State : QuestState.Inactive;
        }

        /// <summary>
        /// The quest's current required step — the next non-optional step to complete — or
        /// <c>null</c> if the quest is not active or every required step is done. Optional steps
        /// are never "current"; they may be advanced at any time while the quest is active.
        /// </summary>
        public QuestStepDefinition CurrentStep(string questId)
        {
            if (!_runtime.TryGetValue(questId, out QuestRuntime runtime) || runtime.State != QuestState.Active)
            {
                return null;
            }

            if (!_definitions.TryGetValue(questId, out QuestDefinition definition))
            {
                return null;
            }

            return RequiredStepAt(definition, runtime.RequiredStepIndex);
        }

        /// <summary>
        /// Attempts to move a quest from <see cref="QuestState.Inactive"/> to
        /// <see cref="QuestState.Active"/>. Rejected (returns <c>false</c>) if the quest is unknown,
        /// already active or complete, or any of its <see cref="QuestDefinition.RequiredStates"/> is
        /// unmet. A required id starting with <c>WS_</c> must be fired in world state; any other id
        /// is a quest id that must be <see cref="QuestState.Complete"/>.
        /// </summary>
        public bool TryActivate(string questId)
        {
            if (!_definitions.TryGetValue(questId, out QuestDefinition definition))
            {
                return false;
            }

            if (GetState(questId) != QuestState.Inactive)
            {
                return false;
            }

            if (!RequirementsMet(definition))
            {
                return false;
            }

            _runtime[questId] = new QuestRuntime { State = QuestState.Active, RequiredStepIndex = 0 };
            QuestActivated?.Invoke(questId);
            return true;
        }

        /// <summary>
        /// Advances a step of an active quest. A required step advances only when it is the
        /// current one (strict order); an optional step advances at any time and never blocks
        /// progress. Any other call — quest not active, unknown step id, an out-of-order required
        /// step, or re-advancing an already-completed step — is rejected with <c>false</c>.
        /// </summary>
        public bool AdvanceStep(string questId, string stepId)
        {
            if (string.IsNullOrEmpty(stepId))
            {
                return false;
            }

            if (!_runtime.TryGetValue(questId, out QuestRuntime runtime) || runtime.State != QuestState.Active)
            {
                return false;
            }

            if (!_definitions.TryGetValue(questId, out QuestDefinition definition))
            {
                return false;
            }

            QuestStepDefinition step = FindStep(definition, stepId);
            if (step == null)
            {
                return false;
            }

            if (step.Optional)
            {
                if (!runtime.CompletedOptional.Add(stepId))
                {
                    return false;
                }

                StepAdvanced?.Invoke(questId, stepId);
                return true;
            }

            QuestStepDefinition current = RequiredStepAt(definition, runtime.RequiredStepIndex);
            if (current == null || current.StepId != stepId)
            {
                return false;
            }

            runtime.RequiredStepIndex++;
            StepAdvanced?.Invoke(questId, stepId);
            return true;
        }

        /// <summary>
        /// Completes an active quest: commits every <see cref="QuestDefinition.FiredStates"/> flag
        /// through the WorldState service (exactly once) and transitions the quest to
        /// <see cref="QuestState.Complete"/>. Rejected with <c>false</c> if the quest is not
        /// currently active, so an already-complete quest can never re-fire its flags.
        /// </summary>
        public bool CompleteQuest(string questId)
        {
            if (!_runtime.TryGetValue(questId, out QuestRuntime runtime) || runtime.State != QuestState.Active)
            {
                return false;
            }

            if (!_definitions.TryGetValue(questId, out QuestDefinition definition))
            {
                return false;
            }

            runtime.State = QuestState.Complete;

            IReadOnlyList<string> fired = definition.FiredStates;
            if (fired != null)
            {
                foreach (string flag in fired)
                {
                    if (string.IsNullOrEmpty(flag))
                    {
                        continue;
                    }

                    _worldState.Fire(flag, isUnbinding: flag.EndsWith(UnbindingSuffix, StringComparison.Ordinal));
                }
            }

            QuestCompleted?.Invoke(questId);
            return true;
        }

        // --- Persistence ---------------------------------------------------------------------
        // Quest progress rides its own versioned save block (see QuestSaveData) rather than the
        // WorldState SaveData, because the asmdef dependency runs Quests -> WorldState only.

        /// <summary>Snapshots every non-<see cref="QuestState.Inactive"/> quest into a versioned save block.</summary>
        public QuestSaveData Capture()
        {
            var data = new QuestSaveData { Version = CurrentSaveVersion };
            foreach (KeyValuePair<string, QuestRuntime> pair in _runtime)
            {
                QuestRuntime runtime = pair.Value;
                if (runtime.State == QuestState.Inactive)
                {
                    continue;
                }

                data.Quests.Add(new QuestSaveEntry(
                    pair.Key,
                    runtime.State,
                    runtime.RequiredStepIndex,
                    new List<string>(runtime.CompletedOptional)));
            }

            return data;
        }

        /// <summary>
        /// Rebuilds runtime progress from a save block, migrating it to the current schema first.
        /// Replaces any existing runtime state (a load, not a merge).
        /// </summary>
        public void Restore(QuestSaveData data)
        {
            QuestSaveData migrated = QuestSaveMigrator.Migrate(data);
            _runtime.Clear();

            if (migrated.Quests == null)
            {
                return;
            }

            foreach (QuestSaveEntry entry in migrated.Quests)
            {
                if (entry == null || string.IsNullOrEmpty(entry.QuestId))
                {
                    continue;
                }

                var runtime = new QuestRuntime
                {
                    State = entry.State,
                    RequiredStepIndex = entry.CurrentStepIndex,
                };

                if (entry.CompletedOptionalStepIds != null)
                {
                    foreach (string optionalId in entry.CompletedOptionalStepIds)
                    {
                        runtime.CompletedOptional.Add(optionalId);
                    }
                }

                _runtime[entry.QuestId] = runtime;
            }
        }

        /// <summary>Serialises a quest save block to JSON (technical.md §Save system, versioned JSON).</summary>
        public string ToJson(QuestSaveData data) => JsonUtility.ToJson(data);

        /// <summary>Deserialises a quest save block from JSON.</summary>
        public QuestSaveData FromJson(string json) => JsonUtility.FromJson<QuestSaveData>(json);

        private bool RequirementsMet(QuestDefinition definition)
        {
            IReadOnlyList<string> required = definition.RequiredStates;
            if (required == null)
            {
                return true;
            }

            foreach (string id in required)
            {
                if (string.IsNullOrEmpty(id))
                {
                    continue;
                }

                bool satisfied = id.StartsWith(WorldStatePrefix, StringComparison.Ordinal)
                    ? _worldState.IsFired(id)
                    : GetState(id) == QuestState.Complete;

                if (!satisfied)
                {
                    return false;
                }
            }

            return true;
        }

        private static QuestStepDefinition FindStep(QuestDefinition definition, string stepId)
        {
            IReadOnlyList<QuestStepDefinition> steps = definition.Steps;
            if (steps == null)
            {
                return null;
            }

            foreach (QuestStepDefinition step in steps)
            {
                if (step != null && step.StepId == stepId)
                {
                    return step;
                }
            }

            return null;
        }

        // The current required step is the (index)-th non-optional step, in authored order.
        private static QuestStepDefinition RequiredStepAt(QuestDefinition definition, int index)
        {
            IReadOnlyList<QuestStepDefinition> steps = definition.Steps;
            if (steps == null || index < 0)
            {
                return null;
            }

            int seen = 0;
            foreach (QuestStepDefinition step in steps)
            {
                if (step == null || step.Optional)
                {
                    continue;
                }

                if (seen == index)
                {
                    return step;
                }

                seen++;
            }

            return null;
        }

        // Mutable per-quest progress, mirrored into QuestSaveEntry on capture. RequiredStepIndex
        // counts required steps completed (the index of the current required step).
        private sealed class QuestRuntime
        {
            public QuestState State;
            public int RequiredStepIndex;
            public readonly HashSet<string> CompletedOptional = new();
        }
    }
}
