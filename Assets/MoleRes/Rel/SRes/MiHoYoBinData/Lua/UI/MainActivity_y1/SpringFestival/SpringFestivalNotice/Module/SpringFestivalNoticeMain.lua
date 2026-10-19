spring_festival_notice_module = spring_festival_notice_module or {}

function spring_festival_notice_module:query_notice(trigger_type, scene_type)
  if not self:should_show_notice(trigger_type, scene_type) then
    return false, nil
  end
  local data = self:get_notice_data(scene_type, trigger_type)
  return data ~= nil, data
end

return spring_festival_notice_module
