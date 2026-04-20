function OnEditorButton()
    print("按下了按钮");
    SendEvent();
end

function OnAttacked_BeforeDamage(hitInfo)
    print("被武器击中了！")
    SendEvent();
end

function SendEvent()
    print(code,func);
    EventCenter.Broadcast(code,func);
end