local M = G.Class("GeLianMarketCropInventoryPanel", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._entry = nil
end

function M:render(entry)
  self._entry = entry
  local config_id = entry and entry.display_config_id or 0
  self:set_active(0 < config_id)
  if config_id <= 0 then
    return
  end
  local item_count = 0
  for i = 1, #(entry.fruit_ids or {}) do
    item_count = item_count + (back_bag_module:get_item_num(entry.fruit_ids[i]) or 0)
  end
  item_module:set_item_icon(self._img_icon, config_id, nil, nil, self:get_load_proxy())
  UIUtil.set_text(self._txt_num, item_count)
end

return M
