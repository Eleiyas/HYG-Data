local M = G.Class("ThemeSeasonChapterItem", G.UIPanel)
local base = G.UIPanel
local reward_item_cls = "UI/ThemeSeason/ThemeSeasonChapterRewardItem"
local CHAPTER_STATE = theme_season_module.CHAPTER_STATE

function M:init()
  base.init(self)
  self._data = nil
  self._index = 0
  self._chapters = nil
  self._reward_items = {}
  self._canvas_group = nil
  self._ui_state_group = nil
  self._img_num_dynamic = nil
  self._txt_title = nil
  self._img_bg_dynamic = nil
  self._list_binder = nil
  self._btn_chapter = nil
  self._txt_unlock_tip = nil
  self._red_point = nil
end

function M:on_create()
  base.on_create(self)
  self._canvas_group = UIUtil.find_cmpt(self.trans, nil, typeof(CanvasGroup))
  self:_add_ui_listener()
end

function M:on_destroy()
  self._data = nil
  self._chapters = nil
  self._reward_items = {}
  base.on_destroy(self)
end

function M:play_enter_anim()
  self:enter_anim_call_back()
end

function M:prepare_enter_anim()
  if self._has_binder then
    self.binder:StopAnimation(false)
  end
  if not_null(self._canvas_group) then
    self._canvas_group.alpha = 0
  end
end

function M:replay_anim(is_enter)
  if not self._has_binder then
    return
  end
  if is_enter then
    self.binder:PlayEnterAnim(nil)
  else
    self.binder:PlayExitAnim(nil)
  end
end

function M:_add_ui_listener()
  if not_null(self._btn_chapter) then
    self:bind_callback(self._btn_chapter, pack(self, M._on_chapter_click))
  end
end

function M:refresh(data, index, chapters)
  self._data = data
  self._index = index
  self._chapters = chapters
  self:_refresh_ui()
end

function M:_refresh_ui()
  local data = self._data
  if data == nil then
    return
  end
  self:_refresh_index_image()
  self:_refresh_banner()
  if not_null(self._txt_title) then
    UIUtil.set_text(self._txt_title, data.title or "")
  end
  self:_refresh_state(data.state)
  self:_refresh_unlock_tip()
  self:_refresh_reward_list()
  self:_refresh_red_point()
end

function M:_refresh_index_image()
  if is_null(self._img_num_dynamic) then
    return
  end
  UIUtil.set_number_image(self._img_num_dynamic, self._index, self:get_load_proxy())
end

function M:_refresh_banner()
  if is_null(self._img_bg_dynamic) then
    return
  end
  local banner_path = self._data and self._data.list_banner or ""
  if banner_path == "" then
    UIUtil.set_active(self._img_bg_dynamic, false)
    return
  end
  UIUtil.set_active(self._img_bg_dynamic, true)
  UIUtil.set_image(self._img_bg_dynamic, banner_path, self:get_load_proxy())
end

function M:_refresh_state(state)
  if not_null(self._ui_state_group) then
    self._ui_state_group:SetState(state)
  end
end

function M:_refresh_unlock_tip()
  if is_null(self._txt_unlock_tip) then
    return
  end
  local data = self._data
  if data == nil or data.state ~= CHAPTER_STATE.LOCKED then
    UIUtil.set_active(self._txt_unlock_tip, false)
    return
  end
  local reason = data.unlock_reason or theme_season_module.CHAPTER_UNLOCK_REASON.NONE
  if reason == theme_season_module.CHAPTER_UNLOCK_REASON.TIME then
    UIUtil.set_text(self._txt_unlock_tip, theme_season_module:format_unlock_remaining_time(data.unlock_remaining or 0))
    UIUtil.set_active(self._txt_unlock_tip, true)
  elseif reason == theme_season_module.CHAPTER_UNLOCK_REASON.PREV_TASK then
    UIUtil.set_text_by_id(self._txt_unlock_tip, "ThemeSeason_UI_021")
    UIUtil.set_active(self._txt_unlock_tip, true)
  else
    UIUtil.set_active(self._txt_unlock_tip, false)
  end
end

function M:_refresh_reward_list()
  if is_null(self._list_binder) then
    return
  end
  local rewards = self._data and self._data.rewards or {}
  local state = self._data and self._data.state or CHAPTER_STATE.LOCKED
  self._on_reward_item_click_cb = self._on_reward_item_click_cb or pack(self, M._on_reward_item_click)
  for i = 1, #rewards do
    local reward = rewards[i]
    local item = self._reward_items[i]
    if item == nil then
      local obj = self._list_binder:AddItem(0)
      item = self:add_panel(reward_item_cls, obj)
      self._reward_items[i] = item
    end
    if item then
      item:set_active(true)
      item:refresh_reward(reward.id, reward.num, state, self._on_reward_item_click_cb)
    end
  end
  for i = #rewards + 1, #self._reward_items do
    local item = self._reward_items[i]
    if item then
      item:set_active(false)
    end
  end
end

function M:_refresh_red_point()
  if is_null(self._red_point) then
    return
  end
  local claimable = self._data and self._data.state == CHAPTER_STATE.CLAIMABLE
  self._red_point:ShowRedPoint(claimable and RedPointType.GiftRP or RedPointType.None)
end

function M:_on_chapter_click()
  if self._chapters and #self._chapters > 0 then
    theme_season_module:open_chapter_detail_page(self._chapters, self._index)
  end
end

function M:_on_reward_item_click(item_id)
  local data = self._data
  if data == nil then
    return
  end
  if data.state == CHAPTER_STATE.CLAIMABLE then
    self:_claim_reward()
    return
  end
  if item_id and 0 < item_id then
    item_module:open_item_info_dialog(item_id, back_bag_module:get_coin_or_item_num(item_id))
  end
end

function M:_claim_reward()
  local bp_story_id = self._data and self._data.id or 0
  if bp_story_id <= 0 then
    return
  end
  CsThemeSeasonModuleUtil.SendStoryRewardClaimReq(bp_story_id)
end

return M
