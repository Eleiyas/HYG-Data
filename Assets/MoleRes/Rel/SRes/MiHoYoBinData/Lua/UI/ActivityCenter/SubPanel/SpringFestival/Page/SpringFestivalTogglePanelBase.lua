local M = G.Class("SpringFestivalTogglePanelBase", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._slot_index = 0
  self._holder = nil
  self._is_auto_setting = false
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._tog) then
    self:bind_callback(self._tog, function(is_on)
      if self._is_auto_setting then
        return
      end
      if is_on and self._holder ~= nil then
        self:on_selected(self._slot_index)
      end
    end)
  end
end

function M:set_data(index, holder)
  self._slot_index = index
  self._holder = holder
  self:refresh()
end

function M:set_toggle_on(is_on)
  if is_null(self._tog) then
    return
  end
  self._is_auto_setting = true
  self._tog.isOnValue = is_on
  self._is_auto_setting = false
end

function M:on_selected(index)
end

function M:refresh()
end

return M
