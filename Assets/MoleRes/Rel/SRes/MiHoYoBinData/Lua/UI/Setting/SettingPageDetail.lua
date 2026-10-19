local M = {}
local DETAIL_STATE_DEFAULT = 0
local DETAIL_STATE_TIPS = 1
local DETAIL_STATE_GROUP_PATH = "state_Group"
local DETAIL_BUTTON_PATH = "Name/Btn_Help_Dark"

function M:_bind_setting_detail_button(item_go, setting_entry)
  if is_null(item_go) or setting_entry == nil then
    return
  end
  local state_group = UIUtil.find_ui_state_group(item_go.transform, DETAIL_STATE_GROUP_PATH)
  if is_null(state_group) then
    Logger.LogWarning("[SettingPageDetail] Detail state group not found, path=" .. DETAIL_STATE_GROUP_PATH)
    return
  end
  local detail_data = setting_entry.detailData
  state_group:SetState(detail_data ~= nil and DETAIL_STATE_TIPS or DETAIL_STATE_DEFAULT)
  if detail_data == nil then
    return
  end
  local detail_button = UIUtil.find_button_ex(item_go.transform, DETAIL_BUTTON_PATH)
  if is_null(detail_button) then
    Logger.LogWarning("[SettingPageDetail] Detail button not found, path=" .. DETAIL_BUTTON_PATH)
    return
  end
  self:bind_callback(detail_button, function()
    self:_open_setting_detail(setting_entry, detail_button.transform)
  end)
end

function M:_open_setting_detail(setting_entry, target_trans)
  if setting_entry == nil then
    return
  end
  local detail_data = setting_entry.detailData
  if detail_data == nil then
    return
  end
  if detail_data.detailType == CS.miHoYo.HYG.ESettingDetailType.Tips then
    UIManagerInstance:open("UI/Setting/SettingTipsDialog", {
      detail_data = detail_data,
      fallback_title = setting_entry.descTextMapContent,
      target_trans = target_trans
    })
    return
  end
  if detail_data.detailType == CS.miHoYo.HYG.ESettingDetailType.Dialog then
    UIManagerInstance:open("UI/Setting/SettingDisplayEffectDemonstrationDialog", {
      detail_data = detail_data,
      fallback_title = setting_entry.descTextMapContent
    })
    return
  end
  Logger.LogWarning("[SettingPageDetail] Unsupported detail type: " .. tostring(detail_data.detailType))
end

return M
