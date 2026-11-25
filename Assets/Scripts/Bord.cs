using NUnit.Framework;
using System.Collections.Generic;
using UnityEngine;

public class Bord : MonoBehaviour, Placeable , Interactable
{
    [SerializeField] public GameObject Snap;
    [SerializeField] public bool HoldingSomething = false;
    [SerializeField] public GameObject HoldingObject;

    [SerializeField] List<string> IngredientsAdded = new List<string>();
    public void OnPlace()
    {
        Debug.Log("Bord placed");
    }

    private void Update()
    {
        if (HoldingSomething)
        {
            IngredientsAdded.Add(HoldingObject.name);
            Destroy(HoldingObject);
            HoldingSomething =false;
        }
    }
    public GameObject IE_Interact()
    {
        Debug.Log("Bord interacted");
        return null;
    }

}
