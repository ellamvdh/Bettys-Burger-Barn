using System;
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

    private void OnEnable()
    {
        playerControls.FindActionMap("Xbox Controller").Enable();
    }

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

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
    }

    private void Update()
    {
        moveAmount = walkAction.ReadValue<Vector2>();
        rotateAmount = rotateAction.ReadValue<Vector2>();
    }

    private void FixedUpdate()
    {
        Walking();
        //RotateTowardsVector();
        Rotating();

        //Debug.Log(rotateAmount.x);
    }


    private void Walking()
    {
        //rb.transform.Translate(moveAmount.x * Time.deltaTime * walkSpeed, 0, moveAmount.y * Time.deltaTime * walkSpeed);

        //if (rotateAmount.x != 0 || rotateAmount.y != 0)
        //{
        //    Vector3 pos = (camera.transform.position + new Vector3(rotateAmount.x, 0, rotateAmount.y)) - camera.transform.position;
        //    rb.rotation = Quaternion.LookRotation(new Vector3(pos.x, pos.y, pos.z));
        //}

        if(moveAmount.x != 0 || moveAmount.y != 0)
        {
            //rb.MovePosition(rb.position + (rb.transform.forward * walkSpeed) * Time.deltaTime);

            Vector3 camRight = camera.transform.right;
            camRight.y = 0;

            Vector3 camForward = camera.transform.forward;
            camForward.y = 0;

            Vector3 forwardRelative = (moveAmount.y * walkSpeed) * camForward;

            Vector3 rigthRelative = (moveAmount.x * walkSpeed) * camRight;

            Vector3 moveDir = forwardRelative + rigthRelative;

            rb.linearVelocity = new Vector3(moveDir.x, rb.linearVelocity.y, moveDir.z);

            transform.forward = new Vector3(rb.linearVelocity.x, 0, rb.linearVelocity.z);
        }

    }
    private void Rotating()
    {
        //float rotationAmount = rotateAmount.x * rotateSpeed * Time.deltaTime;
        //Quaternion deltaRotation = Quaternion.Euler(0, rotationAmount, 0);
        //rb.MoveRotation(rb.rotation * deltaRotation);

        //rb.rotation = Quaternion.Euler(rb.rotation.x, rotateAmount.y * Time.deltaTime * rotateSpeed, rb.rotation.z);
        //if (rotateAmount.x != 0 || rotateAmount.y != 0)
        //{
        //    Vector3 pos = (transform.position + new Vector3(rotateAmount.x, 0, rotateAmount.y)) - transform.position;
        //    rb.rotation = Quaternion.LookRotation(pos);
        //}
    }

    //public void RotateTowardsVector()
    //{
    //    var xzDirection = new Vector3(moveAmount.y, 0, 0);
    //    if (xzDirection.magnitude == 0) return;

    //    var rotation = Quaternion.LookRotation(xzDirection);
    //    rb.transform.rotation = Quaternion.RotateTowards(rb.transform.rotation, rotation, rotateSpeed);
    //}
}
