local M = G.Class("MiTaiRatingScoreMainPage", G.UIWindow)
local base = G.UIWindow
local Stage = {
  NONE = 0,
  SETTLEMENT_PROCESS = 1,
  SUGGESTION = 2,
  SUMMARY = 3
}
local STAGE_PANEL_CLASS = {
  [Stage.SETTLEMENT_PROCESS] = "UI/MiTaiScore/MiTaiSettlementProcessPanel",
  [Stage.SUGGESTION] = "UI/MiTaiScore/MiTaiSuggestionPanel",
  [Stage.SUMMARY] = "UI/MiTaiScore/MiTaiSummaryPanel"
}
local room_item_cls = "UI/MiTaiScore/MiTaiRatingScoreRoomItem"
local room_focus_base_position = Vector2(0, 1)
local room_list_move_smooth_speed = 12
local room_reference_size = 10
local room_reference_item_width = 750
local summary_scroll_left = 570
local suggestion_scroll_left = 870

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MiTaiScore/MiTaiRatingScoreMainPage"
  self.config.type = EUIType.Page
  self._current_stage = Stage.NONE
  self._current_panel = nil
  self._stage_panels = {}
  self._room_list = nil
  self._room_items = {}
  self._selected_room_index = 1
  self._summary_data = nil
  self._is_close = false
  self._room_list_target_pos = nil
  self._room_item_widths = {}
  self._room_item_center_xs = {}
end

function M:on_create()
  base.on_create(self)
  self:_build_room_items()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  self:_start_flow()
end

function M:on_disable()
  self._room_list_target_pos = nil
  if not is_null(self._scroll_room) then
    self._scroll_room.enabled = true
    self._scroll_room:StopMovement()
  end
  base.on_disable(self)
end

function M:update(delta_time)
  base.update(self, delta_time)
  if self._room_list_target_pos ~= nil and not is_null(self._trans_room_content) then
    local cur = self._trans_room_content.anchoredPosition
    local t = math.min(delta_time * room_list_move_smooth_speed, 1)
    local next_pos = Vector2.Lerp(cur, self._room_list_target_pos, t)
    self._trans_room_content.anchoredPosition = next_pos
    if Vector2.Distance(next_pos, self._room_list_target_pos) < 0.5 then
      self._trans_room_content.anchoredPosition = self._room_list_target_pos
      self._room_list_target_pos = nil
      self._scroll_room.enabled = true
    end
  end
end

function M:on_close()
  self:_reset_flow()
  EventCenter.Broadcast(EventID.Performance.OnMiTaiEvaluateResultPageEnd, 0)
  base.on_close(self)
end

function M:on_destroy()
  mi_tai_score_module:release_rating_score_room_textures(self._room_list)
  self._room_list = nil
  self._summary_data = nil
  base.on_destroy(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_fun(ActionType.Act.Back, M._on_back)
end

function M:_start_flow()
  if self._current_stage ~= Stage.NONE then
    return
  end
  local extra_data = self:get_extra_data() or {}
  self:_init_flow_data(extra_data)
  if #self._room_list == 0 then
    Logger.LogError("[MiTaiRatingScoreMainPage] 没有可展示的房间截图")
    self:_close_self_once()
    return
  end
  self:_refresh_room_items()
  if #self._room_list == 1 then
    self:_start_single_room_flow(extra_data)
    return
  end
  self:_start_multi_room_flow(extra_data)
end

function M:_init_flow_data(extra_data)
  self._room_list = extra_data.room_list or {}
  self._selected_room_index = 1
  self:_reset_room_list_position()
  self._summary_data = {
    room_list = self._room_list,
    total_score = extra_data.total_score or 0,
    evaluate_data = extra_data.evaluate_data or {},
    selected_index = 1
  }
end

function M:_reset_room_list_position()
  self._room_list_target_pos = nil
  if is_null(self._scroll_room) then
    return
  end
  self._scroll_room.enabled = true
  self._scroll_room:StopMovement()
  self._scroll_room.normalizedPosition = room_focus_base_position
end

function M:_start_single_room_flow(extra_data)
  local room_data = self._room_list[1]
  self:_set_single_room_mode()
  self._summary_data.total_evaluation = string.format("%s%s%s", extra_data.total_evaluation or "", room_data.highest_evaluation, room_data.lowest_evaluation)
  self:_goto_stage(Stage.SUMMARY, self._summary_data)
end

function M:_start_multi_room_flow(extra_data)
  self:_set_multi_room_mode()
  self._summary_data.total_evaluation = extra_data.total_evaluation or ""
  local highest_room, lowest_room = self:_find_process_rooms()
  self:_goto_stage(Stage.SETTLEMENT_PROCESS, {
    rooms = {
      self:_build_process_room(highest_room, true),
      self:_build_process_room(lowest_room, false)
    },
    room_list = self._room_list,
    total_score = self._summary_data.total_score,
    total_evaluation = self._summary_data.total_evaluation
  })
end

function M:_set_multi_room_mode()
  self._scroll_room.horizontal = true
  for index, item in ipairs(self._room_items) do
    if self._room_list[index] then
      item:set_interactable(true)
    end
  end
end

function M:_find_process_rooms()
  local highest_room = self._room_list[1]
  local lowest_room = self._room_list[1]
  for index = 2, #self._room_list do
    local room_data = self._room_list[index]
    if room_data.score > highest_room.score then
      highest_room = room_data
    end
    if room_data.score < lowest_room.score then
      lowest_room = room_data
    end
  end
  if lowest_room.region_id == highest_room.region_id then
    lowest_room = self._room_list[2]
  end
  return highest_room, lowest_room
end

function M:_set_single_room_mode()
  self._scroll_room.horizontal = false
  self:_reset_room_list_position()
  local item = self._room_items[1]
  if item then
    item:set_interactable(false)
    item:set_selected(false, false)
  end
end

function M:_build_process_room(room_data, is_highest)
  return {
    region_id = room_data.region_id,
    texture = room_data.texture,
    room_name = room_data.room_name,
    score = room_data.score,
    evaluation = is_highest and room_data.highest_evaluation or room_data.lowest_evaluation,
    is_highest = is_highest
  }
end

function M:_goto_stage(stage, extra_data)
  if is_null(self._trans_panel_parent) then
    Logger.LogError("[MiTaiRatingScoreMainPage] _trans_panel_parent 未绑定，无法挂载子界面")
    return
  end
  local panel_class = STAGE_PANEL_CLASS[stage]
  if panel_class == nil then
    Logger.LogError("[MiTaiRatingScoreMainPage] 未配置子界面阶段: " .. tostring(stage))
    return
  end
  self._current_stage = stage
  if not is_null(self._ui_state_group_bg) then
    self._ui_state_group_bg:SetState(stage == Stage.SUGGESTION and 1 or 2)
  end
  self:_set_room_list_visible(stage ~= Stage.SETTLEMENT_PROCESS)
  if stage ~= Stage.SETTLEMENT_PROCESS then
    self:_apply_room_list_stage_layout(stage)
  end
  self:_refresh_room_selection()
  local target_panel = self._stage_panels[stage]
  if target_panel ~= nil then
    target_panel:set_extra_data(extra_data)
    if stage == Stage.SETTLEMENT_PROCESS and target_panel.start_flow then
      target_panel:start_flow(extra_data)
    end
    self._current_panel = target_panel
    target_panel:change_state(EUIState.Show)
    self:_hide_other_stage_panels(target_panel)
    return
  end
  target_panel = self:add_panel_async(panel_class, extra_data, self._trans_panel_parent, function(panel)
    if panel ~= self._current_panel then
      panel:change_state(EUIState.Open)
      return
    end
    panel:change_state(EUIState.Show)
    self:_hide_other_stage_panels(panel)
  end)
  self._stage_panels[stage] = target_panel
  self._current_panel = target_panel
end

function M:on_settlement_process_complete(summary_data)
  summary_data = summary_data or {}
  self._summary_data.total_score = summary_data.total_score or self._summary_data.total_score
  self._summary_data.total_evaluation = summary_data.total_evaluation or self._summary_data.total_evaluation
  self._summary_data.room_list = self._room_list
  self._summary_data.selected_index = self._selected_room_index
  self:_goto_stage(Stage.SUMMARY, self._summary_data)
end

function M:focus_room(index)
  if index < 1 or index > #self._room_list then
    return
  end
  self._selected_room_index = index
  if self._summary_data then
    self._summary_data.selected_index = index
  end
  self:_scroll_to_room(index)
  self:_refresh_room_selection()
  if self._current_panel and self._current_panel.select_room then
    self._current_panel:select_room(index)
  end
end

function M:_on_room_item_click(index)
  if #self._room_list <= 1 then
    return
  end
  if self._current_stage == Stage.SUMMARY then
    self:show_suggestion({selected_index = index})
    return
  end
  self:focus_room(index)
end

function M:show_suggestion(suggestion_data)
  suggestion_data = suggestion_data or {}
  suggestion_data.rooms = self._room_list
  local selected_index = suggestion_data.selected_index or self._selected_room_index
  selected_index = math.max(1, math.min(selected_index, #self._room_list))
  self._selected_room_index = selected_index
  self._summary_data.selected_index = selected_index
  suggestion_data.selected_index = selected_index
  self:_goto_stage(Stage.SUGGESTION, suggestion_data)
  self:_scroll_to_room(selected_index)
  if self._current_panel and self._current_panel.select_room then
    self._current_panel:select_room(selected_index)
  end
end

function M:close_suggestion()
  self:_goto_stage(Stage.SUMMARY, self._summary_data)
end

function M:finish_flow()
  self:_close_self_once()
end

function M:_on_back()
  if self._current_stage == Stage.SETTLEMENT_PROCESS then
    self:on_settlement_process_complete(self._summary_data)
    return
  end
  if self._current_stage == Stage.SUGGESTION then
    self:close_suggestion()
    return
  end
  self:_close_self_once()
end

function M:_close_self_once()
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_self()
  EventCenter.Broadcast(EventID.LuaCloseBlank, nil)
end

function M:_reset_flow()
  self._current_panel = nil
  self._current_stage = Stage.NONE
end

function M:_set_room_list_visible(visible)
  if is_null(self._scroll_room) then
    return
  end
  self._scroll_room.gameObject:SetActive(visible)
end

function M:_apply_room_list_stage_layout(stage)
  if is_null(self._scroll_room) or is_null(self._trans_room_scroll) or is_null(self._layout_room_content) or is_null(self._trans_room_content) then
    return
  end
  local anchor_index = self._selected_room_index
  local anchor_center_x = self._room_item_center_xs[anchor_index]
  local anchor_world_pos
  if anchor_center_x ~= nil then
    anchor_world_pos = self._trans_room_content:TransformPoint(Vector3(anchor_center_x, 0, 0))
  end
  self._room_list_target_pos = nil
  self._scroll_room:StopMovement()
  self._scroll_room.enabled = false
  local offset_min = self._trans_room_scroll.offsetMin
  local is_single_room = #self._room_list <= 1
  offset_min.x = (is_single_room or stage == Stage.SUGGESTION) and suggestion_scroll_left or summary_scroll_left
  self._trans_room_scroll.offsetMin = offset_min
  Canvas.ForceUpdateCanvases()
  self:_rebuild_room_list_content_layout()
  if anchor_world_pos ~= nil then
    local new_anchor_center_x = self._room_item_center_xs[anchor_index]
    if new_anchor_center_x ~= nil then
      local new_anchor_world_pos = self._trans_room_content:TransformPoint(Vector3(new_anchor_center_x, 0, 0))
      local content_parent = self._trans_room_content.parent
      local old_anchor_parent_pos = content_parent:InverseTransformPoint(anchor_world_pos)
      local new_anchor_parent_pos = content_parent:InverseTransformPoint(new_anchor_world_pos)
      local anchored_pos = self._trans_room_content.anchoredPosition
      anchored_pos.x = anchored_pos.x + old_anchor_parent_pos.x - new_anchor_parent_pos.x
      self._trans_room_content.anchoredPosition = anchored_pos
    end
  end
  self._scroll_room.enabled = true
end

function M:_hide_other_stage_panels(target_panel)
  for _, panel in pairs(self._stage_panels) do
    if panel ~= target_panel then
      panel:change_state(EUIState.Hide)
    end
  end
end

function M:_build_room_items()
  if is_null(self._list_binder) then
    return
  end
  local template = self._list_binder:GetItem(0)
  if not is_null(template) then
    self._room_items[1] = self:add_panel(room_item_cls, template)
  end
end

function M:_refresh_room_items()
  if is_null(self._list_binder) then
    return
  end
  self._room_item_widths = {}
  self._room_item_center_xs = {}
  for index = #self._room_items + 1, #self._room_list do
    local trans = self._list_binder:AddItem(0, true)
    self._room_items[index] = self:add_panel(room_item_cls, trans)
  end
  for index, item in ipairs(self._room_items) do
    local room_data = self._room_list[index]
    item:set_active(room_data ~= nil)
    if room_data then
      local item_width = self:_get_room_item_width(room_data)
      self._room_item_widths[index] = item_width
      item:refresh(room_data, index, pack(self, M._on_room_item_click), item_width)
    else
      self._room_item_widths[index] = nil
      item:reset()
    end
  end
  self:_refresh_room_selection()
end

function M:_get_room_item_width(room_data)
  local room_width = room_data.room_width
  if room_width == nil or room_width <= 0 then
    room_width = room_reference_size
  end
  if room_width == room_reference_size then
    return 746
  end
  return math.min(room_reference_item_width * room_width / room_reference_size, room_reference_item_width)
end

function M:_refresh_room_selection()
  local show_selection = self._current_stage == Stage.SUGGESTION
  local show_score = self._current_stage == Stage.SUMMARY and #self._room_list > 1
  for index, item in ipairs(self._room_items) do
    item:set_score_state(show_score and 1 or 0)
    item:set_selected(show_selection and index == self._selected_room_index, show_selection)
  end
end

function M:_rebuild_room_list_content_layout()
  if is_null(self._scroll_room) or is_null(self._scroll_room.viewport) or is_null(self._layout_room_content) then
    return
  end
  local viewport_width = self._scroll_room.viewport.rect.width
  local focus_x = self:_get_room_focus_viewport_x(viewport_width)
  local first_width = self._room_item_widths[1] or 0
  local last_width = self._room_item_widths[#self._room_list] or 0
  local padding_left = 0
  local padding_right = 0
  if self._current_stage == Stage.SUGGESTION then
    padding_left = math.max(focus_x - first_width * 0.5, 0)
    padding_right = math.max(viewport_width - focus_x - last_width * 0.5, 0)
  end
  local padding = self._layout_room_content.padding
  padding.left = math.floor(padding_left + 0.5)
  padding.right = math.floor(padding_right + 0.5)
  self._layout_room_content.padding = padding
  local content_width = padding_left
  local spacing = self._layout_room_content.spacing
  for index, item_width in ipairs(self._room_item_widths) do
    if 1 < index then
      content_width = content_width + spacing
    end
    self._room_item_center_xs[index] = content_width + item_width * 0.5
    content_width = content_width + item_width
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(self._trans_room_content)
end

function M:_get_room_focus_viewport_x(viewport_width)
  local focus_x = viewport_width * 0.5
  if self._current_stage == Stage.SUGGESTION then
    focus_x = focus_x - (suggestion_scroll_left - summary_scroll_left) * 0.5
  end
  return focus_x
end

function M:_scroll_to_room(index)
  if #self._room_list <= 1 then
    return
  end
  if is_null(self._scroll_room) then
    return
  end
  local item_center_x = self._room_item_center_xs[index]
  if item_center_x == nil or is_null(self._scroll_room.viewport) then
    return
  end
  local viewport_w = self._scroll_room.viewport.rect.width
  local target_content_x = self:_get_room_focus_viewport_x(viewport_w) - item_center_x
  self._scroll_room:StopMovement()
  self._scroll_room.enabled = false
  self._room_list_target_pos = Vector2(target_content_x, self._trans_room_content.anchoredPosition.y)
end

return M
