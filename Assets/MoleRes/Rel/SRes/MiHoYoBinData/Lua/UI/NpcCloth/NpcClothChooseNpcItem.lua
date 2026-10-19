local M = G.Class("NpcClothChooseNpcItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._is_refreshing_toggle = false
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._tog_npc_item) then
    self:bind_callback(self._tog_npc_item, pack(self, M._on_toggle_changed))
  end
end

function M:refresh(data)
  data = data or {}
  self._npc_id = data.npc_id or 0
  self._select_callback = data.on_select
  self:set_active(self._npc_id > 0)
  if self._npc_id <= 0 then
    return
  end
  self:_refresh_visual(data)
  self:_refresh_toggle(data.is_selected == true)
end

function M:_refresh_visual(data)
  local icon_target = self._img_icon
  if is_null(icon_target) then
    icon_target = self._img_icon_npc
  end
  if not is_null(icon_target) and string.is_valid(data.icon) then
    UIUtil.set_image(icon_target, data.icon, self:get_load_proxy())
  end
  UIUtil.set_text(self._txt_shape, data.shape_code)
  if not is_null(self._state_group_selected) then
    self._state_group_selected:SetState(data.is_selected == true and 1 or 0)
  end
end

function M:_refresh_toggle(is_selected)
  if is_null(self._tog_npc_item) then
    return
  end
  self._is_refreshing_toggle = true
  if self._tog_npc_item.SetIsOnWithoutNotify then
    self._tog_npc_item:SetIsOnWithoutNotify(is_selected == true)
  else
    self._tog_npc_item.isOn = is_selected == true
  end
  self._is_refreshing_toggle = false
end

function M:_on_toggle_changed(is_on)
  if self._is_refreshing_toggle or is_on ~= true then
    return
  end
  if self._select_callback then
    self._select_callback(self._npc_id)
  end
end

return M
