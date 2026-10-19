local M = G.Class("ThemeSeasonBpGiftReceiveDialog", G.UIWindow)
local base = G.UIWindow
local PREFAB_PATH = "UI/BattlePass/BattlePassSeasonGiftReceivePage"
local GIFT_ITEM_CLS = "UI/Item/ItemV2Panel"
local GIFT_STATE = chat_module.SOCIAL_GIFT_STATE
local ANIM_TRIGGER = theme_season_module.ANIM_TRIGGER
local ANIM_STATE_IDLE = "New State"
local TEXT_ID = {
  TYPE_RECEIVER = "ThemeSeason_UI_056",
  TYPE_SENDER = "ThemeSeason_UI_057",
  TITLE_RECEIVER = "ThemeSeason_UI_058",
  TITLE_SENDER = "ThemeSeason_UI_059",
  TIPS_PENDING = "ThemeSeason_UI_060",
  ACCEPTED_RECEIVER = "ThemeSeason_UI_061",
  ACCEPTED_SENDER = "ThemeSeason_UI_062",
  RETURNED = "ThemeSeason_UI_063",
  CLAIM_FAILED = "ThemeSeason_UI_064",
  FAIL_POPUP_TITLE = "ThemeSeason_UI_065",
  FAIL_BP_OWNED = "ThemeSeason_UI_066",
  FAIL_NOT_FRIEND = "ThemeSeason_UI_068"
}
local CLAIM_FAIL_POPUP_TEXT_ID = {
  [RetCode.RetSocialGiftBpAlreadyOwned] = TEXT_ID.FAIL_BP_OWNED,
  [RetCode.RetSocialGiftNotFriend] = TEXT_ID.FAIL_NOT_FRIEND
}

function M:init()
  base.init(self)
  self.config.prefab_path = PREFAB_PATH
  self.config.type = EUIType.Dialog
  self._gift_id = 0
  self._is_receiver = true
  self._msg_type = 0
  self._send_time = 0
  self._peer_uid = 0
  self._item_id = 0
  self._item_num = 0
  self._claiming = false
  self._gift_item_panel = nil
  self._exit_anim_pending = false
  self._btn_close = nil
  self._img_head = nil
  self._txt_dialog_title = nil
  self._txt_gift_type_title = nil
  self._txt_player_name = nil
  self._trans_gift_item = nil
  self._txt_gift_item_name = nil
  self._txt_title_tips = nil
  self._btn_receive = nil
  self._trans_accepted = nil
  self._txt_accept_state = nil
  self._animator_helper_gift = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn_receive) then
    self:bind_callback(self._btn_receive, pack(self, M._on_btn_receive_click))
  end
  if not_null(self._trans_gift_item) then
    self._gift_item_panel = self:add_panel(GIFT_ITEM_CLS, self._trans_gift_item)
    self:_bind_gift_item_btn()
  end
end

function M:_bind_gift_item_btn()
  local btn = self._gift_item_panel ~= nil and self._gift_item_panel:get_btn() or nil
  if btn == nil then
    return
  end
  self:bind_callback(btn, function()
    if self._item_id > 0 then
      item_module:open_item_info_dialog(self._item_id, back_bag_module:get_coin_or_item_num(self._item_id))
    end
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_close_btn(self._btn_close)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnSocialGiftInboxChanged, pack(self, M.refresh))
  self:add_evt_listener(EventID.OnSocialGiftClaimRsp, pack(self, M._on_claim_rsp))
end

function M:on_open()
  base.on_open(self)
  theme_season_module:report_page_reach(theme_season_module.REPORT_PAGE_ID.BP_GIFT_RECEIVE)
  local ctx = self:get_extra_data() or {}
  self._gift_id = ctx.gift_id or 0
  self._is_receiver = ctx.is_receiver ~= false
  self._msg_type = ctx.msg_type or 0
  self._send_time = ctx.send_time or 0
  self._peer_uid = ctx.peer_uid or 0
  self._item_id = ctx.item_id or 0
  self._item_num = ctx.item_num or 0
  self._claiming = false
end

function M:on_enable()
  base.on_enable(self)
  self:_abort_pending_exit_anim()
  self:refresh()
  self:_play_enter_anim()
end

function M:on_disable()
  self._exit_anim_pending = false
  base.on_disable(self)
end

function M:_abort_pending_exit_anim()
  if not self._exit_anim_pending then
    return
  end
  self._exit_anim_pending = false
  if is_null(self._animator_helper_gift) then
    return
  end
  self._animator_helper_gift:ClearCallback()
  local animator = self._animator_helper_gift:GetAnimator()
  if not_null(animator) then
    animator:Play(ANIM_STATE_IDLE, 0, 0)
  end
end

function M:play_exit_anim()
  if is_null(self._animator_helper_gift) or not self._animator_helper_gift.gameObject.activeInHierarchy then
    base.play_exit_anim(self)
    return
  end
  self._exit_anim_pending = true
  self._animator_helper_gift:SetTriggerWithCallback(ANIM_TRIGGER.OUT, function()
    if not self._exit_anim_pending or self._is_hiding then
      return
    end
    self._exit_anim_pending = false
    base.play_exit_anim(self)
  end, true)
end

function M:refresh()
  if self._gift_id <= 0 then
    return
  end
  if self._is_receiver then
    local sender_uid = CsSocialModuleUtil.GetSocialGiftSenderUid(self._gift_id)
    if sender_uid ~= nil and 0 < sender_uid then
      self._peer_uid = sender_uid
    end
    local item_id = CsSocialModuleUtil.GetSocialGiftItemCfgId(self._gift_id)
    if item_id ~= nil and 0 < item_id then
      self._item_id = item_id
      self._item_num = CsSocialModuleUtil.GetSocialGiftItemNum(self._gift_id) or 0
    end
  end
  self:_refresh_titles()
  self:_refresh_peer()
  self:_refresh_gift_item()
  self:_refresh_button_area()
end

function M:_refresh_titles()
  UIUtil.set_text_by_id(self._txt_dialog_title, self._is_receiver and TEXT_ID.TITLE_RECEIVER or TEXT_ID.TITLE_SENDER)
  UIUtil.set_text_by_id(self._txt_gift_type_title, self._is_receiver and TEXT_ID.TYPE_RECEIVER or TEXT_ID.TYPE_SENDER)
end

function M:_refresh_peer()
  local friend_info = self._peer_uid > 0 and social_module:get_friend_info_by_uid(self._peer_uid) or nil
  UIUtil.set_text(self._txt_player_name, not_null(friend_info) and friend_info.nick_name or "")
  UIUtil.set_active(self._img_head, true)
  UIUtil.set_player_avatar(self._img_head, not_null(friend_info) and friend_info.avatar_id or 0, self:get_load_proxy())
end

function M:_refresh_gift_item()
  local has_item = self._item_id > 0
  UIUtil.set_active(self._trans_gift_item, has_item)
  if has_item and self._gift_item_panel ~= nil then
    self._gift_item_panel:set_item_data(self._item_id, self._item_num > 1 and self._item_num or nil)
  end
  local item_cfg = has_item and item_module:get_cfg_by_id(self._item_id) or nil
  UIUtil.set_text(self._txt_gift_item_name, item_cfg ~= nil and item_cfg.name or "")
end

function M:_refresh_button_area()
  local state = chat_module:gift_display_state(self._gift_id, self._is_receiver, self._msg_type, self._send_time)
  local is_pending = state == GIFT_STATE.PENDING
  UIUtil.set_active(self._txt_title_tips, is_pending)
  if is_pending then
    UIUtil.set_text_by_id(self._txt_title_tips, TEXT_ID.TIPS_PENDING)
  end
  UIUtil.set_active(self._btn_receive, is_pending and self._is_receiver)
  UIUtil.set_active(self._trans_accepted, not is_pending)
  if not is_pending then
    local accept_text_id
    if state == GIFT_STATE.RETURNED then
      accept_text_id = TEXT_ID.RETURNED
    else
      accept_text_id = self._is_receiver and TEXT_ID.ACCEPTED_RECEIVER or TEXT_ID.ACCEPTED_SENDER
    end
    UIUtil.set_text_by_id(self._txt_accept_state, accept_text_id)
  end
end

function M:_on_btn_receive_click()
  if self._claiming or self._gift_id <= 0 then
    return
  end
  if chat_module:gift_display_state(self._gift_id, self._is_receiver, self._msg_type, self._send_time) ~= GIFT_STATE.PENDING then
    self:refresh()
    return
  end
  self._claiming = true
  CsSocialModuleUtil.ClaimSocialGift(self._gift_id)
end

function M:_on_claim_rsp(rsp)
  if rsp == nil or rsp.Id ~= self._gift_id then
    return
  end
  self._claiming = false
  if rsp.Retcode ~= 0 then
    self:_show_claim_fail(rsp.Retcode)
  end
  self:refresh()
end

function M:_play_enter_anim()
  if is_null(self._animator_helper_gift) or not self._animator_helper_gift.gameObject.activeInHierarchy then
    return
  end
  local is_first = not theme_season_module:is_bp_gift_opened()
  self._animator_helper_gift:SetTriggerWithCallback(is_first and ANIM_TRIGGER.FIRST_GET or ANIM_TRIGGER.GET)
  self._animator_helper_gift:ClearCallback()
  if is_first then
    theme_season_module:mark_bp_gift_opened()
  end
end

function M:_show_claim_fail(retcode)
  local popup_text_id = CLAIM_FAIL_POPUP_TEXT_ID[retcode]
  if popup_text_id == nil then
    UIUtil.show_tips_by_text_id(TEXT_ID.CLAIM_FAILED)
    return
  end
  local gift_id = self._gift_id
  local items = {}
  if self._item_id > 0 then
    items[1] = {
      config_id = self._item_id,
      num = 0 < self._item_num and self._item_num or 1
    }
  end
  common_ui_module:show_item_common_confirm_dialog(UIUtil.get_text_by_id(TEXT_ID.FAIL_POPUP_TITLE), UIUtil.get_text_by_id(popup_text_id), items, nil, nil, UIUtil.get_text_by_id("Common_Confirm"), function()
    self:_return_gift(gift_id)
  end, false, nil)
end

function M:_return_gift(gift_id)
  if gift_id == nil or gift_id <= 0 then
    return
  end
  CsSocialModuleUtil.ReturnSocialGift(gift_id)
  self:close_self()
end

return M
