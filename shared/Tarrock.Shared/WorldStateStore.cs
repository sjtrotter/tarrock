using System;
using System.Collections.Generic;

// Block-scoped namespace only. File-scoped namespaces (C# 10) break Unity's
// script-class binder — see docs/design/technical.md.
namespace Tarrock.Shared
{
    /// <summary>
    /// Set-once store for world-state flags (<c>WS_*</c>, owned by
    /// <c>docs/design/world.md</c> §World-state matrix).
    /// <para>
    /// Canon rule: a world-state flag can never be un-fired. There is therefore no
    /// clear/unset/remove operation — the only transition is unfired → fired, and it
    /// happens at most once per flag.
    /// </para>
    /// <para>
    /// Pure logic, no engine types: this same class is compiled by Unity (as the local
    /// UPM package <c>com.tarrock.shared</c>) and by plain .NET. Not thread-safe.
    /// </para>
    /// </summary>
    public sealed class WorldStateStore
    {
        private readonly HashSet<string> _fired = new HashSet<string>(StringComparer.Ordinal);
        private readonly List<string> _readingOrder = new List<string>();

        /// <summary>Every flag that has been fired, in no particular order.</summary>
        public IReadOnlyCollection<string> Fired => _fired;

        /// <summary>
        /// The flags that have been fired, in the order they fired — the player's
        /// reading of the spread so far.
        /// </summary>
        public IReadOnlyList<string> ReadingOrder => _readingOrder;

        /// <summary>
        /// Fires <paramref name="flagId"/> if it has not fired before.
        /// </summary>
        /// <returns>
        /// <c>true</c> if this call fired the flag; <c>false</c> if it had already
        /// fired, in which case the store is left untouched.
        /// </returns>
        /// <exception cref="ArgumentException">
        /// <paramref name="flagId"/> is null, empty, or whitespace.
        /// </exception>
        public bool Fire(string flagId)
        {
            RequireFlagId(flagId);

            if (!_fired.Add(flagId))
            {
                return false;
            }

            _readingOrder.Add(flagId);
            return true;
        }

        /// <summary>Whether <paramref name="flagId"/> has fired.</summary>
        /// <exception cref="ArgumentException">
        /// <paramref name="flagId"/> is null, empty, or whitespace.
        /// </exception>
        public bool IsFired(string flagId)
        {
            RequireFlagId(flagId);
            return _fired.Contains(flagId);
        }

        private static void RequireFlagId(string flagId)
        {
            if (string.IsNullOrWhiteSpace(flagId))
            {
                throw new ArgumentException("A world-state flag id must be a non-empty string.", nameof(flagId));
            }
        }
    }
}
