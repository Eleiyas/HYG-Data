local M = G.Class("InteractiveGiftPacketPage", "UI/PacketView/PacketBaseWindow")
local base = G.PacketBaseWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/PacketView/GiftPacketPage"
  self.config.type = EUIType.Page
  self._is_close = false
  self._give_id = 0
  self.bag_show_type = back_bag_module.bag_show_type.interactive_gift
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._npc_cloth_gift_panel:set_hide_on_create()
end

function M:on_open()
  base.on_open(self)
  local extra_data = self:get_extra_data()
  CsReactionModuleUtil.InteractiveGiftTargetGuid = extra_data and extra_data.target_guid or 0
end

function M:on_close()
  CsReactionModuleUtil.InteractiveGiftTargetGuid = 0
  base.on_close(self)
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  self._give_id = 0
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.hide_packet_page, function()
    self:_on_btn_close_click()
  end)
  self:add_lua_listener(lua_event_module.event_type.common_bag_panel_enable, function()
    self.common_bag_panel:set_tog_active(false)
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
end

function M:_on_btn_close_click()
  if self._is_close then
    return
  end
  self:close_self()
  self._is_close = true
end

function M:refresh()
  base.refresh(self)
end

function M:refresh_data()
  base.refresh_data(self)
end

return M
