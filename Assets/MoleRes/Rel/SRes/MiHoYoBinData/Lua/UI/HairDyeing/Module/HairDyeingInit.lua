hair_dyeing_module = hair_dyeing_module or {}
hair_dyeing_module._cname = "hair_dyeing_module"
lua_module_mgr:require("UI/HairDyeing/Module/HairDyeingMain")
lua_module_mgr:require("UI/HairDyeing/Module/HairDyeingCommon")
lua_module_mgr:require("UI/HairDyeing/Module/HairDyeingCfg")

function hair_dyeing_module:init()
  self._events = nil
  hair_dyeing_module:add_event()
end

function hair_dyeing_module:close()
  hair_dyeing_module:remove_event()
end

function hair_dyeing_module:clear_on_disconnect()
  hair_dyeing_module:clear_dye_session()
end

return hair_dyeing_module
