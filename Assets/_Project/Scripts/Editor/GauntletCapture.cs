namespace Tarrock.EditorTools
{

    using System;
    using System.Collections.Generic;
    using System.IO;
    using Tarrock.Editor;
    using Unity.Cinemachine;
    using UnityEditor;
    using UnityEditor.SceneManagement;
    using UnityEngine;
    using UnityEngine.Rendering.Universal;

    /// <summary>
    /// The Gauntlet screenshot rig: nine FIXED vantages on <c>TerrainProto.unity</c>, rendered at
    /// 1920×1080 (16:9) with post-processing on, so every look round is judged against the same
    /// frames and only the ART changes between rounds.
    ///
    /// <para>WHY FIXED VANTAGES. A look review is a comparison, and a comparison needs a control.
    /// Hand-flown screenshots move the camera between rounds, so a change in the image can never be
    /// attributed to a change in the work. Everything here that could drift between rounds is pinned:
    /// the region is REGENERATED from <see cref="TerrainRegionGenerator"/> first (that generator is
    /// deterministic — same constants in, same landform out), the quality level is forced to the PC
    /// level (MSAA and shadow distance ride on it), the camera FOV/aspect are set per vantage, the
    /// foliage wind and grass bend globals are written explicitly, and the mote particles are
    /// simulated to a fixed settle time from a fixed seed. The only residual non-determinism is
    /// shader <c>_Time</c> (editor clock), and since the 2026-07-31 ruling took ambient sway out of
    /// the bound meadow there is nothing left that reads it but the motes' own drift — never
    /// framing, never colour.</para>
    ///
    /// <para>THE VANTAGE SET answers the questions each round actually asks: does the opening frame
    /// read (v1/v2), does the island-in-cloud read (v3/v4), does the ground hold up close (v5), does
    /// the meadow hold at human scale and where does its LOD line fall (v6/v7), and does the Cliff's
    /// signature — the one dead tree — still break the sky (v8). Coordinates are derived from the
    /// generator's own constants (spawn bowl at 214,91; knoll and dead tree at 150,58; the valley
    /// meander <c>centreZ(x)</c>; the western mouth at x≈24) — see each vantage for its reasoning.</para>
    ///
    /// <para>BATCH USE (note: NO <c>-nographics</c> — this renders, so it needs a graphics device;
    /// and no <c>-quit</c> — the session ends itself via <see cref="EditorApplication.Exit"/>):
    /// <code>
    /// TARROCK_CAPTURE_DIR=Assets/Screenshots/gauntlet/round2 \
    /// Unity -batchmode -projectPath &lt;proj&gt; \
    ///   -executeMethod Tarrock.EditorTools.GauntletCapture.CaptureAllBatch -logFile &lt;log&gt;
    /// </code>
    /// Exit codes: 0 = every vantage written; 1 = one or more vantages failed; 2 = the run threw or
    /// the scene/quality preconditions were not met.</para>
    ///
    /// <para>The scene is NEVER saved by this rig: the camera, the stand-in Fool and the particle
    /// seeds are moved for the shots and restored afterwards, so a director running the menu item on
    /// an open scene gets their scene back exactly as it was. Scene-affecting CHANGES belong in
    /// <see cref="TerrainRegionGenerator"/>, never here and never by hand.</para>
    /// </summary>
    public static class GauntletCapture
    {
        private const string ScenePath = "Assets/_Project/Scenes/Sandbox/TerrainProto.unity";
        private const string DefaultOutputDirectory = "Assets/Screenshots/gauntlet/round1";
        private const string OutputDirectoryVariable = "TARROCK_CAPTURE_DIR";
        private const string LogPrefix = "[Tarrock.Gauntlet]";

        // 16:9 at 1080p — the review format. Anything else and shots from two rounds cannot be
        // flipped between at the same size, which is how a look review is actually read.
        private const int CaptureWidth = 1920;
        private const int CaptureHeight = 1080;
        private const float CaptureAspect = (float)CaptureWidth / CaptureHeight;

        // The PC quality level (ProjectSettings/QualitySettings.asset: 0 = Mobile, 1 = PC). Resolved
        // BY NAME at runtime — the index is an implementation detail of the settings asset, the name
        // is the contract. MSAA (4×) and shadow distance live on this level, so pinning it is what
        // stops "the shadows got softer" being an artefact of which level the editor last used.
        private const string PcQualityLevelName = "PC";

        // Scene object names owned by the installers (KayKitCharacterInstaller / TerrainRegionGenerator).
        private const string MainCameraTag = "MainCamera";
        private const string PlayerRootName = "PlayerRig";

        // -- Wind and bend globals. Neither Tarrock.Regions.RegionWind nor Tarrock.Regions.GrassBender
        //    runs in edit mode, so both globals are whatever the editor session last left in them —
        //    the rig writes them EXPLICITLY so a round is never shot at a stray value someone
        //    scrubbed in the inspector. Capture-time only; the scene is never saved, no flag fired,
        //    and everything written here is cleared again when the shoot ends.
        //
        //    WIND is the BOUND value, 0, because that is the Cliff's state and therefore the picture
        //    the game actually shows. Since the director's 2026-07-31 ruling that is literally no
        //    motion: Tarrock/GrassTuft gates ALL of its sway on this global and poses the meadow's
        //    "wind-combed" look as a static lean instead. Writing 1 here would photograph the region
        //    unbound — moving grass plus foliage that canon says cannot move.
        //
        //    BEND is the exception the same ruling created: the bound world still yields to touch.
        //    The shoot writes a bender at the stand-in Fool's feet (plus a short wake behind him) on
        //    the vantages that plant him, so the meadow shots SHOW the ring of grass pushed aside
        //    rather than leaving the reviewer to take it on trust from a still. Slot count and the
        //    packing MUST match Tarrock.Regions.GrassBender / Tarrock/GrassTuft: xyz+radius in
        //    _TarrockBenderData, strength in _TarrockBenderPower.x, and a bounding sphere in
        //    _TarrockBenderBounds that the shader early-outs against.
        private static readonly int WindStrengthId = Shader.PropertyToID("_TarrockWindStrength");
        private const float CaptureWindStrength = 0f;

        private static readonly int BenderDataId = Shader.PropertyToID("_TarrockBenderData");
        private static readonly int BenderPowerId = Shader.PropertyToID("_TarrockBenderPower");
        private static readonly int BenderBoundsId = Shader.PropertyToID("_TarrockBenderBounds");
        private const int BenderSlots = 8;

        // Matches the GrassBender the generator puts on the Fool's rig, so the photographed ring is
        // the same size as the one the player walks around in. It MUST track that value: a shoot
        // that photographs a ring the game does not produce is worse than a shoot with no ring in
        // it, because the review passes something that was never there.
        //
        // ROUND-4 VERIFICATION, written down so the next round does not re-suspect it. The bend
        // ring had failed to read for three rounds and the leading theory was that these globals
        // did not land where the stand-in was actually planted. THEY DO, and the check is exact:
        // WriteBendGlobals takes `standIn.position` AFTER PlaceStandIn has set it from the
        // vantage's own StandInXz, so the two cannot differ by construction — there is no second
        // source of the coordinate to disagree with. Re-projecting round3/v6 through its own
        // vantage maths puts the feet at pixel (960, 999) in a 1920x1080 frame and the 0.72 m ring
        // at 723-1169 px across, and the crop of that region shows the disc plainly: no upright
        // blades inside it. THE RING WAS ALWAYS IN THE PICTURE. It did not read because a blade
        // laid to 90° is optically an absent blade and the pressed area carried no value change,
        // so the ring rendered as one more bald patch on ground the same critique was already
        // calling too bare. The fix is therefore entirely in Tarrock/GrassTuft (_BendLayDegrees,
        // _BendDarken) and in the mat the disc is pressed into — not here. This number is correct
        // and should be left alone unless the rig's own radius moves.
        private const float StandInBendRadius = 0.72f;
        // Two fading wake points behind him: a still of a standing figure shows a ring, but a ring
        // with a wake behind it shows that he WALKED here, which is the thing being reviewed. The
        // spacing tracks the rig's own trail spacing for the same reason as the radius.
        private const float WakeSpacing = 0.42f;
        // Wake strengths, freshest first. Raised from round 2's 0.55 / 0.22: with the shader now
        // holding the inner half of each ring fully laid over, a 0.22 press no longer lays anything
        // at all, and the wake would photograph as one ring with nothing behind it.
        private const float NearWakePower = 0.72f;
        private const float FarWakePower = 0.42f;

        private static readonly Vector4[] BenderData = new Vector4[BenderSlots];
        private static readonly Vector4[] BenderPower = new Vector4[BenderSlots];

        // Motes: simulated to a fixed settle time from a fixed seed so the dust hangs in the same
        // places every round (art-audio.md — the one particulate allowed while bound).
        private const float ParticleSettleSeconds = 12f;
        private const uint ParticleSeed = 20260731u;

        // Third-person rig geometry, mirroring KayKitCharacterInstaller's camera ratios so the
        // gameplay vantages frame what the player actually sees. (Those constants are private to the
        // installer; they are restated here with this note rather than made public — if the rig is
        // re-tuned, retune these to match and say so in the commit.)
        private const float PlayerHeight = 1.7f;
        private const float CameraPivotHeight = PlayerHeight * 0.92f;   // ≈ head height
        private const float CameraOrbitRadius = PlayerHeight * 3.3f;    // ≈ 5.6 m behind
        private const float CameraTiltDegrees = 16f;                    // the rig's resting tilt
        private const float GameplayFieldOfView = 55f;                  // the rig's lens

        // Landform anchors, taken from TerrainRegionGenerator (its SpawnHint / KnollCentre and the
        // valley functions). Kept as named constants so a vantage reads as "at the spawn" rather
        // than as a pair of numbers.
        private const float SpawnX = 214f;
        private const float SpawnZ = 91f;
        private const float KnollX = 150f;
        private const float KnollZ = 58f;
        private const float KnollTreeCrownLift = 6f;   // aim above the summit: the crown, not the roots

        // The west shoulder's foot (round 9's approach shelf, Landform.cs §THE KNOLL APPROACH:
        // ApproachFootBearing 275°, ApproachFootRadius 32 m from KnollCentre). DERIVED there,
        // restated here for the same reason SpawnX/KnollX are — those constants are private to the
        // generator. If the shelf's bearing or radius move, move these with them and say so.
        private const float ShelfFootX = 118.12f;
        private const float ShelfFootZ = 60.79f;
        // Eleven metres up the tread from the foot, on the spiral's own centreline: the mark the
        // stand-in walks to in v9. Sampled from the shipped spiral, not eyeballed.
        private const float ShelfWalkX = 125.22f;
        private const float ShelfWalkZ = 52.74f;
        // Three metres above the trunk's ground, which is where the v9 lens is aimed. NOT the
        // crown lift v8 uses: v9 stands 37 m out and 12 m BELOW the tree, so aiming at the crown
        // would pitch the lens up past the shelf the shot exists to show. See the vantage.
        private const float ShelfAimLift = 3f;

        private const float StandInGroundClearance = 0.02f; // matches the installer's grounded spawn

        // Discarded renders before the first vantage is shot. See WarmUpRenderer for the
        // measurement; two rather than one because the residency this covers is an upload with a
        // time slice (QualitySettings.asyncUploadTimeSlice, 2 ms), not a single blocking load.
        private const int WarmUpPasses = 2;

        private const int ExitSuccess = 0;
        private const int ExitCaptureFailed = 1;
        private const int ExitPreconditionFailed = 2;

        private const float GroundProbeHeight = 400f;
        private const float GroundProbeLength = 800f;

        /// <summary>
        /// The nine review frames. Order is the order they are shot and the order they read in:
        /// the opening frame first, the region's claims next, the ground and the meadow, and last
        /// (round 10) the walk up the west shoulder to the tree.
        /// </summary>
        private static readonly Vantage[] Vantages =
        {
            // v1 — the opening frame. Third-person at the spawn bowl looking due west, down the
            // valley: the shot that decides whether the game's first second is beautiful. This is
            // now the RAKING frame — TerrainRegionGenerator.SunEuler is 12°/152°, so the disc sits at
            // bearing ≈332° (NNW), 62° off this view — which is what makes the landform's
            // north-refuses/south-permits grammar readable in the very first frame.
            // (ROUND 2: v1 and v2 have SWAPPED ROLES. Round 1's sun sat at ≈297°, only 27° off this
            // view, i.e. essentially contre-jour, and v2 was the raking one.)
            // NOTE, measured and not yet fixed: the knoll and its dead tree sit ~27° left of frame
            // centre but ~18° ABOVE the horizontal, and this vantage's frame tops out ~11.5° up, so
            // the landmark is cropped off the top-left corner. v1 does NOT currently test "does the
            // landmark pull the eye" — v8 does. Lowering v1's pitch would fix it and is a rig call.
            Vantage.ThirdPerson("v1-spawn-west", SpawnX, SpawnZ, yawDegrees: 270f),

            // v2 — the same spot, rotated. Round 1 shot this as the raking frame; at the round-2 sun
            // it is the near-contre-jour one (view yaw 348°, sun bearing ≈332° — only ~16° to the
            // left), so it now reads as a low blaze with everything rim-lit. That is a legitimate
            // storybook frame, not a mistake — but the grammar test moved to v1 above.
            Vantage.ThirdPerson("v2-spawn-side", SpawnX, SpawnZ, yawDegrees: 348f),

            // v3 — the western rim at the valley mouth (x≈25, on the meander's z≈138), looking out
            // over the cloud deck. The ground here sits ~15.7 m with the lip ~6 m below and the deck
            // at y=11: the island-in-cloud claim, tested at eye level where the player meets it.
            Vantage.Facing(
                "v3-rim-west", cameraX: 25f, cameraZ: 138f, eyeHeight: 1.6f,
                yawDegrees: 268f, pitchDegrees: 5f),

            // v4 — from the knoll's east shoulder (the region's highest walkable ground, ~52 m)
            // looking back east across the spawn bowl. The one vantage that shows the whole island
            // at once: bowl, valley, broken edges, cloud horizon.
            Vantage.LookingAt(
                "v4-knoll-east", cameraX: 155f, cameraZ: 61f, eyeHeight: 1.6f,
                targetX: SpawnX, targetZ: SpawnZ, targetLift: 10f),

            // v5 — ground close, 3/4, at a real slope break: the valley's north refusing wall meets
            // the meadow floor at x≈154, z≈147 (a ~7 m rise at ~65°, so grass gives way to rock
            // shading right there). ~2.6 m out at 45° FOV — brush economy, moss-not-grime, and the
            // grass/rock transition all in one frame.
            Vantage.LookingAt(
                "v5-ground-close", cameraX: 155.6f, cameraZ: 144.6f, eyeHeight: 1.15f,
                targetX: 154.2f, targetZ: 146.8f, targetLift: 0.6f, fieldOfView: 45f),

            // v6 — human-scale meadow check, in the thickest grass on the valley floor (the detail
            // density map peaks around x≈174, z≈100 on gentle ground at ~22 m). The stand-in Fool
            // is planted 3.5 m ahead, three-quarter from behind, facing down-valley: the only honest
            // answer to "is the grass ankle-high or waist-high".
            Vantage.LookingAt(
                    "v6-meadow-scale", cameraX: 177.4f, cameraZ: 99f, eyeHeight: 1.65f,
                    targetX: 174f, targetZ: 100f, targetLift: CameraPivotHeight)
                .WithStandIn(174f, 100f, yawDegrees: 250f),

            // v7 — the same stand-in from ~30 m back along the same axis, at eye level. At this
            // range the terrain detail distance (120 m) and the tuft fade (78→114 m) fall inside
            // the frame, so
            // the grass LOD/cutoff line is visible and can be judged rather than discovered later.
            Vantage.LookingAt(
                    "v7-meadow-far", cameraX: 202.8f, cameraZ: 91.5f, eyeHeight: 1.65f,
                    targetX: 174f, targetZ: 100f, targetLift: CameraPivotHeight)
                .WithStandIn(174f, 100f, yawDegrees: 250f),

            // v8 — the Cliff's signature: the knoll framed from the valley floor east of it, aimed
            // at the dead tree's crown with nothing but sky behind (the knoll is the high point, so
            // every ridge beyond it falls away). Looking WSW, so the tree is backlit by the dawn sun
            // — the silhouette read, which is the read that has to survive.
            Vantage.LookingAt(
                "v8-deadtree-skyline", cameraX: 200f, cameraZ: 84f, eyeHeight: 1.6f,
                targetX: KnollX, targetZ: KnollZ, targetLift: KnollTreeCrownLift, fieldOfView: 50f),

            // v9 — THE WALK UP. Round 9 cut the one walkable line to the dead tree (the west
            // shoulder's spiral tread) and shipped it without a single frame looking at it; this is
            // that frame. The lens is the gameplay rig — pivot on the tread at the shelf's FOOT,
            // seat 5.39 m behind it and 3.11 m above its ground, 55° — so what it shows is what a
            // walking player sees, and the stand-in is planted eleven metres up the tread ahead of
            // him so the shot reviews the WALK and not the back of a head.
            //
            // WHY THE FOOT, and it is arithmetic, not taste. The rig fixes the player's own head
            // 14.7° BELOW the lens's horizontal (1.41 m under the seat, 5.39 m in front of it:
            // atan(1.41/5.39)). From the shelf's foot the crown of the 21.6 m tree standing on the
            // 12.1 m knoll sits 39.3° ABOVE it. 39.3 + 14.7 = 54.0° against a 55° lens. Walked up
            // the tread that sum is 54.4° at 5 m, 55.7° at 10 m, 60.1° at 20 m and 68.8° at the
            // top: ONLY THE FIRST ~8 METRES OF THE SHELF can hold both the walking figure and the
            // whole tree in one frame, and this mark is the start of that stretch — which is also
            // the first metre of shelf a player arriving on the lane actually stands on.
            //
            // AND WHAT THIS FRAME EXPOSES, which the round-runner should read as a finding and not
            // as a composition choice: at the rig's RESTING tilt (16° down, so the frame tops out
            // 11.5° up) the crown clears the top edge by 31.7° from this very mark, and the knoll's
            // own skyline by 5.8°. A player who never touches the right stick cannot see the tree
            // he is being told to approach from anywhere on this shelf — nor the hill it stands on.
            // That is a camera-rig question, not a landform one, and it is owed an answer; this
            // frame is here so it is asked against a picture instead of a hunch.
            //
            // ROUND 11 — THOSE TWO FIGURES READ 27.8° AND 2.0°, AND BOTH WERE TAKEN FROM THE WRONG
            // POINT. The arithmetic was never wrong and it is unchanged: a point on the tree's axis
            // 21.6 m above the plateau, 37.4 m out, does sit 39.5° up (39.5 - 11.5 = 28.0), and the
            // summit point under it does sit 13.8° (2.3). But a silhouette is read at its NEAREST
            // edge, never over the trunk, and everything nearer subtends more:
            //   * THE CROWN. The highest-subtending bough tip is 4.6 m WEST of the axis — local
            //     (-4.60, 21.40, +3.51) in BuildDeadTreeMesh, and west is toward this lens — so
            //     32.7 m out rather than 37.4 m: +43.2°, i.e. 31.7° over the top edge. Critic 5's
            //     clean tree mask measured 31.9° on the shipped round-10 frame; parsing the bough
            //     table predicts 31.7°, which is the two methods agreeing to a quarter of a degree.
            //   * THE HILL. The knoll is a FLAT plateau at y = 50 m inside radius 7 with a
            //     smoothstep cone out to 26 (Landform.cs §6c), so what breaks the sky is the flank
            //     tangent at radius ~8.7 m — 28.7 m out, +17.3°, i.e. 5.8° over the top edge. The
            //     summit point is BEHIND that and 3.5° lower, which is why quoting it under-read
            //     the hill by two thirds. Measured on round10/v9: crest elevation +16.5° from a
            //     bottom-connected ground mask and +17.6° from critic 5's, so 5.0-6.1° over the
            //     edge against the 5.8° predicted.
            // The finding is unchanged and larger than it was written: the hill clears a resting
            // frame by about six degrees, not by two. NOTHING ABOUT THE CAMERA MOVED TO FIX THIS.
            // This is a comment; the pose it describes is the pose round 10 shot, unaltered.
            // OWED ELSEWHERE AND DELIBERATELY NOT TAKEN HERE, because it is arithmetic that chose
            // a MARK, and a mark is a camera decision. The "39.3 + 14.7 = 54.0° against a 55° lens"
            // above carries the same wrong point AND a wrong second term:
            //   * 14.7° is not the rig's head-below-lens angle. It is derived from a drop of
            //     1.41 m, and the rig's own constants give 1.5463 m — CameraPivotHeight + orbit
            //     radius x sin(tilt) over the pivot's ground, minus the head at CameraPivotHeight.
            //     atan(1.5463 / 5.3927) = 16.00°, which it must be to the digit, because the seat
            //     is placed ON the 16° ray from the head: the head is one resting tilt below the
            //     lens by construction, never 14.7.
            //   * with both terms right the sum is 43.2 + 16.0 = 59.1°, and even the over-trunk
            //     point is 39.5 + 16.0 = 55.5°. Neither fits a 55° lens, so the stretch of shelf
            //     that holds the walking figure and the whole tree is not "the first ~8 metres" —
            //     it is empty, at this lens.
            // The shipped frame is unaffected: it aims at ShelfAimLift rather than at the player's
            // head, and the crown lands 2.5° inside its top edge. Nothing here moved the camera.
            // The paragraph that picked this mark needs re-deriving by whoever owns the rig.
            Vantage.ThirdPersonLookingAt(
                    "v9-shelf-west", pivotX: ShelfFootX, pivotZ: ShelfFootZ,
                    targetX: KnollX, targetZ: KnollZ, targetLift: ShelfAimLift)
                .WithStandIn(ShelfWalkX, ShelfWalkZ, yawDegrees: 78f),
        };

        // -------------------------------------------------------------------------------------
        // Entry points
        // -------------------------------------------------------------------------------------

        /// <summary>
        /// Headless entry point (<c>-executeMethod</c>): regenerate the region, open it, pin the PC
        /// quality level, shoot every vantage, then end the session with a CI-style exit code.
        /// </summary>
        public static void CaptureAllBatch()
        {
            int exitCode;
            try
            {
                exitCode = RunBatch();
            }
            catch (Exception e)
            {
                Debug.LogError($"{LogPrefix} Capture run threw: {e}");
                exitCode = ExitPreconditionFailed;
            }

            EditorApplication.Exit(exitCode);
        }

        /// <summary>
        /// Editor entry point: shoots the vantages against the CURRENTLY OPEN scene without
        /// regenerating it, so the director can capture a hand-tweaked state mid-iteration. The
        /// batch path is the one that guarantees round-to-round comparability.
        /// </summary>
        [MenuItem("Tarrock/Gauntlet/Capture All")]
        public static void CaptureAllMenu()
        {
            UnityEngine.SceneManagement.Scene scene = EditorSceneManager.GetActiveScene();
            if (scene.path != ScenePath)
            {
                Debug.LogWarning(
                    $"{LogPrefix} Open scene is '{scene.path}', not {ScenePath}. Shooting it anyway — " +
                    "the vantage coordinates are TerrainProto's, so expect nonsense elsewhere.");
            }

            if (!PinPcQuality())
            {
                return;
            }

            string directory = ResolveOutputDirectory();
            int written = CaptureVantages(directory);
            AssetDatabase.Refresh();
            Debug.Log($"{LogPrefix} {written}/{Vantages.Length} vantage(s) written to {directory}.");
        }

        private static int RunBatch()
        {
            // 1. Regenerate. The generator owns every scene-affecting fact; the rig only looks.
            TerrainRegionGenerator.Generate();

            // 2. Open explicitly rather than trusting whatever the generator left active.
            if (!File.Exists(ScenePath))
            {
                Debug.LogError($"{LogPrefix} {ScenePath} does not exist after regeneration; aborting.");
                return ExitPreconditionFailed;
            }

            UnityEngine.SceneManagement.Scene scene =
                EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
            if (!scene.IsValid())
            {
                Debug.LogError($"{LogPrefix} Could not open {ScenePath}; aborting.");
                return ExitPreconditionFailed;
            }

            // A regenerate that bailed early (e.g. a shader still compiling) leaves a scene with no
            // Terrain in it — catch that here rather than shipping nine photographs of the sky.
            if (UnityEngine.Object.FindAnyObjectByType<Terrain>() == null)
            {
                Debug.LogError(
                    $"{LogPrefix} No Terrain in {ScenePath} after regeneration — the generator most " +
                    "likely aborted (missing/compiling shader). See its log lines above.");
                return ExitPreconditionFailed;
            }

            // 3. Pin quality BEFORE any rendering: MSAA and shadow distance ride on the level.
            if (!PinPcQuality())
            {
                return ExitPreconditionFailed;
            }

            // 4-5. Shoot and write.
            string directory = ResolveOutputDirectory();
            int written = CaptureVantages(directory);
            AssetDatabase.Refresh();

            if (written != Vantages.Length)
            {
                Debug.LogError(
                    $"{LogPrefix} Only {written}/{Vantages.Length} vantage(s) written to {directory}.");
                return ExitCaptureFailed;
            }

            Debug.Log($"{LogPrefix} All {written} vantage(s) written to {directory}.");
            return ExitSuccess;
        }

        // -------------------------------------------------------------------------------------
        // Determinism: quality level, output directory
        // -------------------------------------------------------------------------------------

        private static bool PinPcQuality()
        {
            string[] names = QualitySettings.names;
            for (int i = 0; i < names.Length; i++)
            {
                if (names[i] != PcQualityLevelName)
                {
                    continue;
                }

                QualitySettings.SetQualityLevel(i, applyExpensiveChanges: true);
                Debug.Log(
                    $"{LogPrefix} Quality pinned to '{PcQualityLevelName}' (level {i}): " +
                    $"MSAA {QualitySettings.antiAliasing}×, shadow distance {QualitySettings.shadowDistance} m.");
                return true;
            }

            Debug.LogError(
                $"{LogPrefix} No quality level named '{PcQualityLevelName}' " +
                $"(found: {string.Join(", ", names)}); refusing to shoot at an unknown quality level.");
            return false;
        }

        private static string ResolveOutputDirectory()
        {
            string configured = Environment.GetEnvironmentVariable(OutputDirectoryVariable);
            string directory = string.IsNullOrWhiteSpace(configured) ? DefaultOutputDirectory : configured.Trim();
            Directory.CreateDirectory(directory);
            return directory;
        }

        // -------------------------------------------------------------------------------------
        // The shoot
        // -------------------------------------------------------------------------------------

        private static int CaptureVantages(string directory)
        {
            Camera camera = ResolveMainCamera();
            if (camera == null)
            {
                Debug.LogError(
                    $"{LogPrefix} No camera tagged '{MainCameraTag}' in the scene; nothing to shoot through.");
                return 0;
            }

            Transform standIn = ResolveStandIn();
            if (standIn == null)
            {
                Debug.LogWarning(
                    $"{LogPrefix} No '{PlayerRootName}' in the scene — the scale vantages (v6/v7) will " +
                    "have nothing in them to measure the meadow against.");
            }

            // Everything touched below is restored in the finally: this rig never leaves a mark on
            // the scene, and it never saves one.
            Transform cameraTransform = camera.transform;
            cameraTransform.GetPositionAndRotation(out Vector3 cameraPosition, out Quaternion cameraRotation);
            float previousFieldOfView = camera.fieldOfView;
            RenderTexture previousTarget = camera.targetTexture;

            var brain = camera.GetComponent<CinemachineBrain>();
            bool brainWasEnabled = brain != null && brain.enabled;

            Vector3 standInPosition = standIn != null ? standIn.position : Vector3.zero;
            Quaternion standInRotation = standIn != null ? standIn.rotation : Quaternion.identity;

            List<ParticleSnapshot> particles = SnapshotParticles();
            int written = 0;

            try
            {
                // The Cinemachine brain would drag the camera back onto the vcam the moment it
                // updates; the vantages are absolute, so it stands down for the shoot.
                if (brain != null)
                {
                    brain.enabled = false;
                }

                ForcePostProcessing(camera);
                Shader.SetGlobalFloat(WindStrengthId, CaptureWindStrength);
                SettleParticles(particles);
                Physics.SyncTransforms();
                WarmUpRenderer(camera, standIn, standInPosition, standInRotation);

                foreach (Vantage vantage in Vantages)
                {
                    // ORDER IS LOAD-BEARING: WriteBendGlobals reads standIn.position, which
                    // PlaceStandIn has just set for this vantage. See WriteBendGlobals.
                    PlaceStandIn(standIn, vantage, standInPosition, standInRotation);
                    WriteBendGlobals(standIn);
                    PlaceCamera(camera, vantage);

                    string path = Path.Combine(directory, vantage.Name + ".png");
                    if (TryRender(camera, path))
                    {
                        written++;
                        cameraTransform.GetPositionAndRotation(out Vector3 shotPosition, out Quaternion shotRotation);
                        Debug.Log(
                            $"{LogPrefix} {vantage.Name}: pos {shotPosition.ToString("F2")}, " +
                            $"euler {shotRotation.eulerAngles.ToString("F1")}, fov {camera.fieldOfView:F1} → {path}");
                    }
                }
            }
            finally
            {
                cameraTransform.SetPositionAndRotation(cameraPosition, cameraRotation);
                camera.fieldOfView = previousFieldOfView;
                camera.targetTexture = previousTarget;
                camera.ResetAspect();

                if (brain != null)
                {
                    brain.enabled = brainWasEnabled;
                }

                if (standIn != null)
                {
                    standIn.SetPositionAndRotation(standInPosition, standInRotation);
                }

                RestoreParticles(particles);
                ClearBendGlobals();
                Physics.SyncTransforms();
            }

            return written;
        }

        /// <summary>
        /// Renders the first vantage into a throwaway target and discards it, before the shoot
        /// proper starts.
        ///
        /// THE BUG THIS EXISTS FOR, measured in round 10 and present in every round since round 1:
        /// v1-spawn-west photographs the stand-in Fool as a featureless dark shape, while
        /// v2-spawn-side — the SAME object, the SAME world position, the SAME sun, the same 6.2 m
        /// from a camera orbited about the same pivot — photographs him with the KayKit atlas on:
        /// green hood, brown leathers, boots. It is not lighting and it is not a second object.
        /// Both frames' figures stand the same height on the same scanlines (hood top at y 518 and
        /// y 514 of 1080, ~280 px tall, at identical camera height and range), so it is one model
        /// seen from two bearings. What differs is the ALBEDO, and it differs in a way lighting
        /// cannot produce: in v1 the whole model carries ONE flat colour with no material
        /// boundaries anywhere on it, and that colour's linear chroma (R/G 1.32, B/G 0.77) is the
        /// MEAN OF rogue_texture.png itself (R/G 1.49, B/G 0.75), where v2 and v6 measure R/G
        /// 0.36-0.40 — the actual swatches. A model that samples its whole 1024² atlas as a single
        /// averaged colour is a model drawn before that atlas's mips were resident on the GPU.
        ///
        /// v1 is simply the first frame this rig has ever rendered in the session — and the shoot
        /// runs immediately after PinPcQuality, which is called with applyExpensiveChanges: true.
        /// So the fix is to spend a frame nobody looks at. It costs one 1920×1080 render, touches
        /// no scene state that the loop does not set again a line later, and writes no file.
        ///
        /// IF THE ROUND-10 CAPTURE STILL SHOWS A FLAT FOOL IN v1, this hypothesis is wrong and the
        /// remaining candidate is view-dependent: measure the same chroma test on v1 and v2 again
        /// (round10/builderB/hue1.py). Legitimate mip selection is already ruled out — a 280 px
        /// model on a 1024² atlas resolves mip 0-2, never the 1×1 top.
        /// </summary>
        private static void WarmUpRenderer(
            Camera camera, Transform standIn, Vector3 spawnPosition, Quaternion spawnRotation)
        {
            if (Vantages.Length == 0)
            {
                return;
            }

            Vantage first = Vantages[0];
            PlaceStandIn(standIn, first, spawnPosition, spawnRotation);
            WriteBendGlobals(standIn);
            PlaceCamera(camera, first);

            var descriptor = new RenderTextureDescriptor(CaptureWidth, CaptureHeight)
            {
                colorFormat = RenderTextureFormat.ARGBHalf,
                depthBufferBits = 24,
                msaaSamples = Mathf.Max(1, QualitySettings.antiAliasing),
                sRGB = false,
                useMipMap = false,
                autoGenerateMips = false,
            };

            RenderTexture previousTarget = camera.targetTexture;
            var warmUp = new RenderTexture(descriptor);
            try
            {
                if (!warmUp.Create())
                {
                    Debug.LogWarning(
                        $"{LogPrefix} Could not create the warm-up target; the first vantage may " +
                        "photograph textures that are not resident yet (the flat-Fool bug).");
                    return;
                }

                camera.targetTexture = warmUp;
                for (int pass = 0; pass < WarmUpPasses; pass++)
                {
                    camera.Render();
                }
            }
            finally
            {
                camera.targetTexture = previousTarget;
                warmUp.Release();
                UnityEngine.Object.DestroyImmediate(warmUp);
            }
        }

        /// <summary>
        /// Presses the grass where the stand-in Fool is standing. See the bend-globals block above
        /// for the packing contract.
        ///
        /// ROUND-13 FIX — THE FOOL WAS FLOATING IN UNPRESSED BLADES IN THE OPENING FRAME.
        ///
        /// This method used to early-out on `!vantage.MovesStandIn`, and `MovesStandIn` is true for
        /// exactly three vantages (v6, v7, v9 — the ones with `.WithStandIn(...)`). But
        /// <see cref="PlaceStandIn"/> plants the stand-in for EVERY vantage: on the vantage's own
        /// mark when it moves him, and back on his spawn pose when it does not. He is therefore in
        /// the world, standing on grass, in all nine frames, and VISIBLE in six of them — v1, v2 and
        /// v4 as well as v6, v7 and v9. On v1, v2 and v4 the grass under him was photographed
        /// unpressed, i.e. the frame that opens the game showed a figure standing IN blades rather
        /// than on ground that yields to him. "A bound world still yields to touch" is a standing
        /// director ruling and canon (docs/design/art-audio.md §The world-state is the art
        /// direction), so the frames that contain him must show it.
        ///
        /// The condition is now the only one that was ever load-bearing: is there a stand-in at all.
        /// `MovesStandIn` says where he is put, which is <see cref="PlaceStandIn"/>'s business; it
        /// never said whether he exists, and it was never a statement about which frames contain
        /// him. Deriving the press from `standIn.position` rather than from a second list of
        /// "vantages he appears in" keeps ONE source for the coordinate — the same reason the
        /// round-4 note above gives for reading the position off the transform.
        ///
        /// THE ORDERING INVARIANT IS UNCHANGED and is what makes this correct: both call sites
        /// (the shoot loop and <see cref="WarmUpRenderer"/>) call PlaceStandIn IMMEDIATELY before
        /// this, so `standIn.position` is the resting position for this vantage — the vantage's mark
        /// when it moves him, the spawn pose when it does not — and never a stale or zero one. In
        /// both branches PlaceStandIn puts the transform origin at the feet (mark branch: ground +
        /// StandInGroundClearance; spawn branch: the installer's own grounded spawn), so `feet`
        /// below means the same thing either way. PlaceStandIn also calls Physics.SyncTransforms.
        ///
        /// The three frames he is NOT visible in (v3, v5, v8) now press the grass at the spawn too,
        /// which is where he is standing in those frames. That is correct rather than merely
        /// harmless: it is what GrassBender does in play mode, where the press does not know or care
        /// where the camera is looking, and the pressed disc is off-camera in all three.
        /// </summary>
        private static void WriteBendGlobals(Transform standIn)
        {
            for (int i = 0; i < BenderSlots; i++)
            {
                BenderData[i] = Vector4.zero;
                BenderPower[i] = Vector4.zero;
            }

            if (standIn == null)
            {
                Shader.SetGlobalVectorArray(BenderDataId, BenderData);
                Shader.SetGlobalVectorArray(BenderPowerId, BenderPower);
                Shader.SetGlobalVector(BenderBoundsId, Vector4.zero); // w = 0: nothing touches the grass
                return;
            }

            Vector3 feet = standIn.position;
            Vector3 behind = -standIn.forward;

            // Slot 0 is the body itself at full press; 1 and 2 are the wake, fading as the grass
            // stands back up — the same shape GrassBender publishes for a body that has just walked
            // in and stopped.
            BenderData[0] = new Vector4(feet.x, feet.y, feet.z, StandInBendRadius);
            BenderPower[0] = new Vector4(1f, 0f, 0f, 0f);

            Vector3 wake1 = feet + (behind * WakeSpacing);
            BenderData[1] = new Vector4(wake1.x, wake1.y, wake1.z, StandInBendRadius);
            BenderPower[1] = new Vector4(NearWakePower, 0f, 0f, 0f);

            Vector3 wake2 = feet + (behind * (WakeSpacing * 2f));
            BenderData[2] = new Vector4(wake2.x, wake2.y, wake2.z, StandInBendRadius);
            BenderPower[2] = new Vector4(FarWakePower, 0f, 0f, 0f);

            // One sphere over the three, matching GrassBender's own bounds so the shader's early-out
            // behaves identically to the way it does in play mode.
            Vector3 centre = (feet + wake2) * 0.5f;
            float radius = Vector3.Distance(centre, wake2) + StandInBendRadius;

            Shader.SetGlobalVectorArray(BenderDataId, BenderData);
            Shader.SetGlobalVectorArray(BenderPowerId, BenderPower);
            Shader.SetGlobalVector(BenderBoundsId, new Vector4(centre.x, centre.y, centre.z, radius));
        }

        private static void ClearBendGlobals()
        {
            for (int i = 0; i < BenderSlots; i++)
            {
                BenderData[i] = Vector4.zero;
                BenderPower[i] = Vector4.zero;
            }

            Shader.SetGlobalVectorArray(BenderDataId, BenderData);
            Shader.SetGlobalVectorArray(BenderPowerId, BenderPower);
            Shader.SetGlobalVector(BenderBoundsId, Vector4.zero);
        }

        private static void PlaceCamera(Camera camera, Vantage vantage)
        {
            float anchorGround = SampleGround(vantage.HeightAnchorXz);
            var position = new Vector3(
                vantage.CameraXz.x, anchorGround + vantage.HeightAboveAnchor, vantage.CameraXz.y);

            Quaternion rotation;
            if (vantage.AimsAtTarget)
            {
                var target = new Vector3(
                    vantage.TargetXz.x, SampleGround(vantage.TargetXz) + vantage.TargetLift, vantage.TargetXz.y);
                Vector3 forward = target - position;
                rotation = forward.sqrMagnitude > Mathf.Epsilon
                    ? Quaternion.LookRotation(forward, Vector3.up)
                    : Quaternion.identity;
            }
            else
            {
                rotation = Quaternion.Euler(vantage.PitchDegrees, vantage.YawDegrees, 0f);
            }

            camera.transform.SetPositionAndRotation(position, rotation);
            camera.fieldOfView = vantage.FieldOfView;
            camera.aspect = CaptureAspect;
        }

        // The stand-in Fool is scenery for the scale shots: moved onto the vantage's mark, and put
        // back on its spawn for every other frame (v1/v2 want him exactly where the game starts him).
        //
        // THE `MovesStandIn` TEST BELONGS HERE AND ONLY HERE (round 13). It answers "where does he
        // go for this vantage", which is this method's whole job. It is NOT a test for "is he in
        // this frame" — he is in the world for all nine, which is why WriteBendGlobals no longer
        // consults it. Both branches leave the transform origin at his feet, so anything downstream
        // that reads standIn.position as a ground contact is right either way.
        private static void PlaceStandIn(
            Transform standIn, Vantage vantage, Vector3 spawnPosition, Quaternion spawnRotation)
        {
            if (standIn == null)
            {
                return;
            }

            if (vantage.MovesStandIn)
            {
                var position = new Vector3(
                    vantage.StandInXz.x,
                    SampleGround(vantage.StandInXz) + StandInGroundClearance,
                    vantage.StandInXz.y);
                standIn.SetPositionAndRotation(position, Quaternion.Euler(0f, vantage.StandInYawDegrees, 0f));
            }
            else
            {
                standIn.SetPositionAndRotation(spawnPosition, spawnRotation);
            }

            Physics.SyncTransforms();
        }

        // THE HIGHLIGHT CEILING, and it lived HERE — not in the grade, not in the lamp, not in the
        // landform (round-5 finding 1, and it invalidates the highlight half of every capture from
        // round 1 to round 4).
        //
        // WHAT WAS MEASURED. Across round4/v1, v2 and v8 no pixel in any frame exceeded sRGB8 229
        // in red, 218 in green or 176 in blue; 7.0% of v1 and 13.0% of v8 sat inside the 13 levels
        // below that ceiling; and 0.000% of any frame passed luminance 0.85, where every plate on
        // the reference board reaches 255 in all three channels. A distribution that stops dead at
        // one value is not a shoulder, it is a clamp.
        //
        // WHERE THE CLAMP IS. URP takes the CAMERA TARGET TEXTURE'S OWN FORMAT as the format of the
        // camera colour buffer — the buffer every shader writes into, long before the post chain
        // runs (UniversalRenderPipelineCore.CreateRenderTextureDescriptor, the `else` branch; its
        // own comment calls the behaviour "incorrect" and says the workaround is "simply pick a
        // suitable format for the external texture"). This rig handed it ARGB32 sRGB. So every
        // shader output was sRGB-encoded into 8 bits and CLAMPED AT 1.0 at the moment it was
        // written, and the tonemapper, the bloom prefilter and the grade all ran on a picture whose
        // headroom had already been thrown away. HDR was on in the URP asset and on the camera; it
        // was the render target that was LDR.
        // Modelled end-to-end (the round-3/4 chain: shader → fog → bloom → vignette → LutBuilderHdr
        // → Neutral tonemap), the highest sRGB8 value ANY scene colour can reach through a
        // 1.0-clamped buffer is R 228 / G 218 / B 217 — and the measured maxima are R 229 / G 207 /
        // B 176, i.e. red sits exactly on the clamp's own ceiling in every frame and the other two
        // never get there because the dawn is warm. That is the proof.
        //
        // WHAT THE FIX BUYS, measured by inverting the round-4 captures through the grade, repairing
        // the clipped channel from the channels that survived, and re-rendering unclamped:
        //     max sRGB8      v1 229 → 245    v8 230 → 247    v2 224 → 237
        //     pixels pinned  v1 3.7% → 0     v8 10.0% → 0    v2 1.3% → 0
        //     top-end shape  a wall at 229 → a monotone ramp running out to 250 (v1's 215-255
        //                    histogram goes 87k/72k/24k/0/0/0 → 115k/89k/49k/37k/8k/1.6k)
        // The 3.7% of v1 that was one flat cream value is now the modelled highlight it always was.
        //
        // WHY THE TWO TEXTURES. The camera renders into a LINEAR HALF-FLOAT target, which is what
        // gives the chain its headroom; the graded result it leaves there is display-referred but
        // not yet sRGB-encoded (the hardware only encodes on write to an sRGB surface). The blit
        // into the ARGB32 sRGB texture does exactly that encode, so the readback path below is
        // byte-for-byte the one every previous round used and the frames stay comparable.
        private static bool TryRender(Camera camera, string path)
        {
            // MSAA comes from the pinned quality level; both targets carry it so URP resolves the
            // same edges the game view would.
            int msaa = Mathf.Max(1, QualitySettings.antiAliasing);
            var sceneDescriptor = new RenderTextureDescriptor(CaptureWidth, CaptureHeight)
            {
                colorFormat = RenderTextureFormat.ARGBHalf,
                depthBufferBits = 24,
                msaaSamples = msaa,
                sRGB = false,
                useMipMap = false,
                autoGenerateMips = false,
            };
            var displayDescriptor = new RenderTextureDescriptor(CaptureWidth, CaptureHeight)
            {
                colorFormat = RenderTextureFormat.ARGB32,
                depthBufferBits = 0,
                msaaSamples = 1,
                sRGB = true,
                useMipMap = false,
                autoGenerateMips = false,
            };

            if (!SystemInfo.SupportsRenderTextureFormat(RenderTextureFormat.ARGBHalf))
            {
                // Never silently: an LDR capture is exactly the bug this method exists to document,
                // so if the box cannot do half-float the round must know its highlights are fiction.
                Debug.LogWarning(
                    $"{LogPrefix} ARGBHalf render targets are unsupported on this device; falling " +
                    "back to an LDR capture. Every value over 1.0 linear will be clamped and the " +
                    "frame's highlights will be unreadable — see the ceiling note above.");
                sceneDescriptor.colorFormat = RenderTextureFormat.ARGB32;
                sceneDescriptor.sRGB = true;
            }

            var sceneTexture = new RenderTexture(sceneDescriptor);
            var displayTexture = new RenderTexture(displayDescriptor);
            var readback = new Texture2D(CaptureWidth, CaptureHeight, TextureFormat.RGB24, mipChain: false);
            RenderTexture previousActive = RenderTexture.active;
            bool previousSrgbWrite = GL.sRGBWrite;

            try
            {
                if (!sceneTexture.Create() || !displayTexture.Create())
                {
                    Debug.LogError(
                        $"{LogPrefix} Could not create a {CaptureWidth}×{CaptureHeight} render target " +
                        "(is the editor running with -nographics? this rig needs a graphics device).");
                    return false;
                }

                camera.targetTexture = sceneTexture;
                camera.Render();

                // The encode. Explicit rather than ambient: GL.sRGBWrite is editor state, and if it
                // is off the blit copies the linear values through unconverted and the PNG comes out
                // two stops dark.
                GL.sRGBWrite = true;
                Graphics.Blit(sceneTexture, displayTexture);

                RenderTexture.active = displayTexture;
                readback.ReadPixels(new Rect(0f, 0f, CaptureWidth, CaptureHeight), 0, 0, recalculateMipMaps: false);
                readback.Apply(updateMipmaps: false);

                File.WriteAllBytes(path, readback.EncodeToPNG());
                return true;
            }
            catch (Exception e)
            {
                Debug.LogError($"{LogPrefix} Rendering {path} failed: {e}");
                return false;
            }
            finally
            {
                GL.sRGBWrite = previousSrgbWrite;
                RenderTexture.active = previousActive;
                camera.targetTexture = null;
                UnityEngine.Object.DestroyImmediate(readback);
                displayTexture.Release();
                UnityEngine.Object.DestroyImmediate(displayTexture);
                sceneTexture.Release();
                UnityEngine.Object.DestroyImmediate(sceneTexture);
            }
        }

        // -------------------------------------------------------------------------------------
        // Scene lookups and per-shot state
        // -------------------------------------------------------------------------------------

        private static Camera ResolveMainCamera()
        {
            if (Camera.main != null)
            {
                return Camera.main;
            }

            Camera[] cameras = UnityEngine.Object.FindObjectsByType<Camera>(FindObjectsSortMode.None);
            return cameras.Length > 0 ? cameras[0] : null;
        }

        private static Transform ResolveStandIn()
        {
            GameObject rig = GameObject.Find(PlayerRootName);
            return rig != null ? rig.transform : null;
        }

        /// <summary>Ground height in metres at a world XZ — the terrain first, a downward raycast as
        /// the fallback so the rig still works if a vantage ever sits on non-terrain ground.</summary>
        private static float SampleGround(Vector2 xz)
        {
            Terrain terrain = Terrain.activeTerrain;
            if (terrain != null)
            {
                var probe = new Vector3(xz.x, 0f, xz.y);
                return terrain.SampleHeight(probe) + terrain.transform.position.y;
            }

            var origin = new Vector3(xz.x, GroundProbeHeight, xz.y);
            if (Physics.Raycast(origin, Vector3.down, out RaycastHit hit, GroundProbeLength))
            {
                return hit.point.y;
            }

            Debug.LogWarning($"{LogPrefix} No ground found at ({xz.x}, {xz.y}); treating it as y=0.");
            return 0f;
        }

        // The grade is not optional: without post-processing the frame is raw untonemapped shader
        // output, which is a different image from the one the game shows (the 2026-07-26 audit).
        private static void ForcePostProcessing(Camera camera)
        {
            var data = camera.GetComponent<UniversalAdditionalCameraData>();
            if (data == null)
            {
                Debug.LogWarning(
                    $"{LogPrefix} Main Camera has no URP camera data; post-processing cannot be forced " +
                    "on and the captures may be untonemapped.");
                return;
            }

            data.renderPostProcessing = true;
        }

        private static List<ParticleSnapshot> SnapshotParticles()
        {
            var snapshots = new List<ParticleSnapshot>();
            foreach (ParticleSystem system in
                     UnityEngine.Object.FindObjectsByType<ParticleSystem>(FindObjectsSortMode.None))
            {
                snapshots.Add(new ParticleSnapshot(system));
            }

            return snapshots;
        }

        private static void SettleParticles(List<ParticleSnapshot> snapshots)
        {
            foreach (ParticleSnapshot snapshot in snapshots)
            {
                snapshot.SettleTo(ParticleSeed, ParticleSettleSeconds);
            }
        }

        private static void RestoreParticles(List<ParticleSnapshot> snapshots)
        {
            foreach (ParticleSnapshot snapshot in snapshots)
            {
                snapshot.Restore();
            }
        }

        /// <summary>
        /// A particle system's seeding state, so the motes can be driven to a fixed, repeatable
        /// arrangement for the shoot and handed back untouched afterwards.
        /// </summary>
        private sealed class ParticleSnapshot
        {
            private readonly ParticleSystem _system;
            private readonly bool _useAutoRandomSeed;
            private readonly uint _randomSeed;

            public ParticleSnapshot(ParticleSystem system)
            {
                _system = system;
                _useAutoRandomSeed = system.useAutoRandomSeed;
                _randomSeed = system.randomSeed;
            }

            public void SettleTo(uint seed, float seconds)
            {
                if (_system == null)
                {
                    return;
                }

                _system.useAutoRandomSeed = false;
                _system.randomSeed = seed;
                _system.Simulate(seconds, withChildren: true, restart: true, fixedTimeStep: true);
            }

            public void Restore()
            {
                if (_system == null)
                {
                    return;
                }

                _system.randomSeed = _randomSeed;
                _system.useAutoRandomSeed = _useAutoRandomSeed;
            }
        }

        /// <summary>
        /// One named review frame. Positions are world XZ with heights resolved against the terrain
        /// at capture time, so a vantage survives a landform edit that moves the ground under it —
        /// the pair of coordinates is the intent ("at the spawn", "on the knoll"), not the altitude.
        /// </summary>
        private sealed class Vantage
        {
            private Vantage(
                string name,
                Vector2 cameraXz,
                Vector2 heightAnchorXz,
                float heightAboveAnchor,
                bool aimsAtTarget,
                Vector2 targetXz,
                float targetLift,
                float yawDegrees,
                float pitchDegrees,
                float fieldOfView,
                bool movesStandIn,
                Vector2 standInXz,
                float standInYawDegrees)
            {
                Name = name;
                CameraXz = cameraXz;
                HeightAnchorXz = heightAnchorXz;
                HeightAboveAnchor = heightAboveAnchor;
                AimsAtTarget = aimsAtTarget;
                TargetXz = targetXz;
                TargetLift = targetLift;
                YawDegrees = yawDegrees;
                PitchDegrees = pitchDegrees;
                FieldOfView = fieldOfView;
                MovesStandIn = movesStandIn;
                StandInXz = standInXz;
                StandInYawDegrees = standInYawDegrees;
            }

            /// <summary>File stem of the PNG, and the name the round is discussed by.</summary>
            public string Name { get; }

            public Vector2 CameraXz { get; }

            /// <summary>Where the ground is sampled for the camera's height — the same XZ for a
            /// free-standing vantage, but the PIVOT for a third-person one, so an orbit camera that
            /// swings over rising ground keeps its framing instead of climbing.</summary>
            public Vector2 HeightAnchorXz { get; }

            public float HeightAboveAnchor { get; }

            public bool AimsAtTarget { get; }

            public Vector2 TargetXz { get; }

            /// <summary>Metres above the ground at <see cref="TargetXz"/> that the camera aims at.</summary>
            public float TargetLift { get; }

            public float YawDegrees { get; }

            public float PitchDegrees { get; }

            public float FieldOfView { get; }

            public bool MovesStandIn { get; }

            public Vector2 StandInXz { get; }

            public float StandInYawDegrees { get; }

            /// <summary>A free-standing vantage aimed by compass yaw and pitch — for shots whose
            /// subject is the sky or the void (there is nothing to look AT over a cloud deck).</summary>
            public static Vantage Facing(
                string name, float cameraX, float cameraZ, float eyeHeight,
                float yawDegrees, float pitchDegrees, float fieldOfView = GameplayFieldOfView)
            {
                var cameraXz = new Vector2(cameraX, cameraZ);
                return new Vantage(
                    name, cameraXz, cameraXz, eyeHeight,
                    aimsAtTarget: false, targetXz: Vector2.zero, targetLift: 0f,
                    yawDegrees, pitchDegrees, fieldOfView,
                    movesStandIn: false, standInXz: Vector2.zero, standInYawDegrees: 0f);
            }

            /// <summary>A vantage aimed at a world point, given as XZ plus a lift above the ground
            /// there. Aiming at ground-relative points keeps the composition when the landform moves.</summary>
            public static Vantage LookingAt(
                string name, float cameraX, float cameraZ, float eyeHeight,
                float targetX, float targetZ, float targetLift,
                float fieldOfView = GameplayFieldOfView)
            {
                var cameraXz = new Vector2(cameraX, cameraZ);
                return new Vantage(
                    name, cameraXz, cameraXz, eyeHeight,
                    aimsAtTarget: true, targetXz: new Vector2(targetX, targetZ), targetLift,
                    yawDegrees: 0f, pitchDegrees: 0f, fieldOfView,
                    movesStandIn: false, standInXz: Vector2.zero, standInYawDegrees: 0f);
            }

            /// <summary>
            /// A gameplay vantage: the orbit camera seated behind a pivot on the ground, at the rig's
            /// radius and resting tilt, looking down the given yaw. This is what the player sees, so
            /// these are the frames that decide whether the game looks good — not the pretty flyovers.
            /// </summary>
            public static Vantage ThirdPerson(
                string name, float pivotX, float pivotZ, float yawDegrees,
                float fieldOfView = GameplayFieldOfView)
            {
                float yawRadians = yawDegrees * Mathf.Deg2Rad;
                var forward = new Vector2(Mathf.Sin(yawRadians), Mathf.Cos(yawRadians));
                var pivotXz = new Vector2(pivotX, pivotZ);

                float tiltRadians = CameraTiltDegrees * Mathf.Deg2Rad;
                Vector2 cameraXz = pivotXz - (forward * (CameraOrbitRadius * Mathf.Cos(tiltRadians)));
                float height = CameraPivotHeight + (CameraOrbitRadius * Mathf.Sin(tiltRadians));

                return new Vantage(
                    name, cameraXz, pivotXz, height,
                    aimsAtTarget: true, targetXz: pivotXz, targetLift: CameraPivotHeight,
                    yawDegrees, pitchDegrees: CameraTiltDegrees, fieldOfView,
                    movesStandIn: false, standInXz: Vector2.zero, standInYawDegrees: 0f);
            }

            /// <summary>
            /// The gameplay rig's SEAT, with the lens free to aim. Same geometry as
            /// <see cref="ThirdPerson"/> — the camera sits <c>CameraOrbitRadius·cos(tilt)</c> behind
            /// the pivot at <c>CameraPivotHeight + CameraOrbitRadius·sin(tilt)</c> above the PIVOT'S
            /// ground, and the player faces what he is looking at, so the yaw is derived from the
            /// target rather than typed — but it aims at a world point instead of at the player's
            /// own head. That is not a cheat: 16° is the orbit camera's RESTING tilt, not a stop,
            /// and a player looking up at a landmark is holding the stick. Anchoring the height at
            /// the pivot (not at the camera's own XZ) is what keeps the framing when the shot stands
            /// on a slope, which is the whole reason ThirdPerson does it.
            /// </summary>
            public static Vantage ThirdPersonLookingAt(
                string name, float pivotX, float pivotZ, float targetX, float targetZ, float targetLift,
                float fieldOfView = GameplayFieldOfView)
            {
                var pivotXz = new Vector2(pivotX, pivotZ);
                var targetXz = new Vector2(targetX, targetZ);
                Vector2 toTarget = targetXz - pivotXz;
                float yawDegrees = Mathf.Atan2(toTarget.x, toTarget.y) * Mathf.Rad2Deg;
                float yawRadians = yawDegrees * Mathf.Deg2Rad;
                var forward = new Vector2(Mathf.Sin(yawRadians), Mathf.Cos(yawRadians));

                float tiltRadians = CameraTiltDegrees * Mathf.Deg2Rad;
                Vector2 cameraXz = pivotXz - (forward * (CameraOrbitRadius * Mathf.Cos(tiltRadians)));
                float height = CameraPivotHeight + (CameraOrbitRadius * Mathf.Sin(tiltRadians));

                return new Vantage(
                    name, cameraXz, pivotXz, height,
                    aimsAtTarget: true, targetXz, targetLift,
                    yawDegrees, pitchDegrees: 0f, fieldOfView,
                    movesStandIn: false, standInXz: Vector2.zero, standInYawDegrees: 0f);
            }

            /// <summary>Copy of this vantage that also plants the stand-in Fool on a mark — the scale
            /// reference for the meadow shots.</summary>
            public Vantage WithStandIn(float standInX, float standInZ, float yawDegrees)
            {
                return new Vantage(
                    Name, CameraXz, HeightAnchorXz, HeightAboveAnchor,
                    AimsAtTarget, TargetXz, TargetLift,
                    YawDegrees, PitchDegrees, FieldOfView,
                    movesStandIn: true, standInXz: new Vector2(standInX, standInZ), standInYawDegrees: yawDegrees);
            }
        }
    }
}
