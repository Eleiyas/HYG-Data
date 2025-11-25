tutorial_module = tutorial_module or {}

function tutorial_module:gen_all_tutorial()
  local tutorial_table = LocalDataUtil.get_dic_table(typeof(CS.BTutorialHandbookCfg))
  for module_id, cfgs in pairs(dic_to_table(tutorial_table)) do
    local module_items = list_to_table(cfgs)
    for _, item in pairs(module_items) do
      if tutorial_module.all_tutorials[module_id] == nil then
        tutorial_module.all_tutorials[module_id] = {}
      end
      if tutorial_module.all_tutorials[module_id][item.tutorialgroupid] == nil then
        tutorial_module.all_tutorials[module_id][item.tutorialgroupid] = {}
      end
      table.insert(tutorial_module.all_tutorials[module_id][item.tutorialgroupid], item)
    end
  end
end

function tutorial_module:set_tutorial_data()
  local finished_tutorial = CsTutorialModuleUtil.GetAllTutorials()
  tutorial_module:pars_all_finished_tutorial(finished_tutorial)
  local tutorial_table = LocalDataUtil.get_dic_table(typeof(CS.BTutorialHandbookCfg))
  for module_id, cfgs in pairs(dic_to_table(tutorial_table)) do
    if tutorial_module.finished_tutorials[module_id] ~= nil then
      local module_items = list_to_table(cfgs)
      local module_info = {}
      if table.count(module_items) > 0 then
        module_info.modulename = module_items[1].modulename
        module_info.moduleicon = module_items[1].moduleicon
        module_info.moduledesc = module_items[1].moduledesc
        module_info.id = module_id
      end
      tutorial_module.tutorial_modules_info[module_id] = module_info
      local group_id_to_item = {}
      for _, item in pairs(module_items) do
        if tutorial_module.finished_tutorials[module_id][item.tutorialgroupid] ~= nil and item.hardwareplatform == tutorial_module.hardware_id and tutorial_module.finished_tutorials[module_id][item.tutorialgroupid][item.tutorialid] ~= nil then
          if group_id_to_item[item.tutorialgroupid] == nil then
            group_id_to_item[item.tutorialgroupid] = {}
          end
          table.insert(group_id_to_item[item.tutorialgroupid], item)
        end
        tutorial_module.tutorial_content_to_ids[item.tutorialcontent] = {
          [1] = item.moduleid,
          [2] = item.tutorialgroupid,
          [3] = item.tutorialid
        }
      end
      if table.count(group_id_to_item) > 0 then
        tutorial_module.tutorial_items_data[module_id] = group_id_to_item
      end
    end
  end
end

function tutorial_module:set_tutorial_data_with_param(finished_group)
  tutorial_module.finished_tutorials = finished_group
  tutorial_module.tutorial_content_to_ids = {}
  tutorial_module.tutorial_items_data = {}
  tutorial_module.tutorial_modules_info = {}
  local tutorial_table = LocalDataUtil.get_dic_table(typeof(CS.BTutorialHandbookCfg))
  for module_id, cfgs in pairs(dic_to_table(tutorial_table)) do
    if tutorial_module.finished_tutorials[module_id] ~= nil then
      local module_items = list_to_table(cfgs)
      local module_info = {}
      if table.count(module_items) > 0 then
        module_info.modulename = module_items[1].modulename
        module_info.moduleicon = module_items[1].moduleicon
        module_info.moduledesc = module_items[1].moduledesc
        module_info.id = module_id
      end
      tutorial_module.tutorial_modules_info[module_id] = module_info
      local group_id_to_item = {}
      for _, item in pairs(module_items) do
        if tutorial_module.finished_tutorials[module_id] ~= nil and tutorial_module.finished_tutorials[module_id][item.tutorialgroupid] ~= nil then
          table.insert(tutorial_module.finished_tutorials[module_id][item.tutorialgroupid], item.tutorialid)
        end
        if tutorial_module.finished_tutorials[module_id][item.tutorialgroupid] ~= nil and item.hardwareplatform == tutorial_module.hardware_id and tutorial_module.finished_tutorials[module_id][item.tutorialgroupid][item.tutorialid] ~= nil then
          if group_id_to_item[item.tutorialgroupid] == nil then
            group_id_to_item[item.tutorialgroupid] = {}
          end
          table.insert(group_id_to_item[item.tutorialgroupid], item)
        end
        tutorial_module.tutorial_content_to_ids[item.tutorialcontent] = {
          [1] = item.moduleid,
          [2] = item.tutorialgroupid,
          [3] = item.tutorialid
        }
      end
      if table.count(group_id_to_item) > 0 then
        tutorial_module.tutorial_items_data[module_id] = group_id_to_item
      end
    end
  end
end

function tutorial_module:reset_hardware_info(hardware_id)
  tutorial_module.hardware_id = hardware_id
  tutorial_module:set_tutorial_data()
end

function tutorial_module:pars_all_finished_tutorial(finished_tutorials)
  for module_id, group_tutorial in pairs(dic_to_table(finished_tutorials)) do
    local group_to_tutorial = {}
    for group_id, tutorials in pairs(dic_to_table(group_tutorial)) do
      local tutorial_table = {}
      for _, tutorial_id in pairs(list_to_table(tutorials)) do
        tutorial_table[tutorial_id] = tutorial_id
      end
      group_to_tutorial[group_id] = tutorial_table
    end
    if table.count(group_to_tutorial) > 0 then
      tutorial_module.finished_tutorials[module_id] = group_to_tutorial
    end
  end
end

function tutorial_module:_update_graph_ui_dynamic_key()
  self.ui_dynamic_ui_key = {}
  local key_data = CsTutorialManagerUtil.GetCurTutorialDynamicUIKey()
  if key_data then
    local key_tbl = list_to_table(key_data)
    for _, data in ipairs(key_tbl) do
      if data then
        if self.ui_dynamic_ui_key[data.type] == nil then
          self.ui_dynamic_ui_key[data.type] = {}
        end
        table.insert(self.ui_dynamic_ui_key[data.type], data)
      end
    end
  end
end

function tutorial_module:check_tutorial_dynamic_key(type, param)
  if self.ui_dynamic_ui_key and self.ui_dynamic_ui_key[type] then
    for _, data in ipairs(self.ui_dynamic_ui_key[type]) do
      if data.param and data.param == param then
        return data.uiKey
      end
    end
  end
  return nil
end

function tutorial_module:check_tutorial_dynamic_key_2(type, param1, param2)
  if self.ui_dynamic_ui_key and self.ui_dynamic_ui_key[type] then
    for _, data in ipairs(self.ui_dynamic_ui_key[type]) do
      if data.param and data.param == param1 and data.param2 and data.param2 == param2 then
        return data.uiKey
      end
    end
  end
  return nil
end

function tutorial_module:get_packet_tag()
  if self.ui_dynamic_ui_key and self.ui_dynamic_ui_key[GraphDynamicUIKeyType.PacketTag] then
    return self.ui_dynamic_ui_key[GraphDynamicUIKeyType.PacketTag]
  end
  return nil
end

return tutorial_module
