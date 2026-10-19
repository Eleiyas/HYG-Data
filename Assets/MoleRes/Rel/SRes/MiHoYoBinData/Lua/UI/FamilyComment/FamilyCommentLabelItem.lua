local M = G.Class("FamilyCommentLabelItem", G.UIBase)
local base = G.UIBase
local label_style = {
  [0] = {42, 50},
  [1] = {36, 42},
  [2] = {26, 36}
}
local label_font_type = {
  [0] = LanguageFontType.Default,
  [1] = LanguageFontType.Default,
  [2] = LanguageFontType.ThinFont
}

function M:init()
  base.init(self)
  self._index = 0
  self._tag = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._tog_check, pack(self, M._on_toggle_changed))
end

function M:set_icon_type(icon_type)
  self._icon_state:SetState(icon_type)
  local style = label_style[icon_type]
  if style then
    self._tet_label.enableAutoSizing = true
    self._tet_label.fontSizeMin = style[1]
    self._tet_label.fontSizeMax = style[2]
  end
  local font_type = label_font_type[icon_type]
  if font_type and self._tet_label.FontType ~= font_type then
    self._tet_label.FontType = font_type
    self._tet_label.CurrLanType = CS.Proto.LanguageType.LanguageNone
    self._tet_label:CheckTextByLanType()
  end
end

function M:set_data(index, tag, selected, edit_mode)
  self._index = index
  self._tag = tag
  self:set_active(tag ~= nil)
  if not tag then
    return
  end
  self._tet_label.richText = true
  UIUtil.set_text(self._tet_label, family_comment_module:get_social_tag_rich_text(tag.id) or tag.text or "")
  self._tog_check:SetIsOnWithoutNotify(selected == true)
  self._ui_state:SetState(edit_mode and 0 or 1)
end

function M:get_tag()
  return self._tag
end

function M:_on_toggle_changed(is_on)
  if self.holder and self.holder.on_label_item_selection_changed then
    self.holder:on_label_item_selection_changed(self._tag, is_on)
  end
end

return M
