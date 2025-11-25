planet_tree_module = planet_tree_module or {}
planet_tree_module._cname = "planet_tree_module"
lua_module_mgr:require("UI/PlanetTree/Module/PlanetTreeCfg")
lua_module_mgr:require("UI/PlanetTree/Module/PlanetTreeMain")
lua_module_mgr:require("UI/PlanetTree/Module/PlanetTreeCommon")

function planet_tree_module:init()
  self._events = nil
  planet_tree_module:add_event()
end

function planet_tree_module:close()
  planet_tree_module:remove_event()
end

function planet_tree_module:clear_on_disconnect()
end

return planet_tree_module
