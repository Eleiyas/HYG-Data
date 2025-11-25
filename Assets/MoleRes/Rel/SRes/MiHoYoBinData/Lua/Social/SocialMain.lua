social_module = social_module or {}

function social_module:add_event()
  social_module:remove_event()
  lua_event_module:add_sub_listener(lua_event_module.event_type.social_apply_visite, self._cname, pack(self, social_module._on_social_apply_visite))
  lua_event_module:add_sub_listener(lua_event_module.event_type.social_player_visite, self._cname, pack(self, social_module._on_social_player_visite))
  lua_event_module:add_sub_listener(lua_event_module.event_type.social_invite_visite, self._cname, pack(self, social_module._on_social_invite_visite))
  lua_event_module:add_sub_listener(lua_event_module.event_type.player_enter_world, self._cname, pack(self, social_module._on_player_enter_world))
  self._events = {}
  self._events[EventID.OnInviteGatherNotify] = pack(self, social_module._on_invite_gather_notify)
  self._events[EventID.OnInviteReplyNotify] = pack(self, social_module._on_invite_reply_notify)
  self._events[EventID.OnCancelGatherNotify] = pack(self, social_module._on_cancel_gather_notify)
  self._events[EventID.OnLeaveGatherNotify] = pack(self, social_module._on_leave_gather_notify)
  self._events[EventID.LuaShowOnlineItemTip] = pack(self, social_module._on_show_online_item_tip)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function social_module:remove_event()
  if self._events == nil then
    return
  end
  lua_event_module:remove_listener(lua_event_module.event_type.social_apply_visite, self._cname)
  lua_event_module:remove_listener(lua_event_module.event_type.social_invite_visite, self._cname)
  lua_event_module:remove_listener(lua_event_module.event_type.player_enter_world, self._cname)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function social_module:_on_social_apply_visite(from_uid, avatar_id, is_start_multi_world)
  if is_start_multi_world == nil or not is_start_multi_world then
    hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.social_confirm_popup, {
      uid = from_uid,
      avatar_id = avatar_id,
      interact_type = social_module.social_multi_play_visite_interact_type.apply
    })
  else
    hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.social_confirm_popup, {
      uid = from_uid,
      avatar_id = avatar_id,
      interact_type = social_module.social_multi_play_visite_interact_type.first_query,
      source = "player_visit",
      callback = function(from_uid, accept)
        if is_null(from_uid) then
          Logger.LogWarning("PlayerVisitMain: apply visit callback - from_uid is null")
          return
        end
        CsPlayerVisitModuleUtil.SocialPlayerGotoSelfWorldoperateReq(from_uid, accept)
      end
    })
  end
end

function social_module:_on_social_player_visite(from_uid, from_player_name, avatar_id)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.social_confirm_popup, {
    uid = from_uid,
    avatar_id = avatar_id,
    player_name = from_player_name,
    interact_type = social_module.social_multi_play_visite_interact_type.apply
  })
end

function social_module:_on_social_invite_visite(from_uid, avatar_id)
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.social_confirm_popup, {
    uid = from_uid,
    avatar_id = avatar_id,
    interact_type = social_module.social_multi_play_visite_interact_type.invite
  })
end

function social_module:_on_player_enter_world(uid)
  UIManagerInstance:open("UI/Social/SocialMultiPlayerTipsDialog", {uid = uid})
end

function social_module:_on_invite_gather_notify(uid)
  UIManagerInstance:open("UI/Social/GatherInviteConfirmDialog", {uid = uid})
end

function social_module:_on_invite_reply_notify(visitor_info)
  if visitor_info.IsInGather then
    UIUtil.show_tips_by_text_id("Visit_InviteHarvest_Tips2", visitor_info.NickName)
  else
    UIUtil.show_tips_by_text_id("Visit_InviteHarvest_Tips2.1", visitor_info.NickName)
  end
end

function social_module:_on_cancel_gather_notify(uid)
  local owner_info = CsSocialModuleUtil.GetVisitorInfoByUid(uid)
  UIUtil.show_tips_by_text_id("Visit_CancelledPermission_Tips1", owner_info.NickName)
end

function social_module:_on_leave_gather_notify(visitor_info)
  UIUtil.show_tips_by_text_id("Visit_CancelledPermission_Tips2", visitor_info.NickName)
end

function social_module:_on_show_online_item_tip(data)
  if not CsCreatePlayerManagerUtil.IsNull() and CsCreatePlayerManagerUtil.creatingPlayer then
    return
  end
  if is_null(data) then
    return
  end
  if item_module:filter_item_tip_by_data(data) then
    return
  end
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.online_get_item_tip, data)
end

return social_module
