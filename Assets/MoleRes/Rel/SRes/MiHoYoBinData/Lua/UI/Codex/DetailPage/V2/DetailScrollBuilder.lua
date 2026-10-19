local M = G.Class("DetailScrollBuilder")

function M:__ctor()
  self._section_pool = {}
  self._current_keys = {}
  self._holder = nil
end

function M:init(holder)
  self._holder = holder
end

function M:build(section_configs)
  local in_config = {}
  self._current_keys = {}
  for _, cfg in ipairs(section_configs) do
    in_config[cfg.section_key] = true
    self._current_keys[#self._current_keys + 1] = cfg.section_key
    if not self._section_pool[cfg.section_key] then
      local root_trans = self._holder[cfg.root_field]
      if not_null(root_trans) then
        local section = self._holder:add_panel(cfg.class_path, root_trans)
        self._section_pool[cfg.section_key] = section
      end
    end
  end
  for key, section in pairs(self._section_pool) do
    if not in_config[key] then
      section:set_active(false)
    end
  end
end

function M:refresh(item_data)
  for _, key in ipairs(self._current_keys) do
    local section = self._section_pool[key]
    if section then
      if section:should_show(item_data) then
        section:set_active(true)
        section:refresh(item_data)
      else
        section:set_active(false)
      end
    end
  end
end

function M:hide_all()
  for _, section in pairs(self._section_pool) do
    section:set_active(false)
  end
end

function M:get_section(key)
  return self._section_pool[key]
end

function M:destroy()
  for _, section in pairs(self._section_pool) do
    self._holder:remove_panel(section)
  end
  self._section_pool = {}
  self._current_keys = {}
end

return M
