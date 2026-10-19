local M = G.Class("StarEtiquetteNpcGiftDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/StarEtiquette/StarEtiquetteNpcGiftDialog"
  self.config.type = EUIType.Dialog
  self._slot = ESecretSantaGiftSlot.SecretSantaGiftSlotNpc
  self._gift_card = nil
  self._is_requesting = false
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_back, pack(self, M._on_close_click))
  self:bind_callback(self._btn_drift, pack(self, M._on_take_click))
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
  self._is_requesting = false
  self:_apply_extra_data()
  self:_refresh()
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_back)
end

function M:_apply_extra_data()
  local extra_data = self:get_extra_data()
  self._slot = extra_data.slot
end

function M:_refresh()
  local card = CsSecretSantaModuleUtil.GetGiftCard(self._slot)
  self._gift_card = card
  if card == nil or card.Slot ~= self._slot then
    self:close_self()
    return
  end
  self:_refresh_item(card.Item)
  local letter_id = self._secret_santa_cfg and tonumber(self._secret_santa_cfg.cardfromnpc) or 0
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
  local can_take = card.CanTake and not card.IsTaken
  self._btn_drift.interactable = can_take
  UIUtil.set_text_by_id(self._txt_draft, can_take and "SantaStar_GiftCard_Receive_05" or "SantaStar_GiftCard_Receive_06")
end

function M:_refresh_item(item)
  local item_id = item ~= nil and item.ConFigID or 0
  if item_id <= 0 then
    UIUtil.set_text(self._name_text, "")
    UIUtil.set_text(self._classify_text, "")
    UIUtil.set_active(self._item_icon, false)
    return
  end
  local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), item_id)
  local name = item_cfg ~= nil and item_cfg.name or ""
  local icon = item_cfg ~= nil and item_cfg.tooltableicon or ""
  UIUtil.set_text(self._name_text, name or "")
  UIUtil.set_text(self._classify_text, "")
  if string.is_valid(icon) then
    UIUtil.set_active(self._item_icon, true)
    UIUtil.set_image(self._item_icon, icon, self:get_load_proxy())
  else
    UIUtil.set_active(self._item_icon, false)
  end
end

function M:_on_take_click()
  if self._is_requesting then
    return
  end
  local card = CsSecretSantaModuleUtil.GetGiftCard(self._slot)
  self._gift_card = card
  if not (card ~= nil and card.Slot == self._slot and card.CanTake) or card.IsTaken then
    return
  end
  self._is_requesting = true
  self._pending_reward_item = {
    id = card.Item ~= nil and card.Item.ConFigID or 0,
    num = card.Item ~= nil and card.Item.Count or 0
  }
  CsSecretSantaModuleUtil.RequestTakeGift(self._slot, pack(self, M._on_take_finished))
end

function M:_on_take_finished(success)
  self._is_requesting = false
  if not success then
    self._pending_reward_item = nil
    return
  end
  local reward_item = self._pending_reward_item
  self._pending_reward_item = nil
  self:_refresh()
  if reward_item ~= nil and reward_item.id > 0 and 0 < reward_item.num then
    common_ui_module:show_reward_dialog(nil, nil, {reward_item})
  end
end

function M:_on_close_click()
  if not self._is_requesting then
    self:close_self()
  end
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

return M
