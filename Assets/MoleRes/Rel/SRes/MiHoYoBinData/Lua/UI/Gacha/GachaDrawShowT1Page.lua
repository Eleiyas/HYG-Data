local base = require("UI/Gacha/GachaDrawShowPage")
local M = G.Class("GachaDrawShowT1Page", base)

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.panel_path.draw_show_t1
  self.config.type = EUIType.Dialog
end

function M:on_enable()
  base.on_enable(self)
  self:refresh()
end

function M:on_disable()
  base.on_disable(self)
  gacha_module:set_is_in_draw_show(false)
end

function M:on_close()
  base.on_close(self)
  self:_close_process_page()
  gacha_module:set_last_draw_rsp_lua(nil)
end

function M:get_item_cls_path()
  return item_module.item_v2_panel_cls_name
end

function M:refresh_item(cls, result_info, gacha_id)
  local item_id = result_info.ItemId or 0
  local count = result_info.Count or 0
  cls:set_item_data(item_id, count)
  cls:bind_item_info_btn(item_id)
  if not_null(cls._img_bg_crit) then
    local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
    local pool_cfg = activity_cfg and gacha_module:get_pool_cfg(activity_cfg.gachapoolid, result_info.SlotIndex)
    if pool_cfg then
      UIUtil.set_active(cls._img_bg_crit, pool_cfg.coingachalevel < GachaConst.fragment_draw_level.no_guarantee)
    else
      UIUtil.set_active(cls._img_bg_crit, false)
    end
  end
end

function M:refresh_coin(gacha_id, result_infos)
  if result_infos == nil or result_infos[1] == nil then
    return
  end
  local item_id = result_infos[1].ItemId or 0
  if not_null(self._img_icon_gained) and 0 < item_id then
    item_module:set_item_icon(self._img_icon_gained, item_id, nil, nil, self:get_load_proxy())
  end
  local total_gained = 0
  for _, result_info in ipairs(result_infos) do
    total_gained = total_gained + result_info.Count
  end
  if not_null(self._txt_num_gained) then
    UIUtil.set_text(self._txt_num_gained, tostring(total_gained))
  end
  local activity_cfg = gacha_module:get_activity_cfg(gacha_id)
  local is_furniture = activity_cfg and activity_cfg.subtab == GachaConst.sub_tab.furniture
  if not_null(self._txt_total_tip) then
    UIUtil.set_text_by_id(self._txt_total_tip, is_furniture and "Gacha_T1_Furniture_Desc_01" or "Gacha_T1_Cloth_Desc_01")
  end
  if not_null(self._txt_title) then
    UIUtil.set_text_by_id(self._txt_title, is_furniture and "Gacha_T1_Furniture_ResultTitle" or "Gacha_T1_Cloth_ResultTitle")
  end
end

function M:_close_process_page()
  local activity_cfg = gacha_module:get_activity_cfg(self._gacha_id)
  if activity_cfg == nil then
    return
  end
  local page_path = activity_cfg.subtab == GachaConst.sub_tab.cloth and GachaConst.page_path.process_cloth_t1 or GachaConst.page_path.process_furniture_t1
  local result_page = UIManagerInstance:get_window_by_class(page_path)
  if result_page then
    result_page:close_self()
  end
end

return M
