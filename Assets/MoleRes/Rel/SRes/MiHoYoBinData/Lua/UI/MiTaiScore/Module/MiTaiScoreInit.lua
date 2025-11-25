mi_tai_score_module = mi_tai_score_module or {}
mi_tai_score_module._cname = "mi_tai_score_module"
lua_module_mgr:require("UI/MiTaiScore/Module/MiTaiScoreData")
lua_module_mgr:require("UI/MiTaiScore/Module/MiTaiScoreScene")
lua_module_mgr:require("UI/MiTaiScore/Module/MiTaiScoreMain")
local score_ctrl_root_path = "SceneObj/MiTai/MiTaiScoreRoot"
local score_main_scene_root = "Scene/Map/4_UI/SceneMap_UI_MitaiEvaluate"
local camera_ctrl_path = "Art/Art/Mesh/CameraWrap"
local scene_npc_root_path = "Art/Art/Content/Center/NpcRoot"
mi_tai_score_module.evaluate_npc_id = 1007

function mi_tai_score_module:init()
  self.score_level_data_cfgs = nil
  self.house_score_bubble_cfgs = nil
  self._step_cfgs = nil
  self._events = nil
  mi_tai_score_module:add_event()
  self.bubble_count = 2
  self._handles = {}
  self.npc_root = 0
  self.scene_npc = 0
end

function mi_tai_score_module:close()
  mi_tai_score_module:remove_event()
  if is_null(self.score_cam_root) == false then
    GameObject.Destroy(self.score_cam_root)
  end
  if is_null(self.score_scene_root) == false then
    GameObject.Destroy(self.score_scene_root)
  end
  if self.scene_npc ~= 0 then
    EntityUtil.destroy_entity_by_guid(self.scene_npc)
  end
  self.score_cam_root = nil
  self.score_scene_root = nil
  self.npc_root = 0
  self.scene_npc = 0
end

function mi_tai_score_module:reset_on_disconnect()
  if is_null(self.score_cam_root) == false then
    GameObject.Destroy(self.score_cam_root)
  end
  if is_null(self.score_scene_root) == false then
    GameObject.Destroy(self.score_scene_root)
  end
  if self.scene_npc ~= 0 then
    EntityUtil.destroy_entity_by_guid(self.scene_npc)
  end
  if self._handles then
    for i, handle in ipairs(self._handles) do
      CsUIUtil.DismissResource(handle)
    end
  end
  self._handles = {}
  self.score_cam_root = nil
  self.score_scene_root = nil
  self.npc_root = 0
  self.scene_npc = 0
  self.score_level_data_cfgs = nil
  self.house_score_bubble_cfgs = nil
  self._step_cfgs = nil
end

function mi_tai_score_module:destroy_scene()
  if is_null(self.score_scene_root) == false then
    GameObject.Destroy(self.score_scene_root)
  end
end

function mi_tai_score_module:_init_cam_root(callback)
  if is_null(self.score_cam_root) then
    CsUIUtil.LoadPrefabAsync(score_ctrl_root_path, function(go, handle)
      if go then
        self.score_cam_root = go
        self.score_cam_ctrl = UIUtil.find_cmpt(self.score_cam_root, nil, typeof(MiTaiScoreCtrl))
        self.cam_target = self.score_cam_ctrl.cameraTarget
        self.cam_look = self.score_cam_ctrl.cameraLook
        if callback then
          callback(true)
        end
      elseif callback then
        callback(false)
      end
    end)
  elseif callback then
    callback(true)
  end
end

function mi_tai_score_module:_init_scene_root(callback)
  if is_null(self.score_scene_root) then
    CsUIUtil.LoadPrefabAsync(score_main_scene_root, function(go, handle)
      table.insert(self._handles, handle)
      if go then
        self.score_scene_root = go
        UIUtil.set_active(self.score_scene_root, false)
        self.score_scene_root.transform.position = Vector3(0, 1000, 0)
        self.scene_camera_ctrl = UIUtil.find_cmpt(go, camera_ctrl_path, typeof(CS.MonoHYGCameraWrapper))
        self.npc_root = UIUtil.find_trans(self.score_scene_root.transform, scene_npc_root_path)
        CsUIUtil.DisableSphere(self.score_scene_root.transform)
        if self.npc_root then
          self:_init_scene_npc(callback)
        else
          callback(false)
        end
      else
        callback(false)
      end
    end)
  elseif self.npc_root then
    self:_init_scene_npc(callback)
  else
    callback(false)
  end
end

function mi_tai_score_module:_init_scene_npc(callback)
  if self.scene_npc == 0 then
    self.scene_npc = EntityUtil.create_virtual_npc(self.evaluate_npc_id, self.npc_root.position, self.npc_root.rotation)
    if self.scene_npc ~= 0 then
      callback(true)
    else
      callback(false)
    end
  else
    callback(true)
  end
end

return mi_tai_score_module
