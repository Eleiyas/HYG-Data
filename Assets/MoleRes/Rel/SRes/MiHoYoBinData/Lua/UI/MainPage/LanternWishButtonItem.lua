local M = G.Class("LanternWishButtonItem", G.UIPanel)
local base = G.UIPanel
local RET_SUCC = 0
local SUPPORT_WISH_PAGE = "UI/MainActivity_y1/Riddle/SpringFestivalLanternSupportWishPage"
local _pending_support_wish
local ANCHOR_DESIGN_OFFSET_X = 0
local ANCHOR_WORLD_OFFSET_Y = 0.18
local display_phase = {
  hidden = 0,
  showing = 1,
  visible = 2,
  hiding = 3
}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainPage/StarFriendButtonItem"
  self._is_close = false
  self._requested_visible = false
  self._display_phase = display_phase.hidden
  self._has_valid_anchor = false
  self._skip_exit_refresh = false
  self._curr_side = 0
  self._target_data = nil
  self._look_btn_padding = Vector2(150, 0)
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn_look_star_field, pack(self, M._on_btn_click))
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaSpringFestivalLanternInteractRsp, pack(self, M._on_lantern_interact_rsp))
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  if self._display_phase == display_phase.hidden then
    self:_set_canvas_visible(false)
  end
end

function M:update()
  self:_refresh_display_state()
end

function M:show()
  self._requested_visible = true
  self:_refresh_display_state()
end

function M:hide()
  self._requested_visible = false
  self:_refresh_display_state()
end

function M:sync_target(data)
  self._target_data = data
  if is_null(data) then
    self._curr_sub_index = nil
    self._last_is_key_mouse = nil
    self._static_text_set = nil
    self._has_valid_anchor = false
    self._world_pos = nil
    self._lantern_pos = nil
    self._requested_visible = false
    self:_force_hidden_immediately()
    return
  end
  self:refresh(data)
  self._requested_visible = true
  if self._is_play_anim or self._display_phase == display_phase.showing then
    return
  end
  self:_refresh_display_state()
end

function M:refresh(data)
  if is_null(data) then
    return
  end
  if not self._static_text_set then
    self._static_text_set = true
    if self._btn_txt then
      UIUtil.set_text_by_id(self._btn_txt, "Lantern_Check")
    end
    if self._txt_interactname then
      UIUtil.set_text_by_id(self._txt_interactname, "Lantern_Check")
    end
    UIUtil.set_active(self._obj_tags, false)
  end
  local is_key_mouse = InputManagerIns:is_key_mouse()
  if self._last_is_key_mouse ~= is_key_mouse then
    self._last_is_key_mouse = is_key_mouse
    UIUtil.set_active(self._trans_key_mouse_btn, is_key_mouse)
    UIUtil.set_active(self._btn_look_star_field, not is_key_mouse)
  end
  local sub_index = data.sub_index
  if sub_index == nil or sub_index < 0 then
    return
  end
  if self._curr_sub_index ~= sub_index then
    local sender_name = tostring(data.sender_name or "")
    if sender_name == "" then
      sender_name = UIUtil.get_text_by_id("FestiveLantern_DefaultName")
    end
    UIUtil.set_text_by_id(self._txt_starname, "FestiveLantern_Main_Interact", sender_name)
    self._curr_sub_index = sub_index
  end
end

function M:can_interact()
  return self._display_phase == display_phase.visible and self._requested_visible and self.is_active and self._has_valid_anchor
end

function M:on_y_press()
  if self:can_interact() then
    self:_on_btn_click()
  end
end

function M:_on_lantern_interact_rsp(result)
  local pending = _pending_support_wish
  if pending == nil or is_null(result) then
    return
  end
  if result.entityGuid ~= pending.entity_guid then
    return
  end
  if pending.server_lantern_index ~= nil and result.serverLanternIndex ~= nil and result.serverLanternIndex ~= pending.server_lantern_index then
    return
  end
  _pending_support_wish = nil
  local code = tonumber(result.retcode) or -1
  if code ~= RET_SUCC then
    Logger.LogWarning(string.format("[LanternWishButtonItem] LanternInteractRsp failed retcode=%s, skip open", tostring(code)))
    return
  end
  pending.support_count = tonumber(result.boostValue) or 0
  pending.is_boosted_by_me = result.isBoostedByMe == true
  UIManagerInstance:open(SUPPORT_WISH_PAGE, pending)
end

function M:_on_btn_click()
  if not self:can_interact() or is_null(self._target_data) then
    return
  end
  if _pending_support_wish ~= nil then
    return
  end
  if self._target_data.arg_type ~= nil and self._target_data.numArg ~= nil then
    CsUIUtil.OnOptionItemClick(self._target_data.arg_type, self._target_data.numArg)
  end
  local entity_guid = self._target_data.guid or 0
  local server_lantern_index = self._target_data.server_lantern_index
  if entity_guid == 0 or server_lantern_index == nil then
    Logger.LogWarning(string.format("[LanternWishButtonItem] LanternInteract skipped: entity_guid=%s, server_lantern_index=%s", tostring(entity_guid), tostring(server_lantern_index)))
    return
  end
  if CsGameplayUtilitiesLanternUtil == nil or CsGameplayUtilitiesLanternUtil.RequestLanternInteract == nil then
    Logger.LogWarning("[LanternWishButtonItem] RequestLanternInteract not ready")
    return
  end
  local target_world_pos
  if CsGameplayUtilitiesLanternUtil and CsGameplayUtilitiesLanternUtil.GetCurrentLookAtAim then
    local aim = CsGameplayUtilitiesLanternUtil.GetCurrentLookAtAim()
    if not is_null(aim) and aim.IsLantern then
      target_world_pos = Vector3(aim.worldX, aim.worldY, aim.worldZ)
    end
  end
  _pending_support_wish = {
    entity_guid = entity_guid,
    sub_index = self._target_data.sub_index,
    server_lantern_index = server_lantern_index,
    sender_name = self._target_data.sender_name,
    sender_uid = self._target_data.sender_uid,
    wish_text = self._target_data.wish_content,
    wish_target_world_pos = target_world_pos,
    wish_version = self._target_data.wish_version
  }
  CsGameplayUtilitiesLanternUtil.RequestLanternInteract(entity_guid, server_lantern_index)
end

function M:_refresh_display_state()
  if self._is_play_anim then
    return
  end
  local layout = self:_resolve_target_layout()
  local should_show = self._requested_visible and layout ~= nil
  if self._display_phase == display_phase.hidden then
    if not should_show then
      self._has_valid_anchor = false
      self:_set_canvas_visible(false)
      if self.is_active then
        self:_force_hidden_immediately()
      end
      return
    end
    if self.is_active then
      self:_force_hidden_immediately()
    end
    self._pending_show_layout = layout
    self:_begin_show()
    return
  end
  if self._display_phase == display_phase.showing then
    return
  end
  if self._display_phase == display_phase.hiding then
    return
  end
  if not should_show then
    self:_begin_hide()
    return
  end
  self:_apply_layout(layout)
end

function M:_resolve_target_layout()
  if not self._requested_visible or is_null(self._target_data) then
    return nil
  end
  local is_get, x, y, z = self:_try_get_lantern_position()
  if not is_get then
    return nil
  end
  if not self._lantern_pos then
    self._lantern_pos = Vector3(0, 0, 0)
  end
  self._lantern_pos:Set(x, y, z)
  local camera = self:_get_main_camera()
  if is_null(camera) then
    return nil
  end
  local lantern_viewport_pos = camera:WorldToViewportPoint(self._lantern_pos)
  if 0 >= lantern_viewport_pos.z then
    return nil
  end
  local canvas_size = UIManagerInstance:get_canvas_size()
  if not self._btn_pos then
    self._btn_pos = Vector2(0, 0)
  end
  local center_x, center_y = self:_world_to_canvas(x, y, z, canvas_size)
  local side = center_x > canvas_size.x * 0.62 and 1 or 0
  local offset_x, offset_y = self:_get_anchor_point_offset()
  local target_x = center_x + ANCHOR_DESIGN_OFFSET_X
  local target_y = center_y
  if ANCHOR_WORLD_OFFSET_Y ~= 0 then
    local _, offset_center_y = self:_world_to_canvas(x, y + ANCHOR_WORLD_OFFSET_Y, z, canvas_size)
    target_y = offset_center_y
  end
  local content_h = self:_get_content_height()
  local star_y = math.max(content_h, math.min(canvas_size.y - self._look_btn_padding.y, target_y))
  self._btn_pos.x = target_x - offset_x
  self._btn_pos.y = star_y - offset_y
  if not self._resolved_layout then
    self._resolved_layout = {}
  end
  self._resolved_layout.side = side
  self._resolved_layout.pos_x = self._btn_pos.x
  self._resolved_layout.pos_y = self._btn_pos.y
  return self._resolved_layout
end

function M:_world_to_canvas(x, y, z, canvas_size)
  local ux, uy = UIUtil.world_to_ui(x, y, z)
  return ux + canvas_size.x / 2, uy + canvas_size.y / 2
end

function M:_get_content_height()
  if not is_null(self._layout) then
    local content_rect = self._layout.transform
    if not is_null(content_rect) then
      return content_rect.rect.height
    end
  end
  return self:_get_btn_rect_transform().sizeDelta.y
end

function M:_get_anchor_point_offset()
  if is_null(self._trans_star) then
    return 0, 0
  end
  local rect = self:_get_btn_rect_transform()
  local parent = rect.parent
  if is_null(parent) then
    return 0, 0
  end
  local star_local = parent:InverseTransformPoint(self._trans_star.position)
  local root_local = parent:InverseTransformPoint(rect.position)
  return star_local.x - root_local.x, star_local.y - root_local.y
end

function M:_apply_layout(layout)
  self._curr_side = layout.side
  self:_update_side_state()
  self._btn_pos.x = layout.pos_x
  self._btn_pos.y = layout.pos_y
  self._has_valid_anchor = true
  self:_set_canvas_visible(true)
  self:_get_btn_rect_transform().anchoredPosition = self._btn_pos
end

function M:_begin_show()
  self._display_phase = display_phase.showing
  self:_set_canvas_visible(false)
  self:set_active(true)
end

function M:_begin_hide()
  if self._display_phase == display_phase.hidden or self._display_phase == display_phase.hiding then
    return
  end
  self._display_phase = display_phase.hiding
  self._has_valid_anchor = false
  self:set_active(false)
end

function M:_force_hidden_immediately()
  self._pending_show_layout = nil
  self._skip_exit_refresh = true
  self:set_active(false, true)
  self._display_phase = display_phase.hidden
  self._has_valid_anchor = false
  self:_set_canvas_visible(false)
end

function M:_set_canvas_visible(is_visible)
  self._canvas_group.alpha = is_visible and 1 or 0
end

function M:enter_anim_call_back()
  base.enter_anim_call_back(self)
  self._display_phase = display_phase.visible
  self:_set_canvas_visible(true)
  local pending = self._pending_show_layout
  self._pending_show_layout = nil
  if pending then
    self:_apply_layout(pending)
  end
  self:_refresh_display_state()
end

function M:exit_anim_call_back()
  base.exit_anim_call_back(self)
  self._display_phase = display_phase.hidden
  if self._skip_exit_refresh then
    self._skip_exit_refresh = false
    return
  end
  self:_refresh_display_state()
end

function M:_update_side_state()
  local state = self._curr_side
  self._state_group:SetState(state)
  if state == 0 then
    self._layout.childAlignment = CS.UnityEngine.TextAnchor.UpperLeft
    self._txt_starname.horizontalAlignment = CS.TMPro.HorizontalAlignmentOptions.Left
    self._txt_star_friend_btn_tag.horizontalAlignment = CS.TMPro.HorizontalAlignmentOptions.Left
  else
    self._layout.childAlignment = CS.UnityEngine.TextAnchor.UpperRight
    self._txt_starname.horizontalAlignment = CS.TMPro.HorizontalAlignmentOptions.Right
    self._txt_star_friend_btn_tag.horizontalAlignment = CS.TMPro.HorizontalAlignmentOptions.Right
  end
end

function M:_try_get_lantern_position()
  local cs_aim_util = CsGameplayUtilitiesLanternUtil
  if not cs_aim_util or not cs_aim_util.GetCurrentLookAtAim then
    return false
  end
  local aim = cs_aim_util.GetCurrentLookAtAim()
  if is_null(aim) or not aim.IsLantern then
    return false
  end
  local target = self._target_data
  if is_null(target) then
    return false
  end
  if target.guid ~= nil and aim.ownerGuid ~= target.guid then
    return false
  end
  if target.sub_index ~= nil and target.sub_index >= 0 and aim.subIndex ~= target.sub_index then
    return false
  end
  local x = aim.worldX
  local y = aim.worldY
  local z = aim.worldZ
  target.world_pos = target.world_pos or Vector3(0, 0, 0)
  target.world_pos:Set(x, y, z)
  return true, x, y, z
end

function M:_get_main_camera()
  self._main_camera = CsGameplayUtilitiesCameraUtil.GetMainCamera()
  return self._main_camera
end

function M:_get_btn_rect_transform()
  if is_null(self._btn_rect_transform) then
    self._btn_rect_transform = self.trans:GetComponent(typeof(RectTransform))
  end
  return self._btn_rect_transform
end

return M
