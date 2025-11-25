cfg_call_lua_func_module = cfg_call_lua_func_module or {}
cfg_call_lua_func_module._cname = "cfg_call_lua_func_module"
local func_name = {
  CutScene = "CutScene",
  CloseUI = "CloseUI",
  ClickScriptedOptionButton = "ClickScriptedOptionButton",
  SelectorChatDialog = "SelectorChatDialog",
  OpenUI = "OpenUI"
}
local open_ui_type = {
  NpcChatPage = "NpcChatPage"
}
cfg_call_lua_func_module.call_fun_type = {
  Error = -1,
  None = 0,
  CutScene = 1,
  CloseUI = 2,
  CloseSelfUI = 3,
  ClickScriptedOptionButton = 4
}

function cfg_call_lua_func_module:init()
  self._events = nil
  self:_add_event()
end

function cfg_call_lua_func_module:_add_event()
  CS.UnityEngine.Debug.Log("CfgCallLuaFunc _add_event 1")
  self:_remove_event()
  self._events = {}
  self._events[EventID.CfgCallLua] = pack(self, cfg_call_lua_func_module._handle_cfg_call_lua)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
    CS.UnityEngine.Debug.Log("CfgCallLuaFunc _add_event " .. tostring(event_id) .. tostring(fun))
  end
end

function cfg_call_lua_func_module:_remove_event()
  CS.UnityEngine.Debug.Log("CfgCallLuaFunc clear1")
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
    CS.UnityEngine.Debug.Log("CfgCallLuaFunc _remove_event " .. tostring(event_id) .. tostring(fun))
  end
  self._events = nil
end

function cfg_call_lua_func_module:close()
  self:_remove_event()
end

function cfg_call_lua_func_module:_handle_cfg_call_lua(str)
  if type(str) == "string" then
    self:call_lua_by_str(str)
  end
end

function cfg_call_lua_func_module:call_lua_by_str(str)
  if not string.is_valid(str) then
    Logger.LogError("无法通过字符串调用Lua, 字符串为�?!!!")
    return cfg_call_lua_func_module.call_fun_type.Error
  end
  local cmd_str_arr = self:_get_cmd_str_arr(str)
  local ret_type = cfg_call_lua_func_module.call_fun_type.Error
  local ret_value_1
  local fun_type = self:_get_fun_type(cmd_str_arr)
  if cmd_str_arr and fun_type then
    if fun_type == func_name.CutScene then
      if cmd_str_arr[3] == nil or cmd_str_arr[3] == "0" then
        return ret_type
      end
      ret_type = cfg_call_lua_func_module.call_fun_type.CutScene
      level_module:cut_scene(tonumber(cmd_str_arr[3]))
    elseif fun_type == func_name.CloseUI then
      if cmd_str_arr[3] == nil or cmd_str_arr[3] == "0" then
        ret_type = cfg_call_lua_func_module.call_fun_type.CloseSelfUI
        return ret_type
      end
      ret_type = cfg_call_lua_func_module.call_fun_type.CloseUI
    elseif fun_type == func_name.ClickScriptedOptionButton then
      ret_type = cfg_call_lua_func_module.call_fun_type.CloseSelfUI
      local index = tonumber(cmd_str_arr[3])
      if index == nil then
        return ret_type
      end
      ret_type = cfg_call_lua_func_module.call_fun_type.ClickScriptedOptionButton
      EventCenter.Broadcast(EventID.OnClickScriptedOptionButton, index)
    elseif fun_type == func_name.OpenUI and cmd_str_arr[3] == open_ui_type.NpcChatPage then
      npc_module:open_npc_chat_page()
    end
  end
  return ret_type, ret_value_1
end

function cfg_call_lua_func_module:_get_cmd_str_arr(str)
  local cmd_str = string.gsub(str, "%p+", ",")
  local cmd_str_arr = lua_str_split(cmd_str, ",")
  return cmd_str_arr
end

function cfg_call_lua_func_module:_get_fun_type(cmd_str_arr)
  local fun_type
  if cmd_str_arr then
    if not string.is_valid(cmd_str_arr[1]) then
      Logger.LogError("无法通过字符串调用Lua")
    end
    fun_type = cmd_str_arr[2]
  end
  return fun_type
end

function cfg_call_lua_func_module:cmd_is_selected_chat(cmd)
  local cmd_str_arr = cfg_call_lua_func_module:_get_cmd_str_arr(cmd)
  return cmd_str_arr and cfg_call_lua_func_module:_get_fun_type(cmd_str_arr) == func_name.SelectorChatDialog
end

function cfg_call_lua_func_module:cmd_is_open_ui(cmd)
  local cmd_str_arr = cfg_call_lua_func_module:_get_cmd_str_arr(cmd)
  return cmd_str_arr and cfg_call_lua_func_module:_get_fun_type(cmd_str_arr) == func_name.OpenUI
end

return cfg_call_lua_func_module or {}
