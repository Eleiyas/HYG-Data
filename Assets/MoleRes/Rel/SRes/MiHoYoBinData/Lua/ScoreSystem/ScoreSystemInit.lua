score_system_module = score_system_module or {}
score_system_module._cname = "score_system_module"

function score_system_module:init()
  self._events = nil
  self._tbl_rep = nil
  score_system_module:add_event()
end

function score_system_module:close()
  score_system_module:remove_event()
end

function score_system_module:add_event()
  score_system_module:remove_event()
  self._events = {}
end

function score_system_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

return score_system_module
