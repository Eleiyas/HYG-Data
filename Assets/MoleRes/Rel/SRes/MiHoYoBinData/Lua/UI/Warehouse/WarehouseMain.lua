warehouse_module = warehouse_module or {}

function warehouse_module:add_event()
  warehouse_module:remove_event()
  self._events = {}
  self._events[EventID.LuaUpdateDepotData] = pack(self, warehouse_module._on_update_warehouse_data_handle)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function warehouse_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function warehouse_module:_on_update_warehouse_data_handle()
  warehouse_module:_refresh_warehouse_data()
end

function warehouse_module:sort_warehouse_item(sort_type, warehouse_items)
  local res_list = {}
  for i = 1, CsWarehouseModuleUtil.WarehouseMaxNum do
    if warehouse_items[i] then
      table.insert(res_list, warehouse_items[i])
    end
  end
  sort_type = sort_type or warehouse_module.warehouse_sort_type.bag_type
  local sort_rule_list = warehouse_module.sort_type2rule_order[sort_type]
  table.sort(res_list, function(a, b)
    local a_cfg = item_module:get_cfg_by_id(a.ConFigID)
    local b_cfg = item_module:get_cfg_by_id(b.ConFigID)
    for _, sort_rule in ipairs(sort_rule_list) do
      local key = sort_rule.key
      if a_cfg[key] ~= b_cfg[key] then
        if sort_rule.asc then
          return a_cfg[key] < b_cfg[key]
        else
          return a_cfg[key] > b_cfg[key]
        end
      end
    end
    return a.GUID < b.GUID
  end)
  return res_list
end

return warehouse_module
