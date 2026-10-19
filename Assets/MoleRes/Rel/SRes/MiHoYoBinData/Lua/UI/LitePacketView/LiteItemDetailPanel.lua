local M = G.Class("LiteItemDetailPanel", "UI/PacketView/ItemDetailPanel")
local base = G.ItemDetailPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LitePacketView/LiteItemDetailPanel"
end

return M
