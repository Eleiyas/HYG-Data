blueprint_habitat_module = blueprint_habitat_module or {}
blueprint_habitat_module._cname = "blueprint_habitat_module"
lua_module_mgr:require("UI/BlueprintHabitat/Module/BlueprintHabitatMain")
lua_module_mgr:require("UI/BlueprintHabitat/Module/BlueprintHabitatData")
lua_module_mgr:require("UI/BlueprintHabitat/Module/BlueprintHabitatCommon")
lua_module_mgr:require("UI/BlueprintHabitat/Module/NewBlueprint/NewBlueprintInit")

function blueprint_habitat_module:init()
  self._events = nil
  blueprint_habitat_module:add_event()
  new_blueprint_module:init()
end

function blueprint_habitat_module:close()
  blueprint_habitat_module:remove_event()
  new_blueprint_module:close()
  un_require(lua_module_mgr:get_module_path_by_cname("new_blueprint_module"), "new_blueprint_module")
end

function blueprint_habitat_module:clear_on_disconnect()
  new_blueprint_module:clear_on_disconnect()
end

return blueprint_habitat_module
