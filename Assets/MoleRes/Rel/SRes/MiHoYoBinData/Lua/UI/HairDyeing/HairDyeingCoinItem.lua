local M = G.Class("HairDyeingCoinItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._item_id = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_item, pack(self, M._on_btn_item))
end

function M:refresh(item_id)
  self._item_id = item_id
  if item_id and 0 < item_id then
    item_module:set_item_icon(self._img_icon_coin, item_id, nil, nil, self:get_load_proxy())
  end
  self:refresh_num()
end

function M:refresh_num()
  local num = self._item_id and hair_dyeing_module:get_material_num(self._item_id) or 0
  UIUtil.set_text(self._txt_num, tostring(num))
end

function M:get_item_id()
  return self._item_id
end

function M:_on_btn_item()
  if self._item_id and self._item_id > 0 then
    item_module:open_item_info_dialog(self._item_id, hair_dyeing_module:get_material_num(self._item_id))
  end
end

return M
