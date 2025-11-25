appearance_module = appearance_module or {}
appearance_module._cname = "appearance_module"
lua_module_mgr:require("UI/Appearance/AppearanceCommon")
lua_module_mgr:require("UI/Appearance/AppearanceCfg")
lua_module_mgr:require("UI/Appearance/AppearanceMain")
lua_module_mgr:require("UI/Appearance/AppearanceUI")
lua_module_mgr:require("UI/Appearance/AppearanceData")

function appearance_module:init()
  appearance_module:_init_data()
  appearance_module:_init_cfg()
end

function appearance_module:close()
end

function appearance_module:clear_on_disconnect()
end

return appearance_module
