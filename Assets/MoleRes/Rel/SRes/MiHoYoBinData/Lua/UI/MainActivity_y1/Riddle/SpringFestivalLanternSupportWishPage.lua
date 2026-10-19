local M = G.Class("SpringFestivalLanternSupportWishPage", G.UIWindow)
local base = G.UIWindow
local RET_SUCC = 0
local RET_WISH_ALREADY_BOOSTED = 49175
local ACTIVITY_END_DIALOG_TEXT_ID = "Activity_EndDialog_Desc"
local LANTERN_TRACKING_ID = 17
local LANTERN_SUCCESS_VFX = "Effects/Player/Activity/Eff_Yuanxiaohuadeng_Success_01"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_WishSupportDialog"
  self.config.type = EUIType.Page
  self._activity_end_dialog_shown = false
end

function M:on_create()
  base.on_create(self)
  self:_bind_buttons()
end

function M:on_enable()
  base.on_enable(self)
  self._activity_end_dialog_shown = false
  self:_refresh()
  self:_lock_wish_lantern()
  self:_preload_wish_support_info()
end

function M:on_disable()
  self:_unlock_wish_lantern()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaSpringFestivalLanternWishBoostRsp, pack(self, M._on_wish_boost_rsp))
  self:add_evt_listener(EventID.OnActivityRemoved, pack(self, M._on_activity_removed))
end

function M:_on_activity_removed(activity_id)
  local module = spring_festival_activity_module
  if activity_id ~= activity_center_module:get_tracking_activity_id(LANTERN_TRACKING_ID) and activity_id ~= module:get_main_activity_id() then
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
  if self._btn_close ~= nil then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  end
end

function M:_bind_buttons()
  if not is_null(self._btn_close) then
    self:bind_callback(self._btn_close, pack(self, M._on_click_close))
  end
  if not is_null(self._btn_more) then
    self:bind_callback(self._btn_more, pack(self, M._on_click_more))
  end
  if not is_null(self._btn_confirm) then
    self:bind_callback(self._btn_confirm, pack(self, M._on_click_confirm))
  end
end

function M:_refresh()
  local extra = self:get_extra_data() or {}
  self._entity_guid = extra.entity_guid or 0
  self._sender_uid = tonumber(extra.sender_uid or extra.uid) or 0
  self._sender_name = tostring(extra.sender_name or "")
  self._wish_text = tostring(extra.wish_text or "")
  self._sub_index = extra.sub_index
  self._server_lantern_index = extra.server_lantern_index
  self._support_count = tonumber(extra.support_count) or 0
  if extra.is_boosted_by_me == nil then
    self._is_boosted_by_me = false
  else
    self._is_boosted_by_me = extra.is_boosted_by_me == true
  end
  self._wish_target_world_pos = extra.wish_target_world_pos
  self._wish_version = extra.wish_version or 0
  if not is_null(self._text_playername) then
    local display_name = self._sender_name
    if display_name == nil or display_name == "" then
      display_name = UIUtil.get_text_by_id("FestiveLantern_DefaultName")
    end
    UIUtil.set_text_by_id(self._text_playername, "FestiveLantern_WishPlayerName", tostring(display_name or ""))
  end
  if not is_null(self._text_maindesc) then
    UIUtil.set_text(self._text_maindesc, self._wish_text)
  end
  if not is_null(self._text_vxsupported) then
    UIUtil.set_text_by_id(self._text_vxsupported, "FestiveLantern_SupportNum", tostring(self._support_count))
  end
  self:_refresh_confirm_interactable()
end

function M:_refresh_confirm_interactable()
  if is_null(self._btn_confirm) then
    return
  end
  self._btn_confirm.interactable = not self._is_boosted_by_me
end

function M:_on_wish_boost_rsp(retcode)
  if is_null(self._btn_confirm) then
    return
  end
  local code = tonumber(retcode) or -1
  Logger.Log(string.format("[SpringFestivalLanternSupportWishPage] on_wish_boost_rsp retcode=%d", code))
  if code == RET_SUCC then
    self._is_boosted_by_me = true
    self._btn_confirm.interactable = false
    self._support_count = (tonumber(self._support_count) or 0) + 1
    if not is_null(self._text_vxsupported) then
      UIUtil.set_text_by_id(self._text_vxsupported, "FestiveLantern_SupportNum", tostring(self._support_count))
    end
  elseif code == RET_WISH_ALREADY_BOOSTED then
    self._is_boosted_by_me = true
    self._btn_confirm.interactable = false
  else
    self._btn_confirm.interactable = true
  end
end

function M:_preload_wish_support_info()
  UIManagerInstance:pre_open("UI/MainActivity_y1/SpringFestival/SpringFestivalWishSupportInfo")
end

function M:_play_wish_support_fly_effect()
  local from_target = self._btn_confirm and self._btn_confirm.transform or nil
  if is_null(from_target) then
    return
  end
  UIManagerInstance:open("UI/MainActivity_y1/SpringFestival/SpringFestivalWishSupportInfo", {
    from_target = from_target,
    to_world_pos = self._wish_target_world_pos,
    callback = pack(self, M._on_wish_support_fly_end)
  })
end

function M:_on_wish_support_fly_end()
  if is_null(self._wish_target_world_pos) then
    return
  end
  CsGameplayUtilitiesVfxUtil.ShowParticle(LANTERN_SUCCESS_VFX, 0, self._wish_target_world_pos, Quaternion.identity)
end

function M:_lock_wish_lantern()
  local guid = self._entity_guid or 0
  local index = self._sub_index
  if guid == 0 or index == nil or index < 0 then
    return
  end
  if CsGameplayUtilitiesLanternUtil and CsGameplayUtilitiesLanternUtil.LockForWishUI then
    CsGameplayUtilitiesLanternUtil.LockForWishUI(guid, index)
    self._wish_lock_held = true
  end
  if CsGameplayUtilitiesLanternUtil and CsGameplayUtilitiesLanternUtil.PushWishInteractCamera then
    CsGameplayUtilitiesLanternUtil.PushWishInteractCamera(guid, index)
    self._wish_camera_pushed = true
  end
end

function M:_unlock_wish_lantern()
  if self._wish_camera_pushed then
    self._wish_camera_pushed = false
    if CsGameplayUtilitiesLanternUtil and CsGameplayUtilitiesLanternUtil.PopWishInteractCamera then
      CsGameplayUtilitiesLanternUtil.PopWishInteractCamera()
    end
  end
  if not self._wish_lock_held then
    return
  end
  self._wish_lock_held = false
  local guid = self._entity_guid or 0
  local index = self._sub_index
  if guid == 0 or index == nil or index < 0 then
    return
  end
  if CsGameplayUtilitiesLanternUtil and CsGameplayUtilitiesLanternUtil.UnlockForWishUI then
    CsGameplayUtilitiesLanternUtil.UnlockForWishUI(guid, index)
  end
end

function M:_on_click_close()
  UIManagerInstance:close_page_with_dialogs_above(self)
end

function M:_on_click_more()
  if report_module == nil or report_module.open_report_page == nil then
    return
  end
  local menus = {
    {
      desc = UIUtil.get_text_by_id("BEST_FRIEND_EDIT_REPORT"),
      valid = true,
      close = true,
      call_back_action = pack(self, M._on_menu_report)
    }
  }
  local menus_data = {
    show_position = CsUIUtil.CalculateCanvasLocalPosition(self._btn_more.transform, UIManagerInstance.canvas_rect, 0.5, 1),
    menus = menus,
    state = 1
  }
  UIManagerInstance:open("UI/Social/CommonMenuDialog", menus_data)
end

function M:_on_menu_report()
  report_module:open_report_page({
    target = report_module.report_target.lantern_wish,
    target_uid = self._sender_uid,
    target_message = self._wish_text,
    content_version = self._wish_version,
    entity_guid = self._entity_guid,
    lantern_index = self._server_lantern_index or 0
  })
end

function M:_on_click_confirm()
  local entity_guid = self._entity_guid or 0
  local server_lantern_index = self._server_lantern_index
  if entity_guid == 0 or server_lantern_index == nil then
    Logger.LogWarning(string.format("[SpringFestivalLanternSupportWishPage] WishBoost skipped: entity_guid=%s, server_lantern_index=%s, sub_index=%s", tostring(entity_guid), tostring(server_lantern_index), tostring(self._sub_index)))
    return
  end
  if CsGameplayUtilitiesLanternUtil == nil or CsGameplayUtilitiesLanternUtil.RequestWishBoost == nil then
    Logger.LogWarning("[SpringFestivalLanternSupportWishPage] CsGameplayUtilitiesLanternUtil.RequestWishBoost not ready")
    return
  end
  if not is_null(self._btn_confirm) then
    self._btn_confirm.interactable = false
  end
  self:_play_wish_support_fly_effect()
  CsGameplayUtilitiesLanternUtil.RequestWishBoost(entity_guid, server_lantern_index)
  Logger.Log(string.format("[SpringFestivalLanternSupportWishPage] RequestWishBoost entity_guid=%s, server_lantern_index=%s", tostring(entity_guid), tostring(server_lantern_index)))
end

return M
