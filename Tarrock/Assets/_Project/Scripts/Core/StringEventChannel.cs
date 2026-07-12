namespace Tarrock.Core;

using UnityEngine;

/// <summary>
/// Event channel carrying a string payload. Its canonical use is broadcasting a fired
/// world-state id (a <c>WS_*</c> string) out of the WorldState service so decoupled
/// listeners — ambient bark pools, shop pricing, region dressing — can react without a
/// direct reference to the service (technical.md §The WorldState service, "Events").
/// </summary>
[CreateAssetMenu(menuName = "Tarrock/Events/String Event Channel", fileName = "StringEventChannel")]
public sealed class StringEventChannel : EventChannel<string>
{
}
