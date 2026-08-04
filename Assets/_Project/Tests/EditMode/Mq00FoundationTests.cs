namespace Tarrock.Tests.EditMode
{

    using System.Collections.Generic;
    using System.Linq;
    using NUnit.Framework;
    using Tarrock.Core;
    using Tarrock.Quests;
    using Tarrock.Regions;
    using Tarrock.WorldState;
    using UnityEditor;
    using UnityEditor.SceneManagement;
    using UnityEngine;

    [TestFixture]
    public sealed class Mq00FoundationTests
    {
        private const string QuestPath = "Assets/_Project/Data/Quests/MQ00.asset";
        private const string ScenePath = "Assets/_Project/Scenes/Sandbox/TerrainProto.unity";
        private const string WakeChannelPath =
            "Assets/_Project/Data/Events/MQ00/MQ00_STEP_WAKE_Triggered.asset";

        private readonly List<Object> _created = new();

        [TearDown]
        public void TearDown()
        {
            foreach (Object created in _created)
            {
                if (created != null)
                {
                    Object.DestroyImmediate(created);
                }
            }

            _created.Clear();
        }

        [Test]
        public void Mq00_ActivatesAndEveryStepAdvancesThroughItsBoundChannel()
        {
            QuestDefinition quest = AssetDatabase.LoadAssetAtPath<QuestDefinition>(QuestPath);
            Assert.IsNotNull(quest);
            var service = new QuestService(new[] { quest }, new WorldStateService());
            Assert.IsTrue(service.TryActivate(quest.Id));

            var channels = new Dictionary<string, VoidEventChannel>();
            foreach (QuestStepDefinition step in quest.Steps)
            {
                var channel = ScriptableObject.CreateInstance<VoidEventChannel>();
                _created.Add(channel);
                channels.Add(step.StepId, channel);

                var go = new GameObject(step.StepId);
                _created.Add(go);
                go.SetActive(false);
                QuestStepBinder binder = go.AddComponent<QuestStepBinder>();
                binder.EditorInitialize(quest, step.StepId, channel, go.transform);
                binder.Bind(service);
                go.SetActive(true);
            }

            channels[CliffQuestStepIds.CampsiteInspect].Raise();
            foreach (QuestStepDefinition step in quest.Steps.Where(step => !step.Optional))
            {
                Assert.AreEqual(step.StepId, service.CurrentStep(quest.Id).StepId);
                channels[step.StepId].Raise();
            }

            Assert.IsNull(service.CurrentStep(quest.Id));
        }

        [Test]
        public void GeneratedScene_HasUniqueMarkersVolumesAndCompleteBinderGraph()
        {
            EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
            QuestDefinition quest = AssetDatabase.LoadAssetAtPath<QuestDefinition>(QuestPath);
            InteractionMarker[] markers = Object.FindObjectsByType<InteractionMarker>(
                FindObjectsInactive.Include, FindObjectsSortMode.None);
            QuestStepBinder[] binders = Object.FindObjectsByType<QuestStepBinder>(
                FindObjectsInactive.Include, FindObjectsSortMode.None);

            Assert.AreEqual(1, Object.FindObjectsByType<PlayerSpawnPoint>(
                FindObjectsInactive.Include, FindObjectsSortMode.None).Length);
            Assert.IsNotNull(Object.FindFirstObjectByType<CompositionRoot>());
            QuestsRoot questRoot = Object.FindFirstObjectByType<QuestsRoot>();
            Assert.IsNotNull(questRoot);
            Assert.AreSame(quest, questRoot.AutoActivate);
            CollectionAssert.Contains(questRoot.Definitions, quest);
            Assert.AreEqual(quest.Steps.Count, binders.Length);

            foreach (string markerId in quest.Steps.Select(step => step.MarkerId)
                         .Where(id => !string.IsNullOrEmpty(id)).Distinct())
            {
                Assert.AreEqual(1, markers.Count(marker => marker.MarkerId == markerId), markerId);
            }

            foreach (QuestStepDefinition step in quest.Steps)
            {
                QuestStepBinder binder = binders.SingleOrDefault(candidate => candidate.StepId == step.StepId);
                Assert.IsNotNull(binder, step.StepId);
                Assert.AreSame(quest, binder.Quest, step.StepId);
                Assert.IsNotNull(binder.TriggerChannel, step.StepId);
                Assert.IsNotNull(binder.BindingAnchor, step.StepId);

                if (!string.IsNullOrEmpty(step.MarkerId))
                {
                    InteractionMarker anchor = binder.BindingAnchor.GetComponent<InteractionMarker>();
                    Assert.IsNotNull(anchor, step.StepId);
                    Assert.AreEqual(step.MarkerId, anchor.MarkerId, step.StepId);
                }

                if (step.Kind == StepKind.ReachTrigger)
                {
                    Assert.IsTrue(HasTriggerPublisher(binder.TriggerChannel), step.StepId);
                }
            }
        }

        [Test]
        public void GeneratedScene_WakeChannelAdvancesBoundQuestInEditMode()
        {
            EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
            QuestDefinition quest = AssetDatabase.LoadAssetAtPath<QuestDefinition>(QuestPath);
            VoidEventChannel wakeChannel =
                AssetDatabase.LoadAssetAtPath<VoidEventChannel>(WakeChannelPath);
            QuestStepBinder wakeBinder = Object.FindObjectsByType<QuestStepBinder>(
                    FindObjectsInactive.Include, FindObjectsSortMode.None)
                .Single(candidate => candidate.StepId == CliffQuestStepIds.Wake);

            Assert.AreSame(wakeChannel, wakeBinder.TriggerChannel,
                "The generated scene must bind the same channel asset that the test raises.");

            var service = new QuestService(new[] { quest }, new WorldStateService());
            Assert.IsTrue(service.TryActivate(quest.Id));
            Assert.AreEqual(CliffQuestStepIds.Wake, service.CurrentStep(quest.Id).StepId);

            // Bind is the production initialization boundary and must establish the event
            // subscription even when EditMode does not drive MonoBehaviour.OnEnable.
            wakeBinder.Bind(service);
            wakeChannel.Raise();

            Assert.AreEqual(CliffQuestStepIds.Bindle, service.CurrentStep(quest.Id).StepId);
        }

        private static bool HasTriggerPublisher(VoidEventChannel channel)
        {
            foreach (QuestReachTrigger trigger in Object.FindObjectsByType<QuestReachTrigger>(
                         FindObjectsInactive.Include, FindObjectsSortMode.None))
            {
                if (trigger.GetComponent<BoxCollider>().isTrigger &&
                    new SerializedObject(trigger).FindProperty("_onReached").objectReferenceValue == channel)
                {
                    return true;
                }
            }

            foreach (LeapOfFaithTrigger trigger in Object.FindObjectsByType<LeapOfFaithTrigger>(
                         FindObjectsInactive.Include, FindObjectsSortMode.None))
            {
                if (trigger.GetComponent<BoxCollider>().isTrigger &&
                    new SerializedObject(trigger).FindProperty("_onLeapTriggered").objectReferenceValue == channel)
                {
                    return true;
                }
            }

            return false;
        }
    }
}
