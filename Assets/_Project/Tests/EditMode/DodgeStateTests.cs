namespace Tarrock.Tests.EditMode
{

    using NUnit.Framework;
    using Tarrock.Player;

    /// <summary>
    /// Full coverage of <see cref="DodgeState"/>, the pure dodge-roll timing machine
    /// (combat.md §Defense: roll with i-frames "covering the commit window"). Verifies the
    /// Idle → Dodging → Cooldown → Idle progression, the cooldown lock-out, and the i-frame
    /// window's open/close edges — the phase-2 timing contract the combat layer will later
    /// build on. Fixtures use round numbers to keep boundary assertions exact.
    /// </summary>
    [TestFixture]
    public sealed class DodgeStateTests
    {
        private const float DodgeDuration = 0.5f;
        private const float CooldownDuration = 0.4f;
        private const float InvulnerableStart = 0.1f;
        private const float InvulnerableDuration = 0.3f; // window: [0.1, 0.4)

        private static DodgeState NewState() =>
            new(DodgeDuration, CooldownDuration, InvulnerableStart, InvulnerableDuration);

        [Test]
        public void StartsIdle_AndCanDodge()
        {
            var state = NewState();

            Assert.AreEqual(DodgeState.Phase.Idle, state.CurrentPhase);
            Assert.IsTrue(state.CanDodge);
            Assert.IsFalse(state.IsDodging);
            Assert.IsFalse(state.IsInvulnerable);
        }

        [Test]
        public void TryStartDodge_FromIdle_BeginsRoll()
        {
            var state = NewState();

            bool started = state.TryStartDodge();

            Assert.IsTrue(started);
            Assert.AreEqual(DodgeState.Phase.Dodging, state.CurrentPhase);
            Assert.IsTrue(state.IsDodging);
            Assert.IsFalse(state.CanDodge);
        }

        [Test]
        public void Tick_IsNoOp_WhileIdle()
        {
            var state = NewState();

            state.Tick(1f);

            Assert.AreEqual(DodgeState.Phase.Idle, state.CurrentPhase);
        }

        [Test]
        public void CannotDodge_WhileDodging()
        {
            var state = NewState();
            state.TryStartDodge();

            bool secondStart = state.TryStartDodge();

            Assert.IsFalse(secondStart);
            Assert.AreEqual(DodgeState.Phase.Dodging, state.CurrentPhase);
        }

        [Test]
        public void RollEnds_IntoCooldown_AfterDuration()
        {
            var state = NewState();
            state.TryStartDodge();

            state.Tick(DodgeDuration);

            Assert.AreEqual(DodgeState.Phase.Cooldown, state.CurrentPhase);
            Assert.IsFalse(state.IsDodging);
        }

        [Test]
        public void CannotDodge_DuringCooldown()
        {
            var state = NewState();
            state.TryStartDodge();
            state.Tick(DodgeDuration + 0.05f); // into cooldown

            Assert.AreEqual(DodgeState.Phase.Cooldown, state.CurrentPhase);
            Assert.IsFalse(state.CanDodge);
            Assert.IsFalse(state.TryStartDodge());
        }

        [Test]
        public void ReturnsToIdle_AfterCooldownExpires()
        {
            var state = NewState();
            state.TryStartDodge();

            state.Tick(DodgeDuration);   // -> cooldown
            state.Tick(CooldownDuration); // -> idle

            Assert.AreEqual(DodgeState.Phase.Idle, state.CurrentPhase);
            Assert.IsTrue(state.CanDodge);
        }

        [Test]
        public void CanReDodge_AfterFullCycle()
        {
            var state = NewState();
            state.TryStartDodge();
            state.Tick(DodgeDuration + CooldownDuration + 0.02f); // clear the whole cycle in one tick

            Assert.AreEqual(DodgeState.Phase.Idle, state.CurrentPhase);

            bool reDodge = state.TryStartDodge();

            Assert.IsTrue(reDodge);
            Assert.AreEqual(DodgeState.Phase.Dodging, state.CurrentPhase);
        }

        [Test]
        public void NotInvulnerable_BeforeWindowOpens()
        {
            var state = NewState();
            state.TryStartDodge();

            state.Tick(InvulnerableStart - 0.02f);

            Assert.IsFalse(state.IsInvulnerable);
        }

        [Test]
        public void Invulnerable_AtWindowOpeningEdge()
        {
            var state = NewState();
            state.TryStartDodge();

            state.Tick(InvulnerableStart); // inclusive opening edge

            Assert.IsTrue(state.IsInvulnerable);
        }

        [Test]
        public void Invulnerable_MidWindow()
        {
            var state = NewState();
            state.TryStartDodge();

            state.Tick(InvulnerableStart + (InvulnerableDuration * 0.5f));

            Assert.IsTrue(state.IsInvulnerable);
        }

        [Test]
        public void NotInvulnerable_AfterWindowCloses()
        {
            var state = NewState();
            state.TryStartDodge();

            // Just past the window's nominal end (still inside the roll: 0.42 < 0.5).
            state.Tick(InvulnerableStart + InvulnerableDuration + 0.02f);

            Assert.IsTrue(state.IsDodging);
            Assert.IsFalse(state.IsInvulnerable);
        }

        [Test]
        public void NotInvulnerable_OnceCooldownReached()
        {
            var state = NewState();
            state.TryStartDodge();

            state.Tick(DodgeDuration);

            Assert.AreEqual(DodgeState.Phase.Cooldown, state.CurrentPhase);
            Assert.IsFalse(state.IsInvulnerable);
        }

        [Test]
        public void DodgeProgress_TracksRoll_ThenReadsCompleteWhenIdle()
        {
            var state = NewState();
            Assert.AreEqual(1f, state.DodgeProgress, 1e-4f); // idle reads as complete

            state.TryStartDodge();
            Assert.AreEqual(0f, state.DodgeProgress, 1e-4f);

            state.Tick(DodgeDuration * 0.5f);
            Assert.AreEqual(0.5f, state.DodgeProgress, 1e-4f);
        }

        [Test]
        public void Tick_CarriesOvershoot_FromRollIntoCooldown()
        {
            var state = NewState();
            state.TryStartDodge();

            // Overshoot the roll by 0.1s. If the remainder were NOT carried, this single tick
            // (0.6 > cooldown 0.4) would run straight through cooldown to Idle; staying in
            // Cooldown proves only 0.1s of the cooldown has been consumed.
            state.Tick(DodgeDuration + 0.1f);
            Assert.AreEqual(DodgeState.Phase.Cooldown, state.CurrentPhase);

            state.Tick(CooldownDuration);
            Assert.AreEqual(DodgeState.Phase.Idle, state.CurrentPhase);
        }
    }
}
