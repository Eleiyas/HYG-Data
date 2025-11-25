companion_star_module = companion_star_module or {}

function companion_star_module:add_event()
  companion_star_module:remove_event()
  self._events = {}
  self._events[EventID.LuaOpenStarMapDetail] = pack(self, companion_star_module._open_detail)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function companion_star_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function companion_star_module:_open_detail(npc_id)
  local star_data = self:find_star_data(npc_id)
  if star_data then
    CsNPCSphereLandManagerUtil.LoadMap(star_data.npcstarmapid, function()
      CsNPCSphereLandManagerUtil.ShowStar(star_data.npcstarid)
      self:set_detail_page_data(star_data, companion_star_module.open_detail_from.performance)
      UIManagerInstance:open("UI/CompanionStarDetail/StarMapDetailPage", {reset = true})
    end)
  else
    EventCenter.Broadcast(EventID.Performance.OnStarMapDetailEnd, 0)
  end
end

function companion_star_module:open_detail_by_npc_id(npc_id)
  local star_data = self:find_star_data(npc_id)
  if star_data then
    InputManagerIns:lock_input(input_lock_from.Common)
    CsNPCSphereLandManagerUtil.LoadMap(star_data.npcstarmapid, function()
      InputManagerIns:unlock_input(input_lock_from.Common)
      CsNPCSphereLandManagerUtil.ShowStar(star_data.npcstarid)
      self:set_detail_page_data(star_data, companion_star_module.open_detail_from.loading)
      UIManagerInstance:open("UI/CompanionStarDetail/StarMapDetailPage", {reset = true})
    end)
  end
end

function companion_star_module:open_detail()
  self:refresh_all_unlock_data()
  local detail_page_data = self:get_detail_page_data()
  local star_data
  if detail_page_data == nil or detail_page_data.star_data == nil then
    if not self.unlocked_npc or #self.unlocked_npc < 0 then
      return
    end
    star_data = self.unlocked_npc[1]
    if not star_data then
      Logger.LogWarning("星系进入失败，无法读取到配置")
      return
    end
    self:set_detail_page_data(star_data, companion_star_module.open_detail_from.loading)
  else
    star_data = detail_page_data.star_data
  end
  self:cache_camera_mask()
  self:_init_screen_setting_obj(function(success)
    if success then
      InputManagerIns:lock_input(input_lock_from.Common)
      CsNPCSphereLandManagerUtil.LoadMap(star_data.npcstarmapid, function()
        InputManagerIns:unlock_input(input_lock_from.Common)
        CsNPCSphereLandManagerUtil.ShowStar(star_data.npcstarid)
        UIManagerInstance:open("UI/CompanionStarDetail/StarMapDetailPage", {reset = true})
      end)
    end
  end)
end

return companion_star_module
