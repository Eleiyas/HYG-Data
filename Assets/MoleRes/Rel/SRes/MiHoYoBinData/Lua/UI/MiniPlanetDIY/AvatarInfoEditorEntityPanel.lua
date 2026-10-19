local M = G.Class("AvatarInfoEditorEntityPanel", G.UIPanel)
local base = G.UIPanel
local default_l2_tab_icon_path = "UISprite/Load/LayerIcon/LayoutIcon_10.png"
local lv_tab_all = -1
local sort_tag_map = {}

function M:init()
  base.init(self)
  self._lv1_tab_items = {}
  self._lv2_tab_items = {}
  self._entity_items = {}
  self._cache_all_entity_datas = {}
  self._cache_entity_datas = {}
  self._show_entity_datas = {}
  self._classify_infos = {}
  self._cache_valid_tab_lv1 = {}
  self._cache_valid_tab_lv2 = {}
  self._select_lv1_tab_info = nil
  self._select_lv2_tab_info = nil
  self._show_expand = false
  self._show_lv2_tab = false
  self._sort_type = nil
  self._sort_reverse = false
  self._filter_id_list = nil
  self._filter_tag_list = nil
  self._filter_group = nil
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._filter_panel = self:add_panel_async("UI/MiniPlanetDIY/AvatarInfoEditorFilterPanel", nil, self.holder and self.holder.trans or self.trans)
  if not is_null(self._trans_lv1_tab_item) then
    UIUtil.set_active(self._trans_lv1_tab_item, false)
  end
  if not is_null(self._trans_lv2_tab_item) then
    UIUtil.set_active(self._trans_lv2_tab_item, false)
  end
  if not is_null(self._trans_entity_item) then
    UIUtil.set_active(self._trans_entity_item, false)
  end
  if not is_null(self._scroll_entity_full) then
    self._scroll_entity_full:SetFrameLoadingSettings(true, 1)
  end
  if not is_null(self._trans_filter) then
    UIUtil.set_active(self._trans_filter, false)
  end
end

function M:on_enable()
  base.on_enable(self)
  self:_create_sort_panel()
  if not is_null(self._tog_expand) and self._tog_expand.isOn then
    self._tog_expand.isOnValue = false
    self:_refresh_expand(false)
    self:init_anim_trigger()
  end
  self:_refresh_all_entity_datas()
  if self:_can_use_tab_classify() then
    self:_refresh_lv1_tabs()
    if self:_select_first_available_lv1_tab() then
      return
    end
  end
  self:refresh_entity_items()
end

function M:init_anim_trigger()
  if is_null(self._animator) then
    return
  end
  self._animator:ResetTrigger("lifted")
  self._animator:ResetTrigger("lifted_all")
  self._animator:ResetTrigger("downed")
  self._animator:ResetTrigger("downed_all")
  if self._show_expand then
    self._animator:SetTrigger(self._show_lv2_tab and "lifted" or "lifted_all")
  else
    self._animator:SetTrigger(self._show_lv2_tab and "downed" or "downed_all")
  end
end

function M:on_disable()
  base.on_disable(self)
  if not is_null(self._scroll_entity) then
    self._scroll_entity:Close()
  end
  if not is_null(self._scroll_entity_full) then
    self._scroll_entity_full:Close()
  end
  if not is_null(self._filter_panel) then
    self._filter_panel:change_state(EUIState.Hide)
  end
end

function M:on_destroy()
  base.on_destroy(self)
  if not is_null(self._scroll_entity) then
    self._scroll_entity:Close()
  end
  if not is_null(self._scroll_entity_full) then
    self._scroll_entity_full:Close()
  end
end

function M:_add_ui_listener()
  if not is_null(self._tog_expand) then
    self:bind_callback(self._tog_expand, pack(self, M._on_tog_expand_click))
  end
  if not is_null(self._btn_sort) then
    self:bind_callback(self._btn_sort, pack(self, M._on_btn_sort_click))
  end
  if not is_null(self._btn_filter) then
    self:bind_callback(self._btn_filter, pack(self, M._on_btn_filter_click))
  end
  if not is_null(self._btn_clear_filter) then
    self:bind_callback(self._btn_clear_filter, pack(self, M.clear_filter))
  end
end

function M:_on_tog_expand_click(is_on)
  self:_refresh_expand(is_on)
  if is_null(self._animator) then
    return
  end
  if is_on then
    self._animator:SetTrigger(self._show_lv2_tab and "lift" or "lift_all")
  else
    self._animator:SetTrigger(self._show_lv2_tab and "down" or "down_all")
  end
end

function M:is_show_extend()
  return self._show_expand
end

function M:try_handle_back()
  if not self.is_active then
    return false
  end
  if not is_null(self._filter_panel) and self._filter_panel:try_handle_back() then
    return true
  end
  if self:_is_sort_dropdown_expanded() then
    self._sort_panel:on_btn_close_sort_type_click()
    return true
  end
  if self._show_expand then
    if not is_null(self._tog_expand) then
      self._tog_expand.isOnValue = false
    end
    self:_on_tog_expand_click(false)
    return true
  end
  return false
end

function M:_is_sort_dropdown_expanded()
  if self._sort_panel == nil or self._sort_panel._is_close then
    return false
  end
  local btn_close = self._sort_panel._btn_close_sort_type
  return not_null(btn_close) and btn_close.gameObject.activeInHierarchy
end

function M:_refresh_expand(is_on)
  self._show_expand = is_on == true
  if not is_null(self._scroll_rect) then
    UIUtil.set_active(self._scroll_rect.gameObject, not self._show_expand)
  end
  if not is_null(self._scroll_rect_full) then
    UIUtil.set_active(self._scroll_rect_full.gameObject, self._show_expand)
  end
  self:_refresh_entity_items_view()
end

function M:_can_use_tab_classify()
  return not is_null(self._trans_lv1_tab_parent) and not is_null(self._trans_lv1_tab_item)
end

function M:_can_use_lv2_tab()
  return not is_null(self._trans_lv2_tab_parent) and not is_null(self._trans_lv2_tab_item)
end

function M:_refresh_all_entity_datas()
  table.clear(self._cache_all_entity_datas)
  local all_check_tag_list = self:_build_all_check_tag_list()
  if #all_check_tag_list <= 0 then
    return
  end
  local unique_config_ids = {}
  self:_collect_codex_data_list_by_type(CodexDataType.Furniture, unique_config_ids, all_check_tag_list)
  self:_collect_codex_data_list_by_type(CodexDataType.Plant, unique_config_ids, all_check_tag_list)
  self:_collect_special_object_data_list(unique_config_ids, all_check_tag_list)
end

function M:_try_add_entity_data_by_config_id(config_id, unique_config_ids, check_tag_list)
  config_id = avatar_info_editor_module.to_placement_config_id(config_id)
  if config_id <= 0 or unique_config_ids[config_id] then
    return
  end
  if self:_filter_special_data(config_id) then
    return
  end
  if not TagUtil.config_has_any_tag_by_string_list(config_id, check_tag_list) and not TagUtil.config_has_any_tag_by_uint_list(config_id, check_tag_list) then
    return
  end
  unique_config_ids[config_id] = true
  table.insert(self._cache_all_entity_datas, {
    item_type = avatar_info_editor_module.entity_item_type.decoration,
    config_id = config_id
  })
end

function M:_collect_special_object_data_list(unique_config_ids, check_tag_list)
  local cfg_table = ExcelDataUtil.get_table(typeof(BSpecialObjectIdCfg)) or {}
  for _, cfg in pairs(cfg_table) do
    if not is_null(cfg) then
      self:_try_add_entity_data_by_config_id(cfg.specialobjectid or 0, unique_config_ids, check_tag_list)
    end
  end
end

function M:_collect_codex_data_list_by_type(codex_type, unique_config_ids, check_tag_list)
  local codex_data_list = CsCodexModuleUtil.GetCodexDataListByType(codex_type)
  if is_null(codex_data_list) then
    return
  end
  for _, codex_data in ipairs(list_to_table(codex_data_list)) do
    if not is_null(codex_data) and codex_data.IsUnlocked then
      local config_id = codex_data.IdCfg and codex_data.IdCfg.id or 0
      self:_try_add_entity_data_by_config_id(config_id, unique_config_ids, check_tag_list)
    end
  end
end

function M:_build_all_check_tag_list()
  local check_tag_set = {}
  local check_tag_list = {}
  local classify_infos = list_to_table(BFurnTagClassifyCfg.GetClassifyInfos()) or {}
  for _, lv1_tab_info in ipairs(classify_infos) do
    local lv1_cfgs = list_to_table(BFurnTagClassifyCfg.GetCfgsByTag(lv1_tab_info.id))
    self:_append_check_tags_from_cfgs(lv1_cfgs, check_tag_set, check_tag_list)
    local lv2_tab_infos = list_to_table(lv1_tab_info.secondClassifyInfos)
    for _, lv2_tab_info in ipairs(lv2_tab_infos) do
      local lv2_cfgs = list_to_table(BFurnTagClassifyCfg.GetCfgsByTag(lv2_tab_info.id))
      self:_append_check_tags_from_cfgs(lv2_cfgs, check_tag_set, check_tag_list)
    end
  end
  return check_tag_list
end

function M:_append_check_tags_from_cfgs(tag_cfgs, check_tag_set, check_tag_list)
  for _, cfg in ipairs(tag_cfgs) do
    local tag = self:_get_check_tag_from_cfg(cfg)
    if string.is_valid(tag) and not check_tag_set[tag] then
      check_tag_set[tag] = true
      table.insert(check_tag_list, tag)
    end
  end
end

function M:_get_check_tag_from_cfg(cfg)
  if not self:_check_cfg_valid(cfg) then
    return nil
  end
  if string.is_valid(cfg.thirdtagtype) then
    return cfg.thirdtagtype
  end
  if string.is_valid(cfg.scetagtype) then
    return cfg.scetagtype
  end
  if string.is_valid(cfg.fsttagtype) then
    return cfg.fsttagtype
  end
  return nil
end

function M:refresh_entity_items()
  self:_refresh_cache_entity_datas()
  self:_refresh_show_entity_datas()
  self:_refresh_entity_items_view()
end

function M:_refresh_cache_entity_datas()
  table.clear(self._cache_entity_datas)
  if not self:_can_use_tab_classify() or self._select_lv1_tab_info == nil then
    for _, data in ipairs(self._cache_all_entity_datas) do
      table.insert(self._cache_entity_datas, data)
    end
    return
  end
  local select_tag = self._select_lv1_tab_info.id
  if self._select_lv2_tab_info and self._select_lv2_tab_info.id and self._select_lv2_tab_info.id ~= lv_tab_all then
    select_tag = self._select_lv2_tab_info.id
  end
  if select_tag == lv_tab_all then
    for _, data in ipairs(self._cache_all_entity_datas) do
      table.insert(self._cache_entity_datas, data)
    end
    return
  end
  local check_tag_list = self:_build_check_tag_list(select_tag)
  if #check_tag_list <= 0 then
    return
  end
  for _, data in ipairs(self._cache_all_entity_datas) do
    local config_id = data.config_id or 0
    if 0 < config_id and (TagUtil.config_has_any_tag_by_string_list(config_id, check_tag_list) or TagUtil.config_has_any_tag_by_uint_list(config_id, check_tag_list)) then
      table.insert(self._cache_entity_datas, data)
    end
  end
end

function M:_build_check_tag_list(select_tag)
  local check_tag_set = {}
  local check_tag_list = {}
  local tag_cfgs = list_to_table(BFurnTagClassifyCfg.GetCfgsByTag(select_tag))
  self:_append_check_tags_from_cfgs(tag_cfgs, check_tag_set, check_tag_list)
  return check_tag_list
end

function M:_refresh_show_entity_datas()
  table.clear(self._show_entity_datas)
  self:_apply_filter_and_search()
  self:_apply_sort()
end

function M:_apply_filter_and_search()
  if not self:_has_filter() then
    for _, data in ipairs(self._cache_entity_datas) do
      table.insert(self._show_entity_datas, data)
    end
    return
  end
  for _, data in ipairs(self._cache_entity_datas) do
    local config_id = data and data.config_id or 0
    if 0 < config_id and self:_is_item_filtered(config_id) then
      table.insert(self._show_entity_datas, data)
    end
  end
end

local function get_config_id_and_type_sort(data)
  local config_id = data and data.config_id or 0
  if config_id <= 0 then
    return 0, math.huge
  end
  if sort_tag_map[config_id] then
    return config_id, sort_tag_map[config_id]
  end
  local furn_tag_cfg = GameplayUtilities.Furniture.GetFurnTagClassifyCfgByCfgId(config_id)
  local sort = furn_tag_cfg and furn_tag_cfg.sort or math.huge
  sort_tag_map[config_id] = sort
  return config_id, sort
end

function M._sort_helper(a, b)
  local config_id_a, sort_a = get_config_id_and_type_sort(a)
  local config_id_b, sort_b = get_config_id_and_type_sort(b)
  if sort_a ~= sort_b then
    return sort_a < sort_b
  end
  return config_id_a < config_id_b
end

function M._sort_helper_reverse(a, b)
  return M._sort_helper(b, a)
end

function M._sort_by_rarity(a, b)
  local config_id_a, sort_a = get_config_id_and_type_sort(a)
  local config_id_b, sort_b = get_config_id_and_type_sort(b)
  local item_cfg_a = ExcelDataUtil.get_value(typeof(BItemCfg), config_id_a)
  local item_cfg_b = ExcelDataUtil.get_value(typeof(BItemCfg), config_id_b)
  local rank_a = item_cfg_a and item_cfg_a.rank or 0
  local rank_b = item_cfg_b and item_cfg_b.rank or 0
  if rank_a ~= rank_b then
    return rank_a > rank_b
  end
  if sort_a ~= sort_b then
    return sort_a < sort_b
  end
  return config_id_a < config_id_b
end

function M._sort_by_rarity_reverse(a, b)
  return M._sort_by_rarity(b, a)
end

function M._sort_by_suit(a, b)
  local config_id_a, sort_a = get_config_id_and_type_sort(a)
  local config_id_b, sort_b = get_config_id_and_type_sort(b)
  local furniture_cfg_a = ExcelDataUtil.get_value(typeof(BFurnitureCfg), config_id_a)
  local furniture_cfg_b = ExcelDataUtil.get_value(typeof(BFurnitureCfg), config_id_b)
  local package_id_a = furniture_cfg_a and furniture_cfg_a.packageid > 0 and furniture_cfg_a.packageid or math.huge
  local package_id_b = furniture_cfg_b and furniture_cfg_b.packageid > 0 and furniture_cfg_b.packageid or math.huge
  if package_id_a ~= package_id_b then
    return package_id_a < package_id_b
  end
  if sort_a ~= sort_b then
    return sort_a < sort_b
  end
  return config_id_a < config_id_b
end

function M._sort_by_suit_reverse(a, b)
  return M._sort_by_suit(b, a)
end

function M:_apply_sort()
  if self._sort_type == world_editor_module.sort_type.suit then
    table.sort(self._show_entity_datas, self._sort_reverse and M._sort_by_suit_reverse or M._sort_by_suit)
  elseif self._sort_type == world_editor_module.sort_type.rarity then
    table.sort(self._show_entity_datas, self._sort_reverse and M._sort_by_rarity_reverse or M._sort_by_rarity)
  else
    table.sort(self._show_entity_datas, self._sort_reverse and M._sort_helper_reverse or M._sort_helper)
  end
end

function M:_create_sort_panel()
  if is_null(self._trans_sort_panel) or world_editor_module == nil then
    return
  end
  if not self._sort_panel then
    self._sort_panel = self:add_panel(item_module.sort_panel, self._trans_sort_panel)
  end
  local sort_data = {}
  for _, sort_type in ipairs(world_editor_module.sort_type_list) do
    table.insert(sort_data, {
      sort_type = sort_type,
      name = world_editor_module.sort_type_name[sort_type]
    })
  end
  self._sort_panel:refresh(sort_data, pack(self, M._on_sort_type_changed))
end

function M:_on_btn_sort_click()
end

function M:_on_btn_filter_click()
  if is_null(self._filter_panel) then
    return
  end
  self._filter_panel:change_state(EUIState.Show)
  if self._filter_group ~= nil then
    for group_id, filter_info in ipairs(self._filter_group) do
      self._filter_panel:set_choose_group_info(group_id, filter_info)
    end
  else
    self._filter_panel:clear_choose_group_info()
  end
end

function M:_on_sort_type_changed(sort_type, ascending)
  self._sort_type = sort_type
  self._sort_reverse = not ascending
  self:_apply_sort()
  self:_refresh_entity_items_view()
end

function M:_init_classify_infos()
  self._classify_infos = list_to_table(BFurnTagClassifyCfg.GetClassifyInfos()) or {}
  self._cache_valid_tab_lv1 = {}
  self._cache_valid_tab_lv2 = {}
  for _, lv1_tab_info in ipairs(self._classify_infos) do
    local lv1_cfgs = list_to_table(BFurnTagClassifyCfg.GetCfgsByTag(lv1_tab_info.id))
    for _, cfg in ipairs(lv1_cfgs) do
      if self:_check_cfg_valid(cfg) then
        self._cache_valid_tab_lv1[lv1_tab_info.id] = true
        break
      end
    end
    local lv2_tab_infos = list_to_table(lv1_tab_info.secondClassifyInfos)
    for _, lv2_tab_info in ipairs(lv2_tab_infos) do
      local lv2_cfgs = list_to_table(BFurnTagClassifyCfg.GetCfgsByTag(lv2_tab_info.id))
      for _, cfg in ipairs(lv2_cfgs) do
        if self:_check_cfg_valid(cfg) then
          self._cache_valid_tab_lv2[lv2_tab_info.id] = true
          break
        end
      end
    end
  end
  table.insert(self._classify_infos, 1, {
    id = lv_tab_all,
    name = UIUtil.get_text_by_id("UGC_ITEM_CLASSIFY_TOTAL"),
    iconPath = default_l2_tab_icon_path,
    secondClassifyInfos = {}
  })
end

function M:_check_cfg_valid(cfg)
  return cfg.showInMiniPlanet
end

function M:_refresh_lv1_tabs()
  if not self:_can_use_tab_classify() then
    return
  end
  self:_init_classify_infos()
  local index = 0
  for _, lv1_tab_info in ipairs(self._classify_infos) do
    if lv1_tab_info.id == lv_tab_all or self._cache_valid_tab_lv1[lv1_tab_info.id] then
      index = index + 1
      local lv1_tab_item = self._lv1_tab_items[index]
      if not lv1_tab_item then
        local go = UIUtil.load_prefab_set_parent(self._trans_lv1_tab_item, self._trans_lv1_tab_parent)
        lv1_tab_item = self:add_panel("UI/WorldEditor/WorldEditorEntityLv1TabItem", go)
        self._lv1_tab_items[index] = lv1_tab_item
      end
      lv1_tab_item.trans:SetAsLastSibling()
      lv1_tab_item:set_extra_data(lv1_tab_info)
      lv1_tab_item:refresh_view()
    end
  end
  for i = index + 1, #self._lv1_tab_items do
    local lv1_tab_item = self._lv1_tab_items[i]
    lv1_tab_item:set_extra_data(nil)
    lv1_tab_item:refresh_view()
  end
end

function M:set_select_lv1_tab(lv1_tab_info)
  self._select_lv1_tab_info = lv1_tab_info
  self:refresh_lv2_tabs()
  self:refresh_entity_items()
  self:_active_lv2_tabs_with_filter()
end

function M:set_select_lv2_tab(lv2_tab_info)
  self._select_lv2_tab_info = lv2_tab_info
  self:refresh_entity_items()
end

function M:get_select_lv2_tab_info()
  return self._select_lv2_tab_info
end

function M:refresh_lv2_tabs()
  if not self:_can_use_tab_classify() then
    return
  end
  if not self._select_lv1_tab_info then
    return
  end
  if not self:_can_use_lv2_tab() then
    self:set_select_lv2_tab(nil)
    return
  end
  local lv2_tab_infos = list_to_table(self._select_lv1_tab_info.secondClassifyInfos)
  if not lv2_tab_infos[1] or lv2_tab_infos[1].id ~= lv_tab_all then
    table.insert(lv2_tab_infos, 1, {
      id = lv_tab_all,
      name = UIUtil.get_text_by_id("UGC_ITEM_CLASSIFY_TOTAL"),
      iconPath = default_l2_tab_icon_path
    })
  end
  local index = 0
  for _, lv2_tab_info in ipairs(lv2_tab_infos) do
    if lv2_tab_info.id == lv_tab_all or self._cache_valid_tab_lv2[lv2_tab_info.id] then
      index = index + 1
      local lv2_tab_item = self._lv2_tab_items[index]
      if not lv2_tab_item then
        local go = UIUtil.load_prefab_set_parent(self._trans_lv2_tab_item, self._trans_lv2_tab_parent)
        lv2_tab_item = self:add_panel("UI/WorldEditor/WorldEditorEntityLv2TabItem", go)
        self._lv2_tab_items[index] = lv2_tab_item
      end
      lv2_tab_item:set_extra_data(lv2_tab_info)
      lv2_tab_item:refresh_view()
    end
  end
  for i = index + 1, #self._lv2_tab_items do
    local lv2_tab_item = self._lv2_tab_items[i]
    lv2_tab_item:set_extra_data(nil)
    lv2_tab_item:refresh_view()
  end
  local last_show_lv2_tab = self._show_lv2_tab
  self._show_lv2_tab = 1 < index
  UIUtil.set_active(self._trans_lv2_tab_parent, self._show_lv2_tab)
  if not is_null(self._animator) and last_show_lv2_tab ~= self._show_lv2_tab then
    if self._show_lv2_tab then
      self._animator:SetTrigger(self._show_expand and "lifted_switchtonormal" or "downed_switchtonormal")
    else
      self._animator:SetTrigger(self._show_expand and "lifted_switchtoall" or "downed_switchtoall")
    end
  end
  if self:_select_first_available_lv2_tab() then
    return
  end
  if self._lv2_tab_items[1] then
    self._lv2_tab_items[1]:set_select(true)
  else
    self:set_select_lv2_tab(nil)
  end
end

function M:_select_first_available_lv1_tab()
  for _, lv1_tab_item in ipairs(self._lv1_tab_items) do
    if lv1_tab_item and lv1_tab_item._extra_data and lv1_tab_item._toggle and lv1_tab_item._toggle.interactable then
      lv1_tab_item:set_select(true)
      return true
    end
  end
  return false
end

function M:_select_first_available_lv2_tab()
  for _, lv2_tab_item in ipairs(self._lv2_tab_items) do
    if lv2_tab_item and lv2_tab_item._extra_data and lv2_tab_item._toggle and lv2_tab_item._toggle.interactable then
      lv2_tab_item:set_select(true)
      return true
    end
  end
  return false
end

function M:_active_lv2_tabs_with_item_count()
  if not self._select_lv1_tab_info then
    return
  end
  for _, lv2_tab_item in pairs(self._lv2_tab_items) do
    if lv2_tab_item and lv2_tab_item._extra_data then
      local tab_id = lv2_tab_item._extra_data.id
      local has_valid_item
      if tab_id == lv_tab_all then
        has_valid_item = self:_check_tab_has_item(self._select_lv1_tab_info.id)
      else
        has_valid_item = self:_check_tab_has_item(tab_id)
      end
      lv2_tab_item:set_toggle_interactable(has_valid_item)
    end
  end
end

function M:_active_lv1_tabs_with_item_count()
  for _, lv1_tab_item in pairs(self._lv1_tab_items) do
    if lv1_tab_item and lv1_tab_item._extra_data then
      local tab_id = lv1_tab_item._extra_data.id
      lv1_tab_item:set_toggle_interactable(self:_check_tab_has_item(tab_id))
    end
  end
end

function M:_active_lv1_tabs_with_filter()
  if not self:_has_filter() then
    for _, lv1_tab_item in pairs(self._lv1_tab_items) do
      if lv1_tab_item then
        lv1_tab_item:set_toggle_interactable(true)
      end
    end
    return
  end
  for _, lv1_tab_item in pairs(self._lv1_tab_items) do
    if lv1_tab_item and lv1_tab_item._extra_data then
      local has_valid_item = self:_check_tab_has_filtered_item(lv1_tab_item._extra_data.id)
      lv1_tab_item:set_toggle_interactable(has_valid_item)
    end
  end
end

function M:_active_lv2_tabs_with_filter()
  if not self:_has_filter() then
    for _, lv2_tab_item in pairs(self._lv2_tab_items) do
      if lv2_tab_item then
        lv2_tab_item:set_toggle_interactable(true)
      end
    end
    return
  end
  if not self._select_lv1_tab_info then
    return
  end
  for _, lv2_tab_item in pairs(self._lv2_tab_items) do
    if lv2_tab_item and lv2_tab_item._extra_data then
      local tab_id = lv2_tab_item._extra_data.id
      local has_valid_item
      if tab_id == lv_tab_all then
        has_valid_item = self:_check_tab_has_filtered_item(self._select_lv1_tab_info.id)
      else
        has_valid_item = self:_check_tab_has_filtered_item(tab_id)
      end
      lv2_tab_item:set_toggle_interactable(has_valid_item)
    end
  end
end

function M:_check_tab_has_item(tab_id)
  if tab_id == nil then
    return false
  end
  if tab_id == lv_tab_all then
    return #self._cache_all_entity_datas > 0
  end
  local check_tag_list = self:_build_check_tag_list(tab_id)
  if #check_tag_list <= 0 then
    return false
  end
  for _, data in ipairs(self._cache_all_entity_datas) do
    local config_id = data.config_id or 0
    if 0 < config_id and (TagUtil.config_has_any_tag_by_string_list(config_id, check_tag_list) or TagUtil.config_has_any_tag_by_uint_list(config_id, check_tag_list)) then
      return true
    end
  end
  return false
end

function M:_check_tab_has_filtered_item(tab_id)
  if not tab_id then
    return false
  end
  if tab_id == lv_tab_all then
    return true
  end
  local check_tag_list = self:_build_check_tag_list(tab_id)
  if #check_tag_list <= 0 then
    return false
  end
  for _, data in ipairs(self._cache_all_entity_datas) do
    local config_id = data and data.config_id or 0
    local match = 0 < config_id and (TagUtil.config_has_any_tag_by_string_list(config_id, check_tag_list) or TagUtil.config_has_any_tag_by_uint_list(config_id, check_tag_list))
    if match and self:_is_item_filtered(config_id) then
      return true
    end
  end
  return false
end

function M:_has_filter()
  local has_filter = self._filter_tag_list ~= nil or self._filter_id_list ~= nil
  local has_filter_group = self._filter_group ~= nil
  return has_filter or has_filter_group
end

function M:_is_item_filtered(config_id)
  if self._filter_id_list and #self._filter_id_list > 0 and table.contains(self._filter_id_list, config_id) then
    return true
  end
  if self._filter_tag_list and 0 < #self._filter_tag_list and (TagUtil.config_has_any_tag_by_string_list(config_id, self._filter_tag_list) or TagUtil.config_has_any_tag_by_uint_list(config_id, self._filter_tag_list)) then
    return true
  end
  if self._filter_group then
    local has_non_empty_group = false
    for _, filter_info in ipairs(self._filter_group) do
      if filter_info.tags and 0 < #filter_info.tags then
        has_non_empty_group = true
        local group_matched = TagUtil.config_has_any_tag_by_string_list(config_id, filter_info.tags) or TagUtil.config_has_any_tag_by_uint_list(config_id, filter_info.tags)
        if not group_matched then
          return false
        end
      end
      if filter_info.ids then
        local group_matched = false
        local has_ids = false
        for _, target_ids in pairs(filter_info.ids) do
          has_non_empty_group = true
          has_ids = true
          if table.contains(target_ids, config_id) then
            group_matched = true
            break
          end
        end
        if has_ids and not group_matched then
          return false
        end
      end
    end
    if has_non_empty_group then
      return true
    end
  end
  return false
end

function M:apply_filter(id_list, tag_list, text)
  self._filter_id_list = table.shallow_copy(id_list)
  self._filter_tag_list = table.shallow_copy(tag_list)
  self._filter_group = nil
  if not is_null(self._txt_filter) then
    UIUtil.set_text(self._txt_filter, text)
  end
  if not is_null(self._trans_filter) then
    UIUtil.set_active(self._trans_filter, true)
  end
  self:_active_lv1_tabs_with_filter()
  if not self:_select_first_available_lv1_tab() then
    self:refresh_entity_items()
  end
end

function M:apply_filter_group(filter_group, text, ownership_type, search_id_list)
  if filter_group == nil then
    self._filter_group = nil
  else
    self._filter_group = {}
    for _, group_data in ipairs(filter_group) do
      local copy_group = {}
      copy_group.tags = table.shallow_copy(group_data.tags)
      copy_group.ids = {}
      for sub_group_id, target_ids in pairs(group_data.ids) do
        copy_group.ids[sub_group_id] = table.shallow_copy(target_ids)
      end
      table.insert(self._filter_group, copy_group)
    end
  end
  self._filter_id_list = search_id_list and 0 < #search_id_list and table.shallow_copy(search_id_list) or nil
  self._filter_tag_list = nil
  if not is_null(self._txt_filter) then
    UIUtil.set_text(self._txt_filter, text)
  end
  if not is_null(self._trans_filter) then
    UIUtil.set_active(self._trans_filter, true)
  end
  self:_active_lv1_tabs_with_filter()
  if not self:_select_first_available_lv1_tab() then
    self:refresh_entity_items()
  end
end

function M:clear_filter()
  self._filter_id_list = nil
  self._filter_tag_list = nil
  self._filter_group = nil
  if not is_null(self._trans_filter) then
    UIUtil.set_active(self._trans_filter, false)
  end
  if not is_null(self._filter_panel) then
    self._filter_panel:clear_search()
  end
  self:refresh_entity_items()
  self:_active_lv1_tabs_with_filter()
  self:_active_lv2_tabs_with_filter()
end

function M:get_filter_item_count_map()
  local count_map = {}
  for _, data in ipairs(self._cache_all_entity_datas) do
    local config_id = data and data.config_id or 0
    if 0 < config_id then
      count_map[config_id] = (count_map[config_id] or 0) + 1
    end
  end
  return count_map
end

function M:_filter_special_data(config_id)
  local entity_put_type = GameplayUtilities.Furniture.GetEntityTypeFromClassification(config_id)
  local entity_cfg
  if entity_put_type and entity_put_type ~= 0 then
    entity_cfg = BEntityCfg.GetConfig(config_id, entity_put_type)
  end
  entity_cfg = entity_cfg or BEntityCfg.GetConfig(config_id)
  return entity_cfg and (entity_cfg.placecfgid == 202 or entity_cfg.placecfgid == 203)
end

function M:_refresh_entity_items_view()
  if is_null(self._scroll_entity) and is_null(self._scroll_entity_full) then
    return
  end
  if self._show_expand and not is_null(self._scroll_entity_full) then
    self._scroll_entity_full:SetFrameLoadingSettings(false)
  end
  if not is_null(self._scroll_entity) then
    self._scroll_entity:Init(pack(self, M._refresh_entity_item), #self._show_entity_datas)
  end
  if not is_null(self._scroll_entity_full) then
    self._scroll_entity_full:Init(pack(self, M._refresh_entity_item), #self._show_entity_datas)
  end
  if not is_null(self._trans_empty_tips) then
    UIUtil.set_active(self._trans_empty_tips, #self._show_entity_datas <= 0)
  end
end

function M:_refresh_entity_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local entity_item = self._entity_items[instance_id]
  if not entity_item then
    entity_item = self:add_panel("UI/MiniPlanetDIY/AvatarInfoEditorEntityItem", trans)
    self._entity_items[instance_id] = entity_item
  end
  entity_item:set_extra_data(self._show_entity_datas[index])
  entity_item:refresh_view()
end

function M:on_entity_item_begin_drag(evt)
  if not self._show_expand and not is_null(self._scroll_entity) then
    self._scroll_entity:OnBeginDrag(evt)
  elseif self._show_expand and not is_null(self._scroll_entity_full) then
    self._scroll_entity_full:OnBeginDrag(evt)
  end
  if not self._show_expand and not is_null(self._scroll_rect) then
    self._scroll_rect:OnBeginDrag(evt)
  elseif self._show_expand and not is_null(self._scroll_rect_full) then
    self._scroll_rect_full:OnBeginDrag(evt)
  end
end

function M:on_entity_item_drag(evt)
  if not self._show_expand and not is_null(self._scroll_rect) then
    self._scroll_rect:OnDrag(evt)
  elseif self._show_expand and not is_null(self._scroll_rect_full) then
    self._scroll_rect_full:OnDrag(evt)
  end
end

function M:on_entity_item_end_drag(evt)
  if not self._show_expand and not is_null(self._scroll_entity) then
    self._scroll_entity:OnEndDrag(evt)
  elseif self._show_expand and not is_null(self._scroll_entity_full) then
    self._scroll_entity_full:OnEndDrag(evt)
  end
  if not self._show_expand and not is_null(self._scroll_rect) then
    self._scroll_rect:OnEndDrag(evt)
  elseif self._show_expand and not is_null(self._scroll_rect_full) then
    self._scroll_rect_full:OnEndDrag(evt)
  end
end

function M:on_entity_item_scroll(evt)
  if not self._show_expand and not is_null(self._scroll_rect) then
    self._scroll_rect:OnScroll(evt)
  elseif self._show_expand and not is_null(self._scroll_rect_full) then
    self._scroll_rect_full:OnScroll(evt)
  end
end

function M:get_check_drag_area_trans()
  if self._show_expand and not is_null(self._scroll_rect_full) then
    return self._scroll_rect_full.transform
  end
  if not is_null(self._scroll_rect) then
    return self._scroll_rect.transform
  end
  return self.trans
end

function M:set_pending_pointer_screen_pos(pointer_screen_pos)
  self._pending_pointer_screen_pos = pointer_screen_pos
end

function M:_get_edit_handler()
  if is_null(self.holder) or self.holder._get_edit_handler == nil then
    return nil
  end
  local edit_handler = self.holder:_get_edit_handler()
  if is_null(edit_handler) then
    return nil
  end
  return edit_handler
end

function M:get_placement_max_count(config_id)
  config_id = config_id or 0
  if config_id <= 0 then
    return 0
  end
  local edit_handler = self:_get_edit_handler()
  if edit_handler == nil then
    return 0
  end
  return edit_handler:GetPlacementMaxCount(config_id)
end

function M:get_placement_remain_count(config_id)
  config_id = config_id or 0
  if config_id <= 0 then
    return 0
  end
  local edit_handler = self:_get_edit_handler()
  if edit_handler == nil then
    return 0
  end
  return edit_handler:GetPlacementRemainCount(config_id)
end

function M:refresh_placement_limit_state()
  for _, entity_item in pairs(self._entity_items) do
    if not is_null(entity_item) then
      entity_item:refresh_placement_limit_state()
    end
  end
end

function M:_get_entity_put_type(config_id)
  local entity_put_type = GameplayUtilities.Furniture.GetEntityTypeFromClassification(config_id)
  if entity_put_type and 0 < entity_put_type then
    return entity_put_type
  end
  local id_cfg = ExcelDataUtil.get_value(typeof(BIdCfg), config_id)
  return id_cfg and id_cfg.type or 0
end

function M:on_entity_item_try_create_decoration(item_data, is_drag_create)
  if item_data == nil or item_data.item_type ~= avatar_info_editor_module.entity_item_type.decoration then
    return
  end
  local config_id = item_data.config_id or 0
  if config_id <= 0 then
    return
  end
  local edit_handler = self:_get_edit_handler()
  if edit_handler == nil then
    return
  end
  if edit_handler:IsPlacementCountLimitReached(config_id) then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("MiniPlanetDIY_PlaceCountLimitTip", edit_handler:GetPlacementMaxCount(config_id)))
    return
  end
  local scene_type = self:_get_entity_put_type(config_id)
  if scene_type <= 0 then
    Logger.LogError("AvatarInfoEditorEntityPanel: 取不到放置用的 sceneType，config_id=" .. config_id)
    return
  end
  if edit_handler:IsDecorationLoadLimitReached(config_id, scene_type) then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("MiniPlanetDIY_PlaceLoadLimitTip"))
    return
  end
  local screen_pos = self._pending_pointer_screen_pos
  self._pending_pointer_screen_pos = nil
  if screen_pos == nil then
    screen_pos = Vector2(Screen.width * 0.5, Screen.height * 0.5)
  end
  edit_handler:SpawnDecorationByConfigId(config_id, scene_type, screen_pos, is_drag_create == true)
  self:refresh_placement_limit_state()
end

return M
