cooking_module = cooking_module or {}
cooking_module._cname = "cooking_module"
lua_module_mgr:require("UI/Cooking/CookingCommon")
lua_module_mgr:require("UI/Cooking/CookingUI")
lua_module_mgr:require("UI/Cooking/CookingData")
lua_module_mgr:require("UI/Cooking/CookingMain")

function cooking_module:init()
  cooking_module:_init_data()
  cooking_module:add_event()
end

function cooking_module:close()
  cooking_module:remove_event()
end

function cooking_module:clear_on_disconnect()
  cooking_module:_init_data()
end

return cooking_module
