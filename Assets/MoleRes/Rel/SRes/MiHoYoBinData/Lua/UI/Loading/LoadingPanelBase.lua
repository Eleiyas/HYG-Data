local M = G.Class("LoadingPanelBase", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.cur_percent = 0
  self._on_enter_page = nil
  self.is_playing_enter = false
  self.is_playing_exit = false
  self.without_enter = false
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
end

function M:play_enter_anim()
  if self._has_binder and self.without_enter == false then
    self._is_play_anim = true
    self.is_playing_enter = true
    self.binder:PlayEnterAnim(function()
      self._is_play_anim = false
      self.is_playing_enter = false
      self:enter_anim_call_back()
    end)
  else
    self:enter_anim_call_back()
  end
  self.without_enter = false
end

function M:play_exit_anim()
  if self._has_binder then
    self._is_play_anim = true
    self.is_playing_exit = true
    self.binder:PlayExitAnim(function()
      self._is_play_anim = false
      self.is_playing_exit = false
      self:exit_anim_call_back()
    end)
  else
    self:exit_anim_call_back()
  end
end

function M:enter_anim_call_back()
  base.enter_anim_call_back(self)
  if self._on_enter_page then
    self._on_enter_page()
    self._on_enter_page = nil
  end
end

function M:exit_anim_call_back()
  base.exit_anim_call_back(self)
  self.holder:on_panel_exit(self)
end

function M:only_disable()
  self:_inner_set_active(false)
  self:on_disable()
end

function M:on_disable()
  base.on_disable(self)
  self.without_enter = false
  self.is_playing_exit = false
  self.is_playing_enter = false
end

function M:register_events()
  base.register_events(self)
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:init_data()
  self._on_enter_page = nil
end

function M:refresh()
  self:update_percent(0)
  if self._extra_data then
    self._on_enter_page = self._extra_data.onEnterPage
  end
end

function M:update_percent(percent)
  self.cur_percent = percent
end

function M:force_disable()
  self:only_disable()
  if self._is_play_anim and self.binder then
    self.binder:StopAnimation()
    self.binder:ClearAnimationCallback()
  end
end

function M:restart_loading(data)
  self:set_extra_data(data)
  self:init_data()
  self:refresh()
  if self.is_playing_exit then
    self.binder:StopAnimation()
    self.binder:ClearAnimationCallback()
    self:play_enter_anim()
  end
  if self.is_playing_enter == false and self._on_enter_page then
    self._on_enter_page()
    self._on_enter_page = nil
  end
end

return M
