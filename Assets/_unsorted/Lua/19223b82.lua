function Start()
    bellRoot = host.transform:Find("BellRoot");
    keyF = host.transform:Find("KeyF");
    Fx = host.transform:Find("Fx");
    print(bellRoot);
    print("TimeLimitManager is Ready");
    API:DelayCall(1, function()
        bellRoot.transform:DOLocalRotate(Vector3(-15,0,0),3)
                :SetEase(Ease.InOutSine)
                :SetLoops(-1, LoopType.Yoyo)
    end);

end

--[[function OnAttacked_BeforeDamage(hitInfo)
    print("被武器击中了！")

        print("KeySimulating");
        keyF:SetActive(true);
        Fx:SetActive(true);
        EventCenter.Broadcast(2400,HitTrigger);
        API:DelayCall(0.1, function()
            keyF:SetActive(false);
            print("KeySimulated")
        end);
end

function OnEditorButton()

    print("点击了编辑器按钮！");
    EventCenter.Broadcast(2400,HitTrigger);

end]]
