local M = G.Class("DialogFilterGemStoneNormal", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/VX/DialogueFilter/DialogueFilterUI_GemStone_Normal"
  self.config.type = EUIType.Info
  self.config.order_in_layer = 5
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self:play_anim("start", function()
    if self._extra_data then
      self._extra_data()
    end
    self:close_self()
  end)
end

function M:on_disable()
  base.on_disable(self)
end

function M:enter_anim_call_back()
  base.enter_anim_call_back(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

return M
