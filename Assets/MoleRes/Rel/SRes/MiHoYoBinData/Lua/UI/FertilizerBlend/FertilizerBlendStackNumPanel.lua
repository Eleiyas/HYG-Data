local base = require("UI/Item/StackNumPanel")
local M = G.Class("FertilizerBlendStackNumPanel", base)

function M:_refresh_slider()
  base._refresh_slider(self)
end

return M
