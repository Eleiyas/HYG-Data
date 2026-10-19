local daily_item_cls = "UI/ThemeSeason/ThemeSeasonDailyItem"
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local remaining_time_refresh_interval = 1
local M = G.Class("ThemeSeasonDailyPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BattlePass/ThemeSeasonDailyPage"
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  self._daily_items = {}
  self._coin_view = nil
  self._remaining_time_refresh_timer = 0
  self._sub_title = nil
  self._btn_back = nil
  self._btn_claim_all = nil
  self._tog_img_switch = nil
  self._list_content = nil
  self._trans_coin_item_01 = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self:_create_coin_view()
end

function M:on_open()
  base.on_open(self)
  theme_season_module:report_page_reach(theme_season_module.REPORT_PAGE_ID.DAILY)
end

function M:on_enable()
  base.on_enable(self)
  self._remaining_time_refresh_timer = 0
  self:_refresh_view()
  theme_season_module:try_show_season_expired_popup()
end

function M:on_disable()
  base.on_disable(self)
  self._remaining_time_refresh_timer = 0
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  self._remaining_time_refresh_timer = self._remaining_time_refresh_timer + deltaTime
  if self._remaining_time_refresh_timer < remaining_time_refresh_interval then
    return
  end
  self._remaining_time_refresh_timer = 0
  self:_refresh_remaining_time()
end

function M:on_destroy()
  self._daily_items = {}
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_season_daily_mission_reward, pack(self, M._on_claim_reward_rsp))
  self:add_lua_listener(lua_event_module.event_type.on_season_daily_mission_update, pack(self, M._on_mission_update))
  self:add_lua_listener(lua_event_module.event_type.on_season_daily_mission_changed, pack(self, M._on_mission_full_changed))
end

function M:_add_ui_listener()
  if not_null(self._btn_back) then
    self:bind_close_btn(self._btn_back)
  end
  if not_null(self._btn_claim_all) then
    self:bind_callback(self._btn_claim_all, pack(self, M._on_btn_claim_all_click))
  end
  if not_null(self._tog_img_switch) then
    self:bind_callback(self._tog_img_switch, pack(self, M._on_tog_img_switch_click))
  end
end

function M:_refresh_view()
  self:_refresh_mission_list()
  self:_refresh_top_bar()
  self:_refresh_bottom_bar()
  self:_sync_track_toggle()
end

function M:_refresh_mission_list()
  local mission_list = theme_season_module:get_daily_mission_list()
  for index = 1, #mission_list do
    local mission = mission_list[index]
    local item = self._daily_items[index]
    if item == nil then
      item = self:_create_mission_item()
      self._daily_items[index] = item
    end
    if item ~= nil then
      item:set_active(true)
      item:set_extra_data(mission.tracker_id)
      item:refresh_view()
    end
  end
  for i = #mission_list + 1, #self._daily_items do
    local item = self._daily_items[i]
    if item ~= nil then
      item:set_extra_data(nil)
      item:set_active(false)
    end
  end
end

function M:_create_mission_item()
  if is_null(self._list_content) then
    return nil
  end
  local obj = self._list_content:AddItem(0)
  if is_null(obj) then
    return nil
  end
  local item = self:add_panel(daily_item_cls, obj)
  return item
end

function M:_refresh_mission_item_by_tracker(tracker_id)
  for i = 1, #self._daily_items do
    local item = self._daily_items[i]
    if item ~= nil and item:get_tracker_id() == tracker_id then
      item:refresh_view()
      return
    end
  end
end

function M:_refresh_top_bar()
  self:_refresh_remaining_time()
end

function M:_refresh_remaining_time()
  if is_null(self._sub_title) then
    return
  end
  local remain = CsUIUtil.SecondsToNextCrossDay()
  UIUtil.set_text_by_id(self._sub_title, "LemiFootPrintSeason_TimeLeft", LuaTimeUtil.get_time_str(remain))
end

function M:_create_coin_view()
  if is_null(self._trans_coin_item_01) then
    return
  end
  local season_cfg = theme_season_module:get_cur_season_cfg()
  local coin_id = season_cfg and season_cfg.token1 or 0
  if coin_id <= 0 then
    return
  end
  self._coin_view = self:add_panel(coin_item_view_cls, self._trans_coin_item_01, {
    coin_id = coin_id,
    auto_update = true,
    show_detail = true,
    on_add_click = pack(theme_season_module, theme_season_module.on_coin_item_add_click)
  })
end

function M:_refresh_bottom_bar()
  if not_null(self._btn_claim_all) then
    UIUtil.set_active(self._btn_claim_all, theme_season_module:has_daily_claimable())
  end
end

function M:_on_btn_claim_all_click()
  local tracker_ids = theme_season_module:get_daily_claimable_tracker_ids()
  if #tracker_ids == 0 then
    return
  end
  for i = 1, #tracker_ids do
    self:request_claim_reward(tracker_ids[i])
  end
end

function M:_sync_track_toggle()
  if is_null(self._tog_img_switch) then
    return
  end
  local group_id = theme_season_module:get_daily_group_id()
  local is_on = 0 < group_id and tracking_module:is_tracking_by_track_type(tracking_module.track_type.feature, tracking_module.data_source_type.theme_season_daily_task, group_id)
  self._tog_img_switch:SetIsOnWithoutNotify(is_on)
end

function M:_on_tog_img_switch_click(is_on)
  local group_id = theme_season_module:get_daily_group_id()
  if group_id <= 0 then
    return
  end
  local feature_type = tracking_module.track_type.feature
  local source_type = tracking_module.data_source_type.theme_season_daily_task
  tracking_module:set_tracking_by_track_type(feature_type, source_type, group_id, is_on, true)
  if is_on then
    tracking_module:set_cur_track_type(feature_type)
    CsTrackingModuleUtil.RefreshDicTrackData(TrackType.Feature)
    UIUtil.show_tips_by_text_id("Memo_SettingTacking")
  else
    UIUtil.show_tips_by_text_id("Memo_NoSettingTacking")
  end
end

function M:request_claim_reward(tracker_id)
  if tracker_id == nil or tracker_id <= 0 then
    return
  end
  if theme_season_module:get_daily_mission_state(tracker_id) ~= theme_season_module.DAILY_MISSION_STATE.CLAIMABLE then
    return
  end
  if theme_season_module:is_reward_pending(tracker_id) then
    return
  end
  theme_season_module:set_reward_pending(tracker_id)
  local req = {}
  req.TrackerId = tracker_id
  NetHandlerIns:send_data(ClaimSeasonDailyMissionRewardReq, req)
end

function M:_on_claim_reward_rsp(rsp)
  if rsp == nil then
    return
  end
  if rsp.Retcode ~= 0 then
    return
  end
  local tracker_id = rsp.TrackerId or 0
  self:_refresh_mission_item_by_tracker(tracker_id)
  self:_refresh_bottom_bar()
end

function M:_on_mission_update(tracker_id)
  if tracker_id and 0 < tracker_id then
    self:_refresh_mission_item_by_tracker(tracker_id)
  else
    self:_refresh_view()
  end
  self:_refresh_bottom_bar()
end

function M:_on_mission_full_changed()
  self:_refresh_view()
end

return M
