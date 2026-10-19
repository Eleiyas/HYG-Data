activity_center_module = activity_center_module or {}
activity_center_module.activity_type = {
  none = 0,
  jump = 1,
  sign_in = 2,
  task_list = 3,
  bp = 4,
  spring_festival = 5,
  new_year_sprint = 6,
  progress_reward = 7,
  starring = 8,
  secret_santa = 9
}
activity_center_module.activity_panel_registry = {
  [activity_center_module.activity_type.sign_in] = "UI/ActivityCenter/SubPanel/SignIn/ActivitySignInPanel",
  [activity_center_module.activity_type.jump] = "UI/ActivityCenter/SubPanel/Jump/ActivityJumpPanel",
  [activity_center_module.activity_type.task_list] = "UI/ActivityCenter/SubPanel/TaskList/ActivityTaskListPanel",
  [activity_center_module.activity_type.spring_festival] = "UI/ActivityCenter/SubPanel/SpringFestival/ActivitySpringFestivalPanel",
  [activity_center_module.activity_type.progress_reward] = "UI/ActivityCenter/SubPanel/ProgressReward/ActivityProgressRewardPanel",
  [activity_center_module.activity_type.starring] = "UI/ActivityCenter/SubPanel/Starring/StarringActivityPanel",
  [activity_center_module.activity_type.secret_santa] = "UI/ActivityCenter/SubPanel/SecretSanta/ActivitySecretSantaPanel",
  [activity_center_module.activity_type.new_year_sprint] = "UI/ActivityCenter/SubPanel/NewYearSprint/ActivityNewYearSprintPanel"
}
activity_center_module.default_activity_panel_class = "UI/ActivityCenter/SubPanel/ActivityBasePanel"
activity_center_module.activity_state = {
  None = 0,
  Opened = 1,
  Unlocked = 2,
  Finished = 3
}
activity_center_module.activity_task_state = {
  Locked = 0,
  Ongoing = 1,
  Finished = 2,
  Claimed = 3
}
activity_center_module.signin_slot_state = {
  NotSigned = 0,
  Signed = 1,
  Taken = 2
}
activity_center_module.top_tab_category = {recommend = 1, discover = 2}
activity_center_module.top_tab_icon = {
  [activity_center_module.top_tab_category.recommend] = "UISprite/Load/Common/Icon_Common_Countdown",
  [activity_center_module.top_tab_category.discover] = "UISprite/Load/Common/Icon_Common_StarLife"
}
activity_center_module.default_category = activity_center_module.top_tab_category.recommend
activity_center_module.main_page_class_path = "UI/ActivityCenter/ActivityCenterMainPage"
activity_center_module.introduction_dialog_class_path = "UI/ActivityCenter/ActivityIntroductionDialog"
activity_center_module.top_tab_item_class_path = "UI/ActivityCenter/ActivityCenterTopTabItem"
activity_center_module.list_toggle_class_path = "UI/ActivityCenter/ActivityCenterActTabItem"
activity_center_module.activity_expire_tips_text_id = "Activity_ExpireTips"
activity_center_module.activity_end_dialog_text_id = "SpringFestival_Activity_EndDialog"
activity_center_module.activity_end_gate_key_prefix = "activity_end_"
activity_center_module.act_tab_type = {normal = 0, kv = 1}
activity_center_module.activity_time_phase = {
  none = 0,
  before_start = 1,
  running = 2,
  ended = 3
}
activity_center_module.tracking_kind = {task = 0, feature = 1}
activity_center_module.memo_navigable_task_states = {
  [1] = true,
  [5] = true
}
activity_center_module.tracking_state = {can_track = 0, tracking = 1}

function activity_center_module:get_panel_class_by_type(activity_type)
  local cls = self.activity_panel_registry[activity_type]
  if cls == nil or cls == "" then
    if activity_type ~= nil and activity_type ~= self.activity_type.none then
      Logger.LogWarning("[ActivityCenter] activity_panel_registry missing activity_type = " .. tostring(activity_type) .. ", fallback to default panel.")
    end
    return self.default_activity_panel_class
  end
  return cls
end

function activity_center_module:get_act_tab_type(activity_id)
  local ui_cfg = self:get_ui_cfg(activity_id)
  if ui_cfg == nil or not string.is_valid(ui_cfg.listicon) then
    return activity_center_module.act_tab_type.normal
  end
  return activity_center_module.act_tab_type.kv
end

return activity_center_module
