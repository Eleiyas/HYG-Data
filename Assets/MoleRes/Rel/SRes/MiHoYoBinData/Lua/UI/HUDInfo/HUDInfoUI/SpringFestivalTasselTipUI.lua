local M = G.Class("SpringFestivalTasselTipUI", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local GROUP_ID_TO_STATE = {
  [2] = 0,
  [3] = 1
}
local DEFAULT_DURATION = 2

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_TasselTip"
end

function M:on_enable()
  base.on_enable(self)
  if not self._extra_data then
    Logger.LogError("[SpringFestivalTasselTipUI] on_enable extra_data is nil")
    self:close_self()
    return
  end
  self.is_unlock = false
  self:_show_tip(self._extra_data)
end

function M:_show_tip(group_id)
  local state = GROUP_ID_TO_STATE[group_id]
  if state == nil then
    Logger.LogWarning("[SpringFestivalTasselTipUI] unknown group_id:", group_id)
    self:close_self()
    return
  end
  if not is_null(self._state_tasselnum) then
    self._state_tasselnum:SetState(state)
  end
  self.is_unlock = true
  self:start_close_timer(DEFAULT_DURATION, function(ui)
    ui:close_self()
  end)
end

return M
