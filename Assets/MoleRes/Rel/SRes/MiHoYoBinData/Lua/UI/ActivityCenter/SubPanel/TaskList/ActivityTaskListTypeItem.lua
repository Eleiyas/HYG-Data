local M = G.Class("ActivityTaskListTypeItem", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  if not is_null(self._toggle) then
    self:bind_callback(self._toggle, function(is_on)
      if is_on and self.extra_data and self.extra_data.on_click then
        self.extra_data.on_click(self.extra_data.task_type)
      end
    end)
  end
  self:force_refresh()
end

function M:force_refresh()
  if self.extra_data == nil then
    return
  end
  UIUtil.set_text(self._text_tab, self.extra_data.tab_name or "")
  if not is_null(self._red_point) and self._red_point.SetActive then
    self._red_point:SetActive(self.extra_data.has_red_dot == true)
  end
end

function M:set_selected(is_on)
  if not is_null(self._toggle) then
    self._toggle.isOn = is_on
  end
  if not is_null(self._state_group_style) and self._state_group_style.SetState then
    self._state_group_style:SetState(is_on and "Selected" or "Normal")
  end
end

function M:get_task_type()
  return self.extra_data and self.extra_data.task_type or 0
end

return M
