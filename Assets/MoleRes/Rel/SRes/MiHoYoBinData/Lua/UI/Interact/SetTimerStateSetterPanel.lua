local M = G.Class("SetTimerStateSetterPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._on_modify_click = nil
  self._on_switch_changed = nil
  self._is_refreshing_switch = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:_add_ui_listener()
  if not is_null(self._btn_modify) then
    self:bind_callback(self._btn_modify, function()
      if type(self._on_modify_click) == "function" then
        self._on_modify_click()
      end
    end)
  end
  if not is_null(self._tog_switch) then
    self:bind_callback(self._tog_switch, function(is_on)
      if self._is_refreshing_switch then
        return
      end
      if type(self._on_switch_changed) == "function" then
        self._on_switch_changed(is_on == true)
      end
    end)
  end
end

function M:set_on_modify_click(callback)
  self._on_modify_click = callback
end

function M:set_on_switch_changed(callback)
  self._on_switch_changed = callback
end

function M:set_time(hour, minute, second)
  if not is_null(self._txt_h) then
    UIUtil.set_text(self._txt_h, string.format("%02d", hour or 0))
  end
  if not is_null(self._txt_m) then
    UIUtil.set_text(self._txt_m, string.format("%02d", minute or 0))
  end
  if not is_null(self._txt_s) then
    UIUtil.set_text(self._txt_s, string.format("%02d", second or 0))
  end
end

function M:set_switch(is_on)
  if is_null(self._tog_switch) then
    return
  end
  self._is_refreshing_switch = true
  self._tog_switch.isOn = is_on == true
  self._is_refreshing_switch = false
end

return M
