local M = G.Class("CodexScoreProgressRoundItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
end

function M:refresh(data)
  data = data or {}
  self:_set_round_progress(self._round_progress_main, data.prev_norm or 0)
  self:_set_round_progress(self._round_progress_add, data.current_norm or 0)
  self:_set_round_point(self._round_progress_point, data.current_norm or 0)
  if not_null(self._txt_add_num) then
    UIUtil.set_text(self._txt_add_num, "+" .. tostring(data.add_score or 0))
  end
  if not_null(self._txt_title) then
    UIUtil.set_text_by_id(self._txt_title, data.title)
  end
  if not_null(self._img_icon_dynamic) and data.icon then
    UIUtil.set_image(self._img_icon_dynamic, data.icon, self:get_load_proxy())
  end
end

function M:_set_round_progress(progress, value)
  if is_null(progress) then
    return
  end
  if progress.SetProgress then
    progress:SetProgress(value)
  else
    progress.progress = value
  end
end

function M:_set_round_point(point, value)
  if is_null(point) then
    return
  end
  local img = point
  if not_null(img) then
    img.fillAmount = value
  end
end

return M
