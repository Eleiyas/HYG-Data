local M = G.Class("CodexListRendererBase")

function M:__ctor(panel)
  self._panel = panel
end

function M:render(init_position)
end

function M:deactivate()
end

function M:stop_movement()
end

function M:record_position()
  return nil
end

function M:scroll_to(position)
end

function M:close()
end

return M
