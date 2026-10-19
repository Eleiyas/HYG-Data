local M = G.Class("NpcImpressionHallNormalItem", G.UIPanel)
local base = G.UIPanel
local exchange_item_cls = "UI/ThemeSeason/NpcImpressionHallExchangeItem"
local LEVEL_STATE = theme_season_module.LEVEL_STATE
local ANIM_TRIGGER = theme_season_module.ANIM_TRIGGER
local ANIM_STATE_IN = "animi_npcImpressionhallpanel_normalnpc_item_in"

function M:init()
  base.init(self)
  self._cur_anim = nil
  self._canvas_group = nil
  self._data = nil
  self._index = 0
  self._item_panel = nil
  self._on_item_click_callback = nil
  self._ui_state_group = nil
  self._txt_index = nil
  self._trans_item_v2_basic_01 = nil
  self._btn_item = nil
  self._animator = nil
end

function M:play_anim(trigger)
  if is_null(self._animator) or not self._animator.gameObject.activeInHierarchy then
    return
  end
  self._animator.enabled = true
  self._animator:ResetTrigger(ANIM_TRIGGER.GET)
  self._animator:ResetTrigger(ANIM_TRIGGER.OUT)
  self._animator:ResetTrigger(ANIM_TRIGGER.IN)
  if trigger == ANIM_TRIGGER.IN then
    self._animator:Play(ANIM_STATE_IN, 0, 0)
    self._animator:Update(0)
  else
    self._animator:SetTrigger(trigger)
    self._animator:Update(0)
  end
  self._cur_anim = trigger
end

function M:get_cur_anim()
  return self._cur_anim
end

function M:prepare_enter_anim()
  if is_null(self._animator) then
    return
  end
  self._animator:ResetTrigger(ANIM_TRIGGER.GET)
  self._animator:ResetTrigger(ANIM_TRIGGER.OUT)
  self._animator:ResetTrigger(ANIM_TRIGGER.IN)
  self._animator.enabled = false
  if not_null(self._canvas_group) then
    self._canvas_group.alpha = 0
  end
  self._cur_anim = nil
end

function M:reset_anim()
  if is_null(self._animator) or not self._animator.gameObject.activeInHierarchy then
    return
  end
  self._animator.enabled = true
  self._animator:ResetTrigger(ANIM_TRIGGER.GET)
  self._animator:ResetTrigger(ANIM_TRIGGER.OUT)
  self._animator:ResetTrigger(ANIM_TRIGGER.IN)
  self._animator:Play(ANIM_STATE_IN, 0, 1)
  self._animator:Update(0)
  self._cur_anim = ANIM_TRIGGER.IN
end

function M:is_claimable()
  return self._data ~= nil and (self._data.get_state or 0) == 1
end

function M:on_disable()
  self._cur_anim = nil
  base.on_disable(self)
end

function M:on_create()
  base.on_create(self)
  self._canvas_group = UIUtil.find_cmpt(self.trans, nil, typeof(CanvasGroup))
  self:_create_item_panel()
end

function M:on_destroy()
  self._data = nil
  self._item_panel = nil
  self._on_item_click_callback = nil
  base.on_destroy(self)
end

function M:_create_item_panel()
  if is_null(self._trans_item_v2_basic_01) then
    return
  end
  self._item_panel = self:add_panel(exchange_item_cls, self._trans_item_v2_basic_01)
  if self._item_panel then
    self._item_panel:set_toggle_click(pack(self, M._on_click))
  end
end

function M:_on_click()
  if self._on_item_click_callback and self._data then
    self._on_item_click_callback(self._data)
  end
end

function M:refresh(data, index, on_click_callback)
  self._data = data
  self._index = index
  self._on_item_click_callback = on_click_callback
  self:_refresh_index()
  self:_refresh_item_icon()
  self:_refresh_state()
end

function M:_refresh_index()
  if not_null(self._txt_index) then
    UIUtil.set_text(self._txt_index, tostring(self._index))
  end
end

function M:_refresh_item_icon()
  if self._item_panel and self._data then
    self._item_panel:set_item_data(self._data.item_id, self._data.count)
    self._item_panel:set_get_state(self._data.get_state or 0)
    self._item_panel:set_lock_state(self._data.lock_state or 0)
  end
end

function M:_refresh_state()
  if is_null(self._ui_state_group) then
    return
  end
  local state = self._data and self._data.level_state or LEVEL_STATE.LOCKED
  self._ui_state_group:SetState(tonumber(state))
end

function M:sync_selection(selected_config_id)
  if self._item_panel then
    local on = self._data ~= nil and self._data.config_id == selected_config_id
    self._item_panel:set_selected(on)
  end
end

return M
