hair_dyeing_module = hair_dyeing_module or {}

function hair_dyeing_module:get_tab_cfg(panel_key)
  local cfg_id = self.tab_cfg_id[panel_key]
  if cfg_id == nil then
    return nil
  end
  local cfg_type = typeof(BHairDyeingTabCfg)
  if is_null(cfg_type) then
    return nil
  end
  return ExcelDataUtil.get_value(cfg_type, cfg_id)
end

hair_dyeing_module._color_cfg_cache = nil

local function _append_color_cfg(index, key, color_cfg)
  local color_cfgs = index[key]
  if color_cfgs == nil then
    color_cfgs = {}
    index[key] = color_cfgs
  end
  table.insert(color_cfgs, color_cfg)
end

local function _get_color_group_cfg(cache, color_cfg)
  return color_cfg and cache.by_color_group[color_cfg.color] or nil
end

local function _compare_color_cfg(cache, first_cfg, second_cfg)
  local first_group_cfg = _get_color_group_cfg(cache, first_cfg)
  local second_group_cfg = _get_color_group_cfg(cache, second_cfg)
  local first_sort = first_group_cfg and first_group_cfg.sort or 0
  local second_sort = second_group_cfg and second_group_cfg.sort or 0
  if first_sort ~= second_sort then
    return first_sort < second_sort
  end
  return (first_cfg.id or 0) < (second_cfg.id or 0)
end

local function _trim_color_tag(color_tag)
  return string.match(color_tag or "", "^%s*(.-)%s*$")
end

function hair_dyeing_module:_ensure_color_cfg_cache()
  if self._color_cfg_cache then
    return
  end
  local by_color_group = {}
  for _, color_group_cfg in pairs(ExcelDataUtil.get_table(typeof(BColorGroupCfg))) do
    by_color_group[color_group_cfg.colorid] = color_group_cfg
  end
  local by_single_tag = {}
  local by_dual_tags = {}
  local by_color = {}
  local by_color_block = {}
  local by_tag = {}
  local by_type = {}
  for _, cfg in pairs(ExcelDataUtil.get_table(typeof(BColorCfg))) do
    if string.is_valid(cfg.colortagsyn) then
      _append_color_cfg(by_single_tag, cfg.colortagsyn, cfg)
    end
    if string.is_valid(cfg.colortagsyn1) and string.is_valid(cfg.colortagsyn2) then
      local first_tag, second_tag = cfg.colortagsyn1, cfg.colortagsyn2
      local key = first_tag <= second_tag and first_tag .. "|" .. second_tag or second_tag .. "|" .. first_tag
      _append_color_cfg(by_dual_tags, key, cfg)
    end
    if cfg.color then
      by_color[cfg.color] = cfg
      local color_group_data = CsDyeingModuleUtil.GetColorGroupData(cfg.color)
      local color_block_ids = color_group_data and color_group_data.colorBlockIds or nil
      if not is_null(color_block_ids) then
        for i = 0, color_block_ids.Count - 1 do
          by_color_block[color_block_ids[i]] = cfg
        end
      end
    end
    if cfg.tag then
      local list = by_tag[cfg.tag]
      if list == nil then
        list = {}
        by_tag[cfg.tag] = list
      end
      table.insert(list, cfg)
    end
    local color_group_cfg = by_color_group[cfg.color]
    if color_group_cfg then
      local draw_by_dye = color_group_cfg.drawbydye
      local list = by_type[draw_by_dye]
      if list == nil then
        list = {}
        by_type[draw_by_dye] = list
      end
      table.insert(list, cfg)
    end
  end
  self._color_cfg_cache = {
    by_single_tag = by_single_tag,
    by_dual_tags = by_dual_tags,
    by_color = by_color,
    by_color_block = by_color_block,
    by_tag = by_tag,
    by_type = by_type,
    by_color_group = by_color_group
  }
end

function hair_dyeing_module:get_active_color_cfgs_by_tags(color_tags)
  if color_tags == nil or #color_tags == 0 then
    return {}
  end
  self:_ensure_color_cfg_cache()
  local cache = self._color_cfg_cache
  local matched_cfgs
  if #color_tags == 1 then
    matched_cfgs = cache.by_single_tag[color_tags[1]]
  else
    local first_tag, second_tag = color_tags[1], color_tags[2]
    if first_tag == nil or second_tag == nil then
      return {}
    end
    local key = first_tag <= second_tag and first_tag .. "|" .. second_tag or second_tag .. "|" .. first_tag
    matched_cfgs = cache.by_dual_tags[key]
  end
  local active_cfgs = {}
  local active_draw_by_dye_type = self.exchange_inspiration_type.active
  for _, color_cfg in ipairs(matched_cfgs or {}) do
    local color_group_cfg = _get_color_group_cfg(cache, color_cfg)
    if color_group_cfg and color_group_cfg.drawbydye == active_draw_by_dye_type then
      table.insert(active_cfgs, color_cfg)
    end
  end
  table.sort(active_cfgs, function(first_cfg, second_cfg)
    return _compare_color_cfg(cache, first_cfg, second_cfg)
  end)
  return active_cfgs
end

function hair_dyeing_module:get_flower_color_tags_by_item_id(item_id)
  local id_cfg = ExcelDataUtil.get_value(typeof(BIdCfg), item_id)
  local tag_color = id_cfg and id_cfg.tag_color or nil
  if not string.is_valid(tag_color) then
    return {}
  end
  local color_tags = {}
  local added_tags = {}
  tag_color = string.gsub(tag_color, "，", ",")
  for raw_tag in string.gmatch(tag_color, "[^,]+") do
    local color_tag = _trim_color_tag(raw_tag)
    if string.is_valid(color_tag) and not added_tags[color_tag] then
      added_tags[color_tag] = true
      table.insert(color_tags, color_tag)
    end
  end
  return color_tags
end

function hair_dyeing_module:get_flower_mixed_color_tag(item_id)
  local color_tags = self:get_flower_color_tags_by_item_id(item_id)
  if #color_tags == 1 then
    return color_tags[1]
  end
  if #color_tags ~= 2 then
    return nil
  end
  local mixed_cfg = self:get_active_color_cfgs_by_tags(color_tags)[1]
  if mixed_cfg == nil then
    return nil
  end
  if string.is_valid(mixed_cfg.colortagsyn) then
    return mixed_cfg.colortagsyn
  end
  return mixed_cfg.tag
end

function hair_dyeing_module:get_active_color_cfgs_by_flower_ids(flower_ids)
  if flower_ids == nil or #flower_ids == 0 or #flower_ids > self.max_flower_select then
    return {}
  end
  local mixed_color_tags = {}
  for _, item_id in ipairs(flower_ids) do
    local mixed_color_tag = self:get_flower_mixed_color_tag(item_id)
    if not string.is_valid(mixed_color_tag) then
      return {}
    end
    table.insert(mixed_color_tags, mixed_color_tag)
  end
  return self:get_active_color_cfgs_by_tags(mixed_color_tags)
end

function hair_dyeing_module:get_result_rate_cfg(dye_mode, dye_type)
  return nil
end

function hair_dyeing_module:is_color_pickable(color_id)
  local color_group_cfg = self:get_color_group_cfg_by_color_id(color_id)
  if color_group_cfg == nil then
    return false
  end
  return color_group_cfg.exchange == 1
end

function hair_dyeing_module:get_all_color_systems()
  self:_ensure_color_cfg_cache()
  local by_tag = self._color_cfg_cache.by_tag
  return by_tag
end

function hair_dyeing_module:get_color_cfgs_by_type(color_type)
  self:_ensure_color_cfg_cache()
  return self._color_cfg_cache.by_type[color_type] or {}
end

function hair_dyeing_module:get_color_cfg_by_color_group_id(color_group_id)
  if color_group_id == nil or color_group_id <= 0 then
    return nil
  end
  self:_ensure_color_cfg_cache()
  return self._color_cfg_cache.by_color[color_group_id]
end

function hair_dyeing_module:get_color_group_cfg_by_color_group_id(color_group_id)
  if color_group_id == nil or color_group_id <= 0 then
    return nil
  end
  self:_ensure_color_cfg_cache()
  return self._color_cfg_cache.by_color_group[color_group_id]
end

function hair_dyeing_module:get_color_group_cfg(color_cfg)
  return color_cfg and self:get_color_group_cfg_by_color_group_id(color_cfg.color) or nil
end

function hair_dyeing_module:get_color_group_cfg_by_color_id(color_id)
  return self:get_color_group_cfg(self:get_color_cfg_by_color_id(color_id))
end

function hair_dyeing_module:get_color_group_ids_by_hair_region(style_id, region_id)
  if style_id == nil or style_id <= 0 or region_id == nil or region_id <= 0 then
    return nil
  end
  return CsDyeingModuleUtil.GetHairAssetColorGroupIdsByRegionId(style_id, region_id)
end

function hair_dyeing_module:has_gradient_region(style_id)
  style_id = style_id or self:get_cur_style_id()
  if style_id == nil or style_id <= 0 then
    return false
  end
  return CsDyeingModuleUtil.GetHairAssetRegionCount(style_id) >= self.dye_part.region
end

function hair_dyeing_module:get_color_cfgs_by_type_and_region(color_type, style_id, region_id)
  local color_group_ids = self:get_color_group_ids_by_hair_region(style_id, region_id)
  if is_null(color_group_ids) then
    return self:get_color_cfgs_by_type(color_type)
  end
  local result = {}
  local seen = {}
  for i = 0, color_group_ids.Count - 1 do
    local color_group_id = color_group_ids[i]
    if not seen[color_group_id] then
      seen[color_group_id] = true
      local cfg = self:get_color_cfg_by_color_group_id(color_group_id)
      local color_group_cfg = self:get_color_group_cfg_by_color_group_id(color_group_id)
      if cfg ~= nil and color_group_cfg ~= nil and color_group_cfg.drawbydye == color_type then
        table.insert(result, cfg)
      end
    end
  end
  table.sort(result, function(first_cfg, second_cfg)
    return _compare_color_cfg(self._color_cfg_cache, first_cfg, second_cfg)
  end)
  return result
end

function hair_dyeing_module:get_display_color_by_color_group_id(color_group_id)
  if color_group_id == nil or color_group_id <= 0 then
    return nil
  end
  local color = CsDyeingModuleUtil.GetColorGroupDisplayColor(color_group_id)
  if 0 < color.a then
    return color
  end
  local color_block_ids = CsDyeingModuleUtil.GetColorBlockIdsByGroupId(color_group_id)
  if not is_null(color_block_ids) and 0 < color_block_ids.Count then
    return CsDyeingModuleUtil.GetDisplayColorByColorBlockId(color_block_ids[0])
  end
  return color
end

function hair_dyeing_module:get_display_color_by_color_cfg(color_cfg)
  if color_cfg == nil then
    return nil
  end
  return self:get_display_color_by_color_group_id(color_cfg.color)
end

function hair_dyeing_module:get_icon_path_by_color_cfg(color_cfg)
  if color_cfg == nil then
    return nil
  end
  local color_group_data = CsDyeingModuleUtil.GetColorGroupData(color_cfg.color)
  return not is_null(color_group_data) and color_group_data.iconPath or nil
end

function hair_dyeing_module:get_color_cfg_by_color_id(color_id)
  if color_id == nil or color_id <= 0 then
    return nil
  end
  self:_ensure_color_cfg_cache()
  return self._color_cfg_cache.by_color_block[color_id] or self._color_cfg_cache.by_color[color_id]
end

function hair_dyeing_module:get_color_name_by_color_id(color_id)
  local cfg = self:get_color_cfg_by_color_id(color_id)
  if cfg ~= nil and string.is_valid(cfg.name) then
    return cfg.name
  end
  return nil
end

function hair_dyeing_module:get_color_name_by_block_id(color_block_id)
  if color_block_id == nil or color_block_id <= 0 then
    return nil
  end
  local color_cfg = self:get_color_cfg_by_color_id(color_block_id)
  if color_cfg ~= nil and string.is_valid(color_cfg.tag) then
    local color_name = TagUtil.get_tag_name_in_game_by_string(color_cfg.tag)
    if string.is_valid(color_name) then
      return color_name
    end
  end
  return nil
end

function hair_dyeing_module:get_flower_color_systems()
  local cfgs = self:get_color_cfgs_by_type(self.dye_mode.flower)
  local seen = {}
  local systems = {}
  for _, cfg in ipairs(cfgs) do
    local tag = cfg.tag
    if string.is_valid(tag) and not seen[tag] then
      seen[tag] = true
      local color_group_cfg = self:get_color_group_cfg(cfg)
      local color = self:get_display_color_by_color_cfg(cfg)
      table.insert(systems, {
        tag = tag,
        label = cfg.name,
        color = color,
        sort = color_group_cfg and color_group_cfg.sort or 0
      })
    end
  end
  table.sort(systems, function(a, b)
    return a.sort < b.sort
  end)
  local owned_by_tag = self:count_flower_types_by_color_tag()
  for _, sys in ipairs(systems) do
    sys.count = owned_by_tag[sys.tag] or 0
    sys.sort = nil
  end
  return systems
end

function hair_dyeing_module:count_flower_types_by_color_tag()
  local result = {}
  local counted = {}
  local all_tab_index = 0
  local all_filter_index = 0
  local guid_list = CsPacketModuleUtil.GetItemGuids(back_bag_module.bag_show_type.hair_dye_flower, all_tab_index, all_filter_index)
  local guids = guid_list and list_to_table(guid_list) or {}
  for _, guid in ipairs(guids) do
    local item = back_bag_module:get_item_by_guid(guid)
    if not is_null(item) then
      local item_id = item.ConfigId or item.ConFigID
      if item_id and not counted[item_id] then
        counted[item_id] = true
        for _, color_tag in ipairs(self:get_flower_color_tags_by_item_id(item_id)) do
          result[color_tag] = (result[color_tag] or 0) + 1
        end
      end
    end
  end
  return result
end

function hair_dyeing_module:get_flower_display_colors_by_item_id(item_id)
  local display_colors = {}
  local color_tags = self:get_flower_color_tags_by_item_id(item_id)
  local cfgs = self:get_color_cfgs_by_type(self.dye_mode.flower)
  for _, color_tag in ipairs(color_tags) do
    for _, cfg in ipairs(cfgs) do
      if cfg.tag == color_tag then
        table.insert(display_colors, self:get_display_color_by_color_cfg(cfg))
        break
      end
    end
  end
  return display_colors
end

function hair_dyeing_module:get_flower_display_color_by_item_id(item_id)
  return self:get_flower_display_colors_by_item_id(item_id)[1]
end

local function _parse_exchange_cost_item(cost_item)
  if not string.is_valid(cost_item) then
    return nil, nil
  end
  local item_id, count = string.match(cost_item, "^(%d+)_(%d+)$")
  return tonumber(item_id), tonumber(count)
end

function hair_dyeing_module:get_exchange_material_id(exchange_type)
  local type_cfg = self.exchange_inspiration_type or {}
  if exchange_type == type_cfg.active then
    return self.currency.inspiration_active
  elseif exchange_type == type_cfg.paid then
    return self.currency.inspiration_paid
  elseif exchange_type == type_cfg.rainbow then
    return self.currency.rainbow_inspiration
  end
  return 0
end

function hair_dyeing_module:parse_exchange_cost(color_cfg)
  local color_group_cfg = self:get_color_group_cfg(color_cfg)
  local item_id, count = _parse_exchange_cost_item(color_group_cfg and color_group_cfg.costitem or nil)
  if item_id ~= nil and count ~= nil then
    return item_id, count
  end
  return self:get_exchange_material_id(color_group_cfg and color_group_cfg.drawbydye or nil), 1
end

function hair_dyeing_module:get_exchange_inspiration_cost(_exchange_type, color_cfg)
  local _, count = self:parse_exchange_cost(color_cfg)
  return count or 0
end

function hair_dyeing_module:is_exchange_color_unlocked(style_id, dye_part, color_id)
  if style_id == nil or style_id <= 0 or color_id == nil or color_id <= 0 then
    return false
  end
  local global_region_id = 1
  local local_region_id = 2
  local region_id = dye_part == self.dye_part.region and local_region_id or global_region_id
  return CsAppearanceModuleUtil.IsColorUnlocked(style_id, region_id, color_id)
end

function hair_dyeing_module:get_exchange_color_systems(style_id, region_id)
  self:_ensure_color_cfg_cache()
  local type_cfg = self.exchange_inspiration_type or {}
  local result = {}
  local by_tag = {}
  local exchange_types = {
    type_cfg.active,
    type_cfg.paid,
    type_cfg.rainbow
  }
  for _, exchange_type in ipairs(exchange_types) do
    local cfgs = self:get_color_cfgs_by_type_and_region(exchange_type, style_id, region_id)
    for _, cfg in ipairs(cfgs) do
      local tag = cfg.tag
      local color_group_cfg = self:get_color_group_cfg(cfg)
      if string.is_valid(tag) and color_group_cfg ~= nil and color_group_cfg.exchange == 1 then
        local system = by_tag[tag]
        if system == nil then
          system = {
            tag = tag,
            label = cfg.name,
            display_color = self:get_display_color_by_color_cfg(cfg),
            icon_path = self:get_icon_path_by_color_cfg(cfg),
            sort = color_group_cfg.sort or 0,
            colors = {},
            _color_map = {}
          }
          by_tag[tag] = system
          table.insert(result, system)
        end
        local cost_item_id, cost_num = self:parse_exchange_cost(cfg)
        local color_block_ids = self:get_colors_by_color_sys(cfg)
        if not is_null(color_block_ids) then
          for i = 0, color_block_ids.Count - 1 do
            local color_id = color_block_ids[i]
            local key = tostring(exchange_type) .. "|" .. tostring(color_id)
            if not system._color_map[key] then
              system._color_map[key] = true
              table.insert(system.colors, {
                color_id = color_id,
                exchange_type = exchange_type,
                cost_item_id = cost_item_id,
                cost_num = cost_num,
                color_cfg = cfg,
                sort = color_group_cfg.sort or 0
              })
            end
          end
        end
      end
    end
  end
  table.sort(result, function(a, b)
    return (a.sort or 0) < (b.sort or 0)
  end)
  for _, system in ipairs(result) do
    table.sort(system.colors, function(a, b)
      if a.exchange_type ~= b.exchange_type then
        return a.exchange_type < b.exchange_type
      end
      return (a.sort or 0) < (b.sort or 0)
    end)
    system._color_map = nil
  end
  return result
end

return hair_dyeing_module
