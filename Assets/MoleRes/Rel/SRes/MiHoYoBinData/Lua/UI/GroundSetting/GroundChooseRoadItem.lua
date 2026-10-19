local M = G.Class("GroundChooseRoadItem", G.UIPanel)
local base = G.UIPanel
local SELECT_STATE_NORMAL = 0
local SELECT_STATE_SELECTED = 1
local LONG_PRESS_THRESHOLD = 0.5

function M:init()
  base.init(self)
  self._cfg_id = -1
  self._cfg = nil
  self._is_pressing = false
  self._press_time = 0
  self._is_drag_ready = false
  self._has_begun_drag = false
  self._is_scrolling = false
  self._end_drag_fired = false
  self._last_evt_position = nil
end

function M:on_create()
  base.on_create(self)
  self:_bind_drag_events()
end

function M:update(deltaTime)
  if not self._is_pressing or self._is_drag_ready or self._is_scrolling then
    return
  end
  if not self.holder or not self.holder._drag_enabled then
    return
  end
  if Time.time - self._press_time >= LONG_PRESS_THRESHOLD then
    self._is_drag_ready = true
    self:_trigger_drag_begin()
  end
end

function M:_trigger_drag_begin()
  self._is_scrolling = false
  self._has_begun_drag = true
  local icon = self._cfg and self._cfg.icon or nil
  if self.holder and self.holder.on_item_drag_begin then
    self.holder:on_item_drag_begin(self._cfg_id, icon, self._last_evt_position)
  end
end

function M:_on_click()
  if self._has_begun_drag or self.holder and self.holder._is_item_dragging then
    return
  end
  if self._cfg_id < 0 then
    return
  end
  if self.holder and self.holder.toggle_multi_select then
    self.holder:toggle_multi_select(self._cfg_id)
  end
end

function M:_bind_drag_events()
  local trans = self._btn_click and self._btn_click.transform or self.trans
  self.binder:BindViewCallback(trans, EventTriggerType.PointerDown, pack(self, M._on_pointer_down))
  self.binder:BindViewCallback(trans, EventTriggerType.PointerUp, pack(self, M._on_pointer_up))
  self.binder:BindViewCallback(trans, EventTriggerType.BeginDrag, pack(self, M._on_begin_drag))
  self.binder:BindViewCallback(trans, EventTriggerType.Drag, pack(self, M._on_pointer_drag))
  self.binder:BindViewCallback(trans, EventTriggerType.EndDrag, pack(self, M._on_end_drag))
end

function M:_on_pointer_down(evt)
  self._end_drag_fired = false
  if self._cfg_id <= 0 then
    return
  end
  if not self.holder or not self.holder._drag_enabled then
    return
  end
  if self.holder._is_item_dragging then
    return
  end
  self._is_pressing = true
  self._press_time = Time.time
  self._is_drag_ready = false
  self._has_begun_drag = false
  self._is_scrolling = false
  self._last_evt_position = evt.position
end

function M:_on_pointer_up(evt)
  self._is_pressing = false
  if self._has_begun_drag then
    if self.holder and self.holder.on_item_drag_end then
      self.holder:on_item_drag_end(evt.position)
    end
  elseif not self._end_drag_fired then
    self:_on_click()
  end
  self._end_drag_fired = false
  self:_reset_drag_state()
end

function M:_on_begin_drag(evt)
  if self._is_drag_ready then
    return
  end
  self._is_scrolling = true
  local scroll_rect = self:_get_scroll_rect()
  if not is_null(scroll_rect) then
    scroll_rect:OnBeginDrag(evt)
  end
end

function M:_on_pointer_drag(evt)
  self._last_evt_position = evt.position
  if self._is_drag_ready then
    if self._is_scrolling then
      self._is_scrolling = false
      local scroll_rect = self:_get_scroll_rect()
      if not is_null(scroll_rect) then
        scroll_rect:OnEndDrag(evt)
      end
    end
    if not self._has_begun_drag then
      self._has_begun_drag = true
      local icon = self._cfg and self._cfg.icon or nil
      if self.holder and self.holder.on_item_drag_begin then
        self.holder:on_item_drag_begin(self._cfg_id, icon, evt)
      end
    elseif self.holder and self.holder.on_item_drag then
      self.holder:on_item_drag(evt.position)
    end
  elseif self._is_scrolling then
    local scroll_rect = self:_get_scroll_rect()
    if not is_null(scroll_rect) then
      scroll_rect:OnDrag(evt)
    end
  end
end

function M:_on_end_drag(evt)
  self._end_drag_fired = true
  if self._is_scrolling then
    self._is_scrolling = false
    local scroll_rect = self:_get_scroll_rect()
    if not is_null(scroll_rect) then
      scroll_rect:OnEndDrag(evt)
    end
  end
  if self._has_begun_drag and self.holder and self.holder.on_item_drag_end then
    self.holder:on_item_drag_end(evt.position)
  end
  self:_reset_drag_state()
end

function M:_reset_drag_state()
  self._is_pressing = false
  self._is_drag_ready = false
  self._has_begun_drag = false
  self._is_scrolling = false
end

function M:_get_scroll_rect()
  if self.holder and self.holder.get_active_scroll_rect then
    return self.holder:get_active_scroll_rect()
  end
  return nil
end

function M:refresh(index, cfg)
  self._index = index
  if not cfg or not cfg.id then
    self._cfg_id = 0
    self._cfg = nil
    local grass_icon = "UISprite/Load/Ground/Icon_GroundSetting_qingcaolu.png"
    UIUtil.set_image(self._img_icon, grass_icon, self:get_load_proxy())
    UIUtil.set_image(self._img_icon_select, grass_icon, self:get_load_proxy())
  else
    self._cfg_id = cfg.id
    self._cfg = cfg
    UIUtil.set_image(self._img_icon, cfg.icon, self:get_load_proxy())
    UIUtil.set_image(self._img_icon_select, cfg.icon, self:get_load_proxy())
  end
  self:_refresh_select_state()
end

function M:_refresh_select_state()
  if is_null(self._state_group_select) then
    return
  end
  local selected = self.holder and self.holder.is_multi_selected and self.holder:is_multi_selected(self._cfg_id)
  self._state_group_select:SetState(selected and SELECT_STATE_SELECTED or SELECT_STATE_NORMAL)
end

return M
