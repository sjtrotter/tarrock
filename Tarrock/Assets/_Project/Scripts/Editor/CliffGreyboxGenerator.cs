namespace Tarrock.Editor;

using System.IO;
using Tarrock.Regions;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;

/// <summary>
/// Editor command that builds the Cliff's greybox scene — the primitive realisation of
/// MQ00's spaces (docs/quests/main/MQ00-the-leap.md): campfire wake-up spot, old
/// campsites, the buried keepsake, the dead tree on its knoll, the standing stones, the
/// Waystation, the Blank ambush, and the cliff's-edge leap. Mirrors
/// <see cref="CoreScenesSetup"/>'s pattern: a public static entry point usable both from
/// the menu and headlessly via <c>-executeMethod</c>, idempotent against an existing
/// scene file.
/// </summary>
public static class CliffGreyboxGenerator
{
    private const string ScenesDirectory = "Assets/_Project/Scenes/Regions";
    private const string ScenePath = ScenesDirectory + "/Cliff.unity";
    private const string ArtDirectory = "Assets/_Project/Art/Greybox";

    // ==================================================================================
    // MQ00 layout constants (docs/quests/main/MQ00-the-leap.md). X = east(+) to west(-),
    // matching the quest's west-bound walk toward the leap; Z = south(-) to north(+).
    // Origin sits at the plateau's centre; all values are metres. Each block below maps
    // straight to one of the quest's scene headings.
    // ==================================================================================

    // Plateau_Ground: a 240x240m flattened slab. Ground covers X/Z in [-Half, +Half];
    // the west edge (X = -Half) is where the ground simply stops — no wall, per canon.
    private const float PlateauHalfSize = 120f;
    private const float GroundY = -1f;
    private const float GroundHeight = 2f;

    // "The High Meadow" (dawn) — campfire wake-up, east side, generous run-up west.
    private const float CampfireX = 80f;
    private const float CampfireZ = 0f;

    // "The Old Campsites" — five rings scattered across the plateau's middle third.
    private const float Campsite1X = 55f, Campsite1Z = -18f;   // plain 3-cube ring
    private const float Campsite2X = 38f, Campsite2Z = 14f;    // ring + lean-to
    private const float Campsite3X = 20f, Campsite3Z = -16f;   // ring + upright walking stick
    private const float Campsite4X = 2f, Campsite4Z = 12f;     // the largest ring + keepsake dig spot
    private const float Campsite5X = -15f, Campsite5Z = -6f;   // the recent-looking ring

    // "The Dead Tree" — a north detour off the main path, atop a raised knoll.
    private const float DeadTreeX = -10f;
    private const float DeadTreeZ = 65f;

    // "The Waystation Approach" — standing stones flanking the path.
    private const float StandingStonesX = -50f;
    private const float StandingStonesZSpread = 8f;

    // The Blank ambush, staged on the path just before the Waystation.
    private const float AmbushX = -75f;

    // "The First Waystation".
    private const float WaystationX = -100f;

    // "The Cliff's Edge" / "The Edge of the World" — the rim sits at the ground's west
    // edge; the void begins immediately beyond it, and the leap trigger's near face sits
    // flush with that edge so stepping off the ground enters it right away.
    private const float CliffEdgeX = -PlateauHalfSize + 1f; // just inside the ground's edge
    private const float LeapTriggerDepth = 10f;
    private const float LeapTriggerX = -PlateauHalfSize - (LeapTriggerDepth * 0.5f);
    private const float LeapTriggerHeight = 20f;
    private const float LeapTriggerY = -8f;
    private const float VoidCatchY = -80f;

    [MenuItem("Tarrock/Setup/Generate Cliff Greybox")]
    public static void Generate()
    {
        if (File.Exists(ScenePath))
        {
            Debug.Log($"[Tarrock] Cliff greybox already exists, skipping: {ScenePath}. " +
                      "Use \"Tarrock/Setup/Regenerate Cliff Greybox (Overwrite)\" to rebuild it.");
            return;
        }

        Build();
    }

    [MenuItem("Tarrock/Setup/Regenerate Cliff Greybox (Overwrite)")]
    public static void Regenerate()
    {
        if (File.Exists(ScenePath))
        {
            AssetDatabase.DeleteAsset(ScenePath);
            Debug.Log($"[Tarrock] Deleted existing Cliff greybox: {ScenePath}");
        }

        Build();
    }

    private static void Build()
    {
        Directory.CreateDirectory(ScenesDirectory);

        GreyboxMaterials mats = CreateMaterials();

        UnityEngine.SceneManagement.Scene scene =
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

        var environment = CreateEmpty("Environment", null, Vector3.zero);
        var gameplay = CreateEmpty("Gameplay", null, Vector3.zero);
        var lighting = CreateEmpty("Lighting", null, Vector3.zero);

        CreateGround(environment.transform, mats);
        CreateVoidCatch(environment.transform, mats);
        CreateCliffEdgeMarker(environment.transform);
        CreateCampfireWake(environment.transform, mats);
        CreateOldCampsites(environment.transform, mats);
        CreateDeadTreeKnoll(environment.transform, mats);
        CreateStandingStones(environment.transform, mats);
        CreateWaystation(environment.transform, mats);

        CreateAmbushTrigger(gameplay.transform);
        CreateLeapTrigger(gameplay.transform);

        CreateLighting(lighting.transform);

        EditorSceneManager.SaveScene(scene, ScenePath);
        AssetDatabase.SaveAssets();

        int objectCount = CountObjects(scene);
        Debug.Log($"[Tarrock] Generated Cliff greybox at {ScenePath} — {objectCount} GameObjects across " +
                  "Environment/Gameplay/Lighting (MQ00 journey west: campfire -> old campsites -> " +
                  "dead tree knoll -> standing stones -> Blank ambush -> Waystation -> cliff edge).");
    }

    // ---------------------------------------------------------------------------------
    // Materials
    // ---------------------------------------------------------------------------------

    private readonly struct GreyboxMaterials
    {
        public readonly Material Grass;
        public readonly Material Stone;
        public readonly Material Wood;
        public readonly Material DeadTree;
        public readonly Material Marker;
        public readonly Material TriggerVolume;

        public GreyboxMaterials(Material grass, Material stone, Material wood, Material deadTree,
            Material marker, Material triggerVolume)
        {
            Grass = grass;
            Stone = stone;
            Wood = wood;
            DeadTree = deadTree;
            Marker = marker;
            TriggerVolume = triggerVolume;
        }
    }

    private static GreyboxMaterials CreateMaterials()
    {
        Directory.CreateDirectory(ArtDirectory);

        // TriggerVolume is created for completeness/idempotency (and any future debug
        // visualisation) even though the current trigger volumes below are pure colliders
        // with no renderer — per the brief, an opaque-red material stands in for a
        // translucent one, and trigger volumes simply go without a mesh renderer instead
        // of fighting URP transparency from code.
        return new GreyboxMaterials(
            grass: GetOrCreateMaterial("Grass", new Color(0.33f, 0.45f, 0.24f)),
            stone: GetOrCreateMaterial("Stone", new Color(0.52f, 0.52f, 0.5f)),
            wood: GetOrCreateMaterial("Wood", new Color(0.4f, 0.26f, 0.13f)),
            deadTree: GetOrCreateMaterial("DeadTree", new Color(0.07f, 0.07f, 0.07f)),
            marker: GetOrCreateMaterial("Marker", new Color(1f, 0.85f, 0f)),
            triggerVolume: GetOrCreateMaterial("TriggerVolume", new Color(0.8f, 0.1f, 0.1f)));
    }

    private static Material GetOrCreateMaterial(string name, Color baseColor)
    {
        string path = $"{ArtDirectory}/{name}.mat";
        var existing = AssetDatabase.LoadAssetAtPath<Material>(path);
        if (existing != null)
        {
            return existing;
        }

        Shader shader = Shader.Find("Universal Render Pipeline/Lit");
        var material = new Material(shader) { name = name };
        material.SetColor("_BaseColor", baseColor);

        AssetDatabase.CreateAsset(material, path);
        return material;
    }

    // ---------------------------------------------------------------------------------
    // Environment
    // ---------------------------------------------------------------------------------

    private static void CreateGround(Transform parent, GreyboxMaterials mats)
    {
        CreatePrimitive(PrimitiveType.Cube, "Plateau_Ground", parent,
            new Vector3(0f, GroundY, 0f),
            new Vector3(PlateauHalfSize * 2f, GroundHeight, PlateauHalfSize * 2f),
            mats.Grass);
    }

    private static void CreateVoidCatch(Transform parent, GreyboxMaterials mats)
    {
        // Sells the drop without a wall: nothing exists between the west rim and this
        // slab, far below and well beyond it. Given a Stone renderer (per the brief) so a
        // fall reads clearly instead of vanishing into nothing.
        CreatePrimitive(PrimitiveType.Cube, "Void_Catch", parent,
            new Vector3(0f, VoidCatchY, 0f),
            new Vector3(PlateauHalfSize * 6f, GroundHeight, PlateauHalfSize * 6f),
            mats.Stone);
    }

    private static void CreateCliffEdgeMarker(Transform parent)
    {
        GameObject marker = CreateEmpty("CliffEdge_Marker", parent, new Vector3(CliffEdgeX, 0f, 0f));
        SetMarkerId(marker.AddComponent<InteractionMarker>(), CliffMarkerIds.CliffEdge);
    }

    private static void CreateCampfireWake(Transform parent, GreyboxMaterials mats)
    {
        GameObject campfire = CreateEmpty("Campfire_Wake", parent, new Vector3(CampfireX, 0f, CampfireZ));

        const int stoneCount = 6;
        const float ringRadius = 1f;
        for (int i = 0; i < stoneCount; i++)
        {
            float angle = i * Mathf.PI * 2f / stoneCount;
            var position = new Vector3(Mathf.Cos(angle) * ringRadius, 0.15f, Mathf.Sin(angle) * ringRadius);
            CreatePrimitive(PrimitiveType.Cube, $"RingStone_{i + 1}", campfire.transform,
                position, new Vector3(0.3f, 0.3f, 0.3f), mats.Stone);
        }

        CreatePrimitive(PrimitiveType.Cylinder, "Fire_Log", campfire.transform,
            new Vector3(0f, 0.15f, 0f), new Vector3(0.25f, 0.5f, 0.25f), mats.Wood,
            Quaternion.Euler(0f, 0f, 90f));

        GameObject spawn = CreateEmpty("PlayerSpawn_Campfire", campfire.transform, new Vector3(1.5f, 0f, 0f));
        spawn.transform.localRotation = Quaternion.LookRotation(Vector3.left, Vector3.up); // facing west
        spawn.AddComponent<PlayerSpawnPoint>();
    }

    private static void CreateOldCampsites(Transform parent, GreyboxMaterials mats)
    {
        GameObject group = CreateEmpty("OldCampsites", parent, Vector3.zero);

        CreateCampsiteRing(group.transform, "Campsite_1", new Vector3(Campsite1X, 0f, Campsite1Z), 3, mats);

        GameObject campsite2 = CreateCampsiteRing(group.transform, "Campsite_2_LeanTo",
            new Vector3(Campsite2X, 0f, Campsite2Z), 4, mats);
        AddLeanTo(campsite2.transform, mats);

        GameObject campsite3 = CreateCampsiteRing(group.transform, "Campsite_3_WalkingStick",
            new Vector3(Campsite3X, 0f, Campsite3Z), 4, mats);
        AddWalkingStick(campsite3.transform, mats);

        GameObject campsite4 = CreateCampsiteRing(group.transform, "Campsite_4_Largest",
            new Vector3(Campsite4X, 0f, Campsite4Z), 5, mats);
        AddKeepsakeDigSpot(campsite4.transform, mats);

        CreateCampsiteRing(group.transform, "Campsite_5_Recent", new Vector3(Campsite5X, 0f, Campsite5Z), 4, mats);
    }

    private static GameObject CreateCampsiteRing(Transform parent, string name, Vector3 localPosition,
        int charredCubeCount, GreyboxMaterials mats)
    {
        GameObject campsite = CreateEmpty(name, parent, localPosition);

        const float ringRadius = 0.8f;
        for (int i = 0; i < charredCubeCount; i++)
        {
            float angle = i * Mathf.PI * 2f / charredCubeCount;
            var position = new Vector3(Mathf.Cos(angle) * ringRadius, 0.1f, Mathf.Sin(angle) * ringRadius);
            CreatePrimitive(PrimitiveType.Cube, $"CharredStone_{i + 1}", campsite.transform,
                position, new Vector3(0.25f, 0.2f, 0.25f), mats.Stone);
        }

        return campsite;
    }

    private static void AddLeanTo(Transform campsite, GreyboxMaterials mats)
    {
        CreatePrimitive(PrimitiveType.Cube, "LeanTo_Beam_1", campsite,
            new Vector3(0.6f, 0.6f, 0f), new Vector3(0.15f, 1.6f, 0.15f), mats.Wood,
            Quaternion.Euler(0f, 0f, 35f));
        CreatePrimitive(PrimitiveType.Cube, "LeanTo_Beam_2", campsite,
            new Vector3(-0.6f, 0.6f, 0f), new Vector3(0.15f, 1.6f, 0.15f), mats.Wood,
            Quaternion.Euler(0f, 0f, -35f));
    }

    private static void AddWalkingStick(Transform campsite, GreyboxMaterials mats)
    {
        CreatePrimitive(PrimitiveType.Cylinder, "WalkingStick", campsite,
            new Vector3(1f, 0.6f, 0.3f), new Vector3(0.05f, 0.6f, 0.05f), mats.Wood);
    }

    private static void AddKeepsakeDigSpot(Transform campsite, GreyboxMaterials mats)
    {
        GameObject digSpot = CreatePrimitive(PrimitiveType.Cylinder, "Keepsake_DigSpot", campsite,
            new Vector3(1.2f, 0.02f, -0.8f), new Vector3(0.5f, 0.02f, 0.5f), mats.Marker);
        SetMarkerId(digSpot.AddComponent<InteractionMarker>(), CliffMarkerIds.KeepsakeDigSpot);
    }

    private static void CreateDeadTreeKnoll(Transform parent, GreyboxMaterials mats)
    {
        GameObject knoll = CreateEmpty("DeadTree_Knoll", parent, new Vector3(DeadTreeX, 0f, DeadTreeZ));

        CreatePrimitive(PrimitiveType.Sphere, "Knoll_Mound", knoll.transform,
            new Vector3(0f, -1f, 0f), new Vector3(14f, 4f, 14f), mats.Grass);

        GameObject tree = CreateEmpty("DeadTree", knoll.transform, new Vector3(0f, 1f, 0f));

        CreatePrimitive(PrimitiveType.Cube, "Trunk", tree.transform,
            new Vector3(0f, 2f, 0f), new Vector3(0.5f, 4f, 0.5f), mats.DeadTree);

        CreatePrimitive(PrimitiveType.Cube, "Branch_1", tree.transform,
            new Vector3(0.6f, 3.6f, 0f), new Vector3(0.2f, 1.6f, 0.2f), mats.DeadTree,
            Quaternion.Euler(0f, 0f, 50f));
        CreatePrimitive(PrimitiveType.Cube, "Branch_2", tree.transform,
            new Vector3(-0.6f, 3.4f, 0.2f), new Vector3(0.2f, 1.4f, 0.2f), mats.DeadTree,
            Quaternion.Euler(-20f, 0f, -45f));
        CreatePrimitive(PrimitiveType.Cube, "Branch_3", tree.transform,
            new Vector3(0f, 3.9f, -0.5f), new Vector3(0.15f, 1.2f, 0.15f), mats.DeadTree,
            Quaternion.Euler(30f, 0f, 10f));
        CreatePrimitive(PrimitiveType.Cube, "Branch_4", tree.transform,
            new Vector3(0.2f, 3.2f, 0.6f), new Vector3(0.15f, 1f, 0.15f), mats.DeadTree,
            Quaternion.Euler(-40f, 20f, -20f));

        SetMarkerId(tree.AddComponent<InteractionMarker>(), CliffMarkerIds.DeadTree);
    }

    private static void CreateStandingStones(Transform parent, GreyboxMaterials mats)
    {
        GameObject group = CreateEmpty("StandingStones", parent, new Vector3(StandingStonesX, 0f, 0f));

        CreatePrimitive(PrimitiveType.Cube, "Stone_North", group.transform,
            new Vector3(0f, 1.75f, StandingStonesZSpread), new Vector3(1f, 3.5f, 1f), mats.Stone,
            Quaternion.Euler(0f, 0f, -4f));
        CreatePrimitive(PrimitiveType.Cube, "Stone_South", group.transform,
            new Vector3(0f, 1.6f, -StandingStonesZSpread), new Vector3(1f, 3.2f, 1f), mats.Stone,
            Quaternion.Euler(0f, 0f, 5f));
    }

    private static void CreateWaystation(Transform parent, GreyboxMaterials mats)
    {
        GameObject waystation = CreateEmpty("Waystation", parent, new Vector3(WaystationX, 0f, 0f));

        CreatePrimitive(PrimitiveType.Cube, "Arch_UprightLeft", waystation.transform,
            new Vector3(-1.2f, 1.5f, 0f), new Vector3(0.6f, 3f, 0.6f), mats.Stone);
        CreatePrimitive(PrimitiveType.Cube, "Arch_UprightRight", waystation.transform,
            new Vector3(1.2f, 1.5f, 0f), new Vector3(0.6f, 3f, 0.6f), mats.Stone);
        CreatePrimitive(PrimitiveType.Cube, "Arch_Lintel", waystation.transform,
            new Vector3(0f, 3.15f, 0f), new Vector3(3.2f, 0.6f, 0.6f), mats.Stone);

        CreatePrimitive(PrimitiveType.Cylinder, "Basin", waystation.transform,
            new Vector3(0f, 0.4f, 2f), new Vector3(0.8f, 0.4f, 0.8f), mats.Stone);

        SetMarkerId(waystation.AddComponent<InteractionMarker>(), CliffMarkerIds.Waystation);
    }

    // ---------------------------------------------------------------------------------
    // Gameplay
    // ---------------------------------------------------------------------------------

    private static void CreateAmbushTrigger(Transform parent)
    {
        GameObject trigger = CreateEmpty("Ambush_Trigger", parent, new Vector3(AmbushX, 1f, 0f));

        var box = trigger.AddComponent<BoxCollider>();
        box.isTrigger = true;
        box.size = new Vector3(10f, 3f, 6f); // spans the path's width, before the Waystation

        SetMarkerId(trigger.AddComponent<InteractionMarker>(), CliffMarkerIds.BlankAmbush);
    }

    private static void CreateLeapTrigger(Transform parent)
    {
        GameObject trigger = CreateEmpty("Leap_Trigger", parent, new Vector3(LeapTriggerX, LeapTriggerY, 0f));

        var box = trigger.AddComponent<BoxCollider>();
        box.isTrigger = true;
        // Near face flush with the ground's west edge; runs the full width of the rim so
        // stepping off anywhere along it enters the trigger.
        box.size = new Vector3(LeapTriggerDepth, LeapTriggerHeight, PlateauHalfSize * 2f);

        trigger.AddComponent<LeapOfFaithTrigger>();
    }

    // ---------------------------------------------------------------------------------
    // Lighting
    // ---------------------------------------------------------------------------------

    private static void CreateLighting(Transform parent)
    {
        GameObject sun = CreateEmpty("Directional_Light_Dawn", parent, Vector3.zero);
        sun.transform.localRotation = Quaternion.Euler(25f, 250f, 0f);

        var light = sun.AddComponent<Light>();
        light.type = LightType.Directional;
        light.color = new Color(1f, 0.93f, 0.78f); // warm, slightly gold dawn light
        light.intensity = 1.2f;
    }

    // ---------------------------------------------------------------------------------
    // Shared helpers
    // ---------------------------------------------------------------------------------

    private static GameObject CreateEmpty(string name, Transform parent, Vector3 localPosition)
    {
        var go = new GameObject(name);
        if (parent != null)
        {
            go.transform.SetParent(parent, false);
        }

        go.transform.localPosition = localPosition;
        return go;
    }

    private static GameObject CreatePrimitive(PrimitiveType type, string name, Transform parent,
        Vector3 localPosition, Vector3 localScale, Material material, Quaternion? localRotation = null)
    {
        GameObject go = GameObject.CreatePrimitive(type);
        go.name = name;
        go.transform.SetParent(parent, false);
        go.transform.localPosition = localPosition;
        go.transform.localRotation = localRotation ?? Quaternion.identity;
        go.transform.localScale = localScale;

        var renderer = go.GetComponent<MeshRenderer>();
        if (renderer != null)
        {
            renderer.sharedMaterial = material;
        }

        return go;
    }

    private static void SetMarkerId(InteractionMarker marker, string markerId)
    {
        var serialized = new SerializedObject(marker);
        serialized.FindProperty("_markerId").stringValue = markerId;
        serialized.ApplyModifiedPropertiesWithoutUndo();
    }

    private static int CountObjects(UnityEngine.SceneManagement.Scene scene)
    {
        int count = 0;
        foreach (GameObject root in scene.GetRootGameObjects())
        {
            count += CountRecursive(root.transform);
        }

        return count;
    }

    private static int CountRecursive(Transform transform)
    {
        int count = 1;
        foreach (Transform child in transform)
        {
            count += CountRecursive(child);
        }

        return count;
    }
}
