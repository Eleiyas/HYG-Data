planet_tree_module = planet_tree_module or {}

function planet_tree_module:get_node_config(node_id)
  local node_cfg = LocalDataUtil.get_value(typeof(CS.BPlanetTreeNodeCfg), node_id)
  if node_cfg == nil then
    Logger.LogError("cant find planet tree node config : " .. tostring(node_id))
  end
  return node_cfg
end

function planet_tree_module:get_planet_tree_cfgs()
  local cfgs = LocalDataUtil.get_table(typeof(CS.BPlanetTreeCfg))
  return cfgs
end

function planet_tree_module:get_plant_tree_cfg_by_level(level)
  local cfg = LocalDataUtil.get_value(typeof(CS.BPlanetTreeCfg), level)
  return cfg
end

function planet_tree_module:get_task_id_by_tag_id(tag_id)
  local tag_cfg = LocalDataUtil.get_value(typeof(CS.TaskTagCfg), tag_id)
  local task_ids = list_to_table(tag_cfg.taskIds)
  return task_ids[1]
end

return planet_tree_module
