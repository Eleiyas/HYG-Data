local M = G.Class("HairDyeingDyePanel", G.UIPanel)
local base = G.UIPanel
local color_sys_item_cls = "UI/HairDyeing/HairDyeingColorSysItem"
local color_item_cls = "UI/HairDyeing/HairDyeingColorItem"
local coin_item_cls = "UI/HairDyeing/HairDyeingCoinItem"
local coin_item_topbar_cls = common_ui_module.common_coin_item_view_cls
local dye_button_cd = 0.5

function M:init()
  base.init(self)
  self._is_hide_close_listener = false
  self.config.prefab_path = hair_dyeing_module.ui_prefab_path.dye
  self._sys_items = nil
  self._color_items = nil
  self._all_systems = nil
  self._filter_set = nil
  self._cur_dye_part = nil
  self._cur_sys_id = nil
  self._preview_color_id = nil
  self._selection_by_dye_part = {}
  self._coin_item = nil
  self._on_back = nil
  self._on_exchange = nil
  self._on_haircut = nil
  self._dye_button_cd_co = nil
  self._is_dye_button_cooling_down = false
end

function M:on_create()
  self._filter_set = {}
  base.on_create(self)
  self:bind_callback(self._btn_exhange_dyeing, pack(self, M._on_btn_exchange))
  self:bind_callback(self._btn_coin_item1, pack(self, M._on_btn_coin_item1))
  self:bind_callback(self._btn_coin_item2, pack(self, M._on_btn_coin_item2))
  self:bind_callback(self._btn_dyeing_haircut, pack(self, M._on_btn_haircut))
  self:bind_callback(self._btn_start_dyeing, pack(self, M._on_btn_start))
  self:bind_callback(self._btn_back, pack(self, M._on_btn_back))
  self:bind_callback(self._btn_help, pack(self, M._on_btn_help))
  self._coin_item = self:add_panel(coin_item_topbar_cls, self._trans_coin_item, {
    coin_id = hair_dyeing_module.currency.dye_agent,
    auto_update = true,
    show_detail = true,
    extra_events = {
      EventID.LuaChangePacket
    }
  })
end

function M:on_destroy()
  self:_stop_dye_button_cd()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  
  local function refresh_material_count()
    if self._coin_item then
      self._coin_item:refresh()
    end
    self:_refresh_exchange_counts()
    self:_refresh_cost()
  end
  
  self:add_evt_listener(EventID.LuaChangePacket, refresh_material_count)
  self:add_evt_listener(EventID.UpdateCoinData, refresh_material_count)
  self:add_evt_listener(EventID.LuaHairDyeSolidDyeResult, pack(self, M._on_dye_result))
  self:add_evt_listener(EventID.LuaHairDyeGradientDyeResult, pack(self, M._on_dye_result))
  self:add_lua_listener(lua_event_module.event_type.on_hair_dye_color_owned_changed, pack(self, M._refresh_color_data_keep_selection))
end

function M:_on_dye_result(rsp)
  if rsp ~= nil and rsp.Retcode == 0 then
    self:_refresh_exchange_counts()
    self:_update_state_group()
    self:_start_dye_button_cd()
  end
end

function M:set_on_back(callback)
  self._on_back = callback
end

function M:set_on_exchange(callback)
  self._on_exchange = callback
end

function M:set_on_haircut(callback)
  self._on_haircut = callback
end

function M:clear_color_preview()
  self._preview_color_id = nil
  for _, item in ipairs(self._color_items or {}) do
    item:set_selected(false)
  end
end

function M:clear_dye_session_state()
  self:clear_color_preview()
  self._selection_by_dye_part = {}
  self._cur_sys_id = nil
end

function M:_cache_current_part_selection()
  if self._cur_dye_part == nil then
    return
  end
  self._selection_by_dye_part[self._cur_dye_part] = {
    color_group_id = self._cur_sys_id and self._cur_sys_id.color or nil,
    preview_color_id = self._preview_color_id
  }
end

function M:refresh()
  self._cur_dye_part = hair_dyeing_module.dye_part.region
  self._cur_sys_id = nil
  self._preview_color_id = nil
  self:_refresh_color_data_keep_selection()
  self:_refresh_exchange_counts()
  self:_refresh_cost()
  self:_update_state_group()
  if self._coin_item then
    self._coin_item:refresh()
  end
  self:apply_region_brightness_pulse()
end

function M:apply_region_brightness_pulse()
  hair_dyeing_module:set_region_brightness_pulse(self._cur_dye_part, true)
end

function M:_get_region_id_for_color_filter()
  return self._cur_dye_part == hair_dyeing_module.dye_part.region and 2 or 1
end

function M:_is_color_unlocked(color_id)
  return hair_dyeing_module:is_color_owned(hair_dyeing_module:get_cur_style_id(), self._cur_dye_part, color_id)
end

function M:_is_color_sys_completed(color_cfg)
  local color_block_ids = color_cfg and hair_dyeing_module:get_colors_by_color_sys(color_cfg) or nil
  if is_null(color_block_ids) or color_block_ids.Count <= 0 then
    return false
  end
  for i = 0, color_block_ids.Count - 1 do
    if not self:_is_color_unlocked(color_block_ids[i]) then
      return false
    end
  end
  return true
end

function M:_refresh_color_data_keep_selection()
  local selection = self._selection_by_dye_part[self._cur_dye_part] or {}
  local last_color_group_id = selection.color_group_id
  self._all_systems = hair_dyeing_module:get_color_cfgs_by_type_and_region(hair_dyeing_module.dye_mode.dye, hair_dyeing_module:get_cur_style_id(), self:_get_region_id_for_color_filter()) or {}
  self._cur_sys_id = nil
  self._preview_color_id = selection.preview_color_id
  if last_color_group_id ~= nil then
    for _, cfg in ipairs(self._all_systems) do
      if cfg.color == last_color_group_id then
        self._cur_sys_id = cfg
        break
      end
    end
  end
  if self._cur_sys_id == nil then
    self._preview_color_id = nil
  else
    local color_block_ids = hair_dyeing_module:get_colors_by_color_sys(self._cur_sys_id)
    local has_preview_color = false
    if not is_null(color_block_ids) then
      for i = 0, color_block_ids.Count - 1 do
        if color_block_ids[i] == self._preview_color_id then
          has_preview_color = true
          break
        end
      end
    end
    if not has_preview_color then
      self._preview_color_id = nil
    end
  end
  self:_cache_current_part_selection()
  self:_refresh_color_sys_list()
  self:_refresh_color_list()
  self:_refresh_cost()
  self:_update_state_group()
end

function M:_refresh_color_sys_list()
  local list = self:_apply_filter(self._all_systems)
  self._sys_items = self._sys_items or {}
  local parent = self._trans_color_sys_item.parent
  local max_num = math.max(#self._sys_items, #list)
  for i = 1, max_num do
    local cfg = list[i]
    local item = self._sys_items[i]
    if item == nil and cfg then
      local go = i == 1 and self._trans_color_sys_item.gameObject or UIUtil.load_prefab_set_parent(self._trans_color_sys_item.gameObject, parent)
      item = self:add_panel(color_sys_item_cls, go.transform)
      item:set_on_click(function(color_cfg, is_on)
        self:_on_sys_click(color_cfg, is_on)
      end)
      self._sys_items[i] = item
    end
    if item then
      if cfg then
        item:set_active(true)
        item:refresh({
          sys_id = cfg,
          display_color = hair_dyeing_module:get_display_color_by_color_cfg(cfg),
          icon_path = hair_dyeing_module:get_icon_path_by_color_cfg(cfg),
          owned = self:_is_color_sys_completed(cfg),
          selected = self._cur_sys_id == cfg
        })
      else
        item:set_active(false)
      end
    end
  end
end

function M:_apply_filter(systems)
  if next(self._filter_set) == nil then
    return systems
  end
  local result = {}
  for _, sys in ipairs(systems) do
    if self._filter_set[sys.id] then
      table.insert(result, sys)
    end
  end
  return result
end

function M:_on_sys_click(color_cfg, is_on)
  if not is_on then
    if self._cur_sys_id == color_cfg then
      self._cur_sys_id = nil
      self._preview_color_id = nil
      self:_cache_current_part_selection()
      self:_refresh_color_list()
      self:_refresh_cost()
      self:_update_state_group()
    end
    return
  end
  self._cur_sys_id = color_cfg
  self._preview_color_id = nil
  self:_cache_current_part_selection()
  for _, item in ipairs(self._sys_items or {}) do
    item:set_selected(item:get_sys_id() == color_cfg)
  end
  self:_refresh_color_list()
  self:_refresh_cost()
  self:_update_state_group()
end

function M:_refresh_color_list()
  local colors = {}
  local color_block_ids = self._cur_sys_id and hair_dyeing_module:get_colors_by_color_sys(self._cur_sys_id) or nil
  if not is_null(color_block_ids) then
    for i = 0, color_block_ids.Count - 1 do
      table.insert(colors, color_block_ids[i])
    end
  end
  self._color_items = self._color_items or {}
  local parent = self._trans_color_item.parent
  local max_num = math.max(#self._color_items, #colors)
  for i = 1, max_num do
    local color_id = colors[i]
    local item = self._color_items[i]
    if item == nil and color_id then
      local go = i == 1 and self._trans_color_item.gameObject or UIUtil.load_prefab_set_parent(self._trans_color_item.gameObject, parent)
      item = self:add_panel(color_item_cls, go.transform)
      item:set_on_click(function(color_id)
        self:_on_color_click(color_id)
      end)
      self._color_items[i] = item
    end
    if item then
      if color_id then
        item:set_active(true)
        item:refresh({
          color_id = color_id,
          owned = self:_is_color_unlocked(color_id),
          selected = self._preview_color_id == color_id,
          display_only = true,
          preview_only = true
        })
      else
        item:set_active(false)
      end
    end
  end
end

function M:_on_color_click(color_id)
  self._preview_color_id = color_id
  self:_cache_current_part_selection()
  for _, item in ipairs(self._color_items or {}) do
    item:set_selected(item:get_color_id() == color_id)
  end
  hair_dyeing_module:preview_hair_color(color_id, self._cur_dye_part)
end

function M:_refresh_exchange_counts()
  local paid_id = hair_dyeing_module.currency.inspiration_paid
  local rainbow_id = hair_dyeing_module.currency.rainbow_inspiration
  item_module:set_item_icon_no_server_data(self._img_icon_coin_1, paid_id, nil, self:get_load_proxy())
  UIUtil.set_text(self._txt_num_coin_1, tostring(hair_dyeing_module:get_material_num(paid_id)))
  item_module:set_item_icon_no_server_data(self._img_icon_coin_2, rainbow_id, nil, self:get_load_proxy())
  UIUtil.set_text(self._txt_num_coin_2, tostring(hair_dyeing_module:get_material_num(rainbow_id)))
end

function M:_refresh_cost()
  local show_cost = self._cur_sys_id ~= nil
  UIUtil.set_active(self._trans_coin_group, show_cost)
  if not show_cost then
    return
  end
  local dye_item_id, cost = self:_get_dye_item()
  item_module:set_item_icon_no_server_data(self._img_icon_coin, dye_item_id, nil, self:get_load_proxy())
  local owned = hair_dyeing_module:get_material_num(dye_item_id)
  local cost_text = cost > owned and string.format("<style=TextWarning_Light>%d</style>", cost) or tostring(cost)
  UIUtil.set_text(self._txt_cost_num, cost_text)
end

function M:_get_dye_item()
  local color_group_cfg = hair_dyeing_module:get_color_group_cfg(self._cur_sys_id)
  local dye_item = color_group_cfg and color_group_cfg.dyeid or nil
  local item_id, count = string.match(dye_item or "", "^(%d+)_(%d+)$")
  return tonumber(item_id) or 0, tonumber(count) or 0
end

function M:_stop_dye_button_cd()
  if self._dye_button_cd_co ~= nil then
    CsCoroutineManagerUtil.StopCoroutine(self._dye_button_cd_co)
    self._dye_button_cd_co = nil
  end
  self._is_dye_button_cooling_down = false
end

function M:_start_dye_button_cd()
  self:_stop_dye_button_cd()
  self._is_dye_button_cooling_down = true
  self:_update_state_group()
  self._dye_button_cd_co = CsCoroutineManagerUtil.InvokeRealtime(dye_button_cd, function()
    self._dye_button_cd_co = nil
    self._is_dye_button_cooling_down = false
    if not is_null(self.game_obj) then
      self:_update_state_group()
    end
  end)
end

function M:_update_state_group()
  local has_selected_color_group = self._cur_sys_id ~= nil
  self._ui_state_group:SetState(has_selected_color_group and 1 or 0)
  if not is_null(self._btn_start_dyeing) then
    local is_dyeable = hair_dyeing_module:is_current_style_dyeable()
    local has_gradient_region = hair_dyeing_module:has_gradient_region()
    self._btn_start_dyeing.interactable = not self._is_dye_button_cooling_down and (not is_dyeable or not has_gradient_region or has_selected_color_group)
  end
end

function M:refresh_dyeable_state()
  self:_update_state_group()
end

function M:_is_material_enough()
  local dye_item_id, cost = self:_get_dye_item()
  return 0 < dye_item_id and hair_dyeing_module:is_material_enough(dye_item_id, cost)
end

function M:_on_btn_exchange()
  if not hair_dyeing_module:is_current_style_dyeable() then
    hair_dyeing_module:show_cannot_dye_prompt(self._on_haircut)
    return
  end
  if self._on_exchange then
    self._on_exchange({
      color_sys = self._cur_sys_id and self._cur_sys_id.tag or nil
    })
  else
    hair_dyeing_module:open_exchange_dialog({
      color_sys = self._cur_sys_id and self._cur_sys_id.tag or nil
    })
  end
end

function M:_on_btn_coin_item1()
  item_module:open_item_info_dialog(hair_dyeing_module.currency.inspiration_paid, hair_dyeing_module:get_material_num(hair_dyeing_module.currency.inspiration_paid))
end

function M:_on_btn_coin_item2()
  item_module:open_item_info_dialog(hair_dyeing_module.currency.rainbow_inspiration, hair_dyeing_module:get_material_num(hair_dyeing_module.currency.rainbow_inspiration))
end

function M:_on_btn_haircut()
  if self._on_haircut then
    self._on_haircut()
    return
  end
  appearance_module:open_appearance_page_with_preset({
    type = appearance_module.tab_type.dress,
    preset_attrib_type = appearance_module.appearance_attrib_type.hair_style,
    from_hair_dyeing = true
  })
end

function M:_on_btn_start()
  if not hair_dyeing_module:is_current_style_dyeable() then
    hair_dyeing_module:show_cannot_dye_prompt(self._on_haircut)
    return
  end
  if not hair_dyeing_module:has_gradient_region() then
    UIUtil.show_tips_by_text_id("HairDyeing_UI_Tips1")
    return
  end
  if self._cur_sys_id == nil then
    UIUtil.show_tips_by_text_id("HairDyeing_Dye_SelectColorGroup")
    return
  end
  if not self:_is_material_enough() then
    local dye_item_id = self:_get_dye_item()
    local material_name = 0 < dye_item_id and item_module:get_item_name_by_id(dye_item_id) or ""
    UIUtil.show_tips_by_text_id("HairDyeing_Exchange_NotEnough1", material_name)
    return
  end
  hair_dyeing_module:set_dye_mode(hair_dyeing_module.dye_mode.dye)
  hair_dyeing_module:set_dye_part(hair_dyeing_module.dye_part.region)
  hair_dyeing_module:set_dye_type(hair_dyeing_module.dye_type.gradient)
  hair_dyeing_module:set_selected_color_id(self._cur_sys_id.color)
  local req = hair_dyeing_module:build_dye_req()
  req.region = self:_get_region_id_for_color_filter()
  local dye_item_id, cost = self:_get_dye_item()
  req.material_ids = {dye_item_id}
  req.material_counts = {cost}
  hair_dyeing_module:request_dye(req, function(rsp)
  end)
end

function M:_on_btn_back()
  if self._on_back then
    self._on_back()
  end
end

function M:_on_btn_help()
  UIManagerInstance:open("UI/CommonUI/IntroductionDialog", 31)
end

return M
