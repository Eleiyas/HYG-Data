blueprint_habitat_module = blueprint_habitat_module or {}

function blueprint_habitat_module:add_event()
  blueprint_habitat_module:remove_event()
  self._events = {}
  self._events[EventID.OnHabitatDiscovered] = pack(self, blueprint_habitat_module.show_habitat_discover_tip)
  self._events[EventID.OnHabitatRestored] = pack(self, blueprint_habitat_module.show_habitat_restore_tip)
  self._events[EventID.LuaShowArchitectExpChangedTips] = pack(self, blueprint_habitat_module.show_blueprint_habitat_exp_up_tip)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function blueprint_habitat_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function blueprint_habitat_module:open_main_page(tab)
  UIManagerInstance:open("UI/BlueprintHabitat/BlueprintHabitatPage", {
    tab = tab or blueprint_habitat_module.default_tab
  })
end

function blueprint_habitat_module:close_main_page()
  local page = UIManagerInstance:is_show("UI/BlueprintHabitat/BlueprintHabitatPage")
  if page ~= nil then
    UIManagerInstance:close(page.guid)
  end
end

function blueprint_habitat_module:open_habitat_info_page(habitat_id, open_by_main_page)
  if habitat_id == nil or habitat_id == 0 then
    return
  end
  UIManagerInstance:open("UI/BlueprintHabitat/Habitat/HabitatInfoPage", {
    habitat_id = habitat_id,
    open_by_main_page = open_by_main_page or false
  })
end

function blueprint_habitat_module:start_site_selection(habitat_id)
  if habitat_id == nil or habitat_id == 0 then
    return
  end
  return CsHabitatModuleUtil.StartSiteSelection(habitat_id)
end

function blueprint_habitat_module:show_habitat_discover_tip(habitat_id)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.blueprint_habitat_discover, {id = habitat_id, is_habitat = true})
end

function blueprint_habitat_module:show_habitat_restore_tip(habitat_id)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.habitat_restore, {habitat_id = habitat_id})
end

function blueprint_habitat_module:open_architect_award_page()
  UIManagerInstance:open("UI/BlueprintHabitat/BlueprintArchitect/BlueprintArchitectAwardPage")
end

function blueprint_habitat_module:show_architect_level_up_dialog(after_level)
  if CsPerformanceManagerUtil.IsPerformanceShowing() then
    return
  end
  if after_level == nil or after_level <= 0 then
    return
  end
  UIManagerInstance:open("UI/BlueprintHabitat/BlueprintLevelUpDialog", {level = after_level})
end

function blueprint_habitat_module:show_blueprint_habitat_exp_up_tip(level_up_to)
  if CsPerformanceManagerUtil.IsPerformanceShowing() then
    return
  end
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.blueprint_habitat_exp_up_tip, {
    level_up_to = level_up_to or 0
  })
end

return blueprint_habitat_module
