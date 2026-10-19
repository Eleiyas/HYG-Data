local M = G.Class("GeLianMarketFriendPricePanel", G.UIPanel)
local base = G.UIPanel
local friend_price_item_cls = "UI/GeLianMarket/Panel/GeLianMarketFriendPriceEntryPanel"
local inventory_item_cls = "UI/GeLianMarket/Panel/GeLianMarketCropInventoryPanel"
local SORT_DEFAULT = "default"

function M:init()
  base.init(self)
  self._self_row = nil
  self._friend_rows = {}
  self._crop_entries = {}
  self._items = {}
  self._inventory_items = {}
  self._self_item = nil
  self._is_scroller_inited = false
  self._sort_value = SORT_DEFAULT
  self._sort_index = 1
end

function M:on_create()
  base.on_create(self)
  self._self_item = self:add_panel(friend_price_item_cls, self._trans_self_item)
  self:bind_callback(self._btn_sort, pack(self, M._on_btn_sort))
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_view()
end

function M:on_disable()
  self:hide_all_visit_btn()
  base.on_disable(self)
end

function M:on_destroy()
  if self._is_scroller_inited then
    self._grid_scroller:Close()
  end
  self._is_scroller_inited = false
  self._self_row = nil
  self._friend_rows = {}
  self._crop_entries = {}
  self._items = {}
  self._inventory_items = {}
  self._self_item = nil
  base.on_destroy(self)
end

function M:render(view_data)
  self:_refresh_view_data(view_data)
  self:_refresh_view()
end

function M:_refresh_view_data(view_data)
  self._self_row = view_data and view_data.self_row or nil
  self._friend_rows = table.shallow_copy(view_data and view_data.friend_rows or {})
  self._crop_entries = view_data and view_data.crop_entries or {}
  self:_sort_friend_rows()
end

function M:_refresh_view()
  if not (self._self_row and self._friend_rows) or not self._crop_entries then
    return
  end
  self._self_item:render(self._self_row)
  self:_refresh_inventory()
  if self._state_group_price then
    self._state_group_price:SetState(#self._friend_rows > 0 and 0 or 1)
  end
  if self._is_scroller_inited then
    self._grid_scroller:ReLoad(pack(self, M._refresh_item), #self._friend_rows)
  else
    self._grid_scroller:Init(pack(self, M._refresh_item), #self._friend_rows)
    self._is_scroller_inited = true
  end
end

function M:hide_all_visit_btn()
  if self._self_item ~= nil then
    self._self_item:hide_visit_btn()
  end
  for _, item in pairs(self._items) do
    item:hide_visit_btn()
  end
end

function M:_refresh_inventory()
  for i = #self._inventory_items + 1, #self._crop_entries do
    local trans = self._list_item_binder_inventory:AddItem(0, true)
    self._inventory_items[i] = self:add_panel(inventory_item_cls, trans)
  end
  for i = 1, #self._inventory_items do
    local entry = self._crop_entries[i]
    self._inventory_items[i]:render(entry)
  end
end

function M:_refresh_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local item = self._items[instance_id]
  if item == nil then
    item = self:add_panel(friend_price_item_cls, trans)
    self._items[instance_id] = item
  end
  item:render(self._friend_rows[index])
end

function M:_on_btn_sort()
  local options = {
    {
      title = UIUtil.get_text_by_id("Market_FriendPrice_Sort_Default"),
      value = SORT_DEFAULT
    }
  }
  for i = 1, #self._crop_entries do
    local entry = self._crop_entries[i]
    local item_name = item_module:get_item_name_by_id(entry.display_config_id)
    options[#options + 1] = {
      title = UIUtil.get_text_by_id("Market_FriendPrice_Sort_CropPrice", item_name),
      value = entry.tag
    }
  end
  common_ui_module:show_sort_dialog(options, self._sort_index, pack(self, M._on_sort_selected), self._btn_sort.transform, nil, 1)
end

function M:_on_sort_selected(sort_value, sort_index)
  self._sort_value = sort_value or SORT_DEFAULT
  self._sort_index = sort_index or 1
  self:hide_all_visit_btn()
  self:_sort_friend_rows()
  if self._is_scroller_inited then
    self._grid_scroller:ReLoad(pack(self, M._refresh_item), #self._friend_rows)
    self._grid_scroller:MoveTo(0)
  end
end

function M:_sort_friend_rows()
  local sort_value = self._sort_value
  table.sort(self._friend_rows, function(a, b)
    if sort_value ~= SORT_DEFAULT then
      local a_price = M._get_crop_price(a, sort_value)
      local b_price = M._get_crop_price(b, sort_value)
      if a_price ~= b_price then
        return a_price > b_price
      end
    else
      if a.is_online ~= b.is_online then
        return a.is_online
      end
      if a.has_price ~= b.has_price then
        return a.has_price
      end
      if a.intimacy ~= b.intimacy then
        return a.intimacy > b.intimacy
      end
    end
    return a.uid < b.uid
  end)
end

function M._get_crop_price(row, tag)
  local entries = row.entries or {}
  for i = 1, #entries do
    if entries[i].tag == tag then
      return entries[i].final_price or -1
    end
  end
  return -1
end

return M
