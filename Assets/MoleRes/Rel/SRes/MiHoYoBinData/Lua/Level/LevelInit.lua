level_module = level_module or {}
level_module._cname = "level_module"
lua_module_mgr:require("Level/LevelCfg")
lua_module_mgr:require("Level/LevelData")
lua_module_mgr:require("Level/LevelMain")

function level_module:init()
  self._world_cfg_tbl = nil
  level_module:add_event()
end

function level_module:close()
  level_module:remove_event()
end

return level_module or {}
