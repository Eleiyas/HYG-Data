local M = G.Class("CodexScoreSequenceDialog", G.UIWindow)
local base = G.UIWindow
local progress_page_class = "UI/Codex/CodexScoreProgressPage"
local new_record_tip_class = "UI/Codex/CodexScoreNewRecordTip"
local rare_card_class = "UI/Codex/CodexScoreRareCard"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Codex/CodexScoreSequenceDialog"
  self.config.type = EUIType.Dialog
  self._total_score_data = nil
  self._has_increase = false
  self._changed_data_list = nil
  self._progress_page = nil
  self._new_record_tip = nil
  self._rare_card = nil
  self._steps = {}
  self._current_step = 0
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self:_init_data()
  self:_start_sequence()
end

function M:on_disable()
  base.on_disable(self)
end

function M:close_self()
  self:_total_score_shown()
  base.close_self(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_ui_listener()
  if not_null(self._btn_close) then
    self:bind_close_btn(self._btn_close)
  end
  if not_null(self._btn_bg) then
    self:bind_callback(self._btn_bg, pack(self, M._on_btn_bg))
  end
end

function M:_on_btn_bg()
  local step = self._steps[self._current_step]
  if step and step.skippable then
    self:_next_step()
  elseif self._progress_page then
    self._progress_page:on_screen_tap()
  end
end

function M:_total_score_shown()
  CsCodexModuleUtil.CodexTotalScoreShown(function(success)
  end)
end

function M:_init_data()
  self._total_score_data = CsCodexModuleUtil.CodexTotalScoreData
  if is_null(self._total_score_data) then
    return
  end
  self._has_increase = not CsCodexModuleUtil.IsTotalScoreShown and self._total_score_data.TotalScore > self._total_score_data.LastShownData.TotalScore
  if self._has_increase then
    self._changed_data_list = codex_module:get_changed_data_list()
  end
end

function M:_start_sequence()
  self._steps = {}
  self._current_step = 0
  if self._has_increase and self._changed_data_list and 0 < #self._changed_data_list then
    table.insert(self._steps, {type = "new_record", skippable = true})
  end
  table.insert(self._steps, {
    type = "progress_page",
    skippable = false
  })
  self:_next_step()
end

function M:_next_step()
  self:_hide_current_step()
  self._current_step = self._current_step + 1
  if self._current_step > #self._steps then
    return
  end
  local step = self._steps[self._current_step]
  if step.type == "new_record" then
    self:_show_new_record_tip()
  elseif step.type == "rare_card" then
    self:_show_rare_card()
  elseif step.type == "progress_page" then
    self:_show_progress_page()
  end
end

function M:_hide_current_step()
  if self._current_step <= 0 then
    return
  end
  local step = self._steps[self._current_step]
  if not step then
    return
  end
  if step.type == "new_record" and self._new_record_tip then
    self._new_record_tip:hide()
  elseif step.type == "rare_card" and self._rare_card then
    self._rare_card:hide()
  end
end

function M:_show_new_record_tip()
  if self._new_record_tip == nil then
    self._new_record_tip = self:add_panel(new_record_tip_class, self._trans_step_container)
  end
  self._new_record_tip:show(self._changed_data_list, function()
    self:_next_step()
  end)
end

function M:_show_rare_card()
  if self._rare_card == nil then
    self._rare_card = self:add_panel(rare_card_class, self._trans_step_container)
  end
  self._rare_card:show(nil, function()
    self:_next_step()
  end)
end

function M:_show_progress_page()
  if self._progress_page == nil then
    self._progress_page = self:add_panel(progress_page_class, self._trans_progress_page)
  end
  self._progress_page:show(self._total_score_data, function()
  end)
end

return M
