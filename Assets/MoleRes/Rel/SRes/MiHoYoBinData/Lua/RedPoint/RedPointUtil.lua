red_point_util = red_point_util or {}
red_point_util._cname = "red_point_util"
red_point_enum = {none = 0}

function red_point_util:mobile_red_point_state()
  local red_point_to_show = RedPointType.None.value__
  local red_point_num = 0
  local red_point_type, num = red_point_util:le_mi_red_point_state()
  red_point_to_show = red_point_to_show < red_point_type and red_point_to_show or red_point_type
  red_point_type = red_point_util.diy_group_recipe_state()
  red_point_to_show = red_point_to_show < red_point_type and red_point_to_show or red_point_type
  red_point_type = red_point_util:score_system_red_point_state()
  red_point_to_show = red_point_to_show < red_point_type and red_point_to_show or red_point_type
  red_point_type, num = red_point_util:system_mail_red_point_state()
  red_point_to_show = red_point_type > red_point_to_show and red_point_to_show or red_point_type
  red_point_num = red_point_type > red_point_to_show and red_point_num or num
  red_point_type = red_point_util:memo_red_point_state()
  red_point_to_show = red_point_to_show < red_point_type and red_point_to_show or red_point_type
  red_point_type = red_point_util:appearance_red_point_state()
  red_point_to_show = red_point_to_show < red_point_type and red_point_to_show or red_point_type
  return red_point_to_show, red_point_num
end

function red_point_util:le_mi_red_point_state()
  local need_show_red_point = le_mi_achievement_module:get_le_mi_app_red_point_state()
  if need_show_red_point then
    return RedPointType.StrongRP.value__
  end
  return RedPointType.None.value__
end

function red_point_util:collection_red_point_state()
  local cfgs = collection_module:get_all_time_diary_config()
  for group_id, _ in pairs(cfgs) do
    if collection_module:get_time_diary_group_red_show_state(group_id) then
      return RedPointType.StrongRP.value__
    end
  end
  return RedPointType.None.value__
end

function red_point_util:memo_red_point_state()
  if OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateTaskBoard) and red_point_util:get_memo_red_state(memo_module.tab_type.task) == RedPointType.StrongRP.value__ then
    return RedPointType.StrongRP.value__
  end
  if OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateResidentMemorandum) and red_point_util:get_memo_red_state(memo_module.tab_type.npc) == RedPointType.StrongRP.value__ then
    return RedPointType.StrongRP.value__
  end
  return RedPointType.None.value__
end

function red_point_util:appearance_red_point_state()
  if OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateAppearanceApp) then
    if appearance_module:check_tab_type_red_point_state(appearance_module.tab_type.cloth) then
      return RedPointType.StrongRP.value__
    end
    if appearance_module:check_tab_type_red_point_state(appearance_module.tab_type.dress) then
      return RedPointType.StrongRP.value__
    end
  end
  return RedPointType.None.value__
end

function red_point_util:score_system_red_point_state()
  if not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateHouseScore) then
    return RedPointType.None.value__
  end
  local room_score_type = 1
  local can_auth_levels = list_to_table(CsScoreSystemModuleUtil.GetCanAuthScoreLst(room_score_type))
  if 0 < #can_auth_levels then
    return RedPointType.StrongRP.value__
  end
  return RedPointType.None.value__
end

function red_point_util:social_red_point_state()
  if not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateFriendSystem) then
    return RedPointType.None.value__
  end
  local request_red_point_type = RedPointUtil.friend_request_red_point_state()
  local friend_chat_red_point_state, red_num = RedPointUtil.friend_chat_red_point_state()
  if 0 < red_num then
    return RedPointType.NumRP.value__, red_num
  end
  return request_red_point_type, 0
end

function red_point_util:friend_request_red_point_state()
  if not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateFriendSystem) then
    return RedPointType.None.value__
  end
  local friend_request_op_request_list = social_module:get_friend_request_tbl()
  if 0 < #friend_request_op_request_list then
    return RedPointType.StrongRP.value__
  end
  return RedPointType.None.value__
end

function red_point_util:friend_chat_red_point_state()
  if not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateFriendSystem) then
    return RedPointType.None.value__
  end
  local red_num = 0
  local all_friend = social_module:get_friend_info_tbl()
  for _, friend_info in ipairs(all_friend) do
    if friend_info:get_read_sequence() < friend_info:get_max_sequence() then
      red_num = red_num + (friend_info:get_max_sequence() - friend_info:get_read_sequence())
    end
  end
  if red_num <= 0 then
    return RedPointType.None.value__, 0
  end
  return RedPointType.NumRP.value__, math.min(red_num, chat_module.chat_red_max_num)
end

function red_point_util:system_mail_red_point_state()
  local ret_red_num = 0
  local ret_red_point_type = RedPointType.None.value__
  for _, mail_data in pairs(mails_module._mail_datas) do
    local red_point_type, red_num = mails_module:_get_mail_red_point(mail_data)
    if red_point_type ~= RedPointType.None.value__ and ret_red_point_type == RedPointType.None.value__ then
      ret_red_point_type = red_point_type
      ret_red_num = red_num
    end
    if red_point_type ~= RedPointType.None.value__ and ret_red_point_type ~= RedPointType.None.value__ and red_point_type > ret_red_point_type then
      ret_red_point_type = red_point_type
      ret_red_num = red_num
    end
  end
  return ret_red_point_type, ret_red_num
end

function red_point_util:diy_group_recipe_state()
  if not OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateDiyHandbook) then
    return RedPointType.None.value__
  end
  if red_point_module:is_recorded(red_point_module.red_point_type.diy_group_recipe, 0) then
    return RedPointType.StrongRP.value__
  else
    return RedPointType.None.value__
  end
end

function red_point_util:get_memo_red_state(tab_type)
  local point_type = 0
  if tab_type == memo_module.tab_type.task then
    point_type = red_point_module.red_point_type.memo_tog_task
  elseif tab_type == memo_module.tab_type.npc then
    point_type = red_point_module.red_point_type.memo_tog_npc
  end
  if 0 < point_type and red_point_module:is_recorded(point_type) then
    return CsMemoManagerUtil.GetRedPointTypeByMemoTabType(tab_type).value__
  end
  return RedPointType.None.value__
end

function red_point_util:get_codex_red_point_state()
  if codex_module:has_reward_items() then
    return RedPointType.StrongRP.value__
  end
  return RedPointType.None.value__
end

function red_point_util:car_upgrade_red_point_state()
  local cur_level = CsStarSeaManagerV2Util.GetCarLevel()
  local next_level = (cur_level or 0) + 1
  local level_cfg = LocalDataUtil.get_value(typeof(CS.BStellarSeaCarUpgradeCfg), next_level)
  if is_null(level_cfg) then
    return RedPointType.None.value__
  end
  local need_num = level_cfg.costnum or 0
  local item_num = back_bag_module and back_bag_module:get_item_num(level_cfg.costitemid) or 0
  local has_enough = need_num <= item_num
  if has_enough then
    return RedPointType.WeakRP.value__
  end
  return RedPointType.None.value__
end

return red_point_util
