new_year_sprint_activity_module = new_year_sprint_activity_module or {}
local EMPTY_REWARD_LIST = {}
local card_entries_cache, memory_shelf_unlocked_cache

function new_year_sprint_activity_module:get_card_entries()
  if card_entries_cache ~= nil then
    return card_entries_cache
  end
  local count = activity_center_module:get_page_row_count(self.main_page_id)
  local entries = {}
  for index = 1, count do
    entries[index] = {card_index = index}
  end
  if 0 < count then
    card_entries_cache = entries
  end
  return entries
end

function new_year_sprint_activity_module:get_card_entry_by_activity_id(activity_id)
  if activity_id == nil or activity_id <= 0 then
    return nil
  end
  for _, entry in ipairs(self:get_card_entries()) do
    if self:get_card_activity_id(entry) == activity_id then
      return entry
    end
  end
  return nil
end

function new_year_sprint_activity_module:get_time_phase(activity_id)
  local phase = self.time_phase
  local time_phase, remain = activity_center_module:get_activity_time_phase(activity_id)
  if time_phase == phase.none then
    return phase.ended, 0
  end
  return time_phase, remain
end

function new_year_sprint_activity_module:is_time_limited(activity_id)
  local sub_range = activity_center_module:get_activity_time_range(activity_id)
  if sub_range == nil or sub_range.end_time == 0 then
    return false
  end
  local main_range = activity_center_module:get_activity_time_range(self.main_activity_id)
  if main_range == nil or main_range.end_time == 0 then
    return false
  end
  return sub_range.end_time < main_range.end_time
end

function new_year_sprint_activity_module:get_card_state(entry)
  local card_state = self.card_state
  if entry == nil then
    return card_state.locked
  end
  local activity_id = self:get_card_activity_id(entry)
  local phase = self:get_time_phase(activity_id)
  local phase_enum = self.time_phase
  if phase == phase_enum.ended then
    return card_state.ended
  end
  if phase ~= phase_enum.running then
    return card_state.locked
  end
  if not self:is_activity_state_opened(activity_id) then
    return card_state.locked
  end
  return self:is_time_limited(activity_id) and card_state.timed_running or card_state.normal_running
end

function new_year_sprint_activity_module:get_dialog_state(entry, is_memory_shelf_locked, is_activity_finished)
  local state = self:get_card_state(entry)
  if state == self.card_state.ended then
    return self.dialog_state.ended
  end
  if is_activity_finished then
    return self.dialog_state.completed
  end
  if is_memory_shelf_locked then
    return self.dialog_state.locked
  end
  return state
end

function new_year_sprint_activity_module:get_next_opening_activity_id()
  local entries = self:get_card_entries()
  local phase_enum = self.time_phase
  local picked_id = 0
  local picked_remain = 0
  for index = 1, #entries do
    local activity_id = self:get_card_activity_id(entries[index])
    local phase, remain = self:get_time_phase(activity_id)
    if phase == phase_enum.before_start and (picked_id == 0 or picked_remain > remain) then
      picked_id = activity_id
      picked_remain = remain
    end
  end
  return picked_id
end

function new_year_sprint_activity_module:is_memory_shelf_entry(entry)
  return entry ~= nil and self:get_card_activity_id(entry) == self.memory_shelf_special.activity_id
end

function new_year_sprint_activity_module:is_memory_shelf_tracker(tracker_id)
  tracker_id = tonumber(tracker_id)
  local special = self.memory_shelf_special
  return tracker_id == special.start_tracker_id or tracker_id == special.end_tracker_id
end

function new_year_sprint_activity_module:reset_memory_shelf_unlock_state()
  memory_shelf_unlocked_cache = nil
end

function new_year_sprint_activity_module:refresh_memory_shelf_unlock_state()
  memory_shelf_unlocked_cache = activity_center_module:is_tracker_reached(self.memory_shelf_special.start_tracker_id)
end

function new_year_sprint_activity_module:is_memory_shelf_unlock_required(entry)
  if not self:is_memory_shelf_entry(entry) then
    return false
  end
  if memory_shelf_unlocked_cache == nil then
    self:refresh_memory_shelf_unlock_state()
  end
  return not memory_shelf_unlocked_cache
end

function new_year_sprint_activity_module:get_card_locked_tips_text_id(entry)
  local tips = self.locked_tips_text_id
  if entry == nil then
    return tips.open_time
  end
  if self:is_memory_shelf_unlock_required(entry) then
    return tips.memory_shelf
  end
  local activity_id = self:get_card_activity_id(entry)
  if activity_id == self:get_next_opening_activity_id() then
    return tips.coming_soon
  end
  return tips.open_time
end

function new_year_sprint_activity_module:get_card_open_time_text(entry)
  if entry == nil then
    return ""
  end
  local range = activity_center_module:get_activity_time_range(self:get_card_activity_id(entry))
  if range == nil or range.start_time == 0 then
    return ""
  end
  local local_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(range.start_time)
  return UIUtil.get_text_by_id(self.open_time_format_text_id, local_time.Month, local_time.Day, string.format("%02d", local_time.Hour), string.format("%02d", local_time.Minute))
end

function new_year_sprint_activity_module:get_card_open_time_range_text(entry)
  if entry == nil then
    return ""
  end
  local range = activity_center_module:get_activity_time_range(self:get_card_activity_id(entry))
  if range == nil or range.start_time == 0 or range.end_time == 0 then
    return ""
  end
  local start_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(range.start_time)
  local end_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(range.end_time)
  return UIUtil.get_text_by_id(self.open_time_range_format_text_id, start_time.Year, start_time.Month, start_time.Day, string.format("%02d", start_time.Hour), string.format("%02d", start_time.Minute), end_time.Year, end_time.Month, end_time.Day, string.format("%02d", end_time.Hour), string.format("%02d", end_time.Minute))
end

function new_year_sprint_activity_module:get_card_remain_text(entry)
  if entry == nil then
    return ""
  end
  local phase, remain = self:get_time_phase(self:get_card_activity_id(entry))
  if phase ~= self.time_phase.running or remain <= 0 then
    return ""
  end
  return UIUtil.format_left_time(remain)
end

function new_year_sprint_activity_module:get_card_progress_state(entry)
  local progress_state = self.card_progress_state
  if entry == nil then
    return progress_state.not_finished
  end
  local is_finished
  if self:is_memory_shelf_entry(entry) then
    is_finished = activity_center_module:is_tracker_reached(self.memory_shelf_special.end_tracker_id)
  else
    is_finished = activity_center_module:is_tracking_tasks_finished(self:get_card_tracking_id(entry))
  end
  return is_finished and progress_state.finished or progress_state.not_finished
end

function new_year_sprint_activity_module:get_card_activity_id(entry)
  if entry == nil then
    return 0
  end
  local ids = activity_center_module:get_page_timing_activity_ids_by_order(self.main_page_id, entry.card_index)
  return ids[1] or 0
end

function new_year_sprint_activity_module:get_frame_type(entry)
  if entry == nil then
    return nil
  end
  return activity_center_module:get_page_image_id_by_order(self.main_page_id, entry.card_index)
end

function new_year_sprint_activity_module:get_card_title_id(entry)
  if entry == nil then
    return nil
  end
  return activity_center_module:get_page_title_id_by_order(self.main_page_id, entry.card_index)
end

function new_year_sprint_activity_module:get_card_background_path(entry)
  if entry == nil then
    return nil
  end
  return activity_center_module:get_page_background_path_by_order(self.main_page_id, entry.card_index)
end

function new_year_sprint_activity_module:get_dialog_image_path(entry)
  if entry == nil then
    return nil
  end
  return activity_center_module:get_page_image_path_by_order(self.main_page_id, entry.card_index)
end

local function get_title_desc_task_id(module, entry)
  if entry == nil then
    return 0
  end
  return activity_center_module:get_page_title_desc_task_id_by_order(module.main_page_id, entry.card_index)
end

function new_year_sprint_activity_module:get_dialog_title(entry)
  local task_id = get_title_desc_task_id(self, entry)
  if task_id ~= 0 then
    local name = activity_center_module:get_task_name_and_desc(task_id)
    if string.is_valid(name) then
      return name
    end
  end
  local title_id = self:get_card_title_id(entry)
  if not string.is_valid(title_id) then
    return nil
  end
  return UIUtil.get_text_by_id(title_id)
end

function new_year_sprint_activity_module:get_dialog_desc(entry)
  if entry == nil then
    return nil
  end
  local desc_id = activity_center_module:get_page_desc_id_by_order(self.main_page_id, entry.card_index)
  if string.is_valid(desc_id) then
    return UIUtil.get_text_by_id(desc_id)
  end
  local task_id = get_title_desc_task_id(self, entry)
  if task_id == 0 then
    return nil
  end
  local _, desc = activity_center_module:get_task_name_and_desc(task_id)
  if not string.is_valid(desc) then
    return nil
  end
  return desc
end

function new_year_sprint_activity_module:get_dialog_reward_item_ids(entry)
  if entry == nil then
    return EMPTY_REWARD_LIST
  end
  return activity_center_module:get_page_reward_item_ids_by_order(self.main_page_id, entry.card_index)
end

function new_year_sprint_activity_module:get_card_tracking_id(entry)
  local ids = activity_center_module:get_tracking_ids_by_activity_id(self:get_card_activity_id(entry))
  return ids[1] or 0
end

function new_year_sprint_activity_module:get_tracking_target(entry)
  if entry == nil then
    return nil
  end
  return activity_center_module:make_tracking_target_by_id(self:get_card_tracking_id(entry))
end

function new_year_sprint_activity_module:get_tracking_state(entry)
  local target = self:get_tracking_target(entry)
  if activity_center_module:is_tracking(target) then
    return activity_center_module.tracking_state.tracking
  end
  return activity_center_module.tracking_state.can_track
end

function new_year_sprint_activity_module:get_tracking_text(target)
  local state = activity_center_module:is_tracking(target) and activity_center_module.tracking_state.tracking or activity_center_module.tracking_state.can_track
  if state == activity_center_module.tracking_state.can_track then
    local text = activity_center_module:get_tracking_button_text(target)
    if string.is_valid(text) then
      return text
    end
  end
  local text_id = self.tracking_text_id[state]
  return string.is_valid(text_id) and UIUtil.get_text_by_id(text_id) or ""
end

function new_year_sprint_activity_module:has_tracking_target(entry)
  return self:get_tracking_target(entry) ~= nil
end

function new_year_sprint_activity_module:get_main_activity_data()
  return activity_center_module:get_activity_by_id(self.main_activity_id)
end

function new_year_sprint_activity_module:get_card_red_dot_slot(entry)
  if entry == nil or entry.card_index == nil then
    return nil
  end
  return self.red_dot_slot.card_base + entry.card_index - 1
end

function new_year_sprint_activity_module:build_unlocked_slot_mask()
  local mask = 0
  local card_state = self.card_state
  local entries = self:get_card_entries()
  for index = 1, #entries do
    local entry = entries[index]
    local state = self:get_card_state(entry)
    local is_unlocked = state == card_state.normal_running or state == card_state.timed_running
    if is_unlocked and self:is_memory_shelf_unlock_required(entry) then
      is_unlocked = false
    end
    if is_unlocked then
      local slot_id = self:get_card_red_dot_slot(entry)
      if slot_id ~= nil then
        mask = math.set_bit(mask, slot_id, 1)
      end
    end
  end
  if self:is_main_activity_running() then
    mask = math.set_bit(mask, self.red_dot_slot.hot_selling, 1)
  end
  return mask
end

function new_year_sprint_activity_module:has_slot_red_dot(slot_id)
  if slot_id == nil then
    return false
  end
  local data = self:get_main_activity_data()
  if data == nil then
    return false
  end
  return data:HasSlotRedDot(slot_id)
end

function new_year_sprint_activity_module:get_card_red_dot_type(entry)
  if self:has_slot_red_dot(self:get_card_red_dot_slot(entry)) then
    return RedPointType.StrongRP
  end
  return RedPointType.None
end

function new_year_sprint_activity_module:get_hot_selling_red_dot_type()
  if self:has_slot_red_dot(self.red_dot_slot.hot_selling) then
    return RedPointType.NewRp
  end
  return RedPointType.None
end

function new_year_sprint_activity_module:is_activity_state_opened(activity_id)
  activity_id = activity_id or self.main_activity_id
  local state = activity_center_module:get_activity_state(activity_id)
  return state ~= activity_center_module.activity_state.None
end

function new_year_sprint_activity_module:get_main_activity_status()
  local main_activity_id = self.main_activity_id
  local phase, remain = self:get_time_phase(main_activity_id)
  if phase ~= self.time_phase.running then
    return false, 0
  end
  if not self:is_activity_state_opened(main_activity_id) then
    return false, 0
  end
  return true, remain
end

function new_year_sprint_activity_module:is_main_activity_running()
  local is_running = self:get_main_activity_status()
  return is_running
end

function new_year_sprint_activity_module:get_main_activity_remain_seconds()
  local _, remain = self:get_main_activity_status()
  return remain
end

return new_year_sprint_activity_module
