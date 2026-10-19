local M = G.Class("TPSTip", G.PlayerControlInputElementBase)
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

function M:inner_refresh()
  self:refrsh_common_tps()
end

function M:refrsh_common_tps()
  UIUtil.set_active(self.game_obj, self:_is_show_fram_tps())
end

function M:_is_show_fram_tps()
  if CsStarSeaUtil.IsCurrentSceneMaterialStar() or CsStarSeaUtil.IsCurrentSceneStarSea() then
    return false
  end
  if not CsQuickFarmingModuleUtil.CanPlayerHoldingToolEnterQuickFarmingMode() then
    return false
  end
  if CsQuickFarmingModuleUtil.LuaInQuickFarmMode then
    return false
  end
  if GameplayUtilities_Avatar.IsPlayerInTpsFarmMode() then
    return false
  end
  return true
end

return M
