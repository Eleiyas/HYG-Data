item_module = item_module or {}

local function _decorate(option_value, option)
  lua_event_module:send_event(lua_event_module.event_type.bag_unselect_item)
  open_lua_ui_module:open_lua_ui(open_lua_ui_module.lua_ui_type.area_select_tool, {option_value})
  return false
end

local function _put_down(option_value, option)
  local dropSuccess, failResult
  if option_value.Count > 1 then
    local function callback(use_num)
      dropSuccess, failResult = CsPacketModuleUtil.DropItem(option_value, 101, use_num)
      
      if dropSuccess then
      else
        item_module:_show_drop_item_fail_tips(failResult, 101)
      end
    end
    
    item_module:open_bag_item_num_dialog(option.name, back_bag_module:get_item_num_by_guid(option_value.GUID), callback)
  else
    dropSuccess, failResult = CsPacketModuleUtil.DropItem(option_value, 101, 1)
    if dropSuccess then
    else
      item_module:_show_drop_item_fail_tips(failResult, 101)
    end
  end
end

local function _plant(option_value, option)
  local is_plant = 1
  if player_module:get_player_data() then
    is_plant = player_module:get_player_data():OnClickPlantItem(option_value.ConFigID)
  end
  if is_plant == 0 then
    EventCenter.Broadcast(EventID.UIPlantItem, option_value)
    return true
  elseif is_plant == 1 then
    return true
  else
    return false
  end
end

local function _show_off(option_value, option)
  CsGameplayUtilitiesExhibitionUtil.StartExHiBit(option_value.GUID)
  return true
end

local function _pick_up(option_value, option)
  player_module:player_take_on_equip(0, option_value.MakeGUID)
  return true
end

local function _bury(option_value, option)
  EventCenter.Broadcast(EventID.UIBuryItem, option_value)
  return true
end

local function _put_away(option_value, option)
  player_module:player_take_on_equip(0, 0)
  return true
end

local function _open(option_value, option)
  if item_module:is_photo(0, option_value.idCfg) then
    if item_module:is_npc_photo(0, option_value.idCfg) then
      local photo_cfg
      UIManagerInstance:open("UI/InGameLetter/PostcardDialog", photo_cfg)
    else
      local file_name = string.format("/Screenshot_%s_%s.png", player_module:get_player_uid(), option_value.MakeGUID)
      CsUIUtil.LoadDiskSprite(file_name, function(sprite)
        if sprite then
          item_module:open_photo_look_page(sprite)
        else
          UIUtil.show_tips_by_text_id("Item_PhotoIsRemove")
        end
      end)
    end
  elseif item_module:is_flyer(0, option_value.idCfg) then
    item_module:add_leaflet_data(option_value)
  elseif item_module:is_drift_box(0, option_value.idCfg) then
    UIManagerInstance:open("UI/InGameLetter/DriftPaperPage", option_value)
  else
    item_module:add_auto_eat_item(option_value)
    item_module:auto_use_recipe()
  end
end

local function _remember(option_value, option)
  if recipe_module:recipe_is_learn(option_value.ConFigID) then
    UIUtil.show_tips_by_text_id("Item_BookIsLearn")
  else
    item_module:add_auto_eat_item(option_value)
    item_module:auto_use_recipe()
  end
end

local function _put_on(option_value, option)
  local make_guid = option_value.MakeGUID
  item_module:set_clothe_equip_state(true, option_value.ConFigID, make_guid)
end

local function _npc_put_on(option_value, option)
  local make_guid = option_value.MakeGUID
  item_module:set_clothe_equip_state(true, option_value.ConFigID, make_guid, npc_module:get_cur_npc_cfg_id())
end

local function _take_off(option_value, option)
  item_module:set_clothe_equip_state(false, option_value.ConFigID, 0)
end

local function _decorate_walls_and_floors(option_value, option)
  CsRoomManagerUtil.FurnitureEditor:ChangeWallPaperForRealItem(option_value)
end

local function _use_blueprint(option_value, option)
  if item_module:is_task_item(0, option_value.idCfg) then
    item_module:add_auto_eat_item(option_value)
    item_module:auto_use_recipe()
    return true
  else
    lua_event_module:send_event(lua_event_module.event_type.hide_packet_page, nil)
    open_lua_ui_module:open_lua_ui(open_lua_ui_module.lua_ui_type.area_select_tool, {option_value})
  end
end

local function _store_in_warehouse(option_value, option)
  if back_bag_module:item_is_equip(option_value) then
    return false
  end
  if option_value.Count == 1 then
    local items_for_move = {
      [option_value.GUID] = 1
    }
    local items_for_check = {
      [option_value.ConFigID] = 1
    }
    warehouse_module:add_item_to_warehouse_req(warehouse_module.add_item_to_warehouse_type.home, items_for_move, items_for_check)
  else
    local function callback(use_num)
      local items_for_move = {
        [option_value.GUID] = use_num
      }
      local items_for_check = {
        [option_value.ConFigID] = use_num
      }
      warehouse_module:add_item_to_warehouse_req(warehouse_module.add_item_to_warehouse_type.home, items_for_move, items_for_check)
    end
    
    item_module:open_bag_item_num_dialog(option.name, option_value.Count, callback)
  end
end

local function _release_into_wild(option_value, option)
  back_bag_module:get_packet_data():SetReleaseIntoWildItem(option_value)
  CsPerformanceManagerUtil.ShowPerformance(3000080001)
end

local function _give_away(option_value, option)
  CsUIUtil.SendNpcGiftCheckReq(npc_module:get_cur_npc_id(), option_value.GUID)
end

local function _decorate_kitchenware(option_value, option)
  local dropSuccess, failResult = CsPacketModuleUtil.DropItem(option_value, 203, 1)
  if dropSuccess then
    return true
  else
    item_module:_show_drop_item_fail_tips(failResult, 203)
  end
  return false
end

local function _eat(option_value, option)
  local function continue_eating()
    local txt_map_id = "Eat_Normal"
    
    if option_value.ConFigID == 2040002 then
      txt_map_id = "Eat_Rot"
    elseif option_value.StarLevel >= 3 then
      txt_map_id = "Eat_FullStar"
    else
      local food_info = option_value.FoodExtension
      if not is_null(food_info) then
        local bit = food_info.FlavorBitMask
        local is_tasty_or_wrong = false
        if math.get_bit(bit, item_module.food_flavor_bit.normal) == 1 then
          txt_map_id = "Eat_Normal"
        elseif math.get_bit(bit, item_module.food_flavor_bit.sweet) == 1 then
          txt_map_id = "Eat_Sweet"
        elseif math.get_bit(bit, item_module.food_flavor_bit.salty) == 1 then
          txt_map_id = "Eat_Salty"
        elseif math.get_bit(bit, item_module.food_flavor_bit.spicy) == 1 then
          txt_map_id = "Eat_Spicy"
        elseif math.get_bit(bit, item_module.food_flavor_bit.tasteless) == 1 then
          txt_map_id = "Eat_Unseasoned"
          is_tasty_or_wrong = true
        elseif math.get_bit(bit, item_module.food_flavor_bit.wrong_taste) == 1 then
          txt_map_id = "Eat_Weird"
          is_tasty_or_wrong = true
        end
        if math.get_bit(bit, item_module.food_flavor_bit.burnt) == 1 then
          if is_tasty_or_wrong then
            txt_map_id = "Eat_OverCookedAndTastyWrong"
          else
            txt_map_id = "Eat_OverCooked"
          end
        end
      end
    end
    back_bag_module:get_packet_data():EatFood(option_value)
  end
  
  lua_event_module:send_event(lua_event_module.event_type.hide_packet_page, nil)
  cooking_module:check_strength_up_before_eat(option_value.MakeGUID, continue_eating)
  return false
end

local function _learn_recipe(option_value, option)
  local recipe_data = CsCookModuleUtil.GetCookRecipeDataById(option_value.ConFigID)
  if recipe_data ~= nil and recipe_data.Proficiency >= recipe_data.MaxProficiency then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("Cook_Tips_LearnedMax"))
    return false
  end
  back_bag_module:get_packet_data():UseItemReq(option_value.GUID, 1, level_module:get_cur_scene_id())
end

local function _hold_food_in_hand(option_value, option)
  player_module:player_take_on_equip(0, option_value.MakeGUID)
  return true
end

local function _decorate_with_food_here(option_value, option)
  lua_event_module:send_event(lua_event_module.event_type.hide_packet_page, nil)
  open_lua_ui_module:open_lua_ui(open_lua_ui_module.lua_ui_type.area_select_tool, {option_value})
  return true
end

local function _use_expansion_board(option_value, option)
  if GameSceneUtility.IsExpansionBoardLimitReached() then
    UIUtil.show_tips_by_text_id("ExtendableBoard_Exceeds_Scene_Limit")
    return false
  end
  lua_event_module:send_event(lua_event_module.event_type.hide_packet_page, nil)
  open_lua_ui_module:open_lua_ui(open_lua_ui_module.lua_ui_type.area_select_tool, {option_value})
  CsBuriedPointReportManagerUtil.ReportActionFromLuaTable(BuriedPointReportActionEnum.packet_use_expansion_board, "PacketUseExpansionBoard", {})
  return false
end

local function _emote(option_value, option)
  CommandUtil.AllocateLockAvatarCmd(1, true)
  CommandUtil.AllocateTryToggleItemCmd(1, true)
  CommandUtil.AllocateEntityAnimCmd(1, "Wave")
  CommandUtil.AllocateTryToggleItemCmd(1, false)
  return true
end

local function _sell(option_value, option)
  local items = {}
  for _, v in pairs(option_value) do
    items[v.server_data.GUID] = v.num
  end
  return back_bag_module:get_packet_data():PlaySellReq(items)
end

local function _task_submit(option_value, option)
  local lst_send_data = {}
  for _, v in pairs(option_value.items) do
    local guid = v.server_data.GUID
    if lst_send_data[guid] == nil and v.num > 0 then
      lst_send_data[guid] = 0
    end
    lst_send_data[guid] = lst_send_data[guid] + v.num
  end
  if option_value.is_delay_submit then
    back_bag_module:get_packet_data():SetDelayDeliveryItems(lst_send_data)
    lua_event_module:send_event(lua_event_module.event_type.item_option_delay_submit)
    return
  end
  lua_event_module:send_event(lua_event_module.event_type.item_option_submit_send, back_bag_module:handle_task_item_req(lst_send_data))
end

local function _donate(option_value, option)
  local item_list = {}
  for _, v in pairs(option_value) do
    table.insert(item_list, v.server_data)
  end
  CsGalleryModuleUtil.DonationPendingList = item_list
  return true
end

local function _replace_put_down(option_value, option)
  local dropSuccess, failResult = CsPacketModuleUtil.ReplaceAndDropTheItem(option_value, 101, option_value.Count)
  if dropSuccess then
    back_bag_module:set_replace_item_type(back_bag_module.replace_item_type.drop)
  else
    item_module:_show_drop_item_fail_tips(failResult, 101)
  end
end

local function _replace_release_into_wild(option_value, option)
  back_bag_module:get_packet_data():SetReleaseIntoWildItem(option_value)
  back_bag_module:set_replace_item_type(back_bag_module.replace_item_type.release)
  return true
end

local function _collection_submit(option_value, option)
  local lst_send_data = {}
  for _, v in pairs(option_value.items) do
    local guid = v.server_data.GUID
    if lst_send_data[guid] == nil and v.num > 0 then
      lst_send_data[guid] = 0
    end
    lst_send_data[guid] = lst_send_data[guid] + v.num
  end
  if option_value.is_delay_submit then
    back_bag_module:get_packet_data():SetDelayDeliveryItems(lst_send_data)
    lua_event_module:send_event(lua_event_module.event_type.item_option_delay_submit)
    return
  end
  lua_event_module:send_event(lua_event_module.event_type.item_option_submit_send, CsCollectionModuleUtil.TimeDiaryDonateReq(option_value.tracker_id, lst_send_data))
end

local function _common_submit(option_value, option)
  local lst_send_data = {}
  for _, v in pairs(option_value.items) do
    local guid = v.server_data.GUID
    if lst_send_data[guid] == nil and v.num > 0 then
      lst_send_data[guid] = 0
    end
    lst_send_data[guid] = lst_send_data[guid] + v.num
  end
  back_bag_module:get_packet_data():SetDelayDeliveryItems(lst_send_data)
  lua_event_module:send_event(lua_event_module.event_type.item_option_common_submit)
end

local function _equip_to_quick_slot(option_value, option)
  local item_makeguid = option_value.MakeGUID
  local empty_slot_index = CsQuickFarmingModuleUtil.GetFirstEmptySlotIndex()
  if 0 < empty_slot_index then
    CsQuickFarmingModuleUtil.SetSlotData(empty_slot_index, item_makeguid)
    return true
  else
    UIUtil.show_tips_by_text_id("QuickFarming_SlotFull_Tips")
  end
  return false
end

local function _unequip_from_quick_slot(option_value, option)
  local item_makeguid = option_value.MakeGUID
  local slot_index = CsQuickFarmingModuleUtil.GetSlotIndexForItem(item_makeguid)
  if 0 < slot_index then
    CsQuickFarmingModuleUtil.ClearSlotData(slot_index)
    return true
  end
  return false
end

local function _put_blueprint(option_value, option)
  lua_event_module:send_event(lua_event_module.event_type.hide_packet_page, nil)
  EventCenter.Broadcast(EventID.LuaOpenBlueprintAreaSelectPage, option_value)
  return false
end

local function open_favor_box(option_value, option)
  local all_npc_data = list_to_table(CsNpcGrowthModuleUtil.GetFavourGiftBoxNpcList())
  if all_npc_data and 0 < #all_npc_data then
    lua_event_module:send_event(lua_event_module.event_type.hide_packet_page, nil)
    local item_makeguid = option_value.MakeGUID
    local extra_data = {item_guid = item_makeguid, all_npc_data = all_npc_data}
    UIManagerInstance:open("UI/NpcFavour/FavorGiftPacket/FavorGiftPacketPage", extra_data)
  else
    UIUtil.show_tips_by_text_id("NpcFavourGiftBoxNoNpcTip")
  end
  return false
end

local function _put_into_creature_tank(option_value, option)
  CsCreatureTankModuleUtil.SceneCreatureTankInteractReq(option_value.MakeGUID)
  return false
end

local function _take_from_to_creature_tank(option_value, option)
  CsCreatureTankModuleUtil.SceneCreatureTankInteractReq(0)
  return false
end

local function blueprint_view_furniture(option_value, option)
  local blueprint_guid = option_value.BlueprintGuid
  UIManagerInstance:open("UI/Blueprint/BlueprintPackagePage", {blueprint_guid = blueprint_guid})
end

local function _view_organisms_in_creature_tank(option_value, option)
  local item = CsPacketModuleUtil.GetCreatureItemByCreatureTankGuid(option_value.GUID)
  item_module:open_item_info_dialog(item.ConFigID, item.Count, item)
  return false
end

item_module.item_option_function_type = {
  decorate = 1,
  put_down = 2,
  plant = 3,
  show_off = 4,
  pick_up = 5,
  bury = 6,
  put_away = 7,
  open = 8,
  remember = 9,
  put_on = 10,
  take_off = 11,
  decorate_walls_and_floors = 12,
  use_blueprint = 13,
  store_in_warehouse = 14,
  release_into_wild = 15,
  give_away = 16,
  decorate_kitchenware = 17,
  eat = 18,
  learn_recipe = 19,
  hold_food_in_hand = 20,
  decorate_with_food_here = 21,
  use_expansion_board = 22,
  emote = 23,
  sell = 24,
  task_submit = 25,
  donate = 26,
  replace_put_down = 27,
  replace_release_into_wild = 28,
  collection_submit = 29,
  equip_to_quick_slot = 30,
  unequip_from_quick_slot = 31,
  common_submit = 32,
  put_blueprint = 33,
  open_favor_box = 34,
  put_into_creature_tank = 35,
  take_from_to_creature_tank = 36,
  blueprint_view_furniture = 37,
  view_organisms_in_creature_tank = 38,
  npc_put_on = 39,
  bridge_or_slope_furniture = 40
}
local item_option_functions = {
  [item_module.item_option_function_type.decorate] = _decorate,
  [item_module.item_option_function_type.put_down] = _put_down,
  [item_module.item_option_function_type.plant] = _plant,
  [item_module.item_option_function_type.show_off] = _show_off,
  [item_module.item_option_function_type.pick_up] = _pick_up,
  [item_module.item_option_function_type.bury] = _bury,
  [item_module.item_option_function_type.put_away] = _put_away,
  [item_module.item_option_function_type.open] = _open,
  [item_module.item_option_function_type.remember] = _remember,
  [item_module.item_option_function_type.put_on] = _put_on,
  [item_module.item_option_function_type.take_off] = _take_off,
  [item_module.item_option_function_type.decorate_walls_and_floors] = _decorate_walls_and_floors,
  [item_module.item_option_function_type.use_blueprint] = _use_blueprint,
  [item_module.item_option_function_type.store_in_warehouse] = _store_in_warehouse,
  [item_module.item_option_function_type.release_into_wild] = _release_into_wild,
  [item_module.item_option_function_type.give_away] = _give_away,
  [item_module.item_option_function_type.decorate_kitchenware] = _decorate_kitchenware,
  [item_module.item_option_function_type.eat] = _eat,
  [item_module.item_option_function_type.learn_recipe] = _learn_recipe,
  [item_module.item_option_function_type.hold_food_in_hand] = _hold_food_in_hand,
  [item_module.item_option_function_type.decorate_with_food_here] = _decorate_with_food_here,
  [item_module.item_option_function_type.use_expansion_board] = _use_expansion_board,
  [item_module.item_option_function_type.emote] = _emote,
  [item_module.item_option_function_type.sell] = _sell,
  [item_module.item_option_function_type.task_submit] = _task_submit,
  [item_module.item_option_function_type.donate] = _donate,
  [item_module.item_option_function_type.replace_put_down] = _replace_put_down,
  [item_module.item_option_function_type.replace_release_into_wild] = _replace_release_into_wild,
  [item_module.item_option_function_type.collection_submit] = _collection_submit,
  [item_module.item_option_function_type.equip_to_quick_slot] = _equip_to_quick_slot,
  [item_module.item_option_function_type.unequip_from_quick_slot] = _unequip_from_quick_slot,
  [item_module.item_option_function_type.common_submit] = _common_submit,
  [item_module.item_option_function_type.put_blueprint] = _put_blueprint,
  [item_module.item_option_function_type.open_favor_box] = open_favor_box,
  [item_module.item_option_function_type.put_into_creature_tank] = _put_into_creature_tank,
  [item_module.item_option_function_type.take_from_to_creature_tank] = _take_from_to_creature_tank,
  [item_module.item_option_function_type.blueprint_view_furniture] = blueprint_view_furniture,
  [item_module.item_option_function_type.view_organisms_in_creature_tank] = _view_organisms_in_creature_tank,
  [item_module.item_option_function_type.npc_put_on] = _npc_put_on,
  [item_module.item_option_function_type.bridge_or_slope_furniture] = _use_blueprint
}

function item_module:use_item_new(option_value, option)
  if option_value == nil or option == nil then
    return false
  end
  local is_close_self = false
  local option_callback = item_option_functions[option.optionfunction]
  if option_callback then
    is_close_self = option_callback(option_value, option)
  end
  return is_close_self
end

function item_module:_show_drop_item_fail_tips(fail_result, drop_type)
  if drop_type == 203 then
    drop_type = 9
  end
  local fail_result_str = ""
  if fail_result == PlaceFailureReason.None then
    fail_result_str = "None"
  elseif fail_result == PlaceFailureReason.ProhibitedInCurrentLevel then
    fail_result_str = "ProhibitedInCurrentLevel"
  elseif fail_result == PlaceFailureReason.FailToFindAnyValidPlacementPoints then
    fail_result_str = "FailToFindAnyValidPlacementPoints"
  elseif fail_result == PlaceFailureReason.ProhibitedInTargetPlane then
    fail_result_str = "ProhibitedInTargetPlane"
  elseif fail_result == PlaceFailureReason.InvalidPlaneCell then
    fail_result_str = "InvalidPlaneCell"
  elseif fail_result == PlaceFailureReason.InvalidTerrainCell then
    fail_result_str = "InvalidTerrainCell"
  elseif fail_result == PlaceFailureReason.InvalidTerrainCellType then
    fail_result_str = "InvalidTerrainCellType"
  elseif fail_result == PlaceFailureReason.InvalidTerrainCellElevaion then
    fail_result_str = "InvalidTerrainCellElevaion"
  elseif fail_result == PlaceFailureReason.OverlapWithAvatar then
    fail_result_str = "OverlapWithAvatar"
  elseif fail_result == PlaceFailureReason.FailToParityCheck then
    fail_result_str = "FailToParityCheck"
  elseif fail_result == PlaceFailureReason.OverlapWithOtherGridEntity then
    fail_result_str = "OverlapWithOtherGridEntity"
  elseif fail_result == PlaceFailureReason.FailToZoneRule then
    fail_result_str = "FailToZoneRule"
  elseif fail_result == PlaceFailureReason.InnerReanson then
    fail_result_str = "InnerReanson"
  elseif fail_result == PlaceFailureReason.NotFoundInEntityCfg then
    fail_result_str = "NotFoundInEntityCfg"
  elseif fail_result == PlaceFailureReason.InvalidParameter then
    fail_result_str = "InvalidParameter"
  elseif fail_result == PlaceFailureReason.InvalidPlacementCfgId then
    fail_result_str = "InvalidPlacementCfgId"
  elseif fail_result == PlaceFailureReason.InvalidPlane then
    fail_result_str = "InvalidPlane"
  end
  if string.is_valid(fail_result_str) then
    local fail_str = UIUtil.get_text_by_id(string.format("DropError_%s_%s", fail_result_str, drop_type))
    if not string.is_valid(fail_str) then
      fail_str = fail_result_str
    end
    UIUtil.show_tips(fail_str)
  end
end

function item_module:set_clothe_equip_state(is_put_on, cfg_id, make_guid, npc_id)
  local guid
  if npc_id == nil or npc_id <= 0 then
    guid = player_module:get_player_guid()
  else
    guid = EntityUtil.get_npc_guid_by_config_id(npc_id)
  end
  if is_put_on then
    CsGameplayUtilitiesAvatarUtil.PutOnWearable(guid, cfg_id, make_guid, true, 0 < back_bag_module:get_item_num_by_guid(make_guid))
  else
    CsGameplayUtilitiesAvatarUtil.TakeOffWearable(guid, cfg_id, true)
  end
end

return item_module
