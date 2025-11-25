recipe_module = recipe_module or {}
recipe_module._cname = "recipe_module"
lua_module_mgr:require("UI/Recipe/RecipeCommon")
lua_module_mgr:require("UI/Recipe/RecipeData")
lua_module_mgr:require("UI/Recipe/RecipeCfg")
lua_module_mgr:require("UI/Recipe/RecipeUI")
lua_module_mgr:require("UI/Recipe/RecipeMain")

function recipe_module:init()
  recipe_module:reset_server_data()
  self._events = nil
  recipe_module:add_event()
end

function recipe_module:close()
  recipe_module:remove_event()
end

function recipe_module:reset_server_data()
  self._all_group_cfg = nil
  self._all_recipe_cfg = nil
  self._all_diy_ui_cfg = nil
  self._cur_recipe_id = nil
  self._cur_show_recipe_ids = nil
  self._item_recipe_id = nil
  self._all_recipe_group_id = nil
  self._all_recipe_data = nil
  self._all_has_recipe_group = nil
  self._all_task_recipe_cfg = nil
end

function recipe_module:clear_on_disconnect()
  recipe_module:reset_server_data()
end

return recipe_module
