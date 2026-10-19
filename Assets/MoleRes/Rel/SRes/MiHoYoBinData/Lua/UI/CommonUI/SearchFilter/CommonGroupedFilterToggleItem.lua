local M = G.Class("CommonGroupedFilterToggleItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._is_destroyed = false
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._toggle, pack(self, M._on_toggle_change))
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if self._is_destroyed or is_null(self.rect_trans) then
      return
    end
    self:_rebuild_item_layout()
  end)
end

function M:on_destroy()
  self._is_destroyed = true
  base.on_destroy(self)
end

function M:refresh(args)
  args = args or {}
  self._item_key = args.key
  self._change_callback = args.on_change
  self._swatch_color = args.color
  self:set_active(true)
  local label = args.label or ""
  local count_text = tostring(args.count or 0)
  self:_set_text_if_bound(self._txt_type_1, label, args.label_text_id)
  self:_set_text_if_bound(self._txt_type_2, label, args.label_text_id)
  self:_set_text_if_bound(self._txt_num_1, count_text)
  self:_set_text_if_bound(self._txt_num_2, count_text)
  self:_refresh_icon(self._img_icon, args.icon_path)
  self:_refresh_type_style(args.use_color_state == true, args.style_state_id)
  self:_refresh_color_swatch(self._swatch_color)
  self:_refresh_toggle_without_notify(args.is_on == true)
end

function M:reapply_swatch_color()
  self:_refresh_color_swatch(self._swatch_color)
end

function M:_on_toggle_change(is_on)
  is_on = is_on == true
  if self._change_callback then
    self._change_callback(self._item_key, is_on)
  end
end

function M:_refresh_toggle_without_notify(is_on)
  if is_null(self._toggle) then
    return
  end
  if self._toggle.SetIsOnWithoutNotify ~= nil then
    self._toggle:SetIsOnWithoutNotify(is_on == true)
  else
    self._toggle.isOnValue = is_on == true
  end
end

function M:_refresh_type_style(use_color_state, style_state_id)
  if not_null(self._state_group) then
    self._state_group:SetState(use_color_state and 1 or 0)
  end
  if use_color_state and style_state_id ~= nil and not_null(self._state_color_group) then
    self._state_color_group:SetState(style_state_id)
  end
end

function M:_refresh_icon(icon_target, icon_path)
  if is_null(icon_target) then
    return
  end
  if string.is_valid(icon_path) then
    UIUtil.set_image(icon_target, icon_path, self:get_load_proxy())
    return
  end
  icon_target.sprite = nil
end

function M:_refresh_color_swatch(color)
  if is_null(self._img_color) or color == nil then
    return
  end
  UIUtil.set_image_color(self._img_color, color)
end

function M:_set_text_if_bound(text_target, text, text_id)
  if not_null(text_target) then
    if string.is_valid(text_id) then
      UIUtil.set_text_by_id(text_target, text_id)
    else
      UIUtil.set_text(text_target, text)
    end
  end
end

function M:_get_content_layout_root()
  local text_target = self._txt_type_2 or self._txt_type_1 or self._txt_num_2 or self._txt_num_1
  if is_null(text_target) or is_null(text_target.transform) then
    return nil
  end
  return text_target.transform.parent
end

function M:_rebuild_item_layout()
  local layout_root = self:_get_content_layout_root()
  if not_null(layout_root) then
    LayoutRebuilder.ForceRebuildLayoutImmediate(layout_root)
  end
  if not_null(self.rect_trans) then
    LayoutRebuilder.ForceRebuildLayoutImmediate(self.rect_trans)
  end
end

return M
