local M = G.Class("AvatarInfoSaleDialog", G.UIWindow)
local base = G.UIWindow
local SaleBoxSocialInfoView = require("UI/Social/SaleBoxSocialInfoView")
local FOOD_ITEM_MAX_SHOW = 3
local SALE_BOX_MIN_SHOW = 3

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Social/AvatarInfoSalePanel"
  self.config.type = EUIType.Dialog
  self._query_token = 0
  self._view_data = nil
  self._food_item_cls_list = {}
  self._box_item_cls_map = {}
  self._is_scroller_init = false
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close)
end

function M:on_enable()
  base.on_enable(self)
  self:_query_info()
end

function M:on_disable()
  base.on_disable(self)
  self._query_token = self._query_token + 1
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnSocialPlayerInfoChangeNotify, pack(self, M._on_social_player_info_change))
end

function M:_on_social_player_info_change(notify)
  if is_null(notify) then
    return
  end
  local uid = self._extra_data ~= nil and self._extra_data.uid or 0
  if uid == 0 or notify.Uid ~= uid then
    return
  end
  self:_query_info()
end

function M:_query_info()
  local uid = self._extra_data ~= nil and self._extra_data.uid or 0
  if uid == 0 then
    self:_refresh_view(nil)
    return
  end
  self._query_token = self._query_token + 1
  local token = self._query_token
  SaleBoxSocialInfoView.query(uid, true, function(view_data)
    if token ~= self._query_token then
      return
    end
    self:_refresh_view(view_data)
  end)
end

function M:_refresh_view(view_data)
  self._view_data = view_data
  if not is_null(view_data) and view_data.stall ~= nil then
    social_module:mark_stall_snapshot_viewed(view_data.uid, view_data.stall.snapshot_time)
  end
  self:_refresh_header(view_data)
  self:_refresh_market(view_data)
  self:_refresh_sale_box(view_data)
end

function M:_refresh_header(view_data)
  if is_null(view_data) then
    UIUtil.set_text(self._txt_name_dynamic, "")
    UIUtil.set_player_avatar(self._img_head, 0, self:get_load_proxy())
    self._state_group_local:SetState(0)
    return
  end
  UIUtil.set_text(self._txt_name_dynamic, view_data.nickname or "")
  UIUtil.set_player_avatar(self._img_head, view_data.avatar_id, self:get_load_proxy())
  self._state_group_local:SetState(view_data.is_online and 1 or 0)
end

function M:_refresh_market(view_data)
  local is_open = not is_null(view_data) and view_data.is_crop_market_open == true
  if not is_open then
    self._state_group_market_empty:SetState(1)
    self:_set_market_time(0)
    self:_refresh_food_items(nil)
    return
  end
  self._state_group_market_empty:SetState(0)
  local market = view_data.market or {}
  self:_set_market_time(market.sync_time)
  self:_refresh_food_items(market.items)
end

function M:_set_market_time(sync_time)
  if sync_time == nil or sync_time <= 0 then
    UIUtil.set_text(self._txt_date_dynamic, "")
    UIUtil.set_text(self._txt_market_time, "")
    return
  end
  local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(sync_time)
  UIUtil.set_text(self._txt_date_dynamic, TextMapFormatUtil.FormatDateYMD(date_time))
  UIUtil.set_text_by_id(self._txt_market_time, "SaleInformation_TodayMarket_UpdateTime", CsUIUtil.FormatServerLocalDate(sync_time, "HH:mm"))
end

function M:_refresh_food_items(items)
  local template_rect = self._trans_food_item
  if is_null(template_rect) then
    return
  end
  local show_count = 0
  if items ~= nil then
    show_count = math.min(#items, FOOD_ITEM_MAX_SHOW)
  end
  for i = show_count + 1, #self._food_item_cls_list do
    local cls = self._food_item_cls_list[i]
    if not is_null(cls) then
      cls:set_active(false)
    end
  end
  if show_count <= 0 then
    template_rect.gameObject:SetActive(false)
    return
  end
  template_rect.gameObject:SetActive(true)
  local base_x = template_rect.anchoredPosition.x
  local base_y = template_rect.anchoredPosition.y
  local item_height = template_rect.rect.height
  local uid = self._extra_data ~= nil and self._extra_data.uid or 0
  for i = 1, show_count do
    local cls = self._food_item_cls_list[i]
    if is_null(cls) then
      local item_go = i == 1 and template_rect.gameObject or UIUtil.load_prefab_set_parent(template_rect, self._trans_food_parent, string.format("food_item_%d", i))
      if 1 < i then
        item_go.transform:SetAnchoredPos(base_x, base_y - (i - 1) * item_height)
      end
      cls = self:add_panel("UI/Social/AvatarInfoSaleFoodItem", item_go.transform, {uid = uid})
      self._food_item_cls_list[i] = cls
    end
    cls:set_active(true)
    cls:refresh(items[i])
  end
end

function M:_refresh_sale_box(view_data)
  local is_unlocked = not is_null(view_data) and view_data.is_stall_unlocked == true
  if not is_unlocked then
    self._state_group_sale_box_empty:SetState(1)
    self:_set_sale_box_time(0)
    self:_refresh_box_items(nil)
    return
  end
  self._state_group_sale_box_empty:SetState(0)
  local stall = view_data.stall or {}
  local slot_count = stall.slots ~= nil and #stall.slots or 0
  if slot_count <= 0 then
    self:_set_sale_box_time(0)
    self:_refresh_box_items(stall.slots or {})
    return
  end
  UIUtil.set_active(self._trans_box_empty_group, false)
  self:_set_sale_box_time(stall.snapshot_time)
  self:_refresh_box_items(stall.slots)
end

function M:_set_sale_box_time(snapshot_time)
  if snapshot_time == nil or snapshot_time <= 0 then
    UIUtil.set_text(self._txt_box_time, "")
    return
  end
  UIUtil.set_text_by_id(self._txt_box_time, "SaleInformation_TodayMarket_UpdateTime", CsUIUtil.FormatServerLocalDate(snapshot_time, "HH:mm"))
end

function M:_refresh_box_items(slots)
  local count = slots ~= nil and #slots or 0
  if slots ~= nil then
    count = math.max(count, SALE_BOX_MIN_SHOW)
  end
  if self._is_scroller_init then
    self._grid_scroller_sale_box:ReLoad(pack(self, M._refresh_box_item), count)
    self._grid_scroller_sale_box:MoveTo(0)
  else
    self._grid_scroller_sale_box:Init(pack(self, M._refresh_box_item), count)
    self._is_scroller_init = true
  end
end

function M:_refresh_box_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local cls = self._box_item_cls_map[instance_id]
  if is_null(cls) then
    cls = self:add_panel("UI/Social/AvatarInfoSaleBoxItem", trans)
    self._box_item_cls_map[instance_id] = cls
  end
  local stall = self._view_data ~= nil and self._view_data.stall or nil
  local slots = stall ~= nil and stall.slots or nil
  cls:refresh(slots ~= nil and slots[index] or nil)
end

return M
