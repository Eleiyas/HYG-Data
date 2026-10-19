local M = G.Class("ActivityCenterMainPage", G.UIWindow)
local base = G.UIWindow
local TIME_REFRESH_INTERVAL_SEC = 1

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity/MainActivityBasePage"
  self.config.type = EUIType.Page
  self._current_category = activity_center_module.default_category
  self._selected_activity_id = 0
  self._detail_activity_id = 0
  self._category_last_selected = {}
  self._detail_panels = {}
  self._current_detail_panel = nil
  self._top_tab_items = {}
  self._act_tab_item_pool = {}
  self._act_id_to_act_tab_items = {}
  self._pending_detail_navigation = nil
  self._time_acc = 0
  self._list_dirty = false
end

function M:on_create()
  base.on_create(self)
  self:_init_top_tabs()
  self:bind_callbacks()
end

function M:on_open()
  base.on_open(self)
  local extra_data = self:get_extra_data() or {}
  self._current_category = extra_data.focus_category or activity_center_module.default_category
  self._selected_activity_id = extra_data.focus_activity_id or 0
  self._pending_detail_navigation = nil
  local on_detail_ready = extra_data.on_detail_ready
  if on_detail_ready ~= nil then
    self._pending_detail_navigation = {
      activity_id = self._selected_activity_id,
      callback = on_detail_ready
    }
  end
  self._category_last_selected = {}
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  self:_process_pending_list_refresh()
  if self._current_detail_panel == nil then
    return
  end
  self._time_acc = self._time_acc + deltaTime
  if self._time_acc >= TIME_REFRESH_INTERVAL_SEC then
    self._time_acc = self._time_acc - TIME_REFRESH_INTERVAL_SEC
    self._current_detail_panel:update_time_remain()
  end
end

function M:_process_pending_list_refresh()
  if not self._list_dirty then
    return
  end
  if activity_center_module:is_list_refresh_held() then
    return
  end
  self._list_dirty = false
  self:_refresh_list()
  self:_refresh_selection()
end

function M:on_enable()
  base.on_enable(self)
  self._list_dirty = false
  self._detail_activity_id = 0
  self:_select_top_tab(self._current_category)
  self:_refresh_list()
  self:_refresh_selection()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  self._pending_detail_navigation = nil
  self:_reset_shared_widgets()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnActivityListChanged, function()
    self._list_dirty = true
  end)
  self:add_evt_listener(EventID.OnActivityRemoved, function(activity_id)
    self:_on_activity_state_changed(activity_id)
  end)
  self:add_evt_listener(EventID.OnActivityDataChanged, function(activity_id)
    self:_on_activity_data_changed(activity_id)
  end)
  self:add_lua_listener(lua_event_module.event_type.refresh_activity_center_red_point, function()
    self:_refresh_all_red_dot()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_init_top_tabs()
  local activity_category = {
    [1] = activity_center_module.top_tab_category.recommend,
    [2] = activity_center_module.top_tab_category.discover
  }
  self._category_name = {
    [activity_center_module.top_tab_category.recommend] = "Activity_Tab_Recommend",
    [activity_center_module.top_tab_category.discover] = "Activity_Tab_Discover"
  }
  for i, category in ipairs(activity_category) do
    local cls = self._top_tab_items[i]
    if cls == nil then
      local obj = self._top_list_item_binder:AddItem(0)
      cls = self:add_panel(activity_center_module.top_tab_item_class_path, obj)
      self:bind_callback(cls:get_toggle(), function(is_on)
        if is_on then
          self:on_category_changed(category)
        end
      end)
      self._top_tab_items[i] = cls
    end
    cls:refresh({category = category})
  end
end

function M:bind_callbacks()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_help, pack(self, M._on_btn_help_click))
end

function M:_on_btn_close_click()
  activity_center_module:close_main_page()
end

function M:_on_btn_help_click()
  local activity_id = 0
  if self._current_detail_panel ~= nil then
    activity_id = self._current_detail_panel:get_activity_id() or 0
  end
  if activity_id <= 0 then
    activity_id = self._selected_activity_id or 0
  end
  if activity_id <= 0 then
    return
  end
  local cfg = activity_center_module:get_ui_cfg(activity_id)
  if not cfg or not string.is_valid(cfg.activityruledetail) then
    return
  end
  local introduction_cfg_id = tonumber(cfg.activityruledetail) or 0
  if introduction_cfg_id <= 0 then
    return
  end
  activity_center_module:show_activity_introduction_dialog(activity_id, introduction_cfg_id)
end

function M:on_category_changed(category)
  UIUtil.set_text_by_id(self._txt_sub_title, self._category_name[category])
  if self._current_category == category then
    return
  end
  self._current_category = category
  self._selected_activity_id = self._category_last_selected[category] or 0
  self:_cancel_pending_detail_navigation_if_target_changed(self._selected_activity_id)
  self:_refresh_list()
  self:_refresh_selection()
end

function M:_select_top_tab(category)
  for _, item in ipairs(self._top_tab_items) do
    local is_target = item:get_category() == category
    item:set_selected(is_target)
  end
end

function M:_recycle_all_act_tab_items()
  for _, item in pairs(self._act_id_to_act_tab_items) do
    local act_tab_type = item:get_act_tab_type()
    item:refresh(nil)
    local pool = self._act_tab_item_pool[act_tab_type]
    if pool == nil then
      pool = {}
      self._act_tab_item_pool[act_tab_type] = pool
    end
    pool[#pool + 1] = item
  end
  table.clear(self._act_id_to_act_tab_items)
end

function M:_acquire_act_tab_item(act_tab_type)
  local pool = self._act_tab_item_pool[act_tab_type]
  if pool ~= nil and 0 < #pool then
    return table.remove(pool)
  end
  local obj = self._sub_act_list_item_binder:AddItem(act_tab_type)
  local cls = self:add_panel(activity_center_module.list_toggle_class_path, obj)
  self:bind_callback(cls:get_toggle(), function(is_on)
    if is_on then
      self:on_activity_selected(cls:get_activity_id())
    end
  end)
  return cls
end

function M:_refresh_list()
  self:_recycle_all_act_tab_items()
  local ids = activity_center_module:get_ids_by_category(self._current_category)
  for i = 1, #ids do
    local id = ids[i]
    local act_tab_type = activity_center_module:get_act_tab_type(id)
    local cls = self:_acquire_act_tab_item(act_tab_type)
    cls:refresh({activity_id = id})
    cls.trans:SetAsLastSibling()
    self._act_id_to_act_tab_items[id] = cls
    if id == self._selected_activity_id then
      if cls:get_toggle().isOn then
        self:on_activity_selected(id)
      else
        cls:set_selected(true)
      end
    end
  end
  UIUtil.set_active(self._trans_empty, #ids == 0)
  for _, panel in ipairs(self._top_tab_items) do
    if panel.is_active then
      panel:refresh_red_dot()
    end
  end
end

function M:_refresh_all_red_dot()
  for _, panel in pairs(self._act_id_to_act_tab_items) do
    panel:refresh_red_dot()
  end
  for _, panel in ipairs(self._top_tab_items) do
    if panel.is_active then
      panel:refresh_red_dot()
    end
  end
end

function M:_refresh_selection()
  if self._selected_activity_id ~= 0 and activity_center_module:has_activity(self._selected_activity_id) and self._act_id_to_act_tab_items[self._selected_activity_id] then
    self._act_id_to_act_tab_items[self._selected_activity_id]:set_selected(true)
    return
  end
  local ids = activity_center_module:get_ids_by_category(self._current_category)
  local activity_id = ids[1]
  if activity_id then
    local item = self._act_id_to_act_tab_items[activity_id]
    if item then
      if item:get_toggle().isOn then
        self:on_activity_selected(activity_id)
      else
        item:set_selected(true)
      end
      return
    end
  end
  self:_hide_current_detail_panel()
end

function M:on_activity_selected(activity_id)
  if activity_id == nil or activity_id == 0 then
    return
  end
  if activity_id == self._detail_activity_id then
    if self._current_detail_panel ~= nil then
      self._current_detail_panel:refresh()
    end
    return
  end
  self:_cancel_pending_detail_navigation_if_target_changed(activity_id)
  self._category_last_selected[self._current_category] = activity_id
  CsActivityCenterModuleUtil.OnOpenActivityPage(activity_id)
  self:_refresh_all_red_dot()
  self:_show_activity_detail(activity_id)
end

function M:_show_activity_detail(activity_id)
  self:_hide_current_detail_panel()
  self:_reset_shared_widgets()
  if activity_id == 0 or not activity_center_module:has_activity(activity_id) then
    self._selected_activity_id = 0
    self._current_detail_panel = nil
    return
  end
  self._selected_activity_id = activity_id
  self._detail_activity_id = activity_id
  local cached = self._detail_panels[activity_id]
  if cached ~= nil then
    self._current_detail_panel = cached
    self._current_detail_panel:set_shared_widgets(self:_get_shared_widget())
    self._current_detail_panel:change_state(EUIState.Show)
    self._current_detail_panel:refresh()
    self:_invoke_detail_ready(activity_id)
    return
  end
  local lua_class, prefab_path = activity_center_module:resolve_panel_for_activity(activity_id)
  self:_load_detail_panel(lua_class, prefab_path, activity_id)
end

function M:_cancel_pending_detail_navigation_if_target_changed(activity_id)
  local pending = self._pending_detail_navigation
  if pending ~= nil and activity_id ~= pending.activity_id then
    self._pending_detail_navigation = nil
  end
end

function M:_invoke_detail_ready(activity_id)
  local pending = self._pending_detail_navigation
  if pending == nil or activity_id ~= self._selected_activity_id or activity_id ~= pending.activity_id then
    return
  end
  self._pending_detail_navigation = nil
  pending.callback()
end

function M:_load_detail_panel(lua_class, prefab_path, activity_id)
  local extra = {prefab_path = prefab_path, activity_id = activity_id}
  local panel = self:add_panel_async(lua_class, extra, self._trans_sub_panel, pack(self, M._on_detail_panel_loaded))
  panel:change_state(EUIState.Show)
  self._detail_panels[activity_id] = panel
end

function M:_on_detail_panel_loaded(loaded_panel)
  if is_null(loaded_panel) then
    Logger.LogWarning("[ActivityCenter] add_panel_async failed: " .. tostring(lua_class))
    return
  end
  if self._selected_activity_id == loaded_panel:get_activity_id() then
    self._current_detail_panel = loaded_panel
    loaded_panel:set_shared_widgets(self:_get_shared_widget())
    loaded_panel:change_state(EUIState.Show)
    loaded_panel:refresh()
    self:_invoke_detail_ready(loaded_panel:get_activity_id())
  else
    loaded_panel:change_state(EUIState.Hide)
  end
end

function M:_reset_shared_widgets()
  UIUtil.set_text(self._text_main_title, "")
  UIUtil.set_text(self._text_desc, "")
  UIUtil.set_text(self._text_time_remain, "")
  UIUtil.set_active(self._trans_time_remain, false)
  UIUtil.set_active(self._trans_detail_info, true)
  UIUtil.set_active(self._img_bg_dynamic, false)
  self._time_acc = 0
end

function M:_hide_current_detail_panel()
  self._detail_activity_id = 0
  UIUtil.set_active(self._trans_detail_info, false)
  UIUtil.set_active(self._img_bg_dynamic, false)
  if self._current_detail_panel == nil then
    return
  end
  self._current_detail_panel:set_shared_widgets(nil)
  self._current_detail_panel:change_state(EUIState.Hide)
  self._current_detail_panel = nil
end

function M:_get_shared_widget()
  return {
    text_main_title = self._text_main_title,
    text_time_remain = self._text_time_remain,
    text_desc = self._text_desc,
    trans_time_remain = self._trans_time_remain,
    img_bg_dynamic = self._img_bg_dynamic
  }
end

function M:_on_activity_state_changed(activity_id)
  self._list_dirty = true
  if activity_id ~= self._selected_activity_id and self._act_id_to_act_tab_items[activity_id] ~= nil then
    activity_center_module:show_activity_expire_tips()
  end
end

function M:_on_activity_data_changed(activity_id)
  self._list_dirty = true
end

return M
