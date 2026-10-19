local M = G.Class("ActivitySecretSantaPanel", "UI/ActivityCenter/SubPanel/ActivityBasePanel")
local base = G.ActivityBasePanel
local action_item_cls = "UI/ActivityCenter/SubPanel/SecretSanta/ActivitySecretSantaActionItem"

function M:init()
  base.init(self)
  self._reward_items = {}
end

function M:on_create()
  base.on_create(self)
  self._action_btn = self._layout_btn_binder:GetItem(0)
  self._action_btn_item = self:add_panel(action_item_cls, self._action_btn)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnSecretSantaUpdate, pack(self, self.refresh))
  self:add_evt_listener(EventID.LuaTrackingChange, pack(self, self._refresh_action))
  self:add_evt_listener(EventID.onDailyRefresh, pack(self, self.refresh))
end

function M:refresh()
  base.refresh(self)
  self:_refresh_dynamic_bg(self._img_bg)
  self:_refresh_rewards()
  self:_refresh_action()
  self:_refresh_red_point()
end

function M:update(delta_time)
  base.update(self, delta_time)
end

function M:_refresh_action()
  if self._action_btn_item == nil then
    return
  end
  local action = star_etiquette_module:get_activity_center_tracking_action()
  self._tracking_action = action
  self._state_group:SetState(action.state)
  local text = action.text
  if text == nil and action.text_id ~= nil then
    text = UIUtil.get_text_by_id(action.text_id)
  end
  if text ~= nil then
    self._action_btn_item:refresh(text, pack(self, M._on_action_click))
    UIUtil.set_text(self._text_lock, text)
  end
  if self._text_lock.gameObject.activeSelf then
    UIUtil.set_active(self._trans_lock, string.is_valid(text))
  else
    UIUtil.set_active(self._trans_lock, false)
  end
end

function M:_on_action_click()
  star_etiquette_module:execute_activity_center_tracking_action(self._tracking_action)
end

function M:_refresh_red_point()
  if is_null(self._red_point) then
    return
  end
  local red_point_type = star_etiquette_module:get_activity_center_reward_red_point_type()
  self._red_point:ShowRedPoint(red_point_type)
end

function M:_refresh_rewards()
  if is_null(self._layout_items_binder) then
    return
  end
  local reward_list = self:_get_reward_list()
  if #reward_list == 0 then
    for i = 1, #self._reward_items do
      self._reward_items[i]:set_active(false)
    end
    UIUtil.set_active(self._scroll_reward, false)
    UIUtil.set_active(self._trans_reward_title, false)
    return
  end
  UIUtil.set_active(self._scroll_reward, true)
  UIUtil.set_active(self._trans_reward_title, true)
  for i = 1, #reward_list do
    local reward_item = self._reward_items[i]
    if reward_item == nil then
      local obj = self._layout_items_binder:AddItem(0)
      if not_null(obj) then
        reward_item = self:add_panel(item_module.item_v2_panel_cls_name, obj)
        self._reward_items[i] = reward_item
        UIUtil.set_active(obj, true)
      end
    end
    if reward_item then
      local reward = reward_list[i]
      reward_item:set_item_data(reward.item_id, reward.count)
      reward_item:bind_item_info_btn(reward.item_id)
      reward_item:set_active(true)
    end
  end
  for i = #reward_list + 1, #self._reward_items do
    self._reward_items[i]:set_active(false)
  end
end

function M:_get_reward_list()
  local reward_list = {}
  local ui_cfg = activity_center_module:get_ui_cfg(self._activity_id)
  if ui_cfg == nil or not string.is_valid(ui_cfg.rewardlist) then
    return reward_list
  end
  for entry in string.gmatch(ui_cfg.rewardlist, "([^;]+)") do
    local item_id, count = string.match(string.gsub(entry, "%s+", ""), "^(%d+),(%d+)$")
    item_id = tonumber(item_id)
    count = tonumber(count)
    if item_id and count then
      table.insert(reward_list, {item_id = item_id, count = count})
    end
  end
  return reward_list
end

return M
