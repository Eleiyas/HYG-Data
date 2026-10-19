local M = G.Class("ToolSkinPage", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/ToolSkin/ToolSkinPage"
  self.config.type = EUIType.Page
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_HuanZhuangXiTong"
  self._cur_cam_state = ""
  self._cur_pos = Vector2.zero
  self._last_pos = Vector2.zero
  self._delta_pos = Vector2.zero
  self._cur_euler_angle_y = 0
  self._drag_dis = 0
  self._rotation_sensitivity = 0.2
  self._tab_items = nil
  self._cur_tool_cfg_id = 0
  self._skin_ids = {}
  self._skin_items = {}
  self._tbl_instance_ids = {}
  self._select_index = 0
  self._is_skin_list_init = true
  self._cur_skin_id = 0
  self._selected_skin_id = 0
  self._tab_cache = {}
  self._entry_tool_cfg_id = 0
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  local item_size = self._grid_scroller.CellSize
  local width = self._rect_viewport:GetWidth() or 0
  self._row_item_num = math.floor(width / item_size.x)
  if 0 < self._row_item_num then
    local new_x = item_size.x + width % item_size.x / (self._row_item_num + 1)
    self._grid_scroller.CellSize = Vector2(new_x, item_size.y)
  end
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self._entry_tool_cfg_id = CsToolUtil.GetCurrentToolConfigId(player_module:get_player_guid())
  self._cur_tool_cfg_id = 0
  self._cur_euler_angle_y = 0
  self:_refresh_cam()
  self:_refresh_temp_player()
  self:_refresh_tab_list()
end

function M:on_disable()
  base.on_disable(self)
  self:_save_cur_tab_cache()
  CsToolSkinManagerUtil.DestroyTempPlayer()
  CsGameplayUtilitiesCameraUtil.PopState(self._cur_cam_state)
  self._cur_cam_state = ""
  self._tab_cache = {}
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:close_self()
  local need_save = self:_is_need_save()
  if need_save then
    local popup = UIUtil.get_confirm_popup()
    popup:set_texts(UIUtil.get_text_by_id("ToolSkin_Exit_Tips"), UIUtil.get_text_by_id("ToolSkin_Exit_button2"), UIUtil.get_text_by_id("ToolSkin_Exit_button1"))
    popup:set_callbacks(function()
      local cur_tool_performed = false
      if need_save then
        cur_tool_performed = self:_save_all_changes()
      end
      if not cur_tool_performed then
        self:_apply_tool_on_exit()
      end
      base.close_self(self)
    end, function()
      base.close_self(self)
    end)
    popup:show()
    return
  end
  base.close_self(self)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_save, pack(self, M._on_btn_save_click))
  self:bind_callback(self._btn_info, pack(self, M._on_btn_info_click))
  self:_add_drag_event()
end

function M:_on_btn_save_click()
  local need_save = self:_is_need_save()
  local need_switch_tool = self._cur_tool_cfg_id ~= self._entry_tool_cfg_id
  if not need_save and not need_switch_tool then
    self:close_self()
    return
  end
  local cur_tool_performed = false
  if need_save then
    cur_tool_performed = self:_save_all_changes()
  end
  if not cur_tool_performed then
    self:_apply_tool_on_exit()
  end
  base.close_self(self)
end

function M:_on_btn_info_click()
  if self._selected_skin_id == 0 then
    return
  end
  item_module:open_item_info_dialog(self._selected_skin_id)
end

function M:_is_need_save()
  self:_save_cur_tab_cache()
  for tool_id, cache in pairs(self._tab_cache) do
    local effective = CsToolSkinModuleUtil.GetEffectiveSkinId(tool_id)
    if cache.selected_skin_id ~= 0 and cache.selected_skin_id ~= effective then
      return true
    end
  end
  return false
end

function M:_save_all_changes()
  self:_save_cur_tab_cache()
  local cur_tool_need_perform = false
  for tool_id, cache in pairs(self._tab_cache) do
    local effective = CsToolSkinModuleUtil.GetEffectiveSkinId(tool_id)
    if cache.selected_skin_id ~= 0 and cache.selected_skin_id ~= effective then
      if tool_id == self._cur_tool_cfg_id then
        CsGameplayUtilitiesToolSkinUtil.SwitchToolSkinWithPerform(tool_id, cache.selected_skin_id)
        cur_tool_need_perform = true
      else
        CsToolSkinModuleUtil.ReportToolSkin(tool_id, cache.selected_skin_id)
      end
    end
  end
  return cur_tool_need_perform
end

function M:_apply_tool_on_exit()
  CsGameplayUtilitiesToolSkinUtil.EquipToolWithPerform(self._cur_tool_cfg_id)
end

function M:_refresh_cam()
  self._follow_target = UIUtil.find_trans(self.ui_scene_obj, "Art/FollowTarget")
  self._look_target = UIUtil.find_trans(self.ui_scene_obj, "Art/LookTarget")
  if string.is_valid(self._cur_cam_state) then
    CsGameplayUtilitiesCameraUtil.PopState(self._cur_cam_state)
  end
  self._cur_cam_state = "AppearancePage1"
  CsGameplayUtilitiesCameraUtil.PushStateAndSetTargetByTransform(self._cur_cam_state, self._follow_target, self._look_target)
end

function M:_refresh_temp_player()
  local player_root = UIUtil.find_trans(self.ui_scene_obj, "Art/PlayerRoot")
  CsToolSkinManagerUtil.CreateTempPlayer(player_root)
end

function M:_refresh_tab_list()
  local tool_ids = list_to_table(CsToolSkinModuleUtil.GetToolIdsWithSkins())
  if self._tab_items == nil then
    self._tab_items = {}
  end
  local holding_tool_id = CsToolUtil.GetCurrentToolConfigId(player_module:get_player_guid())
  local select_cls
  for i, tool_id in ipairs(tool_ids) do
    local cls = self._tab_items[i]
    if cls == nil then
      local go = self._tab_list_binder:AddItem(0)
      cls = self:add_panel("UI/ToolSkin/ToolSkinTabItem", go)
      self:bind_callback(cls:get_tog(), function(is_on)
        self:_on_tab_click(is_on, cls)
      end)
      self._tab_items[i] = cls
    end
    cls:refresh(tool_id)
    if self._cur_tool_cfg_id == 0 then
      if holding_tool_id ~= 0 and tool_id == holding_tool_id then
        select_cls = cls
      elseif select_cls == nil and i == 1 then
        select_cls = cls
      end
    elseif tool_id == self._cur_tool_cfg_id then
      select_cls = cls
    end
  end
  if select_cls then
    if select_cls:get_tog().isOn then
      self:_on_tab_selected(select_cls)
    else
      select_cls:get_tog().isOn = true
    end
  end
end

function M:_on_tab_click(is_on, cls)
  if is_on then
    self:_on_tab_selected(cls)
  end
end

function M:_on_tab_selected(cls)
  local tool_id = cls:get_tool_cfg_id()
  if tool_id == self._cur_tool_cfg_id then
    return
  end
  self:_save_cur_tab_cache()
  self._cur_tab_cls = cls
  self._cur_tool_cfg_id = tool_id
  CsToolSkinManagerUtil.EquipToolOnPreview(tool_id)
  local tool_cfg = item_module:get_cfg_by_id(tool_id)
  if not is_null(tool_cfg) then
    UIUtil.set_text(self._txt_select_title, tool_cfg.name or "")
  end
  local cache = self._tab_cache[tool_id]
  if cache then
    self._cur_skin_id = cache.cur_skin_id
    self._selected_skin_id = cache.selected_skin_id
  else
    local effective_skin = CsToolSkinModuleUtil.GetEffectiveSkinId(tool_id)
    self._cur_skin_id = effective_skin
    self._selected_skin_id = effective_skin
  end
  if self._selected_skin_id ~= 0 then
    CsToolSkinManagerUtil.ApplySkinOnPreview(self._selected_skin_id)
    cls:refresh_icon(self._selected_skin_id)
    self:_refresh_select_item_name(self._selected_skin_id)
  else
    cls:refresh_icon(nil)
    self:_refresh_select_item_name(self._cur_tool_cfg_id)
  end
  self:_refresh_skin_list()
  self:_restore_tab_cache(cache)
end

function M:_save_cur_tab_cache()
  if self._cur_tool_cfg_id == 0 then
    return
  end
  self._tab_cache[self._cur_tool_cfg_id] = {
    selected_skin_id = self._selected_skin_id,
    cur_skin_id = self._cur_skin_id,
    select_index = self._select_index
  }
end

function M:_restore_tab_cache(cache)
  if cache == nil then
    return
  end
  if self._select_index > 0 then
    self._grid_scroller:MoveTo(self._select_index - 1)
  end
end

function M:_refresh_skin_list()
  local raw_ids = list_to_table(CsToolSkinModuleUtil.GetSkinsByToolId(self._cur_tool_cfg_id)) or {}
  self._skin_ids = {}
  local row_num = math.ceil(#raw_ids / 6)
  local id_index = 1
  for row = 1, row_num do
    for col = 1, self._row_item_num do
      if col <= 3 or col > self._row_item_num - 3 then
        table.insert(self._skin_ids, raw_ids[id_index] or 0)
        id_index = id_index + 1
      else
        table.insert(self._skin_ids, -1)
      end
    end
  end
  self._select_index = 0
  if self._selected_skin_id ~= 0 then
    for i, sid in ipairs(self._skin_ids) do
      if sid == self._selected_skin_id then
        self._select_index = i
        break
      end
    end
  end
  UIUtil.set_active(self._obj_empty, #raw_ids <= 0)
  UIUtil.set_active(self._grid_scroller, 0 < #raw_ids)
  if #raw_ids <= 0 then
    return
  end
  local max_num = math.ceil(#self._skin_ids / self._row_item_num)
  max_num = math.max(#self._skin_ids, max_num * self._row_item_num)
  self._tbl_instance_ids = {}
  if self._is_skin_list_init then
    self._skin_items = {}
    self._grid_scroller:Init(pack(self, M._refresh_skin_item), max_num)
    self._is_skin_list_init = false
  else
    self._grid_scroller:ReLoad(pack(self, M._refresh_skin_item), max_num)
  end
end

function M:_refresh_skin_item(trans, index)
  index = index + 1
  local instance_id = trans:GetInstanceID()
  self._tbl_instance_ids[index] = instance_id
  local cls = self._skin_items[instance_id]
  if is_null(cls) then
    cls = self:add_panel("UI/ToolSkin/ToolSkinItem", trans)
    self:bind_callback(cls:get_btn(), function()
      if cls:get_skin_id() == 0 then
        return
      end
      if self._select_index ~= cls:get_index() then
        self:_change_select_index(cls:get_index(), cls)
      end
      self:_on_skin_item_click(cls)
    end)
    self._skin_items[instance_id] = cls
  end
  local skin_id = self._skin_ids[index]
  if self._select_index <= 0 and 0 < skin_id then
    self._select_index = index
  end
  cls:refresh(skin_id, index, self._cur_skin_id, self._selected_skin_id)
end

function M:_change_select_index(new_index, new_cls)
  local instance_id = self._tbl_instance_ids[self._select_index]
  if instance_id == nil then
    return
  end
  local last_cls = self._skin_items[instance_id]
  self._select_index = new_index
  if last_cls then
    last_cls:refresh_worn_and_select_state(self._selected_skin_id)
  end
  new_cls:refresh_worn_and_select_state(self._selected_skin_id)
end

function M:_on_skin_item_click(cls)
  if not cls:is_unlocked() then
    return
  end
  local skin_id = cls:get_skin_id()
  if skin_id == self._selected_skin_id then
    return
  end
  self._selected_skin_id = skin_id
  CsToolSkinManagerUtil.ApplySkinOnPreview(skin_id)
  self:_refresh_select_item_name(skin_id)
  self._grid_scroller:RefreshCurrent()
  if self._cur_tab_cls then
    self._cur_tab_cls:refresh_icon(skin_id)
  end
end

function M:_refresh_select_item_name(skin_id)
  local cfg = item_module:get_cfg_by_id(skin_id)
  if not is_null(cfg) then
    UIUtil.set_text(self._txt_select_item_name, cfg.name or "")
  else
    UIUtil.set_text(self._txt_select_item_name, "")
  end
end

function M:get_select_index()
  return self._select_index
end

function M:_add_drag_event()
  self.binder:BindViewCallback(self._trans_drag_content, EventTriggerType.BeginDrag, pack(self, M._on_begin_drag))
  self.binder:BindViewCallback(self._trans_drag_content, EventTriggerType.Drag, pack(self, M._on_drag))
  self.binder:BindViewCallback(self._trans_drag_content, EventTriggerType.EndDrag, pack(self, M._on_end_drag))
end

function M:_on_begin_drag(evt)
  self._cur_pos = evt.position
  self._last_pos = evt.position
  self._scroll_rect:OnBeginDrag(evt)
end

function M:_on_drag(evt)
  self._cur_pos = evt.position
  self._delta_pos = self._cur_pos - self._last_pos
  local angle_with_x_axis = Vector2.Angle(self._delta_pos, Vector2.right)
  if 90 < angle_with_x_axis then
    angle_with_x_axis = 180 - angle_with_x_axis
  end
  if angle_with_x_axis <= 60 then
    self._drag_dis = Vector2.Distance(self._cur_pos, self._last_pos)
    if self._cur_pos.x >= self._last_pos.x then
      self._drag_dis = -self._drag_dis
    end
    self._cur_euler_angle_y = self._cur_euler_angle_y + self._drag_dis * self._rotation_sensitivity
    self:_update_player_euler_angle_y()
  else
    self._trans_content:SetAnchoredPosY(self._trans_content:GetAnchoredPosY() + (self._cur_pos.y - self._last_pos.y) * 0.5)
  end
  self._last_pos = self._cur_pos
end

function M:_on_end_drag(evt)
  self._scroll_rect:OnEndDrag(evt)
  self._cur_pos = Vector2.zero
  self._last_pos = Vector2.zero
  self._delta_pos = Vector2.zero
  self._drag_dis = 0
end

function M:_update_player_euler_angle_y()
  CsToolSkinManagerUtil.UpdatePlayerEulerAnglesY(self._cur_euler_angle_y)
end

return M
