local M = npc_cloth_module
lua_module_mgr:require("UI/NpcCloth/NpcClothHelper")
M._selected_npc_by_shape = M._selected_npc_by_shape or {}
M._preset_by_npc = M._preset_by_npc or {}

local function normalize_npc_id(npc_id)
  return tonumber(npc_id) or 0
end

local function normalize_slot_key(slot_key)
  local numeric_slot_key = tonumber(slot_key)
  if numeric_slot_key ~= nil then
    return numeric_slot_key
  end
  return slot_key
end

local function copy_preset_item(item_data, slot_key)
  if type(item_data) ~= "table" then
    return nil
  end
  local result = {}
  for key, value in pairs(item_data) do
    local value_type = type(value)
    if value_type ~= "table" and value_type ~= "userdata" and value_type ~= "function" and value_type ~= "thread" then
      result[key] = value
    end
  end
  result.item_id = tonumber(result.item_id or result.ItemID or result.id or result.ConfigId or result.ConfigID or result.ConFigID or 0) or 0
  result.guid = tonumber(result.guid or result.GUID or result.Guid or 0) or 0
  result.make_guid = tonumber(result.make_guid or result.MakeGUID or result.MakeGuid or 0) or 0
  result.count = tonumber(result.count or result.Count or result.ItemCount or 0) or 0
  result.source_type = result.source_type or result.sourceType or 0
  result.source_npc_id = tonumber(result.source_npc_id or result.sourceNpcId or 0) or 0
  result.slot_key = normalize_slot_key(slot_key or result.slot_key or result.slotKey)
  result.key = result.key or result.Key
  return result
end

local function copy_preset_map(source)
  local result = {}
  for slot_key, item_data in pairs(source or {}) do
    local normalized_slot_key = normalize_slot_key(slot_key)
    local item_copy = copy_preset_item(item_data, normalized_slot_key)
    if item_copy ~= nil then
      result[normalized_slot_key] = item_copy
    end
  end
  return result
end

function M.get_selected_npc_by_shape()
  local result = {}
  for shape, npc_id in pairs(M._selected_npc_by_shape or {}) do
    result[shape] = npc_id
  end
  return result
end

function M.set_selected_npc_by_shape(map)
  M._selected_npc_by_shape = {}
  for shape, npc_id in pairs(map or {}) do
    M._selected_npc_by_shape[shape] = npc_id
  end
end

function M.get_selected_npc(shape)
  shape = tonumber(shape) or 0
  return (M._selected_npc_by_shape or {})[shape] or 0
end

function M.set_selected_npc(shape, npc_id)
  shape = tonumber(shape) or 0
  if shape <= 0 then
    return
  end
  M._selected_npc_by_shape = M._selected_npc_by_shape or {}
  M._selected_npc_by_shape[shape] = tonumber(npc_id) or 0
end

function M.is_empty()
  return next(M._selected_npc_by_shape or {}) == nil
end

function M.get_preset_by_npc(npc_id)
  npc_id = normalize_npc_id(npc_id)
  if npc_id <= 0 then
    return {}
  end
  return copy_preset_map((M._preset_by_npc or {})[npc_id])
end

function M.set_preset_by_npc(npc_id, preset_map)
  npc_id = normalize_npc_id(npc_id)
  if npc_id <= 0 then
    return
  end
  M._preset_by_npc = M._preset_by_npc or {}
  M._preset_by_npc[npc_id] = copy_preset_map(preset_map)
end

function M.get_preset_item_by_slot(npc_id, slot_key)
  npc_id = normalize_npc_id(npc_id)
  if npc_id <= 0 then
    return nil
  end
  slot_key = normalize_slot_key(slot_key)
  local preset_map = (M._preset_by_npc or {})[npc_id]
  if type(preset_map) ~= "table" then
    return nil
  end
  return copy_preset_item(preset_map[slot_key], slot_key)
end

function M.clear_invalid_preset_by_npc(npc_id, validator)
  npc_id = normalize_npc_id(npc_id)
  if npc_id <= 0 or type(validator) ~= "function" then
    return false
  end
  local preset_map = (M._preset_by_npc or {})[npc_id]
  if type(preset_map) ~= "table" then
    return false
  end
  local has_changed = false
  for slot_key, item_data in pairs(preset_map) do
    if validator(item_data) == false then
      preset_map[slot_key] = nil
      has_changed = true
    end
  end
  if has_changed and next(preset_map) == nil then
    M._preset_by_npc[npc_id] = nil
  end
  return has_changed
end

function M.clear_data()
  M._selected_npc_by_shape = {}
  M._preset_by_npc = {}
end

return M
