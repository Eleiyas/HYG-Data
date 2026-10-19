local M = G.Class("FamilyCommentCommentItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._index = 0
  self._data = nil
end

function M:bind_input_action()
  base.bind_input_action(self)
  if not is_null(self._btn_item) then
    self:bind_callback(self._btn_item, pack(self, M._on_btn_item_click))
  end
  if not is_null(self._toggle_select) then
    self:bind_callback(self._toggle_select, pack(self, M._on_toggle_select_changed))
  end
end

function M:_on_btn_item_click()
  if self.holder and self.holder:is_edit_mode() then
    self._toggle_select.isOn = not self._toggle_select.isOn
    return
  end
  if self.holder and self.holder.on_comment_item_click then
    self.holder:on_comment_item_click(self._index)
  end
end

function M:_on_toggle_select_changed(is_on)
  if self.holder and self.holder.on_comment_item_select then
    self.holder:on_comment_item_select(self._data and self._data.Guid, is_on)
  end
end

function M:set_read(guid)
  if self._data and self._data.Guid == guid and not is_null(self._red_point) then
    self._red_point:ShowRedPoint(RedPointType.None)
  end
end

function M:set_edit_mode(edit_mode, selected)
  if not is_null(self._toggle_select) then
    UIUtil.set_active(self._toggle_select, edit_mode)
    self._toggle_select:SetIsOnWithoutNotify(selected == true)
  end
end

function M:set_data(index, data, is_owner, edit_mode, tags, selected)
  self._index = index
  self._data = data
  if not data then
    UIUtil.set_active(self.trans, false)
    return
  end
  UIUtil.set_active(self.trans, true)
  UIUtil.set_text(self._txt_name, data.PlayerNickname or "")
  local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(data.Timestamp or 0)
  UIUtil.set_text(self._txt_time, TextMapFormatUtil.FormatDateYMD(date_time))
  local content = data.Content or ""
  if string.is_valid(content) then
    UIUtil.set_active(self._txt_content, true)
    UIUtil.set_text(self._txt_content, content)
  else
    UIUtil.set_active(self._txt_content, false)
  end
  local tags_text = table.concat(tags or {}, " ")
  if string.is_valid(tags_text) then
    UIUtil.set_active(self._txt_tags, true)
    UIUtil.set_text(self._txt_tags, tags_text)
  else
    UIUtil.set_active(self._txt_tags, false)
  end
  local head_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), data.AvatarId or 0)
  UIUtil.set_active(self._img_avatar, head_cfg ~= nil)
  if head_cfg then
    UIUtil.set_image(self._img_avatar, head_cfg.respath, self:get_load_proxy())
  end
  self:set_edit_mode(edit_mode, selected)
  if not is_null(self._red_point) then
    local is_read = data.IsRead or family_comment_module:is_comment_locally_read(data.Guid)
    self._red_point:ShowRedPoint(not (not is_owner or is_read) and RedPointType.NewRp or RedPointType.None)
  end
end

return M
