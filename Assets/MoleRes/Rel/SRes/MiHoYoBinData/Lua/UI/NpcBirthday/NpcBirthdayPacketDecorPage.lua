local M = G.Class("NpcBirthdayPacketDecorPage", "UI/PacketView/PacketBaseWindow")
local base = G.PacketBaseWindow
local MAX_DECOR_ITEM_NUM = 5
local state_group_type_index = {
  wrap = 0,
  decor = 1,
  gift = 2
}
local slot_state_index = {empty = 0, filled = 2}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcBirthday/NpcBirthdayPacketPage"
  self.config.type = EUIType.Page
  self.bag_show_type = back_bag_module.bag_show_type.npc_birthday_decor
  self.cur_item_select_type = back_bag_module.packet_item_select_type.num_multi_selected
  self._birthday_npc_id = 0
  self._slot_list = nil
  self._is_in_req = false
  self._is_close = false
  self._is_end_broadcast = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._state_group_type:SetState(state_group_type_index.decor)
  if not is_null(self._state_group_confirm) then
    self._state_group_confirm:SetState(0)
  end
  self:_init_item_slots()
  self:_load_sub_panels()
  self:_refresh_confirm_state()
end

function M:_load_sub_panels()
  self.common_bag_panel = self:add_panel_async("UI/LitePacketView/LiteCommonBagPanel", nil, self._lite_bag_without_tag_parent)
  self.item_detail_panel = self:add_panel_async("UI/LitePacketView/LiteItemDetailPanel", nil, self._lite_item_detail_parent_without_tag)
end

function M:_init_item_slots()
  if is_null(self._birthday_item_group) or is_null(self._obj_item_putin) then
    return
  end
  self._slot_list = {}
  for i = 1, MAX_DECOR_ITEM_NUM do
    local slot_trans = self._obj_item_putin
    if 1 < i then
      local go = UIUtil.load_prefab_set_parent(self._obj_item_putin.gameObject, self._birthday_item_group, nil)
      slot_trans = go.transform
    end
    local lite_trans = UIUtil.find_trans(slot_trans, "obj_item_lite")
    local slot = {
      trans = slot_trans,
      state_group_type = UIUtil.find_ui_state_group(slot_trans, "state_group_type"),
      item_cls = not is_null(lite_trans) and item_module:init_lite_item_cls(lite_trans) or nil,
      stack_guid = 0
    }
    local slot_index = i
    self:bind_callback(UIUtil.find_button_ex(slot_trans), function()
      self:_on_slot_click(slot_index)
    end)
    if not is_null(slot.state_group_type) then
      slot.state_group_type:SetState(slot_state_index.empty)
    end
    table.insert(self._slot_list, slot)
  end
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
  if not is_null(self._btn_confirm) then
    self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm_click))
  end
end

function M:_on_btn_close_click()
  if self._is_close then
    return
  end
  self._is_close = true
  self:_broadcast_decor_submit_end(0)
  self:close_self()
end

function M:on_close()
  base.on_close(self)
  self:_broadcast_decor_submit_end(0)
end

function M:_on_btn_confirm_click()
  if self._is_in_req then
    return
  end
  local guid_list = self:_get_submit_guid_list()
  if #guid_list <= 0 then
    return
  end
  if CsNpcBirthdayModuleUtil.IsNpcBirthdayPartyOpen(self._birthday_npc_id) then
    UIUtil.show_tips_by_text_id("NpcBirthday_DecorPage_PartyAlreadyBegun")
    return
  end
  self._is_in_req = true
  CsNpcBirthdayModuleUtil.SubmitDecoration(self._birthday_npc_id, guid_list, function(retcode)
    self._is_in_req = false
    self:_on_submit_decoration_rsp(retcode)
  end)
end

function M:refresh_data()
  local extra_data = self:get_extra_data()
  self._birthday_npc_id = extra_data and extra_data.birthday_npc_id or 0
  base.refresh_data(self)
  self:_refresh_item_slots()
  self:_refresh_confirm_state()
end

function M:get_max_select_item_num(server_data, cur_num)
  local ret_num = cur_num or 0
  if ret_num >= server_data.Count then
    return ret_num
  end
  if self:_get_total_select_num() >= MAX_DECOR_ITEM_NUM then
    UIUtil.show_tips_by_text_id("NpcBirthday_DecorPage_MaxSelected")
    return ret_num
  end
  return ret_num + 1
end

function M:subtract_select_item_num(server_data, cur_num)
  cur_num = cur_num or 0
  if cur_num <= 0 then
    return 0
  end
  return cur_num - 1
end

function M:on_update_bag_item_selected_num(server_data)
  base.on_update_bag_item_selected_num(self, server_data)
  self:_refresh_item_slots()
  self:_refresh_confirm_state()
end

function M:_on_slot_click(slot_index)
  local slot = self._slot_list and self._slot_list[slot_index]
  if slot == nil or slot.stack_guid == 0 then
    return
  end
  if is_null(self.common_bag_panel) then
    return
  end
  local stack_guid = slot.stack_guid
  self:_set_slot_empty(slot)
  self:change_item_num_by_guid(stack_guid, -1)
  self:_refresh_item_slots()
  self:_refresh_confirm_state()
end

function M:_get_select_item_data_list()
  if is_null(self.common_bag_panel) or self.common_bag_panel._tbl_cur_multi_stack == nil then
    return {}
  end
  return self:get_all_select_item_data()
end

function M:_get_total_select_num()
  local total = 0
  for _, item_data in ipairs(self:_get_select_item_data_list()) do
    total = total + item_data.num
  end
  return total
end

function M:_get_submit_guid_list()
  local guid_list = {}
  for _, item_data in ipairs(self:_get_select_item_data_list()) do
    local stack_info = back_bag_module:get_select_stack_info_by_stack_id(item_data.server_data.StackGuid)
    for guid, num in pairs(stack_info or {}) do
      for _ = 1, num do
        table.insert(guid_list, guid)
      end
    end
  end
  return guid_list
end

function M:_refresh_item_slots()
  if self._slot_list == nil then
    return
  end
  local select_map = {}
  for _, item_data in ipairs(self:_get_select_item_data_list()) do
    select_map[item_data.server_data.StackGuid] = {
      num = item_data.num,
      server_data = item_data.server_data
    }
  end
  local claimed = {}
  for _, slot in ipairs(self._slot_list) do
    local guid = slot.stack_guid
    local info = guid ~= 0 and select_map[guid] or nil
    if info ~= nil and (claimed[guid] or 0) < info.num then
      claimed[guid] = (claimed[guid] or 0) + 1
      self:_set_slot_item(slot, info.server_data)
    else
      self:_set_slot_empty(slot)
    end
  end
  for guid, info in pairs(select_map) do
    local remaining = info.num - (claimed[guid] or 0)
    if 0 < remaining then
      for _, slot in ipairs(self._slot_list) do
        if remaining <= 0 then
          break
        end
        if slot.stack_guid == 0 then
          claimed[guid] = (claimed[guid] or 0) + 1
          remaining = remaining - 1
          self:_set_slot_item(slot, info.server_data)
        end
      end
    end
  end
end

function M:_set_slot_item(slot, server_data)
  slot.stack_guid = server_data.StackGuid
  if slot.item_cls ~= nil then
    item_module:set_item_cls(slot.item_cls, server_data.ConfigId, 1, self:get_load_proxy(), nil, false)
  end
  if not is_null(slot.state_group_type) then
    slot.state_group_type:SetState(slot_state_index.filled)
  end
end

function M:_set_slot_empty(slot)
  slot.stack_guid = 0
  if slot.item_cls ~= nil then
    item_module:set_item_cls(slot.item_cls, 0, 0, self:get_load_proxy())
  end
  if not is_null(slot.state_group_type) then
    slot.state_group_type:SetState(slot_state_index.empty)
  end
end

function M:_refresh_confirm_state()
  local can_submit = self:_get_total_select_num() > 0
  if not is_null(self._state_group_confirm) then
    self._state_group_confirm:SetState(can_submit and 1 or 0)
  end
end

function M:_broadcast_decor_submit_end(value)
  if self._is_end_broadcast then
    return
  end
  self._is_end_broadcast = true
  EventCenter.Broadcast(EventID.Performance.OnBirthdayDecorSubmitEnd, value)
end

function M:_on_submit_decoration_rsp(retcode)
  if retcode ~= 0 then
    return
  end
  if self._is_close or is_null(self.trans) then
    return
  end
  self:_broadcast_decor_submit_end(1)
  self:close_self()
end

return M
