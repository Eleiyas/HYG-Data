local M = G.Class("NpcClothMachineSellPage", G.UIWindow)
local base = G.UIWindow
local SHOP_PANEL_CLS = "UI/NpcCloth/NpcClothMachineShopPanel"
local MANNEQUIN_PANEL_CLS = "UI/NpcCloth/NpcClothMannequinPanel"
local DESC_PANEL_CLS = "UI/NpcCloth/NpcClothMachineDescPanel"
local SIZE_GROUP_PANEL_CLS = "UI/NpcCloth/NpcClothMachineSizeGroupPanel"
local PRESET_PANEL_CLS = "UI/NpcCloth/NpcClothMachinePresetPanel"
local DEFAULT_NPC_LIST_PLAYER_CFG_ID = 209
local INTRODUCTION_ID = 25
local MODEL_INTRODUCTION_ID = 32
local MAX_BUY_NUM = 99
local NPC_ROOT_FIELD_BY_SHAPE = {
  [1] = "_trans_npc_root_s",
  [2] = "_trans_npc_root_m",
  [3] = "_trans_npc_root_l"
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcCloth/NpcClothMachineSellPage"
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_NpcClothMachineSellPage"
  self.config.type = EUIType.Page
  self._view_context = self:_build_view_context()
  self._has_requested_shop_data = false
  self._is_waiting_shop_data = false
  self._shop_request_seq = 0
  self._pending_shop_refresh = false
  self._detail_time_refresh_elapsed = 0
  self._has_bound_help_button = false
  self._is_preview_mode = false
  self._pending_shop_panel_refresh = false
  self._is_preset_dirty = false
  self._scene_binder = nil
  self._scene_binder_scene_obj = nil
end

function M:on_create()
  base.on_create(self)
  if self._btn_close then
    self:bind_callback(self._btn_close, pack(self, M._on_close_click))
  end
  if self._btn_buy then
    self:bind_callback(self._btn_buy, pack(self, M._on_buy_click))
  end
  if self._btn_bag_cloth then
    self:bind_callback(self._btn_bag_cloth, pack(self, M._on_bag_cloth_click))
  end
  if self._btn_preset_save then
    self:bind_callback(self._btn_preset_save, pack(self, M._on_preset_save_click))
  end
  if self._btn_back then
    self:bind_callback(self._btn_back, pack(self, M._on_preset_back_click))
  end
  if self._btn_model_info then
    self:bind_callback(self._btn_model_info, pack(self, M._on_model_info_click))
  end
  self:_ensure_help_button()
  self:_create_child_panels()
  self:_create_coin_panel()
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_coin_panel()
  if self._pending_shop_refresh then
    self._pending_shop_refresh = false
    self:_refresh_panels(self:get_extra_data())
    return
  end
  if self._is_waiting_shop_data then
    return
  end
  if self._mannequin_panel and 0 < (self._view_context.mannequin_npc_id or 0) then
    self:_switch_mannequin(self._view_context.mannequin_npc_id, self._view_context.mannequin_shape)
    return
  end
  self:_refresh_selection_context()
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  local goods = self._view_context and self._view_context.latest_selected_goods or nil
  if is_null(goods) or (goods.CloseTime or 0) <= 0 then
    return
  end
  self._detail_time_refresh_elapsed = (self._detail_time_refresh_elapsed or 0) + deltaTime
  if self._detail_time_refresh_elapsed >= 60 then
    self._detail_time_refresh_elapsed = 0
    if self._desc_panel then
      self._desc_panel:refresh_left_time(goods)
    end
  end
end

function M:on_open()
  base.on_open(self)
  self:show(self:get_extra_data())
end

function M:on_close()
  self:_invalidate_shop_request()
  self:_exit_preset_mode_without_save()
  CsShopModuleUtil.DestroyNpcClothShopMannequin()
  self._scene_binder = nil
  self._scene_binder_scene_obj = nil
  EventCenter.Broadcast(EventID.Performance.OnNpcClothMachineShopPageEnd, 0)
  base.on_close(self)
end

function M:show(data)
  self._has_requested_shop_data = false
  self._is_preview_mode = false
  self._is_preset_dirty = false
  if self._state_group_preview then
    self._state_group_preview:SetState(0)
  end
  self._view_context = self:_build_view_context(data)
  self._view_context.npc_list = self:_build_npc_list(data and data.npc_list)
  if self._mannequin_panel then
    self._mannequin_panel:clear_selection()
  end
  self:_ensure_default_mannequin_presets()
  local is_waiting_shop_data = self:_request_shop_data_once(data)
  if is_waiting_shop_data and self._shop_panel then
    self._shop_panel:clear_shop_groups()
  end
  self:_refresh_selection_context()
  self:_switch_mannequin(self:_get_selected_npc_by_shape(self._view_context.mannequin_shape), self._view_context.mannequin_shape)
  if is_waiting_shop_data then
    return
  end
  self:_refresh_panels(data)
end

function M:_build_view_context(data)
  data = data or {}
  return {
    shop_id = data.shop_id or data.shopId or 0,
    level = data.level or data.shop_level or data.shopLevel or 0,
    mannequin_npc_id = data.npc_id or data.npcId or 0,
    mannequin_shape = data.shape or 1,
    current_category_id = 0,
    selected_goods_by_slot = {},
    selected_goods_id_map = {},
    selected_goods_list = {},
    latest_selected_goods = nil,
    npc_list = {},
    selected_npc_by_shape = self:_normalize_selected_npc_by_shape(data.selected_npc_by_shape or data.default_npc_by_shape or {}),
    tracking_context = {},
    keep_selection_after_buy_guid_map = {}
  }
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.NpcFriendShopDataChange, pack(self, M._on_shop_data_change))
end

function M:_create_child_panels()
  if not self._shop_panel and not is_null(self._obj_shop_content) then
    self._shop_panel = self:add_panel(SHOP_PANEL_CLS, self._obj_shop_content)
  elseif not self._shop_panel then
    Logger.LogError("[NpcClothMachineSellPage] missing binder _obj_shop_content")
  end
  if not self._mannequin_panel and not is_null(self._obj_mannequin_content) then
    self._mannequin_panel = self:add_panel(MANNEQUIN_PANEL_CLS, self._obj_mannequin_content)
  elseif not self._mannequin_panel then
    Logger.LogError("[NpcClothMachineSellPage] missing binder _obj_mannequin_content")
  end
  if not self._desc_panel and not is_null(self._obj_desc_group_root) then
    self._desc_panel = self:add_panel(DESC_PANEL_CLS, self._obj_desc_group_root)
  end
  if not self._size_group_panel and not is_null(self._obj_size_group_root) then
    self._size_group_panel = self:add_panel(SIZE_GROUP_PANEL_CLS, self._obj_size_group_root)
  end
  if not self._preset_panel and not is_null(self._obj_shop_content) then
    self._preset_panel = self:add_panel(PRESET_PANEL_CLS, self._obj_shop_content)
  end
  self:_refresh_mannequin_scene_root()
end

function M:_create_coin_panel()
  if self._coin_panel then
    return
  end
  if not is_null(self._trans_coin_parent) then
    self._coin_panel = self:add_panel(back_bag_module.coin_panel_cls, self._trans_coin_parent)
  end
end

function M:_refresh_coin_panel()
  if not self._coin_panel then
    return
  end
  self._coin_panel:set_coin_data({
    coin_types = {
      back_bag_module.coin_type.npc_cloth_ticket
    },
    is_auto_update = true,
    coin_anim_time = 0.5
  })
end

function M:_refresh_panels(data)
  if self._state_group_preview then
    self._state_group_preview:SetState(0)
  end
  self._is_preview_mode = false
  if not self._shop_panel or not self._mannequin_panel then
    return
  end
  self:_refresh_mannequin_scene_root()
  self._shop_panel:show({
    shop_id = self._view_context.shop_id,
    level = self._view_context.level,
    view_context = self._view_context
  }, self:_get_panel_callbacks())
  self:_refresh_size_group_panel()
  self:_switch_mannequin(self:_get_selected_npc_by_shape(self._view_context.mannequin_shape), self._view_context.mannequin_shape)
end

function M:_request_shop_data_once(show_data)
  if self._has_requested_shop_data or (self._view_context.shop_id or 0) <= 0 then
    return false
  end
  self._has_requested_shop_data = true
  self._is_waiting_shop_data = true
  self._shop_request_seq = (self._shop_request_seq or 0) + 1
  local request_seq = self._shop_request_seq
  local request_shop_id = self._view_context.shop_id
  local request_level = self._view_context.level
  CsShopModuleUtil.NpcFriendShopOpenReq(request_shop_id, request_level, function(retcode)
    if not self:_is_current_shop_request(request_seq, request_shop_id, request_level) then
      return
    end
    self._is_waiting_shop_data = false
    if retcode and retcode <= 0 then
      if self.is_active == false then
        self._pending_shop_refresh = true
        return
      end
      self:_refresh_panels(show_data)
    end
  end)
  return true
end

function M:_invalidate_shop_request()
  self._shop_request_seq = (self._shop_request_seq or 0) + 1
  self._is_waiting_shop_data = false
  self._pending_shop_refresh = false
end

function M:_is_current_shop_request(request_seq, shop_id, level)
  if request_seq ~= self._shop_request_seq then
    return false
  end
  return self._view_context.shop_id == shop_id and self._view_context.level == level
end

function M:_on_shop_data_change()
  if self._is_preview_mode == true then
    self._pending_shop_panel_refresh = true
    return
  end
  if self._shop_panel then
    self._shop_panel:show({
      shop_id = self._view_context.shop_id,
      level = self._view_context.level,
      view_context = self._view_context
    }, self:_get_panel_callbacks())
  end
  self:_reconcile_mannequin_selection()
end

function M:_get_panel_callbacks()
  return {
    on_click_item = pack(self, M._on_click_item)
  }
end

function M:_get_size_group_callbacks()
  return {
    on_click_shape = pack(self, M._on_mannequin_shape_changed),
    on_choose_npc_confirm = pack(self, M._on_choose_npc_confirm)
  }
end

function M:_on_click_item(goods, view_state)
  if not self._mannequin_panel then
    return
  end
  local snapshot = self._mannequin_panel:toggle_goods(goods, view_state)
  self:_apply_selection_snapshot(snapshot)
end

function M:_on_mannequin_shape_changed(shape, npc_id)
  if (npc_id or 0) <= 0 and 0 >= (self:_get_selected_npc_by_shape(shape) or 0) then
    return
  end
  self:_switch_mannequin(npc_id, shape, true)
end

function M:_on_choose_npc_confirm()
  npc_cloth_module.set_selected_npc_by_shape(self._view_context.selected_npc_by_shape or {})
  self:_switch_mannequin(self:_get_selected_npc_by_shape(self._view_context.mannequin_shape), self._view_context.mannequin_shape, true)
end

function M:_switch_mannequin(npc_id, shape, force_refresh_visible_items)
  if not self._mannequin_panel then
    return
  end
  local old_shape = self._view_context.mannequin_shape
  local old_npc_id = self._view_context.mannequin_npc_id
  self._view_context.mannequin_shape = shape or self._view_context.mannequin_shape or 1
  self._view_context.mannequin_npc_id = npc_id or self:_get_selected_npc_by_shape(self._view_context.mannequin_shape)
  self:_refresh_mannequin_scene_root()
  self:_refresh_mannequin_base_preset()
  local snapshot = self._mannequin_panel:set_mannequin(self._view_context.mannequin_npc_id, self._view_context)
  self:_apply_selection_snapshot(snapshot, force_refresh_visible_items == true or old_shape ~= self._view_context.mannequin_shape or old_npc_id ~= self._view_context.mannequin_npc_id)
  if force_refresh_visible_items == true and snapshot and #(snapshot.removed_goods_list or {}) > 0 then
    UIUtil.show_tips_by_text_id("NpcCloth_Machine_SwitchNpc_TakeOffIncompatible_Tips")
  end
  if self._is_preview_mode == true then
    self:_refresh_preset_panel()
  end
end

function M:_apply_selection_snapshot(snapshot, force_refresh_visible_items)
  snapshot = snapshot or {}
  self._view_context.selected_goods_by_slot = snapshot.selected_goods_by_slot or {}
  self._view_context.selected_goods_id_map = snapshot.selected_goods_id_map or {}
  self._view_context.selected_goods_list = snapshot.selected_goods_list or {}
  self._view_context.latest_selected_goods = snapshot.latest_selected_goods
  self:_cleanup_keep_selection_after_buy_guid_map()
  self._detail_time_refresh_elapsed = 0
  self:_refresh_lock_state()
  self:_refresh_selection_context(snapshot.changed_goods_key_map, force_refresh_visible_items)
end

function M:_refresh_lock_state()
  if not is_null(self._state_group_lock) then
    local latest_goods = self._view_context.latest_selected_goods
    local is_locked = latest_goods ~= nil and npc_cloth_module.is_goods_protocol_locked(latest_goods)
    self._state_group_lock:SetState(is_locked == true and 1 or 0)
  end
end

function M:_reconcile_mannequin_selection()
  if not self._mannequin_panel or not self._shop_panel then
    return
  end
  local snapshot = self._mannequin_panel:reconcile_selection(self._shop_panel:get_shop_groups(), self._view_context)
  self:_apply_selection_snapshot(snapshot)
end

function M:_refresh_selection_context(changed_goods_key_map, force_refresh_visible_items)
  if self._shop_panel and self._is_waiting_shop_data ~= true and self._is_preview_mode ~= true then
    if force_refresh_visible_items == true then
      self._shop_panel:refresh_visible_item_context(self._view_context)
    else
      self._shop_panel:update_view_context(self._view_context, changed_goods_key_map)
    end
  end
  self:_refresh_buy_button()
  self:_refresh_desc_panel()
  self:_refresh_size_group_panel()
end

function M:_on_bag_cloth_click()
  self:_enter_preset_mode()
end

function M:_on_preset_save_click()
  self:_save_preset_and_return_shop()
end

function M:_enter_preset_mode()
  if self._is_preview_mode == true then
    return
  end
  self._is_preview_mode = true
  self._is_preset_dirty = false
  if self._state_group_preview then
    self._state_group_preview:SetState(1)
  end
  if self._mannequin_panel then
    self._mannequin_panel:enter_preset_edit_mode()
  end
  self:_refresh_preset_panel()
end

function M:_save_preset_and_return_shop()
  if self._is_preview_mode ~= true then
    return
  end
  local preset_map = self._preset_panel and self._preset_panel:get_preset_map() or {}
  npc_cloth_module.set_preset_by_npc(self._view_context.mannequin_npc_id or 0, preset_map)
  self:_return_shop_with_preset(preset_map)
end

function M:_exit_preset_mode_without_save()
  if self._is_preview_mode ~= true then
    return
  end
  self._is_preview_mode = false
  self._is_preset_dirty = false
  if self._state_group_preview then
    self._state_group_preview:SetState(0)
  end
  if self._mannequin_panel then
    self._mannequin_panel:exit_preset_edit_mode(npc_cloth_module.get_preset_by_npc(self._view_context.mannequin_npc_id or 0))
  end
end

function M:_refresh_preset_panel()
  if not self._preset_panel then
    return
  end
  local npc_id = self._view_context.mannequin_npc_id or 0
  self._preset_panel:show({
    npc_id = npc_id,
    shape = self._view_context.mannequin_shape,
    preset_map = npc_cloth_module.get_preset_by_npc(npc_id),
    resident_npc_id_set = self:_build_settled_npc_id_set()
  }, {
    on_preset_changed = pack(self, M._on_preset_changed)
  })
  local valid_preset_map = self._preset_panel:get_preset_map()
  npc_cloth_module.set_preset_by_npc(npc_id, valid_preset_map)
  if self._mannequin_panel then
    self._mannequin_panel:apply_preset_preview(valid_preset_map)
  end
end

function M:_on_preset_changed(preset_map)
  self._is_preset_dirty = true
  if self._mannequin_panel then
    self._mannequin_panel:apply_preset_preview(preset_map)
  end
end

function M:_on_preset_back_click()
  if self._is_preset_dirty == true then
    self:_open_preset_dirty_confirm()
    return
  end
  self:_return_shop_without_saving_preset()
end

function M:_open_preset_dirty_confirm()
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("NpcCloth_Machine_Preset_Back_Unsaved_Tips"), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), UIUtil.get_text_by_id("NpcCloth_Machine_Preset_Back_Unsaved_Title"))
  popup:set_callbacks(pack(self, M._save_preset_and_return_shop), pack(self, M._clear_preset_and_return_shop), function()
  end)
  popup:set_style(ConfirmPopupStyle.NormalWithClose)
  popup:show()
end

function M:_clear_preset_and_return_shop()
  if self._is_preview_mode ~= true then
    return
  end
  local preset_map = {}
  npc_cloth_module.set_preset_by_npc(self._view_context.mannequin_npc_id or 0, preset_map)
  self:_return_shop_with_preset(preset_map)
end

function M:_return_shop_without_saving_preset()
  if self._is_preview_mode ~= true then
    return
  end
  local preset_map = npc_cloth_module.get_preset_by_npc(self._view_context.mannequin_npc_id or 0)
  self:_return_shop_with_preset(preset_map)
end

function M:_return_shop_with_preset(preset_map)
  if self._mannequin_panel then
    self._mannequin_panel:exit_preset_edit_mode(preset_map)
  end
  self._is_preview_mode = false
  self._is_preset_dirty = false
  if self._state_group_preview then
    self._state_group_preview:SetState(0)
  end
  self:_refresh_shop_panel_after_preset()
  self:_refresh_desc_panel()
end

function M:_refresh_shop_panel_after_preset()
  if not self._shop_panel then
    return
  end
  if self._pending_shop_panel_refresh == true then
    self._pending_shop_panel_refresh = false
    self._shop_panel:show({
      shop_id = self._view_context.shop_id,
      level = self._view_context.level,
      view_context = self._view_context
    }, self:_get_panel_callbacks())
    self:_reconcile_mannequin_selection()
  else
    self._shop_panel:refresh_category_panel(false, true)
    self._shop_panel:refresh_visible_item_context(self._view_context)
    self:_refresh_lock_state()
  end
end

function M:_refresh_mannequin_base_preset()
  if self._mannequin_panel then
    self._mannequin_panel:set_base_preset(npc_cloth_module.get_preset_by_npc(self._view_context.mannequin_npc_id or 0))
  end
end

function M:_refresh_desc_panel()
  if self._desc_panel then
    self._desc_panel:refresh(self._view_context.latest_selected_goods)
  end
end

function M:_refresh_size_group_panel()
  if self._size_group_panel then
    self._size_group_panel:refresh({
      view_context = self._view_context
    }, self:_get_size_group_callbacks())
  end
end

function M:_get_selected_npc_by_shape(shape)
  local shape_id = tonumber(shape) or 0
  local selected_map = self._view_context.selected_npc_by_shape or {}
  return selected_map[shape_id] or 0
end

function M:_normalize_selected_npc_by_shape(source)
  return npc_cloth_module.normalize_selected_npc_by_shape(source)
end

function M:_refresh_buy_button()
  local buyable_count = self:_get_buyable_selected_count()
  local can_buy = 0 < buyable_count
  if self._btn_buy then
    self._btn_buy.interactable = can_buy
  end
  if self._txt_buy_count then
    UIUtil.set_text_by_id(self._txt_buy_count, "NpcCloth_Machine_Buy_Selected_Count", buyable_count)
  end
end

function M:_get_buyable_selected_count()
  local count = 0
  for _, goods in ipairs(self:_get_selected_goods_list()) do
    if not npc_cloth_module.is_goods_protocol_locked(goods) then
      count = count + 1
    end
  end
  return count
end

function M:_get_buyable_selected_goods_list()
  local result = {}
  for _, goods in ipairs(self:_get_selected_goods_list()) do
    if not npc_cloth_module.is_goods_protocol_locked(goods) then
      result[#result + 1] = goods
    end
  end
  return result
end

function M:_on_buy_click()
  local goods_list = self:_get_buyable_selected_goods_list()
  if #goods_list <= 0 then
    return
  end
  if #goods_list == 1 then
    self:_open_single_buy_dialog(goods_list[1])
  else
    self:_open_multi_buy_dialog(goods_list)
  end
end

function M:_open_single_buy_dialog(goods)
  local goods_guid = goods.GUID or 0
  local dialog_guid
  dialog_guid = shop_module:open_buy_item_dialog({
    is_npc_cloth = true,
    cfg_id = goods.ItemID,
    coin_id = back_bag_module.coin_type.npc_cloth_ticket,
    hide_coin_item = true,
    unit_price = goods.Price,
    max_num = self:_get_max_buy_num(goods),
    available_balance_func = function()
      return npc_cloth_module.get_available_buy_balance()
    end,
    title_text = UIUtil.get_text_by_id("NpcCloth_txt_Popup_BuyCloth_Title"),
    coin_not_enough_text = npc_cloth_module.get_coin_not_enough_text(true),
    buy_callback = function(num, total_price)
      return self:_buy_goods_list({
        {
          guid = goods_guid,
          num = num,
          total_price = total_price
        }
      }, nil, dialog_guid, true)
    end
  })
end

function M:_open_multi_buy_dialog(goods_list)
  local items = {}
  for _, goods in ipairs(goods_list) do
    items[#items + 1] = {
      key = goods.GUID,
      item_id = goods.ItemID,
      default_num = 1,
      max_num = self:_get_max_buy_num(goods),
      unit_price = goods.Price
    }
  end
  local dialog_guid
  dialog_guid = shop_module:open_npc_cloth_confirm_detail_dialog({
    coin_id = back_bag_module.coin_type.npc_cloth_ticket,
    available_balance_func = function()
      return npc_cloth_module.get_available_buy_balance()
    end,
    items = items,
    confirm_callback = function(items, deleted_items)
      return self:_buy_goods_list(items, deleted_items, dialog_guid)
    end,
    cancel_callback = function(deleted_items)
      self:_take_off_deleted_goods(deleted_items)
    end
  })
end

function M:_take_off_deleted_goods(deleted_items)
  self:_take_off_deleted_goods_by_guid_list(self:_collect_deleted_goods_guid_list(deleted_items))
end

function M:_take_off_deleted_goods_by_guid_list(goods_guid_list)
  if not self._mannequin_panel then
    return
  end
  local selected_id_map = self._view_context.selected_goods_id_map or {}
  for _, goods_guid in ipairs(goods_guid_list or {}) do
    local target_goods = self:_find_latest_goods_by_guid(goods_guid)
    if not is_null(target_goods) then
      local goods_key = npc_cloth_module.get_goods_key(target_goods)
      if 0 < goods_key and selected_id_map[goods_key] == true then
        local snapshot = self._mannequin_panel:toggle_goods(target_goods, nil)
        self:_apply_selection_snapshot(snapshot)
      end
    end
  end
end

function M:_build_buy_data(items)
  local buy_data = {
    total_price = 0,
    goods_guid_list = {},
    goods_count_list = {}
  }
  for _, item in ipairs(items or {}) do
    local goods_guid = item.guid or item.key or 0
    local count = math.floor(tonumber(item.num) or 0)
    local latest_goods = self:_find_latest_goods_by_guid(goods_guid)
    local max_num = self:_get_max_buy_num(latest_goods)
    if not (not is_null(latest_goods) and not (goods_guid <= 0) and npc_cloth_module.is_goods_buyable(latest_goods)) or count <= 0 or count > max_num then
      UIUtil.show_tips_by_text_id("NpcCloth_BuyGoods_Lock")
      return nil
    end
    buy_data.total_price = buy_data.total_price + (latest_goods.Price or 0) * count
    buy_data.goods_guid_list[#buy_data.goods_guid_list + 1] = latest_goods.GUID
    buy_data.goods_count_list[#buy_data.goods_count_list + 1] = count
  end
  return buy_data
end

function M:_buy_goods_list(items, deleted_items, dialog_guid, is_single)
  local buy_data = self:_build_buy_data(items)
  if buy_data == nil then
    return false
  end
  if buy_data.total_price > npc_cloth_module.get_available_buy_balance() then
    local not_enough_key = is_single and "NpcCloth_BuyGood_NotEnough" or "NpcCloth_BuyGoods_NotEnough"
    UIUtil.show_tips_by_text_id(not_enough_key)
    return false
  end
  local fragment_cost = npc_cloth_module.get_fragment_deduct_cost(buy_data.total_price)
  if 0 < fragment_cost then
    local pending_data = {
      items = self:_build_scalar_buy_items(buy_data),
      deleted_goods_guid_list = self:_collect_deleted_goods_guid_list(deleted_items),
      fragment_cost = fragment_cost,
      is_single = is_single
    }
    npc_cloth_module.show_coin_deduct_confirm(fragment_cost, function()
      self:_confirm_coin_deduct_buy(pending_data, dialog_guid)
    end)
    return false
  end
  self:_send_buy_request(buy_data)
  self:_take_off_deleted_goods(deleted_items)
  return true
end

function M:_build_scalar_buy_items(buy_data)
  local items = {}
  for index, goods_guid in ipairs(buy_data.goods_guid_list) do
    items[#items + 1] = {
      guid = goods_guid,
      num = buy_data.goods_count_list[index]
    }
  end
  return items
end

function M:_collect_deleted_goods_guid_list(deleted_items)
  local goods_guid_list = {}
  for _, item in ipairs(deleted_items or {}) do
    local goods_guid = item.guid or item.key or 0
    if 0 < goods_guid then
      goods_guid_list[#goods_guid_list + 1] = goods_guid
    end
  end
  return goods_guid_list
end

function M:_confirm_coin_deduct_buy(pending_data, dialog_guid)
  local buy_data = self:_build_buy_data(pending_data.items)
  local balance = npc_cloth_module.get_available_buy_balance()
  if buy_data == nil or balance < buy_data.total_price then
    if buy_data and balance < buy_data.total_price then
      local not_enough_key = pending_data.is_single and "NpcCloth_BuyGood_NotEnough" or "NpcCloth_BuyGoods_NotEnough"
      UIUtil.show_tips_by_text_id(not_enough_key)
    end
    return
  end
  local fragment_cost = npc_cloth_module.get_fragment_deduct_cost(buy_data.total_price)
  if 0 < fragment_cost and fragment_cost ~= pending_data.fragment_cost then
    pending_data.fragment_cost = fragment_cost
    npc_cloth_module.show_coin_deduct_confirm(fragment_cost, function()
      self:_confirm_coin_deduct_buy(pending_data, dialog_guid)
    end)
    return
  end
  self:_send_buy_request(buy_data)
  self:_take_off_deleted_goods_by_guid_list(pending_data.deleted_goods_guid_list)
  if dialog_guid then
    UIManagerInstance:close(dialog_guid)
  end
end

function M:_send_buy_request(buy_data)
  self:_mark_keep_selection_after_buy(buy_data.goods_guid_list)
  CsShopModuleUtil.NpcFriendShopBatchBuyReq(self._view_context.level or 0, buy_data.goods_guid_list, buy_data.goods_count_list, function(retcode)
    if retcode == nil or 0 < retcode then
      self:_unmark_keep_selection_after_buy(buy_data.goods_guid_list)
    end
  end)
end

function M:_find_latest_goods_by_guid(goods_guid)
  if not self._shop_panel then
    return nil
  end
  return npc_cloth_module.find_goods_by_guid(self._shop_panel:get_shop_groups(), goods_guid, self._shop_panel:get_goods_guid_map())
end

function M:_get_max_buy_num(goods)
  if is_null(goods) then
    return 0
  end
  return math.min(goods.CAmount or 1, MAX_BUY_NUM)
end

function M:_get_selected_goods_list()
  if self._mannequin_panel then
    return self._mannequin_panel:get_selected_goods_list()
  end
  return self._view_context.selected_goods_list or {}
end

function M:_mark_keep_selection_after_buy(goods_guid_list)
  local keep_map = self._view_context.keep_selection_after_buy_guid_map or {}
  self._view_context.keep_selection_after_buy_guid_map = keep_map
  for _, goods_guid in ipairs(goods_guid_list or {}) do
    if 0 < (goods_guid or 0) then
      keep_map[goods_guid] = true
    end
  end
end

function M:_unmark_keep_selection_after_buy(goods_guid_list)
  local keep_map = self._view_context and self._view_context.keep_selection_after_buy_guid_map or nil
  if keep_map == nil then
    return
  end
  for _, goods_guid in ipairs(goods_guid_list or {}) do
    if 0 < (goods_guid or 0) then
      keep_map[goods_guid] = nil
    end
  end
end

function M:_cleanup_keep_selection_after_buy_guid_map()
  local keep_map = self._view_context and self._view_context.keep_selection_after_buy_guid_map or nil
  if keep_map == nil then
    return
  end
  local selected_map = self._view_context.selected_goods_id_map or {}
  for goods_guid, _ in pairs(keep_map) do
    if selected_map[goods_guid] ~= true then
      keep_map[goods_guid] = nil
    end
  end
end

function M:_ensure_help_button()
  if self._has_bound_help_button then
    return
  end
  if not is_null(self._btn_help_dark) then
    self:bind_callback(self._btn_help_dark, pack(self, M._on_help_click))
    self._has_bound_help_button = true
  end
end

function M:_on_help_click()
  common_ui_module:show_introduction_dialog(INTRODUCTION_ID)
end

function M:_on_model_info_click()
  common_ui_module:show_introduction_dialog(MODEL_INTRODUCTION_ID)
end

function M:_on_close_click()
  self:close_self()
end

function M:_refresh_mannequin_scene_root()
  if not self._mannequin_panel or is_null(self.ui_scene_obj) then
    return
  end
  local binder = self:_get_scene_binder()
  local root_field = NPC_ROOT_FIELD_BY_SHAPE[self._view_context.mannequin_shape]
  self._mannequin_panel:set_scene_npc_root(binder and root_field and binder[root_field] or nil)
end

function M:_get_scene_binder()
  if is_null(self.ui_scene_obj) then
    return nil
  end
  if self._scene_binder == nil or self._scene_binder_scene_obj ~= self.ui_scene_obj then
    self._scene_binder = UIUtil.get_mono_binder_field(self.ui_scene_obj)
    self._scene_binder_scene_obj = self.ui_scene_obj
  end
  return self._scene_binder
end

function M:_ensure_default_mannequin_presets()
  local selected = {}
  for _, npc_data in ipairs(self._view_context.npc_list or {}) do
    local npc_id = npc_data.npc_id or npc_data.id or npc_data.config_id or 0
    local shape = self:_get_npc_shape_id(npc_id)
    if 0 < shape and selected[shape] == nil then
      selected[shape] = npc_id
    end
  end
  if 0 < (self._view_context.mannequin_npc_id or 0) then
    local shape = self:_get_npc_shape_id(self._view_context.mannequin_npc_id)
    if 0 < shape then
      selected[shape] = self._view_context.mannequin_npc_id
      self._view_context.mannequin_shape = shape
    end
  end
  local settled_set = self:_build_settled_npc_id_set()
  local cached = npc_cloth_module.get_selected_npc_by_shape()
  for shape, cached_npc_id in pairs(cached) do
    if 0 < cached_npc_id and settled_set[cached_npc_id] then
      selected[shape] = cached_npc_id
    end
  end
  self._view_context.selected_npc_by_shape = selected
end

function M:_build_settled_npc_id_set()
  local result = {}
  if CsNpcInvitationModuleUtil.IsNull and CsNpcInvitationModuleUtil.IsNull() then
    return result
  end
  local settled_data_list = list_to_table(CsNpcInvitationModuleUtil.GetSettledOnIslandInvitationData()) or {}
  for _, invitation_data in ipairs(settled_data_list) do
    local npc_id = invitation_data and invitation_data.NpcId or 0
    if 0 < npc_id then
      result[npc_id] = true
    end
  end
  return result
end

function M:_build_npc_list(source)
  if source and 0 < #source then
    return source
  end
  local result = {}
  local npc_id_map = {}
  self:_append_settled_npc_list(result, npc_id_map)
  self:_append_default_npc_list_from_cfg(result, npc_id_map)
  table.sort(result, function(a, b)
    return (a.npc_id or 0) < (b.npc_id or 0)
  end)
  return result
end

function M:_append_settled_npc_list(result, npc_id_map)
  if CsNpcInvitationModuleUtil.IsNull and CsNpcInvitationModuleUtil.IsNull() then
    return
  end
  local settled_data_list = list_to_table(CsNpcInvitationModuleUtil.GetSettledOnIslandInvitationData()) or {}
  for _, invitation_data in ipairs(settled_data_list) do
    self:_append_npc_id(result, npc_id_map, invitation_data and invitation_data.NpcId or 0)
  end
end

function M:_append_default_npc_list_from_cfg(result, npc_id_map)
  local player_cfg = ExcelDataUtil.get_value(typeof(BPlayerCfg), DEFAULT_NPC_LIST_PLAYER_CFG_ID)
  if player_cfg == nil or not string.is_valid(player_cfg.paramstr) then
    return
  end
  for _, npc_id in ipairs(lua_str_split(player_cfg.paramstr, ",", true)) do
    self:_append_npc_id(result, npc_id_map, npc_id or 0)
  end
end

function M:_append_npc_id(result, npc_id_map, npc_id)
  npc_id = tonumber(npc_id) or 0
  if npc_id <= 0 or npc_id_map[npc_id] or 0 >= self:_get_npc_shape_id(npc_id) then
    return
  end
  npc_id_map[npc_id] = true
  result[#result + 1] = {npc_id = npc_id}
end

function M:_get_npc_shape_id(npc_id)
  return npc_cloth_module.get_npc_shape_id(npc_id)
end

return M
