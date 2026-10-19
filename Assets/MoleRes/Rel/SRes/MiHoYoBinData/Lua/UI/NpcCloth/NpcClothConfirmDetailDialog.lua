local M = G.Class("NpcClothConfirmDetailDialog", G.UIWindow)
local base = G.UIWindow
local ITEM_CLS = "UI/NpcCloth/NpcClothConfirmDetailItem"

local function clamp_num(num, max_num)
  max_num = math.max(tonumber(max_num) or 1, 1)
  num = tonumber(num) or 1
  if num < 1 then
    return 1
  end
  if max_num < num then
    return max_num
  end
  return math.floor(num)
end

local function clone_result_item(item)
  return {
    key = item.key,
    item_id = item.item_id,
    num = item.num,
    unit_price = item.unit_price,
    extra = item.extra
  }
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcCloth/NpcClothConfirmDetailDialog"
  self.config.type = EUIType.Dialog
  self._items = {}
  self._item_views = {}
  self._list_inited = false
  self._on_change_num_proxy = pack(self, M._on_item_num_changed)
  self._on_delete_proxy = pack(self, M._on_item_delete_click)
  
  function self._on_query_can_add_proxy(item_key, next_num)
    return self:_on_item_query_can_add(item_key, next_num)
  end
  
  function self._on_query_affordable_max_proxy(item_key)
    return self:_on_item_query_affordable_max(item_key)
  end
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
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._coin_id = data.coin_id or 0
  self._available_balance_func = data.available_balance_func
  self._confirm_callback = data.confirm_callback
  self._cancel_callback = data.cancel_callback
  self._items = self:_clone_items(data.items)
  self._deleted_items = {}
  self:_refresh_dialog()
end

function M:on_destroy()
  if not is_null(self._scroll_npc_cloth_list) and self._scroll_npc_cloth_list.Close then
    self._scroll_npc_cloth_list:Close()
  end
  self._available_balance_func = nil
  base.on_destroy(self)
end

function M:handle_back(action)
  self:_on_cancel_click()
  action.handled = true
end

function M:_clone_items(raw_items)
  local result = {}
  for _, raw_item in ipairs(raw_items or {}) do
    local max_num = math.max(tonumber(raw_item.max_num) or 1, 1)
    result[#result + 1] = {
      key = raw_item.key,
      item_id = raw_item.item_id or 0,
      num = clamp_num(raw_item.default_num, max_num),
      max_num = max_num,
      unit_price = tonumber(raw_item.unit_price) or 0,
      extra = raw_item.extra
    }
  end
  return result
end

function M:_refresh_dialog()
  self:_refresh_list()
  self:_refresh_total_price()
  self:_refresh_confirm_state()
end

function M:_refresh_list()
  if is_null(self._scroll_npc_cloth_list) then
    return
  end
  local count = #self._items
  UIUtil.set_active(self._scroll_npc_cloth_list, 0 < count)
  if self._scroll_npc_cloth_list.Init == nil then
    return
  end
  if self._list_inited and self._scroll_npc_cloth_list.ReLoad then
    self._scroll_npc_cloth_list:ReLoad(pack(self, M._on_item_bind), count)
  else
    self._scroll_npc_cloth_list:Init(pack(self, M._on_item_bind), count)
    self._list_inited = true
  end
  if self._scroll_npc_cloth_list.RefreshCurrent then
    self._scroll_npc_cloth_list:RefreshCurrent()
  end
end

function M:_on_item_bind(item_trans, index)
  local item = self._items[index + 1]
  if item == nil then
    return
  end
  local instance_id = item_trans:GetInstanceID()
  local item_view = self._item_views[instance_id]
  if item_view == nil then
    item_view = self:add_panel(ITEM_CLS, item_trans)
    self._item_views[instance_id] = item_view
  end
  item_view:refresh({
    key = item.key,
    item_id = item.item_id,
    num = item.num,
    max_num = item.max_num,
    unit_price = item.unit_price,
    on_change_num = self._on_change_num_proxy,
    on_delete = self._on_delete_proxy,
    on_query_can_add = self._on_query_can_add_proxy,
    on_query_affordable_max = self._on_query_affordable_max_proxy
  })
end

function M:_on_item_num_changed(item_key, num)
  for _, item in ipairs(self._items) do
    if item.key == item_key then
      item.num = clamp_num(num, item.max_num)
      break
    end
  end
  self:_refresh_total_price()
  if not is_null(self._scroll_npc_cloth_list) and self._scroll_npc_cloth_list.RefreshCurrent then
    self._scroll_npc_cloth_list:RefreshCurrent()
  end
end

function M:_on_item_query_can_add(item_key, next_num)
  local item = self:_find_item_by_key(item_key)
  return self:_can_add_num(item, tonumber(next_num) or 0)
end

function M:_on_item_query_affordable_max(item_key)
  local item = self:_find_item_by_key(item_key)
  return self:_get_affordable_max(item)
end

function M:_find_item_by_key(item_key)
  for _, item in ipairs(self._items or {}) do
    if item.key == item_key then
      return item
    end
  end
  return nil
end

function M:_on_item_delete_click(item_key)
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("NpcCloth_ConfirmDetail_Delete_Warning"), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    self:_delete_item(item_key)
  end, nil, nil, nil)
  popup:show()
end

function M:_delete_item(item_key)
  for index, item in ipairs(self._items) do
    if item.key == item_key then
      self._deleted_items[#self._deleted_items + 1] = item
      table.remove(self._items, index)
      break
    end
  end
  if #self._items <= 0 then
    self:_on_cancel_click()
    return
  end
  self:_refresh_dialog()
end

function M:_get_total_price()
  local total_price = 0
  for _, item in ipairs(self._items or {}) do
    total_price = total_price + (item.num or 0) * (item.unit_price or 0)
  end
  return total_price
end

function M:_refresh_total_price()
  local total_price = self:_get_total_price()
  local not_enough = 0 < total_price and total_price > self:_get_coin_balance()
  local display_text = not_enough and string.format("<style=TextWarning_Light>%s</style>", tostring(total_price)) or tostring(total_price)
  if not is_null(self._txt_coin_total) then
    UIUtil.set_text(self._txt_coin_total, display_text)
  end
  if not is_null(self._txt_coin_Light) then
    UIUtil.set_text(self._txt_coin_Light, display_text)
  end
end

function M:_get_coin_balance()
  if self._available_balance_func then
    return math.max(tonumber(self._available_balance_func()) or 0, 0)
  end
  return math.max(back_bag_module:get_coin(self._coin_id or 0) or 0, 0)
end

function M:_can_add_num(item, next_num)
  if item == nil then
    return false
  end
  if next_num > (item.max_num or 1) then
    return false
  end
  local other_price = self:_get_total_price() - (item.num or 0) * (item.unit_price or 0)
  local coin_balance = self:_get_coin_balance()
  local unit_price = item.unit_price or 0
  local result = coin_balance >= other_price + next_num * unit_price
  return result
end

function M:_get_affordable_max(item)
  if item == nil then
    return 1
  end
  local max_num = math.max(tonumber(item.max_num) or 1, 1)
  local unit_price = tonumber(item.unit_price) or 0
  if unit_price <= 0 then
    return max_num
  end
  local other_price = self:_get_total_price() - (item.num or 0) * unit_price
  local balance = self:_get_coin_balance()
  local affordable = math.floor((balance - other_price) / unit_price)
  return math.max(1, math.min(max_num, affordable))
end

function M:_refresh_confirm_state()
  if not is_null(self._btn_confirm) then
    self._btn_confirm.interactable = #self._items > 0
  end
end

function M:_build_confirm_items()
  local result = {}
  for _, item in ipairs(self._items or {}) do
    result[#result + 1] = clone_result_item(item)
  end
  return result
end

function M:_on_confirm_click()
  if #self._items <= 0 then
    return
  end
  local can_close = true
  if self._confirm_callback then
    can_close = self._confirm_callback(self:_build_confirm_items(), self._deleted_items)
  end
  if can_close ~= false then
    self:close_self()
  end
end

function M:_on_cancel_click()
  if self._cancel_callback then
    self._cancel_callback(self._deleted_items)
  end
  self:close_self()
end

return M
