local M = G.Class("ExchangeCdKeyPopupDialog", G.UIWindow)
local base = G.UIWindow
local exchange_cooldown_time = 5.2
local refresh_interval = 0.3

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Phone/SDKRedeemCodeTip"
  self.config.type = EUIType.Dialog
  self._confirm_callback = nil
  self._cancel_callback = nil
  self._remain_cooldown_time = 0
  self._refresh_timer = 0
end

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
  self._input.onValueChanged:RemoveAllListeners()
  self._input.onValueChanged:AddListener(pack(self, M._on_input_changed))
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  local extra_data = self:get_extra_data() or {}
  self._confirm_callback = extra_data.confirm_callback
  self._cancel_callback = extra_data.cancel_callback
  self._input.text = ""
  self._refresh_timer = 0
  self:_refresh_exchange_cooldown_state()
  self:_refresh_input_state(self._input.text)
  self:_refresh_result_tip()
end

function M:on_disable()
  base.on_disable(self)
  self._confirm_callback = nil
  self._cancel_callback = nil
  self._remain_cooldown_time = 0
  self._refresh_timer = 0
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  self._refresh_timer = self._refresh_timer + deltaTime
  if self._refresh_timer < refresh_interval then
    return
  end
  self._refresh_timer = 0
  self:_refresh_exchange_cooldown_state()
  self:_refresh_input_state(self._input.text)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  self._input.onValueChanged:RemoveAllListeners()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaShowExchangeCdKeyResult, function(context)
    self:_refresh_result_tip(context)
  end)
end

function M:_on_btn_close_click()
  if self._cancel_callback then
    self._cancel_callback()
  end
  self:close_self()
end

function M:_on_btn_cancel_click()
  if self._cancel_callback then
    self._cancel_callback()
  end
  self:close_self()
end

function M:_on_btn_confirm_click()
  local input_text = self._input.text
  if not string.is_valid(input_text) then
    return
  end
  if self._remain_cooldown_time > 0 then
    return
  end
  exchange_cd_key_module:set_exchange_time(TimeUtil.ServerUtcTimeSeconds)
  self:_refresh_exchange_cooldown_state()
  self:_refresh_input_state(self._input.text)
  self:_refresh_result_tip()
  if self._confirm_callback then
    self._confirm_callback(input_text)
  end
end

function M:_on_btn_paste_click()
  local paste_text = CS.UnityEngine.GUIUtility.systemCopyBuffer or ""
  self._input.text = paste_text
  self:_refresh_input_state(self._input.text)
  UIUtil.set_active(self._trans_error, false)
end

function M:_on_btn_clear_click()
  self._input.text = ""
  self:_refresh_input_state(self._input.text)
  UIUtil.set_active(self._trans_error, false)
end

function M:_on_input_changed(text)
  self:_refresh_input_state(text)
  if self._trans_error_too_long.gameObject.activeSelf then
    UIUtil.set_active(self._trans_error, false)
  end
end

function M:_refresh_input_state(text)
  local has_input = string.is_valid(text)
  self._btn_confirm.interactable = has_input and self._remain_cooldown_time <= 0
end

function M:_refresh_exchange_cooldown_state()
  self._remain_cooldown_time = exchange_cd_key_module:get_exchange_remain_time(exchange_cooldown_time)
  if self._remain_cooldown_time > 0 then
    local display_time = math.floor(self._remain_cooldown_time)
    if display_time == 0 then
      display_time = 1
    end
    UIUtil.set_text_by_id(self._txt_confirm, "UI_SETTING_PAGE_EXCHANGE_TIMESLIMIT", display_time)
  else
    UIUtil.set_active(self._trans_error, false)
    UIUtil.set_text_by_id(self._txt_confirm, "UI_SETTING_PAGE_EXCHANGE")
  end
end

function M:bind_callbacks()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_cancel, pack(self, M._on_btn_cancel_click))
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm_click))
  self:bind_callback(self._btn_paste, pack(self, M._on_btn_paste_click))
  self:bind_callback(self._btn_clear, pack(self, M._on_btn_clear_click))
end

function M:_refresh_result_tip(context)
  if context == nil then
    UIUtil.set_active(self._trans_error, false)
    return
  end
  if context.success == true then
    local popup = UIUtil.get_confirm_popup()
    popup:set_texts(UIUtil.get_text_by_id("UI_SETTING_PAGE_EXCHANGE_RESULT_CONTENT"), UIUtil.get_text_by_id("UI_SETTING_PAGE_EXCHANGE_RESULT_CONFIRM"), nil, UIUtil.get_text_by_id("UI_SETTING_PAGE_EXCHANGE_RESULT_TITLE"))
    popup:set_style(ConfirmPopupStyle.ForcedPopup)
    popup:show()
    self:close_self()
  else
    UIUtil.set_active(self._trans_error, true)
    UIUtil.set_active(self._trans_error_too_long, false)
    UIUtil.set_text(self._txt_error_tip, context.message)
  end
end

return M
