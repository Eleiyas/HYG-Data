local TagUtil = {}

local function is_child_of(a, b)
  return CsGameplayTagUtilUtil.TagMatchesTag(a, b)
end

local function in_tags(target, tags)
  return CsGameplayTagUtilUtil.InTags(target, tags)
end

local function get_tag_name_in_game(tag)
  return CsGameplayTagUtilUtil.GetTagNameInGame(tag)
end

local function get_tag_name_in_game_by_string(tag_str)
  return CsGameplayTagUtilUtil.GetTagNameInGameByString(tag_str)
end

local function get_tag_icon_by_string(tag_str)
  return CsGameplayTagUtilUtil.GetTagIconByString(tag_str)
end

local function get_tag_icon(tag)
  return CsGameplayTagUtilUtil.GetTagIcon(tag)
end

local function config_has_tag(cfg_id, tag)
  return CsGameplayTagUtilUtil.ConfigHasTag(cfg_id, tag)
end

local function config_has_tag_by_string(cfg_id, tag_str)
  return CsGameplayTagUtilUtil.ConfigHasTagByString(cfg_id, tag_str)
end

local function config_has_any_tag_by_string_list(cfg_id, tag_strings)
  return CsGameplayTagUtilUtil.ConfigHasAnyTag(cfg_id, tag_strings)
end

local function scene_config_has_tag(scene_id, tag)
  return CsGameplayTagUtilUtil.SceneConfigHasTag(scene_id, tag)
end

local function get_gameplay_tags_by_string(tag_str)
  return CsGameplayTagUtilUtil.GetUIntTagsByString(tag_str)
end

TagUtil.is_child_of = is_child_of
TagUtil.in_tags = in_tags
TagUtil.get_tag_name_in_game = get_tag_name_in_game
TagUtil.get_tag_icon = get_tag_icon
TagUtil.get_tag_icon_by_string = get_tag_icon_by_string
TagUtil.get_tag_name_in_game_by_string = get_tag_name_in_game_by_string
TagUtil.config_has_tag = config_has_tag
TagUtil.config_has_tag_by_string = config_has_tag_by_string
TagUtil.config_has_any_tag_by_string_list = config_has_any_tag_by_string_list
TagUtil.scene_config_has_tag = scene_config_has_tag
TagUtil.get_gameplay_tags_by_string = get_gameplay_tags_by_string
return TagUtil
