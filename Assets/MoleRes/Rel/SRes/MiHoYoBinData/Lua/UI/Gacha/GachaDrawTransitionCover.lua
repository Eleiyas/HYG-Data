local M = G.Class("GachaDrawTransitionCover", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.panel_path.draw_transition_cover
  self.config.type = EUIType.Info
  self.config.order_in_layer = 10
  self.config.mask_type = EUIMask.None
  self._show_background_flag = false
end

function M:on_enable()
  base.on_enable(self)
  if self._show_background_flag then
    self:show_background()
  else
    self:hide_background()
  end
end

function M:on_disable()
  base.on_disable(self)
  self:hide_background()
  self._show_background_flag = false
end

function M:set_show_background_flag(show)
  self._show_background_flag = show
end

function M:show_background()
  if not_null(self._gradient) then
    UIUtil.set_active(self._gradient, true)
  end
  CsBlackScreenManagerUtil.CloseBlackScreen()
end

function M:hide_background()
  if not_null(self._gradient) then
    UIUtil.set_active(self._gradient, false)
  end
end

return M
