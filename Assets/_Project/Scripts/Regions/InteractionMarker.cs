namespace Tarrock.Regions
{

    using UnityEngine;
    #if UNITY_EDITOR
    using UnityEditor;
    #endif

    /// <summary>
    /// Generic labeled marker for quest-relevant spots authored into a region's greybox (e.g.
    /// MQ00's buried-keepsake dig spot, the dead tree, the Waystation — see
    /// docs/quests/main/MQ00-the-leap.md). Carries no gameplay logic of its own; quest and
    /// interaction systems resolve behaviour by <see cref="MarkerId"/> once they exist. Ids are
    /// expected to come from a runtime constants class (e.g. <see cref="CliffMarkerIds"/>)
    /// rather than being typed as raw literals at the call site, per technical.md's
    /// no-magic-strings rule.
    /// </summary>
    public sealed class InteractionMarker : MonoBehaviour
    {
        [SerializeField] private string _markerId;

        /// <summary>The stable id other systems use to look this marker up.</summary>
        public string MarkerId => _markerId;

    #if UNITY_EDITOR
        private void OnDrawGizmos()
        {
            Handles.Label(transform.position + (Vector3.up * 0.5f),
                string.IsNullOrEmpty(_markerId) ? name : _markerId);
        }
    #endif
    }
}
