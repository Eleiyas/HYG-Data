function Start()
    select1:SetActive(false);
    select2:SetActive(false);
    select3:SetActive(false);
    
    math.randomseed(os.time())

    -- Generate a random number between 1 and 3
    local randomValue = math.random(1, 3)

    -- Use the random value
    if randomValue == 1 then
        -- Option 1
        select1:SetActive(true);
    elseif randomValue == 2 then
        -- Option 2
        select2:SetActive(true);
    elseif randomValue == 3 then
        -- Option 3
        select3:SetActive(true);
    else
        -- Invalid random value
        print("Invalid random value.")
    end

end
