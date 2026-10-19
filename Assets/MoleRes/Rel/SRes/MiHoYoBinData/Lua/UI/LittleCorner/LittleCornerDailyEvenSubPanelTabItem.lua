local M = G.Class("LittleCornerDailyEvenSubPanelTabItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._tab_cfg = nil
  self._panel = nil
  self._toggle = nil
  self._txt_unselect = nil
  self._txt_select = nil
  self._animator = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._toggle, pack(self, M._on_toggle_changed))
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:set_tab_on(is_on)
  if not_null(self._toggle) then
    self._toggle.isOnValue = is_on
  end
end

function M:_on_toggle_changed(is_on)
  if is_on and self._panel then
    self._panel:on_tab_selected(self._tab_cfg)
  end
end

function M:_refresh_ui()
  if is_null(self._tab_cfg) then
    return
  end
  local tab_name = self._tab_cfg.name
  UIUtil.set_text(self._txt_select, tab_name)
  UIUtil.set_text(self._txt_unselect, tab_name)
end

function M:force_refresh()
  local extra_data = self:get_extra_data()
  if extra_data then
    self._tab_cfg = extra_data.tab_cfg
    self._panel = extra_data.panel
  end
  self:_refresh_ui()
end

return M
