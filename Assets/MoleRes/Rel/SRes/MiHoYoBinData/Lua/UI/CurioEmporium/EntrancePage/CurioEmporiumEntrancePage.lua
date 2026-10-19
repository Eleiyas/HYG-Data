local M = G.Class("CurioEmporiumEntrancePage", G.UIWindow)
local base = G.UIWindow
local tag_item_cls = "UI/CurioEmporium/EntrancePage/CurioEmporiumEntranceTagItem"
local tag_cls = {
  [curio_emporium_module.entrance_tag_type.top_up_mall] = "UI/CurioEmporium/EntrancePage/Panel/CurioEmporiumTopUpPanel",
  [curio_emporium_module.entrance_tag_type.hot_sale] = "UI/CurioEmporium/EntrancePage/Panel/CurioEmporiumEntranceHotSalePanel",
  [curio_emporium_module.entrance_tag_type.season_bp] = "UI/CurioEmporium/EntrancePage/Panel/CurioEmporiumEntranceSeasonBpPanel",
  [curio_emporium_module.entrance_tag_type.first_recharge] = "UI/CurioEmporium/EntrancePage/Panel/CurioEmporiumEntranceFirstRechargePanel",
  [curio_emporium_module.entrance_tag_type.monthly_pass] = "UI/CurioEmporium/EntrancePage/Panel/CurioEmporiumMonthlyPassPanel"
}
local ctrl_mode = {touch = 1, keyMouseAndGamePad = 2}
local SERVER_DATA_TIMEOUT = 5

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CurioEmporium/CurioEmporiumEntrancePage"
  self.config.type = EUIType.Page
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_CurioEmporium"
  self.config.wait_previous_window_hide_until_show = true
  self.tag_items = {}
  self.tag_items[ctrl_mode.touch] = {}
  self.tag_items[ctrl_mode.keyMouseAndGamePad] = {}
  self._panels = {}
  self._cur_tag_id = nil
  self._pending_tag_id = nil
  self._skip_resume_refresh = false
  self._close_callback = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._coin_panel = self:add_panel(back_bag_module.coin_panel_cls, self._coin_root)
  self:_refresh_tags()
end

function M:on_open()
  base.on_open(self)
  local extra = self:get_extra_data()
  if type(extra) == "table" then
    self._close_callback = extra.close_callback
  end
end

function M:on_enable()
  base.on_enable(self)
  if self._skip_resume_refresh then
    self._skip_resume_refresh = false
    local panel = self._cur_tag_id and self._panels[self._cur_tag_id]
    if panel and panel.on_resume_from_sub_page then
      panel:on_resume_from_sub_page()
    end
    return
  end
  self._server_data_ready = false
  self._pending_tag_id = self._cur_tag_id
  self:_hide_current_panel()
  self._cur_tag_id = nil
  UIUtil.set_text(self._txt_sub_title, curio_emporium_module:get_tag_name(self:_get_target_tag_id()))
  self:_request_server_data()
end

function M:on_disable()
  base.on_disable(self)
  if self._waiting_server_data then
    self._waiting_server_data = false
    self._request_timer = nil
    EventCenter.Broadcast(EventID.luaClosePayWaitPage, nil)
  end
end

function M:on_close()
  base.on_close(self)
  self:_hide_current_panel()
  self._cur_tag_id = nil
  self._pending_tag_id = nil
  local close_callback = self._close_callback
  self._close_callback = nil
  if close_callback then
    close_callback()
  end
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if not self._request_timer then
    return
  end
  self._request_timer = self._request_timer + deltaTime
  if self._request_timer >= SERVER_DATA_TIMEOUT then
    self:_on_server_data_result(false)
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaRefreshCurioEmporiumRedPoint, pack(self, M.refresh_all_tag_red_point))
  self:add_evt_listener(EventID.OnEmergencySwitchStateChanged, pack(self, M._on_emergency_switch_changed))
end

function M:_on_emergency_switch_changed()
  if is_null(self.game_obj) or not self:is_in_show_state() then
    return
  end
  self:_refresh_tag_visibility()
  if self._cur_tag_id then
    self:_refresh_coin_panel(self._cur_tag_id)
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
end

function M:_on_coin_click(coin_id, _)
  if not coin_id or coin_id <= 0 then
    return
  end
  item_module:open_item_info_dialog(coin_id, back_bag_module:get_coin_or_item_num(coin_id))
end

function M:_on_coin_add_click(coin_id, num)
  if curio_emporium_module:try_block_store_with_tip() or curio_emporium_module:try_block_recharge_with_tip() then
    return
  end
  self:change_tag(curio_emporium_module.entrance_tag_type.top_up_mall)
end

function M:_refresh_coin_panel(tag_id)
  local cfg = curio_emporium_module.entrance_tag_coin_cfg[tag_id]
  if cfg and curio_emporium_module:is_recharge_blocked() then
    local overridden = {}
    for i, coin_cfg in ipairs(cfg) do
      local copied = {}
      for k, v in pairs(coin_cfg) do
        copied[k] = v
      end
      copied.show_add = false
      overridden[i] = copied
    end
    cfg = overridden
  end
  self._coin_panel:set_coin_data({
    coin_items = cfg or {},
    is_auto_update = true,
    coin_anim_time = 0,
    on_coin_click = pack(self, M._on_coin_click),
    on_add_click = pack(self, M._on_coin_add_click)
  })
end

function M:_request_server_data()
  self._waiting_server_data = true
  self._request_timer = 0
  EventCenter.Broadcast(EventID.luaOpenPayWaitPage, nil)
  CsGameStoreModuleUtil.CurioShopGetDataSimple(pack(self, M._on_server_data_result))
end

function M:_on_server_data_result(success)
  if not self._waiting_server_data then
    return
  end
  self._waiting_server_data = false
  self._request_timer = nil
  EventCenter.Broadcast(EventID.luaClosePayWaitPage, nil)
  if is_null(self.game_obj) then
    return
  end
  if not self:is_in_show_state() then
    return
  end
  if not success then
    UIUtil.show_tips_by_text_id(0, "数据拉取失败")
    return
  end
  self._server_data_ready = true
  local target_tag_id = self:_get_target_tag_id()
  if self:get_extra_data() then
    self:set_extra_data(nil)
  end
  self._pending_tag_id = nil
  self:_refresh_tag_visibility()
  self:refresh_all_tag_red_point()
  self:change_tag(target_tag_id)
end

function M:_get_target_tag_id()
  local extra = self:get_extra_data()
  local tag_id
  if type(extra) == "table" then
    tag_id = extra.first_recharge_tag_id
  else
    tag_id = extra
  end
  tag_id = tag_id or self._pending_tag_id or curio_emporium_module.entrance_tag_type.first_recharge
  if not curio_emporium_module:is_tag_visible(tag_id) then
    tag_id = curio_emporium_module:get_first_visible_tag_id()
  end
  return tag_id
end

function M:_refresh_tags()
  local all_tag_cfgs = curio_emporium_module:get_all_tag_cfg()
  for _, cfg in ipairs(all_tag_cfgs) do
    local obj = self._tab_list_binder_mobile:AddItem(0)
    local tag_item = self:add_panel(tag_item_cls, obj)
    tag_item:refresh(cfg, function(tag_id)
      self:_on_tag_click(tag_id)
    end)
    self.tag_items[ctrl_mode.touch][cfg.tagid] = tag_item
    obj = self._tab_list_binder_pcps:AddItem(0)
    tag_item = self:add_panel(tag_item_cls, obj)
    tag_item:refresh(cfg, function(tag_id)
      self:_on_tag_click(tag_id)
    end)
    self.tag_items[ctrl_mode.keyMouseAndGamePad][cfg.tagid] = tag_item
  end
  self:_refresh_tag_visibility()
end

function M:_refresh_tag_visibility()
  for _, items in pairs(self.tag_items) do
    for tag_id, tag_item in pairs(items) do
      if tag_item then
        tag_item:set_active(curio_emporium_module:is_tag_visible(tag_id))
      end
    end
  end
end

function M:change_tag(tag_id)
  if not tag_id or not curio_emporium_module:is_tag_visible(tag_id) then
    return
  end
  local items = InputManagerIns:is_touch() and self.tag_items[ctrl_mode.touch] or self.tag_items[ctrl_mode.keyMouseAndGamePad]
  local tag_item = items and items[tag_id]
  if not tag_item then
    Logger.LogWarning("[CurioEmporium] change_tag missing tag_item: " .. tostring(tag_id))
    return
  end
  self._is_internal_tag_change = true
  tag_item:set_selected()
  self._is_internal_tag_change = false
end

function M:skip_next_resume_refresh()
  self._skip_resume_refresh = true
end

function M:refresh_all_tag_red_point()
  for _, items in pairs(self.tag_items) do
    for _, tag_item in pairs(items) do
      if tag_item and tag_item.refresh_red_point then
        tag_item:refresh_red_point()
      end
    end
  end
end

function M:_on_tag_click(tag_id)
  if not self._server_data_ready then
    return
  end
  if not self._is_internal_tag_change and curio_emporium_module:try_block_store_with_tip() then
    return
  end
  if not self._is_internal_tag_change and curio_emporium_module:try_block_tag_with_tip(tag_id) then
    return
  end
  if not curio_emporium_module:is_tag_visible(tag_id) then
    return
  end
  local cls = tag_cls[tag_id]
  if not cls then
    Logger.LogWarning("[CurioEmporium] unknown tag_id: " .. tostring(tag_id))
    return
  end
  if self._cur_tag_id == tag_id then
    return
  end
  self:_hide_current_panel()
  self._cur_tag_id = tag_id
  self:_refresh_coin_panel(tag_id)
  self:_show_panel(tag_id, cls)
  UIUtil.set_text(self._txt_sub_title, curio_emporium_module:get_tag_name(tag_id))
end

function M:_show_panel(tag_id, cls)
  local cached = self._panels[tag_id]
  if cached then
    cached:change_state(EUIState.Show)
    cached:refresh()
    return
  end
  local panel = self:add_panel_async(cls, nil, self._trans_panel_content, function(loaded_panel)
    self:_on_panel_loaded(tag_id, loaded_panel)
  end)
  panel:change_state(EUIState.Show)
  self._panels[tag_id] = panel
end

function M:_on_panel_loaded(tag_id, loaded_panel)
  if is_null(loaded_panel) then
    return
  end
  loaded_panel:set_tag_cfg(curio_emporium_module:get_tag_cfg(tag_id))
  if self._cur_tag_id == tag_id then
    loaded_panel:change_state(EUIState.Show)
    loaded_panel:refresh()
  else
    loaded_panel:change_state(EUIState.Hide)
  end
end

function M:_hide_current_panel()
  if not self._cur_tag_id then
    return
  end
  local panel = self._panels[self._cur_tag_id]
  if panel then
    panel:change_state(EUIState.Hide)
  end
end

return M
