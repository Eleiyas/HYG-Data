local M = G.Class("BottomTip", G.PlayerControlInputElementBase)
local base = G.PlayerControlInputElementBase

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

return M
