goodman_interview_module = goodman_interview_module or {}
local PAGE_CLASS = "UI/GoodmanInterview/GoodmanInterviewPage"

function goodman_interview_module:is_active()
  return GameplayUtilities_LlmaiNpc.InterviewIsLocalActive()
end

function goodman_interview_module:add_event()
  goodman_interview_module:remove_event()
  self._events = {}
  self._events[EventID.LuaShowInterviewPanel] = pack(self, goodman_interview_module._on_interview_begin)
  self._events[EventID.LuaHideInterviewPanel] = pack(self, goodman_interview_module._on_interview_end)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function goodman_interview_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function goodman_interview_module:_on_interview_begin()
  if UIManagerInstance:is_show(PAGE_CLASS) then
    return
  end
  self._page_guid = UIManagerInstance:open(PAGE_CLASS)
end

function goodman_interview_module:_on_interview_end()
  goodman_interview_module:close_page()
end

function goodman_interview_module:close_page()
  if self._page_guid == nil then
    return
  end
  UIManagerInstance:close(self._page_guid)
  self._page_guid = nil
end

return goodman_interview_module
