local M = G.Class("MuseumLivingthingShowPage", G.UIWindow)
local base = G.UIWindow
local livingthing_item_class = "UI/Museum/MuseumLivingthingShowItem"
local editor_page_class = "UI/Museum/MuseumLivingthingShowEditorPage"
local arrow_hint_scene_type = scene_ui_manager.SceneType.MuseumArrow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Museum/UI_Museum_LivingthingShowPanel"
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
end

function M:on_create()
  base.on_create(self)
  self._item_cfgs = ExcelDataUtil.get_table(typeof(BItemCfg)) or {}
  self._items = {}
  self._exhibit_info = {}
  self._sorted_exhibits = {}
  self._selected_config_id = nil
  self._is_tank_camera_pushed = false
  self._is_display_camera_pushed = false
  self._camera_area_id = nil
  UIUtil.set_active(self._obj_item, false)
  self:_add_btn_listener()
end

function M:on_open()
  base.on_open(self)
  self._interact_id = self:get_extra_data()
  CsUIUtil.HideOrShowAllAvatar(false, 0.1, true)
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  self._handbook_dic = dic_to_table(CsGalleryModuleUtil.HandbookDic)
  self:_build_area_list()
  self:_refresh_area()
  self:_set_ui_hidden(false)
end

function M:on_disable()
  base.on_disable(self)
  self:_pop_display_camera()
  self._arrow_token = (self._arrow_token or 0) + 1
  scene_ui_manager:close_scene(arrow_hint_scene_type)
end

function M:on_close()
  base.on_close(self)
  self:_pop_display_camera()
  self:_pop_tank_camera()
  CsUIUtil.HideOrShowAllAvatar(true, 0.1, true)
end

function M:on_before_close()
  base.on_before_close(self)
  if self._is_play_anim and self:get_cur_ui_state() == EUIState.Show then
    self:stop_playing_anim(true)
  end
end

function M:_add_btn_listener()
  self:bind_callback(self._btn_close_normal, function()
    self:_on_btn_close_click()
  end)
  self:bind_callback(self._btn_hide, function()
    self:_set_ui_hidden(not self._is_ui_hidden)
  end)
  self:bind_callback(self._btn_arrow_left, function()
    self:_switch_area(-1)
  end)
  self:bind_callback(self._btn_arrow_right, function()
    self:_switch_area(1)
  end)
  if not_null(self._btn_editor) then
    self:bind_callback(self._btn_editor, function()
      UIManagerInstance:open(editor_page_class, self._interact_id)
    end)
  end
end

function M:_on_btn_close_click()
  if self._is_close then
    return
  end
  self._is_close = true
  self:close_self()
end

function M:_set_ui_hidden(is_hidden)
  self._is_ui_hidden = is_hidden
  UIUtil.set_active(self._trans_all, not is_hidden)
  UIUtil.set_active(self._trans_btn_close, not is_hidden)
end

function M:_pop_tank_camera()
  if not self._is_tank_camera_pushed then
    return
  end
  CsGameplayUtilitiesCameraUtil.PopState("GalleryTank")
  self._is_tank_camera_pushed = false
  self._camera_area_id = nil
end

function M:_pop_display_camera()
  if not self._is_display_camera_pushed then
    return
  end
  CsGameplayUtilitiesCameraUtil.PopState("GalleryDisplay")
  self._is_display_camera_pushed = false
end

function M:_build_area_list()
  self._area_interact_ids = {
    self._interact_id
  }
  self._area_index = 1
  local interact_cfgs = ExcelDataUtil.get_table(typeof(BDonateInteractCfg)) or {}
  local cur_cfg = interact_cfgs[self._interact_id]
  if is_null(cur_cfg) then
    return
  end
  local ids = {}
  for interact_id, cfg in pairs(interact_cfgs) do
    if cfg.galleryid == cur_cfg.galleryid and cfg.boardtype == cur_cfg.boardtype and cfg.slottype1 == cur_cfg.slottype1 and self:_is_area_in_scene(interact_id) then
      table.insert(ids, interact_id)
    end
  end
  table.sort(ids)
  self._area_interact_ids = ids
  for i, interact_id in ipairs(ids) do
    if interact_id == self._interact_id then
      self._area_index = i
      break
    end
  end
end

function M:_is_area_in_scene(interact_id)
  if interact_id == self._interact_id then
    return true
  end
  return not is_null(CsGalleryModuleUtil.CreatureTanks[interact_id])
end

function M:_switch_area(offset)
  local count = #self._area_interact_ids
  if count <= 1 then
    return
  end
  self._area_index = (self._area_index - 1 + offset) % count + 1
  self._interact_id = self._area_interact_ids[self._area_index]
  self:_pop_display_camera()
  self:_refresh_area()
end

function M:_refresh_area()
  self:_get_exhibit_info()
  self:_sort_exhibits()
  self:_set_area_info()
  self:_set_camera_to_exhibit()
  self:_refresh_exhibit_list()
  self:_set_select(nil)
end

function M:_get_exhibit_info()
  self._exhibit_info = {}
  self._donate_type_ids = {}
  self._slot_count = 0
  self._interact_cfg = ExcelDataUtil.get_value(typeof(BDonateInteractCfg), self._interact_id)
  if is_null(self._interact_cfg) then
    Logger.LogWarning("Failed to get interaction configuration for ID: " .. tostring(self._interact_id))
    return
  end
  self._donate_type_ids = self:_parse_slot_type(self._interact_cfg.slottype1)
  self._gallery_id = self._interact_cfg.galleryid
  self._slot_count = self._interact_cfg.slotcount or 0
  local cached_exhibits = dic_to_table(CsGalleryModuleUtil.CachedExhibitLookUpDic)
  if cached_exhibits[self._interact_id] then
    for _, slots in pairs(cached_exhibits[self._interact_id]) do
      for _, exhibit in pairs(slots) do
        if exhibit and exhibit.itemCfgId then
          self._exhibit_info[exhibit.itemCfgId] = exhibit.displayGuidList and list_to_table(exhibit.displayGuidList) or {}
        end
      end
    end
  end
end

function M:_parse_slot_type(slot_type_str)
  local result = {}
  if slot_type_str and slot_type_str ~= "" then
    for id_str in string.gmatch(slot_type_str, "([^;]+)") do
      local id = tonumber(id_str)
      if id then
        table.insert(result, id)
      end
    end
  end
  return result
end

function M:_sort_exhibits()
  self._sorted_exhibits = {}
  for config_id, _ in pairs(self._exhibit_info) do
    if self._item_cfgs[config_id] then
      table.insert(self._sorted_exhibits, config_id)
    end
  end
  table.sort(self._sorted_exhibits, function(a, b)
    return self:_compare_exhibits(a, b)
  end)
end

function M:_compare_exhibits(id_a, id_b)
  local rank_a = self._item_cfgs[id_a] and self._item_cfgs[id_a].rank or 0
  local rank_b = self._item_cfgs[id_b] and self._item_cfgs[id_b].rank or 0
  if rank_a ~= rank_b then
    return rank_a > rank_b
  end
  local time_a = self._handbook_dic[id_a] and self._handbook_dic[id_a].Time or 0
  local time_b = self._handbook_dic[id_b] and self._handbook_dic[id_b].Time or 0
  return time_a > time_b
end

function M:_set_area_info()
  local area_name = not is_null(self._interact_cfg) and self._interact_cfg.name or ""
  UIUtil.set_text(self._txt_area_name, area_name)
  UIUtil.set_text(self._txt_area_limit, string.format("%d/%d", #self._sorted_exhibits, self._slot_count))
  local can_switch = #self._area_interact_ids > 1
  UIUtil.set_active(self._btn_arrow_left, can_switch)
  UIUtil.set_active(self._btn_arrow_right, can_switch)
end

function M:_refresh_exhibit_list()
  for i = 1, #self._sorted_exhibits do
    local config_id = self._sorted_exhibits[i]
    local item = self:_get_or_create_item(i)
    item:refresh({
      config_id = config_id,
      item_cfg = self._item_cfgs[config_id],
      star_level = self:_get_star_level(config_id),
      on_click = function(clicked_id, is_select)
        self:_on_item_click(clicked_id, is_select)
      end
    })
  end
  for i = #self._sorted_exhibits + 1, #self._items do
    UIUtil.set_active(self._items[i].trans, false)
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(self._trans_parent)
end

function M:_get_or_create_item(index)
  local item = self._items[index]
  if not item then
    local go = UIUtil.load_prefab_set_parent(self._obj_item, self._trans_parent)
    item = self:add_panel(livingthing_item_class, go.transform)
    self._items[index] = item
  end
  UIUtil.set_active(item.trans, true)
  item.trans:SetAsLastSibling()
  return item
end

function M:_get_star_level(config_id)
  local entity_handbook = self._handbook_dic[config_id]
  return entity_handbook and entity_handbook.StarLevel or 0
end

function M:_on_item_click(config_id, is_select)
  self:_set_select(is_select and config_id or nil)
end

function M:_set_select(config_id)
  self._selected_config_id = config_id
  for _, item in ipairs(self._items) do
    item:set_select(config_id ~= nil and item:get_config_id() == config_id)
  end
  UIUtil.set_active(self._trans_item_desc, config_id ~= nil)
  UIUtil.set_active(self._trans_item_desc_bg, config_id ~= nil)
  self:_pop_display_camera()
  self:_refresh_arrow_hint(config_id)
  if config_id == nil then
    return
  end
  local has_desc = self:_refresh_item_desc(config_id)
  UIUtil.set_active(self._trans_item_desc_bg, has_desc)
  self:_set_camera_to_exhibit_item(config_id)
end

function M:_refresh_arrow_hint(config_id)
  self._arrow_token = (self._arrow_token or 0) + 1
  local token = self._arrow_token
  local guid = self:_get_creature_guid(config_id)
  if guid == nil then
    local scene = scene_ui_manager:get_opened_scene(arrow_hint_scene_type)
    if scene ~= nil then
      scene:set_hint(nil)
    end
    return
  end
  scene_ui_manager:open_scene(arrow_hint_scene_type, {guid = guid}, function(scene)
    if token ~= self._arrow_token then
      return
    end
    scene:set_hint(guid)
  end)
end

function M:_get_creature_guid(config_id)
  if config_id == nil or not self._exhibit_info[config_id] then
    return nil
  end
  local tank = CsGalleryModuleUtil.CreatureTanks[self._interact_id]
  if is_null(tank) then
    return nil
  end
  local creature_entity = tank:GetCreatureEntityByConfigId(config_id)
  if is_null(creature_entity) or not creature_entity.IsValid then
    return nil
  end
  return creature_entity.Guid
end

function M:_refresh_item_desc(config_id)
  local codex_cfg = ExcelDataUtil.get_value(typeof(BCodexCfg), config_id)
  local desc = not is_null(codex_cfg) and codex_cfg.codexdes or ""
  UIUtil.set_text(self._txt_item_desc, desc)
  return desc ~= nil and desc ~= ""
end

function M:_set_camera_to_exhibit()
  if self._is_tank_camera_pushed and self._camera_area_id == self._interact_id then
    return
  end
  local interact_trans = self:_find_interaction_point_transform()
  if is_null(interact_trans) then
    return
  end
  local cam_point_trans = UIUtil.find_trans(interact_trans, "CameraPoint")
  if is_null(cam_point_trans) then
    return
  end
  if self._is_tank_camera_pushed then
    CsGameplayUtilitiesCameraUtil.PopState("GalleryTank")
  end
  CsGameplayUtilitiesCameraUtil.PushStateAndSetTargetByTransform("GalleryTank", cam_point_trans, cam_point_trans)
  self._is_tank_camera_pushed = true
  self._camera_area_id = self._interact_id
end

function M:_find_interaction_point_transform()
  local tank = CsGalleryModuleUtil.CreatureTanks[self._interact_id]
  if tank and tank.GetTransform then
    return tank:GetTransform()
  end
  return nil
end

function M:_set_camera_to_exhibit_item(config_id)
  if not config_id or not self._exhibit_info[config_id] then
    return
  end
  local tank = CsGalleryModuleUtil.CreatureTanks[self._interact_id]
  if tank then
    local creature_entity = tank:GetCreatureEntityByConfigId(config_id)
    local cam_point_trans = UIUtil.find_trans(tank.transform, "CameraPoint")
    if not is_null(creature_entity) and not is_null(cam_point_trans) and creature_entity.IsValid then
      CsGameplayUtilitiesCameraUtil.PushGalleryDisplayState(creature_entity, cam_point_trans.rotation)
      self._is_display_camera_pushed = true
    end
  end
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Esc, self._btn_close_normal)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close_normal)
end

return M
