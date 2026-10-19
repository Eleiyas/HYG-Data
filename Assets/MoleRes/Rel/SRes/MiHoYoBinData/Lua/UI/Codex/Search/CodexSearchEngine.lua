local M = {}
local MATCH_NAME_EXACT = 100
local MATCH_NAME_CONTAINS = 90
local MATCH_NAME_PARTIAL = 80
local MATCH_TAG_EXACT = 60
local MATCH_TAG_CONTAINS = 50
local MAX_SUGGESTION = 10
local MAX_HISTORY = 10
local HISTORY_STORAGE_KEY = LocalSaveID.CodexSearchHistory
local history_cache
local TAG_FIELD_GETTERS = {
  function(id_cfg)
    return codex_module:get_item_area_tag_name(nil, id_cfg)
  end,
  function(id_cfg)
    return codex_module:get_item_color_tag_name(nil, id_cfg)
  end,
  function(id_cfg)
    return codex_module:get_item_material_tag_name(nil, id_cfg)
  end,
  function(id_cfg)
    return codex_module:get_item_style_tag_name(nil, id_cfg)
  end,
  function(id_cfg)
    return codex_module:get_item_type_tag_name(nil, id_cfg)
  end,
  function(id_cfg)
    if id_cfg and string.is_valid(id_cfg.tag_foodmaterials) then
      return CsGameplayTagUtilUtil.GetTagNameInGameByString(id_cfg.tag_foodmaterials)
    end
    return nil
  end,
  function(id_cfg)
    if id_cfg and string.is_valid(id_cfg.tag_showtype) then
      return CsGameplayTagUtilUtil.GetTagNameInGameByString(id_cfg.tag_showtype)
    end
    return nil
  end
}

local function _filter_special_chars(text)
  if not text then
    return ""
  end
  local result = {}
  for _, c in utf8.codes(text) do
    local ch = utf8.char(c)
    if not string.match(ch, "[%p%s]") then
      table.insert(result, ch)
    end
  end
  return table.concat(result)
end

local function _score_name(lower_name, lower_keyword)
  if lower_name == lower_keyword then
    return MATCH_NAME_EXACT
  end
  local pos = string.find(lower_name, lower_keyword, 1, true)
  if pos then
    return MATCH_NAME_CONTAINS
  end
  return 0
end

local function _score_tags(id_cfg, lower_keyword)
  local best = 0
  for _, getter in ipairs(TAG_FIELD_GETTERS) do
    local tag_text = getter(id_cfg)
    if tag_text and string.is_valid(tag_text) then
      local lower_tag = string.lower(tag_text)
      if lower_tag == lower_keyword then
        best = math.max(best, MATCH_TAG_EXACT)
      elseif string.find(lower_tag, lower_keyword, 1, true) then
        best = math.max(best, MATCH_TAG_CONTAINS)
      end
      if best >= MATCH_TAG_EXACT then
        break
      end
    end
  end
  return best
end

local function _match_context(data, context)
  if data == nil then
    return false
  end
  if data.Type == CodexDataType.Plant and not data.IsPackage and data.IsFruitKingColorVariant then
    return false
  end
  context = context or {}
  if context.type ~= nil and data.Type ~= context.type then
    return false
  end
  if context.sub_type ~= nil and data.SubType ~= context.sub_type then
    return false
  end
  if data.IsPackage then
    if context.include_package == true then
      return true
    end
    return context.sub_type ~= nil and codex_module:is_package_sub_type(context.sub_type)
  end
  return true
end

function M.search(keyword, context)
  if not keyword or keyword == "" then
    return {}
  end
  local lower_kw = string.lower(keyword)
  local all_data = codex_module:get_all_data()
  if not all_data then
    return {}
  end
  local type_buckets = {}
  for id, data in pairs(all_data) do
    if _match_context(data, context) then
      local id_cfg = data.IdCfg
      if id_cfg and not id_cfg.__empty then
        local name = id_cfg.name or ""
        local lower_name = string.lower(name)
        local name_score = _score_name(lower_name, lower_kw)
        local tag_score = _score_tags(id_cfg, lower_kw)
        local score = math.max(name_score, tag_score)
        if 0 < score then
          local t = data.Type
          local st = data.SubType
          if not type_buckets[t] then
            type_buckets[t] = {}
          end
          if not type_buckets[t][st] then
            type_buckets[t][st] = {}
          end
          table.insert(type_buckets[t][st], {data = data, score = score})
        end
      end
    end
  end
  return M._build_grouped_results(type_buckets)
end

function M.suggest(keyword, context)
  if not keyword or keyword == "" then
    return {}
  end
  local lower_kw = string.lower(keyword)
  local all_data = codex_module:get_all_data()
  if not all_data then
    return {}
  end
  local results = {}
  for id, data in pairs(all_data) do
    if _match_context(data, context) and data.IsUnlocked then
      local id_cfg = data.IdCfg
      if id_cfg and not id_cfg.__empty then
        local name = id_cfg.name or ""
        local lower_name = string.lower(name)
        local score = _score_name(lower_name, lower_kw)
        if 0 < score then
          table.insert(results, {
            name = name,
            cfg_id = id,
            score = score
          })
        end
      end
    end
  end
  table.sort(results, function(a, b)
    if a.score ~= b.score then
      return a.score > b.score
    end
    return a.name < b.name
  end)
  if #results > MAX_SUGGESTION then
    local trimmed = {}
    for i = 1, MAX_SUGGESTION do
      trimmed[i] = results[i]
    end
    return trimmed
  end
  return results
end

function M._build_grouped_results(type_buckets)
  local groups = {}
  for t, sub_map in pairs(type_buckets) do
    local type_group = {
      type = t,
      total_count = 0,
      sub_groups = {}
    }
    for st, items in pairs(sub_map) do
      table.sort(items, function(a, b)
        if a.score ~= b.score then
          return a.score > b.score
        end
        return (a.data.Sequence or 0) < (b.data.Sequence or 0)
      end)
      local sg = {sub_type = st, items = items}
      type_group.total_count = type_group.total_count + #items
      table.insert(type_group.sub_groups, sg)
    end
    table.sort(type_group.sub_groups, function(a, b)
      return a.sub_type < b.sub_type
    end)
    table.insert(groups, type_group)
  end
  table.sort(groups, function(a, b)
    return a.total_count > b.total_count
  end)
  return groups
end

function M.filter_input(text)
  return _filter_special_chars(text)
end

local function _ensure_history_loaded()
  if history_cache ~= nil then
    return
  end
  history_cache = {}
  local raw = CsLocalSaveDataUtil.GetString(HISTORY_STORAGE_KEY, "")
  if raw and raw ~= "" then
    for w in string.gmatch(raw, "[^|]+") do
      if #history_cache < MAX_HISTORY then
        table.insert(history_cache, w)
      end
    end
  end
end

local function _save_history()
  CsLocalSaveDataUtil.SetString(HISTORY_STORAGE_KEY, table.concat(history_cache, "|"))
end

function M.get_search_history()
  _ensure_history_loaded()
  return history_cache
end

function M.add_search_history(keyword)
  if not keyword or keyword == "" then
    return
  end
  _ensure_history_loaded()
  for i, v in ipairs(history_cache) do
    if v == keyword then
      table.remove(history_cache, i)
      break
    end
  end
  table.insert(history_cache, 1, keyword)
  while #history_cache > MAX_HISTORY do
    table.remove(history_cache)
  end
  _save_history()
end

function M.clear_search_history()
  _ensure_history_loaded()
  for i = #history_cache, 1, -1 do
    history_cache[i] = nil
  end
  _save_history()
end

return M
