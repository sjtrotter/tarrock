namespace Tarrock.Player
{

    using UnityEngine;

    /// <summary>Region-local entry volume that requests the Player camera's one-shot shelf reveal.</summary>
    [DisallowMultipleComponent]
    public sealed class ShelfRevealTrigger : MonoBehaviour
    {
        private ShelfRevealCameraNudge _nudge;

        private void OnTriggerEnter(Collider other)
        {
            if (other.GetComponentInParent<PlayerInputReader>() == null)
            {
                return;
            }

            if (_nudge == null)
            {
                _nudge = FindFirstObjectByType<ShelfRevealCameraNudge>();
            }

            _nudge?.TryBeginReveal();
        }
    }
}
