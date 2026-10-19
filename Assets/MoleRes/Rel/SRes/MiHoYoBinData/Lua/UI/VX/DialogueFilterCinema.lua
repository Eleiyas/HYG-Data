local M = G.Class("DialogueFilterCinema", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/VX/DialogueFilter/DialogueFilterUI_Manman"
  self.config.type = EUIType.Info
  self.config.order_in_layer = 5
end

function M:on_enable()
  base.on_enable(self)
  self._animator_helper:SetTriggerWithCallback("in", nil)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaShowDialogueFilterCinemaOut, function()
    self._animator_helper:SetTriggerWithCallback("out", function()
      self:close_self()
    end)
  end)
end

return M
