local M = G.Class("SuitPreviewController")
local ROTATION_SENSITIVITY = 0.2
local DRAG_ANGLE_THRESHOLD = 60
local DEFAULT_IDLE_TAG = "ATLState_Avatar_BasicPerform_IdleAction"

function M:__ctor(player_root)
  self._player_root = player_root
  self:_sync_rotation_baseline()
  self._desired_visible = true
  self._pending_pose_display_tag = nil
  self._pending_pose_idle_tag = nil
  self:_reset_drag()
end

function M:_reset_drag()
  self._cur_pos = Vector2.zero
  self._last_pos = Vector2.zero
  self._delta_pos = Vector2.zero
  self._drag_dis = 0
end

function M:show_by_suit_id(suit_id, style_color_list, sync_player, is_create_preview)
  local mapping = LocalDataUtil.get_value(typeof(CS.miHoYo.HYG.ExcelData.SetIdToOutfitIdMappingCfg), suit_id)
  if is_null(mapping) then
    return
  end
  local cloth_ids = list_to_table(mapping.outfitIdList)
  self:show_by_cloth_ids(cloth_ids, style_color_list, sync_player, is_create_preview)
end

function M:show_by_cloth_ids(cloth_ids, style_color_list, sync_player, is_create_preview)
  self._sync_player = sync_player == nil and true or sync_player
  if is_create_preview == nil then
    is_create_preview = false
  end
  self._is_create_preview = is_create_preview
  self._pending_cloth_ids = cloth_ids
  self._pending_style_color_list = style_color_list
  self._desired_visible = true
  self:_dress()
end

function M:show_by_tool_and_skin(tool_cfg_id, skin_cfg_id)
  CsSuitPreviewManagerUtil.EquipToolAndSkin(tool_cfg_id, skin_cfg_id)
end

function M:set_appearance(style_color_list)
  if not style_color_list then
    return
  end
  for _, item in ipairs(style_color_list) do
    if item.style_id and item.color_id then
      CsSuitPreviewManagerUtil.EquipColor(item.style_id, item.color_id, item.area_id or 1)
    elseif item.style_id then
      CsSuitPreviewManagerUtil.EquipStyle(item.style_id)
      self:_apply_default_color(item.style_id)
    end
  end
end

function M:_apply_default_color(style_id)
  if not CsDyeingModuleUtil.IsHasHairAssetData(style_id) then
    return
  end
  local region_count = CsDyeingModuleUtil.GetHairAssetRegionCount(style_id)
  for region_id = 1, region_count do
    local default_color_id = CsDyeingModuleUtil.GetHairAssetDefaultColorBlockByRegionId(style_id, region_id)
    if default_color_id and default_color_id ~= 0 then
      CsSuitPreviewManagerUtil.EquipColor(style_id, default_color_id, region_id)
    end
  end
end

function M:_dress()
  if is_null(self._player_root) then
    return
  end
  if self._is_create_preview or not CsSuitPreviewManagerUtil.HasPreview() then
    CsSuitPreviewManagerUtil.CreatePreview(self._player_root)
    self:_sync_rotation_baseline()
  end
  if self._sync_player then
    CsSuitPreviewManagerUtil.CopyFromPlayer()
  end
  if self._pending_cloth_ids then
    CsSuitPreviewManagerUtil.PutOnCloths(self._pending_cloth_ids)
  end
  self:set_appearance(self._pending_style_color_list)
  CsSuitPreviewManagerUtil.SetOnReadyCallback(function()
    CsSuitPreviewManagerUtil.SetVisible(self._desired_visible)
    if self._pending_pose_display_tag or self._pending_pose_idle_tag then
      local display_tag = self._pending_pose_display_tag or ""
      local idle_tag = self._pending_pose_idle_tag or ""
      self._pending_pose_display_tag = nil
      self._pending_pose_idle_tag = nil
      CsSuitPreviewManagerUtil.PlayPoseByTag(display_tag, idle_tag)
    end
  end)
end

function M:_sync_rotation_baseline()
  if is_null(self._player_root) then
    self._cur_euler_angle_y = 0
    return
  end
  self._cur_euler_angle_y = self._player_root.localRotation.eulerAngles.y
end

function M:on_begin_drag(evt)
  self._last_pos = evt.position
end

function M:on_drag(evt)
  self._cur_pos = evt.position
  self._delta_pos = self._cur_pos - self._last_pos
  local angle_with_x_axis = Vector2.Angle(self._delta_pos, Vector2.right)
  if 90 < angle_with_x_axis then
    angle_with_x_axis = 180 - angle_with_x_axis
  end
  if angle_with_x_axis <= DRAG_ANGLE_THRESHOLD then
    self._drag_dis = Vector2.Distance(self._cur_pos, self._last_pos)
    if self._cur_pos.x >= self._last_pos.x then
      self._drag_dis = -self._drag_dis
    end
    self._cur_euler_angle_y = self._cur_euler_angle_y + self._drag_dis * ROTATION_SENSITIVITY
    CsSuitPreviewManagerUtil.UpdateRotationY(self._cur_euler_angle_y)
  end
  self._last_pos = self._cur_pos
end

function M:on_end_drag(evt)
  self:_reset_drag()
end

function M:play_pose_by_tag(display_tag, idle_tag)
  display_tag = string.is_valid(display_tag) and display_tag ~= "null" and display_tag or ""
  idle_tag = string.is_valid(idle_tag) and idle_tag ~= "null" and idle_tag or ""
  if display_tag == "" and idle_tag == "" then
    return
  end
  if CsSuitPreviewManagerUtil.IsReady() then
    CsSuitPreviewManagerUtil.PlayPoseByTag(display_tag, idle_tag)
  else
    self._pending_pose_display_tag = display_tag
    self._pending_pose_idle_tag = idle_tag
  end
end

function M:play_pose_by_suit_id(suit_id)
  local display_tag = self:get_suit_pose_tag(suit_id)
  local idle_tag = self:get_suit_pose_idle_tag(suit_id)
  self:play_pose_by_tag(display_tag, idle_tag)
end

function M:play_idle_pose_by_suit_id(suit_id)
  local idle_tag = self:get_suit_pose_idle_tag(suit_id)
  self:play_pose_by_tag(nil, idle_tag)
end

function M:play_pose_by_cloth_id(cloth_id)
  local suit_id = self:get_suit_id_by_cloth_id(cloth_id)
  local display_tag = self:get_suit_pose_tag(suit_id)
  local idle_tag = self:get_suit_pose_idle_tag(suit_id)
  self:play_pose_by_tag(display_tag, idle_tag)
end

function M:play_item_pose(cloth_id)
  local part_id = self:get_part_id_by_cloth_id(cloth_id)
  local part_display = self:get_part_display_tag(part_id)
  local part_idle = self:get_part_idle_tag(part_id) or DEFAULT_IDLE_TAG
  self:play_pose_by_tag(part_display, part_idle)
end

function M:get_suit_pose_tag(suit_id)
  if suit_id == nil or suit_id == 0 then
    return nil
  end
  local suit_cfg = ExcelDataUtil.get_value(typeof(BSuitCfg), suit_id)
  if is_null(suit_cfg) then
    return nil
  end
  local tag = suit_cfg.suitdisplay
  if not string.is_valid(tag) or tag == "null" then
    return nil
  end
  return tag
end

function M:get_cloth_pose_tag(cloth_id)
  local suit_id = self:get_suit_id_by_cloth_id(cloth_id)
  return self:get_suit_pose_tag(suit_id)
end

function M:get_suit_id_by_cloth_id(cloth_id)
  if cloth_id == nil or cloth_id == 0 then
    return 0
  end
  return CsSuitPreviewManagerUtil.GetSuitIdByClothId(cloth_id) or 0
end

function M:get_suit_pose_idle_tag(suit_id)
  if suit_id == nil or suit_id == 0 then
    return nil
  end
  local suit_cfg = ExcelDataUtil.get_value(typeof(BSuitCfg), suit_id)
  if is_null(suit_cfg) then
    return nil
  end
  local tag = suit_cfg.suitpose
  if not string.is_valid(tag) or tag == "null" then
    return nil
  end
  return tag
end

function M:get_part_id_by_cloth_id(cloth_id)
  if cloth_id == nil or cloth_id == 0 then
    return 0
  end
  return CsSuitPreviewManagerUtil.GetPartIdByClothId(cloth_id) or 0
end

function M:get_part_display_tag(part_id)
  if part_id == nil or part_id == 0 then
    return nil
  end
  local part_cfg = ExcelDataUtil.get_value(typeof(BChangeOutfitCfg), part_id)
  if is_null(part_cfg) then
    return nil
  end
  local tag = part_cfg.clothdisplay
  if not string.is_valid(tag) or tag == "null" then
    return nil
  end
  return tag
end

function M:get_part_idle_tag(part_id)
  if part_id == nil or part_id == 0 then
    return nil
  end
  local part_cfg = ExcelDataUtil.get_value(typeof(BChangeOutfitCfg), part_id)
  if is_null(part_cfg) then
    return nil
  end
  local tag = part_cfg.clothpose
  if not string.is_valid(tag) or tag == "null" then
    return nil
  end
  return tag
end

function M:play_gift_pose(suit_id, cloth_ids, idle_tag)
  local display_tag, idle_pose_tag = self:resolve_gift_pose(suit_id, cloth_ids)
  self:play_pose_by_tag(display_tag, idle_pose_tag or idle_tag or DEFAULT_IDLE_TAG)
end

function M:resolve_gift_pose(suit_id, cloth_ids)
  if suit_id and suit_id ~= 0 then
    return self:get_suit_pose_tag(suit_id), self:get_suit_pose_idle_tag(suit_id)
  end
  if cloth_ids then
    for _, cloth_id in ipairs(cloth_ids) do
      local sid = self:get_suit_id_by_cloth_id(cloth_id)
      if sid and sid ~= 0 then
        local display_tag = self:get_suit_pose_tag(sid)
        if display_tag then
          return display_tag, self:get_suit_pose_idle_tag(sid)
        end
      end
    end
  end
  return nil, nil
end

function M:reset(to_player)
  if to_player == nil then
    to_player = true
  end
  self._pending_cloth_ids = nil
  self._pending_style_color_list = nil
  self._desired_visible = true
  if is_null(self._player_root) then
    return
  end
  CsSuitPreviewManagerUtil.CreatePreview(self._player_root)
  self:_sync_rotation_baseline()
  if to_player then
    CsSuitPreviewManagerUtil.CopyFromPlayer()
  end
  CsSuitPreviewManagerUtil.SetOnReadyCallback(function()
    CsSuitPreviewManagerUtil.SetVisible(self._desired_visible)
  end)
end

function M:set_visible(visible)
  self._desired_visible = visible
  CsSuitPreviewManagerUtil.SetVisible(visible)
end

function M:hide()
  CsSuitPreviewManagerUtil.DestroyPreview()
end

function M:destroy()
  CsSuitPreviewManagerUtil.DestroyPreview()
  self._pending_cloth_ids = nil
  self._pending_style_color_list = nil
  self._player_root = nil
end

return M
