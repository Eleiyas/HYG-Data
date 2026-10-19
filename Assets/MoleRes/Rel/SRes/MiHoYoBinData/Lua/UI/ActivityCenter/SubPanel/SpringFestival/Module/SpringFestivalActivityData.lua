spring_festival_activity_module = spring_festival_activity_module or {}
local EMPTY_ID_LIST = {}

function spring_festival_activity_module:get_time_phase(activity_id)
  return activity_center_module:get_activity_time_phase(activity_id)
end

local function pick_latest_end_activity_id(ids)
  if ids == nil or #ids == 0 then
    return 0
  end
  if #ids == 1 then
    return ids[1]
  end
  local latest_id = 0
  local latest_end_time = 0
  for index = 1, #ids do
    local range = activity_center_module:get_activity_time_range(ids[index])
    if range ~= nil and latest_end_time < range.end_time then
      latest_id = ids[index]
      latest_end_time = range.end_time
    end
  end
  if latest_id == 0 then
    return ids[1]
  end
  return latest_id
end

function spring_festival_activity_module:get_page_time_remain_activity_id(page_key, image_id)
  return pick_latest_end_activity_id(activity_center_module:get_page_time_remain_activity_ids(page_key, image_id or 0))
end

function spring_festival_activity_module:get_page_representative_activity_id(page_key)
  return pick_latest_end_activity_id(activity_center_module:get_page_unlock_activity_ids(page_key))
end

function spring_festival_activity_module:is_page_schedule_activity(page_key, activity_id)
  if activity_id == self:get_main_activity_id() then
    return true
  end
  local ids = activity_center_module:get_page_unlock_activity_ids(page_key)
  for index = 1, #ids do
    if ids[index] == activity_id then
      return true
    end
  end
  return false
end

function spring_festival_activity_module:get_page_end_activity_id(page_key)
  local ids = activity_center_module:get_page_unlock_activity_ids(page_key)
  if #ids == 0 then
    return 0
  end
  return ids[#ids]
end

function spring_festival_activity_module:get_main_activity_id()
  return self.main_activity_id
end

function spring_festival_activity_module:is_main_activity_ended()
  local main_activity_id = self:get_main_activity_id()
  if not activity_center_module:has_activity(main_activity_id) then
    return true
  end
  return self:get_time_phase(main_activity_id) == self.time_phase.ended
end

function spring_festival_activity_module:get_main_activity_data()
  return activity_center_module:get_activity_by_id(self:get_main_activity_id())
end

local function is_tracking_activity_running(module, tracking_id)
  if tracking_id == nil or tracking_id == 0 then
    return false
  end
  local activity_id = activity_center_module:get_tracking_activity_id(tracking_id)
  return module:get_time_phase(activity_id) == module.time_phase.running
end

function spring_festival_activity_module:is_lantern_tab_content_unlocked(tab_index)
  local phases = self:get_tracking_phases(self.page_key.lantern_riddles, tab_index)
  for index = 1, #phases do
    if is_tracking_activity_running(self, phases[index]) then
      return true
    end
  end
  return false
end

local function is_phase_cleared(module, tracking_id)
  if activity_center_module:is_tracking_tasks_finished(tracking_id) then
    return true
  end
  local phase_enum = module.time_phase
  local phase = module:get_time_phase(activity_center_module:get_tracking_activity_id(tracking_id))
  return phase ~= phase_enum.before_start and phase ~= phase_enum.running
end

local function get_lantern_phase_unlocked_slot(module, phase_entry)
  if not is_tracking_activity_running(module, phase_entry.tracking_id) then
    return nil
  end
  local require_cleared_id = phase_entry.require_cleared_tracking_id
  if require_cleared_id ~= nil and not is_phase_cleared(module, require_cleared_id) then
    return nil
  end
  return module:get_lantern_phase_red_dot_slot(phase_entry.tracking_id)
end

local function get_lantern_card_tip_unlocked_slot(module)
  local entry = module.corner_activity_by_tracking_id[module.lantern_time_tracking_id]
  if entry == nil then
    return nil
  end
  if module:get_corner_activity_phase(entry) ~= module.time_phase.running then
    return nil
  end
  local session_index = module:get_lantern_session_index()
  if session_index == nil then
    return nil
  end
  return module:get_lantern_card_tip_red_dot_slot(session_index)
end

function spring_festival_activity_module:build_unlocked_slot_mask()
  local mask = 0
  for _, entry in ipairs(self.page_entries) do
    if self:is_page_enterable(entry.key) then
      mask = math.set_bit(mask, self:get_card_red_dot_slot(entry.key), 1)
    end
  end
  for day = 1, self:get_seven_days_day_count() do
    if self:is_seven_days_day_unlocked(day) then
      mask = math.set_bit(mask, self:get_seven_days_red_dot_slot(day), 1)
    end
  end
  for tab_index, tab_entry in ipairs(self.lantern_tab_entries) do
    local phase_entries = tab_entry.phase_red_dot_entries
    if phase_entries == nil then
      if self:is_lantern_tab_content_unlocked(tab_index) then
        mask = math.set_bit(mask, self:get_lantern_red_dot_slot(tab_index), 1)
      end
    else
      for _, phase_entry in ipairs(phase_entries) do
        local slot_id = get_lantern_phase_unlocked_slot(self, phase_entry)
        if slot_id ~= nil then
          mask = math.set_bit(mask, slot_id, 1)
        end
      end
    end
  end
  local lantern_card_tip_slot = get_lantern_card_tip_unlocked_slot(self)
  if lantern_card_tip_slot ~= nil then
    mask = math.set_bit(mask, lantern_card_tip_slot, 1)
  end
  local xieve_phases = self:get_red_dot_tracking_phases(self.page_key.fireworks)
  for phase = 1, #xieve_phases do
    if is_tracking_activity_running(self, xieve_phases[phase]) then
      mask = math.set_bit(mask, self:get_xieve_red_dot_slot(phase), 1)
    end
  end
  for corner_index, entry in ipairs(self.corner_activity_entries) do
    local phase = self:get_corner_activity_phase(entry)
    if phase == self.time_phase.running then
      local slot_id = self:get_corner_current_red_dot_slot(corner_index)
      if slot_id ~= nil then
        mask = math.set_bit(mask, slot_id, 1)
      end
    end
  end
  return mask
end

function spring_festival_activity_module:has_slot_red_dot(slot_id)
  local data = self:get_main_activity_data()
  if data == nil then
    return false
  end
  return data:HasSlotRedDot(slot_id) == true
end

function spring_festival_activity_module:has_lantern_riddle_reward()
  if riddle_module == nil then
    return false
  end
  local list = riddle_module:get_stage_reward_list()
  if list == nil then
    return false
  end
  for index = 1, #list do
    if riddle_module:get_stage_reward_state(list[index]) == riddle_module.stage_reward_state.can_take then
      return true
    end
  end
  return false
end

local function has_page_claimable_reward(module, page_key)
  if page_key == module.page_key.lantern_riddles then
    return module:has_lantern_riddle_reward()
  end
  return false
end

local function has_lantern_tab_unread_slot(module, tab_index)
  local slots = module.lantern_tab_red_dot_slots[tab_index]
  if slots == nil then
    return false
  end
  for index = 1, #slots do
    if module:has_slot_red_dot(slots[index]) then
      return true
    end
  end
  return false
end

local function has_page_unread_sub_slot(module, page_key)
  local key = module.page_key
  if page_key == key.seven_days then
    for day = 1, module:get_seven_days_day_count() do
      if module:has_slot_red_dot(module:get_seven_days_red_dot_slot(day)) then
        return true
      end
    end
  elseif page_key == key.lantern_riddles then
    for tab_index = 1, #module.lantern_tab_entries do
      if has_lantern_tab_unread_slot(module, tab_index) then
        return true
      end
    end
  elseif page_key == key.fireworks then
    local phases = module:get_red_dot_tracking_phases(key.fireworks)
    for phase = 1, #phases do
      if module:has_slot_red_dot(module:get_xieve_red_dot_slot(phase)) then
        return true
      end
    end
  end
  return false
end

function spring_festival_activity_module:has_lantern_card_tip_red_dot()
  for index = 1, #self.lantern_card_tip_slots do
    if self:has_slot_red_dot(self.lantern_card_tip_slots[index]) then
      return true
    end
  end
  return false
end

function spring_festival_activity_module:get_card_red_dot_type(page_key)
  if has_page_claimable_reward(self, page_key) then
    return RedPointType.GiftRP
  end
  if self:has_slot_red_dot(self:get_card_red_dot_slot(page_key)) or has_page_unread_sub_slot(self, page_key) or page_key == self.page_key.lantern_riddles and self:has_lantern_card_tip_red_dot() then
    return RedPointType.StrongRP
  end
  return RedPointType.None
end

function spring_festival_activity_module:get_lantern_tab_red_dot_type(tab_index)
  local entry = self.lantern_tab_entries[tab_index]
  if entry ~= nil and entry.has_riddle_reward and self:has_lantern_riddle_reward() then
    return RedPointType.GiftRP
  end
  if has_lantern_tab_unread_slot(self, tab_index) then
    return RedPointType.StrongRP
  end
  return RedPointType.None
end

spring_festival_activity_module._lantern_daily_open = nil

function spring_festival_activity_module:apply_lantern_daily_open_state(is_open, activity_id, begin_time, end_time)
  local old = self._lantern_daily_open
  local changed = old == nil or old.is_open ~= is_open or old.begin_time ~= begin_time or old.end_time ~= end_time
  self._lantern_daily_open = {
    is_open = is_open,
    activity_id = activity_id,
    begin_time = begin_time,
    end_time = end_time
  }
  return changed
end

function spring_festival_activity_module:get_lantern_session_index()
  local state = self._lantern_daily_open
  if not (state ~= nil and state.is_open) or state.begin_time <= 0 then
    return nil
  end
  local range = activity_center_module:get_activity_time_range(state.activity_id)
  if range == nil or range.start_time == 0 then
    return nil
  end
  local index = TimeUtil.GetUtcGameDayStamp(state.begin_time) - TimeUtil.GetUtcGameDayStamp(range.start_time) + 1
  local entry = self.corner_activity_by_tracking_id[self.lantern_time_tracking_id]
  local count = entry ~= nil and entry.session_count or 1
  if index < 1 or index > count then
    Logger.LogWarning("[SpringFestival] 放花灯场次序号 " .. tostring(index) .. " 超出配置的 session_count " .. tostring(count) .. "，已夹住。")
    index = math.max(1, math.min(index, count))
  end
  return index
end

function spring_festival_activity_module:get_corner_current_red_dot_slot(corner_index)
  local entry = self.corner_activity_entries[corner_index]
  if entry == nil then
    return nil
  end
  if not entry.daily_open_from_server then
    return self:get_corner_red_dot_slot(corner_index)
  end
  local session_index = self:get_lantern_session_index()
  if session_index == nil then
    return nil
  end
  return self:get_corner_red_dot_slot(corner_index, session_index)
end

local CORNER_OPEN_TIP_RECORD

local function get_corner_open_tip_record_type()
  if CORNER_OPEN_TIP_RECORD == nil then
    CORNER_OPEN_TIP_RECORD = red_point_module.red_point_type.spring_festival_corner_open_tip_shown
  end
  return CORNER_OPEN_TIP_RECORD
end

function spring_festival_activity_module:get_corner_open_session_key(corner_index)
  local entry = self.corner_activity_entries[corner_index]
  if entry == nil then
    return nil, nil
  end
  if self:get_corner_activity_phase(entry) ~= self.time_phase.running then
    return nil, nil
  end
  local activity_id = self:get_corner_activity_id(entry)
  if activity_id == 0 then
    return nil, nil
  end
  if entry.daily_open_from_server then
    local state = self._lantern_daily_open
    if state == nil or 0 >= state.begin_time then
      return nil, nil
    end
    return state.begin_time, activity_id
  end
  local range = activity_center_module:get_activity_time_range(activity_id)
  if range == nil or range.start_time == 0 then
    return nil, nil
  end
  return range.start_time, activity_id
end

function spring_festival_activity_module:is_corner_open_tip_pending(corner_index)
  local session_key, activity_id = self:get_corner_open_session_key(corner_index)
  if session_key == nil then
    return false
  end
  return not red_point_module:is_recorded_with_two_ids(get_corner_open_tip_record_type(), activity_id, session_key)
end

function spring_festival_activity_module:mark_corner_open_tip_shown(corner_index)
  local session_key, activity_id = self:get_corner_open_session_key(corner_index)
  if session_key == nil then
    return
  end
  local record_type = get_corner_open_tip_record_type()
  red_point_module:delete_all_record_by_second_id(record_type, activity_id)
  red_point_module:record_with_two_ids(record_type, activity_id, session_key)
end

local LANTERN_DAILY_OPEN_PLAYER_CFG_ID = 213
local lantern_daily_open_clock

local function parse_daily_open_clock(raw)
  if raw == nil or not string.is_valid(raw) then
    return nil
  end
  local oh, om, ch, cm = string.match(raw, "^%s*(%d+):(%d+)%s*%-%s*(%d+):(%d+)%s*$")
  if oh == nil then
    return nil
  end
  local open_hour, open_min = tonumber(oh), tonumber(om)
  local close_hour, close_min = tonumber(ch), tonumber(cm)
  if open_hour == nil or open_min == nil or close_hour == nil or close_min == nil or 23 < open_hour or 23 < close_hour or 59 < open_min or 59 < close_min then
    return nil
  end
  return {
    open_sec_of_day = open_hour * 3600 + open_min * 60,
    close_sec_of_day = close_hour * 3600 + close_min * 60
  }
end

local function get_lantern_daily_open_clock()
  if lantern_daily_open_clock ~= nil then
    return lantern_daily_open_clock or nil
  end
  local cfg = ExcelDataUtil.get_value(typeof(BPlayerCfg), LANTERN_DAILY_OPEN_PLAYER_CFG_ID)
  local parsed = parse_daily_open_clock(cfg ~= nil and cfg.paramstr or nil)
  if parsed == nil then
    if cfg ~= nil then
      Logger.LogWarning("[SpringFestival] PlayerCfg " .. LANTERN_DAILY_OPEN_PLAYER_CFG_ID .. " paramStr 期望 \"HH:MM-HH:MM\"，实际为 " .. tostring(cfg.paramstr))
      lantern_daily_open_clock = false
    end
    return nil
  end
  lantern_daily_open_clock = parsed
  return parsed
end

local function get_seconds_to_next_daily_open()
  local clock = get_lantern_daily_open_clock()
  if clock == nil then
    return 0
  end
  local sec_of_day = TimeUtil.ServerLocalTimeSeconds % LuaTimeUtil.SecondOfOneDay
  local delta = clock.open_sec_of_day - sec_of_day
  if delta <= 0 then
    delta = delta + LuaTimeUtil.SecondOfOneDay
  end
  return delta
end

function spring_festival_activity_module:get_lantern_daily_open_phase(activity_id)
  local phase = self.time_phase
  local state = self._lantern_daily_open
  if state == nil then
    return phase.none, 0
  end
  if state.is_open then
    local remain = state.end_time - TimeUtil.ServerUtcTimeSeconds
    if 0 < remain then
      return phase.running, remain
    end
  end
  local remain_to_next = get_seconds_to_next_daily_open()
  if remain_to_next <= 0 then
    return phase.none, 0
  end
  local range = activity_center_module:get_activity_time_range(activity_id)
  if range ~= nil and 0 < range.end_time and TimeUtil.ServerUtcTimeSeconds + remain_to_next >= range.end_time then
    return phase.ended, 0
  end
  return phase.before_start, remain_to_next
end

function spring_festival_activity_module:get_corner_activity_id(entry)
  if entry == nil then
    return 0
  end
  local activity_id = activity_center_module:get_tracking_activity_id(entry.tracking_id)
  if activity_id == 0 then
    Logger.LogWarning("[SpringFestival] ActivityTrackingCfg 缺少 id = " .. tostring(entry.tracking_id) .. " 那一行，左下角小活动按钮将不可用。")
  end
  return activity_id
end

function spring_festival_activity_module:get_corner_activity_phase(entry)
  local activity_id = self:get_corner_activity_id(entry)
  local phase, remain = self:get_time_phase(activity_id)
  if not entry.daily_open_from_server then
    return phase, remain
  end
  if phase ~= self.time_phase.running then
    return phase, remain
  end
  return self:get_lantern_daily_open_phase(activity_id)
end

function spring_festival_activity_module:get_corner_state()
  local phase_enum = self.time_phase
  local state_enum = self.corner_state
  local live_entry, live_remain, pending_entry, pending_remain
  for _, entry in ipairs(self.corner_activity_entries) do
    local phase, remain = self:get_corner_activity_phase(entry)
    if phase == phase_enum.running then
      if live_remain == nil or live_remain > remain then
        live_entry, live_remain = entry, remain
      end
    elseif phase == phase_enum.before_start and (pending_remain == nil or pending_remain > remain) then
      pending_entry, pending_remain = entry, remain
    end
  end
  if live_entry ~= nil then
    return {
      state = live_entry.button_state,
      tracking_id = live_entry.tracking_id,
      activity_id = self:get_corner_activity_id(live_entry),
      text_id = nil,
      remain = live_remain
    }
  end
  if pending_entry ~= nil then
    return {
      state = state_enum.calendar,
      tracking_id = pending_entry.tracking_id,
      activity_id = self:get_corner_activity_id(pending_entry),
      text_id = pending_entry.text_id,
      remain = pending_remain
    }
  end
  return {
    state = state_enum.calendar,
    tracking_id = 0,
    activity_id = 0,
    text_id = nil,
    remain = 0
  }
end

local function pick_card_activity_id(module, page_id)
  local ids = activity_center_module:get_page_unlock_activity_ids(page_id)
  if ids == nil or #ids == 0 then
    return 0
  end
  if #ids == 1 then
    return ids[1]
  end
  local phase_enum = module.time_phase
  local earliest_pending_id, earliest_pending_remain
  for i = 1, #ids do
    local id = ids[i]
    local phase, remain = module:get_time_phase(id)
    if phase == phase_enum.running then
      return id
    end
    if phase == phase_enum.before_start and (earliest_pending_remain == nil or earliest_pending_remain > remain) then
      earliest_pending_id = id
      earliest_pending_remain = remain
    end
  end
  if earliest_pending_id ~= nil then
    return earliest_pending_id
  end
  return ids[#ids]
end

function spring_festival_activity_module:get_card_time_phase(entry)
  if entry == nil then
    return self.time_phase.ended, 0
  end
  return self:get_time_phase(pick_card_activity_id(self, entry.key))
end

function spring_festival_activity_module:get_card_state_by_entry(entry)
  if entry == nil then
    return self.card_state.locked
  end
  local locked_state = entry.locked_state or self.card_state.locked
  local activity_id = pick_card_activity_id(self, entry.key)
  if activity_id == nil or activity_id == 0 then
    return locked_state
  end
  local data = activity_center_module:get_activity_by_id(activity_id)
  if data == nil then
    return self.card_state.expired
  end
  local phase = self:get_time_phase(activity_id)
  if phase == self.time_phase.ended then
    return self.card_state.expired
  end
  if phase == self.time_phase.before_start then
    return locked_state
  end
  if data.IsAdvance then
    return locked_state
  end
  if data.State == activity_center_module.activity_state.Opened then
    return locked_state
  end
  return self.card_state.unlocked
end

function spring_festival_activity_module:get_card_state_by_page_key(page_key)
  return self:get_card_state_by_entry(self.page_entry_by_key[page_key])
end

function spring_festival_activity_module:is_page_enterable(page_key)
  return self:get_card_state_by_page_key(page_key) == self.card_state.unlocked
end

function spring_festival_activity_module:get_card_title_id(page_key)
  local entry = self.page_entry_by_key[page_key]
  if entry == nil then
    return nil
  end
  return activity_center_module:get_page_title_id_by_order(self.main_page_id, entry.card_index)
end

function spring_festival_activity_module:get_card_icon_path(page_key)
  local entry = self.page_entry_by_key[page_key]
  if entry == nil then
    return nil
  end
  return activity_center_module:get_page_background_path_by_order(self.main_page_id, entry.card_index)
end

function spring_festival_activity_module:get_enterable_page_keys()
  local keys = {}
  for _, entry in ipairs(self.page_entries) do
    if self:is_page_enterable(entry.key) then
      table.insert(keys, entry.key)
    end
  end
  return keys
end

function spring_festival_activity_module:_get_cycled_page_key(current_key, offset)
  local keys = self:get_enterable_page_keys()
  local count = #keys
  if count < 2 then
    return nil
  end
  local current_index
  for i = 1, count do
    if keys[i] == current_key then
      current_index = i
      break
    end
  end
  if current_index == nil then
    return keys[1]
  end
  local target_index = (current_index - 1 + offset) % count + 1
  return keys[target_index]
end

function spring_festival_activity_module:get_next_page_key(current_key)
  return self:_get_cycled_page_key(current_key, 1)
end

function spring_festival_activity_module:get_prev_page_key(current_key)
  return self:_get_cycled_page_key(current_key, -1)
end

function spring_festival_activity_module:get_navigable_task_id_from_list(task_ids)
  return activity_center_module:get_navigable_task_id_from_list(task_ids)
end

function spring_festival_activity_module:get_prewarm_task_id()
  local phases = self:get_tracking_phases(self.main_prewarm_slot)
  if #phases == 0 then
    return 0
  end
  return self:get_navigable_task_id_from_list(activity_center_module:get_tracking_memo_ids(phases[1]))
end

function spring_festival_activity_module:is_prewarm_button_visible()
  local phases = self:get_tracking_phases(self.main_prewarm_slot)
  if #phases == 0 then
    return true
  end
  local memo_ids = activity_center_module:get_tracking_memo_ids(phases[1])
  if #memo_ids == 0 then
    return true
  end
  for index = 1, #memo_ids do
    if not task_module:task_is_finish(memo_ids[index]) then
      return true
    end
  end
  return false
end

function spring_festival_activity_module:is_prewarm_task_navigable(task_id)
  return activity_center_module:is_task_navigable(task_id)
end

function spring_festival_activity_module:get_page_reward_item_ids(page_key, image_id)
  return activity_center_module:get_page_reward_item_ids(page_key, image_id)
end

function spring_festival_activity_module:get_embroidered_tracking_target()
  local tracking_id = self:get_actionable_tracking_id(self.page_key.embroidered)
  return self:make_tracking_target_by_id(tracking_id)
end

local EMPTY_RESOLVED_SLOT = {phases = EMPTY_ID_LIST, red_dot_phases = EMPTY_ID_LIST}
local resolved_slot_cache = {}

local function resolve_slot(slot)
  if slot == nil then
    return EMPTY_RESOLVED_SLOT
  end
  local cached = resolved_slot_cache[slot]
  if cached ~= nil then
    return cached
  end
  if type(slot) == "number" then
    local phases = {slot}
    local resolved = {phases = phases, red_dot_phases = phases}
    resolved_slot_cache[slot] = resolved
    return resolved
  end
  local raw = slot.tracking_phases
  if raw == nil and slot.tracking_id ~= nil then
    raw = {
      slot.tracking_id
    }
  end
  if raw == nil then
    return EMPTY_RESOLVED_SLOT
  end
  local phases = {}
  local actionable_state_by_id, pending_state_by_id
  for index = 1, #raw do
    local item = raw[index]
    if type(item) == "number" then
      phases[index] = item
    else
      local tracking_id = item[1]
      phases[index] = tracking_id
      if item.actionable_state ~= nil then
        actionable_state_by_id = actionable_state_by_id or {}
        actionable_state_by_id[tracking_id] = item.actionable_state
      end
      if item.pending_state ~= nil then
        pending_state_by_id = pending_state_by_id or {}
        pending_state_by_id[tracking_id] = item.pending_state
      end
    end
  end
  local resolved = {
    phases = phases,
    red_dot_phases = slot.red_dot_tracking_phases or phases,
    actionable_state_by_id = actionable_state_by_id,
    pending_state_by_id = pending_state_by_id,
    idle_state = slot.idle_state,
    final_phase_tracking_id = slot.final_phase_tracking_id
  }
  resolved_slot_cache[slot] = resolved
  return resolved
end

local function get_slot(module, source_key, tog_index)
  local source = module.tracking_source[source_key]
  if source == nil then
    return nil
  end
  if source.tracking_by_tog == nil then
    return source
  end
  if tog_index == nil then
    return nil
  end
  return source.tracking_by_tog[tog_index]
end

function spring_festival_activity_module:get_tracking_resolved(source_key, tog_index)
  return resolve_slot(get_slot(self, source_key, tog_index))
end

function spring_festival_activity_module:get_tracking_phases(source_key, tog_index)
  return self:get_tracking_resolved(source_key, tog_index).phases
end

function spring_festival_activity_module:get_red_dot_tracking_phases(source_key, tog_index)
  return self:get_tracking_resolved(source_key, tog_index).red_dot_phases
end

function spring_festival_activity_module:is_corner_tracking_activity_id(activity_id)
  if activity_id == nil or activity_id <= 0 then
    return false
  end
  for _, entry in ipairs(self.corner_activity_entries) do
    if self:get_corner_activity_id(entry) == activity_id then
      return true
    end
  end
  return false
end

function spring_festival_activity_module:get_page_key_by_tracking_activity_id(activity_id)
  if activity_id == nil or activity_id <= 0 then
    return nil
  end
  for _, page_entry in ipairs(self.page_entries) do
    local page_key = page_entry.key
    local source = self.tracking_source[page_key]
    if source ~= nil then
      local tog_count = source.tracking_by_tog ~= nil and #source.tracking_by_tog or 1
      for tog_index = 1, tog_count do
        local actual_tog_index = source.tracking_by_tog ~= nil and tog_index or nil
        for _, tracking_id in ipairs(self:get_tracking_phases(page_key, actual_tog_index)) do
          if activity_center_module:get_tracking_activity_id(tracking_id) == activity_id then
            return page_key
          end
        end
      end
    end
  end
  return nil
end

local function is_phase_running(module, tracking_id)
  local phase_enum = module.time_phase
  local phase = module:get_time_phase(activity_center_module:get_tracking_activity_id(tracking_id))
  return phase == phase_enum.running
end

local function is_phase_actionable(module, tracking_id)
  if not is_phase_running(module, tracking_id) then
    return false
  end
  if activity_center_module:get_tracking_json_id(tracking_id) > 0 then
    return true
  end
  return activity_center_module:get_navigable_task_id_from_list(activity_center_module:get_tracking_memo_ids(tracking_id)) ~= 0
end

local function find_phase(module, phases, predicate)
  for index = 1, #phases do
    if predicate(module, phases[index]) then
      return phases[index]
    end
  end
  return 0
end

function spring_festival_activity_module:get_running_tracking_id(source_key, tog_index)
  return find_phase(self, self:get_tracking_phases(source_key, tog_index), is_phase_running)
end

function spring_festival_activity_module:get_actionable_tracking_id(source_key, tog_index)
  return find_phase(self, self:get_tracking_phases(source_key, tog_index), is_phase_actionable)
end

function spring_festival_activity_module:make_tracking_target_by_id(tracking_id)
  return activity_center_module:make_tracking_target_by_id(tracking_id)
end

local function find_pending_tracking_phase(module, phases)
  for index = 1, #phases do
    local tracking_id = phases[index]
    local memo_ids = activity_center_module:get_tracking_memo_ids(tracking_id)
    if #memo_ids == 0 then
      return tracking_id
    end
    if activity_center_module:get_navigable_task_id_from_list(memo_ids) ~= 0 then
      return tracking_id
    end
    if not activity_center_module:is_tracking_tasks_finished(tracking_id) then
      return tracking_id
    end
  end
  return 0
end

function spring_festival_activity_module:get_tracking_state_by_slot(source_key, tog_index)
  local resolved = self:get_tracking_resolved(source_key, tog_index)
  local actionable_id = self:get_actionable_tracking_id(source_key, tog_index)
  if actionable_id ~= 0 then
    local actionable_state = resolved.actionable_state_by_id ~= nil and resolved.actionable_state_by_id[actionable_id] or nil
    if actionable_state ~= nil then
      return actionable_state
    end
    return self:is_tracking(self:make_tracking_target_by_id(actionable_id)) and self.tracking_state.tracking or self.tracking_state.can_track
  end
  local pending_id = find_pending_tracking_phase(self, resolved.phases)
  if pending_id ~= 0 then
    local pending_state = resolved.pending_state_by_id ~= nil and resolved.pending_state_by_id[pending_id] or nil
    if pending_state ~= nil then
      return pending_state
    end
  end
  return resolved.idle_state or self.tracking_state.can_track
end

function spring_festival_activity_module:get_firework_phase()
  return self:get_time_phase(self:get_firework_activity_id())
end

function spring_festival_activity_module:get_firework_activity_id()
  local entry = self.corner_activity_by_tracking_id[self.firework_time_tracking_id]
  if entry == nil then
    Logger.LogWarning("[SpringFestivalActivity] firework_time_tracking_id " .. tostring(self.firework_time_tracking_id) .. " 不在 corner_activity_entries 里，烟火倒计时将不显示。")
    return 0
  end
  return self:get_corner_activity_id(entry)
end

function spring_festival_activity_module:make_task_tracking_target(task_id)
  return activity_center_module:make_task_tracking_target(task_id)
end

function spring_festival_activity_module:is_tracking(target)
  return activity_center_module:is_tracking(target)
end

function spring_festival_activity_module:_get_seven_days_tracking_id(day)
  if day == nil then
    return 0
  end
  local phases = self:get_tracking_phases(self.page_key.seven_days, day)
  return phases[1] or 0
end

function spring_festival_activity_module:get_seven_days_day_count()
  return activity_center_module:get_page_sub_page_count(self.page_key.seven_days)
end

function spring_festival_activity_module:get_seven_days_day_activity_id(day)
  return activity_center_module:get_tracking_activity_id(self:_get_seven_days_tracking_id(day))
end

function spring_festival_activity_module:get_seven_days_task_ids(day)
  return activity_center_module:get_tracking_memo_ids(self:_get_seven_days_tracking_id(day))
end

function spring_festival_activity_module:get_seven_days_current_task_id(day)
  local task_ids = self:get_seven_days_task_ids(day)
  if #task_ids == 0 then
    return 0
  end
  local navigable_id = self:get_navigable_task_id_from_list(task_ids)
  if navigable_id ~= 0 then
    return navigable_id
  end
  return task_ids[#task_ids]
end

function spring_festival_activity_module:get_seven_days_task_id(day)
  return self:get_seven_days_current_task_id(day)
end

function spring_festival_activity_module:is_seven_days_day_all_finished(day)
  local task_ids = self:get_seven_days_task_ids(day)
  if #task_ids == 0 then
    return false
  end
  for index = 1, #task_ids do
    if not task_module:task_is_finish(task_ids[index]) then
      return false
    end
  end
  return true
end

function spring_festival_activity_module:get_seven_days_day_unlock_time(day)
  local activity_id = self:get_seven_days_day_activity_id(day)
  if activity_id == 0 then
    return 0
  end
  local range = activity_center_module:get_activity_time_range(activity_id)
  if range == nil or range.start_time == 0 then
    return 0
  end
  return range.start_time
end

function spring_festival_activity_module:get_seven_days_day_unlock_remain(day)
  if self:is_seven_days_day_time_unlocked(day) then
    return 0
  end
  local unlock_time = self:get_seven_days_day_unlock_time(day)
  if unlock_time == 0 then
    return 0
  end
  local now = TimeUtil.ServerUtcTimeSeconds
  return unlock_time > now and unlock_time - now or 0
end

function spring_festival_activity_module:is_seven_days_day_time_unlocked(day)
  local unlock_time = self:get_seven_days_day_unlock_time(day)
  if unlock_time == 0 then
    return false
  end
  return unlock_time <= TimeUtil.ServerUtcTimeSeconds
end

function spring_festival_activity_module:is_seven_days_day_task_in_list(day)
  local task_ids = self:get_seven_days_task_ids(day)
  if #task_ids == 0 then
    return false
  end
  for index = 1, #task_ids do
    local task_id = task_ids[index]
    if task_module:task_is_ongoing(task_id) or task_module:task_is_finish(task_id) then
      return true
    end
  end
  return false
end

function spring_festival_activity_module:is_seven_days_day_unlocked(day)
  return self:is_seven_days_day_time_unlocked(day) and self:is_seven_days_day_task_in_list(day)
end

function spring_festival_activity_module:is_seven_days_day_viewed(day)
  local data = self:get_main_activity_data()
  if data == nil then
    return false
  end
  return data:IsSlotRead(self:get_seven_days_red_dot_slot(day)) == true
end

function spring_festival_activity_module:set_seven_days_day_viewed(day)
  self:mark_slot_read(self:get_seven_days_red_dot_slot(day))
end

function spring_festival_activity_module:get_seven_days_mission_state(day)
  local state = self.seven_days_mission_state
  if self:is_seven_days_day_all_finished(day) then
    return state.finished
  end
  if not self:is_seven_days_day_unlocked(day) then
    return state.locked
  end
  if self:is_seven_days_day_viewed(day) then
    return state.unlocked
  end
  return state.new_unlocked
end

function spring_festival_activity_module:get_seven_days_task_name(day)
  local task_id = self:get_seven_days_task_id(day)
  if task_id == 0 then
    return ""
  end
  local step_cfg = task_module:get_task_cfg_data():GetTaskStepCfgById(task_id)
  if is_null(step_cfg) then
    return ""
  end
  return step_cfg.name_l10n:ToString()
end

function spring_festival_activity_module:get_seven_days_task_desc(day)
  local task_id = self:get_seven_days_task_id(day)
  if task_id == 0 then
    return ""
  end
  local step_cfg = task_module:get_task_cfg_data():GetTaskStepCfgById(task_id)
  if is_null(step_cfg) then
    return ""
  end
  return step_cfg.desc_l10n:ToString()
end

function spring_festival_activity_module:get_seven_days_introduction_id(day)
  if day == nil then
    return 0
  end
  return self.seven_days_guide_window_id[day] or 0
end

function spring_festival_activity_module:get_seven_days_has_question_mark(day)
  return self:get_seven_days_introduction_id(day) > 0
end

function spring_festival_activity_module:get_seven_days_drawlock_state(day)
  local state = self.seven_days_drawlock_state
  if not self:is_seven_days_day_unlocked(day) then
    return state.locked
  end
  if self:get_seven_days_has_question_mark(day) then
    return state.unlocked_mark
  end
  return state.unlocked
end

function spring_festival_activity_module:get_seven_days_tracking_state(day)
  local state = self.seven_days_tracking_state
  if not self:is_seven_days_day_unlocked(day) then
    return state.locked
  end
  if self:is_seven_days_day_all_finished(day) then
    return state.finished
  end
  local target = self:make_task_tracking_target(self:get_seven_days_current_task_id(day))
  if target ~= nil and self:is_tracking(target) then
    return state.tracking
  end
  return state.can_track
end

function spring_festival_activity_module:get_seven_days_default_selected_day()
  local last_finished_day = 0
  for day = 1, self:get_seven_days_day_count() do
    local task_id = self:get_seven_days_task_id(day)
    if task_id ~= 0 then
      if task_module:task_is_ongoing(task_id) then
        return day
      end
      if task_module:task_is_finish(task_id) then
        last_finished_day = day
      end
    end
  end
  if 0 < last_finished_day then
    return last_finished_day
  end
  return 1
end

function spring_festival_activity_module:get_seven_days_image_path(day)
  return activity_center_module:get_sub_page_image_path(self.page_key.seven_days, day)
end

function spring_festival_activity_module:get_seven_days_special_name_text_id(day)
  if day == nil then
    return nil
  end
  if not self:is_seven_days_day_unlocked(day) then
    return self.seven_days_special_name_locked_text_id
  end
  return self.seven_days_special_name_text_id[day]
end

function spring_festival_activity_module:get_lantern_tracking_target(tab_index)
  local tracking_id = self:get_actionable_tracking_id(self.page_key.lantern_riddles, tab_index)
  return self:make_tracking_target_by_id(tracking_id)
end

function spring_festival_activity_module:get_lantern_tracking_state(tab_index)
  return self:get_tracking_state_by_slot(self.page_key.lantern_riddles, tab_index)
end

function spring_festival_activity_module:get_lantern_time_remain_activity_id(tab_index)
  local resolved = self:get_tracking_resolved(self.page_key.lantern_riddles, tab_index)
  local final_tracking_id = resolved.final_phase_tracking_id
  if final_tracking_id == nil then
    return 0
  end
  local actionable_id = self:get_actionable_tracking_id(self.page_key.lantern_riddles, tab_index)
  if actionable_id ~= 0 then
    return activity_center_module:get_tracking_activity_id(actionable_id)
  end
  return activity_center_module:get_tracking_activity_id(final_tracking_id)
end

function spring_festival_activity_module:get_lantern_cant_exchange_text_id(tab_index)
  local resolved = self:get_tracking_resolved(self.page_key.lantern_riddles, tab_index)
  local final_tracking_id = resolved.final_phase_tracking_id
  if final_tracking_id == nil then
    return nil
  end
  if self:get_lantern_tracking_state(tab_index) ~= self.lantern_tracking_state.wait_lantern then
    return nil
  end
  local text_id = self.lantern_cant_exchange_text_id
  return activity_center_module:is_tracking_tasks_finished(final_tracking_id) and text_id.all_finished or text_id.wait_next
end

function spring_festival_activity_module:get_page_title_desc_task_id(page_key, image_id)
  return activity_center_module:get_sub_page_title_desc_task_id(page_key, image_id or 0)
end

function spring_festival_activity_module:get_page_task_title(page_key, image_id)
  local name = activity_center_module:get_task_name_and_desc(self:get_page_title_desc_task_id(page_key, image_id))
  return name
end

function spring_festival_activity_module:get_page_task_desc(page_key, image_id)
  local _, desc = activity_center_module:get_task_name_and_desc(self:get_page_title_desc_task_id(page_key, image_id))
  return desc
end

return spring_festival_activity_module
