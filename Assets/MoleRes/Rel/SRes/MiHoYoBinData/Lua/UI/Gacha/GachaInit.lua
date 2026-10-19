gacha_module = gacha_module or {}
gacha_module._cname = "gacha_module"
lua_module_mgr:require("UI/Gacha/GachaCommon")
lua_module_mgr:require("UI/Gacha/GachaCfg")
lua_module_mgr:require("UI/Gacha/GachaData")
lua_module_mgr:require("UI/Gacha/GachaUI")
lua_module_mgr:require("UI/Gacha/GachaMain")

function gacha_module:init()
  gacha_module:_init_data()
  gacha_module:add_event()
end

function gacha_module:close()
  gacha_module:remove_event()
end

function gacha_module:init_on_connect()
  gacha_module:_init_data()
end

function gacha_module:clear_on_disconnect()
  gacha_module:_init_data()
end

function gacha_module:on_level_destroy()
  gacha_module:_init_data()
end

return gacha_module
