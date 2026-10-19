local M = G.Class("ThemeSeasonMainPageBtnDailyTask", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._ui_state_group = nil
  self._txt_num = nil
  self._red_point = nil
  self._btn = nil
end

function M:on_create()
  base.on_create(self)
end

function M:get_btn()
  return self._btn
end

function M:refresh()
  if not_null(self._red_point) then
    local rp_type = theme_season_module:get_footprint_red_point_type()
    self._red_point:ShowRedPoint(rp_type)
  end
  if not_null(self._txt_num) then
    local list = theme_season_module:get_daily_mission_list()
    local total = #list
    local done = theme_season_module:get_daily_done_count()
    UIUtil.set_text(self._txt_num, done .. "/" .. total)
  end
end

function M:_on_click()
  theme_season_module:open_daily_page()
end

return M
