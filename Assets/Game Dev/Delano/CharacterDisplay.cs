using TMPro;
using UnityEngine;

public class CharacterDisplay : MonoBehaviour
{
    [Header("Player Character Text")]
    [SerializeField] private TMP_Text player1Text;
    [SerializeField] private TMP_Text player2Text;

    private string[] roleNames = { "Chef", "Server" };

    private void Start()
    {
        int p1 = GameSession.CharacterIndex[0];
        int p2 = GameSession.CharacterIndex[1];

        player1Text.text = "Player 1: " + roleNames[p1];
        player2Text.text = "Player 2: " + roleNames[p2];
    }
}
