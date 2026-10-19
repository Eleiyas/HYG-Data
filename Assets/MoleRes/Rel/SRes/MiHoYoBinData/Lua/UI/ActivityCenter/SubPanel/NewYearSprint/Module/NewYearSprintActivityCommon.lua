new_year_sprint_activity_module = new_year_sprint_activity_module or {}
new_year_sprint_activity_module.main_activity_id = 80030
new_year_sprint_activity_module.main_page_id = 6
new_year_sprint_activity_module.card_state = {
  normal_running = 0,
  timed_running = 1,
  locked = 2,
  ended = 3
}
new_year_sprint_activity_module.dialog_state = {
  normal_running = new_year_sprint_activity_module.card_state.normal_running,
  timed_running = new_year_sprint_activity_module.card_state.timed_running,
  locked = new_year_sprint_activity_module.card_state.locked,
  ended = new_year_sprint_activity_module.card_state.ended,
  completed = 4
}
new_year_sprint_activity_module.card_progress_state = {not_finished = 0, finished = 1}
new_year_sprint_activity_module.time_phase = activity_center_module.activity_time_phase
new_year_sprint_activity_module.locked_tips_text_id = {
  open_time = "NewYear_ActivityLocked_01",
  coming_soon = "NewYear_ActivityLocked_02",
  memory_shelf = "NewYear_ActivityLocked_03"
}
new_year_sprint_activity_module.tracking_text_id = {
  [activity_center_module.tracking_state.can_track] = "NewYear_ActivityTracking",
  [activity_center_module.tracking_state.tracking] = "NewYear_ActivityTrackingCancel"
}
new_year_sprint_activity_module.open_time_format_text_id = "NewYear_ActivityTime"
new_year_sprint_activity_module.open_time_range_format_text_id = "NewYear_ActivityOpenTime"
new_year_sprint_activity_module.memory_shelf_special = {
  activity_id = 80046,
  start_tracker_id = 8061,
  end_tracker_id = 8062
}
new_year_sprint_activity_module.red_dot_slot = {card_base = 0, hot_selling = 4}
new_year_sprint_activity_module.panel_class_path = "UI/ActivityCenter/SubPanel/NewYearSprint/ActivityNewYearSprintPanel"
new_year_sprint_activity_module.entry_card_class_path = "UI/ActivityCenter/SubPanel/NewYearSprint/NewYearSprintEntryCard"
new_year_sprint_activity_module.dialog_class_path = "UI/ActivityCenter/SubPanel/NewYearSprint/Dialog/NewYearSprintDialog"
return new_year_sprint_activity_module
