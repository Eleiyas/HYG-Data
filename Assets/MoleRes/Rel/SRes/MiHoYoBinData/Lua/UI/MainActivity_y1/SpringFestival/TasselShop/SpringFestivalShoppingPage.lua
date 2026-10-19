local M = G.Class("SpringFestivalShoppingPage", G.UIWindow)
local base = G.UIWindow
local SpringFestivalShoppingSubPanelType = {MainPanel = 1, ListPanel = 2}
local sub_panel_class_name = {
  [SpringFestivalShoppingSubPanelType.MainPanel] = {
    "UI/MainActivity_y1/SpringFestival/TasselShop/SpringFestivalShoppingMainPanel",
    "_main_panel_obj"
  },
  [SpringFestivalShoppingSubPanelType.ListPanel] = {
    "UI/MainActivity_y1/SpringFestival/TasselShop/SpringFestivalShoppingListPanel",
    "_list_panel_obj"
  }
}
local tab_cls = "UI/MainActivity_y1/SpringFestival/TasselShop/SpringFestivalShoppingTab"
local model_preview_view_cls = "UI/CommonUI/CommonModelPreviewView"
local ACTIVITY_END_DIALOG_TEXT_ID = "Activity_EndDialog_Desc"
local TAB_SUB_TITLE_TEXT_IDS = {
  "SpringFestival_Shopping_SubTitle_01",
  "SpringFestival_Shopping_SubTitle_02",
  "SpringFestival_Shopping_SubTitle_03"
}

local function _get_tassel_tab_icon(tassel_cfg)
  if tassel_cfg == nil then
    return ""
  end
  return tassel_cfg.icon or ""
end

local function _get_tassel_tab_name(tassel_cfg)
  if tassel_cfg == nil then
    return ""
  end
  return tassel_cfg.pagename or ""
end

local function _get_tassel_cfg_table()
  local tassel_cfg_type = CS and CS.miHoYo and CS.miHoYo.HYG and CS.miHoYo.HYG.ExcelData and CS.miHoYo.HYG.ExcelData.BTasselStoreCfg
  if tassel_cfg_type == nil then
    Logger.LogWarning("[SpringFestivalShoppingPage] BTasselStoreCfg type is nil")
    return nil
  end
  return ExcelDataUtil.get_table(typeof(tassel_cfg_type))
end

local function _is_gacha_box(item_id)
  if item_id == nil or item_id <= 0 then
    return false
  end
  local cfg = ExcelDataUtil.get_value(typeof(BItemUseCfg), item_id)
  return cfg ~= nil and cfg.effecttype == "ITEM_USE_EFFECT_OPEN_RANDOM_BOX"
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_ShoppingPage"
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_SpringFestival_Shopping01"
  self.config.type = EUIType.Page
  self.config.input_lock_type = input_lock_type.lock_all
  self._sub_panels = {}
  self._main_panel = nil
  self._list_panel = nil
  self._goods_list = {}
  self._display_goods_list = {}
  self._selected_goods = nil
  self._selected_goods_can_buy = true
  self._is_close = false
  self._model_preview_view = nil
  self._preview_item_id = 0
  self._preview_is_gacha = false
  self._cur_tab_id = 0
  self._reset_tab_on_next_refresh = false
  self._tab_configs = {}
  self._tab_items = {}
  self._selected_goods_id_by_tab = {}
  self._scroll_pos_by_tab = {}
  self._pending_restore_scroll_pos = nil
  self._shop_tracker_id_set = {}
  self._is_buy_requesting = false
  self._activity_end_dialog_shown = false
end

function M:on_create()
  base.on_create(self)
  self:_bind_page_callbacks()
  self:_init_sub_panels()
  self:_init_model_preview_view()
end

function M:on_enable()
  base.on_enable(self)
  self._activity_end_dialog_shown = false
  self._is_close = false
  self._is_buy_requesting = false
  self._cur_tab_id = 0
  self._reset_tab_on_next_refresh = true
  self._selected_goods_id_by_tab = {}
  self._scroll_pos_by_tab = {}
  self._pending_restore_scroll_pos = 1
  self:_refresh_all()
end

function M:on_disable()
  self:_end_buy_request()
  base.on_disable(self)
  self:_clear_select_preview()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaSpringFestivalTasselShopDataNotify, pack(self, M._on_shop_data_notify))
  self:add_evt_listener(EventID.LuaSpringFestivalTasselShopGoodsBuyRsp, pack(self, M._on_buy_rsp))
  self:add_evt_listener(EventID.TrackerUpdateNotify, pack(self, M._on_tracker_update_notify))
  self:add_evt_listener(EventID.OnUpdateConditionNotify, pack(self, M._on_update_condition_notify))
  self:add_evt_listener(EventID.OnActivityDataChanged, pack(self, M._on_activity_data_changed))
  self:add_evt_listener(EventID.OnActivityRemoved, pack(self, M._on_activity_removed))
end

function M:_on_activity_removed(activity_id)
  if activity_id ~= spring_festival_activity_module:get_main_activity_id() then
    return
  end
  self:_show_activity_end_dialog()
end

function M:_show_activity_end_dialog()
  if self._activity_end_dialog_shown then
    return
  end
  self._activity_end_dialog_shown = true
  local popup = UIUtil.get_confirm_popup()
  popup:set_style(ConfirmPopupStyle.ForcedPopup)
  popup:set_texts(UIUtil.get_text_by_id(ACTIVITY_END_DIALOG_TEXT_ID), UIUtil.get_text_by_id("Common_Accept"), nil, nil)
  popup:set_callbacks(function()
    self:_on_click_close()
  end)
  popup:show()
end

function M:bind_input_action()
  base.bind_input_action(self)
  if not is_null(self._btn_close) then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  end
end

function M:_bind_page_callbacks()
  if self._btn_close ~= nil then
    self:bind_callback(self._btn_close, pack(self, M._on_click_close))
  end
  if self._btn_show_info ~= nil then
    self:bind_callback(self._btn_show_info, pack(self, M._on_click_show_info))
  end
end

function M:_init_sub_panels()
  self._main_panel = self:_init_sub_panel(SpringFestivalShoppingSubPanelType.MainPanel, {
    on_buy_click = pack(self, M._on_click_buy),
    on_close_click = pack(self, M._on_click_close)
  })
  if self._main_panel ~= nil then
    self._main_panel:set_active(true)
  end
  if self._btn_buy ~= nil then
    self:bind_callback(self._btn_buy, pack(self, M._on_click_buy))
  end
  self._list_panel = self:_init_sub_panel(SpringFestivalShoppingSubPanelType.ListPanel, {
    on_select_goods = pack(self, M._on_select_goods)
  })
  if self._list_panel ~= nil then
    self._list_panel:set_active(true)
  end
end

function M:_init_model_preview_view()
  local host = self._trans_commonmodelpreviewview
  if host == nil then
    Logger.LogWarning("[SpringFestivalShoppingPage] _commonmodelpreviewview_obj missing")
    return
  end
  self._model_preview_view = self:add_panel(model_preview_view_cls, host)
end

function M:_init_tabs()
  if self._tab_list_binder == nil then
    return
  end
  if #self._tab_items > 0 then
    self:_set_cur_tab(self._cur_tab_id, false)
    return
  end
  for _, tab_cfg in ipairs(self._tab_configs or {}) do
    local tab_go = self._tab_list_binder:AddItem(0)
    if tab_go ~= nil then
      local tab_panel = self:add_panel(tab_cls, tab_go)
      if tab_panel ~= nil then
        tab_panel:refresh_view(tab_cfg.id, tab_cfg, pack(self, M._on_tab_toggle))
        table.insert(self._tab_items, tab_panel)
      end
    end
  end
  self:_set_cur_tab(self._cur_tab_id, false)
end

function M:_ensure_tab_configs()
  local goods_list = self._goods_list or {}
  local group_set = {}
  for _, goods in ipairs(goods_list) do
    local group_id = goods.group_id or 0
    if 0 < group_id then
      group_set[group_id] = true
    end
  end
  local tab_by_id = {}
  local tassel_cfgs = _get_tassel_cfg_table() or {}
  for _, tassel_cfg in ipairs(tassel_cfgs) do
    local group_id = tassel_cfg.storegroupid or 0
    if 0 < group_id and group_set[group_id] then
      local cfg = tab_by_id[group_id]
      if cfg == nil then
        cfg = {
          id = group_id,
          name = _get_tassel_tab_name(tassel_cfg),
          icon = _get_tassel_tab_icon(tassel_cfg),
          sort_index = tassel_cfg.id or 0
        }
        tab_by_id[group_id] = cfg
      else
        cfg.sort_index = math.min(cfg.sort_index or 0, tassel_cfg.id or 0)
        if not string.is_valid(cfg.name) then
          cfg.name = _get_tassel_tab_name(tassel_cfg)
        end
        if not string.is_valid(cfg.icon) then
          cfg.icon = _get_tassel_tab_icon(tassel_cfg)
        end
      end
    end
  end
  local dynamic_tabs = {}
  for _, cfg in pairs(tab_by_id) do
    table.insert(dynamic_tabs, cfg)
  end
  table.sort(dynamic_tabs, function(a, b)
    local ai = a.sort_index or 0
    local bi = b.sort_index or 0
    if ai ~= bi then
      return ai < bi
    end
    return (a.id or 0) < (b.id or 0)
  end)
  self._tab_configs = dynamic_tabs
  if self._cur_tab_id <= 0 then
    local first_tab = self._tab_configs[1]
    self._cur_tab_id = first_tab and (first_tab.id or 0) or 0
  end
end

function M:_on_tab_toggle(tab_id)
  if tab_id == nil or self._cur_tab_id == tab_id then
    return
  end
  self:_remember_current_tab_scroll_pos()
  self._pending_restore_scroll_pos = self._scroll_pos_by_tab[tab_id] or 1
  Logger.Log(string.format("[SpringFestivalShoppingPage] on_tab_toggle tab=%d", tab_id))
  self:_set_cur_tab(tab_id, true)
end

function M:_set_cur_tab(tab_id, refresh_now)
  self._cur_tab_id = tab_id or 0
  for _, tab in ipairs(self._tab_items) do
    if tab ~= nil then
      local is_on = tab:get_tab_id() == self._cur_tab_id
      tab:set_toggle_ison(is_on)
    end
  end
  if refresh_now then
    self:_refresh_all()
  end
end

function M:_get_tab_sub_title_text_id(tab_id)
  tab_id = tab_id or 0
  if tab_id <= 0 then
    return TAB_SUB_TITLE_TEXT_IDS[1]
  end
  for idx, cfg in ipairs(self._tab_configs or {}) do
    if (cfg.id or 0) == tab_id then
      return TAB_SUB_TITLE_TEXT_IDS[idx] or TAB_SUB_TITLE_TEXT_IDS[#TAB_SUB_TITLE_TEXT_IDS]
    end
  end
  return TAB_SUB_TITLE_TEXT_IDS[1]
end

function M:_get_goods_tab_id(goods)
  if goods == nil then
    return 0
  end
  return goods.group_id or 0
end

function M:_build_goods_sort_key(goods)
  goods = goods or {}
  local is_locked = goods.has_lock_condition == true and goods.is_locked == true
  local is_today_sold_out = goods.remain_buy_num ~= nil and goods.remain_buy_num == 0 and 0 < (goods.avail_count or 0)
  local is_sold_out = self:_is_reaction_card_unlocked(goods.item_id or 0)
  local priority = 0
  if is_sold_out then
    priority = 3
  elseif is_today_sold_out then
    priority = 2
  elseif is_locked then
    priority = 1
  end
  return {
    priority = priority,
    sort_index = goods.sort_index or 0,
    goods_id = goods.goods_id or 0
  }
end

local function _compare_goods_sort_key(a, b, sort_keys)
  local ka = sort_keys[a] or {}
  local kb = sort_keys[b] or {}
  local ap = ka.priority or 0
  local bp = kb.priority or 0
  if ap ~= bp then
    return ap < bp
  end
  local ai = ka.sort_index or 0
  local bi = kb.sort_index or 0
  if ai ~= bi then
    return ai < bi
  end
  local ag = ka.goods_id or a.goods_id or 0
  local bg = kb.goods_id or b.goods_id or 0
  return ag < bg
end

function M:_refresh_filtered_goods()
  self._display_goods_list = {}
  local sort_keys = {}
  for _, goods in ipairs(self._goods_list) do
    if self:_get_goods_tab_id(goods) == self._cur_tab_id then
      table.insert(self._display_goods_list, goods)
      sort_keys[goods] = self:_build_goods_sort_key(goods)
    end
  end
  table.sort(self._display_goods_list, function(a, b)
    return _compare_goods_sort_key(a, b, sort_keys)
  end)
  Logger.Log(string.format("[SpringFestivalShoppingPage] tab=%d filtered_goods_count=%d", self._cur_tab_id, #self._display_goods_list))
end

function M:_remember_selected_goods(tab_id, goods)
  tab_id = tab_id or 0
  if tab_id <= 0 then
    return
  end
  local goods_id = goods ~= nil and (goods.goods_id or 0) or 0
  if 0 < goods_id then
    self._selected_goods_id_by_tab[tab_id] = goods_id
  else
    self._selected_goods_id_by_tab[tab_id] = nil
  end
end

function M:_remember_current_tab_scroll_pos()
  local tab_id = self._cur_tab_id or 0
  if tab_id <= 0 or self._list_panel == nil or self._list_panel.get_scroll_position == nil then
    return
  end
  local pos = self._list_panel:get_scroll_position()
  if pos ~= nil then
    self._scroll_pos_by_tab[tab_id] = pos
  end
end

function M:_init_sub_panel(panel_type, extra_data)
  local cfg = sub_panel_class_name[panel_type]
  if cfg == nil then
    return nil
  end
  local panel_cls = cfg[1]
  local panel_trans = self[cfg[2]]
  if panel_trans == nil then
    Logger.LogWarning("[SpringFestivalShoppingPage] panel trans missing: " .. tostring(cfg[2]))
    return nil
  end
  local panel = self:add_panel(panel_cls, panel_trans, extra_data)
  self._sub_panels[panel_type] = panel
  return panel
end

function M:_on_click_show_info()
  if self._selected_goods == nil then
    return
  end
  local item_id = self._selected_goods.item_id or 0
  if item_id <= 0 then
    return
  end
  if _is_gacha_box(item_id) then
    self:_on_gacha_detail_btn()
    return
  end
  item_module:open_item_info_dialog(item_id, 0)
end

function M:_on_gacha_detail_btn()
  if self._selected_goods == nil then
    return
  end
  local box_id = self._selected_goods.item_id or 0
  if box_id <= 0 then
    return
  end
  UIManagerInstance:open("UI/GachaGiftBox/GachaGiftBoxDialog", {box_id = box_id})
end

function M:_on_click_close()
  if self._is_close then
    return
  end
  self._is_close = true
  self:_end_buy_request()
  self:_clear_select_preview()
  UIManagerInstance:close_page_with_dialogs_above(self)
end

function M:exit_anim_call_back()
  base.exit_anim_call_back(self)
  if self._is_close then
    EventCenter.Broadcast(EventID.LuaSpringFestivalTasselShopUserClose)
  end
end

function M:_begin_buy_request()
  if self._is_buy_requesting then
    return false
  end
  self._is_buy_requesting = true
  InputManagerIns:lock_input(input_lock_from.Common)
  return true
end

function M:_end_buy_request()
  if not self._is_buy_requesting then
    return
  end
  self._is_buy_requesting = false
  InputManagerIns:unlock_input(input_lock_from.Common)
end

function M:_on_click_buy()
  if self._is_buy_requesting then
    return
  end
  local selected = self._selected_goods
  if selected == nil or (selected.goods_id or 0) <= 0 then
    UIUtil.show_tips_by_text_id("TVShopping_no_goods")
    return
  end
  if self._selected_goods_can_buy == false then
    UIUtil.show_tips_by_text_id("TVShopping_limit_count_tip")
    return
  end
  local remain_buy_num = selected.remain_buy_num
  if remain_buy_num ~= nil and 0 <= remain_buy_num and remain_buy_num <= 0 then
    UIUtil.show_tips_by_text_id("TVShopping_limit_count_tip")
    return
  end
  local money_id = selected.money_id or 0
  local unit_price = selected.price or 0
  local item_id = selected.item_id or 0
  if 0 < money_id then
    local cur_money = back_bag_module:get_coin_or_item_num(money_id)
    if 0 < unit_price and unit_price > cur_money then
      UIUtil.show_tips_by_text_id("SpringFestival_Shopping_NoEnough")
      return
    end
    local max_num
    if 0 < unit_price then
      max_num = math.floor(cur_money / unit_price)
    end
    if remain_buy_num ~= nil and 0 <= remain_buy_num then
      max_num = max_num ~= nil and math.min(max_num, remain_buy_num) or remain_buy_num
    end
    local limit_per_purchase = math.max(0, math.floor(tonumber(selected.limit_per_purchase) or 0))
    if 0 < limit_per_purchase then
      max_num = max_num ~= nil and math.min(max_num, limit_per_purchase) or limit_per_purchase
    end
    max_num = math.max(1, max_num or 1)
    local is_buy_submitted = false
    UIManagerInstance:open("UI/ConfirmView/CommonConfirmBuyItemDialog", {
      cfg_id = item_id,
      unit_price = unit_price,
      max_num = max_num,
      remain_count = remain_buy_num ~= nil and 0 <= remain_buy_num and remain_buy_num or nil,
      coin_id = money_id,
      buy_callback = function(count)
        if is_buy_submitted then
          return false
        end
        if not self:_begin_buy_request() then
          return false
        end
        is_buy_submitted = true
        spring_festival_tassel_shop_module:send_tassel_shop_buy_req(selected.goods_id, count)
        return true
      end
    })
    return
  end
  if not self:_begin_buy_request() then
    return
  end
  spring_festival_tassel_shop_module:send_tassel_shop_buy_req(selected.goods_id, 1)
end

function M:_on_shop_data_notify()
  self:_refresh_all()
end

function M:_on_buy_rsp(retcode)
  self:_end_buy_request()
  if (retcode or -1) ~= 0 then
    UIUtil.show_tips("购买失败")
    return
  end
end

function M:_on_tracker_update_notify(tracker_id)
  if self._is_close then
    return
  end
  tracker_id = tonumber(tracker_id) or 0
  if 0 < tracker_id and self._shop_tracker_id_set ~= nil and self._shop_tracker_id_set[tracker_id] ~= true then
    return
  end
  Logger.Log(string.format("[SpringFestivalShoppingPage] tracker update notify tracker_id=%s, refresh", tostring(tracker_id)))
  self:_refresh_all()
end

function M:_on_update_condition_notify(condition_guid)
  if self._is_close then
    return
  end
  if condition_guid == nil then
    return
  end
  local tracker_data = CsTrackerModuleUtil.GetTrackerDataByConditionId(condition_guid)
  local tracker_id = tracker_data and (tonumber(tracker_data.Id) or 0) or 0
  Logger.Log(string.format("[SpringFestivalShoppingPage] condition notify condition_guid=%s, tracker_id=%s", tostring(condition_guid), tostring(tracker_id)))
  if tracker_id <= 0 then
    return
  end
  self:_on_tracker_update_notify(tracker_id)
end

function M:_on_activity_data_changed(activity_id)
  if self._is_close then
    return
  end
  Logger.Log(string.format("[SpringFestivalShoppingPage] activity data changed activity_id=%s, refresh", tostring(activity_id)))
  self:_refresh_all()
end

function M:_rebuild_shop_tracker_id_set()
  local tracker_id_set = {}
  for _, goods in ipairs(self._goods_list or {}) do
    local goods_id = goods.goods_id or 0
    if 0 < goods_id then
      local tracker_ids = spring_festival_tassel_shop_module:get_goods_lock_tracker_ids(goods_id) or {}
      for _, tracker_id in ipairs(tracker_ids) do
        local parsed_tracker_id = tonumber(tracker_id) or 0
        if 0 < parsed_tracker_id then
          tracker_id_set[parsed_tracker_id] = true
        end
      end
    end
  end
  self._shop_tracker_id_set = tracker_id_set
end

function M:_refresh_all()
  self._goods_list = spring_festival_tassel_shop_module:get_tassel_shop_goods_list() or {}
  self:_rebuild_shop_tracker_id_set()
  Logger.Log(string.format("[SpringFestivalShoppingPage] refresh goods_count=%d", #self._goods_list))
  self:_ensure_tab_configs()
  if self._cur_tab_id <= 0 then
    local first_tab = self._tab_configs and self._tab_configs[1] or nil
    self._cur_tab_id = first_tab and (first_tab.id or 0) or 0
  end
  if 0 < #self._tab_items and #self._tab_items == #(self._tab_configs or {}) then
    for i, tab_cfg in ipairs(self._tab_configs or {}) do
      local tab_panel = self._tab_items[i]
      if tab_panel ~= nil then
        tab_panel:refresh_view(tab_cfg.id, tab_cfg, pack(self, M._on_tab_toggle))
      end
    end
  elseif 0 >= #self._tab_items then
    self:_init_tabs()
  else
    for _, tab in ipairs(self._tab_items) do
      if tab ~= nil and tab.game_obj ~= nil then
        UIUtil.destroy_go(tab.game_obj)
      end
    end
    self._tab_items = {}
    self:_init_tabs()
  end
  if self._reset_tab_on_next_refresh == true then
    local first_tab = self._tab_configs and self._tab_configs[1] or nil
    self._cur_tab_id = first_tab and (first_tab.id or 0) or 0
    self:_set_cur_tab(self._cur_tab_id, false)
    self._reset_tab_on_next_refresh = false
  end
  local has_cur_tab = false
  for _, cfg in ipairs(self._tab_configs or {}) do
    if (cfg.id or 0) == self._cur_tab_id then
      has_cur_tab = true
      break
    end
  end
  if not has_cur_tab then
    local first_tab = self._tab_configs and self._tab_configs[1] or nil
    self._cur_tab_id = first_tab and (first_tab.id or 0) or 0
    self:_set_cur_tab(self._cur_tab_id, false)
  end
  self:_refresh_filtered_goods()
  self:_refresh_selected_goods_ref(self._display_goods_list)
  local selected_goods_id = self._selected_goods ~= nil and (self._selected_goods.goods_id or 0) or 0
  if self._list_panel ~= nil then
    self._list_panel:refresh_list(self._display_goods_list, selected_goods_id, self._pending_restore_scroll_pos)
    self._pending_restore_scroll_pos = nil
  else
    self._pending_restore_scroll_pos = nil
    Logger.LogWarning("[SpringFestivalShoppingPage] _list_panel is nil")
  end
  self:_refresh_selected_view()
end

function M:_refresh_selected_goods_ref(goods_list)
  goods_list = goods_list or {}
  local tab_id = self._cur_tab_id or 0
  local remembered_goods_id = self._selected_goods_id_by_tab[tab_id] or 0
  if 0 < remembered_goods_id then
    for _, goods in ipairs(goods_list) do
      if (goods.goods_id or 0) == remembered_goods_id then
        self._selected_goods = goods
        self:_remember_selected_goods(tab_id, goods)
        return
      end
    end
  end
  if self._selected_goods ~= nil then
    local selected_id = self._selected_goods.goods_id or 0
    for _, goods in ipairs(goods_list) do
      if (goods.goods_id or 0) == selected_id then
        self._selected_goods = goods
        self:_remember_selected_goods(tab_id, goods)
        return
      end
    end
  end
  self._selected_goods = goods_list[1]
  self:_remember_selected_goods(tab_id, self._selected_goods)
end

function M:_on_select_goods(goods)
  self._selected_goods = goods
  self:_remember_selected_goods(self._cur_tab_id, goods)
  self:_refresh_selected_view()
  if self._list_panel ~= nil then
    self._list_panel:refresh_selected(goods ~= nil and (goods.goods_id or 0) or 0)
  end
end

function M:_refresh_selected_view()
  self:_refresh_right_info(self._selected_goods)
  local page_title_text_id = self:_get_tab_sub_title_text_id(self._cur_tab_id)
  if self._main_panel ~= nil then
    self._main_panel:refresh_selected(self._selected_goods, self._selected_goods_can_buy, page_title_text_id)
  end
  if self._list_panel ~= nil and self._list_panel.refresh_notice_by_goods ~= nil then
    self._list_panel:refresh_notice_by_goods(self._selected_goods)
  end
  self:_refresh_model_preview(self._selected_goods)
end

function M:_refresh_right_info(goods)
  local has_goods = goods ~= nil and 0 < (goods.goods_id or 0)
  local item_id = has_goods and (goods.item_id or 0) or 0
  local has_valid_item = has_goods and 0 < item_id
  if self._obj_right ~= nil then
    UIUtil.set_active(self._obj_right, has_goods)
  end
  if self._btn_show_info ~= nil then
    UIUtil.set_active(self._btn_show_info, has_goods)
  end
  if self._text_item_name ~= nil then
    if has_valid_item then
      local cfg = item_module:get_cfg_by_id(item_id)
      if cfg ~= nil then
        UIUtil.set_active(self._text_item_name, true)
        UIUtil.set_text(self._text_item_name, cfg.name)
      else
        UIUtil.set_active(self._text_item_name, false)
      end
    else
      UIUtil.set_active(self._text_item_name, false)
    end
  end
  if self._text_own ~= nil then
    UIUtil.set_active(self._text_own, has_valid_item)
    local own_num = 0 < item_id and (CsPacketModuleUtil.GetItemNum(item_id) or 0) or 0
    if self:_is_reaction_card_unlocked(item_id) then
      own_num = 1
    end
    UIUtil.set_text_by_id(self._text_own, "SpringFestival_Shopping_Item_Own", tostring(own_num))
  end
  self._selected_goods_can_buy = self:_calc_goods_can_buy(goods)
  self:_refresh_lock_state(goods)
  self:_refresh_size_txt(item_id)
end

function M:_refresh_lock_state(goods)
  local has_goods = goods ~= nil and 0 < (goods.goods_id or 0)
  local is_locked = has_goods and goods.has_lock_condition == true and goods.is_locked == true
  if self._ui_state_group_Soldout ~= nil then
    self._ui_state_group_Soldout:SetState(is_locked and 1 or 0)
  end
  if self._text_cantexchange ~= nil then
    if is_locked then
      local remain_seconds = goods.lock_remain_seconds or 0
      local target = goods.lock_target or 0
      local current = goods.lock_current or 0
      local time_text = UIUtil.format_left_time(remain_seconds)
      local text = UIUtil.get_text_by_id("SpringFestival_Shopping_CantExchange_01", time_text, spring_festival_exchange_module:get_token_icon_path(), current, target)
      Logger.Log(string.format("[SpringFestivalShoppingPage] path=%s", spring_festival_exchange_module:get_token_icon_path()))
      UIUtil.set_text_with_dynamic_sprite(self._text_cantexchange, text)
    else
      UIUtil.set_text(self._text_cantexchange, "")
    end
  end
  if self._btn_buy ~= nil then
    self._btn_buy.interactable = not is_locked and self._selected_goods_can_buy == true
  end
end

function M:_calc_goods_can_buy(goods)
  if goods == nil then
    return false
  end
  if goods.has_lock_condition == true and goods.is_locked == true then
    return false
  end
  local remain_buy_num = goods.remain_buy_num
  if remain_buy_num ~= nil and 0 <= remain_buy_num and remain_buy_num <= 0 then
    return false
  end
  local item_id = goods.item_id or 0
  if self:_is_reaction_card_unlocked(item_id) then
    return false
  end
  return true
end

function M:_is_reaction_card_unlocked(item_id)
  if item_id <= 0 or not item_module:is_reaction_card(item_id) then
    return false
  end
  local reaction_card_cfg = ExcelDataUtil.get_value(typeof(BReactionCardCfg), item_id)
  if reaction_card_cfg == nil then
    return false
  end
  local reaction_id = reaction_card_cfg.unlockreactionid or 0
  if reaction_id <= 0 then
    return false
  end
  return CsGameplayUtilitiesReactionUtil.CheckReactionUnlock(reaction_id)
end

function M:_refresh_size_txt(item_id)
  local item_cfg = 0 < item_id and item_module:get_cfg_by_id(item_id) or nil
  local entity_cfg = item_cfg and item_cfg.idCfg and item_cfg.idCfg.entityCfg
  if item_cfg and item_cfg.bagtype == 2 and entity_cfg then
    local size_x = (entity_cfg.sizex or 0) / 2
    local size_z = (entity_cfg.sizez or 0) / 2
    if self._obj_info_size ~= nil then
      UIUtil.set_active(self._obj_info_size, true)
    end
    if self._txt_size ~= nil then
      UIUtil.set_text(self._txt_size, string.format(UIUtil.get_text_by_id("multiplication_sign_fur"), size_x, size_z))
    end
  elseif self._obj_info_size ~= nil then
    UIUtil.set_active(self._obj_info_size, false)
  end
end

function M:_refresh_model_preview(goods)
  if self._model_preview_view == nil then
    return
  end
  local item_id = goods ~= nil and (goods.item_id or 0) or 0
  if item_id <= 0 then
    self:_clear_select_preview()
    return
  end
  local is_gacha = _is_gacha_box(item_id)
  local item_changed = self._preview_item_id ~= item_id
  local gacha_changed = self._preview_is_gacha ~= is_gacha
  local is_showing = self._model_preview_view.is_showing ~= nil and self._model_preview_view:is_showing() or false
  if not item_changed and not gacha_changed and is_showing then
    return
  end
  if gacha_changed or not is_showing then
    self._model_preview_view:set_data({
      item_id = item_id,
      load_proxy = self:get_load_proxy(),
      show_gacha_detail = false
    })
  else
    self._model_preview_view:show_item(item_id, self:get_load_proxy())
  end
  self._preview_item_id = item_id
  self._preview_is_gacha = is_gacha
end

function M:_clear_select_preview()
  if self._model_preview_view ~= nil then
    self._model_preview_view:hide_preview()
  end
  self._preview_item_id = 0
  self._preview_is_gacha = false
end

return M
