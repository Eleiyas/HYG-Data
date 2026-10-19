local M = G.Class("NpcClothMachineDescPanel", G.UIPanel)
local base = G.UIPanel
local SIZE_ITEM_CLS = "UI/NpcCloth/NpcClothSizeItem"
local QUALITY_COLOR_KEY_BY_RANK = {
  [0] = "QualityWhite_Light",
  [1] = "QualityGreen_Light",
  [2] = "QualityPurple_Light",
  [3] = "QualityGold_Light"
}

function M:init()
  base.init(self)
  self._goods = nil
  self._display_item_id = 0
  self._has_bound_info_button = false
end

function M:on_create()
  base.on_create(self)
  self:_ensure_info_button()
  self:_init_size_item()
end

function M:refresh(goods)
  local item_id = goods and goods.ItemID or 0
  if item_id <= 0 then
    self:_hide_content()
    return
  end
  if self._display_item_id == item_id then
    return
  end
  UIUtil.set_active(self.trans, true)
  self._goods = goods
  self._display_item_id = item_id
  local item_cfg = 0 < item_id and item_module:get_cfg_by_id(item_id) or nil
  if self._btn_info_dark then
    UIUtil.set_active(self._btn_info_dark, 0 < item_id)
  end
  if self._txt_name then
    UIUtil.set_text(self._txt_name, item_cfg and item_cfg.name or "")
  end
  local rank = item_cfg and item_cfg.rank or 0
  UIUtil.set_image_color(self._img_quality, QUALITY_COLOR_KEY_BY_RANK[rank] or QUALITY_COLOR_KEY_BY_RANK[0])
  if self._txt_own then
    if 0 < item_id then
      UIUtil.set_text_by_id(self._txt_own, "TVShopping_Item_Own", back_bag_module:get_item_num(item_id))
    else
      UIUtil.set_text(self._txt_own, "")
    end
  end
  self:refresh_left_time(goods)
  if self._size_item then
    self._size_item:refresh_by_item_id(item_id, item_cfg)
  end
end

function M:_hide_content()
  self._goods = nil
  self._display_item_id = 0
  UIUtil.set_active(self.trans, false)
end

function M:_init_size_item()
  if self._size_item or is_null(self._obj_npc_cloth) then
    return
  end
  self._size_item = self:add_panel(SIZE_ITEM_CLS, self._obj_npc_cloth)
end

function M:refresh_left_time(goods)
  goods = goods or self._goods
  if not self._txt_left_time then
    return
  end
  local close_time = tonumber(goods and goods.CloseTime or 0) or 0
  local remain_time = close_time - (TimeUtil.ServerUtcTimeSeconds or 0)
  local is_show = 0 < close_time and 0 < remain_time
  UIUtil.set_active(self._txt_left_time, is_show)
  if is_show then
    UIUtil.set_text(self._txt_left_time, LuaTimeUtil.get_time_str(math.ceil(remain_time)))
  end
end

function M:_ensure_info_button()
  if self._has_bound_info_button or is_null(self._btn_info_dark) then
    return
  end
  self:bind_callback(self._btn_info_dark, pack(self, M._on_info_click))
  self._has_bound_info_button = true
end

function M:_on_info_click()
  local goods = self._goods
  if not is_null(goods) and 0 < (goods.ItemID or 0) then
    item_module:open_item_info_dialog(goods.ItemID, back_bag_module:get_item_num(goods.ItemID))
  end
end

return M
