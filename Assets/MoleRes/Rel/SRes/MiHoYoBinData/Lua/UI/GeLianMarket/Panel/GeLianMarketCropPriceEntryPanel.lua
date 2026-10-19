local M = G.Class("GeLianMarketCropPriceEntryPanel", G.UIPanel)
local base = G.UIPanel
local LimitState = {Normal = 0, Limited = 1}
local PRICE_TEXT_ROLL_DURATION = 2.5

function M:init()
  base.init(self)
  self._view_data = nil
  self._item_cls = nil
  self._price_txt_color_cache = Color()
end

function M:on_create()
  base.on_create(self)
  self._item_cls = self:add_panel(item_module.item_v2_panel_cls_name, self._trans_item)
  self:bind_callback(self._btn_icon, pack(self, M._on_btn_icon))
  self:bind_callback(self._btn_detail, pack(self, M._on_btn_detail))
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:render(view_data, detail_callback)
  self._view_data = view_data
  self._detail_callback = detail_callback
  if view_data == nil then
    self:set_active(false)
    return
  end
  self:set_active(true)
  self._item_cls:set_item_data(view_data.display_config_id, nil)
  UIUtil.set_text(self._txt_sold_count, tostring(view_data.sold_count) .. "/" .. tostring(view_data.sell_limit))
  local is_limited = view_data.sell_limit <= 0 or view_data.sold_count >= view_data.sell_limit
  self._state_group_limited:SetState(is_limited and LimitState.Limited or LimitState.Normal)
  local trend_state = view_data.trend_state or 2
  self._state_trend:SetState(trend_state)
  local delta = math.abs(view_data.display_multiplier - 100) / 100
  local color_key = gelian_market_module.color_util.get_trend_color_key(trend_state, true)
  local color = ColorUtil.get_color(color_key)
  self:_update_price_txt_color_cache(color)
  self._txt_price.color = self._price_txt_color_cache
  UIUtil.set_text(self._txt_price, view_data.final_price)
  UIUtil.set_text(self._txt_trend, TextMapFormatUtil.FormatPercent(delta, 0), color_key)
  UIUtil.set_image_color(self._img_arrow, color_key)
end

function M:play_price_roll()
  if self._view_data == nil then
    return
  end
  local to_number = self._view_data.final_price
  local from_number = 0
  if 1 < to_number then
    from_number = math.random(0, to_number - 1)
  end
  UIUtil.do_anim_txt_number_roll(self._txt_price, from_number, to_number, PRICE_TEXT_ROLL_DURATION, 0, nil, Ease.OutQuad)
end

function M:_on_btn_icon()
  if self._view_data ~= nil and self._detail_callback ~= nil then
    self._detail_callback(self._view_data, self.trans)
  end
end

function M:_on_btn_detail()
  if self._view_data == nil then
    return
  end
  local screen_point = CS.UnityEngine.RectTransformUtility.WorldToScreenPoint(UIManagerInstance.ui_camera, self._img_icon.rectTransform.position)
  local fruit_ids = {}
  for i = 1, #(self._view_data.fruit_ids or {}) do
    fruit_ids[i] = self._view_data.fruit_ids[i]
  end
  UIManagerInstance:open("UI/GeLianMarket/GeLianFoodMarketPriceDialog", {
    tag = self._view_data.tag,
    fruit_ids = fruit_ids,
    price_multiplier = self._view_data.server_multiplier or 100,
    is_right_side = false,
    target_screen_x = screen_point.x,
    target_screen_y = screen_point.y
  })
end

function M:_update_price_txt_color_cache(color)
  if is_null(color) then
    return
  end
  local alpha = self._txt_price.color.a
  self._price_txt_color_cache.r = color.r
  self._price_txt_color_cache.g = color.g
  self._price_txt_color_cache.b = color.b
  self._price_txt_color_cache.a = alpha
end

return M
