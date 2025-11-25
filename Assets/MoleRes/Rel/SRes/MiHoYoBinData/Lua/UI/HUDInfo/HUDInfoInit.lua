hud_info_module = hud_info_module or {}
hud_info_module._cname = "hud_info_module"
lua_module_mgr:require("UI/HUDInfo/HUDInfoUI")
lua_module_mgr:require("UI/HUDInfo/HUDInfoCommon")

function hud_info_module:init()
end

function hud_info_module:close()
end

return hud_info_module
