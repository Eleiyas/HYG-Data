local M = G.Class("NpcHangoutGameTips", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local show_duration = 3.0

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Npc/NpcChanceEncounterTips"
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data() or {}
  UIUtil.set_text(self._txt_des, data.title or "")
  UIUtil.set_text(self._txt_details, data.detail or "")
  UIUtil.set_image(self._img_taskicon, data.icon, self:get_load_proxy())
  self._ui_change_group:SetState(data.state or 0)
  self:start_close_timer(show_duration)
end

return M
