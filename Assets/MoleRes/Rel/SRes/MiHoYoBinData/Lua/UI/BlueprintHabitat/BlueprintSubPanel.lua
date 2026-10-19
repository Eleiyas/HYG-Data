local M = G.Class("BlueprintSubPanel", G.UIPanel)
local base = G.UIPanel
local official_item_cls = "UI/BlueprintHabitat/BlueprintOfficialItem"
local custom_item_cls = "UI/BlueprintHabitat/BlueprintCustomItem"
local empty_state = {has_data = 0, no_data = 1}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/bluePrintSubPanel"
  self._official_items = {}
  self._mine_items = {}
  self._official_count = 0
  self._mine_count = 0
  self._selected_tab = new_blueprint_module.TAB_STATE.official
  self._ui_state_group = nil
  self._ui_state_group_empty = nil
  self._tog_official = nil
  self._tog_custom = nil
  self._tog_copied = nil
  self._list_official = nil
  self._list_custom = nil
  self._txt_slot = nil
  self._trans_lock = nil
  self._trans_lock_copied = nil
  self._btn_create_blueprint = nil
  self._btn_import = nil
  self._btn_find_more = nil
end

function M:on_create()
  base.on_create(self)
  
  function self._on_copied_item_click_cb(data)
    self:_on_copied_item_click(data)
  end
  
  self:_bind_callbacks()
end

function M:on_open()
  base.on_open(self)
  local tab = self._extra_data and self._extra_data.tab
  self._selected_tab = tab or new_blueprint_module.TAB_STATE.official
end

function M:on_enable()
  base.on_enable(self)
  self:_apply_selected_tab()
  self:_refresh_official_list()
  self:_refresh_mine_list()
  self:_refresh_slot_text()
  self:_refresh_tab_lock()
  self:_refresh_official_red_point()
  self:_refresh_mine_stat()
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
  self:add_evt_listener(EventID.WorldEdit.LuaUI.NewBlueprintDataChanged, pack(self, M._on_custom_blueprint_changed))
  self:add_evt_listener(EventID.WorldEdit.LuaUI.NewBlueprintUnlockedChanged, pack(self, M._on_official_unlocked_changed))
  self:add_evt_listener(EventID.WorldEdit.LuaUI.CopiedBlueprintDataChanged, pack(self, M._on_copied_blueprint_changed))
end

function M:_bind_callbacks()
  local tab_state = new_blueprint_module.TAB_STATE
  self:_bind_tab_callback(self._tog_official, tab_state.official)
  self:_bind_tab_callback(self._tog_custom, tab_state.custom)
  self:_bind_tab_callback(self._tog_copied, tab_state.copied)
  if not_null(self._btn_create_blueprint) then
    self:bind_callback(self._btn_create_blueprint, pack(self, M._on_btn_create_blueprint_click))
  end
  if not_null(self._btn_import) then
    self:bind_callback(self._btn_import, pack(self, M._on_btn_import_click))
  end
  if not_null(self._btn_find_more) then
    self:bind_callback(self._btn_find_more, pack(self, M._on_btn_find_more_click))
  end
end

function M:_bind_tab_callback(toggle, tab)
  if is_null(toggle) then
    return
  end
  self:bind_callback(toggle, function(is_on)
    if is_on then
      self:_on_tab_clicked(tab)
    end
  end)
end

function M:_on_tab_clicked(tab)
  if not self:_is_tab_unlocked(tab) then
    UIUtil.show_tips_by_text_id("Blueprint_UI_001", new_blueprint_module:get_custom_unlock_architect_level())
    self:_fallback_to_official_tab()
    return
  end
  self._selected_tab = tab
  self:_switch_state(tab)
  self:_refresh_mine_list()
  self:_refresh_slot_text()
  self:_refresh_mine_stat()
end

function M:_is_tab_unlocked(tab)
  local tab_state = new_blueprint_module.TAB_STATE
  if tab == tab_state.custom then
    return new_blueprint_module:is_custom_blueprint_unlocked()
  end
  if tab == tab_state.copied then
    return new_blueprint_module:is_copied_blueprint_unlocked()
  end
  return true
end

function M:_fallback_to_official_tab()
  local tab_state = new_blueprint_module.TAB_STATE
  self._selected_tab = tab_state.official
  if not_null(self._tog_official) then
    self._tog_official.isOn = true
  end
  self:_switch_state(tab_state.official)
end

function M:_on_btn_create_blueprint_click()
  if new_blueprint_module:intercept_if_custom_slot_full() then
    return
  end
  if not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateSceneOverheadEdit) then
    UIUtil.show_tips_by_text_id("Blueprint_PlanetBuildNotUnlock")
    return
  end
  if not world_editor_module:check_can_enter_world_editor() then
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("Blueprint_CreateConfirm"), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(pack(self, M._confirm_create_blueprint))
  popup:show()
end

function M:_confirm_create_blueprint()
  UIManagerInstance:close_all_stack_window_without_main_page()
  world_editor_module:enter_world_editor(true)
end

function M:_on_btn_import_click()
  new_blueprint_module:open_import_code_dialog()
end

function M:_on_btn_find_more_click()
  if not new_blueprint_module:check_little_corner_unlocked() then
    return
  end
  little_corner_module:open_little_corner_page_with_tab(little_corner_module.little_corner_category.blueprint, little_corner_module.post_source.blueprint_manual)
end

function M:_apply_selected_tab()
  local tab_state = new_blueprint_module.TAB_STATE
  if not self:_is_tab_unlocked(self._selected_tab) then
    self._selected_tab = tab_state.official
  end
  if not_null(self._tog_official) then
    self._tog_official.isOnValue = self._selected_tab == tab_state.official
  end
  if not_null(self._tog_custom) then
    self._tog_custom.isOnValue = self._selected_tab == tab_state.custom
  end
  if not_null(self._tog_copied) then
    self._tog_copied.isOnValue = self._selected_tab == tab_state.copied
  end
  self:_switch_state(self._selected_tab)
end

function M:_refresh_tab_lock()
  if not_null(self._trans_lock) then
    UIUtil.set_active(self._trans_lock, not new_blueprint_module:is_custom_blueprint_unlocked())
  end
  if not_null(self._trans_lock_copied) then
    UIUtil.set_active(self._trans_lock_copied, not new_blueprint_module:is_copied_blueprint_unlocked())
  end
end

function M:_switch_state(state)
  if not_null(self._ui_state_group) then
    self._ui_state_group:SetState(state)
  end
  self:_refresh_empty_state()
end

function M:_refresh_empty_state()
  if is_null(self._ui_state_group_empty) then
    return
  end
  local count = self._selected_tab == new_blueprint_module.TAB_STATE.official and self._official_count or self._mine_count
  self._ui_state_group_empty:SetState(0 < count and empty_state.has_data or empty_state.no_data)
end

function M:_refresh_official_list()
  if is_null(self._list_official) then
    return
  end
  local cfg_list = new_blueprint_module:get_discovered_sorted_list()
  self._official_count = #cfg_list
  for index = 1, #cfg_list do
    local item = self._official_items[index]
    if item == nil then
      item = self:_create_official_item()
      self._official_items[index] = item
    end
    if item ~= nil then
      item:set_active(true)
      item:refresh(cfg_list[index])
    end
  end
  for i = #cfg_list + 1, #self._official_items do
    local item = self._official_items[i]
    if item ~= nil then
      item:set_active(false)
    end
  end
  self:_refresh_empty_state()
end

function M:_create_official_item()
  local obj = self._list_official:AddItem(0)
  if is_null(obj) then
    return nil
  end
  return self:add_panel(official_item_cls, obj)
end

function M:_refresh_mine_list()
  if is_null(self._list_custom) then
    return
  end
  local is_copied_tab = self._selected_tab == new_blueprint_module.TAB_STATE.copied
  local data_list = is_copied_tab and new_blueprint_module:get_copied_sorted_list() or new_blueprint_module:get_custom_sorted_list()
  local on_click = is_copied_tab and self._on_copied_item_click_cb or nil
  self._mine_count = #data_list
  for index = 1, #data_list do
    local item = self._mine_items[index]
    if item == nil then
      item = self:_create_mine_item()
      self._mine_items[index] = item
    end
    if item ~= nil then
      item:set_active(true)
      item:refresh(data_list[index], on_click)
    end
  end
  for i = #data_list + 1, #self._mine_items do
    local item = self._mine_items[i]
    if item ~= nil then
      item:set_active(false)
    end
  end
  self:_refresh_empty_state()
end

function M:_create_mine_item()
  local obj = self._list_custom:AddItem(0)
  if is_null(obj) then
    return nil
  end
  return self:add_panel(custom_item_cls, obj)
end

function M:_refresh_mine_stat()
  local tab_state = new_blueprint_module.TAB_STATE
  local domain_define = new_blueprint_module.BLUEPRINT_DOMAIN
  if self._selected_tab == tab_state.custom then
    new_blueprint_module:refresh_stat_by_domain(domain_define.custom)
  elseif self._selected_tab == tab_state.copied then
    new_blueprint_module:refresh_stat_by_domain(domain_define.copied)
  end
end

function M:_on_copied_item_click(data)
  if data == nil then
    return
  end
  UIManagerInstance:open("UI/BlueprintHabitat/BlueprintCopiedInfoPage", {
    bp_guid = data.BpGuid
  })
end

function M:_on_custom_blueprint_changed(arg)
  if self._selected_tab == new_blueprint_module.TAB_STATE.custom then
    self:_refresh_mine_list()
    self:_refresh_slot_text()
  end
end

function M:_on_copied_blueprint_changed(arg)
  if self._selected_tab == new_blueprint_module.TAB_STATE.copied then
    self:_refresh_mine_list()
    self:_refresh_slot_text()
  end
end

function M:_on_official_unlocked_changed(arg)
  self:_refresh_official_list()
  self:_refresh_official_red_point()
end

function M:_refresh_official_red_point()
  local red_state = RedPointType.None
  if new_blueprint_module:has_any_blueprint_unlock_not_recorded() then
    red_state = RedPointType.NewRp
  end
  self._red_point_official:ShowRedPoint(red_state)
end

function M:_refresh_slot_text()
  if is_null(self._txt_slot) then
    return
  end
  local used, limit, text_id
  if self._selected_tab == new_blueprint_module.TAB_STATE.copied then
    used = new_blueprint_module:get_copied_used_count()
    limit = new_blueprint_module:get_copied_slot_limit()
    text_id = "Blueprint_UI_019"
  else
    used = new_blueprint_module:get_custom_used_count()
    limit = new_blueprint_module:get_custom_slot_limit()
    text_id = "Blueprint_UI_008"
  end
  UIUtil.set_text(self._txt_slot, UIUtil.get_text_by_id(text_id, used, limit))
end

return M
