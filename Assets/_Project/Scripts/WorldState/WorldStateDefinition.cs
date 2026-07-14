namespace Tarrock.WorldState
{

    using UnityEngine;

    /// <summary>
    /// The authored, runtime-immutable data asset for one world-state flag — one asset per
    /// world.md §World-state matrix row (technical.md §The runtime data model). It carries no
    /// logic; the effect summary is documentation for authors, while the systems that subscribe
    /// to the fired event own the actual behaviour. Fields are exposed only through getters so
    /// definitions stay read-only at runtime.
    /// </summary>
    [CreateAssetMenu(menuName = "Tarrock/World State Definition", fileName = "WS_")]
    public sealed class WorldStateDefinition : ScriptableObject
    {
        [SerializeField] private string _id;
        [SerializeField] private bool _isUnbinding;
        [SerializeField] private string _arcanaNumeral;
        [SerializeField, TextArea] private string _designNote;

        /// <summary>The <c>WS_*</c> id, identical to the world.md matrix row id.</summary>
        public string Id => _id;

        /// <summary>True for the 21 <c>*_UNBOUND</c> Arcana flags; false for branch flags.</summary>
        public bool IsUnbinding => _isUnbinding;

        /// <summary>Roman numeral of the Arcana this flag unbinds (e.g. "XIII"); empty for branch flags.</summary>
        public string ArcanaNumeral => _arcanaNumeral;

        /// <summary>Author-facing note citing the owning world.md section.</summary>
        public string DesignNote => _designNote;

    #if UNITY_EDITOR
        /// <summary>
        /// Editor-only initialiser used by the generation tool
        /// (<c>Tarrock/Setup/Generate WorldState Definitions</c>) to author fields on a freshly
        /// created asset. Never called at runtime — definitions are immutable during play.
        /// </summary>
        public void EditorInitialize(string id, bool isUnbinding, string arcanaNumeral, string designNote)
        {
            _id = id;
            _isUnbinding = isUnbinding;
            _arcanaNumeral = arcanaNumeral;
            _designNote = designNote;
        }
    #endif
    }
}
