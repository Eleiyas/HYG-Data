local PROGRESS_ANIM_DURATION = 0.5
local M = G.Class("HabitatTrackingItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._habitat_id = 0
  self._cur_progress = 0
  self._progress_tweener = nil
  self._is_progress_animating = false
  self._open_info_page_call_back = nil
end

function M:set_open_info_page_call_back(callback)
  self._open_info_page_call_back = callback
end

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_reset_progress_anim_state()
end

function M:on_disable()
  self:_reset_progress_anim_state()
  base.on_disable(self)
end

function M:on_close()
  self:_kill_progress_tweener()
  base.on_close(self)
end

function M:on_destroy()
  self:_kill_progress_tweener()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaTrackingChange, function(info)
    self:refresh()
  end)
  self:add_evt_listener(EventID.OnSceneHabitatDataUpdated, function(habitat_id)
    if habitat_id == self._habitat_id then
      self:_refresh_progress(true)
    end
  end)
end

function M:refresh()
  if not blueprint_habitat_module:should_show_tracking_item() then
    self:set_active(false)
    return
  end
  self._habitat_id = blueprint_habitat_module:get_tracking_habitat_id()
  if self._habitat_id == 0 then
    self:set_active(false)
    return
  end
  self:set_active(true)
  self._tog_show.isOnValue = CsHabitatModuleUtil.GetPreviewGhostVisible()
  self:_refresh_info()
  self:_refresh_progress(false)
end

function M:_refresh_info()
  if self._habitat_id == 0 then
    return
  end
  local cfg = blueprint_habitat_module:get_habitat_ui_cfg(self._habitat_id)
  if cfg == nil then
    return
  end
  if string.is_valid(cfg.name) and self._txt_title ~= nil then
    UIUtil.set_text(self._txt_title, cfg.name)
  end
  if string.is_valid(cfg.tooltableicon) and self._icon ~= nil then
    UIUtil.set_image(self._icon, cfg.tooltableicon, self:get_load_proxy())
  end
end

function M:_refresh_progress(animate)
  if self._habitat_id == 0 then
    return
  end
  local progress_float = CsHabitatModuleUtil.GetHabitatTotalProgress(self._habitat_id)
  local to_percent = math.floor(progress_float * 100 + 0.5)
  to_percent = math.max(0, math.min(to_percent, 100))
  if not animate then
    if self._is_progress_animating then
      return
    end
    self._cur_progress = to_percent
    UIUtil.set_text_by_id(self._txt_progress, "Habitat_ProgressRate", to_percent)
    return
  end
  if self._cur_progress == to_percent then
    return
  end
  self:_kill_progress_tweener()
  local from_percent = self._cur_progress
  self._is_progress_animating = true
  self._progress_tweener = DOTween.To(function(value)
    if is_null(self._txt_progress) then
      return
    end
    UIUtil.set_text_by_id(self._txt_progress, "Habitat_ProgressRate", math.ceil(value))
  end, from_percent, to_percent, PROGRESS_ANIM_DURATION):OnComplete(function()
    self._cur_progress = to_percent
    self._progress_tweener = nil
    self._is_progress_animating = false
  end)
  self._cur_progress = to_percent
end

function M:_kill_progress_tweener()
  if self._progress_tweener ~= nil then
    self._progress_tweener:Kill(false)
    self._progress_tweener = nil
  end
  self._is_progress_animating = false
end

function M:_reset_progress_anim_state()
  self:_kill_progress_tweener()
end

function M:bind_callbacks()
  self:bind_callback(self._btn_detail, pack(self, M._on_btn_detail_click))
  self:bind_callback(self._tog_show, pack(self, M._on_tog_show_click))
end

function M:_on_btn_detail_click()
  local habitat_id = self._habitat_id
  if self._open_info_page_call_back ~= nil then
    local can_open_info_page = self._open_info_page_call_back()
    if can_open_info_page ~= nil and can_open_info_page == false then
      return
    end
  end
  blueprint_habitat_module:open_habitat_info_page(habitat_id, false)
end

function M:_on_tog_show_click(is_on)
  if self._habitat_id == 0 then
    return
  end
  CsHabitatModuleUtil.SetPreviewGhostVisible(self._habitat_id, is_on)
end

return M
