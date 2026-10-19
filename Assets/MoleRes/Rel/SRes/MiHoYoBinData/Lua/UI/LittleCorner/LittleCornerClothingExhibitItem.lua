local M = G.Class("LittleCornerClothingExhibitItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._state_group_get = nil
  self._icon_clothing_dynamic = nil
  self._txt_title = nil
  self._btn_source = nil
  self._parsed = nil
  self._owned = false
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_source, pack(self, M._on_btn_item_source))
end

function M:on_open()
  base.on_open(self)
  self:_refresh_ui()
end

function M:_refresh_ui()
  local data = self:get_extra_data()
  if not data then
    return
  end
  local parsed = data.parsed
  if not parsed then
    return
  end
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
  UIUtil.set_text(self._txt_title, name)
  local owned = data.owned
  if owned == nil then
    if parsed.is_appearance then
      owned = appearance_module:is_style_unlocked(config_id)
    else
      owned = back_bag_module:get_item_num(config_id) > 0 or little_corner_module:is_default_outfit(config_id)
    end
  end
  self._owned = owned or false
  self._state_group_get:SetState(self._owned and 0 or 1)
end

function M:get_parsed()
  return self._parsed
end

function M:on_enable()
  base.on_enable(self)
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

function M:_on_btn_item_source()
  if not self._parsed then
    return
  end
  if self._owned then
    return
  end
  item_module:open_item_info_dialog(self._parsed.config_id)
end

function M:force_refresh()
  self:_refresh_ui()
end

return M
