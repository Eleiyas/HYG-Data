local M = G.Class("NpcClothGelianShopItem", G.UIBase)
local base = G.UIBase
local tag_state = {
  normal = 0,
  hot = 1,
  npc_only = 2
}
local lock_state = {
  normal = 0,
  locked = 1,
  not_wearable = 2
}
local limited_time_state = {normal = 0, limited = 1}

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_item, pack(self, M._on_btn_item_click))
end

function M:refresh(goods, context)
  self._goods = goods
  self._context = context or {}
  self._view_state = nil
  if is_null(goods) then
    self:set_active(false)
    return
  end
  self:set_active(true)
  self._btn_item:SetIsOnWithoutNotify(false)
  local item_cfg = item_module:get_cfg_by_id(goods.ItemID)
  self._item_cfg = item_cfg
  if not item_cfg then
    self:set_active(false)
    return
  end
  UIUtil.set_text(self._txt_name, item_cfg.name or "")
  UIUtil.set_image(self._img_icon, item_cfg.tooltableicon or item_cfg.icon, self:get_load_proxy())
  if self._state_quality then
    self._state_quality:SetState(item_cfg.rank or 0)
  end
  UIUtil.set_text(self._txt_price, goods.Price or 0)
  self._npc_id = npc_cloth_module.get_outfit_npc_id(goods)
  self._is_sold_out = (goods.ItemCount or 0) == 0
  self._is_protocol_locked = npc_cloth_module.is_goods_protocol_locked(goods)
  self:_refresh_limited_time()
  self:_refresh_tag_state()
  self:_refresh_lock_state()
  self:refresh_tracking_point_state(self._context.tracking_context)
end

function M:refresh_current(context)
  self:refresh(self._goods, context or self._context)
end

function M:has_goods_key(goods_key_map)
  if goods_key_map == nil or self._goods == nil then
    return false
  end
  return goods_key_map[npc_cloth_module.get_goods_key(self._goods)] == true
end

function M:is_active_in_hierarchy()
  return self.game_obj and self.game_obj.activeInHierarchy
end

function M:need_limited_time_refresh()
  return self._goods ~= nil and self._is_limited_time == true
end

function M:refresh_limited_time()
  self:_refresh_limited_time()
end

function M:refresh_tracking_point_state(tracking_context)
  if is_null(self._trans_tracking_item) then
    return
  end
  local item_id = self._goods and self._goods.ItemID or 0
  local item_map = tracking_context and tracking_context.tracking_item_map or nil
  local is_show = 0 < item_id and item_map ~= nil and item_map[item_id] == true
  UIUtil.set_active(self._trans_tracking_item, is_show)
  if is_show and self._ui_state_group_style and tracking_context.tracking_style then
    self._ui_state_group_style:SetState(tracking_context.tracking_style)
  end
end

function M:_refresh_limited_time()
  local close_time = tonumber(self._goods and self._goods.CloseTime or 0) or 0
  local remain_time = close_time - (TimeUtil.ServerUtcTimeSeconds or 0)
  local is_limited = 0 < close_time and 0 < remain_time
  if self._state_group_limited_time then
    self._state_group_limited_time:SetState(is_limited and limited_time_state.limited or limited_time_state.normal)
  end
  if is_limited and self._txt_time then
    UIUtil.set_text(self._txt_time, LuaTimeUtil.get_time_str(math.ceil(remain_time)))
  end
  self._is_limited_time = is_limited
end

function M:_refresh_tag_state()
  if not self._state_group_tag then
    return
  end
  if self._npc_id > 0 then
    self._state_group_tag:SetState(tag_state.npc_only)
    local npc_cfg = ExcelDataUtil.get_value(typeof(BNpcCfg), self._npc_id)
    if npc_cfg and self._img_npc then
      UIUtil.set_image(self._img_npc, npc_cfg.iconnamesmall, self:get_load_proxy())
    end
  elseif self._goods and self._goods.IsHot == true then
    self._state_group_tag:SetState(tag_state.hot)
  else
    self._state_group_tag:SetState(tag_state.normal)
  end
end

function M:_refresh_lock_state()
  if not self._state_group_lock then
    return
  end
  if self._is_sold_out or self._is_protocol_locked then
    self._state_group_lock:SetState(lock_state.locked)
  else
    self._state_group_lock:SetState(lock_state.normal)
  end
end

function M:_on_btn_item_click(is_on)
  if is_on == false then
    return
  end
  if not self._goods then
    return
  end
  if self._is_sold_out or self._is_protocol_locked then
    self._btn_item:SetIsOnWithoutNotify(false)
    if self._is_protocol_locked then
      UIUtil.show_tips_by_text_id("NpcCloth_AddGoods_Lock_Tip")
    end
    return
  end
  if self._context and self._context.on_click_buy then
    self._context.on_click_buy(self._goods)
  elseif self._context and self._context.on_click_item then
    self._context.on_click_item(self._goods)
  end
  self._btn_item:SetIsOnWithoutNotify(false)
end

return M
