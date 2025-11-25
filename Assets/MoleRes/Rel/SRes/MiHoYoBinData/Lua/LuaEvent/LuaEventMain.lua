lua_event_module = lua_event_module or {}

function lua_event_module:add_listener(main_id, callback)
  if main_id == nil then
    Logger.LogError("main_id is nil !!!!  pos = add_listener")
    return
  end
  if is_null(callback) then
    Logger.LogError("callback为空!!! mainId = " .. main_id)
    return
  end
  self._listeners[main_id] = {
    is_func = true,
    func_data = lua_event_module:_init_func_data(callback)
  }
end

function lua_event_module:add_sub_listener(main_id, sub_id, callback)
  if main_id == nil then
    Logger.LogError("main_id is nil !!!!  pos = add_sub_listener")
    return false
  end
  if is_null(callback) then
    Logger.LogError("callback为空!!! mainId = " .. main_id)
    return false
  end
  if sub_id == nil then
    lua_event_module:add_listener(main_id, callback)
    return true
  end
  if self._listeners[main_id] == nil then
    self._listeners[main_id] = {
      is_func = false,
      func_datas = {},
      len = 0
    }
  end
  if self._listeners[main_id].is_func then
    Logger.LogWarning("该事件已注册!!! main_id = " .. main_id)
    return false
  end
  if self._listeners[main_id].func_datas[sub_id] ~= nil then
    Logger.LogWarning("注册了相同SubID的Event!!!  SubId = " .. sub_id)
    return false
  end
  self._listeners[main_id].func_datas[sub_id] = lua_event_module:_init_func_data(callback)
  self._listeners[main_id].len = self._listeners[main_id].len + 1
  return true
end

function lua_event_module:remove_listener(main_id, sub_id)
  if main_id == nil then
    Logger.LogError("main_id is nil !!!!  pos = remove_listener")
    return
  end
  local sub_listener = self._listeners[main_id]
  if sub_listener == nil then
    Logger.LogError("注销了不存在的Event!!!  mainId = " .. main_id)
    return
  end
  if sub_listener.is_func then
    self._listeners[main_id] = nil
    return
  end
  if sub_id == nil then
    Logger.LogError("subID is nil!!! ")
    return
  end
  if sub_listener.len <= 0 then
    Logger.LogError("注销了不存在的事件!!!  mainId = " .. main_id .. "subId = " .. sub_id)
    return
  end
  if sub_listener.func_datas[sub_id] == nil then
    Logger.LogError("事件已被注销!!!  mainId = " .. main_id .. "subId = " .. sub_id)
    return
  end
  sub_listener.func_datas[sub_id] = nil
  sub_listener.len = sub_listener.len - 1
  if sub_listener.len <= 0 then
    sub_listener = nil
  end
  self._listeners[main_id] = sub_listener
end

function lua_event_module:check_event_exist(main_id)
  if self._listeners[main_id] == nil then
    return false
  else
    return true
  end
end

function lua_event_module:close_listener(main_id, sub_id)
  lua_event_module:_set_listener_state(main_id, sub_id, false)
end

function lua_event_module:open_listener(main_id, sub_id)
  lua_event_module:_set_listener_state(main_id, sub_id, true)
end

function lua_event_module:send_event(main_id, p1, ...)
  if main_id == nil then
    Logger.LogError("main_id is nil !!!! pos = send_event")
    return
  end
  local sub_listener = self._listeners[main_id]
  if sub_listener == nil then
    return
  end
  if sub_listener.is_func and sub_listener.func_data then
    lua_event_module:_call_func(sub_listener.func_data, p1, ...)
    return
  end
  if sub_listener.len > 0 then
    for _, func_data in pairs(sub_listener.func_datas) do
      lua_event_module:_call_func(func_data, p1, ...)
    end
  end
end

function lua_event_module:send_sub_event(main_id, sub_id, p1, ...)
  if main_id == nil then
    Logger.LogError("main_id is nil !!!! pos = send_event")
    return
  end
  local sub_listener = self._listeners[main_id]
  if sub_listener == nil then
    return
  end
  if sub_listener.is_func and sub_listener.func_data then
    lua_event_module:_call_func(sub_listener.func_data, p1, ...)
    return
  end
  if sub_id == nil then
    Logger.LogError("subID is nil!!! ")
    return
  end
  if sub_listener.len > 0 and sub_listener.func_datas[sub_id] then
    lua_event_module:_call_func(sub_listener.func_datas[sub_id], p1, ...)
  end
end

function lua_event_module:_init_func_data(callback)
  return {state = true, callback = callback}
end

function lua_event_module:_call_func(func_data, p1, ...)
  if func_data and func_data.state then
    func_data.callback(p1, ...)
  end
end

function lua_event_module:_set_listener_state(main_id, sub_id, state)
  if main_id == nil then
    Logger.LogError("main_id is nil !!!!  pos = _set_listener_state")
    return
  end
  local sub_listener = self._listeners[main_id]
  if sub_listener == nil then
    Logger.LogError("禁止了不存在的Event!!!  mainId = " .. main_id)
    return
  end
  if sub_listener.is_func then
    sub_listener.func_data.state = state or false
    self._listeners[main_id] = sub_listener
    return
  end
  if sub_id == nil then
    if sub_listener.len <= 0 then
      Logger.LogError("注销了不存在的事件!!!  mainId = " .. main_id .. "subId = " .. sub_id)
      return
    end
    for key, _ in pairs(sub_listener.func_datas) do
      sub_listener[key].state = state or false
    end
    self._listeners[main_id] = sub_listener
    return
  end
  if sub_listener.func_datas[sub_id] == nil then
    Logger.LogError("事件已被注销!!!  mainId = " .. main_id .. "subId = " .. sub_id)
    return
  end
  sub_listener.func_datas[sub_id].state = state or false
  self._listeners[main_id] = sub_listener
end

return lua_event_module
