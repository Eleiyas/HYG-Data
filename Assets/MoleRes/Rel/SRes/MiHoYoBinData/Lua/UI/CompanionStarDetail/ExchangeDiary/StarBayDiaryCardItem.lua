local M = G.Class("StarBayDiaryCardItem", G.UIPanel)
local base = G.UIPanel

local function set_image_if_valid(target, path, proxy)
  if is_null(target) or not string.is_valid(path) then
    return
  end
  UIUtil.set_image(target, path, proxy)
end

local function clear_image_if_valid(target)
  if is_null(target) then
    return
  end
  if target.sprite ~= nil then
    target.sprite = nil
  end
  if target.texture ~= nil then
    target.texture = nil
  end
end

local function is_player_recorder(type_cfg)
  return type_cfg ~= nil and type_cfg.recorderType == NpcDiaryRecorderType.Player
end

local PHOTO_REVIEW_STATUS_PENDING = 1

local function is_photo_in_review(view_data)
  return view_data ~= nil and (view_data.photoReviewStatus or 0) == PHOTO_REVIEW_STATUS_PENDING
end

local function format_diary_date(timestamp)
  local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(timestamp or 0)
  return TextMapFormatUtil.FormatDateYMD(date_time)
end

function M:init()
  base.init(self)
  self._bind_version = 0
  self._bound_file_key = ""
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._btn_share) then
    self:bind_callback(self._btn_share, pack(self, M._on_btn_share))
  end
  if not is_null(self._btn_photo_preview) then
    self:bind_callback(self._btn_photo_preview, pack(self, M._on_btn_photo_preview))
  end
end

function M:_on_btn_share()
  if is_photo_in_review(self._view_data) then
    return
  end
  if self.holder and self.holder.on_card_share then
    self.holder:on_card_share(self._view_data, self._entry_cfg, self._style_cfg, self._type_cfg)
  end
end

function M:_on_btn_photo_preview()
  if self.holder and self.holder.on_card_photo_preview then
    self.holder:on_card_photo_preview(self._view_data, self._entry_cfg)
  end
end

function M:_advance_bind_version(view_data)
  self._bind_version = (self._bind_version or 0) + 1
  self._bound_file_key = view_data and view_data.fileKey or ""
end

function M:_reset_reused_state()
  clear_image_if_valid(self._photo_dynamic)
  clear_image_if_valid(self._big_stamp_icon)
  clear_image_if_valid(self._big_illustration)
  clear_image_if_valid(self._small_illustration)
  clear_image_if_valid(self._small_bg_pattern)
  clear_image_if_valid(self._tag_icon)
  clear_image_if_valid(self._tag_player_head)
  if not is_null(self._tag_icon) then
    UIUtil.set_active(self._tag_icon, false)
  end
  if not is_null(self._tag_player_head_root) then
    UIUtil.set_active(self._tag_player_head_root, false)
  end
  if not is_null(self._small_illustration) then
    UIUtil.set_active(self._small_illustration, false)
  end
  if not is_null(self._small_player_illustration) then
    UIUtil.set_active(self._small_player_illustration, false)
  end
  if not is_null(self._tag_state_group) then
    self._tag_state_group:SetState(0)
  end
  if not is_null(self._photo_group) then
    UIUtil.set_active(self._photo_group, false)
  end
  if not is_null(self._photo_state_group) then
    self._photo_state_group:SetState(0)
  end
  if not is_null(self._btn_share) then
    UIUtil.set_active(self._btn_share, false)
  end
  if not is_null(self._red_point) then
    self._red_point:ShowRedPoint(RedPointType.None)
  end
end

function M:_refresh_tag_icon(view_data, type_cfg)
  if is_player_recorder(type_cfg) then
    if not is_null(self._tag_icon) then
      UIUtil.set_active(self._tag_icon, false)
    end
    if not is_null(self._tag_player_head_root) then
      UIUtil.set_active(self._tag_player_head_root, true)
    end
    if not is_null(self._tag_player_head) then
      player_module:set_player_icon(self._tag_player_head, self:get_load_proxy())
    end
    return
  end
  if is_null(self._tag_icon) or view_data == nil or view_data.npcId == nil or view_data.npcId == 0 then
    return
  end
  UIUtil.set_active(self._tag_icon, true)
  if not is_null(self._tag_player_head_root) then
    UIUtil.set_active(self._tag_player_head_root, false)
  end
  local npc_cfg = ExcelDataUtil.get_value(typeof(BNpcCfg), view_data.npcId)
  if npc_cfg and string.is_valid(npc_cfg.iconnamesmall) then
    set_image_if_valid(self._tag_icon, npc_cfg.iconnamesmall, self:get_load_proxy())
  end
end

function M:_refresh_small_illustration(style_cfg, type_cfg)
  if is_null(self._small_illustration) and is_null(self._small_player_illustration) then
    return
  end
  if is_player_recorder(type_cfg) then
    if not is_null(self._small_player_illustration) then
      UIUtil.set_active(self._small_player_illustration, true)
    end
    if not is_null(self._small_illustration) then
      UIUtil.set_active(self._small_illustration, false)
    end
    return
  end
  if not is_null(self._small_player_illustration) then
    UIUtil.set_active(self._small_player_illustration, false)
  end
  if not is_null(self._small_illustration) then
    UIUtil.set_active(self._small_illustration, true)
  end
end

function M:_apply_style_cfg(style_cfg)
  if style_cfg == nil or is_null(self._style_binding_group) then
    return
  end
  self._style_binding_group:Apply(style_cfg, self:get_load_proxy())
end

function M:get_photo_bind_snapshot()
  return self._bind_version or 0, self._view_data, self._bound_file_key or ""
end

function M:is_photo_bind_snapshot_valid(bind_version, view_data, file_key)
  return not is_null(self.game_obj) and self.is_active and self._bind_version == bind_version and self._view_data == view_data and (self._bound_file_key or "") == (file_key or "")
end

function M:refresh(view_data, entry_cfg, style_cfg, type_cfg)
  self:_advance_bind_version(view_data)
  self._view_data = view_data
  self._entry_cfg = entry_cfg
  self._style_cfg = style_cfg
  self._type_cfg = type_cfg
  self:_reset_reused_state()
  if view_data == nil or entry_cfg == nil then
    self:set_active(false)
    return
  end
  UIUtil.set_text(self._txt_title, entry_cfg.title:ToStringExplicit())
  UIUtil.set_text(self._txt_content, entry_cfg.content:ToStringExplicit())
  UIUtil.set_text(self._txt_date, format_diary_date(view_data.unlockTimestamp))
  self:_refresh_tag_icon(view_data, type_cfg)
  if type_cfg ~= nil then
    local display_name = type_cfg.displayName
    if display_name and display_name.ToStringExplicit then
      display_name = display_name:ToStringExplicit()
    end
    if not is_null(self._tag_title) then
      UIUtil.set_text(self._tag_title, display_name or "")
    end
    if not is_null(self._tag_state_group) then
      self._tag_state_group:SetState(type_cfg.styleStateId or 0)
    end
  end
  self:_apply_style_cfg(style_cfg)
  self:_refresh_small_illustration(style_cfg, type_cfg)
  local has_photo = entry_cfg ~= nil and string.is_valid(entry_cfg.photoAlias)
  if not is_null(self._photo_group) then
    UIUtil.set_active(self._photo_group, has_photo)
  end
  if not is_null(self._photo_state_group) then
    self._photo_state_group:SetState(has_photo and 0 or 1)
  end
  if not is_null(self._btn_share) then
    UIUtil.set_active(self._btn_share, not is_photo_in_review(view_data))
  end
  if not is_null(self._red_point) then
    local red_type = RedPointType.None
    if CsCompanionStarModuleUtil.IsDiaryEntryRedPointNew(view_data) then
      red_type = RedPointType.NewRp
    end
    self._red_point:ShowRedPoint(red_type)
  end
  self:set_active(true)
end

return M
