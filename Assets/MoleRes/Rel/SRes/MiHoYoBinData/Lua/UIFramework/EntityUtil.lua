local EntityUtil = {}

local function get_player_entity_guid()
  return CsUIUtil.GetPlayerEntityGuid()
end

local function get_entity(guid)
  return GameplayUtilities.Entities.GetEntity(guid)
end

local function get_entity_cfg_id(guid)
  return CsUIUtil.GetEntityCfgId(guid)
end

local function try_get_entity_position_by_guid(guid)
  return CsUIUtil.TryGetEntityPositionByGuid(guid)
end

local function set_entity_position_by_guid(guid, x, y, z)
  CsUIUtil.SetEntityPositionByGuid(guid, x, y, z)
end

local function set_entity_rotation_by_guid(guid, x, y, z, w)
  CsUIUtil.SetEntityRotationByGuid(guid, x, y, z, w)
end

local function set_entity_local_rotation_by_guid(guid, x, y, z, w)
  CsUIUtil.SetEntityLocalRotationByGuid(guid, x, y, z, w)
end

local function set_entity_scale_by_guid(guid, x, y, z)
  CsUIUtil.SetEntityScaleByGuid(guid, x, y, z)
end

local function try_get_entity_rotation_by_guid(guid)
  return CsUIUtil.TryGetEntityRotationByGuid(guid)
end

local function try_get_entity_local_rotation_by_guid(guid)
  return CsUIUtil.TryGetEntityLocalRotationByGuid(guid)
end

local function try_get_entity_scale_by_guid(guid)
  return CsUIUtil.TryGetEntityScaleByGuid(guid)
end

local function try_get_avatar_hand_tool_info(guid)
  return CsUIUtil.TryGetAvatarHandToolInfo(guid)
end

local function get_avatar_hand_tool_id(guid)
  return CsUIUtil.GetAvatarHandToolId(guid)
end

local function is_avatar_holding_axe(guid)
  return CsUIUtil.IsAvatarHoldingAxe(guid)
end

local function set_player_move(isActive)
  CsUIUtil.SetPlayerMove(isActive)
end

local function set_player_ability_input_active(isActive)
  CsUIUtil.SetPlayerAbilityInputActive(isActive)
end

local function is_player_run_active()
  return CsUIUtil.GetPlayerIsFastRun()
end

local function is_player_limit_run()
  return CsUIUtil.IsPlayerLimitFastRun()
end

local function is_npc(guid)
  return CsUIUtil.IsNpc(guid)
end

local function is_player(guid)
  return CsUIUtil.IsPlayer(guid)
end

local function is_valid(guid)
  return CsUIUtil.IsValid(guid)
end

local function is_player_can_shake_tree()
  return CsUIUtil.IsPlayerCanShakeTree()
end

local function create_model_preview_entity(cfg_id, callback)
  return CsUIUtil.CreateModelPreviewEntity(cfg_id, callback)
end

local function destroy_entity_by_guid(guid)
  return CsUIUtil.DestroyEntityByGuid(guid)
end

local function run_ability_with_callback(ability_name, caller_guid, target_guid, callback)
  return CsUIUtil.RunAbilityWithCallback(ability_name, caller_guid, target_guid, callback)
end

local function stop_ability(guid, layer, callback)
  return CsUIUtil.StopAbility(guid, layer, callback)
end

local function can_activate_ui_ability(ability_name)
  return CsUIUtil.CanActivateUIAbility(ability_name)
end

local function start_ui_ability(ability_name)
  CsUIUtil.StartUIAbility(ability_name)
end

local function stop_ui_ability(ability_name)
  CsUIUtil.StopUIAbility(ability_name)
end

local function create_virtual_npc(cfg_id, init_pos, init_rotation, on_main_game_obj_init, on_atl_init)
  init_pos = init_pos or Vector3.zero
  init_rotation = init_rotation or Quaternion.identity
  return CsUIUtil.CreateVirtualNpc(cfg_id, init_pos, init_rotation, on_main_game_obj_init, on_atl_init)
end

local function play_atl_with_tag(guid, tag, on_end)
  CsUIUtil.PlayATLWithTag(guid, tag, on_end)
end

local function hide_or_show_avatar(guid, isActive, lerpTime)
  CsUIUtil.HideOrShowAvatar(guid, isActive, lerpTime)
end

local function avatar_lerp_move_cam(guid, callback)
  CsUIUtil.AvatarLerpMoveCam(guid, callback)
end

local function hide_or_show_all_avatar(isActive, lerpTime)
  CsUIUtil.HideOrShowAllAvatar(isActive, lerpTime)
end

local function stop_avavar_move(guid)
  CsUIUtil.StopAvatarMove(guid)
end

local function get_display_name_by_guid(guid)
  return CsUIUtil.GetEntityDisplayNameByGuid(guid)
end

local function get_plant_info_by_guid(guid)
  return CsUIUtil.GetPlantInfoByCropStatPanelGuid(guid)
end

local function get_cfg_id_by_guid(guid)
  return CsUIUtil.GetEntityConfigIdByGuid(guid)
end

local function get_entity_name(guid)
  return CsUIUtil.GetEntityName(guid)
end

local function get_all_player_entity_guids()
  return CsUIUtil.GetAllPlayerEntityGuid()
end

local function get_all_npc_entity_guids()
  return CsUIUtil.GetAllNpcEntityGuid()
end

local function get_avatar_server_data_by_guid(guid)
  return CsUIUtil.GetAvatarServerDataByGuid(guid)
end

local function turn_avatar(guid, target, withLerpAnim, speed, callback)
  CsUIUtil.TurnAvatar(guid, target, withLerpAnim, speed, callback)
end

local function set_main_object_active(guid, is_active, is_recursive)
  CsUIUtil.SetMainObjectActiveByGuid(guid, is_active, is_recursive)
end

local function broadcast_entity_event(event_tag, custom_data)
  CsUIUtil.BroadcastEntityEvent(event_tag, custom_data)
end

local function send_entity_event(guid, event_tag, instigator, target, custom_data)
  CsUIUtil.SendEntityEvent(guid, event_tag, instigator, target, custom_data)
end

local function get_all_equip_clothe_guids_by_guid(guid)
  return list_to_table(CsUIUtil.GetAllEquipClotheGuidsByGuid(guid))
end

local function get_entities_by_config_id(cfg_id)
  return CsUIUtil.GetEntityByConfigId(cfg_id)
end

local function show_entity_bubble(guid, content, duration, distance)
  CsUIUtil.ShowEntityBubble(guid, content, duration, distance)
end

local function pause_npc_ai(guid)
  CsUIUtil.PauseNpcAI(guid)
end

local function resume_npc_ai(guid)
  CsUIUtil.ResumeNpcAI(guid)
end

local function get_entity_scene_type_by_guid(guid)
  return CsUIUtil.GetEntitySceneTypeByGuid(guid)
end

local function get_npc_guid_by_config_id(npc_id)
  return CsUIUtil.GetNpcGuidByConfigId(npc_id)
end

local function create_perform_player(use_real_player, callback)
  return CsUIUtil.CreatePerformPlayer(use_real_player, callback)
end

local function put_on_avatar_by_real_player(guid)
  return CsUIUtil.PutOnAvatarByRealPlayer(guid)
end

local function get_player_entity_by_uid(uid)
  return CsUIUtil.GetPlayerEntityByUid(uid)
end

EntityUtil.get_player_entity_guid = get_player_entity_guid
EntityUtil.get_entity = get_entity
EntityUtil.get_entity_cfg_id = get_entity_cfg_id
EntityUtil.get_entities_by_config_id = get_entities_by_config_id
EntityUtil.try_get_entity_position_by_guid = try_get_entity_position_by_guid
EntityUtil.try_get_entity_scale_by_guid = try_get_entity_scale_by_guid
EntityUtil.try_get_entity_rotation_by_guid = try_get_entity_rotation_by_guid
EntityUtil.try_get_entity_local_rotation_by_guid = try_get_entity_local_rotation_by_guid
EntityUtil.set_entity_local_rotation_by_guid = set_entity_local_rotation_by_guid
EntityUtil.set_entity_rotation_by_guid = set_entity_rotation_by_guid
EntityUtil.set_entity_position_by_guid = set_entity_position_by_guid
EntityUtil.set_entity_scale_by_guid = set_entity_scale_by_guid
EntityUtil.try_get_avatar_hand_tool_info = try_get_avatar_hand_tool_info
EntityUtil.get_avatar_hand_tool_id = get_avatar_hand_tool_id
EntityUtil.is_avatar_holding_axe = is_avatar_holding_axe
EntityUtil.set_player_move = set_player_move
EntityUtil.set_player_ability_input_active = set_player_ability_input_active
EntityUtil.is_player_run_active = is_player_run_active
EntityUtil.is_player_limit_run = is_player_limit_run
EntityUtil.is_player_can_shake_tree = is_player_can_shake_tree
EntityUtil.stop_avavar_move = stop_avavar_move
EntityUtil.create_model_preview_entity = create_model_preview_entity
EntityUtil.destroy_entity_by_guid = destroy_entity_by_guid
EntityUtil.turn_avatar = turn_avatar
EntityUtil.pause_npc_ai = pause_npc_ai
EntityUtil.resume_npc_ai = resume_npc_ai
EntityUtil.is_npc = is_npc
EntityUtil.is_player = is_player
EntityUtil.is_valid = is_valid
EntityUtil.hide_or_show_avatar = hide_or_show_avatar
EntityUtil.avatar_lerp_move_cam = avatar_lerp_move_cam
EntityUtil.hide_or_show_all_avatar = hide_or_show_all_avatar
EntityUtil.create_virtual_npc = create_virtual_npc
EntityUtil.play_atl_with_tag = play_atl_with_tag
EntityUtil.get_entity_name = get_entity_name
EntityUtil.get_all_player_entity_guids = get_all_player_entity_guids
EntityUtil.get_all_npc_entity_guids = get_all_npc_entity_guids
EntityUtil.get_avatar_server_data_by_guid = get_avatar_server_data_by_guid
EntityUtil.get_plant_info_by_guid = get_plant_info_by_guid
EntityUtil.get_display_name_by_guid = get_display_name_by_guid
EntityUtil.get_cfg_id_by_guid = get_cfg_id_by_guid
EntityUtil.set_main_object_active = set_main_object_active
EntityUtil.broadcast_entity_event = broadcast_entity_event
EntityUtil.send_entity_event = send_entity_event
EntityUtil.get_all_equip_clothe_guids_by_guid = get_all_equip_clothe_guids_by_guid
EntityUtil.run_ability_with_callback = run_ability_with_callback
EntityUtil.stop_ability = stop_ability
EntityUtil.can_activate_ui_ability = can_activate_ui_ability
EntityUtil.start_ui_ability = start_ui_ability
EntityUtil.stop_ui_ability = stop_ui_ability
EntityUtil.show_entity_bubble = show_entity_bubble
EntityUtil.get_entity_scene_type_by_guid = get_entity_scene_type_by_guid
EntityUtil.get_npc_guid_by_config_id = get_npc_guid_by_config_id
EntityUtil.create_perform_player = create_perform_player
EntityUtil.put_on_avatar_by_real_player = put_on_avatar_by_real_player
EntityUtil.get_player_entity_by_uid = get_player_entity_by_uid
return EntityUtil
