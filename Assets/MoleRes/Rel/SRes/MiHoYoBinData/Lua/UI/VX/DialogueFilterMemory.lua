local M = G.Class("DialogueFilterMemory", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/VX/DialogueFilter/DialogueFilterUI_Memory"
  self.config.type = EUIType.Info
  self.config.order_in_layer = 5
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self._animator_helper:SetTriggerWithCallback("in", nil)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaShowDialogueFilterMemoryOut, function()
    self._animator_helper:SetTriggerWithCallback("out", function()
      self:close_self()
    end)
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

return M
