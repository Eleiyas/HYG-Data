local M = G.Class("CommonGiftFriendSelectItem", G.UIPanel)
local base = G.UIPanel
local GIFT_BTN_VISUAL = {GIFTABLE = 0, BLOCKED = 1}
local ONLINE_VISUAL = {ONLINE = 0, OFFLINE = 1}

function M:init()
  base.init(self)
  self._data = nil
  self._on_gift_click = nil
  self._img_head = nil
  self._txt_name = nil
  self._txt_title = nil
  self._txt_cannot_tips = nil
  self._btn_gift = nil
  self._btn_follow_group = nil
  self._ui_state_group_btn = nil
  self._ui_state_group_ui_online = nil
  self._trans_icon_tip = nil
  self._img_icon_star_dy = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_gift) then
    self:bind_callback(self._btn_gift, pack(self, M._on_btn_gift_click))
  end
end

function M:refresh(data, on_gift_click)
  self._data = data
  self._on_gift_click = on_gift_click
  if data == nil then
    return
  end
  UIUtil.set_text(self._txt_name, data.name or "")
  self:_refresh_title()
  self:_refresh_head()
  self:_refresh_planet_icon()
  self:_refresh_bestfriend_tag()
  self:_refresh_cannot_tips()
  if not_null(self._ui_state_group_ui_online) then
    self._ui_state_group_ui_online:SetState(data.is_online and ONLINE_VISUAL.ONLINE or ONLINE_VISUAL.OFFLINE)
  end
  if not_null(self._ui_state_group_btn) then
    self._ui_state_group_btn:SetState(data.can_gift and GIFT_BTN_VISUAL.GIFTABLE or GIFT_BTN_VISUAL.BLOCKED)
  end
end

function M:_refresh_cannot_tips()
  if is_null(self._txt_cannot_tips) then
    return
  end
  local text_id = not self._data.can_gift and self._data.block_tip_text_id or nil
  UIUtil.set_text(self._txt_cannot_tips, string.is_valid(text_id) and UIUtil.get_text_by_id(text_id) or "")
end

function M:_refresh_head()
  if is_null(self._img_head) then
    return
  end
  local avatar_id = self._data and self._data.avatar_id or 0
  local head_cfg = 0 < avatar_id and ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), avatar_id) or nil
  UIUtil.set_active(self._img_head, head_cfg ~= nil)
  if head_cfg then
    UIUtil.set_image(self._img_head, head_cfg.respath, self:get_load_proxy())
  end
end

function M:_refresh_planet_icon()
  if is_null(self._img_icon_star_dy) then
    return
  end
  local galaxy_id = self._data and self._data.galaxy_id or 0
  local galaxy_cfg = 0 < galaxy_id and ExcelDataUtil.get_value(typeof(BRegionIconCfg), galaxy_id) or nil
  UIUtil.set_active(self._img_icon_star_dy, galaxy_cfg ~= nil)
  if galaxy_cfg then
    UIUtil.set_image(self._img_icon_star_dy, galaxy_cfg.smallicon, self:get_load_proxy())
  end
end

function M:_refresh_title()
  if is_null(self._txt_title) then
    return
  end
  local title = self._data and self._data.title or ""
  local has_title = string.is_valid(title)
  UIUtil.set_active(self._txt_title, has_title)
  UIUtil.set_text(self._txt_title, has_title and title or "")
end

function M:_refresh_bestfriend_tag()
  if is_null(self._trans_icon_tip) then
    return
  end
  UIUtil.set_active(self._trans_icon_tip, self._data ~= nil and self._data.is_best_friend == true)
end

function M:_on_btn_gift_click()
  if self._data == nil or self._on_gift_click == nil then
    return
  end
  self._on_gift_click(self._data)
end

return M
