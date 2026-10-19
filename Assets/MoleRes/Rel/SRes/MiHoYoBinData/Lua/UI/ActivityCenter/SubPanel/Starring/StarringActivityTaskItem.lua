local M = G.Class("StarringActivityTaskItem", G.UIPanel)
local base = G.UIPanel
local ITEM_STATE = {
  ongoing = 0,
  claimable = 1,
  claimed = 2
}

function M:on_create()
  base.on_create(self)
  if not is_null(self._obj_item) then
    self._reward_item = self:add_panel(item_module.item_v2_panel_cls_name, self._obj_item.transform)
  end
  self:bind_callback(self._btn_track, pack(self, M._on_btn_track_click))
  self:force_refresh()
end

function M:force_refresh()
  local d = self:get_extra_data()
  if d == nil then
    return
  end
  if not is_null(self._ui_state_group) then
    self._ui_state_group:SetState(self:_get_item_state(d))
  end
  UIUtil.set_text(self._txt_content, d.task_desc or "")
  if self._reward_item ~= nil then
    local item_id = d.reward_item_id or 0
    self._reward_item:set_item_data(item_id, d.reward_count)
    if 0 < item_id then
      self._reward_item:bind_item_info_btn(item_id)
    end
  end
end

function M:_on_btn_track_click()
  local d = self:get_extra_data()
  if d == nil then
    return
  end
  if d.is_finished then
    if d.is_claimed or not d.can_claim then
      return
    end
    if d.on_claim ~= nil then
      d.on_claim(d.task_id)
    else
      Logger.LogWarning("[StarringActivityTaskItem] missing claim callback on task " .. tostring(d.task_id))
    end
    return
  end
  local jump_id = d.jump_id or 0
  if jump_id == 0 then
    Logger.LogWarning("[StarringActivityTaskItem] no jumptolist on task " .. tostring(d.task_id))
    return
  end
  activity_center_module:request_jump(jump_id)
end

function M:get_task_id()
  local d = self:get_extra_data()
  return d and d.task_id or 0
end

function M:_get_item_state(d)
  if d.is_claimed then
    return ITEM_STATE.claimed
  end
  if d.is_finished then
    return ITEM_STATE.claimable
  end
  return ITEM_STATE.ongoing
end

return M
