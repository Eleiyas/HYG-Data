local search_engine = require("UI/Codex/Search/CodexSearchEngine")
local history_panel_class = "UI/Codex/Search/CodexSearchHistoryPanel"
local suggestion_panel_class = "UI/Codex/Search/CodexSearchSuggestionPanel"
local result_page_class = "UI/Codex/Search/CodexSearchResultPage"
local input_state = {has_text = 0, empty = 1}
local view_state = {history = 1, suggestion = 2}

local function recursive_find(trans, child_name)
  if is_null(trans) or not string.is_valid(child_name) then
    return nil
  end
  return CsUIUtil.RecursiveFindChild(trans, child_name)
end

local function get_component(trans, component_type)
  if is_null(trans) then
    return nil
  end
  return trans:GetComponent(component_type)
end

local function find_component(trans, component_type)
  if is_null(trans) then
    return nil
  end
  local ok, cmpt = pcall(function()
    return trans:GetComponentInChildren(component_type, true)
  end)
  if ok and not is_null(cmpt) then
    return cmpt
  end
  return UIUtil.find_cmpt(trans, nil, component_type)
end

local function first_not_null(...)
  for i = 1, select("#", ...) do
    local value = select(i, ...)
    if not_null(value) then
      return value
    end
  end
  return nil
end

local function normalize_text(text)
  if text == nil then
    return ""
  end
  text = tostring(text)
  if string.trim then
    return string.trim(text)
  end
  text = string.gsub(text, "^%s+", "")
  text = string.gsub(text, "%s+$", "")
  return text
end

local function to_screen_point(position)
  if position == nil then
    return nil
  end
  return Vector2(position.x, position.y)
end

local function get_pointer_down_position()
  if Input.GetMouseButtonDown(0) then
    return to_screen_point(Input.mousePosition)
  end
  if 0 < Input.touchCount then
    local touch = Input.GetTouch(0)
    if touch.phase == TouchPhase.Began then
      return to_screen_point(touch.position)
    end
  end
  return nil
end

local function get_current_pointer_position()
  if Input.touchCount > 0 then
    local touch = Input.GetTouch(0)
    return to_screen_point(touch.position)
  end
  return to_screen_point(Input.mousePosition)
end

local function is_pointer_pressed()
  return Input.GetMouseButton(0) or 0 < Input.touchCount
end

local function get_target_transform(target)
  if is_null(target) then
    return nil
  end
  local ok, target_trans = pcall(function()
    return target.transform
  end)
  if ok and not_null(target_trans) then
    return target_trans
  end
  return target
end

local function get_rect_transform(target)
  local target_trans = get_target_transform(target)
  if is_null(target_trans) or is_null(target_trans.gameObject) or not target_trans.gameObject.activeInHierarchy then
    return nil
  end
  local rect_trans = get_component(target_trans, typeof(RectTransform))
  if not_null(rect_trans) then
    return rect_trans
  end
  return UIUtil.find_rect_trans(target_trans)
end

local function is_screen_position_in_transform(screen_position, target)
  local rect_trans = get_rect_transform(target)
  if is_null(rect_trans) then
    return false
  end
  local camera = UIManagerInstance and UIManagerInstance.ui_camera or nil
  local canvas = rect_trans:GetComponentInParent(typeof(Canvas))
  if not_null(canvas) and not_null(canvas.worldCamera) then
    camera = canvas.worldCamera
  end
  return RectTransformUtility.RectangleContainsScreenPoint(rect_trans, screen_position, camera)
end

local function is_transform_active(target)
  local target_trans = get_target_transform(target)
  return not_null(target_trans) and not_null(target_trans.gameObject) and target_trans.gameObject.activeInHierarchy
end

local function append_protected_transform(protected_transforms, protected_transform)
  if is_null(protected_transform) then
    return
  end
  table.insert(protected_transforms, protected_transform)
end

local M = G.Class("CodexSearchPanel", G.UIPanel)
local base = G.UIPanel

function M:init()
  base.init(self)
  self._history_panel = nil
  self._suggestion_panel = nil
  self._current_view = view_state.history
  self._last_keyword = ""
  self._context = nil
  self._context_provider = nil
  self._on_search_callback = nil
  self._on_close_callback = nil
  self._on_field_state_callback = nil
  self._on_view_state_callback = nil
  self._is_search_field_open = false
  self._direct_listeners = {}
  self._input_submit_listener = nil
  self._input_deselect_listener = nil
  self._outside_click_callback = nil
  self._outside_click_protected_transforms = nil
  self._is_outside_click_enabled = true
  self._outside_click_enable_frame = 0
  self._pending_outside_click_frame = 0
  self._outside_click_release_suppress_frame = 0
  self._is_suppressing_option_select = false
end

function M:on_create()
  base.on_create(self)
  self:_init_sub_panels()
  self:_add_ui_listener()
  self:_reset_ui_state()
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:update(delta_time)
  if self.is_active == false then
    return
  end
  if base.update then
    base.update(self, delta_time)
  end
  self:_update_outside_click()
end

function M:on_destroy()
  self:_remove_direct_listeners()
  base.on_destroy(self)
end

function M:set_callbacks(on_search, on_close)
  self._on_search_callback = on_search
  self._on_close_callback = on_close
end

function M:set_field_state_callback(callback)
  self._on_field_state_callback = callback
end

function M:set_view_state_callback(callback)
  self._on_view_state_callback = callback
end

function M:set_outside_click_callback(callback)
  self._outside_click_callback = callback
end

function M:set_outside_click_protected_transforms(protected_transforms)
  if protected_transforms == nil then
    self._outside_click_protected_transforms = nil
    return
  end
  self._outside_click_protected_transforms = {}
  for _, protected_transform in pairs(protected_transforms) do
    append_protected_transform(self._outside_click_protected_transforms, protected_transform)
  end
end

function M:add_outside_click_protected_transform(protected_transform)
  if is_null(protected_transform) then
    return
  end
  if self._outside_click_protected_transforms == nil then
    self._outside_click_protected_transforms = self:_get_default_protected_transforms()
  end
  table.insert(self._outside_click_protected_transforms, protected_transform)
end

function M:reset_outside_click_protected_transforms()
  self._outside_click_protected_transforms = nil
end

function M:set_outside_click_enabled(is_enabled)
  self._is_outside_click_enabled = is_enabled ~= false
end

function M:set_context(context)
  self._context = context or {}
  if self._suggestion_panel and self._suggestion_panel.set_context then
    self._suggestion_panel:set_context(self._context)
  end
end

function M:set_context_provider(provider)
  self._context_provider = provider
end

function M:open(context)
  self:set_active(true)
  self:_reset_ui_state()
  self:_set_search_field_open(true)
  self:_show_history_view()
  self:_focus_input()
end

function M:close()
  if self._on_close_callback then
    self._on_close_callback(self._context)
  end
  self:_set_search_field_open(false)
end

function M:reset_state()
  self:_reset_ui_state()
  if self._on_search_callback then
    self._on_search_callback("", {}, self._context)
  end
end

function M:dismiss_panels()
  if not_null(self._trans_history) then
    UIUtil.set_active(self._trans_history, false)
  end
  if not_null(self._trans_suggested) then
    UIUtil.set_active(self._trans_suggested, false)
  end
  if self._on_view_state_callback then
    self._on_view_state_callback(false)
  end
end

function M:collapse()
  self:_reset_ui_state()
end

function M:submit_current_search()
  local text = self:_get_input_text()
  self:_execute_search(text)
end

function M:is_search_field_open()
  return self._is_search_field_open == true
end

function M:show_with_keyword(keyword)
  self._is_search_field_open = true
  if not_null(self._btn_open_search) then
    UIUtil.set_active(self._btn_open_search, false)
  end
  if not_null(self._trans_search_field) then
    UIUtil.set_active(self._trans_search_field, true)
  end
  if not_null(self._trans_history) then
    UIUtil.set_active(self._trans_history, false)
  end
  if not_null(self._trans_suggested) then
    UIUtil.set_active(self._trans_suggested, false)
  end
  if not_null(self._input_search) then
    if self._input_search.SetTextWithoutNotify then
      self._input_search:SetTextWithoutNotify(keyword or "")
    else
      self._input_search.text = keyword or ""
    end
  end
  self:_refresh_input_state(string.is_valid(keyword) and input_state.has_text or input_state.empty)
  self:_set_input_selected_visual(true)
end

function M:_init_sub_panels()
  if not_null(self._trans_history) then
    self._history_panel = self:add_panel(history_panel_class, self._trans_history)
    if self._history_panel then
      self._history_panel:set_on_select(function(keyword)
        self:_on_history_select(keyword)
      end)
    end
  end
  if not_null(self._trans_suggested) then
    self._suggestion_panel = self:add_panel(suggestion_panel_class, self._trans_suggested)
    if self._suggestion_panel then
      self._suggestion_panel:set_on_select(function(name)
        self:_on_suggestion_select(name)
      end)
    end
  end
end

function M:_add_ui_listener()
  if not_null(self._btn_open_search) then
    self:bind_callback(self._btn_open_search, pack(self, M._on_btn_open_search))
  end
  if not_null(self._btn_close) then
    self:bind_callback(self._btn_close, pack(self, M.close))
  end
  if not_null(self._btn_clear) then
    self:bind_callback(self._btn_clear, pack(self, M._on_btn_clear))
  end
  if not_null(self._btn_search) then
    self:bind_callback(self._btn_search, pack(self, M._on_btn_search))
  end
  if not_null(self._input_search) then
    self:bind_value_change_action(self._input_search, pack(self, M._on_input_changed))
    self._input_submit_listener = pack(self, M._on_input_submit)
    self._input_search.onSubmit:AddListener(self._input_submit_listener)
    self._input_deselect_listener = pack(self, M._on_input_deselect)
    self._input_search.onDeselect:AddListener(self._input_deselect_listener)
  end
end

function M:_reset_ui_state()
  self._last_keyword = ""
  if not_null(self._input_search) then
    self._input_search.text = ""
  end
  self:_set_search_field_open(false)
  self:_refresh_input_state(input_state.empty)
end

function M:_set_input_selected_visual(is_selected)
  if is_null(self._input_search) or self._input_search.SetSelect == nil then
    return
  end
  self._input_search:SetSelect(is_selected == true)
end

function M:_focus_input()
  if is_null(self._input_search) then
    return
  end
  self:_set_input_selected_visual(false)
  if self._input_search.ActivateInputField then
    self._input_search:ActivateInputField()
  elseif self._input_search.Select then
    self._input_search:Select()
  end
  self:_sync_input_state()
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    if self._is_search_field_open then
      self:_sync_input_state()
    end
  end)
end

function M:_sync_input_state()
  local has_text = string.is_valid(self:_get_input_text())
  self:_refresh_input_state(has_text and input_state.has_text or input_state.empty)
end

function M:_unfocus_input()
  if is_null(self._input_search) then
    return
  end
  self:_set_input_selected_visual(false)
  if self._input_search.DeactivateInputField then
    self._input_search:DeactivateInputField()
  end
end

function M:_on_input_deselect()
  if self._is_search_field_open then
    self:_set_input_selected_visual(true)
  end
end

function M:_get_input_text()
  if is_null(self._input_search) then
    return ""
  end
  return normalize_text(self._input_search.text)
end

function M:_resolve_context()
  if self._context_provider then
    local context = self._context_provider()
    if context ~= nil then
      return context
    end
  end
  return self._context
end

function M:_set_search_field_open(is_open)
  self._is_search_field_open = is_open == true
  if self._is_search_field_open then
    self._outside_click_enable_frame = Time.frameCount + 1
  end
  if not_null(self._btn_open_search) then
    UIUtil.set_active(self._btn_open_search, not self._is_search_field_open)
  end
  if not_null(self._trans_search_field) then
    UIUtil.set_active(self._trans_search_field, self._is_search_field_open)
  end
  if not self._is_search_field_open then
    if not_null(self._trans_history) then
      UIUtil.set_active(self._trans_history, false)
    end
    if not_null(self._trans_suggested) then
      UIUtil.set_active(self._trans_suggested, false)
    end
  end
  if self._on_field_state_callback then
    self._on_field_state_callback(self._is_search_field_open)
  end
  if not self._is_search_field_open then
    self:_unfocus_input()
  end
end

function M:_on_btn_open_search()
  self:_reset_ui_state()
  self:_set_search_field_open(true)
  self:_show_history_view()
  self:_focus_input()
end

function M:_on_btn_clear()
  if not_null(self._input_search) then
    self._input_search.text = ""
  end
  self:_refresh_input_state(input_state.empty)
  if self._history_panel then
    self:_show_history_view()
  else
    self:_switch_view(view_state.suggestion)
  end
  if self._on_search_callback then
    self._on_search_callback("", {}, self._context)
  end
end

function M:_on_btn_search()
  if self:_should_ignore_search_submit() then
    return
  end
  self:_execute_search(self:_get_input_text())
end

function M:_on_input_submit()
  self:_on_btn_search()
end

function M:_should_ignore_search_submit()
  return self._pending_outside_click_frame > 0 or Time.frameCount <= self._outside_click_release_suppress_frame
end

function M:_on_input_changed(text)
  text = normalize_text(text)
  if string.is_valid(text) then
    local filtered = search_engine.filter_input(text)
    if filtered ~= text and not_null(self._input_search) then
      self._input_search.text = filtered
      return
    end
    self:_refresh_input_state(input_state.has_text)
    if self._suggestion_panel then
      self._suggestion_panel:refresh(text)
      self:_switch_view(view_state.suggestion)
    end
  else
    self:_refresh_input_state(input_state.empty)
    if self._history_panel then
      self:_show_history_view()
    elseif self._on_search_callback then
      self._on_search_callback("", {})
    end
  end
end

function M:_on_history_select(keyword)
  if self:_should_ignore_option_select() then
    return
  end
  self:_fill_input_without_search(keyword)
end

function M:_on_suggestion_select(name)
  if self:_should_ignore_option_select() then
    return
  end
  self:_fill_input_without_search(name)
end

function M:_fill_input_without_search(keyword)
  keyword = keyword or ""
  if not_null(self._input_search) then
    if self._input_search.SetTextWithoutNotify then
      self._input_search:SetTextWithoutNotify(keyword)
    else
      self._input_search.text = keyword
    end
  end
  self:_on_input_changed(keyword)
end

function M:_execute_search(keyword)
  keyword = normalize_text(keyword)
  if not string.is_valid(keyword) then
    self:_on_btn_clear()
    return
  end
  self._last_keyword = keyword
  local results = search_engine.search(keyword)
  if not_null(results) and table.count(results) > 0 and self._history_panel then
    self._history_panel:add_record(keyword)
  end
  UIManagerInstance:open(result_page_class, {
    keyword = keyword,
    results = results,
    context = self._context
  })
  if self._on_search_callback then
    self._on_search_callback(keyword, results, self._context)
  end
end

function M:_show_history_view()
  if self._history_panel and self._history_panel:has_records() then
    self._history_panel:refresh()
    self:_switch_view(view_state.history)
  else
    self:dismiss_panels()
  end
end

function M:_switch_view(state)
  self._current_view = state
  local show_history = state == view_state.history
  local show_suggestion = state == view_state.suggestion
  if not_null(self._trans_history) then
    UIUtil.set_active(self._trans_history, show_history)
  end
  if not_null(self._trans_suggested) then
    UIUtil.set_active(self._trans_suggested, show_suggestion)
  end
  if show_history or show_suggestion then
    self._outside_click_enable_frame = Time.frameCount + 1
  end
  if self._on_view_state_callback then
    self._on_view_state_callback(show_history or show_suggestion)
  end
end

function M:_refresh_input_state(state)
  if not_null(self._state_group_input) then
    self._state_group_input:SetState(state)
  end
  if not_null(self._btn_clear) then
    UIUtil.set_active(self._btn_clear, state == input_state.has_text)
  end
end

function M:_update_outside_click()
  if self._is_outside_click_enabled == false then
    return
  end
  self:_handle_pending_outside_click()
  self:_refresh_option_select_suppression()
  if not self._is_search_field_open and not self:_has_floating_panel_showing() then
    return
  end
  if Time.frameCount <= self._outside_click_enable_frame then
    return
  end
  if self._pending_outside_click_frame > 0 then
    return
  end
  local screen_position = get_pointer_down_position()
  if screen_position == nil then
    return
  end
  if self:_is_position_in_protected_area(screen_position) then
    self._is_suppressing_option_select = false
    return
  end
  self._is_suppressing_option_select = true
  self._pending_outside_click_frame = Time.frameCount
end

function M:_handle_pending_outside_click()
  if self._pending_outside_click_frame <= 0 then
    return
  end
  if is_pointer_pressed() then
    return
  end
  self._pending_outside_click_frame = 0
  self._outside_click_release_suppress_frame = Time.frameCount + 1
  self:_handle_outside_click()
end

function M:_refresh_option_select_suppression()
  if self._pending_outside_click_frame > 0 then
    return
  end
  if Time.frameCount <= self._outside_click_release_suppress_frame then
    return
  end
  if not is_pointer_pressed() then
    self._is_suppressing_option_select = false
  end
end

function M:_should_ignore_option_select()
  if self._is_suppressing_option_select == true then
    return true
  end
  if Time.frameCount <= self._outside_click_release_suppress_frame then
    return true
  end
  local screen_position = get_current_pointer_position()
  if screen_position == nil then
    return false
  end
  return not self:_is_position_in_floating_panel_area(screen_position)
end

function M:_is_position_in_floating_panel_area(screen_position)
  return is_screen_position_in_transform(screen_position, self._trans_history) or is_screen_position_in_transform(screen_position, self._trans_suggested)
end

function M:_has_floating_panel_showing()
  return is_transform_active(self._trans_history) or is_transform_active(self._trans_suggested)
end

function M:_is_position_in_protected_area(screen_position)
  local protected_transforms = self._outside_click_protected_transforms or self:_get_default_protected_transforms()
  for _, protected_trans in ipairs(protected_transforms) do
    if is_screen_position_in_transform(screen_position, protected_trans) then
      return true
    end
  end
  return false
end

function M:_get_default_protected_transforms()
  local protected_transforms = {}
  append_protected_transform(protected_transforms, self._trans_search_field)
  append_protected_transform(protected_transforms, self._input_search)
  append_protected_transform(protected_transforms, self._btn_clear)
  append_protected_transform(protected_transforms, self._btn_search)
  append_protected_transform(protected_transforms, self._trans_history)
  append_protected_transform(protected_transforms, self._trans_suggested)
  return protected_transforms
end

function M:_handle_outside_click()
  if self._outside_click_callback then
    self._outside_click_callback(self)
    return
  end
  self:dismiss_panels()
end

function M:_remove_direct_listeners()
  if not_null(self._input_search) then
    if self._input_submit_listener ~= nil then
      self._input_search.onSubmit:RemoveListener(self._input_submit_listener)
    end
    if self._input_deselect_listener ~= nil then
      self._input_search.onDeselect:RemoveListener(self._input_deselect_listener)
    end
  end
  self._input_submit_listener = nil
  self._input_deselect_listener = nil
  if self._direct_listeners then
    table.clear(self._direct_listeners)
  end
end

return M
