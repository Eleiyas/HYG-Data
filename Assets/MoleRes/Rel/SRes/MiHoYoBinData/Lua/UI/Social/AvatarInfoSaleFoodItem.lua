local M = G.Class("AvatarInfoSaleFoodItem", G.UIBase)
local base = G.UIBase
local color_util = gelian_market_module.color_util
local trend_state_map = {
  [0] = 0,
  [1] = 1,
  [2] = 2,
  [3] = 0,
  [4] = 1
}

function M:init()
  base.init(self)
  self._item_view_data = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_detail, pack(self, M._on_btn_detail))
end

function M:_on_btn_detail()
  if is_null(self._item_view_data) then
    return
  end
  local screen_point = CS.UnityEngine.RectTransformUtility.WorldToScreenPoint(UIManagerInstance.ui_camera, self._img_icon.rectTransform.position)
  local fruit_ids = {}
  for i = 1, #(self._item_view_data.fruit_ids or {}) do
    fruit_ids[i] = self._item_view_data.fruit_ids[i]
  end
  UIManagerInstance:open("UI/GeLianMarket/GeLianFoodMarketPriceDialog", {
    tag = self._item_view_data.tag,
    fruit_ids = fruit_ids,
    price_multiplier = self._item_view_data.server_multiplier or 100,
    is_right_side = true,
    target_screen_x = screen_point.x,
    target_screen_y = screen_point.y
  })
end

function M:refresh(item_view_data)
  self._item_view_data = item_view_data
  if is_null(item_view_data) then
    self:set_active(false)
    return
  end
  self:set_active(true)
  local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), item_view_data.display_config_id)
  item_module:set_item_icon(self._img_icon, item_view_data.display_config_id, nil, nil, self:get_load_proxy())
  UIUtil.set_text(self._txt_name, item_cfg ~= nil and item_cfg.name or "")
  UIUtil.set_text(self._txt_current_num, 0)
  UIUtil.set_text(self._txt_total_num, "/" .. tostring(item_view_data.sell_limit or 0))
  local multiplier = item_view_data.display_multiplier or 100
  local trend_state = item_view_data.trend_state or 2
  local color_key = color_util.get_trend_color_key(trend_state, true)
  self._ui_state_trend:SetState(trend_state_map[trend_state] or 0)
  UIUtil.set_text(self._txt_new_price, TextMapFormatUtil.FormatInteger(item_view_data.final_price or 0), color_key)
  local prefix = ""
  if 100 < multiplier then
    prefix = "+"
  elseif multiplier < 100 then
    prefix = "-"
  end
  UIUtil.set_text(self._txt_trend, prefix .. TextMapFormatUtil.FormatPercent(math.abs(multiplier - 100) / 100, 0), color_key)
  UIUtil.set_image_color(self._img_trend_bg, color_key)
end

return M
