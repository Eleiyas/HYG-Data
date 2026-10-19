local M = G.Class("ThemeSeasonPlotPage", G.UIWindow)
local base = G.UIWindow
local chapter_item_cls = "UI/ThemeSeason/ThemeSeasonChapterItem"
local tab_cls = "UI/ThemeSeason/ThemeSeasonPlotPageTab"
local CHAPTER_STATE = theme_season_module.CHAPTER_STATE
local CHAPTER_UNLOCK_REASON = theme_season_module.CHAPTER_UNLOCK_REASON

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BattlePass/BattlePassSeasonPlotPage"
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  self._tab_items = {}
  self._chapter_items = {}
  self._selected_act_index = 0
  self._acts_data = {}
  self._last_remain_seconds = -1
  self._chapter_anim_queue = {}
  self._chapter_anim_elapsed = 0
  self._need_chapter_enter_anim = false
  self._trans_tabs = nil
  self._list_item_tabs = nil
  self._txt_title = nil
  self._trans_content = nil
  self._list_item_content = nil
  self._trans_empty_group = nil
  self._btn_close_normal = nil
  self._txt_unlock_tip = nil
  self._btn_play = nil
  self._img_new_play = nil
  self._txt_remain_time = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_theme_season_data_changed, pack(self, M._rebuild))
end

function M:on_open()
  base.on_open(self)
  theme_season_module:report_page_reach(theme_season_module.REPORT_PAGE_ID.PLOT)
  self:_collect_data()
  self._selected_act_index = self:_calc_default_act_index()
end

function M:on_enable()
  base.on_enable(self)
  self._last_remain_seconds = -1
  self._need_chapter_enter_anim = true
  self:_refresh()
  theme_season_module:try_show_season_expired_popup()
end

function M:on_disable()
  self:_clear_chapter_anim_queue()
  self._need_chapter_enter_anim = false
  base.on_disable(self)
end

function M:play_exit_anim()
  self:_clear_chapter_anim_queue()
  self:_play_all_chapters_exit_anim()
  base.play_exit_anim(self)
end

function M:on_before_close()
  base.on_before_close(self)
  if self._is_play_anim and self:get_cur_ui_state() == EUIState.Show then
    self:stop_playing_anim(true)
  end
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  self:_clear_chapter_anim_queue()
  self._tab_items = {}
  self._chapter_items = {}
  base.on_destroy(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  self:_refresh_remaining_time()
  self:_drive_chapter_anim_queue(deltaTime)
end

function M:_clear_chapter_anim_queue()
  self._chapter_anim_queue = {}
  self._chapter_anim_elapsed = 0
end

function M:_schedule_chapter_enter_anims(count)
  self:_clear_chapter_anim_queue()
  local queue = self._chapter_anim_queue
  for i = 1, count do
    local item = self._chapter_items[i]
    if item then
      item:prepare_enter_anim()
      queue[#queue + 1] = {
        at = (i - 1) * theme_season_module.ITEM_ENTER_STAGGER_SEC,
        item = item
      }
    end
  end
  self:_drive_chapter_anim_queue(0)
end

function M:_drive_chapter_anim_queue(delta_time)
  local queue = self._chapter_anim_queue
  if #queue == 0 then
    return
  end
  self._chapter_anim_elapsed = self._chapter_anim_elapsed + delta_time
  local elapsed = self._chapter_anim_elapsed
  local rest = {}
  for _, entry in ipairs(queue) do
    if elapsed >= entry.at then
      if entry.item.is_active then
        entry.item:replay_anim(true)
      end
    else
      rest[#rest + 1] = entry
    end
  end
  self._chapter_anim_queue = rest
  if #rest == 0 then
    self._chapter_anim_elapsed = 0
  end
end

function M:_play_all_chapters_exit_anim()
  for _, item in ipairs(self._chapter_items) do
    if item and item.is_active then
      item:replay_anim(false)
    end
  end
end

function M:_refresh_remaining_time()
  if is_null(self._txt_remain_time) then
    return
  end
  local remain = theme_season_module:get_remaining_seconds()
  if remain == self._last_remain_seconds then
    return
  end
  self._last_remain_seconds = remain
  UIUtil.set_text(self._txt_remain_time, theme_season_module:format_season_remaining_time(remain))
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close_normal)
  if not_null(self._btn_play) then
    self:bind_callback(self._btn_play, pack(self, M._on_btn_play_click))
  end
end

function M:_collect_data()
  self._acts_data = self:_get_acts_data()
end

function M:_refresh()
  self:_refresh_tabs()
  self:_select_act(self._selected_act_index)
end

function M:_rebuild()
  self:_collect_data()
  if self._selected_act_index < 1 or self._selected_act_index > #self._acts_data then
    self._selected_act_index = self:_calc_default_act_index()
  end
  self:_refresh()
end

function M:_refresh_title()
  if is_null(self._txt_title) then
    return
  end
  local act = self._acts_data[self._selected_act_index]
  if act then
    UIUtil.set_text(self._txt_title, act.desc or "")
  end
end

function M:_refresh_tabs()
  local acts = self._acts_data
  for i = 1, #acts do
    local act = acts[i]
    local tab = self._tab_items[i]
    if tab == nil then
      tab = self:_create_tab_item(i)
      self._tab_items[i] = tab
    end
    if tab then
      tab:refresh(act, i)
      tab:set_active(true)
    end
  end
  for i = #acts + 1, #self._tab_items do
    local tab = self._tab_items[i]
    if tab then
      tab:set_active(false)
    end
  end
end

function M:_create_tab_item(index)
  if is_null(self._list_item_tabs) then
    return nil
  end
  local obj = self._list_item_tabs:AddItem(0)
  if is_null(obj) then
    return nil
  end
  local tab = self:add_panel(tab_cls, obj)
  if tab == nil then
    return nil
  end
  local toggle = tab:get_toggle()
  if not_null(toggle) then
    self:bind_callback(toggle, pack(self, function(s, is_on)
      s:_on_tab_toggle_changed(index, is_on)
    end))
  end
  return tab
end

function M:_on_tab_toggle_changed(index, is_on)
  if not is_on then
    return
  end
  if index == self._selected_act_index then
    return
  end
  self._need_chapter_enter_anim = true
  self:_select_act(index)
end

function M:_calc_default_act_index()
  local default_index = 1
  for i, act in ipairs(self._acts_data) do
    for _, chapter in ipairs(act.chapters) do
      if chapter.state ~= CHAPTER_STATE.LOCKED then
        default_index = i
        break
      end
    end
    if default_index ~= 1 then
      break
    end
  end
  return default_index
end

function M:_select_act(index)
  if index < 1 or index > #self._acts_data then
    return
  end
  self._selected_act_index = index
  local act = self._acts_data[index]
  if act then
    theme_season_module:mark_story_act_seen(act.id)
    local tab = self._tab_items[index]
    if tab then
      tab:refresh_red_point(act)
    end
  end
  self:_refresh_title()
  self:_refresh_chapters()
  self:_sync_tab_visuals()
  self:_refresh_unlock_tip()
  self:_refresh_play_button()
end

function M:_refresh_play_button()
  local act = self._acts_data[self._selected_act_index]
  local pv_id = act and act.pv or 0
  if not_null(self._btn_play) then
    UIUtil.set_active(self._btn_play, 0 < pv_id)
  end
  if not_null(self._img_new_play) then
    UIUtil.set_active(self._img_new_play, 0 < pv_id and not theme_season_module:is_pv_watched(pv_id))
  end
end

function M:_on_btn_play_click()
  local act = self._acts_data[self._selected_act_index]
  local pv_id = act and act.pv or 0
  if pv_id == 0 then
    UIUtil.show_tips_by_text_id("ThemeSeason_UI_008")
    return
  end
  local ctx = {
    title = act.desc or nil,
    video_cfg_id = pv_id,
    auto_play = true,
    is_loop = true,
    can_skip = true,
    on_close = function()
      theme_season_module:mark_pv_watched(pv_id)
      self:_refresh_play_button()
    end
  }
  UIManagerInstance:open("UI/CommonUI/VideoPreviewDialog", ctx)
end

function M:_is_act_opened(act)
  return theme_season_module:is_act_opened_by_data(act)
end

function M:_refresh_unlock_tip()
  if is_null(self._txt_unlock_tip) then
    return
  end
  local act = self._acts_data[self._selected_act_index]
  local start_ts = act and act.start_time or 0
  if 0 < start_ts and start_ts > TimeUtil.ServerUtcTimeSeconds then
    local year, month, day, hour, min = LuaTimeUtil.get_date_time_from_timestamp(start_ts)
    UIUtil.set_text_by_id(self._txt_unlock_tip, "ThemeSeason_UI_037", year, month, day, hour, string.format("%02d", min))
    UIUtil.set_active(self._txt_unlock_tip, true)
    return
  end
  local reason = act and act.unlock_reason or CHAPTER_UNLOCK_REASON.NONE
  if reason == CHAPTER_UNLOCK_REASON.PREV_TASK then
    local prev_act = self._acts_data[self._selected_act_index - 1]
    UIUtil.set_text_by_id(self._txt_unlock_tip, "ThemeSeason_UI_085", prev_act and prev_act.title or "")
    UIUtil.set_active(self._txt_unlock_tip, true)
  else
    UIUtil.set_active(self._txt_unlock_tip, false)
  end
end

function M:_sync_tab_visuals()
  for i, tab in ipairs(self._tab_items) do
    if tab then
      tab:set_selected(i == self._selected_act_index)
    end
  end
end

function M:_refresh_chapters()
  local need_enter_anim = self._need_chapter_enter_anim
  self._need_chapter_enter_anim = false
  local act = self._acts_data[self._selected_act_index]
  if act == nil then
    self:_show_empty(true)
    return
  end
  if not self:_is_act_opened(act) then
    self:_show_empty(true)
    return
  end
  local chapters = act.chapters
  if chapters == nil or #chapters == 0 then
    self:_show_empty(true)
    return
  end
  self:_show_empty(false)
  for i = 1, #chapters do
    local chapter_data = chapters[i]
    local item = self._chapter_items[i]
    if item == nil then
      item = self:_create_chapter_item()
      self._chapter_items[i] = item
    end
    if item then
      item:refresh(chapter_data, i, chapters)
      item:set_active(true, true)
    end
  end
  for i = #chapters + 1, #self._chapter_items do
    local item = self._chapter_items[i]
    if item then
      item:set_active(false)
    end
  end
  if need_enter_anim then
    self:_schedule_chapter_enter_anims(#chapters)
  end
end

function M:_create_chapter_item()
  if is_null(self._list_item_content) then
    return nil
  end
  local obj = self._list_item_content:AddItem(0)
  if is_null(obj) then
    return nil
  end
  local item = self:add_panel(chapter_item_cls, obj)
  return item
end

function M:_show_empty(show)
  UIUtil.set_active(self._trans_empty_group, show)
  UIUtil.set_active(self._trans_content, not show)
end

function M:_get_acts_data()
  return theme_season_module:build_story_acts_data()
end

return M
