local M = G.Class("LittleCornerAwardLevelItem", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._level = 0
end

function M:on_create()
  base.on_create(self)
  self._reward_items = {}
  self:bind_callback(self._btn_rights, function()
    little_corner_module:open_lv_rights_dialog(self._level)
  end)
  self:bind_callback(self._btn_get, function()
    if little_corner_module:can_claim_creator_level_reward(self._level) then
      little_corner_module:claim_creator_level_reward(self._level)
    end
  end)
end

function M:refresh(cfg, current_level, index, total, prev_cfg)
  if cfg == nil then
    return
  end
  self._level = cfg.level
  self._current_level = current_level
  self:_refresh_state(index, total)
  self:_refresh_info(cfg)
  self:_refresh_progress(prev_cfg)
  self:_refresh_reward(cfg)
end

function M:_refresh_state(index, total)
  if index <= 1 then
    self._state_group_pos:SetState(0)
  elseif total <= index then
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
  elseif little_corner_module:can_claim_creator_level_reward(self._level) then
    self._state_group_award:SetState(1)
  else
    self._state_group_award:SetState(2)
  end
end

function M:_refresh_info(cfg)
  UIUtil.set_text(self._txt_lv, tostring(self._level))
  local rights_desc = cfg.desc1 or ""
  if cfg.desc2 and cfg.desc2 ~= "" then
    rights_desc = rights_desc .. "\n" .. cfg.desc2
  end
  UIUtil.set_text(self._txt_describe, rights_desc)
end

function M:_refresh_progress(prev_cfg)
  local is_achieved = self._level <= self._current_level
  local progress_text = little_corner_module:get_exam_progress_text(prev_cfg, is_achieved)
  local has_progress = progress_text ~= nil and progress_text ~= ""
  UIUtil.set_active(self._txt_progress, has_progress)
  if has_progress then
    UIUtil.set_text(self._txt_progress, progress_text)
  end
end

function M:_refresh_reward(cfg)
  local count = cfg.rewarditemidlistLength
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

function M:get_btn()
  return self._btn
end

function M:get_level()
  return self._level
end

return M
