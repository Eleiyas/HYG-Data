local M = G.Class("NpcHangoutGameMainPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainPage/CaptureOrganismsMainPanel"
  self._score_delta_coroutine = nil
  self._score_delta_version = nil
  self._score_delta_final_title = ""
  self._last_countdown_second = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_abandon, function()
    npc_hangout_game_module:request_abandon()
  end)
end

function M:on_enable()
  base.on_enable(self)
  self._score_delta_version = nil
  self._last_countdown_second = nil
  self:refresh()
end

function M:on_disable()
  self:_stop_score_delta_coroutine()
  base.on_disable(self)
end

function M:on_destroy()
  self:_stop_score_delta_coroutine()
  base.on_destroy(self)
end

function M:update(delta_time)
  local data = npc_hangout_game_module:get_render_data()
  if data == nil then
    return
  end
  if data.content_mode == 1 and data.remain_seconds ~= self._last_countdown_second then
    self._last_countdown_second = data.remain_seconds
    UIUtil.set_text(self._txt_content, data.content or "")
  end
end

function M:refresh()
  local data = npc_hangout_game_module:get_render_data()
  if data == nil then
    return
  end
  UIUtil.set_image(self._img_feature, data.feature_icon, self:get_load_proxy())
  self:_refresh_title(data)
  UIUtil.set_text(self._txt_content, data.content or "")
  self._last_countdown_second = data.content_mode == 1 and data.remain_seconds or nil
  UIUtil.set_text(self._txt_button, data.button_text or "")
  UIUtil.set_active(self._btn_abandon, data.show_button == true)
end

function M:_refresh_title(data)
  local now = Time.realtimeSinceStartup
  local has_score_delta = data.score_delta_expire_time and now < data.score_delta_expire_time
  self._score_delta_final_title = data.final_title or data.title or ""
  UIUtil.set_text(self._txt_title, has_score_delta and data.title or self._score_delta_final_title)
  if not has_score_delta then
    self:_stop_score_delta_coroutine()
    self._score_delta_version = data.score_delta_version
    return
  end
  if self._score_delta_version == data.score_delta_version then
    return
  end
  self:_stop_score_delta_coroutine()
  self._score_delta_version = data.score_delta_version
  local version = data.score_delta_version
  self._score_delta_coroutine = CsCoroutineManagerUtil.InvokeRealtime(data.score_delta_expire_time - now, function()
    self._score_delta_coroutine = nil
    if self.guid and self._score_delta_version == version and not_null(self._txt_title) then
      UIUtil.set_text(self._txt_title, self._score_delta_final_title)
    end
  end)
end

function M:_stop_score_delta_coroutine()
  if self._score_delta_coroutine then
    CsCoroutineManagerUtil.StopCoroutine(self._score_delta_coroutine)
    self._score_delta_coroutine = nil
  end
end

return M
