local M = G.Class("CodexScoreProgressPage", G.UIPanel)
local base = G.UIPanel
local Phase = {
  INIT = 0,
  PROGRESS = 1,
  WAIT_TAP = 2,
  SCROLL = 3,
  REWARD = 4
}
local ProgressMode = {
  NONE = 0,
  GROW_IN_VIEW = 1,
  GROW_SCROLL = 2
}
local IN_VIEW_TOTAL_DURATION = 2
local IN_VIEW_SLIDER_DURATION = 1
local SCROLL_TOTAL_DURATION = 2.5
local SCROLL_SLIDER_DURATION = 2
local HEAD_EDGE_PADDING = 200
local Trigger = {
  NONE = "none",
  RUN_IN_VIEW = "run_once",
  REWARD_IN_VIEW = "scroll_once",
  RUN_SCROLL = "run",
  REWARD_SCROLL = "scroll"
}
local CodexScoreProgressItem = require("UI/Codex/CodexScoreProgressItem")
local reward_group_title_class = "UI/Codex/CodexScoreProgressGroupTitle"
local round_progress_item_class = "UI/Codex/CodexScoreProgressRoundItem"
local category_detail_panel_class = "UI/Codex/CodexScoreCategoryDetailPanel"
local RISE_ITEM_SCORE_PATH = "txt_num"
local ScoreCategory = {
  Creature = 1,
  Plant = 2,
  Cloth = 3,
  Food = 4,
  Furniture = 5
}
local ScoreCategoryOrder = {
  ScoreCategory.Creature,
  ScoreCategory.Plant,
  ScoreCategory.Cloth,
  ScoreCategory.Food,
  ScoreCategory.Furniture
}
local ScoreCategoryMeta = {
  [ScoreCategory.Creature] = {
    title = "Codex_Creature",
    icon = "UISprite/Load/TabIcon/Icon_Common_Tab_Organism"
  },
  [ScoreCategory.Plant] = {
    title = "Codex_Plant",
    icon = "UISprite/Load/TabIcon/Icon_Common_Tab_Plant"
  },
  [ScoreCategory.Cloth] = {
    title = "Codex_Clothes",
    icon = "UISprite/Load/TabIcon/Icon_Common_Tab_Clothe"
  },
  [ScoreCategory.Food] = {
    title = "Codex_Food",
    icon = "UISprite/Load/TabIcon/Tab_Icon_Ugc_003_c"
  },
  [ScoreCategory.Furniture] = {
    title = "Codex_Furniture",
    icon = "UISprite/Load/TabIcon/Icon_Common_Tab_Furniture"
  }
}
local CREATURE_MAX_STAR = 3

local function get_rise_row_score(row)
  local total_score = 0
  if row and row.add_score then
    for i = 1, #row.add_score do
      total_score = total_score + (row.add_score[i] or 0)
    end
  end
  return total_score
end

local function get_rise_row_quality(row)
  local current_data = row and row.changed_data and row.changed_data.curr_data or nil
  local item_cfg = current_data and current_data.ItemCfg or nil
  return item_cfg and (item_cfg.rank or 0) or 0
end

local function sort_rise_rows(rows)
  local decorated_rows = {}
  for original_index, row in ipairs(rows) do
    decorated_rows[original_index] = {
      row = row,
      quality = get_rise_row_quality(row),
      score = get_rise_row_score(row),
      original_index = original_index
    }
  end
  table.sort(decorated_rows, function(left_entry, right_entry)
    if left_entry.quality ~= right_entry.quality then
      return left_entry.quality > right_entry.quality
    end
    if left_entry.score ~= right_entry.score then
      return left_entry.score > right_entry.score
    end
    return left_entry.original_index < right_entry.original_index
  end)
  for sorted_index, entry in ipairs(decorated_rows) do
    rows[sorted_index] = entry.row
  end
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexScoreProgressPage"
  self._phase = Phase.INIT
  self._on_complete = nil
  self._total_score_data = nil
  self._prev_score = 0
  self._curr_score = 0
  self._score_cfgs = nil
  self._rewarded_id_table = nil
  self._max_score = 0
  self._items = {}
  self._progress_timer = 0
  self._progress_mode = ProgressMode.NONE
  self._progress_duration = 0
  self._slider_duration = 0
  self._entrance_scroll = 0
  self._reward_item_cls_list = {}
  self._reward_groups = {}
  self._reward_item_cls_map = {}
  self._reward_title_cls_map = {}
  self._score_category_data = {}
  self._selected_score_category = ScoreCategory.Creature
  self._progress_icon_items = {}
  self._create_items_co = nil
  self._progress_info_panel = nil
  self._progress_info_visible = false
end

function M:on_create()
  base.on_create(self)
  self:_set_initialization_visible(false)
  self:_init_derived_refs()
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  if self._total_score_data == nil then
    local total_score_data = CsCodexModuleUtil.CodexTotalScoreData
    if not is_null(total_score_data) then
      self:show(total_score_data)
    end
  end
end

function M:on_disable()
  base.on_disable(self)
  self:_set_initialization_visible(false)
  self:_close_reward_scroller()
  if self._create_items_co then
    CsCoroutineManagerUtil.StopCoroutine(self._create_items_co)
    self._create_items_co = nil
  end
  self._phase = Phase.INIT
  self._total_score_data = nil
  self._changed_data_list = nil
  self._progress_info_visible = false
  if not_null(self._trans_popup_tip) then
    UIUtil.set_active(self._trans_popup_tip, false)
  end
  if not_null(self._btn_bg) then
    UIUtil.set_active(self._btn_bg, false)
  end
end

function M:_set_initialization_visible(visible)
  if not self.trans then
    return
  end
  local scale = visible and 1 or 0
  self.trans:SetLocalScale(scale, scale, scale)
end

function M:_init_derived_refs()
  self._trans_reward_list_content = UIUtil.find_trans(self._trans_reward_group, "ScrollHorizontalList/viewport/content")
  if is_null(self._trans_reward_list_content) then
    self._trans_reward_list_content = UIUtil.find_trans(self._trans_reward_group, "ScrollHorizontalList/viewport")
  end
  if is_null(self._trans_reward_list_content) then
    self._trans_reward_list_content = UIUtil.find_trans(self._trans_reward_group, "ScrollHorizontalList")
  end
  if not_null(self._trans_popup_tip) then
    UIUtil.set_active(self._trans_popup_tip, false)
  end
end

function M:_add_ui_listener()
  if not_null(self._btn_bg) then
    self:bind_callback(self._btn_bg, pack(self, M.on_screen_tap))
  end
  self:bind_callback(self._btn_confirm_score, pack(self, M.on_screen_tap))
  self:bind_callback(self._btn_close, pack(self, M._on_close_btn))
  self:bind_input_and_fun(ActionType.Act.Back, M._on_esc)
  self:bind_callback(self._btn_progress_info, pack(self, M._on_btn_progress_info))
end

function M:show(total_score_data, on_complete)
  if is_null(total_score_data) then
    return
  end
  self._on_complete = on_complete
  self._total_score_data = total_score_data
  self:set_active(true)
  UIUtil.set_active(self.trans, true)
  self:_set_initialization_visible(false)
  UIUtil.set_text(self._txt_title_in_progress, "")
  self:_init_data()
  self:set_score_title()
  self._changed_data_list = codex_module:get_changed_data_list()
  self:_init_score_category_data()
  self:_destroy_progress_items()
  self:_create_progress_items(function()
    self:_ensure_content_layout()
    self:_init_sliders()
    self:_create_round_progress_items()
    self:_refresh_category_progress(0)
    self:_hide_result_reward()
    self:_set_scroll_input_enabled(false)
    self:_set_tap_catcher_active(true)
    self:_refresh_items_by_score(self._prev_score)
    self:_align_content_to_score(self._prev_score)
    self:_start_progress_phase()
    self:_set_initialization_visible(true)
  end)
end

function M:hide()
  self:set_active(false)
  UIUtil.set_active(self.trans, false)
  self._phase = Phase.INIT
end

function M:_init_data()
  local data = self._total_score_data
  self._curr_score = data.TotalScore
  self._prev_score = data.LastShownData.TotalScore
  self._score_cfgs = codex_module:get_total_score_cfgs()
  self._max_score = 0
  if #self._score_cfgs > 0 then
    self._max_score = self._score_cfgs[#self._score_cfgs].needtotalscore
  end
  self._rewarded_id_table = {}
  local rewarded_ids = list_to_table(data.RewardedLevelIdList)
  for i = 1, #rewarded_ids do
    self._rewarded_id_table[rewarded_ids[i]] = true
  end
end

function M:_destroy_progress_items()
  for i = 1, #self._items do
    local item = self._items[i]
    if item ~= nil then
      if item.clear_cache then
        item:clear_cache()
      end
      if not is_null(item.game_obj) then
        UIUtil.set_active(item.game_obj, false)
      end
    end
  end
end

local PROGRESS_ITEMS_PER_FRAME = 10

function M:_create_progress_items(on_complete)
  UIUtil.set_active(self._trans_item, false)
  UIUtil.set_active(self._trans_item_final, false)
  local need_count = #self._score_cfgs
  local total = #self._score_cfgs
  local index = 1
  for i = need_count + 1, #self._items do
    local item = self._items[i]
    if item ~= nil and not is_null(item.game_obj) then
      UIUtil.set_active(item.game_obj, false)
    end
  end
  
  local function create_one(i)
    local cfg = self._score_cfgs[i]
    local is_final = i == total
    local item = self._items[i]
    if item == nil then
      local template = is_final and self._trans_item_final or self._trans_item
      local class_path = is_final and "UI/Codex/CodexScoreProgressItemFinal" or "UI/Codex/CodexScoreProgressItem"
      local go = UIUtil.load_prefab_set_parent(template, self._trans_content)
      if not_null(go) then
        go.name = template.name .. "_" .. tostring(i)
        UIUtil.set_active(go, true)
        item = self:add_panel(class_path, go)
        if item ~= nil then
          item:set_claim_callback(function()
            self:_on_claim_reward()
          end)
          self._items[i] = item
        end
      end
    elseif not is_null(item.game_obj) then
      UIUtil.set_active(item.game_obj, true)
    end
    if item ~= nil and item.set_data then
      item:set_data(cfg, i)
    end
  end
  
  local has_new = false
  for i = 1, total do
    if self._items[i] == nil then
      has_new = true
      break
    end
  end
  if not has_new then
    for i = 1, total do
      create_one(i)
    end
    if on_complete then
      on_complete()
    end
    return
  end
  
  local function step()
    local batch_end = math.min(index + PROGRESS_ITEMS_PER_FRAME - 1, total)
    for i = index, batch_end do
      create_one(i)
    end
    index = batch_end + 1
    if index <= total then
      self._create_items_co = CsCoroutineManagerUtil.InvokeNextFrame(step)
    else
      self._create_items_co = nil
      if on_complete then
        on_complete()
      end
    end
  end
  
  step()
end

function M:_refresh_items()
  self:_refresh_items_by_score(self._curr_score, true)
end

function M:_refresh_items_by_score(score, show_reward)
  for i = 1, #self._items do
    self._items[i]:refresh_by_score(score, self._total_score_data, self._rewarded_id_table, self:get_load_proxy(), show_reward)
  end
end

function M:_init_sliders()
  if self._max_score <= 0 then
    return
  end
  local prev_norm = self:_score_to_norm(self._prev_score)
  local curr_norm = self:_score_to_norm(self._curr_score)
  local first_x, last_x = self:_get_item_center_x_span()
  local content_width = not is_null(self._trans_content) and self._trans_content.rect.width or 0
  print(string.format("[CodexScoreProgress] prev=%s curr=%s prev_norm=%.4f curr_norm=%.4f node_prev=%.4f node_curr=%.4f first_x=%.1f last_x=%.1f content_w=%.1f", tostring(self._prev_score), tostring(self._curr_score), prev_norm, curr_norm, self:_score_to_node_progress(self._prev_score), self:_score_to_node_progress(self._curr_score), first_x, last_x, content_width))
  if not_null(self._slider_main) then
    self._slider_main.value = prev_norm
  end
  if not_null(self._slider_add) then
    self._slider_add.value = prev_norm
  end
  if not_null(self._slider_icon) then
    self._slider_icon.value = prev_norm
  end
end

function M:_start_progress_phase()
  self._progress_mode = self:_resolve_progress_mode()
  self:_set_scroll_input_enabled(false)
  self._entrance_scroll = self:_calc_target_scroll_x(self._prev_score)
  if self._progress_mode == ProgressMode.NONE then
    self:_align_content_to_score(self._curr_score)
    self:_set_final_item_scale(0.72)
    self:_play_anim(Trigger.NONE)
    self:_enter_reward_phase()
    return
  end
  if not_null(self._txt_num_add) then
    UIUtil.set_text(self._txt_num_add, self._curr_score - self._prev_score)
  end
  self:_set_title_by_score(self._prev_score)
  self:_check_passing_items(self._prev_score)
  if not_null(self._txt_cur_num) then
    UIUtil.set_text(self._txt_cur_num, math.floor(self._prev_score))
  end
  self._phase = Phase.PROGRESS
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    self:_refresh_reward_group()
  end)
  self._progress_timer = 0
  self:_set_final_item_scale(1)
  if self._progress_mode == ProgressMode.GROW_SCROLL then
    self._progress_duration = SCROLL_TOTAL_DURATION
    self._slider_duration = SCROLL_SLIDER_DURATION
    self:_play_anim(Trigger.RUN_SCROLL)
  else
    self._progress_duration = IN_VIEW_TOTAL_DURATION
    self._slider_duration = IN_VIEW_SLIDER_DURATION
    self:_play_anim(Trigger.RUN_IN_VIEW)
  end
end

function M:_enter_wait_tap_phase()
  self._phase = Phase.WAIT_TAP
end

function M:_enter_scroll_phase()
  self._phase = Phase.SCROLL
  self:_set_scroll_input_enabled(false)
  self:_set_slider_main_to_current_score()
  self:_play_final_smaller()
  local trigger = self._progress_mode == ProgressMode.GROW_SCROLL and Trigger.REWARD_SCROLL or Trigger.REWARD_IN_VIEW
  self:_play_anim(trigger, function()
    self:_enter_reward_phase()
  end)
end

function M:_enter_reward_phase()
  self._phase = Phase.REWARD
  self:_set_tap_catcher_active(false)
  self:_set_all_sliders_to_current_score()
  self:_refresh_category_progress()
  self:_refresh_items()
  UIUtil.set_active(self._trans_reward_group, true)
  self:_open_claim_panels()
  self:_set_scroll_input_enabled(true)
end

function M:update(deltaTime)
  if base.update then
    base.update(self, deltaTime)
  end
  if self._phase == Phase.PROGRESS then
    self:_update_progress(deltaTime)
  end
end

function M:_update_progress(dt)
  self._progress_timer = self._progress_timer + dt
  local slider_t = self._slider_duration > 0 and math.min(self._progress_timer / self._slider_duration, 1) or 1
  local slider_eased = self:_sample_slider_curve(slider_t)
  local score = self._prev_score + (self._curr_score - self._prev_score) * slider_eased
  self:_set_add_sliders_value(self:_score_to_norm(score))
  self:_refresh_category_progress(slider_eased)
  if not_null(self._txt_cur_num) then
    UIUtil.set_text(self._txt_cur_num, math.floor(score))
  end
  self:_check_passing_items(score)
  self:_update_content_follow(score)
  if self._progress_timer >= self._progress_duration then
    self:_set_add_sliders_value(self:_score_to_norm(self._curr_score))
    self:_refresh_category_progress(1)
    self:_check_passing_items(self._curr_score)
    self:_update_content_follow(self._curr_score)
    self:_enter_wait_tap_phase()
  end
end

function M:_update_content_follow(score)
  if is_null(self._scrollrect_main) or is_null(self._trans_content) then
    return
  end
  local viewport_rt = self._scrollrect_main.viewport
  if is_null(viewport_rt) then
    return
  end
  local viewport_width = viewport_rt.rect.width
  local content_width = self._trans_content.rect.width
  local max_left = math.max(content_width - viewport_width, 0)
  if max_left <= 0 then
    return
  end
  local head_x = self:_score_to_content_x(score)
  local follow_scroll = head_x - (viewport_width - HEAD_EDGE_PADDING)
  local scroll_x = math.max(self._entrance_scroll, follow_scroll)
  scroll_x = math.max(0, math.min(scroll_x, max_left))
  self:_set_scroll_x(scroll_x)
end

function M:_sample_slider_curve(t)
  if not_null(self._curve_slider_add) and self._curve_slider_add.Evaluate then
    return self._curve_slider_add:Evaluate(t)
  end
  return self:_ease_in_out(t)
end

function M:_init_score_category_data()
  self._score_category_data = {}
  for _, category in ipairs(ScoreCategoryOrder) do
    local codex_type = self:_get_codex_type_by_category(category)
    local cs_info = CsCodexModuleUtil.GetScoreCategoryInfo(codex_type)
    self._score_category_data[category] = {
      category = category,
      current_score = cs_info.currentScore or 0,
      add_score = 0,
      full_score = cs_info.fullScore or 0
    }
  end
  local changed_data_list = self._changed_data_list or {}
  for i = 1, #changed_data_list do
    local changed_data = changed_data_list[i]
    local curr_data = changed_data.curr_data
    local category = self:_get_score_category(curr_data)
    if category ~= nil then
      self._score_category_data[category].add_score = self._score_category_data[category].add_score + (changed_data.total_add_score or 0)
    end
  end
  self._selected_score_category = self:_resolve_default_score_category()
end

function M:_accumulate_category_score(data)
  if is_null(data) or data.IsPackage then
    return
  end
  local category = self:_get_score_category(data)
  if category == nil then
    return
  end
  local server_data = data.ServerData
  local score = 0
  if not_null(server_data) then
    score = server_data.AddTotalScore or 0
  end
  self._score_category_data[category].current_score = self._score_category_data[category].current_score + score
  self._score_category_data[category].full_score = self._score_category_data[category].full_score + self:_get_entry_full_score(data)
end

function M:_get_entry_full_score(data)
  if is_null(data) then
    return 0
  end
  if data.Type == CodexDataType.Creature then
    local sub_type_ctrl = codex_module:get_sub_type_controller(data.Type, data.SubType)
    local sub_type_cfg = sub_type_ctrl and sub_type_ctrl:get_sub_type_cfg() or nil
    local tag = sub_type_cfg and sub_type_cfg.contenttag or nil
    local rank = data.ItemCfg and data.ItemCfg.rank or 0
    if tag == nil then
      return 0
    end
    return codex_module:get_creature_star_score(tag, rank, CREATURE_MAX_STAR)
  end
  local codex_cfg = data.CodexCfg
  return codex_cfg and (codex_cfg.totalscorepoints or 0) or 0
end

function M:_get_score_category(data)
  if is_null(data) then
    return nil
  end
  return self:_get_score_category_by_type(data.Type)
end

function M:_get_score_category_by_type(codex_type)
  if codex_type == CodexDataType.Creature then
    return ScoreCategory.Creature
  elseif codex_type == CodexDataType.Plant then
    return ScoreCategory.Plant
  elseif codex_type == CodexDataType.Cloth then
    return ScoreCategory.Cloth
  elseif codex_type == CodexDataType.Food then
    return ScoreCategory.Food
  elseif codex_type == CodexDataType.Furniture then
    return ScoreCategory.Furniture
  end
  return nil
end

function M:_get_codex_type_by_category(category)
  if category == ScoreCategory.Creature then
    return CodexDataType.Creature
  elseif category == ScoreCategory.Plant then
    return CodexDataType.Plant
  elseif category == ScoreCategory.Cloth then
    return CodexDataType.Cloth
  elseif category == ScoreCategory.Food then
    return CodexDataType.Food
  elseif category == ScoreCategory.Furniture then
    return CodexDataType.Furniture
  end
  return nil
end

function M:_resolve_default_score_category()
  for _, category in ipairs(ScoreCategoryOrder) do
    local data = self._score_category_data[category]
    if data and data.add_score > 0 then
      return category
    end
  end
  return ScoreCategory.Creature
end

function M:_create_round_progress_items()
  self:_clear_round_progress_items()
  if is_null(self._trans_progress_list) or is_null(self._trans_progress_item) then
    return
  end
  UIUtil.set_active(self._trans_progress_item, false)
  for i = 1, #ScoreCategoryOrder do
    local category = ScoreCategoryOrder[i]
    local go = UIUtil.load_prefab_set_parent(self._trans_progress_item, self._trans_progress_list)
    if not_null(go) then
      go.name = self._trans_progress_item.name .. "_" .. tostring(i)
      UIUtil.set_active(go, true)
      local item = self:add_panel(round_progress_item_class, go)
      if item ~= nil then
        self._progress_icon_items[category] = item
      end
    end
  end
end

function M:_clear_round_progress_items()
  self._progress_icon_items = {}
  if is_null(self._trans_progress_list) then
    return
  end
  for i = self._trans_progress_list.childCount - 1, 0, -1 do
    local child = self._trans_progress_list:GetChild(i)
    if not_null(child) and child ~= self._trans_progress_item then
      UIUtil.destroy_go(child.gameObject)
    end
  end
end

function M:_refresh_category_progress(lerp_t)
  lerp_t = lerp_t or 1
  if lerp_t < 0 then
    lerp_t = 0
  elseif 1 < lerp_t then
    lerp_t = 1
  end
  for _, category in ipairs(ScoreCategoryOrder) do
    local item = self._progress_icon_items[category]
    local data = self._score_category_data[category]
    if item ~= nil and data ~= nil then
      local current_score = data.current_score or 0
      local add_score = data.add_score or 0
      local prev_score = math.max(current_score - add_score, 0)
      local full_score = data.full_score or 0
      local current_norm = 0 < full_score and math.min(current_score / full_score, 1) or 0
      local prev_norm = 0 < full_score and math.min(prev_score / full_score, 1) or 0
      local shown_norm = prev_norm + (current_norm - prev_norm) * lerp_t
      local meta = ScoreCategoryMeta[category]
      item:refresh({
        category = category,
        title = meta and meta.title or "",
        prev_norm = prev_norm,
        current_norm = shown_norm,
        add_score = add_score,
        icon = meta and meta.icon or nil
      })
    end
  end
end

function M:_build_reward_groups()
  local rows_by_cat = {}
  for _, category in ipairs(ScoreCategoryOrder) do
    rows_by_cat[category] = {}
  end
  local changed_list = self._changed_data_list or {}
  for i = 1, #changed_list do
    local data = changed_list[i]
    local category = self:_get_score_category(data.curr_data)
    if category ~= nil then
      self:_collect_rise_rows(rows_by_cat[category], data)
    end
  end
  local groups = {}
  for _, category in ipairs(ScoreCategoryOrder) do
    local rows = rows_by_cat[category]
    if 0 < #rows then
      sort_rise_rows(rows)
      local meta = ScoreCategoryMeta[category]
      table.insert(groups, {
        category = category,
        title_text_id = meta and meta.title or "",
        icon = meta and meta.icon or nil,
        items = rows
      })
    end
  end
  self._reward_groups = groups
end

function M:_collect_rise_rows(bucket, data)
  local show_types = {
    codex_module.DataChangeType.Unlock,
    codex_module.DataChangeType.Upgrade,
    codex_module.DataChangeType.PackageCollected
  }
  for j = 1, #show_types do
    local show_type = show_types[j]
    if data.change_type & show_type == show_type then
      local add_score = data.add_score_by_type[show_type]
      if show_type == codex_module.DataChangeType.Unlock then
        local last_creature = data.last_server_data and data.last_server_data.Creature or nil
        local last_max_stars = not_null(last_creature) and last_creature.MaxStars or 0
        if add_score and 1 < #add_score then
          for k = 1, #add_score do
            if 0 < add_score[k] then
              table.insert(bucket, {
                changed_data = data,
                add_score = {
                  add_score[k]
                },
                star_level = last_max_stars + k
              })
            end
          end
        elseif add_score and 0 < #add_score and add_score[1] > 0 then
          table.insert(bucket, {
            changed_data = data,
            add_score = add_score,
            star_level = last_max_stars + 1
          })
        end
      elseif add_score then
        table.insert(bucket, {
          changed_data = data,
          add_score = add_score,
          show_type = show_type
        })
      end
    end
  end
end

function M:_refresh_reward_group()
  self:_build_reward_groups()
  if is_null(self._scroll_list) then
    return
  end
  local node_count = #self._reward_groups
  UIUtil.set_active(self._scroll_list, 0 < node_count)
  self._scroll_list:SetNodeCount(node_count)
  if node_count <= 0 then
    return
  end
  for i, group in ipairs(self._reward_groups) do
    local node_index = i - 1
    local item_count = group.items and #group.items or 0
    self._scroll_list:Init(node_index, 0, item_count, pack(self, M._on_reward_item_bind), pack(self, M._on_reward_node_init))
    self._scroll_list:ExpandNode(node_index, 0)
  end
  self._scroll_list:RebindAllVisibleItems()
  self._scroll_list:MoveToNode(0)
end

function M:_on_reward_node_init(node_trans, node_index)
  local group = self._reward_groups[node_index + 1]
  if group == nil then
    return
  end
  local title_trans = node_trans:Find("group_title")
  if is_null(title_trans) then
    title_trans = node_trans
  end
  local instance_id = title_trans:GetInstanceID()
  local title_panel = self._reward_title_cls_map[instance_id]
  if title_panel == nil then
    title_panel = self:add_panel(reward_group_title_class, title_trans)
    self._reward_title_cls_map[instance_id] = title_panel
  end
  title_panel:refresh(group)
end

function M:_on_reward_item_bind(item_trans, node_index, item_index)
  local group = self._reward_groups[node_index + 1]
  if group == nil or group.items == nil then
    return
  end
  local row = group.items[item_index + 1]
  if row == nil then
    return
  end
  local instance_id = item_trans:GetInstanceID()
  local item_panel = self._reward_item_cls_map[instance_id]
  if item_panel == nil then
    item_panel = self:add_panel(item_module.item_v2_panel_cls_name, item_trans)
    self._reward_item_cls_map[instance_id] = item_panel
  end
  item_panel:set_item_data(row.changed_data.curr_data.IdCfg.id, 0, nil)
  if item_panel.set_star_level then
    local star_level = 0
    if row.changed_data.curr_data.Type == CodexDataType.Creature then
      star_level = row.star_level or 0
    end
    item_panel:set_star_level(star_level)
  end
  local total = get_rise_row_score(row)
  if RISE_ITEM_SCORE_PATH ~= nil then
    local score_txt = UIUtil.find_text(item_trans, RISE_ITEM_SCORE_PATH)
    if not_null(score_txt) then
      UIUtil.set_text(score_txt, "+" .. total)
    end
  end
  UIUtil.set_active(item_trans, true)
end

function M:_close_reward_scroller()
  if not is_null(self._scroll_list) then
    self._scroll_list:Close()
  end
  self._reward_item_cls_map = {}
  self._reward_title_cls_map = {}
end

function M:_resolve_progress_mode()
  if CsCodexModuleUtil.IsTotalScoreShown or self._prev_score >= self._curr_score then
    return ProgressMode.NONE
  end
  if self:_is_target_out_of_safe_view(self._curr_score) then
    return ProgressMode.GROW_SCROLL
  end
  return ProgressMode.GROW_IN_VIEW
end

function M:_is_target_out_of_safe_view(score)
  if is_null(self._scrollrect_main) or is_null(self._trans_content) then
    return false
  end
  local viewport_rt = self._scrollrect_main.viewport
  if is_null(viewport_rt) then
    return false
  end
  local viewport_width = viewport_rt.rect.width
  local content_width = self._trans_content.rect.width
  if viewport_width >= content_width then
    return false
  end
  local target_x = self:_score_to_content_x(score)
  return viewport_width < target_x
end

function M:_score_to_node_progress(score)
  local cfgs = self._score_cfgs
  local n = cfgs and #cfgs or 0
  if n < 2 then
    return 0 < self._max_score and math.max(0, math.min(score / self._max_score, 1)) or 0
  end
  local first = cfgs[1].needtotalscore or 0
  local last = cfgs[n].needtotalscore or 0
  if score <= first then
    return 0
  end
  if score >= last then
    return 1
  end
  local seg_count = n - 1
  for k = 1, seg_count do
    local lo = cfgs[k].needtotalscore or 0
    local hi = cfgs[k + 1].needtotalscore or 0
    if score >= lo and score <= hi then
      local seg = lo < hi and (score - lo) / (hi - lo) or 0
      return (k - 1 + seg) / seg_count
    end
  end
  return 1
end

function M:_get_item_center_x_span()
  local item_count = #self._items
  local first_item = 0 < item_count and self._items[1] or nil
  local last_item = 0 < item_count and self._items[item_count] or nil
  if first_item == nil or last_item == nil or is_null(first_item.trans) or is_null(last_item.trans) then
    return 0, 0
  end
  local first_x = first_item.trans.anchoredPosition.x
  local last_x = last_item.trans.anchoredPosition.x
  return first_x, last_x
end

function M:_ensure_content_layout()
  if is_null(self._trans_content) then
    return
  end
  Canvas.ForceUpdateCanvases()
  LayoutRebuilder.ForceRebuildLayoutImmediate(self._trans_content)
  local first_x, last_x = self:_get_item_center_x_span()
  if last_x <= first_x then
    return
  end
  local need_w = last_x + 230
  local width = self._trans_content.rect.width
  if need_w > width + 0.5 then
    local sd = self._trans_content.sizeDelta
    self._trans_content.sizeDelta = Vector2(need_w, sd.y)
    LayoutRebuilder.ForceRebuildLayoutImmediate(self._trans_content)
  end
end

function M:_node_progress_to_content_x(progress)
  local first_x, last_x = self:_get_item_center_x_span()
  if first_x < last_x then
    return first_x + (last_x - first_x) * math.max(0, math.min(progress, 1))
  end
  local content_width = not is_null(self._trans_content) and self._trans_content.rect.width or 0
  return math.max(0, math.min(progress, 1)) * content_width
end

function M:_score_to_content_x(score)
  if is_null(self._trans_content) then
    return 0
  end
  return self:_node_progress_to_content_x(self:_score_to_node_progress(score))
end

function M:_score_to_norm(score)
  if is_null(self._trans_content) then
    return self:_score_to_node_progress(score)
  end
  local content_width = self._trans_content.rect.width
  local first_x, last_x = self:_get_item_center_x_span()
  if content_width <= 0 or first_x < last_x and last_x > content_width * 1.01 then
    return self:_score_to_node_progress(score)
  end
  return math.max(0, math.min(self:_score_to_content_x(score) / content_width, 1))
end

function M:_calc_target_scroll_x(score)
  if is_null(self._scrollrect_main) or is_null(self._trans_content) then
    return 0
  end
  local viewport_rt = self._scrollrect_main.viewport
  if is_null(viewport_rt) then
    return 0
  end
  local viewport_width = viewport_rt.rect.width
  local content_width = self._trans_content.rect.width
  local max_left = math.max(content_width - viewport_width, 0)
  if max_left <= 0 then
    return 0
  end
  local target_x = self:_score_to_content_x(score)
  local desired_left = target_x - viewport_width * 0.5
  return math.max(0, math.min(desired_left, max_left))
end

function M:_set_scroll_x(scroll_x)
  if is_null(self._trans_content) then
    return
  end
  local pos = self._trans_content.anchoredPosition
  self._trans_content.anchoredPosition = Vector2(-scroll_x, pos.y)
end

function M:_align_content_to_score(score)
  self:_set_scroll_x(self:_calc_target_scroll_x(score))
end

function M:_set_add_sliders_value(value)
  local clamped = math.max(0, math.min(value, 1))
  if not_null(self._slider_add) then
    self._slider_add.value = clamped
  end
  if not_null(self._slider_icon) then
    self._slider_icon.value = clamped
  end
end

function M:_set_slider_main_to_current_score()
  if not_null(self._slider_main) and self._max_score > 0 then
    self._slider_main.value = self:_score_to_norm(self._curr_score)
  end
end

function M:_set_all_sliders_to_current_score()
  self:_set_slider_main_to_current_score()
  if self._max_score <= 0 then
    return
  end
  local current = self:_score_to_norm(self._curr_score)
  self:_set_add_sliders_value(current)
end

function M:_set_scroll_input_enabled(enabled)
  if not_null(self._scrollrect_main) then
    self._scrollrect_main.enabled = enabled
  end
end

function M:_set_tap_catcher_active(active)
end

function M:_open_claim_panels()
  for i = 1, #self._items do
    local item = self._items[i]
    item:show_panel(true)
  end
end

function M:_set_final_item_scale(scale)
  for i = 1, #self._items do
    local item = self._items[i]
    if item.set_dot_scale then
      item:set_dot_scale(scale)
    end
  end
end

function M:_play_final_smaller()
  for i = 1, #self._items do
    local item = self._items[i]
    if item.play_smaller then
      item:play_smaller()
    end
  end
end

function M:_ease_in_out(t)
  if t < 0.5 then
    return 2 * t * t
  end
  return 1 - (-2 * t + 2) ^ 2 * 0.5
end

function M:_set_title_by_score(score)
  if is_null(self._txt_title_in_progress) then
    return
  end
  local last_name
  for i = 1, #self._items do
    local item = self._items[i]
    if score >= item:get_score() then
      local item_data = item:get_cfg()
      if item_data ~= nil and string.is_valid(item_data.name) then
        last_name = item_data.name
      end
    end
  end
  if last_name ~= nil then
    UIUtil.set_text(self._txt_title_in_progress, last_name)
  end
end

function M:_check_passing_items(current_score)
  for i = 1, #self._items do
    local item = self._items[i]
    if item:get_state() == CodexScoreProgressItem.State.UNCOMPLETED and current_score >= item:get_score() then
      item:set_state_visual(CodexScoreProgressItem.State.TO_CLAIM)
      if item.play_completed then
        item:play_completed()
      end
      if not_null(self._txt_title_in_progress) then
        local item_data = item:get_cfg()
        if item_data ~= nil and item_data.name ~= nil then
          UIUtil.set_text(self._txt_title_in_progress, item_data.name)
        end
      end
    end
  end
end

function M:_hide_result_reward()
  UIUtil.set_active(self._trans_result_group, false)
  UIUtil.set_active(self._trans_reward_group, false)
end

function M:_on_claim_reward()
  local claimable_level_ids = {}
  local reward_num_by_id = {}
  local reward_order = {}
  for _, item in ipairs(self._items) do
    if item:get_state() == CodexScoreProgressItem.State.TO_CLAIM then
      local cfg = item:get_cfg()
      if cfg ~= nil then
        table.insert(claimable_level_ids, cfg.id)
      end
      local rewards = item.get_reward_items and item:get_reward_items() or {}
      for _, reward in ipairs(rewards) do
        if reward_num_by_id[reward.id] == nil then
          reward_num_by_id[reward.id] = reward.num
          table.insert(reward_order, reward.id)
        else
          reward_num_by_id[reward.id] = reward_num_by_id[reward.id] + reward.num
        end
      end
    end
  end
  CsCodexModuleUtil.CodexTotalScoreAwardsTaken(function(success)
    if success then
      for _, level_id in ipairs(claimable_level_ids) do
        self._rewarded_id_table[level_id] = true
      end
      self:_refresh_items()
      lua_event_module:send_event(lua_event_module.event_type.codex_total_reward_taken)
      local rewards = {}
      for _, reward_id in ipairs(reward_order) do
        table.insert(rewards, {
          id = reward_id,
          num = reward_num_by_id[reward_id]
        })
      end
      if 0 < #rewards then
        common_ui_module:show_reward_dialog(nil, nil, rewards)
      end
    else
      UIUtil.show_tips_by_text_id("Codex_Tips_TakeRewardFail")
    end
  end)
end

function M:on_screen_tap()
  if self._progress_info_visible then
    self:_set_progress_info_visible(false)
    return
  end
  if self._phase == Phase.WAIT_TAP then
    self:_enter_scroll_phase()
  end
end

function M:_on_btn_progress_info()
  self:_set_progress_info_visible(not self._progress_info_visible)
end

function M:_on_esc()
  if self._progress_info_visible then
    self:_set_progress_info_visible(false)
    return
  end
  self.holder:close_self()
end

function M:_on_close_btn()
  self.holder:close_self()
end

function M:_set_progress_info_visible(visible)
  if is_null(self._trans_popup_tip) then
    return
  end
  self._progress_info_visible = visible
  UIUtil.set_active(self._trans_popup_tip, visible)
  if not_null(self._btn_bg) then
    UIUtil.set_active(self._btn_bg, visible)
  end
  if not visible then
    return
  end
  if self._progress_info_panel == nil then
    self._progress_info_panel = self:add_panel(category_detail_panel_class, self._trans_popup_tip)
  end
  if self._progress_info_panel ~= nil then
    self._progress_info_panel:refresh(self:_build_category_add_score_map())
  end
end

function M:_build_category_add_score_map()
  local map = {}
  for _, category in ipairs(ScoreCategoryOrder) do
    local data = self._score_category_data[category]
    local codex_type = self:_get_codex_type_by_category(category)
    if data ~= nil and codex_type ~= nil then
      map[codex_type] = data.add_score or 0
    end
  end
  return map
end

function M:set_score_title()
  local cfgs = self._score_cfgs
  if cfgs == nil or #cfgs == 0 then
    return
  end
  local current_cfg = codex_module:get_total_score_cfg_by_score(self._curr_score)
  if not_null(self._txt_title_name) then
    UIUtil.set_text(self._txt_title_name, current_cfg ~= nil and current_cfg.name or "")
  end
  local next_cfg
  for i = 1, #cfgs do
    if (cfgs[i].needtotalscore or 0) > self._curr_score then
      next_cfg = cfgs[i]
      break
    end
  end
  if not_null(self._txt_next_part) then
    if next_cfg ~= nil then
      local diff = (next_cfg.needtotalscore or 0) - self._curr_score
      UIUtil.set_active(self._txt_next_part, true)
      UIUtil.set_text_by_id(self._txt_next_part, "CodexScore_NextPartTips", diff)
    else
      UIUtil.set_text_by_id(self._txt_next_part, "CodexScore_AllComplete")
    end
  end
end

function M:_play_anim(trigger, callback)
  if not_null(self._animator_helper) then
    self._animator_helper:SetTriggerWithCallback(trigger, function()
      if callback then
        callback()
      end
    end, true)
  elseif callback then
    callback()
  end
end

return M
