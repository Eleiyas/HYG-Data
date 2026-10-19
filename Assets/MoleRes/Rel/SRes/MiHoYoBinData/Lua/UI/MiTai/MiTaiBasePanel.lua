local M = G.Class("MiTaiBasePanel", G.UIPanel)
local base = G.UIPanel

function M:set_on_enter_anim_done(callback)
  self._on_enter_anim_done = callback
end

function M:set_on_exit_anim_done(callback)
  self._on_exit_anim_done = callback
end

function M:enter_anim_call_back()
  base.enter_anim_call_back(self)
  local cb = self._on_enter_anim_done
  if cb then
    self._on_enter_anim_done = nil
    cb()
  end
end

function M:exit_anim_call_back()
  base.exit_anim_call_back(self)
  local cb = self._on_exit_anim_done
  if cb then
    self._on_exit_anim_done = nil
    cb()
  end
end

return M
