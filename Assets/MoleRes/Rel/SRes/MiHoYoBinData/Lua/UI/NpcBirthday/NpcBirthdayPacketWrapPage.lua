local M = G.Class("NpcBirthdayPacketWrapPage", "UI/PacketView/PacketBaseWindow")
local base = G.PacketBaseWindow
local WRAP_PAPER_ITEM_ID = 11011
local WRAP_PAPER_COST = 1
local state_group_type_index = {
  wrap = 0,
  decor = 1,
  gift = 2
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/NpcBirthday/NpcBirthdayPacketPage"
  self.config.type = EUIType.Page
  self.bag_show_type = back_bag_module.bag_show_type.gift
  self._paper_guid = 0
  self._paper_last_count = 1
  self._is_in_req = false
  self._is_close = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._state_group_type:SetState(state_group_type_index.wrap)
  self:_load_sub_panels()
  self:_refresh_package_btn_state()
end

function M:_load_sub_panels()
  self.common_bag_panel = self:add_panel_async("UI/LitePacketView/LiteNpcBirthdayWrapBagPanel", nil, self._lite_bag_with_tag_parent)
  self.item_detail_panel = self:add_panel_async("UI/LitePacketView/LiteItemDetailPanel", nil, self._lite_item_detail_parent_with_tag)
end

function M:on_open()
  base.on_open(self)
  local extra_data = self:get_extra_data()
  self._paper_guid = extra_data and extra_data.paper_guid or 0
  UIUtil.set_text(self._txt_pack_num, WRAP_PAPER_COST)
  item_module:set_item_icon(self._img_pack_icon, WRAP_PAPER_ITEM_ID, nil, nil, self:get_load_proxy())
end

function M:check_3c_validate()
  local extra_data = self:get_extra_data()
  if extra_data and not extra_data.show_mode then
    extra_data.show_mode = self.bag_show_type
  end
  return base.check_3c_validate(self)
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  self._is_in_req = false
end

function M:on_disable()
  base.on_disable(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_package, pack(self, M._on_btn_package_click))
end

function M:_on_btn_close_click()
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_self()
end

function M:_on_btn_package_click()
  if self._is_in_req then
    return
  end
  if self._paper_guid == 0 then
    self:_try_acquire_next_paper()
  end
  if self._paper_guid == 0 then
    UIUtil.show_tips(UIUtil.get_text_by_id("Shop_ItemDeficiency"))
    return
  end
  local gift_guid = self:_get_cur_select_gift_guid()
  if gift_guid == 0 then
    return
  end
  local paper_item = CsPacketModuleUtil.GetItemByGUIDForLua(self._paper_guid)
  self._paper_last_count = not is_null(paper_item) and paper_item.Count or 1
  self._is_in_req = true
  CsNpcBirthdayModuleUtil.PackGiftBox(self._paper_guid, gift_guid, function(retcode, result_item_guid)
    self._is_in_req = false
    self:_on_pack_gift_box_rsp(retcode, result_item_guid)
  end)
end

function M:refresh_data()
  base.refresh_data(self)
  self:_refresh_package_btn_state()
end

function M:refresh_selected_ui(select_item_data)
  base.refresh_selected_ui(self, select_item_data)
  self:_refresh_package_btn_state()
end

function M:_refresh_package_btn_state()
  if is_null(self._btn_package) then
    return
  end
  UIUtil.set_active(self._btn_package, self:_get_cur_select_gift_guid() ~= 0)
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

function M:_on_pack_gift_box_rsp(retcode, result_item_guid)
  if retcode ~= 0 then
    self._paper_guid = 0
    UIUtil.show_tips_by_text_id("NpcBirthday_WrapPage_WrapFail")
    return
  end
  self:_show_get_gift_box_dialog(result_item_guid)
  if self._is_close or is_null(self.trans) then
    return
  end
  if (self._paper_last_count or 1) <= 1 then
    self:_try_acquire_next_paper()
  end
end

function M:_try_acquire_next_paper()
  local papers = list_to_table(CsPacketModuleUtil.GetItemsByCfgIdForLua(WRAP_PAPER_ITEM_ID))
  for _, paper in ipairs(papers) do
    if paper.GUID ~= self._paper_guid then
      self._paper_guid = paper.GUID
      return true
    end
  end
  self._paper_guid = 0
  return false
end

function M:_show_get_gift_box_dialog(result_item_guid)
  local gift_box_item = CsPacketModuleUtil.GetItemByGUIDForLua(result_item_guid)
  if is_null(gift_box_item) then
    return
  end
  item_module:open_get_item_common_dialog({gift_box_item})
end

return M
