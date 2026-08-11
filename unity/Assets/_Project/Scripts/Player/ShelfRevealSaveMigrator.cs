namespace Tarrock.Player
{

    using System;

    /// <summary>Explicit schema gate for the Player-owned shelf-reveal save block.</summary>
    public static class ShelfRevealSaveMigrator
    {
        public const int CurrentVersion = 1;

        public static ShelfRevealSaveData Migrate(ShelfRevealSaveData data)
        {
            if (data == null)
            {
                return new ShelfRevealSaveData { Version = CurrentVersion };
            }

            if (data.Version == CurrentVersion)
            {
                return data;
            }

            throw new InvalidOperationException(
                $"Unsupported shelf-reveal save version {data.Version}; expected {CurrentVersion}.");
        }
    }
}
