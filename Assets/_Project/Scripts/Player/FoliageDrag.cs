namespace Tarrock.Player
{

    using UnityEngine;

    /// <summary>
    /// A trigger-relay for a SHORT bush's foliage volume (combat.md §Focus foliage note; the
    /// short-bush tier the Cliff generator places): while the Fool's capsule overlaps, the bush
    /// slows the walk to the walk tier. This component carries no policy of its own — it forwards
    /// enter/exit to <see cref="PlayerMotor.EnterFoliage"/>/<see cref="PlayerMotor.ExitFoliage"/>,
    /// which owns the speed clamp (and reference-counts overlapping bushes so nested foliage does
    /// not un-slow early).
    ///
    /// Sits on a trigger collider (world-scale-1, sized to the bush) authored by the generator, not
    /// on the visual bush itself, so the bush's non-uniform prop scale never distorts the volume.
    /// </summary>
    [RequireComponent(typeof(Collider))]
    public sealed class FoliageDrag : MonoBehaviour
    {
        // TBD (bush-cutting, future feature the director floated): a cuttable-bush component would
        // attach alongside this relay here — the trigger volume that slows the Fool is also the
        // volume a cut would clear. Left as a hook; not implemented this pass.

        private void OnTriggerEnter(Collider other)
        {
            PlayerMotor motor = other.GetComponentInParent<PlayerMotor>();
            if (motor != null)
            {
                motor.EnterFoliage();
            }
        }

        private void OnTriggerExit(Collider other)
        {
            PlayerMotor motor = other.GetComponentInParent<PlayerMotor>();
            if (motor != null)
            {
                motor.ExitFoliage();
            }
        }
    }
}
