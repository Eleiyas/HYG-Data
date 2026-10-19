local M = G.Class("NpcBirthdayPacketGiftPage", "UI/PacketView/PacketBaseWindow")
local base = G.PacketBaseWindow
local state_group_type_index = {
  wrap = 0,
  decor = 1,
  gift = 2
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcBirthday/NpcBirthdayPacketPage"
  self.config.type = EUIType.Page
  self.bag_show_type = back_bag_module.bag_show_type.npc_birthday_gift
  self._birthday_npc_id = 0
  self._is_in_req = false
  self._is_close = false
  self._is_end_broadcast = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._state_group_type:SetState(state_group_type_index.gift)
  self:_load_sub_panels()
  self:_refresh_choose_btn_state()
end

function M:_load_sub_panels()
  self.common_bag_panel = self:add_panel_async("UI/LitePacketView/LiteCommonBagPanel", nil, self._lite_bag_with_tag_parent)
  self.item_detail_panel = self:add_panel_async("UI/LitePacketView/LiteItemDetailPanel", nil, self._lite_item_detail_parent_with_tag)
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  self._is_in_req = false
  self._is_end_broadcast = false
end

function M:on_disable()
  base.on_disable(self)
end

function M:check_3c_validate()
  local extra_data = self:get_extra_data()
  if extra_data and not extra_data.show_mode then
    extra_data.show_mode = self.bag_show_type
  end
  return base.check_3c_validate(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  if not is_null(self._btn_choose) then
    self:bind_callback(self._btn_choose, pack(self, M._on_btn_choose_click))
  end
end

function M:_on_btn_close_click()
  if self._is_close then
    return
  end
  self._is_close = true
  self:_broadcast_gift_submit_end(0)
  self:close_self()
end

function M:on_close()
  base.on_close(self)
  self:_broadcast_gift_submit_end(0)
end

function M:_on_btn_choose_click()
  if self._is_in_req then
    return
  end
  local item_guid = self:_get_cur_select_gift_guid()
  if item_guid == 0 then
    return
  end
  self._is_in_req = true
  CsSendGiftModuleUtil.SubmitGiftCheckByItemGuid(self._birthday_npc_id, item_guid, function(success)
    self._is_in_req = false
    self:_on_submit_gift_rsp(success)
  end, SendNpcGiftReason.Birthday)
end

function M:refresh_data()
  local extra_data = self:get_extra_data()
  self._birthday_npc_id = extra_data and extra_data.birthday_npc_id or 0
  base.refresh_data(self)
  self:_refresh_choose_btn_state()
end

function M:refresh_selected_ui(select_item_data)
  base.refresh_selected_ui(self, select_item_data)
  self:_refresh_choose_btn_state()
end

function M:_get_cur_select_gift_guid()
  if is_null(self.common_bag_panel) then
    return 0
  end
  local stack_guid = self.common_bag_panel:get_cur_select_item_guid()
  if stack_guid == 0 then
    return 0
  end
  local stack = self.common_bag_panel:get_item_by_guid(stack_guid)
  if is_null(stack) or is_null(stack.firstItem) then
    return 0
  end
  return stack.firstItem.GUID
end

function M:_refresh_choose_btn_state()
  if is_null(self._btn_choose) then
    return
  end
  UIUtil.set_active(self._btn_choose, self:_get_cur_select_gift_guid() ~= 0)
end

function M:_on_submit_gift_rsp(success)
  if not success then
    UIUtil.show_tips_by_text_id("NpcBirthday_GiftPage_SubmitFail")
    return
  end
  if self._is_close or is_null(self.trans) then
    return
  end
  self:_broadcast_gift_submit_end(1)
  self:close_self()
end

function M:_broadcast_gift_submit_end(value)
  if self._is_end_broadcast then
    return
  end
  self._is_end_broadcast = true
  EventCenter.Broadcast(EventID.Performance.OnBirthdayGiftSubmitEnd, value)
end

return M
