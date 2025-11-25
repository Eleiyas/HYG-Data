fortune_wheel_module = fortune_wheel_module or {}
fortune_wheel_module._cname = "fortune_wheel_module"
lua_module_mgr:require("UI/FortuneWheel/FortuneWheelMain")
lua_module_mgr:require("UI/FortuneWheel/FortuneWheelCfg")

function fortune_wheel_module:init()
  self._events = nil
  fortune_wheel_module:add_event()
end

function fortune_wheel_module:close()
  fortune_wheel_module:remove_event()
end

function fortune_wheel_module:clear_on_disconnect()
end

return fortune_wheel_module
