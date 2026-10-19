coffee_rp_module = coffee_rp_module or {}
coffee_rp_module._cname = "coffee_rp_module"
lua_module_mgr:require("UI/CoffeeRpUI/CoffeeRpData")
lua_module_mgr:require("UI/CoffeeRpUI/CoffeeRpMain")

function coffee_rp_module:init()
  coffee_rp_module:_init_data()
  coffee_rp_module:add_event()
end

function coffee_rp_module:close()
  coffee_rp_module:remove_event()
end

function coffee_rp_module:clear_on_disconnect()
  coffee_rp_module:_init_data()
end

function coffee_rp_module:init_on_connect()
  coffee_rp_module:_init_data()
end

function coffee_rp_module:on_level_prepare()
  if level_module:cur_level_is_coffee_rp() then
    return
  end
  self:_apply_na_luo_letter_recover()
end

function coffee_rp_module:add_event()
  self:remove_event()
  self._events = {}
  self._events[EventID.NaLuoLetterReceived] = pack(self, self._on_evt_na_luo_letter_received)
  self._events[EventID.NaLuoLetterRecovered] = pack(self, self._on_evt_na_luo_letter_recovered)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function coffee_rp_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

return coffee_rp_module
