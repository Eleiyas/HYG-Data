local M = G.Class("NewYearSprintEntryCard", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._entry = nil
  self._is_memory_shelf_locked = false
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_card) then
    self:bind_callback(self._btn_card, pack(self, M._on_card_click))
  end
end

function M:register_events()
  base.register_events(self)
end

function M:refresh(entry)
  if entry == nil then
    self:set_active(false)
    return
  end
  self._entry = entry
  self:set_active(true)
  if not is_null(self._ui_state_frame_type) then
    local frame_type = new_year_sprint_activity_module:get_frame_type(entry)
    if frame_type ~= nil then
      self._ui_state_frame_type:SetState(frame_type)
    end
  end
  self:_refresh_title_and_image()
  self:_refresh_static_texts()
  self:refresh_tracker_state()
  self:refresh_time()
end

function M:refresh_time()
  local entry = self._entry
  if entry == nil then
    return
  end
  local card_state = new_year_sprint_activity_module:get_card_state(entry)
  if self._is_memory_shelf_locked and card_state ~= new_year_sprint_activity_module.card_state.ended then
    card_state = new_year_sprint_activity_module.card_state.locked
  end
  if not is_null(self._ui_state_activity) then
    self._ui_state_activity:SetState(card_state)
  end
  self:_refresh_remain_text(card_state)
  self:refresh_red_dot()
end

function M:refresh_tracker_state()
  local entry = self._entry
  if entry == nil then
    return
  end
  local module = new_year_sprint_activity_module
  self._is_memory_shelf_locked = module:is_memory_shelf_unlock_required(entry)
  local card_state = module:get_card_state(entry)
  if self._is_memory_shelf_locked and card_state ~= module.card_state.ended then
    card_state = module.card_state.locked
  end
  if not is_null(self._ui_state_activity) then
    self._ui_state_activity:SetState(card_state)
  end
  if not is_null(self._ui_state_progress) then
    self._ui_state_progress:SetState(module:get_card_progress_state(entry))
  end
  self:_refresh_locked_texts(card_state)
end

function M:refresh_red_dot()
  if is_null(self._redpoint) then
    return
  end
  local red_dot_type = RedPointType.None
  if self._entry ~= nil then
    red_dot_type = new_year_sprint_activity_module:get_card_red_dot_type(self._entry)
  end
  self._redpoint:ShowRedPoint(red_dot_type)
end

function M:_refresh_title_and_image()
  local entry = self._entry
  if not is_null(self._txt_activitytitle) then
    local title_id = new_year_sprint_activity_module:get_card_title_id(entry)
    if string.is_valid(title_id) then
      UIUtil.set_text_by_id(self._txt_activitytitle, title_id)
    end
  end
  if not is_null(self._img_activity) then
    local image_path = new_year_sprint_activity_module:get_card_background_path(entry)
    if string.is_valid(image_path) then
      UIUtil.set_image(self._img_activity, image_path, self:get_load_proxy())
    end
  end
end

function M:_refresh_static_texts()
  local entry = self._entry
  if entry == nil then
    return
  end
  if not is_null(self._txt_opentime) then
    UIUtil.set_text(self._txt_opentime, new_year_sprint_activity_module:get_card_open_time_text(entry))
  end
end

function M:_refresh_locked_texts(card_state)
  if card_state ~= new_year_sprint_activity_module.card_state.locked then
    return
  end
  local show_memory_shelf_tips = new_year_sprint_activity_module:is_memory_shelf_unlock_required(self._entry)
  if not is_null(self._txt_opentime) then
    UIUtil.set_active(self._txt_opentime, not show_memory_shelf_tips)
  end
  if not is_null(self._txt_opentips) then
    UIUtil.set_active(self._txt_opentips, true)
    UIUtil.set_text_by_id(self._txt_opentips, new_year_sprint_activity_module:get_card_locked_tips_text_id(self._entry))
  end
end

function M:_refresh_remain_text(card_state)
  if card_state ~= new_year_sprint_activity_module.card_state.timed_running then
    return
  end
  if is_null(self._txt_remaintime) then
    return
  end
  UIUtil.set_text(self._txt_remaintime, new_year_sprint_activity_module:get_card_remain_text(self._entry))
end

function M:_on_card_click()
  new_year_sprint_activity_module:on_card_click(self._entry)
end

function M:get_activity_id()
  return new_year_sprint_activity_module:get_card_activity_id(self._entry)
end

return M
