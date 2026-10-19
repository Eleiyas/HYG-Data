local M = G.Class("CodexProgressBarPanel", G.UIPanel)
local base = G.UIPanel
local step_bg_item_class = "UI/Codex/TypePage/CodexStepBgItem"
local step_fg_item_class = "UI/Codex/TypePage/CodexStepFgItem"

function M:init()
  base.init(self)
  self._step_bg_items = {}
  self._step_fg_items = {}
  self._pixels_per_element = nil
  self._min_bar_width = 0
  self._force_icon_mode = false
  self._show_reward_icon = false
  self._skip_bg = false
  self._equal_spacing = nil
  self._equal_spacing_start = 0
  self._even_distribution = false
end

function M:get_slider()
  return self._slider_progress_bar
end

function M:set_slider_value(value)
  if not_null(self._slider_progress_bar) then
    self._slider_progress_bar.value = value
  end
end

function M:get_bar_width()
  if is_null(self._slider_progress_bar) then
    return nil
  end
  local slider_rect = self._slider_progress_bar:GetComponent(typeof(RectTransform))
  return slider_rect.rect.width
end

function M:set_dynamic_bar_config(pixels_per_element, min_width)
  self._pixels_per_element = pixels_per_element
  self._min_bar_width = min_width or 0
end

function M:set_force_icon_mode(enabled)
  self._force_icon_mode = enabled
end

function M:set_show_reward_icon(enabled)
  self._show_reward_icon = enabled
end

function M:set_skip_bg(enabled)
  self._skip_bg = enabled
end

function M:set_equal_spacing(spacing, start_offset)
  self._equal_spacing = spacing
  self._equal_spacing_start = start_offset or 0
end

function M:set_even_distribution(enabled)
  self._even_distribution = enabled
end

function M:apply_dynamic_bar_width(item_count)
  if not self._pixels_per_element or self._pixels_per_element <= 0 then
    return
  end
  if is_null(self._slider_progress_bar) then
    return
  end
  local ic = math.max(0, math.floor(item_count or 0))
  local target_w = math.max(self._min_bar_width or 0, ic * self._pixels_per_element)
  local slider_rect = self._slider_progress_bar:GetComponent(typeof(RectTransform))
  local sd = slider_rect.sizeDelta
  slider_rect.sizeDelta = Vector2(target_w, sd.y)
end

function M:set_steps(level_cfgs, item_count, unlocked_count, reward_type)
  if is_null(level_cfgs) then
    self:hide_all_steps()
    return
  end
  local use_equal = self._equal_spacing and self._equal_spacing > 0
  local use_even = self._even_distribution and not use_equal
  local total = #level_cfgs
  local bar_width
  if use_equal then
    bar_width = self._equal_spacing_start + (total - 1) * self._equal_spacing
    self:_set_bar_width(bar_width)
  else
    self:apply_dynamic_bar_width(item_count)
    bar_width = self:get_bar_width()
  end
  if not bar_width then
    return
  end
  local reward_show_map = self:_build_reward_show_map(level_cfgs, reward_type)
  local count = 0
  for i, cfg in ipairs(level_cfgs) do
    count = count + 1
    local show_type = reward_show_map and reward_show_map[cfg.num] or 0
    if show_type ~= 1 and show_type ~= 2 then
      show_type = 0
    end
    if self._force_icon_mode then
      show_type = 2
    end
    local bg = not self._skip_bg and self:_ensure_step_bg(i, show_type) or nil
    local fg = self:_ensure_step_fg(i, show_type)
    if bg then
      bg:refresh(cfg, item_count, bar_width, unlocked_count, show_type)
    end
    if fg then
      fg:refresh(cfg, item_count, bar_width, unlocked_count, show_type)
      if self._show_reward_icon then
        local reward_data = CsCodexModuleUtil.GetSubTypeLevelRewardData(cfg.subtype, cfg.level)
        if not_null(reward_data) then
          fg:_set_step_icon_from_reward_data(reward_data)
        end
      end
    end
    if use_equal then
      local pos_x = self._equal_spacing_start + (i - 1) * self._equal_spacing
      if bg then
        bg.rect_trans:SetAnchoredPosX(pos_x)
      end
      if fg then
        fg.rect_trans:SetAnchoredPosX(pos_x)
      end
    elseif use_even then
      local pos_x = bar_width * i / total
      if bg then
        bg.rect_trans:SetAnchoredPosX(pos_x)
      end
      if fg then
        fg.rect_trans:SetAnchoredPosX(pos_x)
      end
    end
  end
  if use_even then
    local nums = {}
    for i, cfg in ipairs(level_cfgs) do
      nums[i] = cfg.num
    end
    self:_apply_node_based_slider(nums, function(idx)
      return bar_width * idx / total
    end, total, bar_width, unlocked_count)
  end
  for i = count + 1, #self._step_bg_items do
    self._step_bg_items[i]:set_active(false)
  end
  for i = count + 1, #self._step_fg_items do
    self._step_fg_items[i]:set_active(false)
  end
end

function M:_build_reward_show_map(level_cfgs, reward_type)
  local first_cfg = level_cfgs[1]
  if not first_cfg then
    return nil
  end
  local sub_type_cfg = codex_module:get_sub_type_cfg(first_cfg.subtype)
  local tag = sub_type_cfg and sub_type_cfg.contenttag or nil
  if not tag or tag == "" then
    return nil
  end
  local all_rows = ExcelDataUtil.get_value(typeof(BCodexTagNumRewardCfg))
  if not all_rows then
    return nil
  end
  local map = {}
  for _, row in pairs(all_rows) do
    if not is_null(row) and row.tag == tag and (reward_type == nil or row.type == nil or row.type == reward_type) then
      map[row.num] = row.rewardshowtype
    end
  end
  return map
end

function M:build_tag_num_show_map(tag, reward_type)
  if not tag or tag == "" then
    return nil
  end
  local all_rows = ExcelDataUtil.get_value(typeof(BCodexTagNumRewardCfg))
  if not all_rows then
    return nil
  end
  local map = {}
  for _, row in pairs(all_rows) do
    if not is_null(row) and row.tag == tag and (reward_type == nil or row.type == nil or row.type == reward_type) then
      map[row.num] = row.rewardshowtype
    end
  end
  return map
end

function M:set_tag_num_steps(reward_list, item_count, unlocked_count, show_map)
  if not reward_list or #reward_list == 0 then
    self:hide_all_steps()
    return
  end
  local use_equal = self._equal_spacing and 0 < self._equal_spacing
  local use_even = self._even_distribution and not use_equal
  local total = #reward_list
  local bar_width
  if use_equal then
    bar_width = self._equal_spacing_start + (total - 1) * self._equal_spacing
    self:_set_bar_width(bar_width)
  else
    self:apply_dynamic_bar_width(item_count)
    bar_width = self:get_bar_width()
  end
  if not bar_width then
    return
  end
  local count = 0
  for i, reward_data in ipairs(reward_list) do
    count = count + 1
    local show_type = show_map and show_map[reward_data.Num] or 0
    if show_type ~= 1 and show_type ~= 2 then
      show_type = 0
    end
    if self._force_icon_mode then
      show_type = 2
    end
    local bg = not self._skip_bg and self:_ensure_step_bg(i, show_type) or nil
    local fg = self:_ensure_step_fg(i, show_type)
    if bg then
      bg:refresh_tag_num(reward_data, item_count, bar_width, unlocked_count, show_type)
    end
    if fg then
      fg:refresh_tag_num(reward_data, item_count, bar_width, unlocked_count, show_type)
      if self._show_reward_icon then
        fg:_set_step_icon_from_reward_data(reward_data)
      end
    end
    if use_equal then
      local pos_x = self._equal_spacing_start + (i - 1) * self._equal_spacing
      if bg then
        bg.rect_trans:SetAnchoredPosX(pos_x)
      end
      if fg then
        fg.rect_trans:SetAnchoredPosX(pos_x)
      end
    elseif use_even then
      local pos_x = bar_width * i / total
      if bg then
        bg.rect_trans:SetAnchoredPosX(pos_x)
      end
      if fg then
        fg.rect_trans:SetAnchoredPosX(pos_x)
      end
    end
  end
  if use_equal then
    self:_apply_equal_spacing_slider(reward_list, unlocked_count, bar_width)
  elseif use_even then
    local nums = {}
    for i, rd in ipairs(reward_list) do
      nums[i] = rd.Num or 0
    end
    self:_apply_node_based_slider(nums, function(idx)
      return bar_width * idx / total
    end, total, bar_width, unlocked_count)
  end
  for i = count + 1, #self._step_bg_items do
    self._step_bg_items[i]:set_active(false)
  end
  for i = count + 1, #self._step_fg_items do
    self._step_fg_items[i]:set_active(false)
  end
end

function M:set_creature_tag_steps(reward_list, item_count, current_count)
  if not reward_list or #reward_list == 0 then
    self:hide_all_steps()
    return
  end
  local use_even = self._even_distribution
  local total = #reward_list
  self:apply_dynamic_bar_width(item_count)
  local bar_width = self:get_bar_width()
  if not bar_width then
    return
  end
  local count = 0
  for i, reward_data in ipairs(reward_list) do
    count = count + 1
    local reward_cfg = ExcelDataUtil.get_value(typeof(BCodexTagNumRewardCfg), reward_data.ConfigId)
    local show_type = not is_null(reward_cfg) and reward_cfg.rewardshowtype or 0
    if show_type ~= 1 and show_type ~= 2 then
      show_type = 0
    end
    local bg = self:_ensure_step_bg(i, show_type)
    local fg = self:_ensure_step_fg(i, show_type)
    if bg then
      bg:refresh_creature_tag(reward_data, item_count, bar_width, current_count, show_type)
    end
    if fg then
      fg:refresh_creature_tag(reward_data, item_count, bar_width, current_count, show_type)
    end
    if use_even then
      local pos_x = bar_width * i / total
      if bg then
        bg.rect_trans:SetAnchoredPosX(pos_x)
      end
      if fg then
        fg.rect_trans:SetAnchoredPosX(pos_x)
      end
    end
  end
  if use_even then
    local nums = {}
    for i, rd in ipairs(reward_list) do
      nums[i] = rd.CreatureNum or 0
    end
    self:_apply_node_based_slider(nums, function(idx)
      return bar_width * idx / total
    end, total, bar_width, current_count)
  end
  for i = count + 1, #self._step_bg_items do
    self._step_bg_items[i]:set_active(false)
  end
  for i = count + 1, #self._step_fg_items do
    self._step_fg_items[i]:set_active(false)
  end
end

function M:hide_all_steps()
  for i = 1, #self._step_bg_items do
    self._step_bg_items[i]:set_active(false)
  end
  for i = 1, #self._step_fg_items do
    self._step_fg_items[i]:set_active(false)
  end
end

function M:toggle_progress_tips(cfg, anchor_rect)
  if self.holder and self.holder.toggle_progress_tips then
    self.holder:toggle_progress_tips(cfg, anchor_rect)
  end
end

function M:toggle_tag_num_reward_tips(reward_data, anchor_rect)
  if self.holder and self.holder.toggle_tag_num_reward_tips then
    self.holder:toggle_tag_num_reward_tips(reward_data, anchor_rect)
  end
end

function M:toggle_creature_tag_reward_tips(reward_data, anchor_rect)
  if self.holder and self.holder.toggle_creature_tag_reward_tips then
    self.holder:toggle_creature_tag_reward_tips(reward_data, anchor_rect)
  end
end

function M:toggle_icon_reward_tips(data, anchor_rect)
  if self.holder and self.holder.toggle_icon_reward_tips then
    self.holder:toggle_icon_reward_tips(data, anchor_rect)
  end
end

function M:claim_all_progress_rewards()
  if self.holder and self.holder.claim_all_progress_rewards then
    self.holder:claim_all_progress_rewards()
  end
end

function M:_close_progress_tips()
  if self.holder and self.holder._close_progress_tips then
    self.holder:_close_progress_tips()
  end
end

function M:_ensure_step_bg(index, show_type)
  local existing = self._step_bg_items[index]
  if existing and existing._show_type == show_type then
    return existing
  end
  if existing then
    self:remove_panel(existing)
    self._step_bg_items[index] = nil
  end
  local template
  if 1 <= show_type then
    template = self._trans_hide_step_icon_bg
  else
    template = self._trans_hide_step_big_bg
  end
  if is_null(template) or is_null(self._trans_bg_root) then
    return nil
  end
  local obj = UIUtil.load_prefab_set_parent(template, self._trans_bg_root)
  local panel = self:add_panel(step_bg_item_class, obj)
  panel._show_type = show_type
  self._step_bg_items[index] = panel
  return panel
end

function M:_ensure_step_fg(index, show_type)
  local existing = self._step_fg_items[index]
  if existing and existing._show_type == show_type then
    return existing
  end
  if existing then
    self:remove_panel(existing)
    self._step_fg_items[index] = nil
  end
  local template
  if 1 <= show_type then
    template = self._trans_hide_step_icon
  else
    template = self._trans_hide_step_big
  end
  if is_null(template) or is_null(self._trans_fg_root) then
    return nil
  end
  local obj = UIUtil.load_prefab_set_parent(template, self._trans_fg_root)
  local panel = self:add_panel(step_fg_item_class, obj)
  panel._show_type = show_type
  self._step_fg_items[index] = panel
  return panel
end

function M:_set_bar_width(width)
  if is_null(self._slider_progress_bar) then
    return
  end
  local slider_rect = self._slider_progress_bar:GetComponent(typeof(RectTransform))
  local sd = slider_rect.sizeDelta
  slider_rect.sizeDelta = Vector2(width, sd.y)
end

function M:_apply_node_based_slider(nums, node_x, count, bar_width, unlocked_count)
  if is_null(self._slider_progress_bar) or bar_width <= 0 or count <= 0 then
    return
  end
  local passed = 0
  for i = 1, count do
    if unlocked_count >= (nums[i] or 0) then
      passed = i
    else
      break
    end
  end
  local pos
  if count <= passed then
    pos = node_x(count)
  elseif passed == 0 then
    local first_num = nums[1] or 0
    local frac = 0 < first_num and unlocked_count / first_num or 0
    pos = node_x(1) * math.min(1, math.max(0, frac))
  else
    local cur_num = nums[passed] or 0
    local next_num = nums[passed + 1] or cur_num
    local frac = cur_num < next_num and (unlocked_count - cur_num) / (next_num - cur_num) or 0
    frac = math.min(1, math.max(0, frac))
    local cur_x = node_x(passed)
    pos = cur_x + (node_x(passed + 1) - cur_x) * frac
  end
  self._slider_progress_bar.value = math.min(1, math.max(0, pos / bar_width))
end

function M:_apply_equal_spacing_slider(reward_list, unlocked_count, bar_width)
  local count = #reward_list
  local nums = {}
  for i, rd in ipairs(reward_list) do
    nums[i] = rd.Num or rd.CreatureNum or 0
  end
  
  local function node_x(idx)
    return self._equal_spacing_start + (idx - 1) * self._equal_spacing
  end
  
  self:_apply_node_based_slider(nums, node_x, count, bar_width, unlocked_count)
end

return M
