namespace Tarrock.Regions
{

    using Tarrock.Companion;
    using Tarrock.Quests;
    using UnityEngine;

    /// <summary>
    /// Scene glue for MQ00's keepsake beat (docs/quests/main/MQ00-the-leap.md, the whittled wooden
    /// dog): when the Fool first comes within range of the dig-spot marker, Pip runs to it of his
    /// own accord and digs — "sudden, businesslike enthusiasm" — and the quest's keepsake step
    /// advances once the digging has had its moment. The keepsake pickup/inspect interaction (and
    /// the Querent dialogue around it) belongs to the coming interaction layer; this component owns
    /// only the dog's half of the beat.
    /// <para>
    /// Quest wiring is optional by design: with no <see cref="QuestsRoot"/> service in the scene
    /// the dig still plays (the beat degrades to pure flavor), and step ids are inspector data on
    /// the same pattern as <see cref="RegionWind"/>'s region-state id. Because nothing yet advances
    /// MQ00's opening WAKE step (the real wake-at-the-campfire beat is the interaction layer's),
    /// <see cref="_autoAdvanceOnStart"/> bridges it so the keepsake step is reachable — remove that
    /// wiring once the wake beat exists.
    /// </para>
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class CliffKeepsakeSequence : MonoBehaviour
    {
        private enum Phase { Waiting, Seeking, Digging, Done }

        [Header("Scene references")]
        [SerializeField] private InteractionMarker _digMarker;
        [SerializeField] private PipController _pip;
        [SerializeField] private Transform _player;

        [Header("Tuning")]
        [Tooltip("How close the Fool must come to the dig spot before Pip breaks off to dig.")]
        [SerializeField] private float _triggerRadius = 6f;
        [Tooltip("How long Pip digs before the beat completes and he returns to heel.")]
        [SerializeField] private float _digSeconds = 2.5f;

        [Header("Quest wiring (optional — inspector data, not code literals)")]
        [SerializeField] private string _questId = string.Empty;
        [SerializeField] private string _stepId = string.Empty;
        [Tooltip("A step advanced on Start so this beat is reachable (MQ00's WAKE placeholder). " +
                 "Clear once the real wake beat advances it.")]
        [SerializeField] private string _autoAdvanceOnStart = string.Empty;

        private Phase _phase = Phase.Waiting;
        private float _digTimer;

        private void Start()
        {
            if (QuestsRoot.Service != null && !string.IsNullOrEmpty(_questId) &&
                !string.IsNullOrEmpty(_autoAdvanceOnStart))
            {
                QuestsRoot.Service.AdvanceStep(_questId, _autoAdvanceOnStart);
            }
        }

        private void OnEnable()
        {
            if (_pip != null)
            {
                _pip.StateCompleted += OnPipStateCompleted;
            }
        }

        private void OnDisable()
        {
            if (_pip != null)
            {
                _pip.StateCompleted -= OnPipStateCompleted;
            }
        }

        private void Update()
        {
            if (_digMarker == null || _pip == null || _player == null)
            {
                return;
            }

            if (_phase == Phase.Waiting)
            {
                Vector3 toMarker = _player.position - _digMarker.transform.position;
                toMarker.y = 0f;
                if (toMarker.sqrMagnitude <= _triggerRadius * _triggerRadius)
                {
                    _phase = Phase.Seeking;
                    _pip.Seek(_digMarker.transform.position);
                }
            }
            else if (_phase == Phase.Digging)
            {
                _digTimer -= Time.deltaTime;
                if (_digTimer <= 0f)
                {
                    CompleteBeat();
                }
            }
        }

        private void OnPipStateCompleted(PipState state)
        {
            if (_phase == Phase.Seeking && state == PipState.Seek)
            {
                _phase = Phase.Digging;
                _digTimer = _digSeconds;
                _pip.Dig(_digMarker.transform.position);
            }
        }

        private void CompleteBeat()
        {
            _phase = Phase.Done;
            _pip.Heel();

            if (QuestsRoot.Service != null && !string.IsNullOrEmpty(_questId) &&
                !string.IsNullOrEmpty(_stepId))
            {
                QuestsRoot.Service.AdvanceStep(_questId, _stepId);
            }
        }
    }
}
