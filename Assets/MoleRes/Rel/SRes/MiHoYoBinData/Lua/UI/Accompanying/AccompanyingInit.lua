accompanying_module = accompanying_module or {}
accompanying_module._cname = "accompanying_module"
lua_module_mgr:require("UI/Accompanying/AccompanyingMain")
lua_module_mgr:require("UI/Accompanying/AccompanyingUI")

function accompanying_module:init()
  accompanying_module:_init_data()
  accompanying_module:add_event()
end

function accompanying_module:close()
  accompanying_module:remove_event()
end

function accompanying_module:init_on_connect()
  accompanying_module:_init_data()
end

return accompanying_module
