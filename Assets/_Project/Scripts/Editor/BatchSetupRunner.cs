namespace Tarrock.Editor
{

    using UnityEditor;
    using UnityEditor.SceneManagement;
    using UnityEngine;

    /// <summary>
    /// Headless driver for the Tarrock/Setup installers, so the whole setup pass can run via
    /// <c>Unity -batchmode -executeMethod Tarrock.Editor.BatchSetupRunner.RunCliffHexSetup</c>
    /// without an interactive session. Opens the CliffHex scene, runs the quest-definition
    /// generator, the foliage-wind installer, and the Pip installer, then saves scene and assets.
    /// Each step logs loudly; a failure in any step throws so the batch run exits non-zero and
    /// the caller can read the log rather than trusting a silent pass.
    /// </summary>
    public static class BatchSetupRunner
    {
        private const string CliffHexScenePath = "Assets/_Project/Scenes/Regions/CliffHex.unity";

        public static void RunCliffHexSetup()
        {
            Debug.Log("[Tarrock.Batch] === CliffHex setup pass starting ===");

            Debug.Log("[Tarrock.Batch] Step 1/4: Generate Quest Definitions");
            QuestDefinitionGenerator.GenerateDefinitions();

            Debug.Log($"[Tarrock.Batch] Step 2/4: Open scene {CliffHexScenePath}");
            EditorSceneManager.OpenScene(CliffHexScenePath, OpenSceneMode.Single);

            Debug.Log("[Tarrock.Batch] Step 3/4: Install Foliage Wind");
            FoliageWindInstaller.Install();

            Debug.Log("[Tarrock.Batch] Step 4/4: Install Pip Beside Player");
            PipInstaller.Install();

            EditorSceneManager.SaveOpenScenes();
            AssetDatabase.SaveAssets();
            Debug.Log("[Tarrock.Batch] === CliffHex setup pass complete; scene and assets saved ===");
        }
    }
}
