local TIME_REFRESH_INTERVAL_SEC = 1
local M = G.Class("NewYearSprintDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/NewYearSprint/NewYearSprintDialog"
  self.config.type = EUIType.Dialog
  self._entry = nil
  self._time_acc = 0
  self._is_memory_shelf_locked = false
  self._is_activity_finished = false
  self._reward_items = {}
end

function M:on_create()
  base.on_create(self)
  self:_bind_callbacks()
end

function M:bind_input_action()
  base.bind_input_action(self)
  if not is_null(self._btn_close) then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  end
end

function M:_bind_callbacks()
  if not is_null(self._btn_close) then
    self:bind_callback(self._btn_close, pack(self, M._on_btn_back_click))
  end
  if not is_null(self._btn_bg) then
    self:bind_callback(self._btn_bg, pack(self, M._on_btn_back_click))
  end
  if not is_null(self._btn_track) then
    self:bind_callback(self._btn_track, pack(self, M._on_btn_track_click))
  end
end

function M:_on_btn_back_click()
  self:close_self()
end

function M:_on_btn_track_click()
  local module = new_year_sprint_activity_module
  local target = module:get_tracking_target(self._entry)
  if target == nil then
    Logger.LogWarning("[NewYearSprint] tracking target not configured, tracking_id = " .. tostring(module:get_card_tracking_id(self._entry)))
    return
  end
  activity_center_module:toggle_tracking(target)
end

function M:on_enable()
  base.on_enable(self)
  self._entry = self:get_extra_data()
  self._time_acc = 0
  self:_refresh_static()
  self:refresh()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnActivityDataChanged, pack(self, M._on_activity_data_changed))
  self:add_evt_listener(EventID.TrackerUpdateNotify, pack(self, M._on_tracker_update_notify))
  self:add_evt_listener(EventID.LuaTrackingChange, pack(self, M._refresh_tracking))
end

function M:_on_activity_data_changed(activity_id)
  if self._entry == nil or activity_id ~= new_year_sprint_activity_module:get_card_activity_id(self._entry) then
    return
  end
  self:refresh()
end

function M:_on_tracker_update_notify(tracker_id)
  local module = new_year_sprint_activity_module
  if not module:is_memory_shelf_entry(self._entry) or not module:is_memory_shelf_tracker(tracker_id) then
    return
  end
  if tonumber(tracker_id) == module.memory_shelf_special.start_tracker_id then
    module:refresh_memory_shelf_unlock_state()
  end
  self:_refresh_tracker_state()
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  self._time_acc = self._time_acc + deltaTime
  if self._time_acc < TIME_REFRESH_INTERVAL_SEC then
    return
  end
  self._time_acc = self._time_acc - TIME_REFRESH_INTERVAL_SEC
  self:refresh_time()
end

function M:refresh()
  self:_refresh_tracker_state()
  self:refresh_time()
  self:_refresh_tracking()
end

function M:refresh_time()
  local entry = self._entry
  local module = new_year_sprint_activity_module
  local dialog_state = module:get_dialog_state(entry, self._is_memory_shelf_locked, self._is_activity_finished)
  if not is_null(self._ui_state_activity_time) then
    self._ui_state_activity_time:SetState(dialog_state)
  end
  self:_refresh_time_texts(entry, dialog_state)
end

function M:_refresh_tracker_state()
  local module = new_year_sprint_activity_module
  self._is_memory_shelf_locked = module:is_memory_shelf_unlock_required(self._entry)
  local progress_state = module:get_card_progress_state(self._entry)
  self._is_activity_finished = progress_state == module.card_progress_state.finished
  if not is_null(self._ui_state_activity_progress) then
    self._ui_state_activity_progress:SetState(progress_state)
  end
  local dialog_state = module:get_dialog_state(self._entry, self._is_memory_shelf_locked, self._is_activity_finished)
  if not is_null(self._ui_state_activity_time) then
    self._ui_state_activity_time:SetState(dialog_state)
  end
  self:_refresh_open_text()
end

function M:_refresh_tracking()
  local module = new_year_sprint_activity_module
  local entry = self._entry
  local target = module:get_tracking_target(entry)
  if not is_null(self._txt_track) then
    UIUtil.set_text(self._txt_track, module:get_tracking_text(target))
  end
  if not is_null(self._btn_track) then
    self._btn_track.interactable = target ~= nil
  end
end

function M:_refresh_time_texts(entry, dialog_state)
  local dialog_state_enum = new_year_sprint_activity_module.dialog_state
  if dialog_state == dialog_state_enum.timed_running and not is_null(self._txt_remaintime) then
    UIUtil.set_text(self._txt_remaintime, new_year_sprint_activity_module:get_card_remain_text(entry))
  end
end

function M:_refresh_open_text()
  if is_null(self._txt_opentime) then
    return
  end
  local module = new_year_sprint_activity_module
  if self._is_memory_shelf_locked then
    UIUtil.set_text_by_id(self._txt_opentime, module.locked_tips_text_id.memory_shelf)
    return
  end
  UIUtil.set_text(self._txt_opentime, module:get_card_open_time_range_text(self._entry))
end

function M:_refresh_static()
  local entry = self._entry
  local module = new_year_sprint_activity_module
  if not is_null(self._ui_state_frame_type) then
    local frame_type = module:get_frame_type(entry)
    if frame_type ~= nil then
      self._ui_state_frame_type:SetState(frame_type)
    end
  end
  if not is_null(self._img_bg) then
    local image_path = module:get_dialog_image_path(entry)
    if string.is_valid(image_path) then
      UIUtil.set_image(self._img_bg, image_path, self:get_load_proxy())
    end
  end
  if not is_null(self._txt_title) then
    local title = module:get_dialog_title(entry)
    if title ~= nil then
      UIUtil.set_text(self._txt_title, title)
    end
  end
  if not is_null(self._txt_taskdesc) then
    local desc = module:get_dialog_desc(entry)
    if desc ~= nil then
      UIUtil.set_text(self._txt_taskdesc, desc)
    end
  end
  self:_refresh_reward_list()
end

function M:_refresh_reward_list()
  if self._entry == nil then
    return
  end
  local item_ids = new_year_sprint_activity_module:get_dialog_reward_item_ids(self._entry)
  local has_reward = 0 < #item_ids
  if not is_null(self._trans_rewardlist) then
    UIUtil.set_active(self._trans_rewardlist, has_reward)
  end
  if not has_reward or is_null(self._layout_rewardlist) then
    for _, panel in ipairs(self._reward_items) do
      if panel ~= nil then
        panel:set_active(false)
      end
    end
    return
  end
  for index = 1, #item_ids do
    local panel = self._reward_items[index]
    if panel == nil then
      local obj = self._layout_rewardlist:AddItem(0)
      if not_null(obj) then
        panel = self:add_panel(item_module.item_v2_panel_cls_name, obj)
        self._reward_items[index] = panel
      end
    end
    if panel ~= nil then
      local item_id = item_ids[index]
      panel:set_item_data(item_id, nil)
      panel:bind_item_info_btn(item_id)
      panel:set_active(true)
    end
  end
  for index = #item_ids + 1, #self._reward_items do
    self._reward_items[index]:set_active(false)
  end
end

return M
