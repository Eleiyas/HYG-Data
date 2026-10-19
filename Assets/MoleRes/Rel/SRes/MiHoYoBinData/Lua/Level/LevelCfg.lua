level_module = level_module or {}

function level_module:get_world_cfg_by_id(world_id)
  if world_id == nil or world_id <= 0 then
    return
  end
  if self._world_cfg_tbl == nil then
    self._world_cfg_tbl = {}
  end
  if self._world_cfg_tbl[world_id] == nil then
    self._world_cfg_tbl[world_id] = LocalDataUtil.get_value(typeof(GameSceneCfg), world_id)
  end
  return self._world_cfg_tbl[world_id]
end

function level_module:world_is_star_core(world_id)
  local cfg = level_module:get_world_cfg_by_id(world_id)
  if is_null(cfg) or cfg.type ~= GameSceneType.StarCore then
    return false
  end
  return true
end

function level_module:get_world_display_name(world_id)
  if self._world_online_display_name_tbl == nil then
    self._world_online_display_name_tbl = {}
  end
  if self._world_online_display_name_tbl[world_id] == nil then
    local game_scene_cfg = self:get_world_cfg_by_id(world_id)
    if not game_scene_cfg then
      return ""
    end
    if not game_scene_cfg.onlineDisplayNameCfg or not (game_scene_cfg.onlineDisplayNameCfg > 0) then
      self._world_online_display_name_tbl[world_id] = game_scene_cfg.nameInGame
    else
      local name_cfg = LocalDataUtil.get_value(typeof(OnlineDisplayName), game_scene_cfg.onlineDisplayNameCfg)
      self._world_online_display_name_tbl[world_id] = name_cfg.name
    end
  end
  return self._world_online_display_name_tbl[world_id]
end

function level_module:get_world_name(world_id)
  local game_scene_cfg = self:get_world_cfg_by_id(world_id)
  if not game_scene_cfg then
    return ""
  end
  return game_scene_cfg.name
end

return level_module or {}
