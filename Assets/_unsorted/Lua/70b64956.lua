DefaultNextSkill = "SwordAttack_3"

function OnEnter()
    host.weapon.enabled = true;
    this:PlayAnim("Ani_Avatar_Player_sword_ackA_atk");
    this.animState.Speed = 2;
    this:SetCanSwitchList("SwordAttack_3")
end

function OnUpdate()
    
end

function OnLastFrame()
    host.weapon.enabled = false;
end