local M = G.Class("HUDBlueprintHabitatExpUpTip", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local default_show_time = 3.0

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/BlueprintHabitatExpUpTips"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self:start_close_timer(default_show_time)
  self._level_up_to = self._extra_data and self._extra_data.level_up_to or 0
  self:_refresh()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaOpenBlackScreenView, function()
    self._level_up_to = 0
    self:close_self()
  end)
  self:add_evt_listener(EventID.LuaShowBlank, function()
    self._level_up_to = 0
    self:close_self()
  end)
end

function M:on_disable()
  base.on_disable(self)
  if self._level_up_to and self._level_up_to > 0 then
    local level = self._level_up_to
    self._level_up_to = 0
    blueprint_habitat_module:show_architect_level_up_dialog(level)
  end
end

function M:_refresh()
  local current_level, next_diff, next_need = blueprint_habitat_module:get_architect_level()
  UIUtil.set_text_by_id(self._txt_lv, "Habitat_CurrentLevel", current_level)
  if 0 < next_need then
    self._slider.value = 1 - next_diff / next_need
  else
    self._slider.value = 1
  end
end

return M
