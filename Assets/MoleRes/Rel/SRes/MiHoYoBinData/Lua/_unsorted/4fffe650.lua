DefaultNextSkill = "Idle"

function OnEnter()
    this:PlayAnim("Ani_Avatar_Player_sword_stand+sword_stand");
    this:SetCanSwitchList("Idle", "Move","SwordAttack_1")
end

function OnUpdate()
    
end