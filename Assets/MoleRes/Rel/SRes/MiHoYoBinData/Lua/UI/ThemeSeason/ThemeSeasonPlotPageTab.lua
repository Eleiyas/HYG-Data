local M = G.Class("ThemeSeasonPlotPageTab", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._index = 0
  self._txt_title = nil
  self._red_point = nil
end

function M:on_create()
  base.on_create(self)
  self._toggle = self.game_obj:GetComponent(typeof(ToggleEx))
end

function M:get_toggle()
  return self._toggle
end

function M:refresh(act_data, index)
  self._index = index
  if not_null(self._txt_title) then
    UIUtil.set_text(self._txt_title, act_data.title or "")
  end
  self:refresh_red_point(act_data)
end

function M:refresh_red_point(act_data)
  if is_null(self._red_point) then
    return
  end
  local rp_type = theme_season_module:get_story_act_red_point_type(act_data)
  self._red_point:ShowRedPoint(rp_type)
end

function M:set_selected(is_on)
  if not_null(self._toggle) then
    self._toggle.isOnValue = is_on
  end
end

return M
