instrument_play_module = instrument_play_module or {}
instrument_play_module._cname = "instrument_play_module"
lua_module_mgr:require("UI/InstrumentPlay/InstrumentPlayUI")
lua_module_mgr:require("UI/InstrumentPlay/InstrumentPlayCommon")

function instrument_play_module:init()
end

function instrument_play_module:close()
end

return instrument_play_module
