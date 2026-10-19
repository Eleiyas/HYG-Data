local M = G.Class("ActivityTaskListMissionItem", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  if not is_null(self._obj_item) and item_module ~= nil and item_module.item_v2_panel_cls_name ~= nil then
    self._reward_item_panel = self:add_panel(item_module.item_v2_panel_cls_name, self._obj_item.gameObject)
  end
  if not is_null(self._toggle) then
    self:bind_callback(self._toggle, function(is_on)
      local d = self:get_extra_data()
      if is_on and d and d.on_click then
        d.on_click(d.task_id)
      end
    end)
  end
  self:force_refresh()
end

function M:force_refresh()
  local d = self:get_extra_data()
  if d == nil then
    return
  end
  local task_state = activity_center_module.activity_task_state
  local desc = d.task_desc or ""
  if d.state == task_state.Locked and string.is_valid(d.unlock_desc) then
    desc = d.unlock_desc
  end
  UIUtil.set_text(self._text_desc, desc)
  if self._reward_item_panel ~= nil and self._reward_item_panel.refresh then
    self._reward_item_panel:refresh(d.reward_item_id, d.reward_count)
  end
  if not is_null(self._img_state) then
    UIUtil.set_active(self._img_state, d.state ~= task_state.Ongoing)
  end
  if not is_null(self._red_point) and self._red_point.SetActive then
    self._red_point:SetActive(d.can_claim == true)
  end
end

function M:get_task_id()
  local d = self:get_extra_data()
  return d and d.task_id or 0
end

return M
