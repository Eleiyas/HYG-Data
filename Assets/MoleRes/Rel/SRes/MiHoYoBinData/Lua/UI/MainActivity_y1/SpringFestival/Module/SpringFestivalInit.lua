spring_festival_module = spring_festival_module or {}
spring_festival_module._cname = "spring_festival_module"
require("UI/MainActivity_y1/SpringFestival/Module/SpringFestivalGateData")
lua_module_mgr:require("UI/MainActivity_y1/SpringFestival/FukubagExchange/Module/SpringFestivalFukubagExchangeInit")
lua_module_mgr:require("UI/MainActivity_y1/SpringFestival/TasselShop/Module/SpringFestivalTasselShopInit")
lua_module_mgr:require("UI/MainActivity_y1/SpringFestival/CoinShop/Module/SpringFestivalCoinShopInit")

function spring_festival_module:init()
end

function spring_festival_module:close()
end

function spring_festival_module:clear_on_disconnect()
end

function spring_festival_module:on_level_destroy()
end

return spring_festival_module
