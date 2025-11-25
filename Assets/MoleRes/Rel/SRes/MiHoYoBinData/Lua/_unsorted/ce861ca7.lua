require("PrototypeUtil");

--同mono脚本
function Awake()
    print("lua awake...")
end

--同mono脚本
function Start()
    print("lua start...")
    --test：调用require进来的Example2中的requireTest方法
    PrototypeUtil:requireTest()
end

--同mono脚本
function Update()
    --test：从mono脚本中获取名为floatParam的float类型参数
    print("injected object: ", floatParam)

    local speed = 10
    --test：控制mono脚本中的transform旋转
    local r = CS.UnityEngine.Vector3.up * CS.UnityEngine.Time.deltaTime * speed
    
    --host等同于mono脚本中的this
    host.transform:Rotate(r)
end

--同mono脚本
function OnDestroy()
    print("lua destroy")
end

--调用时机：host所在的GameObject上的Trigger组件与玩家武器发生碰撞时
--使用条件：给受击物添加了Collider组件，勾选IsTrigger，Layer设为CollisionableObject
function OnAttacked_BeforeDamage(hitInfo)
    print("被武器击中了！")
    particle = ParticleManager:ShowParticle("Effects/Player/Interact/Eff_caikuang_knock.prefab", 2)
    particle.transform.position = hitInfo.hitPoint
end

--调用时机：host所在的GameObject上的Trigger组件与玩家发生碰撞时
--使用条件：给受击物添加了Collider组件，勾选IsTrigger，Layer设为CollisionableObject
function OnCollisionToPlayer()
    print("碰到了玩家！")
end

--调用时机：host所在的GameObject上的Trigger组件与玩家发生碰撞时
--使用条件：给受击物添加了Collider组件，勾选IsTrigger，Layer设为CollisionableObject
function OnStayWithPlayer()
    print("与玩家持续接触！")
end

--调用时机：host所在的GameObject上的Trigger组件与玩家发生碰撞时
--使用条件：给受击物添加了Collider组件，勾选IsTrigger，Layer设为CollisionableObject
function OnExitFromPlayer()
    print("与玩家结束碰撞！")
end

function OnOptionButton(buttonName)
    print("按钮 "..buttonName.."被点击了")
end

--调用时机：点击宿主脚本在Inspector上显示的【自定义按钮】
function OnEditorButton()
    API:Test()
    print("点击了编辑器按钮！")
    
    --变量访问示例：
    print(Player) --拿到玩家的Entity对象
    print(Companion) --拿到陪伴的Entity对象

    --全局变量访问示例：多个脚本之间共享的变量
    G.levelScore = G.levelScore or 0
    G.levelScore = G.levelScore + 1
    print("levelScore = ", G.levelScore)

    local slope = API:GetSlope(Player.root)
    print("当前坡度：", slope)
    local isInWater = API:IsInWater(Player.root)
    print("在水中：", isInWater)
    
    --API示例：创建一个选项按钮
    local btnHandler = API:ShowOptionButton(
            "测试",
            function()
                print("点击了创建出来的按钮！")
            end)
    
    --API示例：移除刚刚创建的选项按钮
    API:RemoveOptionButton("测试")
    
    --API示例：在屏幕中间创建一个按钮（可以传入按下和抬起的回调）
    local btn = API:ShowButton(
            "QTE", 
            function()
                print("按下")
            end, 
            function()
                print("抬起")
            end)
    
    --API示例：移除刚刚创建的按钮
    API:RemoveButton("QTE")

    --API示例：显示一条Tooltip
    API:ShowTooltip("显示一条Tooltip")
    
    --API示例：在host所在的GameObject的相对位置播放一个特效资源
    API:ShowVFX("Effects/Player/Interact/Eff_caikuang_knock.prefab", Vector3(0, 1, 1), 2)
    
    --API示例：获取当前的陪伴NPC Entity对象
    local companion = API:GetCompanion()
    if companion~=nil then
        print("当前陪伴对象： ",companion.DisplayName)
    end

    --API示例：暂停npc的AI
    API:PauseAI(companion.guid)
    --API示例：恢复npc的AI
    API:ResumeAI(companion.guid)
    
    --API示例：增加陪伴值
    API:AddCompanionValue(5)
    
    --API实例：延迟执行
    API:DelayCall(2, function()
        --2秒后执行
        print("延迟2秒才执行的内容")
    end);

    --API示例：执行一个时长0.5秒的平移过程，参数依次为：目标点，过程时长
    host.transform:DOMove(host.transform.position + Vector3.forward * 10,  0.5)
    
    --API示例：执行一个时长0.5秒的跳跃过程，参数依次为：目标点，跳跃高度，跳跃次数，过程时长
    host.transform:DOJump(host.transform.position + Vector3.forward * 10, 1, 1, 0.5)

    --API示例：执行一个时长0.5秒的旋转过程，绕x轴旋转100度，参数依次为：目标旋转（xyz），过程时长
    host.transform:DOLocalRotate(host.transform.rotation.eulerAngles + Vector3(100,0,0),  0.5)

    if API:PossibilityCheck(10) then
        --如果命中了一次10%概率的判定，则...
    end
    
    --API示例：创建一个Entity，参数依次为：Entity的ConfigID，位置在000
    local entity = API:CreateEntity(30000, Vector3(0,0,0))

    --API示例：给玩家加速50%
    API:AddMoveSpeedMultiplier(Player.guid,0.5)
    --API示例：移除玩家加速效果
    API:RemoveMoveSpeedMultiplier(Player.guid)
    
    
    
end