using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem;
using UnityEngine.SceneManagement;

public class MenuController : MonoBehaviour
{
    [Header("Panels")]
    [SerializeField] private GameObject mainMenuPanel;
    [SerializeField] private GameObject settingsPanel;

    [Header("Default Select")]
    [SerializeField] private GameObject firstMainMenuButton;
    [SerializeField] private GameObject firstSettingsElement;  

    private void Start()
    {
        Cursor.visible = false;
        Cursor.lockState = CursorLockMode.Locked;

        ShowMainMenu();
    }

    private void Update()
    {
        if (settingsPanel.activeSelf &&
            Gamepad.current != null &&
            Gamepad.current.buttonEast.wasPressedThisFrame)
        {
            ShowMainMenu();
        }
    }

    public void OpenSettings()
    {
        mainMenuPanel.SetActive(false);
        settingsPanel.SetActive(true);
        Select(firstSettingsElement);
    }

    public void ShowMainMenu()
    {
        settingsPanel.SetActive(false);
        mainMenuPanel.SetActive(true);
        Select(firstMainMenuButton);
    }

    private void Select(GameObject target)
    {
        EventSystem.current.SetSelectedGameObject(null);
        EventSystem.current.SetSelectedGameObject(target);
    }

    public void LoadScene(string sceneName)
    {
        Time.timeScale = 1f;
        SceneManager.LoadScene(sceneName);
    }

    public void Quit()
    {
        Application.Quit();
    }
}