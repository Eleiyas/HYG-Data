local M = G.Class("TrafficQuizOptionPage", G.UIWindow)
local base = G.UIWindow
local BNpcSpecialInteractQuizCfgType = typeof(BNpcSpecialInteractQuizCfg)
local option_item_cls = "UI/TrafficQuiz/TrafficQuizOptionItem"
local OptionState = {
  Unselected = 0,
  Correct = 1,
  Wrong = 2
}
local ResultState = {Correct = 0, Wrong = 1}
local BtnState = {NotAnswered = 0, Answered = 1}
local REVEAL_DELAY = 0.0

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/TrafficQuiz/TrafficQuizOptionPage"
  self.config.type = EUIType.Page
  self._context = nil
  self._question_id = 0
  self._options = {}
  self._option_items = {}
  self._selected_index = 0
  self._is_answered = false
  self._is_correct = false
  self._dither_player_guid = 0
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:check_3c_validate()
  return true
end

function M:on_enable()
  base.on_enable(self)
  self._is_answered = false
  self._selected_index = 0
  self._is_correct = false
  self._context = self:get_extra_data()
  if not self._context then
    Logger.LogError("[TrafficQuizOptionPage] context is nil")
    return
  end
  self:_dither_player()
  self._question_id = CsNPCPersonaGameModuleUtil.GetCurrentQuizQuestionId()
  self:_load_question_data()
  self:_refresh_ui()
end

function M:on_disable()
  base.on_disable(self)
  self:_restore_player_dither()
  self._context = nil
end

function M:on_destroy()
  self:_restore_player_dither()
  base.on_destroy(self)
end

function M:_dither_player()
  if self._dither_player_guid and self._dither_player_guid ~= 0 then
    return
  end
  local player_guid = CsUIUtil.GetPlayerEntityGuid()
  if not player_guid or player_guid == 0 then
    return
  end
  self._dither_player_guid = player_guid
  CsUIUtil.HideOrShowAvatarForPerformance(player_guid, false, 0.3)
end

function M:_restore_player_dither()
  if not self._dither_player_guid or self._dither_player_guid == 0 then
    return
  end
  CsUIUtil.HideOrShowAvatarForPerformance(self._dither_player_guid, true, 0.3)
  self._dither_player_guid = 0
end

function M:bind_input_action()
  base.bind_input_action(self)
  if self._btn_back then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_back)
  end
end

function M:_ensure_option_items(count)
  if is_null(self._tog_item) then
    return
  end
  local content_trans = self._scroll_option.content
  if is_null(content_trans) then
    return
  end
  for i = #self._option_items + 1, count do
    local go
    if i == 1 then
      go = self._tog_item
    else
      go = UIUtil.load_prefab_set_parent(self._tog_item, content_trans)
    end
    local item = self:add_panel(option_item_cls, go.transform)
    table.insert(self._option_items, item)
    local idx = i
    local tog = item:get_toggle()
    if not is_null(tog) then
      self:bind_callback(tog, function(is_on)
        if is_on then
          self:_on_option_selected(idx)
        end
      end)
    end
  end
end

function M:_add_ui_listener()
  if self._btn_back then
    self:bind_callback(self._btn_back, pack(self, M._on_btn_back_click))
  end
  if self._btn_continue then
    self:bind_callback(self._btn_continue, pack(self, M._on_btn_continue_click))
  end
end

function M:_load_question_data()
  self._options = {}
  self._question_text = ""
  local id = self._question_id
  local sub_id = 0
  while true do
    local cfg = ExcelDataUtil.get_value(BNpcSpecialInteractQuizCfgType, id, sub_id)
    if not cfg then
      break
    end
    if cfg.content_type == "Q" then
      self._question_text = cfg.content
    elseif cfg.content_type == "A" then
      table.insert(self._options, {
        sub_id = sub_id,
        text = cfg.content,
        is_correct = cfg.is_correct == 1
      })
    end
    sub_id = sub_id + 1
  end
  self:_shuffle_options()
end

function M:_shuffle_options()
  local n = #self._options
  for i = n, 2, -1 do
    local j = math.random(1, i)
    self._options[i], self._options[j] = self._options[j], self._options[i]
  end
end

local OPTION_LABELS = {
  "A",
  "B",
  "C",
  "D"
}

function M:_refresh_ui()
  if self._txt_question_dynamic then
    UIUtil.set_text(self._txt_question_dynamic, self._question_text)
  end
  if self._btn_back then
    self._btn_back.interactable = true
  end
  self:_ensure_option_items(#self._options)
  self:_refresh_options()
  if self._state_group_btn then
    self._state_group_btn:SetState(BtnState.NotAnswered)
  end
  if self._state_group_result then
    self._state_group_result:SetState(ResultState.Correct)
  end
end

function M:_refresh_options()
  for i, opt in ipairs(self._options) do
    local item = self._option_items[i]
    if item then
      item:set_option(OPTION_LABELS[i] or "", opt.text)
      item:set_state(OptionState.Unselected)
      item:reset_toggle()
      item:set_interactable(true)
      item:set_active(true)
    end
  end
  for i = #self._options + 1, #self._option_items do
    local item = self._option_items[i]
    if item then
      item:set_active(false)
    end
  end
end

function M:_on_option_selected(index)
  if self._is_answered then
    return
  end
  if index < 1 or index > #self._options then
    return
  end
  self._is_answered = true
  self._selected_index = index
  for i, item in ipairs(self._option_items) do
    if item then
      item:set_interactable(false)
    end
  end
  if self._btn_back then
    self._btn_back.interactable = false
  end
  local opt = self._options[index]
  CsNPCPersonaGameModuleUtil.QuizSubmitAnswer(self._context.specialInteractionId, opt.sub_id, function(success)
    if success then
      self._is_correct = CsNPCPersonaGameModuleUtil.GetCurrentQuizResult()
      self._correct_answer_id = CsNPCPersonaGameModuleUtil.GetCurrentQuizCorrectAnswerId()
    end
    self:_delay_reveal()
  end)
end

function M:_delay_reveal()
  if REVEAL_DELAY <= 0.0 then
    self:_reveal_result()
  else
    CsCoroutineManagerUtil.Invoke(REVEAL_DELAY, function()
      self:_reveal_result()
    end)
  end
end

function M:_reveal_result()
  local selected_item = self._option_items[self._selected_index]
  if selected_item then
    if self._is_correct then
      selected_item:set_state(OptionState.Correct)
    else
      selected_item:set_state(OptionState.Wrong)
      self:_highlight_correct_option()
    end
  end
  if self._state_group_btn then
    self._state_group_btn:SetState(BtnState.Answered)
  end
  if self._state_group_result then
    self._state_group_result:SetState(self._is_correct and ResultState.Correct or ResultState.Wrong)
  end
  if self._context and self._context.npcGuid then
    CsNPCPersonaGameModuleUtil.PlayQuizReaction(self._context.npcGuid, self._is_correct)
  end
end

function M:_highlight_correct_option()
  if not self._correct_answer_id then
    return
  end
  for i, opt in ipairs(self._options) do
    if opt.sub_id == self._correct_answer_id and i ~= self._selected_index then
      local item = self._option_items[i]
      if item then
        item:set_state(OptionState.Correct)
      end
      break
    end
  end
end

function M:_on_btn_back_click()
  if self._is_answered then
    return
  end
  self:close_self()
  EventCenter.Broadcast(EventID.Performance.OnTrafficQuizExited)
end

function M:_on_btn_continue_click()
  if not self._is_answered then
    return
  end
  self:close_self()
  EventCenter.Broadcast(EventID.Performance.OnTrafficQuizAnswered, self._is_correct and 0 or 1)
end

return M
