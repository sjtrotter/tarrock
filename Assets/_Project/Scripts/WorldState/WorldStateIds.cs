namespace Tarrock.WorldState
{

    using System.Collections.Generic;
    using System.Reflection;

    /// <summary>
    /// The compile-time constant surface for every world-state flag id, mirroring
    /// world.md §World-state matrix (the 21 <c>*_UNBOUND</c> Arcana flags) and the branch
    /// flags fired by MQ01 and MQ06. Code references these constants instead of typing raw
    /// <c>WS_*</c> literals, satisfying the no-magic-strings rule (CLAUDE.md §3,
    /// technical.md §Coding conventions). The strings are identical to the matrix row ids;
    /// this class is the single place a literal appears.
    /// </summary>
    public static class WorldStateIds
    {
        // --- The 21 unbinding flags (world.md §World-state matrix, one per Major Arcana) ---
        public const string MagicianUnbound = "WS_MAGICIAN_UNBOUND";
        public const string PriestessUnbound = "WS_PRIESTESS_UNBOUND";
        public const string EmpressUnbound = "WS_EMPRESS_UNBOUND";
        public const string EmperorUnbound = "WS_EMPEROR_UNBOUND";
        public const string HierophantUnbound = "WS_HIEROPHANT_UNBOUND";
        public const string LoversUnbound = "WS_LOVERS_UNBOUND";
        public const string ChariotUnbound = "WS_CHARIOT_UNBOUND";
        public const string StrengthUnbound = "WS_STRENGTH_UNBOUND";
        public const string HermitUnbound = "WS_HERMIT_UNBOUND";
        public const string FortuneUnbound = "WS_FORTUNE_UNBOUND";
        public const string JusticeUnbound = "WS_JUSTICE_UNBOUND";
        public const string HangedManUnbound = "WS_HANGEDMAN_UNBOUND";
        public const string DeathUnbound = "WS_DEATH_UNBOUND";
        public const string TemperanceUnbound = "WS_TEMPERANCE_UNBOUND";
        public const string DevilUnbound = "WS_DEVIL_UNBOUND";
        public const string TowerUnbound = "WS_TOWER_UNBOUND";
        public const string StarUnbound = "WS_STAR_UNBOUND";
        public const string MoonUnbound = "WS_MOON_UNBOUND";
        public const string SunUnbound = "WS_SUN_UNBOUND";
        public const string JudgementUnbound = "WS_JUDGEMENT_UNBOUND";
        public const string WorldUnbound = "WS_WORLD_UNBOUND";

        // --- Branch flags (world.md §World-state matrix, mutually-exclusive per quote choice) ---
        // MQ01 troupe branch (WS_MAGICIAN_UNBOUND row); MQ06 union branch (WS_LOVERS_UNBOUND row).
        public const string TroupeTraveling = "WS_TROUPE_TRAVELING";
        public const string TroupeSettled = "WS_TROUPE_SETTLED";
        public const string DivideEastMarried = "WS_DIVIDE_EASTMARRIED";
        public const string DivideWestMarried = "WS_DIVIDE_WESTMARRIED";

        private static readonly string[] AllIds = BuildAllIds();

        /// <summary>
        /// Every declared flag id, discovered by reflection over the public constants above so
        /// that adding a constant automatically extends this list (and the drift canary test in
        /// the EditMode suite catches any mismatch with world.md's matrix count).
        /// </summary>
        public static IReadOnlyList<string> All => AllIds;

        private static string[] BuildAllIds()
        {
            FieldInfo[] fields = typeof(WorldStateIds).GetFields(BindingFlags.Public | BindingFlags.Static);
            var ids = new List<string>(fields.Length);
            foreach (FieldInfo field in fields)
            {
                if (field.IsLiteral && !field.IsInitOnly && field.FieldType == typeof(string))
                {
                    ids.Add((string)field.GetRawConstantValue());
                }
            }

            return ids.ToArray();
        }
    }
}
