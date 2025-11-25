local M = G.Class("KeyMouseInputPanel", G.PlayerControlInputPanelBase)
local base = G.PlayerControlInputPanelBase
local use_prop_cls = "UI/PlayerCtrl/Common/UsePropTip"
local tool_bar_cls = "UI/PlayerCtrl/Common/ToolBarTip"
local common_cls = "UI/PlayerCtrl/Base/PlayerControlInputElementBase"
local interaction_list_cls = "UI/PlayerCtrl/InteractionList/InteractionList"
local fish_cast_cls = "UI/PlayerCtrl/Common/FishCastTip"
local special_tool_cls = "UI/PlayerCtrl/Common/SpecialToolTip"
local farming_switch_cls = "UI/PlayerCtrl/Common/FarmingModeSwitchTip"
local music_mode_switch_cls = "UI/PlayerCtrl/Common/MusicModeSwitchTip"
local speed_up_cls = "UI/PlayerCtrl/Common/SpeedUpTip"
local kite_ctrl_cls = "UI/PlayerCtrl/Common/KiteCtrlTip"
local car_speed_up_cls = "UI/PlayerCtrl/Common/CarSpeedUpTip"
local fly_kite_cls = "UI/PlayerCtrl/Common/FlyKiteTip"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/PlayerCtrl/KeyMouseInput"
end

function M:on_create()
  base.on_create(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnEnterQuickFarmingMode, pack(self, M.set_quick_farming_icon))
  self:add_evt_listener(EventID.OnExitQuickFarmingMode, pack(self, M.unset_quick_farming_icon))
  self:add_evt_listener(EventID.Performance.OnRollerBrushEnterTPS, pack(self, M.set_quick_farming_icon))
  self:add_evt_listener(EventID.Performance.OnRollerBrushExitTPS, pack(self, M.unset_quick_farming_icon))
  self:add_evt_listener(EventID.OnKiteGameFail, function()
    self._kite_ctrl:reset()
  end)
  self:add_evt_listener(EventID.OnKiteTakeOver, function(state)
    UIUtil.set_active(self._trans_kite_distance, state)
  end)
end

function M:set_quick_farming_icon()
  local image = player_controller_module:get_precise_farming_icon()
  self.farming_mode_switch:set_icon(image)
end

function M:unset_quick_farming_icon()
  local image = player_controller_module:get_default_farming_icon()
  self.farming_mode_switch:set_icon(image)
end

function M:inner_refresh()
  local ui_cfg = self:get_extra_data()
  if ui_cfg == nil or ui_cfg.ability == nil or ui_cfg.ability == false then
    UIUtil.set_active(self.game_obj, false)
    return
  end
  UIUtil.set_active(self.game_obj, true)
  self:refresh_all_element()
  CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.tips_root_rectTrans)
  CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self._rect_content)
  self:update_btn_state()
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self.is_active then
    self:update_btn_state()
  end
end

function M:update_btn_state()
end

function M:init_all_element()
  self.all_element = {}
  self.inter_action_list = self:add_panel(interaction_list_cls, self._interact_list_obj)
  table.insert(self.all_element, self.inter_action_list)
  self.use_prop = self:add_panel(use_prop_cls, self._use_prop_obj)
  self.use_prop:set_linked_btn_type(CommandButton.Tool)
  table.insert(self.all_element, self.use_prop)
  self.run = self:add_panel(speed_up_cls, self._speed_up_obj)
  self.run:set_linked_btn_type(CommandButton.RunToggle)
  table.insert(self.all_element, self.run)
  self.tool_bar = self:add_panel(tool_bar_cls, self._tool_bar_obj)
  table.insert(self.all_element, self.tool_bar)
  self.fish_retrieve = self:add_panel(common_cls, self._fish_retrieve_obj)
  self.fish_retrieve:set_linked_btn_type(CommandButton.FishTap)
  table.insert(self.all_element, self.fish_retrieve)
  self.fish_cast = self:add_panel(fish_cast_cls, self._fish_cast_obj)
  self.fish_cast:set_linked_btn_type(CommandButton.FishHold)
  table.insert(self.all_element, self.fish_cast)
  self.farming_mode_switch = self:add_panel(farming_switch_cls, self._switch_plant_mode_obj)
  self.farming_mode_switch:set_linked_btn_type(CommandButton.FarmingModeSwitch)
  table.insert(self.all_element, self.farming_mode_switch)
  self._rotate_furniture = self:add_panel(common_cls, self._rotate_furniture_obj)
  self._rotate_furniture:set_linked_btn_type(CommandButton.RunToggle)
  table.insert(self.all_element, self._rotate_furniture)
  self._confirm_furniture = self:add_panel(common_cls, self._confirm_furniture_obj)
  self._confirm_furniture:set_linked_btn_type(CommandButton.Tool)
  table.insert(self.all_element, self._confirm_furniture)
  self.jump = self:add_panel(common_cls, self._jump_obj)
  self.jump:set_linked_btn_type(CommandButton.Tool)
  table.insert(self.all_element, self.jump)
  self.special_tool = self:add_panel(special_tool_cls, self._btn_special_tool_obj)
  table.insert(self.all_element, self.special_tool)
  self._music_mode_switch = self:add_panel(music_mode_switch_cls, self._switch_music_mode_obj)
  table.insert(self.all_element, self._music_mode_switch)
  self._take_back = self:add_panel(common_cls, self._obj_take_back)
  table.insert(self.all_element, self._take_back)
  self._kite_ctrl = self:add_panel(kite_ctrl_cls, self._kite_ctrl_obj)
  table.insert(self.all_element, self._kite_ctrl)
  self._car_speed_up = self:add_panel(car_speed_up_cls, self._obj_car_speep_up)
  table.insert(self.all_element, self._car_speed_up)
  self._star_sea_scan = self:add_panel(common_cls, self._obj_scan)
  table.insert(self.all_element, self._star_sea_scan)
  self._switch_music_mode = self:add_panel(common_cls, self._obj_switch_music_mode)
  table.insert(self.all_element, self._switch_music_mode)
  self._share = self:add_panel(common_cls, self._obj_share)
  table.insert(self.all_element, self._share)
  self._fly_kite = self:add_panel(fly_kite_cls, self._obj_fly_kite)
  table.insert(self.all_element, self._fly_kite)
end

return M
