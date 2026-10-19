local HotProtoRegistry

local function ensure_hot_proto_registry()
  if HotProtoRegistry == nil then
    local ok, reg = pcall(function()
      return CS.HotProto.HotProtoRegistry
    end)
    if ok and reg then
      HotProtoRegistry = reg
    end
  end
  return HotProtoRegistry
end

local hot_proto_helper_methods = {}

function hot_proto_helper_methods:HasField(name)
  return self._accessor:HasField(name)
end

function hot_proto_helper_methods:GetOrCreateMessage(name)
  return hot_proto_wrap_accessor(self._accessor:GetOrCreateMessage(name))
end

function hot_proto_helper_methods:AddMessage(name)
  return hot_proto_wrap_accessor(self._accessor:AddMessage(name))
end

function hot_proto_helper_methods:GetRepeated(name)
  return self._accessor:GetRepeated(name)
end

function hot_proto_helper_methods:GetMap(name)
  return self._accessor:GetMap(name)
end

function hot_proto_helper_methods:SetMapValue(name, key, value)
  value = type(value) == "table" and rawget(value, "_accessor") or value
  self._accessor:SetMapValue(name, key, value)
end

function hot_proto_helper_methods:AddRepeated(name, value)
  value = type(value) == "table" and rawget(value, "_accessor") or value
  self._accessor:AddRepeated(name, value)
end

function hot_proto_helper_methods:ClearField(name)
  self._accessor:ClearField(name)
end

local hot_proto_helper_metatable = {__index = hot_proto_helper_methods}
local hot_proto_accessor_metatable = {
  __index = function(obj, key)
    if key == "_accessor" then
      return rawget(obj, key)
    end
    if key == "_hotproto" then
      return rawget(obj, "_helper")
    end
    local accessor = rawget(obj, "_accessor")
    local value = accessor:Get(key)
    local child = accessor:GetMessage(key)
    if child ~= nil then
      return hot_proto_wrap_accessor(child)
    end
    return value
  end,
  __newindex = function(obj, key, value)
    value = type(value) == "table" and rawget(value, "_accessor") or value
    rawget(obj, "_accessor"):Set(key, value)
  end
}

function hot_proto_wrap_accessor(accessor)
  if accessor == nil then
    return nil
  end
  local helper = setmetatable({_accessor = accessor}, hot_proto_helper_metatable)
  return setmetatable({_accessor = accessor, _helper = helper}, hot_proto_accessor_metatable)
end

local hot_proto_metatable = {
  __call = function(cls)
    local reg = ensure_hot_proto_registry()
    if reg == nil then
      Logger.LogError("[HotProto] HotProtoRegistry not available")
      return nil
    end
    return hot_proto_wrap_accessor(reg.Create(rawget(cls, "_full_name")))
  end
}

function hot_proto_define(full_name, cmd_id)
  local t = {
    _full_name = full_name,
    _cmd_id = cmd_id or 0,
    _is_hot_proto = true
  }
  setmetatable(t, hot_proto_metatable)
  return t
end
