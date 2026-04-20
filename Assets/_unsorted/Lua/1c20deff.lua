function Start()
    EventCenter.LuaAddListener(code, HitTrigger);
    print("Generator is ready!")
end

function OnEditorButton()
    HitTrigger();
end


function HitTrigger()
    print("接收到了信号！")

    if pos1 ~=nil then
        local entity = API:CreateEntity(entityID,pos1.transform.position);
        print("1召唤了",entityID,pos1.transform.position)
    end
    if pos2 ~=nil then
        local entity = API:CreateEntity(entityID,pos2.transform.position);
        print("2召唤了",entityID,pos2.transform.position)
    end
    if pos3 ~=nil then
        local entity = API:CreateEntity(entityID,pos3.transform.position);
        print("3召唤了",entityID,pos3.transform.position)
    end
    if pos4 ~=nil then
        local entity = API:CreateEntity(entityID,pos4.transform);
        print("4召唤了",entityID,pos4.transform.position)
    end
    if pos5 ~=nil then
        local entity = API:CreateEntity(entityID,pos5.transform);
        print("5召唤了",entityID,pos5.transform.position)
    end

    end