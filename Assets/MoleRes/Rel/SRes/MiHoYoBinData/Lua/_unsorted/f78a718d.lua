function Start()
    capsule:SetActive(false);
    
    --获取奇械的根并重设父对象
    API:DelayCall(2, function()
        Avatar = GameObject.Find("Avatar(Clone)");
        host.transform:SetParent(Avatar.transform, false);
    end);
end

function Update()

    if Input.GetMouseButtonDown(ture) then
        API:DelayCall(0.35, function()
            print("Weapon Fire");
            capsule:SetActive(true);
            API:DelayCall(0.4, function()
                capsule:SetActive(false);
                print("WeaponFinished")
            end);
        end);
    end
    
end