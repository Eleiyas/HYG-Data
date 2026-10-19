function table.serialize(obj)
  local lua = ""
  
  local t = type(obj)
  if t == "number" then
    lua = lua .. obj
  elseif t == "boolean" then
    lua = lua .. tostring(obj)
  elseif t == "string" then
    lua = lua .. string.format("%q", obj)
  elseif t == "table" then
    lua = lua .. "{\n"
    for k, v in pairs(obj) do
      lua = lua .. "[" .. table.serialize(k) .. "]=" .. table.serialize(v) .. ",\n"
    end
    local metatable = getmetatable(obj)
    if metatable ~= nil and type(metatable.__index) == "table" then
      for k, v in pairs(metatable.__index) do
        lua = lua .. "[" .. table.serialize(k) .. "]=" .. table.serialize(v) .. ",\n"
      end
    end
    lua = lua .. "}"
  elseif t == "nil" then
    return nil
  else
    return "-nil-"
  end
  return lua
end

function table.print(tbl)
  local msg = table.serialize(tbl)
  print(msg)
end

function table.find(tb, func)
  if tb == nil or func == nil then
    return nil, 0
  end
  local index = 0
  for key, value in pairs(tb) do
    if value ~= nil then
      index = index + 1
      if func(value) then
        return value, index
      end
    end
  end
  return nil, 0
end

function table.findlast(tb, func)
  if tb == nil or func == nil then
    return nil, 0
  end
  local ret
  local index = 0
  for key, value in pairs(tb) do
    if value ~= nil then
      index = index + 1
      if func(value) then
        ret = value
      end
    end
  end
  if ret == nil then
    index = 0
  end
  return ret, index
end

function table.removewhere(tb, func)
  if tb == nil or func == nil then
    return
  end
  for i = #tb, 1, -1 do
    local t = tb[i]
    if func(t) then
      table.remove(tb, i)
    end
  end
end

function table.select(tb, func)
  if tb == nil or func == nil then
    return nil
  end
  local list = {}
  for key, value in pairs(tb) do
    if value ~= nil then
      table.insert(list, func(value))
    end
  end
  return list
end

function table.exists(tb, func)
  if tb == nil or func == nil then
    return false
  end
  for key, value in pairs(tb) do
    if value ~= nil and func(value) then
      return true
    end
  end
  return false
end

function table.contains(tb, item)
  if tb == nil or item == nil then
    return false
  end
  for key, value in pairs(tb) do
    if value ~= nil and value == item then
      return true
    end
  end
  return false
end

function table.clear(tb)
  if tb == nil then
    return
  end
  for k in pairs(tb) do
    tb[k] = nil
  end
end

function table.clone(org)
  local function copy(org, res)
    for k, v in pairs(org) do
      if type(v) ~= "table" then
        res[k] = v
      else
        res[k] = {}
        copy(v, res[k])
      end
    end
  end
  
  local res = {}
  copy(org, res)
  return res
end

function table.merge(tDest, tSrc)
  for k, v in pairs(tSrc) do
    tDest[k] = v
  end
end

function table.count(hashtable)
  if not hashtable then
    return 0
  end
  local count = 0
  for _, _ in pairs(hashtable) do
    count = count + 1
  end
  return count
end

function table.shallow_copy(orig)
  local copy = {}
  for k, v in pairs(orig) do
    copy[k] = v
  end
  return copy
end

function table.next(tbl)
  if tbl == nil then
    return nil
  end
  return next(tbl)
end

function table.is_null(tbl)
  return table.next(tbl) == nil
end

function table.clear_table(tbl, action)
  if table.is_null(tbl) then
    return
  end
  if is_null(action) then
    table.clear(tbl)
    return
  end
  local cur_value = next(tbl)
  while cur_value ~= nil do
    action(cur_value)
    cur_value = next(tbl)
  end
  tbl = {}
end
