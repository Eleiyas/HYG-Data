mails_module = mails_module or {}
mails_module._cname = "mails_module"
lua_module_mgr:require("UI/Mail/MailNet")
lua_module_mgr:require("UI/Mail/MailData")

function mails_module:init()
  mails_module:reset_server_data()
  mails_module:register_cmd_handler()
  mails_module:add_event()
end

function mails_module:_init_fetch_all_mails()
  self:fetch_all_mails_req()
end

function mails_module:close()
  mails_module:un_register_cmd_handler()
  mails_module:remove_event()
end

function mails_module:add_event()
  mails_module:remove_event()
  self._events = {}
  self._events[EventID.LuaOpenMainPanel] = pack(self, self._init_fetch_all_mails)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function mails_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function mails_module:reset_server_data()
  self._mail_datas = {}
end

function mails_module:clear_on_disconnect()
  mails_module:reset_server_data()
end

return mails_module or {}
