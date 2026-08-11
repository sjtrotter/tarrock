namespace Tarrock.Tests.EditMode
{

    using System.Collections.Generic;
    using NUnit.Framework;
    using Tarrock.Quests;
    using Tarrock.WorldState;
    using UnityEngine;

    /// <summary>
    /// Verifies the quest state machine — the one path that writes world state (technical.md
    /// §Testing: "Quest logic is pure data + transitions ... testable without a scene"). Covers
    /// activation gating (WorldState flags and prerequisite quests), strict step order with
    /// non-blocking optional steps, completion firing flags through the WorldState service exactly
    /// once with no re-fire, and the quest-save round-trip and migrator. The service is exercised
    /// with in-memory <see cref="QuestDefinition"/> assets and a real <see cref="WorldStateService"/>,
    /// no scene objects, matching <c>WorldStateServiceTests</c> / <c>SaveRoundtripTests</c>.
    /// </summary>
    [TestFixture]
    public sealed class QuestServiceTests
    {
        private readonly List<Object> _created = new();

        [TearDown]
        public void TearDown()
        {
            foreach (Object obj in _created)
            {
                if (obj != null)
                {
                    Object.DestroyImmediate(obj);
                }
            }

            _created.Clear();
        }

        // --- Activation gating ----------------------------------------------------------------

        [Test]
        public void TryActivate_BlockedWhenRequiredWorldStateNotFired()
        {
            var world = new WorldStateService();
            QuestDefinition quest = MakeQuest("MQ_TEST_A",
                requires: new[] { WorldStateIds.SunUnbound },
                fires: System.Array.Empty<string>(),
                steps: new[] { MakeStep("S1", optional: false) });
            var service = new QuestService(new[] { quest }, world);

            Assert.IsFalse(service.TryActivate("MQ_TEST_A"));
            Assert.AreEqual(QuestState.Inactive, service.GetState("MQ_TEST_A"));
        }

        [Test]
        public void TryActivate_AllowedWhenRequiredWorldStateFired()
        {
            var world = new WorldStateService();
            world.Fire(WorldStateIds.SunUnbound, isUnbinding: true);
            QuestDefinition quest = MakeQuest("MQ_TEST_A",
                requires: new[] { WorldStateIds.SunUnbound },
                fires: System.Array.Empty<string>(),
                steps: new[] { MakeStep("S1", optional: false) });
            var service = new QuestService(new[] { quest }, world);

            Assert.IsTrue(service.TryActivate("MQ_TEST_A"));
            Assert.AreEqual(QuestState.Active, service.GetState("MQ_TEST_A"));
        }

        [Test]
        public void TryActivate_BlockedUntilPrerequisiteQuestComplete()
        {
            var world = new WorldStateService();
            QuestDefinition first = MakeQuest("MQ_FIRST",
                requires: System.Array.Empty<string>(),
                fires: System.Array.Empty<string>(),
                steps: new[] { MakeStep("S1", optional: false) });
            QuestDefinition second = MakeQuest("MQ_SECOND",
                requires: new[] { "MQ_FIRST" },
                fires: System.Array.Empty<string>(),
                steps: new[] { MakeStep("S1", optional: false) });
            var service = new QuestService(new[] { first, second }, world);

            Assert.IsFalse(service.TryActivate("MQ_SECOND"), "prerequisite not yet complete");

            Assert.IsTrue(service.TryActivate("MQ_FIRST"));
            Assert.IsTrue(service.CompleteQuest("MQ_FIRST"));

            Assert.IsTrue(service.TryActivate("MQ_SECOND"), "prerequisite complete unlocks it");
        }

        [Test]
        public void TryActivate_RejectsSecondActivation()
        {
            var service = SingleQuestService(out _);
            Assert.IsTrue(service.TryActivate("MQ_TEST_A"));
            Assert.IsFalse(service.TryActivate("MQ_TEST_A"), "already active");
        }

        [Test]
        public void TryActivate_UnknownQuestRejected()
        {
            var service = SingleQuestService(out _);
            Assert.IsFalse(service.TryActivate("MQ_DOES_NOT_EXIST"));
        }

        // --- Step order and optional steps ----------------------------------------------------

        [Test]
        public void AdvanceStep_RequiredStepsAdvanceOnlyInOrder()
        {
            var world = new WorldStateService();
            QuestDefinition quest = MakeQuest("MQ_STEPS",
                requires: System.Array.Empty<string>(),
                fires: System.Array.Empty<string>(),
                steps: new[]
                {
                    MakeStep("R1", optional: false),
                    MakeStep("O1", optional: true),
                    MakeStep("R2", optional: false),
                    MakeStep("R3", optional: false),
                });
            var service = new QuestService(new[] { quest }, world);
            service.TryActivate("MQ_STEPS");

            Assert.AreEqual("R1", service.CurrentStep("MQ_STEPS").StepId);
            Assert.IsFalse(service.AdvanceStep("MQ_STEPS", "R2"), "cannot skip R1");
            Assert.IsFalse(service.AdvanceStep("MQ_STEPS", "R3"), "cannot skip to R3");

            Assert.IsTrue(service.AdvanceStep("MQ_STEPS", "R1"));
            Assert.IsFalse(service.AdvanceStep("MQ_STEPS", "R1"), "R1 already done");
            Assert.AreEqual("R2", service.CurrentStep("MQ_STEPS").StepId);

            Assert.IsFalse(service.AdvanceStep("MQ_STEPS", "R3"), "R2 still current");
            Assert.IsTrue(service.AdvanceStep("MQ_STEPS", "R2"));
            Assert.IsTrue(service.AdvanceStep("MQ_STEPS", "R3"));
            Assert.IsNull(service.CurrentStep("MQ_STEPS"), "all required steps done");
        }

        [Test]
        public void AdvanceStep_OptionalStepsDoNotBlockAndAdvanceAnytime()
        {
            var world = new WorldStateService();
            QuestDefinition quest = MakeQuest("MQ_STEPS",
                requires: System.Array.Empty<string>(),
                fires: System.Array.Empty<string>(),
                steps: new[]
                {
                    MakeStep("R1", optional: false),
                    MakeStep("O1", optional: true),
                    MakeStep("R2", optional: false),
                });
            var service = new QuestService(new[] { quest }, world);
            service.TryActivate("MQ_STEPS");

            // Optional advances before the current required step, and does not move CurrentStep.
            Assert.IsTrue(service.AdvanceStep("MQ_STEPS", "O1"));
            Assert.AreEqual("R1", service.CurrentStep("MQ_STEPS").StepId);
            Assert.IsFalse(service.AdvanceStep("MQ_STEPS", "O1"), "optional cannot be re-completed");

            Assert.IsTrue(service.AdvanceStep("MQ_STEPS", "R1"));
            Assert.IsTrue(service.AdvanceStep("MQ_STEPS", "R2"));
        }

        [Test]
        public void AdvanceStep_RejectedWhenQuestNotActive()
        {
            var service = SingleQuestService(out _);
            Assert.IsFalse(service.AdvanceStep("MQ_TEST_A", "S1"), "inactive quest");
        }

        // --- Completion and firing ------------------------------------------------------------

        [Test]
        public void CompleteQuest_FiresStatesThroughServiceExactlyOnce()
        {
            var world = new WorldStateService();
            int fireEvents = 0;
            world.StateFired += _ => fireEvents++;

            QuestDefinition quest = MakeQuest("MQ_FIRES",
                requires: System.Array.Empty<string>(),
                fires: new[] { WorldStateIds.TroupeSettled },
                steps: new[] { MakeStep("S1", optional: false) });
            var service = new QuestService(new[] { quest }, world);

            service.TryActivate("MQ_FIRES");
            Assert.IsTrue(service.CompleteQuest("MQ_FIRES"));

            Assert.AreEqual(QuestState.Complete, service.GetState("MQ_FIRES"));
            Assert.IsTrue(world.IsFired(WorldStateIds.TroupeSettled));
            Assert.AreEqual(1, fireEvents);
        }

        [Test]
        public void CompleteQuest_CannotReCompleteAndDoesNotReFire()
        {
            var world = new WorldStateService();
            int fireEvents = 0;
            world.StateFired += _ => fireEvents++;

            QuestDefinition quest = MakeQuest("MQ_FIRES",
                requires: System.Array.Empty<string>(),
                fires: new[] { WorldStateIds.TroupeSettled },
                steps: new[] { MakeStep("S1", optional: false) });
            var service = new QuestService(new[] { quest }, world);

            service.TryActivate("MQ_FIRES");
            Assert.IsTrue(service.CompleteQuest("MQ_FIRES"));
            Assert.IsFalse(service.CompleteQuest("MQ_FIRES"), "already complete");

            Assert.AreEqual(1, fireEvents, "flags fire exactly once");
        }

        [Test]
        public void CompleteQuest_RejectedWhenNotActive()
        {
            var service = SingleQuestService(out _);
            Assert.IsFalse(service.CompleteQuest("MQ_TEST_A"), "inactive quest cannot complete");
        }

        // --- Persistence ----------------------------------------------------------------------

        [Test]
        public void SaveRoundtrip_PreservesProgress()
        {
            var world = new WorldStateService();
            QuestDefinition quest = MakeQuest("MQ_STEPS",
                requires: System.Array.Empty<string>(),
                fires: System.Array.Empty<string>(),
                steps: new[]
                {
                    MakeStep("R1", optional: false),
                    MakeStep("O1", optional: true),
                    MakeStep("R2", optional: false),
                    MakeStep("R3", optional: false),
                });
            var service = new QuestService(new[] { quest }, world);

            service.TryActivate("MQ_STEPS");
            service.AdvanceStep("MQ_STEPS", "R1");   // required progress
            service.AdvanceStep("MQ_STEPS", "O1");   // optional progress

            QuestSaveData captured = service.Capture();
            Assert.AreEqual(QuestService.CurrentSaveVersion, captured.Version);
            Assert.AreEqual(1, captured.Quests.Count, "only the active quest is captured");

            string json = service.ToJson(captured);

            // Restore into a fresh service (same definitions, new world) — a load, not a merge.
            var restored = new QuestService(new[] { quest }, new WorldStateService());
            restored.Restore(restored.FromJson(json));

            Assert.AreEqual(QuestState.Active, restored.GetState("MQ_STEPS"));
            Assert.AreEqual("R2", restored.CurrentStep("MQ_STEPS").StepId, "required step index preserved");
            Assert.IsFalse(restored.AdvanceStep("MQ_STEPS", "O1"), "completed optional preserved");
            Assert.IsTrue(restored.AdvanceStep("MQ_STEPS", "R2"), "resumes from the right required step");
        }

        [Test]
        public void Capture_OmitsUntouchedQuests()
        {
            var world = new WorldStateService();
            QuestDefinition a = MakeQuest("MQ_A", System.Array.Empty<string>(), System.Array.Empty<string>(),
                new[] { MakeStep("S1", optional: false) });
            QuestDefinition b = MakeQuest("MQ_B", System.Array.Empty<string>(), System.Array.Empty<string>(),
                new[] { MakeStep("S1", optional: false) });
            var service = new QuestService(new[] { a, b }, world);

            service.TryActivate("MQ_A"); // B never touched

            QuestSaveData captured = service.Capture();
            Assert.AreEqual(1, captured.Quests.Count);
            Assert.AreEqual("MQ_A", captured.Quests[0].QuestId);
        }

        [Test]
        public void Migrate_V1IsPassthrough()
        {
            var data = new QuestSaveData { Version = QuestService.CurrentSaveVersion };
            data.Quests.Add(new QuestSaveEntry("MQ_A", QuestState.Active, 1, new List<string> { "O1" }));

            QuestSaveData migrated = QuestSaveMigrator.Migrate(data);

            Assert.AreSame(data, migrated);
            Assert.AreEqual(QuestService.CurrentSaveVersion, migrated.Version);
            Assert.AreEqual(1, migrated.Quests.Count);
        }

        // --- Helpers --------------------------------------------------------------------------

        private QuestService SingleQuestService(out QuestDefinition quest)
        {
            var world = new WorldStateService();
            quest = MakeQuest("MQ_TEST_A",
                requires: System.Array.Empty<string>(),
                fires: System.Array.Empty<string>(),
                steps: new[] { MakeStep("S1", optional: false) });
            return new QuestService(new[] { quest }, world);
        }

        private QuestDefinition MakeQuest(string id, string[] requires, string[] fires, QuestStepDefinition[] steps)
        {
            var quest = ScriptableObject.CreateInstance<QuestDefinition>();
            quest.EditorInitialize(id, $"{id}.TITLE", QuestType.Main, string.Empty, "The Cliff", requires, fires, steps);
            _created.Add(quest);
            return quest;
        }

        private static QuestStepDefinition MakeStep(string stepId, bool optional)
        {
            var step = new QuestStepDefinition();
            step.EditorInitialize(stepId, string.Empty, StepKind.Interact, string.Empty, optional);
            return step;
        }
    }
}
