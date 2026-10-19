local FuncMergeUtil = require("Common/FuncMergeUtil")

local function make(opts)
  local calls = {}
  local _, ctrl = FuncMergeUtil.new(function(...)
    calls[#calls + 1] = {
      ...
    }
  end, opts)
  local cbs = {}
  
  function ctrl._schedule(cb)
    cbs[#cbs + 1] = cb
    return 0
  end
  
  return ctrl, calls, cbs
end

local function run_logic_tests()
  local log = {}
  
  local function ok(name, cond)
    log[#log + 1] = (cond and "PASS  " or "FAIL  ") .. name
  end
  
  do
    local c, calls, cbs = make(nil)
    c.trigger("x")
    ok("1 single leading fired", #calls == 1 and calls[1][1] == "x")
    cbs[1]()
    ok("1 single no trailing", #calls == 1)
  end
  do
    local c, calls, cbs = make(nil)
    c.trigger("a")
    c.trigger("b")
    c.trigger("c")
    ok("2 leading immediate a", #calls == 1 and calls[1][1] == "a")
    cbs[1]()
    ok("2 trailing last c", #calls == 2 and calls[2][1] == "c")
  end
  do
    local c, calls, cbs = make({leading = false})
    c.trigger("a")
    c.trigger("b")
    ok("3 no leading", #calls == 0)
    cbs[1]()
    ok("3 trailing only b", #calls == 1 and calls[1][1] == "b")
  end
  do
    local c, calls, cbs = make({trailing = false})
    c.trigger("a")
    c.trigger("b")
    ok("4 leading only a", #calls == 1 and calls[1][1] == "a")
    cbs[1]()
    ok("4 trailing suppressed", #calls == 1)
  end
  do
    local c, calls, cbs = make(nil)
    c.trigger("a")
    c.trigger("b")
    cbs[1]()
    c.trigger("c")
    ok("5 reopen leading c", #calls == 3 and calls[3][1] == "c")
  end
  do
    local c, calls, cbs = make({debounce = true})
    c.trigger("a")
    c.trigger("b")
    c.trigger("c")
    ok("6 debounce reschedule x3", #cbs == 3)
    cbs[#cbs]()
    ok("6 debounce trailing c", #calls == 2 and calls[2][1] == "c")
  end
  do
    local c, calls, cbs = make(nil)
    c.trigger()
    c.trigger(1, 2, 3, 4)
    cbs[1]()
    ok("7 argc0 leading", #calls[1] == 0)
    local last = calls[2]
    ok("7 argc4 trailing", last and #last == 4 and last[1] == 1 and last[4] == 4)
  end
  do
    local c, calls, cbs = make(nil)
    c.trigger("a")
    c.trigger("b")
    c:dispose()
    ok("8 dispose clears", c._fn == nil and c._open == false and c._timer_id == nil and c._disposed == true)
  end
  do
    local phase_ok = TimerTickPhase ~= nil and TimerTickPhase.LateUpdateBehavior ~= nil and TimerTickPhase.UpdateCoroutine ~= nil
    ok("9 TimerTickPhase enum", phase_ok)
    local c, calls, cbs = make({same_frame = true})
    c.trigger("a")
    c.trigger("b")
    cbs[1]()
    ok("9 same_frame first+last", #calls == 2 and calls[1][1] == "a" and calls[2][1] == "b")
  end
  do
    local run_count = 0
    
    local function err_fn()
      run_count = run_count + 1
      if run_count == 1 then
        error("boom")
      end
    end
    
    local _, c = FuncMergeUtil.new(err_fn, {leading = false})
    local cbs = {}
    
    function c._schedule(cb)
      cbs[#cbs + 1] = cb
      return 0
    end
    
    c.trigger()
    pcall(cbs[1])
    ok("10 open reset after trailing error", c._open == false and c._pending == false)
    c.trigger()
    ok("10 recover reopen", c._open == true)
  end
  do
    local ok_assert = pcall(FuncMergeUtil.new, function()
    end, {leading = false, trailing = false})
    ok("11 double-false asserts", ok_assert == false)
  end
  do
    local c, calls, cbs = make(nil)
    c.trigger("a")
    c:dispose()
    local no_throw = pcall(function()
      c.trigger("b")
    end)
    ok("12 trigger after dispose is noop", no_throw == true and #calls == 1)
  end
  do
    local calls = {}
    local ctrl
    local reentered = false
    
    local function fn(v)
      calls[#calls + 1] = v
      if not reentered then
        reentered = true
        ctrl.trigger("c")
      end
    end
    
    local _, c = FuncMergeUtil.new(fn, {leading = false})
    ctrl = c
    local cbs = {}
    
    function c._schedule(cb)
      cbs[#cbs + 1] = cb
      return 0
    end
    
    c.trigger("b")
    cbs[1]()
    ok("13 reentry keeps new args", c._pending == true and c._argc == 1 and c._a1 == "c")
    cbs[2]()
    ok("13 reentry trailing c", #calls == 2 and calls[2] == "c")
  end
  do
    local c, calls, cbs = make(nil)
    c.trigger("a")
    c.trigger("b")
    c._deadline = -1
    c.trigger("c")
    ok("14 expired settles pending b", 2 <= #calls and calls[2][1] == "b")
    ok("14 expired reopens with c", #calls == 3 and calls[3][1] == "c" and c._open == true)
  end
  do
    local c, calls, cbs = make(nil)
    c.trigger("a")
    c.trigger("b")
    c.trigger("c")
    ok("15 not expired keeps window", #calls == 1 and c._open == true and c._pending == true)
  end
  do
    local c, calls, cbs = make(nil)
    c.trigger("a")
    c.trigger("b")
    local stale_cb = cbs[1]
    c._deadline = -1
    c.trigger("c")
    c.trigger("d")
    stale_cb()
    ok("16 stale timer ignored", #calls == 3 and c._open == true and c._pending == true)
    cbs[#cbs]()
    ok("16 new window settles normally", #calls == 4 and calls[4][1] == "d")
  end
  do
    local c, calls, cbs = make(nil)
    c.trigger("a")
    local stale_cb = cbs[1]
    c:dispose()
    local no_throw = pcall(stale_cb)
    ok("17 callback after dispose is noop", no_throw == true and #calls == 1)
  end
  do
    local c, calls, cbs = make({leading = false})
    c.trigger(1, 2, 3, 4)
    cbs[1]()
    ok("18 buffer cleared after settle", c._args[1] == nil and c._args[4] == nil and c._buf_len == 0)
    c.trigger("p", "q", "r", "s")
    c.trigger("x")
    ok("18 fastpath clears buffer", c._args[2] == nil and c._args[4] == nil and c._buf_len == 0)
  end
  do
    local passed = pcall(FuncMergeUtil.new, function()
    end, {window = "0.3"})
    ok("19 bad window asserts", passed == false)
  end
  print("[FuncMergeTest] Part1 状态机逻辑:\n" .. table.concat(log, "\n"))
end

local function run_frame_tests()
  local reg = Time.frameCount
  local result = {
    next_f = -1,
    same_reg = -1,
    same_f = -1,
    stopped_fired = false,
    scene_indep_f = -1
  }
  CsTimerManagerUtil.InvokeNextFrame(function()
    result.next_f = Time.frameCount
  end)
  CsTimerManagerUtil.Invoke(0, function()
    result.same_reg = Time.frameCount
    CsTimerManagerUtil.Invoke(0, function()
      result.same_f = Time.frameCount
    end, TimerTickPhase.LateUpdateBehavior)
  end, TimerTickPhase.UpdateBehavior)
  local stop_id = CsTimerManagerUtil.InvokeNextFrame(function()
    result.stopped_fired = true
  end)
  CsTimerManagerUtil.StopTimer(stop_id)
  CsTimerManagerUtil.Invoke(0, function()
    result.scene_indep_f = Time.frameCount
  end, TimerTickPhase.LateUpdateBehavior, CsTimerManagerUtil.SCENE_INDEPENDENT)
  CsTimerManagerUtil.InvokeAfterFrames(5, function()
    local log = {}
    log[#log + 1] = string.format("reg=%d next_f=%d same_reg=%d same_f=%d stopped_fired=%s scene_indep_f=%d", reg, result.next_f, result.same_reg, result.same_f, tostring(result.stopped_fired), result.scene_indep_f)
    log[#log + 1] = result.next_f > reg and "PASS  InvokeNextFrame fired on later frame" or "FAIL  next_f"
    log[#log + 1] = result.same_f == result.same_reg and result.same_reg > 0 and "PASS  same_frame TRUE same-frame when triggered in Update phase" or "FAIL  same_frame timing"
    log[#log + 1] = result.stopped_fired == false and "PASS  StopTimer cancelled callback" or "FAIL  StopTimer"
    log[#log + 1] = result.scene_indep_f > 0 and "PASS  scene-independent timer fired" or "FAIL  scene_indep"
    print("[FuncMergeTest] Part2 真实帧时序:\n" .. table.concat(log, "\n"))
  end)
end

run_logic_tests()
run_frame_tests()
