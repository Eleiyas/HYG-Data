level_musicalchairs = level_musicalchairs or {}
level_musicalchairs._cname = "level_musicalchairs"

function level_musicalchairs:add_event()
  level_musicalchairs:remove_event()
  self._events = {}
  self.startgame = false
  self.realstartgame = false
  self.npcid = 0
  self.reachtimes = 0
  self.npcpos = Vector3.zero
  self._events[EventID.LuaOnFinishOnSit] = pack(self, level_musicalchairs._on_finishsit)
  self._events[EventID.LuaOnStartMusicGame] = pack(self, level_musicalchairs._on_startmusicgame)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function level_musicalchairs:_on_finishsit(notify)
  self.startgame = false
  self.realstartgame = false
  if self.npcid == notify then
    CsPerformanceManagerUtil.ShowPerformance(99016)
  else
    CsPerformanceManagerUtil.ShowPerformance(99015)
  end
end

function level_musicalchairs:_on_startmusicgame(notify)
  self.npcid = notify
  self.startgame = true
  local npc = CsEntityManagerUtil.avatarManager:GetNpcEntityByGuid(self.npcid)
  self.npcpos = npc.root.transform.position
  GameplayUtility.PauseUtilityAI(self.npcid)
  GameplayUtility.FreezeBTRunner(self.npcid)
  GameplayUtility.PauseBTRunner(self.npcid, PauseReason.PlayGame)
  GameplayUtility.Avatar.SetStopBehaviorsFlag(self.npcid, true)
  CsCoroutineManagerUtil.InvokeAfterFrames(2, function()
    local player = CsEntityManagerUtil.avatarManager:GetPlayer()
    GameplayUtility.Avatar.DisableCapableBits(player.guid, CapableBits.Move)
  end)
  CsMusicalChairModuleUtil.GotoPos(self.npcid, CsMusicalChairModuleUtil.GetRadioPos(), function()
    self:_openradio()
  end)
end

function level_musicalchairs:_openradio()
  AudioManagerIns:post_eventnew(WEvent.Play_obj_fanmaiji_usable_bgmx_loop_test, nil, nil, nil, function()
    if self.startgame then
      self.realstartgame = false
      local player = CsEntityManagerUtil.avatarManager:GetPlayer()
      player:GetComponent(typeof(LCMove)):DealCircleMove(false, Vector3.zero, 0)
      local npc = CsEntityManagerUtil.avatarManager:GetNpcEntityByGuid(self.npcid)
      npc:GetComponent(typeof(LCMove)):DealCircleMove(false, Vector3.zero, 0)
      local time = CS.UnityEngine.Random.Range(0.3, 1.1)
      CsCoroutineManagerUtil.Invoke(time, function()
        CsMusicalChairModuleUtil.GotoPos(self.npcid, CsMusicalChairModuleUtil.GetNearestInteractPos(), function()
          local id = CsMusicalChairModuleUtil.GetChairGuid()
          CommandUtil.AllocateSSSitCmd(self.npcid, true, id, 0, 0, EntityCmdExecuteType.EnQueue, true)
        end)
      end)
    end
  end)
  CsCoroutineManagerUtil.Invoke(0.5, function()
    self.reachtimes = 0
    local player = CsEntityManagerUtil.avatarManager:GetPlayer()
    local pos1 = (self.npcpos - CsMusicalChairModuleUtil.GetChairPos()) * CsMusicalChairModuleUtil.GetMusicGameRadius() / (self.npcpos - CsMusicalChairModuleUtil.GetChairPos()).magnitude
    pos1 = CsMusicalChairModuleUtil.GetChairPos() + pos1
    local pos2 = 2.0 * CsMusicalChairModuleUtil.GetChairPos() - pos1
    CsMusicalChairModuleUtil.GotoPos(self.npcid, pos1, function()
      self:moveend()
    end, true)
    CsMusicalChairModuleUtil.GotoPos(player.guid, pos2, function()
      self:moveend()
    end, true)
  end)
end

function level_musicalchairs:moveend()
  self.reachtimes = self.reachtimes + 1
  if self.reachtimes >= 2 then
    local player = CsEntityManagerUtil.avatarManager:GetPlayer()
    GameplayUtility.Avatar.EnableCapableBits(player.guid, CapableBits.Move)
    self.realstartgame = true
    local pos = CsMusicalChairModuleUtil.GetChairPos()
    local radius = CsMusicalChairModuleUtil.GetMusicGameRadius()
    player:GetComponent(typeof(LCMove)):DealCircleMove(true, pos, radius)
    local npc = CsEntityManagerUtil.avatarManager:GetNpcEntityByGuid(self.npcid)
    npc:GetComponent(typeof(LCMove)):DealCircleMove(true, pos, radius)
  end
end

function level_musicalchairs:_losegame()
  if self.realstartgame then
    CsMusicalChairModuleUtil.ClearGame()
    self.startgame = false
    self.realstartgame = false
    local player = CsEntityManagerUtil.avatarManager:GetPlayer()
    player:GetComponent(typeof(LCMove)):DealCircleMove(false, Vector3.zero, 0)
    local npc = CsEntityManagerUtil.avatarManager:GetNpcEntityByGuid(self.npcid)
    npc:GetComponent(typeof(LCMove)):DealCircleMove(false, Vector3.zero, 0)
    AudioManagerIns:stop(WEvent.Play_obj_fanmaiji_usable_bgmx_loop_test)
    CsPerformanceManagerUtil.ShowPerformance(99016)
  end
end

function level_musicalchairs:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function level_musicalchairs:init()
  self._events = nil
  level_musicalchairs:add_event()
end

function level_musicalchairs:close()
  level_musicalchairs:remove_event()
end

return level_musicalchairs
