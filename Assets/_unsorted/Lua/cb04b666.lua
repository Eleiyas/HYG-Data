function Start()
    EventCenter.LuaAddListener(114514,TimeLimitStart);
    --Ballon = host.transform:Find("Ballon");
    Parent = host.transform.parent.gameObject;
    Parent:SetActive(false);
    print("Balloon is Ready");
    API:DelayCall(1, function()
        Parent:SetActive(false);
    end);
    
end

--通过TimeLimitManager触发
function TimeLimitStart()
    print("收到开启限时任务的信号了！")
    Parent:SetActive(true);
end
