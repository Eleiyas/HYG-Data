local M = G.Class("CurioEmporiumEntranceTagItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:_add_btn_listener()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_btn_listener()
  self:bind_callback(self._tog, pack(self, M._on_toggle))
end

function M:_on_toggle(is_on)
  if self._on_toggle_click and is_on then
    self._on_toggle_click(self.cfg.tagid)
  end
end

function M:refresh(cfg, on_toggle_click)
  if not cfg then
    return
  end
  self.cfg = cfg
  self._on_toggle_click = on_toggle_click
  UIUtil.set_image(self._img_select_icon, cfg.icon, self:get_load_proxy())
  UIUtil.set_image(self._img_unselect_icon, cfg.icon, self:get_load_proxy())
  self:refresh_red_point()
end

function M:refresh_red_point()
  if is_null(self._red_point) or not self.cfg then
    return
  end
  self._red_point:ShowRedPoint(curio_emporium_module:get_tag_red_point_type(self.cfg.tagid))
end

function M:set_selected()
  if self._tog.isOn then
    self:_on_toggle(true)
  else
    self._tog.isOn = true
  end
end

return M
