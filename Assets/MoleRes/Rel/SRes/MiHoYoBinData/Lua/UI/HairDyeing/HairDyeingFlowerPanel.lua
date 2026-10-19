local M = G.Class("HairDyeingFlowerPanel", G.UIPanel)
local base = G.UIPanel
local sel_flower_item_cls = "UI/HairDyeing/HairDyeingSelectedFlowerItem"
local color_item_cls = "UI/HairDyeing/HairDyeingColorItem"
local coin_item_cls = "UI/HairDyeing/HairDyeingCoinItem"
local lite_common_bag_cls = "UI/HairDyeing/HairDyeingFlowerBagPanel"
local flower_detail_panel_cls = "UI/HairDyeing/HairDyeingFlowerDetailPanel"
local dye_button_cd = 0.5
local flower_selection_state = {
  no_selection = 0,
  has_target_color = 1,
  no_target_color = 2
}

function M:init()
  base.init(self)
  self._is_hide_close_listener = false
  self.config.prefab_path = hair_dyeing_module.ui_prefab_path.flower
  self._sel_items = nil
  self._preview_color_items = nil
  self._preview_color_id = nil
  self._flower_color_id = nil
  self._selected_ids = nil
  self._active_coin_item = nil
  self._flower_detail_panel = nil
  self._detail_item_id = nil
  self._on_back = nil
  self._on_haircut = nil
  self._dye_button_cd_co = nil
  self._is_dye_button_cooling_down = false
  self.is_need_lock_other_item = false
end

function M:on_create()
  base.on_create(self)
  self._selected_ids = {}
  self._sel_items = {}
  self._preview_color_items = {}
  if not is_null(self._trans_color_item) then
    local preview_item = self:add_panel(color_item_cls, self._trans_color_item)
    preview_item:set_active(false)
    self._preview_color_items[1] = preview_item
  end
  self:bind_callback(self._btn_exchange_dye, pack(self, M._on_btn_exchange))
  self:bind_callback(self._btn_dye_haircut, pack(self, M._on_btn_haircut))
  self:bind_callback(self._btn_start_dyeing, pack(self, M._on_btn_start))
  self:bind_callback(self._btn_back, pack(self, M._on_btn_back))
  self:bind_callback(self._btn_help, pack(self, M._on_btn_help))
  if not is_null(self._btn_filter) then
    self:bind_callback(self._btn_filter, pack(self, M._on_btn_filter))
  end
  self._active_coin_item = self:add_panel(coin_item_cls, self._trans_coin_item)
  self._active_coin_item:refresh(hair_dyeing_module.currency.inspiration_active)
  local detail_panel_trans = self._trans_lite_item_detail_panel or self._trans_lite_item_detail
  if not is_null(detail_panel_trans) then
    self._flower_detail_panel = self:add_panel(flower_detail_panel_cls, detail_panel_trans)
    self._flower_detail_panel:refresh(nil)
  end
  self.common_bag_panel = self:add_panel(lite_common_bag_cls, self._trans_lite_common_bag)
  self:_setup_bag()
end

function M:on_disable()
  base.on_disable(self)
  if not is_null(self.common_bag_panel) then
    self.common_bag_panel:clear_all_select_item_data()
  end
end

function M:on_destroy()
  self:_stop_dye_button_cd()
  self._sel_items = nil
  self._preview_color_items = nil
  self._flower_color_id = nil
  self._active_coin_item = nil
  self._flower_detail_panel = nil
  self._detail_item_id = nil
  self.common_bag_panel = nil
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  
  local function refresh_active_coin()
    if self._active_coin_item then
      self._active_coin_item:refresh_num()
    end
  end
  
  self:add_evt_listener(EventID.UpdateCoinData, refresh_active_coin)
  self:add_evt_listener(EventID.LuaChangePacket, function()
    refresh_active_coin()
    if not is_null(self.common_bag_panel) then
      self.common_bag_panel:refresh_bag()
    end
    if not self:_remove_insufficient_selected_flowers() then
      self:_refresh_flower_detail(self._detail_item_id)
    end
  end)
  self:add_evt_listener(EventID.LuaHairDyeSolidFlowerResult, pack(self, M._on_dye_result))
  self:add_evt_listener(EventID.LuaHairDyeGradientFlowerResult, pack(self, M._on_dye_result))
  self:add_lua_listener(lua_event_module.event_type.on_hair_dye_color_owned_changed, pack(self, M._refresh_preview_colors))
end

function M:_on_dye_result(rsp)
  if rsp == nil or rsp.Retcode ~= 0 then
    return
  end
  if self._active_coin_item then
    self._active_coin_item:refresh_num()
  end
  if not self:_remove_insufficient_selected_flowers() then
    self:_refresh_preview_colors()
    self:_refresh_flower_detail(self._detail_item_id)
  end
  self:_update_state_group()
  self:_start_dye_button_cd()
end

function M:set_on_back(callback)
  self._on_back = callback
end

function M:set_on_haircut(callback)
  self._on_haircut = callback
end

function M:clear_color_preview()
  self._preview_color_id = nil
  for _, item in ipairs(self._preview_color_items or {}) do
    item:set_selected(false)
  end
end

function M:get_selected_flower_count()
  return #(self._selected_ids or {})
end

function M:is_flower_selected(item_id)
  for _, selected_id in ipairs(self._selected_ids or {}) do
    if selected_id == item_id then
      return true
    end
  end
  return false
end

function M:_clear_selected_flowers()
  self._selected_ids = {}
  self._flower_color_id = nil
  self._preview_color_id = nil
  if not is_null(self.common_bag_panel) then
    self.common_bag_panel:clear_all_select_item_data()
    self.common_bag_panel:refresh_title()
  end
  self:_refresh_selected_list()
  self:_refresh_preview_colors()
  self:_refresh_flower_detail(nil)
  self:_refresh_cost()
  self:_update_state_group()
end

function M:_remove_insufficient_selected_flowers()
  local retained_flower_ids = {}
  local has_insufficient_flower = false
  for _, item_id in ipairs(self._selected_ids or {}) do
    if hair_dyeing_module:is_material_enough(item_id, self:_get_flower_cost(item_id)) then
      table.insert(retained_flower_ids, item_id)
    else
      has_insufficient_flower = true
    end
  end
  if not has_insufficient_flower then
    return false
  end
  self._selected_ids = retained_flower_ids
  self._flower_color_id = nil
  self._preview_color_id = nil
  if not is_null(self.common_bag_panel) then
    self.common_bag_panel:clear_all_select_item_data()
    self.common_bag_panel:refresh_bag()
  end
  self:_on_selection_changed()
  local detail_item_id = self:is_flower_selected(self._detail_item_id) and self._detail_item_id or self._selected_ids[#self._selected_ids]
  self:_refresh_flower_detail(detail_item_id)
  return true
end

function M:refresh()
  self:_clear_selected_flowers()
  if not is_null(self.common_bag_panel) then
    self.common_bag_panel:set_filter_tags(nil)
    self.common_bag_panel:set_filter_ranks(nil)
    self.common_bag_panel:refresh_data(back_bag_module.bag_show_type.hair_dye_flower)
    self.common_bag_panel:refresh_ui()
  end
  if self._active_coin_item then
    self._active_coin_item:refresh_num()
  end
  self:apply_region_brightness_pulse()
end

function M:_setup_bag()
  if is_null(self.common_bag_panel) then
    return
  end
  self.common_bag_panel:clear_all_select_item_data()
  self.common_bag_panel:set_extra_data(back_bag_module.bag_main_type.normal)
  self.common_bag_panel:set_cur_item_select_type(back_bag_module.packet_item_select_type.fixed_num_multi_selected)
  self.common_bag_panel:refresh_data(back_bag_module.bag_show_type.hair_dye_flower)
  self.common_bag_panel:refresh_ui()
end

local function _item_id_of(server_data)
  if is_null(server_data) then
    return nil
  end
  return server_data.ConfigId
end

function M:select_item_by_multi_selected(server_data)
  local item_id = _item_id_of(server_data)
  if item_id == nil then
    return false
  end
  for _, id in ipairs(self._selected_ids) do
    if id == item_id then
      return false
    end
  end
  if #self._selected_ids >= hair_dyeing_module.max_flower_select then
    UIUtil.show_tips_by_text_id("HairDyeing_Flower_MaxSelect", hair_dyeing_module.max_flower_select)
    return false
  end
  table.insert(self._selected_ids, item_id)
  self:_on_selection_changed()
  return true
end

function M:unselect_item_by_multi_selected(server_data)
  local item_id = _item_id_of(server_data)
  if item_id == nil then
    return false
  end
  table.removewhere(self._selected_ids, function(id)
    return id == item_id
  end)
  self:_on_selection_changed()
  return true
end

function M:_on_selection_changed()
  if not is_null(self.common_bag_panel) then
    self.common_bag_panel:refresh_title()
  end
  self._preview_color_id = nil
  self:_refresh_selected_list()
  self:_refresh_preview_colors()
  self:_refresh_cost()
  self:_update_state_group()
end

function M:refresh_selected_ui(item_data)
  local server_data = item_data and item_data.server_data or nil
  local item_id = _item_id_of(server_data)
  if item_id == nil then
    item_id = self._selected_ids[#self._selected_ids]
  end
  self:_refresh_flower_detail(item_id, server_data)
end

function M:_refresh_flower_detail(item_id, server_data)
  if is_null(self._flower_detail_panel) then
    return
  end
  if item_id ~= nil and 0 < item_id and 0 >= hair_dyeing_module:get_material_num(item_id) then
    item_id = nil
    server_data = nil
  end
  self._detail_item_id = item_id
  self._flower_detail_panel:refresh({
    item_id = item_id or 0,
    server_data = server_data
  })
end

function M:bag_panel_tog_change(cur_tog_type)
end

function M:get_fixed_select_num(server_data)
  if is_null(server_data) then
    return 1
  end
  return self:_get_flower_cost(server_data.ConfigId)
end

function M:_get_flower_cost(config_id)
  local item_cfg = ExcelDataUtil.get_value(typeof(BItemCfg), config_id)
  local rank = item_cfg and item_cfg.rank or 0
  local flower_cfg = ExcelDataUtil.get_value(typeof(BFlowerCfg), rank + 1)
  return flower_cfg and flower_cfg.cost or 1
end

function M:_get_flower_quality_name(config_id)
  local item_cfg = config_id and ExcelDataUtil.get_value(typeof(BItemCfg), config_id)
  if is_null(item_cfg) then
    return nil
  end
  local rank_cfg = ExcelDataUtil.get_value(typeof(BChangeClothesRankCfg), item_cfg.rank + 1)
  return rank_cfg and rank_cfg.name or nil
end

function M:_refresh_selected_list()
  self._sel_items = self._sel_items or {}
  local max_num = math.max(#self._sel_items, #self._selected_ids)
  for i = 1, max_num do
    local item_id = self._selected_ids[i]
    local item = self._sel_items[i]
    if item == nil and item_id then
      local go = self._now_select_list_binder:AddItem(0)
      item = self:add_panel(sel_flower_item_cls, go)
      self._sel_items[i] = item
    end
    if item then
      if item_id then
        item:set_active(true)
        item:refresh({
          item_id = item_id,
          num = self:_get_flower_cost(item_id)
        })
      else
        item:set_active(false)
      end
    end
  end
end

function M:_get_selected_flower_color_cfgs()
  return hair_dyeing_module:get_active_color_cfgs_by_flower_ids(self._selected_ids)
end

function M:_refresh_preview_colors()
  if is_null(self._trans_color_item) then
    return
  end
  local color_cfgs = self:_get_selected_flower_color_cfgs()
  local color_cfg = color_cfgs[1]
  self._flower_color_id = color_cfg and color_cfg.color or nil
  local color_block_ids = color_cfg and hair_dyeing_module:get_colors_by_color_sys(color_cfg) or nil
  local color_id_list = not is_null(color_block_ids) and list_to_table(color_block_ids) or {}
  if not_null(color_cfg) then
    UIUtil.set_text_by_id(self._txt_random_get_color, "HairDyeing_Flower_RandomColor", color_cfg.name)
  else
    UIUtil.set_text_by_id(self._txt_random_get_color, "HairDyeing_Flower_ColorGroupInvalid")
  end
  local preview_color_items = self._preview_color_items or {}
  self._preview_color_items = preview_color_items
  local color_count = #color_id_list
  local max_num = math.max(#preview_color_items, color_count)
  local parent = self._trans_color_item.parent
  local style_id = hair_dyeing_module:get_cur_style_id()
  local dye_part = hair_dyeing_module.dye_part.global
  for i = 1, max_num do
    local color_id = color_id_list[i]
    local item = preview_color_items[i]
    if item == nil and color_id ~= nil then
      local go = UIUtil.load_prefab_set_parent(self._trans_color_item.gameObject, parent)
      item = self:add_panel(color_item_cls, go.transform)
      preview_color_items[i] = item
    end
    if item ~= nil then
      item:set_on_click(function(clicked_color_id)
        self:_on_preview_color_click(clicked_color_id)
      end)
      if color_id ~= nil then
        item:set_active(true)
        item:refresh({
          color_id = color_id,
          owned = hair_dyeing_module:is_color_owned(style_id, dye_part, color_id),
          selected = self._preview_color_id == color_id,
          display_only = true,
          preview_only = true
        })
      else
        item:set_active(false)
      end
    end
  end
  Canvas.ForceUpdateCanvases()
  LayoutRebuilder.ForceRebuildLayoutImmediate(parent)
end

function M:_on_preview_color_click(color_id)
  self._preview_color_id = color_id
  for _, item in ipairs(self._preview_color_items or {}) do
    item:set_selected(item:get_color_id() == color_id)
  end
  hair_dyeing_module:preview_hair_color(color_id, hair_dyeing_module.dye_part.global)
end

function M:_get_selected_flower_counts()
  local counts = {}
  for _, item_id in ipairs(self._selected_ids or {}) do
    table.insert(counts, self:_get_flower_cost(item_id))
  end
  return counts
end

function M:subtract_select_item_num(server_data, _current_num)
  self:unselect_item_by_multi_selected(server_data)
  return 0
end

function M:apply_region_brightness_pulse()
  hair_dyeing_module:set_region_brightness_pulse(hair_dyeing_module.dye_part.global, true)
end

function M:_refresh_cost()
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
  local state = flower_selection_state.no_selection
  if #self._selected_ids > 0 then
    state = self._flower_color_id ~= nil and flower_selection_state.has_target_color or flower_selection_state.no_target_color
  end
  self._ui_state_group:SetState(state)
  if not is_null(self._btn_start_dyeing) then
    local is_dyeable = hair_dyeing_module:is_current_style_dyeable()
    local can_start_dyeing = state == flower_selection_state.has_target_color
    self._btn_start_dyeing.interactable = not self._is_dye_button_cooling_down and (not is_dyeable or can_start_dyeing)
  end
end

function M:refresh_dyeable_state()
  self:_update_state_group()
end

function M:_is_material_enough()
  if #self._selected_ids == 0 then
    return false
  end
  for _, id in ipairs(self._selected_ids) do
    local cost = self:_get_flower_cost(id)
    if not hair_dyeing_module:is_material_enough(id, cost) then
      return false
    end
  end
  return true
end

function M:show_not_enough_tip(server_data)
  local item_id = _item_id_of(server_data)
  if item_id == nil then
    for _, id in ipairs(self._selected_ids or {}) do
      if not hair_dyeing_module:is_material_enough(id, self:_get_flower_cost(id)) then
        item_id = id
        break
      end
    end
  end
  if item_id == nil then
    UIUtil.show_tips_by_text_id("HairDyeing_Flower_NotEnough")
    return
  end
  local quality_name = self:_get_flower_quality_name(item_id)
  if quality_name == nil or quality_name == "" then
    UIUtil.show_tips_by_text_id("HairDyeing_Flower_NotEnough")
    return
  end
  UIUtil.show_tips_by_text_id("HairDyeing_UI_Tips2", quality_name, self:_get_flower_cost(item_id))
end

function M:_on_btn_exchange()
  if not hair_dyeing_module:is_current_style_dyeable() then
    hair_dyeing_module:show_cannot_dye_prompt(self._on_haircut)
    return
  end
  hair_dyeing_module:open_exchange_dialog({})
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
  if #self._selected_ids == 0 then
    UIUtil.show_tips_by_text_id("HairDyeing_Flower_SelectFirst")
    return
  end
  if not self:_is_material_enough() then
    self:show_not_enough_tip()
    self:_remove_insufficient_selected_flowers()
    return
  end
  local color_id = self._flower_color_id
  if color_id == nil then
    UIUtil.show_tips_by_text_id("HairDyeing_Flower_ColorGroupInvalid")
    return
  end
  hair_dyeing_module:set_dye_mode(hair_dyeing_module.dye_mode.flower)
  hair_dyeing_module:set_dye_type(hair_dyeing_module.dye_type.pure)
  hair_dyeing_module:set_dye_part(hair_dyeing_module.dye_part.global)
  hair_dyeing_module:set_selected_color_id(color_id)
  hair_dyeing_module:set_selected_flowers(self._selected_ids, self:_get_selected_flower_counts())
  hair_dyeing_module:request_dye(hair_dyeing_module:build_dye_req(), function(rsp)
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

function M:_on_btn_filter()
  local cur_tags = not is_null(self.common_bag_panel) and self.common_bag_panel.get_filter_tags and self.common_bag_panel:get_filter_tags() or nil
  hair_dyeing_module:open_flower_color_filter({
    selected_tags = cur_tags,
    on_confirm = function(tags)
      self:on_filter_tags_changed(tags)
    end
  })
end

function M:on_filter_tags_changed(tags)
  if not is_null(self.common_bag_panel) and self.common_bag_panel.set_filter_tags then
    self.common_bag_panel:set_filter_tags(tags)
  end
end

return M
