local M = G.Class("SuitPanel", G.UIPanel)
local base = G.UIPanel
local AppearanceQueryUtil = require("UI/Appearance/AppearanceQueryUtil")
local item_class_name = "UI/Appearance/AppearanceSuitItem"

function M:init()
  base.init(self)
  self._is_init = true
  self._suit_data_list = nil
  self._raw_count = 0
  self._tbl_items = nil
  self._tbl_instance_ids = nil
  self._cur_euler_angle_y = 0
  self._cur_pos = Vector2.zero
  self._last_pos = Vector2.zero
  self._delta_pos = Vector2.zero
  self._drag_dis = 0
  self._rotation_sensitivity = 0.2
end

function M:on_create()
  base.on_create(self)
  self:_add_drag_event()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
  self._cur_euler_angle_y = 0
  self:_update_player_euler_angle_y()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.Tutorial.OnTutorialStart, function()
    if not is_null(self.game_obj) and self.game_obj.activeInHierarchy then
      self:refresh_tutorial_key()
    end
  end)
end

function M:refresh(tags, sort_type, outfit_id)
  local raw_list = appearance_module:get_suit_data_list()
  raw_list = AppearanceQueryUtil.filter_suit_list(raw_list, self:_get_query())
  self._raw_count = #raw_list
  self._suit_data_list = {}
  for k, v in pairs(raw_list) do
    table.insert(self._suit_data_list, v)
  end
  self._cur_euler_angle_y = 0
  self:refresh_ui()
  self:_update_player_euler_angle_y()
end

function M:is_empty()
  return not self._raw_count or self._raw_count <= 0
end

function M:_get_query()
  return self.holder and self.holder.get_query_state and self.holder:get_query_state() or nil
end

function M:refresh_ui()
  local count = #self._suit_data_list
  UIUtil.set_active(self._obj_empty, count <= 0)
  UIUtil.set_active(self._grid_scroller, 0 < count)
  if count <= 0 then
    return
  end
  self._tbl_instance_ids = {}
  self._tutorial_index = 0
  self._has_set_tutorial_key = false
  self._max_num = count
  if self._is_init then
    self._tbl_items = {}
    self._grid_scroller:Init(pack(self, M._refresh_item), count)
    self._is_init = false
  else
    self._grid_scroller:ReLoad(pack(self, M._refresh_item), count)
    self._grid_scroller:MoveTo(0)
  end
  self:refresh_tutorial_key()
end

function M:refresh_tutorial_key()
  if not self._max_num then
    return
  end
  local index = 0
  for i = 1, self._max_num do
    local instance_id = self._tbl_instance_ids[i]
    if instance_id then
      local cls = self._tbl_items[instance_id]
      if cls and cls.is_active and cls.is_worn and cls:is_worn() == false and cls:get_suit_data() then
        index = index + 1
        if cls:refresh_tutorial_key(index) then
          break
        end
      end
    end
  end
end

function M:_refresh_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  self._tbl_instance_ids[index] = instance_id
  local cls = self._tbl_items[instance_id]
  if is_null(cls) then
    cls = self:add_panel(item_class_name, trans)
    self:bind_callback(cls:get_btn(), function()
      if is_null(cls:get_suit_data()) then
        return
      end
      cls:set_red_point_state()
      if cls:is_worn() then
        self:_take_off_suit(cls)
      else
        self:_put_on_suit(cls)
      end
    end)
    self._tbl_items[instance_id] = cls
  end
  local suit_data = self._suit_data_list[index]
  cls:refresh(suit_data, index)
  if cls.is_active and cls.is_worn and cls:is_worn() == false and not self._has_set_tutorial_key and type(suit_data) == "userdata" then
    self._tutorial_index = self._tutorial_index + 1
    if cls:refresh_tutorial_key(self._tutorial_index) then
      self._has_set_tutorial_key = true
    end
  end
end

function M:_put_on_suit(cls)
  local suit_id = cls:get_suit_id()
  if 0 < suit_id then
    CsAppearanceManagerUtil.PutOnSuit(suit_id)
    CsBuriedPointReportManagerUtil.ReportActionFromLuaTable(BuriedPointReportActionEnum.appearance_use_suit, "AppearanceUseSuit", {outfit_id = suit_id})
  end
  self:_after_suit_action(cls, true)
end

function M:_take_off_suit(cls)
  local suit_id = cls:get_suit_id()
  if 0 < suit_id then
    CsAppearanceManagerUtil.TakeOffSuit(suit_id)
  end
  self:_after_suit_action(cls, false)
end

function M:_after_suit_action(cls, is_put_on)
  self:_refresh_all_worn_state()
  self.holder:notify_item_operated(cls:get_suit_id(), is_put_on)
  self.holder:refresh_undo_and_redo_btn()
end

function M:_refresh_all_worn_state()
  if not self._tbl_items then
    return
  end
  for _, cls in pairs(self._tbl_items) do
    if cls and cls.refresh_worn_state then
      cls:refresh_worn_state()
    end
  end
end

function M:get_selected_item_info_data()
  local cfg_id = self:get_first_worn_cfg_id()
  if cfg_id <= 0 then
    return nil
  end
  return {cfg_id = cfg_id}
end

function M:get_first_worn_cfg_id()
  self._first_worn_cfg_id = 0
  if self._suit_data_list == nil then
    return 0
  end
  for _, suit_data in ipairs(self._suit_data_list) do
    if suit_data and suit_data ~= 0 and suit_data ~= -1 and not is_null(suit_data) and CsAppearanceManagerUtil.IsSuitWorn(suit_data.suitId) then
      self._first_worn_cfg_id = suit_data.suitId
      return suit_data.suitId
    end
  end
  return 0
end

function M:refresh_cur()
  if not self._is_init then
    self._grid_scroller:RefreshCurrent()
  end
end

function M:reset()
  if appearance_module:reset_cloth() and not self._is_init then
    self._grid_scroller:RefreshCurrent()
    return true
  end
  return false
end

function M:take_off_all()
  if appearance_module:take_off_all_cloth() and not self._is_init then
    self._grid_scroller:RefreshCurrent()
    return true
  end
  return false
end

function M:undo()
  if appearance_module:cloth_undo_last_action() and not self._is_init then
    self._grid_scroller:RefreshCurrent()
    return appearance_module:get_cloth_action_operated_cfg_id()
  end
  return nil
end

function M:redo()
  if appearance_module:cloth_redo_next_action() and not self._is_init then
    self._grid_scroller:RefreshCurrent()
    return appearance_module:get_cloth_action_operated_cfg_id()
  end
  return nil
end

function M:is_can_undo()
  return appearance_module:cloth_can_undo()
end

function M:is_can_redo()
  return appearance_module:cloth_can_redo()
end

function M:_add_drag_event()
  self.binder:BindViewCallback(self._trans_drag_content, EventTriggerType.BeginDrag, pack(self, M._on_begin_drag))
  self.binder:BindViewCallback(self._trans_drag_content, EventTriggerType.Drag, pack(self, M._on_drag))
  self.binder:BindViewCallback(self._trans_drag_content, EventTriggerType.EndDrag, pack(self, M._on_end_drag))
end

function M:_on_begin_drag(evt)
  self._cur_pos = evt.position
  self._last_pos = evt.position
  self._scroll_rect:OnBeginDrag(evt)
end

function M:_on_drag(evt)
  self._cur_pos = evt.position
  self._delta_pos = self._cur_pos - self._last_pos
  local angle_with_x_axis = Vector2.Angle(self._delta_pos, Vector2.right)
  if 90 < angle_with_x_axis then
    angle_with_x_axis = 180 - angle_with_x_axis
  end
  if angle_with_x_axis <= 60 then
    self._drag_dis = Vector2.Distance(self._cur_pos, self._last_pos)
    if self._cur_pos.x >= self._last_pos.x then
      self._drag_dis = -self._drag_dis
    end
    self._cur_euler_angle_y = self._cur_euler_angle_y + self._drag_dis * self._rotation_sensitivity
    self:_update_player_euler_angle_y()
  else
    self._scroll_rect:OnDrag(evt)
  end
  self._last_pos = self._cur_pos
end

function M:_on_end_drag(evt)
  self._scroll_rect:OnEndDrag(evt)
  self._cur_pos = Vector2.zero
  self._last_pos = Vector2.zero
  self._delta_pos = Vector2.zero
  self._drag_dis = 0
end

function M:_update_player_euler_angle_y()
  appearance_module:update_player_euler_angles_y(self._cur_euler_angle_y)
end

return M
