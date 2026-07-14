namespace Tarrock.WorldState
{

    using System.IO;
    using UnityEngine;

    /// <summary>
    /// Isolates save-file disk I/O to a single small class so the JSON layer
    /// (<see cref="SaveService.ToJson"/> / <see cref="SaveService.FromJson"/>) can be tested
    /// without touching the filesystem. Defaults to <c>Application.persistentDataPath</c>; tests
    /// may point it at a temporary directory.
    /// </summary>
    public sealed class SaveFileStore
    {
        private readonly string _directory;

        /// <summary>Creates a store rooted at the platform's persistent data path.</summary>
        public SaveFileStore()
            : this(Application.persistentDataPath)
        {
        }

        /// <summary>Creates a store rooted at <paramref name="directory"/> (used by tests).</summary>
        public SaveFileStore(string directory)
        {
            _directory = directory;
        }

        /// <summary>Whether a save file with the given name exists.</summary>
        public bool Exists(string fileName) => File.Exists(PathFor(fileName));

        /// <summary>Writes JSON to the named save file, creating the directory if needed.</summary>
        public void Write(string fileName, string json)
        {
            Directory.CreateDirectory(_directory);
            File.WriteAllText(PathFor(fileName), json);
        }

        /// <summary>Reads JSON from the named save file.</summary>
        public string Read(string fileName) => File.ReadAllText(PathFor(fileName));

        private string PathFor(string fileName) => Path.Combine(_directory, fileName);
    }
}
