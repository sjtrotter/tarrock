namespace Tarrock.Quests
{

    using System;
    using UnityEngine;

    /// <summary>
    /// One authored step in a quest's ordered beat list — the data half of a scene hook. It
    /// carries no logic: a <see cref="QuestStepBinder"/> in the region scene resolves the
    /// behaviour by <see cref="MarkerId"/> (the same id an <c>InteractionMarker</c> / trigger
    /// carries, per technical.md's no-magic-strings rule) and, when the beat fires, tells the
    /// <see cref="QuestService"/> to advance this step by <see cref="StepId"/>.
    /// <para>
    /// A <see cref="Serializable"/> class rather than a struct so it nests inside
    /// <see cref="QuestDefinition"/>'s serialized array; fields are <c>[SerializeField] private</c>
    /// with read-only accessors so a definition stays immutable during play (technical.md
    /// §The runtime data model). The parameterless constructor exists for Unity's serializer;
    /// authored values are written once, in the editor, via <see cref="EditorInitialize"/>.
    /// </para>
    /// </summary>
    [Serializable]
    public sealed class QuestStepDefinition
    {
        [SerializeField] private string _stepId;
        [SerializeField] private string _markerId;
        [SerializeField] private StepKind _kind;
        [SerializeField] private string _dialogueKey;
        [SerializeField] private bool _optional;

        /// <summary>Unity serializer constructor. Author fields via <see cref="EditorInitialize"/>.</summary>
        public QuestStepDefinition()
        {
        }

        /// <summary>Stable id used to advance this step through <see cref="QuestService.AdvanceStep"/>.</summary>
        public string StepId => _stepId;

        /// <summary>
        /// The scene marker/trigger id this step binds to (a <c>CliffMarkerIds</c> constant for
        /// MQ00), or empty for steps with no placed marker (e.g. the opening wake beat).
        /// </summary>
        public string MarkerId => _markerId;

        /// <summary>How the step is satisfied (interact, reach a trigger, Pip Seek, dialogue, custom).</summary>
        public StepKind Kind => _kind;

        /// <summary>Localization table key for this step's line — a key, never player-facing text.</summary>
        public string DialogueKey => _dialogueKey;

        /// <summary>
        /// True for a side beat that may be completed in any order and never blocks quest
        /// progress (e.g. inspecting an old campsite, resting again at the Waystation).
        /// </summary>
        public bool Optional => _optional;

    #if UNITY_EDITOR
        /// <summary>
        /// Editor-only authoring initialiser, used by <c>Tarrock.Editor</c>'s quest generator.
        /// Never called at runtime — steps are immutable authored data during play.
        /// </summary>
        public void EditorInitialize(string stepId, string markerId, StepKind kind, string dialogueKey, bool optional)
        {
            _stepId = stepId;
            _markerId = markerId;
            _kind = kind;
            _dialogueKey = dialogueKey;
            _optional = optional;
        }
    #endif
    }
}
