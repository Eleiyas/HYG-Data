theme_season_module = theme_season_module or {}
theme_season_module._cname = "theme_season_module"
lua_module_mgr:require("UI/ThemeSeason/ThemeSeasonCommon")
lua_module_mgr:require("UI/ThemeSeason/ThemeSeasonData")
lua_module_mgr:require("UI/ThemeSeason/ThemeSeasonCfg")
lua_module_mgr:require("UI/ThemeSeason/ThemeSeasonMain")
lua_module_mgr:require("UI/ThemeSeason/ThemeSeasonUI")

function theme_season_module:init()
  theme_season_module:_init_data()
  theme_season_module:add_event()
end

function theme_season_module:close()
  theme_season_module:remove_event()
end

function theme_season_module:clear_on_disconnect()
  theme_season_module:_init_data()
end

return theme_season_module
