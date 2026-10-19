local M = G.Class("FortuneWheelItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._index = 0
  self._is_selected = false
end

function M:on_create()
  base.on_create(self)
end

function M:set_selected(is_selected)
  self._is_selected = is_selected
  self._state_group:SetState(is_selected and 1 or 0)
end

function M:set_index(index)
  self._index = index
end

function M:get_index()
  return self._index
end

function M:get_btn()
  return self._btn
end

return M
