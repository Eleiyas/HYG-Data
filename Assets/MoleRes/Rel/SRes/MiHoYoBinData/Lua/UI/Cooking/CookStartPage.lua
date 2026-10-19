local M = G.Class("CookStartPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Cooking/CookStartPage"
  self.config.type = EUIType.Info
  self.config.handle_input = true
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaCloseCookStartPage, function()
    self:close_self()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_skip)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_skip, pack(self, M._on_btn_skip_click))
end

function M:_on_btn_skip_click()
  EventCenter.Broadcast(EventID.SkipCookAnim)
end

return M
