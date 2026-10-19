local M = {}
local MARKET_CACHE_DURATION = 0.2
local market_cache = {}

local function get_cache_key(is_self)
  return is_self and 1 or 0
end

local function get_cache_time()
  if Time and Time.realtimeSinceStartup then
    return Time.realtimeSinceStartup
  end
  return os.clock()
end

local function build_market_cache(is_self)
  local snapshot = CsGeLianMarketModuleUtil.GetMarketSnapshot(is_self)
  local entries = list_to_table(snapshot and snapshot.Entries) or {}
  table.sort(entries, function(a, b)
    return a.Tag < b.Tag
  end)
  return {
    snapshot = snapshot,
    entries = entries,
    entry_map = M.build_entry_map(entries),
    timestamp = get_cache_time()
  }
end

function M.invalidate_market_cache(is_self)
  if is_self == nil then
    market_cache = {}
    return
  end
  market_cache[get_cache_key(is_self)] = nil
end

function M.get_market_cache(is_self, force_refresh)
  local cache_key = get_cache_key(is_self)
  local cache = market_cache[cache_key]
  local now = get_cache_time()
  if not (not force_refresh and cache) or now - (cache.timestamp or 0) > MARKET_CACHE_DURATION then
    cache = build_market_cache(is_self)
    market_cache[cache_key] = cache
  end
  return cache
end

function M.get_market_snapshot(is_self)
  return M.get_market_cache(is_self).snapshot
end

function M.get_sorted_entries(is_self)
  local cache = M.get_market_cache(is_self)
  return cache.snapshot, cache.entries
end

function M.get_sorted_entries_by_uid(uid)
  local is_self = uid == player_module:get_player_uid()
  local cache = M.get_market_cache(is_self)
  return cache.snapshot, cache.entries, is_self, cache.entry_map
end

function M.build_entry_map(entries)
  local entry_map = {}
  for _, entry in ipairs(entries or {}) do
    entry_map[entry.Tag] = entry
  end
  return entry_map
end

function M.get_entry_by_tag(is_self, tag)
  local cache = M.get_market_cache(is_self)
  return cache.entry_map and cache.entry_map[tag] or nil
end

function M.build_rank_view_data(entries)
  local total = 0
  local rank_entries = {}
  for _, entry in ipairs(entries or {}) do
    total = total + (entry.ProgressCount or 0)
    rank_entries[#rank_entries + 1] = entry
  end
  table.sort(rank_entries, function(a, b)
    return (a.ProgressCount or 0) > (b.ProgressCount or 0)
  end)
  local rank_by_tag = {}
  for index, entry in ipairs(rank_entries) do
    rank_by_tag[entry.Tag] = index
  end
  local percentages = {}
  local remaining = 100
  for index, entry in ipairs(entries or {}) do
    local count = entry.ProgressCount or 0
    if index == #(entries or {}) then
      percentages[entry.Tag] = remaining
    else
      local percent = 0 < total and math.floor(count * 100 / total + 0.5) or 0
      percentages[entry.Tag] = percent
      remaining = remaining - percent
    end
  end
  return {
    total = total,
    rank_by_tag = rank_by_tag,
    percentages = percentages
  }
end

return M
