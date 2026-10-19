local M = G.Class("TVShoppingGiftBoxPreview", G.UIWindow)
local base = G.UIWindow
local STAR_ANCHOR_ITEM_ID = 30200
local STAR_ANCHOR_MAX_COUNT = 10

local function _is_star_anchor_at_limit(item_id)
  return item_id == STAR_ANCHOR_ITEM_ID and (CsPacketModuleUtil.GetItemNum(STAR_ANCHOR_ITEM_ID) or 0) >= STAR_ANCHOR_MAX_COUNT
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/TVShopping/TVShoppingGiftBoxPreview"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._item_list = {}
end

function M:on_enable()
  base.on_enable(self)
  local content = self:get_extra_data()
  self._goods = content.goods
  self._page_id = content.page_id
  self._tab_type = content.tab_type
  self._buy_callback = content.buy_callback
  self._main_tab_id = content.main_tab_id or 1
  self:_refresh_ui()
end

function M:on_disable()
  base.on_disable(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:register_events()
  base.register_events(self)
end

function M:_add_ui_listener()
  if not is_null(self._btn_close) then
    self:bind_callback(self._btn_close, pack(self, M._on_close))
  end
  if not is_null(self._btn_mask) then
    self:bind_callback(self._btn_mask, pack(self, M._on_close))
  end
  if not is_null(self._btn_buy) then
    self:bind_callback(self._btn_buy, pack(self, M._on_buy))
  end
  if not is_null(self._btn_rule) then
    self:bind_callback(self._btn_rule, pack(self, M._on_rule))
  end
end

function M:_refresh_ui()
  if self._goods == nil then
    return
  end
  local item_id = self._goods.ItemConfigId
  local cfg = item_module:get_cfg_by_id(item_id)
  if not is_null(self._txt_title) and cfg then
    UIUtil.set_text(self._txt_title, cfg.name)
  end
  local box_cfg = ExcelDataUtil.get_value(typeof(BItemUseCfg), item_id)
  if box_cfg then
    self:_refresh_item_list(box_cfg)
  end
  if not is_null(self._btn_rule) then
    local intro_id = tvshop_module:get_sub_tab_introduction_id(self._page_id)
    UIUtil.set_active(self._btn_rule, intro_id ~= nil and 0 < intro_id)
    self._intro_id = intro_id
  end
  if CsShopModuleUtil.shopData:IsTVShopGoodsSoldOut(self._goods) or tvshop_module:is_item_sold_out(self._goods) then
    if not is_null(self._btn_buy) then
      self._btn_buy.interactable = false
    end
  elseif not is_null(self._btn_buy) then
    self._btn_buy.interactable = true
  end
end

function M:_refresh_item_list(box_cfg)
  local effect_params = tonumber(box_cfg.effectparams)
  if not effect_params or effect_params <= 0 then
    return
  end
  local all_table = ExcelDataUtil.get_table(typeof(BRandomPoolCfg)) or {}
  local pool_list = all_table[effect_params]
  if is_null(pool_list) then
    return
  end
  local cfg_lst = list_to_table(pool_list)
  table.sort(cfg_lst, function(a, b)
    local ra = item_module:get_cfg_by_id(a.configid)
    local rb = item_module:get_cfg_by_id(b.configid)
    return (ra and ra.rank or 0) > (rb and rb.rank or 0)
  end)
  if is_null(self._trans_item_content) or is_null(self._obj_item_template) then
    return
  end
  for i, cfg in ipairs(cfg_lst) do
    local obj = self._item_list[i]
    if obj == nil then
      obj = GameObject.Instantiate(self._obj_item_template, self._trans_item_content)
      self._item_list[i] = obj
    end
    UIUtil.set_active(obj, true)
    local cls = item_module:init_item_cls(obj.transform)
    if cls then
      item_module:set_item_cls(cls, cfg.configid, cfg.num, self:get_load_proxy())
    end
    local obtained = self:_is_item_obtained(cfg.configid)
    local check_obj = UIUtil.find_cmpt(obj.transform, "obj_check", "GameObject")
    if not_null(check_obj) then
      UIUtil.set_active(check_obj, obtained)
    end
  end
  for i = #cfg_lst + 1, #self._item_list do
    UIUtil.set_active(self._item_list[i], false)
  end
  UIUtil.set_active(self._obj_item_template, false)
end

function M:_is_item_obtained(item_id)
  if item_id == nil or item_id <= 0 then
    return false
  end
  if item_module:is_unlock_appearance_card(item_id) then
    return 0 < back_bag_module:get_item_num(item_id)
  end
  local codex_data = codex_module:get_data_by_id(item_id)
  if codex_data ~= nil then
    return codex_data.IsUnlocked or false
  end
  return 0 < back_bag_module:get_item_num(item_id)
end

function M:_on_close()
  self:close_self()
end

function M:_on_buy()
  if self._page_id and tvshop_module:is_purchase_blocked_by_time(self._page_id) then
    UIUtil.show_tips_by_text_id("TVShopping_item_off_shelf")
    self:close_self()
    EventCenter.Broadcast(EventID.UpdateTVShopping, "TVShopEventStateChanged")
    return
  end
  if self._goods then
    local raw_data = self._goods
    local item_id = raw_data.ItemConfigId
    if _is_star_anchor_at_limit(item_id) then
      UIUtil.show_tips_by_text_id("TVShopping_StarAnchor_LimitTip")
      return
    end
    local price = raw_data.Price or 0
    local main_tab_id = self._main_tab_id or 1
    local token_id = tvshop_module:get_main_tab_token_id(main_tab_id)
    local remain_coin = CsPacketModuleUtil.GetCoinCountById(token_id)
    if price > remain_coin then
      UIUtil.show_tips_by_text_id("TVShopping_no_money_tip")
      return
    end
    local max_num = tvshop_module:calc_max_buy_count(raw_data, remain_coin)
    local page_id = self._page_id
    local buy_callback = self._buy_callback
    local show_limit = tvshop_module:should_show_limit_count(raw_data.GoodsId)
    local remain_count = show_limit and tvshop_module:get_remaining_purchase_count(raw_data) or nil
    UIManagerInstance:open("UI/ConfirmView/CommonConfirmBuyItemDialog", {
      cfg_id = item_id,
      unit_price = price,
      max_num = max_num,
      remain_count = remain_count,
      coin_id = token_id,
      total_price_func = function(count)
        return tvshop_module:calc_total_buy_price(raw_data, count)
      end,
      buy_callback = function(count)
        if page_id and tvshop_module:is_purchase_blocked_by_time(page_id) then
          UIUtil.show_tips_by_text_id("TVShopping_item_off_shelf")
          EventCenter.Broadcast(EventID.UpdateTVShopping, "TVShopEventStateChanged")
          return
        end
        InputManagerIns:lock_input(input_lock_from.Common)
        CsShopModuleUtil.TVShopBuyReq(raw_data.GoodsId, count, function(rsp)
          InputManagerIns:unlock_input(input_lock_from.Common)
          if rsp and rsp.Retcode == 0 then
            self:close_self()
            if buy_callback then
              buy_callback(true, item_id)
            end
          end
        end)
      end
    })
  end
end

function M:_on_rule()
  if self._intro_id and self._intro_id > 0 then
    UIManagerInstance:open("IntroductionDialog", {
      cfg_id = self._intro_id
    })
  end
end

return M
