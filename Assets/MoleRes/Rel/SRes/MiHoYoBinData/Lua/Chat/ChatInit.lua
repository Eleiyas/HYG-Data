chat_module = chat_module or {}
chat_module._cname = "chat_module"
lua_module_mgr:require("Chat/ChatMain")
lua_module_mgr:require("Chat/ChatCommon")
lua_module_mgr:require("Chat/ChatCfg")
lua_module_mgr:require("Chat/ChatNet")
lua_module_mgr:require("Chat/ChatData")
lua_module_mgr:require("Chat/ChatUI")

function chat_module:init()
  self._events = nil
  chat_module:add_event()
  chat_module:reset_server_data()
  chat_module:register_cmd_handler()
  chat_module:_init_cfg()
end

function chat_module:close()
  if self._tbl_all_npc_chat_call_back_guid ~= nil then
    for k, _ in pairs(self._tbl_all_npc_chat_call_back_guid) do
      CsNLPModuleUtil.ClearCb(k)
    end
    self._tbl_all_npc_chat_call_back_guid = nil
  end
  chat_module:remove_event()
  chat_module:un_register_cmd_handler()
end

function chat_module:reset_server_data()
  self._public_chat_tbl = {}
  self._chat_tbl = {}
  self._read_sequence_tbl = {}
  self._tbl_all_npc_chat = {}
  self._tbl_all_npc_chat_call_back_guid = {}
  self._cur_chat_uid = -1
  self._sys_hint_queue = nil
  self._is_show_sys_tips = false
end

function chat_module:clear_on_disconnect()
  chat_module:reset_server_data()
end

return chat_module
