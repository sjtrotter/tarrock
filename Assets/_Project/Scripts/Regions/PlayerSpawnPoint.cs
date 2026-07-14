namespace Tarrock.Regions
{

    using UnityEngine;

    /// <summary>
    /// Marker component for a location the player character should be placed at when a region
    /// scene loads (e.g. the Cliff's campfire wake-up spot, MQ00). Carries no placement logic
    /// itself — the region streaming loader (technical.md §World streaming) reads this
    /// transform to position the Fool once that system exists. Draws a readable gizmo (a
    /// sphere plus a forward-facing arrow) so designers can see position and facing in the
    /// Scene view without selecting the object.
    /// </summary>
    public sealed class PlayerSpawnPoint : MonoBehaviour
    {
        private const float GizmoRadius = 0.5f;
        private const float ArrowLength = 1.5f;
        private const float ArrowHeadLength = 0.35f;
        private const float ArrowHeadAngle = 150f;

        private static readonly Color GizmoColor = Color.cyan;

        private void OnDrawGizmos()
        {
            Gizmos.color = GizmoColor;
            Gizmos.DrawWireSphere(transform.position, GizmoRadius);

            Vector3 origin = transform.position;
            Vector3 tip = origin + (transform.forward * ArrowLength);
            Gizmos.DrawLine(origin, tip);

            Vector3 headRight = tip + (Quaternion.LookRotation(transform.forward) *
                Quaternion.Euler(0f, ArrowHeadAngle, 0f) * Vector3.forward * ArrowHeadLength);
            Vector3 headLeft = tip + (Quaternion.LookRotation(transform.forward) *
                Quaternion.Euler(0f, -ArrowHeadAngle, 0f) * Vector3.forward * ArrowHeadLength);
            Gizmos.DrawLine(tip, headRight);
            Gizmos.DrawLine(tip, headLeft);
        }
    }
}
