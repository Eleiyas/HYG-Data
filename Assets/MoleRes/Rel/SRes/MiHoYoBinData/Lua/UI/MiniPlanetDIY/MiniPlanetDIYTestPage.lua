local M = G.Class("MiniPlanetDIYTestPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "MiniPlanetDIY_Prototype/UI/MiniPlanetDIY/MiniPlanetDIYTestPage"
  self.config.type = EUIType.Page
  self.config.scene_prefab_path = "MiniPlanetDIY_Prototype/Scene/Map/4_UI/SceneMap_406ChuShiXingQiuXuanZe"
end

function M:on_create()
  base.on_create(self)
  self._planet_res_handle = 0
  self._planet_go = nil
  self._planet_entity_guid = 0
  self._player_entity_guid = 0
  self._is_page_active = false
  self._scene_tool = nil
  self._trans_planet_root = nil
  self._mini_planet_editor = nil
  if not is_null(self.ui_scene_obj) then
    self:_ensure_editor()
    self._scene_tool = UIUtil.find_cmpt(self.ui_scene_obj, nil, typeof(PlanetChooseSceneTool))
    if not_null(self._scene_tool) then
      self._trans_planet_root = self._scene_tool.PlanetRoot
      CsUIUtil.DisableSphere(self.ui_scene_obj.transform)
      if self._scene_tool.InitPosition then
        self.ui_scene_obj.transform:SetLocalPosition(self._scene_tool.InitPosition.x, self._scene_tool.InitPosition.y, self._scene_tool.InitPosition.z)
        self.ui_scene_obj.transform:SetLocalEulerAngles(self._scene_tool.InitRotation.x, self._scene_tool.InitRotation.y, self._scene_tool.InitRotation.z)
      end
    end
  end
  self._editor_panel = self:add_panel_async("UI/MiniPlanetDIY/AvatarInfoEditorPanel", nil, self.trans)
  self._editor_panel:change_state(EUIState.Show)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_cleanup_planet_content()
  if not is_null(self._mini_planet_editor) then
    self._mini_planet_editor:SetPlanetRoot(nil)
  end
  if self._planet_entity_guid and self._planet_entity_guid ~= 0 then
    CS.miHoYo.HYG.MiniPlanetDIYPlanetFactory.DestroyDIYPlanet(self._planet_entity_guid)
    self._planet_entity_guid = 0
  end
  self._player_entity_guid = 0
  self._planet_go = nil
  if self._planet_res_handle and 0 < self._planet_res_handle then
    CsUIUtil.DismissResource(self._planet_res_handle)
    self._planet_res_handle = 0
  end
end

function M:on_enable()
  base.on_enable(self)
  self._is_page_active = true
  lua_event_module:send_event(lua_event_module.event_type.set_click_scene_active, false)
  if self._planet_entity_guid and self._planet_entity_guid ~= 0 then
    return
  end
  if is_null(self._trans_planet_root) then
    Logger.LogError("MiniPlanetDIYTestPage: PlanetRoot nil, check PlanetChooseSceneTool on ui_scene_obj")
    return
  end
  if not_null(self._scene_tool) then
    CsGameplayUtilitiesCameraUtil.PushStateAndSetTargetByTransform("UIScene", self._scene_tool.FollowTarget, self._scene_tool.LookTarget)
  end
  local uid = 0
  if player_module ~= nil and player_module.get_player_data ~= nil then
    local player_data = player_module:get_player_data()
    if player_data ~= nil and player_data.uid ~= nil then
      uid = player_data.uid
    end
  end
  local position = self._trans_planet_root.position
  local rotation = self._trans_planet_root.rotation
  local scale = self._trans_planet_root.lossyScale * 1.2
  self._planet_entity_guid = CS.miHoYo.HYG.MiniPlanetDIYPlanetFactory.CreateDIYPlanetWithCallback(uid, position, rotation, scale, function(go)
    if is_null(self) or not self._is_page_active then
      return
    end
    if is_null(go) then
      Logger.LogError("MiniPlanetDIYTestPage: planet main gameobject is nil.")
      return
    end
    self._planet_go = go
    CsUIUtil.DisableSphere(go.transform)
    if not is_null(self._mini_planet_editor) then
      self._mini_planet_editor:SetPlanetRoot(go.transform)
      self._mini_planet_editor:EnableEditing()
      self:_request_self_diy_snapshot()
    end
  end)
  if self._planet_entity_guid == 0 then
    Logger.LogError("MiniPlanetDIYTestPage: CreateDIYPlanetWithCallback failed.")
    return
  end
  self._player_entity_guid = CS.miHoYo.HYG.MiniPlanetDIYPlanetFactory.CreateDIYPlayerEntity(self._planet_entity_guid, uid, true, 0)
  if self._player_entity_guid == 0 then
    Logger.LogError("MiniPlanetDIYTestPage: CreateDIYPlayerEntity failed.")
  end
end

function M:on_disable()
  base.on_disable(self)
  self._is_page_active = false
  lua_event_module:send_event(lua_event_module.event_type.set_click_scene_active, true)
  self:_cleanup_planet_content()
  CsGameplayUtilitiesCameraUtil.PopState("UIScene")
end

function M:_ensure_editor()
  if not is_null(self._mini_planet_editor) then
    return
  end
  if is_null(self.ui_scene_obj) then
    return
  end
  self._mini_planet_editor = self.ui_scene_obj:GetComponent(typeof(CS.miHoYo.HYG.MiniPlanetDIYEditor))
  if is_null(self._mini_planet_editor) then
    self._mini_planet_editor = self.ui_scene_obj:AddComponent(typeof(CS.miHoYo.HYG.MiniPlanetDIYEditor))
  end
end

function M:_request_self_diy_snapshot()
  if is_null(self._mini_planet_editor) then
    return
  end
  local req = CS.Proto.LittlePlanetDiyGetReq()
  local uid = 0
  if player_module ~= nil and player_module.get_player_data ~= nil then
    local player_data = player_module:get_player_data()
    if player_data ~= nil and player_data.uid ~= nil then
      uid = player_data.uid
    end
  end
  req.TargetUid = uid
  NetHandlerIns.net_handler:Send(req, function(rsp)
    if is_null(self) or not self._is_page_active then
      return
    end
    self:_on_recv_diy_get_rsp(rsp)
  end, typeof(CS.Proto.LittlePlanetDiyGetRsp), false)
end

function M:_on_recv_diy_get_rsp(rsp)
  if is_null(rsp) or rsp.Retcode ~= 0 then
    return
  end
  if is_null(self._mini_planet_editor) then
    return
  end
  local edit_handler = self._mini_planet_editor.EditHandler
  if is_null(edit_handler) then
    return
  end
  edit_handler:ApplySnapshot(rsp)
end

return M
