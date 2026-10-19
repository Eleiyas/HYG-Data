local M = G.Class("BlueprintArchitectLevelItem", G.UIPanel)
local base = G.UIPanel
local slider_min_height = 75
local slider_max_height = 175

function M:init()
  base.init(self)
  self._level = 0
end

function M:on_create()
  base.on_create(self)
  self._reward_items = {}
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:refresh(cfg, current_level)
  if cfg == nil then
    return
  end
  self._level = cfg.level
  self._current_level = current_level
  self:_refresh_state(cfg)
  self:_refresh_info(cfg)
  self:_refresh_reward()
end

function M:set_slider(progress)
  if self._rect_slider == nil then
    return
  end
  if progress < 0 then
    progress = 0
  elseif 1 < progress then
    progress = 1
  end
  local height = slider_min_height + (slider_max_height - slider_min_height) * progress
  self._rect_slider:SetSizeDeltaY(height)
end

function M:_refresh_state(cfg)
  if self._level == 1 then
    self._state_group_pos:SetState(0)
  elseif self._level == blueprint_habitat_module:get_architect_max_level() then
    self._state_group_pos:SetState(2)
  else
    self._state_group_pos:SetState(1)
  end
  if self._level == self._current_level then
    self._state_group_unlock:SetState(1)
  elseif self._level > self._current_level then
    self._state_group_unlock:SetState(0)
  else
    self._state_group_unlock:SetState(2)
  end
  if self._level > self._current_level then
    self._state_group_award:SetState(0)
  elseif blueprint_habitat_module:has_architect_level_reward(self._level) and not blueprint_habitat_module:has_architect_level_reward_claimed(self._level) then
    self._state_group_award:SetState(1)
  else
    self._state_group_award:SetState(2)
  end
end

function M:_refresh_info(cfg)
  UIUtil.set_text(self._txt_lv, tostring(self._level))
  UIUtil.set_text(self._txt_title, cfg.levelname)
  UIUtil.set_text(self._txt_describe, cfg.leveldescribe)
end

function M:_refresh_reward()
  local reward = blueprint_habitat_module:get_architect_level_reward_id(self._level)
  local reward_id = reward and reward.id or 0
  if 0 < reward_id and item_module:has_cfg_by_id(reward_id) then
    local item_cls = self._reward_items[1]
    if item_cls == nil then
      local obj = self._list_item:AddItem(0)
      item_cls = self:add_panel(item_module.item_v2_panel_cls_name, obj)
      self._reward_items[1] = item_cls
    end
    item_cls:set_active(true)
    item_cls:set_item_data(reward_id, reward.num or 1)
    item_cls:bind_item_info_btn(reward_id)
  elseif self._reward_items[1] then
    self._reward_items[1]:set_active(false)
  end
  for i = 2, #self._reward_items do
    local item = self._reward_items[i]
    if item then
      item:set_active(false)
    end
  end
end

function M:get_btn()
  return self._btn
end

function M:get_level()
  return self._level
end

return M
