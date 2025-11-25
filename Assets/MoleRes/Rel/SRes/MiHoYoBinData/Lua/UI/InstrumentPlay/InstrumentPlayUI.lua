instrument_play_module = instrument_play_module or {}
instrument_play_module._cname = "instrument_play_module"

function instrument_play_module:enter_instrument_play()
  UIManagerInstance:open("UI/InstrumentPlay/InstrumentPlayPage")
end

function instrument_play_module:exit_instrument_play()
end

return instrument_play_module or {}
