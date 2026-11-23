using UnityEngine;

public class Grab : MonoBehaviour, Interactable
{
    [SerializeField] private GameObject Food;
    public GameObject IE_Interact()
    {
        return Food;
    }
}
