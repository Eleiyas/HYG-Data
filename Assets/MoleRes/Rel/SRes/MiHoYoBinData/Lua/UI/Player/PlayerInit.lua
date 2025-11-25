player_module = player_module or {}
player_module._cname = "player_module"
lua_module_mgr:require("UI/Player/PlayerCommon")
lua_module_mgr:require("UI/Player/PlayerUI")
lua_module_mgr:require("UI/Player/PlayerData")
lua_module_mgr:require("UI/Player/PlayerMain")
lua_module_mgr:require("UI/Player/PlayerNet")

function player_module:init()
  player_module:reset_server_data()
  player_module:refresh_data()
  player_module:add_event()
  player_module:register_cmd_handler()
end

function player_module:refresh_data()
  self._player_avatar = nil
  self._player_input = nil
  self._learn_item_cfg_id = 0
  self._learn_tips_action = nil
end

function player_module:close()
  player_module:remove_event()
  player_module:un_register_cmd_handler()
end

function player_module:reset_server_data()
  self._player_data = nil
  self._tbl_have_tools = nil
  self._tbl_all_tools = nil
  self._cur_equip_tool_index = -1
  self._is_can_equip_tool = false
  self._interaction_mask_is_open = false
  self._is_right_away_hide_tool_list = false
  self._cut_tool_guid = nil
  self._ability_availability_state = true
  self._is_need_show_strength_ui = false
end

function player_module:clear_on_disconnect()
  player_module:reset_server_data()
end

return player_module or {}
