local M = G.Class("StarExploreLevelTipPanel", G.UIWindow)
local base = G.UIWindow
local auto_close_delay_seconds = 2

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MaterialStarExplore/StarExploreLevelTip"
  self.config.type = EUIType.Info
end

function M:on_open()
  base.on_open(self)
  self._remaining_time = auto_close_delay_seconds
end

function M:on_enable()
  base.on_enable(self)
  star_explore_module.is_island_quality_tip_showing = true
  local info = self:get_extra_data()
  if not string.is_valid(info) then
    self:close_self()
    return
  end
  UIUtil.set_text(self._txt_info_dynamic, info)
end

function M:on_disable()
  base.on_disable(self)
  star_explore_module.is_island_quality_tip_showing = false
  lua_event_module:send_event(lua_event_module.event_type.on_island_quality_tip_finished)
end

function M:update(delta_time)
  base.update(self, delta_time)
  self._remaining_time = self._remaining_time - delta_time
  if self._remaining_time <= 0 then
    self._remaining_time = 0
    self:close_self()
  end
end

return M
