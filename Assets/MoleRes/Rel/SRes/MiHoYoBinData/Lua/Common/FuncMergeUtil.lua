local FuncMergeUtil = {}
FuncMergeUtil._cname = "FuncMergeUtil"
local SCENE_INDEPENDENT = -1
local SCENE_CURRENT = 0

local function _fire(ctrl)
  local fn = ctrl._fn
  local n = ctrl._argc
  if n == 0 then
    fn()
  elseif n == 1 then
    fn(ctrl._a1)
  elseif n == 2 then
    fn(ctrl._a1, ctrl._a2)
  else
    fn(table.unpack(ctrl._args, 1, n))
  end
end

local function _clear_buf(ctrl)
  if ctrl._buf_len > 0 then
    local buf = ctrl._args
    for i = 1, ctrl._buf_len do
      buf[i] = nil
    end
    ctrl._buf_len = 0
  end
end

local function _clear_args(ctrl)
  ctrl._a1 = nil
  ctrl._a2 = nil
  _clear_buf(ctrl)
  ctrl._argc = 0
end

local function _record_args(ctrl, ...)
  local n = select("#", ...)
  ctrl._argc = n
  if n <= 2 then
    ctrl._a1, ctrl._a2 = ...
    _clear_buf(ctrl)
  else
    local buf = ctrl._args
    if not buf then
      buf = {}
      ctrl._args = buf
    end
    for i = 1, n do
      buf[i] = select(i, ...)
    end
    for i = n + 1, ctrl._buf_len do
      buf[i] = nil
    end
    ctrl._buf_len = n
  end
end

local function _settle(ctrl)
  if not ctrl._open then
    return
  end
  ctrl._timer_id = nil
  local should_fire = ctrl._trailing and ctrl._pending
  ctrl._open = false
  ctrl._pending = false
  if should_fire then
    _fire(ctrl)
    if not ctrl._open then
      _clear_args(ctrl)
    end
  end
end

local function _settle_expired(ctrl)
  if ctrl._timer_id then
    CsTimerManagerUtil.StopTimer(ctrl._timer_id)
    ctrl._timer_id = nil
  end
  _settle(ctrl)
end

local function _open_window(ctrl)
  local gen = ctrl._gen + 1
  ctrl._gen = gen
  ctrl._mark_deadline()
  ctrl._timer_id = ctrl._schedule(function()
    if ctrl._gen == gen then
      _settle(ctrl)
    end
  end)
end

function FuncMergeUtil.new(fn, opts)
  assert(type(fn) == "function")
  opts = opts or {}
  assert(opts.leading ~= false or opts.trailing ~= false, "FuncMergeUtil: leading 和 trailing 不能同时为 false")
  local ctrl = {
    _fn = fn,
    _open = false,
    _pending = false,
    _disposed = false,
    _argc = 0,
    _buf_len = 0,
    _gen = 0,
    _timer_id = nil,
    _deadline = nil,
    _debounce = opts.debounce == true,
    _leading = opts.leading ~= false,
    _trailing = opts.trailing ~= false
  }
  local scene = opts.scene_independent and SCENE_INDEPENDENT or SCENE_CURRENT
  local window = opts.window
  assert(window == nil or type(window) == "number" and 0 <= window, "FuncMergeUtil: window 必须是非负数")
  if opts.same_frame then
    local late_update_phase = TimerTickPhase.LateUpdateBehavior
    
    function ctrl._schedule(cb)
      return CsTimerManagerUtil.Invoke(0, cb, late_update_phase, scene)
    end
    
    function ctrl._mark_deadline()
      ctrl._deadline = Time.frameCount
    end
    
    function ctrl._is_expired()
      local deadline = ctrl._deadline
      return deadline ~= nil and deadline < Time.frameCount
    end
  elseif window then
    local phase = TimerTickPhase.UpdateCoroutine
    
    function ctrl._schedule(cb)
      return CsTimerManagerUtil.Invoke(window, cb, phase, scene)
    end
    
    function ctrl._mark_deadline()
      ctrl._deadline = Time.time + window
    end
    
    function ctrl._is_expired()
      local deadline = ctrl._deadline
      return deadline ~= nil and deadline < Time.time
    end
  else
    local frames = opts.frames or 1
    local phase = TimerTickPhase.UpdateCoroutine
    if frames <= 1 then
      frames = 1
      
      function ctrl._schedule(cb)
        return CsTimerManagerUtil.InvokeNextFrame(cb, phase, scene)
      end
    else
      function ctrl._schedule(cb)
        return CsTimerManagerUtil.InvokeAfterFrames(frames, cb, phase, scene)
      end
    end
    
    function ctrl._mark_deadline()
      ctrl._deadline = Time.frameCount + frames
    end
    
    function ctrl._is_expired()
      local deadline = ctrl._deadline
      return deadline ~= nil and deadline < Time.frameCount
    end
  end
  
  function ctrl.trigger(...)
    if ctrl._disposed then
      return
    end
    if ctrl._open and ctrl._is_expired() then
      _settle_expired(ctrl)
    end
    if not ctrl._open then
      ctrl._open = true
      ctrl._pending = false
      _open_window(ctrl)
      if ctrl._leading then
        ctrl._fn(...)
      elseif ctrl._trailing then
        _record_args(ctrl, ...)
        ctrl._pending = true
      end
    else
      if ctrl._debounce and ctrl._timer_id then
        CsTimerManagerUtil.StopTimer(ctrl._timer_id)
        _open_window(ctrl)
      end
      if ctrl._trailing then
        _record_args(ctrl, ...)
        ctrl._pending = true
      end
    end
  end
  
  function ctrl:dispose()
    if self._timer_id then
      CsTimerManagerUtil.StopTimer(self._timer_id)
      self._timer_id = nil
    end
    self._gen = self._gen + 1
    _clear_args(self)
    self._disposed = true
    self._fn = nil
    self._schedule = nil
    self._mark_deadline = nil
    self._is_expired = nil
    self._deadline = nil
    self._open = false
    self._pending = false
  end
  
  return ctrl.trigger, ctrl
end

function FuncMergeUtil.new_frame(fn)
  return FuncMergeUtil.new(fn)
end

function FuncMergeUtil.new_time(fn, window_seconds)
  return FuncMergeUtil.new(fn, {window = window_seconds})
end

function FuncMergeUtil.new_same_frame(fn)
  return FuncMergeUtil.new(fn, {same_frame = true})
end

return FuncMergeUtil
