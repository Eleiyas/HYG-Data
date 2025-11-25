mi_tai_score_module = mi_tai_score_module or {}
local scene_camera_state1 = "MitaiEvaluate0"
local scene_camera_state2 = "MitaiEvaluate1"
local scene_camera_state3 = "MitaiEvaluate2"

function mi_tai_score_module:remove_layer_from_camera(layerName)
  local main_cam = GameplayUtility.Camera.MainCamera
  local layer = CS.UnityEngine.LayerMask.NameToLayer(layerName)
  if layer ~= -1 and not_null(main_cam) then
    main_cam.cullingMask = main_cam.cullingMask & ~(1 << layer)
  end
end

function mi_tai_score_module:add_layer_to_camera(layerName)
  local main_cam = GameplayUtility.Camera.MainCamera
  local layer = CS.UnityEngine.LayerMask.NameToLayer(layerName)
  if layer ~= -1 and not_null(main_cam) then
    main_cam.cullingMask = main_cam.cullingMask | 1 << layer
  end
end

function mi_tai_score_module:init_mitai_score_camera(callback)
  self:_init_cam_root(function(succeeded)
    if succeeded then
      self:start_to_score_result_camera()
      if self.score_cam_ctrl then
        self.score_cam_ctrl:InitRootPos()
      end
    end
    if callback then
      callback(succeeded)
    end
  end)
end

function mi_tai_score_module:start_to_score_result_camera()
  CsGameplayUtilitiesCameraUtil.PushStateWithExternalTarget("MiTaiScoreResult", self.cam_target, self.cam_look)
  EventCenter.Broadcast(EventID.LuaSetOverheadHintShowState, false)
end

function mi_tai_score_module:exit_score_result_camera()
  CsGameplayUtilitiesCameraUtil.PopState("MiTaiScoreResult")
  EventCenter.Broadcast(EventID.LuaSetOverheadHintShowState, true)
end

function mi_tai_score_module:change_cam_pos(index)
  if self.score_cam_ctrl then
    self.score_cam_ctrl:SetCameraPos(index)
  end
end

function mi_tai_score_module:prepare_scene(callback)
  self:_init_scene_root(function(succeeded)
    callback(succeeded)
  end)
end

function mi_tai_score_module:enter_scene()
  self:_init_scene_root(function(succeeded)
    if succeeded then
      UIUtil.set_active(self.score_scene_root, true)
      if self.scene_camera_ctrl then
        self.scene_camera_ctrl:ChangeState(scene_camera_state1)
        CsCoroutineManagerUtil.Invoke(0.2, function()
          self.scene_camera_ctrl:ChangeState(scene_camera_state2)
        end)
      end
    end
  end)
end

function mi_tai_score_module:pre_exit_scene()
  if self.scene_camera_ctrl then
    self.scene_camera_ctrl:ChangeState(scene_camera_state1)
  end
end

function mi_tai_score_module:exit_scene()
  if is_null(self.score_scene_root) == false then
    UIUtil.set_active(self.score_scene_root, false)
  end
  if self.scene_npc ~= 0 then
    EntityUtil.destroy_entity_by_guid(self.scene_npc)
    self.scene_npc = 0
  end
end

function mi_tai_score_module:start_to_score_level_camera()
  if self.scene_camera_ctrl then
    self.scene_camera_ctrl:ChangeState(scene_camera_state3)
  end
end

function mi_tai_score_module:exit_score_level_camera()
  if self.scene_camera_ctrl then
    self.scene_camera_ctrl:ChangeState(scene_camera_state2)
  end
end

return mi_tai_score_module
