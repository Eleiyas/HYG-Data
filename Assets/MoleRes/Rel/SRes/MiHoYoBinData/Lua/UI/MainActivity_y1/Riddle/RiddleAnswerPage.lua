local M = G.Class("RiddleAnswerPage", G.UIWindow)
local base = G.UIWindow
local BRiddlesListCfgType = typeof(CS.miHoYo.HYG.ExcelData.BRiddlesListCfg)
local option_item_cls = "UI/MainActivity_y1/Riddle/RiddleAnswerOptionItem"
local chat_bubble_panel_cls = "UI/MainActivity_y1/Riddle/Panel/RiddleChatBubbleLitePanel"
local OptionState = {
  Unselected = 0,
  Correct = 1,
  Wrong = 2,
  WrongButCorrectShow = 3
}
local MAGIC_Y = 360
local OPTION_LABELS = {
  "A",
  "B",
  "C",
  "D"
}
local ACTIVITY_END_DIALOG_TEXT_ID = "Activity_EndDialog_Desc"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_LanternRiddlesDialog"
  self.config.type = EUIType.Page
  self._question_id = 0
  self._question_text = ""
  self._options = {}
  self._option_items = {}
  self._selected_index = 0
  self._is_answered = false
  self._dither_player_guid = 0
  self._is_close = false
  self._activity_end_dialog_shown = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self:_init_chat_bubble_panel()
end

function M:on_enable()
  base.on_enable(self)
  local data = self:get_extra_data()
  self._question_id = tonumber(data and data.question_id) or 0
  self._selected_index = 0
  self._is_answered = false
  self._is_close = false
  self._activity_end_dialog_shown = false
  self:_refresh_chat_bubble(nil)
  if self._question_id <= 0 then
    Logger.LogWarning("[RiddleAnswerPage] invalid question_id")
    return
  end
  self:_dither_player()
  self:_load_question_data()
  self:_refresh_ui()
  if riddle_module ~= nil then
    local pending = riddle_module:consume_pending_answer_bubble_context()
    if pending ~= nil then
      self:on_riddle_answer_bubble_update(pending)
    end
  end
end

function M:on_disable()
  self:_restore_player_dither()
  base.on_disable(self)
end

function M:on_destroy()
  self:_restore_player_dither()
  base.on_destroy(self)
end

function M:on_before_close()
  base.on_before_close(self)
  if self._is_play_anim and self:get_cur_ui_state() == EUIState.Show then
    self:stop_playing_anim(true)
  end
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnActivityRemoved, pack(self, M._on_activity_removed))
end

function M:bind_input_action()
  base.bind_input_action(self)
  if self._btn_back ~= nil then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_back)
  end
end

function M:_add_ui_listener()
  if self._btn_back then
    self:bind_callback(self._btn_back, pack(self, M._on_btn_back_click))
  end
end

function M:_init_chat_bubble_panel()
  if is_null(self._common_chatbubblelite) then
    Logger.LogWarning("[RiddleAnswerPage] _common_chatbubblelite binder is null, chat bubble disabled. Check prefab MonoViewBinder config.")
    return
  end
  local rect = self._common_chatbubblelite:GetComponent(typeof(RectTransform))
  if is_null(rect) then
    Logger.LogWarning("[RiddleAnswerPage] _common_chatbubblelite has no RectTransform")
  else
    rect.anchorMin = Vector2(0.5, 0.5)
    rect.anchorMax = Vector2(0.5, 0.5)
  end
  self._chat_bubble_panel = self:add_panel(chat_bubble_panel_cls, self._common_chatbubblelite)
  Logger.Log(string.format("[RiddleAnswerPage] chat_bubble_panel created. nil=%s", tostring(self._chat_bubble_panel == nil)))
end

function M:on_riddle_answer_bubble_update(context)
  Logger.Log(string.format("[RiddleAnswerPage] receive bubble event. context_nil=%s", tostring(context == nil)))
  if is_null(self._chat_bubble_panel) then
    if riddle_module ~= nil then
      riddle_module:cache_pending_answer_bubble_context(context)
    end
    return false
  end
  self:_refresh_chat_bubble(context)
  return true
end

function M:_refresh_chat_bubble(context)
  local has_context = context ~= nil
  local text = has_context and (context.text or context.bubble_text or context.Text or context.BubbleText) or ""
  local show_value = has_context and context.show
  local should_show = text ~= nil and text ~= ""
  if show_value ~= nil then
    if show_value == true or show_value == 1 or show_value == "1" or show_value == "true" then
      should_show = true
    else
      should_show = false
    end
  end
  local x = tonumber(context and (context.x or context.pos_x or context.X or context.PosX)) or 0
  local y = MAGIC_Y
  local state = tonumber(context and (context.state or context.chat_state or context.State or context.ChatState)) or 4
  Logger.Log(string.format("[RiddleAnswerPage] bubble parsed show=%s text=%s state=%d", tostring(should_show), tostring(text), state))
  if is_null(self._chat_bubble_panel) then
    return
  end
  self._chat_bubble_panel:refresh(text, state, x, y, should_show)
  Logger.Log(string.format("[RiddleAnswerPage] bubble anchoredPosition=(%.2f, %.2f)", x, y))
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

function M:_ensure_option_items(count)
  if is_null(self._layout_answerlist) then
    Logger.LogWarning("[RiddleAnswerPage] _layout_answerlist not bound")
    return
  end
  if self._layout_answerlist.AddItem == nil then
    Logger.LogWarning("[RiddleAnswerPage] _layout_answerlist has no AddItem")
    return
  end
  for i = #self._option_items + 1, count do
    local go = self._layout_answerlist:AddItem(0)
    if is_null(go) then
      Logger.LogWarning("[RiddleAnswerPage] _layout_answerlist:AddItem failed")
      break
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

function M:_load_question_data()
  self._question_text = ""
  self._options = {}
  local sub_id = 0
  while true do
    local cfg = ExcelDataUtil.get_value(BRiddlesListCfgType, self._question_id, sub_id)
    if cfg == nil then
      break
    end
    if sub_id == 0 then
      self._question_text = cfg.content or ""
    else
      table.insert(self._options, {
        sub_id = sub_id,
        text = cfg.content or "",
        is_correct = cfg.is_correct == true or cfg.is_correct == 1
      })
    end
    sub_id = sub_id + 1
  end
end

function M:_refresh_ui()
  if self._text_desc then
    UIUtil.set_text(self._text_desc, self._question_text)
  end
  if self._btn_back then
    self._btn_back.interactable = true
  end
  self:_ensure_option_items(#self._options)
  self:_refresh_options()
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
  local opt = self._options[index]
  if opt == nil then
    return
  end
  local correct_index = 0
  if not opt.is_correct then
    for i, o in ipairs(self._options) do
      if o.is_correct then
        correct_index = i
        break
      end
    end
  end
  for i, item in ipairs(self._option_items) do
    if item then
      item:set_interactable(false)
      if i == index then
        item:set_state(opt.is_correct and OptionState.Correct or OptionState.Wrong)
      elseif i == correct_index then
        item:set_state(OptionState.WrongButCorrectShow)
      else
        item:set_state(OptionState.Unselected)
      end
    end
  end
  EventCenter.Broadcast(EventID.Performance.OnRiddleAnswerSubmitted, tonumber(opt.sub_id) or 0)
end

function M:close_from_performance()
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_self()
end

function M:exit_anim_call_back()
  base.exit_anim_call_back(self)
  if self._is_close then
    EventCenter.Broadcast(EventID.Performance.OnRiddleAnswerExited, true)
  end
end

function M:_do_close_and_notify()
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_self()
  EventCenter.Broadcast(EventID.Performance.OnRiddleAnswerExited, false)
end

function M:_on_btn_back_click()
  if self._is_answered then
    return
  end
  self:_do_close_and_notify()
end

function M:_on_activity_removed(activity_id)
  if not riddle_module:is_riddle_related_activity(activity_id) then
    return
  end
  self:_show_activity_end_dialog()
end

function M:_show_activity_end_dialog()
  if self._activity_end_dialog_shown then
    return
  end
  self._activity_end_dialog_shown = true
  local popup = UIUtil.get_confirm_popup()
  popup:set_style(ConfirmPopupStyle.ForcedPopup)
  popup:set_texts(UIUtil.get_text_by_id(ACTIVITY_END_DIALOG_TEXT_ID), UIUtil.get_text_by_id("Common_Accept"), nil, nil)
  popup:set_callbacks(function()
    self:_do_close_and_notify()
  end)
  popup:show()
end

return M
