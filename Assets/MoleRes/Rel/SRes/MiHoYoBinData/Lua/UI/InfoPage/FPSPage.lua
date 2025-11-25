local M = G.Class("FPSPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/InfoPage/GMFPSPage"
  self.config.type = EUIType.Top
  self._is_close = false
end

function M:on_create()
  base.on_create(self)
  self:_add_btn_listener()
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_btn_listener()
  self:bind_callback(self._btn_close, function()
    self:_on_btn_close_click()
  end)
end

function M:_on_btn_close_click()
  if self._is_close then
    return
  end
  self._is_close = true
  UIManagerInstance:close(self.guid)
end

return M
