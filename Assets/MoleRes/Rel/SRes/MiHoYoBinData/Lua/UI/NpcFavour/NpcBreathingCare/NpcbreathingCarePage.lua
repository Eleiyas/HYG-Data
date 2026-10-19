local M = G.Class("NpcbreathingCarePage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Npc/NpcbreathingCarePage"
  self.config.type = EUIType.Page
end

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  local extra_data = self._extra_data or {}
  self._finish_callback = extra_data.onFinish
  self._interrupt_callback = extra_data.onInterrupt
  self._duration_second = extra_data.durationSecond
  self._start_second = extra_data.startSecond
  self._elapsed_time = self._start_second
  self._npc_id = extra_data.npcId
  UIUtil.set_active(self._trans_anim, false)
  CsNPCSpecialActivityModuleUtil.SetNpcBreathingCarePassedTime(self._npc_id, self._elapsed_time)
  CsNPCSpecialActivityModuleUtil.PlayBreathingCareAtl(self._npc_id, function()
    UIUtil.set_active(self._trans_anim, true)
    self._anim_helper:SetTriggerWithCallback("stage1", function()
      self:on_anim_loop_end()
    end)
  end)
end

function M:on_anim_loop_end()
  if self._elapsed_time >= self._duration_second then
    CsNPCSpecialActivityModuleUtil.StopBreathingCareAtl(self._npc_id, true)
    if self._finish_callback then
      self._finish_callback()
    end
    self:close_self()
    return
  end
  self._anim_helper:SetTriggerWithCallback("stage1", function()
    self:on_anim_loop_end()
  end)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  self._elapsed_time = self._elapsed_time + deltaTime
  self._time = math.floor(self._elapsed_time)
  _, _, self._m, self._s = LuaTimeUtil.split_time(self._time)
  self._str_m = self._m >= 10 and tostring(self._m) or "0" .. tostring(self._m)
  self._str_s = self._s >= 10 and tostring(self._s) or "0" .. tostring(self._s)
  UIUtil.set_text(self._txt_time, self._str_m .. ":" .. self._str_s)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
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

function M:bind_callbacks()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
end

function M:_on_btn_close_click()
  CsNPCSpecialActivityModuleUtil.StopBreathingCareAtl(self._npc_id, false)
  CsNPCSpecialActivityModuleUtil.SetNpcBreathingCarePassedTime(self._npc_id, math.floor(self._elapsed_time))
  if self._interrupt_callback then
    self._interrupt_callback()
  end
  self:close_self()
end

return M
