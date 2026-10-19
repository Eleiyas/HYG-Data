local M = G.Class("LeMiFootprintDailySlider", G.UIBase)
local base = G.UIBase
local FILL_MIN = 0.01
local FILL_MAX = 0.84
local FILL_RANGE = FILL_MAX - FILL_MIN
local FILL_MIN_THRESHOLD = 0.1
local FILL_MAX_THRESHOLD = 0.8

function M:on_create()
  base.on_create(self)
  self:set_progress(0)
end

function M:set_progress(progress)
  progress = math.max(0, math.min(progress or 0, 1))
  local fill = FILL_MIN + progress * FILL_RANGE
  if self._slider then
    self._slider.fillAmount = fill
  end
  self:_refresh_text(progress, fill)
end

function M:hide_all_text()
  UIUtil.set_active(self._text_num, false)
  UIUtil.set_active(self._text_num_start, false)
  UIUtil.set_active(self._text_num_end, false)
end

function M:_refresh_text(progress, fill)
  local percent = math.floor(progress * 100)
  if fill < FILL_MIN_THRESHOLD then
    UIUtil.set_active(self._text_num, false)
    UIUtil.set_active(self._text_num_start, true)
    UIUtil.set_active(self._text_num_end, false)
    UIUtil.set_text_by_id(self._text_num_start, "LeMiFootprintDaily_PercentNum", percent)
  elseif fill > FILL_MAX_THRESHOLD then
    UIUtil.set_active(self._text_num, false)
    UIUtil.set_active(self._text_num_start, false)
    UIUtil.set_active(self._text_num_end, true)
    UIUtil.set_text_by_id(self._text_num_end, "LeMiFootprintDaily_PercentNum", percent)
  else
    UIUtil.set_active(self._text_num, true)
    UIUtil.set_active(self._text_num_start, false)
    UIUtil.set_active(self._text_num_end, false)
    UIUtil.set_text_by_id(self._text_num, "LeMiFootprintDaily_PercentNum", percent)
  end
end

return M
