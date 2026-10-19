local M = G.Class("FortuneWheelCoinItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._config_id = 0
end

function M:refresh(config_id, custom_num)
  if config_id == nil or config_id == 0 then
    return
  end
  self._config_id = config_id
  item_module:set_item_icon(self._img_coin_icon, config_id, nil, nil, self:get_load_proxy())
  local bag_num = back_bag_module:get_coin_or_item_num(config_id)
  if custom_num then
    if custom_num > bag_num then
      UIUtil.set_text(self._txt_coin_num, string.format("<style=TextWarning_Dark>%d</style>", custom_num))
    else
      UIUtil.set_text(self._txt_coin_num, tostring(custom_num))
    end
  else
    UIUtil.set_text(self._txt_coin_num, tostring(bag_num))
  end
end

return M
