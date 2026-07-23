namespace Tarrock.Quests
{

    using System.Collections.Generic;
    using UnityEngine;

    /// <summary>
    /// The authored, runtime-immutable data asset for one quest — one asset per
    /// <c>docs/quests/**</c> file, its fields mapping 1:1 to that file's YAML frontmatter
    /// (docs/quests/README.md §Frontmatter schema; technical.md §Quests at runtime). It carries
    /// no logic: the <see cref="QuestService"/> reads it to gate activation, walk the ordered
    /// steps, and commit fired flags. Fields are exposed only through getters so definitions stay
    /// read-only during play; the mutable per-save progress lives in <see cref="QuestSaveEntry"/>.
    /// <para>
    /// <see cref="TitleKey"/> is a localization table key, never the display title itself — no
    /// player-facing string literal ever rides in a definition (technical.md §Localization).
    /// <see cref="RequiredStates"/> entries are either <c>WS_*</c> world-state ids or quest ids
    /// (a required quest must be <see cref="QuestState.Complete"/>); <see cref="FiredStates"/> are
    /// <c>WS_*</c> ids committed through the WorldState service on completion, never directly.
    /// </para>
    /// </summary>
    [CreateAssetMenu(menuName = "Tarrock/Quest Definition", fileName = "MQ00")]
    public sealed class QuestDefinition : ScriptableObject
    {
        [SerializeField] private string _id;
        [SerializeField] private string _titleKey;
        [SerializeField] private QuestType _type;
        [SerializeField] private string _arcana;
        [SerializeField] private string _region;
        [SerializeField] private string[] _requiredStates;
        [SerializeField] private string[] _firedStates;
        [SerializeField] private QuestStepDefinition[] _steps;

        /// <summary>The quest id (<c>MQ##</c> / <c>SQ-*</c>), identical to the doc's <c>id</c> frontmatter.</summary>
        public string Id => _id;

        /// <summary>Localization table key for the quest's display title — a key, not the title text.</summary>
        public string TitleKey => _titleKey;

        /// <summary>Main or Side (the <c>type</c> frontmatter key).</summary>
        public QuestType Type => _type;

        /// <summary>The card this quest belongs to (e.g. "I. The Magician"), or empty for "none".</summary>
        public string Arcana => _arcana;

        /// <summary>The home region name (GLOSSARY spelling), e.g. "The Cliff".</summary>
        public string Region => _region;

        /// <summary>
        /// Ids that must be satisfied before this quest can activate: <c>WS_*</c> flags (fired)
        /// and/or quest ids (completed). Empty for a quest with no prerequisites, like MQ00.
        /// </summary>
        public IReadOnlyList<string> RequiredStates => _requiredStates;

        /// <summary><c>WS_*</c> flags committed through the WorldState service on completion.</summary>
        public IReadOnlyList<string> FiredStates => _firedStates;

        /// <summary>The quest's ordered beat list.</summary>
        public IReadOnlyList<QuestStepDefinition> Steps => _steps;

    #if UNITY_EDITOR
        /// <summary>
        /// Editor-only authoring initialiser used by <c>Tarrock.Editor</c>'s quest generator to
        /// fill a freshly created asset from parsed frontmatter plus a hand-authored step list.
        /// Never called at runtime — definitions are immutable during play.
        /// </summary>
        public void EditorInitialize(
            string id,
            string titleKey,
            QuestType type,
            string arcana,
            string region,
            string[] requiredStates,
            string[] firedStates,
            QuestStepDefinition[] steps)
        {
            _id = id;
            _titleKey = titleKey;
            _type = type;
            _arcana = arcana;
            _region = region;
            _requiredStates = requiredStates ?? System.Array.Empty<string>();
            _firedStates = firedStates ?? System.Array.Empty<string>();
            _steps = steps ?? System.Array.Empty<QuestStepDefinition>();
        }
    #endif
    }
}
