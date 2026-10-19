local M = G.Class("InteractRecordRewardItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._reaction_card_id = 0
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_item, pack(self, M._on_item_click))
end

function M:on_disable()
  base.on_disable(self)
end

function M:set_data(reaction_card_id)
  if reaction_card_id == nil or reaction_card_id == 0 then
    self._reaction_card_id = 0
    return
  end
  self._reaction_card_id = reaction_card_id
  local item_cfg = item_module:get_cfg_by_id(reaction_card_id)
  if is_null(item_cfg) then
    Logger.LogError("InteractRecordRewardItem: 动作卡道具配置缺失, id=" .. tostring(reaction_card_id))
    return
  end
  item_module:set_item_icon_no_server_data(self._img_icon, reaction_card_id, item_cfg, self:get_load_proxy())
end

function M:_on_item_click()
  if self._reaction_card_id == nil or self._reaction_card_id == 0 then
    return
  end
  item_module:open_item_info_dialog(self._reaction_card_id, 1)
end

return M
