local NetHandler = G.Class("NetHandler")
local net_state = NetState
local net_manager = NetManager

function NetHandler:__ctor()
  self.net_handler = CSNetHandler.instance
  self._has_connected = false
end

function NetHandler:send_msg(msg)
  self.net_handler:Send(msg, ApplicationUtil.IsDebugMode())
end

function NetHandler:create_cmd(msg_type)
  if msg_type == nil then
    Logger.LogError("Proto type is nil")
    return
  end
  local msg = msg_type()
  return msg
end

function NetHandler:register_cmd_handler(msg_type, func)
  if msg_type == nil then
    Logger.LogError("Proto type is nil")
    return
  end
  
  local function receive_func(msg)
    func(msg)
  end
  
  self.net_handler:RegisterLuaCmdHandler(self.net_handler:GetCmdId(typeof(msg_type)), receive_func)
end

function NetHandler:unregister_cmd_handler(msg_type)
  if msg_type == nil then
    Logger.LogError("Proto type is nil")
    return
  end
  self.net_handler:UnregisterLuaCmdHandler(self.net_handler:GetCmdId(typeof(msg_type)))
end

function NetHandler:send_data(msg_type, data, print_log)
  if msg_type == nil then
    Logger.LogError("Proto type is nil")
    return
  end
  local msg = msg_type()
  table.merge(msg, data)
  self.net_handler:Send(msg, print_log or false)
end

function NetHandler:is_connected()
  return net_manager.mNetState == net_state.Connected
end

function NetHandler:destroy()
end

return NetHandler
