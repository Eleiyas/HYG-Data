local M = G.Class("AudioInputManager")

function M:__ctor()
end

function M:acquire(frequency, window_size)
  frequency = frequency or 0
  window_size = window_size or 0
  return CsAudioInputManagerUtil.Acquire(frequency, window_size)
end

function M:release(handle)
  if not handle or handle == 0 then
    return
  end
  CsAudioInputManagerUtil.Release(handle)
end

function M:is_available()
  return CsAudioInputManagerUtil.IsAvailable()
end

function M:get_rms()
  return CsAudioInputManagerUtil.GetLatestRms()
end

function M:get_intensity()
  return CsAudioInputManagerUtil.GetLatestIntensity()
end

return M
