tvshop_module = tvshop_module or {}
tvshop_module._cname = "tvshop_module"
lua_module_mgr:require("UI/TVShopping/TVShopData")

function tvshop_module:init()
  self._tvshop_data = nil
end

function tvshop_module:close()
end

return tvshop_module
