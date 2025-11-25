open_lua_ui_module = open_lua_ui_module or {}
open_lua_ui_module._cname = "open_lua_ui_module"

function open_lua_ui_module:init()
  self._events = nil
  open_lua_ui_module:_add_event()
end

function open_lua_ui_module:close()
  open_lua_ui_module:_remove_event()
end

function open_lua_ui_module:clear_on_disconnect()
  open_lua_ui_module:init()
end

function open_lua_ui_module:_add_event()
  self:_remove_event()
  self._events = {}
  self._events[EventID.OpenLuaUI] = pack(self, open_lua_ui_module._handle_open_lua_ui)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function open_lua_ui_module:_remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

local function _packet(parameters)
  if not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateBag) then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("CommonTips_FunctionNotEnabled"))
    return
  end
  back_bag_module:open_packet_page(parameters)
end

local function _tool_table(parameters)
  if galactic_bazaar_module:get_match_state_to_open_tool() then
    UIUtil.show_tips_by_text_id("RhythmShow_Tips1")
    return
  end
  recipe_module:set_is_tool_table_state(true)
  UIManagerInstance:open("UI/Recipe/DIYHandbookPage")
end

local function _homeward(parameters)
  if CsTravelModuleUtil.CurStarData and CsTravelModuleUtil.CurStarData.StarId == 1 then
    UIManagerInstance:open("UI/Travel/HomewardPage", {
      item_list = parameters[1],
      time = parameters[2],
      extra_item_list = parameters[3],
      crystal_num = parameters[4],
      coin_num = parameters[5]
    })
  end
end

local function _house_upgrade(parameters)
  UIManagerInstance:open("UI/HouseUpgrade/HouseUpgradePage")
end

local function _in_game_letter(parameters)
  UIManagerInstance:open("UI/InGameLetter/InGameLetterDialog")
end

local function _le_mi_achieve(parameters)
  le_mi_achievement_module:open_le_mi_achieve_page()
end

local function _diy_handbook(parameters)
  recipe_module:set_is_tool_table_state(false)
  recipe_module:open_diy_handbook_page()
end

local function _register(parameters)
  UIManagerInstance:open("UI/RegisterPage/RegisterPage")
end

local function _phone(parameters)
  UINavigatorIns.enter_phone_page()
end

local function _road_sign(parameters)
  UIManagerInstance:open("UI/RoadSignPage/RoadSignPage", parameters[1])
end

local function _loan_sign(parameters)
  UIManagerInstance:open("UI/LoanSignPage/LoanSignPage", parameters[1])
end

local function _dine_together(parameters)
  dine_together_module:open_dine_together_npc_select_page()
end

local function _entity_shop(parameters)
  shop_module:open_entity_shop_page()
end

local function _tv_shopping(parameters)
  UIManagerInstance:open("UI/TVShopping/TVShoppingHomePage")
end

local function _task_award_tips(parameters)
  task_module:show_task_get_item_tips(parameters[1])
end

local function _planet_tree(parameters)
  UIManagerInstance:open("UI/PlanetTree/PlanetTreePage")
end

local function _simple_camera(parameters)
  UIManagerInstance:open("UI/Photography/SimplePhotographyPage")
end

local function _series_task_tips(parameters)
  UIManagerInstance:open("UI/Tips/SeriesTaskTips", {
    task_id = parameters[1],
    is_start = parameters[2]
  })
end

local function _area_select_tool(parameters)
  if parameters then
    UIManagerInstance:open("UI/FurnitureEditView/BuildingAreaSelectPage", {
      item = parameters[1]
    })
  else
    UIManagerInstance:open("UI/FurnitureEditView/BuildingAreaSelectPage")
  end
end

local function _attrib_unlock_tips(parameters)
  appearance_module:open_attrib_unlock_tips(parameters[1])
end

local function _player_visit(parameters)
  if parameters then
    UIManagerInstance:open("UI/PlayerVisit/PlayerVisitPage", parameters[1])
  else
    UIManagerInstance:open("UI/PlayerVisit/PlayerVisitPage")
  end
end

local function _galactic_bazaar_bulletin(parameters)
  UIManagerInstance:open("UI/GalacticBazaar/GalacticBazaarBulletinPage")
end

local function _galactic_bazaar_dance_shop(parameters)
  UIManagerInstance:open("UI/GalacticBazaar/GalacticBazaarRewardShopPage")
end

local function _talking_board(parameters)
  UIManagerInstance:open("UI/StarMarket/TalkingBoardPage")
end

local function _planet_choose(parameters)
  UIManagerInstance:open("UI/PlanetChoose/PlanetChoosePage")
end

local function _npc_weeding_box(parameters)
  if parameters then
    UIManagerInstance:open("UI/Npc/NpcWeedingConfirmDialog", parameters[1])
  else
    UIManagerInstance:open("UI/Npc/NpcWeedingConfirmDialog")
  end
end

local function _star_map_detail(parameters)
  if parameters and 1 <= #parameters then
    companion_star_module:open_detail_by_npc_id(parameters[1])
  else
    companion_star_module:open_detail()
  end
end

local function _mi_you_zhu(parameters)
  npc_house_order_module:beiwanglu_open_miyouzhu_page()
end

local function _message_board(parameters)
  UIManagerInstance:open("UI/MessageBoard/MessageBoardPage")
end

local function _host_message(parameters)
  UIManagerInstance:open("UI/MessageBoard/MessageBoardHostContentPage")
end

local function _diy_recipe_info(parameters)
  recipe_module:beiwanglu_open_diy_recipe_info_page(parameters[1])
end

open_lua_ui_module.lua_ui_type = {
  none = 0,
  packet = 1,
  tool_table = 2,
  homeward = 5,
  house_upgrade = 6,
  in_game_letter = 7,
  le_mi_achieve = 8,
  diy_handbook = 9,
  register = 10,
  phone = 11,
  road_sign = 12,
  loan_sign = 13,
  dine_together = 15,
  entity_shop = 16,
  tv_shopping = 17,
  task_award_tips = 18,
  planet_tree = 19,
  simple_camera = 20,
  series_task_tips = 21,
  area_select_tool = 22,
  attrib_unlock_tips = 23,
  player_visit = 24,
  galactic_bazaar_bulletin = 25,
  npc_weeding_box = 26,
  galactic_bazaar_dance_shop = 27,
  talking_board = 28,
  planet_choose = 29,
  star_map_detail = 30,
  mi_you_zhu = 31,
  message_board = 32,
  host_message = 33,
  diy_recipe_info = 34
}
local ui_type_functions = {
  [open_lua_ui_module.lua_ui_type.packet] = _packet,
  [open_lua_ui_module.lua_ui_type.tool_table] = _tool_table,
  [open_lua_ui_module.lua_ui_type.homeward] = _homeward,
  [open_lua_ui_module.lua_ui_type.house_upgrade] = _house_upgrade,
  [open_lua_ui_module.lua_ui_type.in_game_letter] = _in_game_letter,
  [open_lua_ui_module.lua_ui_type.le_mi_achieve] = _le_mi_achieve,
  [open_lua_ui_module.lua_ui_type.diy_handbook] = _diy_handbook,
  [open_lua_ui_module.lua_ui_type.register] = _register,
  [open_lua_ui_module.lua_ui_type.phone] = _phone,
  [open_lua_ui_module.lua_ui_type.road_sign] = _road_sign,
  [open_lua_ui_module.lua_ui_type.loan_sign] = _loan_sign,
  [open_lua_ui_module.lua_ui_type.dine_together] = _dine_together,
  [open_lua_ui_module.lua_ui_type.entity_shop] = _entity_shop,
  [open_lua_ui_module.lua_ui_type.tv_shopping] = _tv_shopping,
  [open_lua_ui_module.lua_ui_type.task_award_tips] = _task_award_tips,
  [open_lua_ui_module.lua_ui_type.planet_tree] = _planet_tree,
  [open_lua_ui_module.lua_ui_type.simple_camera] = _simple_camera,
  [open_lua_ui_module.lua_ui_type.series_task_tips] = _series_task_tips,
  [open_lua_ui_module.lua_ui_type.area_select_tool] = _area_select_tool,
  [open_lua_ui_module.lua_ui_type.attrib_unlock_tips] = _attrib_unlock_tips,
  [open_lua_ui_module.lua_ui_type.player_visit] = _player_visit,
  [open_lua_ui_module.lua_ui_type.galactic_bazaar_bulletin] = _galactic_bazaar_bulletin,
  [open_lua_ui_module.lua_ui_type.npc_weeding_box] = _npc_weeding_box,
  [open_lua_ui_module.lua_ui_type.galactic_bazaar_dance_shop] = _galactic_bazaar_dance_shop,
  [open_lua_ui_module.lua_ui_type.talking_board] = _talking_board,
  [open_lua_ui_module.lua_ui_type.planet_choose] = _planet_choose,
  [open_lua_ui_module.lua_ui_type.star_map_detail] = _star_map_detail,
  [open_lua_ui_module.lua_ui_type.mi_you_zhu] = _mi_you_zhu,
  [open_lua_ui_module.lua_ui_type.message_board] = _message_board,
  [open_lua_ui_module.lua_ui_type.host_message] = _host_message,
  [open_lua_ui_module.lua_ui_type.diy_recipe_info] = _diy_recipe_info
}

function open_lua_ui_module:_handle_open_lua_ui(ui_data)
  if is_null(ui_data) then
    return
  end
  local option_callback = ui_type_functions[ui_data.uiType]
  if option_callback then
    option_callback(array_to_table(ui_data.parameters))
  end
end

function open_lua_ui_module:open_lua_ui(ui_type, parameters)
  local option_callback = ui_type_functions[ui_type]
  if option_callback then
    option_callback(array_to_table(parameters or {}))
  end
end

return open_lua_ui_module
