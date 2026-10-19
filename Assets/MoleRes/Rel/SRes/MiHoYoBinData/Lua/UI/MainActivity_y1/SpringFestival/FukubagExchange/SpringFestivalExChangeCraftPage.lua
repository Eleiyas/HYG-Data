local cell_cls_name = "UI/MainActivity_y1/SpringFestival/FukubagExchange/SpringFestivalExChangeCraftCell"
local ACTIVITY_END_DIALOG_TEXT_ID = "Activity_EndDialog_Desc"
local M = G.Class("SpringFestivalExChangeCraftPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_ExChangeCraftDialog"
  self.config.type = EUIType.Page
  self._fukubag_entries = {}
  self._token_icon_path = ""
  self._token_big_icon_path = ""
  self._max_exchangeable = 0
  self._cur_exchange_num = 0
  self._cur_introduction_id = spring_festival_exchange_module.EXCHANGE_INTRODUCTION_ID or 0
  self._activity_end_dialog_shown = false
end

function M:on_create()
  base.on_create(self)
  self:_bind_buttons()
  self:_build_entries()
end

function M:on_enable()
  base.on_enable(self)
  self._activity_end_dialog_shown = false
  self:_refresh_all()
end

function M:_bind_buttons()
  if self._btn_close then
    self:bind_callback(self._btn_close, pack(self, M._on_click_close))
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  end
  if not is_null(self._btn_add_deep) then
    self:bind_callback(self._btn_add_deep, function()
      self:_on_btn_add_or_minus_click(1)
    end)
  end
  if not is_null(self._btn_minus_deep) then
    self:bind_callback(self._btn_minus_deep, function()
      self:_on_btn_add_or_minus_click(-1)
    end)
  end
  if not is_null(self._slider) then
    self:bind_callback(self._slider, pack(self, M._on_slider_value_changed))
  end
  if not is_null(self._btn_lv1) then
    self:bind_callback(self._btn_lv1, pack(self, M._on_click_confirm))
  end
  if not is_null(self._btn_introduction) then
    self:bind_callback(self._btn_introduction, pack(self, M._on_click_introduction))
  end
end

function M:_refresh_introduction_btn()
  if not is_null(self._btn_introduction) then
    UIUtil.set_active(self._btn_introduction, self._cur_introduction_id > 0)
  end
end

function M:_on_click_introduction()
  if self._cur_introduction_id > 0 then
    UIManagerInstance:open("UI/CommonUI/IntroductionDialog", self._cur_introduction_id)
  end
end

function M:_on_click_close()
  UIManagerInstance:close_page_with_dialogs_above(self)
  EventCenter.Broadcast(EventID.LuaSpringFestivalExchangeCraftUserClose)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaFukuBagExchangeTokenRsp, pack(self, M._on_exchange_rsp))
  self:add_evt_listener(EventID.LuaFukuBagCombineLuckyBagRsp, pack(self, M._on_combine_rsp))
  self:add_evt_listener(EventID.OnActivityRemoved, pack(self, M._on_activity_removed))
end

function M:_on_activity_removed(activity_id)
  if activity_id ~= spring_festival_activity_module:get_main_activity_id() then
    return
  end
  self:_show_activity_end_dialog()
end

function M:_show_activity_end_dialog()
  if self._activity_end_dialog_shown then
    return
  end
  self._activity_end_dialog_shown = true
  local popup = UIUtil.get_confirm_popup()
  popup:set_style(ConfirmPopupStyle.ForcedPopup)
  popup:set_texts(UIUtil.get_text_by_id(ACTIVITY_END_DIALOG_TEXT_ID), UIUtil.get_text_by_id("Common_Accept"), nil, nil)
  popup:set_callbacks(function()
    self:_on_click_close()
  end)
  popup:show()
end

function M:_on_click_confirm()
  if (self._cur_exchange_num or 0) == 0 then
    UIUtil.show_tips_by_text_id("SpringFestival_HUDCommonTip_Rule")
    return
  end
  spring_festival_exchange_module:send_exchange_req(self._cur_exchange_num)
end

function M:_on_exchange_rsp(arg)
  local retcode = tonumber(arg) or -1
  self:_refresh_all()
  if retcode == 0 then
    self:close_self()
  end
end

function M:_on_combine_rsp(arg)
  self:_refresh_all()
end

function M:_build_entries()
  if is_null(self._layout_sublist) then
    Logger.LogWarning("[SpringFestivalExChangeCraftPage] _layout_sublist not bound, skip build entries")
  elseif self._layout_sublist.AddItem == nil then
    Logger.LogWarning("[SpringFestivalExChangeCraftPage] _layout_sublist has no AddItem (not a List component)")
  else
    local ids = spring_festival_exchange_module:get_fukubag_ids()
    for i, item_id in ipairs(ids) do
      local cell_obj = self._layout_sublist:AddItem(0)
      if not_null(cell_obj) then
        local cell = self:add_panel(cell_cls_name, cell_obj)
        cell:set_data(item_id, function(id)
          self:_on_btn_craft_click(id)
        end)
        table.insert(self._fukubag_entries, {
          obj = cell_obj,
          cell = cell,
          item_id = item_id
        })
      end
    end
  end
end

function M:_refresh_token_icons()
  self._token_icon_path = spring_festival_exchange_module:get_token_icon_path()
  self._token_big_icon_path = spring_festival_exchange_module:get_token_big_icon_path()
  if not is_null(self._img_craft) then
    UIUtil.set_image(self._img_craft, self._token_big_icon_path, self:get_load_proxy())
  end
end

function M:_refresh_all()
  self:_refresh_introduction_btn()
  self:_refresh_token_icons()
  self:_refresh_slider()
end

function M:_refresh_fukubag_nums()
  local need = spring_festival_exchange_module:get_required_per_fukubag(self._cur_exchange_num)
  local per = spring_festival_exchange_module:get_fukubag_per_combine()
  for _, entry in ipairs(self._fukubag_entries) do
    if entry and entry.cell then
      local cur = CsPacketModuleUtil.GetItemNum(entry.item_id) or 0
      local sum = 0
      for _, other_id in ipairs(spring_festival_exchange_module:get_fukubag_ids()) do
        if other_id ~= entry.item_id then
          local effective = (CsPacketModuleUtil.GetItemNum(other_id) or 0) - need
          if 0 < effective then
            sum = sum + effective
          end
          if per <= sum then
            break
          end
        end
      end
      local can_combine = per <= sum
      local can_flash = can_combine
      entry.cell:refresh(cur, need, can_combine, can_flash)
    end
  end
end

function M:_on_btn_craft_click(item_id)
  local reserved_per_item = spring_festival_exchange_module:get_required_per_fukubag(self._cur_exchange_num)
  UIManagerInstance:open("UI/MainActivity_y1/SpringFestival/FukubagExchange/SpringFestivalCombineLuckyBagDialog", {target_item_id = item_id, reserved_per_item = reserved_per_item})
end

function M:_refresh_slider()
  self._max_exchangeable = spring_festival_exchange_module:calc_max_exchangeable()
  local can_exchange = self._max_exchangeable > 0
  if not is_null(self._state_exchangeble) then
    self._state_exchangeble:SetState(can_exchange and 0 or 1)
  end
  if not is_null(self._trans_slider) then
    UIUtil.set_active(self._trans_slider, can_exchange)
  end
  if is_null(self._slider) then
    self:_apply_cur_exchange_num(can_exchange and self._max_exchangeable or 0)
    return
  end
  self._slider.minValue = 0
  self._slider.maxValue = self._max_exchangeable
  self._slider.interactable = self._max_exchangeable > 1
  local target = can_exchange and self._max_exchangeable or 0
  self._slider.value = target
  self:_apply_cur_exchange_num(target)
end

function M:_on_btn_add_or_minus_click(delta)
  if is_null(self._slider) then
    return
  end
  self._slider.value = self._cur_exchange_num + delta
end

function M:_on_slider_value_changed(value)
  local cur = math.modf(value or 0)
  if cur == self._cur_exchange_num then
    return
  end
  self:_apply_cur_exchange_num(cur)
end

function M:_apply_cur_exchange_num(cur)
  self._cur_exchange_num = cur
  local exchange_num_arg = 0 < cur and tostring(cur) or string.format("<style=TextWarning_Dark>%d</style>", cur)
  UIUtil.set_text_by_id(self._text_exchangenum, "SpringFestival_NPCExChange_ExchangeNum", exchange_num_arg)
  local least_num = spring_festival_exchange_module:calc_least_token(cur)
  local least_text = UIUtil.get_text_by_id("SpringFestival_NPCExChange_LeastNum", self._token_icon_path or "", least_num)
  UIUtil.set_text_with_dynamic_sprite(self._text_leastnum, least_text)
  if not is_null(self._btn_add_deep) then
    self._btn_add_deep.interactable = cur < self._max_exchangeable
  end
  if not is_null(self._btn_minus_deep) then
    self._btn_minus_deep.interactable = 0 < cur
  end
  self:_refresh_fukubag_nums()
end

return M
