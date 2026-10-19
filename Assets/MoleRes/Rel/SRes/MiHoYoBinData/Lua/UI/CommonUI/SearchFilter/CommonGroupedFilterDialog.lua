local M = G.Class("CommonGroupedFilterDialog", G.UIWindow)
local base = G.UIWindow
local default_group_item_cls = "UI/CommonUI/SearchFilter/CommonGroupedFilterGroupItem"
local default_toggle_item_cls = "UI/CommonUI/SearchFilter/CommonGroupedFilterToggleItem"

local function clone_selected(source)
  local selected = {}
  for group_key, group_selected in pairs(source or {}) do
    selected[group_key] = {}
    for item_key, is_on in pairs(group_selected or {}) do
      if is_on == true then
        selected[group_key][item_key] = true
      end
    end
  end
  return selected
end

local function has_selected(selected, group_key, item_key)
  return selected and selected[group_key] and selected[group_key][item_key] == true
end

local function set_selected(selected, group_key, item_key, is_on, mode)
  selected[group_key] = selected[group_key] or {}
  if mode == "single" and is_on then
    selected[group_key] = {}
  end
  selected[group_key][item_key] = is_on == true or nil
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CompanionStar/StarBay/StarBayDiaryFilterDialog"
  self.config.type = EUIType.Dialog
  self._group_views = {}
  self._toggle_views = {}
  self._group_item_cls = default_group_item_cls
  self._toggle_item_cls = default_toggle_item_cls
  self._default_title_text_id = "StarBayDiaryFilterDialog_txt_title_1"
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_close) then
    self:bind_close_btn(self._btn_close)
  end
  if not is_null(self._btn_bg) then
    self:bind_close_btn(self._btn_bg)
  end
  if not is_null(self._btn_reset) then
    self:bind_callback(self._btn_reset, pack(self, M._reset_draft_state))
  end
  if not is_null(self._btn_confirm) then
    self:bind_callback(self._btn_confirm, pack(self, M._confirm_filter_state))
  end
end

function M:on_open()
  self:_clear_view_cache()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._filter_groups = data.groups or data.filter_groups or {}
  self._confirm_callback = data.on_confirm
  self._group_item_cls = data.group_item_cls or default_group_item_cls
  self._toggle_item_cls = data.toggle_item_cls or default_toggle_item_cls
  self._draft_selected = clone_selected(data.selected)
  local title_text_id = data.title_text_id or self._default_title_text_id
  UIUtil.set_text(self._txt_title, UIUtil.get_text_by_id(title_text_id))
  self:_refresh_groups()
end

function M:_refresh_groups()
  if is_null(self._grouped_node_scroller) then
    return
  end
  local node_count = #self._filter_groups
  UIUtil.set_active(self._grouped_node_scroller, 0 < node_count)
  if node_count <= 0 then
    return
  end
  self._grouped_node_scroller:SetNodeCount(node_count)
  for index, group_data in ipairs(self._filter_groups) do
    local node_index = index - 1
    local item_count = group_data.items and #group_data.items or 0
    self._grouped_node_scroller:ExpandNode(node_index, 0)
    self._grouped_node_scroller:Init(node_index, 0, item_count, pack(self, M._on_group_item_bind), pack(self, M._on_group_node_init))
    self._grouped_node_scroller:ExpandNode(node_index, 0)
  end
  self._grouped_node_scroller:Refresh()
  self._grouped_node_scroller:RebindAllVisibleItems()
  self._grouped_node_scroller:MoveToNode(0)
  self:_force_rebuild_scroller_layout()
end

function M:_on_group_node_init(node_trans, node_index)
  local group_data = self._filter_groups[node_index + 1]
  if group_data == nil then
    return
  end
  local group_view = self:_get_group_view(node_trans)
  group_view:refresh({
    title = group_data.title,
    title_text_id = group_data.title_text_id,
    scroller = self._grouped_node_scroller,
    node_index = node_index,
    is_expanded = not self._grouped_node_scroller:IsNodeCollapsed(node_index)
  })
end

function M:_on_group_item_bind(item_trans, node_index, item_index)
  local group_data = self._filter_groups[node_index + 1]
  local item_data = group_data and group_data.items and group_data.items[item_index + 1] or nil
  if item_data == nil then
    return
  end
  local group_key = group_data.group_key
  local item_panel = self:_get_toggle_view(item_trans)
  item_panel:refresh({
    key = item_data.key,
    label = item_data.label,
    label_text_id = item_data.label_text_id,
    count = item_data.count,
    icon_path = item_data.icon_path,
    style_state_id = item_data.style_state_id,
    use_color_state = item_data.use_color_state == true or group_data.use_color_state == true,
    is_on = has_selected(self._draft_selected, group_key, item_data.key),
    on_change = function(key, is_on)
      self:_on_item_toggle(group_key, key, is_on)
    end
  })
end

function M:_get_group_view(node_trans)
  local instance_id = node_trans:GetInstanceID()
  local group_view = self._group_views[instance_id]
  if group_view ~= nil then
    return group_view
  end
  group_view = self:add_panel(self._group_item_cls, node_trans)
  self._group_views[instance_id] = group_view
  return group_view
end

function M:_get_toggle_view(item_trans)
  local instance_id = item_trans:GetInstanceID()
  local item_view = self._toggle_views[instance_id]
  if item_view ~= nil then
    return item_view
  end
  item_view = self:add_panel(self._toggle_item_cls, item_trans)
  self._toggle_views[instance_id] = item_view
  return item_view
end

function M:_clear_view_cache()
  for _, group_view in pairs(self._group_views or {}) do
    self:_release_cached_view(group_view)
  end
  for _, toggle_view in pairs(self._toggle_views or {}) do
    self:_release_cached_view(toggle_view)
  end
  self._group_views = {}
  self._toggle_views = {}
end

function M:_release_cached_view(view)
  if view == nil then
    return
  end
  if view._session_opened then
    view:on_close()
  end
  view:on_destroy()
  self:_release_cached_view_load_proxy(view)
  if self.container then
    table.removewhere(self.container, function(panel)
      return panel == view
    end)
  end
  view:on_release()
end

function M:_release_cached_view_load_proxy(view)
  if not is_null(view._prefab_load_proxy) then
    ResourcesUtil.DeallocatePrefabLoadProxy(view._prefab_load_proxy)
    view._prefab_load_proxy = nil
  end
  if not is_null(view._asset_load_proxy) then
    ResourcesUtil.DeallocateAssetLoadProxy(view._asset_load_proxy)
    view._asset_load_proxy = nil
  end
end

function M:_force_rebuild_scroller_layout()
  Canvas.ForceUpdateCanvases()
  LayoutRebuilder.ForceRebuildLayoutImmediate(self._grouped_node_scroller.transform)
end

function M:_on_item_toggle(group_key, key, is_on)
  local group_data = self:_get_group_data(group_key)
  local mode = group_data and group_data.selection_mode or "multi"
  set_selected(self._draft_selected, group_key, key, is_on == true, mode)
  if mode == "single" and is_on == true then
    self:_refresh_visible_items()
  end
end

function M:_get_group_data(group_key)
  for _, group_data in ipairs(self._filter_groups or {}) do
    if group_data.group_key == group_key then
      return group_data
    end
  end
  return nil
end

function M:_refresh_visible_items()
  if is_null(self._grouped_node_scroller) then
    return
  end
  self._grouped_node_scroller:RebindAllVisibleItems()
end

function M:_reset_draft_state()
  self._draft_selected = {}
  self:_refresh_groups()
end

function M:_confirm_filter_state()
  if self._confirm_callback then
    self._confirm_callback(clone_selected(self._draft_selected))
  end
  self:close_self()
end

function M:on_destroy()
  self:_clear_view_cache()
  if not is_null(self._grouped_node_scroller) then
    self._grouped_node_scroller:Close()
  end
  base.on_destroy(self)
end

return M
