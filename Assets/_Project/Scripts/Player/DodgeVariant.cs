namespace Tarrock.Player
{

    /// <summary>
    /// Which flavour of directional dodge a Focus-stance dodge resolves to (combat.md §Focus:
    /// "the dodge input is directional: forward or neutral = the dodge roll; left/right = a
    /// strafing side-hop; backward = a backflip"). Out of Focus the dodge input is a jump instead
    /// and never produces a variant. The variant selects the Dodge_* clip (via DodgeX/DodgeY) and
    /// tells <see cref="PlayerAnimationDriver"/> whether — and which way — to spin the procedural
    /// tumble.
    /// </summary>
    public enum DodgeVariant
    {
        /// <summary>Forward or neutral: the standard roll with the head-over-heels procedural tumble.</summary>
        Roll,

        /// <summary>Leftward strafe-hop: Dodge_Left clip, shorter distance, no tumble.</summary>
        HopLeft,

        /// <summary>Rightward strafe-hop: Dodge_Right clip, shorter distance, no tumble.</summary>
        HopRight,

        /// <summary>Backward: Dodge_Backward clip with a REVERSED procedural flip (backflip).</summary>
        Backflip,
    }
}
