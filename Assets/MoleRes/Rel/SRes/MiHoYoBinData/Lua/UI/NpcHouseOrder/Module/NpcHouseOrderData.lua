npc_house_order_module = npc_house_order_module or {}
npc_house_order_module.score_category = {
  Cozy = "NPC_HOME_SCORE_CATEGORY_COZINESS",
  Style = "NPC_HOME_SCORE_CATEGORY_STYLE",
  Supplementary = "NPC_HOME_SCORE_CATEGORY_SUPPLEMENTARY"
}
npc_house_order_module.score_type = {
  Base = "NPC_HOME_SCORE_TYPE_BASE",
  Multiplier = "NPC_HOME_SCORE_TYPE_MULTIPLIER",
  FineTuning = "NPC_HOME_SCORE_TYPE_FINE_TUNING"
}

function npc_house_order_module:build_npc_order_data(order)
  self.force_enter_npc_house_edit = true
  local quest_cfg = self:get_npc_design_quest_cfg(order.OrderCfgId)
  self.house_order_data = {
    order = order,
    quest_cfg = quest_cfg,
    npc_id = quest_cfg.npcid,
    force_pulled = false,
    npc_guid = 0,
    wait_for_create = false
  }
end

function npc_house_order_module:check_npc_house_order()
  if self.force_enter_npc_house_edit then
    self.force_enter_npc_house_edit = false
    return true
  end
  return false
end

function npc_house_order_module:get_order_list(is_main)
  local orders = list_to_table(CsMiTaiModuleUtil.orders)
  local finished_order_list = {}
  local unfinished_order_list = {}
  for index, order in ipairs(orders) do
    if order then
      if order.ReleaseTimestamp ~= 0 and is_main then
        table.insert(unfinished_order_list, order)
      elseif order.AcceptState and order.AcceptState.AcceptTimestamp ~= 0 then
        table.insert(unfinished_order_list, order)
      elseif order.FinishTimestamp ~= 0 then
        table.insert(finished_order_list, order)
      else
        Logger.LogWarning("住家订单可能存在异常，没有任何订单状态标识")
      end
    end
  end
  return unfinished_order_list, finished_order_list
end

function npc_house_order_module:get_house_order_list()
  local cur_scene_id = level_module:get_cur_scene_id()
  local order_list = {}
  if cur_scene_id then
    local unfinished_order_list, finished_order_list = self:get_order_list(false)
    for index, order in ipairs(finished_order_list) do
      if order then
        local quest_cfg = npc_house_order_module:get_npc_design_quest_cfg(order.OrderCfgId)
        if quest_cfg then
          local npc_home_id = GameSceneUtility.GetNpcHomeSceneId(quest_cfg.npcid)
          if npc_home_id == cur_scene_id and quest_cfg.iscanredesign == 1 then
            table.insert(order_list, order)
          end
        end
      end
    end
    for index, order in ipairs(unfinished_order_list) do
      if order then
        local quest_cfg = npc_house_order_module:get_npc_design_quest_cfg(order.OrderCfgId)
        if quest_cfg then
          local npc_home_id = GameSceneUtility.GetNpcHomeSceneId(quest_cfg.npcid)
          if npc_home_id == cur_scene_id then
            table.insert(order_list, order)
          end
        end
      end
    end
  end
  return order_list
end

function npc_house_order_module:get_npc_design_quest_cfg(config_id)
  return LocalDataUtil.get_value(typeof(CS.BNpcDesignQuestCfg), config_id)
end

function npc_house_order_module:_get_order_pass_rubric(group_id)
  if not self.all_order_pass_rubric_data then
    self.all_order_pass_rubric_data = {}
  end
  if not self.all_order_pass_rubric_data[group_id] then
    local rubric_data = LocalDataUtil.get_value(typeof(CS.BNpcDesignPassRubricCfg), group_id)
    if rubric_data then
      local rubric_data_tb = list_to_table(rubric_data)
      table.sort(rubric_data_tb, function(a, b)
        return a.star < b.star
      end)
      self.all_order_pass_rubric_data[group_id] = list_to_table(rubric_data)
    end
  end
  return self.all_order_pass_rubric_data[group_id]
end

function npc_house_order_module:get_order_score_level(group_id)
  if not group_id then
    return nil
  end
  local score_level = {}
  local level_desc = {}
  local rubric_list = self:_get_order_pass_rubric(group_id)
  if not rubric_list then
    return nil
  end
  for i = 1, #rubric_list do
    table.insert(score_level, rubric_list[i].point)
    table.insert(level_desc, rubric_list[i].content)
  end
  return score_level, level_desc
end

function npc_house_order_module:get_star_count_by_score(group_id, score)
  if not group_id or not score then
    return 0
  end
  local list = self:_get_order_pass_rubric(group_id)
  for i = #list, 1, -1 do
    if score >= list[i].point then
      return list[i].star
    end
  end
  return 0
end

function npc_house_order_module:get_total_star_count(order_id)
  if not order_id then
    return 0
  end
  local rubric_list = self:_get_order_pass_rubric(order_id)
  if not rubric_list then
    return 0
  end
  local max_stars = 0
  for _, rubric in ipairs(rubric_list) do
    if max_stars < rubric.star then
      max_stars = rubric.star
    end
  end
  return max_stars
end

function npc_house_order_module:check_pass_by_score(group_id, score)
  if not group_id or not score then
    return false
  end
  local list = self:_get_order_pass_rubric(group_id)
  for i = #list, 1, -1 do
    if score >= list[i].point then
      return list[i].ifpass == 1
    end
  end
  return false
end

function npc_house_order_module:get_comment_by_score(group_id, score)
  if not group_id or not score then
    return ""
  end
  local list = self:_get_order_pass_rubric(group_id)
  for i = #list, 1, -1 do
    if score >= list[i].point then
      return list[i].comment
    end
  end
  return ""
end

function npc_house_order_module:get_reward_list(group_id)
  if not group_id then
    return 0
  end
  local list = self:_get_order_pass_rubric(group_id)
  local reward_list = {}
  for i = #list, 1, -1 do
    if list[i].reward ~= 0 then
      table.insert(reward_list, list[i])
    end
  end
  return reward_list
end

function npc_house_order_module:get_pass_type(group_id)
  if not group_id then
    return 0
  end
  local list = self:_get_order_pass_rubric(group_id)
  if list and 0 < #list then
    return list[1].passtype
  end
  return 1
end

function npc_house_order_module:get_cur_submit_furns(order_data)
  local furn_list = order_data.LastFinishFurnitureList
  return list_to_table(furn_list)
end

function npc_house_order_module:init_house_order_req_cfg()
  self.order_design_req_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BNpcDesignReqCfg))
  for k, v in pairs(cfgs) do
    local id = tonumber(k)
    local sub_data = {}
    for _, vv in ipairs(list_to_table(v)) do
      table.insert(sub_data, vv.Value)
    end
    table.sort(sub_data, function(a, b)
      return a.index < b.index
    end)
    self.order_design_req_cfgs[id] = sub_data
  end
end

function npc_house_order_module:get_house_order_req_list(order_id)
  if not self.order_design_req_cfgs then
    self:init_house_order_req_cfg()
  end
  return self.order_design_req_cfgs[order_id]
end

function npc_house_order_module:init_house_order_style_cfg()
  self.order_design_style_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BNpcDesignPrefCfg))
  for k, v in pairs(cfgs) do
    local id = tonumber(k)
    local sub_data = {}
    for _, vv in ipairs(list_to_table(v)) do
      if vv.Value.weight ~= 0 then
        table.insert(sub_data, vv.Value)
      end
    end
    table.sort(sub_data, function(a, b)
      return a.index < b.index
    end)
    self.order_design_style_cfgs[id] = sub_data
  end
end

function npc_house_order_module:get_house_order_style_list(order_id)
  if not self.order_design_style_cfgs then
    self:init_house_order_style_cfg()
  end
  return self.order_design_style_cfgs[order_id]
end

function npc_house_order_module:init_house_order_score_criteria_cfg()
  self.order_score_criteria_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BNpcFurScoreCriteriaCfg))
  for id, cfg in pairs(cfgs) do
    for _, quest_id in ipairs(list_to_table(cfg.apply_quest_id_list)) do
      if not self.order_score_criteria_cfgs[quest_id] then
        self.order_score_criteria_cfgs[quest_id] = {}
      end
      if not self.order_score_criteria_cfgs[quest_id][cfg.score_category] then
        self.order_score_criteria_cfgs[quest_id][cfg.score_category] = {}
      end
      table.insert(self.order_score_criteria_cfgs[quest_id][cfg.score_category], cfg)
    end
  end
end

function npc_house_order_module:get_house_order_score_criteria_list(order_id, category)
  if not self.order_score_criteria_cfgs then
    self:init_house_order_score_criteria_cfg()
  end
  return self.order_score_criteria_cfgs[order_id] and self.order_score_criteria_cfgs[order_id][category] or {}
end

function npc_house_order_module:check_order_condition(order, furniture_list, use_cache)
  use_cache = use_cache or false
  if use_cache and self._cached_condition_satisfaction and self._cached_order_id == order.OrderCfgId then
    Logger.Log("Using cached order condition check result.")
    local overall_satisfied = true
    local all_best_choices_satisfied = true
    for _, detail in ipairs(self._cached_condition_satisfaction) do
      if (detail.missing_essentials or detail.missing_count) and detail.req_cfg and (detail.req_cfg.ordertype == 1 or detail.req_cfg.ordertype == 2) then
        overall_satisfied = false
      end
      if detail.req_cfg and detail.req_cfg.ordertype == 2 and detail.req_cfg.number > 0 and not detail.best_choice_satisfied then
        all_best_choices_satisfied = false
      end
    end
    return overall_satisfied, self._cached_condition_satisfaction, all_best_choices_satisfied
  end
  if not order then
    return false, {}, false
  end
  local cs_result
  if furniture_list then
    cs_result = CsMiTaiModuleUtil.CheckOrderConditionWithFurnitureEntities(order, furniture_list)
  else
    cs_result = CsMiTaiModuleUtil.CheckOrderCondition(order)
  end
  if not cs_result then
    return false, {}, false
  end
  local lua_condition_satisfaction = {}
  if cs_result.ConditionSatisfactionDetails then
    for i = 0, cs_result.ConditionSatisfactionDetails.Count - 1 do
      local detail = cs_result.ConditionSatisfactionDetails[i]
      if detail then
        table.insert(lua_condition_satisfaction, {
          req_cfg = detail.ReqCfg,
          satisfied_count = detail.SatisfiedCount,
          max_count = detail.MaxCount,
          missing_essentials = detail.MissingEssentials,
          missing_count = detail.MissingCount,
          best_choice_satisfied = detail.BestChoiceSatisfied,
          satisfied_furniture_id = detail.SatisfiedFurnitureId
        })
      end
    end
  end
  self._cached_condition_satisfaction = lua_condition_satisfaction
  self._cached_order_id = order.OrderCfgId
  return cs_result.OverallSatisfied, lua_condition_satisfaction, cs_result.AllBestChoicesSatisfied
end

function npc_house_order_module:get_cached_req_satisfaction(req_index)
  if not self._cached_condition_satisfaction then
    return nil
  end
  return self._cached_condition_satisfaction[req_index]
end

function npc_house_order_module:_check_one_order_condition(condition, furniture_list)
  if not furniture_list or not condition then
    return false, false, 0, false, 0
  end
  local cs_single_result = CsMiTaiModuleUtil.CheckOneOrderCondition(condition, furniture_list)
  if not cs_single_result then
    return false, false, 0, false, 0
  end
  return cs_single_result.MissingEssentials, cs_single_result.MissingCount, cs_single_result.SatisfiedCount, cs_single_result.BestChoiceSatisfied, cs_single_result.SatisfiedFurnitureId
end

function npc_house_order_module:_does_item_match_requirement(req_cfg, item_cfg_id)
  return CsMiTaiModuleUtil.DoesItemMatchRequirement(req_cfg, item_cfg_id)
end

function npc_house_order_module:get_furniture_max_count()
  if self.max_furniture_count then
    return self.max_furniture_count
  end
  self.max_furniture_count = 0
  local cfgs = LocalDataUtil.get_table(typeof(CS.BNpcDesignScoreCriteriaCfg))
  for k, v in pairs(cfgs) do
    if v and v.gradeindex == "NPC_HOME_SCORE_CRITERIA_QUANTITY" then
      self.max_furniture_count = v.thresh
    end
  end
  return self.max_furniture_count
end

function npc_house_order_module:get_furniture_score(order_data, furniture_list)
  local score = 0
  local req_list = self:get_house_order_req_list(order_data.OrderCfgId)
  if not req_list then
    return 0
  end
end

function npc_house_order_module:get_order_puzzle_furniture_cfg()
  local index = self:_get_order_puzzle_furniture()
  if index then
    local cur_order = CsMiTaiModuleUtil.curOrder
    local req_list = self:get_house_order_req_list(cur_order.OrderCfgId)
    if req_list then
      for i, cfg in ipairs(req_list) do
        if cfg and cfg.index == index then
          return cfg
        end
      end
    end
  end
  return nil
end

function npc_house_order_module:_get_order_puzzle_furniture()
  if CsMiTaiModuleUtil.HasUnlockedFurniture() then
    local cur_order = CsMiTaiModuleUtil.curOrder
    if cur_order then
    end
  end
  return nil
end

function npc_house_order_module:get_order_house_icon(order_id, is_old)
  local relative_path = GameplayUtility.MiTai.GetNpcHouseOrderScreenshotPath(order_id, is_old or false)
  return CsUIUtil.LoadFileImage(relative_path)
end

function npc_house_order_module:is_order_state_unreleased(order)
  return order.ReleaseTimestamp ~= 0 and (not order.AcceptState or order.AcceptState.AcceptTimestamp == 0)
end

function npc_house_order_module:is_order_state_accepted(order)
  return order.AcceptState and order.AcceptState.AcceptTimestamp ~= 0 and order.FinishTimestamp == 0
end

function npc_house_order_module:is_order_state_finished(order)
  return order.FinishTimestamp ~= 0
end

function npc_house_order_module:get_order_state(order)
  if self:is_order_state_finished(order) then
    return 2
  elseif self:is_order_state_accepted(order) then
    return 1
  elseif self:is_order_state_unreleased(order) then
    return 0
  end
  return -1
end

function npc_house_order_module:is_order_read(order_id)
  return red_point_module:is_recorded_with_id(red_point_module.red_point_type.npc_house_unread_order, order_id)
end

function npc_house_order_module:mark_order_as_read(order_id)
  red_point_module:record_with_id(red_point_module.red_point_type.npc_house_unread_order, order_id)
end

function npc_house_order_module:has_unread_orders()
  local orders = list_to_table(CsMiTaiModuleUtil.orders)
  for _, order in ipairs(orders) do
    local quest_cfg = self:get_npc_design_quest_cfg(order.OrderCfgId)
    if quest_cfg and not self:is_order_read(order.OrderCfgId) then
      return true
    end
  end
  return false
end

function npc_house_order_module:get_current_best_furniture()
  local cur_order = CsMiTaiModuleUtil.curOrder
  if not cur_order then
    return {}
  end
  local req_list = self:get_house_order_req_list(cur_order.OrderCfgId)
  if not req_list then
    return {}
  end
  local best_furniture = {}
  for _, req_cfg in ipairs(req_list) do
    if req_cfg and req_cfg.requiretype == 2 then
      local furniture_id = tonumber(req_cfg.paramstr)
      if furniture_id then
        table.insert(best_furniture, {
          id = furniture_id,
          count = req_cfg.number,
          index = req_cfg.index
        })
      end
    end
  end
  return best_furniture
end

function npc_house_order_module:get_furniture_cfg(furniture_id)
  if not furniture_id then
    return nil
  end
  local furniture_cfg = LocalDataUtil.get_value(typeof(CS.BItemCfg), furniture_id)
  if not furniture_cfg then
    Logger.LogWarning(string.format("找不到家具配置，ID: %d", furniture_id))
    return nil
  end
  return furniture_cfg
end

function npc_house_order_module:get_score_cap_cfg(quest_id)
  local cfgs = LocalDataUtil.get_table(typeof(CS.BNpcScoreComponentCapCfg))
  local quest_cfgs = {}
  if cfgs then
    for _, cfg in pairs(cfgs) do
      if cfg.quest_id == quest_id then
        table.insert(quest_cfgs, cfg)
      end
    end
  end
  return quest_cfgs
end

function npc_house_order_module:get_best_furniture_cap(quest_id)
  local req_cfg = LocalDataUtil.get_value(typeof(CS.BNpcDesignReqCfg), quest_id)
  local cap = 0
  if req_cfg then
    local req_cfg_tb = dic_to_list_table(req_cfg)
    for _, cfg in ipairs(req_cfg_tb) do
      cap = cap + cfg.bonus_per_furniture
    end
  end
  return cap
end

return npc_house_order_module
