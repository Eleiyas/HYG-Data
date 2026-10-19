local M = G.Class("LittleCornerPostSearchOrFilterPanel", G.UIPanel)
local base = G.UIPanel
local search_filter_mode = little_corner_module.search_filter_mode
local history_item_cls = "UI/LittleCorner/LittleCornerPostSearchHistoryItem"

function M:init()
  base.init(self)
  self._btn_search = nil
  self._btn_filter_tag = nil
  self._input_field_search = nil
  self._input_search_history_list = nil
  self._btn_del_search = nil
  self._btn_search_submit = nil
  self._txt_tag_filter_result = nil
  self._btn_close_tag_filter = nil
  self._rect_search_group = nil
  self._rect_filter_group = nil
  self._rect_input_history_group = nil
  self._mode = search_filter_mode.none
  self._callbacks = nil
  self._filter_tag_id_list = {}
  self._history_items = {}
  self._is_input_focused = false
  self._pre_deselect_text = nil
  self._deselect_timer = nil
  self._full_history_list = {}
  self._committed_keyword = ""
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  UIUtil.set_active(self._rect_input_history_group, false)
  UIUtil.set_active(self._btn_del_search, false)
  local cfg = ExcelDataUtil.get_value(typeof(BXhsConstantCfg), 1)
  if cfg then
    self._input_field_search.maxCharacters = cfg.searchkeywordcharslimit
  end
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  self:_cancel_deselect_timer()
  self._is_input_focused = false
  self._full_history_list = {}
  self._committed_keyword = ""
  self:_set_mode(search_filter_mode.none)
  self._filter_tag_id_list = {}
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:set_callbacks(cfg)
  self._callbacks = cfg
end

function M:restore_state(keyword, tag_id_list)
  keyword = keyword or ""
  tag_id_list = tag_id_list or {}
  self._committed_keyword = keyword
  self._filter_tag_id_list = tag_id_list
  if 0 < #tag_id_list then
    self._input_field_search.text = ""
    self:_set_mode(search_filter_mode.filter)
    self:_refresh_tag_filter_result()
  elseif keyword ~= "" then
    self._input_field_search.text = keyword
    self:_set_mode(search_filter_mode.search)
  else
    self._input_field_search.text = ""
    self:_set_mode(search_filter_mode.none)
  end
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_search, pack(self, M._on_btn_search))
  self:bind_callback(self._btn_filter_tag, pack(self, M._on_btn_filter_tag))
  self:bind_callback(self._btn_del_search, pack(self, M._on_btn_del_search))
  self:bind_callback(self._btn_search_submit, pack(self, M._on_btn_search_submit))
  self:bind_callback(self._btn_close_tag_filter, pack(self, M._on_btn_close_tag_filter))
  self._input_field_search.onSelect:AddListener(pack(self, M._on_input_field_select))
  self._input_field_search.onDeselect:AddListener(pack(self, M._on_input_field_deselect))
  self._input_field_search.onValueChanged:AddListener(pack(self, M._on_input_value_changed))
  self._input_field_search.onSubmit:AddListener(pack(self, M._on_btn_search_submit))
end

function M:_on_btn_search()
  if self._mode == search_filter_mode.search then
    self:_set_mode(search_filter_mode.none)
    return
  end
  if little_corner_module:try_block_search_with_tip() then
    return
  end
  local had_filter = #self._filter_tag_id_list > 0
  self._filter_tag_id_list = {}
  self:_set_mode(search_filter_mode.search)
  self._input_field_search:ActivateInputField()
  if had_filter then
    self:_notify_clear()
  end
end

function M:_on_btn_filter_tag()
  if little_corner_module:try_block_search_with_tip() then
    return
  end
  local extra_data = {
    on_confirm = function(tag_list)
      self:_on_tag_filter_confirmed(tag_list)
    end,
    max_tag_count = little_corner_module.max_choose_tag_count,
    default_tags = self._filter_tag_id_list
  }
  UIManagerInstance:open("UI/LittleCorner/LittleCornerTagChooseDialog", extra_data)
end

function M:_on_tag_filter_confirmed(tag_list)
  tag_list = tag_list or {}
  self._filter_tag_id_list = tag_list
  self._input_field_search.text = ""
  if 0 < #tag_list then
    self:_set_mode(search_filter_mode.filter)
    self:_refresh_tag_filter_result()
    self:_notify_filter_submit(tag_list)
  else
    self:_set_mode(search_filter_mode.none)
    self:_notify_clear()
  end
end

function M:_on_btn_del_search()
  self:_cancel_deselect_timer()
  self._input_field_search.text = ""
  self._input_field_search:ActivateInputField()
end

function M:_on_btn_search_submit()
  self:_cancel_deselect_timer()
  if little_corner_module:try_block_search_with_tip() then
    self:_hide_search_history()
    return
  end
  local raw = self._pre_deselect_text or self._input_field_search.text or ""
  self._pre_deselect_text = nil
  local keyword = string.match(raw, "^%s*(.-)%s*$") or ""
  self:_hide_search_history()
  if keyword == "" then
    self:_set_mode(search_filter_mode.none)
    self:_notify_clear()
    return
  end
  self:_add_search_history(keyword)
  self:_notify_search_submit(keyword)
end

function M:_on_btn_close_tag_filter()
  self._filter_tag_id_list = {}
  self:_set_mode(search_filter_mode.none)
  self:_notify_clear()
end

function M:_on_input_field_select()
  self:_cancel_deselect_timer()
  self._is_input_focused = true
  if not self._rect_input_history_group.gameObject.activeSelf then
    self:_show_search_history()
  end
end

function M:_on_input_field_deselect()
  self._is_input_focused = false
  self._pre_deselect_text = self._input_field_search.text
  if self:_is_pointer_in_history_rect() then
    self._input_field_search:ActivateInputField()
    return
  end
  self:_schedule_deselect_hide()
end

function M:_on_input_value_changed(text)
  local has_text = text and text ~= ""
  UIUtil.set_active(self._btn_del_search, has_text)
  if self._is_input_focused and self._full_history_list and #self._full_history_list > 0 then
    self:_rebuild_history_display(text)
  end
end

function M:_set_mode(new_mode)
  self._mode = new_mode
  self:_refresh_mode_ui()
end

function M:_refresh_mode_ui()
  local is_search = self._mode == search_filter_mode.search
  local is_filter = self._mode == search_filter_mode.filter
  local is_none = not is_search and not is_filter
  UIUtil.set_active(self._rect_search_group, is_search)
  UIUtil.set_active(self._rect_filter_group, is_filter)
  UIUtil.set_active(self._btn_search, is_none)
  UIUtil.set_active(self._btn_filter_tag, is_none)
  if is_search then
    local has_text = (self._input_field_search.text or "") ~= ""
    UIUtil.set_active(self._btn_del_search, has_text)
  end
  if not is_search then
    self:_hide_search_history()
  end
end

function M:_refresh_tag_filter_result()
  if not self._filter_tag_id_list or #self._filter_tag_id_list == 0 then
    UIUtil.set_text(self._txt_tag_filter_result, "")
    return
  end
  local names = {}
  for _, tag_id in ipairs(self._filter_tag_id_list) do
    local name = little_corner_module:get_tag_name(tag_id)
    if name and name ~= "" then
      table.insert(names, name)
    end
  end
  UIUtil.set_text(self._txt_tag_filter_result, table.concat(names, "/"))
end

function M:_load_search_history()
  local sep = little_corner_module.search_history_separator
  local raw = CsLocalSaveDataUtil.GetString(LocalSaveID.LittleCornerPostSearchTxtHistory, "")
  if not raw or raw == "" then
    return {}
  end
  local list = {}
  for item in string.gmatch(raw, "([^" .. sep .. "]+)") do
    if item ~= "" then
      table.insert(list, item)
    end
  end
  return list
end

function M:_save_search_history(list)
  local str = table.concat(list, little_corner_module.search_history_separator)
  CsLocalSaveDataUtil.SetString(LocalSaveID.LittleCornerPostSearchTxtHistory, str)
end

function M:_add_search_history(keyword)
  if not keyword or keyword == "" then
    return
  end
  local list = self:_load_search_history()
  for i = #list, 1, -1 do
    if list[i] == keyword then
      table.remove(list, i)
    end
  end
  table.insert(list, 1, keyword)
  while #list > little_corner_module.max_search_history_count do
    table.remove(list, #list)
  end
  self:_save_search_history(list)
end

function M:_show_search_history()
  self._full_history_list = self:_load_search_history()
  self:_create_history_items()
  local current_text = self._input_field_search.text or ""
  self:_rebuild_history_display(current_text)
end

function M:_create_history_items()
  self:_clear_history_items()
  local list = self._full_history_list
  if not list or #list == 0 then
    return
  end
  for _, keyword in ipairs(list) do
    local obj = self._input_search_history_list:AddItem(0)
    if not_null(obj) then
      UIUtil.set_active(obj, true)
      local item = self:add_panel(history_item_cls, obj, {
        keyword = keyword,
        is_last = false,
        on_click = function(kw)
          self:_on_history_item_clicked(kw)
        end
      })
      table.insert(self._history_items, {
        panel = item,
        go = obj,
        keyword = keyword
      })
    end
  end
end

function M:_rebuild_history_display(filter_text)
  if not self._history_items or #self._history_items == 0 then
    UIUtil.set_active(self._rect_input_history_group, false)
    return
  end
  local use_filter = filter_text and filter_text ~= ""
  local lower_input = use_filter and string.lower(filter_text) or nil
  local last_visible_idx = 0
  for i, entry in ipairs(self._history_items) do
    local visible = not use_filter or string.find(string.lower(entry.keyword), lower_input, 1, true) ~= nil
    UIUtil.set_active(entry.go, visible)
    if visible then
      last_visible_idx = i
    end
  end
  if last_visible_idx == 0 then
    UIUtil.set_active(self._rect_input_history_group, false)
    return
  end
  for i, entry in ipairs(self._history_items) do
    local data = entry.panel:get_extra_data()
    if data then
      local new_is_last = i == last_visible_idx
      if data.is_last ~= new_is_last then
        data.is_last = new_is_last
        entry.panel:force_refresh()
      end
    end
  end
  UIUtil.set_active(self._rect_input_history_group, true)
end

function M:_hide_search_history()
  self:_cancel_deselect_timer()
  UIUtil.set_active(self._rect_input_history_group, false)
  self:_clear_history_items()
end

function M:_on_history_item_clicked(keyword)
  self:_cancel_deselect_timer()
  self._input_field_search.text = keyword
  self:_hide_search_history()
  self:_add_search_history(keyword)
  self:_notify_search_submit(keyword)
end

function M:_is_pointer_in_history_rect()
  if not self._rect_input_history_group or not self._rect_input_history_group.gameObject.activeInHierarchy then
    return false
  end
  local mouse_pos = Input.mousePosition
  local screen_point = Vector2(mouse_pos.x, mouse_pos.y)
  return RectTransformUtility.RectangleContainsScreenPoint(self._rect_input_history_group, screen_point, UIManagerInstance.ui_camera)
end

function M:_schedule_deselect_hide()
  self:_cancel_deselect_timer()
  self._deselect_timer = CsTimerManagerUtil.StartTimer(0.15, function()
    self._deselect_timer = nil
    self:_process_deselect()
  end)
end

function M:_process_deselect()
  if self._is_input_focused then
    return
  end
  self._pre_deselect_text = nil
  self:_hide_search_history()
  if self._committed_keyword and self._committed_keyword ~= "" then
    self._input_field_search.text = self._committed_keyword
  else
    self._input_field_search.text = ""
    self:_set_mode(search_filter_mode.none)
  end
end

function M:_cancel_deselect_timer()
  if self._deselect_timer then
    CsTimerManagerUtil.StopTimer(self._deselect_timer)
    self._deselect_timer = nil
  end
end

function M:_clear_history_items()
  if #self._history_items > 0 then
    for _, entry in ipairs(self._history_items) do
      self:remove_panel(entry.panel)
      UIUtil.destroy_go(entry.go)
    end
    self._history_items = {}
  end
end

function M:_notify_search_submit(keyword)
  self._committed_keyword = keyword
  if self._callbacks and self._callbacks.on_search_submit then
    self._callbacks.on_search_submit(keyword)
  end
end

function M:_notify_filter_submit(tag_id_list)
  self._committed_keyword = ""
  if self._callbacks and self._callbacks.on_filter_submit then
    self._callbacks.on_filter_submit(tag_id_list)
  end
end

function M:_notify_clear()
  self._committed_keyword = ""
  if self._callbacks and self._callbacks.on_clear then
    self._callbacks.on_clear()
  end
end

return M
