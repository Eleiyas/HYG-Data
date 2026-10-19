local M = G.Class("StarEtiquetteGiftDialog", G.UIWindow)
local base = G.UIWindow
local MODE_GIVE = 0
local MODE_RECEIVE = 1
local ITEM_STATE_EMPTY = 0
local ITEM_STATE_SELECTED = 1
local SENDER_STATE_HIDDEN = 0
local SENDER_STATE_VISIBLE = 1

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/StarEtiquette/StarEtiquetteGiftDialog"
  self.config.type = EUIType.Dialog
  self._mode = MODE_GIVE
  self._slot = ESecretSantaGiftSlot.SecretSantaGiftSlotSwap
  self._selected_item = nil
  self._gift_card = nil
  self._is_requesting = false
end

function M:on_create()
  base.on_create(self)
  self:_bind_callbacks()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnActivityRemoved, pack(self, M._on_activity_removed))
end

function M:on_enable()
  base.on_enable(self)
  self._activity_id = tonumber(CsSecretSantaModuleUtil.GetActivityId()) or 0
  local secret_santa_id = CsSecretSantaModuleUtil.GetSecretSantaId()
  self._secret_santa_cfg = ExcelDataUtil.get_value(typeof(BSecretSantaActivityCfg), secret_santa_id)
  self._message_chars_limit = self._secret_santa_cfg and self._secret_santa_cfg.messagecharslimit or 0
  self._input_message.characterLimit = self._message_chars_limit
  self._is_requesting = false
  self:_apply_extra_data()
  self:_refresh()
end

function M:on_close()
  self._sender_query_token = (self._sender_query_token or 0) + 1
  base.on_close(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_back)
end

function M:_bind_callbacks()
  self:bind_callback(self._btn_back, pack(self, M._on_close_click))
  self:bind_callback(self._btn_item, pack(self, M._on_select_item_click))
  self:bind_callback(self._btn_random_blessing, pack(self, M._on_random_blessing_click))
  self:bind_callback(self._btn_drift, pack(self, M._on_confirm_click))
  self:bind_callback(self._btn_collect, pack(self, M._on_confirm_click))
  self:bind_callback(self._btn_access, pack(self, M._on_access_click))
  self:bind_callback(self._btn_apply, pack(self, M._on_apply_click))
  self:bind_callback(self._btn_more, pack(self, M._on_report_click))
  self:bind_callback(self._tog_anonymous, pack(self, M._on_anonymous_changed))
end

function M:_on_anonymous_changed(is_on)
  if is_on then
    UIUtil.show_tips_by_text_id("SecretSanta_AnonymousTips")
  end
  if self._mode == MODE_GIVE then
    self:_refresh_give_sender()
  end
end

function M:_on_report_click()
  if self._gift_card == nil or self._slot ~= ESecretSantaGiftSlot.SecretSantaGiftSlotSwap then
    return
  end
  local menus = {
    {
      desc = UIUtil.get_text_by_id("Menu_Tip_Off"),
      valid = true,
      close = true,
      call_back_action = pack(self, M._on_menu_report)
    }
  }
  UIManagerInstance:open("UI/Social/CommonMenuDialog", {
    show_position = CsUIUtil.CalculateCanvasLocalPosition(self._btn_more.transform, UIManagerInstance.canvas_rect, 0.5, 1),
    state = 1,
    menus = menus
  })
end

function M:_on_menu_report()
  local card = self._gift_card
  if card == nil then
    return
  end
  report_module:open_report_page({
    target = report_module.report_target.secret_santa,
    target_uid = card.SenderUid or 0,
    target_message = card.Message or "",
    secret_santa_id = CsSecretSantaModuleUtil.GetSecretSantaId(),
    over_callback = function()
      UIUtil.set_text_by_id(self._content_text, "SecretSanta_Rejected_Tips")
    end
  })
end

function M:_apply_extra_data()
  local extra_data = self:get_extra_data()
  if type(extra_data) ~= "table" then
    self._mode = MODE_GIVE
    self._selected_item = nil
    self._gift_card = nil
    self._input_message.text = ""
    self._tog_anonymous.isOn = false
    return
  end
  self._mode = extra_data.mode == "receive" and MODE_RECEIVE or MODE_GIVE
  self._slot = extra_data.slot or ESecretSantaGiftSlot.SecretSantaGiftSlotSwap
  self._selected_item = nil
  self._gift_card = nil
  self._input_message.text = ""
  self._tog_anonymous.isOn = false
end

function M:_refresh()
  if self._mode == MODE_GIVE then
    self._state_mode:SetState(0)
  else
    local card = CsSecretSantaModuleUtil.GetGiftCard(self._slot)
    local can_show_sender = self:_can_show_sender(card)
    self._state_mode:SetState(can_show_sender and 1 or 2)
  end
  UIUtil.set_active(self._trans_content, self._mode == MODE_RECEIVE)
  UIUtil.set_active(self._input_message, self._mode == MODE_GIVE)
  if self._mode == MODE_RECEIVE then
    self:_refresh_receive()
  else
    self:_refresh_give()
  end
end

function M:_refresh_give()
  UIUtil.set_active(self._btn_drift, true)
  UIUtil.set_active(self._btn_collect, false)
  UIUtil.set_active(self._trans_over, false)
  UIUtil.set_active(self._btn_more, false)
  UIUtil.set_text_by_id(self._to_text, "SantaStar_GiftCard_Send_01")
  self._state_text_edit:SetState(SENDER_STATE_VISIBLE)
  self:_refresh_give_sender()
  self:_refresh_item(self._selected_item)
end

function M:_refresh_give_sender()
  UIUtil.set_active(self._trans_avatar, true)
  player_module:set_player_icon(self._img_head, self:get_load_proxy())
  if self._tog_anonymous.isOn then
    UIUtil.set_text_by_id(self._from_text, "SantaStar_GiftCard_Send_05")
  else
    UIUtil.set_text_by_id(self._from_text, "SecretSanta_FromPlayer", player_module:get_player_name())
  end
end

function M:_refresh_receive()
  self._sender_query_token = (self._sender_query_token or 0) + 1
  self._sender_name = nil
  self._gift_card = CsSecretSantaModuleUtil.GetGiftCard(self._slot)
  local card = self._gift_card
  if card == nil or card.Item == nil or card.Item.ConFigID == 0 then
    self._state_item:SetState(ITEM_STATE_EMPTY)
    self._state_text_edit:SetState(SENDER_STATE_HIDDEN)
    UIUtil.set_text(self._content_text, "")
    UIUtil.set_text(self._from_text, "")
    UIUtil.set_text(self._to_text, "")
    UIUtil.set_active(self._btn_drift, false)
    UIUtil.set_active(self._btn_collect, false)
    UIUtil.set_active(self._trans_over, false)
    UIUtil.set_active(self._btn_access, false)
    UIUtil.set_active(self._btn_apply, false)
    UIUtil.set_active(self._btn_more, false)
    return
  end
  self:_refresh_item(card.Item)
  if card.Slot == ESecretSantaGiftSlot.SecretSantaGiftSlotSwap then
    UIUtil.set_text_by_id(self._to_text, "SantaStar_GiftCard_Send_01")
    local message = card.Message or ""
    if card.IsReported then
      message = UIUtil.get_text_by_id("SecretSanta_Rejected_Tips")
    elseif not string.is_valid(message) then
      math.randomseed(player_module:get_player_uid())
      message = self:_get_random_blessing()
      math.randomseed(os.time())
    end
    UIUtil.set_text(self._content_text, message)
    if card.IsAnonymous or card.IsBot or card.SenderUid == 0 then
      UIUtil.set_text_by_id(self._from_text, "SantaStar_GiftCard_Send_05")
      UIUtil.set_active(self._trans_avatar, false)
    else
      self:_query_sender_info(card.SenderUid, self._sender_query_token)
      UIUtil.set_active(self._trans_avatar, true)
    end
  elseif card.Slot == ESecretSantaGiftSlot.SecretSantaGiftSlotSystem then
    UIUtil.set_active(self._trans_avatar, false)
    local letter_id = self._secret_santa_cfg and tonumber(self._secret_santa_cfg.cardfromsystem) or 0
    local letter_cfg = 0 < letter_id and ExcelDataUtil.get_value(typeof(BLetterCfg), letter_id) or nil
    if letter_cfg then
      UIUtil.set_text(self._content_text, letter_cfg.content or "")
      UIUtil.set_text(self._from_text, letter_cfg.fromformatstr or "")
      UIUtil.set_text(self._to_text, letter_cfg.toformatstr or "")
    else
      UIUtil.set_text(self._content_text, "")
      UIUtil.set_text(self._from_text, "")
      UIUtil.set_text(self._to_text, "")
    end
  end
  self._state_text_edit:SetState(SENDER_STATE_VISIBLE)
  UIUtil.set_active(self._btn_more, self._slot == ESecretSantaGiftSlot.SecretSantaGiftSlotSwap)
  local can_take = card.CanTake and not card.IsTaken
  UIUtil.set_active(self._btn_drift, false)
  UIUtil.set_active(self._btn_collect, can_take)
  UIUtil.set_active(self._trans_over, not can_take)
end

function M:_query_sender_info(sender_uid, query_token)
  self:_set_deleted_sender_info()
  CsSocialModuleUtil.QuerySocialPlayerInfo(sender_uid, function(info)
    if query_token ~= self._sender_query_token then
      return
    end
    local card = CsSecretSantaModuleUtil.GetGiftCard(self._slot)
    if card == nil or card.SenderUid ~= sender_uid then
      return
    end
    if info == nil or not string.is_valid(info.Nickname) then
      return
    end
    self._sender_name = info.Nickname
    UIUtil.set_text_by_id(self._from_text, "SecretSanta_FromPlayer", info.Nickname)
    UIUtil.set_player_avatar(self._img_head, info.AvatarId, self:get_load_proxy())
  end)
end

function M:_set_deleted_sender_info()
  local avatar_id = self._secret_santa_cfg and tonumber(self._secret_santa_cfg.deleteaccounthead) or 0
  local name_text_id = self._secret_santa_cfg and self._secret_santa_cfg.deleteaccounname or ""
  UIUtil.set_player_avatar(self._img_head, avatar_id, self:get_load_proxy())
  UIUtil.set_text_by_id(self._from_text, "SecretSanta_FromPlayer", string.is_valid(name_text_id) and UIUtil.get_text_by_id(name_text_id) or "")
end

function M:_refresh_item(item)
  local item_id = item ~= nil and item.ConFigID or 0
  local has_item = 0 < item_id
  self._state_item:SetState(has_item and ITEM_STATE_SELECTED or ITEM_STATE_EMPTY)
  if not has_item then
    UIUtil.set_text(self._name_text, "")
    UIUtil.set_text(self._classify_text, "")
    return
  end
  local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), item_id)
  local name = item_cfg ~= nil and item_cfg.name or ""
  local classify = ""
  local icon = item_cfg ~= nil and item_cfg.tooltableicon or ""
  UIUtil.set_text(self._name_text, name or "")
  UIUtil.set_text(self._classify_text, classify or "")
  if string.is_valid(icon) then
    UIUtil.set_image(self._item_icon, icon, self:get_load_proxy())
  end
end

function M:_on_select_item_click()
  if self._mode ~= MODE_GIVE or self._is_requesting then
    return
  end
  UIManagerInstance:open("UI/CommonUI/CommonSelectObjDialog", {
    show_mode = back_bag_module.bag_show_type.secret_santa,
    bag_main_type = back_bag_module.bag_main_type.none,
    on_select = function(_, item)
      if item == nil then
        return
      end
      self._selected_item = item
      self:_refresh_give()
    end
  })
end

function M:_get_random_blessing()
  local template_count = self._secret_santa_cfg and tonumber(self._secret_santa_cfg.notetempleteLength) or 0
  if template_count <= 0 then
    return
  end
  local index = math.random(0, template_count - 1)
  return UIUtil.get_text_by_id(self._secret_santa_cfg:notetemplete(index))
end

function M:_on_random_blessing_click()
  if self._mode ~= MODE_GIVE or self._is_requesting then
    return
  end
  self._input_message.text = self:_get_random_blessing()
end

function M:_on_confirm_click()
  if self._is_requesting then
    return
  end
  if self._mode == MODE_RECEIVE then
    self:_request_take_gift()
  else
    self:_request_submit_gift()
  end
end

function M:_request_submit_gift()
  if self._is_requesting then
    return
  end
  local selected_item = self._selected_item
  local item_id = selected_item ~= nil and selected_item.ConFigID or 0
  local item_guid = selected_item ~= nil and selected_item.GUID or 0
  local message = tostring(self._input_message.text or "")
  message = string.trim and string.trim(message) or message
  local message_len = utf8.len(message) or 0
  if item_id <= 0 then
    UIUtil.show_tips_by_text_id("SecretSanta_EmptyGift")
    return
  end
  if message_len <= 0 then
    UIUtil.show_tips_by_text_id("SecretSanta_EmptyText")
    return
  end
  local is_anonymous = self._tog_anonymous.isOn
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("SantaStar_GiftCard_Send_08"), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    self:_set_requesting(true)
    CsSecretSantaModuleUtil.RequestSubmitGift(item_guid, item_id, message, is_anonymous, pack(self, M._on_submit_finished))
  end)
  popup:show()
end

function M:_request_take_gift()
  if self._is_requesting then
    return
  end
  local card = CsSecretSantaModuleUtil.GetGiftCard(self._slot)
  self._gift_card = card
  if not (card ~= nil and card.Slot == self._slot and card.CanTake) or card.IsTaken then
    return
  end
  self:_set_requesting(true)
  self._pending_reward_item = {
    id = card.Item ~= nil and card.Item.ConFigID or 0,
    num = card.Item ~= nil and card.Item.Count or 0
  }
  CsSecretSantaModuleUtil.RequestTakeGift(self._slot, pack(self, M._on_take_finished))
end

function M:_on_submit_finished(success)
  self:_set_requesting(false)
  if not success then
    return
  end
  self:close_self()
  UIManagerInstance:open("UI/MainActivity_y1/StarEtiquette/StarEtiquetteTipsDialog", {
    text_id = "SantaStar_GiftCard_Send_10"
  })
end

function M:_on_take_finished(success)
  self:_set_requesting(false)
  if not success then
    self._pending_reward_item = nil
    return
  end
  local reward_item = self._pending_reward_item
  self._pending_reward_item = nil
  self:_refresh_receive()
  if reward_item ~= nil and reward_item.id > 0 and 0 < reward_item.num then
    common_ui_module:show_reward_dialog(nil, nil, {reward_item})
  end
end

function M:_set_requesting(requesting)
  self._is_requesting = requesting
end

function M:_on_access_click()
  local card = CsSecretSantaModuleUtil.GetGiftCard(self._slot)
  social_module:request_visit_player_mainland(social_module.social_transport_entry_source.secret_santa, card.SenderUid)
end

function M:_on_apply_click()
  local card = CsSecretSantaModuleUtil.GetGiftCard(self._slot)
  CsSocialModuleUtil.AddPasserByReqBySourceType(card.SenderUid, AddPasserBySourceType.StarGift)
end

function M:_on_close_click()
  if self._is_requesting then
    return
  end
  self:close_self()
end

function M:_on_activity_removed(activity_id)
  if activity_id ~= self._activity_id or not self:is_in_show_state() then
    return
  end
  star_etiquette_module:show_activity_end_dialog(self._activity_id, pack(self, M._on_activity_end_confirmed))
end

function M:_on_activity_end_confirmed()
  star_etiquette_module:finish_activity_end(self)
end

function M:_can_show_sender(card)
  return card ~= nil and card.Slot == self._slot and not card.IsAnonymous and not card.IsBot and 0 < (tonumber(card.SenderUid) or 0)
end

return M
