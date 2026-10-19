local M = G.Class("HairDyeingFlowerBagPanel", "UI/LitePacketView/LiteCommonBagPanel")
local base = G.LiteCommonBagPanel
local flower_bag_title_text_id = "HairDyeing_Flower_SelectCount"
local FILTER_ALL_LABEL_TEXT_ID = "Common_All"
local FILTER_COLOR_LABEL_TEXT_ID = "Bag_Tag_Title_Color"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/LitePacketView/LiteCommonBagPanel"
  self._filter_tags = nil
  self._filter_ranks = nil
  self._selected_guid_by_item_id = {}
  self._display_guid_by_item_id = {}
  self._display_item_id_order = {}
end

function M:on_create()
  base.on_create(self)
end

function M:refresh_ui(tog_sort_type)
  base.refresh_ui(self, tog_sort_type)
  self:refresh_title()
  self._ui_state_group_filter:SetState(1)
  self:_refresh_filter_text()
end

function M:tog_change()
  base.tog_change(self)
  self:refresh_title()
end

function M:refresh_title()
  if not is_null(self._txt_title) then
    local selected_count = 0
    if self.holder and self.holder.get_selected_flower_count then
      selected_count = self.holder:get_selected_flower_count()
    end
    UIUtil.set_text_by_id(self._txt_title, flower_bag_title_text_id, selected_count)
  end
end

function M:_bind_selected_guid(item_id, guid, item)
  self._selected_guid_by_item_id = self._selected_guid_by_item_id or {}
  self._selected_guid_by_item_id[item_id] = guid
  local select_num = self.holder:get_fixed_select_num(item)
  if self._tbl_cur_multi_stack[guid] ~= select_num then
    self._tbl_cur_multi_stack[guid] = select_num
    back_bag_module:reset_select_stack(item, select_num)
  end
  return guid
end

function M:_get_selected_guid(item_id, preferred_guid)
  self._selected_guid_by_item_id = self._selected_guid_by_item_id or {}
  local selected_guid = self._selected_guid_by_item_id[item_id]
  local display_guid = self._display_guid_by_item_id and self._display_guid_by_item_id[item_id]
  if display_guid ~= nil and selected_guid ~= display_guid then
    local display_item = self:get_item_by_guid(display_guid)
    if not is_null(display_item) and display_item.ConfigId == item_id then
      if selected_guid ~= nil then
        self._tbl_cur_multi_stack[selected_guid] = nil
        back_bag_module:set_select_stack(selected_guid, nil)
      end
      return self:_bind_selected_guid(item_id, display_guid, display_item)
    end
  end
  if selected_guid ~= nil then
    local selected_item = self:get_item_by_guid(selected_guid)
    if not is_null(selected_item) and selected_item.ConfigId == item_id then
      return self:_bind_selected_guid(item_id, selected_guid, selected_item)
    end
    self._selected_guid_by_item_id[item_id] = nil
  end
  for guid, num in pairs(self._tbl_cur_multi_stack or {}) do
    if 0 < num then
      local item = self:get_item_by_guid(guid)
      if not is_null(item) and item.ConfigId == item_id then
        return self:_bind_selected_guid(item_id, guid, item)
      end
    end
  end
  local preferred_item = self:get_item_by_guid(preferred_guid)
  if not is_null(preferred_item) and preferred_item.ConfigId == item_id then
    return self:_bind_selected_guid(item_id, preferred_guid, preferred_item)
  end
  return nil
end

function M:get_item_select_state_by_guid(guid)
  self._selected_guid_by_item_id = self._selected_guid_by_item_id or {}
  local item = self:get_item_by_guid(guid)
  if not is_null(item) and self.holder and self.holder.is_flower_selected then
    if not self.holder:is_flower_selected(item.ConfigId) then
      self._selected_guid_by_item_id[item.ConfigId] = nil
      return false
    end
    return self:_get_selected_guid(item.ConfigId, guid) == guid
  end
  return base.get_item_select_state_by_guid(self, guid)
end

function M:get_item_select_num_by_guid(guid)
  local item = self:get_item_by_guid(guid)
  if not is_null(item) and self.holder and self.holder.is_flower_selected then
    if self:get_item_select_state_by_guid(guid) then
      return self.holder:get_fixed_select_num(item)
    end
    return 0
  end
  return base.get_item_select_num_by_guid(self, guid)
end

function M:should_auto_click_selected_item_after_bag_change()
  return false
end

function M:get_fixed_select_item_num(server_data)
  return back_bag_module:get_item_num(server_data.ConfigId, false)
end

function M:should_handle_fixed_num_select(by_click, is_force_refresh)
  return by_click == true or is_force_refresh == true
end

function M:refresh_data(bag_show_type)
  self._display_item_id_order = {}
  base.refresh_data(self, bag_show_type)
end

function M:refresh_cur_show_data()
  local focused_item_id
  local focused_data = self._lst_cur_show_data and self._lst_cur_show_data[self._select_item_index]
  if focused_data then
    local focused_item = focused_data.server_data or self:get_item_by_guid(focused_data.guid)
    focused_item_id = not is_null(focused_item) and focused_item.ConfigId or nil
  end
  if self._tbl_all_show_data and self.cur_tog_type then
    self._tbl_all_show_data[self.cur_tog_type] = nil
  end
  if self._tbl_item_data_guid_and_index and self.cur_tog_type then
    self._tbl_item_data_guid_and_index[self.cur_tog_type] = nil
  end
  base.refresh_cur_show_data(self)
  if focused_item_id ~= nil then
    self._select_item_index = 0
    for index, item_data in ipairs(self._lst_cur_show_data or {}) do
      local item = self:get_item_by_guid(item_data.guid)
      if not is_null(item) and item.ConfigId == focused_item_id then
        self._select_item_index = index
        break
      end
    end
  end
end

function M:_init_item_extra_data(item_data, index)
  base._init_item_extra_data(self, item_data, index)
  if not is_null(item_data.server_data) then
    item_data.show_count = back_bag_module:get_item_num(item_data.server_data.ConfigId, false)
  end
end

function M:set_filter_tags(tags)
  self._filter_tags = tags and 0 < #tags and tags or nil
  if self._tbl_all_show_data and self.cur_tog_type then
    self._tbl_all_show_data[self.cur_tog_type] = nil
  end
  if self._tbl_item_data_guid_and_index and self.cur_tog_type then
    self._tbl_item_data_guid_and_index[self.cur_tog_type] = nil
  end
  self._is_reload_grid_scroller = true
  self:set_select_item_index(0)
  self:refresh_cur_show_data()
  self:refresh_bag()
  self:_refresh_filter_text()
end

function M:get_filter_tags()
  return self._filter_tags
end

function M:_get_filter_txt()
  if not is_null(self._txt_filter) then
    return self._txt_filter
  end
end

function M:_refresh_filter_text()
  local txt = self:_get_filter_txt()
  if is_null(txt) then
    return
  end
  local selected_labels = {}
  local tag_set = {}
  for _, tag in ipairs(self._filter_tags or {}) do
    tag_set[tag] = true
  end
  if next(tag_set) ~= nil then
    for _, sys in ipairs(hair_dyeing_module:get_flower_color_systems() or {}) do
      if tag_set[sys.tag] and string.is_valid(sys.label) then
        table.insert(selected_labels, sys.label)
      end
    end
  end
  local filter_text = 0 < #selected_labels and table.concat(selected_labels, "、") or UIUtil.get_text_by_id(FILTER_ALL_LABEL_TEXT_ID)
  UIUtil.set_text(txt, string.format("%s：%s", UIUtil.get_text_by_id(FILTER_COLOR_LABEL_TEXT_ID), filter_text))
end

function M:set_filter_ranks(ranks)
  self._filter_ranks = ranks and 0 < #ranks and ranks or nil
  if self._tbl_all_show_data and self.cur_tog_type then
    self._tbl_all_show_data[self.cur_tog_type] = nil
  end
  if self._tbl_item_data_guid_and_index and self.cur_tog_type then
    self._tbl_item_data_guid_and_index[self.cur_tog_type] = nil
  end
  self._is_reload_grid_scroller = true
  self:set_select_item_index(0)
  self:refresh_cur_show_data()
  self:refresh_bag()
end

function M:get_filter_ranks()
  return self._filter_ranks
end

function M:get_item_guids(select_index)
  local all_guids = base.get_item_guids(self, select_index)
  local has_tag_filter = self._filter_tags ~= nil and #self._filter_tags > 0
  local has_rank_filter = self._filter_ranks ~= nil and 0 < #self._filter_ranks
  local tag_set = {}
  for _, tag in ipairs(self._filter_tags or {}) do
    tag_set[tag] = true
  end
  local rank_set = {}
  for _, rank in ipairs(self._filter_ranks or {}) do
    rank_set[rank] = true
  end
  local item_id_order = {}
  local first_guid_by_item_id = {}
  local available_guids = {}
  for _, guid in ipairs(all_guids) do
    local item = self:get_item_by_guid(guid)
    if not is_null(item) then
      local match_tag = not has_tag_filter
      if has_tag_filter then
        for _, color_tag in ipairs(hair_dyeing_module:get_flower_color_tags_by_item_id(item.ConfigId)) do
          if tag_set[color_tag] then
            match_tag = true
            break
          end
        end
      end
      local match_rank = not has_rank_filter
      if has_rank_filter then
        local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), item.ConfigId)
        match_rank = item_cfg and rank_set[item_cfg.rank] == true
      end
      if match_tag and match_rank then
        available_guids[guid] = true
        if first_guid_by_item_id[item.ConfigId] == nil then
          first_guid_by_item_id[item.ConfigId] = guid
          table.insert(item_id_order, item.ConfigId)
        end
      end
    end
  end
  self._display_item_id_order = self._display_item_id_order or {}
  local keep_display_order = #self._display_item_id_order == #item_id_order
  if keep_display_order then
    for _, item_id in ipairs(self._display_item_id_order) do
      if first_guid_by_item_id[item_id] == nil then
        keep_display_order = false
        break
      end
    end
  end
  if keep_display_order then
    item_id_order = self._display_item_id_order
  else
    self._display_item_id_order = item_id_order
  end
  self._display_guid_by_item_id = self._display_guid_by_item_id or {}
  local filtered = {}
  for _, item_id in ipairs(item_id_order) do
    local guid = self._selected_guid_by_item_id[item_id] or self._display_guid_by_item_id[item_id]
    if guid == nil or not available_guids[guid] then
      guid = first_guid_by_item_id[item_id]
    end
    self._display_guid_by_item_id[item_id] = guid
    table.insert(filtered, guid)
  end
  return filtered
end

return M
