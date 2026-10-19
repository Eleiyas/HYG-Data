local M = G.Class("ThemeSeasonMainPageBtnStarExplore", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._red_point = nil
  self._img_icon_npc = nil
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
    self._red_point:ShowRedPoint(theme_season_module:get_season_codex_red_point_type())
  end
end

function M:_on_click()
  UIManagerInstance:open("UI/StarExplore/StarExploreTeleportationPage", {is_outside_star_sea = true})
end

return M
