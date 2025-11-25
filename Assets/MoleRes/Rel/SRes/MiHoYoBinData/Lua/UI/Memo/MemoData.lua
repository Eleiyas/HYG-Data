memo_module = memo_module or {}

function memo_module:_init_data()
  self._tbl_tab_select_info = {}
end

function memo_module:set_tab_select_info(tab_type, group_id, node_index)
  self._tbl_tab_select_info[tab_type] = {group_id = group_id, node_index = node_index}
end

function memo_module:get_tab_select_info(tab_type)
  return self._tbl_tab_select_info[tab_type] or {}
end

function memo_module:check_node_is_select(tab_type, group_id, node_index)
  local info = memo_module:get_tab_select_info(tab_type)
  return info.group_id ~= nil and info.group_id == group_id and info.node_index ~= nil and info.node_index == node_index
end

function memo_module:clear_node_is_select()
  self._tbl_tab_select_info = {}
end

return memo_module
