local base = require("UI/CommonUI/SearchFilter/CommonSearchFieldPanel")
local M = G.Class("StarbaySearchFieldPanel", base)

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CompanionStar/StarBay/StarbaySearchFieldDialog"
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._close_area, pack(self, M._on_click_close_area))
  self:_refresh_close_area_active()
end

function M:_on_click_close_area()
  self:request_blank_close("blank")
end

function M:sync_visibility(is_visible)
  base.sync_visibility(self, is_visible)
  self:_refresh_close_area_active()
end

function M:open()
  base.open(self)
  self:_refresh_close_area_active()
end

function M:sync_reset()
  base.sync_reset(self)
  self:_refresh_close_area_active()
end

function M:sync_applied_text(search_text)
  base.sync_applied_text(self, search_text)
  self:_refresh_close_area_active()
end

function M:request_submit(reason, search_text, should_store)
  base.request_submit(self, reason, search_text, should_store)
  self:_refresh_close_area_active()
end

function M:request_clear(reason, keep_editing)
  base.request_clear(self, reason, keep_editing)
  self:_refresh_close_area_active()
end

function M:request_blank_close(reason)
  if self._is_requesting_shell_close or self._is_panel_visible ~= true then
    return
  end
  self._is_requesting_shell_close = true
  local should_force_close = self._request_close_callback ~= nil
  local request_close_callback = self._request_close_callback
  if should_force_close then
    self._request_close_callback = nil
  end
  base.request_blank_close(self, reason)
  self._request_close_callback = request_close_callback
  if should_force_close then
    request_close_callback(reason)
  end
  self:_refresh_close_area_active()
  self._is_requesting_shell_close = false
end

function M:_process_input_deselect()
  base._process_input_deselect(self)
end

function M:_refresh_close_area_active()
  if is_null(self._close_area) then
    return
  end
  UIUtil.set_active(self._close_area, self._is_panel_visible == true and self:_is_editing_state())
end

return M
