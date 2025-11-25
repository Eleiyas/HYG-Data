codex_module = codex_module or {}
local model_scale_cfg_id = 105

function codex_module:pack_with_params(func, ...)
  assert(self == nil or type(self) == "table")
  assert(func ~= nil and type(func) == "function")
  local outer_args = {
    ...
  }
  return function(...)
    local inner_args = {
      ...
    }
    for _, value in ipairs(inner_args) do
      table.insert(outer_args, value)
    end
    func(self, table.unpack(outer_args))
  end
end

function codex_module:is_codex_unlocked()
  return CsOpenStateModuleUtil.GetStateIsUnlockByInt(OpenStateType.OpenStateBiologyHandbook.value__)
end

function codex_module:get_medal_statics_by_id(id)
  local data = self:get_data_by_id(id)
  if not_null(data) then
    return self:get_medal_statics_by_data(data.ServerData)
  end
  return nil
end

function codex_module:get_medal_statics_by_data(codex_data)
  local statics = {}
  if is_null(codex_data.Topic) then
    return nil
  end
  local medal_list = codex_data.Topic.MedalList
  local accomplished_mandatory_topic_count = self:get_accomplished_topic_count_by_data(codex_data, true)
  local accomplished_not_mandatory_topic_count = self:get_accomplished_topic_count_by_data(codex_data, false)
  for i = 0, medal_list.Count - 1 do
    local medal_info = medal_list[i]
    if medal_info.NeedTopicNum <= accomplished_mandatory_topic_count + accomplished_not_mandatory_topic_count and accomplished_mandatory_topic_count >= medal_info.NeedMandatoryNum then
      statics[medal_info.Level] = 1
    else
      statics[medal_info.Level] = 0
    end
  end
  return statics
end

function codex_module:get_accomplished_topic_count_by_id(id, is_mandatory)
  local data = self:get_data_by_id(id)
  if not_null(data) then
    return self:get_accomplished_topic_count_by_data(data.ServerData, is_mandatory)
  end
  return 0
end

function codex_module:get_accomplished_topic_count_by_data(codex_data, is_mandatory)
  if is_null(codex_data.Topic) then
    return 0
  end
  local count = 0
  local tracker_list = codex_data.Topic.TrackerList
  for i = 0, tracker_list.Count - 1 do
    local track_info = tracker_list[i]
    if track_info.IsMandatory == is_mandatory and self:is_track_satisfied(track_info) then
      count = count + 1
    end
  end
  return count
end

function codex_module:get_topic_count_by_data(codex_data, is_mandatory)
  if is_null(codex_data.Topic) then
    return 0
  end
  local count = 0
  local tracker_list = codex_data.Topic.TrackerList
  for i = 0, tracker_list.Count - 1 do
    local track_info = tracker_list[i]
    if track_info.IsMandatory == is_mandatory then
      count = count + 1
    end
  end
  return count
end

function codex_module:take_topic_reward(id, level, callback)
  if self:is_topic_level_arrived(id, level) then
    CsCodexModuleUtil.TakeTopicAward(id, level, callback)
    return true
  end
  return false
end

function codex_module:take_all_total_score_reward()
end

function codex_module:is_track_satisfied(track_info)
  return track_info.CurrentProgress >= track_info.GoalProgress
end

function codex_module:is_topic_level_arrived(id, level)
  local medal_statics = self:get_medal_statics_by_id(id)
  if medal_statics then
    return medal_statics[level] == 1
  end
  return false
end

function codex_module:get_type_ctrl(type)
  if type == nil then
    return nil
  end
  if self._type_ctrls == nil and not self:_init_type_ctrls() then
    return nil
  end
  return self._type_ctrls[type]
end

function codex_module:get_sub_type_controller(type, sub_type)
  if type == nil or sub_type == nil then
    return nil
  end
  local type_ctrl = self:get_type_ctrl(type)
  if type_ctrl == nil then
    return nil
  end
  return type_ctrl:get_sub_type_ctrl(sub_type)
end

function codex_module:get_types()
  local type_maps = self:get_type_maps()
  local types = {}
  for type, _ in pairs(type_maps) do
    table.insert(types, type)
  end
  return types
end

function codex_module:get_sub_type_unlock_cfgs(sub_type_id)
  local cfgs = LocalDataUtil.get_value(typeof(CS.BCodexFeatureUnlockCfg), sub_type_id)
  return dic_to_table(cfgs)
end

function codex_module:get_total_score_cfg_by_score(score)
  if score < 0 then
    return nil
  end
  local level = 1
  while level <= #self._total_score_cfgs and score >= self._total_score_cfgs[level].needtotalscore do
    level = level + 1
  end
  return self._total_score_cfgs[level - 1]
end

function codex_module:get_total_score_cfg_by_level(level)
  return self._total_score_cfgs[level]
end

function codex_module:get_task_rank_cfgs()
  return self._task_rank_cfgs
end

function codex_module:get_task_rank_cfg_by_medal_level(level, is_highest)
  if is_highest then
    return self._task_rank_cfgs[1]
  end
  return self._task_rank_cfgs[level + 1]
end

function codex_module:get_max_task_rank()
  return #self._task_rank_cfgs
end

function codex_module:group_data_by_type(data_list)
  local data_groups = {}
  for _, data in ipairs(data_list) do
    if data_groups[data.Type] == nil then
      data_groups[data.Type] = {}
    end
    table.insert(data_groups[data.Type], data)
  end
  return data_groups
end

function codex_module:group_data_by_sub_type(data_list)
  local data_groups = {}
  for _, data in ipairs(data_list) do
    if data_groups[data.SubType] == nil then
      data_groups[data.SubType] = {}
    end
    table.insert(data_groups[data.SubType], data)
  end
  return data_groups
end

function codex_module:sort_data_by_sub_type_sequence(data_list)
  local data_groups = self:group_data_by_type(data_list)
  local sorted_data_groups = {}
  for type, data_group in pairs(data_groups) do
    local controller = self._type_ctrls[type]
    if controller then
      local sorted_data_group = controller:sort_data_by_sub_type_sequence(data_group)
      sorted_data_groups[type] = sorted_data_group
    end
  end
  return sorted_data_groups
end

function codex_module:has_reward_items()
  if self:has_total_score_rewards() then
    return true
  end
  if self._type_ctrls == nil and not self:_init_type_ctrls() then
    return false
  end
  for _, ctrl in pairs(self._type_ctrls) do
    if ctrl:has_reward_items() then
      return true
    end
  end
  return false
end

function codex_module:has_total_score_rewards()
  local total_score_cfgs = self:get_total_score_cfgs()
  local total_score_data = CsCodexModuleUtil.CodexTotalScoreData
  local total_score = total_score_data.TotalScore
  local rewarded_ids = list_to_table(total_score_data.RewardedLevelIdList)
  local rewarded_id_table = {}
  for i = 1, #rewarded_ids do
    rewarded_id_table[rewarded_ids[i]] = true
  end
  for level, cfg in ipairs(total_score_cfgs) do
    local is_rewarded = rewarded_id_table[level]
    if 1 < level and total_score >= cfg.needtotalscore and is_rewarded == nil then
      return true
    elseif total_score < cfg.needtotalscore then
      return false
    end
  end
  return false
end

function codex_module:has_reward_items_by_type(type)
  local type_ctrl = self:get_type_ctrl(type)
  if type_ctrl then
    return type_ctrl:has_reward_items()
  end
  return false
end

function codex_module:has_reward_items_by_sub_type(type, sub_type)
  local sub_type_ctrl = self:get_sub_type_controller(type, sub_type)
  if sub_type_ctrl then
    return sub_type_ctrl:has_reward_items()
  end
  return false
end

function codex_module:has_new_items_by_type(type)
  local type_ctrl = self:get_type_ctrl(type)
  if type_ctrl then
    return type_ctrl:has_new_items()
  end
  return false
end

function codex_module:has_new_items_by_sub_type(type, sub_type)
  local sub_type_ctrl = self:get_sub_type_controller(type, sub_type)
  if sub_type_ctrl then
    return sub_type_ctrl:has_new_items()
  end
  return false
end

function codex_module:has_total_score_progressed()
  local total_score_data = CsCodexModuleUtil.CodexTotalScoreData
  return not CsCodexModuleUtil.IsTotalScoreShown and total_score_data.TotalScore > total_score_data.LastShownData.TotalScore
end

function codex_module:get_group_sequence_by_id(id)
  local data = self:get_data_by_id(id)
  local controller = self:get_sub_type_controller(data.Type, data.SubType)
  return controller:get_group_sequence_by_id(id)
end

function codex_module:get_global_sequence_by_id(id)
  local data = self:get_data_by_id(id)
  local controller = self:get_sub_type_controller(data.Type, data.SubType)
  return controller:get_global_sequence_by_id(id)
end

function codex_module:get_model_scale_cfg()
  local cfg = LocalDataUtil.get_value(typeof(CS.BPlayerCfg), model_scale_cfg_id)
  local values = {}
  for match in string.gmatch(cfg.paramstr, "[^" .. "," .. "]+") do
    table.insert(values, tonumber(match))
  end
  return values
end

function codex_module:get_changed_data_list()
  local changed_server_data_list = CsCodexModuleUtil.CodexTotalScoreData.LastShownData.ChangedCodexOriginList
  local changed_data_list = {}
  for i = 0, changed_server_data_list.Count - 1 do
    local changed_server_data = changed_server_data_list[i]
    local data = self:get_data_by_id(changed_server_data.Id)
    if not_null(data) then
      local changed_data = {
        curr_data = data,
        last_server_data = changed_server_data,
        change_type = codex_module.DataChangeType.None,
        add_score_by_type = {},
        total_add_score = 0
      }
      if codex_module:_init_changed_data(changed_data) then
        table.insert(changed_data_list, changed_data)
      end
    end
  end
  return changed_data_list
end

function codex_module:_init_changed_data(data)
  local curr_data = data.curr_data
  local last_server_data = data.last_server_data
  local is_valid = false
  if codex_module:is_package_sub_type(curr_data.SubType) and (is_null(last_server_data.Suite) or last_server_data.Suite.CompleteTime == 0) and 0 < curr_data.ServerData.Suite.CompleteTime and 0 < curr_data.CodexCfg.totalscorepoints then
    data.add_score_by_type[codex_module.DataChangeType.PackageCollected] = {
      [1] = curr_data.CodexCfg.totalscorepoints
    }
    data.total_add_score = data.total_add_score + curr_data.CodexCfg.totalscorepoints
    data.change_type = data.change_type | codex_module.DataChangeType.PackageCollected
    is_valid = true
  end
  if not codex_module:is_package_sub_type(curr_data.SubType) and last_server_data.UnlockTime == 0 and 0 < curr_data.ServerData.UnlockTime and 0 < curr_data.CodexCfg.totalscorepoints then
    data.add_score_by_type[codex_module.DataChangeType.Unlock] = {
      [1] = curr_data.CodexCfg.totalscorepoints
    }
    data.total_add_score = data.total_add_score + curr_data.CodexCfg.totalscorepoints
    data.change_type = data.change_type | codex_module.DataChangeType.Unlock
    is_valid = true
  end
  local sub_type_ctrl = self:get_sub_type_controller(curr_data.Type, curr_data.SubType)
  if is_null(last_server_data.Topic) or sub_type_ctrl and sub_type_ctrl:get_sub_type_level() < 2 then
    return is_valid
  end
  local scores = {}
  local curr_medal_list = last_server_data.Topic.MedalList
  local last_medal_statics = codex_module:get_medal_statics_by_data(last_server_data)
  local curr_medal_statics = codex_module:get_medal_statics_by_data(curr_data.ServerData)
  for i = 1, #last_medal_statics do
    if last_medal_statics[i] == 0 and curr_medal_statics[i] == 1 and curr_medal_list[i - 1].AddTotalScore and 0 < curr_medal_list[i - 1].AddTotalScore then
      table.insert(scores, curr_medal_list[i - 1].AddTotalScore)
      data.total_add_score = data.total_add_score + curr_medal_list[i - 1].AddTotalScore
      data.change_type = data.change_type | codex_module.DataChangeType.Upgrade
      is_valid = true
    else
      table.insert(scores, 0)
    end
  end
  if data.change_type & codex_module.DataChangeType.Upgrade == codex_module.DataChangeType.Upgrade then
    data.add_score_by_type[codex_module.DataChangeType.Upgrade] = scores
  end
  return is_valid
end

return codex_module
