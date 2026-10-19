task_module = task_module or {}

function task_module:register_cmd_handler()
  task_module:un_register_cmd_handler()
  self._tbl_rep = {}
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function task_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

return task_module
