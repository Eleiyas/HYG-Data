local M = G.Class("GroundSettingNewPage", G.UIWindow)
local base = G.UIWindow
local SLOT_ITEM_CLS = "UI/GroundSetting/GroundSettingSlotItem"
local CHOOSE_PANEL_CLS = "UI/GroundSetting/GroundChooseRoadPanel"
local CHOOSE_DIALOG_CLS = "UI/GroundSetting/GroundChooseRoadDialog"
local TAB_ROAD = 0
local TAB_PATTERN = 1
local PANEL_STATE_CLOSED = 0
local PANEL_STATE_OPENED = 1

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainPage/GroundSettingNewPage"
  self.config.type = EUIType.Page
  self.config.player_ctrl_cfg = {
    ctrl_cfg = {
      move = true,
      camera = true,
      ability = true
    },
    ui_cfg = {
      player_ctrl = true,
      ability = true,
      tip = true
    }
  }
  self._is_show = false
  self._cur_tab = TAB_ROAD
  self._slot_item_list = {}
  self._is_inited = false
  self._slot_cfg_list = {}
  self.select_cfg_id = 0
  self.select_index = 1
  self._is_dragging = false
  self._drag_from_index = 0
  self._drag_cfg_id = 0
  self._choose_panel = nil
  self._choose_panel_ready = false
  self._is_external_dragging = false
  self._external_drag_cfg_id = 0
  self._is_precise_editing = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self:_create_choose_panel()
  self._tool_bar_panel = self:add_panel_async("UI/MainPage/ToolWheelPanel", {is_quick_farming = true}, self.trans)
  self._tool_bar_panel:change_state(EUIState.Show)
end

function M:on_enable()
  base.on_enable(self)
  self._is_show = true
  CsGroundSettingModuleUtil.SetCurRoadCfgId(0)
  CsGroundSettingModuleUtil.SetCurDecalCfgId(0)
  self._cur_tab = TAB_ROAD
  CsGroundSettingModuleUtil.SetCurBrushMode(TAB_ROAD)
  self:_apply_tab_toggle(false)
  self:_apply_panel_state(false)
  self.select_cfg_id = 0
  self.select_index = 0
  UIUtil.set_text_by_id(self._txt_name, "GroundEraser")
  self:_sync_earser_toggle()
  self:_refresh_data()
  self:_refresh_slot_items()
  if not is_null(self._drag_item_obj) then
    UIUtil.set_active(self._drag_item_obj, false)
  end
  if self._tool_bar_panel and self._tool_bar_panel.is_active then
    self._tool_bar_panel:reset_is_tab_down()
    self._tool_bar_panel:change_state(EUIState.Hide)
  end
end

function M:on_disable()
  base.on_disable(self)
  if self._is_precise_editing then
    self._is_precise_editing = false
    if self._saved_ctrl_cfg then
      self.config.player_ctrl_cfg.ctrl_cfg = self._saved_ctrl_cfg
      self._saved_ctrl_cfg = nil
    end
    InputManagerIns:set_mouse_active(false)
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.EnterGroundSettingMode, function()
    self:_refresh_data()
    self:_refresh_slot_items()
  end)
  self:add_evt_listener(EventID.ExitGroundSettingMode, function()
    UIManagerInstance:close(self.guid)
  end)
  self:add_evt_listener(EventID.Performance.OnRollerBrushExitTPS, function()
    self:_close_dialog()
    UIManagerInstance:close(self.guid)
  end)
  self:add_evt_listener(EventID.OnAllUnlockedSceneUgcGridStylesNotify, function()
    self:_refresh_data()
    if self._is_show then
      self:_refresh_slot_items()
    end
  end)
  self:add_evt_listener(EventID.OnSceneUgcGridStyleUpdateNotify, function()
    self:_refresh_data()
    if self._is_show then
      self:_refresh_slot_items()
    end
  end)
  self:add_evt_listener(EventID.OnPlayerSceneUgcDataNotify, function()
    self:_refresh_data()
    if self._is_show then
      self:_refresh_slot_items()
    end
  end)
  self:add_evt_listener(EventID.OnOverlaySlotUpdated, function()
    if self._cur_tab == TAB_ROAD then
      self:_refresh_data()
      if self._is_show then
        self:_refresh_slot_items()
      end
    end
  end)
  self:add_evt_listener(EventID.OnDecalSlotUpdated, function()
    if self._cur_tab == TAB_PATTERN then
      self:_refresh_data()
      if self._is_show then
        self:_refresh_slot_items()
      end
    end
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.SwitchRoad, pack(self, M._on_switch_road), ActionType.EType.InProgress)
  self:bind_input_and_fun(ActionType.Act.Q, pack(self, M._on_key_switch_tab))
  self:bind_input_and_fun(ActionType.Act.E, pack(self, M._on_key_switch_tab))
  self:bind_input_and_fun(ActionType.Act.C, pack(self, M._on_key_modify))
  self:bind_input_and_fun(ActionType.Act.ToolWheel, pack(self, M._on_tool_wheel_click), ActionType.EType.ButtonPressed)
end

function M:handle_input_action(action)
  if not self:is_showing() then
    return
  end
  self:_inter_handle_input_action(action)
end

function M:is_showing()
  return self._is_show
end

function M:_create_choose_panel()
  local parent = self._trans_choose_panel_root or self.trans
  self._choose_panel = self:add_panel_async(CHOOSE_PANEL_CLS, nil, parent, pack(self, M._on_choose_panel_ready))
end

function M:_on_choose_panel_ready()
  self._choose_panel_ready = true
end

function M:_setup_choose_panel()
  if self._choose_panel and self._choose_panel.setup then
    self._choose_panel:setup({
      is_precise = true,
      is_embedded = true,
      default_tab = self._cur_tab
    })
  end
end

function M:_sync_choose_panel_tab()
  if self._choose_panel and self._choose_panel.switch_tab and self._choose_panel.is_active then
    self._choose_panel:switch_tab(self._cur_tab)
  end
end

function M:on_panel_tab_changed(tab)
  local new_tab = tab == 1 and TAB_PATTERN or TAB_ROAD
  if self._cur_tab == new_tab then
    return
  end
  self._cur_tab = new_tab
  CsGroundSettingModuleUtil.SetCurBrushMode(self._cur_tab)
  self:_apply_tab_toggle(new_tab == TAB_PATTERN)
  self.select_cfg_id = 0
  self.select_index = 0
  UIUtil.set_text_by_id(self._txt_name, "GroundEraser")
  self:_refresh_data()
  self:_refresh_slot_items()
  self:_sync_earser_toggle()
end

function M:_apply_panel_state(is_panel_open)
  if is_null(self._state_group_panel) then
    return
  end
  self._state_group_panel:SetState(is_panel_open and PANEL_STATE_OPENED or PANEL_STATE_CLOSED)
end

function M:_close_dialog()
  if self._choose_panel then
    self._choose_panel:change_state(EUIState.Hide)
  end
  self:_apply_panel_state(false)
  self:_restore_page_ctrl()
end

function M:_enter_precise_edit_ctrl()
  if self._is_precise_editing then
    return
  end
  self._is_precise_editing = true
  self._saved_ctrl_cfg = self.config.player_ctrl_cfg.ctrl_cfg
  self.config.player_ctrl_cfg.ctrl_cfg = {
    move = false,
    camera = false,
    ability = false
  }
  player_controller:apply_player_ctrl_cfg(self, {
    ctrl_cfg = self.config.player_ctrl_cfg.ctrl_cfg
  })
  InputManagerIns:set_mouse_active(true)
  Logger.Log("[GroundSettingNewPage] enter precise edit: 3C off, mouse resident")
end

function M:_restore_page_ctrl()
  if not self._is_precise_editing then
    return
  end
  self._is_precise_editing = false
  if self._saved_ctrl_cfg then
    self.config.player_ctrl_cfg.ctrl_cfg = self._saved_ctrl_cfg
    self._saved_ctrl_cfg = nil
  end
  if self.is_active then
    player_controller:apply_player_ctrl_cfg(self, self.config.player_ctrl_cfg)
  else
    InputManagerIns:set_mouse_active(false)
  end
  Logger.Log("[GroundSettingNewPage] restore roller-brush ctrl")
end

function M:_add_ui_listener()
  if not is_null(self._tog_tab_road) then
    self:bind_callback(self._tog_tab_road, pack(self, M._on_tog_tab_road))
  end
  if not is_null(self._tog_tab_pattern) then
    self:bind_callback(self._tog_tab_pattern, pack(self, M._on_tog_tab_pattern))
  end
  if not is_null(self._btn_modify) then
    self:bind_callback(self._btn_modify, pack(self, M._on_btn_modify))
  end
  if not is_null(self._btn_close) then
    self:bind_callback(self._btn_close, pack(self, M._on_btn_close))
  end
  if not is_null(self._tog_earser) then
    self:bind_callback(self._tog_earser, pack(self, M._on_tog_earser))
  end
end

function M:_apply_tab_toggle(is_pattern)
  if is_pattern then
    if not is_null(self._tog_tab_pattern) then
      self._tog_tab_pattern:SetIsOnWithoutNotify(true)
    end
    if not is_null(self._tog_tab_road) then
      self._tog_tab_road:SetIsOnWithoutNotify(false)
    end
  else
    if not is_null(self._tog_tab_road) then
      self._tog_tab_road:SetIsOnWithoutNotify(true)
    end
    if not is_null(self._tog_tab_pattern) then
      self._tog_tab_pattern:SetIsOnWithoutNotify(false)
    end
  end
end

function M:_on_tog_tab_road(is_on)
  if self._is_dragging or self._is_external_dragging then
    return
  end
  if is_on and self._cur_tab ~= TAB_ROAD then
    self._cur_tab = TAB_ROAD
    CsGroundSettingModuleUtil.SetCurBrushMode(TAB_ROAD)
    self.select_cfg_id = 0
    self.select_index = 0
    UIUtil.set_text_by_id(self._txt_name, "GroundEraser")
    self:_refresh_data()
    self:_refresh_slot_items()
    self:_sync_earser_toggle()
    self:_sync_choose_panel_tab()
  end
end

function M:_on_tog_tab_pattern(is_on)
  if self._is_dragging or self._is_external_dragging then
    return
  end
  if is_on and self._cur_tab ~= TAB_PATTERN then
    self._cur_tab = TAB_PATTERN
    CsGroundSettingModuleUtil.SetCurBrushMode(TAB_PATTERN)
    self.select_cfg_id = 0
    self.select_index = 0
    UIUtil.set_text_by_id(self._txt_name, "GroundEraser")
    self:_refresh_data()
    self:_refresh_slot_items()
    self:_sync_earser_toggle()
    self:_sync_choose_panel_tab()
  end
end

function M:_on_btn_modify()
  if self._is_precise_editing then
    return
  end
  if self._choose_panel then
    self._choose_panel:change_state(EUIState.Show)
    self:_setup_choose_panel()
    self:_apply_panel_state(true)
    self:_enter_precise_edit_ctrl()
  end
end

function M:_on_btn_close()
  if self._choose_panel and self._choose_panel.is_active then
    self._choose_panel:change_state(EUIState.Hide)
    self:_apply_panel_state(false)
    self:_restore_page_ctrl()
    return
  end
  local guid = EntityUtil.get_player_entity_guid()
  local player = EntityUtil.get_entity(guid)
  CsUIUtil.SendEntityEvent(guid, InputTagTags.Tags.inputtag_ability_tools_rollerbrush_toggletps, player)
end

function M:_on_tog_earser(is_on)
  if self._is_dragging or self._is_external_dragging then
    return
  end
  if not is_on then
    return
  end
  self:_select_earser()
  if not is_null(self._grid_scroll) then
    self._grid_scroll:RefreshCurrent()
  end
  self:_apply_active_toggle()
end

function M:_select_earser()
  if self._cur_tab == TAB_ROAD then
    CsGroundSettingModuleUtil.SetCurRoadCfgId(0)
  else
    CsGroundSettingModuleUtil.SetCurDecalCfgId(0)
  end
  self.select_cfg_id = 0
  self.select_index = 0
  UIUtil.set_text_by_id(self._txt_name, "GroundEraser")
  self:_sync_earser_toggle()
  self:_refresh_data()
end

function M:_sync_earser_toggle()
  if is_null(self._tog_earser) then
    return
  end
  local is_earser = self.select_index == 0
  self._tog_earser:SetIsOnWithoutNotify(is_earser)
end

function M:_apply_active_toggle()
  local sel = self.select_cfg_id or 0
  if 0 < sel then
    for _, item in pairs(self._slot_item_list) do
      if item and not is_null(item._tog_click) and item._cfg_id == sel and item._tog_click.gameObject.activeInHierarchy then
        item._tog_click:SetIsOnWithoutNotify(true)
        return
      end
    end
  end
  if sel == 0 and not is_null(self._tog_earser) then
    self._tog_earser:SetIsOnWithoutNotify(true)
  end
end

function M:_on_switch_road(action)
  if self._is_dragging or self._is_external_dragging then
    return
  end
  local wheel_delta = InputManagerIns:get_axis(ActionType.Act.SwitchRoad)
  if 0 < wheel_delta then
    self:select_prev()
  elseif wheel_delta < 0 then
    self:select_next()
  end
end

function M:_on_key_switch_tab()
  if self._is_dragging or self._is_external_dragging then
    return
  end
  if self._cur_tab == TAB_ROAD then
    self._cur_tab = TAB_PATTERN
  else
    self._cur_tab = TAB_ROAD
  end
  self:_apply_tab_toggle(self._cur_tab == TAB_PATTERN)
  CsGroundSettingModuleUtil.SetCurBrushMode(self._cur_tab)
  self.select_cfg_id = 0
  self.select_index = 0
  UIUtil.set_text_by_id(self._txt_name, "GroundEraser")
  self:_refresh_data()
  self:_refresh_slot_items()
  self:_sync_earser_toggle()
  self:_sync_choose_panel_tab()
end

function M:_on_key_modify()
  if self._is_dragging or self._is_external_dragging then
    return
  end
  self:_on_btn_modify()
end

function M:_on_tool_wheel_click()
  if self._is_dragging or self._is_external_dragging then
    return
  end
  if not self._tool_bar_panel then
    return
  end
  if self._is_precise_editing and not self._tool_bar_panel._is_show_tool_bar then
    return
  end
  if not self._tool_bar_panel._is_show_tool_bar and not GameplayUtilities_Shovel.CanSwitchToolInTps() then
    return
  end
  CsBuriedPointReportManagerUtil.ReportActionFromLuaTable(BuriedPointReportActionEnum.open_tool_wheel_panel, "OpenToolWheelPanel", {
    info = "on_press_tool_wheel"
  })
  self._tool_bar_panel:_handle_tab_down()
end

function M:_refresh_data()
  self._slot_cfg_list = {}
  local max_slot = CsGroundSettingModuleUtil.GetMaxSlotCount()
  if self._cur_tab == TAB_ROAD then
    local slot_ids = list_to_table(CsGroundSettingModuleUtil.GetOverlaySlotList())
    if slot_ids then
      for _, id in ipairs(slot_ids) do
        local cfg = ExcelDataUtil.get_value(typeof(BRoadCfg), id)
        if cfg then
          self._slot_cfg_list[#self._slot_cfg_list + 1] = cfg
        end
      end
    end
  else
    local slot_ids = list_to_table(CsGroundSettingModuleUtil.GetDecalSlotList())
    if slot_ids then
      for _, id in ipairs(slot_ids) do
        local cfg = ExcelDataUtil.get_value(typeof(BDecalCfg), id)
        if cfg then
          self._slot_cfg_list[#self._slot_cfg_list + 1] = cfg
        end
      end
    end
  end
  while max_slot > #self._slot_cfg_list do
    self._slot_cfg_list[#self._slot_cfg_list + 1] = {}
  end
  local cur_id
  if self._cur_tab == TAB_ROAD then
    cur_id = CsGroundSettingModuleUtil.GetCurRoadCfgId()
  else
    cur_id = CsGroundSettingModuleUtil.GetCurDecalCfgId()
  end
  self.select_cfg_id = cur_id or 0
  self.select_index = 0
  for i, cfg in ipairs(self._slot_cfg_list) do
    local cfg_id = cfg.id or cfg.decalid or 0
    if cfg_id == cur_id and cfg_id ~= 0 then
      self.select_index = i
      break
    end
  end
  if cur_id and cur_id ~= 0 and self.select_index == 0 then
    if self._cur_tab == TAB_ROAD then
      CsGroundSettingModuleUtil.SetCurRoadCfgId(0)
    else
      CsGroundSettingModuleUtil.SetCurDecalCfgId(0)
    end
    self.select_cfg_id = 0
    UIUtil.set_text_by_id(self._txt_name, "GroundEraser")
    self:_sync_earser_toggle()
  end
end

function M:_refresh_slot_items()
  if is_null(self._grid_scroll) then
    return
  end
  if not self._is_inited then
    self._is_inited = true
    self._grid_scroll:Init(pack(self, M._refresh_slot_item), #self._slot_cfg_list)
  else
    self._grid_scroll:ReLoad(pack(self, M._refresh_slot_item), #self._slot_cfg_list)
  end
  self:_apply_active_toggle()
end

function M:_refresh_slot_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local slot_item = self._slot_item_list[instance_id]
  if not slot_item then
    slot_item = self:add_panel(SLOT_ITEM_CLS, trans)
    self._slot_item_list[instance_id] = slot_item
  end
  slot_item:refresh(index, self._slot_cfg_list[index])
end

function M:refresh_select_slot(index, cfg_id)
  self.select_cfg_id = cfg_id
  self.select_index = index
  if cfg_id and 0 < cfg_id then
    local cfg
    if self._cur_tab == TAB_ROAD then
      cfg = ExcelDataUtil.get_value(typeof(BRoadCfg), cfg_id)
    else
      cfg = ExcelDataUtil.get_value(typeof(BDecalCfg), cfg_id)
    end
    UIUtil.set_text(self._txt_name, cfg and cfg.name or "")
  else
    UIUtil.set_text_by_id(self._txt_name, "GroundEraser")
  end
  if self._cur_tab == TAB_ROAD then
    CsGroundSettingModuleUtil.SetCurRoadCfgId(cfg_id or 0)
  else
    CsGroundSettingModuleUtil.SetCurDecalCfgId(cfg_id or 0)
  end
  self:_sync_earser_toggle()
  if not is_null(self._grid_scroll) then
    self._grid_scroll:RefreshCurrent()
  end
  self:_apply_active_toggle()
end

function M:select_prev()
  if self.select_index <= 0 then
    return
  end
  for i = self.select_index - 1, 0, -1 do
    if i == 0 then
      self:_select_earser()
      if not is_null(self._grid_scroll) then
        self._grid_scroll:RefreshCurrent()
      end
      self:_apply_active_toggle()
      return
    end
    local cfg = self._slot_cfg_list[i]
    local cfg_id = cfg and (cfg.id or cfg.decalid) or nil
    if cfg_id and 0 < cfg_id then
      self:refresh_select_slot(i, cfg_id)
      self:ensure_index_in_view(self.select_index)
      return
    end
  end
end

function M:select_next()
  for i = self.select_index + 1, #self._slot_cfg_list do
    local cfg = self._slot_cfg_list[i]
    local cfg_id = cfg and (cfg.id or cfg.decalid) or nil
    if cfg_id and 0 < cfg_id then
      self:refresh_select_slot(i, cfg_id)
      self:ensure_index_in_view(self.select_index)
      return
    end
  end
end

function M:ensure_index_in_view(index)
  local left_x = self._grid_scroll.ItemSize.x * (index - 1)
  local right_x = self._grid_scroll.ItemSize.x * (index - 1) + self._grid_scroll.CellSize.x + self._grid_scroll.Padding.left + self._grid_scroll.Padding.right
  local offset = -self._scroll_rect.content.anchoredPosition.x
  local viewport_width = self._scroll_rect.viewport.rect.width
  if left_x >= offset and right_x <= offset + viewport_width then
    return
  end
  if left_x < offset then
    self._scroll_rect.content:DOAnchorPosX(-left_x, 0.5):SetEase(Ease.OutQuad)
  elseif right_x > offset then
    self._scroll_rect.content:DOAnchorPosX(-right_x + viewport_width, 0.5):SetEase(Ease.OutQuad)
  end
end

function M:on_slot_begin_drag(index, cfg_id, icon, evt_or_pos)
  self._is_dragging = true
  self._drag_from_index = index
  self._drag_cfg_id = cfg_id
  self._drag_preview_index = index
  if not is_null(self._drag_item_obj) then
    UIUtil.set_active(self._drag_item_obj, true)
  end
  if not is_null(self._drag_item_img) and icon then
    UIUtil.set_image(self._drag_item_img, icon, self:get_load_proxy())
  end
  if not is_null(self._scroll_rect) then
    self._scroll_rect.enabled = false
  end
  self:_update_drag_position_by_screen(self:_extract_position(evt_or_pos))
  self:_update_drag_preview(index)
end

function M:on_slot_drag(evt)
  if not self._is_dragging then
    return
  end
  local screen_pos = self:_extract_position(evt)
  self:_update_drag_position_by_screen(screen_pos)
  local new_preview = self:_calc_drop_index_by_screen(screen_pos)
  if new_preview ~= self._drag_preview_index then
    self._drag_preview_index = new_preview
    self:_update_drag_preview(new_preview)
  end
end

function M:on_slot_end_drag(evt)
  if not self._is_dragging then
    return
  end
  local screen_pos = self:_extract_position(evt)
  local drop_index = self:_calc_drop_index_by_screen(screen_pos)
  if not is_null(self._drag_item_obj) then
    UIUtil.set_active(self._drag_item_obj, false)
  end
  if not is_null(self._scroll_rect) then
    self._scroll_rect.enabled = true
  end
  self._is_dragging = false
  self._drag_preview_index = 0
  self:_apply_reorder(self._drag_from_index, drop_index)
  self._drag_from_index = 0
  self._drag_cfg_id = 0
end

function M:on_external_drag_begin(cfg_id, icon, screen_pos)
  self._is_external_dragging = true
  self._external_drag_cfg_id = cfg_id
  self._drag_preview_index = 0
  if not is_null(self._drag_item_obj) then
    UIUtil.set_active(self._drag_item_obj, true)
  end
  if not is_null(self._drag_item_img) and icon then
    UIUtil.set_image(self._drag_item_img, icon, self:get_load_proxy())
  end
  if not is_null(self._scroll_rect) then
    self._scroll_rect.enabled = false
  end
  local pos = screen_pos
  if pos and pos.position then
    pos = pos.position
  end
  if pos then
    self:_update_drag_position_by_screen(pos)
  end
end

function M:on_external_drag(screen_pos)
  if not self._is_external_dragging then
    return
  end
  self:_update_drag_position_by_screen(screen_pos)
  local new_preview = self:_calc_external_drop_index(screen_pos)
  if new_preview ~= self._drag_preview_index then
    self._drag_preview_index = new_preview
    if 0 < new_preview then
      self:_update_external_drag_preview(new_preview)
    else
      self:_refresh_slot_items()
    end
  end
end

function M:on_external_drop(cfg_id, screen_pos)
  if not self._is_external_dragging then
    return
  end
  local drop_index = self:_calc_external_drop_index(screen_pos)
  if not is_null(self._drag_item_obj) then
    UIUtil.set_active(self._drag_item_obj, false)
  end
  if not is_null(self._scroll_rect) then
    self._scroll_rect.enabled = true
  end
  self._is_external_dragging = false
  self._drag_preview_index = 0
  if 0 < drop_index then
    self:_apply_external_insert(cfg_id, drop_index)
  else
    self:_refresh_data()
    self:_refresh_slot_items()
  end
  self._external_drag_cfg_id = 0
end

function M:on_external_drag_cancel()
  if not self._is_external_dragging then
    return
  end
  if not is_null(self._drag_item_obj) then
    UIUtil.set_active(self._drag_item_obj, false)
  end
  if not is_null(self._scroll_rect) then
    self._scroll_rect.enabled = true
  end
  self._is_external_dragging = false
  self._drag_preview_index = 0
  self._external_drag_cfg_id = 0
  self:_refresh_data()
  self:_refresh_slot_items()
end

function M:_calc_external_drop_index(screen_pos)
  if is_null(self._scroll_rect) or is_null(self._grid_scroll) then
    return 0
  end
  local content_rect = self._scroll_rect.content
  local success, local_pos = RectTransformUtility.ScreenPointToLocalPointInRectangle(content_rect, screen_pos, UIManagerInstance.ui_camera)
  if not success then
    return 0
  end
  local item_width = self._grid_scroll.ItemSize.x
  if item_width <= 0 then
    return 0
  end
  local local_x = local_pos.x
  local drop_index = math.floor(local_x / item_width) + 1
  local valid_count = self:_get_valid_slot_count()
  local max_slot = CsGroundSettingModuleUtil.GetMaxSlotCount()
  local max_index = valid_count >= max_slot and max_slot or valid_count + 1
  drop_index = math.max(1, math.min(drop_index, max_index))
  return drop_index
end

function M:_update_external_drag_preview(target_index)
  local max_slot = CsGroundSettingModuleUtil.GetMaxSlotCount()
  local display_list = {}
  for _, cfg in ipairs(self._slot_cfg_list) do
    display_list[#display_list + 1] = cfg
  end
  local existing_index = self:_find_cfg_index(self._external_drag_cfg_id)
  if 0 < existing_index then
    table.remove(display_list, existing_index)
  end
  local insert_pos = math.max(1, math.min(target_index, #display_list + 1))
  table.insert(display_list, insert_pos, {})
  while max_slot < #display_list do
    table.remove(display_list)
  end
  self:_refresh_slot_items_with_list(display_list)
end

function M:_apply_external_insert(cfg_id, drop_index)
  local max_slot = CsGroundSettingModuleUtil.GetMaxSlotCount()
  local existing_index = self:_find_cfg_index(cfg_id)
  if 0 < existing_index then
    self:_apply_reorder(existing_index, drop_index)
    return
  end
  local valid_count = self:_get_valid_slot_count()
  if max_slot <= valid_count then
    self:_apply_external_replace_insert(cfg_id, drop_index)
    return
  end
  if self._cur_tab == TAB_ROAD then
    CsGroundSettingModuleUtil.AddOverlaySlot(cfg_id)
  else
    CsGroundSettingModuleUtil.AddDecalSlot(cfg_id)
  end
  self:_refresh_data()
  local new_index = self:_find_cfg_index(cfg_id)
  if 0 < new_index and new_index ~= drop_index then
    self:_apply_reorder(new_index, drop_index)
  else
    self:_refresh_slot_items()
  end
  if self._cur_tab == TAB_ROAD then
    CsGroundSettingModuleUtil.SendOverlaySlotUpdateReq()
  else
    CsGroundSettingModuleUtil.SendDecalSlotUpdateReq()
  end
end

function M:_apply_external_replace_insert(cfg_id, drop_index)
  local max_slot = CsGroundSettingModuleUtil.GetMaxSlotCount()
  local id_list = {}
  for _, cfg in ipairs(self._slot_cfg_list) do
    local id = cfg.id or cfg.decalid or 0
    if 0 < id then
      id_list[#id_list + 1] = id
    end
  end
  local insert_pos = math.max(1, math.min(drop_index, max_slot))
  table.insert(id_list, insert_pos, cfg_id)
  while max_slot < #id_list do
    table.remove(id_list)
  end
  local cs_list = CS.System.Collections.Generic.List(CS.System.UInt32)()
  for _, id in ipairs(id_list) do
    cs_list:Add(id)
  end
  if self._cur_tab == TAB_ROAD then
    CsGroundSettingModuleUtil.SetOverlaySlotList(cs_list)
    CsGroundSettingModuleUtil.SendOverlaySlotUpdateReq()
  else
    CsGroundSettingModuleUtil.SetDecalSlotList(cs_list)
    CsGroundSettingModuleUtil.SendDecalSlotUpdateReq()
  end
  self:_refresh_data()
  self:_refresh_slot_items()
end

function M:_find_cfg_index(cfg_id)
  if not cfg_id or cfg_id <= 0 then
    return 0
  end
  for i, cfg in ipairs(self._slot_cfg_list) do
    local id = cfg.id or cfg.decalid or 0
    if id == cfg_id then
      return i
    end
  end
  return 0
end

function M:_extract_position(evt_or_pos)
  if evt_or_pos == nil then
    return Vector2.zero
  end
  if evt_or_pos.position then
    return evt_or_pos.position
  end
  return evt_or_pos
end

function M:_update_drag_position_by_screen(screen_pos)
  if is_null(self._drag_item_trans) then
    return
  end
  local parent_rect = self._drag_item_trans.parent
  if is_null(parent_rect) then
    return
  end
  local success, local_pos = RectTransformUtility.ScreenPointToLocalPointInRectangle(parent_rect, screen_pos, UIManagerInstance.ui_camera)
  if success then
    self._drag_item_trans.anchoredPosition = local_pos
  end
end

function M:_update_drag_preview(target_index)
  local display_list = {}
  for i, cfg in ipairs(self._slot_cfg_list) do
    if i ~= self._drag_from_index then
      display_list[#display_list + 1] = cfg
    end
  end
  local insert_pos = math.max(1, math.min(target_index, #display_list + 1))
  table.insert(display_list, insert_pos, {})
  self._drag_display_list = display_list
  self:_refresh_slot_items_with_list(display_list)
end

function M:_refresh_slot_items_with_list(list)
  if is_null(self._grid_scroll) then
    return
  end
  
  local function refresh_fn(trans, index)
    index = index + 1
    local instance_id = trans:GetInstanceID()
    local slot_item = self._slot_item_list[instance_id]
    if not slot_item then
      slot_item = self:add_panel(SLOT_ITEM_CLS, trans)
      self._slot_item_list[instance_id] = slot_item
    end
    slot_item:refresh(index, list[index])
  end
  
  if not self._is_inited then
    self._is_inited = true
    self._grid_scroll:Init(refresh_fn, #list)
  else
    self._grid_scroll:ReLoad(refresh_fn, #list)
  end
end

function M:_calc_drop_index_by_screen(screen_pos)
  if is_null(self._scroll_rect) or is_null(self._grid_scroll) then
    return self._drag_from_index
  end
  local content_rect = self._scroll_rect.content
  local success, local_pos = RectTransformUtility.ScreenPointToLocalPointInRectangle(content_rect, screen_pos, UIManagerInstance.ui_camera)
  if not success then
    return self._drag_from_index
  end
  local item_width = self._grid_scroll.ItemSize.x
  if item_width <= 0 then
    return self._drag_from_index
  end
  local local_x = local_pos.x
  local drop_index = math.floor(local_x / item_width) + 1
  local valid_count = self:_get_valid_slot_count()
  drop_index = math.max(1, math.min(drop_index, valid_count))
  return drop_index
end

function M:_get_valid_slot_count()
  local count = 0
  for _, cfg in ipairs(self._slot_cfg_list) do
    local cfg_id = cfg.id or cfg.decalid or 0
    if 0 < cfg_id then
      count = count + 1
    end
  end
  return count
end

function M:_apply_reorder(from_index, to_index)
  if from_index == to_index then
    self:_refresh_data()
    self:_refresh_slot_items()
    return
  end
  local from_cfg = self._slot_cfg_list[from_index]
  if not from_cfg then
    self:_refresh_data()
    self:_refresh_slot_items()
    return
  end
  local from_id = from_cfg.id or from_cfg.decalid or 0
  if from_id <= 0 then
    self:_refresh_data()
    self:_refresh_slot_items()
    return
  end
  table.remove(self._slot_cfg_list, from_index)
  local actual_to = math.min(to_index, #self._slot_cfg_list + 1)
  table.insert(self._slot_cfg_list, actual_to, from_cfg)
  self:_persist_slot_order()
  if self.select_cfg_id == from_id then
    self.select_index = actual_to
  end
  self:_refresh_slot_items()
end

function M:_persist_slot_order()
  local id_list = {}
  for _, cfg in ipairs(self._slot_cfg_list) do
    local cfg_id = cfg.id or cfg.decalid or 0
    if 0 < cfg_id then
      id_list[#id_list + 1] = cfg_id
    end
  end
  local cs_list = CS.System.Collections.Generic.List(CS.System.UInt32)()
  for _, id in ipairs(id_list) do
    cs_list:Add(id)
  end
  if self._cur_tab == TAB_ROAD then
    CsGroundSettingModuleUtil.SetOverlaySlotList(cs_list)
  else
    CsGroundSettingModuleUtil.SetDecalSlotList(cs_list)
  end
end

function M:get_panel(type)
  return nil
end

function M:set_player_ctrl_cfg(move_ctrl, camera_ctrl, ability_ctrl)
  if not UIManagerInstance:is_top(self.guid) then
    return
  end
  if self._is_precise_editing then
    return
  end
  self.config.player_ctrl_cfg.ctrl_cfg = {
    move = move_ctrl,
    camera = camera_ctrl,
    ability = ability_ctrl
  }
  player_controller:apply_player_ctrl_cfg(self, self.config.player_ctrl_cfg)
end

function M:refresh_ability_availability()
  if not UIManagerInstance:is_top(self.guid) then
    return
  end
  if self._is_precise_editing then
    return
  end
  local state = player_module:get_ability_availability_state()
  local ability = state ~= false
  self.config.player_ctrl_cfg = {
    ctrl_cfg = {
      move = true,
      camera = true,
      ability = ability
    },
    ui_cfg = {
      player_ctrl = true,
      ability = ability,
      tip = ability
    }
  }
  if self.is_active then
    player_controller:apply_player_ctrl_cfg(self, self.config.player_ctrl_cfg)
  end
end

return M
