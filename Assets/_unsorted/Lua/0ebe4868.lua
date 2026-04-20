--伙伴会获取道具，并展示 √
--离开素材星时，发放奖励
--清除湮沫后，如果在路程靠前段，概率出现交互物，对话询问是否直接前往下一个岛 √
--离开素材星时，提示增加伙伴好感度

local maxSize = maxSize or 5

MatStarManager = MatStarManager or {}
--G.表示全局变量，存储那些不能随着场景切换而重置的信息
G.MatStarManager = G.MatStarManager or {}
G.MatStarManager.npcBags = G.MatStarManager.npcBags or {}
npcBags = G.MatStarManager.npcBags
G.MatStarManager.addedListeners = G.MatStarManager.addedListeners or false
G.MatStarManager.starFinished = G.MatStarManager.starFinished or false

function Start()
    print("matstar manager start...")
    --local sceneId = CS.miHoYo.SingletonManager.GetSingletonInstance("miHoYo.HYG.LevelModule").curLevel.worldId
    npcBags[1005] = npcBags[1005] or {}
    npcBags[12] = npcBags[12] or {}
end

function OnAllEntityReady()
    --暂时没有精确的Entity加载完成时机，用延迟3秒代替
    API:DelayCall(3, function()
        
        API:ListenDeath(15103, function()
            if API:PossibilityCheck(100) then
                API:AddMapObj(15105)
            end
        end)

        --因为脚本每次Load场景都会重新执行，所以需要判断是否已经注册过监听
        if G.MatStarManager.addedListeners then
            return
        end
        
        --监听：通关时执行通关流程
        print('注册通关监听')
        EventCenter.LuaAddListener(EventID.Prototype.StarFinish, MatStarManager.OnStarFinish);

        --监听：有道具被拾取时，尝试添加到背包
        API:ListenPick(function(npcId,itemId)
            print("pickup!:", npcId, itemId)
            if npcId == 1005 or npcId == 12 then
                MatStarManager:TryAddItem(npcId,itemId)
            end
        end)

        G.MatStarManager.addedListeners = true
        
    end)

end

function MatStarManager:TryAddItem(npcId,itemId)
    if npcBags[npcId] ~= nil and not MatStarManager:CheckNpcBagIsFull(npcId) then
        table.insert(npcBags[npcId], itemId)
    end
end

function MatStarManager:OnStarFinish()
    if G.MatStarManager.starFinished then
        return
    end
    --lua对数据到字符串的处理比较麻烦，放在C#写比较方便，所以直接封了个特化的API
    --但这样的做法对白盒测试会不太友好，需要能进行基础的C#编程
    API:ShowStarReward(1005,npcBags[1005])
    API:ShowStarReward(12,npcBags[12])

    G.MatStarManager.starFinished = true
end


function Update()
    API:DisplayItemsById(npcBags[1005],"1005's bag",true,100,"PageLayer/MainPage(Clone)/TeamSkillNew(Clone)/Content/NpcList/2",4, Vector2(-70,-70),-1)
    API:DisplayItemsById(npcBags[12],"12's bag",true,100,"PageLayer/MainPage(Clone)/TeamSkillNew(Clone)/Content/NpcList/1",4, Vector2(-70,-70),-1)
end

function OnEditorButton()
    if API:PossibilityCheck(30) then
        MatStarManager:TryAddItem(12, 30023)
    elseif API:PossibilityCheck(30) then
        MatStarManager:TryAddItem(1005, 30024)
    elseif API:PossibilityCheck(30) then
        MatStarManager:TryAddItem(1005, 30025)
    else
        MatStarManager:TryAddItem(12, 30026)
    end
end

function MatStarManager:CheckNpcBagIsFull(npcId)
    local ret =  #npcBags[npcId] >= maxSize
    return ret
end

G.MatStarManager.CheckNpcBagIsFull = MatStarManager.CheckNpcBagIsFull
