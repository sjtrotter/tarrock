namespace Tarrock.Player
{
    using UnityEngine;
    using UnityEngine.InputSystem;

    /// <summary>
    /// Locks and hides the hardware cursor during play so mouse-look reads relative motion
    /// forever instead of dying at the monitor's edge (the "camera hits a hard wall" bug —
    /// the wall was the physical screen). Standard third-person behavior: locked on play,
    /// Escape releases (so the editor stays usable), click re-locks.
    /// </summary>
    public sealed class CursorLock : MonoBehaviour
    {
        private void OnEnable()
        {
            Lock();
        }

        private void OnDisable()
        {
            Release();
        }

        // Direct InputSystem use is normally PlayerInputReader's exclusive right
        // (technical.md port-readiness); cursor management is editor/system chrome, not
        // gameplay input, so it gets a narrow exemption rather than an action binding.
        private void Update()
        {
            if (Keyboard.current != null && Keyboard.current.escapeKey.wasPressedThisFrame)
            {
                Release();
            }
            else if (Cursor.lockState != CursorLockMode.Locked
                && Mouse.current != null && Mouse.current.leftButton.wasPressedThisFrame)
            {
                Lock();
            }
        }

        private static void Lock()
        {
            Cursor.lockState = CursorLockMode.Locked;
            Cursor.visible = false;
        }

        private static void Release()
        {
            Cursor.lockState = CursorLockMode.None;
            Cursor.visible = true;
        }
    }
}
