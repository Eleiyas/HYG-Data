local M = G.Class("HairDyeingExchangePanel", G.UIPanel)
local base = G.UIPanel
local color_sys_item_cls = "UI/HairDyeing/HairDyeingColorSysItem"
local color_item_cls = "UI/HairDyeing/HairDyeingColorItem"
local region_tog_item_cls = "UI/HairDyeing/HairDyeingExchangeRegionTogItem"
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local exchange_btn_transition_state = {normal = 0, disabled = 4}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/HairDyeing/HairDyeingExchangePage"
  self._cur_dye_part = nil
  self._cur_sys_tag = nil
  self._cur_exchange_color = nil
  self._selection_by_dye_part = {}
  self._all_systems = nil
  self._sys_items = nil
  self._color_items = nil
  self._region_tog_items = nil
  self._coin_items = nil
  self._on_back = nil
  self._on_haircut = nil
  self._suppress_sys_click = false
end

function M:on_create()
  base.on_create(self)
  self:_init_region_tog_items()
  self:bind_callback(self._btn_exchange, pack(self, M._on_btn_exchange))
  self:bind_callback(self._btn_back, pack(self, M._on_btn_back))
  self:bind_callback(self._btn_help, pack(self, M._on_btn_help))
  self:_init_coin_items()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaChangePacket, function()
    self:_refresh_coin_items()
    self:_refresh_cost()
  end)
  self:add_lua_listener(lua_event_module.event_type.on_hair_dye_color_owned_changed, pack(self, M._refresh_owned_state))
end

function M:_refresh_owned_state()
  self:_refresh_color_list()
  self:_refresh_exchange_btn_state()
end

function M:set_on_back(callback)
  self._on_back = callback
end

function M:set_on_haircut(callback)
  self._on_haircut = callback
end

function M:_reset_dye_session_state()
  self._selection_by_dye_part = {}
  self._cur_sys_tag = nil
  self._cur_exchange_color = nil
end

function M:clear_dye_session_state()
  self:_reset_dye_session_state()
end

function M:_cache_current_part_selection()
  if self._cur_dye_part == nil then
    return
  end
  self._selection_by_dye_part[self._cur_dye_part] = {
    sys_tag = self._cur_sys_tag,
    color_id = self._cur_exchange_color and self._cur_exchange_color.color_id or nil
  }
end

function M:_restore_current_part_selection()
  local selection = self._selection_by_dye_part[self._cur_dye_part]
  local system = selection ~= nil and self:_get_system_by_tag(selection.sys_tag) or nil
  if system == nil then
    self._cur_sys_tag = nil
    self._cur_exchange_color = nil
    self:_cache_current_part_selection()
    return
  end
  self._cur_sys_tag = system.tag
  self._cur_exchange_color = nil
  for _, data in ipairs(system.colors or {}) do
    if selection.color_id ~= nil and data.color_id == selection.color_id then
      self._cur_exchange_color = data
      break
    end
  end
  self:_cache_current_part_selection()
end

function M:refresh_after_appearance()
  self._suppress_sys_click = true
  if hair_dyeing_module:get_cur_style_id() <= 0 then
    hair_dyeing_module:sync_cur_style_id_from_appearance()
  end
  if self._cur_dye_part == hair_dyeing_module.dye_part.region and not hair_dyeing_module:has_gradient_region() then
    self._cur_dye_part = hair_dyeing_module.dye_part.global
  end
  self:_refresh_region_tog_items()
  self:_refresh_exchange_data_keep_selection()
  self:_refresh_coin_items()
  self:_ensure_sys_group_allow_switch_off()
  self._suppress_sys_click = false
  self:apply_region_brightness_pulse()
end

function M:refresh(entry_data)
  self._suppress_sys_click = true
  self:_reset_dye_session_state()
  if hair_dyeing_module:get_cur_style_id() <= 0 then
    hair_dyeing_module:sync_cur_style_id_from_appearance()
  end
  self._cur_dye_part = hair_dyeing_module.dye_part.global
  self:_refresh_region_tog_items()
  self._all_systems = hair_dyeing_module:get_exchange_color_systems(self:_get_cur_style_id(), self:_get_region_id_for_color_filter()) or {}
  self:_cache_current_part_selection()
  self:_refresh_coin_items()
  self:_refresh_color_sys_list()
  self:_ensure_sys_group_allow_switch_off()
  self:_clear_auto_sys_selection()
  self:_refresh_color_list()
  self:_refresh_cost()
  self._suppress_sys_click = false
  self:apply_region_brightness_pulse()
end

function M:_ensure_sys_group_allow_switch_off()
  local first = self._sys_items and self._sys_items[1] or nil
  local tog = first and first._tog_item or nil
  if is_null(tog) or is_null(tog.group) then
    return
  end
  tog.group.allowSwitchOff = true
end

function M:_clear_auto_sys_selection()
  self._cur_sys_tag = nil
  self._cur_exchange_color = nil
  self:_cache_current_part_selection()
  for _, item in ipairs(self._sys_items or {}) do
    item:set_selected(false)
  end
end

function M:_init_coin_items()
  self._coin_items = self._coin_items or {}
  local coin_ids = self:_get_coin_item_ids()
  local parent = self._trans_coin_item.parent
  for i, coin_id in ipairs(coin_ids) do
    local trans = self._trans_coin_item
    if 1 < i then
      local go = UIUtil.load_prefab_set_parent(self._trans_coin_item.gameObject, parent)
      trans = go.transform
    end
    local item = self:add_panel(coin_item_view_cls, trans, {
      coin_id = coin_id,
      auto_update = true,
      show_detail = true,
      extra_events = {
        EventID.LuaChangePacket
      }
    })
    self._coin_items[i] = item
  end
  self._btn_help.transform:SetAsLastSibling()
end

function M:_get_coin_item_ids()
  return {
    hair_dyeing_module.currency.inspiration_active,
    hair_dyeing_module.currency.inspiration_paid,
    hair_dyeing_module.currency.rainbow_inspiration
  }
end

function M:_refresh_coin_items()
  for _, item in ipairs(self._coin_items or {}) do
    item:refresh()
  end
end

function M:_preview_cur_color()
  if self._cur_exchange_color == nil then
    return
  end
  hair_dyeing_module:preview_hair_color(self._cur_exchange_color.color_id, self._cur_dye_part)
end

function M:_init_region_tog_items()
  self._region_tog_items = {
    self:_create_region_tog_item(self._tog_global_color, hair_dyeing_module.dye_part.global),
    self:_create_region_tog_item(self._tog_local_color, hair_dyeing_module.dye_part.region)
  }
end

function M:_create_region_tog_item(toggle, dye_part)
  local item = self:add_panel(region_tog_item_cls, toggle.transform, {toggle = toggle})
  item:setup(dye_part, pack(self, M._on_region_selected))
  return item
end

function M:_refresh_region_tog_items()
  for _, item in ipairs(self._region_tog_items or {}) do
    item:refresh(item:get_dye_part() == self._cur_dye_part)
  end
end

function M:_on_region_selected(dye_part)
  if dye_part == nil or dye_part == self._cur_dye_part then
    return
  end
  if dye_part == hair_dyeing_module.dye_part.region and not hair_dyeing_module:has_gradient_region() then
    UIUtil.show_tips_by_text_id("HairDyeing_UI_Tips1")
    self:_refresh_region_tog_items()
    return
  end
  self._cur_dye_part = dye_part
  self:_refresh_region_tog_items()
  self:_refresh_exchange_data_keep_selection()
  self:apply_region_brightness_pulse()
end

function M:apply_region_brightness_pulse()
  hair_dyeing_module:set_region_brightness_pulse(self._cur_dye_part, true)
end

function M:_refresh_color_sys_list()
  self._sys_items = self._sys_items or {}
  local parent = self._trans_color_sys_item.parent
  local max_num = math.max(#self._sys_items, #self._all_systems)
  for i = 1, max_num do
    local data = self._all_systems[i]
    local item = self._sys_items[i]
    if item == nil and data then
      local go = i == 1 and self._trans_color_sys_item.gameObject or UIUtil.load_prefab_set_parent(self._trans_color_sys_item.gameObject, parent)
      item = self:add_panel(color_sys_item_cls, go.transform)
      item:set_on_click(function(sys_tag, is_on)
        self:_on_sys_click(sys_tag, is_on)
      end)
      self._sys_items[i] = item
    end
    if item then
      if data then
        item:set_active(true)
        item:refresh({
          sys_id = data.tag,
          display_color = data.display_color,
          icon_path = data.icon_path,
          owned = false,
          selected = self._cur_sys_tag == data.tag
        })
      else
        item:set_active(false)
      end
    end
  end
end

function M:_on_sys_click(sys_tag, is_on)
  if self._suppress_sys_click then
    return
  end
  if not is_on then
    if self._cur_sys_tag == sys_tag then
      self._cur_sys_tag = nil
      self._cur_exchange_color = nil
      self:_cache_current_part_selection()
      self:_refresh_color_list()
      self:_refresh_cost()
    end
    return
  end
  self._cur_sys_tag = sys_tag
  local system = self:_get_system_by_tag(sys_tag)
  self._cur_exchange_color = system and system.colors and system.colors[1] or nil
  self:_cache_current_part_selection()
  for _, item in ipairs(self._sys_items or {}) do
    item:set_selected(item:get_sys_id() == sys_tag)
  end
  self:_refresh_color_list()
  self:_preview_cur_color()
  self:_refresh_cost()
end

function M:_get_system_by_tag(sys_tag)
  for _, system in ipairs(self._all_systems or {}) do
    if system.tag == sys_tag then
      return system
    end
  end
  return nil
end

function M:_refresh_target_text()
  local system = self:_get_system_by_tag(self._cur_sys_tag)
  UIUtil.set_text_by_id(self._txt_target, "HairDyeing_Exchange_SelectTargetColor", system and system.label or "")
end

function M:_get_cur_style_id()
  return hair_dyeing_module:get_cur_style_id()
end

function M:_get_region_id_for_color_filter()
  return self._cur_dye_part == hair_dyeing_module.dye_part.region and 2 or 1
end

function M:_is_exchange_color_unlocked(color_data)
  if color_data == nil then
    return false
  end
  return hair_dyeing_module:is_color_owned(self:_get_cur_style_id(), self._cur_dye_part, color_data.color_id)
end

function M:_refresh_exchange_data_keep_selection()
  self._all_systems = hair_dyeing_module:get_exchange_color_systems(self:_get_cur_style_id(), self:_get_region_id_for_color_filter()) or {}
  self:_restore_current_part_selection()
  self:_refresh_color_sys_list()
  self:_refresh_color_list()
  self:_refresh_cost()
  self:_preview_cur_color()
end

function M:_refresh_color_list()
  self:_update_state_group()
  self:_refresh_target_text()
  local system = self:_get_system_by_tag(self._cur_sys_tag)
  local colors = system and system.colors or {}
  self._color_items = self._color_items or {}
  if #colors == 0 and #self._color_items == 0 and not is_null(self._trans_color_item) then
    UIUtil.set_active(self._trans_color_item, false)
  end
  local parent = self._trans_color_item.parent
  local max_num = math.max(#self._color_items, #colors)
  for i = 1, max_num do
    local data = colors[i]
    local item = self._color_items[i]
    if item == nil and data then
      local go = i == 1 and self._trans_color_item.gameObject or UIUtil.load_prefab_set_parent(self._trans_color_item.gameObject, parent)
      item = self:add_panel(color_item_cls, go.transform)
      item:set_on_click(function(color_id)
        self:_on_color_click(color_id)
      end)
      self._color_items[i] = item
    end
    if item then
      if data then
        item:set_active(true)
        item:refresh({
          color_id = data.color_id,
          owned = self:_is_exchange_color_unlocked(data),
          selected = self._cur_exchange_color ~= nil and self._cur_exchange_color.color_id == data.color_id
        })
      else
        item:set_active(false)
      end
    end
  end
end

function M:_update_state_group()
  self._ui_state_group:SetState(self._cur_sys_tag == nil and 0 or 1)
end

function M:_on_color_click(color_id)
  local system = self:_get_system_by_tag(self._cur_sys_tag)
  for _, data in ipairs(system and system.colors or {}) do
    if data.color_id == color_id then
      self._cur_exchange_color = data
      break
    end
  end
  self:_cache_current_part_selection()
  for _, item in ipairs(self._color_items or {}) do
    item:set_selected(item:get_color_id() == color_id)
  end
  self:_preview_cur_color()
  self:_refresh_cost()
end

function M:_refresh_cost()
  local material_id = self:_get_cur_material_id()
  if material_id and 0 < material_id then
    item_module:set_item_icon(self._img_icon_coin, material_id, nil, nil, self:get_load_proxy())
  end
  local cost = self:_get_cur_cost()
  local owned = material_id and hair_dyeing_module:get_material_num(material_id) or 0
  local cost_text = cost > owned and string.format("<style=TextWarning_Light>%d</style>", cost) or tostring(cost)
  UIUtil.set_text(self._txt_cost_num, cost_text)
  self:_refresh_exchange_btn_state()
end

function M:_refresh_exchange_btn_state()
  local has_selected_color = self._cur_exchange_color ~= nil
  local is_owned = has_selected_color and self:_is_exchange_color_unlocked(self._cur_exchange_color)
  UIUtil.set_active(self._btn_exchange, has_selected_color and not is_owned)
  UIUtil.set_active(self._trans_owned, is_owned)
  if not has_selected_color or is_owned or is_null(self._ui_transition_btn) then
    return
  end
  local state = self:_is_material_enough() and exchange_btn_transition_state.normal or exchange_btn_transition_state.disabled
  self._ui_transition_btn:SetState(state)
end

function M:_get_cur_cost()
  if self._cur_exchange_color == nil then
    return 0
  end
  return self._cur_exchange_color.cost_num or 0
end

function M:_get_cur_material_id()
  if self._cur_exchange_color == nil then
    return nil
  end
  return self._cur_exchange_color.cost_item_id
end

function M:_is_material_enough()
  local material_id = self:_get_cur_material_id()
  if material_id == nil or material_id <= 0 then
    return false
  end
  return hair_dyeing_module:is_material_enough(material_id, self:_get_cur_cost())
end

function M:_on_btn_exchange()
  if not hair_dyeing_module:is_current_style_dyeable() then
    hair_dyeing_module:show_cannot_dye_prompt(self._on_haircut)
    return
  end
  if self._cur_exchange_color == nil then
    UIUtil.show_tips_by_text_id("HairDyeing_Exchange_SelectColor")
    return
  end
  if self:_is_exchange_color_unlocked(self._cur_exchange_color) then
    return
  end
  if not self:_is_material_enough() then
    local material_id = self:_get_cur_material_id()
    local material_name = material_id and item_module:get_item_name_by_id(material_id) or ""
    UIUtil.show_tips_by_text_id("HairDyeing_Exchange_NotEnough1", material_name)
    return
  end
  local color_cfg = self._cur_exchange_color.color_cfg
  hair_dyeing_module:request_exchange_hair_color({
    style_id = self:_get_cur_style_id(),
    dye_part = self._cur_dye_part,
    region = self:_get_region_id_for_color_filter(),
    color_id = self._cur_exchange_color.color_id,
    color_cfg_id = color_cfg and color_cfg.color or 0,
    inspiration_item_id = self:_get_cur_material_id(),
    inspiration_item_count = self:_get_cur_cost(),
    exchange_type = self._cur_exchange_color.exchange_type
  }, function(_rsp)
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
