mi_tai_score_module = mi_tai_score_module or {}

function mi_tai_score_module:init_score_level_data()
  self.score_level_data_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BScoreSystemLevelCfg))
  for k, v in pairs(cfgs) do
    local id = tonumber(k)
    if id == 1 then
      for _, vv in ipairs(list_to_table(v)) do
        table.insert(self.score_level_data_cfgs, vv.Value)
      end
    end
  end
  table.sort(self.score_level_data_cfgs, function(a, b)
    return a.level < b.level
  end)
end

function mi_tai_score_module:get_score_level_cfg(score)
  local level_cfgs = self:get_all_score_level_cfg()
  if level_cfgs then
    for i = #level_cfgs, 1, -1 do
      if score >= level_cfgs[i].score then
        return level_cfgs[i]
      end
    end
  end
  return nil
end

function mi_tai_score_module:get_score_next_level_cfg(score)
  local level_cfgs = self:get_all_score_level_cfg()
  if level_cfgs then
    for i = #level_cfgs, 1, -1 do
      if score >= level_cfgs[i].score then
        if level_cfgs[i + 1] then
          return level_cfgs[i + 1]
        else
          return level_cfgs[i]
        end
      end
    end
  end
  return nil
end

function mi_tai_score_module:get_all_score_level_cfg()
  if self.score_level_data_cfgs == nil then
    self:init_score_level_data()
  end
  return self.score_level_data_cfgs
end

function mi_tai_score_module:init_house_score_bubble_data()
  self.house_score_bubble_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BHouseScoreBubbleCfg))
  self.all_weight = 0
  for _, cfg in pairs(cfgs) do
    if cfg and 0 < cfg.weight then
      self.all_weight = self.all_weight + cfg.weight
      self.house_score_bubble_cfgs[self.all_weight] = cfg
    end
  end
end

function mi_tai_score_module:get_random_house_score_bubble_cfg()
  if self.house_score_bubble_cfgs == nil then
    self:init_house_score_bubble_data()
  end
  math.randomseed(os.time())
  local n = 10
  local randomNumber = math.random(0, self.all_weight)
  for all_wight, cfg in pairs(self.house_score_bubble_cfgs) do
    if all_wight >= randomNumber then
      return cfg
    end
  end
  return nil
end

function mi_tai_score_module:_load_mitai_evaluate_step_cfg()
  self._step_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BMiTaiEvaluateStepCfg))
  for k, v in pairs(cfgs) do
    local id = tonumber(k)
    local sub_data = {}
    for _, vv in ipairs(list_to_table(v)) do
      table.insert(sub_data, vv.Value)
    end
    table.sort(sub_data, function(a, b)
      return a.step < b.step
    end)
    self._step_cfgs[id] = sub_data
  end
end

function mi_tai_score_module:get_step_cfg(group_id)
  if self._step_cfgs == nil then
    self:_load_mitai_evaluate_step_cfg()
  end
  return self._step_cfgs[group_id]
end

function mi_tai_score_module:check_score_level_unlock_status(level)
  return red_point_module:is_recorded_with_id(red_point_module.red_point_type.mitai_score_level_unlock, level) == false
end

function mi_tai_score_module:record_score_level_unlock_status(level)
  red_point_module:record_with_id(red_point_module.red_point_type.mitai_score_level_unlock, level)
end

function mi_tai_score_module:build_evaluate_data(last_score, last_max_score, new_score, new_max_score)
  local last_level = self:_get_level(last_max_score)
  local new_level = self:_get_level(new_max_score)
  local reward_list = self:_get_reward_list(last_max_score, new_max_score)
  self.evaluate_data = {
    last_score = last_score,
    last_max_score = last_max_score,
    new_score = new_score,
    new_max_score = new_max_score,
    reward_list = reward_list,
    last_level = last_level,
    new_level = new_level
  }
  if self.evaluate_data.new_level > self.evaluate_data.last_level then
    CsMiTaiModuleUtil.evaluateBranchCache = 0
  elseif self.evaluate_data.new_max_score > self.evaluate_data.last_max_score then
    CsMiTaiModuleUtil.evaluateBranchCache = 2
  else
    CsMiTaiModuleUtil.evaluateBranchCache = 1
  end
end

function mi_tai_score_module:check_show_score_result()
  if self.need_show_score_result then
    self.need_show_score_result = false
    return true
  end
  return false
end

function mi_tai_score_module:_get_reward_list(last_score, cur_score)
  local reward_list = {}
  if last_score < cur_score then
    local level_cfgs = self:get_all_score_level_cfg()
    if level_cfgs then
      for i, cfg in ipairs(level_cfgs) do
        if last_score < cfg.score and cur_score >= cfg.score and cfg.houseserverid and cfg.houseserverid ~= "" then
          table.insert(reward_list, cfg)
        end
      end
    end
  end
  return reward_list
end

function mi_tai_score_module:_get_level(score)
  local level_cfg = self:get_score_level_cfg(score)
  if level_cfg then
    return level_cfg.level
  end
  return 0
end

return mi_tai_score_module
