namespace Tarrock.Player;

/// <summary>
/// Pure C# state machine for the Fool's dodge roll (combat.md §Defense: a "short-range roll
/// with invincibility frames covering the commit window"). Deliberately free of
/// <c>UnityEngine</c> so the timing contract — the roll's duration, its i-frame window, and
/// the cooldown that gates re-dodging — is EditMode-testable without a scene, per
/// technical.md §Testing ("pure data + transitions ... testable without a scene").
///
/// The machine runs Idle → Dodging (for <c>dodgeDuration</c>) → Cooldown (for
/// <c>cooldownDuration</c>) → Idle, advanced purely by <see cref="Tick"/>. This phase owns
/// only the movement + i-frame timing; the combat layer (Fool's Chance, damage) reads
/// <see cref="IsInvulnerable"/> later without owning any of this timing.
/// </summary>
public sealed class DodgeState
{
    /// <summary>The three phases of a dodge cycle.</summary>
    public enum Phase
    {
        /// <summary>Ready to dodge; no roll in progress.</summary>
        Idle,

        /// <summary>The roll is active and driving movement.</summary>
        Dodging,

        /// <summary>The roll has ended; dodging is locked out until this expires.</summary>
        Cooldown,
    }

    private readonly float _dodgeDuration;
    private readonly float _cooldownDuration;
    private readonly float _invulnerableStartOffset;
    private readonly float _invulnerableDuration;

    private Phase _phase = Phase.Idle;

    // Seconds elapsed within the current non-idle phase (Dodging or Cooldown).
    private float _phaseTime;

    /// <summary>Creates a dodge state machine. All parameters are in seconds.</summary>
    /// <param name="dodgeDuration">How long the roll drives movement.</param>
    /// <param name="cooldownDuration">Lock-out after the roll before another dodge is allowed.</param>
    /// <param name="invulnerableStartOffset">Delay from roll start until i-frames begin.</param>
    /// <param name="invulnerableDuration">How long the i-frame window stays open.</param>
    public DodgeState(
        float dodgeDuration,
        float cooldownDuration,
        float invulnerableStartOffset,
        float invulnerableDuration)
    {
        _dodgeDuration = dodgeDuration;
        _cooldownDuration = cooldownDuration;
        _invulnerableStartOffset = invulnerableStartOffset;
        _invulnerableDuration = invulnerableDuration;
    }

    /// <summary>The current phase of the cycle.</summary>
    public Phase CurrentPhase => _phase;

    /// <summary>True while the roll is active and should be driving movement.</summary>
    public bool IsDodging => _phase == Phase.Dodging;

    /// <summary>True only when a fresh dodge may be started (i.e. the machine is idle).</summary>
    public bool CanDodge => _phase == Phase.Idle;

    /// <summary>The configured roll duration, in seconds.</summary>
    public float DodgeDuration => _dodgeDuration;

    /// <summary>
    /// Normalised progress through the active roll, 0 at start and 1 at end. Returns 1 when
    /// not dodging so callers can treat "not rolling" as "roll complete".
    /// </summary>
    public float DodgeProgress
    {
        get
        {
            if (_phase != Phase.Dodging || _dodgeDuration <= 0f)
            {
                return 1f;
            }

            float t = _phaseTime / _dodgeDuration;
            return t < 0f ? 0f : (t > 1f ? 1f : t);
        }
    }

    /// <summary>
    /// True while the i-frame window is open — from <c>invulnerableStartOffset</c> until
    /// <c>invulnerableStartOffset + invulnerableDuration</c> into the roll. Inclusive at the
    /// opening edge, exclusive at the closing edge. combat.md §Defense: i-frames "covering
    /// the commit window".
    /// </summary>
    public bool IsInvulnerable =>
        _phase == Phase.Dodging
        && _phaseTime >= _invulnerableStartOffset
        && _phaseTime < _invulnerableStartOffset + _invulnerableDuration;

    /// <summary>
    /// Attempts to begin a dodge. Succeeds only from <see cref="Phase.Idle"/>; returns
    /// <c>false</c> (and changes nothing) while dodging or on cooldown.
    /// </summary>
    /// <returns><c>true</c> if a new roll started this call.</returns>
    public bool TryStartDodge()
    {
        if (_phase != Phase.Idle)
        {
            return false;
        }

        _phase = Phase.Dodging;
        _phaseTime = 0f;
        return true;
    }

    /// <summary>
    /// Advances the machine by <paramref name="deltaSeconds"/>. Ends the roll once its
    /// duration is reached (carrying any overshoot into cooldown) and returns to idle once
    /// the cooldown expires. A non-positive delta, or an idle machine, is a no-op.
    /// </summary>
    public void Tick(float deltaSeconds)
    {
        if (deltaSeconds <= 0f || _phase == Phase.Idle)
        {
            return;
        }

        _phaseTime += deltaSeconds;

        if (_phase == Phase.Dodging && _phaseTime >= _dodgeDuration)
        {
            _phaseTime -= _dodgeDuration;
            _phase = Phase.Cooldown;
        }

        if (_phase == Phase.Cooldown && _phaseTime >= _cooldownDuration)
        {
            _phaseTime = 0f;
            _phase = Phase.Idle;
        }
    }
}
