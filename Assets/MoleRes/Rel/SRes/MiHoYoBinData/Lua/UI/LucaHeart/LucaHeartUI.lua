luca_heart_module = luca_heart_module or {}
luca_heart_module._cname = "luca_heart_module"
luca_heart_module.scene_root_prefab_path = "Scene/Map/UI/SceneMap_UI_LukaStar.prefab"
luca_heart_module._scene_root = nil
luca_heart_module._b_scene_root_prefab_loading = false
luca_heart_module._init_scene_callback = nil
luca_heart_module._scene_root_load_handle = 0
luca_heart_module._scene_tool = nil
luca_heart_module.enter_edit_page_anim_name = "LucaHeartEditEnterAnim"
luca_heart_module.exit_edit_page_anim_name = "LucaHeartEditExitAnim"
luca_heart_module.luca_data_equip_change = false
luca_heart_module.c_max_track_count = 7
luca_heart_module.c_max_slot_count = 4
luca_heart_module.positon_update_time = 2

function luca_heart_module:enter_luca_heart()
  local function enter_luca()
    CsLucaHeartModuleUtil.SendLucaHeartQueryInfo()
    
    CsLucaHeartModuleUtil.SendEnterLucaHeart()
    InputManagerIns:lock_input(input_lock_from.Common)
    luca_heart_module:init_luca_ui_scene(luca_heart_module.scene_root_prefab_path, function(success)
      InputManagerIns:unlock_input(input_lock_from.Common)
      if success then
        luca_heart_module:start_enter_camera_anim()
        UIManagerInstance:open("UI/LucaHeart/LucaHeartPage")
      end
      CsPerformanceTriggerManagerUtil.UnLockTrigger()
    end)
  end
  
  CsPerformanceTriggerManagerUtil.LockTrigger()
  if not red_point_module:is_recorded(red_point_module.red_point_type.luca_heart_first_open) then
    local video_task = VideoTask()
    if video_task:InitByCfgId(10003) then
      function video_task.onStartPlay()
        CsLucaHeartModuleUtil.SendLucaHeartQueryInfo()
        
        CsLucaHeartModuleUtil.SendEnterLucaHeart()
        InputManagerIns:lock_input(input_lock_from.Common)
        luca_heart_module:init_luca_ui_scene(luca_heart_module.scene_root_prefab_path, function(success)
          InputManagerIns:unlock_input(input_lock_from.Common)
          luca_heart_module:start_enter_camera_anim()
        end)
      end
      
      function video_task.onFinishPlay()
        UIManagerInstance:open("UI/LucaHeart/LucaHeartPage")
        CsPerformanceTriggerManagerUtil.UnLockTrigger()
      end
      
      EventCenter.Broadcast(EventID.LuaShowFullScreenVideo, video_task)
    else
      enter_luca()
    end
  else
    enter_luca()
  end
end

function luca_heart_module:enter_luca_heart_edit_page()
  if is_null(self._scene_tool) then
    return
  end
  InputManagerIns:lock_input(input_lock_from.Common)
  self._scene_tool:ChangeCameraState("Luca2")
  self._scene_tool:PlayAnimation(self.enter_edit_page_anim_name, function()
    local page = UIManagerInstance:get_window_by_class("UI/LucaHeart/LucaHeartEditPage")
    if not is_null(page) then
      CsCoroutineManagerUtil.InvokeNextFrame(function()
        if not is_null(page) then
          page:_refresh_select()
        end
      end)
      page:update_tab_name_position()
    end
    InputManagerIns:unlock_input(input_lock_from.Common)
  end)
end

function luca_heart_module:exit_luca_heart_edit_page()
  if is_null(self._scene_tool) then
    return
  end
  self._scene_tool:ChangeCameraState("Luca1")
  self._scene_tool:PlayAnimation(self.exit_edit_page_anim_name, function()
  end)
end

function luca_heart_module:start_enter_camera_anim()
  if is_null(self._scene_tool) then
    return
  end
  self._scene_tool:ChangeCameraState("Luca0")
  CsCoroutineManagerUtil.InvokeAfterFrames(2, function()
    self._scene_tool:ChangeCameraState("Luca1")
  end)
end

function luca_heart_module:_on_reset_slot_luca(reset_type)
  if reset_type == 0 then
    luca_heart_module:_init_main_page_slot_luca()
  else
    luca_heart_module:_init_edit_page_slot_luca(0)
  end
end

function luca_heart_module:init_luca_ui_scene(scene_prefab_path, callback)
  self._init_scene_callback = callback
  if is_null(self._scene_root) and not self._b_scene_root_prefab_loading then
    self._b_scene_root_prefab_loading = true
    CsUIUtil.LoadPrefabAsync(scene_prefab_path, function(go, hanle)
      self:_scene_root_load_complete(go, hanle)
    end)
  else
    self:_scene_root_load_complete(self._scene_root, 0)
  end
end

function luca_heart_module:_scene_root_load_complete(go, handle)
  self._b_scene_root_prefab_loading = false
  if is_null(go) then
    return
  end
  if 0 < handle then
    luca_heart_module._scene_root_load_handle = handle
  end
  self._scene_root = go.transform
  self._scene_root.localPosition = Vector3(0, 200, -100)
  UIUtil.set_active(self._scene_root, true)
  self._scene_tool = UIUtil.find_cmpt(self._scene_root, "", typeof(MonoLucaHeartSceneTool))
  self._scene_tool:HideTracks()
  self:_init_main_page_slot_luca()
  self:_init_npc()
  if not is_null(self._init_scene_callback) then
    self:_init_scene_callback(true)
  end
end

function luca_heart_module:_check_show_performance()
  if not red_point_module:is_recorded(red_point_module.red_point_type.luca_heart_first_open) then
    local first_open_performance_id = 402101
    if not is_null(self._scene_tool) then
      self._scene_tool:PlayPerformance(first_open_performance_id, nil)
      red_point_module:record(red_point_module.red_point_type.luca_heart_first_open)
      return
    end
  end
  local all_luca_heart_data = list_to_table(CsLucaHeartModuleUtil.LucaHeartData:GetAllLucaData())
  table.sort(all_luca_heart_data, function(a, b)
    return a.unlockTimestamp > b.unlockTimestamp
  end)
  local alreay_play_performance = false
  for _, luca_heart_data in pairs(all_luca_heart_data) do
    if luca_heart_data.bUnlock and not red_point_module:is_recorded_with_id(red_point_module.red_point_type.luca_heart_unlock_performance, luca_heart_data.id) and not is_null(self._scene_tool) then
      if not alreay_play_performance then
        self._scene_tool:PlayUnlockPerformance(luca_heart_data.id, nil)
        alreay_play_performance = true
      end
      red_point_module:record_with_id(red_point_module.red_point_type.luca_heart_unlock_performance, luca_heart_data.id)
    end
  end
end

function luca_heart_module:_init_npc()
  if is_null(self._scene_tool) then
    return
  end
  self._scene_tool:LoadEntity(function(npc_entity)
    self:_check_show_performance()
  end)
end

function luca_heart_module:_init_main_page_slot_luca()
  if is_null(self._scene_tool) then
    return
  end
  local all_luca_data = list_to_table(CsLucaHeartModuleUtil.LucaHeartData:GetAllLucaData())
  for i = #all_luca_data, 1, -1 do
    local luca_data = all_luca_data[i]
    if not luca_data.bUnlock then
      table.remove(all_luca_data, i)
    end
  end
  table.sort(all_luca_data, function(a, b)
    return a.unlockTimestamp > b.unlockTimestamp
  end)
  for i = #all_luca_data, 1, -1 do
    if i > self.c_max_track_count then
      table.remove(all_luca_data, i)
    end
  end
  table.sort(all_luca_data, function(a, b)
    return a.unlockTimestamp < b.unlockTimestamp
  end)
  for i = 1, self.c_max_track_count do
    for j = 1, self.c_max_slot_count do
      self._scene_tool:ClearSlot(i - 1, j - 1)
    end
  end
  for i = 1, self.c_max_track_count do
    if i <= #all_luca_data then
      local luca_data = all_luca_data[i]
      if not is_null(luca_data) then
        if red_point_module:is_recorded_with_id(red_point_module.red_point_type.luca_heart_unlock, luca_data.id) then
          self._scene_tool:SetLucaPrefab(i - 1, 0, luca_data.id, true)
        else
          self._scene_tool:PlayUnlockEffect(i - 1, 0, nil)
          CsCoroutineManagerUtil.Invoke(2, function()
            self._scene_tool:SetLucaPrefab(i - 1, 0, luca_data.id, true)
            red_point_module:record_with_id(red_point_module.red_point_type.luca_heart_unlock, luca_data.id)
          end)
        end
      else
        self._scene_tool:ClearSlot(i - 1, 0)
      end
    end
  end
end

function luca_heart_module:_init_edit_page_slot_luca(cur_first_classification)
  for i = 1, luca_heart_module.c_max_track_count do
    luca_heart_module:_refresh_track_luca(cur_first_classification, i - 1)
  end
end

function luca_heart_module:_refresh_track_luca(cur_first_classification, track_index)
  local luca_data_tbl = list_to_table(CsLucaHeartModuleUtil.LucaHeartData:GetLucaDataByClassification(cur_first_classification, track_index, true, true))
  table.sort(luca_data_tbl, function(a, b)
    return a.equipedTimestamp < b.equipedTimestamp
  end)
  for j = 1, luca_heart_module.c_max_slot_count do
    if j > #luca_data_tbl then
      luca_heart_module._scene_tool:ClearSlot(track_index, j - 1)
    else
      local luca_data = luca_data_tbl[j]
      luca_heart_module._scene_tool:SetLucaPrefab(track_index, j - 1, luca_data.id)
    end
  end
end

function luca_heart_module:hide_scene_root()
  if is_null(self._scene_root) then
    return
  end
  UIUtil.set_active(self._scene_root, false)
end

function luca_heart_module:destroy_scene_root()
  if not is_null(self._scene_root) then
    UIUtil.destroy_go(self._scene_root.gameObject)
    self._scene_root = nil
  end
  if luca_heart_module._scene_root_load_handle > 0 then
    CsUIUtil.DismissResource(luca_heart_module._scene_root_load_handle)
    luca_heart_module._scene_root_load_handle = 0
  end
  CsLucaHeartModuleUtil.SendLeaveLucaHeart()
end

function luca_heart_module:_get_track_count(classification)
  if classification == 0 then
    return 5
  end
  if classification == 1 then
    return 3
  end
  return 0
end

function luca_heart_module:show_performance(performance_id)
  self._scene_tool:PlayPerformance(performance_id)
end

return luca_heart_module
