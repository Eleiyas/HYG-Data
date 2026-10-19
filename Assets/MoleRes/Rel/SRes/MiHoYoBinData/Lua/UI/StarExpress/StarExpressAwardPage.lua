local M = G.Class("StarExpressAwardPage", G.UIWindow)
local base = G.UIWindow
local level_award_item_cls_name = "UI/StarExpress/StarExpressAwardLevelItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/StarExpress/StarExpressAwardPage"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  self._level_award_items = {}
  if self._obj_lv_award_common_item ~= nil then
    UIUtil.set_active(self._obj_lv_award_common_item.transform, false)
  end
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_ui()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  if self._btn_back ~= nil then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_back)
  end
end

function M:_refresh_ui()
  local rider_level = star_express_module:get_rider_level()
  local rider_cfg = star_express_module:get_rider_level_cfg(rider_level)
  local history = star_express_module:get_history()
  if self._txt_lv ~= nil then
    UIUtil.set_text(self._txt_lv, TextMapFormatUtil.FormatInteger(rider_level))
  end
  if self._txt_lv_name ~= nil then
    UIUtil.set_text_by_id(self._txt_lv_name, rider_cfg ~= nil and rider_cfg.titlename or "")
  end
  if self._txt_next_level_num ~= nil then
    local cur_count = history.total_count or 0
    local next_required = star_express_module:get_rider_level_required_orders(rider_level + 1)
    local remain = 0
    if next_required ~= nil and cur_count <= next_required then
      remain = next_required - cur_count
    end
    UIUtil.set_text_by_id(self._txt_next_level_num, "StarExpress_RiderLevel_OrderToGo2", remain)
  end
  if self._txt_complete_num ~= nil then
    UIUtil.set_text(self._txt_complete_num, TextMapFormatUtil.FormatInteger(history.total_count or 0))
  end
  if self._txt_complete_exo_num ~= nil then
    UIUtil.set_text(self._txt_complete_exo_num, TextMapFormatUtil.FormatInteger(history.universe_count or 0))
  end
  if self._txt_coin_num ~= nil then
    UIUtil.set_text(self._txt_coin_num, TextMapFormatUtil.FormatInteger(history.total_money or 0))
  end
  self:_refresh_level_award_items(rider_level)
end

function M:_get_level_award_item(index)
  if self._level_award_items[index] ~= nil then
    return self._level_award_items[index]
  end
  local go = index == 1 and self._obj_lv_award_common_item or UIUtil.load_prefab_set_parent(self._obj_lv_award_common_item, self._trans_parent)
  local item_cls = self:add_panel(level_award_item_cls_name, go.transform)
  self._level_award_items[index] = item_cls
  return item_cls
end

function M:_refresh_level_award_items(cur_level)
  if self._obj_lv_award_common_item == nil then
    return
  end
  local cfg_list = star_express_module:get_rider_level_cfg_list()
  for index, cfg in ipairs(cfg_list) do
    local item_cls = self:_get_level_award_item(index)
    item_cls:refresh(cfg, cur_level, index, #cfg_list)
  end
  for index = #cfg_list, 1, -1 do
    self._level_award_items[index].trans:SetSiblingIndex(#cfg_list - index)
  end
  for i = #cfg_list + 1, #self._level_award_items do
    self._level_award_items[i]:set_active(false)
  end
  for index = 1, #cfg_list do
    self._level_award_items[index]:play_item_enter_anim()
  end
end

function M:play_exit_anim()
  for _, item_cls in ipairs(self._level_award_items) do
    if item_cls.is_active then
      item_cls:play_item_exit_anim()
    end
  end
  base.play_exit_anim(self)
end

function M:_add_ui_listener()
  if self._btn_back ~= nil then
    self:bind_callback(self._btn_back, pack(self, M._on_btn_close_click))
  end
end

function M:_on_btn_close_click()
  self:close_self()
end

return M
