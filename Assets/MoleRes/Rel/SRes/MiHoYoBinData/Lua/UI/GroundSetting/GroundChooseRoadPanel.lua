local M = G.Class("GroundChooseRoadPanel", G.UIPanel)
local base = G.UIPanel
local STATE_TYPE_PRECISE = 0
local STATE_TYPE_NORMAL = 1
local STATE_GROUND_ROAD = 0
local STATE_GROUND_PATTERN = 1
local MAP_CELL_TYPE_LAND = 1
local SINGLE_ITEM_CLS = "UI/GroundSetting/GroundChooseRoadSingleItem"
local MULTI_ITEM_CLS = "UI/GroundSetting/GroundChooseRoadItem"
local PATTERN_TYPE_ITEM_CLS = "UI/GroundSetting/GroundChoosePatternTypeItem"
local PATTERN_SINGLE_ITEM_CLS = "UI/GroundSetting/GroundChoosePatternSingleItem"
local PATTERN_MULTI_ITEM_CLS = "UI/GroundSetting/GroundChoosePatternItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainPage/GroundChooseRoadDialog"
  self._is_embedded = false
  self._is_precise = false
  self._cur_ground_state = STATE_GROUND_ROAD
  self._max_slot_count = 0
  self._road_cfg_list = {}
  self._single_item_map = {}
  self._multi_item_map = {}
  self._single_list_inited = false
  self._multi_list_inited = false
  self.select_cfg_id = 0
  self.select_index = 1
  self._multi_selected_ids = {}
  self._pattern_set_list = {}
  self._pattern_cfg_list = {}
  self._all_decal_cfgs = {}
  self._cur_pattern_set_id = 0
  self._pattern_type_item_map = {}
  self._pattern_single_item_map = {}
  self._pattern_multi_item_map = {}
  self._pattern_type_inited = false
  self._pattern_single_inited = false
  self._pattern_multi_inited = false
  self._is_item_dragging = false
  self._drag_cfg_id = 0
  self._drag_enabled = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  if not self._is_precise then
    return
  end
  self:_init_multi_selected_from_slot()
  if self._cur_ground_state == STATE_GROUND_ROAD then
    if self._multi_list_inited and not is_null(self._scroll_load_list_multi) then
      self._scroll_load_list_multi:RefreshCurrent()
    end
  elseif self._cur_ground_state == STATE_GROUND_PATTERN and self._pattern_multi_inited and not is_null(self._scroll_pattern_list_multi) then
    self._scroll_pattern_list_multi:RefreshCurrent()
  end
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnAllUnlockedSceneUgcGridStylesNotify, function()
    self:_refresh_ui()
  end)
  self:add_evt_listener(EventID.OnSceneUgcGridStyleUpdateNotify, function()
    self:_refresh_ui()
  end)
  self:add_evt_listener(EventID.OnPlayerSceneUgcDataNotify, function()
    self:_init_multi_selected_from_slot()
    self:_refresh_ui()
  end)
  self:add_evt_listener(EventID.OnOverlaySlotUpdated, function()
    if self._cur_ground_state == STATE_GROUND_ROAD then
      self:_init_multi_selected_from_slot()
      if self._is_precise and not is_null(self._scroll_load_list_multi) then
        self._scroll_load_list_multi:RefreshCurrent()
      end
    end
  end)
  self:add_evt_listener(EventID.OnDecalSlotUpdated, function()
    if self._cur_ground_state == STATE_GROUND_PATTERN then
      self:_init_multi_selected_from_slot()
      if self._is_precise and not is_null(self._scroll_pattern_list_multi) then
        self._scroll_pattern_list_multi:RefreshCurrent()
      end
    end
  end)
  self:add_evt_listener(EventID.OnDecalSetUnlocked, function()
    self:_load_pattern_data()
    if self._cur_ground_state == STATE_GROUND_PATTERN then
      self:_refresh_pattern_type_list()
      self:_refresh_pattern_list()
    end
  end)
end

function M:setup(config)
  self._is_precise = config and config.is_precise or false
  self._is_embedded = config and config.is_embedded or false
  self._drag_enabled = self._is_precise and self._is_embedded and self.holder ~= nil and self.holder.on_external_drag_begin ~= nil
  local default_tab = config and config.default_tab
  if default_tab == nil then
    default_tab = CsGroundSettingModuleUtil.GetCurBrushMode()
  end
  self._max_slot_count = CsGroundSettingModuleUtil.GetMaxSlotCount()
  if self._is_embedded then
    UIUtil.set_active(self._btn_bg, false)
    UIUtil.set_active(self._btn_back, false)
  end
  self:_init_multi_selected_from_slot()
  self:_apply_type_state()
  self:_refresh_road_data()
  self:_load_pattern_data()
  if self._is_precise then
    self:_sort_list_for_precise()
  end
  if default_tab == STATE_GROUND_PATTERN then
    self:_apply_tab_toggle(true)
    self:_switch_to_pattern_tab()
  else
    self:_apply_tab_toggle(false)
    self:_switch_to_road_tab()
  end
end

function M:get_cur_ground_state()
  return self._cur_ground_state
end

function M:_apply_tab_toggle(is_pattern)
  if is_pattern then
    if not is_null(self._tog_pattern) then
      self._tog_pattern:SetIsOnWithoutNotify(true)
    end
    if not is_null(self._tog_road) then
      self._tog_road:SetIsOnWithoutNotify(false)
    end
  else
    if not is_null(self._tog_road) then
      self._tog_road:SetIsOnWithoutNotify(true)
    end
    if not is_null(self._tog_pattern) then
      self._tog_pattern:SetIsOnWithoutNotify(false)
    end
  end
end

function M:switch_tab(tab)
  if tab == STATE_GROUND_PATTERN then
    self:_apply_tab_toggle(true)
    self:_switch_to_pattern_tab()
  else
    self:_apply_tab_toggle(false)
    self:_switch_to_road_tab()
  end
end

function M:_add_ui_listener()
  if not is_null(self._tog_road) then
    self:bind_callback(self._tog_road, pack(self, M._on_tog_road))
  end
  if not is_null(self._tog_pattern) then
    self:bind_callback(self._tog_pattern, pack(self, M._on_tog_pattern))
  end
end

function M:_apply_type_state()
  if not is_null(self._state_group_type) then
    local state = self._is_precise and STATE_TYPE_PRECISE or STATE_TYPE_NORMAL
    self._state_group_type:SetState(state)
  end
  UIUtil.set_active(self._scroll_load_list, not self._is_precise)
  UIUtil.set_active(self._scroll_load_list_multi, self._is_precise)
  self:_cache_scroll_rects()
end

function M:_cache_scroll_rects()
  self._road_multi_scroll_rect = nil
  self._pattern_multi_scroll_rect = nil
  if not is_null(self._scroll_load_list_multi) then
    self._road_multi_scroll_rect = self._scroll_load_list_multi:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
  end
  if not is_null(self._scroll_pattern_list_multi) then
    self._pattern_multi_scroll_rect = self._scroll_pattern_list_multi:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
  end
end

function M:get_active_scroll_rect()
  if self._cur_ground_state == STATE_GROUND_ROAD then
    return self._road_multi_scroll_rect
  else
    return self._pattern_multi_scroll_rect
  end
end

function M:_on_tog_road(is_on)
  if is_on then
    self:_switch_to_road_tab()
    if self._is_embedded and self.holder and self.holder.on_panel_tab_changed then
      self.holder:on_panel_tab_changed(STATE_GROUND_ROAD)
    end
  end
end

function M:_on_tog_pattern(is_on)
  if is_on then
    self:_switch_to_pattern_tab()
    if self._is_embedded and self.holder and self.holder.on_panel_tab_changed then
      self.holder:on_panel_tab_changed(STATE_GROUND_PATTERN)
    end
  end
end

function M:_switch_to_road_tab()
  if is_null(self._state_group_ground) then
    return
  end
  self._cur_ground_state = STATE_GROUND_ROAD
  self._state_group_ground:SetState(STATE_GROUND_ROAD)
  CsGroundSettingModuleUtil.SetCurBrushMode(STATE_GROUND_ROAD)
  self:_init_multi_selected_from_slot()
  if self._is_precise then
    self.select_cfg_id = self:_get_first_multi_selected() or 0
  else
    local cur_road = CsGroundSettingModuleUtil.GetCurRoadCfgId()
    self.select_cfg_id = cur_road or 0
  end
  self.select_index = 1
  if self.select_cfg_id and self.select_cfg_id > 0 then
    for i, cfg in ipairs(self._road_cfg_list) do
      if cfg.id == self.select_cfg_id then
        self.select_index = i + 1
        break
      end
    end
  end
  self:_apply_scroll_visibility()
  self:_refresh_road_list()
  self:_refresh_info()
end

function M:_switch_to_pattern_tab()
  if is_null(self._state_group_ground) then
    return
  end
  self._cur_ground_state = STATE_GROUND_PATTERN
  self._state_group_ground:SetState(STATE_GROUND_PATTERN)
  CsGroundSettingModuleUtil.SetCurBrushMode(STATE_GROUND_PATTERN)
  self:_init_multi_selected_from_slot()
  if self._is_precise then
    self.select_cfg_id = self:_get_first_multi_selected() or 0
  else
    local cur_decal = CsGroundSettingModuleUtil.GetCurDecalCfgId()
    self.select_cfg_id = cur_decal and 0 < cur_decal and cur_decal or 0
  end
  self:_navigate_to_selected_pattern_set()
  self.select_index = 1
  if self.select_cfg_id and self.select_cfg_id > 0 then
    for i, cfg in ipairs(self._pattern_cfg_list) do
      if cfg.decalid == self.select_cfg_id then
        self.select_index = i + 1
        break
      end
    end
  end
  self:_apply_scroll_visibility()
  self:_refresh_pattern_type_list()
  self:_refresh_pattern_list()
  self:_refresh_info()
end

function M:_apply_scroll_visibility()
  local is_road = self._cur_ground_state == STATE_GROUND_ROAD
  local is_pattern = not is_road
  if self._is_precise then
    UIUtil.set_active(self._scroll_load_list, false)
    UIUtil.set_active(self._scroll_load_list_multi, is_road)
    UIUtil.set_active(self._scroll_pattern_list, false)
    UIUtil.set_active(self._scroll_pattern_list_multi, is_pattern)
  else
    UIUtil.set_active(self._scroll_load_list, is_road)
    UIUtil.set_active(self._scroll_load_list_multi, false)
    UIUtil.set_active(self._scroll_pattern_list, is_pattern)
    UIUtil.set_active(self._scroll_pattern_list_multi, false)
  end
end

function M:_refresh_ui()
  self:_refresh_road_data()
  self:_load_pattern_data()
  if self._cur_ground_state == STATE_GROUND_ROAD then
    self:_refresh_road_list()
  else
    self:_refresh_pattern_type_list()
    self:_refresh_pattern_list()
  end
  self:_refresh_info()
end

function M:_refresh_road_data()
  self._road_cfg_list = {}
  local ids = list_to_table(CsGroundSettingModuleUtil.GetAllUnLockUgcGridStyles())
  for i, id in ipairs(ids) do
    self._road_cfg_list[i] = ExcelDataUtil.get_value(typeof(BRoadCfg), id)
  end
  table.sort(self._road_cfg_list, function(a, b)
    return a.roadindex < b.roadindex
  end)
  self.select_index = 1
  if self.select_cfg_id and self.select_cfg_id > 0 then
    for i, cfg in ipairs(self._road_cfg_list) do
      if cfg.id == self.select_cfg_id then
        self.select_index = i + 1
        break
      end
    end
  end
end

function M:_refresh_road_list()
  if self._is_precise then
    self:_refresh_road_list_multi()
  else
    self:_refresh_road_list_single()
  end
end

function M:_refresh_road_list_single()
  if is_null(self._scroll_load_list) then
    return
  end
  local count = #self._road_cfg_list + 1
  if not self._single_list_inited then
    self._single_list_inited = true
    self._scroll_load_list:Init(pack(self, M._on_refresh_single_item), count)
  else
    self._scroll_load_list:ReLoad(pack(self, M._on_refresh_single_item), count)
  end
end

function M:_on_refresh_single_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local item = self._single_item_map[instance_id]
  if not item then
    item = self:add_panel(SINGLE_ITEM_CLS, trans)
    self._single_item_map[instance_id] = item
  end
  if index == 1 then
  end
  local cfg = self._road_cfg_list[index - 1]
  item:refresh(index, cfg)
end

function M:_refresh_road_list_multi()
  if is_null(self._scroll_load_list_multi) then
    return
  end
  if not self._multi_list_inited then
    self._multi_list_inited = true
    self._scroll_load_list_multi:Init(pack(self, M._on_refresh_multi_item), #self._road_cfg_list)
  else
    self._scroll_load_list_multi:ReLoad(pack(self, M._on_refresh_multi_item), #self._road_cfg_list)
  end
end

function M:_on_refresh_multi_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local item = self._multi_item_map[instance_id]
  if not item then
    item = self:add_panel(MULTI_ITEM_CLS, trans)
    self._multi_item_map[instance_id] = item
  end
  item:refresh(index, self._road_cfg_list[index])
end

function M:_load_pattern_data()
  self._pattern_set_list = {}
  self._all_decal_cfgs = {}
  local unlocked_set_ids = list_to_table(CsGroundSettingModuleUtil.GetAllUnLockDecalSets())
  local unlocked_set_map = {}
  for _, id in ipairs(unlocked_set_ids) do
    unlocked_set_map[id] = true
  end
  local set_table = ExcelDataUtil.get_table(typeof(BDecalSetCfg))
  if set_table then
    for _, set_cfg in pairs(set_table) do
      if unlocked_set_map[set_cfg.decalsetid] then
        table.insert(self._pattern_set_list, set_cfg)
      end
    end
    table.sort(self._pattern_set_list, function(a, b)
      return a.decalsetid < b.decalsetid
    end)
  end
  local decal_table = ExcelDataUtil.get_table(typeof(BDecalCfg))
  if decal_table then
    for _, cfg in pairs(decal_table) do
      local set_id = cfg.decalsetid
      if unlocked_set_map[set_id] then
        if not self._all_decal_cfgs[set_id] then
          self._all_decal_cfgs[set_id] = {}
        end
        table.insert(self._all_decal_cfgs[set_id], cfg)
      end
    end
    for _, list in pairs(self._all_decal_cfgs) do
      table.sort(list, function(a, b)
        return a.decalid < b.decalid
      end)
    end
  end
  if self._cur_pattern_set_id == 0 and #self._pattern_set_list > 0 then
    self._cur_pattern_set_id = self._pattern_set_list[1].decalsetid
  end
  self:_build_pattern_cfg_list()
end

function M:_build_pattern_cfg_list()
  self._pattern_cfg_list = self._all_decal_cfgs[self._cur_pattern_set_id] or {}
end

function M:_sort_list_for_precise()
  local selected = self._multi_selected_ids
  table.sort(self._road_cfg_list, function(a, b)
    local a_sel = selected[a.id] and 1 or 0
    local b_sel = selected[b.id] and 1 or 0
    if a_sel ~= b_sel then
      return a_sel > b_sel
    end
    return a.id < b.id
  end)
  for set_id, list in pairs(self._all_decal_cfgs) do
    table.sort(list, function(a, b)
      local a_sel = selected[a.decalid] and 1 or 0
      local b_sel = selected[b.decalid] and 1 or 0
      if a_sel ~= b_sel then
        return a_sel > b_sel
      end
      return a.decalid < b.decalid
    end)
  end
  self:_build_pattern_cfg_list()
end

function M:on_select_pattern_set(set_id)
  if self._cur_pattern_set_id == set_id then
    return
  end
  self._cur_pattern_set_id = set_id
  self:_build_pattern_cfg_list()
  if #self._pattern_cfg_list > 0 then
    self.select_cfg_id = self._pattern_cfg_list[1].decalid
  else
    self.select_cfg_id = 0
  end
  self:_refresh_pattern_list()
  self:_refresh_info()
end

function M:_refresh_pattern_type_list()
  if is_null(self._scroll_pattern_type_list) then
    return
  end
  if not self._pattern_type_inited then
    self._pattern_type_inited = true
    self._scroll_pattern_type_list:Init(pack(self, M._on_refresh_pattern_type_item), #self._pattern_set_list)
  else
    self._scroll_pattern_type_list:ReLoad(pack(self, M._on_refresh_pattern_type_item), #self._pattern_set_list)
  end
end

function M:_on_refresh_pattern_type_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local item = self._pattern_type_item_map[instance_id]
  if not item then
    item = self:add_panel(PATTERN_TYPE_ITEM_CLS, trans)
    self._pattern_type_item_map[instance_id] = item
  end
  item:refresh(index, self._pattern_set_list[index])
end

function M:_refresh_pattern_list()
  if self._is_precise then
    self:_refresh_pattern_list_multi()
  else
    self:_refresh_pattern_list_single()
  end
end

function M:_refresh_pattern_list_single()
  if is_null(self._scroll_pattern_list) then
    return
  end
  local count = #self._pattern_cfg_list + 1
  if not self._pattern_single_inited then
    self._pattern_single_inited = true
    self._scroll_pattern_list:Init(pack(self, M._on_refresh_pattern_single_item), count)
  else
    self._scroll_pattern_list:ReLoad(pack(self, M._on_refresh_pattern_single_item), count)
  end
end

function M:_on_refresh_pattern_single_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local item = self._pattern_single_item_map[instance_id]
  if not item then
    item = self:add_panel(PATTERN_SINGLE_ITEM_CLS, trans)
    self._pattern_single_item_map[instance_id] = item
  end
  if index == 1 then
  end
  local cfg = self._pattern_cfg_list[index - 1]
  item:refresh(index, cfg)
end

function M:_refresh_pattern_list_multi()
  if is_null(self._scroll_pattern_list_multi) then
    return
  end
  if not self._pattern_multi_inited then
    self._pattern_multi_inited = true
    self._scroll_pattern_list_multi:Init(pack(self, M._on_refresh_pattern_multi_item), #self._pattern_cfg_list)
  else
    self._scroll_pattern_list_multi:ReLoad(pack(self, M._on_refresh_pattern_multi_item), #self._pattern_cfg_list)
  end
end

function M:_on_refresh_pattern_multi_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  local item = self._pattern_multi_item_map[instance_id]
  if not item then
    item = self:add_panel(PATTERN_MULTI_ITEM_CLS, trans)
    self._pattern_multi_item_map[instance_id] = item
  end
  item:refresh(index, self._pattern_cfg_list[index])
end

function M:refresh_select_slot(index, cfg_id)
  self.select_cfg_id = cfg_id
  self.select_index = index
  if self._cur_ground_state == STATE_GROUND_ROAD then
    if not is_null(self._scroll_load_list) then
      self._scroll_load_list:RefreshCurrent()
    end
  elseif not is_null(self._scroll_pattern_list) then
    self._scroll_pattern_list:RefreshCurrent()
  end
  self:_refresh_info()
end

function M:toggle_multi_select(cfg_id)
  if self._multi_selected_ids[cfg_id] then
    self._multi_selected_ids[cfg_id] = nil
    if self._cur_ground_state == STATE_GROUND_ROAD then
      CsGroundSettingModuleUtil.RemoveOverlaySlot(cfg_id)
      CsGroundSettingModuleUtil.SendOverlaySlotUpdateReq()
    else
      CsGroundSettingModuleUtil.RemoveDecalSlot(cfg_id)
      CsGroundSettingModuleUtil.SendDecalSlotUpdateReq()
    end
  else
    local count = 0
    for _ in pairs(self._multi_selected_ids) do
      count = count + 1
    end
    if count >= self._max_slot_count then
      return
    end
    self._multi_selected_ids[cfg_id] = true
    if self._cur_ground_state == STATE_GROUND_ROAD then
      CsGroundSettingModuleUtil.AddOverlaySlot(cfg_id)
      CsGroundSettingModuleUtil.SendOverlaySlotUpdateReq()
    else
      CsGroundSettingModuleUtil.AddDecalSlot(cfg_id)
      CsGroundSettingModuleUtil.SendDecalSlotUpdateReq()
    end
  end
  if self._cur_ground_state == STATE_GROUND_ROAD then
    if not is_null(self._scroll_load_list_multi) then
      self._scroll_load_list_multi:RefreshCurrent()
    end
  elseif not is_null(self._scroll_pattern_list_multi) then
    self._scroll_pattern_list_multi:RefreshCurrent()
  end
  self.select_cfg_id = cfg_id
  self:_refresh_info()
end

function M:is_multi_selected(cfg_id)
  return self._multi_selected_ids[cfg_id] == true
end

function M:_init_multi_selected_from_slot()
  self._multi_selected_ids = {}
  local slot_list
  if self._cur_ground_state == STATE_GROUND_PATTERN then
    slot_list = list_to_table(CsGroundSettingModuleUtil.GetDecalSlotList())
  else
    slot_list = list_to_table(CsGroundSettingModuleUtil.GetOverlaySlotList())
  end
  if slot_list then
    for _, id in ipairs(slot_list) do
      self._multi_selected_ids[id] = true
    end
  end
end

function M:_get_first_multi_selected()
  local slot_list
  if self._cur_ground_state == STATE_GROUND_PATTERN then
    slot_list = list_to_table(CsGroundSettingModuleUtil.GetDecalSlotList())
  else
    slot_list = list_to_table(CsGroundSettingModuleUtil.GetOverlaySlotList())
  end
  if slot_list and 0 < #slot_list then
    return slot_list[1]
  end
  return nil
end

function M:_navigate_to_selected_pattern_set()
  if not self.select_cfg_id or self.select_cfg_id <= 0 then
    return
  end
  local cfg = ExcelDataUtil.get_value(typeof(BDecalCfg), self.select_cfg_id)
  if cfg and cfg.decalsetid and 0 < cfg.decalsetid then
    self._cur_pattern_set_id = cfg.decalsetid
    self:_build_pattern_cfg_list()
  end
end

function M:_refresh_info()
  if self._cur_ground_state == STATE_GROUND_ROAD then
    self:_refresh_road_info()
  else
    self:_refresh_pattern_info()
  end
end

function M:_refresh_road_info()
  local cfg
  if self.select_cfg_id and self.select_cfg_id > 0 then
    cfg = ExcelDataUtil.get_value(typeof(BRoadCfg), self.select_cfg_id)
  end
  UIUtil.set_active(self._trans_info_group, true)
  UIUtil.set_active(self._txt_land_desc_dynamic, true)
  if cfg then
    UIUtil.set_image(self._img_land_dynamic, cfg.icon, self:get_load_proxy())
    UIUtil.set_text(self._txt_land_name_dynamic, cfg.name)
    local plantable_id = cfg.mapcelltype == MAP_CELL_TYPE_LAND and "GroundPlantable" or "GroundNotPlantable"
    UIUtil.set_text_by_id(self._txt_land_desc_dynamic, plantable_id)
  else
    UIUtil.set_image(self._img_land_dynamic, "UISprite/Load/Ground/Icon_GroundSetting_xiangpica", self:get_load_proxy())
    UIUtil.set_text_by_id(self._txt_land_name_dynamic, "GroundEraser")
    UIUtil.set_text(self._txt_land_desc_dynamic, "")
  end
end

function M:_refresh_pattern_info()
  local cfg
  if self.select_cfg_id and self.select_cfg_id > 0 then
    cfg = ExcelDataUtil.get_value(typeof(BDecalCfg), self.select_cfg_id)
  end
  UIUtil.set_active(self._trans_info_group, true)
  UIUtil.set_active(self._txt_land_desc_dynamic, false)
  if cfg then
    UIUtil.set_image(self._img_land_dynamic, cfg.icon, self:get_load_proxy())
    UIUtil.set_text(self._txt_land_name_dynamic, cfg.name)
  else
    UIUtil.set_image(self._img_land_dynamic, "UISprite/Load/Ground/Icon_GroundSetting_xiangpica", self:get_load_proxy())
    UIUtil.set_text_by_id(self._txt_land_name_dynamic, "GroundEraser")
  end
end

function M:on_item_drag_begin(cfg_id, icon, screen_pos)
  self._is_item_dragging = true
  self._drag_cfg_id = cfg_id
  if self.holder and self.holder.on_external_drag_begin then
    self.holder:on_external_drag_begin(cfg_id, icon, screen_pos)
  end
end

function M:on_item_drag(screen_pos)
  if not self._is_item_dragging then
    return
  end
  if self.holder and self.holder.on_external_drag then
    self.holder:on_external_drag(screen_pos)
  end
end

function M:on_item_drag_end(screen_pos)
  if not self._is_item_dragging then
    return
  end
  self._is_item_dragging = false
  if self.holder and self.holder.on_external_drop then
    self.holder:on_external_drop(self._drag_cfg_id, screen_pos)
  end
  self._drag_cfg_id = 0
end

function M:on_item_drag_cancel()
  if not self._is_item_dragging then
    return
  end
  self._is_item_dragging = false
  self._drag_cfg_id = 0
  if self.holder and self.holder.on_external_drag_cancel then
    self.holder:on_external_drag_cancel()
  end
end

return M
