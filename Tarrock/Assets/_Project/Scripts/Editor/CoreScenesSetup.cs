namespace Tarrock.Editor;

using System.IO;
using Tarrock.WorldState;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

/// <summary>
/// Editor command that programmatically creates the two core scenes described in
/// technical.md §Assets/ folder tree: Bootstrap (holding the <see cref="CompositionRoot"/>)
/// and Core (the persistent scene's root objects). Idempotent — existing scene files are
/// left untouched and logged as skipped.
/// </summary>
public static class CoreScenesSetup
{
    private const string ScenesDirectory = "Assets/_Project/Scenes";
    private const string BootstrapScenePath = ScenesDirectory + "/Bootstrap.unity";
    private const string CoreScenePath = ScenesDirectory + "/Core.unity";

    [MenuItem("Tarrock/Setup/Create Core Scenes")]
    public static void CreateCoreScenes()
    {
        Directory.CreateDirectory(ScenesDirectory);
        CreateBootstrapScene();
        CreateCoreScene();
        AssetDatabase.Refresh();
    }

    private static void CreateBootstrapScene()
    {
        if (File.Exists(BootstrapScenePath))
        {
            Debug.Log($"[Tarrock] Bootstrap scene already exists, skipping: {BootstrapScenePath}");
            return;
        }

        UnityEngine.SceneManagement.Scene scene =
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        var root = new GameObject("CompositionRoot");
        root.AddComponent<CompositionRoot>();

        EditorSceneManager.SaveScene(scene, BootstrapScenePath);
        Debug.Log($"[Tarrock] Created Bootstrap scene: {BootstrapScenePath}");
    }

    private static void CreateCoreScene()
    {
        if (File.Exists(CoreScenePath))
        {
            Debug.Log($"[Tarrock] Core scene already exists, skipping: {CoreScenePath}");
            return;
        }

        UnityEngine.SceneManagement.Scene scene =
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        // Empty root anchors for the persistent scene; services and UI attach here later.
        new GameObject("Services");
        new GameObject("UI Root");

        EditorSceneManager.SaveScene(scene, CoreScenePath);
        Debug.Log($"[Tarrock] Created Core scene: {CoreScenePath}");
    }
}
