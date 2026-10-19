local M = G.Class("CommonSearchFieldPanel", G.UIPanel)
local base = G.UIPanel
local default_history_item_cls = "UI/CommonUI/SearchFilter/CommonSearchHistoryItem"
local callback_reason = {
  button = "button",
  blank = "blank",
  history = "history",
  submit = "submit",
  sync = "sync"
}
local search_state = {
  empty_idle = 1,
  editing_empty = 2,
  editing_draft = 3,
  result_idle = 4,
  editing_result = 5
}

local function default_normalize_text(text)
  if text == nil then
    return ""
  end
  text = tostring(text)
  return string.trim and string.trim(text) or text
end

local function default_history_filter(history_text, search_text)
  local normalized = string.lower(default_normalize_text(search_text))
  local history = string.lower(default_normalize_text(history_text))
  return not string.is_valid(normalized) or string.find(history, normalized, 1, true) ~= nil
end

function M:init()
  base.init(self)
  self._history_items = {}
  self._history_cache = {}
  self._history_limit = nil
  self._history_item_cls = default_history_item_cls
  self._normalizer = default_normalize_text
  self._history_filter = default_history_filter
  self._record_history_callback = nil
  self._input_submit_listener = nil
  self._input_select_listener = nil
  self._input_deselect_listener = nil
  self._applied_search_text = ""
  self._history_input_rect = nil
  self._is_panel_visible = false
  self._is_input_selected = false
  self._focus_request_id = 0
  self._is_setting_search_text = false
  self._search_sm = G.New("Common/SimpleStateMachine")
  self:_init_search_sm()
end

function M:on_create()
  base.on_create(self)
  self:_read_extra_config()
  self:_init_history_template()
  if not is_null(self._input_search) then
    self._input_submit_listener = pack(self, M._on_submit_input)
    self._input_select_listener = pack(self, M._on_input_select)
    self._input_deselect_listener = pack(self, M._on_input_deselect)
    self._input_search.onSubmit:AddListener(self._input_submit_listener)
    self._input_search.onSelect:AddListener(self._input_select_listener)
    self._input_search.onDeselect:AddListener(self._input_deselect_listener)
    self:bind_value_change_action(self._input_search, pack(self, M._on_input_changed))
  end
  if not is_null(self._btn_clear) then
    self:bind_callback(self._btn_clear, pack(self, M._on_click_clear))
  end
  if not is_null(self._btn_search) then
    self:bind_callback(self._btn_search, pack(self, M._on_click_search))
  end
  self._search_sm:set_initial_state(search_state.empty_idle)
end

function M:on_enable()
  base.on_enable(self)
  self:sync_visibility(true)
end

function M:on_disable()
  self._focus_request_id = self._focus_request_id + 1
  self._is_input_selected = false
  self:sync_visibility(false)
  base.on_disable(self)
end

function M:on_destroy()
  self._focus_request_id = self._focus_request_id + 1
  if not is_null(self._input_search) then
    if self._input_submit_listener ~= nil then
      self._input_search.onSubmit:RemoveListener(self._input_submit_listener)
    end
    if self._input_select_listener ~= nil then
      self._input_search.onSelect:RemoveListener(self._input_select_listener)
    end
    if self._input_deselect_listener ~= nil then
      self._input_search.onDeselect:RemoveListener(self._input_deselect_listener)
    end
  end
  self._input_submit_listener = nil
  self._input_select_listener = nil
  self._input_deselect_listener = nil
  base.on_destroy(self)
end

function M:set_config(config)
  config = config or {}
  self._history_item_cls = config.history_item_cls or self._history_item_cls
  self._normalizer = config.normalizer or self._normalizer or default_normalize_text
  self._history_filter = config.history_filter or self._history_filter or default_history_filter
  self._record_history_callback = config.on_record_history or self._record_history_callback
  self:set_history_list(config.history_list, config.history_limit)
end

function M:set_callbacks(callbacks)
  callbacks = callbacks or {}
  self._submit_callback = callbacks.on_submit
  self._candidate_callback = callbacks.on_candidate_refresh
  self._clear_callback = callbacks.on_clear
  self._request_close_callback = callbacks.on_request_close
end

function M:sync_visibility(is_visible)
  self._is_panel_visible = is_visible == true
  if self._is_panel_visible and self:_is_editing_state() then
    self:_refresh_history_candidates(self:get_search_text())
  else
    self:_hide_history_candidates()
  end
end

function M:set_search_text(search_text, should_refresh_history)
  if not is_null(self._input_search) then
    local final_text = search_text or ""
    if self._input_search.SetTextWithoutNotify ~= nil then
      self._input_search:SetTextWithoutNotify(final_text)
      if self._input_search.UpdateTipState ~= nil then
        self._input_search:UpdateTipState()
      end
    else
      self._is_setting_search_text = true
      self._input_search.text = final_text
      self._is_setting_search_text = false
    end
  end
  if should_refresh_history == false then
    return
  end
  if self:_is_editing_state() then
    self:_refresh_history_candidates(search_text or "")
  end
end

function M:get_search_text()
  if is_null(self._input_search) then
    return ""
  end
  return self:_normalize_text(self._input_search.text)
end

function M:sync_reset()
  self._applied_search_text = ""
  self:set_search_text("")
  self._search_sm:change_state(search_state.empty_idle, nil, true)
end

function M:show_history_candidates()
  if self._is_panel_visible and self:_is_editing_state() then
    self:_refresh_history_candidates(self:get_search_text())
  end
end

function M:open()
  local current_text = self:get_search_text()
  local applied_text = self:_normalize_text(self._applied_search_text)
  if string.is_valid(applied_text) and current_text == applied_text then
    self._search_sm:change_state(search_state.editing_result, nil, true)
  elseif string.is_valid(current_text) then
    self._search_sm:change_state(search_state.editing_draft, nil, true)
  else
    self._search_sm:change_state(search_state.editing_empty, nil, true)
  end
end

function M:set_history_list(history_list, history_limit)
  if history_limit ~= nil then
    self._history_limit = history_limit
  end
  if history_list == nil then
    return
  end
  self._history_cache = self:_clone_history_list(history_list)
end

function M:sync_applied_text(search_text)
  local final_text = self:_normalize_text(search_text)
  if self:get_search_text() ~= final_text then
    self:set_search_text(final_text, false)
  end
  self._applied_search_text = final_text
  local next_state = string.is_valid(final_text) and search_state.result_idle or search_state.empty_idle
  self._search_sm:change_state(next_state, nil, true)
end

function M:request_submit(reason, search_text, should_store)
  local final_text = self:_normalize_text(search_text or self:get_search_text())
  if self:get_search_text() ~= final_text then
    self:set_search_text(final_text, false)
  end
  if not string.is_valid(final_text) then
    self._search_sm:change_state(search_state.editing_empty)
    return
  end
  if should_store ~= false and string.is_valid(final_text) then
    self:_record_history(final_text)
  end
  self._applied_search_text = final_text
  self._search_sm:change_state(search_state.result_idle, nil, true)
  if self._submit_callback then
    self._submit_callback(final_text, reason or callback_reason.submit)
  end
end

function M:_read_extra_config()
  local data = self.get_extra_data and self:get_extra_data() or nil
  if data and data.search_config then
    self:set_config(data.search_config)
  elseif data then
    self:set_config(data)
  end
end

function M:_normalize_text(text)
  local normalizer = self._normalizer or default_normalize_text
  return normalizer(text)
end

function M:_init_search_sm()
  self._search_sm:register_state(search_state.empty_idle, pack(self, M._on_empty_idle_enter), nil)
  self._search_sm:register_state(search_state.editing_empty, pack(self, M._on_editing_empty_enter), nil)
  self._search_sm:register_state(search_state.editing_draft, pack(self, M._on_editing_draft_enter), nil)
  self._search_sm:register_state(search_state.result_idle, pack(self, M._on_result_idle_enter), nil)
  self._search_sm:register_state(search_state.editing_result, pack(self, M._on_editing_result_enter), nil)
end

function M:_on_empty_idle_enter()
  self:_hide_history_candidates()
  self:_set_delete_button_active(false)
end

function M:_on_editing_empty_enter()
  self:_activate_input_field()
  self:_set_delete_button_active(false)
  self:show_history_candidates()
end

function M:_on_editing_draft_enter()
  self:_activate_input_field()
  self:_set_delete_button_active(true)
  self:show_history_candidates()
end

function M:_on_result_idle_enter()
  self:_hide_history_candidates()
  self:_set_delete_button_active(string.is_valid(self._applied_search_text))
end

function M:_on_editing_result_enter()
  self:_activate_input_field()
  self:_set_delete_button_active(true)
  self:show_history_candidates()
end

function M:_activate_input_field()
  if is_null(self._input_search) then
    return
  end
  local input_search = self._input_search
  self._focus_request_id = self._focus_request_id + 1
  local focus_request_id = self._focus_request_id
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if not (focus_request_id == self._focus_request_id and self._is_panel_visible) or is_null(input_search) then
      return
    end
    if input_search.ActivateInputField ~= nil then
      input_search:ActivateInputField()
    elseif input_search.Select ~= nil then
      input_search:Select()
    end
    self._is_input_selected = true
    self:show_history_candidates()
  end)
end

function M:_on_submit_input()
  self:request_submit(callback_reason.submit, nil, true)
end

function M:_on_input_select()
  self._is_input_selected = true
  if self:_is_editing_state() then
    self:show_history_candidates()
  else
    self:open()
  end
end

function M:_on_input_deselect()
  if self:_is_pointer_in_search_control_or_history_rect() then
    return
  end
  self._is_input_selected = false
  self:_hide_history_candidates()
  self:_process_input_deselect()
end

function M:_on_input_changed()
  if self._is_setting_search_text then
    return
  end
  self:_refresh_editing_state_by_text()
  if self:_is_editing_state() then
    self:show_history_candidates()
  end
end

function M:_on_click_clear()
  self:request_clear(callback_reason.button, true)
end

function M:request_clear(reason, keep_editing)
  self._applied_search_text = ""
  self:set_search_text("")
  self._search_sm:change_state(keep_editing and search_state.editing_empty or search_state.empty_idle, nil, true)
  if self._clear_callback then
    self._clear_callback(reason or callback_reason.button)
  elseif self._submit_callback then
    self._submit_callback("", reason or callback_reason.button)
  end
end

function M:request_blank_close(reason)
  local current_text = self:get_search_text()
  local applied_text = self:_normalize_text(self._applied_search_text)
  if string.is_valid(applied_text) and current_text == applied_text then
    self._search_sm:change_state(search_state.result_idle)
    return
  end
  if string.is_valid(current_text) or string.is_valid(applied_text) then
    self:request_clear(reason or callback_reason.blank, false)
  else
    self._search_sm:change_state(search_state.empty_idle, nil, true)
  end
  if self._request_close_callback then
    self._request_close_callback(reason or callback_reason.blank)
  end
end

function M:_process_input_deselect()
  local current_text = self:get_search_text()
  local applied_text = self:_normalize_text(self._applied_search_text)
  if string.is_valid(applied_text) and current_text == applied_text then
    self._search_sm:change_state(search_state.result_idle)
    return
  end
  if string.is_valid(current_text) then
    self._search_sm:change_state(search_state.editing_draft)
    self:_hide_history_candidates()
    return
  end
  self._search_sm:change_state(string.is_valid(applied_text) and search_state.result_idle or search_state.empty_idle)
end

function M:_refresh_editing_state_by_text()
  local current_text = self:get_search_text()
  local applied_text = self:_normalize_text(self._applied_search_text)
  if not string.is_valid(current_text) then
    self._search_sm:change_state(search_state.editing_empty)
  elseif string.is_valid(applied_text) and current_text == applied_text then
    self._search_sm:change_state(search_state.editing_result)
  else
    self._search_sm:change_state(search_state.editing_draft)
  end
end

function M:_is_editing_state()
  local state = self._search_sm and self._search_sm:get_state() or nil
  return state == search_state.editing_empty or state == search_state.editing_draft or state == search_state.editing_result
end

function M:_on_click_search()
  self:request_submit(callback_reason.button, nil, true)
end

function M:_on_click_history_item(history_text)
  self:set_search_text(history_text, false)
  self:request_submit(callback_reason.history, history_text, true)
end

function M:_set_delete_button_active(is_active)
  if not is_null(self._btn_clear) then
    UIUtil.set_active(self._btn_clear, is_active == true)
  end
end

function M:_clone_history_list(history_list)
  local result = {}
  for _, history_text in ipairs(history_list or {}) do
    history_text = self:_normalize_text(history_text)
    if string.is_valid(history_text) then
      table.insert(result, history_text)
    end
    if self._history_limit ~= nil and #result >= self._history_limit then
      break
    end
  end
  return result
end

function M:_record_history(search_text)
  search_text = self:_normalize_text(search_text)
  if not string.is_valid(search_text) then
    return
  end
  if self._record_history_callback == nil then
    return
  end
  local history_list, history_limit = self._record_history_callback(search_text)
  if history_list ~= nil then
    self:set_history_list(history_list, history_limit)
  end
end

function M:_get_filtered_history(search_text)
  local result = {}
  local filter = self._history_filter or default_history_filter
  for _, item in ipairs(self._history_cache) do
    if filter(item, search_text) then
      table.insert(result, item)
    end
  end
  return result
end

function M:_refresh_history_candidates(search_text)
  local filtered_history = self:_get_filtered_history(search_text)
  for index, history_text in ipairs(filtered_history) do
    local item = self:_get_history_item(index)
    item:refresh(history_text, pack(self, M._on_click_history_item))
  end
  for index = #filtered_history + 1, #self._history_items do
    self._history_items[index]:set_active(false)
  end
  self:_set_history_candidates_active(self._is_panel_visible and self._is_input_selected and self:_is_editing_state() and 0 < #filtered_history)
  if self._candidate_callback then
    self._candidate_callback(search_text, filtered_history)
  end
end

function M:_hide_history_candidates()
  self:_set_history_candidates_active(false)
end

function M:_is_pointer_in_search_control_or_history_rect()
  if Input == nil or Vector2 == nil or RectTransformUtility == nil then
    return false
  end
  local mouse_pos = Input.mousePosition
  local screen_point = Vector2(mouse_pos.x, mouse_pos.y)
  return self:_is_screen_point_in_component_rect(self._input_search, screen_point) or self:_is_screen_point_in_component_rect(self._btn_clear, screen_point) or self:_is_screen_point_in_component_rect(self._btn_search, screen_point) or self:_is_screen_point_in_rect(self:_get_history_input_rect(), screen_point)
end

function M:_is_screen_point_in_component_rect(component, screen_point)
  if is_null(component) then
    return false
  end
  return self:_is_screen_point_in_rect(component.transform, screen_point)
end

function M:_get_history_input_rect()
  if is_null(self._history_input_rect) and not is_null(self._history_prompt_root) then
    self._history_input_rect = UIUtil.find_rect_trans(self._history_prompt_root, "InputField_InputHistory")
  end
  return self._history_input_rect
end

function M:_is_screen_point_in_rect(rect_trans, screen_point)
  if is_null(rect_trans) or not rect_trans.gameObject.activeInHierarchy then
    return false
  end
  return RectTransformUtility.RectangleContainsScreenPoint(rect_trans, screen_point, UIManagerInstance.ui_camera)
end

function M:_init_history_template()
  UIUtil.set_active(self._history_prompt_root, false)
  UIUtil.set_active(self._history_item_template, false)
end

function M:_set_history_candidates_active(is_active)
  UIUtil.set_active(self._history_prompt_root, is_active == true)
end

function M:_get_history_item(index)
  local item = self._history_items[index]
  if item ~= nil then
    return item
  end
  local go = UIUtil.load_prefab_set_parent(self._history_item_template, self._history_content_root)
  local panel = self:add_panel(self._history_item_cls, go)
  self._history_items[index] = panel
  return panel
end

return M
