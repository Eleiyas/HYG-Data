spring_festival_exchange_module = spring_festival_exchange_module or {}
local M = spring_festival_exchange_module
local FUKUBAG_PER_TOKEN_PLACEHOLDER = 1
local EMPTY_LIST = {}
local FUKUBAG_CFG_ROW_ID = 1
local EXCHANGE_INTRODUCTION_ID = 26
local COMBINE_INTRODUCTION_ID = 28
local FUKUBAG_PER_COMBINE = 4
M.EXCHANGE_INTRODUCTION_ID = EXCHANGE_INTRODUCTION_ID
M.COMBINE_INTRODUCTION_ID = COMBINE_INTRODUCTION_ID
M._fukubag_ids_cache = nil
M._token_item_id_cache = nil
M._tassel_pool_id_cache = nil
M._min_tassel_per_exchange_cache = nil

function M:_init_data()
  self._fukubag_ids_cache = nil
  self._token_item_id_cache = nil
  self._tassel_pool_id_cache = nil
  self._min_tassel_per_exchange_cache = nil
end

local function _get_cfg_row()
  local fuku_cfg_type = not BFukuBagCfg and CS and CS.miHoYo and CS.miHoYo.HYG and CS.miHoYo.HYG.ExcelData and CS.miHoYo.HYG.ExcelData.BFukuBagCfg
  if fuku_cfg_type == nil then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(fuku_cfg_type), FUKUBAG_CFG_ROW_ID)
end

function M:get_fukubag_ids()
  if self._fukubag_ids_cache ~= nil then
    return self._fukubag_ids_cache
  end
  local row = _get_cfg_row()
  if row == nil then
    return EMPTY_LIST
  end
  local raw = row.fukubagid or ""
  local list = {}
  for piece in string.gmatch(raw, "([^,%s]+)") do
    local id = tonumber(piece)
    if id ~= nil then
      table.insert(list, id)
    end
  end
  self._fukubag_ids_cache = list
  self._token_item_id_cache = row.tasselid or 0
  return list
end

function M:get_token_item_id()
  if self._token_item_id_cache ~= nil then
    return self._token_item_id_cache
  end
  local row = _get_cfg_row()
  if row == nil then
    return 0
  end
  self._token_item_id_cache = row.tasselid or 0
  return self._token_item_id_cache
end

function M:get_token_icon_path()
  local token_item_id = self:get_token_item_id() or 0
  if token_item_id <= 0 then
    return ""
  end
  return item_module:get_item_icon(token_item_id) or ""
end

function M:get_token_big_icon_path()
  local token_item_id = self:get_token_item_id() or 0
  if token_item_id <= 0 then
    return ""
  end
  return item_module:get_item_big_icon(token_item_id) or ""
end

function M:get_tassel_pool_id()
  if self._tassel_pool_id_cache ~= nil then
    return self._tassel_pool_id_cache
  end
  local row = _get_cfg_row()
  if row == nil then
    return 0
  end
  self._tassel_pool_id_cache = row.fukubagtotassel or 0
  return self._tassel_pool_id_cache
end

function M:get_fukubag_stock(item_id)
  if item_id == nil or item_id == 0 then
    return 0
  end
  return CsPacketModuleUtil.GetItemNum(item_id) or 0
end

function M:calc_max_exchangeable()
  local ids = self:get_fukubag_ids()
  if #ids == 0 then
    return 0
  end
  local min_stock
  for _, item_id in ipairs(ids) do
    local stock = self:get_fukubag_stock(item_id)
    if min_stock == nil or min_stock > stock then
      min_stock = stock
    end
  end
  return math.floor((min_stock or 0) / FUKUBAG_PER_TOKEN_PLACEHOLDER)
end

function M:get_required_per_fukubag(cur)
  cur = tonumber(cur) or 0
  if cur <= 0 then
    return 0
  end
  return cur * FUKUBAG_PER_TOKEN_PLACEHOLDER
end

function M:get_min_tassel_per_exchange()
  if self._min_tassel_per_exchange_cache ~= nil then
    return self._min_tassel_per_exchange_cache
  end
  local pool_id = self:get_tassel_pool_id()
  if pool_id == nil or pool_id == 0 then
    return 0
  end
  local pool_cfg_type = not BRandomPoolCfg and CS and CS.miHoYo and CS.miHoYo.HYG and CS.miHoYo.HYG.ExcelData and CS.miHoYo.HYG.ExcelData.BRandomPoolCfg
  if pool_cfg_type == nil then
    return 0
  end
  local rows = ExcelDataUtil.get_value(typeof(pool_cfg_type), pool_id)
  if rows == nil then
    return 0
  end
  for _, row in ipairs(rows) do
    if (row.weight or 0) == 0 then
      self._min_tassel_per_exchange_cache = row.num or 0
      return self._min_tassel_per_exchange_cache
    end
  end
  return 0
end

function M:calc_least_token(cur)
  cur = tonumber(cur) or 0
  if cur <= 0 then
    return 0
  end
  return cur * self:get_min_tassel_per_exchange()
end

function M:get_fukubag_per_combine()
  return FUKUBAG_PER_COMBINE
end

function M:get_other_fukubag_id_list(exclude_id, reserved_per_item)
  local ids = self:get_fukubag_ids()
  local reserved = math.max(0, tonumber(reserved_per_item) or 0)
  local entries = {}
  for _, id in ipairs(ids) do
    if id ~= exclude_id then
      entries[#entries + 1] = {
        id = id,
        is_empty = 0 >= math.max(0, self:get_fukubag_stock(id) - reserved)
      }
    end
  end
  table.sort(entries, function(lhs, rhs)
    if lhs.is_empty ~= rhs.is_empty then
      return not lhs.is_empty
    end
    return lhs.id < rhs.id
  end)
  local result = {}
  for i = 1, #entries do
    result[i] = entries[i].id
  end
  return result
end

function M:can_combine_for(exclude_id)
  local ids = self:get_fukubag_ids()
  local sum = 0
  for _, id in ipairs(ids) do
    if id ~= exclude_id then
      sum = sum + self:get_fukubag_stock(id)
      if sum >= FUKUBAG_PER_COMBINE then
        return true
      end
    end
  end
  return false
end

return M
