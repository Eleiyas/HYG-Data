local M = G.Class("CommonSelectObjDialog", "UI/PacketView/PacketBaseWindow")
local base = G.PacketBaseWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/CommonSelectObjDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self:_refresh_select_btn_state()
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_select, pack(self, M._on_btn_select_click))
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
end

function M:on_enable()
  local extra_data = self:get_extra_data()
  if not extra_data or not extra_data.show_mode then
    Logger.LogError("CommonSelectObjDialog show_mode不能为nil")
    return
  end
  self.bag_show_type = extra_data.show_mode
  base.on_enable(self)
  self:_refresh_select_btn_state()
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.hide_packet_page, function()
    self:_on_btn_close_click()
  end)
  self:add_evt_listener(EventID.LuaChangePacket, function(change_data)
    if self._is_close then
      return
    end
    self.common_bag_panel:set_refresh_tog_tracking_state()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:refresh()
  self.cur_item_select_type = back_bag_module.packet_item_select_type.one_selected
  base.refresh(self)
end

function M:refresh_ui()
  base.refresh_ui(self)
  self:_refresh_select_btn_state()
end

function M:refresh_selected_ui(select_item_data)
  base.refresh_selected_ui(self, select_item_data)
  self:_refresh_select_btn_state()
end

function M:refresh_btn()
  self:_refresh_select_btn_state()
end

function M:on_update_bag_item_selected_num(server_data)
  base.on_update_bag_item_selected_num(self, server_data)
  self:_refresh_select_btn_state()
end

function M:_get_selected_stack()
  if is_null(self.common_bag_panel) then
    return nil
  end
  local stack_guid = self.common_bag_panel:get_cur_select_item_guid()
  if stack_guid == 0 then
    return nil
  end
  return self.common_bag_panel:get_item_by_guid(stack_guid)
end

function M:_refresh_select_btn_state()
  local stack = self:_get_selected_stack()
  UIUtil.set_active(self._btn_select, not is_null(stack) and not is_null(stack.firstItem))
end

function M:_on_btn_select_click()
  local stack = self:_get_selected_stack()
  if is_null(stack) or is_null(stack.firstItem) then
    self:_refresh_select_btn_state()
    return
  end
  local extra_data = self:get_extra_data()
  if extra_data and extra_data.on_select then
    extra_data.on_select(stack, stack.firstItem)
  end
  self:close_self()
end

function M:_on_btn_close_click()
  self:close_self()
end

return M
