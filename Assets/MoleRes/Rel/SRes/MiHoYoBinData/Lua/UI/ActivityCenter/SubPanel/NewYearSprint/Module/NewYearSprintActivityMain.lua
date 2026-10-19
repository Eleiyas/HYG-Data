new_year_sprint_activity_module = new_year_sprint_activity_module or {}
local TRACKING_NAVIGATION_RESOLVER_KEY = "new_year_sprint"

function new_year_sprint_activity_module:register_tracking_navigation()
  activity_center_module:register_tracking_navigation_resolver(TRACKING_NAVIGATION_RESOLVER_KEY, function(source_activity_id)
    return self:resolve_tracking_navigation(source_activity_id)
  end)
end

function new_year_sprint_activity_module:unregister_tracking_navigation()
  activity_center_module:unregister_tracking_navigation_resolver(TRACKING_NAVIGATION_RESOLVER_KEY)
end

function new_year_sprint_activity_module:resolve_tracking_navigation(source_activity_id)
  local entry = self:get_card_entry_by_activity_id(source_activity_id)
  if entry == nil then
    return nil
  end
  return {
    host_activity_id = self.main_activity_id,
    open_content = function()
      self:on_card_click(entry)
    end
  }
end

function new_year_sprint_activity_module:on_card_click(entry)
  if entry == nil then
    return
  end
  self:mark_slot_read(self:get_card_red_dot_slot(entry))
  UIManagerInstance:open(self.dialog_class_path, entry)
end

function new_year_sprint_activity_module:open_hot_selling()
  if not self:is_main_activity_running() then
    return
  end
  local main_activity_id = self.main_activity_id
  local main_tab_id = tvshop_module:get_main_tab_id_by_activity_id(main_activity_id)
  if main_tab_id == nil then
    Logger.LogWarning("[NewYearSprint] no BTVShopMainTabCfg matches activity " .. tostring(main_activity_id))
    return
  end
  self:mark_slot_read(self.red_dot_slot.hot_selling)
  UIManagerInstance:open("UI/TVShopping/TVShoppingNewPage", {
    tab_type = tvshop_module.TabsType.TvShopTabsLuomi,
    enter_by_ad = false,
    main_tab_id = main_tab_id
  })
end

new_year_sprint_activity_module._last_reported_slot_mask = nil

function new_year_sprint_activity_module:on_tracker_update_notify(tracker_id)
  if tonumber(tracker_id) ~= self.memory_shelf_special.start_tracker_id then
    return
  end
  self:refresh_memory_shelf_unlock_state()
  self:refresh_red_dot()
end

function new_year_sprint_activity_module:refresh_red_dot()
  local data = self:get_main_activity_data()
  if data == nil then
    return
  end
  local mask = self:build_unlocked_slot_mask()
  data:SetUnlockedSlotMask(mask)
  if self._last_reported_slot_mask == mask then
    return
  end
  self._last_reported_slot_mask = mask
  self:notify_red_dot_dirty()
end

function new_year_sprint_activity_module:mark_slot_read(slot_id)
  if slot_id == nil then
    return
  end
  local data = self:get_main_activity_data()
  if data == nil then
    return
  end
  if not data:IsSlotUnlocked(slot_id) then
    return
  end
  data:MarkSlotRead(slot_id)
  self:notify_red_dot_dirty()
end

function new_year_sprint_activity_module:notify_red_dot_dirty()
  lua_event_module:send_event(lua_event_module.event_type.refresh_activity_center_red_point)
end

return new_year_sprint_activity_module
