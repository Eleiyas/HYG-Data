local M = G.Class("PlayerPlanetEcoValuePacketPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/PlayerPlanetEcoValue/PlayerPlanetEcoValuePacketDialog"
  self._is_show = false
end

function M:on_create()
  base.on_create(self)
  self:change_state(self._is_show and EUIState.Show or EUIState.Hide)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_ui()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnGatherLoadUpdate, function()
    self:_refresh_ui()
  end)
end

function M:set_show(is_show)
  self._is_show = is_show
  if not is_null(self.game_obj) then
    self:change_state(is_show and EUIState.Show or EUIState.Hide)
  end
end

function M:_refresh_ui()
  UIUtil.set_image(self._img_icon, social_module:get_current_gather_load_icon_path(), self:get_load_proxy())
  UIUtil.set_text(self._txt_ecology, social_module:get_current_gather_load_text())
end

return M
