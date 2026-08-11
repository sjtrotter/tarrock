namespace Tarrock.Regions
{

    using UnityEngine;

    /// <summary>
    /// The cloud deck's catch volume: anything with a CharacterController that falls past the deck
    /// has left the world, and is returned to the respawn point. PROTO STAND-IN for the defeat loop
    /// (combat.md §Defeat — the fall, the lick, the wake at the last Waystation): when the defeat
    /// sequence is wired, it replaces the teleport here; the trigger itself stays, because "below
    /// the cloud sea" is canonically not a place (world.md §The Cliff). The deck's render surface
    /// carries no walkable collider — clouds are an ending, not a floor.
    /// </summary>
    public sealed class CloudFallCatch : MonoBehaviour
    {
        [Tooltip("Where a fallen body wakes. Set by the region generator/installer; stands in " +
                 "for 'the last Waystation' until the defeat loop owns this.")]
        [SerializeField] private Vector3 _respawnPoint;

        private void OnTriggerEnter(Collider other)
        {
            var controller = other.GetComponent<CharacterController>();
            if (controller == null)
            {
                return;
            }

            // A CharacterController must be disabled across a teleport or it stays at the old
            // position internally and snaps back on the next Move.
            controller.enabled = false;
            other.transform.position = _respawnPoint;
            controller.enabled = true;
        }
    }
}
