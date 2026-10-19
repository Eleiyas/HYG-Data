hair_dyeing_module = hair_dyeing_module or {}

local function _loc_or(text_id, fallback)
  local text = UIUtil.get_text_by_id(text_id)
  if not string.is_valid(text) or text == text_id then
    return fallback
  end
  return text
end

function hair_dyeing_module:add_event()
  hair_dyeing_module:remove_event()
  self._events = {}
  self._events[EventID.LuaHairDyeSolidFlowerResult] = pack(self, hair_dyeing_module._handle_solid_flower_result)
  self._events[EventID.LuaHairDyeSolidDyeResult] = pack(self, hair_dyeing_module._handle_solid_dye_result)
  self._events[EventID.LuaHairDyeGradientFlowerResult] = pack(self, hair_dyeing_module._handle_gradient_flower_result)
  self._events[EventID.LuaHairDyeGradientDyeResult] = pack(self, hair_dyeing_module._handle_gradient_dye_result)
  self._events[EventID.LuaHairDyeExchangeInspirationResult] = pack(self, hair_dyeing_module._handle_exchange_inspiration_result)
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaAddListener(event_id, fun)
  end
end

function hair_dyeing_module:remove_event()
  if self._events == nil then
    return
  end
  for event_id, fun in pairs(self._events) do
    EventCenter.LuaRemoveListener(event_id, fun)
  end
  self._events = nil
end

function hair_dyeing_module:clear_dye_session()
  self:stop_region_brightness_pulse()
  self._cur_style_id = nil
  self._cur_dye_mode = nil
  self._cur_dye_part = nil
  self._cur_dye_type = nil
  self._selected_flower_ids = nil
  self._selected_flower_counts = nil
  self._selected_color_id = nil
  self._exchange_on_result = nil
  self._session_owned_colors = nil
end

function hair_dyeing_module:set_region_brightness_pulse(dye_part, enable)
  self:stop_region_brightness_pulse()
  if not enable then
    return
  end
  if dye_part == self.dye_part.region then
    CsAppearanceManagerUtil.SetTempPlayerHairRegionBrightnessPulse(2, true)
  else
    CsAppearanceManagerUtil.SetTempPlayerHairRegionBrightnessPulse(1, true)
    CsAppearanceManagerUtil.SetTempPlayerHairRegionBrightnessPulse(2, true)
  end
end

function hair_dyeing_module:stop_region_brightness_pulse()
  CsAppearanceManagerUtil.SetTempPlayerHairRegionBrightnessPulse(0, false)
end

function hair_dyeing_module:open_hair_dyeing_page(entry_data)
  self:clear_dye_session()
  if entry_data and entry_data.style_id then
    self:set_cur_style_id(entry_data.style_id)
  end
  UIManagerInstance:open("UI/HairDyeing/HairDyeingPage", entry_data or {})
end

function hair_dyeing_module:test_close_hair_dyeing_page()
  local page = UIManagerInstance:is_show("UI/HairDyeing/HairDyeingPage")
  if page ~= nil and page.is_active then
    UIManagerInstance:close(page.guid)
  end
end

function hair_dyeing_module:open_exchange_dialog(entry_data)
  local page = UIManagerInstance:is_show("UI/HairDyeing/HairDyeingPage")
  if page ~= nil and page.is_active and page.show_exchange then
    page:show_exchange(entry_data or {})
    return
  end
  Logger.LogWarning("[HairDyeing] HairDyeingPage 未打开，无法进入兑换工作区")
end

function hair_dyeing_module:open_flower_color_filter(entry_data)
  UIManagerInstance:open("UI/HairDyeing/HairDyeingFlowerFilterDialog", entry_data or {})
end

local default_flower_exchange_id = 1

function hair_dyeing_module:get_flower_exchange_config(exchange_id)
  exchange_id = exchange_id or default_flower_exchange_id
  local consume_ranks = list_to_table(CsDyeingModuleUtil.GetHairDyeRabbitExchangeConsumeRanks(exchange_id)) or {}
  local data = {
    exchange_id = exchange_id,
    required_flower_count = CsDyeingModuleUtil.GetHairDyeRabbitExchangeConsumeCount(exchange_id),
    reward_item_id = CsDyeingModuleUtil.GetHairDyeRabbitExchangeRewardItemId(exchange_id),
    reward_item_count = CsDyeingModuleUtil.GetHairDyeRabbitExchangeRewardCount(exchange_id),
    max_exchange_count = CsDyeingModuleUtil.GetHairDyeRabbitExchangeLimit(exchange_id),
    exchange_count = CsDyeingModuleUtil.GetHairDyeRabbitExchangeCount(exchange_id),
    exchange_time = CsDyeingModuleUtil.GetHairDyeRabbitExchangeTime(exchange_id),
    remaining_exchange_count = CsDyeingModuleUtil.GetHairDyeRabbitExchangeRemainingCount(exchange_id),
    consume_ranks = consume_ranks
  }
  if data.required_flower_count <= 0 or data.reward_item_id <= 0 or data.reward_item_count <= 0 or data.max_exchange_count <= 0 or #consume_ranks <= 0 then
    return nil
  end
  return data
end

function hair_dyeing_module:request_flower_exchange(exchange_id, material_ids, material_counts)
  return CsDyeingModuleUtil.RequestHairDyeRabbitExchange(exchange_id or default_flower_exchange_id, material_ids, material_counts)
end

function hair_dyeing_module:open_flower_exchange_page(entry_data)
  entry_data = entry_data or {}
  local exchange_id = entry_data.exchange_id or default_flower_exchange_id
  local config = self:get_flower_exchange_config(exchange_id)
  if config == nil then
    UIUtil.show_tips_by_text_id("HairDyeing_FlowerExchange_NotReady")
    return
  end
  if config.remaining_exchange_count <= 0 then
    UIUtil.show_tips_by_text_id("HairDyeing_FlowerExchange_CycleLimit")
    return
  end
  entry_data.exchange_id = exchange_id
  UIManagerInstance:open("UI/HairDyeing/HairDyeingFlowerExchangePage", entry_data)
end

function hair_dyeing_module:get_material_num(item_id)
  return back_bag_module:get_coin_or_item_num(item_id)
end

function hair_dyeing_module:is_material_enough(item_id, need_num)
  need_num = need_num or 0
  return need_num <= 0 or need_num <= self:get_material_num(item_id)
end

function hair_dyeing_module:set_cur_style_id(style_id)
  local prev_style_id = self._cur_style_id
  self._cur_style_id = style_id
  if prev_style_id ~= nil and prev_style_id ~= style_id then
    self:_notify_color_owned_changed()
  end
end

function hair_dyeing_module:sync_cur_style_id_from_appearance()
  local style_id = CsDyeingModuleUtil.GetCurrentHairDyeStyleId() or 0
  if 0 < style_id then
    self:set_cur_style_id(style_id)
  else
    self:set_cur_style_id(0)
  end
  return self:get_cur_style_id()
end

function hair_dyeing_module:mark_need_refresh_from_appearance()
  self._need_refresh_from_appearance = true
end

function hair_dyeing_module:consume_need_refresh_from_appearance()
  local need_refresh = self._need_refresh_from_appearance == true
  self._need_refresh_from_appearance = false
  return need_refresh
end

function hair_dyeing_module:get_cur_style_id()
  return self._cur_style_id or 0
end

function hair_dyeing_module:is_current_style_dyeable()
  if CsDyeingModuleUtil.IsFailHairEquipped() == true then
    return false
  end
  local style_id = self:get_cur_style_id()
  return 0 < style_id and CsDyeingModuleUtil.IsHasHairAssetData(style_id) == true
end

function hair_dyeing_module:show_cannot_dye_prompt(on_go_salon)
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(_loc_or("HairDyeing_Fail_NeedChangeHair", "当前发型无法染色，请先更换发型。"), _loc_or("HairDyeing_Fail_GoAppearance", "去发型屋"), UIUtil.get_text_by_id("Common_Cancel"), UIUtil.get_text_by_id("CommonRechargePromptDialog_Title"))
  popup:set_callbacks(function()
    if type(on_go_salon) == "function" then
      on_go_salon()
      return
    end
    appearance_module:open_appearance_page_with_preset({
      type = appearance_module.tab_type.dress,
      preset_attrib_type = appearance_module.appearance_attrib_type.hair_style,
      from_hair_dyeing = true
    })
  end)
  popup:show()
end

function hair_dyeing_module:set_dye_mode(dye_mode)
  self._cur_dye_mode = dye_mode
end

function hair_dyeing_module:set_dye_type(dye_type)
  self._cur_dye_type = dye_type
end

function hair_dyeing_module:set_dye_part(dye_part)
  self._cur_dye_part = dye_part
end

function hair_dyeing_module:set_selected_flowers(flower_ids, flower_counts)
  self._selected_flower_ids = flower_ids
  self._selected_flower_counts = flower_counts
end

function hair_dyeing_module:set_selected_color_id(color_id)
  self._selected_color_id = color_id
end

function hair_dyeing_module:preview_hair_color(color_id, dye_part)
  local style_id = self:get_cur_style_id()
  if style_id <= 0 or color_id == nil or color_id <= 0 then
    return false
  end
  local region_id = dye_part == self.dye_part.region and 2 or 1
  return CsAppearanceManagerUtil.PreviewAppearanceColor(style_id, region_id, color_id)
end

function hair_dyeing_module:mark_color_owned(style_id, dye_part, color_id)
  if style_id == nil or style_id <= 0 or color_id == nil or color_id <= 0 then
    return
  end
  dye_part = dye_part or self.dye_part.global
  self._session_owned_colors = self._session_owned_colors or {}
  local color_ids_by_part = self._session_owned_colors[style_id]
  if color_ids_by_part == nil then
    color_ids_by_part = {}
    self._session_owned_colors[style_id] = color_ids_by_part
  end
  local color_ids = color_ids_by_part[dye_part]
  if color_ids == nil then
    color_ids = {}
    color_ids_by_part[dye_part] = color_ids
  end
  color_ids[color_id] = true
  self:_notify_color_owned_changed()
end

function hair_dyeing_module:is_color_owned(style_id, dye_part, color_id)
  local color_ids_by_part = self._session_owned_colors and self._session_owned_colors[style_id] or nil
  local color_ids = color_ids_by_part and color_ids_by_part[dye_part or self.dye_part.global] or nil
  if color_ids ~= nil and color_ids[color_id] == true then
    return true
  end
  return self:is_exchange_color_unlocked(style_id, dye_part, color_id)
end

function hair_dyeing_module:_notify_color_owned_changed()
  lua_event_module:send_event(lua_event_module.event_type.on_hair_dye_color_owned_changed)
end

function hair_dyeing_module:build_dye_req()
  return {
    style_id = self._cur_style_id,
    dye_mode = self._cur_dye_mode,
    dye_part = self._cur_dye_part,
    dye_type = self._cur_dye_type,
    material_ids = self._selected_flower_ids,
    material_counts = self._selected_flower_counts,
    color_id = self._selected_color_id
  }
end

function hair_dyeing_module:_is_repeated_hair_color_result(result_type)
  local rt = self.result_type
  return result_type == rt.inspiration_active or result_type == rt.inspiration_paid
end

function hair_dyeing_module:_is_hair_color_win_tip_result(result_type, color_id)
  local rt = self.result_type
  if result_type == rt.fail or result_type == rt.rainbow_inspiration then
    return false
  end
  if result_type == rt.pure_color or result_type == rt.gradient_color or result_type == rt.inspiration_active or result_type == rt.inspiration_paid then
    return true
  end
  return color_id ~= nil and 0 < color_id
end

function hair_dyeing_module:_get_dye_result_color_id(rsp)
  if rsp == nil then
    return 0
  end
  local dye_part = rsp.dye_part or self._cur_dye_part or self.dye_part.global
  if dye_part == self.dye_part.region then
    if rsp.region_color_id ~= nil and 0 < rsp.region_color_id then
      return rsp.region_color_id
    end
    local region_color_ids = rsp.region_color_ids
    if region_color_ids ~= nil and 0 < #region_color_ids then
      return region_color_ids[1] or 0
    end
  end
  if rsp.color_id ~= nil and 0 < rsp.color_id then
    return rsp.color_id
  end
  if rsp.ColorId ~= nil and 0 < rsp.ColorId then
    return rsp.ColorId
  end
  return 0
end

function hair_dyeing_module:_get_dye_part_name(dye_part)
  if dye_part == self.dye_part.region then
    return UIUtil.get_text_by_id("HairDyeing_Result_Global")
  end
  return UIUtil.get_text_by_id("HairDyeing_Result_Region")
end

function hair_dyeing_module:_build_hair_dyeing_win_tip_data(rsp)
  rsp = rsp or {}
  local color_id = self:_get_dye_result_color_id(rsp)
  if not self:_is_hair_color_win_tip_result(rsp and rsp.result_type or nil, color_id) then
    return nil
  end
  if color_id <= 0 then
    return nil
  end
  local dye_part = rsp.dye_part or self._cur_dye_part or self.dye_part.global
  local color_name = self:get_color_name_by_block_id(color_id) or rsp.color_name or UIUtil.get_text_by_id("HairDyeing_Result_NewColor")
  local is_repeat = self:_is_repeated_hair_color_result(rsp.result_type)
  local repeat_tip
  if is_repeat then
    local repeat_text_id = rsp.result_type == self.result_type.inspiration_paid and "HairDyeing_Result_DuplicateDye" or "HairDyeing_Result_DuplicateFlower"
    repeat_tip = UIUtil.get_text_by_id(repeat_text_id)
  end
  return {
    color_id = color_id,
    color_name = color_name,
    dye_part = dye_part,
    part_name = self:_get_dye_part_name(dye_part),
    is_repeat = is_repeat,
    repeat_tip = repeat_tip
  }
end

function hair_dyeing_module:_show_hair_dyeing_win_tip(rsp, on_close)
  local tip_data = self:_build_hair_dyeing_win_tip_data(rsp or {})
  if tip_data == nil then
    return
  end
  tip_data.on_close = on_close
  hud_info_module:show_hud_info_ui(hud_info_module.hud_ui_type.hair_dyeing_win_tip, tip_data)
end

function hair_dyeing_module:get_colors_by_color_sys(color_cfg)
  local color_group_id = color_cfg.color
  return CsDyeingModuleUtil.GetColorBlockIdsByGroupId(color_group_id) or {}
end

function hair_dyeing_module:request_dye(req_data, on_result)
  req_data = req_data or {}
  if not self:is_current_style_dyeable() then
    Logger.LogWarning("[HairDyeing] request_dye blocked: current style not dyeable, style_id = " .. tostring(self:get_cur_style_id()))
    return
  end
  CsDyeingModuleUtil.RequestDyeHair(req_data.style_id or 0, req_data.dye_mode or 0, req_data.dye_part or 0, req_data.dye_type or 0, req_data.material_ids, req_data.material_counts, req_data.color_id or 0, req_data.region or 0, req_data.target_color_id or 0)
end

function hair_dyeing_module:_handle_solid_flower_result(rsp)
  if not self:_check_dye_result_rsp(rsp) then
    return
  end
  local gain_item_id, gain_item_count = self:_get_rsp_gain_item(rsp)
  local result_type = self.result_type.pure_color
  if rsp.IsExplodedHair == true then
    result_type = self.result_type.fail
  elseif 0 < gain_item_id then
    result_type = self.result_type.inspiration_active
  end
  self:_show_dye_result_data(self:_build_dye_result_data(rsp.ColorId or 0, {}, result_type, gain_item_id, 0, 0, gain_item_count, self.dye_part.global))
end

function hair_dyeing_module:_handle_solid_dye_result(rsp)
  if not self:_check_dye_result_rsp(rsp) then
    return
  end
  local gain_item_id, gain_item_count = self:_get_rsp_gain_item(rsp)
  local rainbow_inspiration_guid = rsp.RainbowInspirationGuid or 0
  local rainbow_inspiration_guid_value = tonumber(tostring(rainbow_inspiration_guid)) or 0
  local result_type = self.result_type.pure_color
  if 0 < rainbow_inspiration_guid_value then
    result_type = self.result_type.rainbow_inspiration
  elseif 0 < gain_item_id then
    result_type = self.result_type.inspiration_paid
  end
  self:_show_dye_result_data(self:_build_dye_result_data(rsp.ColorId or 0, {}, result_type, gain_item_id, rainbow_inspiration_guid, 0, gain_item_count, self.dye_part.global))
end

function hair_dyeing_module:_handle_gradient_flower_result(rsp)
  if not self:_check_dye_result_rsp(rsp) then
    return
  end
  local gain_item_id, gain_item_count = self:_get_rsp_gain_item(rsp)
  local result_type = self.result_type.gradient_color
  if rsp.IsExplodedHair == true then
    result_type = self.result_type.fail
  elseif 0 < gain_item_id then
    result_type = self.result_type.inspiration_active
  end
  self:_show_dye_result_data(self:_build_dye_result_data(rsp.ColorId or 0, self:_build_gradient_region_color_ids(rsp), result_type, gain_item_id, 0, rsp.RegionColorId or 0, gain_item_count, self.dye_part.region))
end

function hair_dyeing_module:_handle_gradient_dye_result(rsp)
  if not self:_check_dye_result_rsp(rsp) then
    return
  end
  local gain_item_id, gain_item_count = self:_get_rsp_gain_item(rsp)
  local result_type = 0 < gain_item_id and self.result_type.inspiration_paid or self.result_type.gradient_color
  self:_show_dye_result_data(self:_build_dye_result_data(rsp.ColorId or 0, self:_build_gradient_region_color_ids(rsp), result_type, gain_item_id, 0, rsp.RegionColorId or 0, gain_item_count, self.dye_part.region))
end

function hair_dyeing_module:_handle_exchange_inspiration_result(rsp)
  local on_result = self._exchange_on_result
  self._exchange_on_result = nil
  if type(on_result) == "function" then
    on_result(rsp)
  end
  if not self:_check_dye_result_rsp(rsp) then
    return
  end
  local dye_part = self._cur_dye_part or self.dye_part.global
  self:mark_color_owned(self._cur_style_id, dye_part, rsp.ResultColorId or 0)
  self:_show_hair_dyeing_win_tip({
    color_id = rsp.ResultColorId or 0,
    dye_part = dye_part
  })
end

function hair_dyeing_module:_check_dye_result_rsp(rsp)
  if rsp == nil then
    return false
  end
  if rsp.Retcode ~= 0 then
    self:_show_dye_result_error(rsp.Retcode)
    return false
  end
  return true
end

function hair_dyeing_module:_show_dye_result_data(result_data)
  result_data = result_data or {}
  if result_data.result_type == self.result_type.fail then
    local page = UIManagerInstance:is_show("UI/HairDyeing/HairDyeingPage")
    if page ~= nil and page.is_active then
      page:show_result(result_data)
    end
    return
  end
  if result_data.gain_item_id == 200022 then
    self:_show_dye_item_reward(self.currency.rainbow_inspiration, 1)
    return
  end
  if not self:_is_repeated_hair_color_result(result_data.result_type) then
    self:mark_color_owned(result_data.style_id, result_data.dye_part, self:_get_dye_result_color_id(result_data))
  end
  local on_tip_close
  if self:_is_repeated_hair_color_result(result_data.result_type) and result_data.gain_item_id > 0 and 0 < result_data.gain_item_count then
    function on_tip_close()
      self:_show_dye_item_reward(result_data.gain_item_id, result_data.gain_item_count)
    end
  end
  self:_show_hair_dyeing_win_tip(result_data, on_tip_close)
end

function hair_dyeing_module:_show_dye_result_error(retcode)
  if retcode == nil or retcode == 0 then
    return
  end
  local ret_str = CsUIUtil.GetEnumStr(typeof(RetCode), retcode)
  if string.is_valid(ret_str) then
    UIUtil.show_tips_by_text_id(ret_str)
    return
  end
  Logger.LogWarning("[HairDyeing] dye result failed, retcode = " .. tostring(retcode))
end

function hair_dyeing_module:_build_dye_result_data(color_id, region_color_ids, result_type, gain_item_id, gain_item_guid, region_color_id, gain_item_count, dye_part)
  return {
    result_type = result_type,
    color_id = color_id or 0,
    region_color_id = region_color_id or 0,
    region_color_ids = region_color_ids or {},
    gain_item_id = gain_item_id or 0,
    gain_item_count = gain_item_count or 0,
    gain_item_guid = gain_item_guid or 0,
    style_id = self._cur_style_id or 0,
    dye_part = dye_part or self._cur_dye_part or hair_dyeing_module.dye_part.global,
    color_cfg_id = self._selected_color_id
  }
end

function hair_dyeing_module:_get_rsp_gain_item(rsp)
  local inspiration_item = rsp and rsp.InspirationItem or nil
  if inspiration_item == nil then
    return 0, 0
  end
  return inspiration_item.ItemId or 0, inspiration_item.Count or 0
end

function hair_dyeing_module:_show_dye_item_reward(item_id, item_count)
  if item_id == nil or item_id <= 0 or item_count == nil or item_count <= 0 then
    return
  end
  common_ui_module:show_reward_dialog(nil, nil, {
    {id = item_id, num = item_count}
  })
end

function hair_dyeing_module:_build_gradient_region_color_ids(rsp)
  local result = {}
  if rsp.RegionColorId ~= nil and rsp.RegionColorId > 0 then
    table.insert(result, rsp.RegionColorId)
  end
  return result
end

function hair_dyeing_module:request_exchange_hair_color(req_data, on_result)
  req_data = req_data or {}
  local color_cfg = req_data.color_cfg or self:get_color_cfg_by_color_id(req_data.color_id)
  local default_item_id, default_item_count = self:parse_exchange_cost(color_cfg)
  local color_cfg_id = req_data.color_cfg_id or color_cfg and color_cfg.color or 0
  local inspiration_item_id = req_data.inspiration_item_id or default_item_id or 0
  local inspiration_item_count = req_data.inspiration_item_count or default_item_count or 0
  local style_id = req_data.style_id or self:get_cur_style_id()
  local dye_part = req_data.dye_part or self.dye_part.global
  self._cur_style_id = style_id
  self._cur_dye_part = dye_part
  self._selected_color_id = color_cfg_id
  self._exchange_on_result = on_result
  CsDyeingModuleUtil.RequestExchangeHairColor(style_id, inspiration_item_id, inspiration_item_count, color_cfg_id, req_data.color_id or 0, dye_part == self.dye_part.global)
end

return hair_dyeing_module
