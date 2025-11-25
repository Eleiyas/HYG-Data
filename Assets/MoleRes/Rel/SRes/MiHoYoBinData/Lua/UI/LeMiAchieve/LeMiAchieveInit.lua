le_mi_achievement_module = le_mi_achievement_module or {}
le_mi_achievement_module._cname = "le_mi_achievement_module"
lua_module_mgr:require("UI/LeMiAchieve/LeMiAchieveCommon")
lua_module_mgr:require("UI/LeMiAchieve/LeMiAchieveMain")
lua_module_mgr:require("UI/LeMiAchieve/LeMiAchieveData")
lua_module_mgr:require("UI/LeMiAchieve/LeMiAchieveCfg")
lua_module_mgr:require("UI/LeMiAchieve/LeMiAchieveNet")
lua_module_mgr:require("UI/LeMiAchieve/LeMiAchieveUI")

function le_mi_achievement_module:init()
  self:_init_cfg_data()
  self:_init_data()
  self._events = nil
  self._tbl_rep = nil
  le_mi_achievement_module:add_event()
  le_mi_achievement_module:register_cmd_handler()
end

function le_mi_achievement_module:close()
  le_mi_achievement_module:remove_event()
  le_mi_achievement_module:un_register_cmd_handler()
end

function le_mi_achievement_module:clear_on_disconnect()
  le_mi_achievement_module:_init_data()
end

return le_mi_achievement_module
