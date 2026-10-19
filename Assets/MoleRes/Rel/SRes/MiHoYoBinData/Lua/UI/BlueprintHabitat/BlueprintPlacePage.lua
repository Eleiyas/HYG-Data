local M = G.Class("BlueprintPlacePage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/SiteSelectionPage"
  self.config.player_ctrl_cfg = {
    ctrl_cfg = {
      move = false,
      camera = false,
      ability = false
    },
    ui_cfg = {
      player_ctrl = true,
      camera_drag_area = false,
      ability = false,
      tip = false
    }
  }
  self.config.type = EUIType.Page
  self._btn_ok = nil
  self._btn_cancel = nil
  self._btn_turn_left = nil
  self._btn_turn_right = nil
  self._btn_preview = nil
  self._trans_blueprint_preview = nil
  self._trans_tips_error = nil
  self._txt_tips_error = nil
  self._trans_load_value_root = nil
  self._trans_habitat_item = nil
  self._load_value_info_panel = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_ok) then
    self:bind_callback(self._btn_ok, pack(self, M._on_click_confirm))
  end
  if not_null(self._btn_cancel) then
    self:bind_callback(self._btn_cancel, pack(self, M._on_click_cancel))
  end
  if not_null(self._btn_turn_left) then
    self:bind_callback(self._btn_turn_left, pack(self, M._on_click_rotate))
  end
  if not_null(self._btn_turn_right) then
    self:bind_callback(self._btn_turn_right, pack(self, M._on_click_rotate))
  end
  UIUtil.set_active(self._btn_preview, false)
  UIUtil.set_active(self._trans_blueprint_preview, false)
  UIUtil.set_active(self._trans_habitat_item, false)
  UIUtil.set_active(self._trans_tips_error, false)
  UIUtil.set_text_by_id(self._txt_tips_error, "Blueprint_UI_005")
  if not_null(self._trans_load_value_root) then
    self._load_value_info_panel = self:add_panel_async("UI/LoadValue/LoadValueInfoPanel", nil, self._trans_load_value_root)
  end
end

function M:on_enable()
  base.on_enable(self)
  if self._load_value_info_panel then
    self._load_value_info_panel:change_state(EUIState.Show)
  end
end

function M:on_disable()
  base.on_disable(self)
  if self._load_value_info_panel then
    self._load_value_info_panel:change_state(EUIState.Hide)
  end
end

function M:on_before_close()
  base.on_before_close(self)
  new_blueprint_module:set_blueprint_place_mode(false)
  new_blueprint_module:clear_place_report_ctx()
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  local editor = RuntimeWorldEditor.Current
  if is_null(editor) or editor.eicEntityEditHandler == nil then
    return
  end
  local editCtrl = editor.eicEntityEditHandler.editCtrl
  if editCtrl == nil then
    return
  end
  local can_place = not editCtrl.IsMultiHolding or editCtrl:CanApplyMultiHold()
  if not_null(self._btn_ok) then
    self._btn_ok.interactable = can_place
  end
  UIUtil.set_active(self._trans_tips_error, not can_place)
  local can_rotate = editCtrl:CanRotateMultiSelection()
  if not_null(self._btn_turn_left) then
    self._btn_turn_left.interactable = can_rotate
  end
  if not_null(self._btn_turn_right) then
    self._btn_turn_right.interactable = can_rotate
  end
end

function M:_on_click_confirm()
  if CsGameplayUtilitiesEmergencySwitchUtil.IsSwitchOnByType(EmergencySwitchType.EmergencySwitchCloseIslandBuild) then
    CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
    return
  end
  local ctx = new_blueprint_module:get_place_report_ctx()
  if ctx then
    local fields = new_blueprint_module:build_blueprint_report_fields_by_key(ctx.domain, ctx.key)
    CsBuriedPointReportManagerUtil.ReportActionFromLuaTable(BuriedPointReportActionEnum.new_blueprint_save, "NewBlueprintSave", fields)
  end
  CsNewBlueprintModuleUtil.ConfirmBlueprintPlacement()
  self:close_self()
end

function M:_on_click_cancel()
  CsNewBlueprintModuleUtil.CancelBlueprintPlacement()
  self:close_self()
end

function M:_on_click_rotate()
  CsNewBlueprintModuleUtil.RotateBlueprintPlacement()
end

function M:handle_back(action)
  action.handled = true
  self:_on_click_cancel()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.ButtonSouth, M._on_click_confirm)
  self:bind_input_and_fun(ActionType.Act.InterAction, M._on_click_confirm)
  self:bind_input_and_fun(ActionType.Act.ButtonEast, M.handle_back)
  self:bind_input_and_fun(ActionType.Act.Back, M.handle_back)
  self:bind_input_and_fun(ActionType.Act.PutAwayTools, M.handle_back)
  self:bind_input_and_btn(ActionType.Act.Q, self._btn_turn_left)
  self:bind_input_and_btn(ActionType.Act.E, self._btn_turn_right)
  self:bind_input_and_fun(ActionType.Act.Move, function()
    local x, y = InputManagerIns:get_vector2(ActionType.Act.Move)
    if x and y then
      local sensitivity = CsAssetConfigManagerUtil.ugcCameraConfig.mobileCameraMoveSensitivity
      CsGameplayUtilitiesCameraUtil.MoveCamera(x * sensitivity, y * sensitivity)
    end
  end, ActionType.EType.ButtonRepeating)
end

return M
