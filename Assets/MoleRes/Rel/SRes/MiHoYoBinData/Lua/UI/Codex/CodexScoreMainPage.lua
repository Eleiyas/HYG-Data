local M = G.Class("CodexScoreMainPage", G.UIWindow)
local base = G.UIWindow
local Stage = {
  NONE = 0,
  NEW_RECORD = 1,
  RARE_CARD = 2,
  PROGRESS = 3
}
local STAGE_PANEL_CLASS = {
  [Stage.NEW_RECORD] = "UI/Codex/CodexScoreNewRecordPage",
  [Stage.RARE_CARD] = "UI/Codex/CodexScoreNewRecordCardPage",
  [Stage.PROGRESS] = "UI/Codex/CodexScoreProgressPage"
}
local RANK_GOLD = 3
local CREATURE_RARE_STAR = 3

local function is_rare_record(changed_data)
  if is_null(changed_data) then
    return false
  end
  local curr_data = changed_data.curr_data
  if is_null(curr_data) then
    return false
  end
  local item_cfg = curr_data.ItemCfg
  local rank = item_cfg ~= nil and item_cfg.rank or 0
  if rank >= RANK_GOLD then
    return true
  end
  if curr_data.Type == CodexDataType.Creature then
    local server_data = curr_data.ServerData
    local creature = server_data ~= nil and server_data.Creature or nil
    local max_stars = creature ~= nil and creature.MaxStars or 0
    if max_stars >= CREATURE_RARE_STAR then
      return true
    end
  end
  return false
end

local function filter_rare_records(changed_data_list)
  local rare_list = {}
  if is_null(changed_data_list) then
    return rare_list
  end
  for i = 1, #changed_data_list do
    if is_rare_record(changed_data_list[i]) then
      table.insert(rare_list, changed_data_list[i])
    end
  end
  return rare_list
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexScoreMainPage"
  self.config.type = EUIType.Page
  self._changed_data_list = nil
  self._rare_data_list = nil
  self._current_stage = Stage.NONE
  self._current_panel = nil
  self._score_shown_notified = false
  self.config.wait_previous_window_hide_until_show = true
end

function M:on_create()
  base.on_create(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_start_flow()
end

function M:on_close()
  self:_notify_total_score_shown()
  self:_reset_flow_state()
  base.on_close(self)
end

function M:close_self()
  base.close_self(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, M._on_back)
end

function M:_on_back(_action)
  self:close_self()
end

function M:_reset_flow_state()
  if self._current_panel ~= nil then
    self:remove_panel_async(self._current_panel)
    self._current_panel = nil
  end
  self._current_stage = Stage.NONE
  self._changed_data_list = nil
  self._rare_data_list = nil
  self._score_shown_notified = false
end

function M:_start_flow()
  if self._current_stage ~= Stage.NONE then
    return
  end
  local total_score_data = CsCodexModuleUtil.CodexTotalScoreData
  if is_null(total_score_data) then
    self:_goto_stage(Stage.PROGRESS)
    return
  end
  local has_increase = not CsCodexModuleUtil.IsTotalScoreShown and total_score_data.TotalScore > total_score_data.LastShownData.TotalScore
  self._changed_data_list = has_increase and codex_module:get_changed_data_list() or nil
  self._rare_data_list = filter_rare_records(self._changed_data_list)
  if has_increase and self._changed_data_list and #self._changed_data_list > 0 then
    self:_goto_stage(Stage.NEW_RECORD, {
      rare_count = #self._rare_data_list
    })
  else
    self:_goto_stage(Stage.PROGRESS)
  end
end

function M:_goto_stage(stage, extra_data)
  if is_null(self._trans_panel_parent) then
    Logger.LogError("[CodexScoreMainPage] _trans_panel_parent 未绑定，无法挂载子面板")
    return
  end
  local class_path = STAGE_PANEL_CLASS[stage]
  if class_path == nil then
    return
  end
  local prev_panel = self._current_panel
  self._current_stage = stage
  self._current_panel = self:add_panel_async(class_path, extra_data, self._trans_panel_parent, function(panel)
    panel:change_state(EUIState.Show)
    if prev_panel ~= nil then
      self:remove_panel_async(prev_panel)
    end
  end)
end

function M:on_new_record_complete()
  if self._rare_data_list and #self._rare_data_list > 0 then
    self:_goto_stage(Stage.RARE_CARD, {
      rare_data_list = self._rare_data_list
    })
  else
    self:_goto_stage(Stage.PROGRESS)
  end
end

function M:on_card_complete()
  self:_goto_stage(Stage.PROGRESS)
end

function M:_notify_total_score_shown()
  if self._score_shown_notified then
    return
  end
  self._score_shown_notified = true
  CsCodexModuleUtil.CodexTotalScoreShown(function(_success)
  end)
end

return M
