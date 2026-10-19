local M = G.Class("ThemeSeasonMainPageBtnStory", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._red_point = nil
  self._img_new = nil
  self._btn = nil
end

function M:on_create()
  base.on_create(self)
end

function M:get_btn()
  return self._btn
end

function M:refresh()
  local rp_type = theme_season_module:get_story_red_point_type()
  if not_null(self._red_point) then
    local red_point_type = rp_type
    if red_point_type == RedPointType.NewRp then
      red_point_type = RedPointType.None
    end
    self._red_point:ShowRedPoint(red_point_type)
  end
  if not_null(self._img_new) then
    local show_new = theme_season_module:is_season_active() and theme_season_module:has_story_new_content()
    UIUtil.set_active(self._img_new, show_new)
  end
end

function M:_on_click()
  theme_season_module:open_plot_page()
end

return M
