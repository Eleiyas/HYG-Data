local M = {}
local _enabled = false
local _class, _original_hotfix, _original_class_fn
local _saved_meta = {}
local _no_cache_meta = {}

local function find_upvalue(fn, target)
  if type(fn) ~= "function" then
    return nil
  end
  local i = 1
  while true do
    local name, value = debug.getupvalue(fn, i)
    if name == nil then
      return nil
    end
    if name == target then
      return value
    end
    i = i + 1
  end
end

local function resolve_class_table()
  if type(G) ~= "table" or type(G.Class) ~= "function" then
    return nil
  end
  local class_fn = find_upvalue(G.Class, "class")
  if class_fn == nil then
    return nil
  end
  return find_upvalue(class_fn, "_class")
end

local function get_no_cache_meta(super_class_type)
  local meta = _no_cache_meta[super_class_type]
  if meta == nil then
    meta = {
      __index = function(_, k)
        return _class[super_class_type][k]
      end
    }
    _no_cache_meta[super_class_type] = meta
  end
  return meta
end

local function patch_vtbl(class_type, vtbl)
  local super = class_type.super
  if super == nil then
    return
  end
  local super_vtbl = _class[super]
  if super_vtbl == nil then
    return
  end
  if _saved_meta[vtbl] == nil then
    _saved_meta[vtbl] = getmetatable(vtbl) or false
  end
  for k, v in pairs(vtbl) do
    if super_vtbl[k] == v then
      vtbl[k] = nil
    end
  end
  setmetatable(vtbl, get_no_cache_meta(super))
end

local function swap_class(old_class_type, new_class_type)
  local old_vtbl = _class[old_class_type]
  local new_vtbl = _class[new_class_type]
  if old_vtbl == nil or new_vtbl == nil then
    return false
  end
  for k in pairs(old_vtbl) do
    old_vtbl[k] = nil
  end
  for k, v in pairs(new_vtbl) do
    old_vtbl[k] = v
  end
  rawset(old_class_type, "__ctor", rawget(new_class_type, "__ctor"))
  rawset(old_class_type, "__delete", rawget(new_class_type, "__delete"))
  _class[new_class_type] = nil
  _saved_meta[new_vtbl] = nil
  return true
end

local function enhanced_hotfix(filename)
  local old = package.loaded[filename]
  if old == nil then
    return
  end
  if type(old) ~= "table" then
    return
  end
  local old_cname = old.__cname
  package.loaded[filename] = nil
  local is_ok, err_str = pcall(require, filename)
  if not is_ok then
    package.loaded[filename] = old
    Logger.LogError("[EditorHotReloadEnhance] hotfix failed: " .. tostring(err_str))
    return
  end
  local new = package.loaded[filename]
  if old_cname ~= nil and type(new) == "table" and new.__cname == old_cname and G[old_cname] == new then
    swap_class(old, new)
    G[old_cname] = old
    package.loaded[filename] = old
    UIManagerInstance:reload_windows_class(filename, old)
  else
    local new_module = old_cname ~= nil and _G.G[old_cname] or old._cname ~= nil and _G[old._cname]
    if type(new_module) == "table" then
      for k, v in pairs(new_module) do
        old[k] = v
      end
    else
      for k in pairs(old) do
        old[k] = nil
      end
      for k, v in pairs(new) do
        old[k] = v
      end
    end
    package.loaded[filename] = old
  end
  Logger.Log("[EditorHotReloadEnhance] hotfix success: " .. tostring(filename))
end

function M.enable()
  if _enabled then
    return
  end
  _class = resolve_class_table()
  if _class == nil then
    Logger.LogError("[EditorHotReloadEnhance] 无法通过反射获取 Class 的 _class 容器, 启用失败(Class.lua 结构可能已变更)")
    return
  end
  _enabled = true
  for class_type, vtbl in pairs(_class) do
    if type(class_type) == "table" and class_type.super then
      patch_vtbl(class_type, vtbl)
    end
  end
  _original_class_fn = G.Class
  
  function G.Class(name, super, namespace)
    local cls = _original_class_fn(name, super, namespace)
    local vtbl = _class[cls]
    if vtbl and cls.super then
      patch_vtbl(cls, vtbl)
    end
    return cls
  end
  
  _original_hotfix = _G.hotfix
  _G.hotfix = enhanced_hotfix
  Logger.Log("[EditorHotReloadEnhance] ENABLED - Lua加强热重载已开启")
end

function M.disable()
  if not _enabled then
    return
  end
  _enabled = false
  if _original_class_fn then
    G.Class = _original_class_fn
    _original_class_fn = nil
  end
  if _original_hotfix then
    _G.hotfix = _original_hotfix
    _original_hotfix = nil
  end
  for vtbl, meta in pairs(_saved_meta) do
    setmetatable(vtbl, meta or nil)
  end
  _saved_meta = {}
  _no_cache_meta = {}
  Logger.Log("[EditorHotReloadEnhance] DISABLED - 已恢复原始热重载")
end

function M.is_enabled()
  return _enabled
end

function M.try_auto_enable()
  if not ApplicationUtil.IsUnityEditor() then
    return
  end
  local is_ok, on = pcall(function()
    return CS.UnityEngine.PlayerPrefs.GetInt("enhanced_hotreload", 0) == 1
  end)
  if is_ok and on then
    M.enable()
  end
end

return M
