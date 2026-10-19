local M = G.Class("ActivitySpringFestivalPanel", "UI/ActivityCenter/SubPanel/ActivityBasePanel")
local base = G.ActivityBasePanel

function M:init()
  base.init(self)
  self._entry_cards = {}
  self._corner_tracking_id = 0
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_prewarm) then
    self:bind_callback(self._btn_prewarm, pack(self, M._on_btn_prewarm_click))
  end
  if not is_null(self._btn_calendar) then
    self:bind_callback(self._btn_calendar, pack(self, M._on_btn_calendar_click))
  end
  if not is_null(self._btn_goactivity) then
    self:bind_callback(self._btn_goactivity, pack(self, M._on_btn_goactivity_click))
  end
end

function M:update_time_remain()
  base.update_time_remain(self)
  if not self:is_in_show_state() then
    return
  end
  self:_refresh_corner_button(false)
end

function M:on_enable()
  base.on_enable(self)
  spring_festival_activity_module:refresh_red_dot()
  self:_mark_corner_activity_read()
  self:refresh()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnActivityListChanged, function()
    self:refresh()
  end)
  self:add_evt_listener(EventID.LuaTrackingChange, pack(self, M._on_tracking_change))
end

function M:refresh()
  base.refresh(self)
  self:_refresh_prewarm_button()
  self:_refresh_corner_button(true)
  self:_refresh_entry_cards()
end

function M:_refresh_prewarm_button()
  if is_null(self._btn_prewarm) then
    return
  end
  UIUtil.set_active(self._btn_prewarm, spring_festival_activity_module:is_prewarm_button_visible())
end

function M:_on_btn_prewarm_click()
  spring_festival_activity_module:open_prewarm_task_memo()
end

function M:_refresh_corner_button(force_refresh_tracking_text)
  local state = spring_festival_activity_module:get_corner_state()
  local tracking_changed = self._corner_tracking_id ~= state.tracking_id
  self._corner_tracking_id = state.tracking_id
  if not is_null(self._state_activity) then
    self._state_activity:SetState(state.state)
  else
    Logger.LogWarning("[ActivitySpringFestivalPanel] _state_activity is missing on prefab.")
  end
  if force_refresh_tracking_text or tracking_changed then
    self:_refresh_corner_tracking_text(state.tracking_id)
  end
  self:_refresh_corner_time_remain(state)
end

function M:_on_tracking_change()
  if not self:is_in_show_state() then
    return
  end
  self:_refresh_corner_tracking_text(self._corner_tracking_id)
end

function M:_refresh_corner_tracking_text(tracking_id)
  if is_null(self._txt_goactivity) then
    return
  end
  local target = activity_center_module:make_feature_tracking_target(tracking_id)
  local state_enum = spring_festival_activity_module.tracking_state
  local tracking_state = activity_center_module:is_tracking(target) and state_enum.tracking or state_enum.can_track
  if tracking_state == state_enum.can_track then
    local text = activity_center_module:get_tracking_button_text(target)
    if string.is_valid(text) then
      UIUtil.set_text(self._txt_goactivity, text)
      return
    end
  end
  local text_id = spring_festival_activity_module.tracking_text_id[tracking_state]
  if string.is_valid(text_id) then
    UIUtil.set_text_by_id(self._txt_goactivity, text_id)
  end
end

function M:_mark_corner_activity_read()
  local module = spring_festival_activity_module
  for corner_index = 1, #module.corner_activity_entries do
    local slot_id = module:get_corner_current_red_dot_slot(corner_index)
    if slot_id ~= nil and module:has_slot_red_dot(slot_id) then
      module:mark_slot_read(slot_id)
    end
  end
end

function M:_refresh_corner_time_remain(state)
  local state_enum = spring_festival_activity_module.corner_state
  local visible_seconds = spring_festival_activity_module.corner_countdown_visible_seconds
  local is_calendar = state.state == state_enum.calendar
  local has_countdown = state.remain > 0
  if not is_null(self._trans_calendartime) then
    local show = is_calendar and has_countdown and visible_seconds >= state.remain and string.is_valid(state.text_id)
    UIUtil.set_active(self._trans_calendartime, show)
    if show and not is_null(self._text_calendar_timeremain) then
      UIUtil.set_text_by_id(self._text_calendar_timeremain, state.text_id, UIUtil.format_left_time(state.remain))
    end
  end
  if not is_null(self._trans_activitytime) then
    local show = not is_calendar and has_countdown
    UIUtil.set_active(self._trans_activitytime, show)
    if show and not is_null(self._text_goactivity_timeremain) then
      UIUtil.set_text(self._text_goactivity_timeremain, UIUtil.format_left_time(state.remain))
    end
  end
end

function M:_on_btn_calendar_click()
  spring_festival_activity_module:open_calendar_dialog()
end

function M:_on_btn_goactivity_click()
  spring_festival_activity_module:go_activity(self._corner_tracking_id or 0)
end

function M:_get_activity_end_gate_key()
  return spring_festival_activity_module.activity_end_gate_key
end

function M:get_activity_end_dialog_text_id()
  return spring_festival_activity_module.activity_end_dialog_text_id
end

function M:_refresh_entry_cards()
  if is_null(self._layout_list) then
    Logger.LogWarning("[ActivitySpringFestivalPanel] _layout_list is missing on prefab.")
    return
  end
  local entries = spring_festival_activity_module.page_entries
  for i = 1, #entries do
    local cls = self._entry_cards[i]
    if cls == nil then
      local obj = self._layout_list:AddItem(0)
      if not_null(obj) then
        cls = self:add_panel(spring_festival_activity_module.entry_card_class_path, obj)
        self._entry_cards[i] = cls
      end
    end
    if cls ~= nil then
      cls:refresh(entries[i])
    end
  end
end

return M
