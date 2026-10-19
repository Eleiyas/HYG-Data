local M = G.Class("GachaDrawShowPage", G.UIWindow)
local base = G.UIWindow
local item_v2_cls = item_module.item_v2_panel_cls_name

function M:init()
  base.init(self)
  self._single_items = {}
  self._ten_items = {}
  self._exchangeable_items = {}
  self.exchangeable_item_index = 0
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_close) then
    self:bind_callback(self._btn_close, pack(self, M._on_click_close))
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  end
  if not_null(self._btn_exchange) then
    self:bind_callback(self._btn_exchange, pack(self, M._on_click_exchange))
  end
  if not_null(self._btn_confirm) then
    self:bind_callback(self._btn_confirm, pack(self, M._on_click_confirm))
  end
end

function M:on_destroy()
  self:_clear_custom_layout_items(self._single_custom_layout, self._single_items)
  self:_clear_custom_layout_items(self._ten_custom_layout, self._ten_items)
  self:_destroy_item_panels(self._exchangeable_items)
  base.on_destroy(self)
end

function M:get_item_cls_path()
  return GachaConst.item_path.draw_result
end

function M:refresh_item(cls, result_info, gacha_id)
  cls:refresh(result_info, gacha_id)
end

function M:_refresh_exchangeable_items(can_exchangeable_infos, can_exchangeable_item_count)
  local item_count = #self._exchangeable_items
  local info_count = math.min(GachaConst.draw_show_exchangeable_item_count, can_exchangeable_item_count)
  local max_count = math.max(item_count, info_count)
  for i = 1, max_count do
    local item = self._exchangeable_items[i]
    if i <= info_count then
      item = self:_create_exchangeable_item(item, can_exchangeable_infos[i])
      self._exchangeable_items[i] = item
      item:set_active(true)
    elseif item then
      item:set_active(false)
    end
  end
end

function M:_create_exchangeable_item(cls, info)
  if cls == nil then
    local obj = self._exchangeable_item_binder:AddItem(0)
    cls = self:add_panel(item_v2_cls, obj)
    local item_btn = cls:get_btn()
    if not_null(item_btn) then
      item_btn.interactable = false
    end
  end
  cls:set_item_data(info.item_id, 1)
  return cls
end

function M:_refresh_items(draw_rsp_lua, custom_layout, items)
  self:_destroy_item_panels(items)
  if is_null(custom_layout) then
    self:on_items_refreshed(items)
    return
  end
  local result_item_cls = self:get_item_cls_path()
  local result_infos = draw_rsp_lua.result_infos
  custom_layout:ReLoad(function(item, index)
    local data = result_infos[index + 1]
    if is_null(data) then
      UIUtil.set_active(item, false)
      return
    end
    local cls = self:add_panel(result_item_cls, item)
    table.insert(items, cls)
    self:refresh_item_active(cls)
    self:refresh_item(cls, data, draw_rsp_lua.gacha_id)
  end)
  self:on_items_refreshed(items)
end

function M:refresh_item_active(cls)
  cls:set_active(true)
end

function M:on_items_refreshed(items)
  self:_check_all_collect()
end

function M:_clear_custom_layout_items(custom_layout, items)
  self:_destroy_item_panels(items)
  if is_null(custom_layout) then
    return
  end
  custom_layout:Clear()
end

function M:_destroy_item_panels(items)
  for k, cls in pairs(items) do
    if cls ~= nil then
      self:remove_panel(cls)
    end
    items[k] = nil
  end
end

function M:refresh()
  local last_draw_rsp_lua = gacha_module:get_last_draw_rsp_lua()
  if last_draw_rsp_lua == nil or last_draw_rsp_lua.result_infos == nil then
    self:_on_click_close()
    return
  end
  self._gacha_id = last_draw_rsp_lua.gacha_id
  local results = last_draw_rsp_lua.result_infos
  local is_ten = 1 < #results
  if is_ten then
    self:_refresh_items(last_draw_rsp_lua, self._ten_custom_layout, self._ten_items)
  else
    self:_refresh_items(last_draw_rsp_lua, self._single_custom_layout, self._single_items)
  end
  UIUtil.set_active(self._ten_custom_layout, is_ten)
  UIUtil.set_active(self._single_custom_layout, not is_ten)
  self:refresh_coin(self._gacha_id, last_draw_rsp_lua.result_infos)
  self:_refresh_exchange()
end

function M:refresh_coin(gacha_id, result_infos)
end

function M:_close_process_page()
end

function M:_refresh_exchange()
  local cur_gacha_id = self._gacha_id
  local activity_cfg = gacha_module:get_activity_cfg(cur_gacha_id)
  if activity_cfg == nil then
    return
  end
  local is_furniture = activity_cfg.subtab == GachaConst.sub_tab.furniture
  local exchange_text_id = is_furniture and "Gacha_T0_MainScreen_Exchange_Furniture" or "Gacha_T0_MainScreen_Exchange_Cloth"
  UIUtil.set_text_by_id(self._txt_exchange, exchange_text_id)
  local progress_text_id = "Gacha_T0_ClothShop_SuitColloection"
  local is_suit = activity_cfg.tab == GachaConst.tab.t0 and not is_furniture
  if is_suit then
    progress_text_id = "Gacha_Common_SuitCollection_Show"
  end
  local owned, total = gacha_module:get_collect_progress(cur_gacha_id)
  if not_null(self._txt_progress) then
    UIUtil.set_text_by_id(self._txt_progress, progress_text_id, owned, total)
  end
  if not_null(self._progress_bar) then
    local ratio = 0 < total and owned / total or 0
    self._progress_bar.value = ratio
  end
  local can_exchangeable_infos, can_exchangeable_item_count = gacha_module:get_can_exchangeable_infos(cur_gacha_id)
  local can_exchangeable = 0 < can_exchangeable_item_count
  self._state_group_exchange:SetState(can_exchangeable and 1 or 0)
  if not can_exchangeable then
    return
  end
  local exchangeable_item_info = can_exchangeable_infos[1]
  self.exchangeable_item_index = exchangeable_item_info and exchangeable_item_info.index or 0
  local show_count_text = ""
  if can_exchangeable_item_count > GachaConst.draw_show_exchangeable_item_count then
    show_count_text = UIUtil.get_text_by_id("Gacha_Common_MoreItem_Tips")
  end
  UIUtil.set_text(self._txt_exchangeable_num, show_count_text)
  UIUtil.set_active(self._img_more, 3 < can_exchangeable_item_count)
  self:_refresh_exchangeable_items(can_exchangeable_infos, can_exchangeable_item_count)
end

function M:_check_all_collect()
  local last_draw_rsp_lua = gacha_module:get_last_draw_rsp_lua()
  if last_draw_rsp_lua ~= nil and last_draw_rsp_lua.is_all_collected == true then
    gacha_module:open_all_collect_banner(last_draw_rsp_lua.gacha_id)
  end
end

function M:_on_click_exchange()
  self:_close_handler()
  gacha_module:open_exchange_page(self.exchangeable_item_index)
end

function M:_on_click_confirm()
  self:_close_handler()
end

function M:_on_click_close()
  self:_close_handler()
end

function M:_close_handler()
  self:close_self()
end

return M
