local M = G.Class("LeMiFootprintAchieveRewardItem", G.UIBase)
local base = G.UIBase

function M:on_create()
  base.on_create(self)
end

function M:set_item_id(item_id)
  item_module:set_item_icon(self._img_coin_icon, item_id, nil, nil, self:get_load_proxy())
end

function M:set_num(num)
  UIUtil.set_text(self._txt_coin_num, TextMapFormatUtil.FormatInteger(num))
end

return M
