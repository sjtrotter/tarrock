namespace Tarrock.Player
{

    using Tarrock.Core;
    using UnityEngine;

    /// <summary>Region-local entry volume that requests the Player camera's one-shot shelf reveal.</summary>
    [DisallowMultipleComponent]
    public sealed class ShelfRevealTrigger : MonoBehaviour
    {
        [SerializeField] private VoidEventChannel _onEntered;

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
            _onEntered?.Raise();
        }
    }
}
