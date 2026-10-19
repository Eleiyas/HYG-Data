local M = G.Class("PlayerIntimacyLoadingPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Social/PlayerIntimacyLoadingPage"
  self.config.type = EUIType.Info
  self._auto_close_timer = nil
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_clear_auto_close_timer()
  self:_refresh_from_extra_data()
end

function M:on_disable()
  base.on_disable(self)
  self:_clear_auto_close_timer()
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
  self:_clear_auto_close_timer()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaClosePlayerIntimacyLoadingPage, function()
    self:close_self()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_refresh_from_extra_data()
  local data = self:get_extra_data()
  if is_null(data) then
    return
  end
  UIUtil.set_active(self._txt, data)
end

function M:_schedule_auto_close()
  local data = self:get_extra_data()
  local duration = data and tonumber(data.auto_close_sec)
  if not duration or duration <= 0 then
    return
  end
  self._auto_close_timer = duration
end

function M:_clear_auto_close_timer()
  self._auto_close_timer = nil
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if not self._auto_close_timer then
    return
  end
  self._auto_close_timer = self._auto_close_timer - deltaTime
  if self._auto_close_timer <= 0 then
    self._auto_close_timer = nil
    self:close_self()
  end
end

return M
