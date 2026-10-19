local M = G.Class("CurioEmporiumEntranceHotSalePanel", G.CurioEmporiumEntrancePanelBase)
local base = G.CurioEmporiumEntrancePanelBase
local group_cls = "UI/CurioEmporium/EntrancePage/Panel/CurioEmporiumEntranceHotSaleGroup"
local model_preview_view_cls = "UI/CommonUI/CommonModelPreviewView"
local HOT_SALE_TYPE = 3
local QUERY_TIMEOUT = 15

local function collect_gift_id_set(groups)
  local ids = {}
  local count = 0
  for _, group in ipairs(groups or {}) do
    for _, cfg in ipairs(group.cfgs) do
      if not ids[cfg.id] then
        ids[cfg.id] = true
        count = count + 1
      end
    end
  end
  return {ids = ids, count = count}
end

local function is_same_gift_id_set(id_set, groups)
  if not id_set then
    return false
  end
  local other = collect_gift_id_set(groups)
  if id_set.count ~= other.count then
    return false
  end
  for id in pairs(other.ids) do
    if not id_set.ids[id] then
      return false
    end
  end
  return true
end

local quality_state = {
  Grey = 0,
  Green = 1,
  Purple = 2,
  Gold = 3
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CurioEmporium/CurioEmporiumDirectSalePanel"
end

function M:on_create()
  self._group_pool = {}
  self._candidate_gift_ids = nil
  self._next_gift_time_change = nil
  self._rebuild_check_timer = nil
  self._selected_cfg = nil
  self._selected_sdk_goods_data = nil
  self._selected_server_goods_data = nil
  self._goods_dict = nil
  self._suit_preview = nil
  self._is_suit_gift = false
  self._single_item_id = nil
  base.on_create(self)
  self:_add_btn_listener()
  self._model_preview_view = self:add_panel(model_preview_view_cls, self._obj_common_model_group)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_resume_from_sub_page()
  if self._selected_cfg and self._is_suit_gift then
    CsCoroutineManagerUtil.InvokeAfterFrames(2, function()
      if is_null(self.game_obj) then
        return
      end
      self:_show_suit_preview(curio_emporium_module:split_suit_gift_items(self._selected_cfg.id))
    end)
  end
end

function M:on_disable()
  base.on_disable(self)
  if self._query_timer then
    self._query_timer = nil
    EventCenter.Broadcast(EventID.luaClosePayWaitPage, nil)
  end
  if not self._skip_disable_preview_cleanup then
    self:_hide_suit_preview()
  end
  self._skip_disable_preview_cleanup = false
  if self._model_preview_view then
    self._model_preview_view:hide_preview()
  end
end

function M:on_destroy()
  base.on_destroy(self)
  if self._suit_preview then
    self._suit_preview:destroy()
    self._suit_preview = nil
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaOnStoreGoodsInfoRefreshed, pack(self, M._on_store_goods_info_refreshed))
  self:add_evt_listener(EventID.LuaOnOpenConditionNotify, pack(self, M._on_open_condition_notify))
end

function M:_on_open_condition_notify(condition_id)
  if is_null(self.game_obj) or not self:is_in_show_state() then
    return
  end
  if not curio_emporium_module:is_gift_unlock_condition(HOT_SALE_TYPE, condition_id) then
    return
  end
  self:_try_rebuild_gift_list()
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:_on_store_goods_info_refreshed(config_id)
  if is_null(self.game_obj) or not self:is_in_show_state() then
    return
  end
  if self._query_timer then
    return
  end
  if not self:_is_displayed_goods(config_id) then
    return
  end
  self:_refresh_groups_keep_selection()
end

function M:_is_displayed_goods(config_id)
  for _, group in ipairs(self._grouped_cfgs or {}) do
    for _, cfg in ipairs(group.cfgs) do
      if curio_emporium_module:is_refreshed_goods_match(cfg, config_id) then
        return true
      end
    end
  end
  return false
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self._query_timer then
    self._query_timer = self._query_timer + deltaTime
    if self._query_timer >= QUERY_TIMEOUT then
      self:_on_query_finish(false, nil)
    end
  end
  if self._next_gift_time_change then
    self._rebuild_check_timer = (self._rebuild_check_timer or 0) + deltaTime
    if self._rebuild_check_timer >= 1 then
      self._rebuild_check_timer = 0
      if TimeUtil.ServerUtcTimeSeconds >= self._next_gift_time_change then
        self:_try_rebuild_gift_list()
      end
    end
  end
  if self._selected_cfg then
    self._time_refresh_timer = (self._time_refresh_timer or 0) + deltaTime
    if 1 <= self._time_refresh_timer then
      self._time_refresh_timer = self._time_refresh_timer - 1
      self:_refresh_time()
      self:_refresh_pass_state()
    end
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_btn_listener()
  self:bind_callback(self._btn_buy, pack(self, M._on_buy_click))
  self:bind_callback(self._btn_info, pack(self, M._on_info_click))
  self:bind_callback(self._btn_look, pack(self, M._on_look_click))
  if not_null(self._trans_suit_touch_rect) then
    self.binder:BindViewCallback(self._trans_suit_touch_rect, EventTriggerType.PointerDown, pack(self, M._on_suit_pointer_down))
    self.binder:BindViewCallback(self._trans_suit_touch_rect, EventTriggerType.Drag, pack(self, M._on_suit_drag))
    self.binder:BindViewCallback(self._trans_suit_touch_rect, EventTriggerType.PointerUp, pack(self, M._on_suit_pointer_up))
  end
end

function M:_set_suit_touch_active(active)
  if not_null(self._trans_suit_touch_rect) then
    UIUtil.set_active(self._trans_suit_touch_rect, active)
  end
end

function M:_on_suit_pointer_down(evt)
  if self._suit_preview then
    self._suit_preview:on_begin_drag(evt)
  end
end

function M:_on_suit_drag(evt)
  if self._suit_preview then
    self._suit_preview:on_drag(evt)
  end
end

function M:_on_suit_pointer_up(evt)
  if self._suit_preview then
    self._suit_preview:on_end_drag(evt)
  end
end

function M:refresh()
  base.refresh(self)
  self._grouped_cfgs = self:_get_candidate_groups()
  self._candidate_gift_ids = collect_gift_id_set(self._grouped_cfgs)
  self._next_gift_time_change = curio_emporium_module:get_next_gift_time_change(HOT_SALE_TYPE)
  if #self._grouped_cfgs <= 0 then
    self._goods_dict = nil
    UIUtil.set_active(self._obj_root, false)
    self:_clear_selection()
    self:_refresh_groups(nil)
    return
  end
  self:_collect_goods_ids()
  if 0 < #self._goods_id_list then
    self._query_timer = 0
    EventCenter.Broadcast(EventID.luaOpenPayWaitPage, nil)
    UIUtil.set_active(self._obj_root, false)
    self:_hide_suit_preview()
    curio_emporium_module:query_hot_sale_goods(pack(self, M._on_query_finish))
  else
    self:_refresh_groups(nil)
  end
end

function M:_collect_goods_ids()
  self._goods_id_list = {}
  for _, group in ipairs(self._grouped_cfgs) do
    for _, cfg in ipairs(group.cfgs) do
      if not cfg:goodsid_is_empty() then
        table.insert(self._goods_id_list, cfg.goodsid)
      end
    end
  end
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
  self._goods_dict = success and goods_dict or nil
  self._grouped_cfgs = self:_filter_undisplayable_groups(self._grouped_cfgs, self._goods_dict)
  local has_any = #self._grouped_cfgs > 0
  UIUtil.set_active(self._obj_root, has_any)
  self:_sort_grouped_cfgs_by_sold_out(self._goods_dict)
  self:_refresh_groups(self._goods_dict)
  if has_any then
    self:_select_first_item()
  end
end

function M:_get_candidate_groups()
  local result = {}
  local groups = curio_emporium_module:get_gift_cfg_grouped_by_tag(HOT_SALE_TYPE)
  for _, group in ipairs(groups or {}) do
    local cfgs = {}
    for _, cfg in ipairs(group.cfgs) do
      if not curio_emporium_module:is_gift_blocked_by_tag_emergency_switch(cfg) then
        table.insert(cfgs, cfg)
      end
    end
    if 0 < #cfgs then
      table.insert(result, {
        tag = group.tag,
        cfgs = cfgs
      })
    end
  end
  return result
end

function M:_filter_undisplayable_groups(groups, goods_dict)
  local result = {}
  for _, group in ipairs(groups or {}) do
    local cfgs = {}
    for _, cfg in ipairs(group.cfgs) do
      if curio_emporium_module:is_goods_displayable(cfg, goods_dict) then
        table.insert(cfgs, cfg)
      end
    end
    if 0 < #cfgs then
      table.insert(result, {
        tag = group.tag,
        cfgs = cfgs
      })
    end
  end
  return result
end

function M:_try_rebuild_gift_list()
  if self._query_timer then
    return
  end
  self._next_gift_time_change = curio_emporium_module:get_next_gift_time_change(HOT_SALE_TYPE)
  local candidates = self:_get_candidate_groups()
  if is_same_gift_id_set(self._candidate_gift_ids, candidates) then
    return
  end
  if not self._goods_dict then
    self:refresh()
    return
  end
  self._candidate_gift_ids = collect_gift_id_set(candidates)
  self._grouped_cfgs = self:_filter_undisplayable_groups(candidates, self._goods_dict)
  local has_any = #self._grouped_cfgs > 0
  UIUtil.set_active(self._obj_root, has_any)
  if not has_any then
    self:_clear_selection()
  end
  self:_refresh_groups_keep_selection()
end

function M:_clear_selection()
  if self._selected_item then
    self._selected_item:set_select(false)
    self._selected_item = nil
  end
  self._selected_cfg = nil
  self._selected_sdk_goods_data = nil
  self._selected_server_goods_data = nil
  self._single_item_id = nil
  self._is_suit_gift = false
  self:_hide_suit_preview()
  if self._model_preview_view then
    self._model_preview_view:hide_preview()
  end
end

function M:_refresh_groups(goods_dict)
  for i, group_data in ipairs(self._grouped_cfgs) do
    local group = self._group_pool[i]
    if not group then
      local obj = self._good_list_item_binder:AddItem(0)
      if not_null(obj) then
        group = self:add_panel(group_cls, obj)
        self._group_pool[i] = group
      end
    end
    if group then
      group:refresh(group_data.tag, group_data.cfgs, goods_dict, pack(self, M._on_item_selected))
      UIUtil.set_active(group.game_obj, true)
    end
  end
  for i = #self._grouped_cfgs + 1, #self._group_pool do
    local group = self._group_pool[i]
    if group then
      UIUtil.set_active(group.game_obj, false)
    end
  end
end

function M:_select_first_item()
  if not self._grouped_cfgs or #self._grouped_cfgs <= 0 then
    return
  end
  local first_group = self._grouped_cfgs[1]
  if first_group and first_group.cfgs and 0 < #first_group.cfgs then
    local first_cfg = first_group.cfgs[1]
    local first_item
    local group = self._group_pool[1]
    if group and group._item_pool then
      first_item = group._item_pool[1]
    end
    self:_on_item_selected(first_cfg, first_item)
  end
end

function M:_is_cfg_sold_out(cfg, goods_dict)
  if not cfg then
    return false
  end
  if not cfg:goodsid_is_empty() then
    local goods_data = curio_emporium_module:get_sdk_goods_data(cfg, goods_dict)
    return curio_emporium_module:is_sdk_goods_sold_out(goods_data)
  else
    local purchase_limit = cfg.purchaselimit
    if purchase_limit and 0 < purchase_limit then
      local server_data = CsGameStoreModuleUtil.GetCurioShopGoods(cfg.id)
      local bought_num = server_data and server_data.BoughtNum or 0
      return purchase_limit <= bought_num
    end
    return false
  end
end

function M:_sort_grouped_cfgs_by_sold_out(goods_dict)
  if not self._grouped_cfgs then
    return
  end
  for _, group in ipairs(self._grouped_cfgs) do
    table.sort(group.cfgs, function(a, b)
      local a_sold = self:_is_cfg_sold_out(a, goods_dict)
      local b_sold = self:_is_cfg_sold_out(b, goods_dict)
      if a_sold ~= b_sold then
        return not a_sold
      end
      return (a.index or 0) < (b.index or 0)
    end)
  end
end

function M:_find_cfg_and_item_by_id(id)
  for gi, group_data in ipairs(self._grouped_cfgs) do
    local group = self._group_pool[gi]
    for i, cfg in ipairs(group_data.cfgs) do
      if cfg.id == id then
        local item = group and group._item_pool and group._item_pool[i]
        return cfg, item
      end
    end
  end
  return nil, nil
end

function M:_restore_selection(selected_id)
  if not selected_id then
    self:_select_first_item()
    return
  end
  local cfg, item = self:_find_cfg_and_item_by_id(selected_id)
  if cfg then
    self:_on_item_selected(cfg, item)
  else
    self:_select_first_item()
  end
end

function M:_refresh_groups_keep_selection()
  if not self._grouped_cfgs then
    return
  end
  local selected_id = self._selected_cfg and self._selected_cfg.id or nil
  self:_sort_grouped_cfgs_by_sold_out(self._goods_dict)
  self:_refresh_groups(self._goods_dict)
  self:_restore_selection(selected_id)
end

function M:_on_item_selected(cfg, item)
  if not cfg then
    return
  end
  self._selected_cfg = cfg
  self._single_item_id = self:_get_single_item_id(cfg)
  if self._selected_item and self._selected_item ~= item then
    self._selected_item:set_select(false)
  end
  self._selected_item = item
  if item then
    item:set_select(true)
  end
  curio_emporium_module:mark_gift_shown(cfg.id)
  if item then
    item:refresh_red_point()
  end
  if self.holder and self.holder.refresh_all_tag_red_point then
    self.holder:refresh_all_tag_red_point()
  end
  self._selected_sdk_goods_data = nil
  self._selected_server_goods_data = nil
  if not cfg:goodsid_is_empty() then
    self._selected_sdk_goods_data = curio_emporium_module:get_sdk_goods_data(cfg, self._goods_dict)
  else
    self._selected_server_goods_data = CsGameStoreModuleUtil.GetCurioShopGoods(cfg.id)
  end
  self:_refresh_selected_detail()
end

function M:_refresh_selected_detail()
  self._time_refresh_timer = 0
  self:_refresh_name()
  self:_refresh_preview()
  self:_refresh_quality()
  self:_refresh_time()
  self:_refresh_limit()
  self:_refresh_price()
  self:_refresh_buy_btn_state()
  self:_refresh_action_btn_state()
  self:_refresh_pass_state()
end

function M:_get_single_item_id(cfg)
  if not cfg or curio_emporium_module:is_month_card_gift(cfg) or not curio_emporium_module:is_gift_item(cfg.id) then
    return nil
  end
  local items = curio_emporium_module:get_gift_item_list(cfg.id)
  if #items ~= 1 then
    return nil
  end
  local item_id = items[1].config_id
  return item_id and 0 < item_id and item_id or nil
end

function M:_refresh_action_btn_state()
  if not is_null(self._btn_look) then
    local is_month_card = curio_emporium_module:is_month_card_gift(self._selected_cfg)
    UIUtil.set_active(self._btn_look, not self._single_item_id and not is_month_card)
  end
end

function M:_refresh_pass_state()
  if not curio_emporium_module:is_month_card_gift(self._selected_cfg) then
    UIUtil.set_active(self._obj_pass_not_buy, false)
    UIUtil.set_active(self._obj_pass_time_root, false)
    return
  end
  local is_valid, left_days = curio_emporium_module:get_month_card_state()
  UIUtil.set_active(self._obj_pass_not_buy, not is_valid)
  UIUtil.set_active(self._obj_pass_time_root, is_valid)
  if not is_valid then
    return
  end
  local days_text = curio_emporium_module:get_month_card_left_days_text(left_days)
  UIUtil.set_text_by_id(self._txt_pass_time, "Curio_Emporium_Left_Time_Day", days_text)
end

function M:_refresh_name()
  local name = item_module:get_item_name_by_id(self._selected_cfg.id) or ""
  UIUtil.set_text(self._txt_name, name)
end

function M:_refresh_model_preview()
  if not self._model_preview_view then
    return
  end
  local item_id = self._selected_cfg.id
  if item_id and 0 < item_id then
    self._model_preview_view:show_item(item_id, self:get_load_proxy())
  end
end

function M:_refresh_preview()
  if not self._selected_cfg then
    return
  end
  self._is_suit_gift = curio_emporium_module:is_suit_auto_claim_gift(self._selected_cfg.id)
  if self._is_suit_gift then
    self:_show_suit_preview(curio_emporium_module:split_suit_gift_items(self._selected_cfg.id))
  else
    self:_hide_suit_preview()
    UIUtil.set_active(self._obj_common_model_group, true)
    self:_refresh_model_preview()
  end
end

function M:_show_suit_preview(split)
  if not split then
    return
  end
  if not self._suit_preview then
    local scene_obj = self.holder and self.holder.ui_scene_obj
    if is_null(scene_obj) then
      return
    end
    local player_root = UIUtil.find_trans(scene_obj, "Art/ModelPos/pos")
    if is_null(player_root) then
      return
    end
    self._suit_preview = G.New(require("ModelPreview/SuitPreviewController"), player_root)
  end
  self._suit_preview:show_by_cloth_ids(split.cloth_ids, split.style_color_list)
  UIUtil.set_active(self._obj_common_model_group, false)
  self:_set_suit_touch_active(true)
  self._suit_preview:play_gift_pose(self._selected_cfg.suitid, split.cloth_ids)
end

function M:_hide_suit_preview()
  if self._suit_preview then
    self._suit_preview:hide()
  end
  self:_set_suit_touch_active(false)
end

function M:_refresh_quality()
  if is_null(self._ui_state_change_group_quality) then
    return
  end
  local item_id = self._selected_cfg.id
  if not item_id or item_id <= 0 then
    self._ui_state_change_group_quality:SetState(quality_state.Grey)
    return
  end
  local cfg = item_module:get_cfg_by_id(item_id)
  if cfg == nil then
    self._ui_state_change_group_quality:SetState(quality_state.Grey)
    return
  end
  self._ui_state_change_group_quality:SetState(cfg.rank or 0)
end

function M:_refresh_time()
  local cfg = self._selected_cfg
  if not cfg then
    UIUtil.set_active(self._txt_time, false)
    return
  end
  local endtime = cfg.endtime
  if not endtime or endtime == "" then
    UIUtil.set_active(self._txt_time, false)
    return
  end
  local end_ts = curio_emporium_module:parse_endtime(endtime)
  if end_ts <= 0 then
    UIUtil.set_active(self._txt_time, false)
    return
  end
  local now = TimeUtil.ServerUtcTimeSeconds
  local remain_seconds = end_ts - now
  if remain_seconds <= 0 then
    UIUtil.set_active(self._txt_time, false)
    return
  end
  local time_text = curio_emporium_module:format_remain_time(remain_seconds)
  UIUtil.set_active(self._txt_time, true)
  UIUtil.set_text_by_id(self._txt_time, "Curio_Emporium_Good_Time_Prefix", time_text)
end

function M:_refresh_limit()
  local cfg = self._selected_cfg
  if not cfg then
    UIUtil.set_active(self._txt_limit, false)
    return
  end
  if not cfg:goodsid_is_empty() then
    local remain, total = curio_emporium_module:get_sdk_goods_limit(self._selected_sdk_goods_data)
    if total then
      UIUtil.set_active(self._txt_limit, true)
      UIUtil.set_text_by_id(self._txt_limit, "Curio_Emporium_Good_Limit_Txt", remain, total)
    else
      UIUtil.set_active(self._txt_limit, false)
    end
  else
    local purchase_limit = cfg.purchaselimit
    if purchase_limit and 0 < purchase_limit then
      local server_data = CsGameStoreModuleUtil.GetCurioShopGoods(cfg.id)
      local bought_num = 0
      if server_data then
        bought_num = server_data.BoughtNum
      end
      local remain = purchase_limit - bought_num
      if remain < 0 then
        remain = 0
      end
      UIUtil.set_active(self._txt_limit, true)
      UIUtil.set_text_by_id(self._txt_limit, "Curio_Emporium_Good_Limit_Txt", remain, purchase_limit)
    else
      UIUtil.set_active(self._txt_limit, false)
    end
  end
end

function M:_refresh_price()
  local cfg = self._selected_cfg
  if not cfg then
    UIUtil.set_active(self._txt_price_before, false)
    UIUtil.set_active(self._txt_price_now, false)
    UIUtil.set_active(self._img_price_icon, false)
    return
  end
  if not cfg:goodsid_is_empty() then
    UIUtil.set_active(self._img_price_icon, false)
    local price_info = self._selected_sdk_goods_data and self._selected_sdk_goods_data.price or nil
    if is_null(price_info) then
      UIUtil.set_active(self._txt_price_before, false)
      UIUtil.set_active(self._txt_price_now, false)
      return
    end
    local current_display = price_info.amountDisplay or ""
    local original_display = price_info.originalAmountDisplay
    local has_discount = original_display and original_display ~= ""
    UIUtil.set_text(self._txt_price_now, current_display)
    UIUtil.set_active(self._txt_price_now, true)
    if has_discount then
      UIUtil.set_text(self._txt_price_before, original_display)
      UIUtil.set_active(self._txt_price_before, true)
    else
      UIUtil.set_active(self._txt_price_before, false)
    end
  else
    local cost_item_id = cfg.costitemid or 0
    if not is_null(self._img_price_icon) and 0 < cost_item_id then
      UIUtil.set_active(self._img_price_icon, true)
      item_module:set_item_icon(self._img_price_icon, cost_item_id, nil, nil, self:get_load_proxy())
    else
      UIUtil.set_active(self._img_price_icon, false)
    end
    local price = cfg.price or 0
    local original_price = cfg.originalprice or 0
    local has_discount = 0 < original_price and price < original_price
    UIUtil.set_text(self._txt_price_now, tostring(price))
    UIUtil.set_active(self._txt_price_now, true)
    if has_discount then
      UIUtil.set_text(self._txt_price_before, tostring(original_price))
      UIUtil.set_active(self._txt_price_before, true)
    else
      UIUtil.set_active(self._txt_price_before, false)
    end
  end
end

function M:_refresh_buy_btn_state()
  if is_null(self._btn_buy) then
    return
  end
  local cfg = self._selected_cfg
  if not cfg then
    UIUtil.set_active(self._btn_buy, false)
    return
  end
  if not cfg:goodsid_is_empty() and not self._selected_sdk_goods_data then
    UIUtil.set_active(self._btn_buy, false)
    return
  end
  UIUtil.set_active(self._btn_buy, true)
  local endtime = cfg.endtime
  if endtime and endtime ~= "" then
    local end_ts = curio_emporium_module:parse_endtime(endtime)
    if 0 < end_ts and end_ts <= TimeUtil.ServerUtcTimeSeconds then
      self._btn_buy.interactable = false
      return
    end
  end
  if not cfg:goodsid_is_empty() then
    if not curio_emporium_module:can_buy_sdk_goods(self._selected_sdk_goods_data) then
      self._btn_buy.interactable = false
      return
    end
  else
    local purchase_limit = cfg.purchaselimit
    if purchase_limit and 0 < purchase_limit then
      local server_data = CsGameStoreModuleUtil.GetCurioShopGoods(cfg.id)
      local bought_num = 0
      if server_data then
        bought_num = server_data.BoughtNum
      end
      if purchase_limit <= bought_num then
        self._btn_buy.interactable = false
        return
      end
    end
  end
  self._btn_buy.interactable = true
end

function M:_on_buy_click()
  if curio_emporium_module:try_block_store_with_tip() then
    return
  end
  if not self._selected_cfg then
    return
  end
  if curio_emporium_module:try_block_gift_by_tag_switch_with_tip(self._selected_cfg) then
    return
  end
  local cfg = self._selected_cfg
  local item_id = cfg.id
  local is_gift = curio_emporium_module:is_gift_item(item_id)
  local has_goods_id = not cfg:goodsid_is_empty()
  if curio_emporium_module:is_month_card_gift(cfg) then
    if curio_emporium_module:try_block_month_card_day_limit_with_tip() then
      return
    end
    self:_do_buy(cfg)
    return
  end
  if is_gift then
    if not has_goods_id and self:_check_currency_lack(cfg) then
      return
    end
    if self._single_item_id then
      self:_open_confirm_dialog(cfg, has_goods_id, self._single_item_id)
    else
      self:_open_gift_dialog(cfg, has_goods_id)
    end
  else
    self:_open_confirm_dialog(cfg, has_goods_id)
  end
end

function M:_open_gift_dialog(cfg, has_goods_id)
  local items = curio_emporium_module:get_gift_item_list(cfg.id)
  local data = {
    items = items,
    title = item_module:get_item_name_by_id(cfg.id) or "",
    content_desc = UIUtil.get_text_by_id("Curio_Emporium_Good_Included_Tip"),
    gift_item_id = cfg.id,
    gift_item_num = 1,
    has_sale_tag = cfg.saletag == 1,
    on_cancel = function()
    end,
    on_confirm = function()
      self:_do_buy(cfg)
    end
  }
  if has_goods_id then
    local price_text = ""
    local price_info = self._selected_sdk_goods_data and self._selected_sdk_goods_data.price or nil
    if price_info then
      price_text = price_info.amountDisplay or ""
      local original_display = price_info.originalAmountDisplay
      data.is_sdk_discount = original_display and original_display ~= ""
      data.original_price_text = original_display or ""
    end
    data.price_text = price_text
    data.show_top_coin = false
    local remain, total = curio_emporium_module:get_sdk_goods_limit(self._selected_sdk_goods_data)
    if total then
      data.limit_text = UIUtil.get_text_by_id("Curio_Emporium_Good_Limit_Txt", remain, total)
    end
  else
    data.coin_id = cfg.costitemid or 0
    data.price = cfg.price or 0
    data.original_price = cfg.originalprice or 0
    local purchase_limit = cfg.purchaselimit
    if purchase_limit and 0 < purchase_limit then
      local server_data = CsGameStoreModuleUtil.GetCurioShopGoods(cfg.id)
      local bought_num = server_data and server_data.BoughtNum or 0
      local remain = purchase_limit - bought_num
      if remain < 0 then
        remain = 0
      end
      data.limit_text = UIUtil.get_text_by_id("Curio_Emporium_Good_Limit_Txt", remain, purchase_limit)
    end
  end
  UIManagerInstance:open("UI/ConfirmView/CommonGiftDetailsDialog", data)
end

function M:_get_max_buy_num(cfg)
  local max_num
  local purchase_limit = cfg.purchaselimit or 0
  if 0 < purchase_limit then
    local server_data = CsGameStoreModuleUtil.GetCurioShopGoods(cfg.id)
    local bought_num = server_data and server_data.BoughtNum or 0
    max_num = purchase_limit - bought_num
  end
  local price = cfg.price or 0
  local cost_item_id = cfg.costitemid or 0
  if 0 < price and 0 < cost_item_id then
    local owned = back_bag_module:get_coin_or_item_num(cost_item_id) or 0
    local affordable = math.floor(owned / price)
    if not max_num or max_num > affordable then
      max_num = affordable
    end
  end
  if not max_num or max_num < 1 then
    return 1
  end
  return max_num
end

function M:_open_confirm_dialog(cfg, has_goods_id, item_id)
  local max_num = 1
  if not has_goods_id and item_id then
    max_num = self:_get_max_buy_num(cfg)
  end
  local data = {
    cfg_id = item_id or cfg.id,
    max_num = max_num,
    buy_callback = function(count)
      self:_do_buy(cfg, count)
    end
  }
  if has_goods_id then
    local price_text = ""
    if self._selected_sdk_goods_data and self._selected_sdk_goods_data.price then
      price_text = self._selected_sdk_goods_data.price.amountDisplay or ""
    end
    data.price_text = price_text
    data.unit_price = 0
  else
    data.coin_id = cfg.costitemid or 0
    data.unit_price = cfg.price or 0
  end
  UIManagerInstance:open("UI/ConfirmView/CommonConfirmBuyItemDialog", data)
end

function M:_check_currency_lack(cfg)
  local cost_item_id = cfg.costitemid or 0
  local price = cfg.price or 0
  if cost_item_id <= 0 or price <= 0 then
    return false
  end
  local owned = back_bag_module:get_coin_or_item_num(cost_item_id) or 0
  if price <= owned then
    return false
  end
  local lack = price - owned
  if curio_emporium_module:try_block_recharge_with_tip(item_module:get_coin_lack_tip(cost_item_id)) then
    return true
  end
  UIManagerInstance:open("UI/ConfirmView/CommonRechargePromptDialog", {
    title = UIUtil.get_text_by_id("CommonRechargePromptDialog_Title"),
    info = UIUtil.get_text_by_id("CommonRechargePromptDialog_Info", lack),
    lack_amount = lack,
    confirm_callback = function()
      self.holder:change_tag(curio_emporium_module.entrance_tag_type.top_up_mall)
    end
  })
  return true
end

function M:_do_buy(cfg, num)
  if not cfg then
    return
  end
  local cfg_id = cfg.id
  if not cfg:goodsid_is_empty() then
    CsGameStoreModuleUtil.PayGoods(cfg.goodsid, function(ret, msg)
      if ret == 0 then
        curio_emporium_module:show_purchase_reward(cfg_id)
      else
        Logger.LogWarning("[CurioEmporiumHotSale] Pay failed, ret=" .. tostring(ret) .. " msg=" .. tostring(msg))
      end
      if is_null(self.game_obj) then
        return
      end
      if ret == 0 then
        self:_refresh_groups_keep_selection()
      else
        self:_on_sdk_pay_finish(cfg)
      end
    end)
  else
    local buy_num = num and 1 < num and math.floor(num) or 1
    CsGameStoreModuleUtil.CurioShopBuySimple(cfg_id, buy_num, function(retcode)
      if retcode ~= 0 then
        Logger.LogWarning("[CurioEmporiumHotSale] CurioShopBuy failed, retcode=" .. tostring(retcode))
        return
      end
      curio_emporium_module:show_purchase_reward(cfg_id, buy_num)
      if is_null(self.game_obj) then
        return
      end
      self:_refresh_groups_keep_selection()
    end)
  end
end

function M:_on_sdk_pay_finish(cfg)
  if not (cfg and self._selected_cfg) or self._selected_cfg.id ~= cfg.id then
    return
  end
  self._selected_sdk_goods_data = CsGameStoreModuleUtil.GetGoods(cfg.goodsid)
  self:_refresh_limit()
  self:_refresh_buy_btn_state()
  if self._selected_item then
    self._selected_item:refresh(cfg, self._selected_sdk_goods_data, pack(self, M._on_item_selected), self:get_load_proxy())
  end
end

function M:_on_info_click()
  if not self._selected_cfg then
    return
  end
  local item_id = self._single_item_id or self._selected_cfg.id
  if curio_emporium_module:is_month_card_gift(self._selected_cfg) then
    item_id = self._selected_cfg.id
  end
  item_module:open_item_info_dialog(item_id)
end

function M:_on_look_click()
  if not self._selected_cfg then
    return
  end
  self:_hide_suit_preview()
  self._skip_disable_preview_cleanup = true
  if self.holder and self.holder.skip_next_resume_refresh then
    self.holder:skip_next_resume_refresh()
  end
  curio_emporium_module:open_item_details_page(self._selected_cfg.id)
end

return M
