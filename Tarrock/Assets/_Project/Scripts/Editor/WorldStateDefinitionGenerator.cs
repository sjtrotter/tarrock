namespace Tarrock.Editor;

using System.IO;
using Tarrock.WorldState;
using UnityEditor;
using UnityEngine;

/// <summary>
/// Editor command that materialises one <see cref="WorldStateDefinition"/> asset per
/// world-state id under <c>Data/WorldStates/</c>, filling in the unbinding flag and Arcana
/// numeral from world.md §World-state matrix. Idempotent — existing assets are skipped, so
/// re-running only adds any that are missing. The id→numeral table below is the authoring
/// source for generation; the constant ids themselves come from <see cref="WorldStateIds"/>.
/// </summary>
public static class WorldStateDefinitionGenerator
{
    private const string OutputDirectory = "Assets/_Project/Data/WorldStates";
    private const string DesignNoteUnbinding =
        "world.md §World-state matrix — Arcana unbinding flag. Effect summary lives in the matrix row.";
    private const string DesignNoteBranch =
        "world.md §World-state matrix — mutually-exclusive branch flag set by player choice.";

    // The 21 unbinding flags paired with their Major Arcana numerals (world.md matrix order).
    private static readonly (string Id, string Numeral)[] Unbindings =
    {
        (WorldStateIds.MagicianUnbound, "I"),
        (WorldStateIds.PriestessUnbound, "II"),
        (WorldStateIds.EmpressUnbound, "III"),
        (WorldStateIds.EmperorUnbound, "IV"),
        (WorldStateIds.HierophantUnbound, "V"),
        (WorldStateIds.LoversUnbound, "VI"),
        (WorldStateIds.ChariotUnbound, "VII"),
        (WorldStateIds.StrengthUnbound, "VIII"),
        (WorldStateIds.HermitUnbound, "IX"),
        (WorldStateIds.FortuneUnbound, "X"),
        (WorldStateIds.JusticeUnbound, "XI"),
        (WorldStateIds.HangedManUnbound, "XII"),
        (WorldStateIds.DeathUnbound, "XIII"),
        (WorldStateIds.TemperanceUnbound, "XIV"),
        (WorldStateIds.DevilUnbound, "XV"),
        (WorldStateIds.TowerUnbound, "XVI"),
        (WorldStateIds.StarUnbound, "XVII"),
        (WorldStateIds.MoonUnbound, "XVIII"),
        (WorldStateIds.SunUnbound, "XIX"),
        (WorldStateIds.JudgementUnbound, "XX"),
        (WorldStateIds.WorldUnbound, "XXI"),
    };

    private static readonly string[] Branches =
    {
        WorldStateIds.TroupeTraveling,
        WorldStateIds.TroupeSettled,
        WorldStateIds.DivideEastMarried,
        WorldStateIds.DivideWestMarried,
    };

    [MenuItem("Tarrock/Setup/Generate WorldState Definitions")]
    public static void GenerateDefinitions()
    {
        Directory.CreateDirectory(OutputDirectory);

        int created = 0;
        int skipped = 0;

        foreach ((string id, string numeral) in Unbindings)
        {
            if (CreateDefinition(id, isUnbinding: true, arcanaNumeral: numeral, designNote: DesignNoteUnbinding))
            {
                created++;
            }
            else
            {
                skipped++;
            }
        }

        foreach (string id in Branches)
        {
            if (CreateDefinition(id, isUnbinding: false, arcanaNumeral: string.Empty, designNote: DesignNoteBranch))
            {
                created++;
            }
            else
            {
                skipped++;
            }
        }

        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log($"[Tarrock] WorldState definitions: {created} created, {skipped} already existed.");
    }

    private static bool CreateDefinition(string id, bool isUnbinding, string arcanaNumeral, string designNote)
    {
        string path = $"{OutputDirectory}/{id}.asset";
        if (AssetDatabase.LoadAssetAtPath<WorldStateDefinition>(path) != null)
        {
            return false;
        }

        var definition = ScriptableObject.CreateInstance<WorldStateDefinition>();
        definition.EditorInitialize(id, isUnbinding, arcanaNumeral, designNote);
        AssetDatabase.CreateAsset(definition, path);
        return true;
    }
}
