local base = require("UI/Gacha/GachaPoolPanelBase")
local M = G.Class("GachaClothScratchPoolPanel", base)

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.panel_path.pool_cloth_scratch
end

function M:_on_create_extend()
  if not_null(self._btn_draw_once) then
    self:bind_callback(self._btn_draw_once, pack(self, M._on_btn_scratch_click))
  end
end

function M:_refresh_extend()
  self:refresh_draw_ticket_price(GachaConst.draw_count.once, self._txt_num_once, self._img_icon_coin_once)
  self:_refresh_suit()
end

function M:_refresh_collect_progress()
  local total, collected = self:_calc_collection()
  UIUtil.set_text_by_id(self._txt_collect_progress, "Gacha_T0_ClothShop_SuitColloection", collected, total)
end

function M:_calc_collection()
  if self._activity_cfg == nil then
    return 0, 0
  end
  local list = gacha_module:get_pool_cfg_list(self._activity_cfg.gachapoolid) or {}
  local total = #list
  local collected = 0
  local pool_info = gacha_module:get_pool_info(self._gacha_id)
  if pool_info ~= nil and not is_null(pool_info.DrawnItemIdList) then
    local drawn = list_to_table(pool_info.DrawnItemIdList) or {}
    collected = #drawn
  end
  return total, collected
end

function M:_refresh_suit()
  local suit_cfg = gacha_module:get_cloth_core_item(self._gacha_id)
  if suit_cfg ~= nil then
    item_module:set_item_icon(self._img_icon_suit, suit_cfg.itemid, nil, nil, self:get_load_proxy())
  end
  if not_null(self._txt_name_suit) and self._activity_cfg.name ~= nil then
    UIUtil.set_text(self._txt_name_suit, self._activity_cfg.name)
  end
  if not_null(self._txt_des_suit) and self._activity_cfg.advdiscrip ~= nil then
    UIUtil.set_text(self._txt_des_suit, self._activity_cfg.advdiscrip)
  end
end

function M:_refresh_exchange_entry()
  if not_null(self._btn_exchange) then
    UIUtil.set_active(self._btn_exchange, true)
  end
  if not_null(self._txt_exchange) then
    UIUtil.set_text_by_id(self._txt_exchange, "Gacha_T0_ClothShop_Title")
  end
end

function M:_on_btn_scratch_click()
  self:do_draw(false)
end

function M:on_exchange_click()
  gacha_module:open_cloth_pool_show_page()
end

return M
