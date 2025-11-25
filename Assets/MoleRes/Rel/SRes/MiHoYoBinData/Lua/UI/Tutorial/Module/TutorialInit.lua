tutorial_module = tutorial_module or {}
tutorial_module._cname = "tutorial_module"
lua_module_mgr:require("UI/Tutorial/Module/TutorialMain")
lua_module_mgr:require("UI/Tutorial/Module/TutorialData")

function tutorial_module:init()
  self._events = nil
  self._tbl_rep = nil
  self.hardware_id = 1
  tutorial_module:add_event()
  tutorial_module:register_cmd_handler()
  tutorial_module:_init_data()
end

function tutorial_module:close()
  tutorial_module:remove_event()
  tutorial_module:un_register_cmd_handler()
end

function tutorial_module:register_cmd_handler()
  tutorial_module:un_register_cmd_handler()
  self._tbl_rep = {}
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function tutorial_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

function tutorial_module:clear_on_disconnect()
  self:_init_data()
end

function tutorial_module:_init_data()
  self.tutorial_items_data = {}
  self.tutorial_modules_info = {}
  self.finished_tutorials = {}
  self.tutorial_content_to_ids = {}
  self.all_tutorials = {}
  self.ui_dynamic_ui_key = {}
  tutorial_module:gen_all_tutorial()
end

return tutorial_module
