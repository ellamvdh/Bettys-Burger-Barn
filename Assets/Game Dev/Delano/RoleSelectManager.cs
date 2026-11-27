using TMPro;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

public class RoleSelectManager : MonoBehaviour
{
    [Header("Buttons")]
    [SerializeField] private Button[] roleButtons;

    [Header("UI")]
    [SerializeField] private TMP_Text p1Text;
    [SerializeField] private TMP_Text p2Text;
    [SerializeField] private GameObject startPrompt;

    [Header("Scenes")]
    [SerializeField] private string gameSceneName;
    [SerializeField] private string mainMenuSceneName;

    private readonly string[] roleNames = { "Chef", "Server" };
    private int p1Role = -1;

    private bool waitForARelease = false;

    private void Start()
    {
        Cursor.visible = false;
        Cursor.lockState = CursorLockMode.Locked;

        GameSession.CharacterIndex = new[] { -1, -1 };
        ResetSelection();
    }

    public void SelectRole(int role)
    {
        if (p1Role != -1) return;

        p1Role = role;
        int p2Role = 1 - role;

        GameSession.CharacterIndex[0] = p1Role;
        GameSession.CharacterIndex[1] = p2Role;

        // Whoever pressed A first is player 1
        Gamepad p1Pad = Gamepad.current;
        GameSession.Pads[0] = p1Pad;
        GameSession.Pads[1] = null;
        foreach (var pad in Gamepad.all)
            if (pad != p1Pad) { GameSession.Pads[1] = pad; break; }

        foreach (var b in roleButtons) b.interactable = false;

        p1Text.text = "Player 1: " + roleNames[p1Role];
        p2Text.text = "Player 2: " + roleNames[p2Role];
        startPrompt.SetActive(true);
        waitForARelease = true;
    }

    private void Update()
    {
        if (Gamepad.all.Count == 0) return;

        bool back = false;
        bool confirm = false;
        bool aHeld = false;

        foreach (var pad in Gamepad.all)
        {
            if (pad.buttonEast.wasPressedThisFrame)
                back = true;

            if (pad.buttonSouth.wasPressedThisFrame)
                confirm = true;

            if (pad.buttonSouth.isPressed)
                aHeld = true;
        }

        if (p1Role == -1)
        {
            if (back)
                SceneManager.LoadScene(mainMenuSceneName);
        }
        else
        {
            if (waitForARelease)
            {
                if (!aHeld)
                    waitForARelease = false;

                return;
            }

            if (back)
            {
                ResetSelection();
            }
            else if (confirm)
            {
                SceneManager.LoadScene(gameSceneName);
            }
        }
    }

    private void ResetSelection()
    {
        int previous = Mathf.Max(p1Role, 0);
        p1Role = -1;
        GameSession.CharacterIndex = new[] { -1, -1 };

        foreach (var b in roleButtons) b.interactable = true;

        p1Text.text = "Player 1";
        p2Text.text = "Player 2";
        startPrompt.SetActive(false);

        EventSystem.current.SetSelectedGameObject(null);
        EventSystem.current.SetSelectedGameObject(roleButtons[previous].gameObject);
    }
}