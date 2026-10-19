local M = G.Class("SeasonCodexPopup", G.UIWindow)
local base = G.UIWindow
require("UI/Codex/SeasonCodex/CodexSeasonData")
require("Social/SocialData")
local SeasonCodexRewardItem = "UI/Codex/SeasonCodex/SeasonCodexRewardItem"
local SeasonCodexRewardItemSpecialPath = "UI/Codex/SeasonCodex/SeasonCodexRewardItemSpecial"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/SeasonCodexPopup"
  self.config.type = EUIType.Dialog
  self._is_close = false
  self._reward_items = {}
  self._season_data_list = nil
  self._season_id = nil
  self._max_count = 0
  self._reward_cfgs = nil
end

function M:on_create()
  base.on_create(self)
  self:_hide_reward_templates()
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  local params = self:get_extra_data()
  if params then
    self._season_id = params.season_id
    self._season_data_list = params.season_data_list
  end
  self:_refresh_all()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_destroy()
  base.on_destroy(self)
  self:_clear_reward_items()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnCodexSeasonNumRewardUpdate, pack(self, M._refresh_reward_states))
end

function M:_add_ui_listener()
  if not_null(self._btn_close) then
    self:bind_close_btn(self._btn_close)
  end
  if not_null(self._btn_bg) then
  end
end

function M:_refresh_all()
  local reward_cfgs = codex_module:get_season_reward_cfgs(self._season_id) or {}
  self._reward_cfgs = reward_cfgs
  self._max_count = self:_get_max_reward_count(reward_cfgs)
  self:_refresh_fixed_text()
  self:_refresh_progress(self._max_count)
  local special_cfg = self:_refresh_reward_list(reward_cfgs)
  self:_refresh_dialog(special_cfg)
end

function M:_refresh_reward_states()
  if self._season_id == nil then
    return
  end
  local reward_cfgs = codex_module:get_season_reward_cfgs(self._season_id) or {}
  self._reward_cfgs = reward_cfgs
  local cfg_by_id = {}
  for _, cfg in ipairs(reward_cfgs) do
    cfg_by_id[cfg.id] = cfg
  end
  for _, entry in ipairs(self._reward_items) do
    local cfg = entry.reward_id ~= nil and cfg_by_id[entry.reward_id] or nil
    if entry.panel ~= nil and cfg ~= nil then
      entry.panel:refresh_state(cfg)
    end
  end
  self:_refresh_progress(self._max_count or 0)
end

function M:_refresh_progress(max_count)
  if not self._season_data_list then
    self._season_data_list = self._season_id and codex_module:get_season_all_creatures(self._season_id) or codex_module:get_season_codex_data_list()
  end
  local unlocked = self:_get_unlocked_count()
  local next_node = codex_module:get_season_next_reward_node(self._season_id, unlocked)
  local hint_target = next_node and next_node.count or max_count
  if not_null(self._slider_progress) then
    local reward_cfgs = self._reward_cfgs or self._season_id and codex_module:get_season_reward_cfgs(self._season_id) or {}
    self._slider_progress.value = self:_calc_progress_ratio(unlocked, reward_cfgs)
  end
  if not_null(self._ui_state_group_progrees) then
    local state = max_count > unlocked and 0 or 1
    self._ui_state_group_progrees:SetState(state)
  end
  if not_null(self._txt_progress_num) then
    local unlocked_str = TextMapFormatUtil.FormatInteger(unlocked)
    local target_str = TextMapFormatUtil.FormatInteger(hint_target)
    UIUtil.set_text(self._txt_progress_num, string.format("%s/%s", unlocked_str, target_str))
  end
end

function M:_node_slot_ratio(index, total)
  if total == nil or total <= 0 then
    return 0
  end
  if total <= 1 then
    return 0.1
  end
  return 0.1 + (index - 1) * 0.9 / (total - 1)
end

function M:_calc_progress_ratio(unlocked, reward_cfgs)
  local total = #(reward_cfgs or {})
  if total <= 0 or unlocked == nil or unlocked <= 0 then
    return 0
  end
  local prev_count = 0
  local prev_ratio = 0
  for i, cfg in ipairs(reward_cfgs) do
    local count = cfg.count or 0
    local ratio = self:_node_slot_ratio(i, total)
    if unlocked < count then
      local span = count - prev_count
      if span <= 0 then
        return prev_ratio
      end
      return prev_ratio + (unlocked - prev_count) / span * (ratio - prev_ratio)
    end
    prev_count = count
    prev_ratio = ratio
  end
  return 1
end

function M:_refresh_reward_list(reward_cfgs)
  self:_clear_reward_items()
  local special_cfg
  local total = #(reward_cfgs or {})
  for index, cfg in ipairs(reward_cfgs or {}) do
    if cfg.is_special then
      special_cfg = cfg
    end
    self:_create_reward_item(cfg, index, total)
  end
  return special_cfg
end

function M:_create_reward_item(cfg, index, total)
  if not cfg or is_null(self._trans_reward_list) then
    return
  end
  local template = cfg.is_special and self._obj_reward_special or self._item_reward_template
  if is_null(template) then
    return
  end
  local go = UIUtil.load_prefab_set_parent(template, self._trans_reward_list)
  if is_null(go) then
    return
  end
  go.name = cfg.is_special and "item_reward_special_dynamic" or "item_reward_dynamic_" .. tostring(cfg.id)
  UIUtil.set_active(go, true)
  local panel_path = cfg.is_special and SeasonCodexRewardItemSpecialPath or SeasonCodexRewardItem
  local item = self:add_panel(panel_path, go.transform)
  if not item then
    UIUtil.destroy_go(go)
    return
  end
  item:refresh({
    cfg = cfg,
    on_claim = pack(self, M._on_claim_reward)
  })
  table.insert(self._reward_items, {
    panel = item,
    go = go,
    reward_id = cfg.id
  })
  self:_set_reward_position(go.transform, index, total)
end

function M:_set_reward_position(trans, index, total)
  if not (not is_null(trans) and not is_null(self._round_progress) and total) or total <= 0 then
    return
  end
  local rect = trans:GetComponent(typeof(RectTransform))
  if is_null(rect) then
    return
  end
  local ratio = self:_node_slot_ratio(index, total)
  self._round_progress:SetMarkerPositionAndRotation(rect, ratio, 0, 180)
  if index == total and not_null(self._obj_reward_special) then
    local template_rect = self._obj_reward_special:GetComponent(typeof(RectTransform))
    if not_null(template_rect) then
      rect.position = template_rect.position
      rect.rotation = template_rect.rotation
    end
  end
  self:_move_rect_center_x_to_world(rect, self:_get_reward_center_world_x(index, total))
end

function M:_get_reward_center_world_x(index, total)
  local start_local = self._round_progress:EvaluateLocalPosition(0.1, 0)
  local start_world = self._round_progress.transform:TransformPoint(Vector3(start_local.x, start_local.y, 0))
  local end_world_x = start_world.x
  if not_null(self._obj_reward_special) then
    local template_rect = self._obj_reward_special:GetComponent(typeof(RectTransform))
    if not_null(template_rect) then
      local center = template_rect.rect.center
      end_world_x = template_rect:TransformPoint(Vector3(center.x, center.y, 0)).x
    end
  end
  if total <= 1 then
    return start_world.x
  end
  return start_world.x + (end_world_x - start_world.x) * (index - 1) / (total - 1)
end

function M:_move_rect_center_x_to_world(rect, target_world_x)
  local center = rect.rect.center
  local current_world = rect:TransformPoint(Vector3(center.x, center.y, 0))
  local position = rect.position
  rect.position = Vector3(position.x + target_world_x - current_world.x, position.y, position.z)
end

function M:_hide_reward_templates()
  if not_null(self._item_reward_template) then
    UIUtil.set_active(self._item_reward_template, false)
  end
  if not_null(self._obj_reward_special) then
    UIUtil.set_active(self._obj_reward_special, false)
  end
  for index = 1, 4 do
    local trans = self["_trans_item_reward_" .. tostring(index)]
    if not_null(trans) then
      UIUtil.set_active(trans, false)
    end
  end
  if not_null(self._trans_item_reward_special) then
    UIUtil.set_active(self._trans_item_reward_special, false)
  end
end

function M:_refresh_fixed_text()
  if not_null(self._txt_title) then
    local title = UIUtil.get_text_by_id("SeasonCodex_RewardTitle")
    local season_cfg = ExcelDataUtil.get_value(typeof(BCodexSeasonSignCfg), self._season_id)
    if not_null(season_cfg) and not_null(season_cfg.seasoncodexprogresstitle) and season_cfg.seasoncodexprogresstitle ~= "" then
      title = season_cfg.seasoncodexprogresstitle
    end
    UIUtil.set_text(self._txt_title, title)
  end
  if not_null(self._txt_title_dialog) then
    UIUtil.set_text(self._txt_title_dialog, UIUtil.get_text_by_id("SeasonCodex_RewardTypeTitle"))
  end
end

function M:_refresh_dialog(special_cfg)
  if not_null(self._txt_dialog) then
    local dialog_text = special_cfg and special_cfg.name or ""
    if special_cfg and special_cfg.title_ids and #special_cfg.title_ids >= 2 then
      dialog_text = social_module:get_display_title_by_title_list(special_cfg.title_ids)
    end
    UIUtil.set_text(self._txt_dialog, dialog_text)
  end
end

function M:_get_max_reward_count(reward_cfgs)
  if not reward_cfgs or #reward_cfgs == 0 then
    return 0
  end
  local max_count = 0
  for _, cfg in ipairs(reward_cfgs) do
    local c = cfg.count or 0
    if max_count < c then
      max_count = c
    end
  end
  return max_count
end

function M:_on_claim_reward(cfg)
  if not cfg then
    return
  end
  codex_module:claim_season_reward(cfg.id, function(success, rewards)
    if not success then
      UIUtil.show_tips_by_text_id("Codex_Tips_TakeRewardFail")
      return
    end
    if rewards and 0 < #rewards then
      common_ui_module:show_reward_dialog(nil, nil, rewards)
    else
      UIUtil.show_tips_by_text_id("Codex_Tips_TakeRewardSuccess")
    end
  end)
end

function M:_get_unlocked_count()
  if not self._season_data_list then
    return 0
  end
  local count = 0
  for _, data in ipairs(self._season_data_list) do
    if data.IsUnlocked then
      count = count + 1
    end
  end
  return count
end

function M:_clear_reward_items()
  for _, entry in ipairs(self._reward_items) do
    if entry.panel ~= nil then
      self:remove_panel(entry.panel)
    end
    if not is_null(entry.go) then
      UIUtil.destroy_go(entry.go)
    end
  end
  self._reward_items = {}
end

return M
