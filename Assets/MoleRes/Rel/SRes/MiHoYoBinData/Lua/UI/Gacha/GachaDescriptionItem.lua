local M = G.Class("GachaDescriptionItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(item_data, is_history, gacha_pool_id)
  if item_data == nil then
    return
  end
  if not_null(self._txt_item_name) and 0 < (item_data.item_id or 0) then
    local item_name = item_data.item_name ~= nil and item_data.item_name or item_module:get_item_name_by_id(item_data.item_id)
    if is_history and gacha_pool_id and item_data.slot_index and 0 < item_data.slot_index then
      local pool_cfg = gacha_module:get_pool_cfg(gacha_pool_id, item_data.slot_index)
      local extra_str = ""
      if pool_cfg and pool_cfg.unitcount and pool_cfg.unitcount > 1 then
        extra_str = " x" .. tostring(pool_cfg.unitcount)
      end
      item_name = item_name .. extra_str
    end
    UIUtil.set_text(self._txt_item_name, item_name)
    item_module:set_item_color(self._txt_item_name, item_data.item_id, self._state_group_rainbow)
  end
  if is_history then
    UIUtil.set_text(self._txt_probability_num, item_data.draw_time or "")
  else
    UIUtil.set_text(self._txt_probability_num, item_data.item_probability or "0%")
  end
end

return M
