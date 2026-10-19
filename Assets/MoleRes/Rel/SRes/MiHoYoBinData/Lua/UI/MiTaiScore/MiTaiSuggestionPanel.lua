local M = G.Class("MiTaiSuggestionPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MiTaiScore/MiTaiSuggestionPanel"
  self._rooms = {}
  self._room_index = 1
  self._is_closing = false
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_close, pack(self, M.close_panel))
  self:bind_callback(self._btn_left, pack(self, M._show_previous_room))
  self:bind_callback(self._btn_right, pack(self, M._show_next_room))
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  self._rooms = data.rooms or {}
  if #self._rooms > 0 then
    self._room_index = math.max(1, math.min(data.selected_index or 1, #self._rooms))
  else
    self._room_index = 0
  end
  self._is_closing = false
  self:_refresh_room()
end

function M:select_room(index)
  if index < 1 or index > #self._rooms then
    return
  end
  self._room_index = index
  self:_refresh_room()
end

function M:_show_previous_room()
  self:_switch_room(-1)
end

function M:_show_next_room()
  self:_switch_room(1)
end

function M:_switch_room(offset)
  local room_count = #self._rooms
  if room_count <= 1 then
    return
  end
  local index = (self._room_index - 1 + offset) % room_count + 1
  self.holder:focus_room(index)
end

function M:_refresh_room()
  local room_data = self._rooms[self._room_index]
  if room_data == nil then
    UIUtil.set_text(self._txt_room_name, "")
    UIUtil.set_text(self._txt_rating_num, "")
    UIUtil.set_text(self._txt_content, "")
    return
  end
  UIUtil.set_text(self._txt_room_name, room_data.room_name)
  UIUtil.set_text(self._txt_rating_num, TextMapFormatUtil.FormatInteger(room_data.score or 0))
  UIUtil.set_text(self._txt_content, string.format([[
%s
%s]], room_data.highest_evaluation, room_data.lowest_evaluation))
end

function M:close_panel()
  if self._is_closing then
    return
  end
  self._is_closing = true
  self.holder:close_suggestion()
end

return M
