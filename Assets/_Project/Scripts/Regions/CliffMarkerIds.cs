namespace Tarrock.Regions
{

    /// <summary>
    /// Stable marker ids for the Cliff's <see cref="InteractionMarker"/> instances, keyed to
    /// MQ00's beats (docs/quests/main/MQ00-the-leap.md). This is a runtime type, not an
    /// Editor-only one, so both the greybox generator (Tarrock.Editor's
    /// CliffGreyboxGenerator) and future quest/dialogue code share one literal per id — per
    /// technical.md §Coding conventions ("no magic strings").
    /// </summary>
    public static class CliffMarkerIds
    {
        /// <summary>The buried wooden-dog keepsake dig spot near the largest old campsite.</summary>
        public const string KeepsakeDigSpot = "MQ00_KEEPSAKE_DIGSPOT";

        /// <summary>The single dead tree on its knoll.</summary>
        public const string DeadTree = "MQ00_DEADTREE";

        /// <summary>The Cliff's Waystation shrine.</summary>
        public const string Waystation = "MQ00_WAYSTATION";

        /// <summary>The staged Blank ambush on the path before the Waystation.</summary>
        public const string BlankAmbush = "MQ00_BLANK_AMBUSH";

        /// <summary>The rim's midpoint, where the meadow simply stops.</summary>
        public const string CliffEdge = "MQ00_CLIFF_EDGE";
    }
}
