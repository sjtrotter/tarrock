namespace Tarrock.Quests
{

    using Tarrock.WorldState;
    using UnityEngine;

    /// <summary>
    /// The Quests-side composition root: constructs the <see cref="QuestService"/> over the
    /// scene-authored definition list and the sanctioned <see cref="CompositionRoot"/>'s
    /// <see cref="WorldStateService"/>, then hands the live service to every
    /// <see cref="QuestStepBinder"/> in the loaded scenes. Lives in <c>Tarrock.Quests</c> because
    /// the WorldState composition root cannot reference this assembly (the dependency runs
    /// Quests → WorldState only — see QuestService's persistence note).
    /// <para>
    /// Initialization happens in <c>Start</c>, after every <c>Awake</c> (including
    /// <see cref="CompositionRoot"/>'s), so the world-state service is guaranteed constructed
    /// first. When no composition root exists — a region scene opened bare in the editor — the
    /// component logs once and stays inert; binders are already null-safe by design.
    /// </para>
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class QuestsRoot : MonoBehaviour
    {
        [Tooltip("Every quest definition this scene's content may reference. Generated assets " +
                 "live under Assets/_Project/Data/Quests (Tarrock/Setup/Generate Quest Definitions).")]
        [SerializeField] private QuestDefinition[] _definitions = new QuestDefinition[0];

        [Tooltip("Optional: a quest activated automatically once the service is up (e.g. MQ00 on " +
                 "the Cliff). Leave empty for scenes whose quests are activated by gameplay.")]
        [SerializeField] private QuestDefinition _autoActivate;

        /// <summary>The scene's live quest service, or null when no composition root was present.</summary>
        public static QuestService Service { get; private set; }

        private void Start()
        {
            if (CompositionRoot.Instance == null || CompositionRoot.Instance.WorldState == null)
            {
                Debug.LogWarning(
                    "[Tarrock] QuestsRoot found no CompositionRoot — quest service not constructed " +
                    "(expected when a region scene is opened bare in the editor).", this);
                return;
            }

            Service = new QuestService(_definitions, CompositionRoot.Instance.WorldState);

            QuestStepBinder[] binders =
                FindObjectsByType<QuestStepBinder>(FindObjectsInactive.Include, FindObjectsSortMode.None);
            foreach (QuestStepBinder binder in binders)
            {
                binder.Bind(Service);
            }

            if (_autoActivate != null)
            {
                Service.TryActivate(_autoActivate.Id);
            }
        }

        private void OnDestroy()
        {
            if (Service != null)
            {
                Service = null;
            }
        }
    }
}
