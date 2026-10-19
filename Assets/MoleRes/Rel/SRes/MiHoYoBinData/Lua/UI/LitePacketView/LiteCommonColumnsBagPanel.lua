local M = G.Class("LiteCommonColumnsBagPanel", "UI/LitePacketView/LiteCommonBagPanel")
local base = G.LiteCommonBagPanel
local column_title_cls = "UI/ConfirmView/ItemConfirmColumnTitle"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LitePacketView/LiteCommonColumnsBagPanel"
  self._display_groups = {}
  self._title_items = {}
end

function M:on_destroy()
  if not is_null(self._grouped_node_scroller) then
    self._grouped_node_scroller:Close()
  end
  self._display_groups = {}
  self._title_items = {}
  base.on_destroy(self)
end

function M:_refresh_grid_scroller(item_count)
  self._tbl_item_id = {}
  self._display_groups = self:_build_display_groups()
  local scroller = self._grouped_node_scroller
  if is_null(scroller) then
    Logger.LogError("分栏背包缺少 _grouped_node_scroller 绑定! lua class name = " .. self.__cname)
    return
  end
  local group_count = #self._display_groups
  scroller:SetNodeCount(group_count)
  for i = 1, group_count do
    local node_index = i - 1
    scroller:Init(node_index, 0, #self._display_groups[i].flat_indices, pack(self, M._on_grouped_item_bind), pack(self, M._on_grouped_node_init))
    scroller:ExpandNode(node_index, 0)
  end
  scroller:RebindAllVisibleItems()
  if self._is_init or self._is_reload_grid_scroller then
    scroller:MoveToNode(0)
  end
  self._is_init = false
  self._is_reload_grid_scroller = false
  self._packet_max_num = item_count
  local select_index = self._select_item_index
  if item_count < self._select_item_index then
    self:_select_item(item_count)
  else
    self:_select_item(select_index)
  end
end

function M:grid_scroller_refresh_current()
  if not is_null(self._grouped_node_scroller) then
    self._grouped_node_scroller:RebindAllVisibleItems()
  end
end

function M:_build_display_groups()
  local flat_indices = {}
  for i = 1, #self._lst_cur_show_data do
    flat_indices[i] = i
  end
  if #flat_indices == 0 then
    return {}
  end
  return {
    {
      key = "all",
      title = "",
      flat_indices = flat_indices
    }
  }
end

function M:_on_grouped_node_init(node_trans, node_index)
  local instance_id = node_trans:GetInstanceID()
  local title_item = self._title_items[instance_id]
  if title_item == nil then
    title_item = self:add_panel(column_title_cls, node_trans)
    self._title_items[instance_id] = title_item
  end
  local group = self._display_groups[node_index + 1]
  title_item:set_title(group and group.title or "")
end

function M:_on_grouped_item_bind(item_trans, node_index, item_index)
  local group = self._display_groups[node_index + 1]
  local flat_index = group and group.flat_indices[item_index + 1] or nil
  if flat_index == nil then
    return
  end
  local item_id = tostring(item_trans:GetInstanceID())
  self._tbl_item_id[flat_index] = item_id
  local cls = self._tbl_items[item_id]
  if cls == nil then
    cls = self:add_panel(back_bag_module.packet_stack_item_cls_name, item_trans)
    self:bind_callback(cls:get_btn(), function()
      self:_item_btn_click(cls)
    end)
    self:bind_callback(cls:get_btn_subtract(), function()
      self:_subtract_btn_click(cls)
    end)
    self._tbl_items[item_id] = cls
  end
  local item_data = self._lst_cur_show_data[flat_index] or {}
  if is_null(item_data) or is_null(item_data.server_data) or is_null(item_data.index) then
    self:_init_item_extra_data(item_data, flat_index)
  end
  cls:deactive_tutorial()
  if self._tutorial_guid and self._tutorial_guid == item_data.guid then
    item_data.is_set_tutorial = true
    item_data.tutorial_ui_key = self._tutorial_key
  end
  if self.cur_item_select_type == back_bag_module.packet_item_select_type.num_multi_selected then
    cls:set_cur_num_txt(self._tbl_cur_multi_stack[item_data.guid] or 0)
  elseif self.cur_item_select_type == back_bag_module.packet_item_select_type.fixed_num_multi_selected then
    cls:set_cur_num_txt(self:get_item_select_num_by_guid(item_data.guid))
  end
  if not_null(item_data) and not_null(item_data.server_data) then
    local dynamic_lock_state = self:_get_item_dynamic_lock_state(item_data.server_data)
    if item_data.dynamic_lock_state ~= dynamic_lock_state then
      item_data.dynamic_lock_state = dynamic_lock_state
    end
  end
  cls:set_extra_data(item_data)
  cls:refresh()
  cls:refresh_tracking_point_state(self._bag_show_type)
  if not cls.is_active then
    cls:set_active(true)
  end
end

return M
