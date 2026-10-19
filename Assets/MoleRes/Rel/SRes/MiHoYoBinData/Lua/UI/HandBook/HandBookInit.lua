hand_book_module = hand_book_module or {}
hand_book_module._cname = "hand_book_module"
lua_module_mgr:require("UI/HandBook/HandBookDef")
lua_module_mgr:require("UI/HandBook/HandBookCfg")
lua_module_mgr:require("UI/HandBook/HandBook")

function hand_book_module:init()
  self._item_cfg_list = nil
  self._item_size_cfg_list = nil
  hand_book_module:reset_server_data()
end

function hand_book_module:close()
  self._add_item_fun = nil
end

function hand_book_module:reset_server_data()
  self._is_new_hand_book = nil
  
  function self._add_item_fun(item)
    if item and type(item) ~= "number" then
      hand_book_module:_refresh_main_tips(item)
    end
  end
end

function hand_book_module:clear_on_disconnect()
  hand_book_module:reset_server_data()
end

return hand_book_module or {}
