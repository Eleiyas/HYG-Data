local M = G.Class("FortuneWheelMultiSliderPanel", G.UIPanel)
local base = G.UIPanel
local multi_options = {
  1,
  3,
  5
}
local multi_text_id = {
  "FortuneWheeNewPage_Text_1",
  "FortuneWheeNewPage_Text_2",
  "FortuneWheeNewPage_Text_3"
}

function M:init()
  base.init(self)
  self._cur_index = 1
  self._on_value_changed = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_ui()
end

function M:_add_ui_listener()
  self._slider.minValue = 1
  self._slider.maxValue = #multi_options
  self._slider.wholeNumbers = true
  self:bind_callback(self._slider, pack(self, M._on_slider_value_changed))
  self:bind_callback(self._btn_add, pack(self, M._on_btn_add_click))
  self:bind_callback(self._btn_minus, pack(self, M._on_btn_minus_click))
end

function M:set_value_changed_callback(callback)
  self._on_value_changed = callback
end

function M:get_multiplier()
  return multi_options[self._cur_index] or 1
end

function M:_on_btn_add_click()
  if self._cur_index < #multi_options then
    self._cur_index = self._cur_index + 1
    self:_refresh_ui()
    self:_notify_changed()
  end
end

function M:_on_btn_minus_click()
  if self._cur_index > 1 then
    self._cur_index = self._cur_index - 1
    self:_refresh_ui()
    self:_notify_changed()
  end
end

function M:_on_slider_value_changed(value)
  local index = math.floor(value + 0.5)
  index = math.max(1, math.min(#multi_options, index))
  if index ~= self._cur_index then
    self._cur_index = index
    self:_refresh_ui()
    self:_notify_changed()
  end
  self._state_group_multi:SetState(index - 1)
end

function M:_refresh_ui()
  UIUtil.set_text_by_id(self._txt_num, multi_text_id[self._cur_index])
  self._slider.value = self._cur_index
  self._btn_add.interactable = self._cur_index < #multi_options
  self._btn_minus.interactable = self._cur_index > 1
end

function M:_notify_changed()
  if self._on_value_changed then
    self._on_value_changed(self:get_multiplier())
  end
end

return M
