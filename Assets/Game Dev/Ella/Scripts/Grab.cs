using System;
using System.Collections.Generic;
using UnityEngine;

public class Grab : MonoBehaviour, Interactable
{
    [SerializeField] private GameObject Food;
    [SerializeField] private List<GameObject> FoodList;

    // Wordt afgevuurd zodra er een ingredient gekozen is
    public event Action<GameObject> OnIngredientChosen;

    public GameObject IE_Interact()
    {
        // Alleen het menu openen, de speler krijgt pas iets zodra er op een knop gedrukt is
        return null;
    }

  
    public void ChooseIngredient(int index)
    {
        Food = FoodList[index];
        OnIngredientChosen?.Invoke(Food);
        
    }


    private void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {

        }
    }

}