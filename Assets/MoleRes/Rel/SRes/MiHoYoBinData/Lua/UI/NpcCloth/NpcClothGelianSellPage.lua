local M = G.Class("NpcClothGelianSellPage", "UI/PacketView/PacketBaseWindow")
local base = G.PacketBaseWindow
local SHOP_PANEL_CLS = "UI/NpcCloth/NpcClothGelianShopPanel"
local INTRODUCTION_ID = 25
local CameraState = {
  LevelOne = "UIShopOutside",
  LevelTwo = "UINpcClothMachineRecycle"
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcCloth/NpcClothGelianSellPage"
  self.config.type = EUIType.Page
  self.bag_panel_cls_name = "UI/PacketView/SellBagPanel"
  self.bag_show_type = back_bag_module.bag_show_type.npc_cloth_recycle
  self.cur_item_select_type = back_bag_module.packet_item_select_type.num_multi_selected
  self._all_price = 0
  self._shop_panel = nil
  self._is_recycle_tab_active = false
  self._has_shown_shop_panel_this_open = false
  self._recycle_only = false
end

function M:check_3c_validate()
  self:_ensure_extra_data()
  return base.check_3c_validate(self)
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
  self._has_shown_shop_panel_this_open = false
  self._recycle_only = false
  self._camera_state_pushed = false
  if self._shop_panel then
    self._shop_panel:reset_request_state()
  end
end

function M:on_enable()
  self:_ensure_extra_data()
  base.on_enable(self)
  self._recycle_only = self._extra_data.recycle_only == true
  local tab = self._recycle_only and "recycle" or self._extra_data.tab or "buy"
  self:_switch_tab(tab == "recycle" or tab == "sell", true)
  self:_set_camera_state()
end

function M:on_disable()
  base.on_disable(self)
  if self._camera_state_pushed then
    local camera_state = self:_get_camera_state()
    CsGameplayUtilitiesCameraUtil.PopState(camera_state)
    self._camera_state_pushed = false
  end
end

function M:on_close()
  EventCenter.Broadcast(EventID.Performance.OnNpcClothGelianShopPageEnd, 0)
  base.on_close(self)
end

function M:refresh_coin_data()
  self.lst_coin_data = {
    coin_types = {
      back_bag_module.coin_type.npc_cloth_ticket
    },
    is_auto_update = true,
    coin_anim_time = 0.5
  }
end

function M:refresh_data()
  self:_ensure_extra_data()
  base.refresh_data(self)
end

function M:refresh_ui()
  base.refresh_ui(self)
  self:_hide_stack_num_panel()
  self:_refresh_all_price()
  self:_refresh_recycle_btn_ui()
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close_sell, function()
    self:close_self()
  end)
  self:bind_callback(self._btn_close_buy, function()
    self:close_self()
  end)
  self:bind_callback(self._btn_buy_tab, function()
    self:_switch_tab(false)
  end)
  self:bind_callback(self._btn_recycle_tab, function()
    self:_switch_tab(true)
  end)
  self:bind_callback(self._btn_recycle or self._btn_sell, pack(self, M._on_btn_recycle_click))
  local help_pack = pack(self, M._on_btn_help_click)
  self:bind_callback(self._btn_help_dark, help_pack)
  self:bind_callback(self._btn_help_buy, help_pack)
end

function M:_ensure_extra_data()
  local extra_data = self:get_extra_data() or {}
  extra_data.show_mode = extra_data.show_mode or back_bag_module.bag_show_type.npc_cloth_recycle
  extra_data.bag_main_type = extra_data.bag_main_type or back_bag_module.bag_main_type.clothes
  self:set_extra_data(extra_data)
end

function M:_set_camera_state()
  local camera_state, follow, target = self:_get_camera_state_params()
  if is_null(follow) or not follow.IsValid then
    Logger.LogWarning("[NpcClothGelianSellPage] invalid camera target, guid = " .. tostring(self._extra_data.camera_target_guid))
    return
  end
  CsGameplayUtilitiesCameraUtil.PushStateAndSetTargetByEntity(camera_state, follow, target)
  self._camera_state_pushed = true
end

function M:_get_camera_state_params()
  local camera_state = self:_get_camera_state()
  if camera_state == CameraState.LevelOne then
    local guid = CsPerformanceManagerUtil.Initiator
    return camera_state, EntityUtil.get_entity(player_module:get_player_guid()), EntityUtil.get_entity(guid)
  else
    local entity = EntityUtil.get_entity(self._extra_data.camera_target_guid or 0)
    return camera_state, entity, entity
  end
end

function M:_switch_tab(is_recycle, force_refresh)
  if self._recycle_only then
    is_recycle = true
  end
  local was_recycle = self._is_recycle_tab_active
  self._is_recycle_tab_active = is_recycle
  UIUtil.set_active(self._obj_shop_content, not is_recycle)
  UIUtil.set_active(self._obj_recycle_content or self._obj_sell_content, is_recycle)
  UIUtil.set_active(self._btn_buy_tab, is_recycle and not self._recycle_only)
  UIUtil.set_active(self._btn_recycle_tab, not is_recycle and not self._recycle_only)
  self:_hide_stack_num_panel()
  if is_recycle then
    if self._shop_panel then
      self._shop_panel:set_active(false)
    end
    self:_refresh_all_price()
    self:_refresh_recycle_btn_ui()
    self:_refresh_stack_num_panel_by_current_selection()
    return
  end
  if not self._shop_panel then
    self._shop_panel = self:add_panel(SHOP_PANEL_CLS, self._obj_shop_content, self._extra_data)
  end
  self._shop_panel:set_active(true)
  if force_refresh or was_recycle or not self._has_shown_shop_panel_this_open then
    self._shop_panel:show(self._extra_data)
    self._has_shown_shop_panel_this_open = true
  end
end

function M:_refresh_all_price()
  self._all_price = 0
  local all_select_item_data = self:get_all_select_item_data() or {}
  UIUtil.set_active(self._obj_item_price, 0 < #all_select_item_data)
  for _, item_data in pairs(all_select_item_data) do
    local config_id = item_data.server_data and item_data.server_data.ConfigId or 0
    self._all_price = math.floor(self._all_price + CsShopModuleUtil.GetNpcClothRecyclePrice(config_id) * (item_data.num or 0))
  end
  UIUtil.set_text(self._txt_recycle_price or self._txt_item_sell_price, math.modf(self._all_price))
end

function M:_refresh_recycle_btn_ui()
  local all_select_item_data = self:get_all_select_item_data() or {}
  local select_num = #all_select_item_data
  local btn = self._btn_recycle or self._btn_sell
  if btn then
    btn.interactable = 0 < select_num
  end
  UIUtil.set_text_by_id(self._txt_btn_sell_title, "NpcCloth_txt_Button_RecycleCloth_Confirm", select_num)
end

function M:_hide_stack_num_panel()
  if self._stack_num_panel then
    self._stack_num_panel:change_state(EUIState.Hide)
  end
end

function M:_refresh_stack_num_panel_by_current_selection()
  local server_data = self.cur_select_item and self.cur_select_item.server_data
  local cur_select_guid = self:get_cur_select_item_guid()
  if cur_select_guid <= 0 then
    self:_hide_stack_num_panel()
    return
  end
  if is_null(server_data) or server_data.StackGuid ~= cur_select_guid then
    local all_select_item_data = self:get_all_select_item_data() or {}
    for _, item_data in pairs(all_select_item_data) do
      local item_server_data = item_data.server_data
      if not is_null(item_server_data) and item_server_data.StackGuid == cur_select_guid then
        server_data = item_server_data
        break
      end
    end
  end
  self:_refresh_stack_num_panel(server_data)
end

function M:_refresh_stack_num_panel(server_data)
  if is_null(server_data) or not self._stack_num_panel then
    self:_hide_stack_num_panel()
    return
  end
  local cur_select_guid = self:get_cur_select_item_guid()
  if cur_select_guid <= 0 or server_data.StackGuid ~= cur_select_guid then
    if cur_select_guid <= 0 then
      self:_hide_stack_num_panel()
    end
    return
  end
  local cur_num = self:get_cur_select_item_num()
  if cur_num <= 0 then
    self:_hide_stack_num_panel()
    return
  end
  self._stack_num_panel:change_state(EUIState.Show)
  self._stack_num_panel:show({
    cur_num = cur_num,
    max_num = server_data.Count,
    server_data = server_data,
    price = self:_get_recycle_unit_price(server_data),
    coin_id = back_bag_module.coin_type.npc_cloth_ticket,
    num_change_callback = function(new_num)
      self:refresh_cur_select_item_num(new_num)
      self:_refresh_all_price()
      self:_refresh_recycle_btn_ui()
    end
  })
end

function M:_get_recycle_unit_price(server_data)
  if is_null(server_data) then
    return 0
  end
  return CsShopModuleUtil.GetNpcClothRecyclePrice(server_data.ConfigId or 0)
end

function M:_on_btn_recycle_click()
  local select_items = self:get_all_select_item_data() or {}
  if #select_items <= 0 then
    return
  end
  local item_counts = {}
  for _, item_data in pairs(select_items) do
    for guid, num in pairs(back_bag_module:get_select_stack_info_by_stack_id(item_data.server_data.StackGuid) or {}) do
      item_counts[guid] = num
    end
  end
  
  local function recycle_callback()
    CsShopModuleUtil.NpcClothRecycleReq(item_counts, function(retcode)
      if retcode and retcode <= 0 then
        self:_try_play_player_recycle_atl()
        self:clear_all_select_item_data()
        self:set_select_item_index(0)
        self:_hide_stack_num_panel()
        self:_refresh_all_price()
        self:_refresh_recycle_btn_ui()
      end
    end)
  end
  
  back_bag_module:show_sell_item_confirm_dialog(UIUtil.get_text_by_id("NpcCloth_txt_Popup_RecycleCloth_Title"), back_bag_module.coin_type.npc_cloth_ticket, self._all_price, select_items, UIUtil.get_text_by_id("NpcCloth_txt_Popup_RecycleCloth_Cancel"), nil, UIUtil.get_text_by_id("NpcCloth_txt_Popup_RecycleCloth_Confirm"), recycle_callback, true, nil, {
    is_npc_cloth = true,
    reward_item_id = back_bag_module.coin_type.npc_cloth_ticket
  })
end

function M:_on_btn_help_click()
  common_ui_module:show_introduction_dialog(INTRODUCTION_ID)
end

function M:refresh_selected_ui(select_item_data)
  base.refresh_selected_ui(self, select_item_data)
  if is_null(select_item_data) then
    self:_hide_stack_num_panel()
  end
end

function M:on_update_bag_item_selected_num(server_data)
  base.on_update_bag_item_selected_num(self, server_data)
  self:_refresh_all_price()
  self:_refresh_recycle_btn_ui()
  self:_refresh_stack_num_panel(server_data)
  self:_check_recycle_last_one_tip(server_data)
end

function M:_check_recycle_last_one_tip(server_data)
  if is_null(server_data) then
    return
  end
  local cfg_id = server_data.ConfigId or 0
  if cfg_id <= 0 then
    return
  end
  local total_num = back_bag_module:get_item_num(cfg_id) or 0
  if total_num <= 0 then
    return
  end
  local selected_num = 0
  for _, item_data in ipairs(self:get_all_select_item_data() or {}) do
    local sd = item_data.server_data
    if not is_null(sd) and (sd.ConfigId or 0) == cfg_id then
      selected_num = selected_num + (item_data.num or 0)
    end
  end
  local is_last_one = total_num <= selected_num and 0 < selected_num
  self._last_one_tip_cfgid_set = self._last_one_tip_cfgid_set or {}
  local was_last_one = self._last_one_tip_cfgid_set[cfg_id] == true
  if is_last_one and not was_last_one then
    self._last_one_tip_cfgid_set[cfg_id] = true
    UIUtil.show_tips_by_text_id("NpcCloth_RecycleCloth_LastOneTip")
  elseif not is_last_one and was_last_one then
    self._last_one_tip_cfgid_set[cfg_id] = nil
  end
end

function M:_request_expired_items()
end

function M:_try_play_player_recycle_atl()
  if self._recycle_only then
    local player_guid = player_module:get_player_guid()
    EntityUtil.play_atl_with_tag(player_guid, ATLTagTags.Tags.atlstate_avatar_default_behavior_npcwardroberecycle)
  end
end

function M:_get_camera_state()
  if self._recycle_only then
    return CameraState.LevelTwo
  else
    return CameraState.LevelOne
  end
end

return M
