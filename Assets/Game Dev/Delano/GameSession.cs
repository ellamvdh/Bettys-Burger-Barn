using UnityEngine.InputSystem;

public static class GameSession
{
    public static int[] CharacterIndex = { -1, -1 }; // 0 = Chef, 1 = Server, per player
    public static Gamepad[] Pads = new Gamepad[2];   // which controller belongs to which player
}