weather_clock_module = weather_clock_module or {}
weather_clock_module._cname = "weather_clock_module"
lua_module_mgr:require("UI/WeatherClock/Module/WeatherClockMain")
lua_module_mgr:require("UI/WeatherClock/Module/WeatherClockCommon")

function weather_clock_module:init()
  self._events = nil
  weather_clock_module:add_event()
end

function weather_clock_module:close()
  weather_clock_module:remove_event()
end

function weather_clock_module:clear_on_disconnect()
end

return weather_clock_module
