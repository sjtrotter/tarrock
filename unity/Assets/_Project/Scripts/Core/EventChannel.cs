namespace Tarrock.Core
{

    using System;
    using UnityEngine;

    /// <summary>
    /// Generic base for ScriptableObject event channels — the decoupling backbone required by
    /// technical.md §Architecture principles 3 ("systems talk through ScriptableObject event
    /// channels ... not direct references"). Publishers <see cref="Raise"/> a payload; any
    /// number of subscribers listen without either side holding a reference to the other.
    /// Concrete channels (e.g. <see cref="StringEventChannel"/>) subclass this with a fixed
    /// payload type so an asset can be created and wired in the Inspector.
    /// </summary>
    /// <typeparam name="T">The payload type carried by each raised event.</typeparam>
    public abstract class EventChannel<T> : ScriptableObject
    {
        private event Action<T> _raised;

        /// <summary>Notifies every current subscriber with <paramref name="value"/>.</summary>
        public void Raise(T value) => _raised?.Invoke(value);

        /// <summary>Registers <paramref name="handler"/> to receive raised events.</summary>
        public void Subscribe(Action<T> handler) => _raised += handler;

        /// <summary>Removes a previously registered <paramref name="handler"/>.</summary>
        public void Unsubscribe(Action<T> handler) => _raised -= handler;
    }
}
