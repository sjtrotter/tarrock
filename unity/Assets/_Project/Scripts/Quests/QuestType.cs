namespace Tarrock.Quests
{

    /// <summary>
    /// A quest's top-level category, mirroring the <c>type</c> frontmatter key
    /// (docs/quests/README.md §Frontmatter schema: <c>main | side</c>). Drives Almanack
    /// categorisation (technical.md §Quests at runtime). This is authored data, never
    /// mutated at runtime.
    /// </summary>
    public enum QuestType
    {
        Main,
        Side,
    }
}
