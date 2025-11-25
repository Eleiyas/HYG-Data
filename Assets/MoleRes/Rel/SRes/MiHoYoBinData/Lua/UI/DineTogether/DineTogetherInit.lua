dine_together_module = dine_together_module or {}
dine_together_module._cname = "dine_together_module"
lua_module_mgr:require("UI/DineTogether/DineTogetherCommon")
lua_module_mgr:require("UI/DineTogether/DineTogetherCfg")
lua_module_mgr:require("UI/DineTogether/DineTogetherUI")
lua_module_mgr:require("UI/DineTogether/DineTogetherData")
lua_module_mgr:require("UI/DineTogether/DineTogetherMain")

function dine_together_module:init()
  dine_together_module:_init_data()
end

function dine_together_module:close()
end

function dine_together_module:clear_on_disconnect()
  dine_together_module:_init_data()
end

return dine_together_module
