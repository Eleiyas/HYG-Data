local M = G.Class("CodexSetListItem", G.UIBase)
local base = G.UIBase
local lock_state = {
  locked = 0,
  unlocked_not_complete = 1,
  unlocked_complete = 2
}

function M:init()
  base.init(self)
  self._data = nil
  self._item_obj_id = 0
  self._sequence = 0
  self._group_index = 0
  self._red_point_type = RedPointType.None
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_record_codex_item_red_point, function(id)
    if self._data and self._data.IdCfg and self._data.IdCfg.id == id then
      self:_refresh_red_point()
    end
  end)
  self:add_lua_listener(lua_event_module.event_type.on_codex_sub_type_progress_reward_taken, function()
    if self._data then
      self:_refresh_red_point()
    end
  end)
end

function M:_add_ui_listener()
  if not_null(self._btn_content) then
    self:bind_callback(self._btn_content, pack(self, M._on_btn_content))
  end
end

function M:_on_btn_content()
  if self.holder and self.holder.record_curr_position then
    self.holder:record_curr_position(self._data and self._data.IdCfg and self._data.IdCfg.id or nil)
  end
  local strategy = codex_module:get_type_view_strategy(self._data.Type)
  UIManagerInstance:open(strategy:get_detail_page_class(), {
    item_id = self._data.IdCfg.id,
    enter_type = codex_module.codex_page_enter_type.codex_sub_type_list
  })
end

function M:refresh(item_data)
  self._item_data = item_data
  if not self:_refresh_data(item_data) then
    return
  end
  self:set_active(true)
  self:_refresh_icon()
  self:_refresh_state()
  self:_refresh_progress()
  self:_refresh_red_point()
  self:_refresh_season_hot()
end

function M:_refresh_data(item_data)
  if item_data == nil or item_data.sequence == nil or is_null(item_data.data) or item_data.item_obj_id == nil or item_data.group_index == nil then
    return false
  end
  self._group_index = item_data.group_index
  self._sequence = item_data.sequence
  self._item_obj_id = item_data.item_obj_id
  self._data = item_data.data
  return true
end

function M:_refresh_icon()
  if is_null(self._img_icon_dynamic) then
    return
  end
  item_module:set_item_big_icon_with_prismatic(self._img_icon_dynamic, 0, item_module:get_cfg_by_id(self._data.IdCfg.id), self:get_load_proxy(), self._img_furniture_dynamic_prismatic)
end

function M:_refresh_state()
  local suite = self._data.ServerData and self._data.ServerData.Suite or nil
  local is_complete = not_null(suite) and suite.CompleteTime > 0
  if not_null(self._ui_state_group_lock) then
    if is_complete then
      self._ui_state_group_lock:SetState(lock_state.unlocked_not_complete)
      self._ui_state_group_slider:SetState(1)
    else
      self._ui_state_group_lock:SetState(lock_state.unlocked_not_complete)
      self._ui_state_group_slider:SetState(0)
    end
  end
  if not_null(self._txt_name) then
    UIUtil.set_text(self._txt_name, self._data.IdCfg.name or "")
  end
  local rank = not_null(self._data.ItemCfg) and self._data.ItemCfg.rank or 0
  if not_null(self._ui_state_group_quality) then
    self._ui_state_group_quality:SetState(rank)
  end
end

function M:_refresh_progress()
  local unlocked = self._data.unlockCount or 0
  local total = self._data.allCount or 0
  if not_null(self._slider_progress) then
    local progress = 0 < total and unlocked / total or 0
    self._slider_progress.value = math.min(1, math.max(0, progress))
  end
  if not_null(self._txt_progress) then
    local ns, ts
    if self._data.Type == CodexDataType.Cloth then
      ns, ts = 48, 28
    else
      ns, ts = 30, 26
    end
    UIUtil.set_text(self._txt_progress, string.format("<size=%d>%d</size><size=%d>/%d</size>", ns, unlocked, ts, total))
  end
end

function M:_refresh_red_point()
  self._red_point_type = self:_get_red_point_type()
  if is_null(self._red_point) then
    return
  end
  self._red_point:ShowRedPoint(self._red_point_type)
end

function M:_get_red_point_type()
  if not self._data or not self._data.IdCfg then
    return RedPointType.None
  end
  if codex_module:is_reward_item(self._data.IdCfg.id) then
    return RedPointType.GiftRP
  end
  if codex_module:is_new_item(self._data.IdCfg.id) then
    return RedPointType.NewRp
  end
  return RedPointType.None
end

function M:_refresh_season_hot()
  if is_null(self._img_icon_hot) then
    return
  end
  local is_hot = self:_is_season_hot_set()
  UIUtil.set_active(self._img_icon_hot, is_hot)
end

function M:_is_season_hot_set()
  return codex_module:has_season_sign(self._data)
end

return M
