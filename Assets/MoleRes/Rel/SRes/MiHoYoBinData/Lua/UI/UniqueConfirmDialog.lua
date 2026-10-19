local base = require("UI/ConfirmDialog")
local M = G.Class("UniqueConfirmDialog", base)

function M:init()
  base.init(self)
  self.config.is_singleton = true
end

function M:close_callback()
  if self._close_callback then
    self:_press_btn(self._close_callback)
  else
    self:_press_btn(self._no_callback)
  end
end

return M
