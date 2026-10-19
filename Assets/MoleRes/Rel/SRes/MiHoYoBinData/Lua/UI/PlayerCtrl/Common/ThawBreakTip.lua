local M = G.Class("ThawBreakTip", G.PlayerControlInputElementBase)
local base = G.PlayerControlInputElementBase

function M:bind_input_action()
  base.bind_input_action(self)
  if not is_null(self._btn_break) then
    self:bind_input_and_btn(ActionType.Act.PrimaryKey, self._btn_break)
  end
end

return M
