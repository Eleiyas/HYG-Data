local M = G.Class("LittleCornerPostSearchHistoryItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._txt_cell = nil
  self._btn_cell = nil
  self._state_cell = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_cell, pack(self, M._on_click))
end

function M:on_open()
  base.on_open(self)
  self:_refresh_ui()
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

function M:_refresh_ui()
  local data = self:get_extra_data()
  if not data then
    return
  end
  UIUtil.set_text(self._txt_cell, data.keyword or "")
  if self._state_cell then
    self._state_cell:SetState(data.is_last and 1 or 0)
  end
end

function M:_on_click()
  local data = self:get_extra_data()
  if data and data.on_click then
    data.on_click(data.keyword)
  end
end

function M:force_refresh()
  self:_refresh_ui()
end

return M
