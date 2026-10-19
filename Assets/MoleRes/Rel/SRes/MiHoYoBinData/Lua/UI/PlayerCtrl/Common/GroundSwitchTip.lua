local M = G.Class("GroundSwitchTip", G.PlayerControlInputElementBase)
local base = G.PlayerControlInputElementBase
local CHOOSE_DIALOG_CLS = "UI/GroundSetting/GroundChooseRoadDialog"
local tick_time = 0.2
local BRUSH_MODE_ROAD = 0
local BRUSH_MODE_DECAL = 1

function M:init()
  base.init(self)
  self.tick_timer = 0
  self._should_show = false
  self._is_precise_mode = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self.tick_timer = 0
  self._should_show = nil
  self:_check_show_state()
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaOnPlayerEquipRsp, pack(self, M._check_show_state))
  self:add_evt_listener(EventID.EnterGroundSettingMode, pack(self, M._check_show_state))
  self:add_evt_listener(EventID.ExitGroundSettingMode, pack(self, M._check_show_state))
  self:add_evt_listener(EventID.Performance.OnRollerBrushEnterTPS, pack(self, M._on_enter_precise))
  self:add_evt_listener(EventID.Performance.OnRollerBrushExitTPS, pack(self, M._on_exit_precise))
  self:add_evt_listener(EventID.OnSceneUgcGridStyleUpdateNotify, pack(self, M._refresh_icon))
  self:add_evt_listener(EventID.OnGroundBrushModeChanged, pack(self, M._refresh_icon))
  self:add_evt_listener(EventID.OnOverlaySlotUpdated, pack(self, M._refresh_icon))
  self:add_evt_listener(EventID.OnDecalSlotUpdated, pack(self, M._refresh_icon))
  self:add_lua_listener(lua_event_module.event_type.on_ground_switch_pressed, pack(self, M._on_ground_switch_event))
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:update(deltaTime)
  if self.is_active then
    self.tick_timer = self.tick_timer + deltaTime
    if self.tick_timer > tick_time then
      self.tick_timer = 0
      self:_check_show_state()
    end
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  self:bind_callback(UIUtil.find_button_ex(self.game_obj), pack(self, self._on_btn_click))
end

function M:_on_btn_click()
  UIManagerInstance:open(CHOOSE_DIALOG_CLS, {is_precise = false})
end

function M:_on_ground_switch_event()
  if not self:_can_show() then
    return
  end
  self:_on_btn_click()
end

function M:_check_show_state()
  local should_show = self:_can_show()
  if self._should_show ~= should_show then
    self._should_show = should_show
    UIUtil.set_active(self.game_obj, should_show)
  end
end

function M:_can_show()
  if self._is_precise_mode then
    return false
  end
  local cur_tool = player_module:get_cur_equip_item()
  if cur_tool ~= nil and cur_tool.ConFigID == 20015 then
    return CsGameplayUtilitiesPermissionUtil.GetPermissionOfItem(PlayerOpType.EquipItem, 20015)
  end
  return false
end

function M:_on_enter_precise()
  self._is_precise_mode = true
  self:_check_show_state()
end

function M:_on_exit_precise()
  self._is_precise_mode = false
  self:_check_show_state()
end

function M:inner_refresh()
  if is_null(self.game_obj) then
    return
  end
  self:_check_show_state()
  self:_refresh_icon()
end

function M:_refresh_icon()
  if is_null(self._icon) then
    return
  end
  local icon_path
  local brush_mode = CsGroundSettingModuleUtil.GetCurBrushMode()
  if brush_mode == BRUSH_MODE_DECAL then
    local decal_id = CsGroundSettingModuleUtil.GetCurDecalCfgId()
    if decal_id and 0 < decal_id then
      local cfg = ExcelDataUtil.get_value(typeof(BDecalCfg), decal_id)
      if cfg then
        icon_path = cfg.icon
      end
    end
  else
    local road_id = CsGroundSettingModuleUtil.GetCurRoadCfgId()
    if road_id and 0 < road_id then
      local cfg = ExcelDataUtil.get_value(typeof(BRoadCfg), road_id)
      if cfg then
        icon_path = cfg.icon
      end
    end
  end
  if not icon_path or icon_path == "" then
    icon_path = "UISprite/Load/GroundSetting/Img_GroundSetting_01"
  end
  UIUtil.set_image(self._icon, icon_path, self:get_load_proxy())
end

return M
