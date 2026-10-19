theme_season_module = theme_season_module or {}

function theme_season_module:_init_data()
  self._cur_season_id = 1
  self._cur_season_state = theme_season_module.season_state.locked
  self._open_timestamp = 0
  self._end_timestamp = 0
  self._exchanged_graduate_ids = {}
  self._purchased_product_ids = {}
  self._claimed_story_reward_ids = {}
  self._npc_exchanged_goods = {}
  self._debug_mode = false
  self._daily_group_id = 0
  self._daily_mission_map = {}
  self._daily_mission_list = {}
  self._daily_reward_pending = {}
  self._daily_mission_cfg_cache = nil
  self._act_open_activity_id_cache = {}
  self._expired_season_task_ids = {}
  self._pending_expired_dialog = false
  self._chapter_activity_id_cache = {}
end

function theme_season_module:set_cur_season_id(season_id)
  self._cur_season_id = season_id or 0
end

function theme_season_module:get_cur_season_id()
  return self._cur_season_id or 0
end

function theme_season_module:set_cur_season_state(state)
  self:_set_season_state(state or theme_season_module.season_state.locked)
end

function theme_season_module:get_cur_season_state()
  return self._cur_season_state or theme_season_module.season_state.locked
end

function theme_season_module:update_from_notify(notify)
  if notify == nil then
    return
  end
  local new_season_id = notify.SeasonId or 0
  if new_season_id ~= self._cur_season_id then
    self:clear_season_end_popup_pending()
    self:_set_season_time_unavailable()
    self._act_open_activity_id_cache = {}
  end
  self._cur_season_id = new_season_id
  self._exchanged_graduate_ids = {}
  if notify.ExchangedGraduateConfigIdList ~= nil then
    for i = 0, notify.ExchangedGraduateConfigIdList.Count - 1 do
      local id = notify.ExchangedGraduateConfigIdList[i]
      self._exchanged_graduate_ids[id] = true
    end
  end
  self._purchased_product_ids = {}
  if notify.PurchasedProductIdList ~= nil then
    for i = 0, notify.PurchasedProductIdList.Count - 1 do
      local id = notify.PurchasedProductIdList[i]
      self._purchased_product_ids[id] = true
    end
  end
  self._claimed_story_reward_ids = {}
  if notify.ClaimedStoryRewardIdList ~= nil then
    for i = 0, notify.ClaimedStoryRewardIdList.Count - 1 do
      local id = notify.ClaimedStoryRewardIdList[i]
      self._claimed_story_reward_ids[id] = true
    end
  end
  self:invalidate_npc_goods_cache()
end

function theme_season_module:is_graduate_exchanged(config_id)
  return self._exchanged_graduate_ids[config_id] == true
end

function theme_season_module:add_exchanged_graduate(config_id)
  if config_id and 0 < config_id then
    self._exchanged_graduate_ids[config_id] = true
  end
end

function theme_season_module:is_product_purchased(product_id)
  return self._purchased_product_ids[product_id] == true
end

function theme_season_module:add_purchased_product(product_id)
  if product_id and 0 < product_id then
    self._purchased_product_ids[product_id] = true
  end
end

function theme_season_module:has_purchased_bp()
  return next(self._purchased_product_ids) ~= nil
end

function theme_season_module:is_debug_mode()
  return self._debug_mode == true
end

function theme_season_module:set_debug_mode(on)
  self._debug_mode = on == true
end

function theme_season_module:update_npc_exchange_data(notify)
  if notify == nil then
    return
  end
  self._npc_exchanged_goods = {}
  local list = notify.NpcExchangeDataList
  if list ~= nil then
    for i = 0, list.Count - 1 do
      local data = list[i]
      local npc_id = data.NpcId or 0
      if 0 < npc_id then
        local set = {}
        local goods_list = data.ExchangedGoodsConfigIdList
        if goods_list ~= nil then
          for j = 0, goods_list.Count - 1 do
            set[goods_list[j]] = true
          end
        end
        self._npc_exchanged_goods[npc_id] = set
      end
    end
  end
  self:invalidate_npc_goods_cache()
end

function theme_season_module:add_npc_exchanged_goods(npc_id, goods_config_id)
  if npc_id == nil or npc_id <= 0 or goods_config_id == nil or goods_config_id <= 0 then
    return
  end
  if self._npc_exchanged_goods[npc_id] == nil then
    self._npc_exchanged_goods[npc_id] = {}
  end
  self._npc_exchanged_goods[npc_id][goods_config_id] = true
end

function theme_season_module:is_npc_goods_exchanged(npc_id, goods_config_id)
  local set = self._npc_exchanged_goods[npc_id]
  if set == nil then
    return false
  end
  return set[goods_config_id] == true
end

function theme_season_module:get_npc_id_by_goods_config_id(goods_config_id)
  if goods_config_id == nil or goods_config_id <= 0 then
    return 0
  end
  local cfg = self:get_theme_season_npc_goods_cfg_by_id(goods_config_id)
  if cfg == nil then
    return 0
  end
  return cfg.npcid or 0
end

function theme_season_module:get_npc_current_level(npc_id)
  if npc_id == nil or npc_id <= 0 then
    return 1
  end
  local rows = self:_get_npc_goods_cfg_index()[npc_id]
  if rows == nil then
    return 1
  end
  local free_entries = {}
  for _, cfg in ipairs(rows) do
    if cfg.bp == nil or cfg.bp ~= 1 then
      free_entries[#free_entries + 1] = cfg
    end
  end
  table.sort(free_entries, function(a, b)
    return (a.level or 0) < (b.level or 0)
  end)
  for _, cfg in ipairs(free_entries) do
    if not self:is_npc_goods_exchanged(npc_id, cfg.id) then
      return cfg.level or 1
    end
  end
  local max_level = 0
  for _, cfg in ipairs(free_entries) do
    if max_level < (cfg.level or 0) then
      max_level = cfg.level
    end
  end
  return max_level + 1
end

function theme_season_module:is_story_reward_claimed(story_task_cfg_id)
  return self._claimed_story_reward_ids[story_task_cfg_id] == true
end

function theme_season_module:add_claimed_story_reward(story_task_cfg_id)
  if story_task_cfg_id and 0 < story_task_cfg_id then
    self._claimed_story_reward_ids[story_task_cfg_id] = true
  end
end

function theme_season_module:is_open_state_unlocked()
  return OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateThemeSeason)
end

function theme_season_module:_set_season_state(state)
  local prev_state = self._cur_season_state
  self._cur_season_state = state
  if state == theme_season_module.season_state.ended then
    self:_clear_daily_mission_tracking()
  end
  if prev_state == theme_season_module.season_state.active and state == theme_season_module.season_state.ended then
    self:mark_season_end_popup_pending()
  end
end

function theme_season_module:_set_season_time_unavailable()
  self:_set_season_state(theme_season_module.season_state.locked)
  self._open_timestamp = 0
  self._end_timestamp = 0
end

function theme_season_module:_is_season_activity_closed(activity_data)
  if activity_data.IsAdvance then
    return false
  end
  return activity_data.State == activity_center_module.activity_state.None
end

function theme_season_module:update_season_time_state()
  if not self:is_open_state_unlocked() then
    self:_set_season_time_unavailable()
    return
  end
  local season_id = self:get_cur_season_id()
  if season_id <= 0 then
    self:_set_season_time_unavailable()
    return
  end
  local season_cfg = self:get_cur_season_cfg()
  if season_cfg == nil then
    self:_set_season_time_unavailable()
    return
  end
  local activity_id = season_cfg.activityid or 0
  if activity_id <= 0 then
    self:_set_season_time_unavailable()
    return
  end
  local activity_data = activity_center_module:get_activity_by_id(activity_id)
  if activity_data == nil then
    if self:is_season_active() then
      self:_set_season_state(theme_season_module.season_state.ended)
    else
      self:_set_season_time_unavailable()
    end
    return
  end
  if not activity_data.HasTimeRange then
    self:_set_season_time_unavailable()
    return
  end
  self._open_timestamp = activity_data.StartTimeUtcSec
  self._end_timestamp = activity_data.EndTimeUtcSec
  local now = TimeUtil.ServerUtcTimeSeconds
  if 0 < self._open_timestamp and now < self._open_timestamp then
    self:_set_season_state(theme_season_module.season_state.locked)
  elseif self:_is_season_activity_closed(activity_data) or 0 < self._end_timestamp and now >= self._end_timestamp then
    self:_set_season_state(theme_season_module.season_state.ended)
  else
    self:_set_season_state(theme_season_module.season_state.active)
  end
end

function theme_season_module:get_open_timestamp()
  return self._open_timestamp or 0
end

function theme_season_module:get_end_timestamp()
  return self._end_timestamp or 0
end

function theme_season_module:get_remaining_seconds()
  local now = TimeUtil.ServerUtcTimeSeconds
  local state = self:get_cur_season_state()
  if state == theme_season_module.season_state.active then
    local remain = self._end_timestamp - now
    return 0 < remain and remain or 0
  elseif state == theme_season_module.season_state.locked and 0 < self._open_timestamp then
    local remain = self._open_timestamp - now
    return 0 < remain and remain or 0
  end
  return 0
end

function theme_season_module:is_season_active()
  return self:get_cur_season_state() == theme_season_module.season_state.active
end

function theme_season_module:is_season_locked()
  return self:get_cur_season_state() == theme_season_module.season_state.locked
end

function theme_season_module:is_season_ended()
  return self:get_cur_season_state() == theme_season_module.season_state.ended
end

function theme_season_module:is_pv_watched(pv_id)
  if pv_id == nil or pv_id == 0 then
    return true
  end
  return red_point_module:is_recorded_with_id(red_point_module.red_point_type.theme_season_pv_played, pv_id)
end

function theme_season_module:mark_pv_watched(pv_id)
  if pv_id == nil or pv_id == 0 then
    return
  end
  red_point_module:record_with_id(red_point_module.red_point_type.theme_season_pv_played, pv_id)
end

function theme_season_module:is_main_page_entered()
  local season_id = self:get_cur_season_id()
  if season_id == nil or season_id <= 0 then
    return true
  end
  return red_point_module:is_recorded_with_id(red_point_module.red_point_type.theme_season_main_page_entered, season_id)
end

function theme_season_module:mark_main_page_entered()
  local season_id = self:get_cur_season_id()
  if season_id == nil or season_id <= 0 then
    return
  end
  red_point_module:record_with_id(red_point_module.red_point_type.theme_season_main_page_entered, season_id)
end

function theme_season_module:is_bp_gift_opened()
  return red_point_module:is_recorded(red_point_module.red_point_type.theme_season_bp_gift_opened)
end

function theme_season_module:mark_bp_gift_opened()
  red_point_module:record(red_point_module.red_point_type.theme_season_bp_gift_opened)
end

function theme_season_module:get_season_activity_id()
  local season_cfg = self:get_cur_season_cfg()
  if season_cfg then
    return season_cfg.activityid or 0
  end
  return 0
end

function theme_season_module:get_theme_season_scene_id()
  local season_cfg = self:get_cur_season_cfg()
  if season_cfg then
    return season_cfg.scene
  end
  return 0
end

function theme_season_module:get_activity_start_ts(activity_id)
  if activity_id == nil or activity_id <= 0 then
    return 0
  end
  local activity_data = activity_center_module:get_activity_by_id(activity_id)
  if activity_data == nil or not activity_data.HasTimeRange then
    return 0
  end
  return activity_data.StartTimeUtcSec or 0
end

function theme_season_module:get_activity_end_ts(activity_id)
  if activity_id == nil or activity_id <= 0 then
    return 0
  end
  local activity_data = activity_center_module:get_activity_by_id(activity_id)
  if activity_data == nil or not activity_data.HasTimeRange then
    return 0
  end
  return activity_data.EndTimeUtcSec or 0
end

function theme_season_module:get_task_unlock_timestamp(task_id)
  if task_id == nil or task_id <= 0 then
    return 0
  end
  local season_id = self:get_cur_season_id()
  if season_id <= 0 then
    return 0
  end
  local part_ids = self:get_story_part_ids(season_id)
  for _, part_id in ipairs(part_ids) do
    local part_cfg = self:get_theme_season_story_part_cfg_by_id(part_id)
    if part_cfg then
      local task_cfg_ids = self:_parse_id_list(part_cfg.storyidlist)
      for _, task_cfg_id in ipairs(task_cfg_ids) do
        local story_task_cfg = self:get_theme_season_story_task_cfg_by_id(task_cfg_id)
        if story_task_cfg then
          local begin_id = story_task_cfg.begintask or 0
          local end_id = story_task_cfg.endtask or 0
          if begin_id == task_id or end_id == task_id then
            local activity_id = self:get_chapter_activity_id(story_task_cfg)
            return self:get_activity_start_ts(activity_id)
          end
        end
      end
    end
  end
  return 0
end

function theme_season_module:get_chapter_activity_id(story_task_cfg)
  local begin_task_id = story_task_cfg and story_task_cfg.begintask or 0
  if begin_task_id <= 0 then
    return 0
  end
  local cached = self._chapter_activity_id_cache[begin_task_id]
  if cached ~= nil and 0 < cached then
    return cached
  end
  local activity_id = 0
  local activity_ids = list_to_table(CsTaskModuleUtil.GetTaskFinishOpenedActivityIds(begin_task_id))
  if activity_ids and 0 < #activity_ids then
    activity_id = activity_ids[1] or 0
  end
  if 0 < activity_id then
    self._chapter_activity_id_cache[begin_task_id] = activity_id
  end
  return activity_id
end

function theme_season_module:is_season_story_chapter_activity(activity_id)
  if not activity_id or activity_id <= 0 then
    return false
  end
  if not self:is_season_active() then
    return false
  end
  local part_ids = self:get_story_part_ids()
  for _, part_id in ipairs(part_ids) do
    if self:_get_act_open_activity_id(part_id) == activity_id then
      return true
    end
  end
  return false
end

function theme_season_module:get_chapter_state(story_task_cfg)
  if not self:is_season_active() then
    return self.CHAPTER_STATE.LOCKED
  end
  local start_ts = self:get_activity_start_ts(self:get_chapter_activity_id(story_task_cfg))
  if 0 < start_ts then
    local now = TimeUtil.ServerUtcTimeSeconds
    if start_ts > now then
      return self.CHAPTER_STATE.LOCKED
    end
  end
  local task_cfg_id = story_task_cfg and story_task_cfg.id or 0
  if 0 < task_cfg_id and self:is_story_reward_claimed(task_cfg_id) then
    return self.CHAPTER_STATE.CLAIMED
  end
  local end_task_id = story_task_cfg and story_task_cfg.endtask or 0
  if 0 < end_task_id and task_module:task_is_finish(end_task_id) then
    return self.CHAPTER_STATE.CLAIMABLE
  end
  return self.CHAPTER_STATE.IN_PROGRESS
end

function theme_season_module:is_chapter_in_progress(story_task_cfg)
  local begin_task_id = story_task_cfg and story_task_cfg.begintask or 0
  if begin_task_id <= 0 then
    return false
  end
  local begin_received = task_module:task_is_ongoing(begin_task_id) or task_module:task_is_finish(begin_task_id)
  if not begin_received then
    return false
  end
  local end_task_id = story_task_cfg.endtask or 0
  return not (0 < end_task_id) or not task_module:task_is_finish(end_task_id)
end

function theme_season_module:get_chapter_unlock_remaining(story_task_cfg)
  local start_ts = self:get_activity_start_ts(self:get_chapter_activity_id(story_task_cfg))
  if start_ts <= 0 then
    return 0
  end
  local now = TimeUtil.ServerUtcTimeSeconds
  local remain = start_ts - now
  return 0 < remain and remain or 0
end

function theme_season_module:_is_chapter_prerequisite_satisfied(prev_chapter)
  if prev_chapter.state == self.CHAPTER_STATE.LOCKED then
    return false
  end
  local prev_end_task_id = prev_chapter.task_id or 0
  return prev_end_task_id <= 0 or task_module:task_is_finish(prev_end_task_id)
end

function theme_season_module:get_chapter_unlock_reason(story_task_cfg, prev_chapter)
  if prev_chapter and not self:_is_chapter_prerequisite_satisfied(prev_chapter) then
    return self.CHAPTER_UNLOCK_REASON.PREV_TASK, 0
  end
  local remain = self:get_chapter_unlock_remaining(story_task_cfg)
  if 0 < remain then
    return self.CHAPTER_UNLOCK_REASON.TIME, remain
  end
  return self.CHAPTER_UNLOCK_REASON.NONE, 0
end

function theme_season_module:_build_chapter_reward_items(story_task_cfg)
  local items = {}
  if story_task_cfg == nil then
    return items
  end
  local reward_items = item_module:get_random_pool_items(story_task_cfg.reward)
  if reward_items then
    for _, it in ipairs(reward_items) do
      items[#items + 1] = {
        id = it.id,
        num = it.num
      }
    end
  end
  return items
end

function theme_season_module:get_story_reward_items(story_task_id)
  if story_task_id == nil or story_task_id <= 0 then
    return {}
  end
  return self:_build_chapter_reward_items(self:get_theme_season_story_task_cfg_by_id(story_task_id))
end

function theme_season_module:build_story_acts_data(season_id)
  local part_ids = self:get_story_part_ids(season_id)
  local acts = {}
  local prev_chapter
  for _, part_id in ipairs(part_ids) do
    local part_cfg = self:get_theme_season_story_part_cfg_by_id(part_id)
    if part_cfg then
      local task_ids = self:_parse_id_list(part_cfg.storyidlist)
      local chapters = {}
      for _, task_id in ipairs(task_ids) do
        local task_cfg = self:get_theme_season_story_task_cfg_by_id(task_id)
        if task_cfg then
          local rewards = self:_build_chapter_reward_items(task_cfg)
          local unlock_reason, unlock_remaining = self:get_chapter_unlock_reason(task_cfg, prev_chapter)
          local state = self:get_chapter_state(task_cfg)
          if unlock_reason ~= self.CHAPTER_UNLOCK_REASON.NONE then
            state = self.CHAPTER_STATE.LOCKED
          end
          local chapter = {
            id = task_cfg.id,
            title = task_cfg.tasktitle or "",
            desc = task_cfg.taskdesc or "",
            task_id = task_cfg.endtask or 0,
            banner = task_cfg.banner or "",
            list_banner = task_cfg.listbanner or "",
            start_time = self:get_activity_start_ts(self:get_chapter_activity_id(task_cfg)),
            rewards = rewards,
            state = state,
            unlock_reason = unlock_reason,
            unlock_remaining = unlock_remaining
          }
          chapters[#chapters + 1] = chapter
          prev_chapter = chapter
        end
      end
      acts[#acts + 1] = {
        id = part_cfg.id,
        title = part_cfg.title or "",
        desc = part_cfg.desc or "",
        pv = part_cfg.pv or 0,
        start_time = chapters[1] and chapters[1].start_time or 0,
        unlock_reason = chapters[1] and chapters[1].unlock_reason or self.CHAPTER_UNLOCK_REASON.NONE,
        unlock_remaining = chapters[1] and chapters[1].unlock_remaining or 0,
        chapters = chapters
      }
    end
  end
  return acts
end

function theme_season_module:get_season_finished_story_task_count(season_id)
  local sid = season_id or self:get_cur_season_id()
  if sid <= 0 then
    return 0
  end
  local part_ids = self:get_story_part_ids(sid)
  local count = 0
  for _, part_id in ipairs(part_ids) do
    local part_cfg = self:get_theme_season_story_part_cfg_by_id(part_id)
    if part_cfg then
      local task_cfg_ids = self:_parse_id_list(part_cfg.storyidlist)
      for _, task_cfg_id in ipairs(task_cfg_ids) do
        local story_task_cfg = self:get_theme_season_story_task_cfg_by_id(task_cfg_id)
        if story_task_cfg and story_task_cfg.endtask and 0 < story_task_cfg.endtask and task_module:task_is_finish(story_task_cfg.endtask) then
          count = count + 1
        end
      end
    end
  end
  return count
end

function theme_season_module:_get_season_memo_category_id()
  return memo_module.grouping_type.main_task
end

function theme_season_module:get_season_memo_task_id(story_task_id)
  local task_ids = self:get_story_task_group_ids(story_task_id)
  if #task_ids == 0 then
    return 0
  end
  local category = memo_module:get_memo_category_data(memo_module.tab_type.task, self:_get_season_memo_category_id())
  if category == nil then
    return 0
  end
  local memo_task_ids = {}
  
  local function collect(grouping)
    if grouping == nil or grouping.nodes == nil then
      return
    end
    for _, node in ipairs(grouping.nodes) do
      local source_id = node.source_id or 0
      if 0 < source_id then
        memo_task_ids[source_id] = true
      end
    end
  end
  
  collect(category.top_grouping)
  for _, grouping in ipairs(category.middle_groupings or {}) do
    collect(grouping)
  end
  collect(category.bottom_grouping)
  for _, task_id in ipairs(task_ids) do
    if memo_task_ids[task_id] then
      return task_id
    end
  end
  return 0
end

function theme_season_module:get_graduation_items()
  local season_id = self:get_cur_season_id()
  if season_id <= 0 then
    return {}
  end
  local all_cfgs = self:get_theme_season_graduate_cfg()
  local items = {}
  local is_bp_purchased = self:has_purchased_bp()
  local finished_story_count = self:get_season_finished_story_task_count(season_id)
  local state_enum = self.GRADUATE_EXCHANGE_STATE
  for _, cfg in pairs(all_cfgs) do
    if cfg.seasonid == season_id then
      local exchange_state = state_enum.AVAILABLE
      local cost_item_id = cfg.costitemid or 0
      local cost_item_count = cfg.costitemcount or 0
      local required_count = cfg.finishstorytaskcount or 0
      if self:is_graduate_exchanged(cfg.id) then
        exchange_state = state_enum.EXCHANGED
      elseif not is_bp_purchased then
        exchange_state = state_enum.LOCKED
      elseif 0 < required_count and finished_story_count < required_count then
        exchange_state = state_enum.LOCKED
      elseif 0 < cost_item_id and 0 < cost_item_count and cost_item_count > back_bag_module:get_coin_or_item_num(cost_item_id) then
        exchange_state = state_enum.LACKED_COIN
      end
      items[#items + 1] = {
        config_id = cfg.id,
        item_id = cfg.itemid or 0,
        count = cfg.itemcount or 1,
        cost_item_id = cost_item_id,
        cost_item_count = cost_item_count,
        exchange_state = exchange_state,
        finished_story_count = finished_story_count,
        required_story_count = required_count
      }
    end
  end
  table.sort(items, function(a, b)
    return a.config_id < b.config_id
  end)
  return items
end

function theme_season_module:is_in_theme_season_scene()
  local cur_scene_id = GameSceneUtility.GetCurrentSceneId()
  return cur_scene_id == self:get_theme_season_scene_id()
end

function theme_season_module:_build_daily_mission_entry(data)
  return {
    tracker_id = data.TrackerId or 0,
    cur_progress = data.CurProgress or 0,
    total_progress = data.TotalProgress or 0,
    is_finish = data.IsFinish == true,
    is_reward_claimed = data.IsRewardClaimed == true
  }
end

function theme_season_module:update_from_daily_notify(notify)
  if notify == nil then
    return
  end
  self._daily_group_id = notify.DailyGroupId or 0
  self._daily_mission_map = {}
  self._daily_mission_list = {}
  self._daily_reward_pending = {}
  local list = notify.MissionDataList
  if list ~= nil then
    for i = 0, list.Count - 1 do
      local data = list[i]
      local entry = self:_build_daily_mission_entry(data)
      local tracker_id = entry.tracker_id
      if tracker_id and 0 < tracker_id and self._daily_mission_map[tracker_id] == nil then
        self._daily_mission_map[tracker_id] = entry
        self._daily_mission_list[#self._daily_mission_list + 1] = entry
      end
    end
  end
end

function theme_season_module:update_from_daily_mission_update(notify)
  if notify == nil then
    return
  end
  local tracker_id = notify.TrackerId or 0
  if tracker_id <= 0 then
    return
  end
  local entry = self._daily_mission_map[tracker_id]
  if entry == nil then
    entry = {
      tracker_id = tracker_id,
      cur_progress = 0,
      total_progress = 0,
      is_finish = false,
      is_reward_claimed = false
    }
    self._daily_mission_map[tracker_id] = entry
    self._daily_mission_list[#self._daily_mission_list + 1] = entry
  end
  entry.cur_progress = notify.CurProgress or entry.cur_progress
  entry.total_progress = notify.TotalProgress or entry.total_progress
  if notify.IsFinishConditionMet == true then
    entry.is_finish = true
  end
end

function theme_season_module:apply_daily_reward_claimed(tracker_id)
  if tracker_id == nil or tracker_id <= 0 then
    return
  end
  local entry = self._daily_mission_map[tracker_id]
  if entry then
    entry.is_reward_claimed = true
  end
  self:clear_reward_pending(tracker_id)
end

function theme_season_module:get_daily_group_id()
  return self._daily_group_id or 0
end

function theme_season_module:get_daily_mission_list()
  return self._daily_mission_list
end

function theme_season_module:get_daily_mission_by_tracker(tracker_id)
  if tracker_id == nil then
    return nil
  end
  return self._daily_mission_map[tracker_id]
end

function theme_season_module:get_daily_mission_state(tracker_id)
  local entry = self:get_daily_mission_by_tracker(tracker_id)
  if entry == nil then
    return self.DAILY_MISSION_STATE.UNFINISHED
  end
  if entry.is_reward_claimed then
    return self.DAILY_MISSION_STATE.CLAIMED
  end
  if entry.is_finish then
    return self.DAILY_MISSION_STATE.CLAIMABLE
  end
  return self.DAILY_MISSION_STATE.UNFINISHED
end

function theme_season_module:get_daily_claimable_tracker_ids()
  local result = {}
  local list = self._daily_mission_list
  for i = 1, #list do
    local tracker_id = list[i].tracker_id
    if self:get_daily_mission_state(tracker_id) == self.DAILY_MISSION_STATE.CLAIMABLE then
      result[#result + 1] = tracker_id
    end
  end
  return result
end

function theme_season_module:has_daily_claimable()
  local list = self._daily_mission_list
  for i = 1, #list do
    if self:get_daily_mission_state(list[i].tracker_id) == self.DAILY_MISSION_STATE.CLAIMABLE then
      return true
    end
  end
  return false
end

function theme_season_module:has_daily_red_point()
  return self:has_daily_claimable()
end

function theme_season_module:get_daily_done_count()
  local list = self._daily_mission_list
  local done = 0
  for i = 1, #list do
    if self:get_daily_mission_state(list[i].tracker_id) ~= self.DAILY_MISSION_STATE.UNFINISHED then
      done = done + 1
    end
  end
  return done
end

function theme_season_module:set_reward_pending(tracker_id)
  if tracker_id and 0 < tracker_id then
    self._daily_reward_pending[tracker_id] = true
  end
end

function theme_season_module:is_reward_pending(tracker_id)
  if tracker_id == nil then
    return false
  end
  return self._daily_reward_pending[tracker_id] == true
end

function theme_season_module:clear_reward_pending(tracker_id)
  if tracker_id == nil then
    table.clear(self._daily_reward_pending)
  else
    self._daily_reward_pending[tracker_id] = nil
  end
end

function theme_season_module:_get_daily_mission_cfg_by_tracker(tracker_id)
  if tracker_id == nil or tracker_id <= 0 then
    return nil
  end
  if self._daily_mission_cfg_cache == nil then
    local cache = {}
    
    local function fill_from_table(raw_table)
      if raw_table == nil then
        return
      end
      for _, group_rows in pairs(raw_table) do
        for _, row in ipairs(list_to_table(group_rows)) do
          local tid = row.trackerid or 0
          if 0 < tid and cache[tid] == nil then
            cache[tid] = row
          end
        end
      end
    end
    
    fill_from_table(ExcelDataUtil.get_table(typeof(BDailyMissionGroupCfg)))
    fill_from_table(ExcelDataUtil.get_table(typeof(BLimitTimeMissionGroupCfg)))
    self._daily_mission_cfg_cache = cache
  end
  return self._daily_mission_cfg_cache[tracker_id]
end

function theme_season_module:get_daily_mission_type_icon(tracker_id)
  local cfg = self:_get_daily_mission_cfg_by_tracker(tracker_id)
  if cfg == nil then
    return nil
  end
  local icon = cfg.missionicon
  if icon == nil or icon == "" then
    return nil
  end
  return icon
end

function theme_season_module:get_daily_mission_title(tracker_id)
  local cfg = self:_get_daily_mission_cfg_by_tracker(tracker_id)
  if cfg == nil then
    return nil
  end
  local text_id = cfg.titletext
  if text_id == nil or text_id == "" then
    return nil
  end
  return text_id
end

function theme_season_module:get_daily_mission_desc(tracker_id)
  local cfg = self:_get_daily_mission_cfg_by_tracker(tracker_id)
  if cfg == nil then
    return nil
  end
  local text_id = cfg.contenttext
  if text_id == nil or text_id == "" then
    return nil
  end
  return text_id
end

function theme_season_module:get_daily_mission_rewards(tracker_id)
  local cfg = self:_get_daily_mission_cfg_by_tracker(tracker_id)
  if cfg == nil then
    return {}
  end
  local reward_id = cfg.rewardid or 0
  if reward_id <= 0 then
    return {}
  end
  local pool_entries = list_to_table(ExcelDataUtil.get_value(typeof(BRandomPoolCfg), reward_id) or {})
  local rewards = {}
  for _, entry in ipairs(pool_entries) do
    local item_id = entry.configid or 0
    if 0 < item_id then
      table.insert(rewards, {
        item_id = item_id,
        count = entry.num or 0
      })
    end
  end
  return rewards
end

function theme_season_module:invalidate_npc_goods_cache()
  self._npc_goods_cache = nil
  self._exchange_npc_list_cache = nil
  self._season_npc_id_set_cache = nil
  self._npc_goods_cfg_index_cache = nil
end

function theme_season_module:_get_npc_goods_cfg_index()
  if self._npc_goods_cfg_index_cache then
    return self._npc_goods_cfg_index_cache
  end
  local index = {}
  for _, cfg in pairs(self:get_theme_season_npc_goods_cfg()) do
    local npc_id = cfg.npcid or 0
    if 0 < npc_id then
      local rows = index[npc_id]
      if rows == nil then
        rows = {}
        index[npc_id] = rows
      end
      rows[#rows + 1] = cfg
    end
  end
  self._npc_goods_cfg_index_cache = index
  return index
end

function theme_season_module:get_season_npc_id_set()
  if self._season_npc_id_set_cache then
    return self._season_npc_id_set_cache
  end
  local season_npc_set = {}
  local season_cfg = self:get_cur_season_cfg()
  local npc_ids = self:_parse_id_list(season_cfg and season_cfg.seasonnpclist or "")
  for i = 1, #npc_ids do
    season_npc_set[npc_ids[i]] = true
  end
  self._season_npc_id_set_cache = season_npc_set
  return season_npc_set
end

function theme_season_module:get_exchange_npc_list()
  if self._exchange_npc_list_cache then
    return self._exchange_npc_list_cache
  end
  local season_npc_set = self:get_season_npc_id_set()
  local all_cfgs = self:get_theme_season_npc_goods_cfg()
  local npc_map = {}
  local npc_order = {}
  for _, cfg in pairs(all_cfgs) do
    local npc_id = cfg.npcid
    if npc_id and 0 < npc_id and npc_map[npc_id] == nil then
      npc_map[npc_id] = true
      npc_order[#npc_order + 1] = npc_id
    end
  end
  local result = {}
  for i = 1, #npc_order do
    local npc_id = npc_order[i]
    result[#result + 1] = {
      npc_id = npc_id,
      is_season = season_npc_set[npc_id] or false
    }
  end
  self._exchange_npc_list_cache = result
  return result
end

function theme_season_module:has_npc_exchange_goods(npc_id)
  if not npc_id or npc_id <= 0 then
    return false
  end
  return self:_get_npc_goods_cfg_index()[npc_id] ~= nil
end

function theme_season_module:is_season_npc(npc_id)
  if not npc_id or npc_id <= 0 then
    return false
  end
  if not self:get_season_npc_id_set()[npc_id] then
    return false
  end
  return self:has_npc_exchange_goods(npc_id)
end

function theme_season_module:is_npc_exchange_line_completed(npc_id)
  if not npc_id or npc_id <= 0 then
    return false
  end
  local has_bp = self:has_purchased_bp()
  local has_counted_goods = false
  for _, cfg in ipairs(self:_get_npc_goods_cfg_index()[npc_id] or {}) do
    local is_premium = cfg.bp == 1
    if has_bp or not is_premium then
      has_counted_goods = true
      if not self:is_npc_goods_exchanged(npc_id, cfg.id) then
        return false
      end
    end
  end
  return has_counted_goods
end

function theme_season_module:get_npc_exchange_data(npc_id)
  if npc_id == nil or npc_id <= 0 then
    return {
      free_items = {},
      free_final = nil,
      premium_items = {},
      premium_final = nil
    }
  end
  if self._npc_goods_cache == nil then
    self._npc_goods_cache = {}
  end
  if self._npc_goods_cache[npc_id] then
    return self._npc_goods_cache[npc_id]
  end
  local data = self:_build_npc_exchange_data(npc_id)
  self._npc_goods_cache[npc_id] = data
  return data
end

function theme_season_module:_build_npc_exchange_data(npc_id)
  local free_entries = {}
  local premium_entries = {}
  for _, cfg in ipairs(self:_get_npc_goods_cfg_index()[npc_id] or {}) do
    local entry = {
      id = cfg.id,
      level = cfg.level or 0,
      cost_item_id = cfg.costitemid or 0,
      cost_item_count = cfg.costitemcount or 0,
      item_id = cfg.itemid or 0,
      item_count = cfg.itemcount or 0
    }
    if cfg.bp and cfg.bp == 1 then
      premium_entries[#premium_entries + 1] = entry
    else
      free_entries[#free_entries + 1] = entry
    end
  end
  table.sort(free_entries, function(a, b)
    return a.level < b.level
  end)
  table.sort(premium_entries, function(a, b)
    return a.level < b.level
  end)
  local current_level = self:get_npc_current_level(npc_id)
  local has_bp = self:has_purchased_bp()
  local free_items, free_final = self:_split_items_and_final(free_entries, npc_id, current_level, has_bp)
  local premium_items, premium_final
  if 0 < #premium_entries then
    local paired = self:_pair_exchange_lines(free_entries, premium_entries, npc_id, current_level, has_bp)
    premium_items = {}
    for i = 1, #paired - 1 do
      premium_items[#premium_items + 1] = paired[i]
    end
    premium_final = paired[#paired] or nil
  else
    premium_items = {}
    premium_final = nil
  end
  return {
    free_items = free_items,
    free_final = free_final,
    premium_items = premium_items,
    premium_final = premium_final,
    current_level = current_level
  }
end

function theme_season_module:_pair_exchange_lines(free_entries, premium_entries, npc_id, current_level, has_bp)
  local free_by_level = {}
  for _, entry in ipairs(free_entries) do
    free_by_level[entry.level] = entry
  end
  local premium_by_level = {}
  for _, entry in ipairs(premium_entries) do
    premium_by_level[entry.level] = entry
  end
  local levels = {}
  local level_set = {}
  for _, entry in ipairs(free_entries) do
    if not level_set[entry.level] then
      levels[#levels + 1] = entry.level
      level_set[entry.level] = true
    end
  end
  for _, entry in ipairs(premium_entries) do
    if not level_set[entry.level] then
      levels[#levels + 1] = entry.level
      level_set[entry.level] = true
    end
  end
  table.sort(levels)
  local LEVEL_STATE = theme_season_module.LEVEL_STATE
  local all_free_exchanged = true
  for _, fe in ipairs(free_entries) do
    if not self:is_npc_goods_exchanged(npc_id, fe.id) then
      all_free_exchanged = false
      break
    end
  end
  local final_level = levels[#levels]
  local result = {}
  for _, level in ipairs(levels) do
    local free_e = free_by_level[level]
    local prem_e = premium_by_level[level]
    local level_state
    if current_level > level then
      level_state = LEVEL_STATE.OBTAINED
    elseif level == current_level then
      level_state = LEVEL_STATE.CURRENT
    else
      level_state = LEVEL_STATE.LOCKED
    end
    local basic_exchanged = free_e and self:is_npc_goods_exchanged(npc_id, free_e.id) or false
    local basic_item_data
    if free_e then
      basic_item_data = {
        config_id = free_e.id,
        item_id = free_e.item_id,
        count = free_e.item_count,
        cost_item_id = free_e.cost_item_id,
        cost_item_count = free_e.cost_item_count,
        get_state = basic_exchanged and 2 or level_state == LEVEL_STATE.CURRENT and 1 or 0,
        lock_state = 1
      }
    end
    local premium_item_data
    if prem_e then
      local prem_exchanged = self:is_npc_goods_exchanged(npc_id, prem_e.id)
      local same_level_free_done = free_e == nil or basic_exchanged
      local prereq_ok = same_level_free_done
      if level == final_level and prereq_ok then
        prereq_ok = all_free_exchanged
      end
      local prem_lock_state = has_bp and prereq_ok and 1 or 0
      local prem_get_state = 0
      if prem_exchanged then
        prem_get_state = 2
      elseif prem_lock_state == 1 then
        prem_get_state = 1
      end
      premium_item_data = {
        config_id = prem_e.id,
        item_id = prem_e.item_id,
        count = prem_e.item_count,
        cost_item_id = prem_e.cost_item_id,
        cost_item_count = prem_e.cost_item_count,
        get_state = prem_get_state,
        lock_state = prem_lock_state,
        is_premium = true
      }
    end
    result[#result + 1] = {
      basic_item = basic_item_data,
      premium_item = premium_item_data,
      level = level,
      level_state = level_state
    }
  end
  if 0 < #result then
    result[#result].level_state = LEVEL_STATE.FINAL
  end
  return result
end

function theme_season_module:_split_items_and_final(entries, npc_id, current_level, has_bp)
  if #entries == 0 then
    return {}, nil
  end
  local LEVEL_STATE = theme_season_module.LEVEL_STATE
  
  local function calc_item_state(entry)
    local level = entry.level
    local level_state
    if level < current_level then
      level_state = LEVEL_STATE.OBTAINED
    elseif level == current_level then
      level_state = LEVEL_STATE.CURRENT
    else
      level_state = LEVEL_STATE.LOCKED
    end
    return {
      config_id = entry.id,
      item_id = entry.item_id,
      count = entry.item_count,
      cost_item_id = entry.cost_item_id,
      cost_item_count = entry.cost_item_count,
      level = level,
      level_state = level_state,
      get_state = self:is_npc_goods_exchanged(npc_id, entry.id) and 2 or level_state == LEVEL_STATE.CURRENT and 1 or 0,
      lock_state = 1
    }
  end
  
  local final_item = calc_item_state(entries[#entries])
  final_item.level_state = LEVEL_STATE.FINAL
  local items = {}
  for i = 1, #entries - 1 do
    items[#items + 1] = calc_item_state(entries[i])
  end
  return items, final_item
end

function theme_season_module:_get_act_first_story_task_cfg(part_id)
  local part_cfg = self:get_theme_season_story_part_cfg_by_id(part_id)
  if part_cfg == nil then
    return nil
  end
  local task_cfg_ids = self:_parse_id_list(part_cfg.storyidlist)
  local first_id = task_cfg_ids[1]
  if first_id == nil then
    return nil
  end
  return self:get_theme_season_story_task_cfg_by_id(first_id)
end

function theme_season_module:_get_act_open_activity_id(part_id)
  if part_id == nil or part_id <= 0 then
    return 0
  end
  local cache = self._act_open_activity_id_cache
  if cache == nil then
    cache = {}
    self._act_open_activity_id_cache = cache
  end
  local cached = cache[part_id]
  if cached ~= nil and 0 < cached then
    return cached
  end
  local activity_id = self:get_chapter_activity_id(self:_get_act_first_story_task_cfg(part_id))
  if 0 < activity_id then
    cache[part_id] = activity_id
  end
  return activity_id
end

function theme_season_module:_is_act_open_activity_data_ready(part_id)
  local activity_id = self:_get_act_open_activity_id(part_id)
  if activity_id <= 0 then
    return true
  end
  return activity_center_module:get_activity_by_id(activity_id) ~= nil
end

function theme_season_module:is_act_opened_by_data(act_data)
  if act_data == nil then
    return false
  end
  local start_ts = act_data.start_time or 0
  if 0 < start_ts then
    if start_ts > TimeUtil.ServerUtcTimeSeconds then
      return false
    end
  elseif not self:_is_act_open_activity_data_ready(act_data.id) then
    return false
  end
  return act_data.unlock_reason ~= self.CHAPTER_UNLOCK_REASON.PREV_TASK
end

function theme_season_module:_is_act_open_time_reached(part_id)
  if not self:is_season_active() then
    return false
  end
  local activity_id = self:_get_act_open_activity_id(part_id)
  if activity_id <= 0 then
    return false
  end
  local start_ts = self:get_activity_start_ts(activity_id)
  if start_ts <= 0 then
    return false
  end
  return start_ts <= TimeUtil.ServerUtcTimeSeconds
end

function theme_season_module:_is_act_open_tip_shown(part_id)
  if part_id == nil or part_id <= 0 then
    return true
  end
  return red_point_module:is_recorded_with_id(red_point_module.red_point_type.theme_season_act_open_tip_shown, part_id)
end

function theme_season_module:get_pending_act_open_tip_part_id()
  if not self:is_season_active() then
    return 0
  end
  local part_ids = self:get_story_part_ids()
  local has_unshown = false
  for i = 2, #part_ids do
    if not self:_is_act_open_tip_shown(part_ids[i]) then
      has_unshown = true
      break
    end
  end
  if not has_unshown then
    return 0
  end
  local pending_id = 0
  for i = 2, #part_ids do
    local part_id = part_ids[i]
    if self:_is_act_open_time_reached(part_id) and not self:_is_act_open_tip_shown(part_id) then
      pending_id = part_id
    end
  end
  return pending_id
end

function theme_season_module:mark_act_open_tip_shown_through(part_id)
  if part_id == nil or part_id <= 0 then
    return
  end
  local rp_type = red_point_module.red_point_type.theme_season_act_open_tip_shown
  local part_ids = self:get_story_part_ids()
  for i = 2, #part_ids do
    local id = part_ids[i]
    if self:_is_act_open_time_reached(id) then
      red_point_module:record_with_id(rp_type, id)
    end
    if id == part_id then
      break
    end
  end
end

local HUD_ENTRY_TIP_KIND_SEASON = 1
local HUD_ENTRY_TIP_KIND_ACT = 2

function theme_season_module:get_hud_entry_tip(season_id)
  if not red_point_module:is_recorded_with_id(red_point_module.red_point_type.theme_season_entry_tip_shown, season_id) then
    return "ThemeSeason_UI_013", nil, HUD_ENTRY_TIP_KIND_SEASON, season_id
  end
  local part_id = self:get_pending_act_open_tip_part_id()
  if part_id <= 0 then
    return nil
  end
  return "ThemeSeason_UI_088", self:get_story_part_title(part_id), HUD_ENTRY_TIP_KIND_ACT, part_id
end

function theme_season_module:mark_hud_entry_tip(kind, id)
  if kind == HUD_ENTRY_TIP_KIND_SEASON then
    red_point_module:record_with_id(red_point_module.red_point_type.theme_season_entry_tip_shown, id)
  elseif kind == HUD_ENTRY_TIP_KIND_ACT then
    self:mark_act_open_tip_shown_through(id)
  end
end

function theme_season_module:is_story_act_new(act_id)
  if act_id == nil or act_id <= 0 then
    return false
  end
  return not red_point_module:is_recorded_with_id(red_point_module.red_point_type.theme_season_story_act_seen, act_id)
end

function theme_season_module:mark_story_act_seen(act_id)
  if act_id == nil or act_id <= 0 then
    return
  end
  red_point_module:record_with_id(red_point_module.red_point_type.theme_season_story_act_seen, act_id)
end

function theme_season_module:has_story_new_content()
  if not self:is_season_active() then
    return false
  end
  for _, act in ipairs(self:build_story_acts_data()) do
    if self:is_act_opened_by_data(act) and self:is_story_act_new(act.id) then
      return true
    end
  end
  return false
end

function theme_season_module:get_story_act_red_point_type(act_data)
  if act_data and act_data.chapters then
    for _, chapter in ipairs(act_data.chapters) do
      if chapter.state == 1 then
        return RedPointType.GiftRP
      end
    end
  end
  if act_data and self:is_act_opened_by_data(act_data) and self:is_story_act_new(act_data.id) then
    return RedPointType.NewRp
  end
  return RedPointType.None
end

function theme_season_module:get_story_red_point_type()
  if not self:is_season_active() then
    return RedPointType.None
  end
  local acts = self:build_story_acts_data()
  local has_new = false
  for _, act in ipairs(acts) do
    if act.chapters then
      for _, chapter in ipairs(act.chapters) do
        if chapter.state == 1 then
          return RedPointType.GiftRP
        end
      end
    end
    if not has_new and self:is_act_opened_by_data(act) and self:is_story_act_new(act.id) then
      has_new = true
    end
  end
  if has_new then
    return RedPointType.NewRp
  end
  return RedPointType.None
end

function theme_season_module:is_premium_item_free_claimable(premium_item)
  return premium_item ~= nil and (premium_item.lock_state or 0) == 1 and (premium_item.get_state or 0) == 1 and (premium_item.cost_item_count or 0) == 0
end

function theme_season_module:npc_has_claimable_premium(npc_id)
  if not npc_id or npc_id <= 0 then
    return false
  end
  if not self:is_season_npc(npc_id) then
    return false
  end
  local exchange_data = self:get_npc_exchange_data(npc_id)
  for _, row in ipairs(exchange_data.premium_items or {}) do
    if self:is_premium_item_free_claimable(row.premium_item) then
      return true
    end
  end
  if exchange_data.premium_final and self:is_premium_item_free_claimable(exchange_data.premium_final.premium_item) then
    return true
  end
  return false
end

function theme_season_module:is_npc_all_goods_obtained(npc_id)
  if not npc_id or npc_id <= 0 then
    return false
  end
  local rows = self:_get_npc_goods_cfg_index()[npc_id]
  if rows == nil or #rows == 0 then
    return false
  end
  for _, cfg in ipairs(rows) do
    if not self:is_npc_goods_exchanged(npc_id, cfg.id) then
      return false
    end
  end
  return true
end

function theme_season_module:get_npc_exchange_red_point_type(npc_id)
  if not self:is_season_active() then
    return RedPointType.None
  end
  if self:npc_has_claimable_premium(npc_id) then
    return RedPointType.GiftRP
  end
  return RedPointType.None
end

function theme_season_module:get_impression_red_point_type()
  if not self:is_season_active() then
    return RedPointType.None
  end
  local npc_list = self:get_exchange_npc_list()
  for _, entry in ipairs(npc_list) do
    if entry.is_season and self:npc_has_claimable_premium(entry.npc_id) then
      return RedPointType.GiftRP
    end
  end
  return RedPointType.None
end

function theme_season_module:is_item_cost_affordable(item)
  if item == nil then
    return false
  end
  if (item.get_state or 0) ~= 1 then
    return false
  end
  local cost_item_id = item.cost_item_id or 0
  local cost_item_count = item.cost_item_count or 0
  if cost_item_id <= 0 or cost_item_count <= 0 then
    return false
  end
  return cost_item_count <= back_bag_module:get_coin_or_item_num(cost_item_id)
end

function theme_season_module:npc_has_affordable_exchange(npc_id)
  if not npc_id or npc_id <= 0 then
    return false
  end
  if not self:is_season_npc(npc_id) then
    return false
  end
  local exchange_data = self:get_npc_exchange_data(npc_id)
  for _, item in ipairs(exchange_data.free_items or {}) do
    if self:is_item_cost_affordable(item) then
      return true
    end
  end
  if self:is_item_cost_affordable(exchange_data.free_final) then
    return true
  end
  for _, row in ipairs(exchange_data.premium_items or {}) do
    if self:is_item_cost_affordable(row.basic_item) or self:is_item_cost_affordable(row.premium_item) then
      return true
    end
  end
  local final_row = exchange_data.premium_final
  if final_row then
    return self:is_item_cost_affordable(final_row.basic_item) or self:is_item_cost_affordable(final_row.premium_item)
  end
  return false
end

function theme_season_module:should_show_npc_exchange_tips(npc_id)
  if not self:is_season_active() then
    return false
  end
  if self:npc_has_claimable_premium(npc_id) then
    return false
  end
  return self:npc_has_affordable_exchange(npc_id)
end

function theme_season_module:should_show_impression_tips()
  if not self:is_season_active() then
    return false
  end
  if self:get_impression_red_point_type() == RedPointType.GiftRP then
    return false
  end
  local npc_list = self:get_exchange_npc_list()
  for _, entry in ipairs(npc_list) do
    if entry.is_season and self:npc_has_affordable_exchange(entry.npc_id) then
      return true
    end
  end
  return false
end

function theme_season_module:get_footprint_red_point_type()
  if self:has_daily_red_point() then
    return RedPointType.GiftRP
  end
  return RedPointType.None
end

function theme_season_module:get_season_codex_red_point_type()
  local season_id = self:get_cur_season_id()
  if season_id == 0 then
    return RedPointType.None
  end
  require("UI/Codex/SeasonCodex/CodexSeasonData")
  local reward_rp = codex_module:get_season_reward_red_point_type(season_id)
  if reward_rp == RedPointType.GiftRP then
    return reward_rp
  end
  if codex_module:has_season_new_items(season_id) then
    return RedPointType.NewRp
  end
  return RedPointType.None
end

function theme_season_module:get_season_entry_red_point_type()
  if self:get_footprint_red_point_type() == RedPointType.GiftRP then
    return RedPointType.GiftRP
  end
  local story_rp = self:get_story_red_point_type()
  if story_rp == RedPointType.GiftRP then
    return RedPointType.GiftRP
  end
  if self:get_impression_red_point_type() == RedPointType.GiftRP then
    return RedPointType.GiftRP
  end
  if self:get_season_codex_red_point_type() == RedPointType.GiftRP then
    return RedPointType.GiftRP
  end
  if story_rp == RedPointType.NewRp then
    return RedPointType.NewRp
  end
  return RedPointType.None
end

local GIFT_BLOCK_TIP_TEXT_ID = {
  [theme_season_module.GIFT_BLOCK_REASON.NOT_FRIEND] = "ThemeSeason_UI_051",
  [theme_season_module.GIFT_BLOCK_REASON.SEASON_NOT_OPEN] = "ThemeSeason_UI_052",
  [theme_season_module.GIFT_BLOCK_REASON.ALREADY_HAS_BP] = "ThemeSeason_UI_053"
}
local BP_TYPE = {
  SINGLE_COMMON = "SINGLE_BP_COMMON",
  SINGLE_LUXURY = "SINGLE_BP_LUXURY",
  SINGLE_COMMON_TO_LUXURY = "SINGLE_BP_COMMON_TO_LUXURY",
  DOUBLE_COMMON = "DOUBLE_BP_COMMON",
  DOUBLE_LUXURY = "DOUBLE_BP_LUXURY",
  SINGLE_TO_DOUBLE_COMMON = "SINGLE_BP_TO_DOUBLE_BP_COMMON",
  SINGLE_COMMON_TO_DOUBLE_LUXURY = "SINGLE_BP_COMMON_TO_DOUBLE_BP_LUXURY",
  SINGLE_LUXURY_TO_DOUBLE_LUXURY = "SINGLE_BP_LUXURY_TO_DOUBLE_BP_LUXURY"
}
theme_season_module.BP_TYPE = BP_TYPE
local BP_TYPE_GRANTS = {
  [BP_TYPE.SINGLE_COMMON] = {common = true},
  [BP_TYPE.SINGLE_LUXURY] = {luxury = true},
  [BP_TYPE.SINGLE_COMMON_TO_LUXURY] = {luxury = true},
  [BP_TYPE.DOUBLE_COMMON] = {
    common = true,
    double = true,
    double_common = true
  },
  [BP_TYPE.DOUBLE_LUXURY] = {
    luxury = true,
    double = true,
    double_luxury = true
  },
  [BP_TYPE.SINGLE_TO_DOUBLE_COMMON] = {double = true, double_common = true},
  [BP_TYPE.SINGLE_COMMON_TO_DOUBLE_LUXURY] = {
    luxury = true,
    double = true,
    double_luxury = true
  },
  [BP_TYPE.SINGLE_LUXURY_TO_DOUBLE_LUXURY] = {
    luxury = true,
    double = true,
    double_luxury = true
  }
}
local BP_TYPE_REQUIREMENT = {
  [BP_TYPE.SINGLE_COMMON] = function(owns)
    return not owns.common and not owns.luxury
  end,
  [BP_TYPE.SINGLE_LUXURY] = function(owns)
    return not owns.common and not owns.luxury
  end,
  [BP_TYPE.SINGLE_COMMON_TO_LUXURY] = function(owns)
    return owns.common and not owns.luxury
  end,
  [BP_TYPE.DOUBLE_COMMON] = function(owns)
    return not owns.common and not owns.luxury and not owns.double_common
  end,
  [BP_TYPE.DOUBLE_LUXURY] = function(owns)
    return not owns.common and not owns.luxury and not owns.double_luxury
  end,
  [BP_TYPE.SINGLE_TO_DOUBLE_COMMON] = function(owns)
    return (owns.common or owns.luxury) and not owns.double_common
  end,
  [BP_TYPE.SINGLE_COMMON_TO_DOUBLE_LUXURY] = function(owns)
    return owns.common and not owns.luxury and not owns.double_luxury
  end,
  [BP_TYPE.SINGLE_LUXURY_TO_DOUBLE_LUXURY] = function(owns)
    return owns.luxury and not owns.double_luxury
  end
}
local BP_SLOT_CANDIDATES = {
  [theme_season_module.BP_SLOT.SINGLE_COMMON] = {
    BP_TYPE.SINGLE_COMMON
  },
  [theme_season_module.BP_SLOT.SINGLE_LUXURY] = {
    BP_TYPE.SINGLE_COMMON_TO_LUXURY,
    BP_TYPE.SINGLE_LUXURY
  },
  [theme_season_module.BP_SLOT.DOUBLE_COMMON] = {
    BP_TYPE.SINGLE_TO_DOUBLE_COMMON,
    BP_TYPE.DOUBLE_COMMON
  },
  [theme_season_module.BP_SLOT.DOUBLE_LUXURY] = {
    BP_TYPE.SINGLE_LUXURY_TO_DOUBLE_LUXURY,
    BP_TYPE.SINGLE_COMMON_TO_DOUBLE_LUXURY,
    BP_TYPE.DOUBLE_LUXURY
  }
}
local PURCHASE_CONFIRM_TEXT_ID = {
  SINGLE = "ThemeSeason_UI_005",
  DOUBLE = "ThemeSeason_UI_054",
  COUPON_ONLY = "ThemeSeason_UI_055"
}
local BP_TYPE_UPGRADE = {
  [BP_TYPE.SINGLE_COMMON_TO_LUXURY] = true,
  [BP_TYPE.SINGLE_TO_DOUBLE_COMMON] = true,
  [BP_TYPE.SINGLE_COMMON_TO_DOUBLE_LUXURY] = true,
  [BP_TYPE.SINGLE_LUXURY_TO_DOUBLE_LUXURY] = true
}

function theme_season_module:is_bp_upgrade_type(bp_type)
  return BP_TYPE_UPGRADE[bp_type] == true
end

function theme_season_module:invalidate_bp_price_cache()
  self._bp_price_cache = nil
end

function theme_season_module:_ensure_bp_price_cache()
  if self._bp_price_cache then
    return
  end
  self._bp_price_cache = {}
  local all_cfgs = self:get_theme_season_bp_price_cfg()
  for _, cfg in pairs(all_cfgs) do
    self._bp_price_cache[cfg.bptype] = cfg
  end
end

function theme_season_module:get_bp_price_by_type(bp_type)
  self:_ensure_bp_price_cache()
  if self._bp_price_cache then
    return self._bp_price_cache[bp_type]
  end
  return nil
end

function theme_season_module:is_bp_item_exchange_mode()
  return CsGameplayUtilitiesEmergencySwitchUtil.IsSwitchOnByType(EmergencySwitchType.EmergencySwtichOpenBpItemExchange)
end

function theme_season_module:get_bp_purchasing_items(bp_type)
  return self:get_bp_purchasing_items_by_cfg(self:get_bp_price_by_type(bp_type))
end

function theme_season_module:get_bp_purchasing_items_by_cfg(cfg)
  if cfg == nil then
    return {}
  end
  return self:_parse_reward_list(cfg.purchasingitems)
end

function theme_season_module:get_season_instant_reward_items(season_id)
  local season_cfg = season_id and self:get_theme_season_cfg_by_id(season_id) or self:get_cur_season_cfg()
  return self:_parse_reward_list(season_cfg and season_cfg.instantreward or "")
end

function theme_season_module:get_season_daily_reward_items(season_id)
  local season_cfg = season_id and self:get_theme_season_cfg_by_id(season_id) or self:get_cur_season_cfg()
  return self:_parse_reward_list(season_cfg and season_cfg.dailyreward or "")
end

function theme_season_module:get_bp_entitlement(exclude_product_id)
  local owns = {
    common = false,
    luxury = false,
    double = false,
    double_common = false,
    double_luxury = false
  }
  self:_ensure_bp_price_cache()
  if self._bp_price_cache then
    for bp_type, cfg in pairs(self._bp_price_cache) do
      if cfg.id ~= exclude_product_id and self:is_product_purchased(cfg.id) then
        local grants = BP_TYPE_GRANTS[bp_type]
        if grants then
          owns.common = owns.common or grants.common == true
          owns.luxury = owns.luxury or grants.luxury == true
          owns.double = owns.double or grants.double == true
          owns.double_common = owns.double_common or grants.double_common == true
          owns.double_luxury = owns.double_luxury or grants.double_luxury == true
        end
      end
    end
  end
  return owns
end

function theme_season_module:is_double_bp_owned(is_premium)
  local owns = self:get_bp_entitlement()
  if is_premium == nil then
    return owns.double
  end
  if is_premium then
    return owns.double_luxury
  end
  return owns.double_common
end

function theme_season_module:get_gift_bp_item_id(is_luxury)
  local season_cfg = self:get_cur_season_cfg()
  if season_cfg == nil then
    return 0
  end
  if is_luxury then
    return season_cfg.giftluxurybpitemid or 0
  end
  return season_cfg.giftcommonbpitemid or 0
end

function theme_season_module:get_bp_name(is_double, is_luxury)
  local season_cfg = self:get_cur_season_cfg()
  if season_cfg == nil then
    return ""
  end
  if is_double then
    return is_luxury and season_cfg.doubleluxurybpname or season_cfg.doublecommonbpname or ""
  end
  return is_luxury and season_cfg.luxurybpname or season_cfg.commonbpname or ""
end

function theme_season_module:get_gift_bp_unlock_name(gift_item_id)
  if gift_item_id == nil or gift_item_id <= 0 then
    return ""
  end
  if gift_item_id == self:get_gift_bp_item_id(true) then
    return self:get_bp_name(false, true)
  end
  if gift_item_id == self:get_gift_bp_item_id(false) then
    return self:get_bp_name(false, false)
  end
  return ""
end

function theme_season_module:get_bp_current_tier()
  local owns = self:get_bp_entitlement()
  local T = theme_season_module.BP_TIER
  if owns.double and owns.luxury then
    return T.DOUBLE_LUXURY
  elseif owns.double then
    return T.DOUBLE_COMMON
  elseif owns.luxury then
    return T.SINGLE_LUXURY
  elseif owns.common then
    return T.SINGLE_COMMON
  end
  return T.NONE
end

function theme_season_module:get_bp_tier_name(tier)
  if self._bp_tier_name_map == nil then
    self._bp_tier_name_map = {}
    for name, value in pairs(theme_season_module.BP_TIER) do
      self._bp_tier_name_map[value] = name
    end
  end
  return self._bp_tier_name_map[tier] or "UNKNOWN"
end

function theme_season_module:get_purchased_bp_product_ids()
  local ids = {}
  self:_ensure_bp_price_cache()
  if self._bp_price_cache then
    for _, cfg in pairs(self._bp_price_cache) do
      if self:is_product_purchased(cfg.id) then
        ids[#ids + 1] = cfg.id
      end
    end
  end
  table.sort(ids)
  return ids
end

function theme_season_module:dump_story_chapters_to_log()
  local STATE_TXT = {
    [0] = "进行中",
    [1] = "可领奖",
    [2] = "锁定",
    [3] = "已领奖"
  }
  local REASON_TXT = {
    [0] = "无",
    [1] = "活动时间未到",
    [2] = "前置endtask未完成"
  }
  local sid = self:get_cur_season_id()
  local acts = self:build_story_acts_data(sid)
  Logger.Log(string.format("[TS剧情] season=%d active=%s acts=%d", sid, tostring(self:is_season_active()), acts and #acts or 0))
  if not acts then
    return
  end
  local now = TimeUtil.ServerUtcTimeSeconds
  for ai, act in ipairs(acts) do
    local chapters = act.chapters or {}
    Logger.Log(string.format("[TS剧情] 第%d幕 act_id=%s title=%s chapters=%d", ai, tostring(act.id), tostring(act.title), #chapters))
    for ci, c in ipairs(chapters) do
      local cfg = self:get_theme_season_story_task_cfg_by_id(c.id)
      local begin_task = cfg and (cfg.begintask or 0) or 0
      local end_task = cfg and (cfg.endtask or 0) or 0
      local activity_id = cfg and self:get_chapter_activity_id(cfg) or 0
      local start_ts = self:get_activity_start_ts(activity_id) or 0
      local activity_started = 0 < start_ts and now >= start_ts
      Logger.Log(string.format("[TS剧情]   #%d cfgId=%s begin=%d(完成=%s,进行=%s) end=%d(完成=%s) 活动=%d 开始时间=%s 已开始=%s 状态=%s 锁定原因=%s 剩余=%s 已领奖=%s 奖励数=%d", ci, tostring(c.id), begin_task, tostring(task_module:task_is_finish(begin_task)), tostring(task_module:task_is_ongoing(begin_task)), end_task, tostring(task_module:task_is_finish(end_task)), activity_id, tostring(start_ts), tostring(activity_started), STATE_TXT[c.state] or tostring(c.state), REASON_TXT[c.unlock_reason] or tostring(c.unlock_reason), tostring(c.unlock_remaining or 0), tostring(self:is_story_reward_claimed(c.id)), c.rewards and #c.rewards or 0))
    end
  end
end

function theme_season_module:_resolve_purchasable_bp_type(slot, owns)
  local candidates = BP_SLOT_CANDIDATES[slot]
  if candidates == nil then
    return nil
  end
  for _, bp_type in ipairs(candidates) do
    local requirement = BP_TYPE_REQUIREMENT[bp_type]
    if requirement ~= nil and requirement(owns) then
      return bp_type
    end
  end
  return nil
end

function theme_season_module:get_bp_slot_state(slot)
  local SLOT = theme_season_module.BP_SLOT
  local STATE = theme_season_module.BP_SLOT_STATE
  local result = {
    state = STATE.PURCHASABLE,
    bp_type = nil,
    gift_item_id = 0
  }
  if self:is_season_ended() then
    result.state = STATE.UNAVAILABLE
    return result
  end
  local owns = self:get_bp_entitlement()
  if slot == SLOT.SINGLE_COMMON then
    if owns.common or owns.luxury then
      result.state = STATE.PURCHASED
      return result
    end
  elseif slot == SLOT.SINGLE_LUXURY then
    if owns.luxury then
      result.state = STATE.PURCHASED
      return result
    end
  elseif slot == SLOT.DOUBLE_COMMON or slot == SLOT.DOUBLE_LUXURY then
    local is_premium = slot == SLOT.DOUBLE_LUXURY
    if self:is_double_bp_owned(is_premium) then
      result.gift_item_id = self:get_gift_bp_item_id(is_premium)
      local gift_num = result.gift_item_id > 0 and back_bag_module:get_coin_or_item_num(result.gift_item_id) or 0
      result.state = 0 < gift_num and STATE.GIFTABLE or STATE.GIFTED
      return result
    end
  end
  result.bp_type = self:_resolve_purchasable_bp_type(slot, owns)
  if result.bp_type == nil then
    result.state = STATE.UNAVAILABLE
  end
  return result
end

function theme_season_module:get_gift_block_reason(friend_data)
  local REASON = theme_season_module.GIFT_BLOCK_REASON
  if is_null(friend_data) then
    return REASON.NOT_FRIEND
  end
  if not friend_data.is_theme_season_open then
    return REASON.SEASON_NOT_OPEN
  end
  if friend_data.theme_season_id == self:get_cur_season_id() and friend_data.has_single_bp then
    return REASON.ALREADY_HAS_BP
  end
  return REASON.NONE
end

function theme_season_module:build_gift_target_list()
  local REASON = theme_season_module.GIFT_BLOCK_REASON
  local list = {}
  local friends = social_module:get_friend_info_tbl()
  for _, friend_data in ipairs(friends or {}) do
    if not is_null(friend_data) then
      local reason = self:get_gift_block_reason(friend_data)
      local starling = friend_data:get_current_starling()
      list[#list + 1] = {
        uid = friend_data.uid,
        name = friend_data:get_nick_name_with_remark_name(),
        avatar_id = friend_data.avatar_id,
        galaxy_id = friend_data.galaxy_id,
        title = social_module:get_display_title_by_title_list(list_to_table(friend_data.current_title_list), friend_data.gender_preference),
        is_online = friend_data.is_online,
        intimacy = friend_data:get_intimacy(),
        is_best_friend = friend_data:is_best_friend(),
        bestie_time = friend_data:get_became_bestie_time() or math.huge,
        starling_point = is_null(starling) and 0 or starling.TotalPoint or 0,
        block_reason = reason,
        can_gift = reason == REASON.NONE,
        block_tip_text_id = GIFT_BLOCK_TIP_TEXT_ID[reason]
      }
    end
  end
  local passersby = dic_to_list_table(CsSocialModuleUtil.GetAllPasserByBriefInfos())
  for _, brief in ipairs(passersby or {}) do
    if brief ~= nil then
      list[#list + 1] = {
        uid = brief.Uid,
        name = brief.Nickname,
        avatar_id = brief.AvatarId,
        galaxy_id = brief.GalaxyType,
        title = social_module:get_display_title_by_player_info(brief),
        is_online = brief.IsOnline,
        intimacy = 0,
        is_best_friend = false,
        bestie_time = math.huge,
        starling_point = 0,
        block_reason = REASON.NOT_FRIEND,
        can_gift = false,
        block_tip_text_id = GIFT_BLOCK_TIP_TEXT_ID[REASON.NOT_FRIEND]
      }
    end
  end
  table.sort(list, function(a, b)
    if a.can_gift ~= b.can_gift then
      return a.can_gift
    end
    if a.is_online ~= b.is_online then
      return a.is_online == true
    end
    if a.is_best_friend ~= b.is_best_friend then
      return a.is_best_friend == true
    end
    if a.is_best_friend then
      if a.bestie_time ~= b.bestie_time then
        return a.bestie_time < b.bestie_time
      end
    elseif a.starling_point ~= b.starling_point then
      return a.starling_point > b.starling_point
    end
    return a.uid < b.uid
  end)
  return list
end

function theme_season_module:get_bp_purchase_info(product_id)
  self:_ensure_bp_price_cache()
  local grants
  if self._bp_price_cache then
    for bp_type, cfg in pairs(self._bp_price_cache) do
      if cfg.id == product_id then
        grants = BP_TYPE_GRANTS[bp_type]
        break
      end
    end
  end
  grants = grants or {}
  local is_double = grants.double == true
  local is_luxury = grants.luxury == true
  local instant_items = {}
  if is_luxury then
    instant_items = self:get_season_instant_reward_items()
  end
  local gift_item_id = 0
  if is_double then
    gift_item_id = self:get_gift_bp_item_id(is_luxury)
  end
  local coupon_only = false
  if is_double then
    local owns = self:get_bp_entitlement(product_id)
    local adds_single = grants.luxury == true and not owns.luxury or grants.common == true and not owns.common and not owns.luxury
    coupon_only = not adds_single
  end
  return {
    is_double = is_double,
    is_luxury = is_luxury,
    coupon_only = coupon_only,
    bp_name = self:get_bp_name(is_double, is_luxury),
    single_bp_name = self:get_bp_name(false, is_luxury),
    gift_item_id = gift_item_id,
    gift_item_count = 0 < gift_item_id and 1 or 0,
    gift_item_name = 0 < gift_item_id and item_module:get_item_name_by_id(gift_item_id) or "",
    instant_items = instant_items
  }
end

function theme_season_module:get_bp_purchase_confirm_text(product_id)
  local info = self:get_bp_purchase_info(product_id)
  if not info.is_double then
    return UIUtil.get_text_by_id(PURCHASE_CONFIRM_TEXT_ID.SINGLE, info.bp_name)
  end
  if info.coupon_only then
    return UIUtil.get_text_by_id(PURCHASE_CONFIRM_TEXT_ID.COUPON_ONLY, info.gift_item_name)
  end
  return UIUtil.get_text_by_id(PURCHASE_CONFIRM_TEXT_ID.DOUBLE, info.bp_name, info.single_bp_name, info.gift_item_name)
end

function theme_season_module:get_bp_bonus_items()
  local season_id = self:get_cur_season_id()
  if season_id <= 0 then
    return {}
  end
  local merged = {}
  local source_map = {}
  local graduate_cfgs = self:get_theme_season_graduate_cfg()
  for _, cfg in pairs(graduate_cfgs) do
    if cfg.seasonid == season_id then
      local item_id = cfg.itemid or 0
      local count = cfg.itemcount or 0
      if 0 < item_id and 0 < count then
        merged[item_id] = (merged[item_id] or 0) + count
        source_map[item_id] = "graduation"
      end
    end
  end
  local season_npc_ids = self:get_season_npc_id_set()
  local npc_goods_cfgs = self:get_theme_season_npc_goods_cfg()
  for _, cfg in pairs(npc_goods_cfgs) do
    local npc_id = cfg.npcid or 0
    if season_npc_ids[npc_id] and cfg.bp == 1 then
      local item_id = cfg.itemid or 0
      local count = cfg.itemcount or 0
      if 0 < item_id and 0 < count then
        merged[item_id] = (merged[item_id] or 0) + count
        if source_map[item_id] == nil then
          source_map[item_id] = "npc_bp"
        end
      end
    end
  end
  local items = {}
  for item_id, count in pairs(merged) do
    items[#items + 1] = {
      item_id = item_id,
      count = count,
      source = source_map[item_id] or "npc_bp",
      rank = item_module:get_item_quality_by_id(item_id)
    }
  end
  table.sort(items, function(a, b)
    if a.source ~= b.source then
      return a.source == "graduation"
    end
    if a.rank ~= b.rank then
      return a.rank > b.rank
    end
    return a.count > b.count
  end)
  return items
end

local function get_tip_shown_red_point_type()
  return red_point_module.red_point_type.theme_season_bp_gift_tip_shown
end

function theme_season_module:get_latest_untipped_social_gift_id()
  if CsSocialModuleUtil.IsNull() then
    return 0
  end
  local gift_ids = CsSocialModuleUtil.GetPendingSocialGiftIdsOrderByTimeDesc()
  if is_null(gift_ids) then
    return 0
  end
  local red_point_type = get_tip_shown_red_point_type()
  for i = 0, gift_ids.Count - 1 do
    local gift_id = gift_ids[i]
    if CsSocialModuleUtil.GetSocialGiftState(gift_id) == chat_module.SOCIAL_GIFT_STATE.PENDING and not CsSocialModuleUtil.IsSocialGiftTipShown(red_point_type, gift_id) then
      return gift_id
    end
  end
  return 0
end

function theme_season_module:mark_social_gift_tip_shown(gift_id)
  if (gift_id or 0) <= 0 or CsSocialModuleUtil.IsNull() then
    return
  end
  CsSocialModuleUtil.MarkSocialGiftTipShown(get_tip_shown_red_point_type(), gift_id)
end

function theme_season_module:mark_social_gift_tip_shown_through(gift_id)
  gift_id = gift_id or 0
  if gift_id <= 0 or CsSocialModuleUtil.IsNull() then
    return
  end
  local red_point_type = get_tip_shown_red_point_type()
  CsSocialModuleUtil.MarkSocialGiftTipShown(red_point_type, gift_id)
  local gift_ids = CsSocialModuleUtil.GetPendingSocialGiftIdsOrderByTimeDesc()
  if is_null(gift_ids) then
    return
  end
  local shown_send_time = CsSocialModuleUtil.GetSocialGiftSendTime(gift_id) or 0
  for i = 0, gift_ids.Count - 1 do
    local id = gift_ids[i]
    if shown_send_time >= (CsSocialModuleUtil.GetSocialGiftSendTime(id) or 0) then
      CsSocialModuleUtil.MarkSocialGiftTipShown(red_point_type, id)
    end
  end
end

function theme_season_module:is_season_closing(const_type)
  if not self:is_season_active() then
    return true
  end
  local close_seconds = self:get_const_value(const_type) * 60
  local remain = self:get_remaining_seconds()
  return 0 < remain and close_seconds >= remain
end

function theme_season_module:can_teleport_to_season_scene()
  if self:is_season_closing(self.CONST_TYPE.FORBID_TELEPORT_SCENE_MINUTES) then
    local remain = self:get_remaining_seconds()
    local time_str = UIUtil.format_left_time(remain)
    UIUtil.show_tips_by_text_id("ThemeSeason_UI_040", time_str)
    return false
  end
  return true
end

function theme_season_module:update_expired_season_task_ids(task_id_list)
  self._expired_season_task_ids = {}
  if task_id_list then
    for _, id in ipairs(list_to_table(task_id_list)) do
      table.insert(self._expired_season_task_ids, id)
    end
  end
  self._pending_expired_dialog = #self._expired_season_task_ids > 0
end

function theme_season_module:has_pending_expired_dialog()
  return self._pending_expired_dialog and #self._expired_season_task_ids > 0
end

function theme_season_module:get_expired_season_task_ids()
  return self._expired_season_task_ids
end

function theme_season_module:on_expired_dialog_shown()
  self._pending_expired_dialog = false
  CsThemeSeasonModuleUtil.SendClearExpiredTaskRecord()
  CsThemeSeasonModuleUtil.ClearExpiredSeasonTaskIds()
  self._expired_season_task_ids = {}
end

return theme_season_module
