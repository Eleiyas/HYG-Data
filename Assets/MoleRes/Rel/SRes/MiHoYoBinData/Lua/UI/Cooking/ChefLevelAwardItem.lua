local M = G.Class("ChefLevelAwardItem", G.UIPanel)
local base = G.UIPanel
local slider_min_height = 75
local slider_max_height = 175
local award_state = {
  locked = 0,
  claimable = 1,
  claimed = 2,
  no_reward = 3
}

function M:init()
  base.init(self)
  self._level = 0
  self._has_reward = false
  self._reward_items = {}
end

function M:on_create()
  base.on_create(self)
  self:bind_callback(self._btn, pack(self, M._on_btn_claim_click))
end

function M:refresh(cfg, current_level, total)
  if is_null(cfg) then
    return
  end
  self._level = cfg.cheflevel or 0
  self._current_level = current_level or 0
  self._has_reward = 0 < (cfg.rewarditemidlistLength or 0)
  self:_refresh_state(total)
  self:_refresh_info(cfg)
  self:_refresh_reward(cfg)
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

function M:get_level()
  return self._level
end

function M:has_reward()
  return self._has_reward == true
end

function M:get_btn()
  return self._btn
end

function M:get_preferred_height()
  if not_null(self._layout_element) and self._layout_element.preferredHeight > 0 then
    return self._layout_element.preferredHeight
  end
  local rt = self.rect_trans or self.trans
  if not_null(rt) then
    return rt.rect.height
  end
  return 0
end

function M:_on_btn_claim_click()
  if cooking_module:can_claim_chef_level_reward(self._level) then
    cooking_module:claim_chef_level_reward(self._level)
  end
end

function M:_refresh_state(total)
  if self._level <= 1 then
    self._state_group_pos:SetState(0)
  elseif total <= self._level then
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
    if cooking_module:has_chef_level_reward(self._level) then
      self._state_group_award:SetState(award_state.locked)
    else
      self._state_group_award:SetState(award_state.no_reward)
    end
  elseif cooking_module:can_claim_chef_level_reward(self._level) then
    self._state_group_award:SetState(award_state.claimable)
  else
    self._state_group_award:SetState(award_state.claimed)
  end
end

function M:_refresh_info(cfg)
  UIUtil.set_text(self._txt_lv, tostring(self._level))
  self:_set_describe_text(self._txt_describe1 or self.txt_describe1, cfg.chefunlockdesc1 or "")
  self:_set_describe_text(self._txt_describe2, cfg.chefunlockdesc or "")
end

function M:_set_describe_text(txt, content)
  if is_null(txt) then
    return
  end
  local has = string.is_valid(content)
  UIUtil.set_active(txt, has)
  if has then
    UIUtil.set_text(txt, content)
  end
end

function M:_refresh_reward(cfg)
  local count = cfg.rewarditemidlistLength or 0
  local valid_count = 0
  for i = 0, count - 1 do
    local item_id = cfg:rewarditemidlist(i)
    local item_num = cfg:rewarditemcountlist(i)
    if 0 < item_id and item_module:has_cfg_by_id(item_id) then
      valid_count = valid_count + 1
      local reward_item = self._reward_items[valid_count]
      if reward_item == nil then
        local obj = self._list_item:AddItem(0)
        reward_item = self:add_panel(item_module.item_v2_panel_cls_name, obj)
        self._reward_items[valid_count] = reward_item
      end
      reward_item:set_active(true)
      reward_item:set_item_data(item_id, item_num)
      reward_item:bind_item_info_btn(item_id)
    end
  end
  for i = valid_count + 1, #self._reward_items do
    local reward_item = self._reward_items[i]
    if reward_item then
      reward_item:set_active(false)
    end
  end
end

return M
