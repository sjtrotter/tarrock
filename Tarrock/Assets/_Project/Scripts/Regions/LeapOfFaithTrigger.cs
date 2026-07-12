namespace Tarrock.Regions;

using Tarrock.Core;
using UnityEngine;

/// <summary>
/// MQ00's "cliff's edge leap" hook (docs/quests/main/MQ00-the-leap.md, "The Edge of the
/// World"): a trigger volume placed just past the Cliff's west rim. Stepping into it is
/// the player's deliberate step off the edge. This component only detects that moment and
/// announces it — the fall / skydive / Spread reveal / haywain landing sequence belongs to
/// a later cutscene system. For now it logs the event and, if wired in the Inspector,
/// raises a <see cref="VoidEventChannel"/> so other systems (dialogue, camera) can react
/// without holding a direct reference to this component.
/// </summary>
[RequireComponent(typeof(BoxCollider))]
public sealed class LeapOfFaithTrigger : MonoBehaviour
{
    private const string PlayerTag = "Player";

    [SerializeField] private VoidEventChannel _onLeapTriggered;

    private void Reset()
    {
        GetComponent<BoxCollider>().isTrigger = true;
    }

    private void OnTriggerEnter(Collider other)
    {
        if (!other.CompareTag(PlayerTag))
        {
            return;
        }

        Debug.Log("[Tarrock] Leap of Faith triggered (MQ00, docs/quests/main/MQ00-the-leap.md " +
                  "\"The Edge of the World\") — the Fool steps off the Cliff.", this);
        _onLeapTriggered?.Raise();
    }
}
