spring_festival_activity_module = spring_festival_activity_module or {}
spring_festival_activity_module.main_activity_id = 80001
spring_festival_activity_module.main_page_id = 5
spring_festival_activity_module.page_key = {
  embroidered = 1,
  fireworks = 2,
  seven_days = 3,
  lantern_riddles = 4
}
spring_festival_activity_module.card_state = {
  locked_secret = 0,
  locked = 1,
  expired = 2,
  unlocked = 3
}
spring_festival_activity_module.time_phase = activity_center_module.activity_time_phase
spring_festival_activity_module.corner_state = {
  calendar = 0,
  fireworks = 1,
  lantern = 2
}
spring_festival_activity_module.corner_open_tip_state = {firework = 0, lantern = 1}
spring_festival_activity_module.corner_activity_entries = {
  {
    tracking_id = 17,
    button_state = spring_festival_activity_module.corner_state.lantern,
    text_id = "SpringFestival_ActivityCalendar_Light",
    open_tip_state = spring_festival_activity_module.corner_open_tip_state.lantern,
    daily_open_from_server = true,
    session_count = 2
  },
  {
    tracking_id = 5,
    button_state = spring_festival_activity_module.corner_state.fireworks,
    text_id = "SpringFestival_ActivityCalendar_FireWork",
    open_tip_state = spring_festival_activity_module.corner_open_tip_state.firework
  }
}
spring_festival_activity_module.corner_activity_by_tracking_id = {}
for _, entry in ipairs(spring_festival_activity_module.corner_activity_entries) do
  spring_festival_activity_module.corner_activity_by_tracking_id[entry.tracking_id] = entry
end
spring_festival_activity_module.corner_countdown_visible_seconds = 43200
spring_festival_activity_module.tracking_state = {can_track = 0, tracking = 1}
spring_festival_activity_module.tracking_kind = activity_center_module.tracking_kind
spring_festival_activity_module.tracking_text_id = {
  [spring_festival_activity_module.tracking_state.can_track] = "SpringFestival_TrackTask",
  [spring_festival_activity_module.tracking_state.tracking] = "SpringFestival_TrackTaskCancel"
}
spring_festival_activity_module.lantern_tracking_state = {
  can_track = spring_festival_activity_module.tracking_state.can_track,
  tracking = spring_festival_activity_module.tracking_state.tracking,
  go_riddles = 2,
  wait_lantern = 3
}
spring_festival_activity_module.main_prewarm_slot = "main_prewarm"
spring_festival_activity_module.firework_tracking_state = {
  can_track = spring_festival_activity_module.tracking_state.can_track,
  tracking = spring_festival_activity_module.tracking_state.tracking,
  phase_finished = 2,
  all_finished = 3
}
spring_festival_activity_module.tracking_source = {
  [spring_festival_activity_module.main_prewarm_slot] = {tracking_id = 1},
  [spring_festival_activity_module.page_key.embroidered] = {tracking_id = 2},
  [spring_festival_activity_module.page_key.fireworks] = {
    tracking_phases = {
      3,
      {
        4,
        pending_state = spring_festival_activity_module.firework_tracking_state.phase_finished
      }
    },
    red_dot_tracking_phases = {
      3,
      4,
      5
    },
    idle_state = spring_festival_activity_module.firework_tracking_state.all_finished
  },
  [spring_festival_activity_module.page_key.seven_days] = {
    tracking_by_tog = {
      6,
      7,
      8,
      9,
      10,
      11,
      12
    }
  },
  [spring_festival_activity_module.page_key.lantern_riddles] = {
    tracking_by_tog = {
      {
        tracking_phases = {
          13,
          {
            14,
            actionable_state = spring_festival_activity_module.lantern_tracking_state.go_riddles
          }
        }
      },
      {
        tracking_phases = {
          15,
          {
            16,
            pending_state = spring_festival_activity_module.lantern_tracking_state.wait_lantern
          }
        },
        idle_state = spring_festival_activity_module.lantern_tracking_state.wait_lantern,
        final_phase_tracking_id = 16
      }
    }
  }
}
spring_festival_activity_module.panel_class_path = "UI/ActivityCenter/SubPanel/SpringFestival/ActivitySpringFestivalPanel"
spring_festival_activity_module.entry_card_class_path = "UI/ActivityCenter/SubPanel/SpringFestival/SpringFestivalEntryCard"
spring_festival_activity_module.page_entries = {
  {
    key = spring_festival_activity_module.page_key.embroidered,
    page_class = "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestivalEmbroideredPage",
    locked_state = spring_festival_activity_module.card_state.locked
  },
  {
    key = spring_festival_activity_module.page_key.fireworks,
    page_class = "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestivalFireworksPage",
    locked_state = spring_festival_activity_module.card_state.locked
  },
  {
    key = spring_festival_activity_module.page_key.seven_days,
    page_class = "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestival7DaysPage",
    locked_state = spring_festival_activity_module.card_state.locked
  },
  {
    key = spring_festival_activity_module.page_key.lantern_riddles,
    page_class = "UI/ActivityCenter/SubPanel/SpringFestival/Page/SpringFestivalLanternRiddlesPage",
    locked_state = spring_festival_activity_module.card_state.locked_secret
  }
}
spring_festival_activity_module.tips_text_id = {
  not_open = "SpringFestival_Activity_OpenTimeTips",
  ended = "SpringFestival_Activity_EndTips"
}
spring_festival_activity_module.activity_end_gate_key = "spring_festival_activity_end"
spring_festival_activity_module.activity_end_dialog_text_id = "SpringFestival_Activity_EndDialog"
spring_festival_activity_module.red_dot_slot = {
  card_base = 0,
  seven_days_base = 3,
  lantern_base = 10,
  xieve_base = 15,
  corner_base = 18
}

function spring_festival_activity_module:get_card_red_dot_slot(page_key)
  return self.red_dot_slot.card_base + page_key - 1
end

function spring_festival_activity_module:get_seven_days_red_dot_slot(day)
  return self.red_dot_slot.seven_days_base + day
end

function spring_festival_activity_module:get_lantern_red_dot_slot(tab_index)
  return self.lantern_tab_whole_slot[tab_index]
end

function spring_festival_activity_module:get_xieve_red_dot_slot(phase)
  return self.red_dot_slot.xieve_base + phase
end

spring_festival_activity_module.corner_slot_offset = {}
do
  local next_slot = spring_festival_activity_module.red_dot_slot.corner_base + 1
  for index, entry in ipairs(spring_festival_activity_module.corner_activity_entries) do
    spring_festival_activity_module.corner_slot_offset[index] = next_slot
    next_slot = next_slot + (entry.session_count or 1)
  end
end

function spring_festival_activity_module:get_corner_red_dot_slot(corner_index, session_index)
  local base = self.corner_slot_offset[corner_index]
  if base == nil then
    Logger.LogError("[SpringFestival] get_corner_red_dot_slot: 未知的 corner_index " .. tostring(corner_index))
    return self.red_dot_slot.corner_base
  end
  return base + (session_index or 1) - 1
end

spring_festival_activity_module.page_entry_by_key = {}
for index, entry in ipairs(spring_festival_activity_module.page_entries) do
  entry.card_index = index
  spring_festival_activity_module.page_entry_by_key[entry.key] = entry
end
spring_festival_activity_module.firework_time_tracking_id = 5
spring_festival_activity_module.firework_time_text_id = {
  remain = "SpringFestival_Fireworks_Fireworktime_0",
  ready = "SpringFestival_Fireworks_Fireworktime_1"
}
spring_festival_activity_module.firework_cant_exchange_text_id = {
  [spring_festival_activity_module.firework_tracking_state.phase_finished] = "SpringFestival_Lantern_CantExchange_01",
  [spring_festival_activity_module.firework_tracking_state.all_finished] = "SpringFestival_CantExchange_03"
}
spring_festival_activity_module.seven_days_mission_state = {
  locked = 0,
  new_unlocked = 1,
  unlocked = 2,
  finished = 3
}
spring_festival_activity_module.seven_days_drawlock_state = {
  locked = 0,
  unlocked = 1,
  unlocked_mark = 2
}
spring_festival_activity_module.seven_days_tracking_state = {
  can_track = spring_festival_activity_module.tracking_state.can_track,
  tracking = spring_festival_activity_module.tracking_state.tracking,
  finished = 2,
  locked = 3
}
spring_festival_activity_module.seven_days_guide_window_id = {
  22,
  23,
  0,
  0,
  0,
  0,
  0
}
spring_festival_activity_module.seven_days_special_name_text_id = {
  "SpringFestival_7Day_SpecialName_01",
  "SpringFestival_7Day_SpecialName_02"
}
spring_festival_activity_module.seven_days_special_name_locked_text_id = "SpringFestival_7Day_SpecialName_03"
spring_festival_activity_module.lantern_active_value_text_id = "SpringFestival_LanternRiddles_ActiveValue"
spring_festival_activity_module.lantern_tab_entries = {
  {
    title_text_id = "SpringFestival_LanternRiddles_Tabs_0",
    has_riddle_reward = true
  },
  {
    title_text_id = "SpringFestival_LanternRiddles_Tabs_1",
    has_riddle_reward = false,
    phase_red_dot_entries = {
      {tracking_id = 15},
      {tracking_id = 16, require_cleared_tracking_id = 15}
    }
  }
}
spring_festival_activity_module.lantern_time_tracking_id = 17
spring_festival_activity_module.lantern_time_text_id = {
  remain = "SpringFestival_LanternRiddles_LanternTime_0",
  ready = "SpringFestival_LanternRiddles_LanternTime_1"
}
spring_festival_activity_module.lantern_cant_exchange_text_id = {
  wait_next = "SpringFestival_Lantern_CantExchange_01",
  all_finished = "SpringFestival_Lantern_CantExchange_02"
}
spring_festival_activity_module.lantern_tab_whole_slot = {}
spring_festival_activity_module.lantern_phase_slot_offset = {}
spring_festival_activity_module.lantern_tab_red_dot_slots = {}
spring_festival_activity_module.lantern_card_tip_slots = {}
do
  local module = spring_festival_activity_module
  local next_slot = module.red_dot_slot.lantern_base + 1
  for tab_index, tab_entry in ipairs(module.lantern_tab_entries) do
    local slots = {}
    local phase_entries = tab_entry.phase_red_dot_entries
    if phase_entries == nil then
      module.lantern_tab_whole_slot[tab_index] = next_slot
      table.insert(slots, next_slot)
      next_slot = next_slot + 1
    else
      for _, phase_entry in ipairs(phase_entries) do
        module.lantern_phase_slot_offset[phase_entry.tracking_id] = next_slot
        table.insert(slots, next_slot)
        next_slot = next_slot + 1
      end
    end
    module.lantern_tab_red_dot_slots[tab_index] = slots
  end
  local lantern_corner_entry = module.corner_activity_by_tracking_id[module.lantern_time_tracking_id]
  local lantern_session_count = lantern_corner_entry ~= nil and lantern_corner_entry.session_count or 1
  for session_index = 1, lantern_session_count do
    module.lantern_card_tip_slots[session_index] = next_slot
    next_slot = next_slot + 1
  end
  local lantern_slot_end = next_slot - 1
  if lantern_slot_end > module.red_dot_slot.xieve_base then
    Logger.LogError("[SpringFestival] 元宵红点段越界：占到位 " .. tostring(lantern_slot_end) .. "，但下一段 xieve_base = " .. tostring(module.red_dot_slot.xieve_base) .. "，会与除夕段重叠。请把 xieve_base 及后续各段 base 往后推。")
  end
end

function spring_festival_activity_module:get_lantern_phase_red_dot_slot(tracking_id)
  return self.lantern_phase_slot_offset[tracking_id]
end

function spring_festival_activity_module:get_lantern_card_tip_red_dot_slot(session_index)
  return self.lantern_card_tip_slots[session_index]
end

return spring_festival_activity_module
