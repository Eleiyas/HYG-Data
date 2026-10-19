local M = G.Class("CommonMissionJumpItem", G.UIBase)
local base = G.UIBase
local new_task_state_text_id = {
  [1] = "Lukashu_Task_Inprogress",
  [2] = "Lukashu_Task_Completed",
  [3] = "Lukashu_Task_Notaccepted",
  [4] = "Lukashu_Task_Notaccepted",
  [5] = "Lukashu_Task_Inprogress"
}
local new_task_state_text_id_fallback = "Lukashu_Task_Notaccepted"
local new_task_state_complete = 2

function M:init()
  base.init(self)
  self._task_id = 0
  self._txt_title = nil
  self._txt_info = nil
  self._btn_jump = nil
  self._img_icon = nil
  self._state_group = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_destroy()
  self._task_id = 0
  base.on_destroy(self)
end

function M:_add_ui_listener()
  if not_null(self._btn_jump) then
    self:bind_callback(self._btn_jump, pack(self, M._on_btn_jump_click))
  end
end

function M:set_data(task_id)
  self._task_id = task_id or 0
  if self._task_id == 0 then
    return
  end
  local step_cfg = task_module:get_task_cfg_data():GetTaskStepCfgById(self._task_id)
  if not_null(self._txt_title) then
    local title = ""
    if not_null(step_cfg) and not_null(step_cfg.name_l10n) then
      title = step_cfg.name_l10n:ToString() or ""
    end
    UIUtil.set_text(self._txt_title, title)
  end
  if not_null(self._txt_info) then
    local group_title = self:_resolve_group_title(step_cfg)
    local state_text = self:_resolve_state_text()
    UIUtil.set_text(self._txt_info, string.format("%s / %s", group_title, state_text))
  end
  self:_refresh_icon(step_cfg)
  self:_refresh_complete_state()
end

function M:_refresh_icon(step_cfg)
  if is_null(self._img_icon) then
    return
  end
  if is_null(step_cfg) or is_null(step_cfg.MemoGrouping) then
    UIUtil.set_active(self._img_icon, false)
    return
  end
  local grouping = step_cfg.MemoGrouping
  local icon = grouping.icon
  if string.is_valid(icon) then
    UIUtil.set_active(self._img_icon, true)
    UIUtil.set_image(self._img_icon, icon, self:get_load_proxy())
    return
  end
  local npc_id = grouping.npcId
  if npc_id ~= nil and 0 < npc_id then
    UIUtil.set_active(self._img_icon, true)
    npc_module:set_npc_icon_by_id(self._img_icon, npc_id, self:get_load_proxy())
    return
  end
  UIUtil.set_active(self._img_icon, false)
end

function M:_refresh_complete_state()
  if is_null(self._state_group) then
    return
  end
  local state = task_module:get_task_data():GetTaskState(self._task_id)
  self._state_group:SetState(state == new_task_state_complete and 1 or 0)
end

function M:_resolve_group_title(step_cfg)
  if is_null(step_cfg) or is_null(step_cfg.MemoGrouping) then
    return ""
  end
  local group_title = step_cfg.MemoGrouping.groupTitle
  if is_null(group_title) then
    return ""
  end
  return group_title:ToStringExplicit() or ""
end

function M:_resolve_state_text()
  local state = task_module:get_task_data():GetTaskState(self._task_id)
  local text_id = new_task_state_text_id[state] or new_task_state_text_id_fallback
  return UIUtil.get_text_by_id(text_id) or ""
end

function M:_on_btn_jump_click()
  if self._task_id == 0 then
    return
  end
  local state = task_module:get_task_data():GetTaskState(self._task_id)
  if state ~= 1 and state ~= 5 then
    UIUtil.show_tips_by_text_id("Lukashu_Task_Notacceptedprompt")
    return
  end
  local step_cfg = task_module:get_task_cfg_data():GetTaskStepCfgById(self._task_id)
  local grouping_type = memo_module.grouping_type.none
  if not_null(step_cfg) then
    grouping_type = step_cfg.GroupingType or memo_module.grouping_type.none
  end
  self.holder:close_self()
  memo_module:open_memo_page(false, memo_module.tab_type.task, grouping_type, self._task_id)
end

return M
