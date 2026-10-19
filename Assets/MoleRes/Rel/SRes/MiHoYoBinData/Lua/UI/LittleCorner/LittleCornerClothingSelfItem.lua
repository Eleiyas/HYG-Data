local M = G.Class("LittleCornerClothingSelfItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._state_group_select = nil
  self._icon_clothing_dynamic = nil
  self._txt_name = nil
  self._toggle_self = nil
  self._parsed = nil
  self._raw_info = ""
  self._on_toggle_changed_callback = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_ui()
end

function M:_refresh_ui()
  local data = self:get_extra_data()
  if not data then
    return
  end
  local seg = data.seg
  if not seg or seg == "" then
    return
  end
  local parsed = data.parsed
  if not parsed then
    return
  end
  self._raw_info = seg
  self._parsed = parsed
  local config_id = parsed.config_id
  local cfg = item_module:get_cfg_by_id(config_id)
  if not cfg then
    return
  end
  item_module:set_item_icon(self._icon_clothing_dynamic, config_id, cfg, nil, self:get_load_proxy())
  local name = item_module:get_item_name_by_id(config_id)
  if little_corner_module.debug_mode then
    name = name .. string.format("(%d)", config_id)
  end
  UIUtil.set_text(self._txt_name, name)
  local is_selected = data.is_selected == nil and true or data.is_selected
  self:set_selected(is_selected)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:_add_ui_listener()
  self:bind_callback(self._toggle_self, pack(self, M._on_toggle_self))
end

function M:_on_toggle_self(is_on)
  self._is_selected = is_on
  self._state_group_select:SetState(is_on and 1 or 0)
  if self._on_toggle_changed_callback then
    self._on_toggle_changed_callback(is_on)
  end
end

function M:set_on_toggle_changed_callback(callback)
  self._on_toggle_changed_callback = callback
end

function M:set_selected(is_on)
  self._is_selected = is_on
  self._state_group_select:SetState(is_on and 1 or 0)
  self._toggle_self.isOnValue = is_on
end

function M:is_selected()
  return self._is_selected
end

function M:get_parsed()
  return self._parsed
end

function M:get_raw_info()
  return self._raw_info
end

function M:force_refresh()
  self:_refresh_ui()
end

return M
