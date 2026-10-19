local M = G.Class("CommonTxtInfoConfirmDialog", G.UIWindow)
local base = G.UIWindow
local info_item_cls = "UI/CommonUI/CommonTxtInfoItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/Dialog/CommonTxtInfoConfirmDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self._info_items = {}
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_ui()
end

function M:on_disable()
  base.on_disable(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close_1)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close_1)
  self:bind_close_btn(self._btn_close_2)
  self:bind_close_btn(self._btn_close_3)
end

function M:_refresh_ui()
  local data = self:get_extra_data()
  if data == nil then
    self:close_self()
    return
  end
  if data.title then
    UIUtil.set_text(self._txt_title, data.title)
  end
  if data.info then
    UIUtil.set_text(self._txt_info, data.info)
  end
  self:_refresh_info_list(data.info_list)
end

function M:_refresh_info_list(info_list)
  info_list = info_list or {}
  local count = #info_list
  for i = 1, count do
    local cls = self._info_items[i]
    if cls == nil then
      local obj = self._list_item:AddItem(0)
      cls = self:add_panel(info_item_cls, obj)
      self._info_items[i] = cls
    end
    cls:set_active(true)
    cls:refresh(info_list[i])
  end
  for i = count + 1, #self._info_items do
    self._info_items[i]:set_active(false)
  end
end

return M
