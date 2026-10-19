in_game_letter_module = in_game_letter_module or {}
in_game_letter_module._cname = "in_game_letter_module"
lua_module_mgr:require("InGameLetter/InGameLetterNet")
lua_module_mgr:require("InGameLetter/InGameLetterData")

function in_game_letter_module:init()
  self._events = nil
  self._tbl_rep = nil
  self:add_event()
  self:register_cmd_handler()
end

function in_game_letter_module:close()
  self:remove_event()
  self:un_register_cmd_handler()
end

function in_game_letter_module:add_event()
  self:remove_event()
  self._events = {}
  self._events[EventID.VCLetterBoxReady] = pack(self, in_game_letter_module.check_unread_letter)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function in_game_letter_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

return in_game_letter_module
