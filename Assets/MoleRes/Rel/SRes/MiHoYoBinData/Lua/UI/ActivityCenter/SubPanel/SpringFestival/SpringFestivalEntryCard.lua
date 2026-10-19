local M = G.Class("SpringFestivalEntryCard", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._entry = nil
  self._card_state = nil
  self._applied_card_state = nil
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_entrance) then
    self:bind_callback(self._btn_entrance, pack(self, M._on_card_click))
  end
end

function M:refresh(entry)
  if entry == nil then
    self:set_active(false)
    return
  end
  self._entry = entry
  self._card_state = spring_festival_activity_module:get_card_state_by_entry(entry)
  self:set_active(true)
  self:_apply_card_state(self._card_state)
  self:_refresh_name()
  self:_refresh_icon()
  self:_refresh_red_dot()
end

function M:_refresh_red_dot()
  if is_null(self._redpoint) then
    return
  end
  local red_dot_type = RedPointType.None
  if self._entry ~= nil then
    red_dot_type = spring_festival_activity_module:get_card_red_dot_type(self._entry.key)
  end
  self._redpoint:ShowRedPoint(red_dot_type)
end

function M:_apply_card_state(card_state)
  if self._applied_card_state == card_state then
    return
  end
  self._applied_card_state = card_state
  if is_null(self._state_card) then
    Logger.LogWarning("[SpringFestivalEntryCard] _state_card is missing on prefab.")
    return
  end
  self._state_card:SetState(card_state)
end

function M:_refresh_name()
  if is_null(self._text_activityname) then
    return
  end
  local card_state_enum = spring_festival_activity_module.card_state
  if self._card_state == card_state_enum.locked_secret or self._card_state == card_state_enum.expired then
    return
  end
  if self._entry == nil then
    return
  end
  local name_text_id = spring_festival_activity_module:get_card_title_id(self._entry.key)
  if not string.is_valid(name_text_id) then
    return
  end
  UIUtil.set_text_by_id(self._text_activityname, name_text_id)
end

function M:_refresh_icon()
  if is_null(self._img_icon) or self._entry == nil then
    return
  end
  local icon_path = spring_festival_activity_module:get_card_icon_path(self._entry.key)
  if not string.is_valid(icon_path) then
    return
  end
  UIUtil.set_image(self._img_icon, icon_path, self:get_load_proxy())
end

function M:_on_card_click()
  if self._entry == nil then
    return
  end
  local card_state_enum = spring_festival_activity_module.card_state
  if self._card_state == card_state_enum.unlocked then
    spring_festival_activity_module:open_page(self._entry.key)
    return
  end
  if self._card_state == card_state_enum.expired then
    UIUtil.show_tips_by_text_id(spring_festival_activity_module.tips_text_id.ended)
    return
  end
  self:_show_not_open_tips()
end

function M:_show_not_open_tips()
  local phase_enum = spring_festival_activity_module.time_phase
  local phase, remain = spring_festival_activity_module:get_card_time_phase(self._entry)
  local text_id = spring_festival_activity_module.tips_text_id.not_open
  if phase == phase_enum.before_start and 0 < remain then
    UIUtil.show_tips_by_text_id(text_id, UIUtil.format_left_time(remain))
    return
  end
  UIUtil.show_tips_by_text_id(text_id, "")
end

function M:get_page_key()
  return self._entry ~= nil and self._entry.key or 0
end

return M
