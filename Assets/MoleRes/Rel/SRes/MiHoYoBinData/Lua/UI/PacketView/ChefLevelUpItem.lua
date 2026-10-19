local M = G.Class("ChefLevelUpItem", G.UIPanel)
local base = G.UIPanel
local SLIDER_DURATION = 0.5

function M:init()
  base.init(self)
  self._change_info = nil
  self._dt_slider = nil
end

function M:on_create()
  base.on_create(self)
end

function M:on_disable()
  base.on_disable(self)
  self:_dt_slider_kill()
end

function M:on_destroy()
  self:_dt_slider_kill()
  base.on_destroy(self)
  self._change_info = nil
end

function M:refresh(change_info)
  self:_dt_slider_kill()
  self._change_info = change_info
  if change_info == nil then
    self:set_active(false)
    return
  end
  local cur_level = change_info.curLevel or 0
  local last_level = change_info.lastLevel or 0
  local cur_total_exp = change_info.curExp or 0
  local last_total_exp = change_info.lastExp or 0
  local is_level_up = change_info.IsLevelUp == true
  local cur_cfg = ExcelDataUtil.get_value(typeof(BChefLevelCfg), cur_level)
  local last_progress = cooking_module:get_chef_level_exp_progress(last_level, last_total_exp)
  local cur_progress = cooking_module:get_chef_level_exp_progress(cur_level, cur_total_exp)
  self:set_active(true)
  UIUtil.set_text(self._txt_lv, tostring(last_level))
  UIUtil.set_text(self._txt_name, not is_null(cur_cfg) and cur_cfg.cheftitle or "")
  self._slider.minValue = 0
  self._slider.maxValue = 1
  if not is_level_up and cur_total_exp <= last_total_exp and cur_level <= last_level then
    UIUtil.set_text(self._txt_add_exp, "")
    UIUtil.set_active(self._obj_lv_up, false)
    self._slider.value = cur_progress
    return
  end
  UIUtil.set_text(self._txt_add_exp, string.format("+%d", math.max(0, cur_total_exp - last_total_exp)))
  self._slider.value = last_progress
  UIUtil.set_active(self._obj_lv_up, is_level_up)
  if is_level_up then
    UIUtil.set_text(self._txt_last_lv, tostring(last_level))
    UIUtil.set_text(self._txt_cur_lv, tostring(cur_level))
  end
  if is_level_up then
    self:_do_slider(last_progress, 1, function()
      UIUtil.set_text(self._txt_lv, tostring(cur_level))
      self:_do_slider(0, cur_progress, function()
        self:_dt_slider_kill()
      end)
    end)
  else
    self:_do_slider(last_progress, cur_progress, function()
      self:_dt_slider_kill()
    end)
  end
end

function M:_do_slider(from, to, callback)
  self:_dt_slider_kill()
  self._slider.value = from
  self._dt_slider = self._slider:DOValue(to, SLIDER_DURATION):SetEase(Ease.Linear):OnComplete(function()
    if callback then
      callback()
    end
  end)
end

function M:_dt_slider_kill()
  if self._dt_slider then
    self._dt_slider:Kill()
    self._dt_slider:OnComplete(nil)
    self._dt_slider = nil
  end
end

return M
