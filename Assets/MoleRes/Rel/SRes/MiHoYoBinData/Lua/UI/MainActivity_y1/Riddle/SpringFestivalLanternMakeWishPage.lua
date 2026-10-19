local M = G.Class("SpringFestivalLanternMakeWishPage", G.UIWindow)
local base = G.UIWindow
local RANDOM_WISH_RECENT_LIMIT = 5
local WISH_STATE_CANCELABLE = 0
local WISH_STATE_VIEW_ONLY = 1
local WISH_PUBLISH_RET_SUCCESS = 0
local WISH_PUBLISH_FAIL_TIPS = {
  [49171] = "FestiveLantern_Empty",
  [49176] = "FestiveLantern_Sensitive"
}
local ACTIVITY_END_DIALOG_TEXT_ID = "Activity_EndDialog_Desc"
local WISH_TRACKING_ID = 15

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_MakeWishDialog"
  self.config.type = EUIType.Dialog
  self._recent_random_wish_ids = {}
  self._activity_end_dialog_shown = false
end

function M:on_create()
  base.on_create(self)
  self:_bind_buttons()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaSpringFestivalLanternWishPublishRsp, pack(self, M._on_publish_wish_rsp))
  self:add_evt_listener(EventID.OnActivityRemoved, pack(self, M._on_activity_removed))
  self:add_evt_listener(EventID.LuaSpringFestivalLanternWishCleared, pack(self, M._on_wish_cleared))
end

function M:_on_wish_cleared()
  self:_refresh_wish_state()
end

function M:on_enable()
  base.on_enable(self)
  self._activity_end_dialog_shown = false
  self._is_publishing = false
  self:_refresh_wish_state()
  self:_refresh_player_name()
end

function M:_on_activity_removed(activity_id)
  local module = spring_festival_activity_module
  if activity_id ~= activity_center_module:get_tracking_activity_id(WISH_TRACKING_ID) and activity_id ~= module:get_main_activity_id() then
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

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, pack(self, M._handle_esc_back))
end

function M:_handle_esc_back(action)
  if self._esc_cancelable then
    self:_on_click_close()
  end
  if action ~= nil then
    action.handled = true
  end
end

function M:_load_cached_wish_text()
  if CsLocalSaveDataUtil == nil or CsLocalSaveDataUtil.GetString == nil or LocalSaveID == nil then
    return ""
  end
  return tostring(CsLocalSaveDataUtil.GetString(LocalSaveID.SpringFestivalLanternWishCache, "") or "")
end

function M:_save_cached_wish_text(wish_text)
  if CsLocalSaveDataUtil == nil or CsLocalSaveDataUtil.SetString == nil or LocalSaveID == nil then
    return
  end
  CsLocalSaveDataUtil.SetString(LocalSaveID.SpringFestivalLanternWishCache, tostring(wish_text or ""))
  if CsLocalSaveDataUtil.SaveAll ~= nil then
    CsLocalSaveDataUtil.SaveAll()
  end
end

function M:_refresh_wish_state()
  local cached_wish_text = self:_load_cached_wish_text()
  local has_cached_wish = cached_wish_text ~= ""
  self._esc_cancelable = has_cached_wish
  if not is_null(self._state_cancelable) and self._state_cancelable.SetState ~= nil then
    self._state_cancelable:SetState(has_cached_wish and WISH_STATE_CANCELABLE or WISH_STATE_VIEW_ONLY)
  end
  if not is_null(self._inputfield) then
    self._inputfield.text = has_cached_wish and cached_wish_text or ""
  end
end

function M:_bind_buttons()
  if not is_null(self._btn_close) then
    self:bind_callback(self._btn_close, pack(self, M._on_click_close))
  end
  if not is_null(self._btn_cancel) then
    self:bind_callback(self._btn_cancel, pack(self, M._on_click_close))
  end
  if not is_null(self._btn_randomwish) then
    self:bind_callback(self._btn_randomwish, pack(self, M._on_click_random_wish))
  end
  if not is_null(self._btn_confirm) then
    self:bind_callback(self._btn_confirm, pack(self, M._on_click_confirm))
  end
  if not is_null(self._tog_anonymous) then
    self:bind_callback(self._tog_anonymous, pack(self, M._on_tog_anonymous_change))
  end
end

function M:_on_tog_anonymous_change(is_on)
  self:_refresh_player_name()
end

function M:_refresh_player_name()
  if is_null(self._text_playername) then
    return
  end
  local is_anonymous = false
  if not is_null(self._tog_anonymous) and self._tog_anonymous.isOn ~= nil then
    is_anonymous = self._tog_anonymous.isOn
  end
  local display_name = ""
  if is_anonymous then
    display_name = UIUtil.get_text_by_id("FestiveLantern_DefaultName")
  else
    if player_module ~= nil and player_module.get_player_name ~= nil then
      display_name = tostring(player_module:get_player_name() or "")
    end
    if display_name == nil or display_name == "" then
      display_name = UIUtil.get_text_by_id("FestiveLantern_DefaultName")
    end
  end
  UIUtil.set_text_by_id(self._text_playername, "FestiveLantern_WishPlayerName", tostring(display_name or ""))
end

function M:_on_click_close()
  EventCenter.Broadcast(EventID.LuaSpringFestivalLanternWishUserCancel)
  self:close_self()
end

function M:_on_click_random_wish()
  if is_null(self._inputfield) then
    return
  end
  if BYuanXiaoMessagePullFallbackCfg == nil then
    Logger.LogWarning("[SpringFestivalLanternMakeWishPage] BYuanXiaoMessagePullFallbackCfg not defined")
    return
  end
  local cfg_type = typeof(BYuanXiaoMessagePullFallbackCfg)
  local cfg_table = ExcelDataUtil.get_table(cfg_type)
  if cfg_table == nil then
    Logger.LogWarning("[SpringFestivalLanternMakeWishPage] YuanXiaoMessagePullFallbackCfg table is nil")
    return
  end
  local all_ids = {}
  local candidate_ids = {}
  for id, cfg in pairs(cfg_table) do
    local id_num = tonumber(id)
    local content = cfg and tostring(cfg.content or "") or ""
    if id_num ~= nil and content ~= "" then
      table.insert(all_ids, id_num)
      if not self:_is_recent_random_wish_id(id_num) then
        table.insert(candidate_ids, id_num)
      end
    end
  end
  local pool_ids = candidate_ids
  if #pool_ids <= 0 then
    pool_ids = all_ids
  end
  if #pool_ids <= 0 then
    Logger.LogWarning("[SpringFestivalLanternMakeWishPage] YuanXiaoMessagePullFallbackCfg has no valid content")
    return
  end
  local random_id = pool_ids[math.random(1, #pool_ids)]
  local cfg = cfg_table[random_id] or ExcelDataUtil.get_value(cfg_type, random_id)
  if cfg == nil then
    Logger.LogWarning(string.format("[SpringFestivalLanternMakeWishPage] random cfg not found, id=%s", tostring(random_id)))
    return
  end
  local content = tostring(cfg.content or "")
  if content == "" then
    Logger.LogWarning(string.format("[SpringFestivalLanternMakeWishPage] random cfg content empty, id=%s", tostring(random_id)))
    return
  end
  self._inputfield.text = content
  self:_record_recent_random_wish_id(random_id)
end

function M:_is_recent_random_wish_id(id)
  for _, recent_id in ipairs(self._recent_random_wish_ids) do
    if recent_id == id then
      return true
    end
  end
  return false
end

function M:_record_recent_random_wish_id(id)
  if id == nil then
    return
  end
  table.insert(self._recent_random_wish_ids, id)
  while #self._recent_random_wish_ids > RANDOM_WISH_RECENT_LIMIT do
    table.remove(self._recent_random_wish_ids, 1)
  end
end

function M:_on_click_confirm()
  if self._is_publishing then
    return
  end
  local wish_text = ""
  if not is_null(self._inputfield) and self._inputfield.text ~= nil then
    wish_text = tostring(self._inputfield.text)
  end
  local is_anonymous = false
  if not is_null(self._tog_anonymous) and self._tog_anonymous.isOn ~= nil then
    is_anonymous = self._tog_anonymous.isOn
  end
  Logger.Log(string.format("[SpringFestivalLanternMakeWishPage] Confirm clicked. is_anonymous=%s, wish=%s", tostring(is_anonymous), wish_text))
  if CsSpringFestivalLanternWishModuleUtil == nil or CsSpringFestivalLanternWishModuleUtil.RequestPublishWish == nil then
    Logger.LogWarning("[SpringFestivalLanternMakeWishPage] CsSpringFestivalLanternWishModuleUtil not ready")
    return
  end
  local uid = 0
  if CsPlayerModuleUtil ~= nil and CsPlayerModuleUtil.playerData ~= nil then
    local raw_uid = tonumber(CsPlayerModuleUtil.playerData.Uid) or tonumber(CsPlayerModuleUtil.playerData.uid) or tonumber(CsPlayerModuleUtil.playerData.PlayerId) or tonumber(CsPlayerModuleUtil.playerData.playerId) or 0
    uid = math.tointeger(raw_uid) or 0
  end
  self._is_publishing = true
  CsSpringFestivalLanternWishModuleUtil.RequestPublishWish(uid, wish_text, is_anonymous)
end

function M:_on_publish_wish_rsp(retcode)
  self._is_publishing = false
  local code = tonumber(retcode) or -1
  if code == WISH_PUBLISH_RET_SUCCESS then
    EventCenter.Broadcast(EventID.LuaSpringFestivalLanternWishUserConfirm)
    local wish_text = ""
    if not is_null(self._inputfield) and self._inputfield.text ~= nil then
      wish_text = tostring(self._inputfield.text)
    end
    if wish_text ~= "" then
      self:_save_cached_wish_text(wish_text)
    end
    self:close_self()
    return
  end
  local tips_key = WISH_PUBLISH_FAIL_TIPS[code]
  if tips_key ~= nil then
    UIUtil.show_tips_by_text_id(tips_key)
  else
    UIUtil.show_tips_by_text_id("FestiveLantern_Sensitive")
  end
  Logger.LogWarning(string.format("[SpringFestivalLanternMakeWishPage] PublishWish failed, retcode=%s", tostring(code)))
end

return M
