item_module = item_module or {}
item_module._cname = "item_module"
lua_module_mgr:require("UI/Item/ItemCommon")
lua_module_mgr:require("UI/Item/ItemCfg")
lua_module_mgr:require("UI/Item/ItemMain")
lua_module_mgr:require("UI/Item/ItemOption")
lua_module_mgr:require("UI/Item/ItemNet")
lua_module_mgr:require("UI/Item/ItemUI")

function item_module:init()
  item_module:reset_server_data()
  item_module:init_cfg()
  item_module:add_event()
  item_module:register_cmd_handler()
end

function item_module:close()
  item_module:remove_event()
  item_module:un_register_cmd_handler()
  item_module:remove_all_handle()
end

function item_module:reset_server_data()
  self._fur_classify_names = nil
  self._auto_eat_item = nil
  self._recipe_configId = 0
  self._is_back_tool = false
  self._tbl_leaflet_data = nil
  self._tbl_item_handle = nil
  self._cur_learn_recipe_id = nil
  self._cur_make_item_id = nil
  self._item_num_data = nil
  self._diy_anim_action_fun = nil
  self._first_gain_biota_fun = nil
  self._item_tips_show_num = 0
end

function item_module:clear_on_disconnect()
  item_module:reset_server_data()
end

return item_module or {}
