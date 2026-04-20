
function OnAttacked_BeforeDamage(hitInfo)
    
    print("被武器击中了！")
    FishLaunch();
    
end

function OnEditorButton()
    FishLaunch();
end

function FishLaunch()
    math.randomseed(os.time())

    -- Generate a random number between 1 and 3
    local randomValue = math.random(1, 3)

    -- Use the random value
    if randomValue == 1 then
        -- Option 1
        print("寄居蟹")
        local entity = API:CreateEntity(43007, host.transform.position)
    elseif randomValue == 2 then
        -- Option 2
        print("招潮蟹")
        local entity = API:CreateEntity(43000, host.transform.position)
    elseif randomValue == 3 then
        -- Option 3
        print("龙虾")
        local entity = API:CreateEntity(43005, host.transform.position)
    else
        -- Invalid random value
        print("Invalid random value.")
    end
    
end