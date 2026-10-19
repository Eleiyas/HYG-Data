local M = G.Class("MuseumLivingthingShowEditorPage", G.UIWindow)
local base = G.UIWindow
local editor_item_class = "UI/Museum/MuseumLivingthingShowEditorItem"
local arrow_hint_scene_type = scene_ui_manager.SceneType.MuseumArrow
local TIER_CUR_AREA = 1
local TIER_OTHER_AREA = 2
local TIER_NOT_EXHIBITED = 3

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Museum/UI_Museum_LivingthingShowEditorPanel"
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
end

function M:on_create()
  base.on_create(self)
  self._item_cfgs = ExcelDataUtil.get_table(typeof(BItemCfg)) or {}
  self._items = {}
  self._creatures = {}
  self._exhibit_area_map = {}
  self._cur_area_exhibits = {}
  self._selected_config_id = nil
  self._is_display_camera_pushed = false
  self._camera_area_id = nil
  self._waiting_set_display = false
  self._set_display_token = 0
  self._is_auto_display = true
  self._waiting_auto_display = false
  self._auto_display_token = 0
  self._trans_parent = not_null(self._obj_item) and self._obj_item.transform.parent or nil
  UIUtil.set_active(self._obj_item, false)
  self:_add_btn_listener()
end

function M:on_enable()
  base.on_enable(self)
  self._is_close = false
  self._interact_id = self:get_extra_data()
  self._camera_area_id = self._interact_id
  self._handbook_dic = dic_to_table(CsGalleryModuleUtil.HandbookDic)
  self:_build_area_list()
  self:_get_area_info()
  self:_build_creature_pool()
  self:_refresh_area()
  self:_refresh_auto_display()
  self:_set_ui_hidden(false)
end

function M:on_disable()
  base.on_disable(self)
  self._set_display_token = (self._set_display_token or 0) + 1
  self._waiting_set_display = false
  self._auto_display_token = (self._auto_display_token or 0) + 1
  self._waiting_auto_display = false
  self._arrow_token = (self._arrow_token or 0) + 1
  scene_ui_manager:close_scene(arrow_hint_scene_type)
end

function M:on_close()
  base.on_close(self)
  self:_pop_display_state()
end

function M:on_before_close()
  base.on_before_close(self)
  if self._is_play_anim and self:get_cur_ui_state() == EUIState.Show then
    self:stop_playing_anim(true)
  end
end

function M:_add_btn_listener()
  self:bind_callback(self._btn_close, function()
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
  self:bind_callback(self._tog_switch, pack(self, M._on_auto_display_click))
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
  UIUtil.set_active(self._trans_safearea, not is_hidden)
  UIUtil.set_active(self._trans_btn_close, not is_hidden)
  UIUtil.set_active(self._trans_tog_switch, not is_hidden)
end

function M:_build_area_list()
  self._area_interact_ids = {
    self._interact_id
  }
  self._area_index = 1
  self._area_group_id = nil
  local interact_cfgs = ExcelDataUtil.get_table(typeof(BDonateInteractCfg)) or {}
  local cur_cfg = interact_cfgs[self._interact_id]
  if is_null(cur_cfg) then
    return
  end
  local ids = {}
  for interact_id, cfg in pairs(interact_cfgs) do
    if cfg.galleryid == cur_cfg.galleryid and cfg.boardtype == cur_cfg.boardtype and cfg.slottype1 == cur_cfg.slottype1 then
      if self._area_group_id == nil or interact_id < self._area_group_id then
        self._area_group_id = interact_id
      end
      if self:_is_area_in_scene(interact_id) then
        table.insert(ids, interact_id)
      end
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

function M:_get_auto_display_group_id()
  return self._area_group_id or self._interact_id
end

function M:_switch_area(offset)
  local count = #self._area_interact_ids
  if count <= 1 then
    return
  end
  self._area_index = (self._area_index - 1 + offset) % count + 1
  self._interact_id = self._area_interact_ids[self._area_index]
  self:_pop_display_state()
  self._selected_config_id = nil
  self:_refresh_area()
end

function M:_refresh_area()
  self:_get_area_info()
  self:_collect_exhibit_state()
  self:_sort_creatures()
  self:_set_area_info()
  self:_pop_display_state()
  self:_set_camera_to_exhibit()
  self:_refresh_creature_list()
  self:_set_select(nil)
end

function M:_get_area_info()
  self._donate_type_ids = {}
  self._slot_count = 0
  self._interact_cfg = ExcelDataUtil.get_value(typeof(BDonateInteractCfg), self._interact_id)
  if is_null(self._interact_cfg) then
    Logger.LogWarning("Failed to get interaction configuration for ID: " .. tostring(self._interact_id))
    return
  end
  self._donate_type_ids = self:_parse_slot_type(self._interact_cfg.slottype1)
  self._slot_count = self._interact_cfg.slotcount or 0
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

function M:_build_creature_pool()
  self._creatures = {}
  for _, donated_item in pairs(dic_to_table(CsGalleryModuleUtil.OwnerDonatedItems)) do
    local config_id = donated_item.itemCfgId
    local donation_cfg = ExcelDataUtil.get_value(typeof(BDonationCfg), config_id)
    if not is_null(donation_cfg) and self:_is_cur_donate_type(donation_cfg.donatetypeid) then
      local item_cfg = self._item_cfgs[config_id]
      table.insert(self._creatures, {
        config_id = config_id,
        rank = item_cfg and item_cfg.rank or 0,
        star_level = self:_get_star_level(config_id),
        is_variant = 0 < (donated_item.colorVariantId or 0),
        donate_time = donated_item.timestamp or 0,
        tier = TIER_NOT_EXHIBITED
      })
    end
  end
end

function M:_collect_exhibit_state()
  self._exhibit_area_map = {}
  self._cur_area_exhibits = {}
  self._cur_area_count = 0
  local cached_exhibits = dic_to_table(CsGalleryModuleUtil.CachedExhibitLookUpDic)
  for interact_id, area_dic in pairs(cached_exhibits) do
    local is_cur_area = interact_id == self._interact_id
    for _, slot_dic in pairs(area_dic) do
      for _, exhibit_info in pairs(slot_dic) do
        local exhibit_cfg_id = exhibit_info and exhibit_info.itemCfgId
        if exhibit_cfg_id and self._item_cfgs[exhibit_cfg_id] then
          if is_cur_area then
            if not self._cur_area_exhibits[exhibit_cfg_id] then
              self._cur_area_exhibits[exhibit_cfg_id] = true
              self._cur_area_count = self._cur_area_count + 1
            end
            self._exhibit_area_map[exhibit_cfg_id] = interact_id
          elseif self._exhibit_area_map[exhibit_cfg_id] == nil then
            self._exhibit_area_map[exhibit_cfg_id] = interact_id
          end
        end
      end
    end
  end
end

function M:_is_cur_donate_type(donate_type_id)
  for _, id in ipairs(self._donate_type_ids) do
    if id == donate_type_id then
      return true
    end
  end
  return false
end

function M:_update_creature_tiers()
  for _, info in ipairs(self._creatures) do
    if self._cur_area_exhibits[info.config_id] then
      info.tier = TIER_CUR_AREA
    elseif self._exhibit_area_map[info.config_id] ~= nil then
      info.tier = TIER_OTHER_AREA
    else
      info.tier = TIER_NOT_EXHIBITED
    end
  end
end

function M:_sort_creatures()
  self:_update_creature_tiers()
  table.sort(self._creatures, function(a, b)
    return self:_compare_creatures(a, b)
  end)
end

function M:_compare_creatures(info_a, info_b)
  if info_a.tier ~= info_b.tier then
    return info_a.tier < info_b.tier
  end
  if info_a.rank ~= info_b.rank then
    return info_a.rank > info_b.rank
  end
  if info_a.star_level ~= info_b.star_level then
    return info_a.star_level > info_b.star_level
  end
  if info_a.is_variant ~= info_b.is_variant then
    return info_a.is_variant
  end
  if info_a.donate_time ~= info_b.donate_time then
    return info_a.donate_time > info_b.donate_time
  end
  return info_a.config_id < info_b.config_id
end

function M:_set_area_info()
  UIUtil.set_text(self._txt_area_name, self:_get_area_title(self._interact_id))
  UIUtil.set_text(self._txt_area_limit, string.format("%d/%d", self._cur_area_count, self._slot_count))
  local can_switch = #self._area_interact_ids > 1
  UIUtil.set_active(self._btn_arrow_left, can_switch)
  UIUtil.set_active(self._btn_arrow_right, can_switch)
end

function M:_get_area_title(interact_id)
  local interact_cfg = ExcelDataUtil.get_value(typeof(BDonateInteractCfg), interact_id)
  if is_null(interact_cfg) then
    return ""
  end
  return string.is_valid(interact_cfg.name) and interact_cfg.name or ""
end

function M:_get_area_name(interact_id)
  local interact_cfg = ExcelDataUtil.get_value(typeof(BDonateInteractCfg), interact_id)
  if is_null(interact_cfg) then
    return ""
  end
  if string.is_valid(interact_cfg.subname) then
    return interact_cfg.subname
  end
  return string.is_valid(interact_cfg.name) and interact_cfg.name or ""
end

function M:_refresh_creature_list()
  for i = 1, #self._creatures do
    local info = self._creatures[i]
    local config_id = info.config_id
    local item = self:_get_or_create_item(i)
    item:refresh({
      config_id = config_id,
      item_cfg = self._item_cfgs[config_id],
      star_level = info.star_level,
      is_exhibited = info.tier ~= TIER_NOT_EXHIBITED,
      area_name = self:_get_item_area_name(info),
      on_click = function(clicked_id, is_select)
        self:_on_item_click(clicked_id, is_select)
      end,
      on_checkbox_click = function(clicked_id)
        self:_on_checkbox_click(clicked_id)
      end
    })
  end
  for i = #self._creatures + 1, #self._items do
    UIUtil.set_active(self._items[i].trans, false)
  end
  if not_null(self._trans_parent) then
    LayoutRebuilder.ForceRebuildLayoutImmediate(self._trans_parent)
  end
end

function M:_get_item_area_name(info)
  if info.tier ~= TIER_OTHER_AREA then
    return nil
  end
  return self:_get_area_name(self._exhibit_area_map[info.config_id])
end

function M:_get_or_create_item(index)
  local item = self._items[index]
  if not item then
    local go = UIUtil.load_prefab_set_parent(self._obj_item, self._trans_parent)
    item = self:add_panel(editor_item_class, go.transform)
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
  self:_pop_display_state()
  self:_refresh_arrow_hint(config_id)
  if config_id == nil then
    return
  end
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
  if config_id == nil or not self._cur_area_exhibits[config_id] then
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

function M:_pop_display_state()
  if not self._is_display_camera_pushed then
    return
  end
  CsGameplayUtilitiesCameraUtil.PopState("GalleryDisplay")
  self._is_display_camera_pushed = false
end

function M:_on_checkbox_click(config_id)
  if self._waiting_set_display then
    return
  end
  local exhibit_interact_id = self._exhibit_area_map[config_id]
  if exhibit_interact_id == self._interact_id then
    self:_send_set_display(config_id, false)
    return
  end
  if self._cur_area_count >= self._slot_count then
    EventCenter.Broadcast(EventID.LuaShowTips, UIUtil.get_text_by_id("MusApp_Display_Limit_Tips"))
    return
  end
  if exhibit_interact_id ~= nil then
    local popup = UIUtil.get_confirm_popup()
    popup:set_texts(UIUtil.get_text_by_id("MusApp_Display_Move_Confirm"), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), UIUtil.get_text_by_id("MusApp_Display_Move_Confirm_Title"))
    popup:set_callbacks(function()
      self:_send_set_display(config_id, true)
    end)
    popup:show()
    return
  end
  self:_send_set_display(config_id, true)
end

function M:_send_set_display(config_id, is_display)
  self._waiting_set_display = true
  self._set_display_token = (self._set_display_token or 0) + 1
  local token = self._set_display_token
  CsGalleryModuleUtil.SendMuseumSetDisplayReq(self._interact_id, config_id, is_display, function(retcode)
    if token ~= self._set_display_token then
      return
    end
    self._waiting_set_display = false
    if retcode ~= 0 then
      self:_refresh_exhibit_view()
    end
  end)
end

function M:_refresh_exhibit_view()
  self:_collect_exhibit_state()
  self:_update_creature_tiers()
  UIUtil.set_text(self._txt_area_limit, string.format("%d/%d", self._cur_area_count, self._slot_count))
  for i = 1, #self._creatures do
    local info = self._creatures[i]
    local item = self._items[i]
    if item then
      item:set_exhibit_state(info.tier ~= TIER_NOT_EXHIBITED, self:_get_item_area_name(info))
    end
  end
  if self._selected_config_id ~= nil and not self._cur_area_exhibits[self._selected_config_id] then
    self:_set_select(nil)
  else
    self:_refresh_arrow_hint(self._selected_config_id)
    if self._selected_config_id ~= nil and not self._is_display_camera_pushed then
      self:_set_camera_to_exhibit_item(self._selected_config_id)
    end
  end
end

function M:_refresh_auto_display()
  self._is_auto_display = CsGalleryModuleUtil.IsAutoDisplayOn(self:_get_auto_display_group_id())
  self:_set_auto_display_toggle(self._is_auto_display)
end

function M:_set_auto_display_toggle(is_on)
  if is_null(self._tog_switch) then
    return
  end
  self._tog_switch:SetIsOnWithoutNotify(is_on == true)
end

function M:_on_auto_display_click()
  self:_set_auto_display_toggle(self._is_auto_display)
  if self._waiting_auto_display then
    return
  end
  self._waiting_auto_display = true
  self._auto_display_token = (self._auto_display_token or 0) + 1
  local token = self._auto_display_token
  CsGalleryModuleUtil.SendSetMuseumAutoDisplayReq(self._interact_id, not self._is_auto_display, function()
    if token ~= self._auto_display_token then
      return
    end
    self._waiting_auto_display = false
    self:_refresh_auto_display()
  end)
end

function M:_set_camera_to_exhibit()
  if self._camera_area_id == self._interact_id then
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
  CsGameplayUtilitiesCameraUtil.PopState("GalleryTank")
  CsGameplayUtilitiesCameraUtil.PushStateAndSetTargetByTransform("GalleryTank", cam_point_trans, cam_point_trans)
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
  local tank = CsGalleryModuleUtil.CreatureTanks[self._interact_id]
  if config_id and self._cur_area_exhibits[config_id] and tank then
    local creature_entity = tank:GetCreatureEntityByConfigId(config_id)
    local cam_point_trans = UIUtil.find_trans(tank.transform, "CameraPoint")
    if not is_null(creature_entity) and not is_null(cam_point_trans) and creature_entity.IsValid then
      CsGameplayUtilitiesCameraUtil.PushGalleryDisplayState(creature_entity, cam_point_trans.rotation)
      self._is_display_camera_pushed = true
      return
    end
  end
  self:_set_camera_to_exhibit()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.onExhibitInfoUpdated, pack(self, M._refresh_exhibit_view))
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Esc, self._btn_close)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_close)
end

return M
