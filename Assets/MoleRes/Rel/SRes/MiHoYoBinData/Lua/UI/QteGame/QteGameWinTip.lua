local M = G.Class("QteGameWinTip", G.UIWindow)
local base = G.UIWindow
local ResultState = {PlayerWin = 0, OtherWin = 1}
local DEFAULT_DURATION = 1
local FinishReason = {Success = 1}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/QteGame/QteGameWinTip"
  self.config.type = EUIType.Dialog
  self._context = nil
  self._show_time = 0
  self._duration = DEFAULT_DURATION
  self._is_close = false
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self._context = self:get_extra_data() or {}
  self._show_time = 0
  self._duration = self:_get_duration(self._context)
  self._is_close = false
  self:_refresh()
end

function M:update(delta_time)
  if self.is_active == false then
    return
  end
  base.update(self, delta_time)
  self._show_time = self._show_time + delta_time
  if self._show_time >= self._duration then
    self:_close()
  end
end

function M:on_close()
  base.on_close(self)
  EventCenter.Broadcast(EventID.Performance.OnQteGameWinTipEnd, nil)
  if self._context and self._context.on_close then
    local callback = self._context.on_close
    self._context.on_close = nil
    callback()
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, function()
    self:_close()
  end)
end

function M:_close()
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_self()
end

function M:_refresh()
  local data = self._context or {}
  local result_state = self:_get_result_state(data)
  if self._state_group_result then
    self._state_group_result:SetState(result_state)
  end
  if self._txt_tip and string.is_valid(data.tip) then
    UIUtil.set_text(self._txt_tip, data.tip)
  end
end

function M:_get_duration(data)
  local duration = data and tonumber(data.duration) or nil
  if duration == nil or duration < 0 then
    return DEFAULT_DURATION
  end
  return duration
end

function M:_get_result_state(data)
  if data.resultState ~= nil then
    return data.resultState
  end
  if data.isSuccess ~= nil then
    return data.isSuccess and ResultState.PlayerWin or ResultState.OtherWin
  end
  if data.finishReason ~= nil then
    return data.finishReason == FinishReason.Success and ResultState.PlayerWin or ResultState.OtherWin
  end
  return ResultState.PlayerWin
end

return M
