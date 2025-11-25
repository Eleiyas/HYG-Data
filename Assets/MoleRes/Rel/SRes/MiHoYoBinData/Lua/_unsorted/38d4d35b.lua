DefaultNextSkill = "FallDown_2"

function OnEnter()
    this:PlayAnim("Ani_Avatar_Player_falldown_start");
    this:SetCanSwitchList("FallDown_2")
end

function OnUpdate()
    
end