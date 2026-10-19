local M = G.Class("TouchJayStick", G.PlayerControlInputElementBase)
local base = G.PlayerControlInputElementBase

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  if not is_null(self._joy_stick) then
    self._joy_stick.uiCam = UIManagerInstance.ui_camera
  end
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

function M:update(deltaTime)
  base.update(self, deltaTime)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
end

function M:inner_refresh()
end

return M
