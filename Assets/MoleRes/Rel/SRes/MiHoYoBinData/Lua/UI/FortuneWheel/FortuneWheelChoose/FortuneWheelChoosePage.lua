local M = G.Class("FortuneWheelChoosePage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/FortuneWheel/FortuneWheelChoosePage"
  self.config.type = EUIType.Page
  self._cur_multiplier = 1
  self._cur_number = 1
end

function M:on_create()
  base.on_create(self)
  self:_init_panels()
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self._wheel_panel:set_number(1)
  self:_refresh_ui()
end

function M:on_disable()
  base.on_disable(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.ModuleUpdateEvent.LuaOnPrizeWheelDrawing, function()
    UIUtil.show_tips_by_text_id("FortuneWheeNewPage_Text_8")
    self:close_self()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_help, pack(self, M._on_btn_help_click))
  self:bind_callback(self._btn_bet, pack(self, M._on_btn_bet_click))
  self:bind_callback(self._btn_coin, pack(self, M._on_btn_coin_click))
end

function M:_init_panels()
  self._coin_bag_panel = self:add_panel("UI/FortuneWheel/FortuneWheelChoose/FortuneWheelCoinItem", self._trans_coin_bag)
  self._coin_need_panel = self:add_panel("UI/FortuneWheel/FortuneWheelChoose/FortuneWheelCoinItem", self._trans_coin_need)
  self._multi_panel = self:add_panel("UI/FortuneWheel/FortuneWheelChoose/FortuneWheelMultiSliderPanel", self._trans_multi)
  self._multi_panel:set_value_changed_callback(pack(self, M._on_multiplier_changed))
  self._wheel_panel = self:add_panel("UI/FortuneWheel/FortuneWheelChoose/FortuneWheelPanel", self._trans_wheel)
  self._wheel_panel:set_number_changed_callback(pack(self, M._on_number_changed))
  self._wheel_panel:set_drag_enabled(true)
  self._wheel_panel:set_number(1)
  self._wheel_panel:set_arrow_default()
end

function M:_refresh_ui()
  self:_refresh_coin()
  self:_refresh_bet_btn()
end

function M:_refresh_coin()
  self._coin_bag_panel:refresh(fortune_wheel_module:get_lottery_id())
  self._coin_need_panel:refresh(fortune_wheel_module:get_lottery_id(), self._cur_multiplier)
end

function M:_refresh_bet_btn()
  local lottery_id = fortune_wheel_module:get_lottery_id()
  local bag_count = back_bag_module:get_coin_or_item_num(lottery_id)
  self._btn_bet.interactable = bag_count >= self._cur_multiplier
end

function M:_on_multiplier_changed(multiplier)
  self._cur_multiplier = multiplier
  self:_refresh_coin()
  self:_refresh_bet_btn()
end

function M:_on_number_changed(number)
  self._cur_number = number
end

function M:_on_btn_help_click()
  fortune_wheel_module:open_intro_dialog()
end

function M:_on_btn_bet_click()
  local lottery_id = fortune_wheel_module:get_lottery_id()
  local bag_count = back_bag_module:get_coin_or_item_num(lottery_id)
  if bag_count < self._cur_multiplier then
    return
  end
  fortune_wheel_module:do_bet(self._cur_number, self._cur_multiplier)
  self:close_self()
end

function M:_on_btn_coin_click()
  local lottery_id = fortune_wheel_module:get_lottery_id()
  local num = back_bag_module:get_coin_or_item_num(lottery_id)
  item_module:open_item_info_dialog(lottery_id, num)
end

return M
