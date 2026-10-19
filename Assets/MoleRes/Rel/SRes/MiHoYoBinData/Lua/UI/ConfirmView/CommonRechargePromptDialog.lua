local M = G.Class("CommonRechargePromptDialog", G.UIWindow)
local base = G.UIWindow
local QUERY_TIMEOUT = 15
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/ConfirmView/CommonRechargePromptDialog"
  self.config.type = EUIType.Dialog
  self._coin_items = {}
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_init_data()
  self:_refresh_static_ui()
  self:_start_query()
  self:_refresh_coin()
end

function M:on_disable()
  base.on_disable(self)
  if self._query_timer then
    self._query_timer = nil
    EventCenter.Broadcast(EventID.luaClosePayWaitPage, nil)
  end
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if not self._query_timer then
    return
  end
  self._query_timer = self._query_timer + deltaTime
  if self._query_timer >= QUERY_TIMEOUT then
    self:_on_query_finish(false, nil)
  end
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_buy, pack(self, M._on_btn_buy_click))
  self:bind_callback(self._btn_confim, pack(self, M._on_btn_confim_click))
  self:bind_callback(self._btn_cancel, pack(self, M._on_btn_cancel_click))
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
end

function M:_on_btn_close_click()
  UIManagerInstance:close(self.guid)
end

function M:_on_btn_buy_click()
  if curio_emporium_module:try_block_recharge_with_tip() then
    return
  end
  if not self._selected_cfg or not self._selected_goods then
    return
  end
  if self._selected_cfg:goodsid_is_empty() then
    return
  end
  local paid_goods_data = self._selected_goods
  local goods_name = self._selected_cfg.goodsname
  CsGameStoreModuleUtil.PayGoods(self._selected_cfg.goodsid, function(ret, msg)
    if ret ~= 0 then
      Logger.LogWarning("[CommonRechargePromptDialog] Pay failed, ret=" .. tostring(ret) .. " msg=" .. tostring(msg))
      return
    end
    Logger.Log("[CommonRechargePromptDialog] Pay success")
    if not_null(self.game_obj) then
      self:close_self()
    end
    curio_emporium_module:show_top_up_reward(paid_goods_data, goods_name)
  end, self._selected_cfg.goodsname)
end

function M:_on_btn_confim_click()
  if curio_emporium_module:try_block_store_with_tip() or curio_emporium_module:try_block_recharge_with_tip() then
    return
  end
  if self._confirm_callback then
    self._confirm_callback()
  end
  UIManagerInstance:close(self.guid)
end

function M:_on_btn_cancel_click()
  if self._cancel_callback then
    self._cancel_callback()
  end
  UIManagerInstance:close(self.guid)
end

function M:_init_data()
  local data = self:get_extra_data()
  data = data or {}
  self._title_text = data.title or ""
  self._info_text = data.info or ""
  self._confirm_text = data.confirm_text or UIUtil.get_text_by_id("Common_GoTo")
  self._lack_amount = data.lack_amount or 0
  self._confirm_callback = data.confirm_callback
  self._cancel_callback = data.cancel_callback
  self._selected_cfg = nil
  self._selected_goods = nil
  self._coin_ids = data.coin_ids
end

function M:_refresh_static_ui()
  UIUtil.set_text(self._text_title, self._title_text)
  UIUtil.set_text_with_dynamic_sprite(self._text_info, self._info_text)
  UIUtil.set_text(self._text_confirm, self._confirm_text)
  UIUtil.set_active(self._obj_item_group, false)
end

function M:_start_query()
  local cfgs = curio_emporium_module:get_all_top_up_cfg()
  if not cfgs then
    return
  end
  self._cfg_list = {}
  for _, cfg in pairs(cfgs) do
    table.insert(self._cfg_list, cfg)
  end
  table.sort(self._cfg_list, function(a, b)
    return a.id < b.id
  end)
  self._query_timer = 0
  EventCenter.Broadcast(EventID.luaOpenPayWaitPage, nil)
  curio_emporium_module:query_virtual_currency_goods(pack(self, M._on_query_finish))
end

function M:_on_query_finish(success, goods_dict)
  if not self._query_timer then
    return
  end
  self._query_timer = nil
  EventCenter.Broadcast(EventID.luaClosePayWaitPage, nil)
  if is_null(self.game_obj) then
    return
  end
  if not success or not goods_dict then
    return
  end
  self:_select_best_goods(goods_dict)
end

function M:_select_best_goods(goods_dict)
  local best_cfg, best_goods, best_total
  for _, cfg in ipairs(self._cfg_list) do
    if not cfg:goodsid_is_empty() then
      local ok, goods_data = goods_dict:TryGetValue(cfg.goodsid)
      if ok and goods_data and not is_null(goods_data.virtualCurrency) then
        local vc = goods_data.virtualCurrency
        local total = vc.count + (vc.countBonus or 0)
        if total >= self._lack_amount and (not best_total or best_total > total) then
          best_cfg = cfg
          best_goods = goods_data
          best_total = total
        end
      end
    end
  end
  if not best_cfg then
    for i = #self._cfg_list, 1, -1 do
      local cfg = self._cfg_list[i]
      if not cfg:goodsid_is_empty() then
        local ok, goods_data = goods_dict:TryGetValue(cfg.goodsid)
        if ok and goods_data and not is_null(goods_data.virtualCurrency) then
          best_cfg = cfg
          best_goods = goods_data
          break
        end
      end
    end
  end
  if not best_cfg or not best_goods then
    return
  end
  self._selected_cfg = best_cfg
  self._selected_goods = best_goods
  self:_refresh_goods_ui()
end

function M:_refresh_goods_ui()
  local goods = self._selected_goods
  if not goods then
    return
  end
  UIUtil.set_active(self._obj_item_group, true)
  UIUtil.set_text(self._text_name, self._selected_cfg.goodsname or "")
  if not is_null(goods.price) then
    UIUtil.set_text(self._text_money, goods.price.amountDisplay or "")
  end
  if not is_null(self._img_icon) and self._selected_cfg and not self._selected_cfg:icon_is_empty() then
    UIUtil.set_image(self._img_icon, self._selected_cfg.icon, self:get_load_proxy())
  end
  local vc = goods.virtualCurrency
  if not is_null(vc) then
    local has_double = vc.bonusOnceEligible and vc.countBonus > 0
    UIUtil.set_active(self._obj_double_tips, has_double)
    local bonus = vc.countBonus or 0
    if 0 < bonus then
      UIUtil.set_active(self._text_additionnal, true)
      UIUtil.set_text_by_id(self._text_additionnal, "CommonRechargePromptDialog_Additional", bonus)
    else
      UIUtil.set_active(self._text_additionnal, false)
    end
  else
    UIUtil.set_active(self._obj_double_tips, false)
    UIUtil.set_active(self._text_additionnal, false)
  end
end

function M:_refresh_coin()
  local is_show_coin = self._coin_ids and #self._coin_ids > 0
  UIUtil.set_active(self._right_layout_trans, is_show_coin)
  if not is_show_coin then
    return
  end
  local cur_coin_num = math.max(#self._coin_items, #self._coin_ids)
  for i = 1, cur_coin_num do
    if self._coin_ids[i] then
      if self._coin_items[i] == nil then
        self._coin_items[i] = self:_create_coin_item()
      end
      self._coin_items[i]:set_coin_id(self._coin_ids[i])
      self._coin_items[i]:set_active(true)
    elseif self._coin_items[i] then
      self._coin_items[i]:set_active(false)
    end
  end
end

function M:_create_coin_item(coin_type)
  local obj = UIUtil.load_prefab_set_parent(self._obj_coin_item, self._right_layout_trans, coin_item_view_cls)
  local coin_item = self:add_panel(coin_item_view_cls, obj, {auto_update = true, show_detail = true})
  return coin_item
end

return M
