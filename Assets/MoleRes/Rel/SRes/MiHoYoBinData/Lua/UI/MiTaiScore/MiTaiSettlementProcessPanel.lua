local M = G.Class("MiTaiSettlementProcessPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MiTaiScore/MiTaiSettlementProcessPanel"
  self._room_index = 1
  self._rooms = {}
  self._summary_data = nil
  self._is_completed = false
  self._sprite = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_next, pack(self, M.show_next_room))
  self:bind_callback(self._btn_settlement, pack(self, M._complete_settlement))
  self:bind_callback(self._btn_skip, pack(self, M.skip_settlement))
end

function M:on_enable()
  base.on_enable(self)
  if not self._session_initialized then
    self:_reset_data()
    self._session_initialized = true
  else
    self:_refresh_room()
    self:_refresh_button_state()
  end
end

function M:on_close()
  self._session_initialized = false
  base.on_close(self)
end

function M:on_destroy()
  self:_clear_sprite()
  base.on_destroy(self)
end

function M:_reset_data()
  self._summary_data = self:get_extra_data() or {}
  self._rooms = self._summary_data.rooms or {}
  self._room_index = 1
  self._is_completed = false
  self:_refresh_room()
  self:_refresh_button_state()
end

function M:start_flow(data)
  self:set_extra_data(data)
  self._session_initialized = true
  self:_reset_data()
end

function M:show_next_room()
  if self._is_completed then
    return
  end
  if self._room_index < #self._rooms then
    self._room_index = self._room_index + 1
    self:_refresh_room()
    self:_refresh_button_state()
    return
  end
  self:_complete_settlement()
end

function M:_refresh_button_state()
  local is_last_room = self._room_index >= #self._rooms
  self._ui_state_group_next_or_settlement:SetState(is_last_room and 1 or 0)
  self._ui_state_group_skip:SetState(not (not (#self._rooms > 1) or is_last_room) and 0 or 1)
  self._ui_state_group_max:SetState(is_last_room and 1 or 0)
end

function M:select_room(index)
  if index < 1 or index > #self._rooms then
    return
  end
  self._room_index = index
  self:_refresh_room()
  self:_refresh_button_state()
end

function M:_refresh_room()
  self:_clear_sprite()
  local room_data = self._rooms[self._room_index]
  if room_data == nil then
    return
  end
  UIUtil.set_text(self._txt_room_name, room_data.room_name)
  UIUtil.set_text_by_id(self._txt_rating_room, room_data.is_highest and "MitaiScore_HighmarkTitle" or "MitaiScore_LowmarkTitle")
  UIUtil.set_text_by_id(self._txt_rating, "MitaiScore_ScoreTitle1", TextMapFormatUtil.FormatInteger(room_data.score or 0))
  UIUtil.set_text(self._txt_title, room_data.evaluation or "")
  local texture = room_data and room_data.texture or nil
  if is_null(texture) then
    self._img_icon_dynamic.sprite = nil
    return
  end
  self._sprite = Sprite.Create(texture, Rect(0, 0, texture.width, texture.height), Vector2(0.5, 0.5))
  self._img_icon_dynamic.sprite = self._sprite
end

function M:_clear_sprite()
  if not_null(self._sprite) then
    CS.UnityEngine.Object.Destroy(self._sprite)
    self._sprite = nil
  end
end

function M:skip_settlement()
  self:_complete_settlement()
end

function M:_complete_settlement()
  if self._is_completed then
    return
  end
  self._is_completed = true
  self.holder:on_settlement_process_complete(self._summary_data)
end

return M
