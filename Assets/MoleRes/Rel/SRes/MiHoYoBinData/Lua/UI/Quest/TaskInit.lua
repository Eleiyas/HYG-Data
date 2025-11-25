task_module = task_module or {}
task_module._cname = "task_module"
lua_module_mgr:require("UI/Quest/TaskCommon")
lua_module_mgr:require("UI/Quest/TaskData")
lua_module_mgr:require("UI/Quest/TaskCfg")
lua_module_mgr:require("UI/Quest/TaskNet")
lua_module_mgr:require("UI/Quest/TaskUI")
lua_module_mgr:require("UI/Quest/TaskMain")

function task_module:init()
  self._lst_finish_task_ids = nil
  task_module:_init_data()
  task_module:add_event()
  task_module:register_cmd_handler()
end

function task_module:close()
  task_module:_init_data()
  task_module:remove_event()
  task_module:un_register_cmd_handler()
end

return task_module or {}
