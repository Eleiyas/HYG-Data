local M = G.Class("WorldEditorDecalTypeItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._button, pack(self, self._on_click))
end

function M:_on_click()
  if self._extra_data then
    self.holder:on_select_decal_type(self._extra_data.decalsetid)
  end
end

function M:refresh_view()
  self:set_active(self._extra_data ~= nil)
  if not self._extra_data then
    return
  end
  local cfg = self._extra_data
  UIUtil.set_image(self._img_type_dynamic, cfg.icon, self:get_load_proxy())
  UIUtil.set_text(self._txt_type_dynamic, cfg.name or "")
  local count = self.holder:get_decal_count_for_set(cfg.decalsetid)
  UIUtil.set_text(self._txt_num_dynamic, tostring(count))
end

return M
