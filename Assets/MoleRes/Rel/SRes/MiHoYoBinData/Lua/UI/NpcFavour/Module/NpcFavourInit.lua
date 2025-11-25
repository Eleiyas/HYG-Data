npc_favour_module = npc_favour_module or {}
npc_favour_module._cname = "npc_favour_module"
lua_module_mgr:require("UI/NpcFavour/Module/NpcFavourMain")
lua_module_mgr:require("UI/NpcFavour/Module/NpcFavourData")

function npc_favour_module:init()
  self._favour_level_cfgs = nil
  self._favour_all_exp = nil
  self._favor_max_lv = nil
  self._favour_level_lock_cfgs = nil
  self._favour_level_reward_des_cfgs = nil
  self._events = nil
  npc_favour_module:add_event()
end

function npc_favour_module:close()
  npc_favour_module:remove_event()
end

function npc_favour_module:clear_on_disconnect()
  self._favour_level_cfgs = nil
  self._favour_all_exp = nil
  self._favor_max_lv = nil
  self._favour_level_lock_cfgs = nil
  self._favour_level_reward_des_cfgs = nil
end

return npc_favour_module
