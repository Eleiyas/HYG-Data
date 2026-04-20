function Start()
    
    print("Weapon for fog is working")
    capsule:SetActive(false);
    
    --获取奇械的根并重设父对象
    API:DelayCall(2, function()
        weapon = GameObject.Find("root_daojv");
        print(weapon);
        host.transform:SetParent(weapon.transform, false);
    end);
end

function Update()

    if Input.GetMouseButtonDown(ture) then
        API:DelayCall(0, function()
            print("Weapon Fire");
            capsule:SetActive(true);
            API:DelayCall(1, function()
                capsule:SetActive(false);
                print("WeaponFinished")
            end);
        end);
    end
    
end