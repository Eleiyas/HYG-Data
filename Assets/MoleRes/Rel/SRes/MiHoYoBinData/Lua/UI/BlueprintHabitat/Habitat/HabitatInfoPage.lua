local reward_item_cls = "UI/BlueprintHabitat/Habitat/HabitatRewardItem"
local info_item_cls = "UI/BlueprintHabitat/Habitat/HabitatInfoItem"
local info_tip_panel_cls = "UI/BlueprintHabitat/Habitat/HabitatInfoTipPanel"
local M = G.Class("HabitatInfoPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/HabitatInfoPage"
  self.config.type = EUIType.Page
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_BlueprintHabitat"
  self.config.wait_previous_window_hide_until_show = true
  self._habitat_id = 0
  self._preview_helper = nil
  self._habitat_id_list = {}
  self._star_objs = {}
  self._reward_panel = nil
  self._creature_panel = nil
  self._need_items = {}
  self._condition_items = {}
  self._selected_need_slot = 0
  self._selected_condition_slot = 0
  self._info_tip_panel = nil
end

function M:on_create()
  base.on_create(self)
  self._view_root = UIUtil.find_trans(self.ui_scene_obj, "Art/ModelPos/pos")
  self._follow_trans = UIUtil.find_trans(self.ui_scene_obj, "Art/Content/CameraWrap/StarExploreSettlementFollow0")
  self._default_follow_pos = self._follow_trans and self._follow_trans.localPosition or Vector3.zero
  self._look_at_trans = UIUtil.find_trans(self.ui_scene_obj, "Art/Content/CameraWrap/StarExploreSettlementLookAt0")
  self._default_look_at_pos = self._look_at_trans and self._look_at_trans.localPosition or Vector3.zero
  self._reward_panel = self:add_panel(reward_item_cls, self._item_reward)
  self._creature_panel = self:add_panel(reward_item_cls, self._item_creature)
  if not_null(self._trans_tips) then
    self._info_tip_panel = self:add_panel(info_tip_panel_cls, self._trans_tips)
  end
  self:bind_callbacks()
  self.binder:BindViewCallback(self._trans_drag, EventTriggerType.Drag, pack(self, M._on_drag))
end

function M:on_open()
  base.on_open(self)
  self._habitat_id = self._extra_data and self._extra_data.habitat_id or 0
  self._habitat_id_list = list_to_table(CsHabitatModuleUtil.GetAllDiscoveredHabitatId()) or {}
  if self._habitat_id > 0 and not blueprint_habitat_module:is_habitat_unlock_recorded(self._habitat_id) then
    blueprint_habitat_module:record_habitat_unlock(self._habitat_id)
  end
  self:_refresh()
end

function M:on_enable()
  base.on_enable(self)
  self._return_main_page = self._extra_data and self._extra_data.open_by_main_page or false
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  self:_destroy_preview()
end

function M:on_destroy()
  self:_destroy_preview()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnGetHabitatRestoreReward, function(reward_list)
    self:_show_reward_dialog(reward_list)
    self:_refresh_npc_reward_panels()
  end)
end

function M:play_exit_anim()
  UIUtil.set_active(self.ui_scene_obj, false)
  CsUISceneManagerUtil.ExitUIScene()
  base.play_exit_anim(self)
end

function M:_exit_ui_scene()
end

function M:_show_reward_dialog(reward_list)
  if is_null(reward_list) then
    return
  end
  local rewards = array_to_table(reward_list)
  local items = {}
  for k, v in ipairs(rewards) do
    table.insert(items, {
      id = v.ItemConfigId,
      num = v.Count
    })
  end
  if 0 < #items then
    common_ui_module:show_reward_dialog(nil, nil, items)
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_back)
end

function M:bind_callbacks()
  self:bind_callback(self._btn_back, pack(self, M._on_btn_back_click))
  self:bind_callback(self._btn_start_site, pack(self, M._on_btn_start_site_click))
  self:bind_callback(self._tog_track, pack(self, M._on_tog_track))
  self:bind_callback(self._btn_last, pack(self, M._on_btn_last_click))
  self:bind_callback(self._btn_next, pack(self, M._on_btn_next_click))
end

function M:_get_current_index()
  for i = 1, #self._habitat_id_list do
    if self._habitat_id_list[i] == self._habitat_id then
      return i
    end
  end
  return 0
end

function M:_refresh()
  if self._habitat_id == 0 then
    return
  end
  local ok = false
  ok, self._ui_cfg = CsHabitatModuleUtil.TryGetHabitatUICfg(self._habitat_id, true)
  if not ok then
    return
  end
  self:_refresh_name()
  self:_refresh_stars()
  self:_clear_all_selection()
  self:_refresh_npc_reward_panels()
  self:_refresh_need_items()
  self:_refresh_condition_items()
  self:_refresh_finish_states()
  self:_refresh_arrows()
  self:_refresh_tracking()
  self:_refresh_tracking_tog()
  self:_refresh_preview()
  self:_refresh_restored_time()
end

function M:_refresh_name()
  local success, cfg = CsHabitatModuleUtil.TryGetHabitatUICfg(self._habitat_id)
  if not success or cfg == nil then
    UIUtil.set_text(self._txt_habitat_name, "")
    return
  end
  UIUtil.set_text(self._txt_habitat_name, cfg.Name)
end

function M:_refresh_stars()
  local ok, cfg = CsHabitatModuleUtil.TryGetHabitatCfg(self._habitat_id)
  local star_count = ok and cfg and cfg.Star or 0
  for i = 1, star_count do
    local obj = self._star_objs[i]
    if obj == nil then
      obj = self._list_stars:AddItem(0)
      self._star_objs[i] = obj
    end
    UIUtil.set_active(obj, true)
  end
  for i = star_count + 1, #self._star_objs do
    UIUtil.set_active(self._star_objs[i], false)
  end
end

function M:_refresh_need_items()
  local titles = self:_split_refer_description()
  local refer_entities = self._ui_cfg and self._ui_cfg.ReferEntities or nil
  self._selected_need_slot = 0
  if self._info_tip_panel then
    self._info_tip_panel:hide()
  end
  for i = 1, #titles do
    local title = titles[i]
    local num, cfg_id, tag = self:_get_refer_entity_display(refer_entities, i)
    local slot_index = i
    local refer_entity = refer_entities and 1 <= i and i <= refer_entities.Count and refer_entities[i - 1] or nil
    local cls = self._need_items[i]
    if cls == nil then
      local obj = self._list_need_item:AddItem(0)
      cls = self:add_panel(info_item_cls, obj)
      self._need_items[i] = cls
      self:bind_callback(cls:get_btn(), function()
        self:_on_need_item_click(cls)
      end)
    end
    cls:set_active(true)
    cls:set_slot_id(slot_index)
    if cfg_id then
      cls:refresh_as_need_item(title, num, cfg_id, refer_entity)
    else
      cls:refresh_as_need_tag(title, num, tag, nil, refer_entity)
      self:bind_callback(cls:get_tag_btn(), function()
        self:_show_tip_for_tag(cls:get_slot_id())
      end)
    end
  end
  for i = #titles + 1, #self._need_items do
    self._need_items[i]:set_active(false)
  end
end

function M:_refresh_condition_items()
  local ids = self._ui_cfg and self._ui_cfg.RequirementIds or nil
  local count = ids and ids.Count or 0
  self._selected_condition_slot = 0
  for i = 1, count do
    local requirement_id = ids[i - 1]
    local slot_index = i
    local cls = self._condition_items[i]
    if cls == nil then
      local obj = self._list_condition_item:AddItem(0)
      cls = self:add_panel(info_item_cls, obj)
      self._condition_items[i] = cls
      self:bind_callback(cls:get_btn(), function()
        self:_on_condition_item_click(cls)
      end)
    end
    cls:set_slot_id(slot_index)
    cls:set_active(true)
    cls:refresh_as_condition(self._habitat_id, requirement_id)
  end
  for i = count + 1, #self._condition_items do
    self._condition_items[i]:set_active(false)
  end
end

function M:_refresh_finish_states(is_tracking)
  if is_tracking == nil then
    is_tracking = blueprint_habitat_module:is_tracking_habitat_by_id(self._habitat_id, false)
  end
  if not is_tracking or blueprint_habitat_module:has_habitat_ever_been_restored(self._habitat_id) then
    for _, cls in ipairs(self._need_items) do
      cls:refresh_finish_state(false)
    end
    for _, cls in ipairs(self._condition_items) do
      cls:refresh_finish_state(false)
    end
    return
  end
  local completed_items = list_to_table(CsHabitatModuleUtil.GetCompletedItemIndexes(self._habitat_id)) or {}
  local item_finished_set = {}
  for _, idx in ipairs(completed_items) do
    item_finished_set[idx] = true
  end
  for i, cls in ipairs(self._need_items) do
    local is_finish = item_finished_set[i - 1] == true
    cls:refresh_finish_state(is_finish)
  end
  local completed_conditions = list_to_table(CsHabitatModuleUtil.GetCompletedConditionIndexes(self._habitat_id)) or {}
  local condition_finished_set = {}
  for _, idx in ipairs(completed_conditions) do
    condition_finished_set[idx] = true
  end
  local filtered_index = 0
  for i, cls in ipairs(self._condition_items) do
    local req_type = cls:get_requirement_type()
    if req_type == 1 then
      cls:refresh_finish_state(blueprint_habitat_module:has_habitat_site_data(self._habitat_id))
    else
      local is_finish = condition_finished_set[filtered_index] == true
      cls:refresh_finish_state(is_finish)
      filtered_index = filtered_index + 1
    end
  end
end

function M:_on_need_item_click(item_cls)
  self:_on_item_click(item_cls)
  if not item_cls:is_selected() then
    return
  end
  self._selected_need_slot = item_cls:get_slot_id()
  if self._preview_helper then
    self._preview_helper:SelectEntities(self._selected_need_slot - 1)
  end
end

function M:_on_condition_item_click(item_cls)
  self:_on_item_click(item_cls)
  if not item_cls:is_selected() then
    return
  end
  self._selected_condition_slot = item_cls:get_slot_id()
  local type = item_cls:get_requirement_type()
  if type == 0 then
    return
  end
  if type == 1 then
    if self._preview_helper then
      self._preview_helper:ShowOutline()
    end
  elseif type == 2 and self._preview_helper then
    self._preview_helper:SelectEntitiesByExtraConditions(self._habitat_id)
  end
end

function M:_on_item_click(item_cls)
  if self._preview_helper then
    self._preview_helper:ClearSelection()
    self._preview_helper:HideOutline()
  end
  if item_cls:is_selected() then
    item_cls:refresh_select_state(false)
    return
  end
  self:_clear_all_selection()
  item_cls:refresh_select_state(true)
end

function M:_clear_all_selection()
  for _, item in ipairs(self._need_items) do
    item:refresh_select_state(false)
  end
  for _, item in ipairs(self._condition_items) do
    item:refresh_select_state(false)
  end
  self._selected_need_slot = 0
  self._selected_condition_slot = 0
end

function M:_show_tip_for_tag(slot)
  if self._info_tip_panel == nil then
    return
  end
  local refer_entities = self._ui_cfg and self._ui_cfg.ReferEntities or nil
  if refer_entities == nil or slot < 1 or slot > refer_entities.Count then
    self._info_tip_panel:hide()
    return
  end
  local entity = refer_entities[slot - 1]
  local pairs_list = {}
  local items = entity and entity.Items or nil
  local count = items and items.Count or 0
  for i = 0, count - 1 do
    local it = items[i]
    pairs_list[#pairs_list + 1] = {
      it.ConfigId or 0,
      it.Count or 0
    }
  end
  if 0 < #pairs_list then
    self._info_tip_panel:show_tag(pairs_list)
    self:_position_tip_to_slot(slot)
  else
    self._info_tip_panel:hide()
  end
end

function M:_position_tip_to_slot(slot)
  if self._info_tip_panel == nil then
    return
  end
  local item = self._need_items[slot]
  if item == nil or item.get_top_center_position == nil then
    return
  end
  local x, y, z = item:get_top_center_position()
  self._info_tip_panel:set_trans_pos(x, y, z)
end

function M:_split_refer_description()
  local desc = self._ui_cfg and self._ui_cfg.ReferDescription or ""
  if not string.is_valid(desc) then
    return {}
  end
  local raw = lua_str_split(desc, ";")
  local result = {}
  for i = 1, #raw do
    local s = raw[i]
    if s ~= nil then
      result[#result + 1] = s
    end
  end
  return result
end

function M:_get_refer_entity_display(refer_entities, index)
  if refer_entities == nil or index < 1 or index > refer_entities.Count then
    return nil, nil, nil
  end
  local entity = refer_entities[index - 1]
  local repair = entity and entity.RepairItem or nil
  if repair == nil then
    return nil, nil, nil
  end
  local num = repair.Count
  local cfg_id, tag
  local target = repair.Target
  local terms = target and target.Terms
  local terms_count = terms and terms.Count or 0
  if 0 < terms_count then
    local first = terms[0]
    local first_cfg_id = first and first.ConfigId or 0
    if 0 < first_cfg_id then
      cfg_id = first_cfg_id
    elseif first and first.GameplayTag and 0 < first.GameplayTag.TagId then
      tag = first.GameplayTag
    end
  end
  return num, cfg_id, tag
end

function M:_refresh_npc_reward_panels()
  local npc_icon
  local ok, cfg = CsHabitatModuleUtil.TryGetHabitatCfg(self._habitat_id)
  if ok and cfg and cfg.RelatedNpcID ~= 0 then
    local npc_cfg = npc_module:get_npc_cfg(cfg.RelatedNpcID)
    if npc_cfg and string.is_valid(npc_cfg.iconnamesmall) then
      npc_icon = npc_cfg.iconnamesmall
    end
  end
  if string.is_valid(npc_icon) then
    UIUtil.set_active(self._icon_npc, true)
    UIUtil.set_image(self._icon_npc, npc_icon, self:get_load_proxy())
    UIUtil.set_image(self._icon_npc_2, npc_icon, self:get_load_proxy())
  else
    UIUtil.set_active(self._icon_npc, false)
  end
  self._reward_panel:refresh_as_reward(self._habitat_id)
  local creature_id = blueprint_habitat_module:get_habitat_creature_id(self._habitat_id)
  if 0 < creature_id then
    self._creature_panel:refresh_as_creature(self._habitat_id)
    self._state_group_reward_num:SetState(1)
  elseif string.is_valid(npc_icon) then
    self._state_group_reward_num:SetState(2)
    local has_claimed_reward = blueprint_habitat_module:is_habitat_reward_claimed(self._habitat_id)
    if has_claimed_reward then
      self._state_group_npc_favor:SetState(2)
    else
      self._state_group_npc_favor:SetState(0)
    end
  else
    self._state_group_reward_num:SetState(0)
  end
end

function M:_refresh_arrows()
  local idx = self:_get_current_index()
  local count = #self._habitat_id_list
  local show_last = 1 < idx
  local show_next = 0 < idx and idx < count
  UIUtil.set_active(self._btn_last, show_last)
  UIUtil.set_active(self._btn_next, show_next)
end

function M:_refresh_tracking()
  local ever_restored = blueprint_habitat_module:has_habitat_ever_been_restored(self._habitat_id)
  if ever_restored then
    UIUtil.set_active(self._tog_track, false)
    UIUtil.set_active(self._btn_start_site, false)
    return
  end
  local has_data = CsHabitatModuleUtil.HasHabitatSiteDataFromSceneData(self._habitat_id)
  UIUtil.set_active(self._tog_track, has_data)
  UIUtil.set_active(self._btn_start_site, true)
  if has_data then
    UIUtil.set_text_by_id(self._txt_btn_site, "Habitat_Button_SiteReselect")
  else
    UIUtil.set_text_by_id(self._txt_btn_site, "Habitat_Button_SiteSelect")
  end
end

function M:_refresh_tracking_tog()
  local has_data = CsHabitatModuleUtil.HasHabitatSiteDataFromSceneData(self._habitat_id)
  if has_data then
    self._tog_track.isOnValue = blueprint_habitat_module:is_tracking_habitat_by_id(self._habitat_id, false)
  end
end

function M:_refresh_preview()
  self:_destroy_preview()
  if is_null(self._view_root) then
    return
  end
  local helper = HabitatPreviewHelper.Create(self._view_root.position, self._habitat_id)
  if helper == nil then
    return
  end
  self._preview_helper = helper
  if not_null(self._follow_trans) and self._ui_cfg ~= nil and self._ui_cfg.CameraDummyPos ~= nil then
    self._follow_trans.localPosition = self._ui_cfg.CameraDummyPos.x ~= 0 and self._ui_cfg.CameraDummyPos or self._default_follow_pos
  end
  if not_null(self._look_at_trans) and self._ui_cfg ~= nil and self._ui_cfg.CameraLookAtPos ~= nil then
    self._look_at_trans.localPosition = self._ui_cfg.CameraLookAtPos.x ~= 0 and self._ui_cfg.CameraLookAtPos or self._default_look_at_pos
  end
end

function M:_refresh_restored_time()
  local restored_time = blueprint_habitat_module:get_first_restored_time(self._habitat_id)
  if restored_time == 0 then
    self._state_group_restored:SetState(0)
    return
  end
  self._state_group_restored:SetState(1)
  local date_time = TimeUtil.ChangeServerUtcTimeToServerLocalTime(restored_time)
  UIUtil.set_text(self._txt_restored_time, TextMapFormatUtil.FormatDateYMD(date_time))
end

function M:_destroy_preview()
  if self._preview_helper then
    self._preview_helper:Destroy()
    self._preview_helper = nil
  end
end

function M:_on_drag(event)
  if event.button ~= 0 or self._preview_helper == nil then
    return
  end
  self._preview_helper:RotatePlane(-event.delta.x / 3)
end

function M:_on_btn_back_click()
  self:close_self()
  if self._return_main_page then
    blueprint_habitat_module:open_main_page(blueprint_habitat_module.tab.habitat)
  end
end

function M:_on_btn_start_site_click()
  local in_self_mainland = GameSceneUtility.GetCurrentSceneId() == 2 and player_module:is_local_player_scene_owner()
  if not in_self_mainland then
    UIUtil.show_tips_by_text_id("Habitat_ForbidSiteTips")
    return
  end
  self._return_main_page = false
  self:close_self()
  blueprint_habitat_module:start_site_selection(self._habitat_id)
end

function M:_on_tog_track(is_on)
  if is_on then
    self._return_main_page = false
    blueprint_habitat_module:set_tracking_habitat(self._habitat_id, true, true)
    UIUtil.show_tips_by_text_id("Memo_SettingTacking")
  else
    blueprint_habitat_module:set_tracking_habitat(self._habitat_id, false, true)
    self:_refresh_tracking()
    UIUtil.show_tips_by_text_id("Memo_NoSettingTacking")
  end
  self:_refresh_finish_states(is_on)
end

function M:_on_btn_last_click()
  local idx = self:_get_current_index()
  if idx <= 1 then
    return
  end
  self:_switch_to(self._habitat_id_list[idx - 1])
end

function M:_on_btn_next_click()
  local idx = self:_get_current_index()
  if idx <= 0 or idx >= #self._habitat_id_list then
    return
  end
  self:_switch_to(self._habitat_id_list[idx + 1])
end

function M:_switch_to(habitat_id)
  if habitat_id == nil or habitat_id == 0 or habitat_id == self._habitat_id then
    return
  end
  self._habitat_id = habitat_id
  if not blueprint_habitat_module:is_habitat_unlock_recorded(self._habitat_id) then
    blueprint_habitat_module:record_habitat_unlock(self._habitat_id)
  end
  self:_refresh()
end

return M
