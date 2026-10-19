local M = {}
M.rank_group_key = "rank"
M.style_group_key = "style"
M.material_group_key = "material"
M.color_group_key = "color"
M.tag_group_keys = {
  M.color_group_key,
  M.style_group_key,
  M.material_group_key
}
M.rank_group_id = 1
M.color_group_id = 2
M.style_group_id = 3
M.material_group_id = 4
local _tag_group_defs, _all_child_tags
local _item_info_cache = {}

local function child_tags_of(parent_tag)
  return list_to_table(TagUtil.get_child_tags_by_tag(parent_tag)) or {}
end

local function get_tag_group_defs()
  if _tag_group_defs == nil then
    _tag_group_defs = {
      {
        group_key = M.color_group_key,
        group_id = M.color_group_id,
        child_tags = child_tags_of(EntityTagTags.Tags.color)
      },
      {
        group_key = M.style_group_key,
        group_id = M.style_group_id,
        child_tags = child_tags_of(EntityTagTags.Tags.artisticstyle)
      },
      {
        group_key = M.material_group_key,
        group_id = M.material_group_id,
        child_tags = child_tags_of(EntityTagTags.Tags.metiral)
      }
    }
  end
  return _tag_group_defs
end

local function get_all_child_tags()
  if _all_child_tags == nil then
    _all_child_tags = {}
    for _, def in ipairs(get_tag_group_defs()) do
      for _, tag in ipairs(def.child_tags) do
        table.insert(_all_child_tags, tag)
      end
    end
  end
  return _all_child_tags
end

local function get_item_info(cfg_id)
  local info = _item_info_cache[cfg_id]
  if info == nil then
    local cfg = item_module:get_cfg_by_id(cfg_id)
    local tags = {}
    for _, tag in ipairs(get_all_child_tags()) do
      if TagUtil.config_has_tag(cfg_id, tag) then
        tags[tag] = true
      end
    end
    info = {
      rank = cfg and cfg.rank or nil,
      tags = tags
    }
    _item_info_cache[cfg_id] = info
  end
  return info
end

local function get_item_name_lower(cfg_id)
  local info = get_item_info(cfg_id)
  if info.name_lower == nil then
    info.name_lower = string.lower(item_module:get_item_name_by_id(cfg_id) or "")
  end
  return info.name_lower
end

function M.clear_item_cache()
  _item_info_cache = {}
end

function M.normalize_text(text)
  if text == nil then
    return ""
  end
  text = tostring(text)
  text = string.gsub(text, "^%s+", "")
  text = string.gsub(text, "%s+$", "")
  return text
end

function M.new_query_state()
  return {
    search_text = "",
    selected = {}
  }
end

function M.clone_selected(source)
  local result = {}
  for group_key, group in pairs(source or {}) do
    result[group_key] = {}
    for key, is_on in pairs(group or {}) do
      if is_on == true then
        result[group_key][key] = true
      end
    end
  end
  return result
end

function M.has_active_filter(query_state)
  for _, group in pairs(query_state and query_state.selected or {}) do
    if next(group) ~= nil then
      return true
    end
  end
  return false
end

function M.has_active_query(query_state)
  return string.is_valid(query_state and query_state.search_text) or M.has_active_filter(query_state)
end

local function get_selected_set(query_state, group_key)
  local group = query_state and query_state.selected and query_state.selected[group_key]
  if group == nil or next(group) == nil then
    return nil
  end
  return group
end

local function get_selected_tag_union(query_state)
  local result
  for _, group_key in ipairs(M.tag_group_keys) do
    local set = get_selected_set(query_state, group_key)
    if set ~= nil then
      for tag in pairs(set) do
        result = result or {}
        table.insert(result, tag)
      end
    end
  end
  return result
end

function M.compile_query(query_state)
  if query_state == nil then
    return nil
  end
  local search_text = query_state.search_text
  local tag_union_set
  local tag_union = get_selected_tag_union(query_state)
  if tag_union ~= nil then
    tag_union_set = {}
    for _, tag in ipairs(tag_union) do
      tag_union_set[tag] = true
    end
  end
  return {
    search_lower = string.is_valid(search_text) and string.lower(search_text) or nil,
    rank_set = get_selected_set(query_state, M.rank_group_key),
    tag_union_set = tag_union_set
  }
end

function M.match_compiled(cfg_id, compiled)
  if cfg_id == nil or cfg_id <= 0 then
    return false
  end
  if compiled == nil then
    return true
  end
  if compiled.search_lower ~= nil and string.find(get_item_name_lower(cfg_id), compiled.search_lower, 1, true) == nil then
    return false
  end
  if compiled.rank_set ~= nil then
    local rank = get_item_info(cfg_id).rank
    if rank == nil or compiled.rank_set[rank] ~= true then
      return false
    end
  end
  if compiled.tag_union_set ~= nil then
    local hit = false
    for tag in pairs(get_item_info(cfg_id).tags) do
      if compiled.tag_union_set[tag] then
        hit = true
        break
      end
    end
    if not hit then
      return false
    end
  end
  return true
end

local function match_suit_compiled(suit_data, compiled)
  if compiled == nil then
    return true
  end
  if is_null(suit_data) or suit_data.outfitIds == nil then
    return false
  end
  for _, cfg_id in ipairs(list_to_table(suit_data.outfitIds) or {}) do
    if M.match_compiled(cfg_id, compiled) then
      return true
    end
  end
  return false
end

function M.match_cfg_id(cfg_id, query_state)
  return M.match_compiled(cfg_id, M.compile_query(query_state))
end

function M.match_suit_data(suit_data, query_state)
  return match_suit_compiled(suit_data, M.compile_query(query_state))
end

function M.filter_cfg_ids(cfg_ids, query_state)
  if not M.has_active_query(query_state) then
    return cfg_ids or {}
  end
  local compiled = M.compile_query(query_state)
  local result, seen = {}, {}
  for _, cfg_id in ipairs(cfg_ids or {}) do
    if not seen[cfg_id] and M.match_compiled(cfg_id, compiled) then
      seen[cfg_id] = true
      table.insert(result, cfg_id)
    end
  end
  return result
end

function M.filter_guids(guids, query_state)
  if not M.has_active_query(query_state) then
    return guids or {}
  end
  local compiled = M.compile_query(query_state)
  local result, seen = {}, {}
  for _, guid in ipairs(guids or {}) do
    if guid and 0 < guid and not seen[guid] then
      local item = back_bag_module:get_item_from_manager_by_guid(guid, PlayerBagManagerType.Normal)
      if not is_null(item) and M.match_compiled(item.ConFigID, compiled) then
        seen[guid] = true
        table.insert(result, guid)
      end
    end
  end
  return result
end

function M.filter_suit_list(suit_list, query_state)
  if not M.has_active_query(query_state) then
    return suit_list or {}
  end
  local compiled = M.compile_query(query_state)
  local result = {}
  for _, suit_data in ipairs(suit_list or {}) do
    if match_suit_compiled(suit_data, compiled) then
      table.insert(result, suit_data)
    end
  end
  return result
end

local function accumulate_cfg_counts(cfg_id, tag_counts, rank_counts)
  if cfg_id == nil or cfg_id <= 0 then
    return
  end
  local info = get_item_info(cfg_id)
  if info.rank ~= nil then
    rank_counts[info.rank] = (rank_counts[info.rank] or 0) + 1
  end
  for tag in pairs(info.tags) do
    tag_counts[tag] = (tag_counts[tag] or 0) + 1
  end
end

local function accumulate_suit_counts(suit_data, tag_counts, rank_counts)
  if is_null(suit_data) or suit_data.outfitIds == nil then
    return
  end
  local rank_seen, tag_seen = {}, {}
  for _, cfg_id in ipairs(list_to_table(suit_data.outfitIds) or {}) do
    if cfg_id and 0 < cfg_id then
      local info = get_item_info(cfg_id)
      if info.rank ~= nil and not rank_seen[info.rank] then
        rank_seen[info.rank] = true
        rank_counts[info.rank] = (rank_counts[info.rank] or 0) + 1
      end
      for tag in pairs(info.tags) do
        if not tag_seen[tag] then
          tag_seen[tag] = true
          tag_counts[tag] = (tag_counts[tag] or 0) + 1
        end
      end
    end
  end
end

local function compute_counts(source)
  source = source or {}
  local tag_counts, rank_counts = {}, {}
  local seen_cfg = {}
  
  local function add_cfg(cfg_id)
    if cfg_id == nil or cfg_id <= 0 or seen_cfg[cfg_id] then
      return
    end
    seen_cfg[cfg_id] = true
    accumulate_cfg_counts(cfg_id, tag_counts, rank_counts)
  end
  
  for _, cfg_id in ipairs(source.cfg_ids or {}) do
    add_cfg(cfg_id)
  end
  for _, guid in ipairs(source.guids or {}) do
    if guid and 0 < guid then
      local item = back_bag_module:get_item_from_manager_by_guid(guid, PlayerBagManagerType.Normal)
      if not is_null(item) then
        add_cfg(item.ConFigID)
      end
    end
  end
  local seen_suit = {}
  for _, suit_data in ipairs(source.suit_list or {}) do
    if not is_null(suit_data) and suit_data.suitId ~= nil and not seen_suit[suit_data.suitId] then
      seen_suit[suit_data.suitId] = true
      accumulate_suit_counts(suit_data, tag_counts, rank_counts)
    end
  end
  return tag_counts, rank_counts
end

local function build_rank_group(rank_counts)
  local items = {}
  local rank_items = appearance_module:get_filter_group_items(M.rank_group_id)
  if rank_items ~= nil then
    for _, item in ipairs(rank_items) do
      table.insert(items, {
        key = item.key,
        label = item.label,
        style_state_id = item.key,
        count = rank_counts and rank_counts[item.key] or 0
      })
    end
  end
  return {
    group_key = M.rank_group_key,
    selection_mode = "multi",
    items = items,
    title = appearance_module:get_filter_group_title(M.rank_group_id)
  }
end

local function build_tag_group(def, tag_counts)
  local items = {}
  for _, tag in ipairs(def.child_tags) do
    table.insert(items, {
      key = tag,
      label = TagUtil.get_tag_name_in_game(tag),
      icon_path = TagUtil.get_tag_icon(tag),
      count = tag_counts and tag_counts[tag] or 0
    })
  end
  if #items == 0 then
    return nil
  end
  return {
    group_key = def.group_key,
    selection_mode = "multi",
    title_text_id = def.title_text_id,
    items = items
  }
end

function M.build_filter_groups(opts)
  opts = opts or {}
  local tag_counts, rank_counts = compute_counts(opts.count_source)
  local groups = {}
  table.insert(groups, build_rank_group(rank_counts))
  if opts.include_tag_categories then
    for _, def in ipairs(get_tag_group_defs()) do
      local g = build_tag_group(def, tag_counts)
      if g then
        g.title = appearance_module:get_filter_group_title(def.group_id)
        table.insert(groups, g)
      end
    end
  end
  return groups
end

function M.select_groups(groups, key_set)
  local result = {}
  for _, g in ipairs(groups or {}) do
    if key_set[g.group_key] then
      table.insert(result, g)
    end
  end
  return result
end

function M.record_history(text, source, limit)
  text = M.normalize_text(text)
  if not string.is_valid(text) then
    return source or {}
  end
  limit = limit or 10
  local result = {text}
  for _, raw in ipairs(source or {}) do
    local item = M.normalize_text(raw)
    if string.is_valid(item) and item ~= text then
      table.insert(result, item)
    end
    if limit <= #result then
      break
    end
  end
  return result
end

return M
