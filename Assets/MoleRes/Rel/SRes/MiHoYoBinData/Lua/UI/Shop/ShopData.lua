shop_module = shop_module or {}

function shop_module:_init_data()
  self._is_show_protected_tips = true
end

function shop_module:set_is_show_protected_tips(is_show)
  self._is_show_protected_tips = is_show or false
end

function shop_module:get_is_show_protected_tips()
  return self._is_show_protected_tips or false
end

return shop_module
