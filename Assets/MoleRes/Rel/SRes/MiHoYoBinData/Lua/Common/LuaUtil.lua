function _ENV:pack(func, ...)
  assert(self == nil or type(self) == "table")
  
  assert(func ~= nil and type(func) == "function")
  return function(...)
    func(self, ...)
  end
end

function is_null(unity_object)
  if unity_object == nil then
    return true
  end
  if type(unity_object) == "userdata" and unity_object.IsNull ~= nil then
    return unity_object:IsNull()
  end
  return false
end

function not_null(unity_object)
  return is_null(unity_object) == false
end

function array_to_table(array)
  if array == nil then
    return nil
  end
  if type(array) == "table" then
    return array
  end
  local tbl = {}
  local len = array.Count or array.Length or 1
  for i = 0, len - 1 do
    table.insert(tbl, array[i])
  end
  return tbl
end

function list_to_table(cs_list)
  if is_null(cs_list) then
    return {}
  end
  if type(cs_list) == "table" then
    return cs_list
  end
  if cs_list.Length then
    return array_to_table(cs_list)
  end
  local list = {}
  if cs_list then
    local index = 1
    local iter = cs_list:GetEnumerator()
    while iter:MoveNext() do
      local v = iter.Current
      list[index] = v
      index = index + 1
    end
  else
    Logger.LogError("Error,CSharpList is null")
  end
  return list
end

function dic_to_list_table(cs_list)
  if type(cs_list) == "table" then
    return cs_list
  end
  local list = {}
  if cs_list then
    local index = 1
    local iter = cs_list:GetEnumerator()
    while iter:MoveNext() do
      local v = iter.Current
      list[index] = v.Value
      index = index + 1
    end
  else
    Logger.LogError("Error,CSharpList is null")
  end
  return list
end

function dic_key_to_list_table(cs_list)
  if type(cs_list) == "table" then
    return cs_list
  end
  local list = {}
  if cs_list then
    local index = 1
    local iter = cs_list:GetEnumerator()
    while iter:MoveNext() do
      local v = iter.Current
      list[index] = v.Key
      index = index + 1
    end
  else
    Logger.LogError("Error,CSharpList is null")
  end
  return list
end

function dic_to_table(cs_dic)
  if type(cs_dic) == "table" then
    return cs_dic
  end
  local dic = {}
  if cs_dic then
    local iter = cs_dic:GetEnumerator()
    while iter:MoveNext() do
      local k = iter.Current.Key
      local v = iter.Current.Value
      dic[k] = v
    end
  end
  return dic
end

function un_require(cname, cls_name)
  if type(cname) == "table" then
    for k, v in pairs(cname) do
      if package.loaded[v] then
        local cls = package.loaded[v]
        package.loaded[v] = close_tbl(package.loaded[v])
      end
    end
  elseif package.loaded[cname] then
    local cls = package.loaded[cname]
    package.loaded[cname] = close_tbl(package.loaded[cname])
    if cls_name == nil then
      cls_name = cls._cname
    end
  end
  if cls_name then
    _G[cls_name] = nil
  end
end

function lua_tbl_split(str, is_number, delimiter1, delimiter2)
  if str == nil or str == "" then
    return {}
  end
  delimiter1 = delimiter1 or "|"
  delimiter2 = delimiter2 or "^"
  local ret_tbl = {}
  local tbl = lua_str_split(str, delimiter1)
  for i, v in ipairs(tbl) do
    ret_tbl[i] = lua_str_split(v, delimiter2, is_number)
  end
  return ret_tbl
end

function lua_str_split(str, delimiter, is_number)
  if str == nil or str == "" or delimiter == nil then
    return {}
  end
  local special_delimiters = {
    "(",
    ")",
    ".",
    "%",
    "+",
    "-",
    "*",
    "?",
    "[",
    "^",
    "$"
  }
  local pattern
  for _, v in ipairs(special_delimiters) do
    if delimiter == v then
      pattern = "(.-)%" .. delimiter
      break
    end
  end
  pattern = pattern or "(.-)" .. delimiter
  local result = {}
  for match in (str .. delimiter):gmatch(pattern) do
    if is_number then
      table.insert(result, tonumber(match))
    else
      table.insert(result, match)
    end
  end
  return result
end

function hotfix(filename)
  local last_table
  if package.loaded[filename] then
    last_table = package.loaded[filename]
    package.loaded[filename] = nil
  else
    return
  end
  local is_ok, err_str = pcall(require, filename)
  if not is_ok then
    package.loaded[filename] = last_table
    return
  end
  last_table = package.loaded[filename]
  local new_module = _G.G[last_table.__cname]
  local is_ui = new_module ~= nil
  if new_module == nil then
    new_module = _G[last_table._cname]
  end
  if new_module then
    for k, v in pairs(new_module) do
      last_table[k] = v
    end
  end
  package.loaded[filename] = last_table
  if is_ui then
    UIManagerInstance:reload_windows_class(filename, last_table)
  end
end

function close_tbl(tbl)
  if type(tbl) == "table" then
    for k, v in pairs(tbl) do
      tbl[k] = close_tbl(tbl[k])
    end
  end
  return nil
end
