riddle_module = riddle_module or {}
riddle_module.stage_reward_state = {
  ongoing = 0,
  can_take = 1,
  taken = 2
}
riddle_module.default_event_id = 1
riddle_module.tracking_id = 14

function riddle_module:is_riddle_related_activity(activity_id)
  return activity_id == activity_center_module:get_tracking_activity_id(self.tracking_id) or activity_id == spring_festival_activity_module:get_main_activity_id()
end

function riddle_module:is_activity_ended()
  if spring_festival_activity_module:is_main_activity_ended() then
    return true
  end
  local activity_id = activity_center_module:get_tracking_activity_id(self.tracking_id)
  if activity_id == 0 then
    return false
  end
  if not activity_center_module:has_activity(activity_id) then
    return true
  end
  return activity_center_module:get_activity_time_phase(activity_id) == activity_center_module.activity_time_phase.ended
end

local function has_activity_info()
  if CsRiddleModuleUtil == nil or CsRiddleModuleUtil.HasActivityInfo == nil then
    return false
  end
  return CsRiddleModuleUtil.HasActivityInfo()
end

function riddle_module:has_activity_info()
  return has_activity_info()
end

function riddle_module:get_stage_reward_list()
  if not has_activity_info() then
    return {}
  end
  local stage_table = list_to_table(CsRiddleModuleUtil.GetStageRewardList()) or {}
  local reward_list = {}
  for _, reward in ipairs(stage_table) do
    reward_list[#reward_list + 1] = {
      stage = tonumber(reward.Stage) or 0,
      need_active = tonumber(reward.NeedActiveValue) or 0,
      reward_pool_id = tonumber(reward.RewardPoolId) or 0,
      can_take = reward.CanTake == true,
      is_taken = reward.IsTaken == true
    }
  end
  table.sort(reward_list, function(a, b)
    return (a.stage or 0) < (b.stage or 0)
  end)
  return reward_list
end

function riddle_module:get_active_value()
  if not has_activity_info() then
    return 0, 0
  end
  return tonumber(CsRiddleModuleUtil.GetActiveValue()) or 0, tonumber(CsRiddleModuleUtil.GetMaxActiveValue()) or 0
end

function riddle_module:get_stage_reward_state(data)
  if data == nil then
    return self.stage_reward_state.ongoing
  end
  if data.is_taken then
    return self.stage_reward_state.taken
  end
  if data.can_take then
    return self.stage_reward_state.can_take
  end
  return self.stage_reward_state.ongoing
end

function riddle_module:get_stage_reward_items(data)
  if data == nil or data.reward_pool_id == nil or data.reward_pool_id <= 0 then
    return {}
  end
  local pool_cfgs = ExcelDataUtil.get_value(typeof(BRandomPoolCfg), data.reward_pool_id)
  if pool_cfgs == nil then
    return {}
  end
  local items = {}
  for _, cfg in ipairs(list_to_table(pool_cfgs)) do
    items[#items + 1] = {
      id = tonumber(cfg.configid) or 0,
      num = tonumber(cfg.num) or 0
    }
  end
  return items
end

function riddle_module:get_stage_reward_display_item(data)
  local items = self:get_stage_reward_items(data)
  if #items == 0 then
    return 0, 0
  end
  return items[1].id, items[1].num
end

function riddle_module:get_claimable_stages()
  local stages = {}
  for _, data in ipairs(self:get_stage_reward_list()) do
    if self:get_stage_reward_state(data) == self.stage_reward_state.can_take then
      stages[#stages + 1] = data.stage
    end
  end
  return stages
end

function riddle_module:is_stage_unlocked_by_active_change(before_active, after_active)
  before_active = tonumber(before_active) or 0
  after_active = tonumber(after_active) or 0
  if before_active >= after_active then
    return false
  end
  for _, data in ipairs(self:get_stage_reward_list()) do
    local need_active = data.need_active or 0
    if not data.is_taken and before_active < need_active and after_active >= need_active then
      return true
    end
  end
  return false
end

function riddle_module:merge_reward_items(item_lists)
  local merged = {}
  local index_by_id = {}
  for _, items in ipairs(item_lists or {}) do
    for _, item in ipairs(items or {}) do
      local id = tonumber(item.id) or 0
      if 0 < id then
        local at = index_by_id[id]
        if at == nil then
          merged[#merged + 1] = {
            id = id,
            num = tonumber(item.num) or 0
          }
          index_by_id[id] = #merged
        else
          merged[at].num = merged[at].num + (tonumber(item.num) or 0)
        end
      end
    end
  end
  return merged
end

function riddle_module:find_stage_reward_by_stage(stage)
  if stage == nil then
    return nil
  end
  for _, data in ipairs(self:get_stage_reward_list()) do
    if data.stage == stage then
      return data
    end
  end
  return nil
end

return riddle_module
