local M = G.Class("CookBagPanel", "UI/LitePacketView/LiteCommonBagPanel")
local base = G.LiteCommonBagPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LitePacketView/LiteCommonBagPanel"
end

function M:on_create()
  base.on_create(self)
end

function M:get_item_by_guid(guid)
  return CsPacketModuleUtil.GetStackByGuid(guid)
end

return M
