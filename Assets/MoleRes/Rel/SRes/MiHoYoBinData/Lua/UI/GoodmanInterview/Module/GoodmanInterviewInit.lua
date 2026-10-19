goodman_interview_module = goodman_interview_module or {}
goodman_interview_module._cname = "goodman_interview_module"
lua_module_mgr:require("UI/GoodmanInterview/Module/GoodmanInterviewMain")

function goodman_interview_module:init()
  self._page_guid = nil
  goodman_interview_module:add_event()
end

function goodman_interview_module:close()
  goodman_interview_module:remove_event()
end

function goodman_interview_module:clear_on_disconnect()
  goodman_interview_module:close_page()
end

return goodman_interview_module
