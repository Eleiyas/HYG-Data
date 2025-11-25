star_friend_social_module = star_friend_social_module or {}

function star_friend_social_module:_get_all_friend_info()
  local result = {}
  local friend_info_tbl = social_module:get_friend_info_tbl()
  if friend_info_tbl == nil then
    return {}
  end
  for _, info in pairs(friend_info_tbl) do
    result[info.uid] = info
  end
  return result
end

function star_friend_social_module:get_group_atl_cfg()
  self.group_atl_cfg = list_to_table(LocalDataUtil.get_value(typeof(CS.BFriendActionGroupCfg), 1))
  self.action_cfgs = LocalDataUtil.get_table(typeof(CS.BFriendActionCfg))
end

function star_friend_social_module:set_cur_friend_uid(uid)
  self.cur_friend_uid = uid
end

return star_friend_social_module
