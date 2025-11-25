social_module = social_module or {}
social_module._cname = "social_module"
social_module.FriendRequestOp = {
  Accept = "FRIEND_REQUEST_OP_ACCEPT",
  Refuse = "FRIEND_REQUEST_OP_REFUSE"
}
social_module.friend_num_upper_limmt = 50
social_module.FriendChangeType = {
  FriendChangeAdd = 0,
  FriendChangeDel = 1,
  FriendChangeUpdate = 2
}
social_module.add_friend_dialog_type = {
  none = 0,
  add_friend = 1,
  add_chat = 2
}
social_module._friend_info_tbl = {}
social_module._friend_request_tbl = {}
social_module._find_player_info = nil
social_module._recommend_friend_tbl = {}
social_module._last_request_recommend_time = 0
social_module._request_recommend_cd = 10

function social_module:_init_data()
  self._friend_info_tbl = {}
  self._friend_request_tbl = {}
  self._find_player_info = nil
  self._recommend_friend_tbl = {}
  self._cur_select_friend_uid = 0
  self.player_titles = {}
  self.pre_title = ""
  self.after_title = ""
  self.cur_reject_count = 0
end

function social_module:get_friend_info_tbl()
  table.sort(self._friend_info_tbl, function(lf, rf)
    if lf.is_online ~= rf.is_online then
      return lf.is_online
    end
    local l_is_best = lf:is_best_friend()
    local r_is_best = rf:is_best_friend()
    if l_is_best ~= r_is_best then
      return l_is_best
    end
    local l_intimacy = lf:get_intimacy()
    local r_intimacy = rf:get_intimacy()
    return l_intimacy > r_intimacy
  end)
  return self._friend_info_tbl
end

function social_module:check_friend_in_list(uid)
  for _, friend_info in ipairs(self._friend_info_tbl) do
    if friend_info.uid == uid then
      return true
    end
  end
  return false
end

function social_module:get_friend_request_tbl()
  return self._friend_request_tbl
end

function social_module:remove_friend_request_tbl_by_uid(uid)
  for i, friend_request in ipairs(self._friend_request_tbl) do
    if friend_request.uid == uid then
      table.remove(self._friend_request_tbl, i)
      return
    end
  end
end

function social_module:get_find_player_info()
  return self._find_player_info
end

function social_module:clear_find_player_info()
  self._find_player_info = nil
end

function social_module:get_friend_info_by_uid(uid)
  if is_null(uid) then
    return nil
  end
  for _, friend_info in ipairs(social_module._friend_info_tbl) do
    if friend_info.uid == uid then
      return friend_info
    end
  end
  return nil
end

function social_module:is_friend(uid)
  return not is_null(social_module:get_friend_info_by_uid(uid))
end

function social_module:is_friend_and_myself(uid)
  if player_module:get_player_uid() == uid then
    return true
  end
  return not is_null(social_module:get_friend_info_by_uid(uid))
end

function social_module:set_last_online_time_by_uid(uid)
  for _, friend_info in ipairs(social_module._friend_info_tbl) do
    if friend_info.uid == uid then
      friend_info.last_online_time = TimeUtil.ServerUtcTimeSeconds
      return
    end
  end
end

function social_module:set_last_chat_time_by_uid(uid)
  for _, friend_info in ipairs(social_module._friend_info_tbl) do
    if friend_info.uid == uid then
      friend_info.last_chat_time = TimeUtil.ServerUtcTimeSeconds
      return
    end
  end
end

function social_module:_get_beirf_info(server_data)
  if server_data == nil then
    return {}
  end
  local friend_data = G.New("Social/FriendData")
  friend_data:init_with_server_data(server_data)
  return friend_data
end

function social_module:_refresh_recommend_friends(server_data)
  self._recommend_friend_tbl = {}
  local friend_info_tbl = array_to_table(server_data)
  Logger.Log("[SocialData] #friend_info_tbl" .. tostring(#friend_info_tbl))
  for _, server_firend_info in ipairs(friend_info_tbl) do
    local friend_data = G.New("Social/FriendData")
    friend_data:init_with_server_data(server_firend_info)
    table.insert(self._recommend_friend_tbl, friend_data)
  end
end

function social_module:get_recommend_friends()
  return self._recommend_friend_tbl
end

function social_module:get_best_friend_request_list()
  local best_friend_tbl = {}
  for _, friend_data in ipairs(self._friend_info_tbl) do
    if friend_data:is_best_friend() and friend_data.friend.Normal.ApplyBestUid ~= player_module:get_player_entity().guid then
      table.insert(best_friend_tbl, friend_data)
    end
  end
  return best_friend_tbl
end

function social_module:set_select_friend_uid(uid)
  self._cur_select_friend_uid = uid or 0
end

function social_module:get_select_friend_uid()
  return self._cur_select_friend_uid or 0
end

function social_module:get_player_title_data()
  local title_cfgs = LocalDataUtil.get_dic_table(typeof(CS.BPlayerTitleCfg))
  local group_to_title_cfgs = dic_to_table(LocalDataUtil.get_dic_table(typeof(CS.BPlayerTitleGroupCfg)))
  self.in_group_title_cfgs = {}
  self.group_id_to_title_cfgs = {}
  for group_id, title_cfgs in pairs(group_to_title_cfgs) do
    for _, title_cfg in pairs(title_cfgs) do
      self.in_group_title_cfgs[title_cfg.titleid] = title_cfg
    end
    self.group_id_to_title_cfgs[group_id] = title_cfgs
  end
  local unlock_title_data_list = list_to_table(CsSocialModuleUtil.UnlockTitleDataList)
  self.unlock_title_ids = {}
  for _, title_data in ipairs(unlock_title_data_list) do
    self.unlock_title_ids[title_data.TitleId] = true
  end
  self._id_to_data = {}
  for _, title_data in ipairs(unlock_title_data_list) do
    self._id_to_data[title_data.TitleId] = title_data
  end
  local temp_unlocked = {}
  local temp_locked = {}
  for _, cfg in pairs(title_cfgs) do
    if is_null(temp_unlocked[cfg.displayorder]) then
      temp_unlocked[cfg.displayorder] = {}
      temp_locked[cfg.displayorder] = {}
    end
    if self.unlock_title_ids[cfg.titleid] then
      table.insert(temp_unlocked[cfg.displayorder], cfg)
    elseif cfg.showiflock == 1 then
      table.insert(temp_locked[cfg.displayorder], cfg)
    end
  end
  for displayorder, _ in pairs(temp_unlocked) do
    if is_null(self.player_titles[displayorder]) then
      self.player_titles[displayorder] = {}
    end
    for _, cfg in ipairs(temp_unlocked[displayorder]) do
      table.insert(self.player_titles[displayorder], cfg)
    end
    for _, cfg in ipairs(temp_locked[displayorder]) do
      table.insert(self.player_titles[displayorder], cfg)
    end
  end
end

function social_module:get_title_data_by_id(id)
  return self._id_to_data[id]
end

function social_module:get_visitor_limit()
  local cfg_count = 0
  local cfg = LocalDataUtil.get_value(typeof(CS.BPlayerCfg), 28)
  if cfg and string.is_valid(cfg.paramstr) then
    local param_list = lua_str_split(cfg.paramstr, ",", true)
    cfg_count = param_list and param_list[3] or 7
  end
  return cfg_count
end

return social_module or {}
