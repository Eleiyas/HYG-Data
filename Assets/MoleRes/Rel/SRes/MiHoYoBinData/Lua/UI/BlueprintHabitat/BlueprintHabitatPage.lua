local M = G.Class("BlueprintHabitatPage", G.UIWindow)
local base = G.UIWindow
local habitat_panel_cls = "UI/BlueprintHabitat/HabitatSubPanel"
local blueprint_panel_cls = "UI/BlueprintHabitat/BlueprintSubPanel"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/BlueprintHabitatPage"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
  self._habitat_panel = self:add_panel_async(habitat_panel_cls, nil, self._trans_sub_panels)
end

function M:_ensure_blueprint_panel()
  if self._blueprint_panel then
    return
  end
  self._blueprint_panel = self:add_panel_async(blueprint_panel_cls, nil, self._trans_sub_panels)
end

function M:on_open()
  base.on_open(self)
  self:_switch_tab(self:_get_open_tab())
  self:_refresh_blueprint_lock()
end

function M:_refresh_blueprint_lock()
  UIUtil.set_active(self._trans_blueprint_lock, not new_blueprint_module:is_unlocked())
end

function M:_refresh_architect_info()
  local cur_level, next_diff, next_need = blueprint_habitat_module:get_architect_level()
  UIUtil.set_text(self._txt_lv_num, tostring(cur_level))
  local cfg = blueprint_habitat_module:get_architect_cur_level_cfg()
  if cfg == nil then
    return
  end
  if next_need == 0 then
    self._slider_architect.value = 1
  else
    self._slider_architect.value = 1 - next_diff / next_need
  end
  local red_state = RedPointType.None
  if CsHabitatModuleUtil.HasAnyArchitectLevelRewardNotClaimed() then
    red_state = RedPointType.GiftRP
  end
  self._red_point_architect:ShowRedPoint(red_state)
end

function M:_refresh_habitat_red_point()
  local red_state = RedPointType.None
  if CsHabitatModuleUtil.HasAnyHabitatRestoredRewardNotClaimed() then
    red_state = RedPointType.GiftRP
  end
  if red_state == RedPointType.None and blueprint_habitat_module:has_any_habitat_unlock_not_recorded() then
    red_state = RedPointType.NewRp
  end
  self._red_point_habitat:ShowRedPoint(red_state)
end

function M:_refresh_blueprint_red_point()
  local red_state = RedPointType.None
  if new_blueprint_module:has_any_blueprint_unlock_not_recorded() and new_blueprint_module:is_unlocked() then
    red_state = RedPointType.NewRp
  end
  self._red_point_blueprint:ShowRedPoint(red_state)
end

function M:_get_open_tab()
  local tab = self._extra_data and self._extra_data.tab
  return tab or blueprint_habitat_module.default_tab
end

function M:_switch_tab(tab)
  if tab == blueprint_habitat_module.tab.blueprint then
    self._tog_habitat.isOnValue = false
    self._tog_blueprint.isOnValue = true
    self:_show_blueprint()
  else
    self._tog_habitat.isOnValue = true
    self._tog_blueprint.isOnValue = false
    self:_show_habitat()
  end
end

function M:_show_habitat()
  self._habitat_panel:change_state(EUIState.Show)
  if self._blueprint_panel then
    self._blueprint_panel:change_state(EUIState.Hide)
  end
end

function M:_show_blueprint()
  if not new_blueprint_module:is_unlocked() then
    UIUtil.show_tips_by_text_id("Blueprint_UI_001", new_blueprint_module:get_unlock_architect_level())
    self._tog_habitat.isOn = true
    return
  end
  self._habitat_panel:change_state(EUIState.Hide)
  self:_ensure_blueprint_panel()
  self._blueprint_panel:change_state(EUIState.Show)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_architect_info()
  self:_refresh_habitat_red_point()
  self:_refresh_blueprint_red_point()
end

function M:on_disable()
  base.on_disable(self)
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

function M:bind_callbacks()
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._tog_habitat, function(is_on)
    if is_on then
      self:_show_habitat()
      self:_refresh_habitat_red_point()
      self:_refresh_blueprint_red_point()
    end
  end)
  self:bind_callback(self._tog_blueprint, function(is_on)
    if is_on then
      self:_show_blueprint()
      self:_refresh_habitat_red_point()
      self:_refresh_blueprint_red_point()
    end
  end)
  self:bind_callback(self._btn_architect, function()
    blueprint_habitat_module:open_architect_award_page()
  end)
  self:bind_callback(self._btn_help, function()
    common_ui_module:show_introduction_dialog(common_ui_module.introduction_dialog_type.habitat_blueprint)
  end)
end

return M
