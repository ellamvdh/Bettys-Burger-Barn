using TMPro;
using UnityEngine;
using UnityEngine.InputSystem;

[DefaultExecutionOrder(-100)]
public class RoleAssigner : MonoBehaviour
{
    [Tooltip("0 = Chef, 1 = Server")]
    [SerializeField] private int role;
    [SerializeField] private InputActionAsset controls;

    private readonly string[] roleNames = { "Chef", "Server" };

    private void Awake()
    {
        int playerIndex = System.Array.IndexOf(GameSession.CharacterIndex, role);
        if (playerIndex < 0) playerIndex = role;

        Gamepad pad = GameSession.Pads[playerIndex];
        if (pad == null && Gamepad.all.Count > playerIndex)
            pad = Gamepad.all[playerIndex];

        var map = controls.FindActionMap("Xbox Controller");

        if (pad != null)
        {
            controls.devices = new InputDevice[] { pad };
            map.Enable();
        }
        else
        {
            map.Disable();
        }
    }

    private void Update()
    {
        var walk = controls.FindAction("Walking");
        Vector2 v = walk.ReadValue<Vector2>();
        if (v != Vector2.zero)
            Debug.Log($"{name}: enabled={walk.enabled}, value={v}, device={walk.activeControl?.device.displayName}");
    }

    private void OnDestroy()
    {
        controls.devices = null;
    }
}