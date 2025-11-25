local M = G.Class("TutorialPanelBase", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
  if self._cur_data and self._cur_data.onEnd then
    self._cur_data.onEnd()
  end
  self._cur_data = nil
  if self.on_panel_disable then
    self.on_panel_disable()
  end
  self.on_panel_disable = nil
end

function M:register_events()
  base.register_events(self)
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:update(deltaTime)
  if not self.is_active then
    return
  end
  base.update(self, deltaTime)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
end

function M:refresh(data)
  self._cur_data = data
end

function M:close_panel(data, on_panel_disable)
  self.on_panel_disable = on_panel_disable
  self:set_active(false)
end

function M:force_close(on_panel_disable)
  self.on_panel_disable = on_panel_disable
  self.is_active = false
  self._cur_data = nil
  self.on_panel_disable = nil
  self.binder:ClearAllLuaCallBack()
  UIUtil.set_active(self.game_obj, false)
end

return M
