local M = G.Class("SpringFestivalShoppingListPanel", G.UIPanel)
local base = G.UIPanel
local group_panel_cls = "UI/MainActivity_y1/SpringFestival/TasselShop/SpringFestivalShoppingListGroupPanel"

function M:init()
  base.init(self)
  self._group_panel = nil
  self._on_select_goods = nil
  self._is_close = false
  self._need_refresh_time = false
  self.next_refresh_second = 0
end

function M:on_create()
  base.on_create(self)
  local data = self:get_extra_data() or {}
  self._on_select_goods = data.on_select_goods
  local group_host = self._obj_item_group or self._layout_listgroup or self._layout_list_group or self._layout_list
  if group_host ~= nil then
    self._group_panel = self:add_panel(group_panel_cls, group_host, {
      on_select_goods = pack(self, M._on_item_selected)
    })
    self._group_panel:set_active(true)
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

function M:refresh_list(goods_list, selected_goods_id, scroll_pos)
  if self._group_panel == nil then
    return
  end
  self._group_panel:refresh(goods_list or {}, selected_goods_id or 0)
  if scroll_pos ~= nil then
    local scroll = self._scroll_rect or self._scroll_view or self._scroll_list or self._scroll_left
    if LayoutRebuilder ~= nil and scroll ~= nil and scroll.content ~= nil then
      LayoutRebuilder.ForceRebuildLayoutImmediate(scroll.content)
    end
    self:set_scroll_position(scroll_pos)
  end
end

function M:refresh_selected(selected_goods_id)
  if self._group_panel == nil then
    return
  end
  self._group_panel:refresh_selected(selected_goods_id or 0)
end

function M:refresh_notice_by_goods(goods)
  self:_set_sub_notice_normal_mode(false)
  self._need_refresh_time = false
end

function M:scroll_to_top()
  local scroll = self._scroll_rect or self._scroll_view or self._scroll_list or self._scroll_left
  if scroll ~= nil and scroll.verticalNormalizedPosition ~= nil then
    scroll.verticalNormalizedPosition = 1
    return
  end
  local group = self._obj_item_group or self._layout_listgroup or self._layout_list_group or self._layout_list
  if group ~= nil and group.GetComponent ~= nil then
    local scroll_rect = group:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
    if not_null(scroll_rect) then
      scroll_rect.verticalNormalizedPosition = 1
    end
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
    return
  end
  local group = self._obj_item_group or self._layout_listgroup or self._layout_list_group or self._layout_list
  if group ~= nil and group.GetComponent ~= nil then
    local scroll_rect = group:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
    if not_null(scroll_rect) then
      if scroll_rect.verticalScrollbar ~= nil then
        scroll_rect.verticalScrollbar.value = pos
      else
        scroll_rect.verticalNormalizedPosition = pos
      end
    end
  end
end

function M:_on_bag_change()
  if self._is_close then
    return
  end
  if self._group_panel ~= nil then
    self._group_panel:refresh_tracking_point_state()
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
  local seconds = self.next_refresh_second or 0
  if seconds < 0 then
    seconds = 0
  end
  local hours = math.floor(seconds / 3600)
  local remaining_seconds = seconds % 3600
  local minutes = math.floor(remaining_seconds / 60)
  UIUtil.set_text_by_id(self._text_time, "TVShopping_time_refresh", hours, minutes)
end

return M
