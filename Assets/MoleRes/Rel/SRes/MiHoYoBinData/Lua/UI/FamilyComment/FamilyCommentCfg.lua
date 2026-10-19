family_comment_module = family_comment_module or {}

function family_comment_module:_init_cfg_data()
  self._social_tag_cfgs = {}
  self._social_tag_cfg_by_id = {}
  for _, cfg in pairs(ExcelDataUtil.get_table(typeof(BSocialTagCfg)) or {}) do
    table.insert(self._social_tag_cfgs, cfg)
    self._social_tag_cfg_by_id[cfg.socialtagtextid] = cfg
  end
  table.sort(self._social_tag_cfgs, function(a, b)
    return a.socialtagtextid < b.socialtagtextid
  end)
  self._social_tags = {}
  self._social_tag_by_id = {}
  self._social_tag_rich_text_by_id = {}
  for _, cfg in ipairs(self._social_tag_cfgs) do
    local tag = self:_build_social_tag(cfg)
    table.insert(self._social_tags, tag)
    self._social_tag_by_id[tag.id] = tag
    self._social_tag_rich_text_by_id[tag.id] = self:_build_social_tag_rich_text(tag)
  end
end

function family_comment_module:_build_social_tag(cfg)
  return {
    id = cfg.socialtagtextid,
    text = cfg.socialtagtext,
    group_id = cfg.socialtaggroupid,
    lighthouse_syn = cfg.lighthousetagsyn,
    color = string.is_valid(cfg.socialtaguitype) and "#" .. cfg.socialtaguitype or "#FFFFFF",
    icon = cfg.socialtagicon
  }
end

function family_comment_module:_build_social_tag_rich_text(tag)
  return ColorUtil.color_text(tag.color, tag.text)
end

function family_comment_module:get_all_social_tags()
  return self._social_tags
end

function family_comment_module:get_hot_tags()
  local tags = {}
  for _, tag_id in ipairs(list_to_table(CsPlayerVisitModuleUtil.MostPopularTagList)) do
    local tag = self:get_social_tag(tag_id)
    if tag then
      table.insert(tags, tag)
    end
  end
  return tags
end

function family_comment_module:get_social_tag_text(tag_id)
  local cfg = self._social_tag_cfg_by_id[tonumber(tag_id) or 0]
  return cfg and cfg.socialtagtext or nil
end

function family_comment_module:get_social_tag_rich_text(tag_id)
  return self._social_tag_rich_text_by_id[tonumber(tag_id) or 0]
end

function family_comment_module:get_social_tag(tag_id)
  return self._social_tag_by_id[tonumber(tag_id) or 0]
end

function family_comment_module:get_social_level()
  local level = CsPlayerVisitModuleUtil.GetSocialActivityLevel()
  local progress = CsPlayerVisitModuleUtil.GetSocialActivityLevelProgress()
  local level_cfg = ExcelDataUtil.get_value(typeof(BSocialActivityLevelCfg), level)
  return {
    level = level,
    progress = progress,
    value = CsPlayerVisitModuleUtil.SocialScore,
    next_value = CsPlayerVisitModuleUtil.GetSocialActivityNextLevelScore(),
    icon = level_cfg and level_cfg.levelicon or "",
    model = level_cfg and level_cfg.levelmodel or ""
  }
end

return family_comment_module
