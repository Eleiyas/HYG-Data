shop_module = shop_module or {}
shop_module._cname = "shop_module"
lua_module_mgr:require("UI/Shop/ShopCommon")
lua_module_mgr:require("UI/Shop/ShopMain")
lua_module_mgr:require("UI/Shop/ShopData")

function shop_module:init()
  shop_module:_init_data()
end

function shop_module:close()
  shop_module:_init_data()
end

return shop_module or {}
