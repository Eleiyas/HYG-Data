local M = G.Class("MobileHUDCustomPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MobileHUDCustom/MobileHUDCustomPage"
  self.config.type = EUIType.Page
  self._is_hide_mode = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_init_controller()
  self:_refresh_slider_values()
end

function M:on_disable()
  base.on_disable(self)
  if not is_null(self._mobile_hud_customize_controller) then
    self._mobile_hud_customize_controller.onSelectionChanged = nil
  end
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_exit, pack(self, M._on_btn_exit_click))
  self:bind_callback(self._btn_reset, pack(self, M._on_btn_reset_click))
  self:bind_callback(self._btn_save, pack(self, M._on_btn_save_click))
  self:bind_callback(self._btn_hide, pack(self, M._on_btn_hide_click))
  self:bind_callback(self._btn_show, pack(self, M._on_btn_show_click))
  if not is_null(self._slider_horizontal_slider_size) then
    self:bind_callback(self._slider_horizontal_slider_size, pack(self, M._on_slider_size_changed))
  end
  if not is_null(self._slider_horizontal_slider_alpha) then
    self:bind_callback(self._slider_horizontal_slider_alpha, pack(self, M._on_slider_alpha_changed))
  end
end

function M:_on_btn_exit_click()
  if is_null(self._mobile_hud_customize_controller) then
    self:close_self()
    return
  end
  if not self._mobile_hud_customize_controller:IsLayoutModified() then
    self._mobile_hud_customize_controller:DeselectCurrent()
    self:close_self()
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("MobileHUDCustom_Exit_Tip"), UIUtil.get_text_by_id("MobileHUDCustom_Exit_Save_Quit"), UIUtil.get_text_by_id("MobileHUDCustom_Exit_No_Save_Quit"), nil)
  popup:set_callbacks(pack(self, M._save_and_exit), pack(self, M._discard_and_exit))
  popup:set_style(ConfirmPopupStyle.NormalWithClose)
  popup:show()
end

function M:_on_btn_reset_click()
  if is_null(self._mobile_hud_customize_controller) then
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("MobileHUDCustom_Reset_Tip"), UIUtil.get_text_by_id("MobileHUDCustom_Confirm"), UIUtil.get_text_by_id("MobileHUDCustom_Cancel"), nil)
  popup:set_callbacks(pack(self, M._do_reset))
  popup:show()
end

function M:_on_btn_save_click()
  if is_null(self._mobile_hud_customize_controller) then
    return
  end
  if not self._mobile_hud_customize_controller:IsLayoutModified() then
    UIUtil.show_tips_by_text_id("MobileHUDCustom_Reset_No_Change_Tip")
    return
  end
  if self._mobile_hud_customize_controller:HasAnyConflict() then
    UIUtil.show_tips_by_text_id("MobileHUDCustom_Save_Fail_Tip")
    return
  end
  self:_save_layout()
  UIUtil.show_tips_by_text_id("MobileHUDCustom_Save_Tip")
end

function M:_on_btn_hide_click()
  self._is_hide_mode = not self._is_hide_mode
  if not is_null(self._ui_state_change_top) then
    self._ui_state_change_top:SetState(self._is_hide_mode and 1 or 0)
  end
end

function M:_on_btn_show_click()
  self._is_hide_mode = false
  if not is_null(self._ui_state_change_top) then
    self._ui_state_change_top:SetState(0)
  end
end

function M:_on_slider_size_changed(value)
  if is_null(self._mobile_hud_customize_controller) then
    return
  end
  local range = self._mobile_hud_customize_controller.scaleRange
  local scale = range.min + (range.max - range.min) * (value or 0)
  local element = self._mobile_hud_customize_controller:GetCurrentSelected()
  if not is_null(element) then
    element.rootTransform.localScale = Vector3.one * scale
    self._mobile_hud_customize_controller:RefreshConflictForCurrent()
  end
  self:_update_size_text(scale)
end

function M:_on_slider_alpha_changed(value)
  if is_null(self._mobile_hud_customize_controller) then
    return
  end
  local range = self._mobile_hud_customize_controller.alphaRange
  local alpha = range.min + (range.max - range.min) * (value or 0)
  local element = self._mobile_hud_customize_controller:GetCurrentSelected()
  if not is_null(element) and not is_null(element.canvasGroup) then
    element.canvasGroup.alpha = alpha
  end
  self:_update_alpha_text(alpha)
end

function M:_save_and_exit()
  if is_null(self._mobile_hud_customize_controller) then
    self:close_self()
    return
  end
  if self._mobile_hud_customize_controller:HasAnyConflict() then
    UIUtil.show_tips_by_text_id("MobileHUDCustom_Save_Fail_Tip")
    return
  end
  self:_save_layout()
  self._mobile_hud_customize_controller:DeselectCurrent()
  UIUtil.show_tips_by_text_id("MobileHUDCustom_Save_Tip")
  self:close_self()
end

function M:_discard_and_exit()
  if not is_null(self._mobile_hud_customize_controller) then
    self._mobile_hud_customize_controller:LoadFromStorage()
    self._mobile_hud_customize_controller:DeselectCurrent()
  end
  self:close_self()
end

function M:_do_reset()
  if is_null(self._mobile_hud_customize_controller) then
    return
  end
  self._mobile_hud_customize_controller:ResetAll()
  self:_refresh_slider_values()
end

function M:_init_controller()
  if is_null(self._mobile_hud_customize_controller) then
    Logger.LogWarning("[MobileHUDCustomPage] controller is null")
    return
  end
  self._mobile_hud_customize_controller:LoadFromStorage()
  
  function self._mobile_hud_customize_controller.onSelectionChanged()
    self:_refresh_slider_values()
  end
end

function M:_save_layout()
  local layout_changes = self._mobile_hud_customize_controller:SaveToStorageAndGetLayoutChanges()
  self:_report_layout_changes(layout_changes)
end

function M:_report_layout_changes(layout_changes)
  if is_null(layout_changes) then
    return
  end
  for i = 0, layout_changes.Count - 1 do
    local change = layout_changes[i]
    CsBuriedPointReportManagerUtil.ReportActionFromLuaTable(BuriedPointReportActionEnum.mobile_hud_layout_adjust, "MobileHUDLayoutAdjust", {
      hotkey = change.hotkey,
      position_before = self:_format_position(change.positionBeforeX, change.positionBeforeY),
      position_after = self:_format_position(change.positionAfterX, change.positionAfterY),
      size_before = self:_format_ratio(change.sizeBefore),
      size_after = self:_format_ratio(change.sizeAfter),
      transparence_before = self:_format_ratio(change.transparenceBefore),
      transparence_after = self:_format_ratio(change.transparenceAfter)
    })
  end
end

function M:_format_position(x, y)
  return string.format("%.3f,%.3f", x, y)
end

function M:_format_ratio(value)
  return string.format("%.3f", value)
end

function M:_refresh_slider_values()
  if is_null(self._mobile_hud_customize_controller) then
    return
  end
  local scale_range = self._mobile_hud_customize_controller.scaleRange
  local alpha_range = self._mobile_hud_customize_controller.alphaRange
  local element = self._mobile_hud_customize_controller:GetCurrentSelected()
  local scale, alpha
  if is_null(element) then
    scale = scale_range.defaultValue
    alpha = alpha_range.defaultValue
  else
    scale = element.rootTransform.localScale.x
    alpha = 1
    if not is_null(element.canvasGroup) then
      alpha = element.canvasGroup.alpha
    end
  end
  local slider_size_value = (scale - scale_range.min) / (scale_range.max - scale_range.min)
  if not is_null(self._slider_horizontal_slider_size) then
    self._slider_horizontal_slider_size.value = slider_size_value
  end
  self:_update_size_text(scale)
  local slider_alpha_value = (alpha - alpha_range.min) / (alpha_range.max - alpha_range.min)
  if not is_null(self._slider_horizontal_slider_alpha) then
    self._slider_horizontal_slider_alpha.value = slider_alpha_value
  end
  self:_update_alpha_text(alpha)
end

function M:_update_size_text(scale)
  if is_null(self._txt_size) then
    return
  end
  local percent = math.floor(scale * 100 + 0.5)
  UIUtil.set_text(self._txt_size, string.format("%d%%", percent))
end

function M:_update_alpha_text(alpha)
  if is_null(self._txt_alpha) then
    return
  end
  local percent = math.floor(alpha * 100 + 0.5)
  UIUtil.set_text(self._txt_alpha, string.format("%d%%", percent))
end

return M
