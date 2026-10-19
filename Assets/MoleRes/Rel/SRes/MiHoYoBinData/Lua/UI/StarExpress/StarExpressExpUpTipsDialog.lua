local M = G.Class("StarExpressExpUpTipsDialog", G.UIWindow)
local base = G.UIWindow
local slider_anim_duration = 0.5
local auto_close_duration = 2

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/StarExpress/StarExpressExpUpTipsDialog"
  self.config.type = EUIType.Tip
  self.config.input_penetrate = true
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  self:_refresh(self:get_extra_data())
end

function M:on_disable()
  base.on_disable(self)
  self:_kill_slider_tween()
  CoolDownManagerIns:unregister(self)
  if self._level_up_to ~= nil then
    local level = self._level_up_to
    self._level_up_to = nil
    star_express_module:open_category_unlock_dialog(level)
  end
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:_refresh(data)
  self._level_up_to = nil
  if data == nil then
    return
  end
  local rider_level = data.rider_level or 0
  local total_order_count = data.total_order_count or 0
  local level_up_required = star_express_module:get_rider_level_required_orders(rider_level)
  local is_level_up = 0 < rider_level and level_up_required == total_order_count
  local show_level = is_level_up and rider_level - 1 or rider_level
  UIUtil.set_text(self._txt_num, TextMapFormatUtil.FormatInteger(show_level))
  local min_value = star_express_module:get_rider_level_required_orders(show_level) or 0
  local next_required = star_express_module:get_rider_level_required_orders(show_level + 1)
  local max_value = next_required or math.max(total_order_count, min_value + 1)
  self._slider.minValue = min_value
  self._slider.maxValue = max_value
  local to_value = math.min(total_order_count, max_value)
  local from_value = math.max(to_value - 1, min_value)
  UIUtil.set_text_by_id(self._txt_info, "StarExpress_Hud_Upgrade")
  self:_do_slider(from_value, to_value, function()
    if is_level_up then
      UIUtil.set_text(self._txt_num, TextMapFormatUtil.FormatInteger(rider_level))
      self._level_up_to = rider_level
      UIUtil.set_text_by_id(self._txt_info, "StarExpress_Hud_UpgradeFull")
    end
    self:_start_auto_close()
  end)
end

function M:_do_slider(from_value, to_value, callback)
  self:_kill_slider_tween()
  self._slider.value = from_value
  self._dt_slider = self._slider:DOValue(to_value, slider_anim_duration):SetEase(Ease.Linear):OnComplete(function()
    if callback ~= nil then
      callback()
    end
  end)
end

function M:_kill_slider_tween()
  if self._dt_slider == nil then
    return
  end
  self._dt_slider:OnComplete(nil)
  self._dt_slider:Kill()
  self._dt_slider = nil
end

function M:_start_auto_close()
  CoolDownManagerIns:register(self, auto_close_duration, function()
    self:_close()
  end)
end

function M:_close()
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_self()
end

return M
