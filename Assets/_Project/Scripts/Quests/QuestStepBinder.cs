namespace Tarrock.Quests
{

    using Tarrock.Core;
    using UnityEngine;

    /// <summary>
    /// Scene-side glue that connects a placed marker/trigger to a quest step. It sits on the same
    /// GameObject as (or alongside) the beat's trigger, which raises a <see cref="VoidEventChannel"/>
    /// when the beat fires — the established decoupling idiom (see <c>LeapOfFaithTrigger</c>, which
    /// raises exactly such a channel). On that signal the binder calls
    /// <see cref="QuestService.AdvanceStep"/> for the configured quest and step.
    /// <para>
    /// The quest is referenced by <see cref="QuestDefinition"/> asset and the step by its string
    /// id (dropdown-free; a validation tool can later confirm <see cref="_stepId"/> names a real
    /// step of <see cref="_quest"/>). The live <see cref="QuestService"/> is injected via
    /// <see cref="Bind"/> by whatever composes the region scene, because the sanctioned composition
    /// root lives in <c>Tarrock.WorldState</c> and cannot reference this assembly. The binder is
    /// fully null-safe: with no channel wired or no service bound (e.g. an editor scene opened on
    /// its own) it simply does nothing.
    /// </para>
    /// </summary>
    public sealed class QuestStepBinder : MonoBehaviour
    {
        [SerializeField] private QuestDefinition _quest;
        [SerializeField] private string _stepId;
        [SerializeField] private VoidEventChannel _onStepTriggered;

        private QuestService _service;

        /// <summary>Injects the live quest service. Passing <c>null</c> unbinds (calls become no-ops).</summary>
        public void Bind(QuestService service) => _service = service;

        private void OnEnable()
        {
            if (_onStepTriggered != null)
            {
                _onStepTriggered.Subscribe(OnStepTriggered);
            }
        }

        private void OnDisable()
        {
            if (_onStepTriggered != null)
            {
                _onStepTriggered.Unsubscribe(OnStepTriggered);
            }
        }

        private void OnStepTriggered()
        {
            if (_service == null || _quest == null || string.IsNullOrEmpty(_stepId))
            {
                return;
            }

            _service.AdvanceStep(_quest.Id, _stepId);
        }
    }
}
