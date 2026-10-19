local M = G.Class("SuitMagicTip", G.PlayerControlInputElementBase)
local base = G.PlayerControlInputElementBase
local SuitMagicState = {Enable = 0, Disable = 1}

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.onPlayerCreateComplete, function()
    self:refresh()
  end)
  self:add_evt_listener(EventID.LuaClothesChange, function()
    self:refresh()
  end)
  self:add_evt_listener(EventID.OnSuitMagicEnabledChanged, function()
    self:refresh()
  end)
end

function M:_add_ui_listener()
end

function M:inner_refresh()
  if self._is_show_suit_magic() then
    UIUtil.set_active(self.game_obj, true)
    if self._enable_state then
      local is_magic_enable = CsAppearanceManagerUtil.GetSuitMagicEnabled()
      if is_magic_enable then
        self._enable_state:SetState(SuitMagicState.Enable)
      else
        self._enable_state:SetState(SuitMagicState.Disable)
      end
    end
  else
    UIUtil.set_active(self.game_obj, false)
  end
end

function M:_is_show_suit_magic()
  return CsAppearanceManagerUtil.IsWearingFullMagicSuit()
end

return M
