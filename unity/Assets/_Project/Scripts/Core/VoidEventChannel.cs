namespace Tarrock.Core
{

    using System;
    using UnityEngine;

    /// <summary>
    /// A payload-less ScriptableObject event channel for signals that carry no data
    /// (e.g. "game booted", "save committed"). Kept separate from <see cref="EventChannel{T}"/>
    /// because there is no meaningful payload type to parameterise it with.
    /// </summary>
    [CreateAssetMenu(menuName = "Tarrock/Events/Void Event Channel", fileName = "VoidEventChannel")]
    public sealed class VoidEventChannel : ScriptableObject
    {
        private event Action _raised;

        /// <summary>Notifies every current subscriber.</summary>
        public void Raise() => _raised?.Invoke();

        /// <summary>Registers <paramref name="handler"/> to receive raised events.</summary>
        public void Subscribe(Action handler) => _raised += handler;

        /// <summary>Removes a previously registered <paramref name="handler"/>.</summary>
        public void Unsubscribe(Action handler) => _raised -= handler;
    }
}
