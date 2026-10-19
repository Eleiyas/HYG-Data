local M = G.Class("SpringFestivalCoinShoppingListPanel", G.UIPanel)
local base = G.UIPanel
local group_panel_cls = "UI/MainActivity_y1/SpringFestival/CoinShop/SpringFestivalCoinShoppingListGroupPanel"

function M:init()
  base.init(self)
  self._group_panels = {}
  self._on_select_goods = nil
  self._is_close = false
  self._need_refresh_time = false
  self._notice_goods = nil
  self.next_refresh_second = 0
end

function M:on_create()
  base.on_create(self)
  local data = self:get_extra_data() or {}
  self._on_select_goods = data.on_select_goods
  if not is_null(self._obj_item_group) then
    UIUtil.set_active(self._obj_item_group, false)
  end
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  self._need_refresh_time = false
  self:_set_sub_notice_normal_mode(false)
end

function M:on_disable()
  base.on_disable(self)
  self._is_close = true
  self._need_refresh_time = false
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaChangePacket, pack(self, M._on_bag_change))
end

function M:set_extra_data(data)
  base.set_extra_data(self, data)
  data = data or {}
  self._on_select_goods = data.on_select_goods
end

function M:_on_item_selected(goods, card_item)
  if self._on_select_goods ~= nil then
    self._on_select_goods(goods, card_item)
  end
end

function M:refresh_list(group_list, selected_goods_id, scroll_pos)
  group_list = group_list or {}
  selected_goods_id = selected_goods_id or 0
  for i, group_data in ipairs(group_list) do
    local panel = self._group_panels[i]
    if panel == nil then
      local obj = UIUtil.load_prefab_set_parent(self._obj_item_group, self._trans_content)
      panel = self:add_panel(group_panel_cls, obj, {
        on_select_goods = pack(self, M._on_item_selected)
      })
      self._group_panels[i] = panel
    end
    panel:set_active(true)
    panel:refresh(group_data.goods_list or {}, selected_goods_id, group_data.tab_name)
  end
  for i = #group_list + 1, #self._group_panels do
    if self._group_panels[i] ~= nil then
      self._group_panels[i]:set_active(false)
    end
  end
  if scroll_pos ~= nil then
    local scroll = self._scroll_rect or self._scroll_view or self._scroll_list or self._scroll_left
    if LayoutRebuilder ~= nil and scroll ~= nil and scroll.content ~= nil then
      LayoutRebuilder.ForceRebuildLayoutImmediate(scroll.content)
    end
    self:set_scroll_position(scroll_pos)
  end
end

function M:refresh_selected(selected_goods_id)
  selected_goods_id = selected_goods_id or 0
  for _, panel in ipairs(self._group_panels) do
    if panel ~= nil and panel.is_active then
      panel:refresh_selected(selected_goods_id)
    end
  end
end

function M:refresh_notice_by_goods(goods)
  self._notice_goods = goods
  local is_last_day = goods ~= nil and goods.is_activity_last_day == true and 0 < (goods.unlock_timestamp or 0)
  if not is_null(self._ui_state_group_layout_sub_notice) then
    self._ui_state_group_layout_sub_notice:SetState(0)
  end
  if not is_null(self._trans_icon) then
    UIUtil.set_active(self._trans_icon, is_last_day)
  end
  if not is_null(self._text_time) then
    UIUtil.set_active(self._text_time, is_last_day)
    if is_last_day then
      self:_refresh_notice_time_text()
    else
      self._last_notice_time_text = nil
    end
  end
  self._need_refresh_time = false
end

function M:refresh_notice_countdown()
  local goods = self._notice_goods
  if goods == nil or goods.is_activity_last_day ~= true then
    return
  end
  if is_null(self._text_time) then
    return
  end
  self:_refresh_notice_time_text()
end

function M:scroll_to_top()
  local scroll = self._scroll_rect or self._scroll_view or self._scroll_list or self._scroll_left
  if scroll ~= nil and scroll.verticalNormalizedPosition ~= nil then
    scroll.verticalNormalizedPosition = 1
  end
end

function M:get_scroll_position()
  local scroll = self._scroll_rect or self._scroll_view or self._scroll_list or self._scroll_left
  if scroll ~= nil and scroll.verticalScrollbar ~= nil then
    return scroll.verticalScrollbar.value
  end
  if scroll ~= nil and scroll.verticalNormalizedPosition ~= nil then
    return scroll.verticalNormalizedPosition
  end
  return nil
end

function M:set_scroll_position(pos)
  if pos == nil then
    return
  end
  local scroll = self._scroll_rect or self._scroll_view or self._scroll_list or self._scroll_left
  if scroll ~= nil and scroll.verticalNormalizedPosition ~= nil then
    scroll.verticalNormalizedPosition = pos
    if scroll.verticalScrollbar ~= nil then
      scroll.verticalScrollbar.value = pos
    end
  end
end

function M:_on_bag_change()
  if self._is_close then
    return
  end
  for _, panel in ipairs(self._group_panels) do
    if panel ~= nil and panel.is_active and panel.refresh_tracking_point_state ~= nil then
      panel:refresh_tracking_point_state()
    end
  end
end

function M:_set_sub_notice_normal_mode(show_time)
  if not is_null(self._ui_state_group_layout_sub_notice) then
    self._ui_state_group_layout_sub_notice:SetState(0)
  end
  if not is_null(self._text_time) then
    UIUtil.set_active(self._text_time, show_time)
  end
  if not is_null(self._trans_icon) then
    UIUtil.set_active(self._trans_icon, show_time)
  end
end

function M:_refresh_notice_time_text()
  if is_null(self._text_time) then
    return
  end
  local goods = self._notice_goods
  if goods == nil then
    return
  end
  local remain_seconds = spring_festival_coin_shop_module:calc_remain_seconds_by_ts(goods.unlock_timestamp or 0)
  local time_text = UIUtil.format_left_time(remain_seconds)
  if self._last_notice_time_text == time_text then
    return
  end
  self._last_notice_time_text = time_text
  UIUtil.set_text_by_id(self._text_time, "SpringFestival_Shopping_Coinstore_03", time_text)
end

return M
