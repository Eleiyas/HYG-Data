local M = G.Class("TeleportMapPage", G.UIWindow)
local base = G.UIWindow
local teleport_panel_class_name = "UI/Map/TeleportMap/TeleportMapPanel"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Map/TestMapPage"
  self.config.type = EUIType.Page
  self.config.input_lock_type = input_lock_type.lock_all
  self.config.player_ctrl_cfg = {
    ctrl_cfg = {
      move = false,
      camera = true,
      ability = false,
      right_ctrl = true
    },
    ui_cfg = {
      player_ctrl = false,
      ability = false,
      tip = false
    }
  }
end

function M:check_3c_validate()
  return true
end

function M:on_create()
  base.on_create(self)
  self._state_group_type:SetState(1)
  self._teleport_panel = self:add_panel(teleport_panel_class_name, self._trans_teleport_panel)
  self:bind_callbacks()
end

function M:on_enable()
  base.on_enable(self)
  self._state_group_type:SetState(1)
  local scene_id = GameSceneUtility.GetCurrentSceneId()
  local scene_cfg = LocalDataUtil.get_value(typeof(GameSceneCfg), scene_id)
  if scene_cfg then
    UIUtil.set_text(self._txt_title, scene_cfg.nameInGame)
  end
  if self._extra_data and self._extra_data.select_guid > 0 then
    self._teleport_panel:set_anchor_selected_by_guid(self._extra_data.select_guid)
    self._teleport_panel:set_extra_data(self._extra_data)
  end
end

function M:_on_btn_return_click()
  self:close_self()
end

function M:close_self()
  base.close_self(self)
  CsMap3DManagerUtil.OnMapUIClosed()
  EventCenter.Broadcast(EventID.Performance.OnMapClose, 1)
end

function M:clear_on_relogin()
  base.clear_on_relogin(self)
  CsMap3DManagerUtil.OnMapUIClosed()
  EventCenter.Broadcast(EventID.Performance.OnMapClose, 1)
end

function M:on_destroy()
  if self.is_active then
    CsMap3DManagerUtil.OnMapUIClosed()
    EventCenter.Broadcast(EventID.Performance.OnMapClose, 1)
  end
  CsAssetConfigManagerUtil.UnloadConfig("ScriptData/MapIconsConfig.asset")
  base.on_destroy(self)
end

function M:handle_back(action)
  action:handle()
  self:_on_btn_return_click()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Map, self._btn_close)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:bind_callbacks()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_return_click))
end

return M
