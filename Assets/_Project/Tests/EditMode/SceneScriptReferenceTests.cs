namespace Tarrock.Tests.EditMode
{

    using System.Collections.Generic;
    using System.IO;
    using System.Text.RegularExpressions;
    using NUnit.Framework;
    using UnityEditor;

    /// <summary>
    /// Guards against the "referenced script (Unknown) is missing" class of failure: a scene
    /// serialized against script GUIDs that no longer (or never) exist on disk leaves every
    /// affected component a dead husk at runtime — input silently dead, triggers inert —
    /// with only console warnings to show for it. This test cross-checks every MonoBehaviour
    /// script reference in every project scene against the asset database, so a GUID split
    /// between a scene and the .meta files fails CI instead of shipping.
    /// </summary>
    public sealed class SceneScriptReferenceTests
    {
        private const string ScenesRoot = "Assets/_Project/Scenes";

        private static readonly Regex ScriptReference = new(
            @"m_Script: \{fileID: 11500000, guid: (?<guid>[0-9a-f]{32})", RegexOptions.Compiled);

        [Test]
        public void AllSceneScriptReferencesResolveToExistingScripts()
        {
            string[] scenes = Directory.GetFiles(ScenesRoot, "*.unity", SearchOption.AllDirectories);
            Assert.That(scenes, Is.Not.Empty, $"No scenes found under {ScenesRoot} — wrong path?");

            var failures = new List<string>();
            foreach (string scenePath in scenes)
            {
                foreach (Match match in ScriptReference.Matches(File.ReadAllText(scenePath)))
                {
                    string guid = match.Groups["guid"].Value;
                    string assetPath = AssetDatabase.GUIDToAssetPath(guid);
                    if (string.IsNullOrEmpty(assetPath))
                    {
                        failures.Add($"{scenePath}: references script guid {guid} which resolves to no asset");
                    }
                    else if (!assetPath.EndsWith(".cs") && !assetPath.EndsWith(".dll"))
                    {
                        failures.Add($"{scenePath}: script guid {guid} resolves to non-script '{assetPath}'");
                    }
                }
            }

            Assert.That(failures, Is.Empty,
                "Scene(s) reference missing scripts — rebuild the scene via Tarrock/Setup after " +
                "confirming .meta GUIDs are stable:\n" + string.Join("\n", failures));
        }

        /// <summary>
        /// Resolution alone is not enough: when Unity's script-class binder cannot map a class
        /// to its file (as happened with file-scoped namespaces), components are silently
        /// DROPPED from the scene at save — every reference that remains resolves fine, and the
        /// test above passes while the game is completely broken. This test pins the Cliff
        /// scene's required Tarrock components by presence.
        /// </summary>
        [Test]
        public void CliffSceneContainsRequiredTarrockComponents()
        {
            const string scenePath = ScenesRoot + "/Regions/Cliff.unity";
            Assert.That(File.Exists(scenePath), Is.True, $"Cliff scene missing at {scenePath}");
            string sceneText = File.ReadAllText(scenePath);

            string[] requiredScripts =
            {
                "Assets/_Project/Scripts/Player/PlayerInputReader.cs",
                "Assets/_Project/Scripts/Player/PlayerMotor.cs",
                "Assets/_Project/Scripts/Player/PlayerDodge.cs",
                "Assets/_Project/Scripts/Regions/LeapOfFaithTrigger.cs",
                "Assets/_Project/Scripts/Regions/PlayerSpawnPoint.cs",
            };

            var missing = new List<string>();
            foreach (string scriptPath in requiredScripts)
            {
                string guid = AssetDatabase.AssetPathToGUID(scriptPath);
                Assert.That(guid, Is.Not.Empty, $"Script asset not found: {scriptPath}");
                if (!sceneText.Contains(guid))
                {
                    missing.Add($"{scriptPath} (guid {guid})");
                }
            }

            Assert.That(missing, Is.Empty,
                "Cliff scene is missing required Tarrock components — if code compiles but " +
                "components vanish on save, suspect the script-class binder (see technical.md " +
                "§Coding conventions on namespaces):\n" + string.Join("\n", missing));
        }
    }
}
