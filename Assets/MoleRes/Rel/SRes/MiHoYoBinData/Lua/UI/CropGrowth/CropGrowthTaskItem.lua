local M = G.Class("CropGrowthTaskItem", G.UIBase)
local base = G.UIBase

function M:init()
  base.init(self)
  self._issue_id = 0
  self._issue_cfg = nil
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(issue_id, view_level)
  self._issue_id = issue_id or 0
  self._issue_cfg = crop_growth_module:get_issue_cfg(issue_id)
  if self._issue_cfg == nil then
    self:set_active(false)
    return
  end
  self:set_active(true)
  local progress = crop_growth_module:get_issue_progress(self._issue_cfg)
  local goal = self._issue_cfg.usetrackergoal == 1 and progress.goal or self._issue_cfg.issuegoal or 0
  local is_done = view_level < crop_growth_module:get_cur_level()
  is_done = is_done or 0 < goal and goal <= progress.trigger
  local trigger = is_done and goal or progress.trigger
  UIUtil.set_text_by_id(self._txt, self._issue_cfg.issuetext, self._issue_cfg.issuegoal, trigger, goal)
  self._state_group:SetState(is_done and 1 or 0)
end

function M:get_issue_cfg()
  return self._issue_cfg
end

return M
