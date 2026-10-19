new_blueprint_module = new_blueprint_module or {}
new_blueprint_module._cname = "new_blueprint_module"
lua_module_mgr:require("UI/BlueprintHabitat/Module/NewBlueprint/NewBlueprintData")
lua_module_mgr:require("UI/BlueprintHabitat/Module/NewBlueprint/NewBlueprintCfg")
lua_module_mgr:require("UI/BlueprintHabitat/Module/NewBlueprint/NewBlueprintMain")
lua_module_mgr:require("UI/BlueprintHabitat/Module/NewBlueprint/NewBlueprintCommon")
return new_blueprint_module
