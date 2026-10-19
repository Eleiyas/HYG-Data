local M = G.Class("GemstonePacketPage", "UI/PacketView/PacketBaseWindow")
local base = G.PacketBaseWindow
local page_result = {close = 0, selected = 1}
local introduction_dialog_id = 17

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/PacketView/GemstonePacketPage"
  self.config.type = EUIType.Page
  self.bag_show_type = back_bag_module.bag_show_type.gemstone
  self.cur_item_select_type = back_bag_module.packet_item_select_type.one_selected
  self._special_interaction_id = 0
  self._is_close = false
  self._dither_player_guid = 0
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  self._is_close = false
  local extra_data = self:get_extra_data() or {}
  self._special_interaction_id = extra_data.special_interaction_id or 0
  CsNPCPersonaGameModuleUtil.SetCurrentGemInteractionId(self._special_interaction_id)
  base.on_enable(self)
  self:_dither_player()
  if extra_data.is_task_mode then
    UIUtil.set_active(self._Btn_Info_Dark_Lv2, false)
  else
    UIUtil.set_active(self._Btn_Info_Dark_Lv2, true)
  end
end

function M:on_disable()
  base.on_disable(self)
  self:_restore_player_dither()
end

function M:on_destroy()
  self:_restore_player_dither()
  base.on_destroy(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, function()
    self:_close_with_result(page_result.close)
  end)
end

function M:on_input_bag_action()
  self:_close_with_result(page_result.close)
end

function M:_add_ui_listener()
  if self._btn_check then
    self:bind_callback(self._btn_check, pack(self, M._on_btn_check))
  end
  if self._btn_open then
    self:bind_callback(self._btn_open, pack(self, M._on_btn_open))
  end
  if self._Btn_Close_Normal then
    self:bind_callback(self._Btn_Close_Normal, pack(self, M._on_btn_close_click))
  end
  if self._Btn_Info_Dark_Lv2 then
    self:bind_callback(self._Btn_Info_Dark_Lv2, pack(self, M._on_btn_info))
  end
end

function M:_dither_player()
  if self._dither_player_guid and self._dither_player_guid ~= 0 then
    return
  end
  local player_guid = CsUIUtil.GetPlayerEntityGuid()
  if not player_guid or player_guid == 0 then
    return
  end
  self._dither_player_guid = player_guid
  CsUIUtil.HideOrShowAvatarForPerformance(player_guid, false, 0.3)
end

function M:_restore_player_dither()
  if not self._dither_player_guid or self._dither_player_guid == 0 then
    return
  end
  CsUIUtil.HideOrShowAvatarForPerformance(self._dither_player_guid, true, 0.3)
  self._dither_player_guid = 0
end

function M:refresh_data()
  CsNPCPersonaGameModuleUtil.SetCurrentGemInteractionId(self._special_interaction_id)
  base.refresh_data(self)
end

function M:refresh_ui()
  base.refresh_ui(self)
  self:_refresh_remain_count()
  self:refresh_btn()
end

function M:refresh_selected_ui(select_item_data)
  base.refresh_selected_ui(self, select_item_data)
  self:refresh_btn()
end

function M:bag_panel_tog_change(cur_tog_type)
  self._cur_tog_type = cur_tog_type
end

function M:refresh_btn()
  local item_guid = 0
  local can_identify = false
  local can_open = false
  item_guid = self:_get_selected_gem_item_guid()
  if item_guid ~= 0 then
    can_identify = CsNPCPersonaGameModuleUtil.CanGemIdentifyByItemGuid(self._special_interaction_id, item_guid)
    can_open = CsNPCPersonaGameModuleUtil.CanGemOpenByItemGuid(self._special_interaction_id, item_guid)
  end
  if self._btn_check then
    UIUtil.set_active(self._btn_check, can_identify)
    self._btn_check.interactable = can_identify
  end
  if self._btn_open then
    UIUtil.set_active(self._btn_open, can_open)
    self._btn_open.interactable = can_open
  end
end

function M:_refresh_remain_count()
  if self._txt_num_dynamic then
    UIUtil.set_text(self._txt_num_dynamic, tostring(CsNPCPersonaGameModuleUtil.GetGemOpenRemainCount(self._special_interaction_id)))
  end
end

function M:_get_selected_gem_item_guid()
  local select_items = self:get_all_select_item_data()
  if not select_items or #select_items <= 0 then
    return 0
  end
  local stack = select_items[1].server_data
  if is_null(stack) then
    return 0
  end
  return stack.FirstGuid or 0
end

function M:_get_selected_gem_item_config_id()
  local select_items = self:get_all_select_item_data()
  if not select_items or #select_items <= 0 then
    return 0
  end
  local stack = select_items[1].server_data
  if is_null(stack) then
    return 0
  end
  return stack.ConfigId or 0
end

function M:_on_btn_check()
  local item_guid = self:_get_selected_gem_item_guid()
  if item_guid == 0 then
    return
  end
  self:_cache_selected_and_close(item_guid, self:_get_selected_gem_item_config_id())
end

function M:_on_btn_open()
  local item_guid = self:_get_selected_gem_item_guid()
  if item_guid == 0 then
    return
  end
  if 0 >= CsNPCPersonaGameModuleUtil.GetGemOpenRemainCount(self._special_interaction_id) then
    UIUtil.show_tips_by_text_id("GemstonePacketPage_txt_tips_15")
    return
  end
  self:_cache_selected_and_close(item_guid, self:_get_selected_gem_item_config_id())
end

function M:_on_btn_info()
  if 0 < introduction_dialog_id then
    common_ui_module:show_introduction_dialog(introduction_dialog_id)
  end
end

function M:_on_btn_close_click()
  self:_close_with_result(page_result.close)
end

function M:_cache_selected_and_close(item_guid, item_config_id)
  CsNPCPersonaGameModuleUtil.CacheSelectedGemItem(self._special_interaction_id, item_guid, item_config_id)
  self:_close_with_result(page_result.selected)
end

function M:_close_with_result(result)
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_self()
  EventCenter.Broadcast(EventID.Performance.OnGemstonePacketPageEnd, result or page_result.close)
end

return M
