DefaultNextSkill = "Idle"

function OnEnter()
    this:PlayAnim("Ani_Avatar_Player_sword_ackA_end");
    this.animState.Speed = 2;
    this:SetCanSwitchList("Idle","Move")
end

function OnUpdate()

end