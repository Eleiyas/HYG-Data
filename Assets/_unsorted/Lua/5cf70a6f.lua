DefaultNextSkill = "Move"

function OnEnter()
    this:PlayAnim("Ani_Avatar_Player_sword_run+sword_run");
    this:SetCanSwitchList("Idle", "SwordAttack_1")
end

function OnUpdate()
    local dir = host.inputMoveDir;
    if (host.inputMoveDir==Vector3.zero) then
        host:TrySwitchToSkill("Idle")
        return
    end
    local cameraDir = Camera.main.transform.rotation;
    dir = cameraDir * dir;
    dir.y = 0;
    dir = dir.normalized;
    host.transform.rotation = Quaternion.Slerp(host.transform.rotation,Quaternion.LookRotation(dir), 0.2);
    host.transform.position = host.transform.position + dir * Time.deltaTime * host.moveSpeed;
end

function OnLastFrame()
    this:SetCanSwitchList("Idle", "Move","SwordAttack_1")
end