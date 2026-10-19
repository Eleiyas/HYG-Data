local M = G.Class("ThemeSeasonChapterDetailPage", G.UIWindow)
local base = G.UIWindow
local dot_cls = "UI/ThemeSeason/ThemeSeasonChapterDetailPageDot"
local CHAPTER_STATE = theme_season_module.CHAPTER_STATE
local ANIM_TRIGGER = theme_season_module.ANIM_TRIGGER
local BTN_STATE = {JUMP_TASK = 0, TASK_FINISHED = 1}
local CHAPTER_TO_BTN = {
  [CHAPTER_STATE.IN_PROGRESS] = BTN_STATE.JUMP_TASK,
  [CHAPTER_STATE.CLAIMABLE] = BTN_STATE.TASK_FINISHED,
  [CHAPTER_STATE.LOCKED] = BTN_STATE.JUMP_TASK,
  [CHAPTER_STATE.CLAIMED] = BTN_STATE.TASK_FINISHED
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BattlePass/BattlePassSeasonPlotDetailsPage"
  self.config.type = EUIType.Page
  self._chapters = {}
  self._selected_index = 0
  self._dot_items = {}
  self._img_photo_dynamic = nil
  self._btn_arrow_left = nil
  self._btn_arrow_right = nil
  self._txt_title = nil
  self._txt_desc = nil
  self._trans_empty_group = nil
  self._btn_close_normal = nil
  self._btn_find = nil
  self._txt_unlock_tip = nil
  self._trans_layout_dot = nil
  self._list_item_dot = nil
  self._ui_state_group = nil
  self._ui_state_group_chapter = nil
  self._animator_center = nil
end

function M:_play_center_anim(trigger)
  if is_null(self._animator_center) or not self._animator_center.gameObject.activeInHierarchy then
    return
  end
  self._animator_center:SetTrigger(trigger)
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_theme_season_data_changed, pack(self, M._on_season_info_changed))
end

function M:on_open()
  base.on_open(self)
  theme_season_module:report_page_reach(theme_season_module.REPORT_PAGE_ID.CHAPTER_DETAIL)
  self._selected_index = 0
end

function M:on_enable()
  base.on_enable(self)
  local extra_data = self:get_extra_data()
  if extra_data then
    self._chapters = extra_data.chapters or {}
    self._selected_index = extra_data.selected_index or 1
    self:set_extra_data(nil)
  end
  self:_refresh_page()
  self:_play_center_anim(ANIM_TRIGGER.IN)
  theme_season_module:try_show_season_expired_popup()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  self._dot_items = {}
  self._chapters = {}
  base.on_destroy(self)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close_normal)
  if not_null(self._btn_arrow_left) then
    self:bind_callback(self._btn_arrow_left, pack(self, M._on_arrow_left_click))
  end
  if not_null(self._btn_arrow_right) then
    self:bind_callback(self._btn_arrow_right, pack(self, M._on_arrow_right_click))
  end
  if not_null(self._btn_find) then
    self:bind_callback(self._btn_find, pack(self, M._on_btn_find_click))
  end
end

function M:_refresh_page()
  local chapters = self._chapters
  if chapters == nil or #chapters == 0 then
    self:_show_empty(true)
    return
  end
  self:_show_empty(false)
  self:_refresh_dots()
  self:_select_chapter(self._selected_index)
end

function M:_show_empty(show)
  UIUtil.set_active(self._trans_empty_group, show)
end

function M:_refresh_dots()
  local count = #self._chapters
  local show_dots = 1 < count
  UIUtil.set_active(self._trans_layout_dot, show_dots)
  if not show_dots then
    return
  end
  for i = 1, count do
    local dot = self._dot_items[i]
    if dot == nil then
      dot = self:_create_dot_item(i)
      self._dot_items[i] = dot
    end
    if dot then
      dot:set_active(true)
    end
  end
  for i = count + 1, #self._dot_items do
    local dot = self._dot_items[i]
    if dot then
      dot:set_active(false)
    end
  end
end

function M:_create_dot_item(index)
  if is_null(self._list_item_dot) then
    return nil
  end
  local obj = self._list_item_dot:AddItem(0)
  if is_null(obj) then
    return nil
  end
  local dot = self:add_panel(dot_cls, obj)
  if dot == nil then
    return nil
  end
  dot:set_data(index, pack(self, M._on_dot_selected))
  return dot
end

function M:_on_dot_selected(index)
  if index == self._selected_index then
    return
  end
  self:_select_chapter(index)
  self:_play_center_anim(ANIM_TRIGGER.NEXT)
end

function M:_sync_dot_visuals()
  local dot = self._dot_items[self._selected_index]
  if dot then
    dot:set_selected(true)
  end
end

function M:_select_chapter(index)
  local count = #self._chapters
  if index < 1 or index > count then
    return
  end
  self._selected_index = index
  self:_refresh_chapter_content()
  self:_refresh_arrows()
  self:_sync_dot_visuals()
end

function M:_refresh_chapter_content()
  local chapter = self._chapters[self._selected_index]
  if chapter == nil then
    return
  end
  if not_null(self._txt_title) then
    UIUtil.set_text(self._txt_title, chapter.title or "")
  end
  if not_null(self._txt_desc) then
    local desc = chapter.desc or ""
    if theme_season_module:is_debug_mode() then
      desc = desc .. self:_build_debug_desc_suffix(chapter)
    end
    UIUtil.set_text(self._txt_desc, desc)
  end
  local btn_state = CHAPTER_TO_BTN[chapter.state] or BTN_STATE.JUMP_TASK
  if not_null(self._ui_state_group) then
    self._ui_state_group:SetState(btn_state)
  end
  if not_null(self._ui_state_group_chapter) then
    local unlocked = chapter.state ~= CHAPTER_STATE.LOCKED
    self._ui_state_group_chapter:SetState(unlocked and 1 or 0)
  end
  self:_refresh_unlock_tip(chapter)
  self:_refresh_banner(chapter)
end

function M:_build_debug_desc_suffix(chapter)
  local story_task_cfg = theme_season_module:get_theme_season_story_task_cfg_by_id(chapter.id)
  if story_task_cfg == nil then
    return ""
  end
  local begin_task = story_task_cfg.begintask or 0
  local end_task = story_task_cfg.endtask or 0
  local activity_id = theme_season_module:get_chapter_activity_id(story_task_cfg)
  local suffix = string.format([[

[Debug] BeginTask=%d(%s) EndTask=%d(%s) ActivityId=%d]], begin_task, self:_debug_task_state_text(begin_task), end_task, self:_debug_task_state_text(end_task), activity_id)
  if 0 < activity_id then
    suffix = suffix .. "(" .. self:_debug_activity_state_text(activity_id) .. ")"
  end
  return suffix
end

function M:_debug_task_state_text(task_id)
  if task_id == nil or task_id <= 0 then
    return "-"
  end
  local state = task_module:get_task_data():GetTaskState(task_id)
  local label
  if state == NewTaskState.Complete then
    label = "已完成"
  elseif state == NewTaskState.Ongoing then
    label = "进行中"
  elseif state == NewTaskState.NotReceive then
    label = "未接取"
  elseif state == NewTaskState.Unlock then
    label = "已解锁未接"
  elseif state == NewTaskState.Freeze then
    label = "冻结"
  else
    label = "未知"
  end
  return string.format("%s:%s", label, tostring(state))
end

function M:_debug_activity_state_text(activity_id)
  local start_ts = theme_season_module:get_activity_start_ts(activity_id) or 0
  local end_ts = theme_season_module:get_activity_end_ts(activity_id) or 0
  if start_ts <= 0 and end_ts <= 0 then
    return "无时间范围"
  end
  
  local function fmt(ts)
    if ts <= 0 then
      return "-"
    end
    return os.date("!%m-%d %H:%M", ts + 28800)
  end
  
  local now = TimeUtil.ServerUtcTimeSeconds
  local state
  if 0 < start_ts and start_ts > now then
    state = string.format("未开启,剩%ds", math.floor(start_ts - now))
  elseif 0 < end_ts and end_ts <= now then
    state = "已结束"
  else
    state = "已开启"
  end
  return string.format("起:%s 止:%s %s", fmt(start_ts), fmt(end_ts), state)
end

function M:_refresh_banner(chapter)
  if is_null(self._img_photo_dynamic) then
    return
  end
  local banner_path = chapter.banner or ""
  if banner_path ~= "" then
    UIUtil.set_image(self._img_photo_dynamic, banner_path, self:get_load_proxy())
  end
end

function M:_refresh_unlock_tip(chapter)
  if is_null(self._txt_unlock_tip) then
    return
  end
  local is_debug = theme_season_module:is_debug_mode()
  if (chapter and chapter.state) ~= CHAPTER_STATE.LOCKED then
    if is_debug then
      UIUtil.set_text(self._txt_unlock_tip, self:_build_debug_desc_suffix(chapter))
    end
    return
  end
  local reason = chapter.unlock_reason or theme_season_module.CHAPTER_UNLOCK_REASON.NONE
  local tip
  if reason == theme_season_module.CHAPTER_UNLOCK_REASON.TIME then
    local start_ts = chapter.start_time or 0
    local now = TimeUtil.ServerUtcTimeSeconds
    local remain = 0 < start_ts and start_ts > now and start_ts - now or 0
    tip = theme_season_module:format_unlock_remaining_time(remain)
  else
    tip = UIUtil.get_text_by_id("ThemeSeason_UI_021")
  end
  if is_debug then
    tip = tip .. self:_build_debug_desc_suffix(chapter)
  end
  UIUtil.set_text(self._txt_unlock_tip, tip)
end

function M:_refresh_arrows()
  local count = #self._chapters
  local index = self._selected_index
  if not_null(self._btn_arrow_left) then
    UIUtil.set_active(self._btn_arrow_left, 1 < index)
  end
  if not_null(self._btn_arrow_right) then
    UIUtil.set_active(self._btn_arrow_right, count > index)
  end
end

function M:_on_arrow_left_click()
  if self._selected_index > 1 then
    self:_select_chapter(self._selected_index - 1)
    self:_play_center_anim(ANIM_TRIGGER.NEXT)
  end
end

function M:_on_arrow_right_click()
  if self._selected_index < #self._chapters then
    self:_select_chapter(self._selected_index + 1)
    self:_play_center_anim(ANIM_TRIGGER.NEXT)
  end
end

function M:_on_btn_find_click()
  local chapter = self._chapters[self._selected_index]
  theme_season_module:goto_season_task_in_memo(chapter and chapter.id or 0)
end

function M:_on_season_info_changed()
  if self._chapters == nil or #self._chapters == 0 then
    return
  end
  local acts = theme_season_module:build_story_acts_data()
  local old_chapter = self._chapters[self._selected_index]
  if old_chapter == nil then
    return
  end
  for _, act in ipairs(acts) do
    for _, ch in ipairs(act.chapters) do
      if ch.id == old_chapter.id then
        self._chapters = act.chapters
        self:_refresh_page()
        return
      end
    end
  end
end

return M
