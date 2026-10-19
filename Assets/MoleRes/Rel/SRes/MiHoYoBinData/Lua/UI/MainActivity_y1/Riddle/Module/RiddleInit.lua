riddle_module = riddle_module or {}
riddle_module._cname = "riddle_module"
lua_module_mgr:require("UI/MainActivity_y1/Riddle/Module/RiddleData")
lua_module_mgr:require("UI/MainActivity_y1/Riddle/Module/RiddleMain")

function riddle_module:init()
  self._events = nil
  self._pending_answer_bubble_context = nil
  riddle_module:add_event()
end

function riddle_module:close()
  riddle_module:remove_event()
  self._pending_answer_bubble_context = nil
end

function riddle_module:clear_on_disconnect()
  self._pending_answer_bubble_context = nil
end

return riddle_module
