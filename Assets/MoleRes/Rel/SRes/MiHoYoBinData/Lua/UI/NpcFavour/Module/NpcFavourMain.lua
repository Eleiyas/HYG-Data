npc_favour_module = npc_favour_module or {}

function npc_favour_module:add_event()
  npc_favour_module:remove_event()
  self._events = {}
  self._events[EventID.OnNpcStarWishAdd] = pack(self, npc_favour_module._on_star_wish_add)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function npc_favour_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function npc_favour_module:_on_star_wish_add(npc_id)
  UIManagerInstance:open("UI/NpcFavour/StarWishTip/NpcStarWishTip", npc_id)
end

return npc_favour_module
