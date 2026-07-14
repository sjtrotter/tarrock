namespace Tarrock.Editor
{

    using UnityEditor;
    using UnityEditor.TestTools.TestRunner.Api;
    using UnityEngine;

    /// <summary>
    /// Single-launch validation for headless workflows: one Unity session performs setup
    /// (scene installers) and then the full EditMode test suite, exiting with a CI-style
    /// code. Replaces the launch-per-step pattern (compile run, install run, test run),
    /// each of which paid full editor startup.
    ///
    /// Usage (note: NO -quit flag — the session ends itself via EditorApplication.Exit when
    /// the test run completes):
    /// <code>
    /// Unity -batchmode -nographics -projectPath &lt;proj&gt; \
    ///   -executeMethod Tarrock.Editor.Ci.FullValidate -logFile &lt;log&gt;
    /// </code>
    /// Exit codes: 0 = setup ran and all tests passed; 1 = test failures; 2 = setup threw.
    /// </summary>
    public static class Ci
    {
        public static void FullValidate()
        {
            try
            {
                // Idempotent setup chain — each installer is safe to re-run (their contract).
                CliffGreyboxGenerator.Generate();
                StandInArtInstaller.Install();
                PlayerRigInstaller.Install();
            }
            catch (System.Exception e)
            {
                Debug.LogError($"[Tarrock.Ci] Setup failed before tests: {e}");
                EditorApplication.Exit(2);
                return;
            }

            RunEditModeTests();
        }

        /// <summary>Tests only — no setup chain. Same session-exit contract as FullValidate.</summary>
        public static void TestsOnly() => RunEditModeTests();

        private static void RunEditModeTests()
        {
            var api = ScriptableObject.CreateInstance<TestRunnerApi>();
            api.RegisterCallbacks(new ExitOnFinishCallbacks());
            api.Execute(new ExecutionSettings(new Filter { testMode = TestMode.EditMode }));
            // Editor stays alive (no -quit) until ExitOnFinishCallbacks calls Exit.
        }

        private sealed class ExitOnFinishCallbacks : ICallbacks
        {
            public void RunStarted(ITestAdaptor testsToRun)
            {
            }

            public void RunFinished(ITestResultAdaptor result)
            {
                Debug.Log(
                    $"[Tarrock.Ci] EditMode tests finished: {result.PassCount} passed, " +
                    $"{result.FailCount} failed, {result.SkipCount} skipped.");
                EditorApplication.Exit(result.FailCount == 0 ? 0 : 1);
            }

            public void TestStarted(ITestAdaptor test)
            {
            }

            public void TestFinished(ITestResultAdaptor result)
            {
                if (result.TestStatus == TestStatus.Failed)
                {
                    Debug.LogError($"[Tarrock.Ci] FAIL: {result.FullName}\n{result.Message}");
                }
            }
        }
    }
}
