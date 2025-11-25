social_module = social_module or {}
social_module._cname = "social_module"

function social_module:register_cmd_handler()
  social_module:un_register_cmd_handler()
  self._tbl_rep = {}
  self._tbl_rep[AddFriendRsp] = pack(self, social_module._handle_add_friend_rsp)
  self._tbl_rep[FriendRequestOpRsp] = pack(self, social_module._handle_friend_request_op_rsp)
  self._tbl_rep[FriendListNotify] = pack(self, social_module._handle_friend_list_notify)
  self._tbl_rep[FriendChangeNotify] = pack(self, social_module._handle_friend_change_notify)
  self._tbl_rep[FriendRequestListNotify] = pack(self, social_module._handle_friend_request_list_notify)
  self._tbl_rep[FriendRequestChangeNotify] = pack(self, social_module._handle_friend_request_change_notify)
  self._tbl_rep[DelFriendRsp] = pack(self, social_module._handle_del_friend_rsp)
  self._tbl_rep[FindPlayerRsp] = pack(self, social_module._handle_find_player_rsp)
  self._tbl_rep[FriendRecommendRsp] = pack(self, social_module._handle_friend_recommend_rsp)
  self._tbl_rep[FriendVisitResultNotify] = pack(self, social_module._handle_friend_visit_result_notify)
  self._tbl_rep[FriendVisitNotify] = pack(self, social_module._handle_friend_visit_notify)
  self._tbl_rep[FriendOperateRsp] = pack(self, social_module._handle_friend_operate_rsp)
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:register_cmd_handler(k, v)
  end
end

function social_module:un_register_cmd_handler()
  if self._tbl_rep == nil then
    return
  end
  for k, v in pairs(self._tbl_rep) do
    NetHandlerIns:unregister_cmd_handler(k)
  end
end

function social_module:add_friend_req(uid)
  local data = {TargetUid = uid}
  NetHandlerIns:send_data(AddFriendReq, data)
  print("[social_net]add_friend_req uid:" .. tostring(uid))
end

function social_module:del_friend_req(uid)
  local data = {TargetUid = uid}
  NetHandlerIns:send_data(DelFriendReq, data)
  print("[social_net]del_friend_req uid:" .. tostring(uid))
end

function social_module:friend_request_op_req(uid, friend_request_op)
  local data = {
    TargetUid = uid,
    Op = friend_request_op.value__
  }
  print("[social_net]friend_request_op_req uid:" .. tostring(uid) .. " op:" .. tostring(friend_request_op) .. "opvalue:" .. tostring(friend_request_op.value__))
  NetHandlerIns:send_data(FriendRequestOpReq, data)
end

function social_module:find_player_req(uid)
  local data = {Uid = uid}
  NetHandlerIns:send_data(FindPlayerReq, data)
  print("[social_net]find_player_req uid:" .. tostring(uid))
end

function social_module:friend_relation_change_req(uid, relation)
  local data = {TargetUid = uid, RelationChange = relation}
  print("[social_net]friend_relation_change_req uid:" .. tostring(uid) .. " RelationChange:" .. tostring(relation))
  NetHandlerIns:send_data(FriendOperateReq, data)
end

function social_module:friend_remark_name_change_req(uid, nick_name)
  local data = {TargetUid = uid, RemarkName = nick_name}
  print("[social_net]friend_remark_name_change_req uid:" .. tostring(uid) .. " nick_name:" .. tostring(nick_name))
  NetHandlerIns:send_data(FriendOperateReq, data)
end

function social_module:apply_visit(uid)
  local data = {TargetUid = uid, ApplyToVisit = true}
  NetHandlerIns:send_data(FriendOperateReq, data)
  Logger.Log("[SocialNet] ApplyVisit UID:" .. tostring(uid))
end

function social_module:invite_visit(uid)
  local data = {TargetUid = uid, InviteToVisit = true}
  NetHandlerIns:send_data(FriendOperateReq, data)
  Logger.Log("[SocialNet] InviteVisit UID:" .. tostring(uid))
end

function social_module:accept_apply(uid)
  local data = {TargetUid = uid, AcceptVisitApply = true}
  NetHandlerIns:send_data(FriendOperateReq, data)
  Logger.Log("[SocialNet] AcceptVisit UID:" .. tostring(uid))
end

function social_module:reject_apply(uid)
  local data = {TargetUid = uid, RejectVisitApply = true}
  NetHandlerIns:send_data(FriendOperateReq, data)
  Logger.Log("[SocialNet] RejectVisit UID:" .. tostring(uid))
end

function social_module:accept_invite(uid)
  local data = {TargetUid = uid, AcceptVisitInvite = true}
  NetHandlerIns:send_data(FriendOperateReq, data)
  Logger.Log("[SocialNet] AcceptInvite UID:" .. tostring(uid))
end

function social_module:reject_invite(uid)
  local data = {TargetUid = uid, RejectVisitInvite = true}
  NetHandlerIns:send_data(FriendOperateReq, data)
  Logger.Log("[SocialNet] RejectInvite UID:" .. tostring(uid))
end

function social_module:friend_recommend_req()
  NetHandlerIns:send_data(FriendRecommendReq, {})
  Logger.Log("[SocialNet] FriendRecommendReq")
end

function social_module:_handle_add_friend_rsp(data)
  if data == nil then
    return
  end
  if data.Retcode == 7001 then
    UIUtil.show_tips_by_text_id("Friend_Full_Text")
    return
  elseif data.Retcode == 7007 then
    UIUtil.show_tips_by_text_id("Friend_Full_Text_otherside")
    return
  end
  lua_event_module:send_event(lua_event_module.event_type.on_send_add_friend_succ)
  Logger.Log("[social_net]_handle_add_friend_rsp:" .. table.serialize(data))
end

function social_module:_handle_friend_request_op_rsp(data)
  if data == nil then
    return
  end
  if data.Retcode == 7001 then
    UIUtil.show_tips_by_text_id("Friend_Full_Text")
  elseif data.Retcode == 7007 then
    UIUtil.show_tips_by_text_id("Friend_Full_Text_otherside")
  end
end

function social_module:_handle_friend_list_notify(server_data)
  if server_data == nil then
    return
  end
  EventCenter.Broadcast(EventID.OnFriendListNotify, server_data)
  self._friend_info_tbl = {}
  for _, v in ipairs(array_to_table(server_data.BriefList)) do
    table.insert(self._friend_info_tbl, social_module:_get_beirf_info(v))
  end
  lua_event_module:send_event(lua_event_module.event_type.on_friend_infos_update)
  print("[social_net]_handle_friend_list_notify:" .. table.serialize(self._friend_info_tbl))
end

function social_module:_handle_friend_change_notify(server_data)
  if server_data == nil then
    return
  end
  EventCenter.Broadcast(EventID.OnFriendChangeNotify, server_data)
  local data = {
    uid = server_data.Uid,
    change_type = server_data.ChangeType.value__,
    brief = social_module:_get_beirf_info(server_data.Brief)
  }
  if data.change_type == social_module.FriendChangeType.FriendChangeAdd then
    print("[social_net]_handle_friend_change_notify FriendChangeAdd")
    local is_repeated = false
    for _, friend_info in ipairs(self._friend_info_tbl) do
      if friend_info.uid == data.uid then
        is_repeated = true
        break
      end
    end
    if not is_repeated then
      table.insert(self._friend_info_tbl, data.brief)
    end
  elseif data.change_type == social_module.FriendChangeType.FriendChangeDel then
    print("[social_net]_handle_friend_change_notify FriendChangeDel")
    for index, friend_info in ipairs(self._friend_info_tbl) do
      if friend_info.uid == data.uid then
        table.remove(self._friend_info_tbl, index)
        break
      end
    end
  elseif data.change_type == social_module.FriendChangeType.FriendChangeUpdate then
    print("[social_net]_handle_friend_change_notify FriendChangeUpdate")
    for index, friend_info in ipairs(self._friend_info_tbl) do
      if friend_info.uid == data.brief.uid then
        self._friend_info_tbl[index] = data.brief
        break
      end
    end
  end
  lua_event_module:send_event(lua_event_module.event_type.on_friend_infos_update)
  print("[social_net]_handle_friend_change_notify:" .. table.serialize(data) .. " changetype:" .. table.serialize(data.change_type))
end

function social_module:_handle_friend_request_list_notify(server_data)
  if server_data == nil then
    return
  end
  local brief_list = {}
  for _, v in ipairs(array_to_table(server_data.BriefList)) do
    table.insert(brief_list, social_module:_get_beirf_info(v))
  end
  local data = {brief_list = brief_list}
  self._friend_request_tbl = {}
  for _, brief_info in ipairs(data.brief_list) do
    table.insert(self._friend_request_tbl, brief_info)
    SocialSaveData.AddFriendRequestRedPointUID(brief_info.uid)
  end
  lua_event_module:send_event(lua_event_module.event_type.on_friend_request_infos_update)
  print("[social_net]_handle_friend_request_list_notify:" .. table.serialize(data))
end

function social_module:_handle_friend_request_change_notify(server_data)
  if server_data == nil then
    return
  end
  local data = {
    uid = server_data.Uid,
    change_type = server_data.ChangeType,
    brief = self:_get_beirf_info(server_data.Brief)
  }
  if data.change_type == CS.Proto.FriendRequestChangeType.FriendRequestChangeAdd then
    table.insert(self._friend_request_tbl, data.brief)
    lua_event_module:send_event(lua_event_module.event_type.on_new_friend_request)
    SocialSaveData.AddFriendRequestRedPointUID(data.brief.uid)
    AudioManagerIns:post_eventnew(WEvent.Play_ui_fb_friend_newMessage, nil, nil, nil, nil)
  elseif data.change_type == CS.Proto.FriendRequestChangeType.FriendRequestChangeAcceptDel or data.change_type == CS.Proto.FriendRequestChangeType.FriendRequestChangeRejectDel then
    for index, friend_info in ipairs(self._friend_request_tbl) do
      if friend_info.uid == data.uid then
        table.remove(self._friend_request_tbl, index)
        break
      end
    end
    SocialSaveData.DeleteFriendRequestRedPointUID(data.uid)
  elseif data.change_type == CS.Proto.FriendRequestChangeType.FriendRequestChangeUpdate then
    for index, friend_info in ipairs(self._friend_request_tbl) do
      if friend_info.uid == data.uid then
        self._friend_request_tbl[index] = data.brief
      end
    end
  end
  lua_event_module:send_event(lua_event_module.event_type.on_friend_request_infos_update)
  print("[social_net]_handle_friend_request_change_notify:" .. table.serialize(data))
end

function social_module:_handle_del_friend_rsp(data)
end

function social_module:_handle_find_player_rsp(server_data)
  if server_data == nil or server_data.Brief == nil then
    UIUtil.show_tips_by_text_id("SOCIAL_CAN_NOT_FOUND_PLAYER")
    return
  end
  self._find_player_info = self:_get_beirf_info(server_data.Brief)
  Logger.Log("socialNet Test Server FindPlayerInfo.Uid" .. tostring(server_data.Brief.Uid) .. " self._find_player_info.uid:" .. tostring(self._find_player_info.uid))
  lua_event_module:send_event(lua_event_module.event_type.on_find_player_rsp)
  print("[social_net]_handle_find_player_rsp:" .. table.serialize(self._find_player_info))
  if is_null(self._find_player_info) then
    UIUtil.show_tips_by_text_id("SOCIAL_CAN_NOT_FOUND_PLAYER")
  end
end

function social_module:_handle_friend_recommend_rsp(server_data)
  if server_data.Retcode > 0 then
    local ret_str = CsUIUtil.GetEnumStr(typeof(RetCode), server_data.Retcode)
    UIUtil.show_tips_by_text_id(ret_str)
    return
  end
  self:_refresh_recommend_friends(server_data.BriefList)
  Logger.Log("[SocialNet] RecommendFriend" .. tostring(table.serialize(self._recommend_friend_tbl)))
  lua_event_module:send_event(lua_event_module.event_type.on_friend_recommend_infos_update)
end

function social_module:_handle_friend_visit_notify(server_data)
  Logger.Log("[SocialNet HandleFriendVisitNotify:" .. tostring(table.serialize(server_data)))
  if server_data.Apply then
    lua_event_module:send_event(lua_event_module.event_type.social_apply_visite, server_data.FromUid, server_data.AvatarId, server_data.IsStartMultiWorld)
  end
  if server_data.Invite then
    lua_event_module:send_event(lua_event_module.event_type.social_invite_visite, server_data.FromUid, server_data.AvatarId)
  end
end

function social_module:_handle_player_visit_notify(server_data)
  Logger.Log("[SocialNet HandleFriendVisitNotify:" .. tostring(table.serialize(server_data)))
  lua_event_module:send_event(lua_event_module.event_type.social_player_visite, server_data.FromUid, server_data.FromPlayerName, server_data.AvatarId)
end

function social_module:_handle_friend_visit_result_notify(server_data)
  Logger.Log("[SocialNet] HandleFriendResultVisitNotify:" .. tostring(server_data.Apply) .. "   " .. tostring(server_data.Invite))
  local uid = server_data.TargetUid
  local friend_info = social_module:get_friend_info_by_uid(uid)
  local star_friend_info = CsFriendPlanetManagerUtil.GetSocialPlayerInfo(uid)
  local nick_name = friend_info and friend_info:get_nick_name_with_remark_name() or star_friend_info and star_friend_info.Nickname
  if server_data.Apply == true then
    if server_data.Reject then
      UIUtil.show_tips_by_text_id("ApplyReject", nick_name)
    end
    if server_data.Timeout then
      UIUtil.show_tips_by_text_id("social_apply_timeout_faile", nick_name)
    end
  elseif server_data.Invite == true then
    if server_data.Reject then
      UIUtil.show_tips_by_text_id("InviteReject", nick_name)
    end
    if server_data.Timeout then
      UIUtil.show_tips_by_text_id("social_apply_timeout_faile", nick_name)
    end
  end
end

function social_module:_handle_friend_operate_rsp(server_data)
  if server_data.Retcode == 9255 then
    UIUtil.show_tips_by_text_id("Visit_full")
  end
  if server_data.Retcode == 9259 then
    UIUtil.show_tips_by_text_id("Visit_full_host")
  end
end

return social_module or {}
