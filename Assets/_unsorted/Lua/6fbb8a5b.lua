DefaultNextSkill = "SwordAttack_2"

function OnEnter()
    this:PlayAnim("Ani_Avatar_Player_sword_ackA_start");
    this.animState.Speed = 2;
    this:SetCanSwitchList("SwordAttack_2")
end

function OnUpdate()
    
end