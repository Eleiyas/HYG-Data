local M = G.Class("PayWaitPage", G.UIWindow)
local base = G.UIWindow
local SHOW_CENTER_DELAY = 1

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NetState/PayWaitPage"
  self.config.type = EUIType.Tip
  self.config.input_penetrate = false
  self.config.is_always_cache = true
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
  self._timer = 0
  self._center_shown = false
  UIUtil.set_active(self._obj_center, false)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
  InputManagerIns:unlock_input(input_lock_from.Pay)
end

function M:on_close()
  base.on_close(self)
  InputManagerIns:unlock_input(input_lock_from.Pay)
end

function M:on_destroy()
  base.on_destroy(self)
  InputManagerIns:unlock_input(input_lock_from.Pay)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:handle_input_action(action)
end

function M:update(deltaTime)
  if not self.is_active then
    return
  end
  if self._center_shown then
    return
  end
  self._timer = self._timer + deltaTime
  if self._timer >= SHOW_CENTER_DELAY then
    self._center_shown = true
    UIUtil.set_active(self._obj_center, true)
  end
end

return M
