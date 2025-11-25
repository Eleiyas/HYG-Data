chat_module = chat_module or {}

function chat_module:_init_cfg()
  self._all_private_def_txt_cfg = nil
  self._tbl_def_chat_txt_cfg = nil
  self._def_chat_txt_cfg_group = nil
  self._def_emoji_group = nil
  self._tbl_def_emoji_cfg = nil
end

function chat_module:get_def_chat_cfg_by_id(cfg_id)
  if self._tbl_def_chat_txt_cfg == nil then
    chat_module:_load_dif_chat_txt_cfg()
  end
  return self._tbl_def_chat_txt_cfg[cfg_id] or {}
end

function chat_module:get_def_chat_by_world_type(world_type)
  if world_type <= 0 then
    return {}
  end
  if self._def_chat_txt_cfg_group == nil then
    self:_load_dif_chat_txt_cfg()
  end
  local ret_cfgs = {}
  local is_multi_scene = level_module:is_multi_scene()
  if self._def_chat_txt_cfg_group[world_type] ~= nil then
    local is_add = true
    local cfg
    for _, id in ipairs(self._def_chat_txt_cfg_group[world_type]) do
      cfg = chat_module:get_def_chat_cfg_by_id(id)
      if cfg then
        if cfg.showtype == chat_module.def_chat_txt_show_type.all then
          is_add = true
        elseif cfg.showtype == chat_module.def_chat_txt_show_type.one then
          is_add = not is_multi_scene
        elseif cfg.showtype == chat_module.def_chat_txt_show_type.multi then
          is_add = is_multi_scene
        end
        if is_add then
          table.insert(ret_cfgs, cfg)
        end
      end
    end
  end
  return ret_cfgs
end

function chat_module:_load_dif_chat_txt_cfg()
  self._tbl_def_chat_txt_cfg = {}
  self._def_chat_txt_cfg_group = {}
  self._all_private_def_txt_cfg = {}
  local cfgs = dic_to_table(LocalDataUtil.get_table(typeof(CS.BDefaultShortcutTextCfg)))
  for id, cfg in pairs(cfgs) do
    self._tbl_def_chat_txt_cfg[id] = cfg
    if self._def_chat_txt_cfg_group[cfg.scenetype] == nil then
      self._def_chat_txt_cfg_group[cfg.scenetype] = {}
    end
    if cfg.showtype == chat_module.def_chat_txt_show_type.all or cfg.showtype == chat_module.def_chat_txt_show_type.one then
      table.insert(self._all_private_def_txt_cfg, cfg)
    end
    table.insert(self._def_chat_txt_cfg_group[cfg.scenetype], id)
  end
  table.sort(self._all_private_def_txt_cfg, function(a, b)
    return a.id < b.id
  end)
  for _, v in pairs(self._def_chat_txt_cfg_group) do
    table.sort(v, function(a, b)
      return a < b
    end)
  end
end

function chat_module:get_private_def_txt_cfg()
  if self._all_private_def_txt_cfg == nil then
    self:_load_dif_chat_txt_cfg()
  end
  return self._all_private_def_txt_cfg or {}
end

function chat_module:get_def_emoji_cfg_by_id(cfg_id)
  if self._tbl_def_emoji_cfg == nil then
    chat_module:_load_def_emoji_cfg()
  end
  return self._tbl_def_emoji_cfg[cfg_id] or {}
end

function chat_module:get_all_def_emoji_group()
  if self._def_emoji_group == nil then
    chat_module:_load_def_emoji_cfg()
  end
  return self._def_emoji_group
end

function chat_module:_load_def_emoji_cfg()
  self._tbl_def_emoji_cfg = {}
  self._def_emoji_group = {}
  local cfg_group = dic_to_table(LocalDataUtil.get_table(typeof(CS.BEmoticonsCfg)))
  for group_id, cfgs in pairs(cfg_group) do
    if self._def_emoji_group[group_id] == nil then
      self._def_emoji_group[group_id] = {}
    end
    for _, cfg in pairs(dic_to_list_table(cfgs)) do
      table.insert(self._def_emoji_group[group_id], cfg.id)
      self._tbl_def_emoji_cfg[cfg.id] = cfg
    end
  end
end

return chat_module
