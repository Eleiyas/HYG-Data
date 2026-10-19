local M = G.Class("LiteNpcBirthdayWrapBagPanel", "UI/LitePacketView/LiteCommonBagPanel")
local base = G.LiteCommonBagPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LitePacketView/LiteCommonBagPanel"
end

function M:_init_item_extra_data(item_data, index)
  base._init_item_extra_data(self, item_data, index)
  if not is_null(item_data.server_data) and CsGameplayTagUtilUtil.ConfigHasTag(item_data.server_data.ConfigId, EntityTagTags.Tags.specialitem_npcgiftbox) then
    item_data.is_lock = true
  end
end

return M
