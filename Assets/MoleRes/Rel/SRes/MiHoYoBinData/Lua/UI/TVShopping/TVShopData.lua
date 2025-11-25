tvshop_module = tvshop_module or {}

function tvshop_module:get_tvshop_data()
  self:update_tvshop_data()
  return self._server_data
end

function tvshop_module:update_tvshop_data()
  self._server_data = CsShopModuleUtil.shopData.tvShoppingData
  self._page_data = nil
end

function tvshop_module:update_page_data(tab_type)
  local server_data = self:get_tvshop_data()
  local page_list = {}
  for _, v in pairs(array_to_table(server_data.Goods.TabsList)) do
    if v.TabsType == tab_type then
      page_list = v.PageList
      break
    end
  end
  self._page_data = {}
  local DetailOneofCase = TVShopPage.DetailOneofCase
  for _, v in ipairs(array_to_table(page_list)) do
    local page = null
    if v.DetailCase == DetailOneofCase.DailyPage then
      page = v.DailyPage
    elseif v.DetailCase == DetailOneofCase.FixedPage then
      page = v.FixedPage
    elseif v.DetailCase == DetailOneofCase.ObtainedPage then
      page = v.ObtainedPage
    elseif v.DetailCase == DetailOneofCase.DirectBuyPage then
      page = v.DirectBuyPage
    end
    if v.PageId ~= 4 then
      self._page_data[v.PageId] = {
        page_type = v.DetailCase,
        page = page
      }
    end
  end
end

function tvshop_module:get_all_page_id(tab_type)
  self:update_page_data(tab_type)
  local page_ids = {}
  for k, v in pairs(self._page_data) do
    table.insert(page_ids, {
      type = v.page_type,
      id = k
    })
  end
  table.sort(page_ids, function(a, b)
    return a.id < b.id
  end)
  return page_ids
end

function tvshop_module:get_sub_page_data(tab_type, page_id)
  self:update_page_data(tab_type)
  return self._page_data[page_id]
end

function tvshop_module:get_cart_page_data(tab_type)
  local server_data = self:get_tvshop_data()
  local cart
  for _, v in pairs(array_to_table(server_data.Carts)) do
    if v.TabsType == tab_type then
      cart = v
      break
    end
  end
  return cart
end

function tvshop_module:get_earliest_package_data()
  local server_data = self:get_tvshop_data()
  local newest_package_data
  for _, v in pairs(array_to_table(server_data.PackageList)) do
    if newest_package_data == nil then
      newest_package_data = v
    elseif newest_package_data.OrderTime > v.OrderTime then
      newest_package_data = v
    end
  end
  return newest_package_data
end

function tvshop_module:get_car_modify_data()
  if self._car_modify_cfgs == nil then
    self._car_modify_cfgs = dic_to_table(LocalDataUtil.get_dic_table(typeof(CS.BCarCustomizationOptionCfg)))
  end
  return self._car_modify_cfgs
end

function tvshop_module:get_car_can_modify_data()
  if self._car_can_modify_cfgs == nil then
    self._car_can_modify_cfgs = dic_to_table(LocalDataUtil.get_dic_table(typeof(CS.BCarCustomizationCfg)))
  end
  return self._car_can_modify_cfgs
end

function tvshop_module:get_car_data()
  if self._car_cfgs == nil then
    self._car_cfgs = dic_to_table(LocalDataUtil.get_dic_table(typeof(CS.BCarCfg)))
  end
  return self._car_cfgs
end

function tvshop_module:get_favorite_goods()
  local server_data = self:get_tvshop_data()
  return array_to_table(server_data.Favorite.GoodsList)
end

function tvshop_module:get_membership()
  local server_data = self:get_tvshop_data()
  return server_data.Membership
end

function tvshop_module:get_vip_lvl_details(lvl)
  local ship_cfgs = self:get_ship_cfgs()
  local cur_cfg = ship_cfgs[lvl]
  if cur_cfg ~= nil then
    return cur_cfg.desc
  end
  return ""
end

function tvshop_module:get_ship_cfgs()
  if self._ship_cfgs == nil then
    self._ship_cfgs = dic_to_table(CsUIUtil.GetTable(typeof(CS.BTVShopMembershipCfg)))
  end
  return self._ship_cfgs
end

function tvshop_module:get_page_cfgs()
  if self._page_cfgs == nil then
    self._page_cfgs = dic_to_table(CsUIUtil.GetTable(typeof(CS.BTVShopPageCfg)))
  end
  return self._page_cfgs
end

function tvshop_module:show_btn_like(tab_type, page_id)
  if tab_type == TVShopTabsType.TvShopTabsGold then
    return false
  end
  return true
end

function tvshop_module:show_tag_new(page_id)
  local page_cfgs = self:get_page_cfgs()
  local cfg = page_cfgs[page_id]
  if cfg ~= nil and (cfg.pagetype == "TV_SHOP_PAGE_DAILY" or cfg.pagetype == "TV_SHOP_PAGE_TOP_ADS") then
    return true
  end
  return false
end

function tvshop_module:get_consecutive_login_days()
  local server_data = self:get_tvshop_data()
  return server_data.ConsecutiveLoginDays
end

function tvshop_module:record_new_goods(goods_id)
  if self._new_goods_id == nil then
    self._new_goods_id = {}
  end
  self._new_goods_id[goods_id] = true
end

function tvshop_module:clear_new_goods()
  if self._new_goods_id == nil then
    return
  end
  local req_goods_id = {}
  for k, v in pairs(self._new_goods_id) do
    table.insert(req_goods_id, k)
  end
  CsShopModuleUtil.TVShopGoodsReadReq(req_goods_id)
  self._new_goods_id = nil
end

function tvshop_module:check_enough_coin(tab_type, need_num)
  local remain_coin = 0
  if tab_type == TVShopTabsType.TvShopTabsLuomi then
    remain_coin = CsPacketModuleUtil.GetCoinCountById(VirtualItemType.VirtualItemNook.value__)
  else
    remain_coin = CsPacketModuleUtil.GetCoinCountById(VirtualItemType.VirtualItemGold.value__)
  end
  return need_num <= remain_coin
end

function tvshop_module:tab_has_new_item(tab_type)
  local page_ids = tvshop_module:get_all_page_id(tab_type)
  for _, v in ipairs(page_ids) do
    if self:page_has_new_item(tab_type, v.id) then
      return true
    end
  end
  return false
end

function tvshop_module:page_has_new_item(tab_type, page_id)
  if self:show_tag_new(page_id) == false then
    return false
  end
  local page_data = tvshop_module:get_sub_page_data(tab_type, page_id)
  local goods = array_to_table(page_data.page.GoodsList)
  for _, good in ipairs(goods) do
    if good.TvShopGoods and good.TvShopGoods.IsNew then
      return true
    end
  end
  return false
end

return tvshop_module
