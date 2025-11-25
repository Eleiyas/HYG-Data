local M = G.Class("AudioManager")

function M:_init()
  if is_null(self.audio_manager) then
    self.audio_manager = CsAudioManagerUtil
  end
  return not is_null(self.audio_manager)
end

function M:post_event(event_id, gameObject, start_cb, end_cb, need_follow, pos_offset)
  print(tostring(event_id))
  if self:_init() then
    self.audio_manager.PostEvent(event_id, gameObject, start_cb, end_cb, need_follow, pos_offset)
  end
end

function M:post_eventnew(event_id, gameObject, before_cb, start_cb, end_cb)
  if self:_init() then
    self.audio_manager.PostEvent(event_id, gameObject, before_cb, start_cb, end_cb)
  end
end

function M:post_event_by_cfg(event, gameObject, before_start_cb, start_cb, end_cb, posOffset, rotOffset)
  if self:_init() then
    if rotOffset == nil and posOffset == nil then
      self.audio_manager.PostEventByCfg(event, gameObject, before_start_cb, start_cb, end_cb)
    elseif rotOffset == nil then
      self.audio_manager.PostEventByCfg(event, gameObject, before_start_cb, start_cb, end_cb, posOffset)
    else
      self.audio_manager.PostEventByCfg(event, gameObject, before_start_cb, start_cb, end_cb, posOffset, rotOffset)
    end
  end
end

function M:play_sfx(event_id, sfx_type)
  if self:_init() then
    self.audio_manager.PlayUISFX(event_id, sfx_type)
  end
end

function M:stop(event_id)
  if self:_init() then
    self.audio_manager.Stop(event_id)
  end
end

function M:stop_by_playing_id(playing_id)
  if self:_init() then
    self.audio_manager.StopByPlayingI(playing_id)
  end
end

function M:pause(event_id)
  if self:_init() then
    self.audio_manager.Pause(event_id)
  end
end

function M:pause_by_playing_id(playing_id)
  if self:_init() then
    self.audio_manager.PauseByPlayingID(playing_id)
  end
end

function M:resume(event_id)
  if self:_init() then
    self.audio_manager.Resume(event_id)
  end
end

function M:resume_by_playing_id(playing_id)
  if self:_init() then
    self.audio_manager.ResumeByPlayingID(playing_id)
  end
end

function M:get_switch(group_id, gameObject)
  if self:_init() then
    return self.audio_manager.GetSwitch(group_id, gameObject)
  end
  return nil
end

function M:set_switch(group_id, state, gameObject)
  if self:_init() then
    self.audio_manager.SetSwitch(group_id, state, gameObject)
  end
end

function M:set_state(group_id, state)
  if self:_init() then
    self.audio_manager.SetState(group_id, state)
  end
end

function M:get_state(group_id)
  if self:_init() then
    return self.audio_manager.GetState(group_id)
  end
  return nil
end

function M:set_rtpc(rtpc_id, value, playing_id)
  if self:_init() then
    self.audio_manager.SetRTPC(rtpc_id, value, playing_id)
  end
end

function M:get_rtpc(rtpc_id, playing_id, gameObject, rtpc_type)
  if self:_init() then
    return self.audio_manager.GetRTPC(rtpc_id, playing_id, gameObject, rtpc_type)
  end
  return nil
end

function M:get_audio_switch()
  if self:_init() then
    return self.audio_manager.SFXSwitch
  end
  return false
end

function M:set_audio_switch(value)
  if self:_init() then
    self.audio_manager.SFXSwitch = value
  end
end

function M:get_music_switch()
  if self:_init() then
    return self.audio_manager.musicSwitch
  end
  return false
end

function M:set_music_switch(value)
  if self:_init() then
    self.audio_manager.musicSwitch = value
  end
end

function M:get_audio_background_switch()
  if self:_init() then
    return self.audio_manager.audioBackgroundSwitch
  end
  return false
end

function M:set_audio_background_switch(value)
  if self:_init() then
    self.audio_manager.audioBackgroundSwitch = value
  end
end

function M:play_btn_sfx()
  if is_null(self._global_click) then
    self._global_click = CsAssetConfigManagerUtil.uiAudioGlobal.click
  end
  self:play_sfx(self._global_click, UISFXType.Button.value__)
end

return M
