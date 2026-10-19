local M = G.Class("BatchUseCardItemDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/PacketView/BatchUseCardItemDialog"
  self.config.type = EUIType.Dialog
  self._lst_item_data = {}
  self._tbl_item_cls = {}
  self._tbl_select_state = {}
  self._dialog_type = back_bag_module.batch_use_card_item_type.idea_card
  self._is_grid_init = false
  self._is_syncing_tog = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
  self._lst_item_data = {}
  self._tbl_item_cls = {}
  self._tbl_select_state = {}
  self._is_grid_init = false
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_cancel)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_cancel, pack(self, M._on_btn_cancel_click))
  self:bind_callback(self._btn_confim, pack(self, M._on_btn_confim_click))
  self:bind_callback(self._tog_sellect_all, pack(self, M._on_tog_sellect_all_click))
end

function M:_on_btn_cancel_click()
  self:close_self()
end

function M:_on_btn_confim_click()
  local lst_select = {}
  for _, item_data in ipairs(self._lst_item_data) do
    if self._tbl_select_state[item_data.GUID] then
      table.insert(lst_select, item_data)
    end
  end
  if #lst_select <= 0 then
    return
  end
  item_module:use_card_items_req(lst_select)
  self:close_self()
end

function M:_on_tog_sellect_all_click(is_on)
  if self._is_syncing_tog then
    return
  end
  self._tbl_select_state = {}
  if is_on then
    for _, item_data in ipairs(self._lst_item_data) do
      self._tbl_select_state[item_data.GUID] = true
    end
  end
  self:_refresh_item_select()
  self:_refresh_confim_btn_state()
end

function M:_on_item_click(cls)
  local extra_data = cls:get_extra_data()
  if extra_data == nil or is_null(extra_data.server_data) then
    return
  end
  local guid = extra_data.server_data.GUID
  if self._tbl_select_state[guid] then
    self._tbl_select_state[guid] = nil
  else
    self._tbl_select_state[guid] = true
  end
  cls:refresh_select()
  self:_refresh_select_all_tog()
  self:_refresh_confim_btn_state()
end

function M:get_item_select_state_by_guid(guid)
  return self._tbl_select_state[guid] == true
end

function M:_refresh()
  self:_refresh_data()
  self:_refresh_type_state()
  self:_refresh_grid()
  self:_refresh_select_all_tog()
  self:_refresh_confim_btn_state()
end

function M:_refresh_data()
  self._lst_item_data = {}
  self._tbl_select_state = {}
  local extra_data = self:get_extra_data() or {}
  self._dialog_type = extra_data.dialog_type or back_bag_module.batch_use_card_item_type.idea_card
  for _, guid in ipairs(extra_data.lst_guid or {}) do
    local item_data = CsPacketModuleUtil.GetItemByGUID(guid)
    if not is_null(item_data) then
      table.insert(self._lst_item_data, item_data)
      self._tbl_select_state[item_data.GUID] = true
    end
  end
end

function M:_refresh_type_state()
  self._ui_state_group_type:SetState(self._dialog_type)
end

function M:_refresh_grid()
  local count = #self._lst_item_data
  if self._is_grid_init then
    self._grid_scroll:ReLoad(pack(self, M._refresh_item), count)
  else
    self._is_grid_init = true
    self._grid_scroll:Init(pack(self, M._refresh_item), count)
  end
end

function M:_refresh_item(trans, index)
  local cls_key = trans:GetInstanceID()
  local cls = self._tbl_item_cls[cls_key]
  if cls == nil then
    cls = self:add_panel(back_bag_module.new_packet_item_cls_name, trans)
    self:bind_callback(cls:get_btn(), function()
      self:_on_item_click(cls)
    end)
    self._tbl_item_cls[cls_key] = cls
  end
  local item_data = self._lst_item_data[index + 1]
  cls:set_extra_data({
    index = index + 1,
    is_lock = false,
    npc_id = 0,
    item_select_type = back_bag_module.packet_item_select_type.multi_selected,
    server_data = item_data,
    guid = not is_null(item_data) and item_data.GUID or 0
  })
  cls:refresh()
end

function M:_refresh_item_select()
  for _, cls in pairs(self._tbl_item_cls) do
    cls:refresh_select()
  end
end

function M:_refresh_select_all_tog()
  local count = #self._lst_item_data
  self._is_syncing_tog = true
  self._tog_sellect_all.isOn = 0 < count and count <= self:_get_select_count()
  self._is_syncing_tog = false
end

function M:_refresh_confim_btn_state()
  self._btn_confim.interactable = self:_get_select_count() > 0
end

function M:_get_select_count()
  local count = 0
  for _, item_data in ipairs(self._lst_item_data) do
    if self._tbl_select_state[item_data.GUID] then
      count = count + 1
    end
  end
  return count
end

return M
