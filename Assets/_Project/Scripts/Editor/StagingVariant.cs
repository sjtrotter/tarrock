namespace Tarrock.Editor
{
    using System;
    using UnityEngine;

    public enum CliffStagingVariant
    {
        Baseline,
        RaisedLane,
        TreeMovedInward,
    }

    internal static class StagingVariantResolver
    {
        private const CliffStagingVariant Default = CliffStagingVariant.Baseline;
        private static readonly CliffStagingVariant ResolvedValue = Resolve();

        public static CliffStagingVariant Current => ResolvedValue;

        public static Vector2 DeadTreePosition
        {
            get
            {
                const float KnollX = 150f;
                const float KnollZ = 58f;
                const float InwardMoveMetres = 11f;
                const float InwardMoveBearing = 275f;
                var baseline = new Vector2(KnollX, KnollZ);
                if (Current != CliffStagingVariant.TreeMovedInward)
                {
                    return baseline;
                }

                float radians = InwardMoveBearing * Mathf.Deg2Rad;
                return baseline
                    + new Vector2(Mathf.Sin(radians), Mathf.Cos(radians)) * InwardMoveMetres;
            }
        }

        private static CliffStagingVariant Resolve()
        {
            string value = Environment.GetEnvironmentVariable("TARROCK_STAGING_VARIANT");
            if (string.Equals(value, "A", StringComparison.OrdinalIgnoreCase))
            {
                return CliffStagingVariant.RaisedLane;
            }

            if (string.Equals(value, "B", StringComparison.OrdinalIgnoreCase))
            {
                return CliffStagingVariant.TreeMovedInward;
            }

            return Default;
        }
    }
}
