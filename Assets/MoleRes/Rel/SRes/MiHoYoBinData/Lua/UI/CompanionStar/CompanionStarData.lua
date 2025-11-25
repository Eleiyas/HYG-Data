companion_star_module = companion_star_module or {}

function companion_star_module:_load_star_map_cfgs()
  self._star_map_cfgs = {}
  self._star_map_names = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BStarMapCfg))
  for k, v in pairs(cfgs) do
    local id = tonumber(k)
    local sub_data = {}
    for _, vv in ipairs(list_to_table(v)) do
      table.insert(sub_data, vv.Value)
      if not string.is_valid(self._star_map_names[id]) and string.is_valid(vv.Value.npcstarmapname) then
        self._star_map_names[id] = vv.Value.npcstarmapname
      end
    end
    table.sort(sub_data, function(a, b)
      return a.mapnnumbered < b.mapnnumbered
    end)
    self._star_map_cfgs[id] = sub_data
  end
end

function companion_star_module:find_galaxy_star_map_cfg(id)
  if self._star_map_cfgs == nil then
    self:_load_star_map_cfgs()
  end
  return self._star_map_cfgs[id]
end

function companion_star_module:get_galaxy_name(id)
  if self._star_map_names == nil then
    self:_load_star_map_cfgs()
  end
  return self._star_map_names[id]
end

function companion_star_module:find_star_data(id)
  if self._star_map_cfgs == nil then
    self:_load_star_map_cfgs()
  end
  for key, val in pairs(self._star_map_cfgs) do
    if val then
      for i, star_data in ipairs(val) do
        if star_data and star_data.npcid == id then
          return star_data
        end
      end
    end
  end
  return nil
end

function companion_star_module:get_prev_star_data(galaxy_id, cur_star_id, check_growth_unlock)
  local galaxy_data = self:find_galaxy_star_map_cfg(galaxy_id)
  if galaxy_data then
    local unlocked_list = {}
    for i, data in ipairs(galaxy_data) do
      if CsCompanionStarModuleUtil.ExchangedContact(data.npcid) then
        if check_growth_unlock then
          if CsCompanionStarManagerUtil.IsInStarList(data.npcid) then
            table.insert(unlocked_list, data)
          end
        else
          table.insert(unlocked_list, data)
        end
      end
    end
    local unlock_count = #unlocked_list
    if unlock_count == 0 or unlock_count == 1 then
      return nil
    end
    local index = 1
    for i, data in ipairs(unlocked_list) do
      if data.npcstarid == cur_star_id then
        index = i
      end
    end
    index = index - 1
    if index < 1 then
      index = unlock_count
    end
    return unlocked_list[index]
  end
end

function companion_star_module:get_next_star_data(galaxy_id, cur_star_id, check_growth_unlock)
  local galaxy_data = self:find_galaxy_star_map_cfg(galaxy_id)
  if galaxy_data then
    local unlocked_list = {}
    for i, data in ipairs(galaxy_data) do
      if CsCompanionStarModuleUtil.ExchangedContact(data.npcid) then
        if check_growth_unlock then
          if CsCompanionStarManagerUtil.IsInStarList(data.npcid) then
            table.insert(unlocked_list, data)
          end
        else
          table.insert(unlocked_list, data)
        end
      end
    end
    local unlock_count = #unlocked_list
    if unlock_count == 0 or unlock_count == 1 then
      return nil
    end
    local index = 1
    for i, data in ipairs(unlocked_list) do
      if data.npcstarid == cur_star_id then
        index = i
      end
    end
    index = index + 1
    if unlock_count < index then
      index = 1
    end
    return unlocked_list[index]
  end
end

function companion_star_module:refresh_all_unlock_data()
  if self._star_map_cfgs == nil then
    self:_load_star_map_cfgs()
  end
  self.unlocked_npc = {}
  self.galaxy_unlocked_npc = {}
  for _, galaxy_data in ipairs(self._star_map_cfgs) do
    if galaxy_data then
      for i, data in ipairs(galaxy_data) do
        if CsCompanionStarModuleUtil.ExchangedContact(data.npcid) then
          table.insert(self.unlocked_npc, data)
          if self.galaxy_unlocked_npc[data.npcstarmapid] == nil then
            self.galaxy_unlocked_npc[data.npcstarmapid] = {}
          end
          table.insert(self.galaxy_unlocked_npc[data.npcstarmapid], data)
        end
      end
    end
  end
  table.sort(self.unlocked_npc, function(a, b)
    return a.npcid > b.npcid
  end)
  for _, unlocked_npc in ipairs(self.galaxy_unlocked_npc) do
    if 0 < #unlocked_npc then
      table.sort(unlocked_npc, function(a, b)
        return a.npcid > b.npcid
      end)
    end
  end
end

function companion_star_module:get_all_unlock_data()
  return self.unlocked_npc
end

function companion_star_module:get_all_unlock_data_count()
  return #self.unlocked_npc
end

function companion_star_module:get_all_unlock_data_table()
  return self.galaxy_unlocked_npc
end

function companion_star_module:get_all_galaxy_unlock_data(galaxy_id)
  if self.galaxy_unlocked_npc[galaxy_id] then
    return self.galaxy_unlocked_npc[galaxy_id]
  end
  return nil
end

function companion_star_module:get_next_galaxy_unlock_data(galaxy_id)
  if self._star_pool_cfgs == nil then
    self:_load_star_pool_cfg()
  end
  if self._star_pool_cfgs[companion_star_module.galaxy_type.companion_star] == nil then
    return {}
  end
  local galaxy_list = self._star_pool_cfgs[companion_star_module.galaxy_type.companion_star]
  local count = #galaxy_list
  if count == 1 then
    return {}
  end
  local index = -1
  for i, cfg in ipairs(galaxy_list) do
    if cfg.starpoolid == galaxy_id then
      index = i
      break
    end
  end
  for i = index + 1, index + count - 1 do
    local real_index = (i - 1) % count + 1
    local cfg = galaxy_list[real_index]
    local unlock_list = self:get_all_galaxy_unlock_data(cfg.starpoolid)
    if unlock_list and 0 < #unlock_list then
      return unlock_list
    end
  end
  return {}
end

function companion_star_module:get_prev_galaxy_unlock_data(galaxy_id)
  if self._star_pool_cfgs == nil then
    self:_load_star_pool_cfg()
  end
  if self._star_pool_cfgs[companion_star_module.galaxy_type.companion_star] == nil then
    return {}
  end
  local galaxy_list = self._star_pool_cfgs[companion_star_module.galaxy_type.companion_star]
  local count = #galaxy_list
  if count == 1 then
    return {}
  end
  local index = -1
  for i, cfg in ipairs(galaxy_list) do
    if cfg.starpoolid == galaxy_id then
      index = i
      break
    end
  end
  for i = index + count - 1, index + 1, -1 do
    local real_index = (i - 1) % count + 1
    local cfg = galaxy_list[real_index]
    local unlock_list = self:get_all_galaxy_unlock_data(cfg.starpoolid)
    if unlock_list and 0 < #unlock_list then
      return unlock_list
    end
  end
  return {}
end

function companion_star_module:_load_star_pool_cfg()
  self._star_pool_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BStarPoolCfg))
  for _, cfg in pairs(cfgs) do
    local type = cfg.pooltype
    if self._star_pool_cfgs[type] == nil then
      self._star_pool_cfgs[type] = {}
    end
    table.insert(self._star_pool_cfgs[type], cfg)
  end
  for i, val in pairs(self._star_pool_cfgs) do
    table.sort(val, function(a, b)
      return a.mapnnumbered < b.mapnnumbered
    end)
  end
end

function companion_star_module:get_first_galaxy_cfg(galaxy_type)
  if self._star_pool_cfgs == nil then
    self:_load_star_pool_cfg()
  end
  if self._star_pool_cfgs[galaxy_type] == nil then
    return nil
  end
  return self._star_pool_cfgs[galaxy_type][1]
end

function companion_star_module:get_initial_galaxy_cfgs(galaxy_type, galaxy_id, range)
  local cfgs = {}
  for i = -range, range do
    local cfg = self:find_relative_galaxy_cfg(galaxy_type, galaxy_id, i)
    if cfg then
      cfgs[i] = cfg
    end
  end
  return cfgs
end

function companion_star_module:find_galaxy_cfg(galaxy_type, id)
  if self._star_pool_cfgs == nil then
    self:_load_star_pool_cfg()
  end
  if self._star_pool_cfgs[galaxy_type] == nil then
    return nil, nil
  end
  for i, v in ipairs(self._star_pool_cfgs[galaxy_type]) do
    if v.starpoolid == id then
      return v, i
    end
  end
  return nil, nil
end

function companion_star_module:find_relative_galaxy_cfg(galaxy_type, galaxy_id, index)
  local cfg, i = self:find_galaxy_cfg(galaxy_type, galaxy_id)
  local count = #self._star_pool_cfgs[galaxy_type]
  if cfg and i and count ~= 0 then
    local modulo = index % count
    i = i + modulo
    i = count >= i and i or i - count
    return self._star_pool_cfgs[galaxy_type][i], i
  end
  return nil, nil
end

function companion_star_module:find_first_unlock_npc(galaxy_type)
  if self._star_pool_cfgs == nil then
    self:_load_star_pool_cfg()
  end
  if self._star_pool_cfgs[galaxy_type] == nil then
    return nil
  end
  for i, v in ipairs(self._star_pool_cfgs[galaxy_type]) do
    local cfg = self:find_first_unlock_npc_in_galaxy(v.starpoolid)
    if cfg then
      return cfg
    end
  end
  return nil
end

function companion_star_module:find_first_unlock_npc_in_galaxy(galaxy_id)
  local galaxy_data = self:find_galaxy_star_map_cfg(galaxy_id)
  if not galaxy_data then
    return nil
  end
  for i, data in ipairs(galaxy_data) do
    if CsCompanionStarModuleUtil.ExchangedContact(data.npcid) then
      return data
    end
  end
  return nil
end

function companion_star_module:_load_npc_tag_pool_cfg()
  self._npc_tag_pool_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BNpcTagPoolCfg))
  for _, cfg in pairs(cfgs) do
    self._npc_tag_pool_cfgs[cfg.npcid] = cfg
  end
end

function companion_star_module:get_npc_tag(npc_id)
  if self._npc_tag_pool_cfgs == nil then
    self:_load_npc_tag_pool_cfg()
  end
  return self._npc_tag_pool_cfgs[npc_id]
end

function companion_star_module:get_interact_cfg(id)
  return LocalDataUtil.get_value(typeof(CS.BNPCInterestsCfg), id)
end

function companion_star_module:get_star_spec_cfg(id)
  return LocalDataUtil.get_value(typeof(CS.BLucaFeatureCfg), id)
end

function companion_star_module:get_npc_tag_cfg(id)
  return LocalDataUtil.get_value(typeof(CS.BNpcTagCfg), id)
end

function companion_star_module:_load_npc_tag_label_cfg()
  self._npc_tag_label_cfgs = {}
  local all_npc_label_cfgs = dic_to_table(LocalDataUtil.get_dic_table(typeof(CS.BNpcLabelCfg)))
  for npc_id, list in pairs(all_npc_label_cfgs) do
    self._npc_tag_label_cfgs[npc_id] = {
      favor_list = {},
      like_list = {},
      hate_lsit = {},
      ability_list = {}
    }
    local n = list.Count
    for i = 0, n - 1 do
      local cfg = list[i]
      if cfg.labelemotion == 1 then
        table.insert(self._npc_tag_label_cfgs[npc_id].like_list, cfg)
      elseif cfg.labelemotion == 2 then
        table.insert(self._npc_tag_label_cfgs[npc_id].favor_list, cfg)
      elseif cfg.labelemotion == 4 then
        table.insert(self._npc_tag_label_cfgs[npc_id].hate_lsit, cfg)
      elseif cfg.labelemotion == 100 then
        table.insert(self._npc_tag_label_cfgs[npc_id].ability_list, cfg)
      end
    end
  end
end

function companion_star_module:get_like_tag_list(npc_id)
  if self._npc_tag_label_cfgs == nil then
    self:_load_npc_tag_label_cfg()
  end
  if self._npc_tag_label_cfgs[npc_id] then
    return self._npc_tag_label_cfgs[npc_id].like_list
  end
end

function companion_star_module:get_favor_tag_list(npc_id)
  if self._npc_tag_label_cfgs == nil then
    self:_load_npc_tag_label_cfg()
  end
  if self._npc_tag_label_cfgs[npc_id] then
    return self._npc_tag_label_cfgs[npc_id].favor_list
  end
end

function companion_star_module:get_hate_tag_list(npc_id)
  if self._npc_tag_label_cfgs == nil then
    self:_load_npc_tag_label_cfg()
  end
  if self._npc_tag_label_cfgs[npc_id] then
    return self._npc_tag_label_cfgs[npc_id].hate_lsit
  end
end

function companion_star_module:get_ability_tag_list(npc_id)
  if self._npc_tag_label_cfgs == nil then
    self:_load_npc_tag_label_cfg()
  end
  if self._npc_tag_label_cfgs[npc_id] then
    return self._npc_tag_label_cfgs[npc_id].ability_list
  end
end

function companion_star_module:check_npc_new_red_point(npc_id)
  if not npc_id or npc_id == 0 then
    return false
  end
  return red_point_module:is_recorded_with_id(red_point_module.red_point_type.companion_star_new_npc, npc_id) == false
end

function companion_star_module:record_npc_new_red_point(npc_id)
  if not npc_id or npc_id == 0 then
    return
  end
  red_point_module:record_with_id(red_point_module.red_point_type.companion_star_new_npc, npc_id)
end

function companion_star_module:check_npc_growth_new_red_point(npc_id)
  if not npc_id or npc_id == 0 or not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateAddArchpor) then
    return false
  end
  return red_point_module:is_recorded_with_id(red_point_module.red_point_type.companion_star_growth_unlock_npc, npc_id) == false and CsCompanionStarManagerUtil.IsInStarList(npc_id)
end

function companion_star_module:record_npc_growth_new_red_point(npc_id)
  if not npc_id or npc_id == 0 then
    return
  end
  red_point_module:record_with_id(red_point_module.red_point_type.companion_star_growth_unlock_npc, npc_id)
end

function companion_star_module:check_npc_new_condition_red_point(npc_id)
  if not npc_id or npc_id == 0 then
    return false
  end
  local conditions = CsCompanionStarModuleUtil.GetAllConditions(npc_id)
  local has_condition = not_null(conditions) and 0 < conditions.Count
  return has_condition and red_point_module:is_recorded_with_id(red_point_module.red_point_type.companion_star_new_npc_condition, npc_id) == false
end

function companion_star_module:record_npc_new_condition_red_point(npc_id)
  if not npc_id or npc_id == 0 then
    return
  end
  local conditions = CsCompanionStarModuleUtil.GetAllConditions(npc_id)
  local has_condition = not_null(conditions) and 0 < conditions.Count
  if has_condition then
    red_point_module:record_with_id(red_point_module.red_point_type.companion_star_new_npc_condition, npc_id)
  end
end

function companion_star_module:check_npc_condition_need_settle_red_point(npc_id)
  if not npc_id or npc_id == 0 then
    return false
  end
  local conditions = CsCompanionStarModuleUtil.GetAllConditions(npc_id)
  for i = 0, conditions.Count - 1 do
    local condition = conditions[i].condition
    if condition then
      local is_settle = condition.IsSettle
      local is_complete = condition.TriggerCount >= condition.GoalCount
      if not is_settle and is_complete then
        return true
      end
    end
  end
  return false
end

function companion_star_module:check_npc_add_star_red_point(npc_id)
  if not npc_id or npc_id == 0 then
    return false
  end
  local is_in_scene = CsCompanionStarManagerUtil.IsInStarList(npc_id)
  local favour_lv = CsNpcGrowthModuleUtil.GetNpcFavourLv(npc_id)
  local cur_favor_level_cfg = npc_favour_module:get_npc_favour_level_cfg(favour_lv, npc_id)
  local settled = GameplayUtility.GetNpcInvitationStatus(npc_id) == 4
  return settled and not is_in_scene and cur_favor_level_cfg.favorlevelrange >= 3
end

function companion_star_module:check_npc_story_reward_red_point(npc_id)
  if not npc_id or npc_id == 0 then
    return false
  end
  local all_story = companion_star_module:get_npc_story(npc_id)
  if not all_story then
    return false
  end
  local favour_lv = CsNpcGrowthModuleUtil.GetNpcFavourLv(npc_id)
  for i, story in ipairs(all_story) do
    if favour_lv >= story.favor_lv then
      local is_got_reward = CsNpcGrowthModuleUtil.IsStoryRewardGot(npc_id, story.story_order)
      if not is_got_reward then
        return true
      end
    end
  end
  return false
end

function companion_star_module:check_npc_star_map_red_point(npc_id)
  local star_map_data = CsCompanionStarModuleUtil.GetStarMapGraph(npc_id)
  if star_map_data and star_map_data.nodes and star_map_data.nodes.Count > 0 then
    for i = 0, star_map_data.nodes.Count - 1 do
      local node_data = star_map_data.nodes[i]
      if node_data.configId ~= 0 then
        local is_achieved = CsCompanionStarModuleUtil.IsTrackerComplete(npc_id, node_data.trackId, node_data.goal)
        local is_completed = CsCompanionStarModuleUtil.IsNodeComplete(npc_id, node_data.id)
        if is_achieved and not is_completed then
          return true
        end
      end
    end
  else
    return false
  end
  return false
end

function companion_star_module:check_icon_red_point()
  local star_datas = CsCompanionStarModuleUtil.allStarWishData
  for i = 0, star_datas.Count - 1 do
    local data = star_datas[i]
    if data then
      local npc_id = data.npcid
      if self:find_star_data(npc_id) ~= nil and self:check_npc_red_point(npc_id) then
        return true
      end
    end
  end
  return false
end

function companion_star_module:check_npc_red_point(npc_id)
  if CsCompanionStarModuleUtil.ExchangedContact(npc_id) and (self:check_npc_new_red_point(npc_id) or self:check_npc_growth_new_red_point(npc_id) or self:check_npc_story_reward_red_point(npc_id) or self:check_npc_star_map_red_point(npc_id)) then
    return true
  end
  return false
end

function companion_star_module:init_friend_data()
  if not self.friend_infos then
    self.friend_infos = social_module:get_friend_info_tbl()
    local friend_count = #self.friend_infos
    self.friend_page_count = friend_count / companion_star_module.friend_count_per_page + 1
    if self.friend_page_count < 4 then
      self.friend_page_count = 3
    end
  end
end

function companion_star_module:get_friend_data(page, index)
  if not self.friend_infos then
    self:init_friend_data()
  end
  page = page % self.friend_page_count
  local real_index = page * companion_star_module.friend_count_per_page + index
  return self.friend_infos[real_index]
end

function companion_star_module:get_cur_npc_guid()
  if CsNPCSphereLandManagerUtil.curStar then
    return CsNPCSphereLandManagerUtil.curStar.NPCGuid
  end
  return 0
end

function companion_star_module:_load_favour_level_cfgs()
  self._favour_level_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BFavorLevelCfg))
  for k, v in pairs(cfgs) do
    local id = tonumber(k)
    local sub_data = {}
    for _, vv in ipairs(list_to_table(v)) do
      table.insert(sub_data, vv.Value)
    end
    table.sort(sub_data, function(a, b)
      return a.favorlevel < b.favorlevel
    end)
    self._favour_level_cfgs[id] = sub_data
  end
end

function companion_star_module:_load_npc_growth_level_type_cfg()
  self._npc_growth_level_type_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BNpcGrowthLevelTypeCfg))
  for k, v in pairs(cfgs) do
    local id = tonumber(k)
    local sub_data = {}
    for _, vv in ipairs(list_to_table(v)) do
      table.insert(sub_data, vv.Value)
    end
    table.sort(sub_data, function(a, b)
      return a.level < b.level
    end)
    self._npc_growth_level_type_cfgs[id] = sub_data
  end
end

function companion_star_module:get_npc_growth_level_type_cfg(npc_id, index)
  if not self._npc_growth_level_type_cfgs then
    self:_load_npc_growth_level_type_cfg()
  end
  local growth_level_cfg = LocalDataUtil.get_value(typeof(CS.BNpcGrowthLevelCfg), npc_id)
  if growth_level_cfg and self._npc_growth_level_type_cfgs[growth_level_cfg.leveltypeid] then
    return self._npc_growth_level_type_cfgs[growth_level_cfg.leveltypeid][index]
  end
  return nil
end

function companion_star_module:_load_npc_growth_level_reward_cfg()
  self._npc_growth_level_reward_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BNpcGrowthLevelRewardCfg))
  for k, v in pairs(cfgs) do
    local id = tonumber(k)
    local sub_data = {}
    for _, vv in ipairs(list_to_table(v)) do
      table.insert(sub_data, vv.Value)
    end
    table.sort(sub_data, function(a, b)
      return a.level < b.level
    end)
    self._npc_growth_level_reward_cfgs[id] = sub_data
  end
end

function companion_star_module:get_npc_growth_level_reward_cfg(npc_id, level)
  if not self._npc_growth_level_reward_cfgs then
    self:_load_npc_growth_level_reward_cfg()
  end
  local growth_level_cfg = LocalDataUtil.get_value(typeof(CS.BNpcGrowthLevelCfg), npc_id)
  if growth_level_cfg and self._npc_growth_level_reward_cfgs[growth_level_cfg.rewardgroupid] then
    return self._npc_growth_level_reward_cfgs[growth_level_cfg.rewardgroupid][level]
  end
  return nil
end

function companion_star_module:find_luka_cfg(unlock_item_id)
  local luka_cfg_tbl = LocalDataUtil.get_table(typeof(CS.BLucaHeartCfg))
  for _, cfg in pairs(luka_cfg_tbl) do
    if tonumber(cfg.lucaitem) == unlock_item_id then
      return cfg
    end
  end
  return nil
end

function companion_star_module:is_order_unlock(npc_id)
  local order_cfg = CsMiTaiModuleUtil.GetFirstHouseOrderCfgByNpc(npc_id)
  if order_cfg then
    local house_order = CsMiTaiModuleUtil.GetOrderById(order_cfg.id)
    return house_order and house_order.UnlockOrder and true or false
  end
  return false
end

function companion_star_module:is_order_depositing(npc_id)
  local order_cfg = CsMiTaiModuleUtil.GetFirstHouseOrderCfgByNpc(npc_id)
  if order_cfg then
    local house_order = CsMiTaiModuleUtil.GetOrderById(order_cfg.id)
    return house_order and house_order.DepositingOrder and true or false
  end
  return false
end

function companion_star_module:is_order_constructing(npc_id)
  local order_cfg = CsMiTaiModuleUtil.GetFirstHouseOrderCfgByNpc(npc_id)
  if order_cfg then
    local house_order = CsMiTaiModuleUtil.GetOrderById(order_cfg.id)
    return house_order and house_order.ConstructingOrder and true or false
  end
  return false
end

function companion_star_module:is_order_complete(npc_id)
  local order_cfg = CsMiTaiModuleUtil.GetFirstHouseOrderCfgByNpc(npc_id)
  if order_cfg then
    local house_order = CsMiTaiModuleUtil.GetOrderById(order_cfg.id)
    return house_order and house_order.CompletedOrder and true or false
  end
  return false
end

function companion_star_module:get_order_complete_time(npc_id)
  local order_cfg = CsMiTaiModuleUtil.GetFirstHouseOrderCfgByNpc(npc_id)
  if order_cfg then
    local house_order = CsMiTaiModuleUtil.GetOrderById(order_cfg.id)
    return house_order and house_order.CompletedOrder and house_order.CompletedOrder.CompletionTimestamp or 0
  end
  return 0
end

function companion_star_module:_load_npc_story_cfg()
  self._npc_story_cfgs = {}
  local cfgs = LocalDataUtil.get_dic_table(typeof(CS.BStoryCfg))
  for npc_id, list in pairs(cfgs) do
    self._npc_story_cfgs[npc_id] = {}
    local n = list.Count
    for i = 0, n - 1 do
      local cfg = list[i]
      local story_cfg
      for _, story_table in ipairs(self._npc_story_cfgs[npc_id]) do
        if story_table.story_order == cfg.storyorder then
          story_cfg = story_table
        end
      end
      if story_cfg == nil then
        story_cfg = {
          story_order = cfg.storyorder,
          title = "",
          title_cfg = nil,
          reward_id = 0,
          reward_count = 0,
          favor_lv = 0,
          list = {}
        }
        table.insert(self._npc_story_cfgs[npc_id], story_cfg)
      end
      table.insert(story_cfg.list, cfg)
      if string.is_valid(cfg.storytitle) then
        story_cfg.title_cfg = cfg
      end
      if cfg.id ~= 0 then
        story_cfg.reward_id = cfg.id
      end
      if cfg.num ~= 0 then
        story_cfg.reward_count = cfg.num
      end
      if cfg.favorlevel ~= 0 then
        story_cfg.favor_lv = cfg.favorlevel
      end
    end
    for _, story_list in pairs(self._npc_story_cfgs) do
      table.sort(story_list, function(a, b)
        return a.story_order < b.story_order
      end)
    end
    for _, story_list in pairs(self._npc_story_cfgs) do
      for _, cfg_table in ipairs(story_list) do
        table.sort(cfg_table.list, function(a, b)
          return a.storyindex < b.storyindex
        end)
      end
    end
  end
end

function companion_star_module:get_npc_story(npc_id)
  if self._npc_story_cfgs == nil then
    self:_load_npc_story_cfg()
  end
  return self._npc_story_cfgs[npc_id]
end

function companion_star_module:set_detail_page_data(star_data, mode)
  self._star_detail_data = {mode = mode, star_data = star_data}
end

function companion_star_module:get_detail_page_data()
  return self._star_detail_data
end

return companion_star_module
