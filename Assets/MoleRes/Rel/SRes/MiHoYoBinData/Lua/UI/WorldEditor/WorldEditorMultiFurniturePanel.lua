local M = G.Class("WorldEditorMultiFurniturePanel", G.UIPanel)
local base = G.UIPanel
local STATE_PANEL_EXPANDED = 0
local STATE_PANEL_COLLAPSED = 1
local CsGameplayUtilitiesFurniture = GameplayUtilities_Furniture
local NodeItem = G.Class("MultiFurnitureNodeItem", G.UIBase)
local NodeItemBase = G.UIBase

function NodeItem:init()
  NodeItemBase.init(self)
end

function NodeItem:on_create()
  NodeItemBase.on_create(self)
  if not_null(self._tog_fold) then
    self._tog_fold.onValueChanged:AddListener(function(isOn)
      if self._ignore_toggle then
        return
      end
      local data = self._extra_data
      if not data then
        return
      end
      local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
      if isOn then
        editCtrl:AddToMultiSelection(data.guid)
      else
        editCtrl:RemoveFromMultiSelection(data.guid)
      end
      data.selected = isOn
      if self._panel_ref then
        self._panel_ref:_on_selection_changed_in_list()
      end
    end)
  end
end

function NodeItem:refresh()
  local data = self._extra_data
  if not data then
    return
  end
  if not_null(self._txt_name) then
    UIUtil.set_text(self._txt_name, data.name)
  end
  if not_null(self._img_icon) and string.is_valid(data.icon) then
    UIUtil.set_image(self._img_icon, data.icon, self:get_load_proxy())
  end
  if not_null(self._txt_num) then
    UIUtil.set_text_by_id(self._txt_num, "WorldEditor_MultiSelect_EntityLoad", string.format("%.1f", data.load_value or 0))
  end
  local is_holding = self._panel_ref and self._panel_ref._is_holding_snapshot
  if not_null(self._tog_fold) then
    UIUtil.set_active(self._tog_fold, not is_holding)
    if not is_holding then
      self._ignore_toggle = true
      self._tog_fold.isOn = data.selected
      self._ignore_toggle = false
    end
  end
end

local SubItem = G.Class("MultiFurnitureSubItem", G.UIBase)
local SubItemBase = G.UIBase

function SubItem:init()
  SubItemBase.init(self)
end

function SubItem:on_create()
  SubItemBase.on_create(self)
end

function SubItem:refresh()
  local data = self._extra_data
  if not data then
    return
  end
  if not_null(self._txt_name) then
    UIUtil.set_text(self._txt_name, data.name)
  end
  if not_null(self._img_icon) and string.is_valid(data.icon) then
    UIUtil.set_image(self._img_icon, data.icon, self:get_load_proxy())
  end
  if not_null(self._txt_num) then
    UIUtil.set_text_by_id(self._txt_num, "WorldEditor_MultiSelect_EntityLoad", string.format("%.1f", data.load_value or 0))
  end
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/WorldEditor/WorldEditorMultiFurniturePanel"
  self._is_expanded = false
  self._is_holding_snapshot = false
  self._is_item_info_open = false
  self._node_cls_cache = {}
  self._item_cls_cache = {}
  self._entity_data_list = {}
  self._entity_data_flat_list = {}
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_open, pack(self, M._on_btn_expand_click))
  self:bind_callback(self._btn_close_popup, pack(self, M._on_btn_collapse_click))
  self:bind_callback(self._btn_back, pack(self, M._on_btn_back_click))
  self:bind_callback(self._btn_cancel, pack(self, M._on_btn_cancel_click))
  self:bind_callback(self._btn_rotate, pack(self, M._on_btn_rotate_click))
  self:bind_callback(self._btn_withdraw, pack(self, M._on_btn_withdraw_click))
  self:bind_callback(self._btn_save_blueprint, pack(self, M._on_btn_save_blueprint_click))
end

function M:on_enable()
  base.on_enable(self)
  self:_set_expanded(false)
  self._can_save_blueprint = new_blueprint_module:is_custom_blueprint_unlocked()
  if not_null(self._btn_save_blueprint) then
    UIUtil.set_active(self._btn_save_blueprint, self._can_save_blueprint)
  end
  if self._extra_data then
    self:_update_count_display(self._extra_data.count or 0)
  end
end

function M:on_disable()
  base.on_disable(self)
  local editor = RuntimeWorldEditor.Current
  if not is_null(editor) then
    editor:SetCameraInputSuspended(false)
  end
end

function M:bind_input_action()
  self:bind_input_and_fun(ActionType.Act.E, function()
    if self._is_expanded then
      return
    end
    self:_on_btn_rotate_click()
  end)
  self:bind_input_and_fun(ActionType.Act.R, function()
    if self._is_expanded then
      return
    end
    local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
    if editCtrl.IsMultiDraging then
      return
    end
    self:_on_btn_withdraw_click()
  end)
  self:bind_input_and_fun(ActionType.Act.ButtonNorth, function()
    if not InputManagerIns:is_joystick() then
      return false
    end
    if not self._is_expanded then
      return false
    end
    self:_on_btn_back_click()
    return true
  end, ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.R3, self._on_preview_item_info)
end

function M:try_handle_back()
  if self._is_item_info_open then
    self._is_item_info_open = false
    return true
  end
  if self._is_expanded then
    self:_on_btn_collapse_click()
    return true
  end
  if InputManagerIns:is_joystick() and self:_try_cancel_box_select() then
    return true
  end
  if not self._extra_data then
    return false
  end
  local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
  if (self._extra_data.count or 0) <= 0 then
    self:_on_btn_back_click()
    return true
  end
  if editCtrl.IsMultiDraging or InputManagerIns:is_joystick() and editCtrl.IsMultiHolding then
    editCtrl:RequestCancelMultiHold()
    return true
  end
  self:_on_btn_cancel_click()
  return true
end

function M:_try_cancel_box_select()
  local editor = RuntimeWorldEditor.Current
  if is_null(editor) or editor.eicEntityEditHandler == nil then
    return false
  end
  local editCtrl = editor.eicEntityEditHandler.editCtrl
  if editCtrl == nil or not editCtrl.IsBoxSelectFlowActive then
    return false
  end
  return editCtrl:RequestCancelBoxSelectFlow()
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
  local is_holding = editCtrl.IsMultiHolding
  local can_rotate = editCtrl:CanRotateMultiSelection()
  local can_cancel = is_holding and editCtrl:CanRevertMultiHold() or editCtrl.MultiSelectedCount > 0
  local can_withdraw = editCtrl:CanRetrieveMultiSelection()
  if not_null(self._btn_rotate) then
    self._btn_rotate.interactable = can_rotate
  end
  if not_null(self._btn_cancel) then
    self._btn_cancel.interactable = can_cancel
  end
  if not_null(self._btn_withdraw) then
    self._btn_withdraw.interactable = can_withdraw
  end
  if self._can_save_blueprint and not_null(self._btn_save_blueprint) then
    self._btn_save_blueprint.interactable = editCtrl:CanSaveMultiSelectionAsBlueprint()
  end
  self:_update_box_select_tips(editor, editCtrl)
end

function M:_update_box_select_tips(editor, editCtrl)
  local visible = editCtrl.BoxSelectTipsVisible
  if visible then
    if not_null(self._multi_select_tips) then
      self._multi_select_tips.gameObject:SetActive(true)
    end
    if not_null(self._state_group_select) then
      self._state_group_select:SetState(editCtrl.BoxSelectTipsState)
    end
    if not_null(self._slider_cd) then
      self._slider_cd.value = editCtrl.BoxSelectTipsProgress
    end
    if not_null(self._multi_select_tips) then
      self._multi_select_tips.anchoredPosition = self:_get_box_select_tips_ui_pos(editor)
    end
  elseif self._box_select_tips_was_visible and not_null(self._multi_select_tips) then
    self._multi_select_tips.gameObject:SetActive(false)
  end
  self._box_select_tips_was_visible = visible
end

function M:_get_box_select_tips_ui_pos(editor)
  if not is_null(editor) and editor.IsGamepadPointerActive then
    local screen_pos = editor:GetPointerScreenPosition()
    local _, pos = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(UIManagerInstance.canvas_rect, Vector2(screen_pos.x, screen_pos.y), UIManagerInstance.ui_camera)
    return pos
  end
  return UIUtil.mouse_position_to_ui()
end

function M:_set_expanded(expanded)
  self._is_expanded = expanded
  if not_null(self._state_group_panel) then
    self._state_group_panel:SetState(expanded and STATE_PANEL_EXPANDED or STATE_PANEL_COLLAPSED)
  end
  local editor = RuntimeWorldEditor.Current
  if not is_null(editor) then
    editor:SetCameraInputSuspended(expanded)
  end
end

function M:_on_btn_expand_click()
  local editor = RuntimeWorldEditor.Current
  if is_null(editor) or editor.eicEntityEditHandler == nil then
    return
  end
  local editCtrl = editor.eicEntityEditHandler.editCtrl
  if editCtrl == nil then
    return
  end
  self._is_holding_snapshot = editCtrl.IsMultiHolding
  self:_set_expanded(true)
  self:_build_entity_data_list()
  self:_refresh_scroll()
end

function M:_on_btn_collapse_click()
  self:_set_expanded(false)
end

function M:_on_btn_back_click()
  local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
  editCtrl:SetSelectMode(0)
end

function M:_on_btn_cancel_click()
  local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
  if editCtrl:CanRevertMultiHold() then
    editCtrl:RevertMultiHold()
  else
    editCtrl:DeselectAllMulti()
  end
end

function M:_on_btn_rotate_click()
  local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
  if editCtrl:CanRotateMultiSelection() then
    editCtrl:RotateMultiSelection()
  end
end

function M:_on_btn_withdraw_click()
  local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
  if not editCtrl:CanRetrieveMultiSelection() then
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("WorldEditor_MultiSelect_RetrieveTip"), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    AudioManagerIns:post_event_by_cfg(UEvent.Furniture_SmokeDel)
    editCtrl:RetrieveMultiSelection()
  end)
  popup:show()
end

function M:_on_btn_save_blueprint_click()
  if not new_blueprint_module:is_custom_blueprint_unlocked() then
    return
  end
  local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
  if not editCtrl:CanSaveMultiSelectionAsBlueprint() then
    return
  end
  if new_blueprint_module:intercept_if_custom_slot_full() then
    return
  end
  if editCtrl:HasWallOrCeilingEntityInMultiSelection(true) then
    local wall_tip = UIUtil.get_text_by_id("WorldEditor_MultiSelect_BlueprintWallCeilingTip")
    UIUtil.show_tips(wall_tip)
    return
  end
  if editCtrl:HasBlueprintOrphanInMultiSelection(true) then
    local orphan_tip = UIUtil.get_text_by_id("WorldEditor_MultiSelect_BlueprintOrphanTip")
    UIUtil.show_tips(orphan_tip)
    return
  end
  if editCtrl:HasBlueprintBlockedInMultiSelection() then
    UIUtil.show_tips_by_text_id("WorldEditor_MultiSelect_BlueprintBlockedTip")
  end
  local COVER_FILL_RATIO = 0.8
  local COVER_MOVE_DURATION = 0.35
  local ok = CsNewBlueprintModuleUtil.FocusCameraOnRuntimeMultiSelect(COVER_FILL_RATIO, COVER_MOVE_DURATION, function()
    CsNewBlueprintModuleUtil.SetRuntimeCoverStageActive(false)
    CsCameraManagerUtil.CreatePictureCenter(0, 0, function(guid)
      UIManagerInstance:open("UI/BlueprintHabitat/BlueprintSaveDataDialog", {cover_guid = guid})
    end)
  end)
  if not ok then
    UIManagerInstance:open("UI/BlueprintHabitat/BlueprintSaveDataDialog", {cover_guid = 0})
  end
end

function M:refresh_view()
  if is_null(self.game_obj) then
    return
  end
  local data = self._extra_data
  if not data then
    return
  end
  self:_update_count_display(data.count or 0)
end

function M:_update_count_display(count)
  local editor = RuntimeWorldEditor.Current
  local max_count = 99
  if not is_null(editor) and editor.eicEntityEditHandler ~= nil and editor.eicEntityEditHandler.editCtrl ~= nil then
    max_count = editor.eicEntityEditHandler.editCtrl.MultiSelectMaxCount
  end
  if not_null(self._txt_num_bottom) then
    UIUtil.set_text_by_id(self._txt_num_bottom, "WorldEditor_MultiSelect_SelectedCount", count)
  end
  if not_null(self._txt_num_title) then
    UIUtil.set_text_by_id(self._txt_num_title, "WorldEditor_MultiSelect_CountWithMax", count, max_count)
  end
end

function M:_get_entity_cfg(configId)
  return ExcelDataUtil.get_value(typeof(BItemCfg), configId)
end

function M:_build_entity_data_list()
  self._entity_data_list = {}
  local editCtrl = RuntimeWorldEditor.Current.eicEntityEditHandler.editCtrl
  local guids = editCtrl.MultiSelectedEntityGuids
  local entityManager = editCtrl.entityManager
  local enumerator = guids:GetEnumerator()
  local flat_index = 0
  while enumerator:MoveNext() do
    local guid = enumerator.Current
    local entity = entityManager:GetEntity(guid)
    if not_null(entity) then
      local configId = entity.ConfigId
      local cfg = self:_get_entity_cfg(configId)
      local children = {}
      local child_guids = CsGameplayUtilitiesFurniture.GetEntitiesOnFurniturePlane(guid)
      local root_flat_index = flat_index
      if child_guids and 0 < child_guids.Count then
        for i = 0, child_guids.Count - 1 do
          local child_guid = child_guids[i]
          local child_entity = entityManager:GetEntity(child_guid)
          if not_null(child_entity) then
            local child_cfg_id = child_entity.ConfigId
            local child_cfg = self:_get_entity_cfg(child_cfg_id)
            local value = {
              guid = child_guid,
              configId = child_cfg_id,
              name = child_cfg and child_cfg.name or "",
              icon = child_cfg and child_cfg.icon or "",
              load_value = CsGameplayUtilitiesFurniture.GetEntityLoadValue(child_guid)
            }
            table.insert(children, value)
            self._entity_data_flat_list[flat_index + 1] = value
            flat_index = flat_index + 1
          end
        end
      end
      local value = {
        guid = guid,
        configId = configId,
        name = cfg and cfg.name or "",
        icon = cfg and cfg.icon or "",
        children = children,
        load_value = CsGameplayUtilitiesFurniture.GetEntityLoadValue(guid),
        selected = true
      }
      table.insert(self._entity_data_list, value)
      self._entity_data_flat_list[root_flat_index] = value
      flat_index = flat_index + 1
    end
  end
  enumerator:Dispose()
end

function M:_refresh_scroll()
  if is_null(self._scroller) then
    return
  end
  local count = #self._entity_data_list
  self._scroller:SetNodeCount(count)
  
  local function on_item_bind_cb(item, nodeIndex, itemIndex)
    self:_on_item_bind(item, nodeIndex, itemIndex)
  end
  
  local function on_node_init_cb(node, nodeIndex)
    self:_on_node_init(node, nodeIndex)
  end
  
  for i = 1, count do
    local data = self._entity_data_list[i]
    local child_count = #data.children
    self._scroller:Init(i - 1, 0, child_count, on_item_bind_cb, on_node_init_cb)
  end
  self._scroller:ReloadAll(nil)
end

function M:_on_selection_changed_in_list()
  local count = 0
  for _, data in ipairs(self._entity_data_list) do
    if data.selected then
      count = count + 1
    end
  end
  self:_update_count_display(count)
end

function M:_get_or_create_cls(trans, cache, cls_template)
  local inst_id = trans:GetInstanceID()
  local cls = cache[inst_id]
  if not cls then
    local inst = G.New(cls_template)
    inst:init()
    cls = self:add_panel(inst, trans)
    cache[inst_id] = cls
  end
  return cls
end

function M:_on_node_init(node, nodeIndex)
  local data = self._entity_data_list[nodeIndex + 1]
  if not data then
    return
  end
  local item_root = node:Find("furniture_content")
  if not is_null(item_root) and item_root.childCount > 0 then
    item_root:GetChild(0).gameObject:SetActive(false)
  end
  local cls = self:_get_or_create_cls(node, self._node_cls_cache, NodeItem)
  cls._panel_ref = self
  cls._node_index = nodeIndex
  cls:set_extra_data(data)
  cls:refresh()
  local has_children = data.children and 0 < #data.children
  if has_children and not is_null(self._scroller) then
    self._scroller:ExpandNode(nodeIndex, 0)
  end
end

function M:_on_item_bind(item, nodeIndex, itemIndex)
  local data = self._entity_data_list[nodeIndex + 1]
  if not data then
    return
  end
  local child = data.children[itemIndex + 1]
  if not child then
    return
  end
  local cls = self:_get_or_create_cls(item, self._item_cls_cache, SubItem)
  cls:set_extra_data(child)
  cls:refresh()
end

function M:_on_preview_item_info()
  if self._navi_scroll == nil then
    return
  end
  local curSelectIndex = self._navi_scroll.curIndex
  if self._entity_data_flat_list[curSelectIndex] == nil or self._entity_data_flat_list[curSelectIndex].configId == nil then
    return
  end
  local item_config_id = self._entity_data_flat_list[curSelectIndex].configId
  if item_module:open_item_info_dialog(item_config_id) ~= nil then
    self._is_item_info_open = true
  end
end

return M
