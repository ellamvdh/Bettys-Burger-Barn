using System;
using System.Collections;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerMovement : MonoBehaviour
{
    private GameObject camera;

    [SerializeField] private InputActionAsset playerControls;

    private InputAction walkAction;
    private InputAction rotateAction;

    private Vector2 moveAmount;
    private Vector2 rotateAmount;

    [SerializeField] private Rigidbody rb;

    [Header("Speed Amount")]
    [SerializeField] private float walkSpeed;
    [SerializeField] private float rotateSpeed;

    private bool activateMovement;

    [Header("Interact")]
    [SerializeField] GameObject interactableObject;
    [SerializeField] bool canInteract = false;
    [SerializeField] InputAction interactAction;
   
    [SerializeField] GameObject SnapPoint;
    [SerializeField] GameObject PickedUpItem;

    enum PickUpState
    {
        none,
        CanPlace,
        CanPickUp
    }
    PickUpState pickupstate = PickUpState.none;
    [SerializeField] bool PickedUp = false;
    //[SerializeField] bool CanPlace = false;
    //[SerializeField] bool CanPickUp = false;
    [SerializeField] Bord WhereToPlace;
    



    //private void OnEnable()
    //{
    //    playerControls.FindActionMap("Xbox Controller").Enable();
    //}

    [SerializeField] private InputActionReference InteractButton;

    private void OnEnable()
    {
        InteractButton.action.Enable();
        InteractButton.action.performed += Interact;
    }
    private void OnDisable()
    {
        playerControls.FindActionMap("Xbox Controller").Disable();
        InteractButton.action.Disable();
    }

    private void Awake()
    {
        walkAction = playerControls.FindAction("Walking");
        rotateAction = playerControls.FindAction("Rotating");
        interactAction = playerControls.FindAction("Interact");

        rb = GetComponent<Rigidbody>();

        camera = Camera.main.gameObject;
    }




    //Interact with the object if A is pressed and the player is in range of the object.
    private void Interact(InputAction.CallbackContext context)
    {
        if(pickupstate == PickUpState.CanPickUp && PickedUp == false && WhereToPlace.HoldingSomething == true)
        {
            
            WhereToPlace.HoldingObject.transform.parent = SnapPoint.transform;
            WhereToPlace.HoldingObject.transform.localPosition = Vector3.zero;
            WhereToPlace.HoldingSomething = false;
            PickedUp = true;
            PickedUpItem = WhereToPlace.HoldingObject;
            WhereToPlace.HoldingObject = null;
        }
        if (PickedUp && pickupstate == PickUpState.CanPlace)
        {
            if (PickedUp && WhereToPlace.HoldingSomething == false)
            {
                PickedUpItem.transform.parent = WhereToPlace.Snap.transform;
                PickedUpItem.transform.localPosition = Vector3.zero;
                WhereToPlace.HoldingSomething = true;
                WhereToPlace.HoldingObject = PickedUpItem;

                PickedUp = false;
                PickedUpItem = null;
                Debug.Log("Dropped");
                pickupstate = PickUpState.CanPickUp;
            }
        }
        else if (canInteract && interactableObject != null && !PickedUp)
        {
            GameObject food = interactableObject.GetComponent<Interactable>().IE_Interact();
            GameObject foodInstance = Instantiate(food, SnapPoint.transform.position, SnapPoint.transform.rotation);
            foodInstance.transform.parent = SnapPoint.transform;
            foodInstance.transform.localPosition = Vector3.zero;

            PickedUp = true;

            canInteract = false;

            //pas dit aan
            PickedUpItem = foodInstance;
            interactableObject = null;

        }
    }

    private void Update()
    {
        moveAmount = walkAction.ReadValue<Vector2>();
        rotateAmount = rotateAction.ReadValue<Vector2>();

        //InteractInput();
    }

    private void FixedUpdate()
    {
        Movement();
    }


    public void ActivateMovement(InputAction.CallbackContext context)
    {
        if (!activateMovement)
        {
            activateMovement = true;
        }
    }

    private void Movement()
    {
        if(moveAmount.x != 0 || moveAmount.y != 0 && activateMovement)
        {
            Vector3 camRight = camera.transform.right;
            camRight.y = 0;

            Vector3 camForward = camera.transform.forward;
            camForward.y = 0;

            Vector3 forwardRelative = (moveAmount.y * walkSpeed) * camForward;

            Vector3 rigthRelative = (moveAmount.x * walkSpeed) * camRight;

            Vector3 moveDir = forwardRelative + rigthRelative;

            rb.linearVelocity = new Vector3(moveDir.x, rb.linearVelocity.y, moveDir.z);

            transform.forward = new Vector3(rb.linearVelocity.x, 0, rb.linearVelocity.z);

            //transform.forward = new Vector3(Mathf.MoveTowards(transform.forward.x, rb.linearVelocity.x, 1f), 0, Mathf.MoveTowards(transform.forward.z, rb.linearVelocity.z, 1f));
        }
        else
        {
            rb.linearVelocity = new Vector3(0, 0, 0);
            activateMovement = false;
        }

    }

    //Detect if the player is in range of an interactable object and set the canInteract variable to true.
    private void OnTriggerEnter(Collider other)
    {
        if(other.gameObject.TryGetComponent<Placeable>(out var placeable))
        {
            WhereToPlace = other.gameObject.GetComponent<Bord>();
            if(WhereToPlace.HoldingSomething == false)
            {
                pickupstate = PickUpState.CanPlace;
            }
            else
            {
                pickupstate = PickUpState.CanPickUp;
            }
               
        }
        else if (other.gameObject.TryGetComponent<Interactable>(out var interactable))
        {
            interactableObject = other.gameObject;
            canInteract = true;
        }
    }

    //Detect if the player is out of range of an interactable object and set the canInteract variable to false.
    private void OnTriggerExit(Collider other)
    {
        if(canInteract && other.gameObject == interactableObject)
        {
            canInteract = false;
            interactableObject = null;
            Debug.Log("Exited");
        }
        WhereToPlace = null;
        pickupstate = PickUpState.none;

    }

    

}


