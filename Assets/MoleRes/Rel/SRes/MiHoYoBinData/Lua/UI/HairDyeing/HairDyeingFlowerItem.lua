local M = G.Class("HairDyeingFlowerItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._item_id = nil
  self._color_tags = nil
  self._selected = false
  self._on_click = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_select, pack(self, M._on_btn_select))
end

function M:refresh(data)
  self._item_id = data.item_id
  self._color_tags = data.color_tags or {}
  self._selected = data.selected == true
  UIUtil.set_active(self._img_icon, true)
  item_module:set_item_icon(self._img_icon, self._item_id)
  UIUtil.set_text(self._txt_num, tostring(data.num or 0))
  UIUtil.set_active(self._go_lack, (data.num or 0) <= 0)
  self:set_selected(self._selected)
end

function M:set_selected(is_select)
  self._selected = is_select
  self._state_group_select:SetState(is_select and 1 or 0)
end

function M:get_selected()
  return self._selected
end

function M:get_item_id()
  return self._item_id
end

function M:get_color_tags()
  return self._color_tags
end

function M:set_on_click(callback)
  self._on_click = callback
end

function M:_on_btn_select()
  if self._on_click then
    self._on_click(self._item_id)
  end
end

return M
