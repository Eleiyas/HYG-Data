local M = G.Class("NpcClothMachineShopItem", G.UIBase)
local base = G.UIBase
local ENTER_ANIMATION_NAME = "anim_npcclothgeliansellpage_item_in"
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
local purchase_state = {normal = 0, in_cart = 1}

function M:on_create()
  base.on_create(self)
  self._is_pointer_click = false
  self:bind_callback(self._btn_item, pack(self, M._on_btn_item_click))
  if self._btn_item and self._btn_item.onClick then
    self._btn_item_pointer_click_callback = pack(self, M._on_btn_item_pointer_click)
    self._btn_item.onClick:AddListener(self._btn_item_pointer_click_callback)
  end
end

function M:on_destroy()
  if self._btn_item and self._btn_item.onClick and self._btn_item_pointer_click_callback then
    self._btn_item.onClick:RemoveListener(self._btn_item_pointer_click_callback)
    self._btn_item_pointer_click_callback = nil
  end
  base.on_destroy(self)
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
  if self._btn_item and self._btn_item.SetIsOnWithoutNotify then
    self._btn_item:SetIsOnWithoutNotify(false)
  end
  local item_cfg = item_module:get_cfg_by_id(goods.ItemID)
  self._item_cfg = item_cfg
  if not item_cfg then
    self:set_active(false)
    return
  end
  UIUtil.set_text(self._txt_name, item_cfg.name or "")
  UIUtil.set_image(self._img_icon, item_cfg.tooltableicon or item_cfg.icon, self:get_load_proxy())
  if not_null(self._state_quality) then
    self._state_quality:SetState(item_cfg.rank or 0)
  end
  UIUtil.set_text(self._txt_price, goods.Price or 0)
  self._view_state = self:_build_view_state(goods, self._context)
  self:_refresh_limited_time()
  self:_refresh_tag_state(self._view_state)
  self:_refresh_lock_state(self._view_state)
  self:_refresh_purchase_state(self._view_state)
  self:_refresh_selected_state(self._view_state)
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

function M:get_goods_key()
  return npc_cloth_module.get_goods_key(self._goods)
end

function M:replay_enter_animation()
  self:play_anim(ENTER_ANIMATION_NAME)
end

function M:need_limited_time_refresh()
  return self._goods ~= nil and self._view_state ~= nil and self._view_state.is_limited_time == true
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
  if self._view_state then
    self._view_state.is_limited_time = is_limited
  end
end

function M:_refresh_tag_state(view_state)
  if not self._state_group_tag then
    return
  end
  if view_state.is_npc_only then
    self._state_group_tag:SetState(tag_state.npc_only)
    local npc_cfg = ExcelDataUtil.get_value(typeof(BNpcCfg), view_state.npc_id)
    if npc_cfg and self._img_npc then
      UIUtil.set_image(self._img_npc, npc_cfg.iconnamesmall, self:get_load_proxy())
    end
  elseif view_state.is_hot then
    self._state_group_tag:SetState(tag_state.hot)
  else
    self._state_group_tag:SetState(tag_state.normal)
  end
end

function M:_refresh_lock_state(view_state)
  if not self._state_group_lock then
    return
  end
  if view_state.is_not_wearable then
    self._state_group_lock:SetState(lock_state.not_wearable)
  elseif view_state.is_locked then
    self._state_group_lock:SetState(lock_state.locked)
  else
    self._state_group_lock:SetState(lock_state.normal)
  end
end

function M:_refresh_purchase_state(view_state)
  if not self._state_group_purchase then
    return
  end
  self._state_group_purchase:SetState(view_state.is_in_cart and purchase_state.in_cart or purchase_state.normal)
end

function M:_refresh_selected_state(view_state)
  if self._btn_item and self._btn_item.SetIsOnWithoutNotify then
    self._btn_item:SetIsOnWithoutNotify(view_state.is_selected == true)
  end
end

function M:_build_view_state(goods, context)
  local npc_id = npc_cloth_module.get_outfit_npc_id(goods)
  local is_not_wearable = self:_is_not_wearable(goods, context)
  local is_sold_out = (goods.ItemCount or 0) == 0
  local is_in_cart = self:_is_goods_in_cart(goods, context)
  local is_selected = self:_is_latest_selected_goods(goods, context)
  local is_protocol_locked = npc_cloth_module.is_goods_protocol_locked(goods)
  return {
    is_hot = goods.IsHot == true,
    is_npc_only = 0 < npc_id,
    npc_id = npc_id,
    is_limited_time = false,
    is_not_wearable = is_not_wearable,
    is_locked = is_sold_out or is_protocol_locked,
    is_sold_out = is_sold_out,
    is_protocol_locked = is_protocol_locked,
    is_selected = is_selected,
    is_in_cart = is_in_cart
  }
end

function M:_is_not_wearable(goods, context)
  if context == nil or context.mannequin_shape == nil then
    return false
  end
  return not npc_cloth_module.is_goods_wearable_by_shape(goods, context.mannequin_shape)
end

function M:_is_goods_in_cart(goods, context)
  local selected_goods_id_map = context and context.selected_goods_id_map or nil
  if not selected_goods_id_map then
    return false
  end
  return selected_goods_id_map[npc_cloth_module.get_goods_key(goods)] == true
end

function M:_is_latest_selected_goods(goods, context)
  local latest_goods = context and context.latest_selected_goods or nil
  if latest_goods == nil or goods == nil then
    return false
  end
  return npc_cloth_module.get_goods_key(latest_goods) == npc_cloth_module.get_goods_key(goods)
end

function M:_on_btn_item_click(is_on)
  if not self._goods or not self._view_state then
    self._is_pointer_click = false
    return
  end
  if is_on == false and self._view_state.is_in_cart ~= true and self._is_pointer_click ~= true then
    self._is_pointer_click = false
    return
  end
  self._is_pointer_click = false
  if not self._view_state.is_in_cart and self._view_state.is_not_wearable then
    self:_show_not_wearable_tip()
    if self._btn_item and self._btn_item.SetIsOnWithoutNotify then
      self._btn_item:SetIsOnWithoutNotify(self._view_state.is_selected == true)
    end
    return
  end
  if not self._view_state.is_in_cart and self._view_state.is_sold_out then
    if self._btn_item and self._btn_item.SetIsOnWithoutNotify then
      self._btn_item:SetIsOnWithoutNotify(self._view_state.is_selected == true)
    end
    return
  end
  if self._context and self._context.on_click_item then
    self._context.on_click_item(self._goods, self._view_state)
  end
end

function M:_on_btn_item_pointer_click()
  self._is_pointer_click = true
end

local SHAPE_SIZE_LABEL = {
  [1] = "S",
  [2] = "M",
  [3] = "L"
}

function M:_show_not_wearable_tip()
  local shape = self._context and self._context.mannequin_shape or 0
  local size_label = SHAPE_SIZE_LABEL[tonumber(shape) or 0] or ""
  UIUtil.show_tips_by_text_id("NpcCloth_Machine_NotWearable_SizeTip", size_label)
end

return M
