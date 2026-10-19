rabbit_tabletop_module = rabbit_tabletop_module or {}
rabbit_tabletop_module._cname = "rabbit_tabletop_module"
lua_module_mgr:require("UI/RabbitTabletop/RabbitTabletopCommon")
lua_module_mgr:require("UI/RabbitTabletop/RabbitTabletopMain")

function rabbit_tabletop_module:init()
  self._events = nil
  rabbit_tabletop_module:add_event()
end

function rabbit_tabletop_module:close()
  rabbit_tabletop_module:remove_event()
end

function rabbit_tabletop_module:clear_on_disconnect()
end

return rabbit_tabletop_module
