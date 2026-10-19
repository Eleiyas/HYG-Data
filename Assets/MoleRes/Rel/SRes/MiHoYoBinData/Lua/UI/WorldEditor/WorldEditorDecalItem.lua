local M = G.Class("WorldEditorDecalItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._toggle, pack(self, self._on_toggle_click))
end

function M:on_disable()
  base.on_disable(self)
  self._toggle:SetIsOnWithoutNotify(false)
end

function M:_on_toggle_click(is_on)
  UIUtil.set_active(self._trans_block, is_on)
  if is_on and self._extra_data then
    self.holder:set_select_decal_id(self._extra_data.decalid)
  end
end

function M:refresh_view()
  self:set_active(self._extra_data ~= nil)
  if not self._extra_data then
    return
  end
  local cfg = self._extra_data
  UIUtil.set_image(self._img_icon, cfg.icon, self:get_load_proxy())
  UIUtil.set_image(self._img_icon_select, cfg.icon, self:get_load_proxy())
  local is_selected = self._extra_data.decalid == self.holder:get_select_decal_id()
  self._toggle:SetIsOnWithoutNotify(is_selected)
  UIUtil.set_active(self._trans_block, is_selected)
end

return M
