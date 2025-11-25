local M = G.Class("StarPanelBase", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._panel_type = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_btn_listener()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_btn_listener()
end

function M:init_data(panel_type)
  self._panel_type = panel_type
end

function M:play_exit(callback)
  if callback then
    callback()
  end
end

function M:set_camera()
  if self._panel_type and companion_star_module.panel_camera[self._panel_type] then
    local camera_state = companion_star_module.panel_camera[self._panel_type]
    companion_star_module:change_camera_state(camera_state)
  end
end

function M:show()
  local star_data = self.holder.cur_star_data
  if star_data then
    local npc_id = star_data.npcid
    self.holder:refresh_npc_state_group_active(self._panel_type)
    self.holder:refresh_npc_state(npc_id)
  end
  self.holder:refresh_hide_btn_active(self._panel_type)
  self:refresh()
  self:set_camera()
  if self._panel_type then
    CsNPCSphereLandManagerUtil.PlayTabATL(self._panel_type, nil)
  end
  CsNPCSphereLandManagerUtil.ResetRotate()
end

function M:refresh()
end

return M
