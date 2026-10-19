local base = require("UI/Gacha/GachaPoolShowPageBase")
local M = G.Class("GachaExchangePage", base)

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_gacha_exchange_result, pack(self, M._on_exchange_result))
end

function M:_init_custom_data()
  base._init_custom_data(self)
  self._all_collect_reward_items = {}
  self._on_reward_item_click = pack(self, M._on_all_collect_reward_item_click)
end

function M:_get_tab_groups(gachapoolid)
  return gacha_module:get_exchange_tab_groups(gachapoolid)
end

function M:_get_cur_select_index()
  return gacha_module:get_cur_exchange_index()
end

function M:_set_cur_select_index(index)
  gacha_module:set_cur_exchange_index(index)
end

function M:_get_pool_cfg(pool_id, index)
  return gacha_module:get_exchange_shop_cfg(pool_id, index)
end

function M:_refresh_show_data()
  self:_refresh_tab_groups_data()
  self:_refresh_base()
end

function M:_refresh_tab_groups_data()
  for k, v in pairs(self._tab_title_cls_map) do
    if v then
      v:refresh_progress(self._drawn_map, self._exchanged_map)
    end
  end
  for k, v in pairs(self._tab_item_cls_map) do
    if v then
      v:refresh_base(self._drawn_map, self._exchanged_map)
    end
  end
end

function M:_refresh_detail()
  self:_refresh_item_info()
  self:_refresh_exchange_btn()
  self:_refresh_all_collect_reward()
  self:_refresh_model_preview()
end

function M:_refresh_base()
  self:_refresh_item_info()
  self:_refresh_exchange_btn()
end

function M:_refresh_item_info()
  if self._cur_select_cfg == nil then
    return
  end
  local shop_cfg = self._cur_select_cfg
  local gacha_id = gacha_module:get_cur_gacha_id()
  if not_null(self._txt_item_name) then
    UIUtil.set_text(self._txt_item_name, item_module:get_item_name_by_id(shop_cfg.itemid))
  end
  local owned_count = gacha_module:get_item_owned_count(gacha_id, shop_cfg.itemid, self._drawn_map, self._exchanged_map)
  local is_item_owned = 0 < owned_count
  if not_null(self._txt_owner_num) then
    UIUtil.set_active(self._txt_owner_num, is_item_owned)
    if is_item_owned then
      UIUtil.set_text_by_id(self._txt_owner_num, "Gacha_T0_ClothShop_ItemObtainNum", tostring(owned_count))
    end
  end
  if not_null(self._txt_not_owner) then
    UIUtil.set_active(self._txt_not_owner, not is_item_owned)
  end
  if not_null(self._txt_core_cloth_desc) then
    UIUtil.set_active(self._txt_core_cloth_desc, false)
  end
  local is_furniture = shop_cfg.shoptag == GachaConst.shop_category.furniture
  self:_refresh_furniture_area(shop_cfg, is_furniture)
  self:_refresh_limit_tip(shop_cfg, is_furniture, owned_count)
  if not_null(self._txt_exchange) then
    UIUtil.set_text_by_id(self._txt_exchange, is_furniture and "Gacha_T0_FurnitureExchange_Button" or "Gacha_T0_ClothExchange_Button")
  end
end

function M:_refresh_furniture_area(shop_cfg, is_furniture)
  local item_cfg = is_furniture and item_module:get_cfg_by_id(shop_cfg.itemid) or nil
  local entity_cfg = item_cfg ~= nil and item_cfg.idCfg ~= nil and item_cfg.idCfg.entityCfg or nil
  local show = is_furniture and entity_cfg ~= nil
  if not_null(self._txt_area) then
    UIUtil.set_active(self._txt_area, show)
  end
  if not show then
    return
  end
  local size_x, size_z = entity_cfg.sizex / 2, entity_cfg.sizez / 2
  if not_null(self._txt_area) then
    UIUtil.set_text(self._txt_area, string.format(UIUtil.get_text_by_id("multiplication_sign_fur"), size_x, size_z))
  end
  if not_null(self._trans_floor_area) then
    self._trans_floor_area:SetLocalScale(math.min(size_x, 3), math.min(size_z, 3), 1)
  end
end

function M:_refresh_limit_tip(shop_cfg, is_furniture, owned_count)
  local limit_count = shop_cfg.limitcount or 0
  local can_buy_num = 0
  if is_furniture and 0 < limit_count then
    can_buy_num = math.max(0, limit_count - owned_count)
  end
  if not_null(self._txt_limit_tip) then
    UIUtil.set_active(self._txt_limit_tip, is_furniture and (limit_count == 0 or limit_count ~= 1 and 0 < can_buy_num))
  end
  if not_null(self._txt_limit_num) then
    UIUtil.set_active(self._txt_limit_num, 0 < can_buy_num)
    UIUtil.set_text_by_id(self._txt_limit_num, "Gacha_Exchange_GoldenFurniture_Limit_2", 0 < can_buy_num and tostring(can_buy_num) or "")
  end
end

function M:_refresh_exchange_btn()
  if self._cur_select_cfg == nil then
    return
  end
  local shop_cfg = self._cur_select_cfg
  local _, cost_num, _ = gacha_module:get_shop_price_info(gacha_module:get_cur_gacha_id(), shop_cfg, self._drawn_map, self._exchanged_map)
  local enough = gacha_module:is_coin_enough(shop_cfg.cointype, cost_num)
  local show_txt = tostring(cost_num)
  if not enough then
    show_txt = gacha_module:wrap_style(show_txt, GachaConst.price_not_enough_style)
  end
  UIUtil.set_text(self._txt_coin_num, show_txt)
  if not_null(self._img_icon_coin) then
    item_module:set_item_icon(self._img_icon_coin, shop_cfg.cointype, nil, nil, self:get_load_proxy())
  end
  local gacha_id = gacha_module:get_cur_gacha_id()
  local owned_count = gacha_module:get_item_owned_count(gacha_id, shop_cfg.itemid, self._drawn_map, self._exchanged_map)
  local state = gacha_module:get_exchange_item_state(gacha_id, shop_cfg, owned_count, self._drawn_map, self._exchanged_map)
  local can_exchange = state ~= GachaConst.exchange_state.owned_not_exchangeable
  UIUtil.set_active(self._btn_exchange, can_exchange)
  UIUtil.set_active(self._btn_owner, not can_exchange)
  UIUtil.set_active(self._btn_go_draw, false)
  self._btn_owner.interactable = false
end

function M:_refresh_all_collect_reward()
  if self._cur_select_cfg == nil then
    return
  end
  local shop_cfg = self._cur_select_cfg
  local is_suit_item = shop_cfg.shoptag == GachaConst.shop_category.suit
  UIUtil.set_active(self._set_effects_panel, is_suit_item)
  if is_suit_item then
    local gacha_id = gacha_module:get_cur_gacha_id()
    local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
    if activity_cfg == nil then
      return
    end
    local all_collect_rewards = gacha_module:get_all_collect_reward_list(activity_cfg.allcollectrewardpoolid)
    local item_count = all_collect_rewards and #all_collect_rewards or 0
    UIUtil.set_active(self._set_effects_panel, 0 < item_count)
    if item_count <= 0 then
      return
    end
    local max_count = math.max(item_count, #self._all_collect_reward_items)
    for i = 1, max_count do
      local item = self._all_collect_reward_items[i]
      if i <= item_count then
        item = self:_refresh_all_collect_reward_item(item, all_collect_rewards[i])
        self._all_collect_reward_items[i] = item
        item:set_active(true)
      elseif item then
        item:set_active(false)
      end
    end
  end
end

function M:_refresh_all_collect_reward_item(cls, collect_cfg)
  if cls == nil then
    local obj = self._collect_reward:AddItem(0)
    cls = self:add_panel(GachaConst.item_path.all_collect_reward, obj)
    cls:set_on_click(self._on_reward_item_click)
  end
  cls:refresh(collect_cfg)
  return cls
end

function M:_on_all_collect_reward_item_click(collect_cfg, is_on)
  if collect_cfg == nil then
    return
  end
  if collect_cfg.rewardtype == GachaConst.all_collect_reward_type.video then
    if not is_on then
      return
    end
    self:_play_all_collect_reward_video(collect_cfg)
  elseif collect_cfg.rewardtype == GachaConst.all_collect_reward_type.effect then
  end
end

function M:_play_all_collect_reward_video(collect_cfg)
  if collect_cfg.advvideoid == nil or collect_cfg.advvideoid <= 0 then
    return
  end
  local ctx = {
    title = collect_cfg.videottitle or nil,
    desc = collect_cfg.videodesc or nil,
    video_cfg_id = collect_cfg.advvideoid,
    auto_play = true,
    is_loop = true,
    can_skip = true
  }
  UIManagerInstance:open("UI/CommonUI/VideoPreviewDialog", ctx)
end

function M:_on_do_exchange_click()
  local shop_cfg = self._cur_select_cfg
  if shop_cfg == nil then
    return
  end
  local _, cost_num, _ = gacha_module:get_shop_price_info(gacha_module:get_cur_gacha_id(), shop_cfg, self._drawn_map, self._exchanged_map)
  local enough = gacha_module:is_coin_enough(shop_cfg.cointype, cost_num)
  if not enough then
    local lack_amount = cost_num - gacha_module:get_owned_coin_count(shop_cfg.cointype)
    local coin_name = item_module:get_item_name_by_id(shop_cfg.cointype)
    self:_show_lack_coin_popup(lack_amount, coin_name)
  elseif shop_cfg.bulkexchangetag and shop_cfg.bulkexchangetag > 0 then
    self:_show_furniture_exchange_popup(shop_cfg)
  else
    self:_show_exchange_popup(shop_cfg)
  end
end

function M:_show_lack_coin_popup(lack_amount, coin_name)
  local gacha_id = gacha_module:get_cur_gacha_id()
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return
  end
  local popup = UIUtil.get_confirm_popup()
  local show_text = UIUtil.get_text_by_id("Gacha_T0_CantExchange_Content", lack_amount, coin_name, activity_cfg.name)
  popup:set_texts(show_text, UIUtil.get_text_by_id("Gacha_T0_CantExchange_ToGacha"), UIUtil.get_text_by_id("Gacha_T0_CantExchange_No"), UIUtil.get_text_by_id("Gacha_T0_Confirm_Title"))
  popup:set_callbacks(function()
    self:close_self()
    gacha_module:open_main_page(gacha_id)
  end)
  popup:show()
end

function M:_show_exchange_popup(shop_cfg)
  local gacha_id = gacha_module:get_cur_gacha_id()
  local _, show_price = gacha_module:get_shop_price_info(gacha_id, shop_cfg, self._drawn_map, self._exchanged_map)
  local popup = UIUtil.get_confirm_popup()
  local icon_path = item_module:get_item_icon(shop_cfg.cointype)
  local show_text = UIUtil.get_text_by_id("Gacha_T0_ClothExchange_Content", icon_path, show_price, shop_cfg.name)
  popup:set_texts(show_text, UIUtil.get_text_by_id("Gacha_T0_ClothExchange_Yes"), UIUtil.get_text_by_id("Gacha_T0_ClothExchange_No"), UIUtil.get_text_by_id("Gacha_T0_ClothExchange_Title"))
  popup:set_currency_type(shop_cfg.cointype)
  popup:set_callbacks(function()
    gacha_module:request_exchange(gacha_module:get_cur_gacha_id(), shop_cfg.index, 1, show_price)
  end)
  popup:show()
end

function M:_show_furniture_exchange_popup(shop_cfg)
  local gacha_id = gacha_module:get_cur_gacha_id()
  local max_num, original_price, discount_price, is_exchanged, limit_tip = self:get_buy_item_info(gacha_id, shop_cfg)
  local is_furniture = shop_cfg.shoptag == GachaConst.shop_category.furniture
  local title_text = is_furniture and UIUtil.get_text_by_id("Gacha_T0_FurnitureShop_Title") or nil
  local buy_text = is_furniture and UIUtil.get_text_by_id("Gacha_T0_FurnitureExchange_Button") or nil
  UIManagerInstance:open("UI/ConfirmView/CommonConfirmBuyItemDialog", {
    title_text = title_text,
    buy_text = buy_text,
    cfg_id = shop_cfg.itemid,
    unit_price = original_price,
    max_num = max_num,
    limit_tip = limit_tip,
    coin_id = shop_cfg.cointype,
    item_group_num = shop_cfg.unitcount,
    discount_price = discount_price,
    discount_start_num = is_exchanged and 0 or 1,
    discount_tip_id = "Gacha_Exchange_Furniture_Sale_1",
    buy_callback = function(count, total_price)
      gacha_module:request_exchange(gacha_id, shop_cfg.index, count, total_price)
    end
  })
end

function M:get_buy_item_info(gacha_id, shop_cfg)
  local exchanged_count = gacha_module:get_item_owned_count(gacha_id, shop_cfg.itemid, self._drawn_map, self._exchanged_map)
  local limit_count = shop_cfg.limitcount or 0
  local remain_count = GachaConst.exchange_max_buy_count
  if 0 < limit_count then
    remain_count = math.max(0, limit_count - exchanged_count)
  end
  local original_price, discount_price = gacha_module:get_shop_price_info_with_saleprice(shop_cfg)
  local owned_coin_count = gacha_module:get_owned_coin_count(shop_cfg.cointype)
  local max_num = 0
  if 0 < discount_price then
    if exchanged_count < 1 then
      if original_price <= owned_coin_count then
        max_num = 1 + math.floor((owned_coin_count - original_price) / discount_price)
      end
    else
      max_num = math.floor(owned_coin_count / discount_price)
    end
  elseif 0 < original_price then
    max_num = math.floor(owned_coin_count / original_price)
  else
    Logger.LogError("[GachaExchangePage] price is 0, pool index: " .. tostring(shop_cfg.index) .. ", item: " .. tostring(shop_cfg.itemid))
    max_num = remain_count
  end
  max_num = math.min(remain_count, max_num)
  local limit_tip = 0 < limit_count and UIUtil.get_text_by_id("Gacha_Exchange_GoldenFurniture_Limit", exchanged_count, limit_count) or nil
  return max_num, original_price, discount_price, 0 < exchanged_count, limit_tip
end

function M:_on_exchange_result(exchange_rsp)
  if exchange_rsp == nil then
    return
  end
  local gacha_id = exchange_rsp.GachaId
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return
  end
  local exchange_cfg = gacha_module:get_exchange_shop_cfg(activity_cfg.gachapoolid, exchange_rsp.ExchangeIndex)
  if exchange_cfg == nil then
    return
  end
  self._drawn_map, self._exchanged_map = gacha_module:build_owned_data_snapshot(gacha_id)
  local is_all_collected = exchange_rsp.IsAllCollected
  local is_dye_tag = exchange_cfg.shoptag == GachaConst.shop_category.dye
  local is_new_item = exchange_cfg.newitemshowtag == GachaConst.new_item_show_tag
  local is_cloth = gacha_module:is_cloth_pool(activity_cfg)
  local item_owned_count = gacha_module:get_item_owned_count(gacha_id, exchange_rsp.ItemId, self._drawn_map, self._exchanged_map)
  if item_owned_count <= exchange_rsp.Count and not is_dye_tag and is_new_item then
    gacha_module:set_is_in_draw_show(true)
    local show_info = {
      gacha_id = gacha_id,
      exchange_index = exchange_rsp.ExchangeIndex,
      item_ids = {
        exchange_rsp.ItemId
      },
      is_exchange = true,
      is_all_collected = is_all_collected
    }
    gacha_module:open_performance_controller_page({
      gacha_id = gacha_id,
      performance_type = GachaConst.performance_type.new_obtain,
      new_obtain_data = show_info
    })
    self._not_move_item_scroller = true
  elseif not is_cloth or is_dye_tag or not is_new_item then
    local items = {
      {
        id = exchange_rsp.ItemId,
        num = exchange_rsp.Count
      }
    }
    common_ui_module:show_reward_dialog_with_callback(item_module:get_item_name_by_id(exchange_rsp.ItemId), nil, items, function()
      if is_all_collected then
        gacha_module:open_all_collect_banner(gacha_id)
      end
    end)
  elseif is_all_collected then
    gacha_module:open_all_collect_banner(gacha_id)
  end
  self:_refresh_show_data()
end

return M
