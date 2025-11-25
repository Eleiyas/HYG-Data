phone_module = phone_module or {}
phone_module._cname = "phone_module"
lua_module_mgr:require("Phone/PhoneNet")

function phone_module:init()
  phone_module:register_cmd_handler()
end

function phone_module:close()
  phone_module:un_register_cmd_handler()
end

return phone_module
