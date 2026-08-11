namespace Tarrock.Editor
{

    using System.Collections.Generic;
    using Tarrock.WorldState;
    using UnityEditor;
    using UnityEngine;

    /// <summary>
    /// The docs↔data validation tool technical.md §The runtime data model promises: it checks
    /// that the set of <see cref="WorldStateDefinition"/> assets matches the canonical
    /// <see cref="WorldStateIds"/> constants exactly, logging an error for any drift in either
    /// direction (an asset id with no matching constant, or a constant with no asset).
    /// </summary>
    public static class WorldStateIdValidator
    {
        [MenuItem("Tarrock/Validate/World State Ids")]
        public static void ValidateWorldStateIds()
        {
            var known = new HashSet<string>(WorldStateIds.All);
            var assetIds = new HashSet<string>();
            int errors = 0;

            string[] guids = AssetDatabase.FindAssets($"t:{nameof(WorldStateDefinition)}");
            foreach (string guid in guids)
            {
                string path = AssetDatabase.GUIDToAssetPath(guid);
                var definition = AssetDatabase.LoadAssetAtPath<WorldStateDefinition>(path);
                if (definition == null)
                {
                    continue;
                }

                string id = definition.Id;
                if (string.IsNullOrEmpty(id) || !known.Contains(id))
                {
                    Debug.LogError($"[Tarrock] WorldStateDefinition at {path} has id '{id}' " +
                                   "not present in WorldStateIds (world.md §World-state matrix).", definition);
                    errors++;
                }

                if (!string.IsNullOrEmpty(id) && !assetIds.Add(id))
                {
                    Debug.LogError($"[Tarrock] Duplicate WorldStateDefinition id '{id}' at {path}.", definition);
                    errors++;
                }
            }

            foreach (string id in known)
            {
                if (!assetIds.Contains(id))
                {
                    Debug.LogError($"[Tarrock] WorldStateIds declares '{id}' but no WorldStateDefinition " +
                                   "asset exists for it. Run Tarrock/Setup/Generate WorldState Definitions.");
                    errors++;
                }
            }

            if (errors == 0)
            {
                Debug.Log($"[Tarrock] World-state id validation passed: {assetIds.Count} definitions match " +
                          $"{known.Count} declared ids.");
            }
            else
            {
                Debug.LogError($"[Tarrock] World-state id validation found {errors} problem(s).");
            }
        }
    }
}
