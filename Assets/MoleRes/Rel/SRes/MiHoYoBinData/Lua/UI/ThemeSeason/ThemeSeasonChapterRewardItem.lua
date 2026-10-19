local ItemV2Panel = require("UI/Item/ItemV2Panel")
local M = G.Class("ThemeSeasonChapterRewardItem", ItemV2Panel)
local base = ItemV2Panel
local CHAPTER_STATE = theme_season_module.CHAPTER_STATE
local STATE_TO_GET_VISUAL = {
  [CHAPTER_STATE.IN_PROGRESS] = 0,
  [CHAPTER_STATE.CLAIMABLE] = 1,
  [CHAPTER_STATE.CLAIMED] = 2,
  [CHAPTER_STATE.LOCKED] = 0
}
local STATE_TO_LOCK_VISUAL = {
  [CHAPTER_STATE.LOCKED] = 0,
  [CHAPTER_STATE.IN_PROGRESS] = 1,
  [CHAPTER_STATE.CLAIMABLE] = 1,
  [CHAPTER_STATE.CLAIMED] = 1
}

function M:init()
  base.init(self)
  self._chapter_state = CHAPTER_STATE.LOCKED
  self._item_id = 0
  self._on_click_callback = nil
  self._ui_state_group_get = nil
  self._ui_state_group_lock = nil
end

function M:on_create()
  base.on_create(self)
  if not_null(self._btn) then
    self:bind_callback(self._btn, pack(self, M._on_click))
  end
end

function M:_on_click()
  if self._on_click_callback then
    self._on_click_callback(self._item_id)
  end
end

function M:refresh_reward(item_id, num, chapter_state, on_click)
  self:set_item_data(item_id, num)
  self._item_id = item_id or 0
  self._chapter_state = chapter_state or CHAPTER_STATE.LOCKED
  self._on_click_callback = on_click
  self:_refresh_state_groups()
  self:_refresh_red_point()
end

function M:_refresh_red_point()
  self:set_red_point(self._chapter_state == CHAPTER_STATE.CLAIMABLE, RedPointType.GiftRP)
end

function M:_refresh_state_groups()
  if not_null(self._ui_state_group_get) then
    self._ui_state_group_get:SetState(STATE_TO_GET_VISUAL[self._chapter_state] or 0)
  end
  if not_null(self._ui_state_group_lock) then
    self._ui_state_group_lock:SetState(STATE_TO_LOCK_VISUAL[self._chapter_state] or 1)
  end
end

return M
