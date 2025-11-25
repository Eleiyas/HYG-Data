back_bag_module = back_bag_module or {}

function back_bag_module:pick_temporary_item_req(guid)
  back_bag_module:get_packet_data():PickTemporaryItemReq(guid)
end

function back_bag_module:handle_task_item_req(send_data)
  return back_bag_module:get_packet_data():HandleTaskItemReq(send_data)
end

function back_bag_module:sort_bag_req()
end

return back_bag_module
