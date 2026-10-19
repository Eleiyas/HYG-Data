local M = G.Class("GachaMainPage", G.UIWindow)
local base = G.UIWindow
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local tab_item_cls = GachaConst.item_path.tab
local tab_title_cls = GachaConst.item_path.tab_title

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.page_path.main
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  
  function self._on_tab_select_callback(gacha_id)
    self:_on_tab_select(gacha_id)
  end
  
  self._coin_items = {}
  self._pool_panels = {}
  self._cur_pool_panel = nil
  self._tab_groups = {}
  self._tab_item_cls_map = {}
  self._tab_title_cls_map = {}
  self._is_checking_single_activity_end = false
  self._is_init_state = false
end

function M:on_prepare()
  base.on_prepare(self)
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.GachaDataAllUpdate, pack(self, M._on_data_all_update))
  self:add_evt_listener(EventID.GachaAccumRewardClaimResult, pack(self, M._on_accum_reward_claim_result))
  self:add_lua_listener(lua_event_module.event_type.gacha_single_activity_end, pack(self, self._on_single_activity_end))
end

function M:on_enable()
  base.on_enable(self)
  self._is_checking_single_activity_end = false
  if not self._is_init_state then
    self._state_group:SetState(0)
    self._is_init_state = true
  end
  gacha_module:load_skip_anim_data()
  gacha_module:load_video_played_data()
  self:_init_panel_info()
  if self._extra_data and self._extra_data.is_request_all_data then
    self._extra_data.is_request_all_data = false
    gacha_module:request_query()
  else
    self:_refresh()
  end
  gacha_module:set_is_request_draw(false)
  gacha_module:set_is_in_draw_show(false)
end

function M:on_disable()
  base.on_disable(self)
  gacha_module:save_skip_anim_data()
  gacha_module:save_video_played_data()
  gacha_module:set_detail_data(nil)
  gacha_module:set_history_data(nil)
  gacha_module:set_is_request_draw(false)
end

function M:on_destroy()
  self._pool_panels = {}
  self._coin_items = {}
  self._cur_pool_panel = nil
  self._tab_item_cls_map = {}
  self._tab_title_cls_map = {}
  self:_close_scroller(self._scroll_card_list)
  self._is_init_state = false
  base.on_destroy(self)
end

function M:_on_data_all_update()
  gacha_module:clear_accum_reward_red_cache()
  self:_refresh()
end

function M:_on_accum_reward_claim_result(rsp)
  if rsp ~= nil then
    gacha_module:clear_accum_reward_red_cache(rsp.GachaPoolId)
  end
  self:_refresh_current_pool_panel()
  self:_refresh_all_tab_red_point()
end

function M:_on_single_activity_end()
  self._is_checking_single_activity_end = true
  self:_refresh_tab_groups()
end

function M:_on_tab_select(gacha_id)
  local cfg = gacha_module:get_activity_cfg(gacha_id)
  if cfg == nil then
    Logger.LogError("[GachaMainPage] activity cfg is nil, gacha_id: " .. tostring(gacha_id))
    return
  end
  gacha_module:set_cur_gacha_id(gacha_id)
  self:_show_pool_panel(cfg)
end

function M:_init_panel_info()
  UIUtil.set_text_by_id(self._txt_panel_title, "Gacha_T0_MainScreen_Title_01")
end

function M:_refresh()
  self:_refresh_tab_groups()
end

function M:_refresh_all_tab_red_point()
  if self._tab_item_cls_map == nil then
    return
  end
  for _, cls in pairs(self._tab_item_cls_map) do
    cls:refresh_red_point()
  end
end

function M:_refresh_tab_groups()
  self._tab_groups = gacha_module:get_tab_groups()
  local has_pool = #self._tab_groups > 0
  self._state_group:SetState(has_pool and 1 or 0)
  if not has_pool then
    self:_check_single_activity_end()
    return
  end
  self._is_checking_single_activity_end = false
  local gacha_id = gacha_module:get_cur_gacha_id()
  local cfg = self:_find_cfg_in_tab_groups(gacha_id)
  self._need_scroll_to_first = cfg == nil
  if cfg == nil then
    local first_group = self._tab_groups[1]
    local first = first_group and first_group.items[1]
    if first ~= nil then
      gacha_id = first.gachaid
      cfg = first
      gacha_module:set_cur_gacha_id(gacha_id)
    end
  end
  self:_refresh_tabs()
  self:_on_tab_select(gacha_id)
end

function M:_find_cfg_in_tab_groups(gacha_id)
  if gacha_id == nil or gacha_id <= 0 then
    return nil
  end
  for _, group in ipairs(self._tab_groups) do
    local items = group.items
    if items ~= nil then
      for i = 1, #items do
        if items[i].gachaid == gacha_id then
          return items[i]
        end
      end
    end
  end
  return nil
end

function M:_refresh_tabs()
  self:_refresh_scroller(self._scroll_card_list, self._tab_groups, M._on_tab_item_bind, M._on_tab_node_init)
end

function M:_refresh_scroller(scroller, groups, item_bind_func, node_init_func)
  if is_null(scroller) then
    return
  end
  local node_count = #groups
  UIUtil.set_active(scroller, 0 < node_count)
  scroller:SetNodeCount(node_count)
  if node_count <= 0 then
    return
  end
  local bind_cb = pack(self, item_bind_func)
  local init_cb = pack(self, node_init_func)
  for i, group in ipairs(groups) do
    local node_index = i - 1
    local item_count = group.items and #group.items or 0
    scroller:Init(node_index, 0, item_count, bind_cb, init_cb)
    scroller:ExpandNode(node_index, 0)
  end
  scroller:RebindAllVisibleItems()
  if self._need_scroll_to_first then
    scroller:MoveToNode(0)
    self._need_scroll_to_first = false
  end
end

function M:_on_tab_node_init(node_trans, node_index)
  local group = self._tab_groups[node_index + 1]
  if not group then
    return
  end
  local title_trans = node_trans:Find(GachaConst.group_title_child_name)
  if is_null(title_trans) then
    title_trans = node_trans
  end
  local title_obj_id = title_trans:GetInstanceID()
  local cls = self._tab_title_cls_map[title_obj_id]
  if not cls then
    cls = self:add_panel(tab_title_cls, title_trans)
    self._tab_title_cls_map[title_obj_id] = cls
  end
  cls:refresh(group.title)
end

function M:_on_tab_item_bind(item_trans, node_index, item_index)
  local group = self._tab_groups[node_index + 1]
  if not group or not group.items then
    return
  end
  local cfg = group.items[item_index + 1]
  if cfg == nil then
    return
  end
  local item_obj_id = item_trans:GetInstanceID()
  local cls = self._tab_item_cls_map[item_obj_id]
  if not cls then
    cls = self:add_panel(tab_item_cls, item_trans)
    self._tab_item_cls_map[item_obj_id] = cls
  end
  local gacha_id = cfg.gachaid
  cls:refresh(cfg, gacha_id == gacha_module:get_cur_gacha_id(), self._on_tab_select_callback)
end

function M:_close_scroller(scroller)
  if not is_null(scroller) then
    scroller:Close()
  end
end

function M:_refresh_coin(gacha_id)
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  if activity_cfg == nil then
    return
  end
  local coins = gacha_module:get_pool_show_coins(activity_cfg.pricestrategyid)
  local cur_coin_num = math.max(#self._coin_items, #coins)
  for i = 1, cur_coin_num do
    local coin_cfg = coins[i]
    if coin_cfg then
      if self._coin_items[i] == nil then
        self._coin_items[i] = self:_create_coin_item(coin_cfg.coinid)
      end
      self._coin_items[i]:set_coin_id(coin_cfg.coinid)
      self._coin_items[i]:set_show_add((coin_cfg.showadd or 0) == 1)
      self._coin_items[i]:set_active(true)
    elseif self._coin_items[i] then
      self._coin_items[i]:set_active(false)
    end
  end
end

function M:_create_coin_item(coin_id)
  local obj = UIUtil.load_prefab_set_parent(self._obj_coin_item, self._right_layout_trans, coin_item_view_cls)
  local coin_item = self:add_panel(coin_item_view_cls, obj, {
    coin_id = coin_id,
    auto_update = true,
    show_detail = true,
    extra_events = {
      EventID.CoinExchangeResult
    },
    on_add_click = pack(self, M._on_coin_add_click)
  })
  return coin_item
end

function M:_on_coin_add_click(coin_id, num)
  if coin_id <= 0 then
    return
  end
  local const_coin_id = gacha_module:get_exchange_coin_id(coin_id)
  if const_coin_id <= 0 then
    return
  end
  if not common_ui_module:get_coin_exchange_cfg(coin_id, const_coin_id) then
    return
  end
  common_ui_module:show_coin_exchange_dialog(coin_id, const_coin_id)
end

function M:_show_pool_panel(cfg)
  local lua_class = GachaConst.tab_pool_panel_path[cfg.tab]
  if lua_class == nil then
    Logger.LogError("[GachaMainPage] no pool panel for tab: " .. tostring(cfg.tab) .. ", gacha_id: " .. tostring(cfg.gachaid))
    return
  end
  local cached = self._pool_panels[cfg.gachaid]
  if cached ~= nil then
    if not cached.is_loaded then
      return
    end
    if self._cur_pool_panel ~= cached.panel then
      self:_hide_current_pool_panel()
      self._cur_pool_panel = cached.panel
      self._cur_pool_panel:change_state(EUIState.Show)
    end
    self._cur_pool_panel:refresh()
    self:_refresh_coin(cfg.gachaid)
    return
  end
  self:_load_pool_panel(cfg)
end

function M:_load_pool_panel(cfg)
  local extra = {
    gacha_id = cfg.gachaid
  }
  local panel_info = {panel = nil, is_loaded = false}
  self._pool_panels[cfg.gachaid] = panel_info
  local lua_class = GachaConst.tab_pool_panel_path[cfg.tab]
  panel_info.panel = self:add_panel_async(lua_class, extra, self._panel_parent, pack(self, M._on_pool_panel_loaded))
  panel_info.panel:change_state(EUIState.Show)
end

function M:_on_pool_panel_loaded(loaded_panel)
  if is_null(loaded_panel) then
    Logger.LogError("[GachaMainPage] add_panel_async failed: ")
    return
  end
  local panel_gacha_id = loaded_panel:get_gacha_id()
  local panel_info = self._pool_panels[panel_gacha_id]
  if panel_info == nil then
    loaded_panel:change_state(EUIState.Hide)
    Logger.LogError("[GachaMainPage] panel_info is nil: " .. panel_gacha_id)
    return
  end
  panel_info.panel = loaded_panel
  panel_info.is_loaded = true
  if gacha_module:get_cur_gacha_id() == panel_gacha_id then
    self:_hide_current_pool_panel()
    self._cur_pool_panel = loaded_panel
    loaded_panel:change_state(EUIState.Show)
    loaded_panel:refresh()
    self:_refresh_coin(panel_gacha_id)
  else
    loaded_panel:change_state(EUIState.Hide)
  end
end

function M:_refresh_current_pool_panel()
  if self._cur_pool_panel == nil then
    return
  end
  self._cur_pool_panel:refresh()
end

function M:_hide_current_pool_panel()
  if self._cur_pool_panel == nil then
    return
  end
  self._cur_pool_panel:change_state(EUIState.Hide)
  self._cur_pool_panel = nil
end

function M:_check_single_activity_end()
  if not self._is_checking_single_activity_end then
    return
  end
  self._is_checking_single_activity_end = false
  local popup = UIUtil.get_confirm_popup()
  local show_text = UIUtil.get_text_by_id("Gacha_Common_Pool_None")
  popup:set_texts(show_text, UIUtil.get_text_by_id("Common_Yes"))
  popup:set_style(ConfirmPopupStyle.ForcedPopup)
  popup:set_callbacks(function()
    self:close_self()
  end)
  popup:show()
end

return M
