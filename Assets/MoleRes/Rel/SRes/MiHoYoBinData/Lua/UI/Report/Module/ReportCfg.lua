report_module = report_module or {}

function report_module:get_all_report_structure_cfgs()
  local cfgs = LocalDataUtil.get_table(typeof(CS.BReportStructureCfg))
  return cfgs
end

function report_module:get_all_report_cfgs()
  local cfgs = LocalDataUtil.get_table(typeof(CS.BReportPlayerCfg))
  return cfgs
end

function report_module:get_report_group_cfg(group_id)
  local cfg = LocalDataUtil.get_value(typeof(CS.BReportStructureCfg), group_id)
  return cfg
end

function report_module:get_report_cfg(group_id)
  local cfgs = LocalDataUtil.get_value(typeof(CS.BReportPlayerCfg), group_id)
  return dic_to_table(cfgs)
end

function report_module:get_report_press_duration()
  if self._report_press_duration == nil then
    local cfg = LocalDataUtil.get_value(typeof(CS.BPlayerCfg), 123)
    self._report_press_duration = tonumber(cfg.paramstr)
  end
  return self._report_press_duration
end

return report_module
