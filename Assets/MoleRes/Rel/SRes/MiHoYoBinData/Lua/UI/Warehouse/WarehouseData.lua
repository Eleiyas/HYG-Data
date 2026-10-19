warehouse_module = warehouse_module or {}

function warehouse_module:_init_data()
  self._all_warehouse_data = nil
  self._cur_warehouse_num = 0
end

function warehouse_module:get_warehouse_item_num(item_id)
  return CsWarehouseModuleUtil.GetWarehouseItemNumByCfgId(item_id, 0)
end

function warehouse_module:_refresh_warehouse_data()
  self._all_warehouse_data = dic_to_list_table(CsWarehouseModuleUtil.AllWarehouseItemDic)
  self._cur_warehouse_num = #self._all_warehouse_data
end

function warehouse_module:get_warehouse_items_by_warehouse_item_type(warehouse_item_type)
  if warehouse_item_type == nil or not table.contains(warehouse_module.warehouse_show_order, warehouse_item_type) then
    warehouse_item_type = warehouse_module.warehouse_show_order[1]
  end
  local ret_items = {}
  local all_items = self._all_warehouse_data
  for _, item in ipairs(all_items) do
    local cfg = item_module:get_cfg_by_id(item.ConFigID)
    if warehouse_module:check_item_type_show(cfg.bagtype, warehouse_item_type) then
      table.insert(ret_items, item)
    end
  end
  return ret_items
end

function warehouse_module:check_item_type_show(item_bag_type, warehouse_item_type)
  if warehouse_item_type == warehouse_module.warehouse_item_type.all then
    return true
  end
  local cfg_warehouse_type = warehouse_module.bag_type2warehous_item_type[item_bag_type]
  if warehouse_item_type == warehouse_module.warehouse_item_type.other then
    local is_show = true
    for _, type in ipairs(warehouse_module.warehouse_show_order) do
      if type ~= warehouse_module.warehouse_item_type.all and type ~= warehouse_module.warehouse_item_type.other and cfg_warehouse_type == type then
        is_show = false
        break
      end
    end
    return is_show
  else
    return cfg_warehouse_type == warehouse_item_type
  end
end

function warehouse_module:get_cur_warehouse_num()
  return self._cur_warehouse_num or 0
end

return warehouse_module
