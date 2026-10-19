local M = G.Class("AvatarInfoEditorPanel", G.UIPanel)
local base = G.UIPanel
local auto_save_interval = 180

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Social/AvatarInfoEditorPanel"
  self.config.type = EUIType.Panel
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._entity_panel = self:add_panel("UI/MiniPlanetDIY/AvatarInfoEditorEntityPanel", self._trans_entity_panel)
  self._single_entity_panel = self:add_panel("UI/MiniPlanetDIY/AvatarInfoEditorSingleEntityPanel", self._trans_single_entity_panel)
  self._setting_panel = self:add_panel("UI/MiniPlanetDIY/AvatarInfoEditorSettingPanel", self._trans_setting_panel)
  self._load_value_info_panel = self:add_panel_async("UI/LoadValue/LoadValueInfoPanel", {
    title_text_id = "MiniPlanetDIY_LoadValueTitle"
  }, self._trans_load_value_root)
  self:refresh_setting_active(false)
  self:refresh_auto_save_ui()
  self:_deselect_single_entity()
  self._in_preview = false
  UIUtil.set_active(self._trans_preview, false)
end

function M:on_enable()
  base.on_enable(self)
  self:_init_edit_toggles()
  self:reset_auto_save_timer()
  self:refresh_auto_save_ui()
end

function M:on_disable()
  base.on_disable(self)
  self:_set_preview_active(false)
  self:refresh_setting_active(false)
  self:_deselect_single_entity()
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if not is_null(self._btn_undo) then
    self._btn_undo.interactable = self:can_undo()
  end
  if not is_null(self._btn_redo) then
    self._btn_redo.interactable = self:can_redo()
  end
  if not is_null(self._btn_save) then
    self._btn_save.interactable = self:can_save() and not self:_is_dragging_decoration()
  end
  self:_refresh_auto_save(deltaTime)
end

function M:_add_ui_listener()
  if not is_null(self._btn_back) then
    self:bind_callback(self._btn_back, pack(self, M._on_btn_back_click))
  end
  if not is_null(self._btn_setting) then
    self:bind_callback(self._btn_setting, pack(self, M._on_btn_setting_click))
  end
  if not is_null(self._btn_undo) then
    self:bind_callback(self._btn_undo, pack(self, M._on_btn_undo_click))
  end
  if not is_null(self._btn_redo) then
    self:bind_callback(self._btn_redo, pack(self, M._on_btn_redo_click))
  end
  if not is_null(self._btn_save) then
    self:bind_callback(self._btn_save, pack(self, M._on_btn_save_click))
  end
  if not is_null(self._btn_more) then
    self:bind_callback(self._btn_more, pack(self, M._on_btn_more_click))
  end
  if not is_null(self._btn_exit_preview) then
    self:bind_callback(self._btn_exit_preview, pack(self, M._on_btn_exit_preview_click))
  end
  if not is_null(self._tog_decoration) then
    self:bind_callback(self._tog_decoration, pack(self, M._on_tog_decoration))
  end
  if not is_null(self._tog_action) then
    self:bind_callback(self._tog_action, pack(self, M._on_tog_action))
  end
end

function M:_init_edit_toggles()
  self:_check_open_state()
  if not is_null(self._tog_decoration) then
    self._tog_decoration.isOn = true
    self:_on_tog_decoration(true)
  end
  if not is_null(self._tog_action) then
    self._tog_action.isOn = false
    self:_on_tog_action(false)
  end
end

function M:_check_open_state()
  if not is_null(self._state_group_decoration) then
    self._state_group_decoration:SetState(1)
  end
  if not is_null(self._state_group_action) then
    self._state_group_action:SetState(1)
  end
end

function M:_on_tog_decoration(is_on)
  if is_null(self._animator_decoration) then
    return
  end
  if is_on then
    self._animator_decoration:SetTrigger("in")
  else
    self._animator_decoration:SetTrigger("out")
  end
end

function M:_on_tog_action(is_on)
  if is_null(self._animator_action) then
    return
  end
  if is_on then
    self._animator_action:SetTrigger("in")
  else
    self._animator_action:SetTrigger("out")
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.MiniPlanetDIYSelectSingleEntity, pack(self, M._on_select_single_entity))
  self:add_evt_listener(EventID.MiniPlanetDIYDeselectSingleEntity, pack(self, M._on_deselect_single_entity))
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, M.handle_back, ActionType.EType.ButtonPressed)
  self:bind_input_and_fun(ActionType.Act.E, function()
    if self:is_in_preview() then
      return
    end
    self:on_single_entity_rotate()
  end)
  self:bind_input_and_fun(ActionType.Act.R, function()
    if self:is_in_preview() then
      return
    end
    self:on_single_entity_withdraw()
  end)
end

function M:_try_handle_preview_back()
  if not self:is_in_preview() then
    return false
  end
  self:_set_preview_active(false)
  return true
end

function M:handle_back()
  if self:_is_dragging_decoration() then
    return
  end
  if self:_try_handle_back_layers() then
    return
  end
  self:_on_btn_back_click()
end

function M:_try_handle_back_layers()
  if self:_try_handle_preview_back() then
    return true
  end
  if not is_null(self._setting_panel) and self._setting_panel:try_handle_back() then
    return true
  end
  if not is_null(self._single_entity_panel) and self._single_entity_panel:try_handle_back() then
    return true
  end
  if not is_null(self._entity_panel) and self._entity_panel:try_handle_back() then
    return true
  end
  return false
end

function M:_exit_editor()
  local extra_data = self:get_extra_data()
  if extra_data ~= nil and extra_data.on_exit ~= nil then
    extra_data.on_exit()
    return
  end
  self.holder:close_self()
end

function M:_on_btn_back_click()
  if self:_is_dragging_decoration() then
    return
  end
  if self:is_auto_save_enabled() and not avatar_info_editor_module.is_diy_blocked_by_emergency_switch() then
    if self:can_save() then
      self:save_diy(function()
        self:_exit_editor()
      end)
    else
      self:_exit_editor()
    end
    return
  end
  if self:can_save() then
    local popup = UIUtil.get_confirm_popup()
    popup:set_texts(UIUtil.get_text_by_id("Edit_Furniture_Info2"), UIUtil.get_text_by_id("WorldEditor_Save_Confirm"), UIUtil.get_text_by_id("WorldEditor_Save_Cancel"), nil)
    popup:set_callbacks(function()
      self:save_diy(function()
        self:_exit_editor()
      end)
    end, function()
      self:_exit_editor()
    end, function()
    end)
    popup:set_style(ConfirmPopupStyle.NormalWithClose)
    popup:show()
  else
    self:_exit_editor()
  end
end

function M:_on_select_single_entity(entity_transform)
  self:_select_single_entity(entity_transform)
end

function M:_on_deselect_single_entity()
  self:_deselect_single_entity()
end

function M:_select_single_entity(entity_transform)
  if is_null(self._single_entity_panel) then
    return
  end
  self._single_entity_panel:set_extra_data({entity = entity_transform})
  self._single_entity_panel:refresh_view()
  self:_set_main_ui_visible(false)
end

function M:_deselect_single_entity()
  if is_null(self._single_entity_panel) then
    return
  end
  self._single_entity_panel:set_extra_data(nil)
  self._single_entity_panel:refresh_view()
  self:_set_main_ui_visible(true)
end

function M:_set_main_ui_visible(is_on)
  if is_on and (self:is_in_preview() or self:is_setting_active()) then
    return
  end
  UIUtil.set_active(self._trans_top, is_on)
  UIUtil.set_active(self._trans_left, is_on)
  UIUtil.set_active(self._trans_func_btns, is_on)
  UIUtil.set_active(self._trans_bottom, is_on)
  if self._load_value_info_panel ~= nil then
    self._load_value_info_panel:change_state(is_on and EUIState.Show or EUIState.Hide)
  end
  if is_on and not is_null(self._entity_panel) and self._entity_panel:is_show_extend() then
    self._entity_panel:init_anim_trigger()
  end
end

function M:_on_btn_setting_click()
  self:refresh_setting_active(true)
end

function M:refresh_setting_active(is_active)
  self._setting_active = is_active == true
  if not is_null(self._setting_panel) then
    self._setting_panel:set_active(is_active)
  end
  self:_set_main_ui_visible(not is_active)
end

function M:is_setting_active()
  return self._setting_active == true
end

function M:can_rotate_selected_decoration()
  local edit_handler = self:_get_edit_handler()
  if edit_handler == nil then
    return false
  end
  return edit_handler:CanRotateSelectedDecoration()
end

function M:can_withdraw_selected_decoration()
  local edit_handler = self:_get_edit_handler()
  if edit_handler == nil then
    return false
  end
  return edit_handler:CanDeleteSelectedDecoration()
end

function M:has_selected_decoration()
  local edit_handler = self:_get_edit_handler()
  if edit_handler == nil then
    return false
  end
  return edit_handler:HasSelectedDecoration()
end

function M:get_selected_decoration_display_name()
  local edit_handler = self:_get_edit_handler()
  if edit_handler == nil then
    return ""
  end
  return edit_handler:GetSelectedDecorationName() or ""
end

function M:on_single_entity_rotate()
  self:_rotate_selected_decoration_step()
end

function M:on_single_entity_withdraw()
  self:_delete_selected_decoration()
end

function M:on_single_entity_cancel()
  local edit_handler = self:_get_edit_handler()
  if edit_handler ~= nil then
    edit_handler:CancelPendingPlacement()
  end
  self:_deselect_single_entity()
end

function M:can_undo()
  local edit_handler = self:_get_edit_handler()
  if not is_null(edit_handler) and edit_handler.CanUndo ~= nil then
    return edit_handler:CanUndo()
  end
  return false
end

function M:can_redo()
  local edit_handler = self:_get_edit_handler()
  if not is_null(edit_handler) and edit_handler.CanRedo ~= nil then
    return edit_handler:CanRedo()
  end
  return false
end

function M:can_save()
  local edit_handler = self:_get_edit_handler()
  if is_null(edit_handler) or edit_handler.CanSave == nil then
    return false
  end
  return edit_handler:CanSave()
end

function M:_on_btn_undo_click()
  if not self:can_undo() then
    return
  end
  self:reset_auto_save_timer()
  local edit_handler = self:_get_edit_handler()
  edit_handler:PerformUndo()
  self:_refresh_entity_placement_limit_state()
end

function M:_on_btn_redo_click()
  if not self:can_redo() then
    return
  end
  self:reset_auto_save_timer()
  local edit_handler = self:_get_edit_handler()
  edit_handler:PerformRedo()
  self:_refresh_entity_placement_limit_state()
end

function M:_on_btn_save_click()
  if self:_is_dragging_decoration() then
    return
  end
  self:save_diy()
end

function M:_on_btn_more_click()
  if is_null(self._btn_more) then
    return
  end
  local menus_data = {
    show_position = self.trans:InverseTransformPoint(self._btn_more.transform.position),
    menus = {
      {
        valid = true,
        desc = UIUtil.get_text_by_id("MiniPlanetDIY_MenuPreview"),
        call_back_action = pack(self, M._on_menu_preview)
      },
      {
        valid = true,
        desc = UIUtil.get_text_by_id("MiniPlanetDIY_MenuResetView"),
        call_back_action = pack(self, M._on_menu_reset_view)
      },
      {
        valid = true,
        special = true,
        desc = UIUtil.get_text_by_id("MiniPlanetDIY_MenuCollectAll"),
        call_back_action = pack(self, M._on_menu_collect_all)
      }
    }
  }
  UIManagerInstance:open("UI/CommonUI/CommonMenuDarkDialog", menus_data)
end

function M:_on_menu_preview()
  self:_set_preview_active(true)
end

function M:_on_btn_exit_preview_click()
  self:_set_preview_active(false)
end

function M:is_in_preview()
  return self._in_preview == true
end

function M:_set_preview_active(is_preview)
  if self:is_in_preview() == is_preview then
    return
  end
  self._in_preview = is_preview
  local edit_handler = self:_get_edit_handler()
  if not is_null(edit_handler) and edit_handler.SetPreviewMode ~= nil then
    edit_handler:SetPreviewMode(is_preview)
  end
  self:_set_main_ui_visible(not is_preview)
  UIUtil.set_active(self._trans_preview, is_preview)
  if is_preview then
    UIUtil.set_active(self._trans_auto_save_tip, false)
  end
end

function M:_on_menu_reset_view()
  local edit_handler = self:_get_edit_handler()
  if is_null(edit_handler) or edit_handler.ResetPlanetView == nil then
    return
  end
  edit_handler:ResetPlanetView()
end

function M:_on_menu_collect_all()
  local edit_handler = self:_get_edit_handler()
  if is_null(edit_handler) or edit_handler.CollectAllDecorations == nil then
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("MiniPlanetDIY_CollectAllConfirm"), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    self:reset_auto_save_timer()
    if edit_handler:CollectAllDecorations() then
      EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("MiniPlanetDIY_CollectAllDoneTip"))
      self:_refresh_entity_placement_limit_state()
    end
  end)
  popup:show()
end

function M:get_auto_save_key()
  return LocalSaveID.MiniPlanetDIYAutoSave
end

function M:is_auto_save_enabled()
  local key = self:get_auto_save_key()
  if key == nil then
    return false
  end
  return CsLocalSaveDataUtil.GetBool(key, false)
end

function M:refresh_auto_save_ui()
  UIUtil.set_active(self._btn_save, not self:is_auto_save_enabled())
  UIUtil.set_active(self._trans_auto_save_tip, false)
end

function M:_refresh_auto_save(deltaTime)
  if not self:is_auto_save_enabled() then
    return
  end
  if avatar_info_editor_module.is_diy_blocked_by_emergency_switch() then
    return
  end
  self._auto_save_timer = (self._auto_save_timer or 0) + deltaTime
  if self._auto_save_timer >= auto_save_interval then
    if self:can_save() and not self:_is_dragging_decoration() then
      self:save_diy()
      if not self:is_in_preview() then
        UIUtil.set_active(self._trans_auto_save_tip, false)
        UIUtil.set_active(self._trans_auto_save_tip, true)
      end
      self:reset_auto_save_timer()
    elseif not self:_has_unsaved_changes() then
      self:reset_auto_save_timer()
    end
  end
  if self._auto_save_timer > 1 and self._auto_save_timer - deltaTime <= 1 then
    local edit_handler = self:_get_edit_handler()
    if not is_null(edit_handler) and not edit_handler.IsSaving and not is_null(self._animator_auto_save) then
      self._animator_auto_save:SetTrigger("out")
    end
  end
end

function M:_has_unsaved_changes()
  local edit_handler = self:_get_edit_handler()
  if is_null(edit_handler) or edit_handler.CanSave == nil then
    return false
  end
  return edit_handler:CanSave() or edit_handler.IsSaving
end

function M:reset_auto_save_timer()
  self._auto_save_timer = 0
end

function M:save_diy(on_close)
  if avatar_info_editor_module.try_block_diy_with_tip() then
    return false
  end
  local edit_handler = self:_get_edit_handler()
  if is_null(edit_handler) then
    if on_close then
      on_close(false)
    end
    return false
  end
  if edit_handler.SaveAndUpload == nil then
    if on_close then
      on_close(false)
    end
    return false
  end
  edit_handler:SaveAndUpload(function(success)
    self:_on_save_rsp(success)
    if on_close then
      on_close(success)
    end
  end)
  return true
end

function M:_on_save_rsp(is_success)
  if is_null(self) then
    return
  end
  if self:is_auto_save_enabled() then
    if not is_null(self._animator_auto_save) and (self._auto_save_timer or 0) > 1 then
      self._animator_auto_save:SetTrigger("out")
    end
  else
    local text_id = is_success and "WorldEditor_Save_Success" or "WorldEditor_Save_Fail"
    UIUtil.show_tips_by_text_id(text_id)
  end
end

function M:_rotate_selected_decoration_step()
  local edit_handler = self:_get_edit_handler()
  if is_null(edit_handler) then
    return false
  end
  return edit_handler:RotateSelectedDecorationStep()
end

function M:_delete_selected_decoration()
  local edit_handler = self:_get_edit_handler()
  if is_null(edit_handler) then
    return false
  end
  local deleted = edit_handler:DeleteSelectedDecoration()
  if deleted then
    self:_refresh_entity_placement_limit_state()
  end
  return deleted
end

function M:_refresh_entity_placement_limit_state()
  if is_null(self._entity_panel) then
    return
  end
  self._entity_panel:refresh_placement_limit_state()
end

function M:get_load_value()
  local edit_handler = self:_get_edit_handler()
  if is_null(edit_handler) or edit_handler.GetCurrentDecorationLoadTotal == nil then
    return nil
  end
  return edit_handler:GetCurrentDecorationLoadTotal()
end

function M:get_load_max_limit()
  local edit_handler = self:_get_edit_handler()
  if is_null(edit_handler) or edit_handler.GetDecorationLoadValueLimit == nil then
    return nil
  end
  return edit_handler:GetDecorationLoadValueLimit()
end

function M:_get_editor()
  if not is_null(self._mini_planet_editor) then
    return self._mini_planet_editor
  end
  self._mini_planet_editor = CS.UnityEngine.Object.FindObjectOfType(typeof(CS.miHoYo.HYG.MiniPlanetDIYEditor))
  return self._mini_planet_editor
end

function M:_get_edit_handler()
  local editor = self:_get_editor()
  if is_null(editor) then
    return nil
  end
  return editor.EditHandler
end

function M:_is_dragging_decoration()
  local edit_handler = self:_get_edit_handler()
  if is_null(edit_handler) then
    return false
  end
  return edit_handler.IsDraggingDecoration == true
end

return M
