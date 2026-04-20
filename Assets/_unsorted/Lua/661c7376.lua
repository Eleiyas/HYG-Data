function Start()
    --delayTrigge = false
    print("rotateMoonBase is working")
    API:DelayCall(1, function()
        mainCamera = GameObject.Find("MainCamera")
        avatar = GameObject.Find("Avatar(Clone)")
    end);

end

function Update()
    
    if avatar~=nil then
        host.transform.position = avatar.transform.position
        rotateTarget.transform.rotation = Quaternion.Euler(-(mainCamera.transform.position.z)*intensity,0,(mainCamera.transform.position.x)*intensity)
        --dir = (Vector3(0,0,0) - rotateTarget.transform.position).normalized
        --rotation = Quaternion.LookRotation(dir)
    end

end
