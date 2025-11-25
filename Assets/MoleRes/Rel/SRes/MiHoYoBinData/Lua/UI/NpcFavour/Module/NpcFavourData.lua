npc_favour_module = npc_favour_module or {}

function npc_favour_module:_load_favour_level_cfgs()
  self._favour_level_cfgs = {}
  self._favour_all_exp = {}
  self._favor_max_lv = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BFavorLevelCfg))
  for k, v in pairs(cfgs) do
    local id = tonumber(k)
    local sub_data = {}
    local max_lv = 0
    for _, vv in ipairs(list_to_table(v)) do
      table.insert(sub_data, vv.Value)
      max_lv = math.max(max_lv, vv.Value.favorlevel)
    end
    table.sort(sub_data, function(a, b)
      return a.favorlevel < b.favorlevel
    end)
    local all_exp = 0
    for _, cfg in ipairs(sub_data) do
      if cfg and cfg.favorlevel ~= max_lv then
        all_exp = all_exp + cfg.favorupexp
      end
    end
    self._favour_all_exp[id] = all_exp
    self._favor_max_lv[id] = max_lv
    self._favour_level_cfgs[id] = sub_data
  end
end

function npc_favour_module:get_npc_favour_level_cfg(level, npc_id)
  if not self._favour_level_cfgs then
    self:_load_favour_level_cfgs()
  end
  local favor_type = 1
  if npc_id then
    local npc_cfg = npc_module:get_npc_cfg(npc_id)
    if npc_cfg then
      favor_type = npc_cfg.favortype
    end
  end
  return self._favour_level_cfgs[favor_type][level]
end

function npc_favour_module:get_npc_all_favor_exp(npc_id)
  if not self._favour_all_exp then
    self:_load_favour_level_cfgs()
  end
  local favor_type = 1
  if npc_id then
    local npc_cfg = npc_module:get_npc_cfg(npc_id)
    if npc_cfg then
      favor_type = npc_cfg.favortype
    end
  end
  return self._favour_all_exp[favor_type]
end

function npc_favour_module:get_npc_max_lv(npc_id)
  if not self._favor_max_lv then
    self:_load_favour_level_cfgs()
  end
  local favor_type = 1
  if npc_id then
    local npc_cfg = npc_module:get_npc_cfg(npc_id)
    if npc_cfg then
      favor_type = npc_cfg.favortype
    end
  end
  return self._favor_max_lv[favor_type]
end

function npc_favour_module:get_favour_mitai_order_reward_level()
  if not self._favour_level_cfgs then
    self:_load_favour_level_cfgs()
  end
  for _, cfg in ipairs(self._favour_level_cfgs[1]) do
    if cfg.rewardtype == 1 then
      return cfg.favorlevel
    end
  end
  return 999999999
end

function npc_favour_module:get_favour_group_level(group_id)
  if not self._favour_level_cfgs then
    self:_load_favour_level_cfgs()
  end
  local find_cfg
  for _, cfg in ipairs(self._favour_level_cfgs[1]) do
    if cfg.favorlevelrange == group_id and (find_cfg == nil or string.is_valid(cfg.rewarddesc)) then
      find_cfg = cfg
    end
  end
  return find_cfg
end

function npc_favour_module:get_favour_group_level_all_cfg(group_id)
  if not self._favour_level_cfgs then
    self:_load_favour_level_cfgs()
  end
  local find_cfgs = {}
  for _, cfg in ipairs(self._favour_level_cfgs[1]) do
    if cfg.favorlevelrange == group_id then
      table.insert(find_cfgs, cfg)
    end
  end
  return find_cfgs
end

function npc_favour_module:get_favour_type_level_all_cfg(favor_type)
  if not self._favour_level_cfgs then
    self:_load_favour_level_cfgs()
  end
  if self._favour_level_cfgs[favor_type] then
    return self._favour_level_cfgs[favor_type]
  end
  return nil
end

function npc_favour_module:get_favour_progress(npc_id)
  local stage, progress
  local favour_lv = CsNpcGrowthModuleUtil.GetNpcFavourLv(npc_id)
  local cur_favor_level_cfg = npc_favour_module:get_npc_favour_level_cfg(favour_lv, npc_id)
  if cur_favor_level_cfg.favorlevelrange >= 4 then
    stage = cur_favor_level_cfg.favorlevelrange
    progress = 1
  else
    stage = cur_favor_level_cfg.favorlevelrange + 1
    local all_level_cfg = npc_favour_module:get_favour_group_level_all_cfg(cur_favor_level_cfg.favorlevelrange)
    local favour_val = CsNpcGrowthModuleUtil.GetNpcFavour(npc_id)
    local total_favour = 0
    for _, cfg in ipairs(all_level_cfg) do
      if cfg then
        if favour_lv > cfg.favorlevel then
          favour_val = favour_val + cfg.favorupexp
        end
        total_favour = total_favour + cfg.favorupexp
      end
    end
    if total_favour ~= 0 then
      progress = math.min(favour_val / total_favour, 1)
    else
      progress = 1
    end
  end
  return stage, progress
end

function npc_favour_module:_load_favour_level_lock_cfgs()
  self._favour_level_lock_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BNpcFavorLevelLockCfg))
  for k, v in pairs(cfgs) do
    local id = tonumber(k)
    local sub_data = {}
    for _, value in ipairs(list_to_table(v)) do
      if value then
        sub_data[value.favorlevel] = value
      end
    end
    self._favour_level_lock_cfgs[id] = sub_data
  end
end

function npc_favour_module:get_favor_lock_str(npc_id, lv)
  if self._favour_level_lock_cfgs == nil then
    self:_load_favour_level_lock_cfgs()
  end
  local all_npc_cfg = self._favour_level_lock_cfgs[npc_id]
  if all_npc_cfg then
    local cfg = all_npc_cfg[lv]
    if cfg then
      return cfg.conditiondes
    end
  end
  return ""
end

function npc_favour_module:get_favor_head_lock_str(npc_id, lv)
  if self._favour_level_lock_cfgs == nil then
    self:_load_favour_level_lock_cfgs()
  end
  local all_npc_cfg = self._favour_level_lock_cfgs[npc_id]
  if all_npc_cfg then
    local cfg = all_npc_cfg[lv]
    if cfg then
      return cfg.npclockdes
    end
  end
  return ""
end

function npc_favour_module:_load_favour_level_reward__des_cfgs()
  self._favour_level_reward_des_cfgs = {}
  local cfgs = LocalDataUtil.get_table(typeof(CS.BFavorLevelRewardDesCfg))
  if not cfgs then
    return
  end
  for k, v in pairs(cfgs) do
    local id = tonumber(k)
    local sub_data = {}
    for _, value in ipairs(list_to_table(v)) do
      if value then
        sub_data[value.favorlevel] = value
      end
    end
    self._favour_level_reward_des_cfgs[id] = sub_data
  end
end

function npc_favour_module:get_favor_reward_des_cfg(npc_id, lv)
  if self._favour_level_reward_des_cfgs == nil then
    self:_load_favour_level_reward__des_cfgs()
  end
  local all_npc_cfg = self._favour_level_reward_des_cfgs[npc_id]
  if all_npc_cfg then
    local cfg = all_npc_cfg[lv]
    if cfg then
      return cfg
    end
  end
  return ""
end

return npc_favour_module
