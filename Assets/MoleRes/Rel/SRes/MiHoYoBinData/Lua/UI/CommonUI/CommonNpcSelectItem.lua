local M = G.Class("CommonNpcSelectItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
end

function M:set_data(data, is_using)
  self._npc_id = data and data.id or nil
  self._state_empty:SetState(data and 1 or 0)
  self._state_use:SetState(is_using and 1 or 0)
  if data then
    UIUtil.set_image(self._img_icon, data.iconnamesmall, self:get_load_proxy())
  end
end

function M:get_npc_id()
  return self._npc_id
end

function M:get_toggle()
  return self._tog
end

return M
