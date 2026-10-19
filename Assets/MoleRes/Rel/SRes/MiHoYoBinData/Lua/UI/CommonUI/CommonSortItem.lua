local M = G.Class("CommonSortItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._on_selected = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._tog_sort, pack(self, M._on_toggle_changed))
end

function M:on_destroy()
  self._on_selected = nil
  base.on_destroy(self)
end

function M:render(option, is_selected, on_selected)
  self:set_active(option ~= nil)
  if option == nil then
    return
  end
  self._on_selected = on_selected
  UIUtil.set_text(self._txt_title, option.title or "")
  self._tog_sort:SetIsOnWithoutNotify(is_selected == true)
end

function M:_on_toggle_changed(is_on)
  if is_on and self._on_selected ~= nil then
    self._on_selected()
  end
end

return M
