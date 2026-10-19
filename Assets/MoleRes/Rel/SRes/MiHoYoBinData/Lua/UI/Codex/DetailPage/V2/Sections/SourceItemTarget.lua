local M = G.Class("SourceItemTarget", G.UIPanel)
local base = G.UIPanel

function M:on_create()
  base.on_create(self)
  self._source_cfg = nil
  self._item_id = 0
  self._is_refreshing_target = false
  self:bind_callback(self._tog_target, pack(self, M._on_toggle))
end

function M:refresh(source_cfg, item_id)
  self._source_cfg = source_cfg
  self._item_id = item_id or 0
  UIUtil.set_text(self._txt, source_cfg.sourcedescription)
  self:_refresh_target_state()
end

function M:_on_toggle(is_on)
  if self._is_refreshing_target then
    return
  end
  local is_tracking = not is_on
  local track_type = tracking_module.track_type.feature
  local source_type = tracking_module.data_source_type.codex
  local tracking_id = self._item_id
  tracking_module:set_tracking_by_track_type(track_type, source_type, tracking_id, is_tracking, true)
  self:_refresh_target_state()
  if is_tracking then
    UIUtil.show_tips_by_text_id("Codex_TrackingItem")
    lua_event_module:send_event(lua_event_module.event_type.system_jump_by_source_item_click)
  else
    UIUtil.show_tips_by_text_id("Codex_CancelTrackingItem")
  end
end

function M:_refresh_target_state()
  local track_type = tracking_module.track_type.feature
  local source_type = tracking_module.data_source_type.codex
  local tracking_id = self._item_id
  local is_tracking = tracking_module:is_tracking_by_track_type(track_type, source_type, tracking_id)
  self._is_refreshing_target = true
  self._tog_target.isOn = not is_tracking
  self._is_refreshing_target = false
end

return M
