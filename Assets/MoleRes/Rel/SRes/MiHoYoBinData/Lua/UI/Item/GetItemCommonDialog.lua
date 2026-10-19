local M = G.Class("GetItemCommonDialog", G.UIWindow)
local base = G.UIWindow
local item_v2_cls = item_module.item_v2_panel_cls_name

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Item/GetItemCommonDialog"
  self.config.type = EUIType.Dialog
  self._is_init = true
  self._tbl_items = nil
  self._lst_items = nil
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
  self:_refresh_data(self:get_extra_data())
  self:_refresh_ui()
end

function M:on_disable()
  base.on_disable(self)
  lua_event_module:send_event(lua_event_module.event_type.close_get_item_common_dialog)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
  if self._tbl_items then
    for _, cls in pairs(self._tbl_items) do
      if not_null(cls) then
        self:remove_panel(cls)
      end
    end
  end
  self._tbl_items = nil
  self._lst_items = nil
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
end

function M:_refresh_data(data)
  self._lst_items = data and data.items or {}
end

function M:_refresh_ui()
  local count = #self._lst_items
  if self._is_init then
    self._tbl_items = {}
    self._grid_scroller:Init(pack(self, M._refresh_item), count)
    self._is_init = false
  else
    self._grid_scroller:MoveTo(0)
    self._grid_scroller:ReLoad(pack(self, M._refresh_item), count)
  end
end

function M:_refresh_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local cls = self._tbl_items[instance_id]
  if cls == nil then
    cls = self:add_panel(item_v2_cls, trans)
    self._tbl_items[instance_id] = cls
    self:bind_callback(cls:get_btn(), function()
      local data = cls._bound_item_data
      if data then
        item_module:open_item_info_dialog(data.ConFigID, back_bag_module:get_item_num(data.ConFigID), data)
      end
    end)
  end
  local item_data = self._lst_items[index]
  cls._bound_item_data = item_data
  if item_data then
    cls:set_active(true)
    cls:set_item_data(item_data.ConFigID, item_data.Count, item_data)
  else
    cls:set_active(false)
  end
end

return M
