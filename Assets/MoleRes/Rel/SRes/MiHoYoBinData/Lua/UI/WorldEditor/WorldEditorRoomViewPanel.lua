local M = G.Class("WorldEditorRoomViewPanel", G.UIPanel)
local base = G.UIPanel

local function get_runtime_editor()
  local rt = RuntimeWorldEditor.Current
  if is_null(rt) then
    return nil
  end
  return rt
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/WorldEditor/WorldEditorRoomViewPanel"
  self._last_in_overview = nil
end

function M:on_create()
  base.on_create(self)
  self._normal_view_panel = self:add_panel("UI/WorldEditor/WorldEditorRoomNormalViewPanel", self._trans_normal_view)
  self._overview_panel = self:add_panel("UI/WorldEditor/WorldEditorRoomOverviewPanel", self._trans_overview)
end

function M:on_enable()
  base.on_enable(self)
  self._last_in_overview = nil
  self:_refresh_view_mode()
end

function M:update(_delta_time)
  if not self.is_active then
    return
  end
  base.update(self, _delta_time)
  self:_refresh_view_mode()
end

function M:_refresh_view_mode()
  local rt = get_runtime_editor()
  local in_overview = rt ~= nil and rt.IsInOverview or false
  if in_overview ~= self._last_in_overview then
    local was_overview = self._last_in_overview
    self._last_in_overview = in_overview
    if not is_null(self._overview_panel) then
      self._overview_panel:set_active(in_overview)
    end
    if not is_null(self._normal_view_panel) then
      self._normal_view_panel:set_active(not in_overview)
    end
    self:_refresh_holder_edit_ui(was_overview, in_overview)
    if was_overview and not in_overview and not is_null(self.holder) and self.holder.reapply_indoor_edit_mode then
      self.holder:reapply_indoor_edit_mode()
    end
  end
end

function M:_refresh_holder_edit_ui(was_overview, in_overview)
  if is_null(self.holder) or not self.holder._on_toggle_hide then
    return
  end
  if in_overview then
    self.holder:_on_toggle_hide(false)
    return
  end
  if not was_overview then
    return
  end
  if self.holder.is_other_edit_ui_force_hidden and self.holder:is_other_edit_ui_force_hidden() then
    return
  end
  self.holder:_on_toggle_hide(true)
end

return M
