local M = G.Class("SpringFestivalPageBase", G.UIWindow)
local base = G.UIWindow
local TIME_REFRESH_INTERVAL_SEC = 1

function M:init()
  base.init(self)
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  self._activity_id = 0
  self._page_key = 0
  self._time_acc = 0
  self._time_ended_notified = false
  self._applied_bg_path = nil
end

function M:set_extra_data(data)
  base.set_extra_data(self, data)
  if data == nil then
    return
  end
  self._activity_id = data.activity_id or self._activity_id
  if self._page_key == 0 then
    self._page_key = data.page_key or 0
  end
  self._pending_close_guid = data.pending_close_guid
end

function M:on_create()
  base.on_create(self)
  self:_bind_callbacks()
end

function M:_mark_card_read()
  if self._page_key == 0 then
    return
  end
  spring_festival_activity_module:mark_slot_read(spring_festival_activity_module:get_card_red_dot_slot(self._page_key))
end

function M:on_enable()
  base.on_enable(self)
  self._time_ended_notified = false
  self:_mark_card_read()
  activity_center_module:reset_activity_end_dialog_flag(spring_festival_activity_module.activity_end_gate_key)
  local pending_guid = self._pending_close_guid
  if pending_guid ~= nil then
    self._pending_close_guid = nil
    UIManagerInstance:close(pending_guid)
  end
  self:refresh()
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  self._time_acc = self._time_acc + deltaTime
  if self._time_acc >= TIME_REFRESH_INTERVAL_SEC then
    self._time_acc = self._time_acc - TIME_REFRESH_INTERVAL_SEC
    self:on_time_tick()
  end
end

function M:on_destroy()
  activity_center_module:release_activity_end_refresh_gate(spring_festival_activity_module.activity_end_gate_key)
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnActivityDataChanged, function(activity_id)
    if activity_id == self._activity_id then
      self:refresh()
    end
  end)
  self:add_evt_listener(EventID.OnActivityRemoved, function(activity_id)
    self:_on_activity_removed(activity_id)
  end)
  self:add_evt_listener(EventID.LuaTrackingChange, function()
    self:_refresh_tracking()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  if not is_null(self._btn_back) then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_back)
  end
end

function M:_bind_callbacks()
  if not is_null(self._btn_back) then
    self:bind_callback(self._btn_back, pack(self, M._on_btn_back_click))
  end
  if not is_null(self._btn_pre) then
    self:bind_callback(self._btn_pre, pack(self, M._on_btn_pre_click))
  end
  if not is_null(self._btn_next) then
    self:bind_callback(self._btn_next, pack(self, M._on_btn_next_click))
  end
  if not is_null(self._btn_introduction) then
    self:bind_callback(self._btn_introduction, pack(self, M._on_btn_introduction_click))
  end
  if not is_null(self._btn_track) then
    self:bind_callback(self._btn_track, pack(self, M._on_btn_track_click))
  end
end

function M:_on_btn_back_click()
  self:close_self()
end

function M:_on_btn_pre_click()
  local target_key = spring_festival_activity_module:get_prev_page_key(self._page_key)
  if target_key == nil then
    return
  end
  spring_festival_activity_module:switch_page(self, target_key)
end

function M:_on_btn_next_click()
  local target_key = spring_festival_activity_module:get_next_page_key(self._page_key)
  if target_key == nil then
    return
  end
  spring_festival_activity_module:switch_page(self, target_key)
end

function M:_on_btn_introduction_click()
  self:open_introduction_dialog()
end

function M:open_introduction_dialog()
  local introduction_id = self:get_introduction_id()
  if introduction_id <= 0 then
    Logger.LogWarning("[SpringFestivalPage] introduction_id not configured, page_key = " .. tostring(self._page_key))
    return
  end
  common_ui_module:show_introduction_dialog(introduction_id)
end

function M:get_page_key()
  return self._page_key
end

function M:get_activity_id()
  return self._activity_id
end

function M:get_activity_data()
  if self._activity_id == 0 then
    return nil
  end
  return activity_center_module:get_activity_by_id(self._activity_id)
end

function M:get_introduction_id()
  return activity_center_module:get_page_guide_window_id(self._page_key)
end

function M:get_desc_text_id()
  return activity_center_module:get_sub_page_desc_id(self._page_key, self:get_current_image_id())
end

function M:get_current_image_id()
  return 0
end

function M:refresh_reward_list(layout)
  if is_null(layout) then
    Logger.LogWarning("[SpringFestivalPage] reward layout is missing on prefab, page_key = " .. tostring(self._page_key))
    return
  end
  self._reward_items = self._reward_items or {}
  local item_ids = spring_festival_activity_module:get_page_reward_item_ids(self._page_key, self:get_current_image_id())
  for index = 1, #item_ids do
    local panel = self._reward_items[index]
    if panel == nil then
      local obj = layout:AddItem(0)
      if not_null(obj) then
        panel = self:add_panel(item_module.item_v2_panel_cls_name, obj)
        self._reward_items[index] = panel
      end
    end
    if panel ~= nil then
      local item_id = item_ids[index]
      panel:set_item_data(item_id, nil)
      panel:bind_item_info_btn(item_id)
      panel:set_active(true)
    end
  end
  for index = #item_ids + 1, #self._reward_items do
    self._reward_items[index]:set_active(false)
  end
end

function M:refresh()
  self:_refresh_background()
  self:_refresh_switch_buttons()
  self:_refresh_introduction_button()
  self:_refresh_desc()
  self:on_time_tick()
end

function M:_refresh_background()
  if is_null(self._img_bg) then
    return
  end
  local path = activity_center_module:get_page_background_path(self._page_key)
  if path == nil or path == self._applied_bg_path then
    return
  end
  self._applied_bg_path = path
  UIUtil.set_image(self._img_bg, path, self:get_load_proxy())
end

function M:_refresh_introduction_button()
  if is_null(self._btn_introduction) then
    return
  end
  UIUtil.set_active(self._btn_introduction, self:get_introduction_id() > 0)
end

function M:_refresh_desc()
  if is_null(self._text_desc) then
    return
  end
  local desc_text = self:get_desc_text()
  if desc_text ~= nil then
    UIUtil.set_text(self._text_desc, desc_text)
    return
  end
  local desc_text_id = self:get_desc_text_id()
  if not string.is_valid(desc_text_id) then
    UIUtil.set_text(self._text_desc, "")
    return
  end
  UIUtil.set_text_by_id(self._text_desc, desc_text_id)
end

function M:get_desc_text()
  return nil
end

function M:_refresh_switch_buttons()
  local has_target = spring_festival_activity_module:get_next_page_key(self._page_key) ~= nil
  if not is_null(self._btn_pre) then
    UIUtil.set_active(self._btn_pre, has_target)
  end
  if not is_null(self._btn_next) then
    UIUtil.set_active(self._btn_next, has_target)
  end
end

function M:on_time_tick()
  self:_apply_activity_time(self._text_timeremain, self._trans_timeremain)
  self:_refresh_tracking()
  if not self._time_ended_notified then
    local phase = spring_festival_activity_module:get_time_phase(self._activity_id)
    if phase == spring_festival_activity_module.time_phase.ended then
      self._time_ended_notified = true
      self:on_activity_time_ended()
    end
  end
end

function M:on_activity_time_ended()
  Logger.Log("[SpringFestivalPage] activity time ended, activity_id = " .. tostring(self._activity_id))
end

function M:get_time_remain_activity_id()
  local activity_id = spring_festival_activity_module:get_page_time_remain_activity_id(self._page_key, self:get_current_image_id())
  if activity_id ~= 0 then
    return activity_id
  end
  return self._activity_id
end

function M:_apply_activity_time(txt, trans)
  if is_null(txt) then
    return
  end
  local range = activity_center_module:get_activity_time_range(self:get_time_remain_activity_id())
  if range == nil or range.end_time == 0 then
    if not is_null(trans) then
      UIUtil.set_active(trans, false)
    end
    return
  end
  local now = TimeUtil.ServerUtcTimeSeconds
  local remain = now < range.end_time and range.end_time - now or 0
  self:_apply_time_remain(txt, trans, remain)
end

function M:_apply_time_remain(txt, trans, remain_seconds)
  if is_null(txt) then
    return
  end
  if remain_seconds == nil or remain_seconds <= 0 then
    if not is_null(trans) then
      UIUtil.set_active(trans, false)
    end
    return
  end
  if not is_null(trans) then
    UIUtil.set_active(trans, true)
  end
  UIUtil.set_text(txt, UIUtil.format_left_time(remain_seconds))
end

function M:_on_activity_removed(activity_id)
  if not spring_festival_activity_module:is_page_schedule_activity(self._page_key, activity_id) then
    return
  end
  if not spring_festival_activity_module:is_main_activity_ended() and activity_id ~= spring_festival_activity_module:get_page_end_activity_id(self._page_key) then
    return
  end
  self:_show_activity_end_dialog()
end

function M:_show_activity_end_dialog()
  activity_center_module:show_activity_end_dialog(function()
    UIManagerInstance:close_page_with_dialogs_above(self)
    if spring_festival_activity_module:is_main_activity_ended() then
      activity_center_module:request_refresh_list()
    end
  end, {
    key = spring_festival_activity_module.activity_end_gate_key,
    text_id = spring_festival_activity_module.activity_end_dialog_text_id
  })
end

function M:get_tracking_target()
  return nil
end

function M:is_tracking_target()
  return spring_festival_activity_module:is_tracking(self:get_tracking_target())
end

function M:_on_btn_track_click()
  local target = self:get_tracking_target()
  if target == nil then
    Logger.LogWarning("[SpringFestivalPageBase] tracking target is unavailable, page_key = " .. tostring(self._page_key))
    self:_refresh_tracking()
    return
  end
  activity_center_module:toggle_tracking(target)
  self:_refresh_tracking()
end

function M:get_tracking_state()
  local state_enum = spring_festival_activity_module.tracking_state
  return self:is_tracking_target() and state_enum.tracking or state_enum.can_track
end

function M:_refresh_tracking()
  if is_null(self._state_tracking) then
    return
  end
  local state = self:get_tracking_state()
  self._state_tracking:SetState(state)
  local text
  if state == spring_festival_activity_module.tracking_state.can_track then
    text = activity_center_module:get_tracking_button_text(self:get_tracking_target())
  end
  if string.is_valid(text) and not is_null(self._txt_tracking) then
    UIUtil.set_text(self._txt_tracking, text)
    return
  end
  local text_id = spring_festival_activity_module.tracking_text_id[state]
  if string.is_valid(text_id) and not is_null(self._txt_tracking) then
    UIUtil.set_text_by_id(self._txt_tracking, text_id)
  end
end

return M
