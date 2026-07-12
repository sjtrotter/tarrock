namespace Tarrock.WorldState;

using Tarrock.Core;
using UnityEngine;

/// <summary>
/// The one sanctioned singleton (technical.md §Architecture principles 4): the composition
/// root that constructs and wires long-lived plain-C# services at startup, then survives
/// region streaming via <c>DontDestroyOnLoad</c>. It hands services out through read-only
/// properties rather than static accessors, keeping them EditMode-testable on their own.
/// <para>
/// Placement note: this type lives in the <c>Tarrock.WorldState</c> assembly rather than
/// <c>Tarrock.Core</c>, because it must construct <see cref="WorldStateService"/> /
/// <see cref="SaveService"/> (which live here) while also referencing
/// <see cref="StringEventChannel"/> (in Core). Housing it in Core would require Core to
/// reference WorldState, which references Core — a cyclic asmdef dependency. WorldState
/// already references Core, so this is the lowest assembly that can see both.
/// </para>
/// </summary>
[DisallowMultipleComponent]
public sealed class CompositionRoot : MonoBehaviour
{
    [SerializeField] private StringEventChannel _worldStateFired;

    /// <summary>The live composition root, established in <see cref="Awake"/>.</summary>
    public static CompositionRoot Instance { get; private set; }

    /// <summary>The single world-state mutation path for the running game.</summary>
    public WorldStateService WorldState { get; private set; }

    /// <summary>The save serialiser wired to <see cref="WorldState"/>.</summary>
    public SaveService Save { get; private set; }

    private void Awake()
    {
        if (Instance != null && Instance != this)
        {
            Destroy(gameObject);
            return;
        }

        Instance = this;
        DontDestroyOnLoad(gameObject);

        WorldState = new WorldStateService();
        Save = new SaveService();

        // Bridge the service's C# event onto the ScriptableObject channel so decoupled
        // listeners can react without referencing the service. Optional: the service works
        // headless (in tests) without a channel wired.
        if (_worldStateFired != null)
        {
            WorldState.StateFired += OnWorldStateFired;
        }
    }

    private void OnDestroy()
    {
        if (Instance != this)
        {
            return;
        }

        if (WorldState != null && _worldStateFired != null)
        {
            WorldState.StateFired -= OnWorldStateFired;
        }

        Instance = null;
    }

    private void OnWorldStateFired(string id) => _worldStateFired.Raise(id);
}
