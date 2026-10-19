local M = G.Class("PerfTagBtnPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "Launch/UI/GM/PerfTagBtnPage"
  self.config.type = EUIType.Top
  self.config.input_penetrate = false
  self._tag_index = 1
  self._active_name = nil
  self._reset_version = PerfMarkerRuntime.GetResetVersion()
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_begin, pack(self, M._on_begin_click))
  self:bind_callback(self._btn_end, pack(self, M._on_end_click))
  self:bind_callback(self._btn_cancel, pack(self, M._on_cancel_click))
  self:_refresh_ui()
end

function M:on_open()
  base.on_open(self)
  self:_refresh_ui()
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_ui()
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self:_sync_reset_version() then
    self:_refresh_ui()
  end
end

function M:on_destroy()
  if self._active_name then
    self:_execute_marker("Cancel", self._active_name)
    self._active_name = nil
  end
  base.on_destroy(self)
end

function M:_current_name()
  return "tag" .. tostring(self._tag_index)
end

function M:_sync_reset_version()
  local reset_version = PerfMarkerRuntime.GetResetVersion()
  if self._reset_version ~= reset_version then
    self._reset_version = reset_version
    self._tag_index = 1
    self._active_name = nil
    return true
  end
  return false
end

function M:_execute_marker(action, name)
  local result = PerfMarkerRuntime.Execute(action .. " " .. name)
  if result and string.sub(tostring(result), 1, 2) == "OK" then
    return true
  end
  Logger.LogError("PerfTagBtnPage " .. action .. " failed: " .. tostring(result))
  return false
end

function M:_refresh_ui()
  self:_sync_reset_version()
  local active = self._active_name ~= nil
  local name = self._active_name or self:_current_name()
  UIUtil.set_active(self._root_begin, not active)
  UIUtil.set_active(self._root_active, active)
  UIUtil.set_text(self._txt_begin, "开始" .. name)
  UIUtil.set_text(self._txt_end, "结束" .. name)
  UIUtil.set_text(self._txt_cancel, "取消" .. name)
end

function M:_on_begin_click()
  if self:_sync_reset_version() then
    self:_refresh_ui()
  end
  if self._active_name then
    return
  end
  local name = self:_current_name()
  if self:_execute_marker("Begin", name) then
    self._active_name = name
    self:_refresh_ui()
  end
end

function M:_on_end_click()
  if self:_sync_reset_version() then
    self:_refresh_ui()
  end
  if not self._active_name then
    return
  end
  local name = self._active_name
  if self:_execute_marker("End", name) then
    self._active_name = nil
    self._tag_index = self._tag_index + 1
    self:_refresh_ui()
  end
end

function M:_on_cancel_click()
  if self:_sync_reset_version() then
    self:_refresh_ui()
  end
  if not self._active_name then
    return
  end
  local name = self._active_name
  if self:_execute_marker("Cancel", name) then
    self._active_name = nil
    self:_refresh_ui()
  end
end

return M
