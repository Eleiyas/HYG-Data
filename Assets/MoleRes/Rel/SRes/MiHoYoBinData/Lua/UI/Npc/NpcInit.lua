npc_module = npc_module or {}
npc_module._cname = "npc_module"
lua_module_mgr:require("UI/Npc/NpcCommon")
lua_module_mgr:require("UI/Npc/NpcGift")
lua_module_mgr:require("UI/Npc/NpcUI")
lua_module_mgr:require("UI/Npc/NpcCfg")
lua_module_mgr:require("UI/Npc/NpcData")
lua_module_mgr:require("UI/Npc/NpcNet")
lua_module_mgr:require("UI/Npc/NpcMain")

function npc_module:init()
  npc_module:add_event()
  npc_module:init_data()
  npc_module:register_cmd_handler()
end

function npc_module:close()
  npc_module:remove_event()
  npc_module:un_register_cmd_handler()
end

function npc_module:clear_on_disconnect()
  npc_module:init_data()
end

return npc_module or {}
