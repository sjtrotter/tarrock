namespace Tarrock.Player
{

    using UnityEngine;

    /// <summary>
    /// The Fool's stylized footfall dust — the project's first VFX pass, kept deliberately minimal to
    /// sit inside the diorama (art-audio.md): small, soft, warm pale-gold puffs, no smoke plumes. It
    /// owns two child <see cref="ParticleSystem"/>s built at runtime, both driven by burst
    /// <see cref="ParticleSystem.Emit(ParticleSystem.EmitParams,int)"/> calls at the rig's feet:
    ///
    /// - a small <b>foot puff</b> — kicked up on a dodge's start and end (<see cref="PlayerDodge"/>)
    ///   and on every landing (<see cref="PlayerMotor"/>), the landing puff scaled by airtime;
    /// - a big <b>dust ring</b> — the grand backflip's emphatic finish (<see cref="EmitGrandRing"/>).
    ///
    /// The soft round sprite reuses the CliffHexGenerator MoteDot approach (a radial-alpha dot); the
    /// material is alpha-blended (dust settles, it does not glow like the suspended motes). A serialized
    /// material is preferred (the installer wires the persisted DustMaterial asset); if none is set the
    /// component generates an equivalent texture + material at runtime so it is always self-sufficient.
    /// Purely cosmetic — it never touches gameplay state or the <see cref="CharacterController"/>.
    /// </summary>
    public sealed class PlayerDustPuffs : MonoBehaviour
    {
        [SerializeField] private Material _dustMaterial;

        [Header("Dust tint (warm pale-gold — reads against the meadow, stays in palette)")]
        [SerializeField] private Color _dustColor = new Color(0.94f, 0.87f, 0.68f, 0.85f);

        [Header("Foot puff (dodge start/end + landings)")]
        [Tooltip("Base particle count for a foot puff; landing puffs scale this by airtime.")]
        [SerializeField] private int _puffCount = 10;
        [SerializeField] private float _puffSize = 0.13f;
        [SerializeField] private float _puffLifetime = 0.5f;
        [SerializeField] private float _puffSpeed = 0.35f;

        [Header("Landing scale (a longer fall lands harder)")]
        [Tooltip("Airtime (seconds) at which a landing puff reaches its full size.")]
        [SerializeField] private float _landFallTimeForFull = 0.6f;
        [SerializeField] private float _landMinScale = 0.7f;
        [SerializeField] private float _landMaxScale = 1.7f;

        [Header("Grand backflip ring")]
        [SerializeField] private int _ringCount = 46;
        [SerializeField] private float _ringSize = 0.2f;
        [SerializeField] private float _ringLifetime = 0.75f;
        [SerializeField] private float _ringSpeed = 1.5f;

        [Tooltip("Height above the rig origin (the feet) at which puffs spawn.")]
        [SerializeField] private float _emitHeight = 0.02f;

        private ParticleSystem _puff;
        private ParticleSystem _ring;

        /// <summary>A small puff at the feet, scaled about 1 (a dodge commit or its plant).</summary>
        public void EmitFootPuff(float scale)
        {
            float s = Mathf.Clamp(scale, 0.2f, 2.5f);
            EmitBurst(_puff, Mathf.Max(1, Mathf.RoundToInt(_puffCount * s)), _puffSize * s);
        }

        /// <summary>A landing puff whose size grows with how long the Fool was airborne.</summary>
        public void EmitLandPuff(float fallTime)
        {
            float t = _landFallTimeForFull > 0.001f ? Mathf.Clamp01(fallTime / _landFallTimeForFull) : 1f;
            float scale = Mathf.Lerp(_landMinScale, _landMaxScale, t);
            EmitBurst(_puff, Mathf.Max(1, Mathf.RoundToInt(_puffCount * scale)), _puffSize * scale);
        }

        /// <summary>The grand backflip's emphatic finish: a big outward dust ring plus a central kick.</summary>
        public void EmitGrandRing()
        {
            EmitBurst(_ring, _ringCount, _ringSize);
            EmitBurst(_puff, Mathf.RoundToInt(_puffCount * 1.3f), _puffSize * 1.3f);
        }

        private void Awake()
        {
            Material mat = _dustMaterial != null ? _dustMaterial : BuildRuntimeDustMaterial();
            _puff = BuildPuffSystem(mat);
            _ring = BuildRingSystem(mat);
        }

        private void EmitBurst(ParticleSystem system, int count, float size)
        {
            if (system == null)
            {
                return;
            }

            var emitParams = new ParticleSystem.EmitParams
            {
                position = transform.position + (Vector3.up * _emitHeight),
                applyShapeToPosition = true,
                startSize = size,
            };
            system.Emit(emitParams, count);
        }

        // The small ground puff: a soft hemisphere of dust kicked up and settling under a little
        // gravity, growing and fading over its short life.
        private ParticleSystem BuildPuffSystem(Material material)
        {
            ParticleSystem ps = CreateChildSystem("DustPuff_Foot", material);

            ParticleSystem.MainModule main = ps.main;
            main.startLifetime = _puffLifetime;
            main.startSpeed = new ParticleSystem.MinMaxCurve(_puffSpeed * 0.35f, _puffSpeed);
            main.startSize = _puffSize;
            main.startColor = _dustColor;
            main.gravityModifier = 0.04f; // settle slightly after the kick
            main.maxParticles = 160;

            ParticleSystem.ShapeModule shape = ps.shape;
            shape.enabled = true;
            shape.shapeType = ParticleSystemShapeType.Hemisphere;
            shape.radius = 0.04f;

            return ps;
        }

        // The grand-backflip ring: a flat circle of dust bursting outward along the ground, expanding
        // then dissipating. The circle is laid horizontal so the radial velocities sweep outward.
        private ParticleSystem BuildRingSystem(Material material)
        {
            ParticleSystem ps = CreateChildSystem("DustPuff_Ring", material);

            ParticleSystem.MainModule main = ps.main;
            main.startLifetime = _ringLifetime;
            main.startSpeed = new ParticleSystem.MinMaxCurve(_ringSpeed * 0.7f, _ringSpeed);
            main.startSize = _ringSize;
            main.startColor = _dustColor;
            main.gravityModifier = 0.015f;
            main.maxParticles = 120;

            ParticleSystem.ShapeModule shape = ps.shape;
            shape.enabled = true;
            shape.shapeType = ParticleSystemShapeType.Circle;
            shape.radius = 0.05f;
            shape.arc = 360f;
            shape.radiusThickness = 1f;
            shape.rotation = new Vector3(90f, 0f, 0f); // lay the circle flat so it rings outward on the ground
            shape.randomDirectionAmount = 0.12f;        // a touch of loft so it is not razor-flat

            // Expand fast then ease so the ring blooms and settles rather than flying off.
            ParticleSystem.LimitVelocityOverLifetimeModule limit = ps.limitVelocityOverLifetime;
            limit.enabled = true;
            limit.dampen = 0.35f;
            limit.limit = new ParticleSystem.MinMaxCurve(_ringSpeed * 0.5f);

            return ps;
        }

        private ParticleSystem CreateChildSystem(string systemName, Material material)
        {
            var go = new GameObject(systemName);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = Vector3.zero;

            var ps = go.AddComponent<ParticleSystem>();
            ps.Stop(true, ParticleSystemStopBehavior.StopEmittingAndClear);

            ParticleSystem.MainModule main = ps.main;
            main.loop = false;
            main.playOnAwake = false;
            main.simulationSpace = ParticleSystemSimulationSpace.World; // puffs stay where they were kicked up

            ParticleSystem.EmissionModule emission = ps.emission;
            emission.enabled = true;
            emission.rateOverTime = 0f; // bursts only, driven by Emit()

            // Grow a little as it dissipates.
            ParticleSystem.SizeOverLifetimeModule size = ps.sizeOverLifetime;
            size.enabled = true;
            size.size = new ParticleSystem.MinMaxCurve(
                1f, new AnimationCurve(new Keyframe(0f, 0.7f), new Keyframe(0.35f, 1f), new Keyframe(1f, 1.25f)));

            // Hold the tint, then fade the alpha out over the life.
            ParticleSystem.ColorOverLifetimeModule color = ps.colorOverLifetime;
            color.enabled = true;
            var gradient = new Gradient();
            gradient.SetKeys(
                new[] { new GradientColorKey(Color.white, 0f), new GradientColorKey(Color.white, 1f) },
                new[] { new GradientAlphaKey(1f, 0f), new GradientAlphaKey(0.85f, 0.35f), new GradientAlphaKey(0f, 1f) });
            color.color = new ParticleSystem.MinMaxGradient(gradient);

            var renderer = ps.GetComponent<ParticleSystemRenderer>();
            renderer.renderMode = ParticleSystemRenderMode.Billboard;
            renderer.sharedMaterial = material;
            renderer.sortMode = ParticleSystemSortMode.Distance;

            return ps;
        }

        // Runtime fallback when no DustMaterial asset is wired: a fuller soft dot on the custom
        // Tarrock/DustParticle shader (URP renders the legacy/programmatic particle materials
        // unreliably; the custom shader is deterministic).
        private static Material BuildRuntimeDustMaterial()
        {
            const int res = 48;
            var dot = new Texture2D(res, res, TextureFormat.RGBA32, false) { name = "DustPuffRuntime" };
            var half = new Vector2((res - 1) * 0.5f, (res - 1) * 0.5f);
            for (int y = 0; y < res; y++)
            {
                for (int x = 0; x < res; x++)
                {
                    float d = Vector2.Distance(new Vector2(x, y), half) / (res * 0.5f);
                    float a = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01((1f - d) * 1.8f)); // broad body, soft edge
                    dot.SetPixel(x, y, new Color(1f, 1f, 1f, a));
                }
            }

            dot.Apply();

            Shader particle = Shader.Find("Tarrock/DustParticle");
            var mat = new Material(particle != null ? particle : Shader.Find("Sprites/Default"))
            {
                name = "DustMaterialRuntime",
                mainTexture = dot,
            };
            if (mat.HasProperty("_MainTex"))
            {
                mat.SetTexture("_MainTex", dot);
            }

            return mat;
        }
    }
}
