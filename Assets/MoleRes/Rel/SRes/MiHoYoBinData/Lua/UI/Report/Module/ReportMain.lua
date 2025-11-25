report_module = report_module or {}

function report_module:add_event()
  report_module:remove_event()
  self._events = {}
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function report_module:init_data()
  self._cur_report_type = 0
  self._cur_report_reason = 0
  self._cur_report_text = ""
  self._cur_target_uid = 0
  self._cur_target_message = ""
end

function report_module:open_report_page(report_target, player_name, player_uid, target_message)
  self:init_data()
  if player_uid ~= nil then
    self._cur_target_uid = player_uid
  end
  if string.is_valid(target_message) then
    self._cur_target_message = target_message
  end
  UIManagerInstance:open("UI/Report/ReportPage", {
    target = report_target,
    player_name = player_name,
    player_uid = player_uid
  })
end

function report_module:show_report_chat_dialog(pos_x, pos_y, report_target, player_name, player_uid, target_message)
  UIManagerInstance:open("UI/Report/ReportChatDialog", {
    pos_x = pos_x,
    pos_y = pos_y,
    target = report_target,
    player_name = player_name,
    player_uid = player_uid,
    target_message = target_message
  })
end

function report_module:get_report_cfg()
  return self._report_cfg
end

function report_module:set_report_type(type)
  self._cur_report_type = type
end

function report_module:set_report_reason(reason)
  self._cur_report_reason = reason
end

function report_module:set_report_text(text)
  self._cur_report_text = text
end

function report_module:reset_report_text()
  self._cur_report_text = ""
end

function report_module:clear_report()
  self._cur_report_type = 0
  self._cur_report_reason = 0
  self._cur_target_uid = 0
  self._cur_target_message = ""
  self:reset_report_text()
end

function report_module:send_report_req()
  if self._cur_report_reason == 0 then
    return
  end
  CsSocialModuleUtil.SendReportReq(self._cur_report_type, self._cur_report_reason, self._cur_report_text, self._cur_target_uid, self._cur_target_message)
  UIUtil.show_tips_by_text_id("ReportPage_txt_tip_title_1")
end

function report_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

return report_module
