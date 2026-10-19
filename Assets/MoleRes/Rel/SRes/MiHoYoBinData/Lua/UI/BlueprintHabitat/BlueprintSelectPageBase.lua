local M = G.Class("BlueprintSelectPageBase", G.UIWindow)
local base = G.UIWindow
local custom_item_cls = "UI/BlueprintHabitat/BlueprintCustomItem"
local empty_state = {has_data = 0, no_data = 1}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/BlueprintSelectDeletePage"
  self.config.type = EUIType.Dialog
  self._items = {}
  self._pending_data = nil
  self._list_count = 0
  self._list_blueprint = nil
  self._txt_content = nil
  self._btn_close_normal = nil
  self._ui_state_group_mode = nil
  self._ui_state_group_empty = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_close_normal)
  
  function self._item_click_cb(data)
    self:_handle_item_click(data)
  end
end

function M:on_enable()
  base.on_enable(self)
  self:_apply_mode()
  self:_refresh_list()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.WorldEdit.LuaUI.NewBlueprintDataChanged, pack(self, M._on_data_changed))
end

function M:_apply_mode()
  if not_null(self._ui_state_group_mode) then
    self._ui_state_group_mode:SetState(self:_mode_state())
  end
  self:_refresh_content_text()
end

function M:_refresh_list()
  local data_list = self:_get_list_source()
  self._list_count = data_list ~= nil and #data_list or 0
  if is_null(self._list_blueprint) then
    self:_refresh_empty_state()
    return
  end
  for index = 1, self._list_count do
    local item = self._items[index]
    if item == nil then
      local obj = self._list_blueprint:AddItem(0)
      if not is_null(obj) then
        item = self:add_panel(custom_item_cls, obj)
        self._items[index] = item
      end
    end
    if item ~= nil then
      item:set_active(true)
      item:refresh(data_list[index], self._item_click_cb)
    end
  end
  for i = self._list_count + 1, #self._items do
    local item = self._items[i]
    if item ~= nil then
      item:set_active(false)
    end
  end
  self:_refresh_empty_state()
end

function M:_refresh_empty_state()
  if is_null(self._ui_state_group_empty) then
    return
  end
  self._ui_state_group_empty:SetState(self._list_count > 0 and empty_state.has_data or empty_state.no_data)
end

function M:_handle_item_click(data)
  if data == nil then
    return
  end
  local confirm_text = self:_confirm_text(data)
  if confirm_text == nil then
    self:_on_item_click(data)
    return
  end
  self._pending_data = data
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(confirm_text, UIUtil.get_text_by_id("Common_Confirm"), UIUtil.get_text_by_id("Common_Cancel"), nil)
  popup:set_callbacks(pack(self, M._on_confirm_click))
  popup:show()
end

function M:_on_confirm_click()
  local data = self._pending_data
  self._pending_data = nil
  if data == nil then
    return
  end
  self:_on_item_click(data)
end

function M:_mode_state()
  return new_blueprint_module.SELECT_MODE_STATE.delete
end

function M:_refresh_content_text()
end

function M:_confirm_text(data)
  return nil
end

function M:_on_item_click(data)
end

function M:_on_data_changed(arg)
  self:_refresh_content_text()
  self:_refresh_list()
end

function M:_get_list_source()
  return new_blueprint_module:get_custom_sorted_list()
end

return M
