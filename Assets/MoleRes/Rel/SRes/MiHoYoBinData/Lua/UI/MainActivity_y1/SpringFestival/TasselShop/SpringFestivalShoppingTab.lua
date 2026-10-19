local M = G.Class("SpringFestivalShoppingTab", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._tab_id = 0
  self._on_toggle = nil
end

function M:on_create()
  base.on_create(self)
  local data = self:get_extra_data() or {}
  self._on_toggle = data.on_toggle
  local toggle = self._tog or self._tog_select or self._toggle
  if toggle ~= nil then
    self:bind_callback(toggle, pack(self, M._on_toggle_changed))
    self._tog = self._tog or toggle
  end
end

function M:set_extra_data(data)
  base.set_extra_data(self, data)
  data = data or {}
  self._on_toggle = data.on_toggle
end

function M:refresh_view(tab_id, tab_cfg, on_toggle)
  self._tab_id = tab_id or 0
  self._on_toggle = on_toggle
  local icon_path = tab_cfg and tab_cfg.icon or ""
  if icon_path ~= "" then
    if self._img_select ~= nil then
      UIUtil.set_image(self._img_select, icon_path, self:get_load_proxy())
    end
    if self._img_unselect ~= nil then
      UIUtil.set_image(self._img_unselect, icon_path, self:get_load_proxy())
    end
  end
end

function M:get_tab_id()
  return self._tab_id or 0
end

function M:set_toggle_ison(is_on)
  local toggle = self._tog or self._tog_select or self._toggle
  if toggle ~= nil then
    UIUtil.set_toggle_ison(toggle, is_on == true)
  end
end

function M:_on_toggle_changed(is_on)
  if not is_on then
    return
  end
  if self._on_toggle ~= nil then
    self._on_toggle(self._tab_id)
  end
end

return M
