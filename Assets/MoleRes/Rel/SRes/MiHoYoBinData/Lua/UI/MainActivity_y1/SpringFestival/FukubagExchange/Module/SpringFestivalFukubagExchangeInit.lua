spring_festival_exchange_module = spring_festival_exchange_module or {}
spring_festival_exchange_module._cname = "spring_festival_exchange_module"
lua_module_mgr:require("UI/MainActivity_y1/SpringFestival/FukubagExchange/Module/SpringFestivalFukubagExchangeData")
lua_module_mgr:require("UI/MainActivity_y1/SpringFestival/FukubagExchange/Module/SpringFestivalFukubagExchangeMain")

function spring_festival_exchange_module:init()
  self:_init_data()
end

function spring_festival_exchange_module:close()
end

function spring_festival_exchange_module:clear_on_disconnect()
  self:_init_data()
end

function spring_festival_exchange_module:on_level_destroy()
  self:_init_data()
end

return spring_festival_exchange_module
