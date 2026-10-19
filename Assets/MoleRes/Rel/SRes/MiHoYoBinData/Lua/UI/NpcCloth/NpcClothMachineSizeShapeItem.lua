local M = G.Class("NpcClothMachineSizeShapeItem", G.UIBase)
local base = G.UIBase
local disable_state = {normal = 0, disabled = 1}

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._tog_size_shape_item, pack(self, M._on_toggle_changed))
end

function M:refresh(data, context)
  self._data = data
  self._context = context or {}
  if is_null(data) then
    self:set_active(false)
    return
  end
  self:set_active(true)
  self:_refresh_icon(data.npc_id)
  self:_refresh_state()
end

function M:_refresh_icon(npc_id)
  local npc_cfg = npc_id and ExcelDataUtil.get_value(typeof(BNpcCfg), npc_id) or nil
  local icon = npc_cfg and (npc_cfg.iconnamesmall or npc_cfg.icon) or nil
  if is_null(self._img_icon_dynamic) then
    return
  end
  local has_icon = string.is_valid(icon)
  UIUtil.set_active(self._img_icon_dynamic, has_icon)
  if has_icon then
    UIUtil.set_image(self._img_icon_dynamic, icon, self:get_load_proxy())
  end
end

function M:_refresh_state()
  local is_disabled = self._data and self._data.disabled == true
  local state_group_disable = self._state_group_disable or self._state_group_diasble
  if state_group_disable then
    state_group_disable:SetState(is_disabled and disable_state.disabled or disable_state.normal)
  end
  self._tog_size_shape_item:SetIsOnWithoutNotify(self._data.shape == self._context.current_shape)
end

function M:_on_toggle_changed(is_on)
  if is_on == false or not self._data then
    return
  end
  if self._data.disabled == true then
    self:_show_disabled_tip()
    self:_refresh_state()
    return
  end
  if self._context and self._context.on_click_shape then
    self._context.on_click_shape(self._data.shape, self._data.npc_id, self._data)
  end
end

function M:_show_disabled_tip()
  local text_id = "NpcCloth_Machine_SizeShape_NotWearable_Tips"
  UIUtil.show_tips_by_text_id(text_id)
end

return M
