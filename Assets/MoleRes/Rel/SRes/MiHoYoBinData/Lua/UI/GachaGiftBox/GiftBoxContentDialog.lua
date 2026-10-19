local M = G.Class("GiftBoxContentDialog", "UI/GachaGiftBox/GachaGiftBoxDialog")
local base = G.GachaGiftBoxDialog

function M:_load_items_cfg_lst()
  local gift_item_id = self._data ~= nil and self._data.gift_item_id or 0
  if gift_item_id == 0 then
    return {}
  end
  local item_cfg = item_module:get_cfg_by_id(gift_item_id)
  return {
    {
      configid = gift_item_id,
      configname = item_cfg.name,
      num = 1
    }
  }
end

function M:_setup_static_ui()
  local item_cfg = item_module:get_cfg_by_id(self._box_id)
  UIUtil.set_text(self._txt_gacha_name, item_cfg.name)
  UIUtil.set_active(self._trans_detail, false)
end

function M:_on_item_btn(item_cfg)
end

return M
