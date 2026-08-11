namespace Tarrock.Player
{

    using System;

    /// <summary>
    /// Pure timing and persistence state for the Cliff shelf's one-shot dead-tree reveal.
    /// The visual driver owns Cinemachine; this type owns the once-only transition contract so it
    /// remains testable without a scene or an Editor. "Played" is committed when the reveal starts,
    /// not when it finishes: moving the look stick is a choice to dismiss it, not a way to farm it.
    /// </summary>
    public sealed class ShelfRevealState
    {
        public enum Phase
        {
            Idle,
            Drifting,
            Holding,
            Returning,
        }

        private readonly float _driftDuration;
        private readonly float _holdDuration;
        private readonly float _returnDuration;

        private float _phaseTime;

        public ShelfRevealState(float driftDuration, float holdDuration, float returnDuration)
        {
            _driftDuration = Math.Max(0.01f, driftDuration);
            _holdDuration = Math.Max(0f, holdDuration);
            _returnDuration = Math.Max(0.01f, returnDuration);
        }

        public Phase CurrentPhase { get; private set; }

        public bool HasPlayed { get; private set; }

        public bool IsActive => CurrentPhase != Phase.Idle;

        /// <summary>Blend weight applied to the authored reveal pose, in the range [0, 1].</summary>
        public float RevealWeight
        {
            get
            {
                switch (CurrentPhase)
                {
                    case Phase.Drifting:
                        return SmoothStep(_phaseTime / _driftDuration);
                    case Phase.Holding:
                        return 1f;
                    case Phase.Returning:
                        return 1f - SmoothStep(_phaseTime / _returnDuration);
                    default:
                        return 0f;
                }
            }
        }

        public bool TryStart()
        {
            if (HasPlayed || IsActive)
            {
                return false;
            }

            HasPlayed = true;
            CurrentPhase = Phase.Drifting;
            _phaseTime = 0f;
            return true;
        }

        public void Tick(float deltaTime)
        {
            if (!IsActive || deltaTime <= 0f)
            {
                return;
            }

            _phaseTime += deltaTime;
            AdvanceCompletedPhases();
        }

        public void ReleaseForLookInput()
        {
            if (!IsActive)
            {
                return;
            }

            CurrentPhase = Phase.Idle;
            _phaseTime = 0f;
        }

        public ShelfRevealSaveData Capture() => new ShelfRevealSaveData
        {
            Version = ShelfRevealSaveMigrator.CurrentVersion,
            HasPlayed = HasPlayed,
        };

        public void Restore(ShelfRevealSaveData data)
        {
            ShelfRevealSaveData migrated = ShelfRevealSaveMigrator.Migrate(data);
            HasPlayed = migrated.HasPlayed;
            CurrentPhase = Phase.Idle;
            _phaseTime = 0f;
        }

        private void AdvanceCompletedPhases()
        {
            while (IsActive)
            {
                float duration = CurrentPhase == Phase.Drifting
                    ? _driftDuration
                    : CurrentPhase == Phase.Holding ? _holdDuration : _returnDuration;

                if (_phaseTime < duration)
                {
                    return;
                }

                _phaseTime -= duration;
                if (CurrentPhase == Phase.Drifting)
                {
                    CurrentPhase = Phase.Holding;
                }
                else if (CurrentPhase == Phase.Holding)
                {
                    CurrentPhase = Phase.Returning;
                }
                else
                {
                    CurrentPhase = Phase.Idle;
                    _phaseTime = 0f;
                }
            }
        }

        private static float SmoothStep(float value)
        {
            float t = Math.Max(0f, Math.Min(1f, value));
            return t * t * (3f - (2f * t));
        }
    }
}
