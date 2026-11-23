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

    //private void OnEnable()
    //{
    //    playerControls.FindActionMap("Xbox Controller").Enable();
    //}

    private void OnDisable()
    {
        playerControls.FindActionMap("Xbox Controller").Disable();
    }

    private void Awake()
    {
        walkAction = playerControls.FindAction("Walking");
        rotateAction = playerControls.FindAction("Rotating");
        
        rb = GetComponent<Rigidbody>();

        camera = Camera.main.gameObject;
    }

    private void Update()
    {
        moveAmount = walkAction.ReadValue<Vector2>();
        rotateAmount = rotateAction.ReadValue<Vector2>();
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
}


