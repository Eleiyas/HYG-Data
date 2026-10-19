local M = G.Class("SetTimerTimeSetterPanel", G.UIPanel)
local base = G.UIPanel
local TimeUnit = {
  Hour = 1,
  Minute = 2,
  Second = 3
}

local function clamp(value, min_value, max_value)
  if value < min_value then
    return min_value
  end
  if max_value < value then
    return max_value
  end
  return value
end

function M:init()
  base.init(self)
  self._on_time_changed = nil
  self._on_confirm = nil
  self._cur_time_unit = TimeUnit.Hour
  self._time_value_map = {
    [TimeUnit.Hour] = 0,
    [TimeUnit.Minute] = 0,
    [TimeUnit.Second] = 0
  }
  self._time_options = {}
  self._time_scroller_inited = false
  self._is_switching_time_unit = false
  self._item_panel_map = {}
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self:_refresh_unit_texts()
  self:_switch_time_unit(TimeUnit.Hour)
end

function M:on_destroy()
  if not is_null(self._grid_scroll) then
    self._grid_scroll:Close()
  end
  self._item_panel_map = {}
  base.on_destroy(self)
end

function M:set_time(hour, minute, second)
  self._time_value_map[TimeUnit.Hour] = clamp(hour or 0, 0, 23)
  self._time_value_map[TimeUnit.Minute] = clamp(minute or 0, 0, 59)
  self._time_value_map[TimeUnit.Second] = clamp(second or 0, 0, 59)
  self:_refresh_unit_texts()
  self:_switch_time_unit(TimeUnit.Hour)
  self:_notify_time_changed()
end

function M:get_time_values()
  return self._time_value_map[TimeUnit.Hour], self._time_value_map[TimeUnit.Minute], self._time_value_map[TimeUnit.Second]
end

function M:set_on_time_changed(callback)
  self._on_time_changed = callback
end

function M:set_on_confirm(callback)
  self._on_confirm = callback
end

function M:_add_ui_listener()
  if not is_null(self._toggle_h) then
    self:bind_callback(self._toggle_h, function(is_on)
      if self._is_switching_time_unit or not is_on then
        return
      end
      self:_switch_time_unit(TimeUnit.Hour)
    end)
  end
  if not is_null(self._toggle_m) then
    self:bind_callback(self._toggle_m, function(is_on)
      if self._is_switching_time_unit or not is_on then
        return
      end
      self:_switch_time_unit(TimeUnit.Minute)
    end)
  end
  if not is_null(self._toggle_s) then
    self:bind_callback(self._toggle_s, function(is_on)
      if self._is_switching_time_unit or not is_on then
        return
      end
      self:_switch_time_unit(TimeUnit.Second)
    end)
  end
  if not is_null(self._btn_confirm) then
    self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm_click))
  end
end

function M:_switch_time_unit(unit)
  self._cur_time_unit = unit
  self:_refresh_time_toggle_state()
  self:_reload_time_items()
end

function M:_refresh_time_toggle_state()
  self._is_switching_time_unit = true
  if not is_null(self._toggle_h) then
    self._toggle_h.isOn = self._cur_time_unit == TimeUnit.Hour
  end
  if not is_null(self._toggle_m) then
    self._toggle_m.isOn = self._cur_time_unit == TimeUnit.Minute
  end
  if not is_null(self._toggle_s) then
    self._toggle_s.isOn = self._cur_time_unit == TimeUnit.Second
  end
  self._is_switching_time_unit = false
end

function M:_reload_time_items()
  if is_null(self._grid_scroll) then
    return
  end
  local max_value = self:_get_time_unit_max_value(self._cur_time_unit)
  self._grid_scroll:Init(pack(self, M._refresh_time_item), max_value + 1)
  self._grid_scroll:RefreshCurrent()
end

function M:_refresh_time_item(trans, index)
  local value = index
  local trans_id = trans:GetInstanceID()
  local item_panel = self._item_panel_map[trans_id]
  if not item_panel then
    item_panel = self:add_panel("UI/Interact/SetTimerTimeSetterItem", trans)
    item_panel:set_on_click(pack(self, M._on_time_item_clicked))
    self._item_panel_map[trans_id] = item_panel
  end
  item_panel:refresh(value, value == (self._time_value_map[self._cur_time_unit] or 0))
end

function M:_refresh_unit_texts()
  if not is_null(self._txt_h) then
    UIUtil.set_text(self._txt_h, string.format("%02d", self._time_value_map[TimeUnit.Hour] or 0))
  end
  if not is_null(self._txt_m) then
    UIUtil.set_text(self._txt_m, string.format("%02d", self._time_value_map[TimeUnit.Minute] or 0))
  end
  if not is_null(self._txt_s) then
    UIUtil.set_text(self._txt_s, string.format("%02d", self._time_value_map[TimeUnit.Second] or 0))
  end
end

function M:_on_btn_confirm_click()
  local hour, minute, second = self:get_time_values()
  print(string.format("[sirius debug] set timer confirm: %02d:%02d:%02d", hour, minute, second))
  if type(self._on_confirm) == "function" then
    self._on_confirm(hour, minute, second)
  end
end

function M:_on_time_item_clicked(value)
  value = clamp(value or 0, 0, self:_get_time_unit_max_value(self._cur_time_unit))
  if value == self._time_value_map[self._cur_time_unit] then
    return
  end
  self._time_value_map[self._cur_time_unit] = value
  self:_refresh_unit_texts()
  self:_notify_time_changed()
  if not is_null(self._grid_scroll) then
    self._grid_scroll:RefreshCurrent()
  end
end

function M:_notify_time_changed()
  if type(self._on_time_changed) == "function" then
    self._on_time_changed(self:get_time_values())
  end
end

function M:_get_time_unit_max_value(unit)
  if unit == TimeUnit.Hour then
    return 23
  end
  return 59
end

return M
