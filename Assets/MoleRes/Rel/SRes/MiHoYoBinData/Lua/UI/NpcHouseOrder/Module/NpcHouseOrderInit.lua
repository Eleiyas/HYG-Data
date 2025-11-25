npc_house_order_module = npc_house_order_module or {}
npc_house_order_module._cname = "npc_house_order_module"
lua_module_mgr:require("UI/NpcHouseOrder/Module/NpcHouseOrderData")
lua_module_mgr:require("UI/NpcHouseOrder/Module/NpcHouseOrderMain")
lua_module_mgr:require("UI/NpcHouseOrder/Module/NpcHouseOrderScene")
local camera_ctrl_path = "SceneObj/MiTai/NpcHouseOrderCameraRoot"
npc_house_order_module.panel_type = {
  main = 1,
  detail = 2,
  finished = 3
}
npc_house_order_module.open_from = {
  external = 0,
  main = 1,
  detail = 2,
  finished = 3
}

function npc_house_order_module:init()
  self._events = nil
  npc_house_order_module:add_event()
end

function npc_house_order_module:close()
  npc_house_order_module:remove_event()
end

function npc_house_order_module:clear_on_disconnect()
  self.order_design_req_cfgs = nil
  self.order_design_style_cfgs = nil
  self.all_order_pass_rubric_data = nil
  self.max_furniture_count = nil
  self.house_order_data = nil
  self.edit_order_data = nil
end

function npc_house_order_module:init_camera_controller(callback)
  if is_null(self.camera_root) then
    CsUIUtil.LoadPrefabAsync(camera_ctrl_path, function(go, handle)
      if go then
        self.camera_root = go
        self.camera_handle = handle
        self.camera_ctrl = UIUtil.find_cmpt(self.camera_root, nil, typeof(MiTaiCameraSequenceCtrl))
        self.camera_target = self.camera_ctrl.cameraFollowTarget
        self.camera_look = self.camera_ctrl.cameraLookTarget
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

function npc_house_order_module:dispose_camera_controller()
  if self.camera_root then
    GameObject.Destroy(self.camera_root)
    self.camera_root = nil
  end
  if self.camera_handle then
    CsUIUtil.DismissResource(self.camera_handle)
    self.camera_handle = nil
  end
  self.camera_ctrl = nil
  self.camera_target = nil
  self.camera_look = nil
end

return npc_house_order_module
