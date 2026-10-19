local M = G.Class("ThemeSeasonChapterDetailPageDot", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._index = 0
  self._on_select_func = nil
  self._tog_dot = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._tog_dot) then
    self:bind_callback(self._tog_dot, pack(self, M._on_toggle_changed))
  end
end

function M:on_destroy()
  self._on_select_func = nil
  base.on_destroy(self)
end

function M:set_data(index, on_select_func)
  self._index = index
  self._on_select_func = on_select_func
end

function M:set_selected(is_on)
  if not_null(self._tog_dot) then
    self._tog_dot.isOn = is_on
  end
end

function M:_on_toggle_changed(is_on)
  if not is_on then
    return
  end
  if self._on_select_func then
    self._on_select_func(self._index)
  end
end

return M
