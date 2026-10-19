local M = G.Class("ThemeSeasonGraduationItem", G.UIPanel)
local base = G.UIPanel
local card_item_cls = "UI/TVShopping/TVShoppingCardItem"
local EXCHANGE_STATE = theme_season_module.GRADUATE_EXCHANGE_STATE
local ITEM_VISUAL_STATE = {
  NORMAL = 0,
  LOCKED = 1,
  OBTAINED = 2
}

function M:init()
  base.init(self)
  self._data = nil
  self._index = 0
  self._item_panel = nil
  self._on_item_click_callback = nil
  self._ui_state_group = nil
  self._tog_select = nil
  self._trans_item = nil
  self._img_coin_icon = nil
  self._txt_coin_num = nil
end

function M:on_create()
  base.on_create(self)
  self:_create_sub_panels()
  self:_bind_callbacks()
end

function M:on_destroy()
  self._data = nil
  self._item_panel = nil
  self._on_item_click_callback = nil
  base.on_destroy(self)
end

function M:_create_sub_panels()
  if not_null(self._trans_item) then
    self._item_panel = self:add_panel(card_item_cls, self._trans_item, {
      load_proxy = self:get_load_proxy()
    })
  end
end

function M:_bind_callbacks()
  if not_null(self._tog_select) then
    self:bind_callback(self._tog_select, pack(self, M._on_toggle))
  end
end

function M:_on_toggle(is_on)
  if not is_on then
    return
  end
  if self._on_item_click_callback and self._data then
    self._on_item_click_callback(self._data)
  end
end

function M:refresh(data, index, on_click_callback)
  self._data = data
  self._index = index
  self._on_item_click_callback = on_click_callback
  self:_refresh_item_icon()
  self:_refresh_state()
  self:_refresh_coin()
  self:_refresh_num()
end

function M:set_select(is_selected)
  if not_null(self._tog_select) and is_selected then
    self._tog_select.isOnValue = true
  end
  if self._item_panel then
    self._item_panel:set_select(is_selected)
  end
end

function M:get_toggle()
  return self._tog_select
end

function M:sync_selection(selected_data)
  self:set_select(self._data ~= nil and self._data == selected_data)
end

function M:_refresh_item_icon()
  if self._item_panel and self._data then
    self._item_panel:set_item_data(self._data.item_id)
  end
end

function M:_refresh_state()
  if is_null(self._ui_state_group) then
    return
  end
  local state = self._data and self._data.exchange_state or EXCHANGE_STATE.LOCKED
  local visual_state = ITEM_VISUAL_STATE.NORMAL
  if state == EXCHANGE_STATE.LOCKED then
    visual_state = ITEM_VISUAL_STATE.LOCKED
  elseif state == EXCHANGE_STATE.EXCHANGED then
    visual_state = ITEM_VISUAL_STATE.OBTAINED
  end
  self._ui_state_group:SetState(visual_state)
end

function M:_refresh_coin()
  if not self._data then
    return
  end
  local cost_id = self._data.cost_item_id or 0
  local cost_count = self._data.cost_item_count or 0
  if not_null(self._img_coin_icon) and 0 < cost_id then
    item_module:set_item_icon(self._img_coin_icon, cost_id, nil, nil, self:get_load_proxy())
  end
  if not_null(self._txt_coin_num) then
    local exchange_state = self._data.exchange_state or EXCHANGE_STATE.LOCKED
    local color = exchange_state == EXCHANGE_STATE.LACKED_COIN and "TexWarning_Light" or "TextDefault_Light"
    UIUtil.set_text(self._txt_coin_num, TextMapFormatUtil.FormatInteger(cost_count), color)
  end
end

function M:_refresh_num()
  if not self._data then
    return
  end
  local count = self._data.count or 0
  UIUtil.set_active(self._item_panel._trans_coin_item, true)
  UIUtil.set_text(self._item_panel._coin_view._txt_coin_num, count)
end

return M
