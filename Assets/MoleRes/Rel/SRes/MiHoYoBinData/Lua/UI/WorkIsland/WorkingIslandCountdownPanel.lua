local M = G.Class("WorkingIslandCountdownPanel", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self._countdown_time = 0
  self._finish_time = 0
end

function M:set_start_info(start_time)
  self._countdown_time = start_time + CsWorkIslandModuleUtil.waitTime
  self:_set_show_hide(true)
end

function M:set_finish_info(finish_time)
  self._finish_time = finish_time
  self:_set_show_hide(true)
  UIUtil.set_text(self._txt_title, UIUtil.get_text_by_id("Tips_FishIsland_CountdownEnd"))
end

function M:_set_show_hide(show_countdown)
  UIUtil.set_active(self._txt_countdown, show_countdown)
  UIUtil.set_active(self._txt_word, not show_countdown)
  UIUtil.set_active(self._txt_title, show_countdown)
  UIUtil.set_text(self._txt_title, UIUtil.get_text_by_id("Tips_FishIsland_CountdownStart"))
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaWorkIslandScoreUpdateNotify, function(score)
  end)
end

function M:update(deltaTime)
  local current_time = TimeUtil.ServerUtcTimeSeconds
  local countdown_text
  if not is_null(self._countdown_time) and current_time <= self._countdown_time then
    local remainingTime = self._countdown_time - current_time
    if 0 < remainingTime then
      local minutes = math.floor(remainingTime / 60)
      local seconds = remainingTime % 60
      countdown_text = string.format("%2d", seconds)
      UIUtil.set_text(self._txt_countdown, countdown_text)
    else
      countdown_text = "0"
      UIUtil.set_text(self._txt_countdown, countdown_text)
      self._countdown_time = 0
      self:_set_show_hide(false)
    end
  end
  if current_time >= self._countdown_time and self._countdown_time ~= 0 then
    self._countdown_time = 0
    self:_set_show_hide(false)
  end
  if self._finish_time - current_time <= CsWorkIslandModuleUtil.waitTime and current_time <= self._finish_time then
    local remainingTime = self._finish_time - current_time
    if 0 < remainingTime then
      local minutes = math.floor(remainingTime / 60)
      local seconds = remainingTime % 60
      countdown_text = string.format("%2d", seconds)
      UIUtil.set_text(self._txt_countdown, countdown_text)
    else
      countdown_text = "0"
      UIUtil.set_text(self._txt_countdown, countdown_text)
      self._finish_time = 0
    end
  end
  if current_time >= self._finish_time and self._finish_time ~= 0 then
    self._finish_time = 0
  end
end

return M
