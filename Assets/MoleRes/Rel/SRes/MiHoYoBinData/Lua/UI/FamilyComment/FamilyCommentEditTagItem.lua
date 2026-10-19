local M = G.Class("FamilyCommentEditTagItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._index = 0
  self._is_selected = false
  self._is_delete_visible = false
end

function M:on_create()
  base.on_create(self)
  self._txt_tag.richText = false
  self:bind_callback(self._btn_tag, pack(self, M._on_btn_click))
  if not is_null(self._btn_delete) then
    self:bind_callback(self._btn_delete, pack(self, M._on_btn_delete_click))
  end
end

function M:set_data(index, tag, is_selected, is_delete_visible)
  self._index = index
  self._is_selected = is_selected
  self._is_delete_visible = is_selected and is_delete_visible == true
  self:set_active(tag ~= nil)
  if not tag then
    return
  end
  if not is_null(self._btn_delete) then
    UIUtil.set_active(self._btn_delete, self._is_delete_visible)
  end
  UIUtil.set_text(self._txt_tag, tag.text or "")
  local tag_color = ColorUtil.get_color(tag.color)
  self._txt_tag.color = tag_color
  self._img_bg.color = Color(tag_color.r, tag_color.g, tag_color.b, self._img_bg.color.a)
end

function M:_on_btn_click()
  if self.holder and self.holder.on_edit_tag_item_click then
    self.holder:on_edit_tag_item_click(self._index, self._is_selected)
  end
end

function M:_on_btn_delete_click()
  if self.holder and self.holder.on_edit_tag_item_delete_click then
    self.holder:on_edit_tag_item_delete_click(self._index)
  end
end

return M
