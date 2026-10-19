local M = G.Class("HomeRatingLevelAwardItem", G.UIPanel)
local base = G.UIPanel
local slider_min_height = 45
local slider_max_height = 175

function M:init()
  base.init(self)
  self._reward_items = {}
end

function M:refresh(cfg, score, current_level, index, total, next_cfg)
  self:_refresh_state(cfg, score, current_level, index, total)
  self:_refresh_info(cfg, score)
  self:_refresh_progress(cfg, score, next_cfg)
  self:_refresh_reward(cfg)
end

function M:_refresh_state(cfg, score, current_level, index, total)
  if index == 1 then
    self._state_group_pos:SetState(0)
  elseif index == total then
    self._state_group_pos:SetState(2)
  else
    self._state_group_pos:SetState(1)
  end
  if cfg.level == current_level then
    self._state_group_unlock:SetState(1)
  elseif current_level < cfg.level then
    self._state_group_unlock:SetState(0)
  else
    self._state_group_unlock:SetState(2)
  end
  self._state_group_award:SetState(score >= cfg.score and 1 or 0)
end

function M:_refresh_info(cfg, score)
  UIUtil.set_text(self._txt_lv, TextMapFormatUtil.FormatInteger(cfg.level))
  UIUtil.set_text_by_id(self._txt_title, "MiTai_Score_Level_Reward_Type1")
  if string.is_valid(cfg.rewarddesc) then
    UIUtil.set_text(self._txt_describe, cfg.rewarddesc)
  end
  UIUtil.set_active(self._txt_describe, string.is_valid(cfg.rewarddesc))
  local timestamp = CsMiTaiModuleUtil.GetScoreLevelUnlockedTime(cfg.level)
  if score >= cfg.score and timestamp and 0 < timestamp then
    local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(timestamp)
    UIUtil.set_text(self._txt_date, TextMapFormatUtil.FormatDateYMD(date_time))
  else
    UIUtil.set_text(self._txt_date, "")
  end
end

function M:_refresh_progress(cfg, score, next_cfg)
  local progress = 0
  if next_cfg and score >= next_cfg.score then
    progress = 1
  elseif next_cfg and score > cfg.score then
    local score_range = next_cfg.score - cfg.score
    if 0 < score_range then
      progress = (score - cfg.score) / score_range
    end
  end
  local height = slider_min_height + (slider_max_height - slider_min_height) * progress
  self._rect_slider:SetSizeDeltaY(height)
end

function M:_refresh_reward(cfg)
  local reward_id = cfg.garland_id or 0
  local item = self._reward_items[1]
  if 0 < reward_id and item_module:has_cfg_by_id(reward_id) then
    if item == nil then
      local trans = self._list_item:AddItem(0)
      item = self:add_panel(item_module.item_v2_panel_cls_name, trans)
      self._reward_items[1] = item
    end
    item:set_item_data(reward_id, 1)
    item:bind_item_info_btn(reward_id)
    item:set_active(true)
  elseif item then
    item:set_active(false)
  end
end

return M
