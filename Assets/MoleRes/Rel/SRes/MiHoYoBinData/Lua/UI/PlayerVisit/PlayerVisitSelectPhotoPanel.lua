local M = G.Class("PlayerVisitSelectPhotoPanel", G.UIPanel)
local base = G.UIPanel
local player_visit_select_photo_item_cls = "UI/PlayerVisit/PlayerVisitSelectPhotoItem"

function M:on_create()
  base.on_create(self)
  self._photo_list = {}
  self._photo_items = {}
  self._min_row_num = 4
  self._item_per_row = 0
  self._min_item_num = 0
  self._selected_index = nil
  self._using_file_key = ""
  self._temp_promo_photo = nil
  self._is_loading_temp_photo = false
end

function M:on_enable()
  base.on_enable(self)
  self:_calculate_min_item_num()
  self:refresh_ui()
end

function M:on_disable()
  base.on_disable(self)
  for _, photo in ipairs(self._photo_list) do
    if not_null(photo.photoThumbnailSprite) and (self._using_file_key == "" or photo.cloudFileKey ~= self._using_file_key) then
      photo:ClearThumbnail()
    end
  end
  if self._temp_promo_photo ~= nil then
    CsPlayerVisitModuleUtil.ReleaseMsgBoardPromoPhoto(self._temp_promo_photo)
    self._temp_promo_photo = nil
  end
  self._is_loading_temp_photo = false
  self._using_file_key = ""
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close))
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm))
end

function M:refresh_ui()
  self._using_file_key = self:_get_using_file_key()
  self._photo_list = self:_get_photo_list()
  self:_move_using_photo_to_top()
  self._selected_index = self:_find_index_by_file_key(self._using_file_key)
  self:_refresh_scroller()
  if self._using_file_key ~= "" and self._selected_index == nil then
    self:_try_load_temp_promo_photo()
  end
end

function M:_refresh_scroller()
  local data_count = #self._photo_list
  local per_row = self._item_per_row > 0 and self._item_per_row or self._min_row_num
  local grid_count = math.ceil(data_count / per_row) * per_row
  grid_count = math.max(grid_count, self._min_item_num)
  self._scroller_photo:Init(pack(self, M._refresh_item), grid_count)
end

function M:_try_load_temp_promo_photo()
  if self._temp_promo_photo ~= nil or self._is_loading_temp_photo then
    return
  end
  local file_key = self._using_file_key
  if not file_key or file_key == "" then
    return
  end
  self._is_loading_temp_photo = true
  CsPlayerVisitModuleUtil.MessageBoardPreparePromoPhotoByFileKey(file_key, function(success, photo)
    self._is_loading_temp_photo = false
    if is_null(self) or self._using_file_key ~= file_key or not self.is_active then
      if photo ~= nil then
        CsPlayerVisitModuleUtil.ReleaseMsgBoardPromoPhoto(photo)
      end
      return
    end
    if not success or photo == nil then
      Logger.LogWarning("PlayerVisitSelectPhotoPanel: prepare temp promo photo failed, fileKey=" .. file_key)
      return
    end
    self._temp_promo_photo = photo
    table.insert(self._photo_list, 1, photo)
    self._selected_index = 1
    self:_refresh_scroller()
  end)
end

function M:_refresh_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local item = self._photo_items[instance_id]
  if item == nil then
    item = self:add_panel(player_visit_select_photo_item_cls, trans)
    self._photo_items[instance_id] = item
  end
  local data = self._photo_list[index]
  item:set_info(data, index, self:_calc_item_state(data, index), pack(self, M._on_item_click))
end

function M:_calc_item_state(data, index)
  local has_photo = data ~= nil
  local is_selected = has_photo and index == self._selected_index
  local is_using = has_photo and self._using_file_key ~= "" and data.cloudFileKey == self._using_file_key
  return {
    has_photo = has_photo,
    is_selected = is_selected,
    is_using = is_using
  }
end

function M:_on_item_click(index)
  if player_visit_module:try_block_station_poster_with_tip() then
    return
  end
  if index == self._selected_index then
    self._selected_index = nil
  else
    self._selected_index = index
  end
  if not is_null(self._scroller_photo) then
    self._scroller_photo:RefreshCurrent()
  end
  local photo = self._selected_index and self._photo_list[self._selected_index] or nil
  EventCenter.Broadcast(EventID.OnPlayerVisitPromoImageChangeTemp, photo)
end

function M:_on_btn_close()
  if not self:_has_unsaved_change() then
    self:_close()
    return
  end
  if player_visit_module:is_station_poster_blocked() then
    self:_cancel_and_close()
    return
  end
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("STATION_EDIT_SAVE_TIPS"), UIUtil.get_text_by_id("STATION_EDIT_SAVE_SAVE"), UIUtil.get_text_by_id("STATION_EDIT_SAVE_CANCLE"), UIUtil.get_text_by_id("STATION_EDIT_SAVE_TITLE"))
  popup:set_callbacks(pack(self, M._save_and_close), pack(self, M._cancel_and_close))
  popup:show()
end

function M:_on_btn_confirm()
  if player_visit_module:try_block_station_poster_with_tip() then
    return
  end
  self:_save_and_close()
end

function M:_broadcast_restore_using_photo(original_file_key)
  local restore_key = original_file_key or self._using_file_key
  local using_index = self:_find_index_by_file_key(restore_key)
  local photo = using_index and self._photo_list[using_index] or nil
  EventCenter.Broadcast(EventID.OnPlayerVisitPromoImageChangeTemp, photo)
end

function M:_cancel_and_close()
  self:_broadcast_restore_using_photo(self._using_file_key)
  self:_close()
end

function M:_save_and_close()
  if player_visit_module:try_block_station_poster_with_tip() then
    self:_cancel_and_close()
    return
  end
  local data = self._selected_index and self._photo_list[self._selected_index] or nil
  self:_apply_photo(data)
  self:_close()
end

function M:_close()
  self.holder:close_select_photo()
end

function M:_has_unsaved_change()
  local data = self._selected_index and self._photo_list[self._selected_index] or nil
  if data then
    local selected_file_key = data.cloudFileKey or ""
    if selected_file_key == "" then
      return true
    end
    return selected_file_key ~= self._using_file_key
  end
  return self._using_file_key ~= ""
end

function M:_calculate_min_item_num()
  if is_null(self._lst_photo) or is_null(self._scroller_photo) then
    return
  end
  local grid_width = self._lst_photo.rect.width + self._scroller_photo._spacing.x
  local item_width = self._scroller_photo.ItemSize.x
  if item_width <= 0 then
    return
  end
  self._item_per_row = math.floor(grid_width / item_width)
  self._min_item_num = self._item_per_row * self._min_row_num
end

function M:_get_photo_list()
  CsAlbumManagerUtil.SyncPhotoDataWithFolder()
  local list = dic_to_list_table(CsAlbumManagerUtil.photoDataDic)
  table.sort(list, function(a, b)
    return a.photoId < b.photoId
  end)
  return list
end

function M:_get_using_file_key()
  return CsPlayerVisitModuleUtil.DisplayPromoImageFileKey or ""
end

function M:_find_index_by_file_key(file_key)
  if not file_key or file_key == "" then
    return nil
  end
  for i, v in ipairs(self._photo_list) do
    if v.cloudFileKey == file_key then
      return i
    end
  end
  return nil
end

function M:_move_using_photo_to_top()
  if self._using_file_key == "" then
    return
  end
  local idx = self:_find_index_by_file_key(self._using_file_key)
  if not idx or idx == 1 then
    return
  end
  local photo = table.remove(self._photo_list, idx)
  table.insert(self._photo_list, 1, photo)
end

function M:_apply_photo(data)
  if not data then
    self:_set_promo_image("")
    return
  end
  local file_key = data.cloudFileKey or ""
  if file_key ~= "" then
    self:_set_promo_image(file_key)
    return
  end
  local original_file_key = self._using_file_key
  CsPlayerVisitModuleUtil.MessageBoardUploadPromoPhoto(data.photoId, function(success, uploaded_file_key)
    if is_null(self) then
      return
    end
    if not (success and uploaded_file_key) or uploaded_file_key == "" then
      Logger.LogWarning("PlayerVisitSelectPhotoPanel: upload promo image failed")
      self:_broadcast_restore_using_photo(original_file_key)
      return
    end
    self:_set_promo_image(uploaded_file_key)
  end)
end

function M:_set_promo_image(file_key)
  local original_file_key = self._using_file_key
  if file_key == original_file_key then
    return
  end
  CsPlayerVisitModuleUtil.MessageBoardSetPromoImageReq(file_key, function(success)
    if is_null(self) then
      return
    end
    if not success then
      self:_broadcast_restore_using_photo(original_file_key)
    end
  end)
end

return M
