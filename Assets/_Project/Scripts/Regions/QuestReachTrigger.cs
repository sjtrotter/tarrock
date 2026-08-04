namespace Tarrock.Regions
{

    using Tarrock.Core;
    using Tarrock.Player;
    using UnityEngine;

    [RequireComponent(typeof(BoxCollider))]
    public sealed class QuestReachTrigger : MonoBehaviour
    {
        [SerializeField] private VoidEventChannel _onReached;

        private void Reset()
        {
            GetComponent<BoxCollider>().isTrigger = true;
        }

        private void OnTriggerEnter(Collider other)
        {
            if (other.GetComponentInParent<PlayerInputReader>() != null)
            {
                _onReached?.Raise();
            }
        }
    }
}
