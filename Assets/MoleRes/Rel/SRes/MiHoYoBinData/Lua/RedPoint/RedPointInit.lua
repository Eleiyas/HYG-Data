red_point_module = red_point_module or {}
red_point_module._cname = "red_point_module"
lua_module_mgr:require("RedPoint/RedPointCommon")

function red_point_module:init()
end

function red_point_module:close()
end

function red_point_module:is_recorded(red_point_start_enum)
  if not self:_check_enum(red_point_start_enum) then
    return false
  end
  return CsRedPointModuleUtil.IsRecorded(red_point_start_enum)
end

function red_point_module:is_recorded_with_id(red_point_start_enum, id)
  if not self:_check_enum(red_point_start_enum) then
    return false
  end
  return CsRedPointModuleUtil.IsRecorded(red_point_start_enum, id)
end

function red_point_module:record(red_point_start_enum)
  if not self:_check_enum(red_point_start_enum) then
    return
  end
  CsRedPointModuleUtil.Record(red_point_start_enum)
end

function red_point_module:record_with_id(red_point_start_enum, id)
  if not self:_check_enum(red_point_start_enum) then
    return
  end
  CsRedPointModuleUtil.Record(red_point_start_enum, id)
end

function red_point_module:delete_record(red_point_start_enum)
  if not self:_check_enum(red_point_start_enum) then
    return
  end
  CsRedPointModuleUtil.DeleteRecord(red_point_start_enum)
end

function red_point_module:delete_record_with_id(red_point_start_enum, id)
  if not self:_check_enum(red_point_start_enum) then
    return
  end
  CsRedPointModuleUtil.DeleteRecord(red_point_start_enum, id)
end

function red_point_module:_check_enum(red_point_start_enum)
  for _, value in pairs(red_point_module.red_point_type) do
    if tonumber(value) == tonumber(red_point_start_enum) then
      return true
    end
  end
  Logger.LogError("[红点系统] 错误的枚举, 先在RedPointCommon.lua定义吧！")
  return false
end

return red_point_module
