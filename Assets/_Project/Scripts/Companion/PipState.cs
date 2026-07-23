namespace Tarrock.Companion
{

    /// <summary>
    /// The behaviour states of Pip, the Fool's white dog companion (characters.md §Pip — a constant
    /// presence, "alert, game, entirely present"). Drives <see cref="PipController"/>'s steering and,
    /// by logical name, the animator (art-audio.md §Current build rule 4: gameplay addresses
    /// animation by state, not clip). Combat commands (combat.md §Pip — Fetch/Harry) are out of
    /// scope for this controller; only the follow/traversal states live here.
    /// </summary>
    public enum PipState
    {
        /// <summary>Default: follow the Fool a settled distance behind, beside — never into — him.</summary>
        Heel,

        /// <summary>Loose exploratory lead: wander near the Fool when he stands idle in a safe space.</summary>
        RangeAhead,

        /// <summary>Move to a target point/marker and perform there (combat.md §Pip — Seek).</summary>
        Seek,

        /// <summary>Park on a marker and play the dig (art-audio.md rule 4 logical "Dig" state).</summary>
        Dig,

        /// <summary>Sit on the spot and hold.</summary>
        Sit,

        /// <summary>Reserved for the combat retreat/yelp beat (combat.md §Pip); not yet implemented.</summary>
        Retreat,
    }
}
