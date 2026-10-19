local M = G.Class("StarExploreTeleportationDetail", G.UIPanel)
local base = G.UIPanel
local teleportation_npc_icon_cls = "UI/StarExplore/StarExploreTeleportationNpcIcon"
local teleport_transition_in_seconds = 1
local teleport_rsp_timeout_seconds = 10
local teleport_rsp_registered = false
local teleport_seq = 0
local teleport_timeout_timer = 0

local function _clear_teleport_pending()
  teleport_seq = teleport_seq + 1
  if teleport_timeout_timer ~= 0 then
    CsTimerManagerUtil.StopTimer(teleport_timeout_timer)
    teleport_timeout_timer = 0
  end
  if teleport_rsp_registered then
    teleport_rsp_registered = false
    NetHandlerIns:unregister_cmd_handler(CS.Proto.StellarSeaInGameStationTeleportRsp)
  end
end

local function _on_station_teleport_rsp(data)
  _clear_teleport_pending()
  local is_success = data == nil or data.Retcode == 0
  if is_success then
    return
  end
  Logger.LogError("[StarExploreTeleportationDetail] station teleport failed, retcode = " .. tostring(data.Retcode))
  EventCenter.Broadcast(EventID.LuaShowCommonTransitionOut, nil)
end

local function _on_teleport_timeout(seq)
  if seq ~= teleport_seq then
    return
  end
  Logger.LogError("[StarExploreTeleportationDetail] station teleport timeout, no rsp")
  _clear_teleport_pending()
  EventCenter.Broadcast(EventID.LuaShowCommonTransitionOut, nil)
end

local function _is_npc_unlocked(npc_id)
  if npc_id == nil or npc_id == 0 then
    return false
  end
  if CsNpcInvitationModuleUtil.IsNull and CsNpcInvitationModuleUtil.IsNull() then
    return false
  end
  local invitation_data = CsNpcInvitationModuleUtil.GetInvitationData(npc_id)
  if invitation_data == nil then
    return false
  end
  local invitation_status = CsNpcInvitationModuleUtil.InvitationStatus
  if invitation_status ~= nil and invitation_status.Unacquired ~= nil then
    return invitation_data.Status ~= invitation_status.Unacquired
  end
  return invitation_data.Status ~= 1
end

local function _contains_layer_id(layer_list, layer_id)
  if layer_list == nil or layer_id == nil then
    return false
  end
  if type(layer_list) == "string" then
    for value in string.gmatch(layer_list, "[^,]+") do
      if tonumber(value) == layer_id then
        return true
      end
    end
  elseif type(layer_list) == "table" then
    for _, value in pairs(layer_list) do
      if tonumber(value) == layer_id then
        return true
      end
    end
  end
  return false
end

function M:init()
  base.init(self)
end

function M:on_enable()
  base.on_enable(self)
  self:refresh_data()
end

function M:on_create()
  base.on_create(self)
  self._npc_icon_items = {}
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:set_data(data)
  self._data = data
  self._is_outside = data ~= nil and data.isOutsideStarSea == true
  self._is_season_layer = data ~= nil and data.isSeasonLayer == true
  local galaxy_id = data and data.galaxyid or CsStarSeaManagerV2Util.GetGalaxyId()
  local layer = data and data.layer or CsStarSeaManagerV2Util.GetLayerId()
  local display_npc = {}
  local place_name = ""
  local layer_cfg_id = data and data.layerCfgId or 0
  local layer_cfg_table = ExcelDataUtil.get_table(typeof(BStellarSeaLayerCfg)) or {}
  for _, cfg in pairs(layer_cfg_table) do
    if cfg.galaxyid == galaxy_id and cfg.layer == layer then
      place_name = cfg.name or ""
      if layer_cfg_id == 0 then
        layer_cfg_id = cfg.id or 0
      end
      break
    end
  end
  UIUtil.set_text(self._txt_station_name, place_name)
  if 0 < layer_cfg_id then
    local npc_pool_cfg_table = ExcelDataUtil.get_table(typeof(BStellarSeaNpcPoolCfg)) or {}
    for _, cfg in pairs(npc_pool_cfg_table) do
      local contains_layer = false
      local layer_len = cfg.layerlistLength
      if type(cfg.layerlist) == "function" and layer_len ~= nil then
        for i = 0, layer_len - 1 do
          if tonumber(cfg:layerlist(i)) == layer_cfg_id then
            contains_layer = true
            break
          end
        end
      else
        contains_layer = _contains_layer_id(cfg.layerlist or cfg.LayerList, layer_cfg_id)
      end
      if contains_layer then
        local npc_id = cfg.npcid
        if npc_id and 0 < npc_id then
          table.insert(display_npc, npc_id)
        end
      end
    end
  end
  local current = CsStarSeaManagerV2Util.GetLayerCurVisitNum(layer_cfg_id) or 0
  local goal = CsStarSeaManagerV2Util.GetLayerGoalVisitNum(layer_cfg_id) or 0
  UIUtil.set_text(self._txt_progress_num, tostring(current) .. "/" .. tostring(goal))
  UIUtil.set_text_by_id(self._txt_chance_encounter, "StarrySeaMapTeleportationPage_txt_chanceEncounter_1")
  UIUtil.set_text_by_id(self._txt_regional_explorationnum, "StarrySeaMapTeleportationPage_txt_explore_2")
  self._target_layer_id = layer_cfg_id
  self:_refresh_npc_items(display_npc)
  self:refresh_data()
  if not self._tp_btn_registered then
    self._tp_btn_registered = true
    self:bind_callback(self._btn_tp, pack(self, M._on_btn_tp_click))
  end
end

function M:_refresh_npc_items(display_npc)
  self._npc_icon_items = self._npc_icon_items or {}
  for _, item in ipairs(self._npc_icon_items) do
    if item.set_active ~= nil then
      item:set_active(false)
    end
  end
  self._obj_npcitem:SetActive(false)
  local parent = self._obj_npcitem.transform.parent
  local display_idx = 0
  for _, npc_id in ipairs(display_npc or {}) do
    if npc_id ~= 1010 then
      display_idx = display_idx + 1
      local item = self._npc_icon_items[display_idx]
      if item == nil then
        local go = GameObject.Instantiate(self._obj_npcitem, parent)
        item = self:add_panel(teleportation_npc_icon_cls, go)
        self._npc_icon_items[display_idx] = item
      end
      local is_encountered = self._is_outside or self._is_season_layer or _is_npc_unlocked(npc_id)
      item.trans:SetParent(parent, false)
      item.trans:SetAsLastSibling()
      item:set_active(true)
      item:set_data(npc_id, is_encountered)
    end
  end
end

function M:refresh_data()
  self._state_group_btn_tp:SetState(1)
  self._state_group_btn:SetState(1)
  UIUtil.set_text(self._txt_unlock_details, "")
  if self._data ~= nil and self._data.isUnlocked == false then
    self._state_group:SetState(0)
    local layer_cfg_id = self._data and self._data.layerCfgId or self._target_layer_id or 0
    if 0 < layer_cfg_id then
      local layer_cfg = ExcelDataUtil.get_value(typeof(BStellarSeaLayerCfg), layer_cfg_id)
      local unlock_tips = layer_cfg and layer_cfg.unlocktips or nil
      if unlock_tips ~= nil and unlock_tips ~= "" then
        UIUtil.set_text_by_id(self._txt_unlock_details, unlock_tips)
      end
    end
  elseif CsStarSeaUtil.IsLightHouseTransportUnlocked() then
    self._state_group:SetState(1)
  else
    self._state_group:SetState(0)
  end
  UIUtil.set_active(self._trans_progress_num, not self._is_outside)
end

function M:_get_station_guid()
  local info = self._data
  if info == nil then
    return nil
  end
  return info.currentStationGuid
end

function M:_on_btn_tp_click()
  if self._is_season_layer and CsStarSeaUtil.IsCurrentSceneMaterialStar() then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("ThemeSeason_GoToStarsea_Error_Tips2"))
    return
  end
  if self._is_outside and not level_module:cur_level_is_main() then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("ThemeSeason_GoToStarsea_Error_Tips1"))
    return
  end
  if self._is_outside then
    self:_go_to_star_sea_layer()
    return
  end
  local guid = self:_get_station_guid()
  if guid == nil then
    Logger.LogError("[StarExploreTeleportationDetail] station guid not found")
    return
  end
  local scene_index = GameplayUtilities_Common.GetCurSceneIndex()
  local layer_id = self._target_layer_id or 0
  self:_close_teleportation_page()
  EventCenter.Broadcast(EventID.LuaShowCommonTransitionIn, nil)
  _clear_teleport_pending()
  local seq = teleport_seq
  teleport_rsp_registered = true
  NetHandlerIns:register_cmd_handler(CS.Proto.StellarSeaInGameStationTeleportRsp, _on_station_teleport_rsp)
  CsTimerManagerUtil.Invoke(teleport_transition_in_seconds, function()
    if seq ~= teleport_seq then
      return
    end
    local req = NetHandlerIns:create_cmd(CS.Proto.StellarSeaInGameStationTeleportReq)
    req.SceneIndex = scene_index
    req.Guid = guid
    req.TargetLayerId = layer_id
    NetHandlerIns:send_msg(req)
    teleport_timeout_timer = CsTimerManagerUtil.Invoke(teleport_rsp_timeout_seconds, function()
      _on_teleport_timeout(seq)
    end, TimerTickPhase.UpdateCoroutine, CsTimerManagerUtil.SCENE_INDEPENDENT)
  end, TimerTickPhase.UpdateCoroutine, CsTimerManagerUtil.SCENE_INDEPENDENT)
end

function M:_go_to_star_sea_layer()
  local layer_id = self._target_layer_id or 0
  if layer_id == 0 then
    Logger.LogError("[StarExploreTeleportationDetail] target layer not found")
    return
  end
  EventCenter.Broadcast(EventID.LuaOpenStarExploreParePage, layer_id)
  self:_close_teleportation_page()
end

function M:_close_teleportation_page()
  local page = UIManagerInstance:get_window_by_class("UI/StarExplore/StarExploreTeleportationPage")
  if page ~= nil then
    UIManagerInstance:close(page.guid)
  end
end

return M
