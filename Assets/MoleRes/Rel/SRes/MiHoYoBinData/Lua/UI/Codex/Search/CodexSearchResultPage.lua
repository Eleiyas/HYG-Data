local list_item_ctl_class = "UI/Codex/TypePage/SubTypeListItem"
local group_header_class = "UI/Codex/Search/CodexSearchResultGroupHeader"
local type_tog_item_class = "UI/Codex/Search/CodexSearchResultTypeTogItem"
local search_mixin = require("UI/Codex/Search/CodexSearchMixin")
local search_engine = require("UI/Codex/Search/CodexSearchEngine")
local group_title_child_name = "grouptitle"
local ui_state = {
  waiting_input = 0,
  has_results = 1,
  no_results = 2
}
local result_list_kind = {normal = "normal", cook = "cook"}
local M = G.Class("CodexSearchResultPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexResultPage"
  self.config.type = EUIType.Dialog
  self._keyword = ""
  self._context = nil
  self._all_grouped_results = {}
  self._all_normal_groups = {}
  self._all_cook_groups = {}
  self._normal_groups = {}
  self._cook_groups = {}
  self._normal_item_cls_map = {}
  self._cook_item_cls_map = {}
  self._normal_title_cls_map = {}
  self._cook_title_cls_map = {}
  self._type_tog_pool = {}
  self._type_sorted_list = {}
  self._selected_type = nil
  self._type_view_state = {}
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close)
  if not_null(self._btn_full) then
    self:bind_callback(self._btn_full, pack(self, M._on_btn_full))
  end
  search_mixin.ensure_search_panel(self, function()
    return self._context
  end)
  if self._search_panel then
    self._search_panel:set_callbacks(function(keyword, results, context)
      self:_on_search_executed(keyword, results, context)
    end, nil)
    self._search_panel:set_outside_click_callback(function(panel)
      panel:dismiss_panels()
    end)
    self._search_panel:set_view_state_callback(function(_is_showing)
      if not_null(self._btn_full) then
        UIUtil.set_active(self._btn_full, false)
      end
    end)
  end
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.system_jump_by_source_item_click, function()
    self:close_self()
  end)
end

function M:on_destroy()
  self:_close_scroller(self._scrolllist_normal)
  self:_close_scroller(self._scrolllist_cook)
  base.on_destroy(self)
end

function M:on_close()
  self:_reset_result_view_state()
  base.on_close(self)
end

function M:on_open()
  base.on_open(self)
  local data = self:get_extra_data() or {}
  self._keyword = data.keyword or ""
  self._context = data.context
  self:_reset_result_view_state()
  if not_null(self._btn_full) then
    UIUtil.set_active(self._btn_full, false)
  end
  if self._search_panel then
    self._search_panel:set_context(self._context)
    self._search_panel:show_with_keyword(self._keyword)
  end
  self:refresh(data.results or {}, self._keyword)
end

function M:on_enable()
  base.on_enable(self)
  self:_apply_selected_type_view_state()
  self:_rebind_visible_items()
end

function M:on_disable()
  self:_save_selected_type_view_state()
  base.on_disable(self)
end

function M:_reset_result_view_state()
  self._type_view_state = {}
  self._selected_type = nil
end

function M:_get_type_view_state(type_value, should_create)
  if type_value == nil then
    return nil
  end
  local state = self._type_view_state[type_value]
  if state == nil and should_create then
    state = {
      [result_list_kind.normal] = {
        expanded_by_sub_type = {},
        vertical_normalized_position = 1
      },
      [result_list_kind.cook] = {
        expanded_by_sub_type = {},
        vertical_normalized_position = 1
      }
    }
    self._type_view_state[type_value] = state
  end
  return state
end

function M:_save_selected_type_view_state()
  local state = self:_get_type_view_state(self._selected_type, true)
  if state == nil then
    return
  end
  self:_save_scroller_view_state(self._scrolllist_normal, self._normal_groups, state[result_list_kind.normal])
  self:_save_scroller_view_state(self._scrolllist_cook, self._cook_groups, state[result_list_kind.cook])
end

function M:_save_scroller_view_state(scroller, groups, state)
  if is_null(scroller) or state == nil then
    return
  end
  state.expanded_by_sub_type = {}
  for index, group in ipairs(groups or {}) do
    state.expanded_by_sub_type[group.sub_type] = not scroller:IsNodeCollapsed(index - 1)
  end
  local scroll_rect = scroller:GetComponent(typeof(ScrollRect))
  if not_null(scroll_rect) then
    state.vertical_normalized_position = scroll_rect.verticalNormalizedPosition
  end
end

function M:_set_group_expanded_state(type_value, list_kind, sub_type, is_expanded)
  local state = self:_get_type_view_state(type_value, true)
  if state == nil or state[list_kind] == nil then
    return
  end
  state[list_kind].expanded_by_sub_type[sub_type] = is_expanded == true
end

function M:_apply_selected_type_view_state()
  local state = self:_get_type_view_state(self._selected_type, false)
  if state == nil then
    return
  end
  self:_apply_scroller_view_state(self._scrolllist_normal, self._normal_groups, self._normal_title_cls_map, state[result_list_kind.normal])
  self:_apply_scroller_view_state(self._scrolllist_cook, self._cook_groups, self._cook_title_cls_map, state[result_list_kind.cook])
end

function M:_apply_scroller_view_state(scroller, groups, title_cls_map, state)
  if is_null(scroller) or state == nil then
    return
  end
  for index, group in ipairs(groups or {}) do
    local node_index = index - 1
    local is_expanded = state.expanded_by_sub_type[group.sub_type]
    if is_expanded == false then
      scroller:CollapseNode(node_index, 0)
    else
      scroller:ExpandNode(node_index, 0)
    end
  end
  self:_refresh_group_header_states(scroller, groups, title_cls_map)
  local scroll_rect = scroller:GetComponent(typeof(ScrollRect))
  if not_null(scroll_rect) then
    scroller:StopMovement()
    scroll_rect.verticalNormalizedPosition = state.vertical_normalized_position or 1
  end
end

function M:_refresh_group_header_states(scroller, groups, title_cls_map)
  for _, title_cls in pairs(title_cls_map or {}) do
    local node_index = title_cls._node_index
    if node_index ~= nil and groups[node_index + 1] ~= nil then
      title_cls:refresh_expanded_state(not scroller:IsNodeCollapsed(node_index))
    end
  end
end

function M:_rebind_visible_items()
  if not_null(self._scrolllist_normal) then
    self._scrolllist_normal:RebindAllVisibleItems()
  end
  if not_null(self._scrolllist_cook) then
    self._scrolllist_cook:RebindAllVisibleItems()
  end
end

function M:_on_btn_full()
  if self._search_panel then
    self._search_panel:dismiss_panels()
  end
end

function M:_on_search_executed(keyword, results, context)
  if not keyword or keyword == "" then
    self:_set_waiting_input_state()
    return
  end
  self._context = context
  self:_reset_result_view_state()
  if self._search_panel then
    self._search_panel:dismiss_panels()
  end
  self:refresh(results or {}, keyword)
end

function M:_set_waiting_input_state()
  if not_null(self._ui_state_group) then
    self._ui_state_group:SetState(ui_state.waiting_input)
  end
  self:_hide_type_sidebar()
end

function M:_hide_type_sidebar()
  for _, entry in ipairs(self._type_tog_pool) do
    entry.panel:set_active(false)
  end
end

function M:refresh(grouped_results, keyword)
  self._keyword = keyword or self._keyword or ""
  self._all_grouped_results = grouped_results or {}
  self._all_normal_groups, self._all_cook_groups = self:_build_sub_type_groups(self._all_grouped_results)
  local normal_count = self:_count_group_items(self._all_normal_groups)
  local cook_count = self:_count_group_items(self._all_cook_groups)
  local total = normal_count + cook_count
  local has_results = 0 < total
  self:_refresh_result_meta(total, self._keyword, has_results)
  self:_refresh_type_sidebar(self._all_grouped_results)
end

function M:_refresh_result_meta(total, keyword, has_results)
  if not_null(self._txt_result_count) then
    UIUtil.set_text(self._txt_result_count, tostring(total))
  end
  if not_null(self._txt_keyword) then
    UIUtil.set_text(self._txt_keyword, keyword or "")
  end
  if not_null(self._ui_state_group) then
    local state = has_results and ui_state.has_results or ui_state.no_results
    self._ui_state_group:SetState(state)
  end
end

function M:_build_sub_type_groups(grouped_results)
  local normal_groups = {}
  local cook_groups = {}
  for _, type_group in ipairs(grouped_results) do
    local type_name = codex_module:get_type_display_name(type_group.type) or ""
    for _, sub_group in ipairs(type_group.sub_groups or {}) do
      local sub_type_name = codex_module:get_sub_type_display_name(sub_group.sub_type) or ""
      local normal_items = {}
      local cook_items = {}
      for _, entry in ipairs(sub_group.items or {}) do
        local data = entry and entry.data
        if not is_null(data) then
          if data.Type == CodexDataType.Food then
            table.insert(cook_items, entry)
          else
            table.insert(normal_items, entry)
          end
        end
      end
      if 0 < #normal_items then
        table.insert(normal_groups, {
          type = type_group.type,
          type_name = type_name,
          sub_type = sub_group.sub_type,
          sub_type_name = sub_type_name,
          items = normal_items
        })
      end
      if 0 < #cook_items then
        table.insert(cook_groups, {
          type = type_group.type,
          type_name = type_name,
          sub_type = sub_group.sub_type,
          sub_type_name = sub_type_name,
          items = cook_items
        })
      end
    end
  end
  return normal_groups, cook_groups
end

function M:_count_group_items(groups)
  local count = 0
  for _, group in ipairs(groups or {}) do
    count = count + #(group.items or {})
  end
  return count
end

function M:_refresh_scroller(scroller, groups, item_bind_func, node_init_func, list_kind, title_cls_map)
  if is_null(scroller) then
    return
  end
  local node_count = #groups
  UIUtil.set_active(scroller, 0 < node_count)
  scroller:SetNodeCount(node_count)
  if node_count <= 0 then
    return
  end
  for index, group in ipairs(groups) do
    local node_index = index - 1
    local item_count = group.items and #group.items or 0
    scroller:Init(node_index, 0, item_count, pack(self, item_bind_func), pack(self, node_init_func))
  end
  scroller:RebindAllVisibleItems()
  local type_state = self:_get_type_view_state(self._selected_type, false)
  local view_state = type_state and type_state[list_kind] or nil
  if view_state then
    self:_apply_scroller_view_state(scroller, groups, title_cls_map, view_state)
  else
    for index = 1, node_count do
      scroller:ExpandNode(index - 1, 0)
    end
    self:_refresh_group_header_states(scroller, groups, title_cls_map)
    scroller:MoveToNode(0)
  end
end

function M:_on_normal_node_init(node_trans, node_index)
  self:_on_node_init(node_trans, node_index, self._normal_groups, self._normal_title_cls_map, self._scrolllist_normal, result_list_kind.normal)
end

function M:_on_cook_node_init(node_trans, node_index)
  self:_on_node_init(node_trans, node_index, self._cook_groups, self._cook_title_cls_map, self._scrolllist_cook, result_list_kind.cook)
end

function M:_on_node_init(node_trans, node_index, groups, title_cls_map, scroller, list_kind)
  local group = groups[node_index + 1]
  if not group then
    return
  end
  local title_trans = node_trans:Find(group_title_child_name)
  if is_null(title_trans) then
    title_trans = node_trans
  end
  local title_obj_id = title_trans:GetInstanceID()
  local title_cls = title_cls_map[title_obj_id]
  if not title_cls then
    title_cls = self:add_panel(group_header_class, title_trans)
    title_cls_map[title_obj_id] = title_cls
  end
  title_cls:refresh({
    title = self:_get_group_title(group),
    count = #(group.items or {}),
    scroller = scroller,
    node_index = node_index,
    is_expanded = not scroller:IsNodeCollapsed(node_index),
    on_expanded_changed = function(is_expanded)
      self:_set_group_expanded_state(group.type, list_kind, group.sub_type, is_expanded)
    end
  })
end

function M:_get_group_title(group)
  if group.sub_type_name and group.sub_type_name ~= "" then
    return group.sub_type_name
  end
  return group.type_name or ""
end

function M:_on_normal_item_bind(item_trans, node_index, item_index)
  self:_on_item_bind(item_trans, node_index, item_index, self._normal_groups, self._normal_item_cls_map)
end

function M:_on_cook_item_bind(item_trans, node_index, item_index)
  self:_on_item_bind(item_trans, node_index, item_index, self._cook_groups, self._cook_item_cls_map)
end

function M:_on_item_bind(item_trans, node_index, item_index, groups, item_cls_map)
  local group = groups[node_index + 1]
  if not group or not group.items then
    return
  end
  local entry = group.items[item_index + 1]
  local data = entry and entry.data
  if is_null(data) then
    return
  end
  local item_obj_id = item_trans:GetInstanceID()
  local item_cls = item_cls_map[item_obj_id]
  if not item_cls then
    item_cls = self:add_panel(list_item_ctl_class, item_trans)
    item_cls_map[item_obj_id] = item_cls
  end
  item_cls:refresh({
    item_obj_id = item_obj_id,
    data = data,
    sequence = item_index + 1,
    group_index = node_index + 1,
    enter_type = codex_module.codex_page_enter_type.codex_search
  })
end

function M:_refresh_type_sidebar(grouped_results)
  local type_count_map = {}
  for _, type_group in ipairs(grouped_results) do
    local count = 0
    for _, sub_group in ipairs(type_group.sub_groups or {}) do
      count = count + #(sub_group.items or {})
    end
    if 0 < count then
      table.insert(type_count_map, {
        type = type_group.type,
        type_name = codex_module:get_type_display_name(type_group.type) or "",
        count = count
      })
    end
  end
  table.sort(type_count_map, function(a, b)
    return a.count > b.count
  end)
  self._type_sorted_list = type_count_map
  self._selected_type = nil
  local template = self._trans_type_tog_item
  local content = self._trans_content
  if is_null(template) or is_null(content) then
    if 0 < #type_count_map then
      self:_select_type(type_count_map[1].type)
    end
    return
  end
  local total = #type_count_map
  for i, info in ipairs(type_count_map) do
    local entry = self._type_tog_pool[i]
    if not entry then
      local obj = UIUtil.load_prefab_set_parent(template, content)
      local panel = self:add_panel(type_tog_item_class, obj)
      entry = {panel = panel, trans = obj}
      self._type_tog_pool[i] = entry
    end
    entry.panel:set_active(true)
    entry.panel:refresh({
      type = info.type,
      type_name = info.type_name,
      count = info.count,
      on_select = function(type_value)
        self:_on_type_tog_select(type_value)
      end
    })
  end
  for i = total + 1, #self._type_tog_pool do
    self._type_tog_pool[i].panel:set_active(false)
  end
  if 0 < total then
    self._type_tog_pool[1].panel:select()
    self:_select_type(type_count_map[1].type)
  end
end

function M:_on_type_tog_select(type_value)
  if self._selected_type == type_value then
    return
  end
  for _, entry in ipairs(self._type_tog_pool) do
    if entry.panel._type ~= type_value then
      entry.panel:un_select()
    end
  end
  self:_select_type(type_value)
end

function M:_select_type(type_value)
  if self._selected_type ~= nil and self._selected_type ~= type_value then
    self:_save_selected_type_view_state()
  end
  self._selected_type = type_value
  self:_refresh_list_by_type(type_value)
end

function M:_refresh_list_by_type(type_value)
  self._normal_groups = self:_filter_groups_by_type(self._all_normal_groups, type_value)
  self._cook_groups = self:_filter_groups_by_type(self._all_cook_groups, type_value)
  self:_refresh_scroller(self._scrolllist_normal, self._normal_groups, M._on_normal_item_bind, M._on_normal_node_init, result_list_kind.normal, self._normal_title_cls_map)
  self:_refresh_scroller(self._scrolllist_cook, self._cook_groups, M._on_cook_item_bind, M._on_cook_node_init, result_list_kind.cook, self._cook_title_cls_map)
end

function M:_filter_groups_by_type(all_groups, type_value)
  if type_value == nil then
    return all_groups
  end
  local filtered = {}
  for _, group in ipairs(all_groups) do
    if group.type == type_value then
      table.insert(filtered, group)
    end
  end
  return filtered
end

function M:_close_scroller(scroller)
  if not is_null(scroller) then
    scroller:Close()
  end
end

return M
