local M = G.Class("ActivityBasePanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.config.type = EUIType.Panel
  self._activity_id = 0
  self._shared_widgets = nil
  self._applied_bg_path = nil
end

function M:on_create()
  base.on_create(self)
end

function M:on_open()
  base.on_open(self)
  if self._activity_id ~= 0 then
    self:refresh()
  end
end

function M:on_enable()
  base.on_enable(self)
  activity_center_module:reset_activity_end_dialog_flag(self:_get_activity_end_gate_key())
end

function M:update(deltaTime)
  base.update(self, deltaTime)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  activity_center_module:release_activity_end_refresh_gate(self:_get_activity_end_gate_key())
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnActivityDataChanged, function(activity_id)
    self:_on_activity_data_changed(activity_id)
  end)
  self:add_evt_listener(EventID.OnActivityRemoved, function(activity_id)
    self:_on_activity_removed(activity_id)
  end)
end

function M:set_extra_data(data)
  base.set_extra_data(self, data)
  self.config.prefab_path = data.prefab_path
  self._activity_id = data.activity_id
end

function M:set_shared_widgets(widgets)
  self._shared_widgets = widgets
  self._applied_bg_path = nil
end

function M:get_activity_id()
  return self._activity_id
end

function M:get_activity_data()
  if self._activity_id == 0 then
    return nil
  end
  return activity_center_module:get_activity_by_id(self._activity_id)
end

function M:update_time_remain()
  if self._shared_widgets == nil or self._activity_id == 0 or not self:is_in_show_state() then
    return
  end
  self:_refresh_time_remain()
end

function M:_refresh_shared()
  if self._shared_widgets == nil then
    return
  end
  local ui_cfg = activity_center_module:get_ui_cfg(self._activity_id)
  if ui_cfg == nil then
    return
  end
  if self._shared_widgets.text_main_title then
    UIUtil.set_text(self._shared_widgets.text_main_title, ui_cfg.activityname or "")
  end
  if self._shared_widgets.text_desc then
    UIUtil.set_text(self._shared_widgets.text_desc, ui_cfg.activitydesc or "")
  end
  self:_refresh_time_remain()
end

function M:_refresh_dynamic_bg(img)
  local ui_cfg = activity_center_module:get_ui_cfg(self._activity_id)
  if is_null(img) or is_null(ui_cfg) then
    return false
  end
  local path = ui_cfg.activitybg
  if not string.is_valid(path) then
    UIUtil.set_active(img, false)
    self._applied_bg_path = nil
    return false
  end
  UIUtil.set_active(img, true)
  self._applied_bg_path = path
  UIUtil.set_image(img, path, self:get_load_proxy())
  return true
end

function M:_refresh_time_remain()
  local trans = self._shared_widgets.trans_time_remain
  local text_remain = self._shared_widgets.text_time_remain
  if is_null(trans) or is_null(text_remain) then
    return
  end
  UIUtil.set_active(trans, true)
  local data = self:get_activity_data()
  if data == nil then
    UIUtil.set_active(trans, false)
    return
  end
  if data.EndTimeUtcSec == 0 then
    UIUtil.set_text_by_id(text_remain, "Activity_LeftTime_Permant")
    return
  end
  local remain = data.EndTimeUtcSec - TimeUtil.ServerUtcTimeSeconds
  if remain <= 0 then
    UIUtil.set_active(trans, false)
    return
  end
  UIUtil.set_text_by_id(text_remain, "Activity_LeftTime", UIUtil.format_left_time(remain))
end

function M:refresh()
  self:_refresh_shared()
end

function M:_on_activity_data_changed(activity_id)
  if activity_id == self._activity_id then
    self:refresh()
  end
end

function M:_on_activity_removed(activity_id)
  if activity_id ~= self._activity_id then
    return
  end
  if not self:is_in_show_state() then
    return
  end
  self:_show_activity_end_dialog()
end

function M:_show_activity_end_dialog()
  activity_center_module:show_activity_end_dialog(pack(self, M._on_activity_end_confirmed), {
    key = self:_get_activity_end_gate_key(),
    text_id = self:get_activity_end_dialog_text_id()
  })
end

function M:_on_activity_end_confirmed()
  self:_close_dialogs_above_self()
  activity_center_module:request_refresh_list()
end

function M:_close_dialogs_above_self()
  local host = self.holder
  while host ~= nil do
    if host.config ~= nil and host.config.type == EUIType.Page then
      UIManagerInstance:close_dialogs_above_page(host)
      return
    end
    host = host.holder
  end
  Logger.LogWarning("[ActivityCenter] " .. tostring(self.__cname) .. " 沿 holder 链找不到承载它的 Page，压在它上面的弹窗不会被关闭。")
end

function M:_get_activity_end_gate_key()
  return activity_center_module:make_activity_end_gate_key(self._activity_id)
end

function M:get_activity_end_dialog_text_id()
  return nil
end

function M:_request_jump(jump_id)
  activity_center_module:request_jump(jump_id)
end

return M
