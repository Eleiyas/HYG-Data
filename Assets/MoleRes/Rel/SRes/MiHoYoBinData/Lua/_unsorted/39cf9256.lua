DefaultNextSkill = "FallDown_3"

function OnEnter()
    this:PlayAnim("Ani_Avatar_Player_falldown_loop");
    this:SetCanSwitchList("FallDown_3")
end

function OnUpdate()
    
end