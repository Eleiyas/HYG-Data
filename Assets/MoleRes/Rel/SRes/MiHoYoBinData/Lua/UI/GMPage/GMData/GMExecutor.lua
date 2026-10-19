GMExecutor = GMExecutor or {}
require("UI/GMPage/GMData/GMCommand")
GMExecutor._lua_local = require("UI/GMPage/LuaLocalCmdHandler")

function GMExecutor:_ensure_init()
  if GMCommand._local_commands == nil then
    GMCommand:init()
  end
end

function GMExecutor:_del_local_data()
  for i = 1, 10 do
    CsLocalSaveDataUtil.DeleteKey(10000 + i)
  end
end

function GMExecutor:_handle_cmd(command, only_send_server)
  if string.is_valid(command) then
    local command_split = lua_str_split(command, " ")
    if 0 < #command_split then
      local command_name = command_split[1]
      local command_data = GMCommand:find_local_command(command_name)
      if command_data then
        if command_data.is_local and not only_send_server then
          if command_data.fun then
            local params = {}
            for i = 2, #command_split do
              if string.is_valid(command_split[i]) then
                table.insert(params, command_split[i])
              end
            end
            command_data.fun(params)
            return true, "client"
          end
        else
          local msg = CS.Proto.GMCmdReq()
          msg.CmdData = command
          NetHandlerIns:send_msg(msg)
          return true, "server"
        end
      end
    end
  end
  return false, nil
end

function GMExecutor:run_one(command, mode)
  if not string.is_valid(command) then
    return "[Error] empty command", false
  end
  mode = mode or "auto"
  local only_send_server = mode == "server"
  command = CsUIUtil.ReplaceGMSpecialStr(command)
  local handled, kind = self:_handle_cmd(command, only_send_server)
  if handled then
    return "[OK] " .. kind .. ": " .. command, false
  end
  if mode == "client" then
    return "[Error] not a client GM command: " .. command, false
  end
  if not only_send_server and self._lua_local.run_cmd(command) then
    return "[OK] lua-local: " .. command, false
  end
  local command_lower = string.lower(command)
  local msg = CS.Proto.GMCmdReq()
  msg.CmdData = command
  local show_send_tip = false
  if command_lower == "help" then
  elseif command_lower == "clearself" then
    self:_del_local_data()
  else
    show_send_tip = true
  end
  NetHandlerIns:send_msg(msg)
  return "[OK] server(fallback): " .. command, show_send_tip
end

function GMExecutor:run(command, mode)
  if not string.is_valid(command) then
    return "[Error] empty command"
  end
  self:_ensure_init()
  local results = {}
  local cmds = lua_str_split(command, ";", false)
  for _, one in ipairs(cmds) do
    if string.is_valid(one) then
      local result = self:run_one(one, mode)
      table.insert(results, result)
    end
  end
  if #results == 0 then
    return "[Error] empty command"
  end
  return table.concat(results, "\n")
end

function gm_run_command(cmd, mode)
  return GMExecutor:run(cmd, mode)
end

return GMExecutor
