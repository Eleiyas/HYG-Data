local item_v2_cls = item_module.item_v2_panel_cls_name
local STATE_EXCHANGE_NORMAL = 0
local STATE_EXCHANGE_EMPTY = 1
local M = G.Class("SpringFestivalCombineExchangeCell", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._fukubag_id = 0
  self._on_add_cb = nil
  self._on_minus_cb = nil
  self._pay_panel = nil
  self._obj_item_v2_basic = nil
  self._btn_add_deep = nil
  self._btn_minus_deep = nil
  self._text_title = nil
  self._text_num = nil
  self._text_exchange_num = nil
  self._state_exchange = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_add_deep) then
    self:bind_callback(self._btn_add_deep, pack(self, M._on_click_add))
  end
  if not_null(self._btn_minus_deep) then
    self:bind_callback(self._btn_minus_deep, pack(self, M._on_click_minus))
  end
  if not_null(self._obj_item_v2_basic) then
    self._pay_panel = self:add_panel(item_v2_cls, self._obj_item_v2_basic)
  end
end

function M:set_data(fukubag_id, on_add_cb, on_minus_cb)
  self._fukubag_id = fukubag_id or 0
  self._on_add_cb = on_add_cb
  self._on_minus_cb = on_minus_cb
  if self._pay_panel ~= nil and self._fukubag_id ~= 0 then
    self._pay_panel:set_item_data(self._fukubag_id, nil, nil)
    self._pay_panel:bind_item_info_btn(self._fukubag_id)
  end
  if not is_null(self._text_title) and self._fukubag_id ~= 0 then
    item_module:set_item_name(self._text_title, self._fukubag_id)
  end
end

function M:refresh(stock, cur, is_locked)
  stock = tonumber(stock) or 0
  cur = tonumber(cur) or 0
  local is_empty = stock <= 0
  if not is_null(self._text_num) then
    UIUtil.set_text(self._text_num, string.format("%d/%d", stock, cur))
  end
  if not is_null(self._text_exchange_num) then
    UIUtil.set_text(self._text_exchange_num, tostring(cur))
  end
  if not is_null(self._state_exchange) then
    self._state_exchange:SetState(is_empty and STATE_EXCHANGE_EMPTY or STATE_EXCHANGE_NORMAL)
  end
  if not is_null(self._btn_add_deep) then
    self._btn_add_deep.interactable = not is_locked and not is_empty and stock > cur
  end
  if not is_null(self._btn_minus_deep) then
    self._btn_minus_deep.interactable = not is_locked and not is_empty and 0 < cur
  end
end

function M:get_fukubag_id()
  return self._fukubag_id
end

function M:_on_click_add()
  if self._on_add_cb ~= nil then
    self._on_add_cb(self._fukubag_id)
  end
end

function M:_on_click_minus()
  if self._on_minus_cb ~= nil then
    self._on_minus_cb(self._fukubag_id)
  end
end

return M
