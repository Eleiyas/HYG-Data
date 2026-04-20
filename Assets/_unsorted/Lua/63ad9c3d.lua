DefaultNextSkill = "Idle"

function OnEnter()
    this:PlayAnim("Ani_Avatar_Player_falldown_end");
    this:SetCanSwitchList("Idle","Move")
end

function OnUpdate()
    
end