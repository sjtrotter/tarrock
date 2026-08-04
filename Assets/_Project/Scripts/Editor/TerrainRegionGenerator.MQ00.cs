namespace Tarrock.Editor
{

    using System.Collections.Generic;
    using System.IO;
    using Tarrock.Core;
    using Tarrock.Player;
    using Tarrock.Quests;
    using Tarrock.Regions;
    using Tarrock.WorldState;
    using UnityEditor;
    using UnityEngine;

    public static partial class TerrainRegionGenerator
    {
        private const string Mq00AssetPath = "Assets/_Project/Data/Quests/MQ00.asset";
        private const string Mq00EventDirectory = "Assets/_Project/Data/Events/MQ00";

        // FIRST-PASS placements. Keep these together so playtest adjustment is a data-sized edit.
        private static readonly Vector2 KeepsakePlacement = new Vector2(202f, 82f);
        private static readonly Vector2 CampsitePlacement = new Vector2(206f, 96f);
        private static readonly Vector2 BlankAmbushPlacement = new Vector2(112f, 141f);
        private static readonly Vector2 WaystationPlacement = new Vector2(76f, 132f);
        private static readonly Vector2 CliffEdgePlacement = new Vector2(22f, 137f);

        private static void BuildMq00Foundation()
        {
            QuestDefinition quest = AssetDatabase.LoadAssetAtPath<QuestDefinition>(Mq00AssetPath);
            if (quest == null)
            {
                throw new System.InvalidOperationException($"MQ00 definition is missing at {Mq00AssetPath}.");
            }

            Directory.CreateDirectory(Mq00EventDirectory);

            var compositionObject = new GameObject("CompositionRoot");
            compositionObject.AddComponent<CompositionRoot>();

            var questRootObject = new GameObject("QuestsRoot_MQ00");
            QuestsRoot questRoot = questRootObject.AddComponent<QuestsRoot>();
            SetQuestRoot(questRoot, quest);

            var gameplay = new GameObject("MQ00_Foundation_FirstPass");
            Transform spawn = CreateSpawn(gameplay.transform);
            Transform campsite = CreateMarker(gameplay.transform, CliffMarkerIds.CampsiteInspect, CampsitePlacement);
            Transform keepsake = CreateMarker(gameplay.transform, CliffMarkerIds.KeepsakeDigSpot, KeepsakePlacement);
            Transform deadTree = FindMarker(CliffMarkerIds.DeadTree).transform;
            Transform blankAmbush = CreateReachMarker(gameplay.transform, CliffMarkerIds.BlankAmbush,
                BlankAmbushPlacement, new Vector3(10f, 4f, 12f));
            Transform waystation = CreateMarker(gameplay.transform, CliffMarkerIds.Waystation, WaystationPlacement);
            Transform cliffEdge = CreateMarker(gameplay.transform, CliffMarkerIds.CliffEdge, CliffEdgePlacement);

            var anchors = new Dictionary<string, Transform>
            {
                { CliffQuestStepIds.Wake, spawn },
                { CliffQuestStepIds.Bindle, spawn },
                { CliffQuestStepIds.CampsiteInspect, campsite },
                { CliffQuestStepIds.Keepsake, keepsake },
                { CliffQuestStepIds.DeadTree, deadTree },
                { CliffQuestStepIds.BlankAmbush, blankAmbush },
                { CliffQuestStepIds.Waystation, waystation },
                { CliffQuestStepIds.WaystationRestAgain, waystation },
                { CliffQuestStepIds.Edge, cliffEdge },
                { CliffQuestStepIds.Leap, cliffEdge },
            };

            foreach (QuestStepDefinition step in quest.Steps)
            {
                VoidEventChannel channel = EnsureStepChannel(step.StepId);
                var bindingObject = new GameObject($"Binding_{step.StepId}");
                bindingObject.transform.SetParent(gameplay.transform, false);
                bindingObject.AddComponent<QuestStepBinder>()
                    .EditorInitialize(quest, step.StepId, channel, anchors[step.StepId]);

                if (step.StepId == CliffQuestStepIds.BlankAmbush)
                {
                    SetObjectReference(blankAmbush.GetComponent<QuestReachTrigger>(), "_onReached", channel);
                }
                else if (step.StepId == CliffQuestStepIds.DeadTree)
                {
                    ShelfRevealTrigger reveal = Object.FindFirstObjectByType<ShelfRevealTrigger>();
                    SetObjectReference(reveal, "_onEntered", channel);
                }
                else if (step.StepId == CliffQuestStepIds.Leap)
                {
                    CreateLeapVolume(gameplay.transform, channel, CliffEdgePlacement);
                }
            }
        }

        private static Transform CreateSpawn(Transform parent)
        {
            var spawn = new GameObject("PlayerSpawn_Campfire_FIRST_PASS");
            spawn.transform.SetParent(parent, false);
            spawn.transform.position = TerrainPoint(new Vector2(SpawnHint.x, SpawnHint.z));
            spawn.transform.rotation = Quaternion.LookRotation(SpawnFacing);
            spawn.AddComponent<PlayerSpawnPoint>();
            return spawn.transform;
        }

        private static Transform CreateMarker(Transform parent, string markerId, Vector2 xz)
        {
            var markerObject = new GameObject(markerId + "_FIRST_PASS");
            markerObject.transform.SetParent(parent, false);
            markerObject.transform.position = TerrainPoint(xz);
            InteractionMarker marker = markerObject.AddComponent<InteractionMarker>();
            SetString(marker, "_markerId", markerId);
            return markerObject.transform;
        }

        private static Transform CreateReachMarker(Transform parent, string markerId, Vector2 xz, Vector3 size)
        {
            Transform marker = CreateMarker(parent, markerId, xz);
            BoxCollider volume = marker.gameObject.AddComponent<BoxCollider>();
            volume.isTrigger = true;
            volume.center = Vector3.up * (size.y * 0.5f);
            volume.size = size;
            marker.gameObject.AddComponent<QuestReachTrigger>();
            return marker;
        }

        private static void CreateLeapVolume(Transform parent, VoidEventChannel channel, Vector2 edge)
        {
            var triggerObject = new GameObject("MQ00_Leap_Trigger_FIRST_PASS");
            triggerObject.transform.SetParent(parent, false);
            triggerObject.transform.position = TerrainPoint(new Vector2(edge.x - 10f, edge.y)) + Vector3.down * 5f;
            BoxCollider volume = triggerObject.AddComponent<BoxCollider>();
            volume.isTrigger = true;
            volume.size = new Vector3(14f, 16f, 22f);
            LeapOfFaithTrigger trigger = triggerObject.AddComponent<LeapOfFaithTrigger>();
            SetObjectReference(trigger, "_onLeapTriggered", channel);
        }

        private static Vector3 TerrainPoint(Vector2 xz)
        {
            return new Vector3(xz.x, SampleHeight(xz.x, xz.y) + 0.1f, xz.y);
        }

        private static InteractionMarker FindMarker(string markerId)
        {
            foreach (InteractionMarker marker in Object.FindObjectsByType<InteractionMarker>(
                         FindObjectsInactive.Include, FindObjectsSortMode.None))
            {
                if (marker.MarkerId == markerId)
                {
                    return marker;
                }
            }

            throw new System.InvalidOperationException($"Generated marker {markerId} was not found.");
        }

        private static VoidEventChannel EnsureStepChannel(string stepId)
        {
            string path = $"{Mq00EventDirectory}/{stepId}_Triggered.asset";
            VoidEventChannel channel = AssetDatabase.LoadAssetAtPath<VoidEventChannel>(path);
            if (channel != null)
            {
                return channel;
            }

            channel = ScriptableObject.CreateInstance<VoidEventChannel>();
            AssetDatabase.CreateAsset(channel, path);
            return channel;
        }

        private static void SetQuestRoot(QuestsRoot root, QuestDefinition quest)
        {
            var serialized = new SerializedObject(root);
            SerializedProperty definitions = serialized.FindProperty("_definitions");
            definitions.arraySize = 1;
            definitions.GetArrayElementAtIndex(0).objectReferenceValue = quest;
            serialized.FindProperty("_autoActivate").objectReferenceValue = quest;
            serialized.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void SetString(Object target, string propertyName, string value)
        {
            var serialized = new SerializedObject(target);
            serialized.FindProperty(propertyName).stringValue = value;
            serialized.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void SetObjectReference(Object target, string propertyName, Object value)
        {
            if (target == null)
            {
                throw new System.InvalidOperationException($"Cannot wire {propertyName}: generated component is missing.");
            }

            var serialized = new SerializedObject(target);
            serialized.FindProperty(propertyName).objectReferenceValue = value;
            serialized.ApplyModifiedPropertiesWithoutUndo();
        }
    }
}
