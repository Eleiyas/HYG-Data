local M = G.Class("HistoryChatDialog", require("UI/ChatMain/HistoryChatPage"))
local base = require("UI/ChatMain/HistoryChatPage")

function M:init()
  base.init(self)
  self.config.type = EUIType.Dialog
end

return M
