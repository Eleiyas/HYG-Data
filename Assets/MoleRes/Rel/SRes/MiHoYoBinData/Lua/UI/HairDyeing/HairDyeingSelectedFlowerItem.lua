local M = G.Class("HairDyeingSelectedFlowerItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._item_id = nil
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(data)
  self._item_id = data.item_id
  self._ui_state_group:SetState(1)
  if self._item_id and self._item_id > 0 then
    item_module:set_item_icon(self._img_icon, self._item_id, nil, nil, self:get_load_proxy())
  end
  if not is_null(self._img_icon_color) then
    UIUtil.set_active(self._img_icon_color, false)
  end
  if not_null(self._txt_num) then
    UIUtil.set_active(self._txt_num, true)
    UIUtil.set_text(self._txt_num, tostring(data.num or 0))
  end
end

function M:get_item_id()
  return self._item_id
end

return M
