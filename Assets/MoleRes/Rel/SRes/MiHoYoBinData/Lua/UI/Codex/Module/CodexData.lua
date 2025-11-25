codex_module = codex_module or {}
codex_module.default_lock_info = "???"
codex_module.red_point_type_data = red_point_module.red_point_type.codex_data
codex_module.red_point_type_type_tog = red_point_module.red_point_type.codex_type_tog
codex_module.red_point_type_sub_type_tog = red_point_module.red_point_type.codex_sub_type_tog
codex_module.DataChangeType = {
  None = 0,
  Unlock = 1,
  Upgrade = 2,
  PackageCollected = 4
}
local package_sub_type_table = {
  [CodexDataSubType.FurniturePackage] = true,
  [CodexDataSubType.PlantPackage] = true,
  [CodexDataSubType.ClothPackage] = true
}

function codex_module:get_type_by_sub_type(sub_type)
  if self._sub_type_to_type_cache and self._sub_type_to_type_cache[sub_type] then
    return self._sub_type_to_type_cache[sub_type]
  end
  local type_maps = self:get_type_maps()
  for type, sub_types in pairs(type_maps) do
    for i = 1, #sub_types do
      if sub_types[i] == sub_type then
        self._sub_type_to_type_cache[sub_type] = type
        return type
      end
    end
  end
  return nil
end

function codex_module:get_sub_type_cfg(sub_type)
  local type = CsCodexModuleUtil.GetTypeBySubType(sub_type)
  local type_id = type.value__
  local sub_type_id = sub_type.value__
  for _, type_cfg in pairs(self._type_cfgs) do
    for subtype, sub_type_cfg in pairs(type_cfg) do
      if subtype == sub_type_id then
        return sub_type_cfg
      end
    end
  end
  return nil
end

function codex_module:is_furniture_type(type)
  return type == CodexDataType.Furniture
end

function codex_module:is_furniture_sub_type(sub_type)
  local furniture_sub_types = self._type_maps[CodexDataType.Furniture]
  for _, furniture_sub_type in ipairs(furniture_sub_types) do
    if furniture_sub_type == sub_type then
      return true
    end
  end
  return false
end

function codex_module:is_item_sub_type(sub_type)
  local item_sub_types = self._type_maps[CodexDataType.Item]
  for _, item_sub_type in ipairs(item_sub_types) do
    if item_sub_type == sub_type then
      return true
    end
  end
  return false
end

function codex_module:is_package_sub_type(sub_type)
  return package_sub_type_table[sub_type] or false
end

function codex_module:is_new_item(id)
  local data = self:get_data_by_id(id)
  if is_null(data) or not data.IsUnlocked then
    return false
  end
  return not red_point_module:is_recorded_with_id(codex_module.red_point_type_data, id)
end

function codex_module:is_reward_item(id)
  local data = self:get_data_by_id(id)
  if is_null(data) or not data.IsUnlocked then
    return false
  end
  if codex_module:is_package_sub_type(data.SubType) then
    local suite_data = data.ServerData.Suite
    return suite_data.CompleteTime > 0 and not suite_data.IsCompleteRewardTaken
  end
  if not data.HasTopic then
    return false
  end
  local sub_type_ctrl = self:get_sub_type_controller(data.Type, data.SubType)
  if not sub_type_ctrl or sub_type_ctrl:get_sub_type_level() < 2 then
    return false
  end
  local medal_statics = codex_module:get_medal_statics_by_data(data.ServerData)
  local medal_list = data.ServerData.Topic.MedalList
  for i = 0, medal_list.Count - 1 do
    local medal_data = medal_list[i]
    if medal_statics[medal_data.Level] == 1 and not medal_data.IsRewardsTaken then
      return true
    end
  end
end

function codex_module:get_sub_type_lock_icon_color(sub_type)
  if self:is_furniture_sub_type(sub_type) then
    return Color(0.5882352941176471, 0.5882352941176471, 0.5882352941176471, 0.5882352941176471)
  else
    return Color(0, 0, 0, 0.5882352941176471)
  end
end

function codex_module:record_creature_new_size(id)
  if self._creature_new_size == nil then
    self._creature_new_size = {}
  end
  self._creature_new_size[id] = true
end

function codex_module:has_creature_new_size(id)
  if self._creature_new_size == nil then
    return false
  end
  return self._creature_new_size[id] or false
end

function codex_module:remove_creature_new_size(id)
  self._creature_new_size[id] = nil
end

function codex_module:get_item_style_tag_name(id, id_cfg)
  id_cfg = id_cfg or LocalDataUtil.get_value(typeof(CS.BIdCfg), id)
  if id_cfg and id_cfg.GameplayStyleTags then
    local tag_str
    local all_tags = id_cfg.GameplayStyleTags
    for i = 0, all_tags.Count - 1 do
      local tag = all_tags[i]
      if tag then
        if not tag_str then
          tag_str = TagUtil.get_tag_name_in_game(tag)
        else
          tag_str = tag_str .. "," .. TagUtil.get_tag_name_in_game(tag)
        end
      end
    end
    return tag_str
  end
  return nil
end

function codex_module:get_item_type_tag_name(id, id_cfg)
  id_cfg = id_cfg or LocalDataUtil.get_value(typeof(CS.BIdCfg), id)
  if id_cfg and id_cfg.GameplayTypeTags then
    local tag_str
    local all_tags = id_cfg.GameplayTypeTags
    for i = 0, all_tags.Count - 1 do
      local tag = all_tags[i]
      if tag then
        if not tag_str then
          tag_str = TagUtil.get_tag_name_in_game(tag)
        else
          tag_str = tag_str .. "," .. TagUtil.get_tag_name_in_game(tag)
        end
      end
    end
    return tag_str
  end
  return nil
end

function codex_module:get_item_color_tag_name(id, id_cfg)
  id_cfg = id_cfg or LocalDataUtil.get_value(typeof(CS.BIdCfg), id)
  if id_cfg and string.is_valid(id_cfg.tag_color) then
    local all_tags = TagUtil.get_gameplay_tags_by_string(id_cfg.tag_color)
    if all_tags then
      local tag_str
      for i = 0, all_tags.Count - 1 do
        local tag = all_tags[i]
        if tag then
          if not tag_str then
            tag_str = TagUtil.get_tag_name_in_game(tag)
          else
            tag_str = tag_str .. "," .. TagUtil.get_tag_name_in_game(tag)
          end
        end
      end
      return tag_str
    end
  end
  return nil
end

function codex_module:get_item_material_tag_name(id, id_cfg)
  id_cfg = id_cfg or LocalDataUtil.get_value(typeof(CS.BIdCfg), id)
  if id_cfg and string.is_valid(id_cfg.tag_material) then
    local all_tags = TagUtil.get_gameplay_tags_by_string(id_cfg.tag_material)
    if all_tags then
      local tag_str
      for i = 0, all_tags.Count - 1 do
        local tag = all_tags[i]
        if tag then
          if not tag_str then
            tag_str = TagUtil.get_tag_name_in_game(tag)
          else
            tag_str = tag_str .. "," .. TagUtil.get_tag_name_in_game(tag)
          end
        end
      end
      return tag_str
    end
  end
  return nil
end

return codex_module
