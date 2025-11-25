warehouse_module = warehouse_module or {}
warehouse_module._cname = "warehouse_module"
lua_module_mgr:require("UI/Warehouse/WarehouseCommon")
lua_module_mgr:require("UI/Warehouse/WarehouseData")
lua_module_mgr:require("UI/Warehouse/WarehouseMain")
lua_module_mgr:require("UI/Warehouse/WarehouseNet")

function warehouse_module:init()
  self:_init_data()
  self._events = nil
  warehouse_module:add_event()
end

function warehouse_module:close()
  warehouse_module:remove_event()
end

function warehouse_module:clear_on_disconnect()
end

return warehouse_module
