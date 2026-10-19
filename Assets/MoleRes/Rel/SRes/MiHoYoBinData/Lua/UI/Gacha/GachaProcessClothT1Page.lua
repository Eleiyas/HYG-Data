local base = require("UI/Gacha/GachaProcessFurnitureT1Page")
local M = G.Class("GachaProcessClothT1Page", base)

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.panel_path.process_cloth_t1
  self.config.type = EUIType.Page
end

return M
