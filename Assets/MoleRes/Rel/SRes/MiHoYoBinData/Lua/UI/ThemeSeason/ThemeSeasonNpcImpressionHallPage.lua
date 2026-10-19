local M = G.Class("ThemeSeasonNpcImpressionHallPage", G.UIWindow)
local base = G.UIWindow
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local npc_panel_cls = "UI/ThemeSeason/NpcImpressionHallPanel"
local npc_tab_cls = "UI/ThemeSeason/NpcImpressionHallNpcTab"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BattlePass/NpcImpressionHallPage"
  self.config.type = EUIType.Page
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_SeasonBP"
  self.config.wait_previous_window_hide_until_show = true
  self._tab_items = {}
  self._selected_npc_index = 0
  self._npc_list = {}
  self._visited_npc_ids = {}
  self._npc_panel = nil
  self._coin_view_01 = nil
  self._coin_view_02 = nil
  self._trans_tab_list = nil
  self._btn_graduation = nil
  self._trans_npc_impression_hall_panel = nil
  self._list_iem = nil
  self._btn_coin_item_01 = nil
  self._btn_coin_item_02 = nil
  self._btn_info_dark = nil
  self._btn_close_normal = nil
end

function M:on_create()
  base.on_create(self)
  self:_create_npc_panel()
  self:_create_coin_views()
  self:_bind_callbacks()
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_theme_season_data_changed, pack(self, M.refresh))
  self:add_lua_listener(lua_event_module.event_type.on_theme_bp_purchased, pack(self, M.refresh))
  self:add_lua_listener(lua_event_module.event_type.on_npc_goods_exchanged, pack(self, M._on_npc_goods_exchanged))
  self:add_evt_listener(EventID.UpdateCoinData, pack(self, M._refresh_tabs_tips))
end

function M:on_open()
  base.on_open(self)
  theme_season_module:report_page_reach(theme_season_module.REPORT_PAGE_ID.NPC_IMPRESSION_HALL)
  self._selected_npc_index = 0
  self._visited_npc_ids = {}
  self:_sync_coin_ids()
end

function M:on_enable()
  base.on_enable(self)
  self:refresh()
  theme_season_module:try_show_season_expired_popup()
end

function M:on_disable()
  base.on_disable(self)
end

function M:play_exit_anim()
  if self._npc_panel and self._npc_panel.is_active then
    self._npc_panel:play_exit_anims()
  end
  base.play_exit_anim(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  self._tab_items = {}
  self._npc_panel = nil
  self._coin_view_01 = nil
  self._coin_view_02 = nil
  base.on_destroy(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
end

function M:_create_npc_panel()
  if not_null(self._trans_npc_impression_hall_panel) then
    self._npc_panel = self:add_panel(npc_panel_cls, self._trans_npc_impression_hall_panel)
  end
end

function M:_sync_coin_ids()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  local coin_id_1 = season_cfg and season_cfg.token1 or 0
  local coin_id_2 = season_cfg and season_cfg.token2 or 0
  if self._coin_view_01 and 0 < coin_id_1 then
    self._coin_view_01:set_coin_id(coin_id_1)
  end
  if self._coin_view_02 and 0 < coin_id_2 then
    self._coin_view_02:set_coin_id(coin_id_2)
  end
end

function M:_create_coin_views()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  local coin_id_1 = season_cfg and season_cfg.token1 or 0
  local coin_id_2 = season_cfg and season_cfg.token2 or 0
  if not_null(self._btn_coin_item_01) and 0 < coin_id_1 then
    self._coin_view_01 = self:add_panel(coin_item_view_cls, self._btn_coin_item_01.transform, {
      coin_id = coin_id_1,
      auto_update = true,
      show_detail = true,
      on_add_click = pack(theme_season_module, theme_season_module.on_coin_item_add_click)
    })
  end
  if not_null(self._btn_coin_item_02) and 0 < coin_id_2 then
    self._coin_view_02 = self:add_panel(coin_item_view_cls, self._btn_coin_item_02.transform, {
      coin_id = coin_id_2,
      auto_update = true,
      show_detail = true,
      on_add_click = pack(theme_season_module, theme_season_module.on_coin_item_add_click)
    })
  end
end

function M:_bind_callbacks()
  self:bind_close_btn(self._btn_close_normal)
  if not_null(self._btn_graduation) then
    self:bind_callback(self._btn_graduation, pack(self, M._on_btn_graduation_click))
  end
  if not_null(self._btn_info_dark) then
    self:bind_callback(self._btn_info_dark, pack(self, M._on_btn_info_click))
  end
end

function M:_on_btn_graduation_click()
  theme_season_module:open_graduation_dialog()
end

function M:_on_btn_info_click()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  local intro_id = season_cfg and season_cfg.introductionid or 0
  if 0 < intro_id then
    common_ui_module:show_introduction_dialog(intro_id)
  end
end

function M:refresh()
  theme_season_module:update_season_time_state()
  self._npc_list = self:_get_npc_list()
  self:_refresh_tabs()
  if self._selected_npc_index >= 1 and self._selected_npc_index <= #self._npc_list then
    self:_refresh_npc_content()
  else
    self:_select_default_npc()
  end
end

function M:_refresh_tabs()
  local npcs = self._npc_list
  for i = 1, #npcs do
    local npc = npcs[i]
    local tab = self._tab_items[i]
    if tab == nil then
      tab = self:_create_tab_item(i)
      self._tab_items[i] = tab
    end
    if tab then
      tab:refresh(npc, i, self:_should_show_tab_tips(npc))
      tab:set_active(true)
    end
  end
  for i = #npcs + 1, #self._tab_items do
    local tab = self._tab_items[i]
    if tab then
      tab:set_active(false)
    end
  end
end

function M:_refresh_tabs_tips()
  for i = 1, #self._npc_list do
    local tab = self._tab_items[i]
    if tab then
      tab:set_tips_visible(self:_should_show_tab_tips(self._npc_list[i]))
    end
  end
end

function M:_should_show_tab_tips(npc_data)
  local npc_id = npc_data and npc_data.config_id or 0
  if npc_id <= 0 or self._visited_npc_ids[npc_id] then
    return false
  end
  return theme_season_module:should_show_npc_exchange_tips(npc_id)
end

function M:_create_tab_item(index)
  if is_null(self._list_iem) then
    return nil
  end
  local obj = self._list_iem:AddItem(0)
  if is_null(obj) then
    return nil
  end
  local tab = self:add_panel(npc_tab_cls, obj)
  if tab == nil then
    return nil
  end
  local toggle = tab:get_toggle()
  if not_null(toggle) then
    self:bind_callback(toggle, pack(self, function(s, is_on)
      s:_on_npc_tab_toggle_changed(index, is_on)
    end))
  end
  return tab
end

function M:_on_npc_tab_toggle_changed(index, is_on)
  if not is_on then
    return
  end
  if index == self._selected_npc_index then
    return
  end
  self:_select_npc(index)
end

function M:_on_npc_goods_exchanged()
  self:refresh()
  self:_try_switch_to_next_incomplete_npc()
end

function M:_select_default_npc()
  if self._selected_npc_index >= 1 and self._selected_npc_index <= #self._npc_list then
    return
  end
  if #self._npc_list > 0 then
    self:_select_npc(self:_find_incomplete_npc_index(1) or 1)
    self:_sync_tab_visuals()
  end
end

function M:_try_switch_to_next_incomplete_npc()
  local cur_index = self._selected_npc_index
  local cur_npc = self._npc_list[cur_index]
  if cur_npc == nil then
    return
  end
  if not theme_season_module:is_npc_exchange_line_completed(cur_npc.config_id) then
    return
  end
  local next_index = self:_find_incomplete_npc_index(cur_index + 1)
  if next_index and next_index ~= cur_index then
    self:_select_npc(next_index)
  end
end

function M:_find_incomplete_npc_index(start_index)
  local count = #self._npc_list
  if count == 0 then
    return nil
  end
  for offset = 0, count - 1 do
    local index = (start_index - 1 + offset) % count + 1
    local npc = self._npc_list[index]
    if npc and not theme_season_module:is_npc_exchange_line_completed(npc.config_id) then
      return index
    end
  end
  return nil
end

function M:_select_npc(index)
  if index < 1 or index > #self._npc_list then
    return
  end
  self._selected_npc_index = index
  local npc_data = self._npc_list[index]
  if npc_data and npc_data.config_id then
    self._visited_npc_ids[npc_data.config_id] = true
  end
  self:_refresh_npc_content()
  self:_sync_tab_visuals()
  self:_refresh_tabs_tips()
end

function M:_sync_tab_visuals()
  for i, tab in ipairs(self._tab_items) do
    if tab then
      tab:set_selected(i == self._selected_npc_index)
    end
  end
end

function M:_refresh_npc_content()
  local npc_data = self._npc_list[self._selected_npc_index]
  if self._npc_panel and npc_data then
    self._npc_panel:refresh(npc_data)
  end
end

function M:_get_npc_cfg_data(config_id)
  local npc_cfg = ExcelDataUtil.get_value(typeof(BNpcCfg), config_id)
  if is_null(npc_cfg) then
    return nil
  end
  return {
    name = npc_cfg.name or "",
    icon = npc_cfg.iconnamesmall or ""
  }
end

function M:_get_npc_list()
  local npc_entries = theme_season_module:get_exchange_npc_list()
  local result = {}
  for i = 1, #npc_entries do
    local entry = npc_entries[i]
    if entry.is_season then
      local cfg_data = self:_get_npc_cfg_data(entry.npc_id)
      result[#result + 1] = {
        config_id = entry.npc_id,
        is_season = entry.is_season,
        name = cfg_data and cfg_data.name or "",
        icon = cfg_data and cfg_data.icon or ""
      }
    end
  end
  return result
end

return M
