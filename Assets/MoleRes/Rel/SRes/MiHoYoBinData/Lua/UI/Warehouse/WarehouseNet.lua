warehouse_module = warehouse_module or {}

function warehouse_module:add_item_to_warehouse_req(add_type, items_for_move, items_for_check, replace_item_guid)
  if not CsWarehouseModuleUtil.WarehouseIsCanAddItem(items_for_check) then
    UIUtil.show_tips_by_text_id("Stock_StockNoSpace")
    return
  end
  CsWarehouseModuleUtil.AddItemToWarehouseReq(add_type, items_for_move, replace_item_guid or 0)
end

function warehouse_module:get_item_from_warehouse_req(items_for_move, items_for_check)
  if not back_bag_module:get_packet_data():BagIsCanAddItem(items_for_check, nil) then
    UIUtil.show_tips_by_text_id("Stock_BagNoSpace")
    return
  end
  CsWarehouseModuleUtil.GetItemFormWarehouseReq(items_for_move)
end

return warehouse_module
