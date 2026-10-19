local M = G.Class("ActivityTaskListPanel", "UI/ActivityCenter/SubPanel/ActivityBasePanel")
local base = G.ActivityBasePanel
local TYPE_ITEM_CLS = "UI/ActivityCenter/SubPanel/TaskList/ActivityTaskListTypeItem"
local MISSION_ITEM_CLS = "UI/ActivityCenter/SubPanel/TaskList/ActivityTaskListMissionItem"

function M:init()
  base.init(self)
  self._type_items = {}
  self._mission_items = {}
  self._current_task_type = 0
end

function M:on_create()
  base.on_create(self)
end

function M:refresh()
  base.refresh(self)
  self:_refresh_type_tabs()
  self:_refresh_mission_list()
  self:_refresh_unlock_text()
end

function M:_refresh_type_tabs()
  if is_null(self._tabs_content_binder) then
    return
  end
  if self._type_items == nil then
    self._type_items = {}
  end
  local type_list = self:_get_task_types() or {}
  if 0 < #type_list and self:_find_task_type(type_list, self._current_task_type) == nil then
    self._current_task_type = type_list[1].task_type
  end
  for i = 1, #type_list do
    local t = type_list[i]
    local extra = {
      task_type = t.task_type,
      tab_name = t.tab_name,
      has_red_dot = t.has_red_dot,
      on_click = function(tt)
        self:on_task_type_changed(tt)
      end
    }
    local cls = self._type_items[i]
    if cls == nil then
      local obj = self._tabs_content_binder:AddItem(0)
      if not_null(obj) then
        cls = self:add_panel(TYPE_ITEM_CLS, obj, extra)
        self._type_items[i] = cls
        UIUtil.set_active(obj, true)
      end
    else
      cls:set_extra_data(extra)
      cls:force_refresh()
      cls:set_active(true)
    end
    if cls ~= nil then
      cls:set_selected(t.task_type == self._current_task_type)
    end
  end
  for i = #type_list + 1, #self._type_items do
    local cls = self._type_items[i]
    if cls ~= nil then
      cls:set_active(false)
    end
  end
end

function M:on_task_type_changed(task_type)
  if self._current_task_type == task_type then
    return
  end
  self._current_task_type = task_type
  for _, item in ipairs(self._type_items) do
    if item and item.set_selected and item.get_task_type then
      item:set_selected(item:get_task_type() == task_type)
    end
  end
  self:_refresh_mission_list()
end

function M:_find_task_type(type_list, task_type)
  if task_type == nil or task_type == 0 then
    return nil
  end
  for _, t in ipairs(type_list) do
    if t.task_type == task_type then
      return t
    end
  end
  return nil
end

function M:_get_task_types()
  local data = self:get_activity_data()
  if data == nil then
    return nil
  end
  local count = data.TaskTypeCount or 0
  if count == 0 then
    return nil
  end
  local ret = {}
  for index = 0, count - 1 do
    local task_type = data:GetTaskType(index)
    if task_type ~= 0 then
      table.insert(ret, {
        task_type = task_type,
        tab_name = data:GetTaskTypeName(task_type),
        has_red_dot = data:HasTaskTypeRedDot(task_type)
      })
    end
  end
  return ret
end

function M:_refresh_mission_list()
  if is_null(self._layout_mission_list_binder) then
    return
  end
  local missions = self:_get_missions(self._current_task_type) or {}
  for i = 1, #missions do
    local m = missions[i]
    local extra = {
      task_id = m.task_id,
      task_desc = m.task_desc,
      reward_item_id = m.reward_item_id,
      reward_count = m.reward_count,
      state = m.state,
      can_claim = m.can_claim,
      jump_id = m.jump_id,
      unlock_desc = m.unlock_desc,
      current_progress = m.current_progress,
      target_progress = m.target_progress,
      on_click = function(tid)
        self:on_mission_clicked(tid)
      end
    }
    local cls = self._mission_items[i]
    if cls == nil then
      local obj = self._layout_mission_list_binder:AddItem(0)
      if not_null(obj) then
        cls = self:add_panel(MISSION_ITEM_CLS, obj, extra)
        self._mission_items[i] = cls
        UIUtil.set_active(obj, true)
      end
    else
      cls:set_extra_data(extra)
      cls:force_refresh()
      cls:set_active(true)
    end
  end
  for i = #missions + 1, #self._mission_items do
    local cls = self._mission_items[i]
    if cls ~= nil then
      cls:set_active(false)
    end
  end
end

function M:on_mission_clicked(task_id)
  local mission = self:_find_mission(task_id)
  if mission == nil then
    return
  end
  if mission.can_claim then
    self:_request_claim(task_id)
  elseif mission.jump_id and mission.jump_id ~= 0 then
    self:_request_jump(mission.jump_id)
  end
end

function M:_request_claim(task_id)
  local data = self:get_activity_data()
  if data == nil or data:IsClaiming() then
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

function M:_find_mission(task_id)
  local missions = self:_get_missions(self._current_task_type)
  if missions == nil then
    return nil
  end
  for _, m in ipairs(missions) do
    if m.task_id == task_id then
      return m
    end
  end
  return nil
end

function M:_get_missions(task_type)
  local data = self:get_activity_data()
  if data == nil or task_type == nil or task_type == 0 then
    return nil
  end
  local count = data:GetTaskCount(task_type)
  if count == 0 then
    return nil
  end
  local ret = {}
  for index = 0, count - 1 do
    local task = data:GetTask(task_type, index)
    if task ~= nil then
      local has_reward = 0 < task.RewardCount
      table.insert(ret, {
        task_id = task.TaskId,
        task_desc = task.TaskDesc,
        reward_item_id = has_reward and task:GetRewardItemId(0) or 0,
        reward_count = has_reward and task:GetRewardItemCount(0) or 0,
        state = task.State,
        can_claim = task.CanClaim,
        jump_id = task.JumpId,
        unlock_desc = task.UnlockDesc,
        current_progress = task.CurrentProgress,
        target_progress = task.TargetProgress
      })
    end
  end
  return ret
end

function M:_refresh_unlock_text()
  if is_null(self._text_time2refresh) then
    return
  end
  local data = self:get_activity_data()
  if data == nil then
    UIUtil.set_active(self._text_time2refresh, false)
    return
  end
  local state = data.State
  if state == activity_center_module.activity_state.Opened then
    UIUtil.set_active(self._text_time2refresh, true)
    UIUtil.set_text(self._text_time2refresh, self:_get_unlock_tips_text())
  else
    UIUtil.set_active(self._text_time2refresh, false)
  end
end

function M:_get_unlock_tips_text()
  return ""
end

return M
