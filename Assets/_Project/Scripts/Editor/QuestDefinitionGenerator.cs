namespace Tarrock.Editor
{

    using System.Collections.Generic;
    using System.IO;
    using Tarrock.Quests;
    using Tarrock.Regions;
    using UnityEditor;
    using UnityEngine;

    /// <summary>
    /// Editor command that materialises <see cref="QuestDefinition"/> assets from the quest docs,
    /// mirroring <see cref="WorldStateDefinitionGenerator"/> (docs → data, idempotent, one asset
    /// per doc). It parses the YAML frontmatter of the quest markdown with a minimal hand-rolled
    /// reader (no YAML package dependency) for <c>id / title / type / arcana / region / requires /
    /// fires</c>, then attaches a hand-authored ordered step list defined as code constants below.
    /// <para>
    /// Step marker ids come from <see cref="CliffMarkerIds"/> so the generated data shares one
    /// literal per scene marker (no-magic-strings rule). <see cref="QuestDefinition.TitleKey"/> is
    /// set to a localization key derived from the id — the doc's English <c>title</c> is used only
    /// for the log line, never stored, so no player-facing string enters the data.
    /// </para>
    /// </summary>
    public static class QuestDefinitionGenerator
    {
        // Convention note: generated content assets live under Data/ (technical.md §Assets/ folder
        // tree; WorldStateDefinitionGenerator writes to Data/WorldStates). Kept a single constant
        // so the location is trivial to retarget if the project standardises on Content/ instead.
        private const string OutputDirectory = "Assets/_Project/Data/Quests";
        private const string Mq00DocPath = "docs/quests/main/MQ00-the-leap.md";

        // --- MQ00 step ids (code constants for now; a runtime constants surface can adopt these
        //     once more quests are scaffolded). Ordered required steps plus two optional beats. ---
        private const string StepWake = "MQ00_STEP_WAKE";
        private const string StepBindle = "MQ00_STEP_BINDLE";
        private const string StepCampsiteInspect = "MQ00_STEP_CAMPSITE_INSPECT";
        private const string StepKeepsake = "MQ00_STEP_KEEPSAKE";
        private const string StepDeadTree = "MQ00_STEP_DEADTREE";
        private const string StepBlankAmbush = "MQ00_STEP_BLANK_AMBUSH";
        private const string StepWaystation = "MQ00_STEP_WAYSTATION";
        private const string StepWaystationRestAgain = "MQ00_STEP_WAYSTATION_REST_AGAIN";
        private const string StepEdge = "MQ00_STEP_EDGE";
        private const string StepLeap = "MQ00_STEP_LEAP";

        // Localization table keys for each beat's Querent line (keys, never player-facing text).
        private const string KeyWake = "MQ00.QUERENT.WAKE";
        private const string KeyKeepsake = "MQ00.QUERENT.KEEPSAKE";
        private const string KeyDeadTree = "MQ00.QUERENT.DEADTREE";
        private const string KeyBlanks = "MQ00.QUERENT.BLANKS";
        private const string KeyWaystation = "MQ00.QUERENT.WAYSTATION";
        private const string KeyWaystationRandom = "MQ00.QUERENT.WAYSTATION_RANDOM";
        private const string KeyEdge = "MQ00.QUERENT.EDGE";
        private const string KeyLeap = "MQ00.QUERENT.LEAP";

        [MenuItem("Tarrock/Setup/Generate Quest Definitions")]
        public static void GenerateDefinitions()
        {
            Directory.CreateDirectory(OutputDirectory);

            string docPath = Path.Combine(Directory.GetCurrentDirectory(), Mq00DocPath);
            if (!File.Exists(docPath))
            {
                Debug.LogError($"[Tarrock] Quest doc not found at {Mq00DocPath}; cannot generate MQ00.");
                return;
            }

            Frontmatter fm = ParseFrontmatter(File.ReadAllLines(docPath));
            if (string.IsNullOrEmpty(fm.Id))
            {
                Debug.LogError($"[Tarrock] {Mq00DocPath} frontmatter has no 'id'; cannot generate MQ00.");
                return;
            }

            string path = $"{OutputDirectory}/{fm.Id}.asset";
            if (AssetDatabase.LoadAssetAtPath<QuestDefinition>(path) != null)
            {
                Debug.Log($"[Tarrock] Quest definition {fm.Id} already exists at {path}; skipped.");
                return;
            }

            var definition = ScriptableObject.CreateInstance<QuestDefinition>();
            definition.EditorInitialize(
                fm.Id,
                $"{fm.Id}.TITLE",
                ParseType(fm.Type),
                fm.Arcana == "none" ? string.Empty : fm.Arcana,
                fm.Region,
                fm.Requires.ToArray(),
                fm.Fires.ToArray(),
                BuildMq00Steps());

            AssetDatabase.CreateAsset(definition, path);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Debug.Log($"[Tarrock] Generated quest definition {fm.Id} (\"{fm.Title}\") at {path} " +
                      $"with {definition.Steps.Count} steps, requires [{string.Join(", ", fm.Requires)}], " +
                      $"fires [{string.Join(", ", fm.Fires)}].");
        }

        // MQ00's beats in play order (docs/quests/main/MQ00-the-leap.md). Two beats are optional
        // side interactions that never block the leap: inspecting an old campsite, and resting a
        // second time at the Waystation for its Random Lines.
        private static QuestStepDefinition[] BuildMq00Steps()
        {
            return new[]
            {
                MakeStep(StepWake, string.Empty, StepKind.Custom, KeyWake, optional: false),
                MakeStep(StepBindle, string.Empty, StepKind.Custom, string.Empty, optional: false),
                MakeStep(StepCampsiteInspect, CliffMarkerIds.CampsiteInspect, StepKind.Interact, string.Empty, optional: true),
                MakeStep(StepKeepsake, CliffMarkerIds.KeepsakeDigSpot, StepKind.PipSeek, KeyKeepsake, optional: false),
                MakeStep(StepDeadTree, CliffMarkerIds.DeadTree, StepKind.Dialogue, KeyDeadTree, optional: false),
                MakeStep(StepBlankAmbush, CliffMarkerIds.BlankAmbush, StepKind.ReachTrigger, KeyBlanks, optional: false),
                MakeStep(StepWaystation, CliffMarkerIds.Waystation, StepKind.Interact, KeyWaystation, optional: false),
                MakeStep(StepWaystationRestAgain, CliffMarkerIds.Waystation, StepKind.Interact, KeyWaystationRandom, optional: true),
                MakeStep(StepEdge, CliffMarkerIds.CliffEdge, StepKind.Dialogue, KeyEdge, optional: false),
                MakeStep(StepLeap, CliffMarkerIds.CliffEdge, StepKind.ReachTrigger, KeyLeap, optional: false),
            };
        }

        private static QuestStepDefinition MakeStep(string stepId, string markerId, StepKind kind, string dialogueKey, bool optional)
        {
            var step = new QuestStepDefinition();
            step.EditorInitialize(stepId, markerId, kind, dialogueKey, optional);
            return step;
        }

        private static QuestType ParseType(string type)
        {
            return string.Equals(type, "side", System.StringComparison.OrdinalIgnoreCase)
                ? QuestType.Side
                : QuestType.Main;
        }

        // --- Minimal frontmatter reader (id/title/type/arcana/region/requires/fires only) -------

        private static Frontmatter ParseFrontmatter(string[] lines)
        {
            var fm = new Frontmatter();
            bool inBlock = false;

            foreach (string raw in lines)
            {
                string line = raw.TrimEnd();
                if (line == "---")
                {
                    if (!inBlock)
                    {
                        inBlock = true;
                        continue;
                    }

                    break; // end of frontmatter block
                }

                if (!inBlock)
                {
                    continue;
                }

                int colon = line.IndexOf(':');
                if (colon < 0)
                {
                    continue;
                }

                string key = line.Substring(0, colon).Trim();
                string value = StripComment(line.Substring(colon + 1)).Trim();

                switch (key)
                {
                    case "id": fm.Id = value; break;
                    case "title": fm.Title = value; break;
                    case "type": fm.Type = value; break;
                    case "arcana": fm.Arcana = value; break;
                    case "region": fm.Region = value; break;
                    case "requires": fm.Requires = ParseInlineList(value); break;
                    case "fires": fm.Fires = ParseInlineList(value); break;
                }
            }

            return fm;
        }

        // Drops a trailing "# comment" while leaving inline-list brackets intact.
        private static string StripComment(string value)
        {
            int hash = value.IndexOf('#');
            return hash < 0 ? value : value.Substring(0, hash);
        }

        // Parses a YAML inline list like "[]" or "[WS_A, WS_B]". Block-style lists are not used by
        // MQ00 and are out of scope for this minimal reader.
        private static List<string> ParseInlineList(string value)
        {
            var list = new List<string>();
            value = value.Trim();
            if (value.StartsWith("[") && value.EndsWith("]"))
            {
                value = value.Substring(1, value.Length - 2);
            }

            foreach (string part in value.Split(','))
            {
                string item = part.Trim();
                if (item.Length > 0)
                {
                    list.Add(item);
                }
            }

            return list;
        }

        private sealed class Frontmatter
        {
            public string Id = string.Empty;
            public string Title = string.Empty;
            public string Type = string.Empty;
            public string Arcana = string.Empty;
            public string Region = string.Empty;
            public List<string> Requires = new();
            public List<string> Fires = new();
        }
    }
}
