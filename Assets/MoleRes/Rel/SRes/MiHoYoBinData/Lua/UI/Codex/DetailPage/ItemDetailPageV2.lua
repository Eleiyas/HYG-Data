local M = G.Class("ItemDetailPageV2", G.UIWindow)
local base = G.UIWindow
local DetailScrollBuilder = require("UI/Codex/DetailPage/V2/DetailScrollBuilder")
local search_mixin = require("UI/Codex/Search/CodexSearchMixin")
local NPC_CLOTH_SIZE_ITEM_CLS = "UI/NpcCloth/NpcClothSizeItem"
local FRUIT_KING_COLOR_TAB_ITEM_CLS = "UI/Codex/DetailPage/FruitKingColorTabItem"
local MODEL_PREVIEW_GALAXY_ID_COMMON = 0
local _bg_mat_path = {
  [CodexDataType.Cloth] = "Materials/UIMaterials/UI_SceneMap_CodexInfoClothing",
  [CodexDataType.Plant] = "Materials/UIMaterials/UI_SceneMap_CodexInfoPlants",
  [CodexDataType.Food] = "Materials/UIMaterials/UI_SceneMap_CodexInfoDishes",
  [CodexDataType.Furniture] = "Materials/UIMaterials/UI_SceneMap_CodexInfoFurniture",
  [CodexDataType.Item] = "Materials/UIMaterials/UI_SceneMap_CodexInfoMaterial"
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexInfoPageV2"
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_CodexInfo"
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  self.item_data = nil
  self.group_index = 0
  self.sequence = 0
  self._is_unlocked = false
  self._sub_type_controller = nil
  self._view_strategy = nil
  self._enter_type = nil
  self._curr_enter_type = nil
  self._scroll_builder = nil
  self._npc_cloth_size_item = nil
  self._search_panel = nil
  self._search_panel_root = nil
  self._fruit_king_color_preview_options = {}
  self._tree_season_preview_options = {}
  self._selected_fruit_king_color_option = nil
  self._selected_tree_season_option = nil
  self._display_item_data = nil
  self._fruit_king_color_tab_items = {}
  self._is_calendar_season_menu_open = false
  self._has_applied_tree_season_preview = false
end

function M:on_create()
  base.on_create(self)
  self._scroll_builder = G.New(DetailScrollBuilder)
  self._scroll_builder:init(self)
  self:_add_ui_listener()
  search_mixin.ensure_search_panel(self, function()
    return {include_package = false}
  end)
  if self._search_panel then
    self._search_panel:set_outside_click_callback(function(panel)
      panel:collapse()
    end)
  end
  if not_null(self._trans_info_basic) then
    self._detail_scroll_rect = self._trans_info_basic:GetComponentInParent(typeof(CS.UnityEngine.UI.ScrollRect))
  end
end

function M:register_events()
  base.register_events(self)
  self._evt_codex_data_update = pack(self, M._on_codex_data_update)
  self:add_evt_listener(EventID.CodexDataUpdate, self._evt_codex_data_update)
  self._evt_all_codex_data_update = pack(self, M._on_all_codex_data_update)
  self:add_evt_listener(EventID.OnAllCodexDataUpdate, self._evt_all_codex_data_update)
  self:add_lua_listener(lua_event_module.event_type.system_jump_by_source_item_click, function()
    if self:_is_search_mode() then
      self:_close_search_result_page()
      self:close_self()
    end
  end)
end

function M:on_enable()
  base.on_enable(self)
  self:refresh()
  self:_guard_model_reload()
end

function M:on_disable()
  base.on_disable(self)
  self:_close_calendar_season_menu()
  self:_close_search_panel(true)
  self:_cancel_model_guard()
  self:_hide_model_preview()
  ModelPreviewManagerIns:set_use_separate_scale(true)
  self._enter_type = nil
  self._from_search_navigation = false
end

function M:_guard_model_reload()
  self:_cancel_model_guard()
  self._model_guard_co = CsCoroutineManagerUtil.InvokeAfterFrames(2, function()
    self._model_guard_co = nil
    if self.item_data then
      self:_refresh_left_display()
    end
  end)
end

function M:_cancel_model_guard()
  if self._model_guard_co then
    CsCoroutineManagerUtil.StopCoroutine(self._model_guard_co)
    self._model_guard_co = nil
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.MouseScroll, function(self, action)
    self:_on_mouse_scroll(action)
  end)
end

function M:_close_search_panel(silent)
  search_mixin.close_search_panel(self, silent)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_left, function()
    self:_on_btn_left()
  end)
  self:bind_callback(self._btn_right, function()
    self:_on_btn_right()
  end)
  self.binder:BindViewCallback(self._trans_model, EventTriggerType.PointerDown, function(evt)
    self:_on_pointer_down(evt)
  end)
  self.binder:BindViewCallback(self._trans_model, EventTriggerType.PointerUp, function(evt)
    self:_on_pointer_up(evt)
  end)
  self.binder:BindViewCallback(self._trans_model, EventTriggerType.Drag, function(evt)
    self:_on_drag(evt)
  end)
  self:bind_callback(self._btn_full_close, function()
    self:_close_food_tooltip()
  end)
  self:bind_callback(self._btn_full_close_bg, function()
    self:_close_food_tooltip()
  end)
  UIUtil.set_active(self._btn_full_close, false)
  UIUtil.set_active(self._btn_full_close_bg, false)
  if not_null(self._dropdown_dark) then
    self._dropdown_dark.enabled = false
    self.binder:BindViewCallback(self._dropdown_dark.transform, EventTriggerType.PointerClick, pack(self, M._on_calendar_season_dropdown_click))
  end
end

function M:_on_calendar_season_dropdown_click()
  if self._is_calendar_season_menu_open then
    self:_close_calendar_season_menu()
    return
  end
  local options = self._tree_season_preview_options or {}
  if #options == 0 then
    return
  end
  local selected_id = self._selected_tree_season_option and self._selected_tree_season_option.OptionId or 0
  local menus = {}
  for _, option in ipairs(options) do
    local option_id = option.OptionId
    table.insert(menus, {
      desc = self:_get_tree_season_option_name(option),
      valid = true,
      selected = option_id == selected_id,
      close = option.IsUnlocked,
      call_back_action = function()
        self:on_plant_calendar_season_selected(option_id)
      end
    })
  end
  self._is_calendar_season_menu_open = true
  UIManagerInstance:open("UI/Social/CommonMenuDialog", {
    show_position = CsUIUtil.CalculateCanvasLocalPosition(self._dropdown_dark.transform, UIManagerInstance.canvas_rect, 0.5, 1),
    state = 1,
    menus = menus,
    close_callback = function()
      self._is_calendar_season_menu_open = false
    end
  })
end

function M:_close_calendar_season_menu()
  if not self._is_calendar_season_menu_open then
    return
  end
  local dialog = UIManagerInstance:is_show("UI/Social/CommonMenuDialog")
  if not is_null(dialog) then
    dialog:_on_btn_close_click()
  else
    self._is_calendar_season_menu_open = false
  end
end

function M:_on_btn_left()
  self:_close_food_tooltip()
  if self._sub_type_controller == nil then
    return
  end
  local gi, prev_seq = self._sub_type_controller:get_prev_group_sequence(self.group_index, self.sequence)
  local prev_data = self._sub_type_controller:get_data_by_group_sequence(gi, prev_seq)
  if is_null(prev_data) then
    return
  end
  local data = {
    item_id = prev_data.IdCfg.id,
    enter_type = codex_module.codex_page_enter_type.codex_page_switch
  }
  if self:_init_data(data) then
    self:set_extra_data(data)
    self:_refresh_page()
  end
end

function M:_on_btn_right()
  self:_close_food_tooltip()
  if self._sub_type_controller == nil then
    return
  end
  local gi, next_seq = self._sub_type_controller:get_next_group_sequence(self.group_index, self.sequence)
  local next_data = self._sub_type_controller:get_data_by_group_sequence(gi, next_seq)
  if is_null(next_data) then
    return
  end
  local data = {
    item_id = next_data.IdCfg.id,
    enter_type = codex_module.codex_page_enter_type.codex_page_switch
  }
  if self:_init_data(data) then
    self:set_extra_data(data)
    self:_refresh_page()
  end
end

function M:_is_search_mode()
  return self._enter_type == codex_module.codex_page_enter_type.codex_search
end

function M:_refresh_nav_buttons()
  local hide = self:_is_search_mode() or self._enter_type == codex_module.codex_page_enter_type.tracking_jump
  if not_null(self._btn_left) then
    UIUtil.set_active(self._btn_left, not hide)
  end
  if not_null(self._btn_right) then
    UIUtil.set_active(self._btn_right, not hide)
  end
  if not_null(self._trans_search_group) then
    UIUtil.set_active(self._trans_search_group, not hide)
  end
  if not_null(self._btn_open_search) then
    UIUtil.set_active(self._btn_open_search, not hide)
  end
  if not_null(self._btn_search) then
    UIUtil.set_active(self._btn_search, not hide)
  end
end

function M:_on_mouse_scroll(action)
  if not self._is_unlocked then
    return
  end
  if self.item_data and codex_module:is_package_sub_type(self.item_data.SubType) then
    return
  end
  if not ModelPreviewManagerIns._model_showing then
    return
  end
  local var = InputManagerIns:get_axis(ActionType.Act.MouseScroll)
  if is_null(var) or var == 0 then
    return
  end
end

function M:_on_pointer_down(evt)
  ModelPreviewManagerIns:on_pointer_down_on_model(evt)
  self:_close_food_tooltip()
end

function M:_on_drag(evt)
  ModelPreviewManagerIns:on_drag_model(evt)
end

function M:_on_pointer_up(evt)
  ModelPreviewManagerIns:on_pointer_up_on_model(evt)
end

function M:refresh()
  local extra_data = self:get_extra_data()
  if not self:_init_data(extra_data) then
    return
  end
  self:_refresh_page()
end

function M:_init_data(extra_data)
  if extra_data == nil or extra_data.item_id == nil then
    return false
  end
  local item_data = codex_module:get_data_by_id(extra_data.item_id)
  if is_null(item_data) then
    return false
  end
  local new_enter_type = extra_data.enter_type
  if self._enter_type == codex_module.codex_page_enter_type.codex_search and new_enter_type == codex_module.codex_page_enter_type.item_detail_dialog then
    self:_close_search_result_page()
    self._enter_type = new_enter_type
    self._from_search_navigation = true
  else
    self._enter_type = self._enter_type or new_enter_type
  end
  self._curr_enter_type = new_enter_type
  self.item_data = item_data
  self._view_strategy = codex_module:get_type_view_strategy(item_data.Type)
  self._sub_type_controller = codex_module:get_sub_type_controller(item_data.Type, item_data.SubType)
  self.group_index, self.sequence = self._sub_type_controller:get_group_sequence_by_id(extra_data.item_id)
  if self.group_index == 0 or self.sequence == 0 then
    return false
  end
  self._is_unlocked = item_data.IsUnlocked
  self:_init_plant_preview_options()
  return true
end

local function find_plant_preview_option(options, option_id)
  for _, option in ipairs(options or {}) do
    if option.OptionId == option_id then
      return option
    end
  end
  return nil
end

function M:_init_plant_preview_options(preserve_selection)
  local selected_fruit_id = preserve_selection and self._selected_fruit_king_color_option and self._selected_fruit_king_color_option.OptionId or 0
  local selected_season_id = preserve_selection and self._selected_tree_season_option and self._selected_tree_season_option.OptionId or 0
  self._fruit_king_color_preview_options = {}
  self._tree_season_preview_options = {}
  self._selected_fruit_king_color_option = nil
  self._selected_tree_season_option = nil
  self:_close_calendar_season_menu()
  if self.item_data.Type == CodexDataType.Plant then
    self._fruit_king_color_preview_options = codex_module:get_fruit_king_color_preview_options(self.item_data)
    self._tree_season_preview_options = codex_module:get_tree_season_preview_options(self.item_data)
    if 0 < selected_fruit_id then
      self._selected_fruit_king_color_option = find_plant_preview_option(self._fruit_king_color_preview_options, selected_fruit_id)
    end
    if self._selected_fruit_king_color_option == nil and 0 < selected_season_id then
      local selected_season = find_plant_preview_option(self._tree_season_preview_options, selected_season_id)
      if selected_season and selected_season.IsUnlocked then
        self._selected_tree_season_option = selected_season
      end
    end
    if self._selected_fruit_king_color_option == nil and self._selected_tree_season_option == nil then
      self._selected_fruit_king_color_option = codex_module:get_default_plant_preview_option(self._fruit_king_color_preview_options)
      if self._selected_fruit_king_color_option == nil then
        self._selected_tree_season_option = codex_module:get_default_plant_preview_option(self._tree_season_preview_options)
      end
    end
  end
  self:_update_plant_display_data()
end

function M:_update_plant_display_data()
  local option = self._selected_fruit_king_color_option or self._selected_tree_season_option
  local display_data
  if option and option.CodexItemId > 0 then
    display_data = codex_module:get_data_by_id(option.CodexItemId)
  elseif option then
    display_data = option.DisplayData
  end
  self._display_item_data = not is_null(display_data) and display_data or self.item_data
end

function M:_get_display_item_data()
  return self._display_item_data or self.item_data
end

function M:_get_display_preview_config_id()
  local option = self._selected_fruit_king_color_option or self._selected_tree_season_option
  if option and option.PreviewConfigId > 0 then
    return option.PreviewConfigId
  end
  local display_data = self:_get_display_item_data()
  return display_data and display_data.IdCfg and display_data.IdCfg.id or 0
end

function M:_is_display_item_unlocked()
  local option = self._selected_fruit_king_color_option or self._selected_tree_season_option
  if option then
    return option.IsUnlocked
  end
  return self._is_unlocked
end

function M:_hide_model_preview()
  ModelPreviewManagerIns:hide()
  self._has_applied_tree_season_preview = false
end

function M:_reset_stale_tree_season_preview()
  if self._has_applied_tree_season_preview and self._selected_tree_season_option == nil then
    self:_hide_model_preview()
  end
end

function M:_on_model_preview_loaded()
  local option = self._selected_tree_season_option
  if not (option ~= nil and option.IsUnlocked) or option.PreviewConfigId == 0 or option.SeasonKey == nil or option.SeasonKey == "" then
    return
  end
  local entity_guid = ModelPreviewManagerIns:get_entity_guid()
  if entity_guid == nil or entity_guid == 0 then
    return
  end
  local entity = EntityUtil.get_entity(entity_guid)
  self._has_applied_tree_season_preview = true
  local success = CsGameplayUtilitiesSeasonUtil.SetModelPreviewSeasonalAppearance(entity, MODEL_PREVIEW_GALAXY_ID_COMMON, option.PreviewConfigId, SeasonalAppearanceType.Season, option.SeasonKey)
  ModelPreviewManagerIns:rebind_if_model_replaced(self._trans_model, option.PreviewConfigId)
  if not success then
    Logger.LogWarning("Failed to set codex tree season preview appearance, configId=" .. tostring(option.PreviewConfigId) .. ", seasonKey=" .. tostring(option.SeasonKey))
  end
end

function M:get_fruit_king_color_preview_options()
  return self._fruit_king_color_preview_options
end

function M:get_selected_fruit_king_color_preview_option()
  return self._selected_fruit_king_color_option
end

function M:get_tree_season_preview_options()
  return self._tree_season_preview_options
end

function M:get_selected_tree_season_preview_option()
  return self._selected_tree_season_option
end

function M:select_fruit_king_color_preview(option_id)
  local option = find_plant_preview_option(self._fruit_king_color_preview_options, option_id)
  if option == nil then
    return false
  end
  if option.IsUnlocked and option.CodexItemId > 0 and codex_module:is_new_item(option.CodexItemId) then
    red_point_module:record_with_id(codex_module.red_point_type_data, option.CodexItemId)
    lua_event_module:send_event(lua_event_module.event_type.on_record_codex_item_red_point, option.CodexItemId)
  end
  self._selected_fruit_king_color_option = option
  self._selected_tree_season_option = nil
  self:_refresh_plant_preview_selection()
  return true
end

function M:select_tree_season_preview(option_id)
  local option = find_plant_preview_option(self._tree_season_preview_options, option_id)
  if option == nil or not option.IsUnlocked then
    return false
  end
  self._selected_tree_season_option = option
  self._selected_fruit_king_color_option = nil
  self:_refresh_plant_preview_selection()
  return true
end

function M:_refresh_plant_preview_selection()
  self:_update_plant_display_data()
  self:_refresh_left_display()
  self:_refresh_sections()
  self:_refresh_plant_preview_item_selection()
  self:_refresh_selected_tree_season_display()
end

function M:on_fruit_king_color_tab_selected(option_id)
  self:select_fruit_king_color_preview(option_id)
end

function M:on_plant_calendar_season_selected(option_id)
  if not self:select_tree_season_preview(option_id) then
    UIUtil.show_tips_by_text_id("Codex_Plant_Season_Locked")
    self:_refresh_plant_preview_item_selection()
  end
end

function M:_on_codex_data_update(data)
  if is_null(data) or is_null(self.item_data) or self.item_data.Type ~= CodexDataType.Plant then
    return
  end
  local item_id = self.item_data.IdCfg and self.item_data.IdCfg.id or 0
  local list_item_id = codex_module:get_codex_list_item_id(self.item_data)
  local updated_item_data = codex_module:get_data_by_id(data.Id)
  if is_null(updated_item_data) or codex_module:get_codex_list_item_id(updated_item_data) ~= list_item_id then
    return
  end
  local refreshed_item_data = codex_module:get_data_by_id(item_id)
  if not_null(refreshed_item_data) then
    self.item_data = refreshed_item_data
  end
  self._is_unlocked = self.item_data.IsUnlocked
  self:_init_plant_preview_options(true)
  self:_refresh_left_display()
  self:_refresh_sections()
  self:_refresh_plant_preview_controls()
end

function M:_on_all_codex_data_update()
  if is_null(self.item_data) or self.item_data.Type ~= CodexDataType.Plant then
    return
  end
  local item_id = self.item_data.IdCfg and self.item_data.IdCfg.id or 0
  local refreshed_item_data = codex_module:get_data_by_id(item_id)
  if is_null(refreshed_item_data) then
    return
  end
  self.item_data = refreshed_item_data
  self._view_strategy = codex_module:get_type_view_strategy(refreshed_item_data.Type)
  self._sub_type_controller = codex_module:get_sub_type_controller(refreshed_item_data.Type, refreshed_item_data.SubType)
  self.group_index, self.sequence = self._sub_type_controller:get_group_sequence_by_id(item_id)
  self._is_unlocked = refreshed_item_data.IsUnlocked
  self:_init_plant_preview_options(true)
  self:_refresh_left_display()
  self:_refresh_sections()
  self:_refresh_plant_preview_controls()
end

function M:_refresh_plant_preview_item_selection()
  local selected_id = self._selected_fruit_king_color_option and self._selected_fruit_king_color_option.OptionId or 0
  local options = self._fruit_king_color_preview_options or {}
  for _, item in ipairs(self._fruit_king_color_tab_items or {}) do
    local option_id = item:get_option_id()
    item:set_selected(option_id == selected_id)
    item:refresh_red_point(find_plant_preview_option(options, option_id))
  end
end

function M:_refresh_fruit_king_color_tabs()
  local options = self._fruit_king_color_preview_options or {}
  local items = self._fruit_king_color_tab_items
  local selected_id = self._selected_fruit_king_color_option and self._selected_fruit_king_color_option.OptionId or 0
  local max_count = math.max(#items, #options)
  for i = 1, max_count do
    local option = options[i]
    local item = items[i]
    if item == nil and option ~= nil and not is_null(self._tab_list_binder) then
      local go = self._tab_list_binder:AddItem(0)
      item = self:add_panel(FRUIT_KING_COLOR_TAB_ITEM_CLS, go)
      items[i] = item
    end
    if item ~= nil then
      item:set_active(option ~= nil)
      if option ~= nil then
        item:refresh(option, option.OptionId == selected_id)
      end
    end
  end
end

function M:_refresh_calendar_season_visibility()
  local has_season_options = #(self._tree_season_preview_options or {}) > 0
  local can_show_season_switch = has_season_options and self._is_unlocked and OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateCalendarSeason)
  if not_null(self._dropdown_dark) then
    UIUtil.set_active(self._dropdown_dark, can_show_season_switch)
  end
  if not_null(self._btn_calendarseason) then
    UIUtil.set_active(self._btn_calendarseason, false)
  end
  if not is_null(self._list_calendarseason) then
    UIUtil.set_active(self._list_calendarseason, false)
  end
  if not can_show_season_switch then
    self:_close_calendar_season_menu()
  end
end

function M:_refresh_plant_preview_controls()
  self:_refresh_fruit_king_tab_visibility()
  self:_refresh_fruit_king_color_tabs()
  self:_refresh_calendar_season_visibility()
  self:_refresh_selected_tree_season_display()
end

function M:_get_tree_season_option_name(option)
  if option == nil then
    return ""
  end
  if string.is_valid(option.Name) then
    return option.Name
  end
  return UIUtil.get_text_by_id("TagDisplayName_" .. (option.SeasonKey or ""))
end

function M:_refresh_selected_tree_season_display()
  local option = self._selected_tree_season_option
  local display_name = self:_get_tree_season_option_name(option)
  if not is_null(self._txt_select_season) then
    UIUtil.set_text(self._txt_select_season, display_name)
  end
  if not_null(self._dropdown_dark) and not is_null(self._dropdown_dark.captionText) then
    UIUtil.set_text(self._dropdown_dark.captionText, display_name)
  end
end

function M:_refresh_fruit_king_tab_visibility()
  local has_color_options = not is_null(self.item_data) and self.item_data.Type == CodexDataType.Plant and self.item_data.IsFruitKing and #(self._fruit_king_color_preview_options or {}) > 0
  if not_null(self._trans_shiny_tab) then
    UIUtil.set_active(self._trans_shiny_tab, has_color_options)
  end
end

function M:_close_search_result_page()
  local result_page = UIManagerInstance:get_window_by_class("UI/Codex/Search/CodexSearchResultPage")
  if result_page then
    result_page:close_self()
  end
end

function M:_refresh_page()
  local item_id = self.item_data.IdCfg.id
  if codex_module:is_new_item(item_id) then
    red_point_module:record_with_id(codex_module.red_point_type_data, item_id)
    lua_event_module:send_event(lua_event_module.event_type.on_record_codex_item_red_point, item_id)
  end
  self:_refresh_bg_material()
  self:_refresh_left_display()
  self:_refresh_sections()
  self:_refresh_plant_preview_controls()
  self:_refresh_nav_buttons()
  self:_refresh_season_hot()
  self:_refresh_season_indicator()
  self:_refresh_npc_cloth_size()
  if not_null(self._detail_scroll_rect) then
    self._detail_scroll_rect.normalizedPosition = Vector2(0, 1)
  end
end

function M:_refresh_bg_material()
  local path = _bg_mat_path[self.item_data.Type]
  if not path then
    return
  end
  if is_null(self.ui_scene_obj) then
    return
  end
  local mat = UIUtil.get_material(path, self:get_load_proxy())
  if is_null(mat) then
    return
  end
  local plane = UIUtil.find_cmpt(self.ui_scene_obj, "Art/Content/Plane", typeof(MeshRender))
  if not_null(plane) then
    plane.material = mat
  end
  local backdrop = UIUtil.find_cmpt(self.ui_scene_obj, "Art/Content/backdrop", typeof(MeshRender))
  if not_null(backdrop) then
    backdrop.material = mat
  end
end

function M:_get_page_title()
  local is_package = codex_module:is_package_sub_type(self.item_data.SubType)
  local data_type = self.item_data.Type
  if is_package then
    if data_type == CodexDataType.Furniture then
      return UIUtil.get_text_by_id("Codex_FurSuite_Detail") or ""
    elseif data_type == CodexDataType.Cloth then
      return UIUtil.get_text_by_id("Codex_ClothSuite_Detail") or ""
    end
    return UIUtil.get_text_by_id("Codex_Suite_Detail") or ""
  end
  local sub_type = self.item_data.SubType
  if data_type == CodexDataType.Furniture then
    return UIUtil.get_text_by_id("Codex_Furniture_Detail") or ""
  elseif data_type == CodexDataType.Cloth then
    return UIUtil.get_text_by_id("Codex_Cloth_Detail") or ""
  elseif data_type == CodexDataType.Food then
    return UIUtil.get_text_by_id("Codex_Cook_Detail") or ""
  elseif data_type == CodexDataType.Plant then
    if sub_type == CodexDataSubType.PlantFlower then
      return UIUtil.get_text_by_id("Codex_Flower_Detail") or ""
    elseif sub_type == CodexDataSubType.PlantGreen then
      return UIUtil.get_text_by_id("Codex_Tree_Detail") or ""
    elseif sub_type == CodexDataSubType.PlantCollect then
      return UIUtil.get_text_by_id("Codex_Mushroom_Detail") or ""
    end
    return UIUtil.get_text_by_id("Codex_Plant_Detail") or ""
  elseif data_type == CodexDataType.Item then
    if sub_type == CodexDataSubType.ItemProp then
      return UIUtil.get_text_by_id("Codex_Collect_Detail") or ""
    end
    return UIUtil.get_text_by_id("Codex_Mat_Detail") or ""
  end
  return self.item_data.IdCfg.name
end

function M:_refresh_left_display()
  local is_package = codex_module:is_package_sub_type(self.item_data.SubType)
  local display_data = self:_get_display_item_data()
  local is_display_unlocked = self:_is_display_item_unlocked()
  self:_reset_stale_tree_season_preview()
  if self.item_data.Type == CodexDataType.Food then
    self:_refresh_left_display_food()
    return
  end
  if is_package then
    local all = self.item_data.allCount or 0
    local unlocked = self.item_data.unlockCount or 0
    local is_complete = 0 < all and all <= unlocked
    self._ui_state_group:SetState(is_complete and 2 or 1)
    if not is_complete and not_null(self._txt_locked) then
      local text_key = self._is_unlocked and "Codex_Suite_NotComplete" or "Codex_Suite_NotUnlocked"
      UIUtil.set_text_by_id(self._txt_locked, text_key)
    end
  else
    self._ui_state_group:SetState(is_display_unlocked and 0 or 1)
    if not is_display_unlocked and not_null(self._txt_locked) then
      UIUtil.set_text_by_id(self._txt_locked, "Codex_Suite_NotUnlocked")
    end
  end
  self:_refresh_fruit_king_tab_visibility()
  UIUtil.set_text(self._txt_title, self:_get_page_title())
  UIUtil.set_active(self._obj_outline, is_package)
  if is_display_unlocked then
    if is_package then
      self:_hide_model_preview()
      UIUtil.set_active(self._trans_pic_group, true)
      UIUtil.set_active(self._img_item_icon, false)
      UIUtil.set_image(self._img_group_icon, self.item_data.ItemCfg.setpic, self:get_load_proxy())
    else
      UIUtil.set_active(self._trans_pic_group, false)
      UIUtil.set_active(self._img_item_icon, false)
      ModelPreviewManagerIns:set_use_separate_scale(false)
      ModelPreviewManagerIns:show_item_by_id(self._trans_model, self:_get_display_preview_config_id(), pack(self, M._on_model_preview_loaded))
    end
  elseif is_package then
    self:_hide_model_preview()
    UIUtil.set_active(self._trans_pic_group, true)
    UIUtil.set_active(self._img_item_icon, false)
    UIUtil.set_image(self._img_group_icon, self.item_data.ItemCfg.setpic, self:get_load_proxy())
  elseif display_data.Type == CodexDataType.Plant or display_data.Type == CodexDataType.Item then
    self:_hide_model_preview()
    UIUtil.set_active(self._trans_pic_group, false)
    UIUtil.set_active(self._img_item_icon, true)
    UIUtil.set_image(self._img_item_icon, display_data.ItemCfg.tooltableicon, self:get_load_proxy())
    UIUtil.set_image_color(self._img_item_icon, codex_module:get_sub_type_lock_icon_color(display_data.SubType))
  else
    UIUtil.set_active(self._trans_pic_group, false)
    UIUtil.set_active(self._img_item_icon, false)
    ModelPreviewManagerIns:set_use_separate_scale(false)
    ModelPreviewManagerIns:show_item_by_id(self._trans_model, self:_get_display_preview_config_id(), pack(self, M._on_model_preview_loaded))
  end
  self:_refresh_date()
end

function M:_refresh_left_display_food()
  local strategy = codex_module:get_type_view_strategy(CodexDataType.Food)
  local unlock_state = strategy:get_food_unlock_state(self.item_data)
  local FUS = strategy.FoodUnlockState
  UIUtil.set_text(self._txt_title, self:_get_page_title())
  UIUtil.set_active(self._obj_outline, false)
  UIUtil.set_active(self._trans_pic_group, false)
  local not_cooked = unlock_state ~= FUS.Cooked
  if not_null(self._txt_locked) and not_cooked then
    UIUtil.set_text_by_id(self._txt_locked, "Codex_NotYetCooked")
  end
  if unlock_state == FUS.Cooked then
    self._ui_state_group:SetState(0)
    UIUtil.set_active(self._img_item_icon, false)
    ModelPreviewManagerIns:set_use_separate_scale(false)
    ModelPreviewManagerIns:show_item_by_id(self._trans_model, self.item_data.IdCfg.id)
  elseif unlock_state == FUS.RecipeLearned or unlock_state == FUS.PartialUnlocked then
    self._ui_state_group:SetState(1)
    UIUtil.set_active(self._img_item_icon, false)
    ModelPreviewManagerIns:set_use_separate_scale(false)
    ModelPreviewManagerIns:show_item_by_id(self._trans_model, self.item_data.IdCfg.id)
  else
    self._ui_state_group:SetState(1)
    self:_hide_model_preview()
    UIUtil.set_active(self._img_item_icon, true)
    UIUtil.set_image(self._img_item_icon, self.item_data.ItemCfg.tooltableicon, self:get_load_proxy())
    UIUtil.set_image_color(self._img_item_icon, codex_module:get_sub_type_lock_icon_color(self.item_data.SubType))
  end
  self:_refresh_fruit_king_tab_visibility()
  self:_refresh_food_date(unlock_state, FUS)
end

function M:_refresh_date()
  local display_data = self:_get_display_item_data()
  local server_data = display_data.ServerData
  local is_package = codex_module:is_package_sub_type(self.item_data.SubType)
  if is_package then
    if not not_null(self._txt_date) then
      return
    end
    local all = self.item_data.allCount or 0
    local unlocked = self.item_data.unlockCount or 0
    local is_complete = 0 < all and all <= unlocked
    if is_complete then
      local suite = server_data and server_data.Suite
      local ts = suite and suite.CompleteTime or 0
      if 0 < ts then
        local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(ts)
        UIUtil.set_text(self._txt_date, TextMapFormatUtil.FormatDateYMD(date_time))
      else
        UIUtil.set_text_by_id(self._txt_date, "Codex_Suite_NotComplete")
      end
    else
      UIUtil.set_text_by_id(self._txt_date, "Codex_Suite_NotComplete")
    end
    return
  end
  if not not_null(self._txt_date) then
    return
  end
  local ts = 0
  if self._selected_tree_season_option then
    ts = self._selected_tree_season_option.UnlockTime or 0
  elseif self:_is_display_item_unlocked() and server_data then
    ts = server_data.UnlockTime or 0
  end
  if 0 < ts then
    local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(ts)
    UIUtil.set_text(self._txt_date, TextMapFormatUtil.FormatDateYMD(date_time))
  else
    UIUtil.set_text(self._txt_date, "")
  end
end

function M:_refresh_food_date(unlock_state, FUS)
  if not not_null(self._txt_date) then
    return
  end
  if unlock_state == FUS.Cooked then
    local food_detail = self.item_data.FoodByCookDetail
    local ts = food_detail and food_detail.FirstCookingObtainedTime or 0
    if 0 < ts then
      local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(ts)
      UIUtil.set_text(self._txt_date, TextMapFormatUtil.FormatDateYMD(date_time))
      return
    end
  end
  UIUtil.set_text(self._txt_date, "")
end

function M:_close_food_tooltip()
  UIUtil.set_active(self._btn_full_close, false)
  UIUtil.set_active(self._btn_full_close_bg, false)
  local info_section = self._scroll_builder and self._scroll_builder:get_section("info_list")
  if info_section and info_section._close_tooltip then
    info_section:_close_tooltip()
  end
  local story_section = self._scroll_builder and self._scroll_builder:get_section("story")
  if story_section and story_section.close_popup then
    story_section:close_popup()
  end
end

function M:_refresh_npc_cloth_size()
  if is_null(self._obj_npc_cloth) then
    return
  end
  if self._npc_cloth_size_item == nil then
    self._npc_cloth_size_item = self:add_panel(NPC_CLOTH_SIZE_ITEM_CLS, self._obj_npc_cloth)
  end
  local item_id = self.item_data and self.item_data.IdCfg and self.item_data.IdCfg.id or 0
  self._npc_cloth_size_item:refresh_by_item_id(item_id, self.item_data and self.item_data.ItemCfg)
end

local all_section_root_fields = {
  "_trans_info_basic",
  "_trans_tag_group",
  "_trans_dyeing",
  "_trans_package_item_list",
  "_trans_package_reward",
  "_trans_get_from_list",
  "_trans_story",
  "_trans_package_info",
  "_trans_info_list",
  "_trans_state_seed",
  "_trans_effect",
  "_trans_describe",
  "_trans_info_icon",
  "_trans_record",
  "_trans_plants_product"
}

function M:_refresh_sections()
  local display_data = self:_get_display_item_data()
  local section_configs = self._view_strategy:get_detail_section_configs(display_data)
  if not section_configs or #section_configs == 0 then
    self._scroll_builder:hide_all()
    self:_hide_unmanaged_roots({})
    return
  end
  self._scroll_builder:build(section_configs)
  self:_hide_unmanaged_roots(section_configs)
  local title_section = self._scroll_builder:get_section("title")
  if title_section and title_section.set_sequence then
    title_section:set_sequence(self.sequence)
  end
  self._scroll_builder:refresh(display_data)
  local info_section = self._scroll_builder:get_section("info_list")
  if info_section and not info_section._tooltip_blocker_cb then
    function info_section._tooltip_blocker_cb(visible)
      UIUtil.set_active(self._btn_full_close, visible)
      
      UIUtil.set_active(self._btn_full_close_bg, visible)
    end
  end
  local story_section = self._scroll_builder:get_section("story")
  if story_section and not story_section._popup_visibility_cb then
    function story_section._popup_visibility_cb(visible)
      UIUtil.set_active(self._btn_full_close, visible)
      
      UIUtil.set_active(self._btn_full_close_bg, visible)
    end
  end
end

function M:_hide_unmanaged_roots(section_configs)
  local managed_id = {}
  for _, cfg in ipairs(section_configs) do
    local trans = self[cfg.root_field]
    if not_null(trans) then
      managed_id[trans:GetInstanceID()] = true
    end
  end
  for _, field in ipairs(all_section_root_fields) do
    local trans = self[field]
    if not_null(trans) and not managed_id[trans:GetInstanceID()] then
      trans.gameObject:SetActive(false)
    end
  end
end

function M:on_destroy()
  if self._evt_codex_data_update then
    self._evt_codex_data_update = nil
  end
  if self._evt_all_codex_data_update then
    self._evt_all_codex_data_update = nil
  end
  self._fruit_king_color_tab_items = nil
  if self._scroll_builder then
    self._scroll_builder:destroy()
  end
  base.on_destroy(self)
end

function M:close_self()
  local story_section = self._scroll_builder and self._scroll_builder:get_section("story")
  if story_section and story_section.close_popup and story_section:close_popup() then
    UIUtil.set_active(self._btn_full_close, false)
    UIUtil.set_active(self._btn_full_close_bg, false)
    return
  end
  if not self.item_data then
    UIManagerInstance:close(self.guid)
    return
  end
  local strategy = codex_module:get_type_view_strategy(self.item_data.Type)
  local type_page_class = strategy:get_type_page_class()
  local window = UIManagerInstance:get_window_by_class(type_page_class)
  local focus_item_id = self.item_data.IdCfg.id
  if window then
    window:set_extra_data({
      type = self.item_data.Type,
      sub_type = self.item_data.SubType,
      focus_item_id = focus_item_id
    })
  elseif self._from_search_navigation then
    UIManagerInstance:close(self.guid)
    UIManagerInstance:open(type_page_class, {
      type = self.item_data.Type,
      sub_type = self.item_data.SubType,
      focus_item_id = focus_item_id
    })
    return
  end
  UIManagerInstance:close(self.guid)
end

function M:_refresh_season_hot()
  if is_null(self._btn_season_hot) then
    return
  end
  local display = codex_module:get_item_season_display(self.item_data)
  UIUtil.set_active(self._btn_season_hot, display ~= nil and display.is_hot)
end

function M:_refresh_season_indicator()
  if is_null(self._trans_season) then
    return
  end
  local display = codex_module:get_item_season_display(self.item_data)
  local has_season_cfg = display ~= nil and not display.is_hot
  UIUtil.set_active(self._trans_season, has_season_cfg)
  if not has_season_cfg then
    return
  end
  if not_null(self._img_icon_season) and display.icon_path ~= "" then
    UIUtil.set_image(self._img_icon_season, display.icon_path, self:get_load_proxy())
  end
  if not_null(self._txt_title_season) then
    UIUtil.set_text(self._txt_title_season, display.tips or "")
  end
end

function M:_is_season_hot_item()
  if not self.item_data then
    return false
  end
  local display = codex_module:get_item_season_display(self.item_data)
  return display ~= nil and display.is_hot
end

return M
