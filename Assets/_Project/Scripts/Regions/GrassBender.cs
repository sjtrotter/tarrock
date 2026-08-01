namespace Tarrock.Regions
{

    using System.Collections.Generic;
    using UnityEngine;

    /// <summary>
    /// Pushes the grass aside around a moving body. Put one on the Fool's rig and one on Pip; the
    /// meadow bends away from them as they walk through it and settles back behind them.
    ///
    /// <para>WHY THIS EXISTS. A bound region holds its breath (art-audio.md §The world-state is the
    /// art direction) — <see cref="RegionWind"/> rests at 0 and <c>Tarrock/GrassTuft</c> therefore
    /// has NO ambient motion at all: the "wind-combed" meadow is a static POSE, the shape the last
    /// wind left. Dead-still grass that a character walks through without touching reads as
    /// painted-on scenery, so the director's ruling (2026-07-31) is that the world still yields to
    /// TOUCH while it is bound: the stasis is the world's, not the Fool's. This component is that
    /// exception, and the only motion the Cliff's meadow has.</para>
    ///
    /// <para>HOW. Every bender publishes a small set of "benders" — a world position, a radius and a
    /// strength — into the shader globals <c>_TarrockBenderData</c> / <c>_TarrockBenderPower</c>,
    /// which <c>Tarrock/GrassTuft</c> reads in its vertex stage and turns into a radial push away
    /// from each centre — outward, and HELD: a live bender's power does not decay, so grass you are
    /// standing in stays laid over for as long as you stand in it. That is what makes the ring
    /// legible in a still frame and not only in motion (gauntlet round 2, v6: the ring was not
    /// findable at all). One live bender sits under the body itself, and behind a moving body the
    /// component drops a short TRAIL of fading benders, one every <see cref="_trailSpacing"/> metres.
    /// The trail is the settle: a wake that closes over <see cref="_settleSeconds"/> once the body
    /// has passed. There is no per-blade state anywhere — a vertex shader has no memory, so the
    /// memory lives here, in a handful of decaying points.</para>
    ///
    /// <para>ONE WRITER PER FRAME. Every bender in the scene shares one fixed-size global array, so
    /// the first one to reach <c>LateUpdate</c> in a frame ticks and publishes for ALL of them (see
    /// <see cref="TickAll"/>). That is deliberate: it removes any dependence on script execution
    /// order, which is the usual way a system like this ends up a frame stale for some movers and
    /// not others. Slots are handed out live-benders-first, so with more movers than slots the
    /// bodies keep their bend and only the wakes are dropped.</para>
    /// </summary>
    [DisallowMultipleComponent]
    public sealed class GrassBender : MonoBehaviour
    {
        // Shader-side array length. MUST match the array size declared in Tarrock/GrassTuft — the
        // shader loops the whole array unconditionally and reads slot strength to decide what is
        // live, so a mismatch either reads garbage or silently ignores the tail.
        private const int MaxSlots = 8;

        // Trail points a single bender may leave behind. Two movers (the Fool and Pip) at three
        // trail points each plus their two live benders is exactly MaxSlots.
        private const int MaxTrailPerBender = 3;

        private const string BenderDataProperty = "_TarrockBenderData";
        private const string BenderPowerProperty = "_TarrockBenderPower";
        private const string BenderBoundsProperty = "_TarrockBenderBounds";

        private static readonly int BenderDataId = Shader.PropertyToID(BenderDataProperty);
        private static readonly int BenderPowerId = Shader.PropertyToID(BenderPowerProperty);
        private static readonly int BenderBoundsId = Shader.PropertyToID(BenderBoundsProperty);

        private static readonly List<GrassBender> Active = new List<GrassBender>(4);

        // Reused every frame — a per-frame allocation here would be one per frame forever.
        private static readonly Vector4[] SlotData = new Vector4[MaxSlots];
        private static readonly Vector4[] SlotPower = new Vector4[MaxSlots];

        private static int _lastWriteFrame = -1;
        private static bool _globalsWritten;

        // ROUND 5 — WHY THIS IS STILL 0.72 WHEN THE RING WAS ASKED TO GET TIGHTER.
        //
        // The gauntlet's round-4 finding is that the ring reads 1.5-1.8x shoulder width and wants to
        // be nearer 1.2x, and that is right: it measured 1.86x. But the number that sets the width
        // of the CLEARING is not this radius, it is Tarrock/GrassTuft's _BendCoreShare — the share
        // of the radius held fully laid over before the rim falls off. At round 4's 0.58 the held
        // floor was 0.418 m in radius, 0.835 m across against a 0.45 m shoulder; at round 5's 0.375
        // it is 0.270 m, 0.540 m across, exactly 1.20x shoulder. The tightening happens there.
        //
        // Moving THIS number instead would have cost the round its own evidence. GauntletCapture's
        // StandInBendRadius is a const 0.72 f, that file is not ours to edit, and the game's ring
        // and the photographed ring must be one ring — a capture of a 0.54 m bend proving a 0.72 m
        // bend correct is not proof of anything. Tightening via the core share moves the picture
        // without desyncing the evidence, which is why it is the lever round 5 pulls.
        [Header("Bend")]
        [Tooltip("Metres from the body at which the grass is untouched. Roughly the body's own " +
                 "footprint plus the length of a blade it can lean on. Tarrock/GrassTuft holds " +
                 "the inner share of this fully laid over and spends the falloff on the rim, so a " +
                 "SMALLER radius reads as a stronger ring, not a weaker one — but the width of the " +
                 "clearing is set by that shader's _BendCoreShare, not by this. Must stay in step " +
                 "with GauntletCapture.StandInBendRadius.")]
        [SerializeField] private float _radius = 0.72f;

        [Tooltip("How hard this body pushes, 0-1. Scales the shader's own bend strength, so this " +
                 "is 'Pip presses less than the Fool', not the absolute amount of lean.")]
        [Range(0f, 1f)]
        [SerializeField] private float _strength = 1f;

        [Tooltip("Metres above the transform's origin that the bend centre sits. Zero for a rig " +
                 "whose origin is already between the feet.")]
        [SerializeField] private float _centreHeight = 0f;

        [Header("Wake")]
        [Tooltip("Metres of travel between trail points. Smaller lays a denser, smoother wake and " +
                 "uses up the shared slots faster.")]
        [SerializeField] private float _trailSpacing = 0.5f;

        [Tooltip("Seconds a trail point takes to fade out — the time the grass takes to stand back " +
                 "up once the body has passed.")]
        [SerializeField] private float _settleSeconds = 1.1f;

        private readonly TrailPoint[] _trail = new TrailPoint[MaxTrailPerBender];

        private int _trailCount;
        private Vector3 _lastDropPosition;

        private void OnEnable()
        {
            _trailCount = 0;
            _lastDropPosition = transform.position;

            if (!Active.Contains(this))
            {
                Active.Add(this);
            }
        }

        private void OnDisable()
        {
            Active.Remove(this);

            // The last bender out clears the field. Without this the meadow would keep a bend ring
            // around wherever the Fool was standing when he was disabled or the scene unloaded.
            if (Active.Count == 0 && _globalsWritten)
            {
                ClearGlobals();
            }
        }

        private void LateUpdate()
        {
            // Whoever gets here first this frame does the work for everyone — see the class doc.
            if (_lastWriteFrame == Time.frameCount)
            {
                return;
            }

            _lastWriteFrame = Time.frameCount;
            TickAll(Time.deltaTime);
        }

        private static void TickAll(float deltaTime)
        {
            for (int i = 0; i < Active.Count; i++)
            {
                Active[i].Advance(deltaTime);
            }

            int slot = 0;

            // Live benders first: a body always keeps its own bend, even in a crowd that has run
            // the shared array out of room.
            for (int i = 0; i < Active.Count && slot < MaxSlots; i++)
            {
                GrassBender bender = Active[i];
                Vector3 centre = bender.transform.position + (Vector3.up * bender._centreHeight);
                SlotData[slot] = new Vector4(centre.x, centre.y, centre.z, Mathf.Max(bender._radius, 0.01f));
                SlotPower[slot] = new Vector4(Mathf.Clamp01(bender._strength), 0f, 0f, 0f);
                slot++;
            }

            // Then the wakes, freshest rank first and round-robin across bodies, so two movers share
            // what is left evenly instead of one of them swallowing the whole array.
            for (int rank = 0; rank < MaxTrailPerBender && slot < MaxSlots; rank++)
            {
                for (int i = 0; i < Active.Count && slot < MaxSlots; i++)
                {
                    GrassBender bender = Active[i];
                    if (rank >= bender._trailCount)
                    {
                        continue;
                    }

                    TrailPoint point = bender._trail[rank];
                    SlotData[slot] = new Vector4(
                        point.Position.x, point.Position.y, point.Position.z, Mathf.Max(bender._radius, 0.01f));
                    SlotPower[slot] = new Vector4(Mathf.Clamp01(bender._strength) * point.Power, 0f, 0f, 0f);
                    slot++;
                }
            }

            // A zero radius makes the shader's radial falloff evaluate to nothing, so empty slots
            // cost a few instructions and change no pixel.
            for (int i = slot; i < MaxSlots; i++)
            {
                SlotData[i] = Vector4.zero;
                SlotPower[i] = Vector4.zero;
            }

            Shader.SetGlobalVectorArray(BenderDataId, SlotData);
            Shader.SetGlobalVectorArray(BenderPowerId, SlotPower);
            Shader.SetGlobalVector(BenderBoundsId, ComputeBounds(slot));
            _globalsWritten = true;
        }

        /// <summary>
        /// One sphere enclosing every live bender, so the shader can reject the whole meadow with a
        /// single distance test instead of looping the array for every blade of grass on the region.
        /// A zero radius (no benders) rejects everywhere, which is what a scene with no movers wants.
        /// </summary>
        private static Vector4 ComputeBounds(int usedSlots)
        {
            if (usedSlots <= 0)
            {
                return Vector4.zero;
            }

            var centre = Vector3.zero;
            for (int i = 0; i < usedSlots; i++)
            {
                centre += new Vector3(SlotData[i].x, SlotData[i].y, SlotData[i].z);
            }

            centre /= usedSlots;

            float radius = 0f;
            for (int i = 0; i < usedSlots; i++)
            {
                var position = new Vector3(SlotData[i].x, SlotData[i].y, SlotData[i].z);
                radius = Mathf.Max(radius, Vector3.Distance(centre, position) + SlotData[i].w);
            }

            return new Vector4(centre.x, centre.y, centre.z, radius);
        }

        private static void ClearGlobals()
        {
            for (int i = 0; i < MaxSlots; i++)
            {
                SlotData[i] = Vector4.zero;
                SlotPower[i] = Vector4.zero;
            }

            Shader.SetGlobalVectorArray(BenderDataId, SlotData);
            Shader.SetGlobalVectorArray(BenderPowerId, SlotPower);
            Shader.SetGlobalVector(BenderBoundsId, Vector4.zero);
            _globalsWritten = false;
        }

        private void Advance(float deltaTime)
        {
            AgeTrail(deltaTime);

            Vector3 position = transform.position + (Vector3.up * _centreHeight);
            Vector3 travel = position - _lastDropPosition;
            travel.y = 0f;

            float spacing = Mathf.Max(_trailSpacing, 0.05f);
            if (travel.sqrMagnitude < spacing * spacing)
            {
                return;
            }

            // Drop the wake point where the body WAS, not where it is: the live bender already owns
            // the ground underfoot, and a trail point laid on top of it would only double the push.
            DropTrailPoint(_lastDropPosition);
            _lastDropPosition = position;
        }

        private void AgeTrail(float deltaTime)
        {
            float settle = Mathf.Max(_settleSeconds, 0.01f);

            int kept = 0;
            for (int i = 0; i < _trailCount; i++)
            {
                TrailPoint point = _trail[i];
                point.Age += deltaTime;
                if (point.Age >= settle)
                {
                    continue;
                }

                // Ease-out: the grass releases quickly at first and creeps back over the last of it,
                // which is how a trodden tuft actually recovers — and it stops the wake ending on a
                // visible pop.
                float remaining = 1f - (point.Age / settle);
                point.Power = remaining * remaining;
                _trail[kept] = point;
                kept++;
            }

            _trailCount = kept;
        }

        private void DropTrailPoint(Vector3 position)
        {
            // Newest first: rank 0 is always the freshest point, which is the order TickAll hands
            // out the shared slots in.
            int shifted = Mathf.Min(_trailCount, MaxTrailPerBender - 1);
            for (int i = shifted; i > 0; i--)
            {
                _trail[i] = _trail[i - 1];
            }

            _trail[0] = new TrailPoint { Position = position, Age = 0f, Power = 1f };
            _trailCount = Mathf.Min(_trailCount + 1, MaxTrailPerBender);
        }

        /// <summary>One fading point of a body's wake: where it pressed, and how much of that press
        /// the grass has not yet stood back up out of.</summary>
        private struct TrailPoint
        {
            public Vector3 Position;
            public float Age;
            public float Power;
        }
    }
}
