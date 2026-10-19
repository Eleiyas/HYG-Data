local MISSION_STATE = theme_season_module.DAILY_MISSION_STATE
local M = G.Class("ThemeSeasonDailyItem", G.UIPanel)
local base = G.UIPanel
local reward_item_cls = "UI/ThemeSeason/ThemeSeasonDailyRewardItem"

function M:init()
  base.init(self)
  self._reward_items = {}
  self._state_group = nil
  self._txt_title = nil
  self._txt_desc = nil
  self._txt_num = nil
  self._img_icon = nil
  self._list_reward = nil
  self._btn_item = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_btn_listener()
end

function M:_add_btn_listener()
  self:bind_callback(self._btn_item, pack(self, self._on_reward_click))
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:get_tracker_id()
  return self._extra_data or 0
end

function M:_on_reward_click()
  local tracker_id = self:get_tracker_id()
  if tracker_id <= 0 then
    return
  end
  if theme_season_module:get_daily_mission_state(tracker_id) ~= MISSION_STATE.CLAIMABLE then
    return
  end
  if self.holder then
    self.holder:request_claim_reward(tracker_id)
  end
end

function M:refresh_view()
  local tracker_id = self._extra_data
  self:set_active(tracker_id ~= nil)
  if tracker_id == nil then
    return
  end
  local mission = theme_season_module:get_daily_mission_by_tracker(tracker_id)
  if mission == nil then
    self:set_active(false)
    return
  end
  self.game_obj.name = tostring(tracker_id)
  self:_refresh_text(tracker_id, mission)
  self:_refresh_icon(tracker_id)
  self:_refresh_reward(tracker_id)
  self:_refresh_state(tracker_id)
end

function M:_refresh_reward(tracker_id)
  if is_null(self._list_reward) then
    return
  end
  local rewards = theme_season_module:get_daily_mission_rewards(tracker_id)
  local state = theme_season_module:get_daily_mission_state(tracker_id)
  for i, reward in ipairs(rewards) do
    local item = self._reward_items[i]
    if item == nil then
      local obj = self._list_reward:AddItem(0)
      if not_null(obj) then
        item = self:add_panel(reward_item_cls, obj)
        self._reward_items[i] = item
      end
    end
    if item ~= nil then
      item:set_active(true)
      item:refresh(reward, state)
    end
  end
  for i = #rewards + 1, #self._reward_items do
    self._reward_items[i]:set_active(false)
  end
end

function M:_refresh_text(tracker_id, mission)
  local title = theme_season_module:get_daily_mission_title(tracker_id)
  if not_null(self._txt_title) and title ~= nil then
    UIUtil.set_text_by_id(self._txt_title, title)
  end
  local desc = theme_season_module:get_daily_mission_desc(tracker_id)
  if not_null(self._txt_desc) and desc ~= nil then
    UIUtil.set_text_by_id(self._txt_desc, desc)
  end
  if not_null(self._txt_num) then
    UIUtil.set_text_by_id(self._txt_num, "ThemeSeasonDaily_UI_041", mission.cur_progress, mission.total_progress)
  end
end

function M:_refresh_icon(tracker_id)
  if is_null(self._img_icon) then
    return
  end
  local icon = theme_season_module:get_daily_mission_type_icon(tracker_id)
  if icon ~= nil then
    UIUtil.set_active(self._img_icon, true)
    UIUtil.set_image(self._img_icon, icon, self:get_load_proxy())
  else
    UIUtil.set_active(self._img_icon, false)
  end
end

function M:_refresh_state(tracker_id)
  if not_null(self._state_group) then
    local state = theme_season_module:get_daily_mission_state(tracker_id)
    self._state_group:SetState(state)
  end
end

return M
