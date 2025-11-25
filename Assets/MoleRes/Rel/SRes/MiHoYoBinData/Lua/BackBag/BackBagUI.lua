local BackBagCommon = require("BackBag.BackBagCommon")
back_bag_module = back_bag_module or {}

function back_bag_module:open_clothe_bag_dialog(npc_id)
  UIManagerInstance:open("UI/PacketView/ClotheBagDialog", npc_id)
end

function back_bag_module:show_sell_item_confirm_dialog(title_txt, coin_type, all_price, items, left_txt, left_callback, right_txt, right_callback, is_show_close_btn, close_callback)
  local data = {
    title_txt = title_txt,
    coin_type = coin_type,
    all_price = all_price,
    items = items or {},
    left_txt = left_txt,
    left_callback = left_callback,
    right_txt = right_txt,
    right_callback = right_callback,
    is_show_close_btn = is_show_close_btn or true,
    close_callback = close_callback
  }
  UIManagerInstance:open("UI/ConfirmView/SellItemConfirmDialog", data)
end

function back_bag_module:open_packet_page(parameters)
  if is_null(parameters) or #parameters <= 0 then
    return
  end
  local open_bag_function = back_bag_module._open_bag_page_functions[parameters[1]]
  if open_bag_function then
    local extra_data = {
      show_mode = parameters[1],
      bag_main_type = parameters[2]
    }
    open_bag_function(extra_data, parameters)
  end
end

local function _open_new_packet_page(extra_data)
  CsBuriedPointReportManagerUtil.ReportActionFromLuaTable(BuriedPointReportActionEnum.player_open_normal_packet, "PlayerOpenNormalPacket", {})
  GameplayUtility.Camera.ChangeCameraState("UIBackpack", true)
  UIManagerInstance:open("UI/PacketView/NewPacketPage", extra_data)
end

local function _open_task_submit_packet_page(extra_data, parameters)
  if parameters then
    back_bag_module:set_delivery_task_step_id(parameters[3])
    extra_data.is_delay_delivery = parameters[4] ~= nil and parameters[4] == 1
  end
  back_bag_module:_open_submit_packet_page(extra_data)
end

local function _open_collection_submit_packet_page(extra_data, parameters)
  if parameters then
    extra_data.tracker_id = parameters[3]
  end
  back_bag_module:_open_submit_packet_page(extra_data)
end

local function _open_common_submit_packet_page(extra_data, parameters)
  if parameters then
    extra_data.conditions = parameters[3]
    extra_data.is_all_conditions_met_for_submit = parameters[6] or false
  end
  back_bag_module:_open_submit_packet_page(extra_data)
end

function back_bag_module:_open_submit_packet_page(extra_data)
  UIManagerInstance:open("UI/PacketView/SubmitPacketPage", extra_data)
end

local function _open_gift_packet_page(extra_data, parameters)
  if parameters then
    npc_module:set_cur_npc_cfg_id(parameters[3])
  end
  UIManagerInstance:open("UI/PacketView/GiftPacketPage", extra_data)
end

local function _open_sell_packet_page(extra_data, parameters)
  if parameters then
    extra_data.tab = parameters[3]
  end
  UIManagerInstance:open("UI/PacketView/SellPacketPage", extra_data)
end

local function _open_donate_packet_page(extra_data, parameters)
  if parameters then
    if donateDialog == nil then
      require("UI/Donate/DonateDialog")
    end
    extra_data.single_choice_donate = parameters[3] == 0 and true or false
    extra_data.show_identify_page = parameters[4] == 1 and true or false
    extra_data.donate_type_list = parameters[5]
    extra_data.task_id = parameters[6]
  end
  UIManagerInstance:open("UI/PacketView/DonatePacketPage", extra_data)
end

local function _open_cook_packet_page(extra_data, parameters)
  if parameters then
    local cook_ware_cfg_id = EntityUtil.get_entity_cfg_id(parameters[3])
    cooking_module:set_cur_selected_cook_ware_guid(parameters[3])
    cooking_module:set_cur_selected_cook_ware_cfg_id(CsGameplayUtilitiesCookUtil.GetCookwareConfigId(parameters[3]))
  end
  extra_data.bag_main_type = back_bag_module.bag_main_type.none
  UIManagerInstance:open("UI/PacketView/CookPacketPage", extra_data)
end

local function _open_replace_packet_page(extra_data, parameters)
  UIManagerInstance:open("UI/PacketView/ReplacePacketPage", extra_data)
end

local function _open_depot_packet_page(extra_data, parameters)
  UIManagerInstance:open("UI/PacketView/DepotPacketPage", extra_data)
end

local function _open_farming_packet_page(extra_data, parameters)
  UIManagerInstance:open("UI/PacketView/FarmingPacketPage", extra_data)
end

local function _open_gelian_market_packet_page(extra_data, parameters)
  UIManagerInstance:open("UI/GeLianMarket/New/GeLianFoodMarketMainPage", extra_data)
end

local function _open_creature_tank_packet_page(extra_data, parameters)
  if parameters then
    extra_data.tab = parameters[2]
    CsPacketModuleUtil.SetCreatureTankGuid(parameters[3])
  end
  CsCameraUtil.SetCameraFocusEntity("CreatureTankCloseUp", parameters[3])
  UIManagerInstance:open("UI/PacketView/CreatureTankPacketPage", extra_data)
end

local function _open_npc_cloth_packet_page(extra_data, parameters)
  if parameters then
    extra_data.tab = parameters[2]
    extra_data.tog_show_type = parameters[3]
    npc_module:set_cur_npc_cfg_id(parameters[4])
  end
  GameplayUtility.Camera.SetAvatarCloseUp(EntityUtil.get_entity(EntityUtil.get_npc_guid_by_config_id(parameters[4])), "NpcClothPacket")
  UIManagerInstance:open("UI/PacketView/Npc/NpcClothPacketPage", extra_data)
end

back_bag_module._open_bag_page_functions = {
  [back_bag_module.bag_show_type.bag] = _open_new_packet_page,
  [back_bag_module.bag_show_type.sell] = _open_sell_packet_page,
  [back_bag_module.bag_show_type.gift] = _open_gift_packet_page,
  [back_bag_module.bag_show_type.donate] = _open_donate_packet_page,
  [back_bag_module.bag_show_type.delivery] = _open_task_submit_packet_page,
  [back_bag_module.bag_show_type.cooking] = _open_cook_packet_page,
  [back_bag_module.bag_show_type.replace_bag] = _open_replace_packet_page,
  [back_bag_module.bag_show_type.depot_bag] = _open_depot_packet_page,
  [back_bag_module.bag_show_type.collection_submit] = _open_collection_submit_packet_page,
  [back_bag_module.bag_show_type.common_submit] = _open_common_submit_packet_page,
  [back_bag_module.bag_show_type.gelian_market] = _open_gelian_market_packet_page,
  [back_bag_module.bag_show_type.farming] = _open_farming_packet_page,
  [back_bag_module.bag_show_type.creature_tank] = _open_creature_tank_packet_page,
  [back_bag_module.bag_show_type.npc_cloth] = _open_npc_cloth_packet_page
}
return back_bag_module
