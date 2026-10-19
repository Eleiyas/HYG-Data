local M = G.Class("StarFriendSocialTransitionPage", G.UIWindow)
local base = G.UIWindow
local page_path = "UI/Friend/StarFriendSocialTransitionPage"

function M:init()
  base.init(self)
  self.config.prefab_path = page_path
  self.config.type = EUIType.Info
end

function M:on_create()
  base.on_create(self)
  self._animator = UIUtil.find_animator(self.trans, "anim")
end

function M:on_enable()
  base.on_enable(self)
  self:_play_trigger()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:play(trigger, on_complete)
  self:set_extra_data({trigger = trigger, on_complete = on_complete})
  self:_play_trigger()
end

local DEFAULT_DURATION = 0.35
local SAFETY_TIMEOUT = 3.0

function M:_play_trigger()
  if not (self._extra_data and self._extra_data.trigger) or not string.is_valid(self._extra_data.trigger) then
    return
  end
  local trigger = self._extra_data.trigger
  local on_complete = self._extra_data.on_complete
  self._play_sequence = (self._play_sequence or 0) + 1
  local current_seq = self._play_sequence
  local state_name = "anui_starfriendsocialtransitionpage_" .. trigger
  local length = DEFAULT_DURATION
  if not_null(self._animator) then
    self._animator.speed = 1
    self._animator:Play(state_name, 0, 0)
    self._animator:Update(0)
    local clip_length = self._animator:GetCurrentAnimatorStateInfo(0).length
    if 0.01 < clip_length then
      length = clip_length
    end
  end
  CsCoroutineManagerUtil.Invoke(length, function()
    if self._play_sequence ~= current_seq then
      return
    end
    if trigger == "in" and not_null(self._animator) then
      self._animator.speed = 0
    end
    if on_complete then
      on_complete()
    end
    if trigger == "out" then
      self:close_self()
    end
    if trigger == "in" then
      CsCoroutineManagerUtil.Invoke(SAFETY_TIMEOUT, function()
        if self._play_sequence == current_seq then
          Logger.LogWarning("[StarFriendSocialTransitionPage] Safety timeout: auto closing stuck transition page")
          self:close_self()
        end
      end)
    end
  end)
end

return M
