local M = G.Class("CommonBubbleInfoDialog", G.UIWindow)
local base = G.UIWindow
local DEFAULT_DURATION = 3
local DEFAULT_STATE = 1

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/CommonUI/CommonBubbleInfoDialog"
  self.config.type = EUIType.Dialog
  self._is_closed = false
  self._co_scope = G.New("Common/CoroutineScope")
  self._auto_close_co = nil
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
end

function M:on_enable()
  base.on_enable(self)
  self._is_closed = false
  self:_refresh_view()
end

function M:on_disable()
  base.on_disable(self)
  self._co_scope:clear()
  self._auto_close_co = nil
  self._anchor_follower:Clear()
end

function M:_on_btn_close_click()
  if self._is_closed then
    return
  end
  self._is_closed = true
  UIManagerInstance:close(self.guid)
end

function M:_refresh_view()
  local extra_data = self._extra_data
  if is_null(extra_data) or is_null(extra_data.target_trans) then
    self:_on_btn_close_click()
    return
  end
  UIUtil.set_text(self._txt_tips, extra_data.tips or "")
  local state = extra_data.state or DEFAULT_STATE
  self._state_group:SetState(state)
  local ratio_y = state <= 2 and 1 or 0
  self._anchor_follower:SetTarget(extra_data.target_trans, UIManagerInstance.canvas_rect, 0.5, ratio_y)
  local duration = extra_data.duration or DEFAULT_DURATION
  self._co_scope:cancel(self._auto_close_co)
  self._auto_close_co = self._co_scope:invoke(duration, function()
    self:_on_btn_close_click()
  end)
end

return M
