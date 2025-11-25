local M = G.Class("InputAction")

function M:__ctor()
  self.type = nil
  self.event_type = nil
  self.id = 0
  self.handled = false
end

function M:init(action, event_type)
  self.type = action
  if event_type then
    self.event_type = event_type
  else
    self.event_type = ActionType.EType.ButtonPressed
  end
  self.id = self.type * 100 + self.event_type
end

function M:handle()
  self.handled = true
end

return M
