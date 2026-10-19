local M = {}
M._cache = {}

local function _make_key(prefab_path, lua_cls)
  if not lua_cls or lua_cls == "" then
    return prefab_path
  end
  return prefab_path .. "|" .. lua_cls
end

function M:get(prefab_path, lua_cls)
  local key = _make_key(prefab_path, lua_cls)
  local pool = self._cache[key]
  if pool and 0 < #pool then
    while 0 < #pool do
      local inst = table.remove(pool)
      if inst and not is_null(inst.game_obj) and not is_null(inst.trans) then
        return inst, true
      end
    end
  end
  return nil, false
end

function M:recycle(prefab_path, lua_cls, element)
  if element == nil or is_null(element.game_obj) or is_null(element.trans) then
    return
  end
  local key = _make_key(prefab_path, lua_cls)
  if not self._cache[key] then
    self._cache[key] = {}
  end
  if element.is_active then
    element:set_active(false)
  end
  element.ui_ctrl_mode_active = false
  UIUtil.set_active(element.game_obj, false)
  table.insert(self._cache[key], element)
end

function M:clear()
  for _, pool in pairs(self._cache) do
    for _, inst in ipairs(pool) do
      if inst.on_destroy then
        inst:on_destroy()
      end
      if not_null(inst.game_obj) then
        CS.UnityEngine.Object.Destroy(inst.game_obj)
      end
    end
  end
  self._cache = {}
end

return M
