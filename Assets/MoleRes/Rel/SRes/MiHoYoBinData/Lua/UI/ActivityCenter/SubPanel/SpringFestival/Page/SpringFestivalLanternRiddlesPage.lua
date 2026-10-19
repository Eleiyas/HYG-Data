local M = G.Class("SpringFestivalLanternRiddlesPage", "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestivalPageBase")
local base = G.SpringFestivalPageBase
local TOGGLE_PANEL_CLASS = "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestivalLanternRiddlesTogglePanel"
local MISSION_PANEL_CLASS = "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestivalLanternMissionPanel"
local COMMON_REWARD_DIALOG_PATH = "UI/CommonUI/CommonRewardDialog"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_LanternRiddlesPage"
  self._page_key = spring_festival_activity_module.page_key.lantern_riddles
  self._toggle_panels = {}
  self._selected_tab = 0
  self._mission_panels = {}
  self._pending_claim_data = nil
end

function M:on_create()
  base.on_create(self)
  self:_create_toggles()
  if not is_null(self._btn_go) then
    self:bind_callback(self._btn_go, pack(self, M._on_btn_go_click))
  end
end

function M:_on_btn_go_click()
  self:_on_btn_track_click()
end

function M:on_enable()
  base.on_enable(self)
  self._pending_claim_data = nil
  spring_festival_activity_module:mark_lantern_card_tip_read()
  riddle_module:request_activity_info_if_needed()
  local default_tab = 1
  local panel = self._toggle_panels[default_tab]
  if panel ~= nil then
    panel:set_toggle_on(true)
    self:on_toggle_selected(default_tab)
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnRiddleActivityInfoChange, pack(self, M._on_riddle_activity_info_change))
end

function M:refresh()
  base.refresh(self)
  self:_refresh_toggles()
  self:_refresh_lantern_time()
  self:_refresh_tab_content()
end

function M:on_time_tick()
  base.on_time_tick(self)
  self:_refresh_lantern_time()
end

function M:_create_toggles()
  if is_null(self._layout_toglist) then
    Logger.LogWarning("[SpringFestivalLanternRiddlesPage] _layout_toglist is missing on prefab.")
    return
  end
  local entries = spring_festival_activity_module.lantern_tab_entries
  for index = 1, #entries do
    local obj = self._layout_toglist:AddItem(0)
    if not_null(obj) then
      local panel = self:add_panel(TOGGLE_PANEL_CLASS, obj)
      panel:set_data(index, self)
      self._toggle_panels[index] = panel
    end
  end
end

function M:_refresh_toggles()
  for index = 1, #self._toggle_panels do
    local panel = self._toggle_panels[index]
    if panel ~= nil then
      panel:refresh()
    end
  end
end

function M:get_tab_title_text_id(index)
  local entry = spring_festival_activity_module.lantern_tab_entries[index]
  return entry ~= nil and entry.title_text_id or nil
end

function M:on_toggle_selected(index)
  if index == nil or spring_festival_activity_module.lantern_tab_entries[index] == nil then
    return
  end
  self._selected_tab = index
  spring_festival_activity_module:mark_lantern_tab_read(index)
  self:_refresh_toggles()
  self:_apply_activity_time(self._text_timeremain, self._trans_timeremain)
  self:_refresh_tracking()
  self:_refresh_tab_content()
end

function M:_refresh_tab_content()
  local module = spring_festival_activity_module
  local image_id = self:get_current_image_id()
  if not is_null(self._text_maintitle) then
    if self:get_tracking_state() == spring_festival_activity_module.lantern_tracking_state.go_riddles then
      UIUtil.set_text(self._text_maintitle, "")
    else
      UIUtil.set_text(self._text_maintitle, module:get_page_task_title(self._page_key, image_id))
    end
  end
  self:_refresh_desc()
  if not is_null(self._text_daunow) then
    local cur_active, max_active = riddle_module:get_active_value()
    if 0 < max_active and max_active < cur_active then
      cur_active = max_active
    end
    UIUtil.set_text_by_id(self._text_daunow, spring_festival_activity_module.lantern_active_value_text_id, string.format("%d/%d", cur_active, max_active))
  end
  self:refresh_reward_list(self._layout_itemreward)
  self:_refresh_reward_visible()
  self:_refresh_mission_list()
end

function M:_refresh_reward_visible()
  if is_null(self._trans_reward) then
    return
  end
  local item_ids = spring_festival_activity_module:get_page_reward_item_ids(self._page_key, self:get_current_image_id())
  UIUtil.set_active(self._trans_reward, 0 < #item_ids)
end

function M:_refresh_mission_list()
  if is_null(self._layout_missionlist) then
    return
  end
  local reward_list = riddle_module:get_stage_reward_list()
  for index = 1, #reward_list do
    local panel = self._mission_panels[index]
    if panel == nil then
      local obj = self._layout_missionlist:AddItem(0)
      if not_null(obj) then
        panel = self:add_panel(MISSION_PANEL_CLASS, obj)
        self._mission_panels[index] = panel
      end
    end
    if panel ~= nil then
      panel:set_active(true)
      panel:refresh(reward_list[index], pack(self, M._on_mission_claim))
    end
  end
  for index = #reward_list + 1, #self._mission_panels do
    self._mission_panels[index]:set_active(false)
  end
end

function M:_on_mission_claim(stage)
  local stage_num = tonumber(stage) or 0
  if stage_num <= 0 then
    return
  end
  local data = riddle_module:find_stage_reward_by_stage(stage_num)
  if data == nil then
    return
  end
  if riddle_module:get_stage_reward_state(data) ~= riddle_module.stage_reward_state.can_take then
    return
  end
  local stages, items = riddle_module:request_take_all_stage_rewards()
  if #stages == 0 then
    return
  end
  self._pending_claim_data = {stages = stages, items = items}
end

function M:_on_riddle_activity_info_change()
  if not self:is_in_show_state() then
    return
  end
  self:_refresh_tab_content()
  self:_refresh_mission_list()
  self:_refresh_toggles()
  self:_try_show_claim_reward_dialog()
end

function M:_try_show_claim_reward_dialog()
  local pending = self._pending_claim_data
  if pending == nil then
    return
  end
  for _, stage in ipairs(pending.stages) do
    local data = riddle_module:find_stage_reward_by_stage(stage)
    if data == nil then
      return
    end
    if riddle_module:get_stage_reward_state(data) ~= riddle_module.stage_reward_state.taken then
      return
    end
  end
  self._pending_claim_data = nil
  if pending.items == nil or #pending.items == 0 then
    return
  end
  UIManagerInstance:open(COMMON_REWARD_DIALOG_PATH, {
    items = pending.items
  })
end

function M:get_desc_text()
  return spring_festival_activity_module:get_page_task_desc(self._page_key, self:get_current_image_id())
end

function M:_refresh_lantern_time()
  if is_null(self._text_fireworktime) then
    return
  end
  local module = spring_festival_activity_module
  local entry = module.corner_activity_by_tracking_id[module.lantern_time_tracking_id]
  if entry == nil then
    Logger.LogWarning("[SpringFestivalLanternRiddlesPage] lantern_time_tracking_id not in corner_activity_entries: " .. tostring(module.lantern_time_tracking_id))
    return
  end
  local phase_enum = module.time_phase
  local text_id = module.lantern_time_text_id
  local visible_seconds = module.corner_countdown_visible_seconds
  local phase, remain = module:get_corner_activity_phase(entry)
  local has_time_text = true
  if phase == phase_enum.before_start and 0 < remain and visible_seconds >= remain then
    UIUtil.set_text_by_id(self._text_fireworktime, text_id.remain, UIUtil.format_left_time(remain))
  elseif phase == phase_enum.running then
    UIUtil.set_text_by_id(self._text_fireworktime, text_id.ready)
  else
    UIUtil.set_text(self._text_fireworktime, "")
    has_time_text = false
  end
  if not is_null(self._trans_imglantern) then
    UIUtil.set_active(self._trans_imglantern, has_time_text)
  end
end

function M:get_tracking_target()
  if self._selected_tab == 0 then
    return nil
  end
  return spring_festival_activity_module:get_lantern_tracking_target(self._selected_tab)
end

function M:get_tracking_state()
  if self._selected_tab == 0 then
    return spring_festival_activity_module.lantern_tracking_state.can_track
  end
  return spring_festival_activity_module:get_lantern_tracking_state(self._selected_tab)
end

function M:get_current_image_id()
  return self._selected_tab
end

function M:get_time_remain_activity_id()
  local activity_id = spring_festival_activity_module:get_lantern_time_remain_activity_id(self._selected_tab)
  if activity_id ~= 0 then
    return activity_id
  end
  return base.get_time_remain_activity_id(self)
end

function M:_refresh_tracking()
  base._refresh_tracking(self)
  self:_refresh_go_button_text()
  self:_refresh_cant_exchange()
  self:_refresh_find_desc()
end

function M:_refresh_go_button_text()
  if is_null(self._txt_btngo) or self:get_tracking_state() ~= spring_festival_activity_module.lantern_tracking_state.go_riddles then
    return
  end
  local target = self:get_tracking_target()
  if spring_festival_activity_module:is_tracking(target) then
    UIUtil.set_text_by_id(self._txt_btngo, spring_festival_activity_module.tracking_text_id[spring_festival_activity_module.tracking_state.tracking])
    return
  end
  local text = activity_center_module:get_tracking_button_text(target)
  if string.is_valid(text) then
    UIUtil.set_text(self._txt_btngo, text)
  end
end

function M:_refresh_cant_exchange()
  if is_null(self._text_cantexchange) then
    return
  end
  local text_id = spring_festival_activity_module:get_lantern_cant_exchange_text_id(self._selected_tab)
  if string.is_valid(text_id) then
    UIUtil.set_text_by_id(self._text_cantexchange, text_id)
  else
    UIUtil.set_text(self._text_cantexchange, "")
  end
end

function M:_refresh_find_desc()
  if is_null(self._text_finddesc) then
    return
  end
  if self:get_tracking_state() == spring_festival_activity_module.lantern_tracking_state.go_riddles then
    UIUtil.set_text_by_id(self._text_finddesc, "SpringFestival_ActivityLantern_FindDesc")
  else
    UIUtil.set_text(self._text_finddesc, "")
  end
end

return M
