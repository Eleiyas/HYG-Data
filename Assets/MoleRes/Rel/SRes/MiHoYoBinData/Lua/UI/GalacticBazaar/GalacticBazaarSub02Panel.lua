local M = G.Class("GalacticBazaarSub02Panel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/GalacticBazaar/GalacticBazaarSub02Panel"
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self._cfg = self:get_extra_data()
  self:_refresh_desc()
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_refresh_desc()
  if not self._cfg then
    return
  end
  UIUtil.set_text_by_id(self._txt_mainname, "Streetmarket_Billboard_Alai_Title")
  UIUtil.set_text_by_id(self._txt_mainnamedes, "Streetmarket_Billboard_Alai_Title2")
  UIUtil.set_text_by_id(self._txt_appraisal_title, "Bizarre_92upgrade_title_buying")
  UIUtil.set_text_by_id(self._txt_appraisal_desc, "Streetmarket_Billboard_Alai_Game1_Des")
  UIUtil.set_text_by_id(self._txt_dancing_title, "Bizarre_92upgrade_title_dancing")
  UIUtil.set_text_by_id(self._txt_dancing_desc, "Streetmarket_Billboard_Alai_Game2_Des")
  local appraisal_schedule_cfg = ExcelDataUtil.get_value(typeof(BShowScheduleCfg), 1)
  local appraisal_start_time_show = appraisal_schedule_cfg and (appraisal_schedule_cfg.starttimeshow or appraisal_schedule_cfg.starttime) or ""
  local appraisal_end_time_show = appraisal_schedule_cfg and (appraisal_schedule_cfg.endtimeshow or appraisal_schedule_cfg.endtime) or ""
  UIUtil.set_text_by_id(self._txt_appraisal_time, "Streetmarket_Billboard_Alai_Time", appraisal_start_time_show, appraisal_end_time_show)
  local dancing_schedule_cfg = ExcelDataUtil.get_value(typeof(BShowScheduleCfg), 2)
  local dancing_start_time_show = dancing_schedule_cfg and (dancing_schedule_cfg.starttimeshow or dancing_schedule_cfg.starttime) or ""
  local dancing_end_time_show = dancing_schedule_cfg and (dancing_schedule_cfg.endtimeshow or dancing_schedule_cfg.endtime) or ""
  UIUtil.set_text_by_id(self._txt_dancing_time, "Streetmarket_Billboard_Alai_Time", dancing_start_time_show, dancing_end_time_show)
end

return M
