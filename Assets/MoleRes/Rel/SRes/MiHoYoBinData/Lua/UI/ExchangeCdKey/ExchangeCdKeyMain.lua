exchange_cd_key_module = exchange_cd_key_module or {}

function exchange_cd_key_module:add_event()
  exchange_cd_key_module:remove_event()
  self._events = {}
  self._events[EventID.LuaShowExchangeCdKeyPopup] = pack(self, exchange_cd_key_module.open_popup)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function exchange_cd_key_module:open_popup(context)
  UIManagerInstance:open("UI/ExchangeCdKey/ExchangeCdKeyPopupDialog", {
    confirm_callback = context.confirm,
    cancel_callback = context.cancel
  })
end

function exchange_cd_key_module:set_exchange_time(time)
  self._exchange_time = time
end

function exchange_cd_key_module:get_exchange_time()
  return self._exchange_time
end

function exchange_cd_key_module:get_exchange_remain_time(cooldown_time)
  local last_exchange_time = self:get_exchange_time() or 0
  if last_exchange_time <= 0 then
    return 0
  end
  local pass_time = TimeUtil.ServerUtcTimeSeconds - last_exchange_time
  return math.max(0, cooldown_time - pass_time)
end

function exchange_cd_key_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

return exchange_cd_key_module
