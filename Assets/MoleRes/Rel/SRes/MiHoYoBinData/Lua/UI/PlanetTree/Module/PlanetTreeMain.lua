planet_tree_module = planet_tree_module or {}

function planet_tree_module:add_event()
  planet_tree_module:remove_event()
  self._events = {}
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function planet_tree_module:init_node_data()
  self._node_data_list = {}
  self._galaxy_type = CsGameplayUtilitiesGalaxyUtil.GetSelectedGalaxyType().value__
  local cfgs = self:get_planet_tree_cfgs()
  self._max_level = 0
  self._coin_item_ids = {}
  for level, cfg in ipairs(cfgs) do
    local node_ids
    if self._galaxy_type == 1 then
      node_ids = lua_str_split(cfg.nodelistforhexia, ",", true)
    elseif self._galaxy_type == 2 then
      node_ids = lua_str_split(cfg.nodelistfortafa, ",", true)
    end
    local level_nodes = {}
    if node_ids ~= nil then
      local small_node_index = 2
      for _, node_id in ipairs(node_ids) do
        local node_cfg = planet_tree_module:get_node_config(node_id)
        if node_cfg ~= nil then
          local unlock_cfg = lua_str_split(node_cfg.unlockitem, ":", true)
          self._coin_item_ids[unlock_cfg[1]] = true
          local node_data = {
            level = level,
            is_lvup = node_cfg.nodetype == 1,
            node_name = node_cfg.nodename,
            node_reward_num = node_cfg.nodenum,
            preview_title = node_cfg.title,
            preview_desc = node_cfg.desc,
            preview_image = node_cfg.image,
            icon = node_cfg.nodeicon,
            video = node_cfg.video,
            unlock_need_item = unlock_cfg[1],
            unlock_need_num = unlock_cfg[2],
            cut_scene_mark = node_cfg.cutscenemark,
            index = node_cfg.nodetype ~= 1 and small_node_index or 1,
            state = planet_tree_module.node_state.lock,
            task_tag_id = tonumber(node_cfg.unlocktask)
          }
          if node_cfg.nodetype ~= 1 then
            small_node_index = small_node_index + 1
          end
          level_nodes[node_data.index] = node_data
        end
      end
    end
    self._node_data_list[level] = level_nodes
    self._max_level = level
  end
end

function planet_tree_module:get_all_node_data()
  return self._node_data_list
end

function planet_tree_module:get_node_data(level, index)
  local level_nodes = self._node_data_list[level]
  if level_nodes == nil then
    return nil
  end
  return level_nodes[index]
end

function planet_tree_module:set_node_state(level, index, state)
  local level_nodes = self._node_data_list[level]
  if level_nodes == nil or level_nodes[index] == nil then
    return
  end
  level_nodes[index].state = state
end

function planet_tree_module:is_lvup_node(level, index)
  local level_nodes = self._node_data_list[level]
  if level_nodes == nil or level_nodes[index] == nil then
    return false
  end
  return level_nodes[index].is_lvup
end

function planet_tree_module:has_cut_scene(level, index)
  local level_nodes = self._node_data_list[level]
  if level_nodes == nil or level_nodes[index] == nil or level_nodes[index].cut_scene_mark == nil then
    return false
  end
  return level_nodes[index].cut_scene_mark == 1
end

function planet_tree_module:get_all_luca_id()
  return self._coin_item_ids
end

function planet_tree_module:is_task_finish_by_tag_id(tag_id)
  local task_id = planet_tree_module:get_task_id_by_tag_id(tag_id)
  return task_module:task_is_finish(task_id)
end

function planet_tree_module:submit_task(level, index, callback)
  local node_data = self:get_node_data(level, index)
  if node_data == nil or node_data.state ~= self.node_state.unlock then
    return
  end
  if not self:check_task_item(node_data) then
    return
  end
  local item_cfg_id = node_data.unlock_need_item
  local item_guid = item_module:get_guid_by_cfg_id(item_cfg_id)
  local item_task_data = {}
  item_task_data[item_guid] = node_data.unlock_need_num
  local task_id = self:get_task_id_by_tag_id(node_data.task_tag_id)
  CsPlanetTreeUtil.HandleTaskItemReq(item_task_data, task_id, callback)
end

function planet_tree_module:set_delay_submit_task(level, index)
  local node_data = self:get_node_data(level, index)
  if node_data == nil or node_data.state ~= self.node_state.unlock then
    return
  end
  if not self:check_task_item(node_data) then
    return
  end
  local item_cfg_id = node_data.unlock_need_item
  local item_guid = item_module:get_guid_by_cfg_id(item_cfg_id)
  local item_task_data = {}
  item_task_data[item_guid] = node_data.unlock_need_num
  local task_id = self:get_task_id_by_tag_id(node_data.task_tag_id)
  CsPlanetTreeUtil.SetDelaySubmitTaskItems(item_task_data, task_id)
end

function planet_tree_module:check_task_item(node_data)
  local item_cfg_id = node_data.unlock_need_item
  local item_num = item_module:get_item_num_by_cfg_id(item_cfg_id)
  if item_num < node_data.unlock_need_num then
    return false
  end
  return true
end

function planet_tree_module:check_task_item_and_show_tip(level, index)
  local node_data = self:get_node_data(level, index)
  if node_data == nil or node_data.state ~= self.node_state.unlock then
    return false
  end
  if not self:check_task_item(node_data) then
    local item_cfg_id = node_data.unlock_need_item
    local item_cfg = item_module:get_cfg_by_id(item_cfg_id)
    UIUtil.show_tips_by_text_id("PlanetTree_Upgrade_Fail_Tip", item_cfg.name)
    return false
  end
  return true
end

function planet_tree_module:get_max_level()
  return self._max_level
end

function planet_tree_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

return planet_tree_module
