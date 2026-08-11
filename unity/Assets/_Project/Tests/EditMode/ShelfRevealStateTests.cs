namespace Tarrock.Tests.EditMode
{

    using System.Reflection;
    using NUnit.Framework;
    using Tarrock.Player;
    using UnityEngine;

    /// <summary>EditMode contract for the Cliff shelf reveal's pure once-only timing state.</summary>
    [TestFixture]
    public sealed class ShelfRevealStateTests
    {
        private static ShelfRevealState NewState() => new ShelfRevealState(2f, 0.75f, 0.45f);

        [Test]
        public void SecondEntry_DoesNotRefire()
        {
            ShelfRevealState state = NewState();

            Assert.IsTrue(state.TryStart());
            state.Tick(3.2f);

            Assert.IsFalse(state.IsActive);
            Assert.IsTrue(state.HasPlayed);
            Assert.IsFalse(state.TryStart());
        }

        [Test]
        public void LookInput_ReleasesImmediatelyAndStillCountsAsPlayed()
        {
            ShelfRevealState state = NewState();
            state.TryStart();
            state.Tick(0.5f);

            state.ReleaseForLookInput();

            Assert.IsFalse(state.IsActive);
            Assert.AreEqual(ShelfRevealState.Phase.Idle, state.CurrentPhase);
            Assert.AreEqual(0f, state.RevealWeight);
            Assert.IsTrue(state.HasPlayed);
            Assert.IsFalse(state.TryStart());
        }

        [Test]
        public void SaveState_JsonRoundtrip_PreservesPlayedFlag()
        {
            ShelfRevealState original = NewState();
            original.TryStart();

            string json = JsonUtility.ToJson(original.Capture());
            ShelfRevealSaveData restoredData = JsonUtility.FromJson<ShelfRevealSaveData>(json);
            ShelfRevealState restored = NewState();
            restored.Restore(restoredData);

            Assert.IsTrue(restored.HasPlayed);
            Assert.IsFalse(restored.IsActive);
            Assert.IsFalse(restored.TryStart());
        }

        [Test]
        public void Capture_StampsCurrentSaveVersion()
        {
            ShelfRevealSaveData data = NewState().Capture();

            Assert.AreEqual(ShelfRevealSaveMigrator.CurrentVersion, data.Version);
        }

        [Test]
        public void TryBeginReveal_RequiresMarkerAndStartsWhenWired()
        {
            var player = new GameObject("ShelfRevealTestPlayer");
            var marker = new GameObject("ShelfRevealTestMarker");
            var camera = new GameObject("ShelfRevealTestCamera");

            try
            {
                var reveal = camera.AddComponent<ShelfRevealCameraNudge>();
                SetComponentField(reveal, "_player", player.transform);
                SetComponentField(reveal, "_orbital", camera);
                SetComponentField(reveal, "_composer", camera);

                Assert.IsFalse(reveal.TryBeginReveal(), "A null marker must fail closed.");

                SetComponentField(reveal, "_deadTreeMarker", marker.transform);
                Assert.IsTrue(reveal.TryBeginReveal(), "A fully wired reveal must start.");
            }
            finally
            {
                Object.DestroyImmediate(camera);
                Object.DestroyImmediate(marker);
                Object.DestroyImmediate(player);
            }
        }

        private static void SetComponentField(
            ShelfRevealCameraNudge reveal, string fieldName, GameObject host)
        {
            FieldInfo field = typeof(ShelfRevealCameraNudge).GetField(
                fieldName, BindingFlags.Instance | BindingFlags.NonPublic);
            Assert.IsNotNull(field);
            field.SetValue(reveal, host.AddComponent(field.FieldType));
        }

        private static void SetComponentField(
            ShelfRevealCameraNudge reveal, string fieldName, Transform value)
        {
            FieldInfo field = typeof(ShelfRevealCameraNudge).GetField(
                fieldName, BindingFlags.Instance | BindingFlags.NonPublic);
            Assert.IsNotNull(field);
            field.SetValue(reveal, value);
        }
    }
}
