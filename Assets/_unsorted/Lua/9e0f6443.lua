--[[将以下内容发送给gpt4：

我在Unity中通过xlua制作一个跷跷板，它是通过在GameObject上挂载一段lua脚本实现的。想要的效果是：
--靠近时出现"跳上"按钮
--点击跳上按钮后玩家和伙伴都进入"跳入中"状态，0.5秒后进入"坐下"状态
--跳入中状态：玩家和伙伴分别通过曲线运动到跷跷板socket1和socket2
--坐下状态：跷跷板获得一个向伙伴侧下沉的角速度，屏幕中出现两个按钮：一个QTE按钮，点击后跷跷板再获得一个向玩家侧下沉的角速度，一个跳出按钮，点击后玩家和伙伴都进入"跳出中"状态，0.5秒后回到默认状态
--跳出中状态：玩家和伙伴分别通过曲线运动到右手边0.5米地面
--在坐下状态下，如果跷跷板的
--已经设定好的全局变量：跷跷板：plane，玩家在跷跷板锚点socket1, 伙伴在跷跷板锚点socket2, 玩家：Player，伙伴：Companion，未按下按钮时伙伴侧下沉的角速度companionForce，按下QTE按钮时玩家下沉的角速度pressForce
--已有的API：Update(), ShowButton(name, onClick), RemoveButton(name), DORotate(targetRotation, duration), DOJump(targetPosition, duration)
请给出能够实现这个效果的lua脚本
--]]
SingletonUtil = require("UIFramework/SingletonUtil");

Seesaw = Seesaw or {}

local SeesawState = {
    Default = 1,
    JumpOn = 2,
    Sitting = 3,
    JumpOut = 4,
}
local isPressingQTE = false
local currentState = SeesawState.Default
local companion = API:GetCompanion()
local balanceTime = 0

function Start()
    if companion == nil then
        --如果当前没有伙伴，就通过CS原生API设置一个伙伴（子涯）
        --对CS原生API的调用方式，较为进阶，不要求掌握，只需要熟悉"API:"开头的调用方式
        local entity = SingletonUtil.get("miHoYo.HYG.Entity.EntityManager").avatarManager:GetNpcEntityByConfigId(1002)
        SingletonUtil.get("miHoYo.HYG.AIManager"):InviteNPCCompanion(entity.guid);
        companion = API:GetCompanion()
    end
end

function Update()
    --本帧内要旋转的角度
    local rotateX = 0
    
    if currentState == SeesawState.Default and API:IsInRange(Player.root, host.gameObject, 1) then
        API:ShowOptionButton("Jump On", function()
            Seesaw:JumpOn()
        end)
    else
        API:RemoveOptionButton("Jump On")
    end

    if currentState == SeesawState.Sitting then
        API:ShowButton("QTE",
                function()
                    isPressingQTE = true
                end,
                function()
                    isPressingQTE = false
                end)
        API:ShowOptionButton("Jump Off", function()
            Seesaw:JumpOut()
        end)
        rotateX = rotateX - companionForce * Time.deltaTime
        if isPressingQTE then
            rotateX = rotateX + pressForce * Time.deltaTime
        end
        plane.transform.rotation = Quaternion.Euler(Seesaw:GetTargetRotation(rotateX))

        if (Seesaw:IsBalanced()) then
            balanceTime = balanceTime + Time.deltaTime
            if (balanceTime>balanceTickInterval) then
                print("陪伴值++")
                API:AddCompanionValue(5)
                balanceTime = 0;
            end
        else
            print("失衡了")
            balanceTime = 0;
        end
    else
        API:RemoveButton("QTE")
        API:RemoveOptionButton("Jump Off")
    end
end

--按下跳上按钮后
function Seesaw:JumpOn()
    --进入跳上状态
    currentState = SeesawState.JumpOn
    --开始进行一个0.5秒的曲线运动，运动结束后进入坐下状态，并将朝向设为望向跷跷板另一边
    Player.root.transform:DOJump(socket1.transform.position, 1, 1, 0.5):OnComplete(function()
        currentState = SeesawState.Sitting
        Player.root.transform.forward = socket1.transform.position - socket2.transform.position;
    end)
    API:PauseAI(companion.guid)
    --开始进行一个0.5秒的曲线运动，运动结束后将朝向设为望向跷跷板另一边
    companion.root.transform:DOJump(socket2.transform.position, 1, 1, 0.5):OnComplete(function()
        companion.root.transform.forward = socket2.transform.position - socket1.transform.position;
    end)
end

--按下跳出按钮后
function Seesaw:JumpOut()
    currentState = SeesawState.JumpOut
    Player.root.transform:DOJump(Player.root.transform.position - host.transform.right, 1, 1, 0.5):OnComplete(function()
        API:ResumeAI(companion.guid)
        currentState = SeesawState.Default
    end)
    companion.root.transform:DOJump(companion.root.transform.position + host.transform.right, 1, 1, 0.5)
end

function Seesaw:IsBalanced()
    local angle = plane.transform.rotation.eulerAngles.x;
    return angle > -balanceAngleRange and angle < balanceAngleRange;
end

--根据x轴角度变化量计算跷跷板的旋转（xyz）
function Seesaw:GetTargetRotation(deltaX)
    local rotation = plane.transform.rotation.eulerAngles
    local x = rotation.x
    if x > 180 then
        x = x - 360
    end
    x = x + deltaX
    if x>10 then
        x = 10
    elseif x<-10 then
        x = -10
    end
    return Vector3(x, rotation.y, rotation.z)
end