local M = G.Class("AvatarInfoEditorFilterPanel", G.UIPanel)
local base = G.UIPanel
local choose_panel_cls = "UI/WorldEditor/WorldEditorFilter/WorldEditorChooseFilterPanel"
local search_panel_cls = "UI/WorldEditor/WorldEditorFilter/WorldEditorFilterSearchPanel"
local type_panel_cls = "UI/WorldEditor/WorldEditorFilter/WorldEditorFilterTypePanel"
local input_field_state = {select = 0, unselect = 1}
local filter_type = world_editor_module and world_editor_module.filter_type or {
  child_tag = 1,
  parent_tag = 2,
  place = 3,
  suit = 4
}
local filter_data_type = world_editor_module and world_editor_module.filter_data or {tag = 1, id = 2}

local function filter_special_chars(text)
  if not string.is_valid(text) then
    return text
  end
  local filtered = text
  filtered = string.gsub(filtered, "[%s!\"#$%%&'%(%)%*%+,%-%./:;<=>?@%[\\%]%^_`{|}~]", "")
  local chinese_punctuations = {
    "。",
    "，",
    "、",
    "；",
    "：",
    "？",
    "！",
    "“",
    "”",
    "‘",
    "’",
    "《",
    "》",
    "〈",
    "〉",
    "「",
    "」",
    "『",
    "』",
    "【",
    "】",
    "（",
    "）",
    "……",
    "—",
    "～",
    "·"
  }
  for _, punct in ipairs(chinese_punctuations) do
    filtered = string.gsub(filtered, punct, "")
  end
  local result = {}
  for _, codepoint in utf8.codes(filtered) do
    local is_emoji = false
    if 128512 <= codepoint and codepoint <= 128591 or 127744 <= codepoint and codepoint <= 128511 or 128640 <= codepoint and codepoint <= 128767 or 129280 <= codepoint and codepoint <= 129535 or 128896 <= codepoint and codepoint <= 129023 or 129024 <= codepoint and codepoint <= 129279 or 9728 <= codepoint and codepoint <= 9983 or 9984 <= codepoint and codepoint <= 10175 or 11008 <= codepoint and codepoint <= 11263 or 127232 <= codepoint and codepoint <= 127487 or 127462 <= codepoint and codepoint <= 127487 or 127995 <= codepoint and codepoint <= 127999 or codepoint == 8205 or codepoint == 65039 or 65024 <= codepoint and codepoint <= 65039 then
      is_emoji = true
    end
    if not is_emoji then
      table.insert(result, utf8.char(codepoint))
    end
  end
  return table.concat(result)
end

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/FurnitureEdit/FurnitureFilterPanel"
end

function M:on_create()
  base.on_create(self)
  self:bind_callbacks()
  self._choose_panel = self:add_panel(choose_panel_cls, self._trans_choose_panel)
  self._search_panel = self:add_panel(search_panel_cls, self._trans_search_panel)
  self._type_cls = {}
  self._show_entity_data = {}
  self._tag_to_icon = {}
end

function M:on_enable()
  base.on_enable(self)
  self._filter_data = self:init_filter_data()
  self:_refresh_group_data()
  self:_refresh_show_entity_data()
  if string.is_valid(self._input_search.text) then
    self:refresh_input_select_state(input_field_state.select)
  else
    self:refresh_input_select_state(input_field_state.unselect)
  end
  self._choose_panel:set_active(false)
  self._search_panel:set_active(false)
  self:_refresh_ui()
  self.trans:SetAsLastSibling()
  self._scroll_rect.verticalNormalizedPosition = 1
end

function M:init_filter_data()
  local filter_data = {}
  local tb = ExcelDataUtil.get_table(typeof(BItemFilterCfg)) or {}
  for group_id, lst in pairs(tb) do
    local datas = list_to_table(lst)
    local group_data
    if datas[1] ~= nil then
      if datas[1].filtertype == filter_type.child_tag or datas[1].filtertype == filter_type.parent_tag then
        group_data = self:init_tag_group(datas)
      elseif datas[1].filtertype == filter_type.place then
        group_data = self:init_place_group(datas)
      elseif datas[1].filtertype == filter_type.suit then
        group_data = self:init_suit_group(datas)
      end
    end
    filter_data[group_id] = group_data
  end
  return filter_data
end

function M:init_tag_group(datas)
  local group_data = {
    filter_data_type = filter_data_type.tag,
    group_name = datas[1].groupname,
    sub_group = {}
  }
  local sub_group_map = {}
  local sub_group_ids = {}
  for _, data in ipairs(datas) do
    local sub_group_id = data.subgroupid == 0 and 1 or data.subgroupid
    if sub_group_map[sub_group_id] == nil then
      sub_group_map[sub_group_id] = {
        sub_group_name = data.subgroupname,
        show_type = data.type ~= 0 and data.type or 1,
        tags = {}
      }
      table.insert(sub_group_ids, sub_group_id)
    end
    local tags = list_to_table(TagUtil.get_gameplay_tags_by_string(data.tag))
    for _, tag in ipairs(tags) do
      if data.filtertype == filter_type.parent_tag then
        local child_tags = list_to_table(TagUtil.get_child_tags_by_tag(tag))
        for _, child_tag in ipairs(child_tags) do
          table.insert(sub_group_map[sub_group_id].tags, {
            child_tag,
            data.index
          })
        end
      elseif data.filtertype == filter_type.child_tag then
        if data.type ~= 1 and string.is_valid(data.icon) then
          self._tag_to_icon[tag] = data.icon
        end
        table.insert(sub_group_map[sub_group_id].tags, {
          tag,
          data.index
        })
      end
    end
  end
  table.sort(sub_group_ids)
  for _, id in ipairs(sub_group_ids) do
    local sub = sub_group_map[id]
    table.sort(sub.tags, function(a, b)
      return a[2] < b[2]
    end)
    for i, entry in ipairs(sub.tags) do
      sub.tags[i] = entry[1]
    end
    table.insert(group_data.sub_group, sub)
  end
  return group_data
end

function M:init_place_group(datas)
  local group_data = {
    filter_data_type = filter_data_type.id,
    group_name = datas[1].groupname,
    sub_group = {}
  }
  for _, data in ipairs(datas) do
    local sub_group_id = tonumber(data.tag)
    if group_data.sub_group[sub_group_id] == nil then
      group_data.sub_group[sub_group_id] = {
        sub_group_name = data.name,
        show_type = data.type ~= 0 and data.type or 1,
        ids = {}
      }
    end
  end
  local entity_cfgs = ExcelDataUtil.get_table(typeof(BEntityCfg)) or {}
  for item_id, cfgs_dic in pairs(entity_cfgs) do
    local cfgs = dic_to_table(cfgs_dic)
    for _, cfg in pairs(cfgs) do
      if cfg.placecfgid ~= 0 and group_data.sub_group[cfg.placecfgid] ~= nil then
        table.insert(group_data.sub_group[cfg.placecfgid].ids, item_id)
      end
    end
  end
  return group_data
end

function M:init_suit_group(datas)
  local group_data = {
    filter_data_type = filter_data_type.id,
    group_name = datas[1].groupname,
    sub_group = {}
  }
  local id_cfgs = ExcelDataUtil.get_table(typeof(BIdCfg)) or {}
  for suit_id, cfg in pairs(id_cfgs) do
    if cfg.type == IdType.Suite and item_module:is_furniture_set(suit_id) then
      local suit_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), suit_id)
      if suit_cfg and group_data.sub_group[suit_id] == nil then
        group_data.sub_group[suit_id] = {
          sub_group_name = cfg.name,
          show_type = 3,
          sub_group_icon = suit_cfg.setpic,
          ids = {}
        }
      end
    end
  end
  local furniture_cfgs = ExcelDataUtil.get_table(typeof(BFurnitureCfg)) or {}
  for item_id, cfg in pairs(furniture_cfgs) do
    if cfg.packageid ~= 0 and group_data.sub_group[cfg.packageid] ~= nil then
      table.insert(group_data.sub_group[cfg.packageid].ids, item_id)
    end
  end
  return group_data
end

function M:_refresh_ui()
  for group_id, data in ipairs(self._group_datas) do
    if self._type_cls[group_id] == nil then
      local go = group_id == 1 and self._obj_type or UIUtil.load_prefab_set_parent(self._obj_type, self._trans_type_parent)
      local panel = self:add_panel(type_panel_cls, go)
      self._type_cls[group_id] = panel
    end
    self:bind_callback(self._type_cls[group_id]:get_btn_add(), function()
      self:on_start_choose_btn_click(group_id)
    end)
    local selected_info = {}
    if data.filter_data_type == filter_data_type.tag then
      if self._group_to_select_infos[group_id] ~= nil and self._group_to_select_infos[group_id].tags ~= nil then
        selected_info = self._group_to_select_infos[group_id].tags
      end
    elseif self._group_to_select_infos[group_id] ~= nil and self._group_to_select_infos[group_id].ids ~= nil then
      selected_info = self._group_to_select_infos[group_id].ids
    end
    if data.filter_data_type == filter_data_type.tag then
      self._type_cls[group_id]:refresh_tags(selected_info)
    else
      self._type_cls[group_id]:refresh_ids(selected_info)
    end
    self._type_cls[group_id]:refresh_ui(data.group_name, group_id)
    self._type_cls[group_id]:set_active(true)
  end
  for i = #self._group_datas + 1, #self._type_cls do
    self._type_cls[i]:set_active(false)
  end
end

function M:_refresh_group_data()
  self._group_datas = {}
  for _, data in ipairs(self._filter_data) do
    table.insert(self._group_datas, data)
  end
  if self._group_to_select_infos == nil then
    self._group_to_select_infos = {}
  end
  for group_id, _ in ipairs(self._group_datas) do
    if self._group_to_select_infos[group_id] == nil then
      self._group_to_select_infos[group_id] = {
        tags = {},
        ids = {}
      }
    end
  end
end

function M:_refresh_show_entity_data()
  self._show_entity_data = {}
  if is_null(self.holder) or self.holder.get_filter_item_count_map == nil then
    return
  end
  local count_map = self.holder:get_filter_item_count_map()
  if count_map == nil then
    return
  end
  for cfg_id, num in pairs(count_map) do
    self._show_entity_data[cfg_id] = num
  end
end

function M:get_entity_number_by_tag(tag)
  local num = 0
  for config_id, entity_num in pairs(self._show_entity_data) do
    if TagUtil.config_has_tag(config_id, tag) then
      num = num + entity_num
    end
  end
  return num
end

function M:get_entity_number_by_id_lst(id_lst)
  local num = 0
  for config_id, entity_num in pairs(self._show_entity_data) do
    if table.contains(id_lst, config_id) then
      num = num + entity_num
    end
  end
  return num
end

function M:clear_choose_group_info()
  if self._group_to_select_infos == nil or self._group_datas == nil then
    return
  end
  for group_id, _ in ipairs(self._group_to_select_infos) do
    self._group_to_select_infos[group_id].tags = {}
    self._group_to_select_infos[group_id].ids = {}
    self._type_cls[group_id]:refresh_tags({})
    self._type_cls[group_id]:refresh_ids({})
  end
end

function M:set_choose_group_info(group_id, selected_info)
  if self._group_to_select_infos == nil or self._group_datas == nil or self._group_datas[group_id] == nil then
    return
  end
  self._group_to_select_infos[group_id].tags = selected_info.tags
  self._group_to_select_infos[group_id].ids = selected_info.ids
  if self._type_cls[group_id] ~= nil then
    if self._group_datas[group_id].filter_data_type == filter_data_type.tag then
      self._type_cls[group_id]:refresh_tags(selected_info.tags)
    else
      self._type_cls[group_id]:refresh_ids(selected_info.ids)
    end
  end
  if self._choose_panel.is_active then
    self._choose_panel:set_extra_data({
      group_id = group_id,
      group_data = self._group_datas[group_id],
      selected_info = self._group_to_select_infos[group_id]
    })
    self._choose_panel:refresh()
  end
end

function M:get_group_show_type(group_id)
  if self._group_datas == nil or self._group_datas[group_id] == nil then
    return 1
  end
  for _, sub_group_info in pairs(self._group_datas[group_id].sub_group) do
    if sub_group_info then
      return sub_group_info.show_type
    end
  end
  return 1
end

function M:get_icon_by_tag(tag)
  return self._tag_to_icon[tag] or ""
end

function M:get_sub_group_name(group_id, sub_group_id)
  if self._group_datas[group_id] == nil or self._group_datas[group_id].sub_group[sub_group_id] == nil then
    return ""
  end
  return self._group_datas[group_id].sub_group[sub_group_id].sub_group_name
end

function M:get_sub_group_icon(group_id, sub_group_id)
  if self._group_datas[group_id] == nil or self._group_datas[group_id].sub_group[sub_group_id] == nil then
    return ""
  end
  return self._group_datas[group_id].sub_group[sub_group_id].sub_group_icon
end

function M:play_exit_anim()
  self._search_panel:set_active(false)
  base.play_exit_anim(self)
end

function M:try_handle_back()
  if not self.is_active then
    return false
  end
  if self._choose_panel ~= nil and self._choose_panel.is_active then
    self._choose_panel:set_active(false)
    return true
  end
  if self._search_panel ~= nil and self._search_panel.is_active then
    self._search_panel:set_active(false)
    return true
  end
  self:_on_btn_close_click()
  return true
end

function M:_on_btn_close_click()
  self:change_state(EUIState.Hide)
end

function M:_on_btn_confirm_filter_click()
  local filter_text = ""
  local has_filter = false
  for group_id, info in ipairs(self._group_to_select_infos) do
    if info.tags ~= nil then
      for _, tag in ipairs(info.tags) do
        filter_text = filter_text .. TagUtil.get_tag_name_in_game(tag) .. "/"
        has_filter = true
      end
    end
    if info.ids ~= nil then
      for sub_group_id, ids in pairs(info.ids) do
        if ids and 0 < #ids then
          filter_text = filter_text .. self:get_sub_group_name(group_id, sub_group_id) .. "/"
          has_filter = true
        end
      end
    end
  end
  local has_search = self._march_items and 0 < #self._march_items
  local search_ids
  if has_search then
    search_ids = {}
    for _, item_data in ipairs(self._march_items) do
      table.insert(search_ids, item_data.cfg_id)
      filter_text = filter_text .. item_data.item_name .. "/"
    end
  end
  if not has_filter and not has_search then
    self.holder:clear_filter()
    self:change_state(EUIState.Hide)
    return
  end
  if 0 < string.len(filter_text) and string.sub(filter_text, -1) == "/" then
    filter_text = string.sub(filter_text, 1, -2)
  end
  self.holder:apply_filter_group(self._group_to_select_infos, filter_text, nil, search_ids)
  self:change_state(EUIState.Hide)
end

function M:_on_btn_reset_click()
  for group_id = 1, #self._group_to_select_infos do
    self._group_to_select_infos[group_id].tags = {}
    self._group_to_select_infos[group_id].ids = {}
    if self._type_cls[group_id] ~= nil then
      self._type_cls[group_id]:refresh_tags({})
      self._type_cls[group_id]:refresh_ids({})
    end
  end
  self._choose_panel:set_active(false)
end

function M:_on_btn_clear_input_click()
  self._input_search.text = ""
  self:refresh_input_select_state(input_field_state.unselect)
  self._search_panel:set_active(false)
end

function M:_on_input_search_changed(text)
  if string.is_valid(text) then
    local filtered_text = filter_special_chars(text)
    if filtered_text ~= text then
      self._input_search.text = filtered_text
      return
    end
    self._march_items = {}
    for cfg_id, num in pairs(self._show_entity_data) do
      local item_name = item_module:get_item_name_by_id(cfg_id)
      if string.is_valid(item_name) then
        local lower_text = string.lower(text)
        local lower_name = string.lower(item_name)
        if string.find(lower_name, lower_text) then
          table.insert(self._march_items, {
            item_name = item_name,
            cfg_id = cfg_id,
            num = num
          })
        end
      end
    end
    self._search_panel:refresh(self._march_items, text)
    self._search_panel:set_active(true)
    self:refresh_input_select_state(input_field_state.select)
  else
    self:refresh_input_select_state(input_field_state.unselect)
    self._search_panel:set_active(false)
  end
end

function M:refresh_input_select_state(state)
  if self._input_select_state ~= state then
    self._input_select_state = state
    self._state_group_input:SetState(self._input_select_state)
  end
end

function M:set_input_search(text)
  self._input_search.text = text
  self._search_panel:set_active(false)
end

function M:search_all_march_items()
  local march_ids = {}
  local text = ""
  for i, item_data in ipairs(self._march_items) do
    table.insert(march_ids, item_data.cfg_id)
    text = text .. item_data.item_name
    if i ~= #self._march_items then
      text = text .. "/"
    end
  end
  if not string.is_valid(text) and string.is_valid(self._input_search.text) then
    text = self._input_search.text
  end
  self.holder:apply_filter(march_ids, {}, text)
  self:change_state(EUIState.Hide)
end

function M:bind_callbacks()
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_close_2, pack(self, M._on_btn_close_click))
  self:bind_callback(self._btn_confirm_filter, pack(self, M._on_btn_confirm_filter_click))
  self:bind_callback(self._btn_reset, pack(self, M._on_btn_reset_click))
  self:bind_callback(self._btn_clear_input, pack(self, M._on_btn_clear_input_click))
  self:bind_callback(self._btn_search, pack(self, M.search_all_march_items))
  self._input_search.onValueChanged:RemoveAllListeners()
  self._input_search.onValueChanged:AddListener(pack(self, M._on_input_search_changed))
end

function M:clear_search()
  if self._input_search ~= nil then
    self._input_search.text = ""
  end
  if self._march_items ~= nil then
    self._march_items = {}
  end
end

function M:on_start_choose_btn_click(group_id)
  if self._group_to_select_infos[group_id] == nil then
    return
  end
  self._choose_panel:set_extra_data({
    group_id = group_id,
    group_data = self._group_datas[group_id],
    selected_info = self._group_to_select_infos[group_id]
  })
  self._choose_panel:refresh()
  self._choose_panel:set_active(true)
  self:play_anim("anim_chooespanel_in")
end

function M:on_destroy()
  self._input_search.onValueChanged:RemoveAllListeners()
  base.on_destroy(self)
end

return M
