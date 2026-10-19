exchange_cd_key_module = exchange_cd_key_module or {}
exchange_cd_key_module._cname = "exchange_cd_key_module"
lua_module_mgr:require("UI/ExchangeCdKey/ExchangeCdKeyMain")

function exchange_cd_key_module:init()
  self._events = nil
  exchange_cd_key_module:add_event()
  self._exchange_time = 0
end

function exchange_cd_key_module:close()
  exchange_cd_key_module:remove_event()
end

function exchange_cd_key_module:clear_on_disconnect()
end

return exchange_cd_key_module
