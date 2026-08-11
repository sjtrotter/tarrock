namespace Tarrock.Quests
{

    /// <summary>
    /// How a quest step is satisfied — the shape of the scene hook a
    /// <see cref="QuestStepBinder"/> waits on before advancing the quest. These map onto the
    /// beat kinds in MQ00 (docs/quests/main/MQ00-the-leap.md): interacting with a marked spot,
    /// reaching a trigger volume (the Blank ambush, the Leap), issuing Pip's Seek command at a
    /// dig spot, or holding a dialogue beat. <see cref="Custom"/> covers anything bespoke a
    /// later system wires by hand. Authored data — the kind never changes at runtime.
    /// </summary>
    public enum StepKind
    {
        Interact,
        ReachTrigger,
        PipSeek,
        Dialogue,
        Custom,
    }
}
