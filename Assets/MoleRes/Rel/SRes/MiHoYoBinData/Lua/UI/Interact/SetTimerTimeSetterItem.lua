local M = G.Class("SetTimerTimeSetterItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._value = 0
  self._on_click = nil
  self._is_refreshing_toggle = false
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._toggle) then
    self:bind_callback(self._toggle, function(is_on)
      if self._is_refreshing_toggle or not is_on then
        return
      end
      if type(self._on_click) == "function" then
        self._on_click(self._value)
      end
    end)
  end
end

function M:set_on_click(callback)
  self._on_click = callback
end

function M:refresh(value, is_selected)
  self._value = value or 0
  if not is_null(self._txt) then
    UIUtil.set_text(self._txt, string.format("%02d", self._value))
  end
  if not is_null(self._toggle) then
    self._is_refreshing_toggle = true
    self._toggle.isOn = is_selected == true
    self._is_refreshing_toggle = false
  end
end

return M
