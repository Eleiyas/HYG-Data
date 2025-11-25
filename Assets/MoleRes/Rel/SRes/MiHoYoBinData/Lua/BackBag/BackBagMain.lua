back_bag_module = back_bag_module or {}

function back_bag_module:add_event()
  back_bag_module:remove_event()
  self._events = {}
  self._events[EventID.TemporaryBagItemsChange] = pack(self, self._on_temporary_bag_items_change)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function back_bag_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function back_bag_module:item_is_equip(item_data)
  if item_data == nil then
    return false
  end
  if item_module:item_bag_type_is_clothes(item_data.ConFigID) then
    return back_bag_module:clothe_is_equip(item_data)
  elseif item_module:is_handheld_tool(item_data.ConFigID) then
    return player_module:get_player_data().curHandToolGuid == item_data.MakeGUID
  end
  return false
end

function back_bag_module:clothe_is_equip(item_data)
  if is_null(item_data) then
    return false
  end
  return CsPacketModuleUtil.ItemIsEquipped(item_data)
end

function back_bag_module:clothe_is_equip_by_make_guid(make_guid)
  if make_guid <= 0 then
    return false
  end
  return CsPacketModuleUtil.ItemIsEquippedByMakeGuid(make_guid)
end

function back_bag_module:check_tutorial_dynamic_key_by_guid(guid)
  return CsPacketModuleUtil.CheckTutorialDynamicKeyByGuid(guid)
end

function back_bag_module:check_tutorial_dynamic_key_by_tags(guid)
  return CsPacketModuleUtil.CheckTutorialDynamicKeyByTags(guid)
end

function back_bag_module:_on_temporary_bag_items_change()
  self._temporary_bag_item = array_to_table(back_bag_module:get_packet_data():GeTemporaryBagItems() or {})[1]
  if self._temporary_bag_item ~= nil then
    function self._check_temporary_bag_fun()
      if self._temporary_bag_item == nil then
        return
      end
      CsPerformanceManagerUtil.ShowPerformance(3000030001)
    end
  end
end

function back_bag_module:check_temporary_bag_fun()
  if self._check_temporary_bag_fun ~= nil then
    self._check_temporary_bag_fun()
    self._check_temporary_bag_fun = nil
    return true
  end
  return false
end

return back_bag_module
