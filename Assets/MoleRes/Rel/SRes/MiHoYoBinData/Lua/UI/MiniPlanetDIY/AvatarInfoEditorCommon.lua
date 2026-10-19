avatar_info_editor_module = avatar_info_editor_module or {}
avatar_info_editor_module.entity_item_type = {decoration = 1, action = 2}

function avatar_info_editor_module.to_placement_config_id(config_id)
  if config_id == nil or config_id <= 0 then
    return config_id or 0
  end
  return codex_module:get_flower_bloom_id(config_id) or config_id
end

function avatar_info_editor_module.is_diy_unlocked()
  return OpenStateUtil.GetStateIsOpen(OpenStateType.OpenStateLittlePlanet)
end

function avatar_info_editor_module.is_diy_unlock_seen()
  return red_point_module:is_recorded(red_point_module.red_point_type.little_planet_diy_unlock)
end

function avatar_info_editor_module.record_diy_unlock_seen()
  if not avatar_info_editor_module.is_diy_unlocked() then
    return
  end
  if avatar_info_editor_module.is_diy_unlock_seen() then
    return
  end
  red_point_module:record(red_point_module.red_point_type.little_planet_diy_unlock)
end

function avatar_info_editor_module.should_show_diy_unlock_red_point()
  return avatar_info_editor_module.is_diy_unlocked() and not avatar_info_editor_module.is_diy_unlock_seen()
end

function avatar_info_editor_module.is_diy_blocked_by_emergency_switch()
  return CsGameplayUtilitiesEmergencySwitchUtil.IsSwitchOnByType(EmergencySwitchType.EmergencySwitchCloseSmallPlanetDiy)
end

function avatar_info_editor_module.try_block_diy_with_tip()
  if not avatar_info_editor_module.is_diy_blocked_by_emergency_switch() then
    return false
  end
  CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
  return true
end

return avatar_info_editor_module
