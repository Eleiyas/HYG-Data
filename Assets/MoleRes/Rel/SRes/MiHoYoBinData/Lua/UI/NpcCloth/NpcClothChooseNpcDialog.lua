local M = G.Class("NpcClothChooseNpcDialog", G.UIWindow)
local base = G.UIWindow
local GROUP_ITEM_CLS = "UI/NpcCloth/NpcClothChooseNpcGroupItem"
local ITEM_CLS = "UI/NpcCloth/NpcClothChooseNpcItem"

local function safe_get_string(obj, field_name)
  if obj == nil then
    return nil
  end
  local ok, value = pcall(function()
    return obj[field_name]
  end)
  if ok and string.is_valid(value) then
    return value
  end
  return nil
end

local function get_shape_title(shape_key)
  local text_id
  if shape_key == "NpcSmall" then
    text_id = "NpcCloth_Machine_SizeShape_Small"
  elseif shape_key == "NpcBig" then
    text_id = "NpcCloth_Machine_SizeShape_Big"
  else
    text_id = "NpcCloth_Machine_SizeShape_Medium"
  end
  if UIUtil.is_valid_text_id and UIUtil.is_valid_text_id(text_id) then
    return UIUtil.get_text_by_id(text_id)
  end
  return text_id
end

local function normalize_selected_map(source)
  local result = {}
  for shape, npc_id in pairs(source or {}) do
    local shape_key = type(shape) == "number" and npc_cloth_module.get_shape_key_by_id(shape) or npc_cloth_module.get_shape_key_by_id(shape) or shape
    local normalized_npc_id = tonumber(npc_id) or 0
    if string.is_valid(shape_key) and 0 < normalized_npc_id then
      result[shape_key] = normalized_npc_id
    end
  end
  return result
end

local function build_result_selected_map(source)
  local result = {}
  for shape_key, npc_id in pairs(source or {}) do
    local shape_id = npc_cloth_module.get_shape_id_by_key(shape_key)
    if 0 < shape_id then
      result[shape_id] = npc_id
    end
  end
  return result
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcCloth/NpcClothChooseNpcDialog"
  self.config.type = EUIType.Dialog
  self._group_views = {}
  self._item_views = {}
  self._npc_groups = {}
  self._selected_npc_by_shape = {}
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_cancel) then
    self:bind_callback(self._btn_cancel, pack(self, M._on_cancel_click))
  end
  if not is_null(self._btn_confirm) then
    self:bind_callback(self._btn_confirm, pack(self, M._on_confirm_click))
  end
  if not is_null(self._btn_close) then
    self:bind_callback(self._btn_close, pack(self, M._on_cancel_click))
  end
  self:bind_callback(self._btn_close, pack(self, M._on_cancel_click))
  self:bind_callback(self._btn_bg, pack(self, M._on_cancel_click))
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._confirm_callback = data.confirm_callback
  self._cancel_callback = data.cancel_callback
  self._npc_groups = self:_build_npc_groups(data.npc_list, data.selected_npc_by_shape)
  self:_refresh_title()
  self:_refresh_groups()
  self:_refresh_confirm_state()
  self:_refresh_btn_text()
end

function M:on_destroy()
  if not is_null(self._scroll_npc_list) and self._scroll_npc_list.Close then
    self._scroll_npc_list:Close()
  end
  base.on_destroy(self)
end

function M:handle_back(action)
  self:_on_cancel_click()
  action.handled = true
end

function M:_build_npc_groups(npc_list, selected_npc_by_shape)
  local grouped_map = {}
  local grouped_list = {}
  self._selected_npc_by_shape = normalize_selected_map(selected_npc_by_shape)
  for _, npc_data in ipairs(npc_list or {}) do
    local detail = self:_build_npc_detail(npc_data)
    if detail ~= nil then
      local group = grouped_map[detail.shape_key]
      if group == nil then
        group = {
          shape_key = detail.shape_key,
          title = get_shape_title(detail.shape_key),
          items = {}
        }
        grouped_map[detail.shape_key] = group
        grouped_list[#grouped_list + 1] = group
      end
      group.items[#group.items + 1] = detail
    end
  end
  table.sort(grouped_list, function(a, b)
    local shape_a = npc_cloth_module.get_shape_id_by_key(a.shape_key)
    local shape_b = npc_cloth_module.get_shape_id_by_key(b.shape_key)
    return (0 < shape_a and shape_a or 99) < (0 < shape_b and shape_b or 99)
  end)
  self:_apply_default_selection(grouped_list)
  return grouped_list
end

function M:_build_npc_detail(npc_data)
  local npc_id = npc_data and (npc_data.npc_id or npc_data.id or npc_data.config_id) or 0
  if npc_id <= 0 then
    return nil
  end
  local npc_cfg = ExcelDataUtil.get_value(typeof(BNpcCfg), npc_id)
  if npc_cfg == nil then
    return nil
  end
  local raw_shape = self:_get_npc_avatar_shape_type(npc_id)
  local shape_key = npc_cloth_module.get_npc_shape_key(npc_id)
  local shape_code = npc_cloth_module.get_npc_shape_code(npc_id)
  if not string.is_valid(shape_key) then
    return nil
  end
  return {
    npc_id = npc_id,
    name = safe_get_string(npc_cfg, "name") or tostring(npc_id),
    icon = safe_get_string(npc_cfg, "iconnamesmall") or "",
    raw_shape = raw_shape,
    shape_key = shape_key,
    shape_code = shape_code
  }
end

function M:_get_npc_avatar_shape_type(npc_id)
  local avatar_cfg = npc_id and ExcelDataUtil.get_value(typeof(BAvatarCfg), npc_id) or nil
  return avatar_cfg and safe_get_string(avatar_cfg, "avatarshapetype") or nil
end

function M:_apply_default_selection(grouped_list)
  for _, group in ipairs(grouped_list or {}) do
    local selected_npc_id = self._selected_npc_by_shape[group.shape_key]
    local has_selected = false
    for _, npc_detail in ipairs(group.items or {}) do
      if npc_detail.npc_id == selected_npc_id then
        has_selected = true
        break
      end
    end
    if not has_selected and group.items and group.items[1] then
      self._selected_npc_by_shape[group.shape_key] = group.items[1].npc_id
    end
  end
end

function M:_refresh_title()
  UIUtil.set_text_by_id(self._txt_title, "NpcCloth_Machine_SizeShape_Select")
end

function M:_refresh_groups()
  if is_null(self._scroll_npc_list) then
    return
  end
  local node_count = #self._npc_groups
  UIUtil.set_active(self._scroll_npc_list, 0 < node_count)
  self._scroll_npc_list:SetNodeCount(node_count)
  for index, group_data in ipairs(self._npc_groups) do
    local node_index = index - 1
    local item_count = group_data.items and #group_data.items or 0
    self._scroll_npc_list:ExpandNode(node_index, 0)
    self._scroll_npc_list:Init(node_index, 0, item_count, pack(self, M._on_group_item_bind), pack(self, M._on_group_node_init))
    self._scroll_npc_list:ExpandNode(node_index, 0)
  end
  if self._scroll_npc_list.Refresh then
    self._scroll_npc_list:Refresh()
  end
  self._scroll_npc_list:RebindAllVisibleItems()
  if 0 < node_count then
    self._scroll_npc_list:MoveToNode(0)
  end
end

function M:_on_group_node_init(node_trans, node_index)
  local group_data = self._npc_groups[node_index + 1]
  if group_data == nil then
    return
  end
  local instance_id = node_trans:GetInstanceID()
  local group_view = self._group_views[instance_id]
  if group_view == nil then
    group_view = self:add_panel(GROUP_ITEM_CLS, node_trans)
    self._group_views[instance_id] = group_view
  end
  group_view:refresh(group_data)
end

function M:_on_group_item_bind(item_trans, node_index, item_index)
  local group_data = self._npc_groups[node_index + 1]
  local item_data = group_data and group_data.items and group_data.items[item_index + 1] or nil
  if item_data == nil then
    return
  end
  local instance_id = item_trans:GetInstanceID()
  local item_view = self._item_views[instance_id]
  if item_view == nil then
    item_view = self:add_panel(ITEM_CLS, item_trans)
    self._item_views[instance_id] = item_view
  end
  item_view:refresh({
    npc_id = item_data.npc_id,
    name = item_data.name,
    icon = item_data.icon,
    shape_code = item_data.shape_code,
    is_selected = self._selected_npc_by_shape[group_data.shape_key] == item_data.npc_id,
    on_select = function(npc_id)
      self:_on_select_npc(group_data.shape_key, npc_id)
    end
  })
end

function M:_on_select_npc(shape_key, npc_id)
  self._selected_npc_by_shape[shape_key] = npc_id
  if not is_null(self._scroll_npc_list) then
    self._scroll_npc_list:RebindAllVisibleItems()
  end
end

function M:_refresh_confirm_state()
  if not is_null(self._btn_confirm) then
    self._btn_confirm.interactable = #self._npc_groups > 0
  end
end

function M:_refresh_btn_text()
  UIUtil.set_text_by_id(self._txt_cancel, "Common_Cancel")
  UIUtil.set_text_by_id(self._txt_confirm, "Common_Confirm")
end

function M:_on_confirm_click()
  if self._confirm_callback then
    self._confirm_callback(build_result_selected_map(self._selected_npc_by_shape))
  end
  self:close_self()
end

function M:_on_cancel_click()
  if self._cancel_callback then
    self._cancel_callback()
  end
  self:close_self()
end

return M
