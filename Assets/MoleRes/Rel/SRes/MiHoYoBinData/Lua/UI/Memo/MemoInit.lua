memo_module = memo_module or {}
memo_module._cname = "memo_module"
lua_module_mgr:require("UI/Memo/MemoCommon")
lua_module_mgr:require("UI/Memo/MemoUI")
lua_module_mgr:require("UI/Memo/MemoMain")
lua_module_mgr:require("UI/Memo/MemoData")

function memo_module:init()
  memo_module:add_event()
  memo_module:_init_data()
end

function memo_module:close()
  memo_module:remove_event()
  memo_module:_init_data()
end

function memo_module:clear_on_disconnect()
  memo_module:init()
end

return memo_module
