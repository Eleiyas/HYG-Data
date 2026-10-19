local M = G.Class("SpringFestival7DaysPage", "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestivalPageBase")
local base = G.SpringFestivalPageBase
local TOGGLE_PANEL_CLASS = "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestival7DaysTogglePanel"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_7DaysPage"
  self._page_key = spring_festival_activity_module.page_key.seven_days
  self._toggle_panels = {}
  self._selected_day = 0
end

function M:on_create()
  base.on_create(self)
  self:_create_toggles()
  if not is_null(self._btn_activity_introduction) then
    self:bind_callback(self._btn_activity_introduction, pack(self, M._on_btn_activity_introduction_click))
  end
end

function M:refresh()
  base.refresh(self)
  self:_refresh_toggles()
  if self._selected_day > 0 then
    self:_refresh_day_content(self._selected_day)
  end
end

function M:on_time_tick()
  base.on_time_tick(self)
  self:_refresh_toggles()
  if self._selected_day > 0 then
    self:_refresh_unlock_time(self._selected_day)
  end
end

function M:_create_toggles()
  if is_null(self._layout_list) then
    Logger.LogWarning("[SpringFestival7DaysPage] _layout_list is missing on prefab.")
    return
  end
  local count = spring_festival_activity_module:get_seven_days_day_count()
  for day = 1, count do
    local obj = self._layout_list:AddItem(0)
    if not_null(obj) then
      local panel = self:add_panel(TOGGLE_PANEL_CLASS, obj)
      panel:set_data(day, self)
      self._toggle_panels[day] = panel
    end
  end
end

function M:_refresh_toggles()
  for day = 1, #self._toggle_panels do
    local panel = self._toggle_panels[day]
    if panel ~= nil then
      panel:refresh()
    end
  end
end

function M:_on_toggle_selected(day)
  if day == nil or day < 1 then
    return
  end
  self._selected_day = day
  local module = spring_festival_activity_module
  if module:is_seven_days_day_unlocked(day) then
    module:set_seven_days_day_viewed(day)
    local panel = self._toggle_panels[day]
    if panel ~= nil then
      panel:refresh()
    end
  end
  self:_refresh_day_content(day)
end

function M:_refresh_day_content(day)
  local module = spring_festival_activity_module
  if not is_null(self._state_drawlock) then
    self._state_drawlock:SetState(module:get_seven_days_drawlock_state(day))
  end
  if not is_null(self._img_subbg) and module:is_seven_days_day_unlocked(day) then
    local image_path = module:get_seven_days_image_path(day)
    if image_path ~= nil then
      UIUtil.set_image(self._img_subbg, image_path, self:get_load_proxy())
    end
  end
  if not is_null(self._text_specialname) then
    local text_id = module:get_seven_days_special_name_text_id(day)
    if text_id ~= nil then
      UIUtil.set_text_by_id(self._text_specialname, text_id)
    else
      UIUtil.set_text(self._text_specialname, "")
    end
  end
  if not is_null(self._text_title) then
    UIUtil.set_text(self._text_title, module:get_page_task_title(self._page_key, day))
  end
  self:_refresh_desc()
  self:_refresh_unlock_time(day)
  if not is_null(self._state_tracking) then
    self._state_tracking:SetState(module:get_seven_days_tracking_state(day))
  end
  self:refresh_reward_list(self._layout_itemreward)
end

function M:_refresh_unlock_time(day)
  if is_null(self._txt_unlocktime) then
    return
  end
  local module = spring_festival_activity_module
  if module:is_seven_days_day_unlocked(day) then
    UIUtil.set_text(self._txt_unlocktime, "")
    return
  end
  local remain = module:get_seven_days_day_unlock_remain(day)
  if 0 < remain then
    UIUtil.set_text_by_id(self._txt_unlocktime, "SpringFestival_Activity7Day_TimeLeft", UIUtil.format_left_time(remain))
  else
    UIUtil.set_text_by_id(self._txt_unlocktime, "SpringFestival_Activity7Day_TaskLeft")
  end
end

function M:_on_btn_activity_introduction_click()
  if self._selected_day == 0 then
    return
  end
  local guide_window_id = spring_festival_activity_module:get_seven_days_introduction_id(self._selected_day)
  if guide_window_id <= 0 then
    Logger.LogWarning("[SpringFestival7DaysPage] guide_window_id not configured, day = " .. tostring(self._selected_day))
    return
  end
  tutorial_module:_open_tutorial_handbook_dialog_with_window_id_list({guide_window_id})
end

function M:get_tracking_target()
  if self._selected_day == 0 then
    return nil
  end
  local module = spring_festival_activity_module
  local task_id = module:get_seven_days_task_id(self._selected_day)
  return module:make_task_tracking_target(task_id)
end

function M:get_tracking_state()
  if self._selected_day == 0 then
    return spring_festival_activity_module.seven_days_tracking_state.locked
  end
  return spring_festival_activity_module:get_seven_days_tracking_state(self._selected_day)
end

function M:get_current_image_id()
  return self._selected_day
end

function M:get_desc_text()
  return spring_festival_activity_module:get_page_task_desc(self._page_key, self._selected_day)
end

function M:on_enable()
  base.on_enable(self)
  local default_day = spring_festival_activity_module:get_seven_days_default_selected_day()
  local panel = self._toggle_panels[default_day]
  if panel ~= nil then
    panel:set_toggle_on(true)
    self:_on_toggle_selected(default_day)
  end
end

return M
