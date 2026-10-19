theme_season_module = theme_season_module or {}

function theme_season_module:get_theme_season_cfg()
  if self._theme_season_cfgs == nil then
    self._theme_season_cfgs = ExcelDataUtil.get_table(typeof(BThemeSeasonCfg)) or {}
  end
  return self._theme_season_cfgs
end

function theme_season_module:get_theme_season_cfg_by_id(season_id)
  if season_id == nil or season_id <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BThemeSeasonCfg), season_id)
end

function theme_season_module:get_theme_season_goods_cfg()
  if self._theme_season_goods_cfgs == nil then
    self._theme_season_goods_cfgs = ExcelDataUtil.get_table(typeof(BThemeSeasonGoodsCfg)) or {}
  end
  return self._theme_season_goods_cfgs
end

function theme_season_module:get_theme_season_goods_cfg_by_id(goods_id)
  if goods_id == nil or goods_id <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BThemeSeasonGoodsCfg), goods_id)
end

function theme_season_module:get_theme_season_mystery_box_cfg()
  if self._theme_season_mystery_box_cfgs == nil then
    self._theme_season_mystery_box_cfgs = ExcelDataUtil.get_table(typeof(BThemeSeasonMysteryBoxCfg)) or {}
  end
  return self._theme_season_mystery_box_cfgs
end

function theme_season_module:get_theme_season_mystery_box_cfg_by_id(box_id)
  if box_id == nil or box_id <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BThemeSeasonMysteryBoxCfg), box_id)
end

function theme_season_module:get_theme_season_npc_goods_cfg()
  if self._theme_season_npc_goods_cfgs == nil then
    self._theme_season_npc_goods_cfgs = ExcelDataUtil.get_table(typeof(BThemeSeasonNpcGoodsCfg)) or {}
  end
  return self._theme_season_npc_goods_cfgs
end

function theme_season_module:get_theme_season_npc_goods_cfg_by_id(goods_id)
  if goods_id == nil or goods_id <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BThemeSeasonNpcGoodsCfg), goods_id)
end

function theme_season_module:get_theme_season_graduate_cfg()
  if self._theme_season_graduate_cfgs == nil then
    self._theme_season_graduate_cfgs = ExcelDataUtil.get_table(typeof(BThemeSeasonGraduateCfg)) or {}
  end
  return self._theme_season_graduate_cfgs
end

function theme_season_module:get_theme_season_graduate_cfg_by_id(graduate_id)
  if graduate_id == nil or graduate_id <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BThemeSeasonGraduateCfg), graduate_id)
end

function theme_season_module:get_theme_season_story_part_cfg()
  if self._theme_season_story_part_cfgs == nil then
    self._theme_season_story_part_cfgs = ExcelDataUtil.get_table(typeof(BThemeSeasonStoryPartCfg)) or {}
  end
  return self._theme_season_story_part_cfgs
end

function theme_season_module:get_theme_season_story_part_cfg_by_id(part_id)
  if part_id == nil or part_id <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BThemeSeasonStoryPartCfg), part_id)
end

function theme_season_module:get_theme_season_story_task_cfg()
  if self._theme_season_story_task_cfgs == nil then
    self._theme_season_story_task_cfgs = ExcelDataUtil.get_table(typeof(BThemeSeasonStoryTaskCfg)) or {}
  end
  return self._theme_season_story_task_cfgs
end

function theme_season_module:get_theme_season_story_task_cfg_by_id(task_id)
  if task_id == nil or task_id <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BThemeSeasonStoryTaskCfg), task_id)
end

function theme_season_module:_parse_id_list(str)
  local result = {}
  if str == nil or str == "" then
    return result
  end
  for id_str in string.gmatch(str, "([^,]+)") do
    local id = tonumber(id_str)
    if id and 0 < id then
      result[#result + 1] = id
    end
  end
  return result
end

function theme_season_module:_parse_reward_list(str)
  local result = {}
  if str == nil or str == "" then
    return result
  end
  for entry in string.gmatch(str, "([^;]+)") do
    local item_id_str, count_str = string.match(entry, "(%d+):(%d+)")
    local item_id = tonumber(item_id_str) or 0
    local count = tonumber(count_str) or 0
    if 0 < item_id and 0 < count then
      result[#result + 1] = {item_id = item_id, count = count}
    end
  end
  return result
end

function theme_season_module:get_story_part_ids(season_id)
  local sid = season_id or self:get_cur_season_id()
  local season_cfg = self:get_theme_season_cfg_by_id(sid)
  if season_cfg == nil then
    return {}
  end
  return self:_parse_id_list(season_cfg.storylist)
end

function theme_season_module:get_story_task_group_ids(story_task_id)
  local story_task_cfg = self:get_theme_season_story_task_cfg_by_id(story_task_id)
  if story_task_cfg == nil then
    return {}
  end
  return self:_parse_id_list(story_task_cfg.taskgrouplist)
end

function theme_season_module:get_story_part_title(part_id)
  local part_cfg = self:get_theme_season_story_part_cfg_by_id(part_id)
  return part_cfg and part_cfg.title or ""
end

function theme_season_module:get_story_part_pv(part_index, season_id)
  local part_ids = self:get_story_part_ids(season_id)
  local part_id = part_ids and part_ids[part_index or 1]
  if part_id == nil then
    return 0
  end
  local part_cfg = self:get_theme_season_story_part_cfg_by_id(part_id)
  return part_cfg and part_cfg.pv or 0
end

function theme_season_module:get_theme_season_bp_price_cfg()
  if self._theme_season_bp_price_cfgs == nil then
    self._theme_season_bp_price_cfgs = ExcelDataUtil.get_table(typeof(BThemeSeasonBPPriceCfg)) or {}
  end
  return self._theme_season_bp_price_cfgs
end

function theme_season_module:get_theme_season_bp_price_cfg_by_id(price_id)
  if price_id == nil or price_id <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BThemeSeasonBPPriceCfg), price_id)
end

function theme_season_module:get_theme_season_const_cfg_map()
  if self._theme_season_const_cfg_map == nil then
    self._theme_season_const_cfg_map = {}
    local cfgs = ExcelDataUtil.get_table(typeof(BThemeSeasonConstCfg)) or {}
    for _, cfg in pairs(cfgs) do
      if string.is_valid(cfg.themeseasonconsttype) then
        self._theme_season_const_cfg_map[cfg.themeseasonconsttype] = cfg
      end
    end
  end
  return self._theme_season_const_cfg_map
end

function theme_season_module:get_const_value(const_type)
  local cfg = self:get_theme_season_const_cfg_map()[const_type]
  return cfg and cfg.value1 or 0
end

function theme_season_module:get_cur_season_cfg()
  local season_id = self:get_cur_season_id()
  if season_id == nil or season_id <= 0 then
    return nil
  end
  return self:get_theme_season_cfg_by_id(season_id)
end

function theme_season_module:get_season_icon_path()
  local season_cfg = self:get_cur_season_cfg()
  if season_cfg and string.is_valid(season_cfg.icon) then
    return season_cfg.icon
  end
  return nil
end

function theme_season_module:get_hud_icon_path()
  return self:get_season_icon_path() or "UISprite/Load/MainPageIcon/HUD_ThemeSeason.png"
end

function theme_season_module:get_season_name()
  local season_cfg = self:get_cur_season_cfg()
  if season_cfg and string.is_valid(season_cfg.name) then
    return season_cfg.name
  end
  return nil
end

function theme_season_module:get_season_phone_icon_path()
  local season_cfg = self:get_cur_season_cfg()
  if season_cfg and string.is_valid(season_cfg.iconphone) then
    return season_cfg.iconphone
  end
  return nil
end

return theme_season_module
