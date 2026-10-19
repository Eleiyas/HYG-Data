local M = G.Class("NpcImpressionHallPremiumItem", G.UIPanel)
local base = G.UIPanel
local exchange_item_cls = "UI/ThemeSeason/NpcImpressionHallExchangeItem"
local LEVEL_STATE = theme_season_module.LEVEL_STATE
local ANIM_TRIGGER = theme_season_module.ANIM_TRIGGER
local ANIM_STATE_IN = "coui_npcImpressionhallpanel_item_in"

function M:init()
  base.init(self)
  self._cur_anim = nil
  self._canvas_group = nil
  self._data = nil
  self._final_row = nil
  self._final_data = nil
  self._index = 0
  self._item_panel_basic = nil
  self._item_panel_premium = nil
  self._item_panel_final = nil
  self._on_item_click_callback = nil
  self._ui_state_group = nil
  self._txt_index = nil
  self._trans_item_basic = nil
  self._trans_item_premium = nil
  self._trans_item_final = nil
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
  if self._final_data then
    return theme_season_module:is_premium_item_free_claimable(self._final_data)
  end
  local premium = self._data and self._data.premium_item
  return premium ~= nil and theme_season_module:is_premium_item_free_claimable(premium)
end

function M:on_disable()
  self._cur_anim = nil
  base.on_disable(self)
end

function M:on_create()
  base.on_create(self)
  self._canvas_group = UIUtil.find_cmpt(self.trans, nil, typeof(CanvasGroup))
  self:_create_item_panels()
end

function M:on_destroy()
  self._data = nil
  self._final_row = nil
  self._final_data = nil
  self._item_panel_basic = nil
  self._item_panel_premium = nil
  self._item_panel_final = nil
  self._on_item_click_callback = nil
  base.on_destroy(self)
end

function M:_create_item_panels()
  if not_null(self._trans_item_basic) then
    self._item_panel_basic = self:add_panel(exchange_item_cls, self._trans_item_basic)
    if self._item_panel_basic then
      self._item_panel_basic:set_toggle_click(pack(self, M._on_click_basic))
    end
  end
  if not_null(self._trans_item_premium) then
    self._item_panel_premium = self:add_panel(exchange_item_cls, self._trans_item_premium)
    if self._item_panel_premium then
      self._item_panel_premium:set_toggle_click(pack(self, M._on_click_premium))
    end
  end
  if not_null(self._trans_item_final) then
    self._item_panel_final = self:add_panel(exchange_item_cls, self._trans_item_final)
    if self._item_panel_final then
      self._item_panel_final:set_toggle_click(pack(self, M._on_click_final))
    end
  end
end

function M:_on_click_basic()
  if self._on_item_click_callback and self._data and self._data.basic_item then
    self._on_item_click_callback(self._data.basic_item)
  end
end

function M:_on_click_premium()
  if self._on_item_click_callback and self._data and self._data.premium_item then
    self._on_item_click_callback(self._data.premium_item)
  end
end

function M:_on_click_final()
  if self._on_item_click_callback and self._final_data then
    self._on_item_click_callback(self._final_data)
  end
end

function M:refresh(data, index, on_click_callback)
  self._data = data
  self._final_row = nil
  self._final_data = nil
  self._index = index
  self._on_item_click_callback = on_click_callback
  self:_refresh_index()
  self:_refresh_state()
  self:_refresh_item_icons()
  if not_null(self._trans_item_final) then
    UIUtil.set_active(self._trans_item_final, false)
  end
end

function M:refresh_as_final(final_row, on_click_callback)
  self._data = nil
  self._final_row = final_row
  self._final_data = final_row and final_row.premium_item or nil
  self._index = final_row and final_row.level or 0
  self._on_item_click_callback = on_click_callback
  self:_refresh_index()
  if not_null(self._trans_item_basic) then
    UIUtil.set_active(self._trans_item_basic, false)
  end
  if not_null(self._trans_item_premium) then
    UIUtil.set_active(self._trans_item_premium, false)
  end
  if not_null(self._trans_item_final) then
    UIUtil.set_active(self._trans_item_final, self._final_data ~= nil)
  end
  if self._item_panel_final and self._final_data then
    self._item_panel_final:set_item_data(self._final_data.item_id, self._final_data.count)
    self._item_panel_final:set_get_state(self._final_data.get_state or 0)
    self._item_panel_final:set_lock_state(self._final_data.lock_state or 0)
    self._item_panel_final:set_red_point(theme_season_module:is_premium_item_free_claimable(self._final_data) and RedPointType.GiftRP or RedPointType.None)
  end
  self:_refresh_state()
end

function M:_refresh_index()
  if not_null(self._txt_index) then
    UIUtil.set_text(self._txt_index, tostring(self._index))
  end
end

function M:_refresh_item_icons()
  local has_basic = self._data ~= nil and self._data.basic_item ~= nil
  local has_premium = self._data ~= nil and self._data.premium_item ~= nil
  if not_null(self._trans_item_basic) then
    UIUtil.set_active(self._trans_item_basic, has_basic)
  end
  if not_null(self._trans_item_premium) then
    UIUtil.set_active(self._trans_item_premium, has_premium)
  end
  if self._item_panel_basic and has_basic then
    local basic = self._data.basic_item
    self._item_panel_basic:set_item_data(basic.item_id, basic.count)
    self._item_panel_basic:set_get_state(basic.get_state or 0)
    self._item_panel_basic:set_lock_state(basic.lock_state or 0)
    self._item_panel_basic:set_red_point(RedPointType.None)
  end
  if self._item_panel_premium and has_premium then
    local premium = self._data.premium_item
    self._item_panel_premium:set_item_data(premium.item_id, premium.count)
    self._item_panel_premium:set_get_state(premium.get_state or 0)
    self._item_panel_premium:set_lock_state(premium.lock_state or 0)
    self._item_panel_premium:set_red_point(theme_season_module:is_premium_item_free_claimable(premium) and RedPointType.GiftRP or RedPointType.None)
  end
end

function M:_refresh_state()
  if is_null(self._ui_state_group) then
    return
  end
  local active = self._data or self._final_row
  local state = active and active.level_state or LEVEL_STATE.LOCKED
  self._ui_state_group:SetState(tonumber(state))
end

function M:sync_selection(selected_config_id)
  if self._item_panel_basic then
    local b = self._data and self._data.basic_item
    self._item_panel_basic:set_selected(b ~= nil and b.config_id == selected_config_id)
  end
  if self._item_panel_premium then
    local p = self._data and self._data.premium_item
    self._item_panel_premium:set_selected(p ~= nil and p.config_id == selected_config_id)
  end
  if self._item_panel_final then
    self._item_panel_final:set_selected(self._final_data ~= nil and self._final_data.config_id == selected_config_id)
  end
end

return M
