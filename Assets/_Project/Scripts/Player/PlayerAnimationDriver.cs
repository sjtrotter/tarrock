namespace Tarrock.Player
{

    using UnityEngine;

    /// <summary>
    /// Bridges the Fool's locomotion state to the vendored KayKit character's <see cref="Animator"/>
    /// (director feedback: "no animation"). Each frame it reads <see cref="PlayerMotor.CurrentPlanarSpeed"/>
    /// and <see cref="PlayerDodge.IsDodging"/> and pushes them into the Animator's <c>Speed</c> float
    /// (driving the Idle→Walk→Run 1D blend tree) and <c>Dodge</c> bool (gating the roll state). The
    /// parameter names are the single source of truth shared with the AnimatorController built by
    /// <c>StandInArtInstaller</c>; keep them in sync.
    ///
    /// This component is purely visual and read-only with respect to gameplay — it never moves the
    /// character or touches the <see cref="CharacterController"/>. If no Animator is wired (e.g. the
    /// capsule fallback when the vendored model is absent) it quietly does nothing.
    /// </summary>
    public sealed class PlayerAnimationDriver : MonoBehaviour
    {
        // Shared with the AnimatorController's parameters (StandInArtInstaller.BuildAnimatorController).
        private const string SpeedParameter = "Speed";
        private const string DodgeParameter = "Dodge";

        private static readonly int SpeedHash = Animator.StringToHash(SpeedParameter);
        private static readonly int DodgeHash = Animator.StringToHash(DodgeParameter);

        [SerializeField] private Animator _animator;
        [SerializeField] private PlayerMotor _motor;
        [SerializeField] private PlayerDodge _dodge;

        [Tooltip("Damping (seconds) applied to the Speed float so the locomotion blend eases rather than snaps.")]
        [SerializeField] private float _speedDampTime = 0.1f;

        private void Awake()
        {
            if (_animator == null)
            {
                _animator = GetComponentInChildren<Animator>();
            }

            if (_motor == null)
            {
                _motor = GetComponent<PlayerMotor>();
            }

            if (_dodge == null)
            {
                _dodge = GetComponent<PlayerDodge>();
            }
        }

        private void Update()
        {
            if (_animator == null || _animator.runtimeAnimatorController == null)
            {
                return;
            }

            float speed = _motor != null ? _motor.CurrentPlanarSpeed : 0f;
            _animator.SetFloat(SpeedHash, speed, _speedDampTime, Time.deltaTime);
            _animator.SetBool(DodgeHash, _dodge != null && _dodge.IsDodging);
        }
    }
}
