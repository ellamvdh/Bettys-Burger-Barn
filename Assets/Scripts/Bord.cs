using UnityEngine;

public class Bord : MonoBehaviour, Placeable , Interactable
{
    [SerializeField] public GameObject Snap;
    [SerializeField] public bool HoldingSomething = false;
    [SerializeField] public GameObject HoldingObject;
    public void OnPlace()
    {
        Debug.Log("Bord placed");
    }

    public GameObject IE_Interact()
    {
        Debug.Log("Bord interacted");
        return null;
    }

}
