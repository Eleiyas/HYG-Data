local M = G.Class("ThemeSeasonMainPage", G.UIWindow)
local base = G.UIWindow
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local btn_impression_cls = "UI/ThemeSeason/ThemeSeasonMainPageBtnImpression"
local btn_daily_task_cls = "UI/ThemeSeason/ThemeSeasonMainPageBtnDailyTask"
local btn_story_cls = "UI/ThemeSeason/ThemeSeasonMainPageBtnStory"
local btn_buy_cls = "UI/ThemeSeason/ThemeSeasonMainPageBtnBuy"
local btn_star_explore_cls = "UI/ThemeSeason/ThemeSeasonMainPageBtnStarExplore"
local DEFAULT_PREFAB = "UI/BattlePass/BattlePassSeasonMainPage"
local MAIN_PAGE_ANIM = theme_season_module.MAIN_PAGE_ANIM

function M:init()
  base.init(self)
  local season_cfg = theme_season_module:get_cur_season_cfg()
  local cfg_ui = season_cfg and season_cfg.ui or ""
  if string.is_valid(cfg_ui) then
    self.config.prefab_path = "UI/BattlePass/" .. cfg_ui
  else
    self.config.prefab_path = DEFAULT_PREFAB
  end
  self._loaded_season_id = theme_season_module:get_cur_season_id()
  self.config.type = EUIType.Page
  self.config.is_singleton = false
  self._btn_panels = {}
  self._coin_view_01 = nil
  self._coin_view_02 = nil
  self._last_remain_seconds = -1
  self._trans_btn_01 = nil
  self._trans_btn_02 = nil
  self._trans_btn_03 = nil
  self._trans_btn_04 = nil
  self._trans_btn_05 = nil
  self._txt_title = nil
  self._txt_time = nil
  self._txt_program = nil
  self._txt_title_top = nil
  self._trans_coin_item_01 = nil
  self._trans_coin_item_02 = nil
  self._btn_info_dark = nil
  self._btn_close_normal = nil
end

function M:on_create()
  base.on_create(self)
  self:_create_btn_panels()
  self:_create_coin_views()
  self:_bind_btn_callbacks()
  self:_bind_top_callbacks()
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_theme_season_data_changed, pack(self, M.refresh))
  self:add_lua_listener(lua_event_module.event_type.on_npc_goods_exchanged, pack(self, M.refresh))
  self:add_evt_listener(EventID.OnCodexSeasonNumRewardUpdate, pack(self, M.refresh))
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:on_open()
  base.on_open(self)
  theme_season_module:report_page_reach(theme_season_module.REPORT_PAGE_ID.MAIN)
  self:_sync_coin_ids()
  self:_check_first_pv_play()
end

function M:on_enable()
  base.on_enable(self)
  self._last_remain_seconds = -1
  self:refresh()
  self:_play_page_enter_anim()
  theme_season_module:try_show_season_expired_popup()
end

function M:on_disable()
  base.on_disable(self)
end

function M:play_exit_anim()
  if not self._has_binder then
    base.play_exit_anim(self)
    return
  end
  if Config.ui_unlock_input_before_anim and self._state_machine and not UIManagerInstance:is_window_waiting_for_hide(self.guid) then
    self._state_machine:release_input_lock_early(EUIState.Hide)
  end
  self._is_play_anim = true
  self.binder:PlayAnimation(MAIN_PAGE_ANIM.OUT, function()
    self._is_play_anim = false
    self:exit_anim_call_back()
  end)
end

function M:_play_page_enter_anim()
  if not self._has_binder then
    return
  end
  local is_first = not theme_season_module:is_main_page_entered()
  self.binder:PlayAnimation(is_first and MAIN_PAGE_ANIM.FIRST_IN or MAIN_PAGE_ANIM.IN, nil)
  if is_first then
    theme_season_module:mark_main_page_entered()
  end
end

function M:on_destroy()
  self._btn_panels = {}
  base.on_destroy(self)
end

function M:update()
  self:_refresh_remaining_time()
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
  local coin_id_1 = 0
  local coin_id_2 = 0
  local season_cfg = theme_season_module:get_cur_season_cfg()
  if season_cfg then
    coin_id_1 = season_cfg.token1 or 0
    coin_id_2 = season_cfg.token2 or 0
  end
  if not_null(self._trans_coin_item_01) and 0 < coin_id_1 then
    self._coin_view_01 = self:add_panel(coin_item_view_cls, self._trans_coin_item_01, {
      coin_id = coin_id_1,
      auto_update = true,
      show_detail = true,
      on_add_click = pack(theme_season_module, theme_season_module.on_coin_item_add_click)
    })
  end
  if not_null(self._trans_coin_item_02) and 0 < coin_id_2 then
    self._coin_view_02 = self:add_panel(coin_item_view_cls, self._trans_coin_item_02, {
      coin_id = coin_id_2,
      auto_update = true,
      show_detail = true,
      on_add_click = pack(theme_season_module, theme_season_module.on_coin_item_add_click)
    })
  end
end

function M:_bind_top_callbacks()
  self:bind_close_btn(self._btn_close_normal)
  if not_null(self._btn_info_dark) then
    self:bind_callback(self._btn_info_dark, pack(self, M._on_btn_info_click))
  end
end

function M:_on_btn_info_click()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  local intro_id = season_cfg and season_cfg.introductionid or 0
  if 0 < intro_id then
    common_ui_module:show_introduction_dialog(intro_id)
  end
end

function M:_create_btn_panels()
  if not_null(self._trans_btn_01) then
    self._btn_panels[1] = self:add_panel(btn_impression_cls, self._trans_btn_01)
  end
  if not_null(self._trans_btn_02) then
    self._btn_panels[2] = self:add_panel(btn_daily_task_cls, self._trans_btn_02)
  end
  if not_null(self._trans_btn_03) then
    self._btn_panels[3] = self:add_panel(btn_story_cls, self._trans_btn_03)
  end
  if not_null(self._trans_btn_04) then
    self._btn_panels[4] = self:add_panel(btn_buy_cls, self._trans_btn_04)
  end
  if not_null(self._trans_btn_05) then
    self._btn_panels[5] = self:add_panel(btn_star_explore_cls, self._trans_btn_05)
  end
end

function M:_bind_btn_callbacks()
  for _, panel in pairs(self._btn_panels) do
    local btn = panel:get_btn()
    if not_null(btn) then
      self:bind_callback(btn, pack(panel, panel._on_click))
    end
  end
end

function M:refresh()
  theme_season_module:update_season_time_state()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  if season_cfg then
    UIUtil.set_text(self._txt_title, season_cfg.title or "")
    UIUtil.set_text(self._txt_title_top, theme_season_module:get_season_name() or "")
    UIUtil.set_text(self._txt_program, season_cfg.desc or "")
  end
  self._last_remain_seconds = -1
  self:_refresh_remaining_time()
  for _, panel in pairs(self._btn_panels) do
    if panel.refresh then
      panel:refresh()
    end
  end
end

function M:_refresh_remaining_time()
  local remain = theme_season_module:get_remaining_seconds()
  if remain == self._last_remain_seconds then
    return
  end
  self._last_remain_seconds = remain
  local time_text = theme_season_module:format_season_remaining_time(remain)
  UIUtil.set_text(self._txt_time, time_text)
end

function M:_check_first_pv_play()
  local season_id = theme_season_module:get_cur_season_id()
  if season_id == 0 then
    return
  end
  local pv_id = theme_season_module:get_story_part_pv(1)
  if pv_id == 0 or theme_season_module:is_pv_watched(pv_id) then
    return
  end
  self:_play_pv_full_screen(pv_id)
end

function M:_play_pv_full_screen(pv_id)
  if pv_id == 0 then
    return
  end
  local task = VideoTask()
  if not task:InitByCfgId(pv_id) then
    return
  end
  task.isLoop = false
  task.canSkip = true
  theme_season_module:mark_pv_watched(pv_id)
  EventCenter.Broadcast(EventID.LuaShowFullScreenVideo, task)
end

return M
