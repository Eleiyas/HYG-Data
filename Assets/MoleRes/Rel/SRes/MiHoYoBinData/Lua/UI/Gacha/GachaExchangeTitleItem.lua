local M = G.Class("GachaExchangeTitleItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._pool_id = nil
  self._pool_index = nil
  self._is_exchange = false
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(pool_id, pool_index, is_exchange, drawn_map, exchanged_map)
  self._pool_id = pool_id
  self._pool_index = pool_index
  self._is_exchange = is_exchange
  if not self._is_exchange then
    local pool_cfg = gacha_module:get_pool_cfg(pool_id, pool_index)
    if pool_cfg == nil then
      return
    end
    if pool_cfg.itemtype == GachaConst.item_type.core then
      UIUtil.set_text_by_id(self._txt_collection_name, "Gacha_T1_ClothShop_CoreItem")
    else
      UIUtil.set_text_by_id(self._txt_collection_name, "Gacha_T1_ClothShop_OtherItem")
    end
  else
    local shop_cfg = gacha_module:get_exchange_shop_cfg(pool_id, pool_index)
    if shop_cfg == nil then
      return
    end
    if shop_cfg.shoptag == GachaConst.shop_category.suit then
      local gacha_id = gacha_module:get_cur_gacha_id()
      local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
      if activity_cfg == nil then
        return
      end
      UIUtil.set_text(self._txt_collection_name, activity_cfg.name)
    elseif shop_cfg.shoptag == GachaConst.shop_category.scatter then
      UIUtil.set_text_by_id(self._txt_collection_name, "Gacha_T0_ClothShop_Title_Others")
    elseif shop_cfg.shoptag == GachaConst.shop_category.furniture then
      UIUtil.set_text_by_id(self._txt_collection_name, "Gacha_T0_FurnitureShop_CurrentTab")
    elseif shop_cfg.shoptag == GachaConst.shop_category.dye then
      UIUtil.set_text_by_id(self._txt_collection_name, "Gacha_Exchange_OtherItem")
    end
  end
  self:refresh_progress(drawn_map, exchanged_map)
end

function M:refresh_progress(drawn_map, exchanged_map)
  local gacha_id = gacha_module:get_cur_gacha_id()
  local owned, total = 0, 0
  local is_show_progress = true
  if self._is_exchange then
    local shop_cfg = gacha_module:get_exchange_shop_cfg(self._pool_id, self._pool_index)
    if shop_cfg == nil then
      return
    end
    if shop_cfg.shoptag == GachaConst.shop_category.dye then
      is_show_progress = false
    else
      owned, total = gacha_module:get_collect_progress(gacha_id, shop_cfg.shoptag, drawn_map, exchanged_map)
    end
  else
    local pool_cfg = gacha_module:get_pool_cfg(self._pool_id, self._pool_index)
    if pool_cfg == nil then
      return
    end
    owned, total = gacha_module:get_collect_progress_by_item_type(gacha_id, self._pool_id, pool_cfg.itemtype, drawn_map, exchanged_map)
  end
  if is_show_progress then
    UIUtil.set_text_by_id(self._txt_collection_count, "Gacha_T0_ClothShop_SuitColloection", owned, total)
  else
    UIUtil.set_text(self._txt_collection_count, "")
  end
end

return M
