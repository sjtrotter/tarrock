namespace Tarrock.Editor
{

    using UnityEditor;
    using UnityEngine;

    /// <summary>
    /// One-shot editor/import performance settings (menu or headless). Import parallelism and
    /// async shader compilation shorten both GUI startup-adjacent imports and the headless
    /// validation runs agents depend on. Idempotent; safe to re-run.
    /// </summary>
    public static class ProjectOptimizer
    {
        [MenuItem("Tarrock/Setup/Apply Editor Performance Settings")]
        public static void Apply()
        {
            EditorSettings.refreshImportMode = AssetDatabase.RefreshImportMode.OutOfProcessPerQueue;
            EditorSettings.asyncShaderCompilation = true;
            AssetDatabase.SaveAssets();
            Debug.Log(
                "[Tarrock] Editor performance settings applied: parallel (out-of-process) import " +
                "workers + async shader compilation.");
        }
    }
}
