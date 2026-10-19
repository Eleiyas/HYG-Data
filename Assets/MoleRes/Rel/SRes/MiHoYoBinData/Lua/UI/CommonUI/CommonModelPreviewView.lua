local M = G.Class("CommonModelPreviewView", G.UIBase)
local base = G.UIBase
local LUCA_GROUP_ANIM_IN = "anim_npcImpressionhallpanel_luca_group_in"
local LUCA_GROUP_ANIM_OUT = "anim_npcImpressionhallpanel_luca_group_out"
local s_current_owner
local ItemIconStyle = {
  Normal = 0,
  Recipe = 1,
  Cookbook = 2,
  AppearanceCard = 3
}

function M:init()
  base.init(self)
  self._cur_item_id = 0
  self._is_showing = false
  self._enable_touch_rotate = true
  self._enable_auto_rotate = true
  self._show_gacha_detail = false
  self._gacha_detail_callback = nil
  self._on_model_loaded = nil
  self._load_proxy = nil
  self._avatar_dirty = true
  self._video_path = nil
  self._video_loop = true
  self._on_video_start = nil
  self._on_video_finish = nil
  self._video_playing_id = 0
  self._video_task = nil
  self._luca_group_shown = false
  self._trans_3d_model = nil
  self._img_3d_model = nil
  self._trans_3d_cloth_model = nil
  self._trans_3d_model_touch_rect = nil
  self._ui_state_group_ui_change_group_icon = nil
  self._trans_ui_change_group_icon = nil
  self._trans_video = nil
  self._img_video = nil
  self._img_icon = nil
  self._img_bg = nil
  self._btn_gacha_detail = nil
  self._icon_luca = nil
  self._txt_luca_desc = nil
  self._anim_helper_luca_group = nil
end

function M:on_create()
  base.on_create(self)
  if not is_null(self._trans_video) then
    UIUtil.set_active(self._trans_video, false)
  end
  self.binder:BindViewCallback(self._trans_3d_model_touch_rect, EventTriggerType.PointerDown, pack(self, M._on_pointer_down))
  self.binder:BindViewCallback(self._trans_3d_model_touch_rect, EventTriggerType.PointerUp, pack(self, M._on_pointer_up))
  self.binder:BindViewCallback(self._trans_3d_model_touch_rect, EventTriggerType.Drag, pack(self, M._on_drag))
  self:bind_callback(self._btn_gacha_detail, pack(self, M._on_btn_gacha_detail_click))
  UIUtil.set_active(self._btn_gacha_detail, false)
end

function M:on_open()
  base.on_open(self)
  local extra_data = self:get_extra_data()
  if extra_data then
    self:_apply_data(extra_data)
  end
end

function M:on_enable()
  base.on_enable(self)
  self._avatar_dirty = true
  if self._cur_item_id > 0 or string.is_valid(self._video_path) then
    self:_refresh_preview()
  end
end

function M:on_disable()
  base.on_disable(self)
  self:_release_video_task()
  if s_current_owner == self then
    ModelPreviewManagerIns:hide()
    s_current_owner = nil
  end
  self._is_showing = false
  self._luca_group_shown = false
end

function M:on_destroy()
  self:_release_video_task()
  if s_current_owner == self then
    s_current_owner = nil
  end
  ModelPreviewManagerIns:destroy_avatar_model()
  base.on_destroy(self)
end

function M:set_data(data)
  if not self:_apply_data(data) then
    return
  end
  self:_refresh_preview()
end

function M:show_item(item_id, load_proxy)
  if not item_id or item_id <= 0 then
    return
  end
  self._cur_item_id = item_id
  self._video_path = nil
  self._avatar_dirty = true
  if load_proxy then
    self._load_proxy = load_proxy
  end
  self:_refresh_preview()
end

function M:hide_preview()
  self:_play_luca_group_anim(false)
  self:_hide_all_areas()
  UIUtil.set_active(self._btn_gacha_detail, false)
  self._is_showing = false
  if s_current_owner == self then
    s_current_owner = nil
  end
  self._cur_item_id = 0
  self._video_path = nil
end

function M:get_current_item_id()
  return self._cur_item_id
end

function M:is_showing()
  return self._is_showing
end

function M:set_touch_enabled(enabled)
  self._enable_touch_rotate = enabled
end

function M:destroy_avatar_model()
  ModelPreviewManagerIns:destroy_avatar_model()
end

function M:mark_avatar_dirty()
  self._avatar_dirty = true
end

function M:show_video(video_path, loop, on_start, on_finish)
  if not string.is_valid(video_path) then
    return
  end
  self._video_path = video_path
  self._video_loop = loop ~= false
  self._on_video_start = on_start
  self._on_video_finish = on_finish
  self:_refresh_preview()
end

function M:stop_video()
  self:_release_video_task()
  if not is_null(self._trans_video) then
    UIUtil.set_active(self._trans_video, false)
  end
  self._video_path = nil
end

function M:is_playing_video()
  return self._video_playing_id ~= 0
end

function M:_apply_data(data)
  if not data then
    return false
  end
  local has_item = data.item_id and data.item_id > 0
  local has_video = string.is_valid(data.video_path)
  if not has_item and not has_video then
    return false
  end
  self._cur_item_id = data.item_id or 0
  self._enable_touch_rotate = data.enable_touch_rotate ~= false
  self._enable_auto_rotate = data.enable_auto_rotate ~= false
  self._show_gacha_detail = data.show_gacha_detail or false
  self._gacha_detail_callback = data.on_gacha_detail_click
  self._on_model_loaded = data.on_model_loaded
  self._load_proxy = data.load_proxy or self:get_load_proxy()
  self._video_path = data.video_path
  self._video_loop = data.video_loop ~= false
  self._on_video_start = data.on_video_start
  self._on_video_finish = data.on_video_finish
  self._avatar_dirty = true
  return true
end

function M:_hide_local_areas()
  self:_release_video_task()
  UIUtil.set_active(self._trans_3d_model, false)
  UIUtil.set_active(self._trans_ui_change_group_icon, false)
  if not is_null(self._img_3d_model) then
    UIUtil.set_active(self._img_3d_model, false)
  end
  if not is_null(self._trans_video) then
    UIUtil.set_active(self._trans_video, false)
  end
  if not is_null(self._icon_luca) then
    UIUtil.set_active(self._icon_luca, false)
  end
  if not is_null(self._txt_luca_desc) then
    UIUtil.set_active(self._txt_luca_desc, false)
  end
end

function M:_hide_all_areas()
  if s_current_owner == nil or s_current_owner == self then
    ModelPreviewManagerIns:hide()
  end
  self:_hide_local_areas()
end

function M:_play_luca_group_anim(is_enter)
  if is_null(self._anim_helper_luca_group) then
    return
  end
  if is_enter then
    self._luca_group_shown = true
    self._anim_helper_luca_group:Play(LUCA_GROUP_ANIM_IN, nil)
  elseif self._luca_group_shown then
    self._luca_group_shown = false
    self._anim_helper_luca_group:Play(LUCA_GROUP_ANIM_OUT, nil)
  end
end

function M:_refresh_preview()
  local item_id = self._cur_item_id
  if item_id <= 0 and not string.is_valid(self._video_path) then
    self:hide_preview()
    return
  end
  local is_luca = not string.is_valid(self._video_path) and item_module:is_luca_hold(item_id)
  self:_play_luca_group_anim(is_luca)
  ModelPreviewManagerIns:hide()
  self:_hide_local_areas()
  if string.is_valid(self._video_path) then
    self:_show_video_preview()
  elseif is_luca then
    self:_show_luca_hold(item_id)
  else
    UIUtil.set_active(self._trans_3d_model, true)
    if self:_can_show_model(item_id) then
      self:_show_3d_model(item_id)
    elseif item_module:is_reaction_card(item_id) then
      self:_show_reaction_card(item_id)
    else
      self:_show_2d_icon(item_id)
    end
  end
  UIUtil.set_active(self._btn_gacha_detail, self._show_gacha_detail)
  s_current_owner = self
  self._is_showing = true
end

function M:_can_show_model(item_id)
  local model_path = CsUIUtil.GetPreviewAssetPath(item_id)
  if not string.is_valid(model_path) then
    return false
  end
  return not item_module:is_eyes(item_id) and not item_module:is_hair(item_id) and not item_module:item_is_recipe(item_id)
end

function M:_show_3d_model(item_id)
  ModelPreviewManagerIns.mode_auto_rotate = self._enable_auto_rotate
  local target = item_module:is_clothing(item_id) and self._trans_3d_cloth_model or self._trans_3d_model
  ModelPreviewManagerIns:show_item_by_id(target, item_id, self._on_model_loaded)
end

function M:_show_reaction_card(item_id)
  ModelPreviewManagerIns:show_react_item_by_id(self._trans_3d_model, self._avatar_dirty, item_id)
  self._avatar_dirty = false
end

function M:_show_luca_hold(item_id)
  local luca_cfg = ExcelDataUtil.get_value(typeof(BLucaHeartCfg), item_id)
  if is_null(luca_cfg) then
    self:_show_2d_icon(item_id)
    return
  end
  if not is_null(self._icon_luca) then
    UIUtil.set_active(self._icon_luca, true)
    local cfg = item_module:get_cfg_by_id(item_id)
    if cfg then
      UIUtil.set_image(self._icon_luca, cfg.icon, self._load_proxy)
    end
  end
  self:_refresh_luca_desc(luca_cfg)
  self:_play_video_by_cfg_id(luca_cfg.lucapreviewvideo)
end

function M:_refresh_luca_desc(luca_cfg)
  if is_null(self._txt_luca_desc) then
    return
  end
  local desc = luca_cfg.lucadescribe
  local has_desc = string.is_valid(desc)
  UIUtil.set_active(self._txt_luca_desc, has_desc)
  if has_desc then
    UIUtil.set_text(self._txt_luca_desc, desc)
  end
end

function M:_show_2d_icon(item_id)
  UIUtil.set_active(self._trans_ui_change_group_icon, true)
  local load_proxy = self._load_proxy
  local need_set_img = true
  local icon_style = ItemIconStyle.Normal
  if item_module:item_is_recipe(item_id) then
    icon_style = ItemIconStyle.Recipe
    item_module:set_recipe_card(self._img_bg, item_id, load_proxy)
  elseif item_module:item_is_cooking_recipe(item_id) then
    icon_style = ItemIconStyle.Cookbook
    item_module:set_cooking_recipe_card(self._img_bg, item_id, load_proxy)
  elseif item_module:is_unlock_appearance_card(item_id) then
    icon_style = ItemIconStyle.AppearanceCard
    item_module:set_appearance_unlock_card(self._img_bg, item_id, load_proxy)
    need_set_img = item_module:set_appearance_unlock_icon(self._img_icon, item_id, load_proxy)
  end
  self._ui_state_group_ui_change_group_icon:SetState(icon_style)
  if need_set_img and not is_null(self._img_icon) then
    UIUtil.set_image_color(self._img_icon, Color(1, 1, 1, 1))
    local cfg = item_module:get_cfg_by_id(item_id)
    if cfg then
      item_module:set_item_big_icon(self._img_icon, 0, cfg, load_proxy)
    end
  end
end

function M:_on_btn_gacha_detail_click()
  if self._gacha_detail_callback then
    self._gacha_detail_callback()
  end
end

function M:_on_pointer_down(evt)
  if not self._enable_touch_rotate then
    return
  end
  ModelPreviewManagerIns:on_pointer_down_on_model(evt)
end

function M:_on_drag(evt)
  if not self._enable_touch_rotate then
    return
  end
  ModelPreviewManagerIns:on_drag_model(evt)
end

function M:_on_pointer_up(evt)
  if not self._enable_touch_rotate then
    return
  end
  ModelPreviewManagerIns:on_pointer_up_on_model(evt)
end

function M:_show_video_preview()
  if is_null(self._trans_video) or is_null(self._img_video) then
    return
  end
  UIUtil.set_active(self._trans_video, true)
  self:_play_video_internal(self._video_path)
end

function M:_play_video_internal(video_path)
  self:_release_video_task()
  local task = VideoTask()
  task.displayType = DisplayType.LocalPartial
  task.screenImage = self._img_video
  task.path = video_path
  task.isLoop = self._video_loop
  self:_start_video_task(task)
end

function M:_play_video_by_cfg_id(video_cfg_id)
  if is_null(self._trans_video) or is_null(self._img_video) then
    return
  end
  self:_release_video_task()
  local task = VideoTask()
  if not task:InitByCfgId(video_cfg_id) then
    return
  end
  task.screenImage = self._img_video
  task.isLoop = true
  UIUtil.set_active(self._trans_video, true)
  self:_start_video_task(task)
end

function M:_start_video_task(task)
  function task.onStartPlay()
    if self._on_video_start then
      self._on_video_start()
    end
  end
  
  local function on_end()
    if self._on_video_finish then
      self._on_video_finish()
    end
  end
  
  task.onFinishPlay = on_end
  task.onPlayError = on_end
  self._video_task = task
  self._video_playing_id = CsVideoManagerUtil.Play(task)
end

function M:_release_video_task()
  if self._video_task then
    self._video_task.onStartPlay = nil
    self._video_task.onFinishPlay = nil
    self._video_task.onPlayError = nil
    self._video_task = nil
  end
  if self._video_playing_id ~= 0 then
    CsVideoManagerUtil.Stop(self._video_playing_id)
    self._video_playing_id = 0
  end
end

return M
