local M = G.Class("CodexSubtypeBgItem", G.UIPanel)
local base = G.UIPanel
local sub_type_tog_item_class = "UI/Codex/TypePage/SubTypeTogItem"
local sort_dropdown_panel_class = "UI/Codex/TypePage/CodexSortDropdownPanel"
local search_mixin = require("UI/Codex/Search/CodexSearchMixin")
local SORT_ICON_ASC = "UISprite/Load/CommonSpriteAsset/Icon_SpriteAsset_Ascending.png"
local SORT_ICON_DESC = "UISprite/Load/CommonSpriteAsset/Icon_SpriteAsset_Descending.png"

function M:init()
  base.init(self)
  self._type_ctrl = nil
  self._view_strategy = nil
  self._sub_type_info = {}
  self._sub_type_tog_items = {}
  self._sub_type_to_tog_item_idx = {}
  self._selected_item_id = 0
  self._sort_dropdown_panel = nil
  self._is_dropdown_showing = false
  self._display_mode = codex_module.CodexDisplayMode.Flat
  self._sort_mode = codex_module.CodexSortMode.Default
  self._sort_order = codex_module.CodexSortOrder.Ascending
  self._current_sub_type_info = nil
  self._curr_pos = nil
  self._tog_item_pool = {}
  self._tab_scroll_reset_version = 0
  self._search_panel = nil
  self._search_panel_root = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  search_mixin.ensure_search_panel(self, function()
    return self:_build_search_context()
  end)
  if self._search_panel then
    self._search_panel:set_outside_click_callback(function(panel)
      panel:collapse()
      if self.holder and self.holder._sub_type_list_ctl then
        self.holder._sub_type_list_ctl:_update_fullscreen_close_visible()
      end
    end)
    self._search_panel:set_field_state_callback(function(_is_open)
      if self.holder and self.holder._sub_type_list_ctl then
        self.holder._sub_type_list_ctl:_update_fullscreen_close_visible()
      end
    end)
  end
end

function M:on_enable()
  base.on_enable(self)
  self:_close_dropdown()
end

function M:on_disable()
  base.on_disable(self)
  self._tab_scroll_reset_version = self._tab_scroll_reset_version + 1
  self:_close_dropdown()
  search_mixin.close_search_panel(self, true)
  local tog_item = self._sub_type_tog_items[self._selected_item_id]
  if tog_item then
    tog_item:un_select()
  end
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, M._on_back_action)
end

function M:_on_back_action()
  if search_mixin.is_search_field_open(self) then
    search_mixin.close_search_panel(self)
    return
  end
  if self._is_dropdown_showing then
    self:_close_dropdown()
    return
  end
  self:_on_close_btn_click()
end

function M:_add_ui_listener()
  if not_null(self._btn_close) then
    self:bind_callback(self._btn_close, pack(self, M._on_close_btn_click))
  end
  if not_null(self._tog_dropdown) then
    self:bind_callback(self._tog_dropdown, pack(self, M._on_tog_dropdown_changed))
  end
  if not_null(self._btn_fullscreen) then
    self:bind_callback(self._btn_fullscreen, pack(self, M._on_fullscreen_click))
  end
  if not_null(self._btn_scroller_red_dot) then
    self:bind_callback(self._btn_scroller_red_dot, pack(self, M._on_btn_scroller_red_dot_up_click))
  end
  if not_null(self._btn_scroller_red_dot_down) then
    self:bind_callback(self._btn_scroller_red_dot_down, pack(self, M._on_btn_scroller_red_dot_down_click))
  end
end

function M:_build_search_context()
  local info = self._current_sub_type_info
  local type = info and info.type or self.holder and self.holder._pictorial_book_type or nil
  local sub_type = info and info.sub_type or nil
  return {
    type = type,
    sub_type = sub_type,
    include_package = sub_type ~= nil and codex_module:is_package_sub_type(sub_type)
  }
end

function M:_close_search_panel(silent)
  search_mixin.close_search_panel(self, silent)
end

function M:_on_close_btn_click()
  self.holder:on_bg_close_click()
end

function M:refresh_sub_type_list(id, sub_type_info)
  self:_refresh_collect_num(sub_type_info)
  self.holder:refresh_sub_type_list(id, sub_type_info)
end

function M:_refresh_collect_num(sub_type_info)
  local ctrl = codex_module:get_sub_type_controller(sub_type_info.type, sub_type_info.sub_type)
  if not ctrl then
    return
  end
  local unlocked = ctrl:get_unlocked_item_count()
  local total = ctrl:get_item_count()
  local text = unlocked .. "/" .. total
  if not_null(self._txt_num_mobile) then
    UIUtil.set_text(self._txt_num_mobile, text)
  end
end

function M:refresh_tabs(type_ctrl, view_strategy, curr_pos)
  self._type_ctrl = type_ctrl
  self._view_strategy = view_strategy
  self._curr_pos = curr_pos
  self:_refresh_bg_state()
  self._sub_type_info = self._type_ctrl:get_all_sub_type_info()
  table.sort(self._sub_type_info, function(a, b)
    return a.priority > b.priority
  end)
  self:_init_sub_type_tog_items()
end

function M:set_tab_title(main_title, name)
  if not_null(self._txt_title_main) then
    UIUtil.set_text(self._txt_title_main, main_title)
  end
  if not_null(self._txt_sub_title) then
    UIUtil.set_text(self._txt_sub_title, name)
  end
end

function M:get_sub_type_info()
  return self._sub_type_info
end

function M:_get_tab_template()
  return self._trans_type_tog_item_mobile
end

function M:_get_tab_content()
  return self._trans_tab_content_mobile
end

function M:_refresh_bg_state()
  if not self._view_strategy or is_null(self._state_group_bgcolor) then
    return
  end
  self._state_group_bgcolor:SetState(self._view_strategy:get_bg_state())
end

function M:_init_sub_type_tog_items()
  if self._sub_type_info == nil then
    return false
  end
  table.clear(self._sub_type_to_tog_item_idx)
  local template = self:_get_tab_template()
  UIUtil.set_active(template, false)
  local content = self:_get_tab_content()
  if is_null(template) or is_null(content) then
    return false
  end
  local count = #self._sub_type_info
  local selected_item
  for i, data in ipairs(self._sub_type_info) do
    local entry = self._tog_item_pool[i]
    if not entry then
      local obj = UIUtil.load_prefab_set_parent(template, content)
      local panel = self:add_panel(sub_type_tog_item_class, obj)
      entry = {panel = panel, trans = obj}
      self._tog_item_pool[i] = entry
    end
    local item = entry.panel
    item:set_active(true)
    local instance_id = entry.trans:GetInstanceID()
    item:refresh(instance_id, data)
    self._sub_type_tog_items[instance_id] = item
    self._sub_type_to_tog_item_idx[data.sub_type] = instance_id
    if selected_item == nil and (self._curr_pos == nil or self._curr_pos.sub_type == data.sub_type) then
      selected_item = item
    end
  end
  for i = count + 1, #self._tog_item_pool do
    self._tog_item_pool[i].panel:set_active(false)
  end
  if selected_item == nil and 0 < count then
    selected_item = self._tog_item_pool[1].panel
  end
  if selected_item ~= nil then
    selected_item:reset_select()
  end
  if self._curr_pos == nil then
    self:_reset_tab_scroll_position()
  end
  return true
end

function M:_reset_tab_scroll_position()
  self._tab_scroll_reset_version = self._tab_scroll_reset_version + 1
  local version = self._tab_scroll_reset_version
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if not (version == self._tab_scroll_reset_version and self.is_active) or self._curr_pos ~= nil then
      return
    end
    self:_apply_tab_scroll_position()
  end)
end

function M:_apply_tab_scroll_position()
  local content = self:_get_tab_content()
  if is_null(content) or is_null(content.parent) then
    return
  end
  Canvas.ForceUpdateCanvases()
  LayoutRebuilder.ForceRebuildLayoutImmediate(content)
  local scroll_rect = content.parent:GetComponent(typeof(ScrollRect))
  if is_null(scroll_rect) then
    return
  end
  scroll_rect:StopMovement()
  scroll_rect.normalizedPosition = Vector2(0, 1)
end

function M:set_selected_item_id(id)
  self._selected_item_id = id
end

function M:restore_tab_selection(sub_type)
  local tog_index = self._sub_type_to_tog_item_idx[sub_type]
  if tog_index then
    local tog_item = self._sub_type_tog_items[tog_index]
    if tog_item then
      tog_item:select()
      self._selected_item_id = tog_index
    end
  end
end

function M:refresh_red_points()
  for _, item in pairs(self._sub_type_tog_items) do
    item:_refresh_red_point()
  end
end

function M:get_tog_item_count()
  local count = 0
  for _, _ in pairs(self._sub_type_tog_items) do
    count = count + 1
  end
  return count
end

function M:get_tog_by_sub_type(sub_type)
  local tog_index = self._sub_type_to_tog_item_idx[sub_type]
  if tog_index then
    return self._sub_type_tog_items[tog_index]
  end
  return nil
end

function M:init_sort_dropdown(sub_type_info, view_strategy, sort_mode, sort_order, display_mode)
  self._current_sub_type_info = sub_type_info
  self._view_strategy = view_strategy
  self._sort_mode = sort_mode
  self._sort_order = sort_order
  self._display_mode = display_mode
  if self._sort_dropdown_panel == nil then
    self._sort_dropdown_panel = self:add_panel(sort_dropdown_panel_class, self._trans_dropdown_list_dark)
  end
  local show_dropdown = view_strategy and view_strategy:supports_sorting(sub_type_info) or false
  UIUtil.set_active(self._tog_dropdown, show_dropdown)
  UIUtil.set_active(self._trans_dropdown_list_dark, false)
  self._is_dropdown_showing = false
  if show_dropdown then
    self._sort_dropdown_panel:sync_state(sort_mode, sort_order, display_mode, view_strategy, sub_type_info)
    self:_refresh_sort_label()
  end
end

function M:_on_tog_dropdown_changed()
  local is_on = self._tog_dropdown.isOn
  self._is_dropdown_showing = is_on
  UIUtil.set_active(self._trans_dropdown_list_dark, is_on)
  if is_on then
    self:set_fullscreen_visible(true)
  elseif self.holder and self.holder.check_fullscreen_needed then
    self:set_fullscreen_visible(self.holder:check_fullscreen_needed())
  else
    self:set_fullscreen_visible(false)
  end
  if self.holder and self.holder._sub_type_list_ctl then
    self.holder._sub_type_list_ctl:_update_fullscreen_close_visible()
  end
end

function M:_close_dropdown()
  if not self._is_dropdown_showing then
    return
  end
  self._is_dropdown_showing = false
  if not_null(self._trans_dropdown_list_dark) then
    UIUtil.set_active(self._trans_dropdown_list_dark, false)
  end
  if not_null(self._tog_dropdown) then
    self._tog_dropdown.isOn = false
  end
  if self.holder and self.holder.check_fullscreen_needed then
    self:set_fullscreen_visible(self.holder:check_fullscreen_needed())
  else
    self:set_fullscreen_visible(false)
  end
  if self.holder and self.holder._sub_type_list_ctl then
    self.holder._sub_type_list_ctl:_update_fullscreen_close_visible()
  end
end

function M:_refresh_sort_label()
  if self._sort_dropdown_panel == nil then
    return
  end
  local sort_name = self._sort_dropdown_panel:get_cur_sort_name()
  local is_asc = self._sort_order == codex_module.CodexSortOrder.Ascending
  local icon_path = is_asc and SORT_ICON_ASC or SORT_ICON_DESC
  local show_group_prefix = self._view_strategy and self._view_strategy:supports_grouping(self._current_sub_type_info) or false
  local label
  if show_group_prefix then
    local is_grouped = self._display_mode == codex_module.CodexDisplayMode.Grouped
    local display_text = is_grouped and UIUtil.get_text_by_id("Codex_Sort_Group") or UIUtil.get_text_by_id("Codex_Sort_Ungroup")
    label = display_text .. " / " .. sort_name .. " / <dynamicsprite=" .. icon_path .. ">"
  else
    label = sort_name .. " / <dynamicsprite=" .. icon_path .. ">"
  end
  UIUtil.set_text_with_dynamic_sprite(self._txt_sort_label, label)
end

function M:on_sort_changed(sort_mode, sort_order)
  self._sort_mode = sort_mode
  self._sort_order = sort_order
  self:_close_dropdown()
  self:_refresh_sort_label()
  self.holder:on_bg_sort_changed(sort_mode, sort_order)
end

function M:on_display_mode_changed(display_mode)
  self._display_mode = display_mode
  self:_close_dropdown()
  self:_refresh_sort_label()
  self.holder:on_bg_display_mode_changed(display_mode)
end

function M:set_sort_visible(visible)
  if not_null(self._tog_dropdown) then
    UIUtil.set_active(self._tog_dropdown, visible)
  end
  if not visible then
    self:_close_dropdown()
  end
end

function M:_on_fullscreen_click()
  self:_close_dropdown()
  if self.holder and self.holder.on_fullscreen_close then
    self.holder:on_fullscreen_close()
  end
end

function M:set_fullscreen_visible(show)
  if not_null(self._btn_fullscreen) then
    UIUtil.set_active(self._btn_fullscreen, show)
  end
end

function M:_on_btn_scroller_red_dot_up_click()
  self.holder:on_bg_scroll_to_reward("above")
end

function M:_on_btn_scroller_red_dot_down_click()
  self.holder:on_bg_scroll_to_reward("below")
end

function M:refresh_scroller_red_dot(has_above, has_below)
  if not_null(self._btn_scroller_red_dot) then
    UIUtil.set_active(self._btn_scroller_red_dot, has_above)
  end
  if not_null(self._btn_scroller_red_dot_down) then
    UIUtil.set_active(self._btn_scroller_red_dot_down, has_below)
  end
end

return M
