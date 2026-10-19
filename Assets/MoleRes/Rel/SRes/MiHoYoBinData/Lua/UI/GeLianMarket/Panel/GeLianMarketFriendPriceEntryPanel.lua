local M = G.Class("GeLianMarketFriendPriceEntryPanel", G.UIPanel)
local base = G.UIPanel
local crop_item_cls = "UI/GeLianMarket/Panel/GeLianMarketFriendCropPriceItem"
local MAX_CROP_COUNT = 3

function M:init()
  base.init(self)
  self._row = nil
  self._crop_items = {}
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_avatar, pack(self, M._on_btn_avatar))
end

function M:on_destroy()
  self._row = nil
  self._crop_items = {}
  base.on_destroy(self)
end

function M:hide_visit_btn()
end

function M:render(row)
  self._row = row
  self:hide_visit_btn()
  if row == nil then
    return
  end
  self:_refresh_player_info(row)
  self:_refresh_crop_entries(row.entries or {})
end

function M:_refresh_player_info(row)
  local head_cfg = ExcelDataUtil.get_value(typeof(BPlayerHeadCfg), row.avatar_id or 1)
  if head_cfg ~= nil then
    UIUtil.set_image(self._img_head, head_cfg.respath, self:get_load_proxy())
  end
  UIUtil.set_text(self._txt_name, row.nickname or "")
  UIUtil.set_text(self._txt_signature, row.title or "")
  self._state_group_state:SetState(row.is_online and 1 or 0)
end

function M:_refresh_crop_entries(entries)
  local count = math.min(#entries, MAX_CROP_COUNT)
  UIUtil.set_active(self._txt_empty, count == 0)
  for i = #self._crop_items + 1, count do
    local trans = self._list_item_binder_crop:AddItem(0, true)
    if is_null(trans) then
      return
    end
    self._crop_items[i] = self:add_panel(crop_item_cls, trans)
  end
  local txt_lightness = self:_get_price_txt_color_lightness()
  for i = 1, #self._crop_items do
    self._crop_items[i]:set_price_txt_color_lightness(txt_lightness)
    self._crop_items[i]:render(entries[i])
  end
end

function M:_on_btn_avatar()
  local row = self._row
  if row == nil or row.is_self then
    return
  end
  UIManagerInstance:open("UI/GeLianMarket/FoodMarketAvatarBtnDialog", {
    uid = row.uid,
    show_chat = social_module:is_friend(row.uid),
    align_target = self._btn_avatar.transform,
    offset = Vector2(0, 0)
  })
end

function M:_get_price_txt_color_lightness()
  local color_util = gelian_market_module.color_util
  if not self._row then
    return color_util.LIGHTNESS.Light
  end
  return self._row.is_self and color_util.LIGHTNESS.Dark or color_util.LIGHTNESS.Light
end

return M
