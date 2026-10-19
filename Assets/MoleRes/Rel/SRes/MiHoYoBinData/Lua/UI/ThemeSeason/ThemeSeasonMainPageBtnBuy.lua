local M = G.Class("ThemeSeasonMainPageBtnBuy", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._red_point = nil
  self._ui_state_group = nil
  self._btn = nil
end

function M:on_create()
  base.on_create(self)
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_theme_bp_purchased, pack(self, M._on_purchase_rsp))
end

function M:get_btn()
  return self._btn
end

function M:refresh()
  self:_refresh_purchase_state()
end

function M:_on_click()
  theme_season_module:open_bp_pay_page()
end

function M:_on_purchase_rsp()
  self:_refresh_purchase_state()
end

function M:_refresh_purchase_state()
  if is_null(self._ui_state_group) then
    return
  end
  local purchased = theme_season_module:has_purchased_bp()
  self._ui_state_group:SetState(purchased and 1 or 0)
end

return M
