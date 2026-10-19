local M = G.Class("QteGameMainPage", G.UIWindow)
local base = G.UIWindow
local ACTION_ITEM_CLS = "UI/QteGame/QteGameActionItem"
local HEAD_ITEM_CLS = "UI/QteGame/QteGameHeadInfoItem"
local EXIT_CONFIRM_CLS = "UI/QteGame/QteGameExitConfirmPopup"
local REFRESH_INTERVAL = 0.1
local URGENT_RATIO = 0.3
local START_COUNTDOWN = 3
local EXIT_CONFIRM_INFO = "退出后本次挑战会失败，是否确认退出？"
local FinishReason = {
  Success = 1,
  WrongInput = 2,
  Exit = 3,
  Timeout = 4
}
local CdState = {Normal = 0, Urgent = 1}
local StageState = {StartCountdown = 0, Playing = 1}
local BtnState = {Default = 0, Pressed = 1}
local ButtonActionMap = {
  [1] = {
    ActionType.Act.W,
    ActionType.Act.DPad_Up
  },
  [2] = {
    ActionType.Act.A,
    ActionType.Act.DPad_Left
  },
  [3] = {
    ActionType.Act.S,
    ActionType.Act.DPad_Down
  },
  [4] = {
    ActionType.Act.D,
    ActionType.Act.DPad_Right
  }
}
local KeyCodeButtonMap = {
  W = 1,
  Up = 1,
  UP = 1,
  A = 2,
  Left = 2,
  LEFT = 2,
  S = 3,
  Down = 3,
  DOWN = 3,
  D = 4,
  Right = 4,
  RIGHT = 4
}
KeyCodeButtonMap[ActionType.Act.W] = 1
KeyCodeButtonMap[ActionType.Act.DPad_Up] = 1
KeyCodeButtonMap[ActionType.Act.A] = 2
KeyCodeButtonMap[ActionType.Act.DPad_Left] = 2
KeyCodeButtonMap[ActionType.Act.S] = 3
KeyCodeButtonMap[ActionType.Act.DPad_Down] = 3
KeyCodeButtonMap[ActionType.Act.D] = 4
KeyCodeButtonMap[ActionType.Act.DPad_Right] = 4

local function build_action_list(actions)
  local ret = {}
  for _, action in ipairs(actions or {}) do
    if action then
      table.insert(ret, action)
    end
  end
  return ret
end

local function get_text_or_default(text_id, default_text)
  local text = UIUtil.get_text_by_id(text_id)
  if string.is_valid(text) then
    return text
  end
  return default_text
end

local function for_each_view_data(map, handler)
  if not map or not handler then
    return
  end
  if type(map) == "table" then
    for node_id, view_data in pairs(map) do
      handler(node_id, view_data)
    end
    return
  end
  local ok, iter = pcall(function()
    return map:GetEnumerator()
  end)
  if ok and iter then
    while iter:MoveNext() do
      local current = iter.Current
      handler(current.Key, current.Value)
    end
  end
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/QteGame/QteGameMainPage"
  self.config.type = EUIType.Page
  self._context = nil
  self._target_node_list = {}
  self._possible_node_list = {}
  self._player_node_list = {}
  self._node_view_data_map = {}
  self._node_view_data_by_node_id = {}
  self._button_index_to_node_ids = {}
  self._enabled_button_index_map = {}
  self._action_items = {}
  self._score_items = {}
  self._btn_state_groups = {}
  self._next_target_index = 1
  self._wrong_index = 0
  self._remain_time = 0
  self._countdown_total = 0
  self._start_countdown_remain = START_COUNTDOWN
  self._stage_state = nil
  self._refresh_timer = 0
  self._is_game_started = false
  self._is_countdown_paused = false
  self._is_exit_confirm_showing = false
  self._has_finished = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:check_3c_validate()
  return true
end

function M:on_open()
  base.on_open(self)
  self:_reset_session()
  self._context = self:get_extra_data()
  if not self._context then
    Logger.LogError("[QteGameMainPage] context is nil")
    return
  end
  self:_load_context(self._context)
  self:_refresh_all()
end

function M:on_enable()
  base.on_enable(self)
  self:_reset_all_btn_state()
end

function M:on_before_close()
  if self._context and not self._has_finished then
    self:_finish(FinishReason.Exit, false)
  end
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  self._context = nil
  self._is_countdown_paused = false
  self._is_exit_confirm_showing = false
end

function M:bind_input_action()
  base.bind_input_action(self)
  for index, actions in pairs(ButtonActionMap) do
    local action_list = build_action_list(actions)
    if 0 < #action_list then
      self:bind_input_and_fun(action_list, function()
        self:_set_btn_state(index, BtnState.Default)
      end, ActionType.EType.ButtonReleased)
    end
  end
end

function M:update(delta_time)
  base.update(self, delta_time)
  if self._has_finished or self._is_countdown_paused or not self._context then
    return
  end
  if not self._is_game_started then
    self:_update_start_countdown(delta_time)
    return
  end
  self._remain_time = math.max(0, self._remain_time - delta_time)
  self._refresh_timer = self._refresh_timer + delta_time
  if self._refresh_timer >= REFRESH_INTERVAL or self._remain_time <= 0 then
    self._refresh_timer = 0
    self:_refresh_countdown()
  end
  if self._remain_time <= 0 then
    self:_finish(FinishReason.Timeout, true)
  end
end

function M:_reset_session()
  self._target_node_list = {}
  self._possible_node_list = {}
  self._player_node_list = {}
  self._node_view_data_map = {}
  self._node_view_data_by_node_id = {}
  self._button_index_to_node_ids = {}
  self._enabled_button_index_map = {}
  self._next_target_index = 1
  self._wrong_index = 0
  self._remain_time = 0
  self._countdown_total = 0
  self._start_countdown_remain = START_COUNTDOWN
  self._stage_state = nil
  self._refresh_timer = 0
  self._is_game_started = false
  self._is_countdown_paused = false
  self._is_exit_confirm_showing = false
  self._has_finished = false
end

function M:_load_context(context)
  self._target_node_list = list_to_table(context.nodeList)
  self._possible_node_list = list_to_table(context.possibleNodeList)
  self._node_view_data_map = context.nodeViewDataMap or {}
  self._countdown_total = tonumber(context.countdown) or 0
  self._remain_time = self._countdown_total
  self:_build_button_index_map()
  self:_refresh_qte_buttons()
  self:_refresh_stage_state()
  self._state_group_difficulty:SetState(context.difficultyDisplay)
  UIUtil.set_text(self._txt_difficulty, context.difficultyDesc)
end

function M:_build_button_index_map()
  for_each_view_data(self._node_view_data_map, function(node_id, view_data)
    if view_data then
      self._node_view_data_by_node_id[node_id] = view_data
    end
  end)
  for _, node_id in ipairs(self._possible_node_list) do
    local view_data = self:_get_node_view_data(node_id)
    local button_index = view_data and self:_key_code_to_button_index(view_data.keyCode) or nil
    if button_index and 1 <= button_index and button_index <= 4 then
      self._enabled_button_index_map[button_index] = true
      self._button_index_to_node_ids[button_index] = self._button_index_to_node_ids[button_index] or {}
      table.insert(self._button_index_to_node_ids[button_index], node_id)
    end
  end
end

function M:_key_code_to_button_index(key_code)
  if key_code == nil then
    return nil
  end
  local number_key = tonumber(key_code)
  if number_key and 1 <= number_key and number_key <= 4 then
    return number_key
  end
  if number_key and KeyCodeButtonMap[number_key] then
    return KeyCodeButtonMap[number_key]
  end
  return KeyCodeButtonMap[tostring(key_code)]
end

function M:_refresh_qte_buttons()
  for index = 1, 4 do
    local btn = self["_btn_qte_" .. tostring(index)]
    local is_enabled = self._enabled_button_index_map[index] == true
    if btn then
      UIUtil.set_active(btn, is_enabled)
    end
    local img_icon = self["_img_icon_qte_" .. tostring(index)]
    local icon_path = is_enabled and self:_get_button_icon_path(index) or nil
    if img_icon and string.is_valid(icon_path) then
      UIUtil.set_image(img_icon, icon_path, self:get_load_proxy())
    end
  end
end

function M:_get_button_icon_path(button_index)
  local node_ids = self._button_index_to_node_ids[button_index]
  local node_id = node_ids and node_ids[1] or nil
  local view_data = self:_get_node_view_data(node_id)
  return view_data and view_data.icon or nil
end

function M:_add_ui_listener()
  for index = 1, 4 do
    local btn = self["_btn_qte_" .. tostring(index)]
    self:_bind_qte_click(btn, index)
    self:_bind_qte_btn_state(btn, index)
  end
  self:_bind_close_confirm()
end

function M:_bind_qte_btn_state(btn, index)
  if not btn then
    return
  end
  local state_group = UIUtil.find_cmpt(btn.transform, nil, typeof(UIStateChangeGroup))
  self._btn_state_groups[index] = state_group
  self:_set_btn_state(index, BtnState.Default)
  if self._has_binder and state_group then
    self.binder:BindViewCallback(btn.transform, EventTriggerType.PointerUp, function(evt)
      self:_set_btn_state(index, BtnState.Default)
    end)
  end
end

function M:_set_btn_state(index, state)
  local state_group = self._btn_state_groups[index]
  if state_group then
    state_group:SetState(state)
  end
end

function M:_bind_close_confirm()
  if self._btn_close then
    self:bind_callback(self._btn_close, function()
      self:_show_exit_confirm_popup()
    end)
  end
end

function M:_bind_qte_click(btn, index)
  if btn then
    self:bind_callback(btn, function()
      self:_on_qte_button_pressed(index)
    end)
  end
end

function M:_ensure_action_items(count)
  if not self._act_item_binder then
    return
  end
  for i = #self._action_items + 1, count do
    local trans = self._act_item_binder:AddItem(0, true)
    if trans then
      local item = self:add_panel(ACTION_ITEM_CLS, trans)
      table.insert(self._action_items, item)
    end
  end
end

function M:_refresh_all()
  self:_refresh_start_countdown()
  self:_refresh_action_items()
  self:_refresh_round_score()
  self:_refresh_countdown()
end

function M:_refresh_round_score()
  local total_round = math.max(0, tonumber(self._context.totalRound) or 0)
  UIUtil.set_active(self._score_board_group, 0 < total_round)
  self:_ensure_score_items(total_round)
  local round_win_list = self._context.roundWinList
  local finished_count = round_win_list and round_win_list.Count or 0
  local npc_id = self:_get_npc_id()
  for index = 1, total_round do
    local item = self._score_items[index]
    item:set_active(true)
    local is_finished = index <= finished_count
    local is_player_win = is_finished and round_win_list[index - 1] == true
    local is_current = not is_finished and index == finished_count + 1
    item:set_result(is_finished, is_player_win, npc_id, is_current)
  end
  for index = total_round + 1, #self._score_items do
    self._score_items[index]:set_active(false)
  end
end

function M:_ensure_score_items(count)
  for index = #self._score_items + 1, count do
    local trans = self._score_item_binder:AddItem(0, true)
    self._score_items[index] = self:add_panel(HEAD_ITEM_CLS, trans)
  end
end

function M:_refresh_action_items()
  self:_ensure_action_items(#self._target_node_list)
  for index, node_id in ipairs(self._target_node_list) do
    local item = self._action_items[index]
    if item then
      item:set_active(true)
      item:set_node(node_id, self:_get_node_view_data(node_id))
      self:_refresh_action_item_state(item, index)
    end
  end
  for index = #self._target_node_list + 1, #self._action_items do
    local item = self._action_items[index]
    if item then
      item:set_active(false)
    end
  end
end

function M:_refresh_action_item_state(item, index)
  if self._wrong_index == index then
    item:set_wrong()
  elseif index < self._next_target_index then
    item:set_pressed()
  elseif index == self._next_target_index then
    item:set_current()
  else
    item:set_idle()
  end
end

function M:_refresh_action_item_state_by_index(index)
  local item = self._action_items[index]
  if item then
    self:_refresh_action_item_state(item, index)
  end
end

function M:_get_node_view_data(node_id)
  if not self._node_view_data_by_node_id then
    return nil
  end
  return self._node_view_data_by_node_id[node_id]
end

function M:_refresh_countdown()
  local remain = math.max(0, self._remain_time)
  local ratio = 0
  if 0 < self._countdown_total then
    ratio = remain / self._countdown_total
  end
  if self._txt_time_dynamic then
    UIUtil.set_text(self._txt_time_dynamic, tostring(math.ceil(remain)))
  end
  if self._slider_left then
    self._slider_left.value = ratio
  end
  if self._slider_right then
    self._slider_right.value = ratio
  end
  if self._state_group_cd_state then
    self._state_group_cd_state:SetState(ratio <= URGENT_RATIO and CdState.Urgent or CdState.Normal)
  end
end

function M:_update_start_countdown(delta_time)
  self._start_countdown_remain = math.max(0, self._start_countdown_remain - delta_time)
  if self._start_countdown_remain <= 0 and not self._is_game_started then
    self._is_game_started = true
    self:_play_enter_anim()
  end
  self:_refresh_start_countdown()
end

function M:_play_enter_anim()
  if not self._has_binder then
    return
  end
  self.binder:PlayAnimation("anim_qtegamemainpage_rightbottom_in")
end

function M:_refresh_start_countdown()
  self:_refresh_stage_state()
  if not self._txt_cd_dynamic or self._is_game_started then
    return
  end
  if self._start_countdown_remain > 0 then
    UIUtil.set_text(self._txt_cd_dynamic, tostring(math.ceil(self._start_countdown_remain)))
  end
end

function M:_refresh_stage_state()
  local stage_state = self._is_game_started and StageState.Playing or StageState.StartCountdown
  if self._stage_state == stage_state then
    return
  end
  self._stage_state = stage_state
  if self._state_group_stage then
    self._state_group_stage:SetState(stage_state)
  end
end

function M:_on_qte_button_pressed(button_index)
  if not (not self._has_finished and not self._is_countdown_paused and self._is_game_started) or not self._context then
    return
  end
  if self._enabled_button_index_map[button_index] ~= true then
    return
  end
  self:_set_btn_state(button_index, BtnState.Pressed)
  local target_node_id = self._target_node_list[self._next_target_index]
  local target_view_data = self:_get_node_view_data(target_node_id)
  local target_button_index = target_view_data and self:_key_code_to_button_index(target_view_data.keyCode) or nil
  if target_node_id == nil or target_button_index == nil then
    self:_record_pressed_node(button_index)
    self._wrong_index = self._next_target_index
    self:_refresh_action_item_state_by_index(self._wrong_index)
    self:_finish(FinishReason.WrongInput, true, 1.0)
    return
  end
  if button_index ~= target_button_index then
    self:_record_pressed_node(button_index)
    self._wrong_index = self._next_target_index
    self:_refresh_action_item_state_by_index(self._wrong_index)
    self:_finish(FinishReason.WrongInput, true, 1.0)
    return
  end
  table.insert(self._player_node_list, target_node_id)
  local pressed_index = self._next_target_index
  self._next_target_index = self._next_target_index + 1
  local pressed_item = self._action_items[pressed_index]
  if pressed_item then
    pressed_item:play_press_direction(button_index)
  end
  self:_refresh_action_item_state_by_index(pressed_index)
  self:_refresh_action_item_state_by_index(self._next_target_index)
  if self._next_target_index > #self._target_node_list then
    self:_finish(FinishReason.Success, true)
  end
end

function M:_record_pressed_node(button_index)
  local node_ids = self._button_index_to_node_ids[button_index]
  if node_ids and node_ids[1] then
    table.insert(self._player_node_list, node_ids[1])
  end
end

function M:_show_exit_confirm_popup()
  if self._has_finished or self._is_exit_confirm_showing then
    return
  end
  self._is_countdown_paused = true
  self._is_exit_confirm_showing = true
  UIManagerInstance:open(EXIT_CONFIRM_CLS, {
    info = get_text_or_default("Qte_Game_Exit_Confirm_Info", EXIT_CONFIRM_INFO),
    yes_text = UIUtil.get_text_by_id("Common_Yes"),
    no_text = UIUtil.get_text_by_id("Common_No"),
    npc_head = self:_get_confirm_npc_icon_path(),
    yes_callback = function()
      self._is_exit_confirm_showing = false
      self:_finish(FinishReason.Exit, true)
    end,
    no_callback = function()
      self:_resume_from_exit_confirm()
    end,
    close_callback = function()
      self:_resume_from_exit_confirm()
    end
  })
end

function M:_get_npc_id()
  local interaction_cfg = ExcelDataUtil.get_value(typeof(BNpcSpecialInteractionCfg), self._context.specialInteractionId)
  if not interaction_cfg or not interaction_cfg.npcid then
    return nil
  end
  return interaction_cfg.npcid
end

function M:_get_confirm_npc_icon_path()
  if not self._context then
    return nil
  end
  local npc_id = self:_get_npc_id()
  local npc_cfg = ExcelDataUtil.get_value(typeof(BNpcCfg), npc_id)
  return npc_cfg and npc_cfg.iconnamesmall or nil
end

function M:_resume_from_exit_confirm()
  if self._has_finished then
    return
  end
  self._is_exit_confirm_showing = false
  self._is_countdown_paused = false
end

function M:_finish(reason, close_page, delay)
  if self._has_finished then
    return
  end
  self._has_finished = true
  self._is_countdown_paused = false
  self._is_exit_confirm_showing = false
  if close_page then
    if delay then
      CsCoroutineManagerUtil.Invoke(delay, function()
        self:_do_callback(reason)
        self:close_self()
      end)
    else
      self:_do_callback(reason)
      self:close_self()
    end
  else
    self:_do_callback(reason)
  end
end

function M:_do_callback(reason)
  EventCenter.Broadcast(EventID.Performance.OnQteGameMainPageEnd, reason)
  if self._context and self._context.onFinish then
    self._context.onFinish(self._player_node_list, reason)
  end
end

function M:_reset_all_btn_state()
  for i = 1, 4 do
    self:_set_btn_state(i, BtnState.Default)
  end
end

return M
