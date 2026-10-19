local M = G.Class("LittleCornerClothingShareDialog", G.UIWindow)
local base = G.UIWindow
local dialog_mode_enum = little_corner_module.share_clothing_dialog_mode
local little_coner_clothing_self_item_cls = "UI/LittleCorner/LittleCornerClothingSelfItem"
local little_coner_clothing_exhibit_item_cls = "UI/LittleCorner/LittleCornerClothingExhibitItem"

local function _get_sort_value(parsed)
  local cfg = little_corner_module.ootd_sort_order
  if not parsed.is_appearance then
    return cfg.fst_id[parsed.fst_id] or cfg.default_fst
  else
    return cfg.attr_type[parsed.attr_type] or cfg.default_attr
  end
end

local function _is_item_owned(parsed)
  if parsed.is_appearance then
    return appearance_module:is_style_unlocked(parsed.config_id)
  else
    return back_bag_module:get_item_num(parsed.config_id) > 0 or little_corner_module:is_default_outfit(parsed.config_id)
  end
end

local function _build_parse_cache(raw_infos, version)
  local cache = {}
  for _, raw in ipairs(raw_infos) do
    cache[raw] = little_corner_module:parse_ootd_segment_by_version(raw, version)
  end
  return cache
end

local function _sort_items_basic(raw_infos, parse_cache)
  table.sort(raw_infos, function(a, b)
    local pa = parse_cache[a]
    local pb = parse_cache[b]
    if not pa then
      return false
    end
    if not pb then
      return true
    end
    local va = _get_sort_value(pa)
    local vb = _get_sort_value(pb)
    if va ~= vb then
      return va < vb
    end
    return pa.config_id < pb.config_id
  end)
end

local function _sort_items_exhibit(raw_infos, parse_cache)
  table.sort(raw_infos, function(a, b)
    local pa = parse_cache[a]
    local pb = parse_cache[b]
    if not pa then
      return false
    end
    if not pb then
      return true
    end
    local oa = _is_item_owned(pa)
    local ob = _is_item_owned(pb)
    if oa ~= ob then
      return oa
    end
    local va = _get_sort_value(pa)
    local vb = _get_sort_value(pb)
    if va ~= vb then
      return va < vb
    end
    return pa.config_id < pb.config_id
  end)
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LittleCorner/LittleCornerClothingShareDialog"
  self.config.type = EUIType.Dialog
  self._dialog_mode = dialog_mode_enum.edit
  self._photo_sprite = nil
  self._photo_index = 0
  self._item_raw_infos = nil
  self._self_share_items = {}
  self._exhibit_share_items = {}
  self._photo_id = nil
  self._ootd_version = 1
  self._txt_title = nil
  self._txt_main = nil
  self._img_photo = nil
  self._btn_confirm = nil
  self._toggle_switch = nil
  self._title_switch = nil
  self._toggle_item = nil
  self._img_photo_aspect = nil
  self._btn_bg = nil
  self._btn_close_popup = nil
  self._txt_btn_confirm = nil
  self._list_item_binder = nil
end

function M:on_create()
  base.on_create(self)
  self._btn_confirm_transition = UIUtil.find_cmpt(self._btn_confirm, nil, typeof(UITransitionGroup))
  self:_add_ui_listener()
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm_click))
  self:bind_callback(self._btn_bg, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_close_popup, pack(self, M._on_btn_close_click))
end

function M:on_open()
  base.on_open(self)
  local extra_data = self:get_extra_data()
  self._dialog_mode = extra_data and extra_data.dialog_mode or dialog_mode_enum.view
  self._item_raw_infos = self:_load_share_item_data(extra_data)
  self._photo_sprite = extra_data.photo_sprite
  self._photo_index = extra_data.photo_index
  self._photo_id = extra_data.photo_id
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh_ui()
end

function M:_refresh_ui()
  self:_refresh_on_dialog_mode()
  self:_refresh_clothing()
  self:_refresh_txt_info()
  self:_refresh_img()
end

function M:_refresh_on_dialog_mode()
  UIUtil.set_active(self._title_switch, false)
  local btn_txt = self._dialog_mode == dialog_mode_enum.view and UIUtil.get_text_by_id("Xhs_UI_Text11") or UIUtil.get_text_by_id("Xhs_UI_Text12")
  UIUtil.set_text(self._txt_btn_confirm, btn_txt)
end

function M:_refresh_clothing()
  if not self._item_raw_infos or #self._item_raw_infos == 0 then
    return
  end
  local parse_cache = _build_parse_cache(self._item_raw_infos, self._ootd_version)
  if self._dialog_mode == dialog_mode_enum.edit then
    _sort_items_basic(self._item_raw_infos, parse_cache)
    self:_refresh_self_share_items(parse_cache)
    self:_hide_items(self._exhibit_share_items)
  elseif self._dialog_mode == dialog_mode_enum.view then
    _sort_items_exhibit(self._item_raw_infos, parse_cache)
    self:_refresh_exhibit_share_items(parse_cache)
    self:_hide_items(self._self_share_items)
    local any_owned = false
    for _, seg in ipairs(self._item_raw_infos) do
      local parsed = parse_cache[seg]
      if parsed and _is_item_owned(parsed) then
        any_owned = true
        break
      end
    end
    self:_set_confirm_enabled(any_owned)
  end
end

function M:_get_selected_raw_infos()
  local selected = {}
  local show_count = math.min(#(self._item_raw_infos or {}), #self._self_share_items)
  for i = 1, show_count do
    local item = self._self_share_items[i]
    if item and item:is_selected() then
      table.insert(selected, item:get_raw_info())
    end
  end
  return selected
end

function M:_set_confirm_enabled(is_enabled)
  if not self._btn_confirm_transition then
    return
  end
  local btn_state = little_corner_module.btn_transition_state
  self._btn_confirm_transition:SetState(is_enabled and btn_state.normal or btn_state.disabled)
end

function M:_hide_items(items)
  for _, item in ipairs(items) do
    if item then
      item:set_active(false)
    end
  end
end

function M:_refresh_self_share_items(parse_cache)
  if not self._item_raw_infos then
    return
  end
  local draft = little_corner_module:get_post_draft()
  local cur_post_share_item_raw_str = draft and draft.extra_data_ootd and draft.extra_data_ootd[self._photo_index] and draft.extra_data_ootd[self._photo_index].ootd_info_str or ""
  for i = 1, #self._item_raw_infos do
    local item_seg = self._item_raw_infos[i]
    local item_enable_shared = cur_post_share_item_raw_str:find(item_seg) ~= nil
    local item_data = {
      seg = item_seg,
      parsed = parse_cache[item_seg],
      is_selected = item_enable_shared
    }
    local item = self._self_share_items[i]
    if not item then
      local obj = self._list_item_binder:AddItem(0)
      if not_null(obj) then
        item = self:add_panel(little_coner_clothing_self_item_cls, obj, item_data)
        self._self_share_items[i] = item
        UIUtil.set_active(obj, true)
      end
    else
      item:set_extra_data(item_data)
      item:force_refresh()
      item:set_active(true)
    end
  end
  for i = #self._item_raw_infos + 1, #self._self_share_items do
    if self._self_share_items[i] then
      self._self_share_items[i]:set_active(false)
    end
  end
end

function M:_refresh_exhibit_share_items(parse_cache)
  if not self._item_raw_infos then
    return
  end
  for i = 1, #self._item_raw_infos do
    local seg = self._item_raw_infos[i]
    local parsed = parse_cache[seg]
    local owned = parsed and _is_item_owned(parsed) or false
    local item_data = {
      seg = seg,
      parsed = parsed,
      owned = owned
    }
    local item = self._exhibit_share_items[i]
    if not item then
      local obj = self._list_item_binder:AddItem(1)
      if not_null(obj) then
        item = self:add_panel(little_coner_clothing_exhibit_item_cls, obj, item_data)
        self._exhibit_share_items[i] = item
        UIUtil.set_active(obj, true)
      end
    else
      item:set_extra_data(item_data)
      item:force_refresh()
      item:set_active(true)
    end
  end
  for i = #self._item_raw_infos + 1, #self._exhibit_share_items do
    if self._exhibit_share_items[i] then
      self._exhibit_share_items[i]:set_active(false)
    end
  end
end

function M:_refresh_txt_info()
end

function M:_refresh_img()
  local photo_sprite = self._photo_sprite
  if not_null(photo_sprite) then
    UIUtil.set_image(self._img_photo, photo_sprite, self:get_load_proxy())
    self._img_photo_aspect.aspectRatio = photo_sprite.rect.width / photo_sprite.rect.height
    UIUtil.set_active(self._img_photo, true)
  else
    UIUtil.set_active(self._img_photo, false)
  end
end

function M:_load_share_item_data(extra_data)
  self._ootd_version = 1
  if not extra_data then
    return {}
  end
  local photo_ootd_info
  if extra_data.ootd_data then
    photo_ootd_info = extra_data.ootd_data
  elseif extra_data.photo_id then
    photo_ootd_info = CsAlbumManagerUtil.GetPhotoOotdData(extra_data.photo_id)
  end
  if not photo_ootd_info or photo_ootd_info == "" then
    return {}
  end
  local segments = {}
  for seg in string.gmatch(photo_ootd_info, "([^|]+)") do
    table.insert(segments, seg)
  end
  local start_idx = 1
  if segments[1] == "v2" then
    self._ootd_version = 2
    start_idx = 2
  else
    self._ootd_version = 1
  end
  local ootd_raw_infos = {}
  for i = start_idx, #segments do
    local seg = segments[i]
    local parsed = little_corner_module:parse_ootd_segment_by_version(seg, self._ootd_version)
    if parsed and not little_corner_module:is_hidden_share_outfit(parsed.config_id) and item_module:get_cfg_by_id(parsed.config_id) then
      table.insert(ootd_raw_infos, seg)
    end
  end
  return ootd_raw_infos
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  self._item_raw_infos = nil
  self._photo_sprite = nil
  self._ootd_version = 1
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_bg)
end

function M:_on_btn_confirm_click()
  if self._dialog_mode == dialog_mode_enum.view then
    self:_on_apply_ootd()
  elseif self._dialog_mode == dialog_mode_enum.edit then
    self:_on_confirm_ootd_info()
  end
end

function M:_on_btn_close_click()
  self:close_self()
end

function M:_on_apply_ootd()
  if not self._item_raw_infos then
    return
  end
  local cloth_ids, appearances = {}, {}
  local any_owned = false
  for i = 1, #self._item_raw_infos do
    local item = self._exhibit_share_items[i]
    local parsed = item and item:get_parsed()
    if parsed then
      if _is_item_owned(parsed) then
        any_owned = true
      end
      if parsed.is_appearance then
        table.insert(appearances, parsed)
      else
        table.insert(cloth_ids, parsed.config_id)
      end
    end
  end
  if not any_owned then
    UIUtil.show_tips_by_text_id("Xhs_UI_Text28")
    return
  end
  little_corner_module:apply_ootd(cloth_ids, appearances)
  self:close_self()
end

function M:_on_confirm_ootd_info()
  local ootd_info_str_table = self:_get_selected_raw_infos()
  if #ootd_info_str_table == 0 then
    UIUtil.show_tips_by_text_id("Xhs_UI_Tips7")
    return
  end
  local draft_ootd_str
  if self._ootd_version == 2 then
    draft_ootd_str = "v2|" .. table.concat(ootd_info_str_table, "|")
  else
    draft_ootd_str = table.concat(ootd_info_str_table, "|")
  end
  little_corner_module:set_draft_ootd(self._photo_index, self._photo_id, draft_ootd_str)
  self:close_self()
end

return M
