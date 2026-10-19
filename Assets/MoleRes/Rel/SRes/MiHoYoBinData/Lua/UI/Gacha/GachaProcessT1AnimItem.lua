local M = G.Class("GachaProcessT1AnimItem", G.UIBase)
local base = G.UIBase
local BIG_NUM_SPRITE_START_INDEX = 10

function M:init()
  base.init(self)
  self._is_burst = false
  self._trigger = nil
  self._add_num = 0
  self._on_burst_request = nil
  self._btn_burst_trans = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_burst) then
    self:bind_callback(self._btn_burst, pack(self, M._on_btn_burst_click))
  end
  if not_null(self._btn_burst_trans) then
    self.binder:BindViewCallback(self._btn_burst_trans, EventTriggerType.PointerEnter, pack(self, M._on_btn_burst_enter))
    self.binder:BindViewCallback(self._btn_burst_trans, EventTriggerType.PointerExit, pack(self, M._on_btn_burst_exit))
  end
end

function M:on_enable()
  base.on_enable(self)
  self:set_add_num(0)
end

function M:setup(trigger, add_num, is_big_burst, on_burst_request)
  self._is_burst = false
  self._trigger = trigger
  self._add_num = add_num or 0
  self._on_burst_request = on_burst_request
  self:set_add_num(0, is_big_burst)
  UIUtil.set_active(self._btn_burst, true)
end

function M:play_burst()
  if self._is_burst then
    return
  end
  self._is_burst = true
  self:set_add_num(self._add_num)
  if not is_null(self._animator) and self._trigger then
    self._animator:SetTrigger(self._trigger)
  end
  UIUtil.set_active(self._btn_burst, false)
end

function M:set_add_num(add_num, is_big_burst)
  if is_null(self._txt_add_num) then
    return
  end
  add_num = add_num or 0
  UIUtil.set_active(self._txt_add_num, 0 < add_num)
  if add_num <= 0 then
    return
  end
  local start_index = is_big_burst and BIG_NUM_SPRITE_START_INDEX or 0
  UIUtil.set_sprite_number_text(self._txt_add_num, add_num, start_index)
end

function M:_on_btn_burst_click()
  if self._is_burst or self._on_burst_request == nil then
    return
  end
  self._on_burst_request(self)
end

function M:_on_btn_burst_enter()
  if self._is_burst or is_null(self._animator) then
    return
  end
  self._animator:SetTrigger("highlight")
end

function M:_on_btn_burst_exit()
  if self._is_burst or is_null(self._animator) then
    return
  end
  self._animator:SetTrigger("normal")
end

return M
