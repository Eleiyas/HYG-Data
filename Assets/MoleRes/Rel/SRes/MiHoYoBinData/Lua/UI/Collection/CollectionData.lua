collection_module = collection_module or {}

function collection_module:_init_data()
  self._cur_submit_panel_type = collection_module.submit_panel_type.none
end

function collection_module:set_submit_panel_type(submit_type)
  self._cur_submit_panel_type = submit_type or collection_module.submit_panel_type.none
end

function collection_module:get_submit_panel_type()
  return self._cur_submit_panel_type
end

return collection_module
