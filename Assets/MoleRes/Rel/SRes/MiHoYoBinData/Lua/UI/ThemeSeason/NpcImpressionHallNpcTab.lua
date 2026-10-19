local M = G.Class("NpcImpressionHallNpcTab", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._npc_data = nil
  self._index = 0
  self._tog = nil
  self._img_select_icon = nil
  self._img_unselect_icon = nil
  self._red_point = nil
  self._ui_state_group_get = nil
  self._trans_can_get_tips = nil
end

function M:on_create()
  base.on_create(self)
end

function M:get_toggle()
  return self._tog
end

function M:refresh(npc_data, index, show_tips)
  self._npc_data = npc_data
  self._index = index
  self:_refresh_icon()
  self:_refresh_red_point()
  self:_refresh_get_state()
  self:set_tips_visible(show_tips)
end

function M:set_tips_visible(show_tips)
  UIUtil.set_active(self._trans_can_get_tips, show_tips == true)
end

function M:_refresh_get_state()
  if not_null(self._ui_state_group_get) then
    local npc_id = self._npc_data and self._npc_data.config_id or 0
    local all_obtained = theme_season_module:is_npc_all_goods_obtained(npc_id)
    self._ui_state_group_get:SetState(all_obtained and 1 or 0)
  end
end

function M:_refresh_red_point()
  if not_null(self._red_point) then
    local npc_id = self._npc_data and self._npc_data.config_id or 0
    local rp = theme_season_module:npc_has_claimable_premium(npc_id) and RedPointType.GiftRP or RedPointType.None
    self._red_point:ShowRedPoint(rp)
  end
end

function M:set_selected(is_on)
  if not_null(self._tog) then
    self._tog.isOnValue = is_on
  end
end

function M:_refresh_icon()
  local icon = self._npc_data and self._npc_data.icon or ""
  if icon ~= "" then
    if not_null(self._img_select_icon) then
      UIUtil.set_image(self._img_select_icon, icon, self:get_load_proxy())
    end
    if not_null(self._img_unselect_icon) then
      UIUtil.set_image(self._img_unselect_icon, icon, self:get_load_proxy())
    end
  end
end

return M
