local M = G.Class("ExpiredItemDialog", G.UIWindow)
local base = G.UIWindow
local TIMEOUT_TEXT_ID_DEFAULT = "ItemTimeOutTip_text_Timeout_3"
local TIMEOUT_TEXT_ID_WITH_MAIL = "ItemTimeOutTip_text_Timeout_4"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/PacketView/ExpiredItemDialog"
  self.config.type = EUIType.Dialog
  self._is_init = true
  self._tbl_items = nil
  self._lst_expired_items = nil
end

function M:on_create()
  base.on_create(self)
  local padding = self._grid_scroller.Padding
  self._original_padding_top = padding.top
  self._original_padding_left = padding.left
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
  lua_event_module:send_event(lua_event_module.event_type.expired_dialog_close_notify)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
  self._tbl_items = nil
  self._lst_expired_items = nil
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_ok, pack(self, M._on_btn_ok_click))
end

function M:_on_btn_ok_click()
  self:close_self()
end

function M:_refresh_data(data)
  self._lst_expired_items = data and data.items or {}
end

function M:_refresh_timeout_text()
  if is_null(self._text_timeout) then
    return
  end
  local text_id = TIMEOUT_TEXT_ID_DEFAULT
  for _, item in ipairs(self._lst_expired_items) do
    local cfg = item_module:get_time_limit_cfg(item.ConFigID)
    if cfg ~= nil and cfg.exchangemailid ~= 0 then
      text_id = TIMEOUT_TEXT_ID_WITH_MAIL
      break
    end
  end
  UIUtil.set_text_by_id(self._text_timeout, text_id)
end

function M:_refresh_ui()
  self:_refresh_timeout_text()
  local count = #self._lst_expired_items
  local padding = self._grid_scroller.Padding
  padding.top = self._original_padding_top
  padding.left = self._original_padding_left
  if self._is_init then
    self._tbl_items = {}
    self._grid_scroller:Init(pack(self, M._refresh_item), count)
    self._is_init = false
  else
    self._grid_scroller:MoveTo(0)
    self._grid_scroller:ReLoad(pack(self, M._refresh_item), count)
  end
  if 0 < count and self:_try_center_padding() then
    self._grid_scroller:ReLoad(pack(self, M._refresh_item), count)
  end
end

function M:_try_center_padding()
  local scroller = self._grid_scroller
  local count = #self._lst_expired_items
  local col = scroller.Col
  local item_w = scroller.ItemSize.x
  local item_h = scroller.ItemSize.y
  local padding = scroller.Padding
  local vw = self._viewport:GetWidth()
  local vh = self._viewport:GetHeight()
  local changed = false
  local rows = math.ceil(count / col)
  local cols_in_use = math.min(count, col)
  local items_h = rows * item_h - scroller._spacing.y
  local items_w = cols_in_use * item_w - scroller._spacing.x
  local need_scroll = items_h > vh + 1
  if vh > items_h + 1 then
    local new_top = math.floor((vh - items_h) / 2)
    if new_top > self._original_padding_top then
      padding.top = new_top
      changed = true
    end
  end
  if vw > items_w + 1 then
    local new_left = math.floor((vw - items_w) / 2)
    if new_left > self._original_padding_left then
      padding.left = new_left
      changed = true
    end
  end
  self._scroll_rect.enabled = need_scroll
  return changed
end

function M:append_items(new_items)
  for _, item in ipairs(new_items) do
    table.insert(self._lst_expired_items, item)
  end
  self:_refresh_ui()
end

function M:_refresh_item(trans, index)
  index = index + 1
  local item_id = trans:GetInstanceID()
  local cls = self._tbl_items[item_id]
  if cls == nil then
    cls = item_module:init_item_cls(UIUtil.find_trans(trans, "content"), item_module.quality_ui_type.def)
    self._tbl_items[item_id] = cls
    self:bind_callback(cls.btn, function()
      local data = self._lst_expired_items[cls._cur_index]
      if data then
        local target = item_module:open_item_info_dialog(data.ConFigID, data.Count, data)
        if target then
          target:set_is_expire_item(true)
        end
      end
    end)
  end
  cls._cur_index = index
  local item = self._lst_expired_items[index]
  if item then
    item_module:set_item_cls(cls, item.ConFigID, item.Count, self:get_load_proxy(), item)
  end
end

return M
