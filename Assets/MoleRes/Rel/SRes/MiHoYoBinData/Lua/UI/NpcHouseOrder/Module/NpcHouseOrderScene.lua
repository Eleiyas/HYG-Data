npc_house_order_module = npc_house_order_module or {}

function npc_house_order_module:pull_npc_to_home_for_accept(npc_id)
  local guid = CsNpcUtil.NpcForceIndoors(npc_id, Vector3(0, 1000, 0), Quaternion.Euler(0, 0, 0))
  self.house_order_data.force_pulled = true
  self.house_order_data.npc_guid = guid
  self.house_order_data.wait_for_create = true
end

function npc_house_order_module:pull_npc_to_home_evaluate(npc_id)
  local guid = CsNpcUtil.NpcForceIndoors(npc_id, Vector3(0, 1000, 0), Quaternion.Euler(0, 0, 0))
  self.edit_order_data.force_pulled = true
  self.edit_order_data.npc_guid = guid
  self.edit_order_data.wait_for_create = true
end

function npc_house_order_module:start_order_camera()
  GameplayUtility.Camera.SetFollowActive("NpcHouseOrderCamera", self.camera_target, self.camera_look)
  EventCenter.Broadcast(EventID.LuaSetOverheadHintShowState, false)
end

function npc_house_order_module:exit_order_camera()
  GameplayUtility.Camera.PopState("NpcHouseOrderCamera")
  EventCenter.Broadcast(EventID.LuaSetOverheadHintShowState, true)
end

return npc_house_order_module
