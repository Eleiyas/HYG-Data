local M = G.Class("ThemeSeasonHUDInfo", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local SHOW_DURATION = 3
local ANIM_START_IN = "anim_hudbattlepass_seasontip_start_in"
local ANIM_START_OUT = "anim_hudbattlepass_seasontip_start_out"
local ANIM_FINISH_IN = "anim_hudbattlepass_seasontip_finish_in"
local ANIM_FINISH_OUT = "anim_hudbattlepass_seasontip_finish_out"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainPage/HUDInfo/HUDBattlePassSeasonTip"
  self._show_timer = 0
  self._exit_anim_name = nil
  self._is_exiting = false
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh()
end

function M:on_disable()
  base.on_disable(self)
  self._show_timer = 0
  self._exit_anim_name = nil
  self._is_exiting = false
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self._show_timer > 0 then
    self._show_timer = self._show_timer - deltaTime
    if self._show_timer <= 0 then
      self._show_timer = 0
      self:_play_exit()
    end
  end
end

function M:_refresh()
  local data = self:get_extra_data()
  if is_null(data) then
    self:close_self()
    return
  end
  local is_start = data.is_start
  local task_id = data.task_id or 0
  UIUtil.set_active(self._trans_bp_start, is_start)
  UIUtil.set_active(self._trans_bp_finish, not is_start)
  local step_cfg = task_module:get_task_step_cfg_by_id(task_id)
  local chapter_name = ""
  if not is_null(step_cfg) and not is_null(step_cfg.MemoGrouping) and not is_null(step_cfg.MemoGrouping.groupTitle) then
    chapter_name = step_cfg.MemoGrouping.groupTitle:ToStringExplicit()
  end
  if is_start then
    UIUtil.set_text(self._txt_tips, chapter_name)
  end
  self._is_exiting = false
  self._exit_anim_name = is_start and ANIM_START_OUT or ANIM_FINISH_OUT
  self.binder:PlayAnimation(is_start and ANIM_START_IN or ANIM_FINISH_IN)
  self._show_timer = SHOW_DURATION
end

function M:_play_exit()
  if self._is_exiting then
    return
  end
  self._is_exiting = true
  local anim_name = self._exit_anim_name
  if anim_name == nil then
    self:close_self()
    return
  end
  self.binder:PlayAnimation(anim_name, function()
    self:close_self()
  end)
end

return M
