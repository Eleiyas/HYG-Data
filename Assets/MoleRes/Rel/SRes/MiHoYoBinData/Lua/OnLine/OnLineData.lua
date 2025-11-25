on_line_module = on_line_module or {}

function on_line_module:set_give_fish_data(data)
  self._give_fish_data = data
end

function on_line_module:get_give_fish_data()
  return self._give_fish_data
end

function on_line_module:set_is_change_give_fish_data_state(is_change)
  self._is_change_give_fish_data = is_change or false
end

function on_line_module:get_is_change_give_fish_data_state()
  local is_change = self._is_change_give_fish_data
  self._is_change_give_fish_data = false
  return is_change
end

return on_line_module
