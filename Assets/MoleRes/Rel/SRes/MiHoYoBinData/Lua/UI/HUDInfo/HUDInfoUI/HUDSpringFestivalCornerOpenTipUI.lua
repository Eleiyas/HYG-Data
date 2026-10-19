local M = G.Class("HUDSpringFestivalCornerOpenTipUI", "UI/HUDInfo/HUDInfoUI/HUDInfoBaseUI")
local base = G.HUDInfoBaseUI
local DEFAULT_DURATION = 2
local DEFAULT_TIP_STATE = 0

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_ActivityTip"
end

function M:on_enable()
  base.on_enable(self)
  self.is_unlock = false
  self:_show_tip()
end

function M:_show_tip()
  if not is_null(self._state_tasselnum) then
    local tip_state = tonumber(self._extra_data) or DEFAULT_TIP_STATE
    self._state_tasselnum:SetState(tip_state)
  end
  self.is_unlock = true
  self:start_close_timer(DEFAULT_DURATION, function(ui)
    ui:close_self()
  end)
end

return M
