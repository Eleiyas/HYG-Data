local M = G.Class("CoffeeRpInviteTastePanel", G.UIPanel)
local base = G.UIPanel
local config = require("UI/CoffeeRpUI/CoffeeRpUIConfig")
local COUNTDOWN_TEXT_ID = "CoffeeRp_OrderPage_backup_txt_donate_title_21"
local TASTE_VALUE = config.TASTE_VALUE
local TOGGLE_CHILD_INDEX = config.TOGGLE_CHILD_INDEX

function M:on_create()
  base.on_create(self)
  self._countdown_suffix = UIUtil.get_text_by_id(COUNTDOWN_TEXT_ID)
  self._last_remain_time = nil
  self._sweet_toggles = {
    [TASTE_VALUE.HIGH] = self._tog_sweet_full,
    [TASTE_VALUE.NORMAL] = self._tog_sweet_half,
    [TASTE_VALUE.LOW] = self._tog_sweet_none
  }
  self._heat_toggles = {
    [TASTE_VALUE.HIGH] = self._tog_heat_hot,
    [TASTE_VALUE.NORMAL] = self._tog_heat_normal,
    [TASTE_VALUE.LOW] = self._tog_heat_cold
  }
  self:bind_callback(self._btn_confirm, function()
    if self._on_confirm then
      self._on_confirm()
    end
  end)
  self:bind_callback(self._btn_close, function()
    if self._on_close then
      self._on_close()
    end
  end)
  self:bind_callback(self._tog_sweet_full, function(is_on)
    self:_on_taste_toggle(is_on, true, TASTE_VALUE.HIGH)
  end)
  self:bind_callback(self._tog_sweet_half, function(is_on)
    self:_on_taste_toggle(is_on, true, TASTE_VALUE.NORMAL)
  end)
  self:bind_callback(self._tog_sweet_none, function(is_on)
    self:_on_taste_toggle(is_on, true, TASTE_VALUE.LOW)
  end)
  self:bind_callback(self._tog_heat_hot, function(is_on)
    self:_on_taste_toggle(is_on, false, TASTE_VALUE.HIGH)
  end)
  self:bind_callback(self._tog_heat_normal, function(is_on)
    self:_on_taste_toggle(is_on, false, TASTE_VALUE.NORMAL)
  end)
  self:bind_callback(self._tog_heat_cold, function(is_on)
    self:_on_taste_toggle(is_on, false, TASTE_VALUE.LOW)
  end)
end

function M:set_callbacks(callbacks)
  self._on_confirm = callbacks and callbacks.on_confirm
  self._on_close = callbacks and callbacks.on_close
  self._on_taste_change = callbacks and callbacks.on_taste_change
end

function M:refresh(model)
  self._last_remain_time = nil
  UIUtil.set_text(self._txt_player_name, model.player_name)
  UIUtil.set_text(self._txt_coffee_name, model.coffee_name)
  local has_icon = string.is_valid(model.coffee_icon_path)
  UIUtil.set_active(self._img_coffee_icon, has_icon)
  if has_icon then
    UIUtil.set_image(self._img_coffee_icon, model.coffee_icon_path, self:get_load_proxy())
  end
end

function M:set_taste(sweetness, temperature)
  self._is_refreshing_toggles = true
  self:_set_toggle(self._tog_sweet_full, sweetness == TASTE_VALUE.HIGH)
  self:_set_toggle(self._tog_sweet_half, sweetness == TASTE_VALUE.NORMAL)
  self:_set_toggle(self._tog_sweet_none, sweetness == TASTE_VALUE.LOW)
  self:_set_toggle(self._tog_heat_hot, temperature == TASTE_VALUE.HIGH)
  self:_set_toggle(self._tog_heat_normal, temperature == TASTE_VALUE.NORMAL)
  self:_set_toggle(self._tog_heat_cold, temperature == TASTE_VALUE.LOW)
  self._is_refreshing_toggles = false
end

function M:set_countdown(remain_time)
  if self._last_remain_time == remain_time then
    return
  end
  self._last_remain_time = remain_time
  UIUtil.set_text(self._txt_countdown, "(" .. tostring(remain_time) .. ") " .. self._countdown_suffix)
end

function M:_on_taste_toggle(is_on, is_sweet, value)
  local toggles = is_sweet and self._sweet_toggles or self._heat_toggles
  local toggle = toggles[value]
  self:_refresh_toggle_visual(toggle, is_on)
  if not is_on or self._is_refreshing_toggles then
    return
  end
  if self._on_taste_change then
    self._on_taste_change(is_sweet, value)
  end
end

function M:_set_toggle(toggle, is_on)
  toggle.isOn = is_on
  self:_refresh_toggle_visual(toggle, is_on)
end

function M:_refresh_toggle_visual(toggle, is_on)
  local trans = toggle.transform
  trans:GetChild(TOGGLE_CHILD_INDEX.OFF).gameObject:SetActive(not is_on)
  trans:GetChild(TOGGLE_CHILD_INDEX.ON).gameObject:SetActive(is_on)
end

return M
