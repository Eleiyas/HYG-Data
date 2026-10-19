local M = G.Class("ThemeSeasonMainPageBtnImpression", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._tips_clicked = false
  self._ui_state_group = nil
  self._red_point = nil
  self._btn = nil
  self._trans_can_get_tips = nil
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
  self._tips_clicked = false
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.UpdateCoinData, pack(self, M.refresh))
end

function M:get_btn()
  return self._btn
end

function M:refresh()
  if not_null(self._red_point) then
    self._red_point:ShowRedPoint(theme_season_module:get_impression_red_point_type())
  end
  UIUtil.set_active(self._trans_can_get_tips, not self._tips_clicked and theme_season_module:should_show_impression_tips())
end

function M:_on_click()
  self._tips_clicked = true
  UIUtil.set_active(self._trans_can_get_tips, false)
  theme_season_module:open_npc_impression_hall_page()
end

return M
