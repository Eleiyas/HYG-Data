function xlua.hotfix(cs, field, func)
  if func == nil then
    func = false
  end
  local tbl = type(field) == "table" and field or {
    [field] = func
  }
  for k, v in pairs(tbl) do
    local cflag = ""
    if k == ".ctor" then
      cflag = "_c"
      k = "ctor"
    end
    local f = type(v) == "function" and v or nil
    xlua.access(cs, cflag .. k, f)
    pcall(function()
      xlua.access(cs, cflag .. k, f)
    end)
  end
  xlua.private_accessible(cs)
end

local Hotfix = {}

function Hotfix:init()
  self.func_list = {}
  if CS.miHoYo.HYG.ApplicationUtil.IsUnityEditor() then
    return
  end
  self:fix_func_ex(CS.miHoYo.HYG.Entities.GameplayUtilities.StarSea, "__Hotfix0_GetAFreePosInTrigger", function(triggerEntity)
    print("GameplayUtilities.StarSea.GetAFreePosInTrigger hotfix")
    if triggerEntity.IsValid == false then
      return CS.UnityEngine.Vector3(0, 0, 0)
    end
    local ed = CS.miHoYo.HYG.Entities.GameplayUtilities.Entities.GetEntityData(triggerEntity)
    if ed == nil or ed.SpatialZone == nil or ed.SpatialZone.Cuboid == nil then
      return triggerEntity.GetPosition()
    end
    return CS.miHoYo.HYG.Entities.GameplayUtilities.StarSea.GetAFreePosInTrigger(triggerEntity)
  end)
  self:fix_func_ex(CS.miHoYo.HYG.Performance.ExitCurrentPosition, "__Hotfix0_Invoke", function(this, callback)
    print("miHoYo.HYG.Performance.ExitCurrentPosition hotfix")
    if CS.miHoYo.HYG.Entities.GameplayUtilities.StarSea.IsCurrentSceneMaterialStar() then
      local player = CS.miHoYo.HYG.Entities.GameplayUtilities.Entities.GetPlayerEntity()
      local sittingTag = CS.CCBLEKEBHBC.LJLNBCGBLAC(StateTags.Tags.state_avatar_posture_sitting)
      local lyingTag = CS.CCBLEKEBHBC.LJLNBCGBLAC(StateTags.Tags.state_avatar_posture_lying)
      local isSitting = player:HasTag(sittingTag)
      local isLying = player:HasTag(lyingTag)
      print("miHoYo.HYG.Performance.ExitCurrentPosition hotfix isSitting :: " .. tostring(isSitting))
      print("miHoYo.HYG.Performance.ExitCurrentPosition hotfix isLying :: " .. tostring(isLying))
      if not isSitting and not isLying then
        this:Invoke(callback)
      else
        callback(0)
        CsStarSeaUtil.LeaveIsland()
      end
    else
      callback(0)
      NetHandlerIns.net_handler:Request_EnterMapReqReq(2)
    end
  end)
end

function Hotfix:fix_func(class_full, func_name, func)
  table.insert(self.func_list, {class_full = class_full, func_name = func_name})
  xlua.hotfix(class_full, func_name, func)
end

function Hotfix:fix_func_ex(class_full, func_name, func)
  assert(type(func_name) == "string" and type(func) == "function", "invalid argument: #2 string needed, #3 function needed!")
  
  local function func_after(...)
    xlua.hotfix(class_full, func_name, nil)
    local ret = {
      func(...)
    }
    xlua.hotfix(class_full, func_name, func_after)
    return table.unpack(ret)
  end
  
  table.insert(self.func_list, {class_full = class_full, func_name = func_name})
  xlua.hotfix(class_full, func_name, func_after)
end

function Hotfix:clear()
  for _, func in ipairs(self.func_list) do
    xlua.hotfix(func.class_full, func.func_name, nil)
  end
  self.func_list = {}
end

return Hotfix
