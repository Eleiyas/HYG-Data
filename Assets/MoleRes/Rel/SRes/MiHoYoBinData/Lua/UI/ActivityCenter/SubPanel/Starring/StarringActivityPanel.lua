local M = G.Class("StarringActivityPanel", "UI/ActivityCenter/SubPanel/ActivityBasePanel")
local base = G.ActivityBasePanel
local SUB_ACTIVITY_IDS = {80037, 80038}
local PAGE_ID = 8
local ENDED_TIME_TEXT_ID = "LeadingStarFestival_Activity_tips"
local SUB_ACTIVITY_STATE = {
  not_started = 0,
  running = 1,
  ended = 2
}
local SELLING_STATE = {not_started = 0, opened = 1}
local TASK_AREA_STATE = {
  not_started = 0,
  running = 1,
  finished = 2,
  claimed = 3
}
local TASK_TYPE = {normal = 1, summary = 2}
local TASK_ITEM_CLS = "UI/ActivityCenter/SubPanel/Starring/StarringActivityTaskItem"

function M:init()
  base.init(self)
  self._sub_activity_state_groups = {}
  self._sub_activity_time_texts = {}
  self._sub_activity_lock_texts = {}
  self._sub_activity_unlock_texts = {}
  self._task_items = {}
  self._gift_item = nil
  self._task_area_not_started = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_help1, pack(self, M._on_btn_help_click1))
  self:bind_callback(self._btn_help2, pack(self, M._on_btn_help_click2))
  self:bind_callback(self._btn_friend1, pack(self, M._on_btn_help_click1))
  self:bind_callback(self._btn_friend2, pack(self, M._on_btn_help_click2))
  self:bind_callback(self._btn_reddot_gift, pack(self, M._on_btn_gift_click))
  self:bind_callback(self._btn_hotselling, pack(self, M._on_btn_hotselling_click))
  self._sub_activity_state_groups = {
    self._ui_state_activity1,
    self._ui_state_activity2
  }
  self._sub_activity_time_texts = {
    self._txt_time1,
    self._txt_time2
  }
  self._sub_activity_lock_texts = {
    self._txt_activity1_lock,
    self._txt_activity2_lock
  }
  self._sub_activity_unlock_texts = {
    self._txt_activity1_unlock,
    self._txt_activity2_unlock
  }
  if is_null(self._obj_item) then
    Logger.LogWarning("[StarringActivityPanel] _obj_item is missing on prefab.")
  else
    self._gift_item = self:add_panel(item_module.item_v2_panel_cls_name, self._obj_item.transform)
  end
end

function M:update_time_remain()
  base.update_time_remain(self)
  if not self:is_in_show_state() then
    return
  end
  self:_refresh_selling_state()
  self:_refresh_sub_activities()
  local state, _ = self:_get_activity_phase(self._activity_id)
  if state == SUB_ACTIVITY_STATE.not_started ~= self._task_area_not_started then
    self:_refresh_task_area()
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnActivityListChanged, function()
    self:refresh()
  end)
end

function M:refresh()
  base.refresh(self)
  self:_refresh_sub_activity_titles()
  self:_refresh_selling_state()
  self:_refresh_sub_activities()
  self:_refresh_task_area()
end

function M:_refresh_sub_activity_titles()
  local lock_texts = self._sub_activity_lock_texts
  local unlock_texts = self._sub_activity_unlock_texts
  for index = 1, #SUB_ACTIVITY_IDS do
    local title_id = activity_center_module:get_sub_page_title_id(PAGE_ID, index)
    if string.is_valid(title_id) then
      local lock_txt = lock_texts and lock_texts[index]
      if not is_null(lock_txt) then
        UIUtil.set_text_by_id(lock_txt, title_id)
      end
      local unlock_txt = unlock_texts and unlock_texts[index]
      if not is_null(unlock_txt) then
        UIUtil.set_text_by_id(unlock_txt, title_id)
      end
    end
  end
end

function M:_refresh_selling_state()
  if is_null(self._ui_state_selling) then
    Logger.LogWarning("[StarringActivityPanel] _ui_state_selling is missing on prefab.")
    return
  end
  local state, _ = self:_get_activity_phase(self._activity_id)
  local is_opened = state ~= SUB_ACTIVITY_STATE.not_started
  self._ui_state_selling:SetState(is_opened and SELLING_STATE.opened or SELLING_STATE.not_started)
end

function M:_refresh_sub_activities()
  for index = 1, #SUB_ACTIVITY_IDS do
    local state, remain = self:_get_activity_phase(SUB_ACTIVITY_IDS[index])
    local group = self._sub_activity_state_groups[index]
    if is_null(group) then
      Logger.LogWarning("[StarringActivityPanel] _ui_state_activity" .. tostring(index) .. " is missing on prefab.")
    else
      group:SetState(state)
    end
    local txt = self._sub_activity_time_texts[index]
    if not is_null(txt) then
      local time_text = ""
      if state == SUB_ACTIVITY_STATE.ended then
        time_text = UIUtil.get_text_by_id(ENDED_TIME_TEXT_ID)
      elseif 0 < remain then
        time_text = UIUtil.format_left_time(remain)
      end
      UIUtil.set_text(txt, time_text)
    end
  end
end

function M:_refresh_task_area()
  local state, _ = self:_get_activity_phase(self._activity_id)
  local is_not_started = state == SUB_ACTIVITY_STATE.not_started
  self._task_area_not_started = is_not_started
  local tasks = is_not_started and {} or self:_get_tasks()
  if is_not_started then
  end
  local summary_task = self:_get_summary_task()
  if not is_null(self._ui_state_task) then
    self._ui_state_task:SetState(is_not_started and TASK_AREA_STATE.not_started or self:_get_task_area_state(summary_task))
  else
    Logger.LogWarning("[StarringActivityPanel] _ui_state_task is missing on prefab.")
  end
  self:_refresh_task_progress(tasks)
  self:_refresh_task_list(tasks)
  self:_refresh_gift_item(summary_task)
end

function M:_refresh_gift_item(summary_task)
  if self._gift_item == nil then
    return
  end
  local item_id = summary_task and summary_task.reward_item_id or 0
  self._gift_item:set_item_data(item_id, summary_task and summary_task.reward_count or 0)
  if 0 < item_id then
    self._gift_item:bind_item_info_btn(item_id)
  end
end

function M:_refresh_task_progress(tasks)
  local total = #tasks
  local finished_count = 0
  for _, task in ipairs(tasks) do
    if task.is_finished then
      finished_count = finished_count + 1
    end
  end
  if not is_null(self._slider) then
    self._slider.value = 0 < total and finished_count / total or 0
  end
  UIUtil.set_text(self._txt_task_num, finished_count .. "/" .. total)
end

function M:_get_task_area_state(summary_task)
  if summary_task == nil or not summary_task.is_finished then
    return TASK_AREA_STATE.running
  end
  return summary_task.is_claimed and TASK_AREA_STATE.claimed or TASK_AREA_STATE.finished
end

function M:_refresh_task_list(tasks)
  local binder = self:_get_task_list_binder()
  if binder == nil then
    return
  end
  for i = 1, #tasks do
    local extra = tasks[i]
    
    function extra.on_claim(task_id)
      self:_request_task_claim(task_id)
    end
    
    local item = self._task_items[i]
    if item == nil then
      local obj = binder:AddItem(0)
      if not_null(obj) then
        item = self:add_panel(TASK_ITEM_CLS, obj, extra)
        self._task_items[i] = item
        UIUtil.set_active(obj, true)
      end
    else
      item:set_extra_data(extra)
      item:force_refresh()
      item:set_active(true)
    end
  end
  for i = #tasks + 1, #self._task_items do
    local item = self._task_items[i]
    if item ~= nil then
      item:set_active(false)
    end
  end
end

function M:_get_task_list_binder()
  if self._task_list_binder ~= nil then
    return self._task_list_binder
  end
  if is_null(self._obj_task) then
    Logger.LogWarning("[StarringActivityPanel] _obj_task is missing on prefab.")
    return nil
  end
  local binder_type = CS.miHoYo.HYG.UI.ListItemBinder
  if binder_type == nil then
    return nil
  end
  local parent = self._obj_task.transform.parent
  if is_null(parent) then
    return nil
  end
  self._task_list_binder = parent:GetComponent(typeof(binder_type))
  if is_null(self._task_list_binder) then
    self._task_list_binder = nil
    Logger.LogWarning("[StarringActivityPanel] ListItemBinder is missing on _obj_task's parent.")
  end
  return self._task_list_binder
end

function M:_get_summary_task()
  local data = self:get_activity_data()
  if data == nil or data.TaskCount == nil or data.GetTaskByIndex == nil then
    return nil
  end
  for index = 0, data.TaskCount - 1 do
    local task = data:GetTaskByIndex(index)
    if task ~= nil and task.TaskType == TASK_TYPE.summary then
      local is_claimed = task.IsClaimed
      local has_reward = 0 < task.RewardCount
      return {
        task_id = task.TaskId,
        reward_item_id = has_reward and task:GetRewardItemId(0) or 0,
        reward_count = has_reward and task:GetRewardItemCount(0) or 0,
        is_finished = is_claimed or task.IsFinished,
        is_claimed = is_claimed,
        can_claim = task.CanClaim
      }
    end
  end
  return nil
end

function M:_get_tasks()
  local ret = {}
  local data = self:get_activity_data()
  if data == nil or data.TaskCount == nil or data.GetTaskByIndex == nil then
    return ret
  end
  for index = 0, data.TaskCount - 1 do
    local task = data:GetTaskByIndex(index)
    if task ~= nil and task.TaskType == TASK_TYPE.normal then
      local is_claimed = task.IsClaimed
      local is_finished = is_claimed or task.IsFinished
      local has_reward = 0 < task.RewardCount
      table.insert(ret, {
        task_id = task.TaskId,
        task_desc = task.TaskDesc,
        jump_id = task.JumpId or 0,
        reward_item_id = has_reward and task:GetRewardItemId(0) or 0,
        reward_count = has_reward and task:GetRewardItemCount(0) or 0,
        is_finished = is_finished,
        is_claimed = is_claimed,
        can_claim = task.CanClaim,
        _order = index,
        _sort_key = is_claimed and 2 or is_finished and 1 or 0
      })
    end
  end
  table.sort(ret, function(a, b)
    if a._sort_key ~= b._sort_key then
      return a._sort_key < b._sort_key
    end
    return a._order < b._order
  end)
  return ret
end

function M:_on_btn_gift_click()
  local summary_task = self:_get_summary_task()
  if summary_task == nil or not summary_task.can_claim then
    return
  end
  self:_request_task_claim(summary_task.task_id)
end

function M:_request_task_claim(task_id)
  local data = self:get_activity_data()
  if data == nil or data.RequestClaim == nil or data:IsClaiming() then
    return
  end
  if task_id == nil or task_id == 0 then
    return
  end
  data:RequestClaim(task_id, function()
    if is_null(self.game_obj) then
      return
    end
    local rewards = {}
    for index = 0, data.ClaimRewardCount - 1 do
      table.insert(rewards, {
        id = data:GetClaimRewardItemId(index),
        num = data:GetClaimRewardItemCount(index)
      })
    end
    if 0 < #rewards then
      common_ui_module:show_reward_dialog(nil, nil, rewards)
    end
  end)
end

function M:_on_btn_hotselling_click()
  local state, _ = self:_get_activity_phase(self._activity_id)
  if state == SUB_ACTIVITY_STATE.not_started then
    return
  end
  local main_tab_id = tvshop_module:get_main_tab_id_by_activity_id(self._activity_id)
  if main_tab_id == nil then
    Logger.LogWarning("[StarringActivityPanel] no BTVShopMainTabCfg matches activity " .. tostring(self._activity_id))
    return
  end
  UIManagerInstance:open("UI/TVShopping/TVShoppingNewPage", {
    tab_type = tvshop_module.TabsType.TvShopTabsLuomi,
    enter_by_ad = false,
    main_tab_id = main_tab_id
  })
end

function M:_get_activity_phase(activity_id)
  local data = activity_center_module:get_activity_by_id(activity_id)
  if data == nil then
    return SUB_ACTIVITY_STATE.not_started, 0
  end
  local start_time = data.StartTimeUtcSec
  local end_time = data.EndTimeUtcSec
  local now = TimeUtil.ServerUtcTimeSeconds
  if data.State == activity_center_module.activity_state.None or start_time ~= 0 and start_time > now then
    local remain = start_time > now and start_time - now or 0
    return SUB_ACTIVITY_STATE.not_started, remain
  end
  if end_time ~= 0 and end_time <= now then
    return SUB_ACTIVITY_STATE.ended, 0
  end
  local remain = end_time > now and end_time - now or 0
  return SUB_ACTIVITY_STATE.running, remain
end

function M:_on_btn_help_click1()
  self:_show_sub_activity_introduction(1)
end

function M:_on_btn_help_click2()
  self:_show_sub_activity_introduction(2)
end

function M:_show_sub_activity_introduction(index)
  local state = self:_get_activity_phase(SUB_ACTIVITY_IDS[index])
  if state ~= SUB_ACTIVITY_STATE.running then
    return
  end
  local introduction_cfg_id = activity_center_module:get_sub_page_guide_window_id(PAGE_ID, index)
  if introduction_cfg_id <= 0 then
    Logger.LogWarning("[StarringActivityPanel] ActivityPageCfg 页面 " .. PAGE_ID .. " 的 ImageId " .. index .. " 未配 GuideWindowId，说明弹窗打不开。")
    return
  end
  activity_center_module:show_activity_introduction_dialog(SUB_ACTIVITY_IDS[index], introduction_cfg_id)
end

return M
