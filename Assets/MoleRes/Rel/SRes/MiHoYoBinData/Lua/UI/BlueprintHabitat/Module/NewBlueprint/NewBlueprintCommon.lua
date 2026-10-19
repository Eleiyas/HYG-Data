new_blueprint_module = new_blueprint_module or {}
new_blueprint_module.INFO_TYPE_STATE = {
  official = 0,
  custom_legacy = 1,
  custom_detail = 2,
  copied_detail = 3,
  custom_repost = 4,
  shared_import = 5,
  under_review = 7
}
new_blueprint_module.INFO_PAGE_SOURCE = {normal = 0, little_corner_post = 1}
new_blueprint_module.BLUEPRINT_DOMAIN = {
  official = 0,
  custom = 1,
  copied = 2,
  shared = 3
}

function new_blueprint_module:get_tracking_source_by_domain(domain)
  local domain_define = self.BLUEPRINT_DOMAIN
  if domain == domain_define.official then
    return tracking_module.data_source_type.blueprint
  end
  if domain == domain_define.custom or domain == domain_define.copied then
    return tracking_module.data_source_type.custom_blueprint
  end
  return nil
end

new_blueprint_module.SELECT_MODE_STATE = {delete = 0, post = 1}
new_blueprint_module.TAB_STATE = {
  official = 0,
  custom = 1,
  copied = 2
}

function new_blueprint_module:is_blueprint_code_blocked()
  return CsGameplayUtilitiesEmergencySwitchUtil.IsSwitchOnByType(EmergencySwitchType.EmergencySwitchCloseBlueprintGenerate)
end

function new_blueprint_module:try_block_blueprint_share_with_tip()
  if not self:is_blueprint_code_blocked() then
    return false
  end
  CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
  return true
end

function new_blueprint_module:try_block_blueprint_import_with_tip()
  if not self:is_blueprint_code_blocked() then
    return false
  end
  CsGameplayUtilitiesEmergencySwitchUtil.ShowEmergencySwitchTip()
  return true
end

return new_blueprint_module
