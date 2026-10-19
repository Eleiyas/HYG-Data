local M = G.Class("ItemConfirmColumnsDialog", "UI/ConfirmView/ItemConfirmWindowBase")
local base = G.ItemConfirmWindowBase
local column_title_cls = "UI/ConfirmView/ItemConfirmColumnTitle"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/ConfirmView/ItemConfirmColumnsDialog"
  self.config.type = EUIType.Dialog
  self._column_groups = {}
  self._title_items = {}
  self._column_items = {}
end

function M:on_destroy()
  self._grouped_node_scroller:Close()
  self._column_groups = {}
  self._title_items = {}
  self._column_items = {}
  base.on_destroy(self)
end

function M:refresh_data(data)
  base.refresh_data(self, data)
  self._column_groups = data and data.groups or {}
  self._coin_type = data and data.coin_type or nil
  self._all_price = data and data.all_price or nil
end

function M:refresh_ui()
  base.refresh_ui(self)
  if not_null(self._img_coin) and self._coin_type ~= nil then
    item_module:set_item_icon(self._img_coin, self._coin_type, nil, nil, self:get_load_proxy())
  end
  if not_null(self._txt_all_price) and self._all_price ~= nil then
    UIUtil.set_text(self._txt_all_price, self._all_price)
  end
end

function M:refresh_grid_scroller(item_count)
  local scroller = self._grouped_node_scroller
  local groups = self._column_groups or {}
  scroller:SetNodeCount(#groups)
  for i = 1, #groups do
    local node_index = i - 1
    local group_item_count = #(groups[i].items or {})
    scroller:Init(node_index, 0, group_item_count, pack(self, M._on_item_bind), pack(self, M._on_node_init))
    scroller:ExpandNode(node_index, 0)
  end
  scroller:RebindAllVisibleItems()
  scroller:MoveToNode(0)
end

function M:_on_node_init(node_trans, node_index)
  local instance_id = node_trans:GetInstanceID()
  local title_item = self._title_items[instance_id]
  if title_item == nil then
    title_item = self:add_panel(column_title_cls, node_trans)
    self._title_items[instance_id] = title_item
  end
  local group = self._column_groups[node_index + 1]
  title_item:render(group)
end

function M:_on_item_bind(item_trans, node_index, item_index)
  local instance_id = item_trans:GetInstanceID()
  local item = self._column_items[instance_id]
  if item == nil then
    item = self:add_panel(item_module.item_v2_panel_cls_name, item_trans)
    self._column_items[instance_id] = item
  end
  local group = self._column_groups[node_index + 1]
  local item_data = group and group.items and group.items[item_index + 1] or nil
  if item_data == nil then
    item:set_active(false)
    return
  end
  item:set_active(true)
  item:set_item_data(item_data.config_id, item_data.num, item_data.server_data)
  item:bind_item_info_btn(item_data.config_id)
end

return M
