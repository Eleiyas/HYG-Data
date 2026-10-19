local base = require("UI/Gacha/GachaPoolShowPageBase")
local M = G.Class("GachaClothPoolShowPage", base)

function M:_get_tab_groups(gachapoolid)
  return gacha_module:get_cloth_pool_tab_groups(gachapoolid)
end

function M:_get_cur_select_index()
  return gacha_module:get_cur_cloth_pool_index()
end

function M:_set_cur_select_index(index)
  gacha_module:set_cur_cloth_pool_index(index)
end

function M:_get_pool_cfg(pool_id, index)
  return gacha_module:get_pool_cfg(pool_id, index)
end

function M:_is_exchange_panel()
  return false
end

function M:_refresh_detail()
  self:_refresh_item_info()
  self:_refresh_model_preview()
end

function M:_refresh_item_info()
  if self._cur_select_cfg == nil then
    return
  end
  local pool_cfg = self._cur_select_cfg
  local gacha_id = gacha_module:get_cur_gacha_id()
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  if not_null(self._txt_item_name) then
    UIUtil.set_text(self._txt_item_name, pool_cfg.name)
  end
  local is_item_owned = gacha_module:is_item_owned(gacha_id, pool_cfg.itemid, self._drawn_map, self._exchanged_map)
  UIUtil.set_active(self._txt_owner_num, false)
  UIUtil.set_active(self._txt_not_owner, not is_item_owned)
  UIUtil.set_active(self._txt_core_cloth_desc, pool_cfg.itemtype == GachaConst.item_type.core)
  if not_null(self._txt_core_cloth_desc) then
    UIUtil.set_text_by_id(self._txt_core_cloth_desc, "Gacha_T1Cloth_MainScreen_Desc", pool_cfg.name)
  end
  if not_null(self._txt_go_draw) and activity_cfg then
    UIUtil.set_text_by_id(self._txt_go_draw, "Gacha_T1_ClothShop_Source", activity_cfg.name)
  end
  UIUtil.set_active(self._btn_exchange, false)
  UIUtil.set_active(self._btn_owner, is_item_owned)
  UIUtil.set_active(self._btn_go_draw, not is_item_owned)
  self._btn_owner.interactable = false
end

function M:_on_do_go_draw_click()
  self:close_self()
  gacha_module:open_main_page(gacha_module:get_cur_gacha_id())
end

return M
