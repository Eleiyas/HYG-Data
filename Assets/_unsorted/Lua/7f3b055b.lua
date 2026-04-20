--被湮沫折磨的蚂蚁
--平时四处游走
--只有背部的湮沫能受击，受到攻击时会生气，停顿一会后进入追击状态
--追击状态：朝目标寻路，寻到了之后攻击，攻击完毕后回到散步状态
--攻击：将玩家击倒
--湮沫受到攻击后会松动，受到三次攻击后会掉落

HoneyAnt = HoneyAnt or {}

chaseSpeed = chaseSpeed or 3

local beHitCount = 0
local playerBeHitCount = 0

function Start()
    HoneyAnt:StartListen()
end

local patrolling = nil
local patrolRotating = nil
local foundPlayer = false

function Update()
    if not(foundPlayer) and API:PossibilityCheck(1) then
        if patrolling ~= nil then
            patrolling:Kill()
        end
        if patrolRotating~=nil then
            patrolRotating:Kill()
        end
        local randomAngle = math.random(0, 90)
        local rotateSpeed = 10.0
        patrolRotating = host.transform:DOLocalRotate(host.transform.rotation.eulerAngles + Vector3(0, randomAngle, 0), randomAngle/rotateSpeed)
        patrolRotating:OnComplete(function()
            patrolling = host.transform:DOMove(host.transform.position + host.transform.forward * 5, 10):OnComplete(function()
                patrolRotating = nil
                patrolling = nil
            end):OnKill(function()
                patrolRotating = nil
                patrolling = nil
            end)
        end)
    end
end

--test
function OnEditorButton()
    HoneyAnt:StartChase()
end

function HoneyAnt:StartListen()
    foundPlayer = false
    honey:GetComponent(typeof(CS.UnityEngine.Renderer)).material:DOColor(Color.yellow, 0.5)
    --监听：蜜受击时进入追击状态
    API:ListenCallback(honey, "OnTriggerEnter", function(other, comp)
        if is_null(other.transform:GetComponent(typeof(CS.miHoYo.HYG.Entity.WeaponObj))) then
            return
        end
        beHitCount = beHitCount + 1
        honey.transform:DOShakeScale(0.5)
        honey.transform.localScale = Vector3.one * (1-beHitCount * 0.33)
        GameObject.Destroy(comp)
        honey:GetComponent(typeof(CS.UnityEngine.Renderer)).material:DOColor(Color.red, 0.5)

        if beHitCount >= 3 then
            HoneyAnt:Finish();
            return
        end

        API:ShowTooltip("湮沫被打松了一些，但蚂蚁也很痛，它生气了！")
        foundPlayer = true;
        if patrolling~=nil then
            patrolling:Kill()
        end
        if patrolRotating~=nil then
            patrolRotating:Kill()
        end
        
        HoneyAnt:PrepareToChase()
    end)
end

function HoneyAnt:PrepareToChase()
    local angle =Quaternion.LookRotation(SimplePlayer.transform.position - host.transform.position).eulerAngles
    angle.x = 0
    angle.z = 0
    --开始转向玩家，如果提前转到位就立即完成
    local rotating = host.transform
                         :DOLocalRotate(angle,  1)
    rotating:OnComplete(function()
        HoneyAnt:StartChase()
    end):OnUpdate(function()
        if Vector3.Angle(SimplePlayer.transform.position - host.transform.position, host.transform.forward) < 1 then
            rotating:Kill()
            HoneyAnt:StartChase()
        end
    end)
end

function HoneyAnt:StartChase()
    local chasing = host.transform:DOMove(host.transform.position + host.transform.forward * 5, 3)
    chasing:OnUpdate(
            function()
                if Vector3.Distance(host.transform.position,SimplePlayer.transform.position) < 0.5 then
                    chasing:Kill();
                    HoneyAnt:Attack();
                    API:DelayCall(1, function()
                        HoneyAnt:StartListen()
                    end);
                end
            end
    ):OnComplete(
            function()
                API:DelayCall(1, function()
                    HoneyAnt:StartListen()
                end);
            end)
end

function HoneyAnt:Attack()
    playerBeHitCount = playerBeHitCount + 1
    SimplePlayer:TrySwitchToSkill("FallDown_1")
end

function HoneyAnt:Finish()
    local dropItem = API:LoadPrefab("Mesh/153_bushfruit")
    dropItem.transform.position = honey.transform.position
    dropItem.transform.localScale = Vector3.one * 3
    dropItem.transform:DOJump(dropItem.transform.position + Quaternion.Euler(0,math.random(0, 360),0) * Vector3.forward, 1, 1, 1)
    local collider = dropItem:AddComponent(typeof(CS.UnityEngine.BoxCollider))
    collider.isTrigger = true;
    dropItem.layer = CS.UnityEngine.LayerMask.NameToLayer("CollisionableObject")
    API:ListenCallback(dropItem, "OnTriggerEnter", function(other, comp)
        API:DelayCall(3, function()
            if other.gameObject == SimplePlayer.gameObject then
                if playerBeHitCount == 0 then
                    API:ShowTooltip("获取了完好无损的水果（玩家未被击倒过）")
                else
                    API:ShowTooltip("获取了卖相普通的水果（玩家被击倒过）")
                end
            end
            GameObject.Destroy(dropItem)
        end)
    end)
    API:ShowTooltip("成功清理了湮沫，蚂蚁舒服了")
end