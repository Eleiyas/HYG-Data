local reward_item_cls = "UI/MainActivity_y1/Riddle/RiddleRewardItem"
local INTRODUCTION_ID = 29
local ACTIVITY_END_DIALOG_TEXT_ID = "Activity_EndDialog_Desc"
local M = G.Class("RiddleRewardPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_DAURewardDialog"
  self.config.type = EUIType.Page
  self._current_active = 0
  self._max_active = 0
  self._reward_list = {}
  self._reward_items = {}
  self._event_id = riddle_module.default_event_id
  self._pending_claim_data = nil
  self._is_close = false
  self._activity_end_dialog_shown = false
end

function M:on_create()
  base.on_create(self)
  local event_id
  local extra_data = self:get_extra_data()
  if type(extra_data) == "table" then
    event_id = tonumber(extra_data.event_id)
  end
  if event_id == nil and type(self.args) == "table" then
    event_id = tonumber(self.args.event_id)
  end
  if event_id ~= nil and 0 < event_id then
    self._event_id = event_id
  end
  self:_bind_buttons()
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  self._activity_end_dialog_shown = false
  self._pending_claim_data = nil
  self:_try_refresh_from_server_data()
  self:_request_activity_info_if_needed()
  self:_refresh_view()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnRiddleActivityInfoChange, pack(self, M._on_riddle_activity_info_change))
  self:add_evt_listener(EventID.OnActivityRemoved, pack(self, M._on_activity_removed))
end

function M:bind_input_action()
  base.bind_input_action(self)
  if self._btn_close ~= nil then
    self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
  end
end

function M:_bind_buttons()
  if not is_null(self._btn_close) then
    self:bind_callback(self._btn_close, pack(self, M._on_click_close))
  end
  if not is_null(self._btn_introduction) then
    self:bind_callback(self._btn_introduction, pack(self, M._on_click_introduction))
    UIUtil.set_active(self._btn_introduction, 0 < INTRODUCTION_ID)
  end
end

function M:_on_click_close()
  if self._is_close then
    return
  end
  self._is_close = true
  UIManagerInstance:close_page_with_dialogs_above(self)
  EventCenter.Broadcast(EventID.LuaRiddleRewardUserClose)
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
    self:_on_click_close()
  end)
  popup:show()
end

function M:_on_click_introduction()
  if 0 < INTRODUCTION_ID then
    UIManagerInstance:open("UI/CommonUI/IntroductionDialog", INTRODUCTION_ID)
  end
end

function M:_request_activity_info_if_needed()
  riddle_module:request_activity_info_if_needed(self._event_id)
end

function M:_on_riddle_activity_info_change(event_id)
  if self._event_id > 0 and tonumber(event_id) ~= self._event_id then
    return
  end
  if not self:is_in_show_state() then
    return
  end
  self:_try_refresh_from_server_data()
  self:_refresh_view()
  self:_try_show_claim_reward_dialog()
end

function M:_try_refresh_from_server_data()
  self._current_active, self._max_active = riddle_module:get_active_value()
  self._reward_list = riddle_module:get_stage_reward_list()
end

function M:_refresh_view()
  self:_refresh_progress_text()
  self:_refresh_reward_list()
end

function M:_refresh_progress_text()
  local max_active = self._max_active
  local cur_active = self._current_active
  if 0 < max_active and max_active < cur_active then
    cur_active = max_active
  end
  if not is_null(self._text_progress) then
    UIUtil.set_text(self._text_progress, string.format("%d/%d", cur_active, max_active))
  end
end

function M:_refresh_reward_list()
  if is_null(self._layout_list) then
    Logger.LogWarning("[RiddleRewardPage] _layout_list not bound")
    return
  end
  if self._layout_list.AddItem == nil then
    Logger.LogWarning("[RiddleRewardPage] _layout_list has no AddItem")
    return
  end
  local count = #self._reward_list
  for i = #self._reward_items + 1, count do
    local go = self._layout_list:AddItem(0)
    if is_null(go) then
      Logger.LogWarning("[RiddleRewardPage] _layout_list:AddItem failed")
      break
    end
    local item = self:add_panel(reward_item_cls, go)
    table.insert(self._reward_items, item)
  end
  for i = 1, count do
    local item = self._reward_items[i]
    local data = self._reward_list[i]
    if item ~= nil and data ~= nil then
      local reward_item_id, reward_count = self:_resolve_reward_item(data)
      item:set_active(true)
      item:refresh({
        stage = tonumber(data.stage) or i,
        need_active = tonumber(data.need_active) or 0,
        prev_need_active = 1 < i and tonumber(self._reward_list[i - 1] and self._reward_list[i - 1].need_active) or 0 or 0,
        current_active = self._current_active,
        state = self:_resolve_reward_state(data),
        on_click_claim = pack(self, M._on_click_claim),
        is_last = data.is_last == true or i == count,
        reward_item_id = reward_item_id,
        reward_count = reward_count
      })
    end
  end
  for i = count + 1, #self._reward_items do
    local item = self._reward_items[i]
    if item ~= nil then
      item:set_active(false)
    end
  end
end

function M:_on_click_claim(stage)
  local stage_num = tonumber(stage) or 0
  if stage_num <= 0 then
    return
  end
  local data = self:_find_reward_data_by_stage(stage_num)
  if data == nil then
    return
  end
  if self:_resolve_reward_state(data) ~= riddle_module.stage_reward_state.can_take then
    return
  end
  local stages, items = riddle_module:request_take_all_stage_rewards(self._event_id)
  if #stages == 0 then
    return
  end
  self._pending_claim_data = {stages = stages, items = items}
end

function M:_find_reward_data_by_stage(stage)
  for _, data in ipairs(self._reward_list) do
    if tonumber(data.stage) == tonumber(stage) then
      return data
    end
  end
  return nil
end

function M:_try_show_claim_reward_dialog()
  local pending = self._pending_claim_data
  if pending == nil then
    return
  end
  for _, stage in ipairs(pending.stages) do
    local data = self:_find_reward_data_by_stage(stage)
    if data == nil then
      return
    end
    if self:_resolve_reward_state(data) ~= riddle_module.stage_reward_state.taken then
      return
    end
  end
  self._pending_claim_data = nil
  if pending.items == nil or #pending.items <= 0 then
    return
  end
  UIManagerInstance:open("UI/CommonUI/CommonRewardDialog", {
    items = pending.items
  })
end

function M:_resolve_reward_state(data)
  return riddle_module:get_stage_reward_state(data)
end

function M:_resolve_reward_item(data)
  return riddle_module:get_stage_reward_display_item(data)
end

function M:_resolve_reward_items(data)
  return riddle_module:get_stage_reward_items(data)
end

return M
