local M = G.Class("GachaProcessFurnitureT1Page", G.UIWindow)
local base = G.UIWindow
local anim_item_view_cls = "UI/Gacha/GachaProcessT1AnimItem"
local anim_result_state = {
  single_small = 0,
  single_mid = 1,
  single_big = 2,
  ten_small = 3,
  ten_mid = 4,
  ten_big = 5
}
local show_type_state = {
  single = 0,
  ten = 1,
  none = 2
}
local final_anim_trigger_type = {
  [anim_result_state.single_small] = "final_single_small",
  [anim_result_state.single_mid] = "final_single_mid",
  [anim_result_state.single_big] = "final_single_big",
  [anim_result_state.ten_small] = "final_mult_small",
  [anim_result_state.ten_mid] = "final_mult_mid",
  [anim_result_state.ten_big] = "final_mult_big"
}

function M:init()
  base.init(self)
  self.config.prefab_path = GachaConst.panel_path.process_furniture_t1
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  self._draw_level_to_burst_trigger = {
    [GachaConst.fragment_draw_level.huge_guarantee] = "burst_big",
    [GachaConst.fragment_draw_level.normal_guarantee] = "burst_mid",
    [GachaConst.fragment_draw_level.no_guarantee] = "burst_small"
  }
  self._pending_items = {}
  self._pending_map = {}
  self._single_anim_item = nil
  self._ten_anim_items = {}
  self._ten_item_gos = nil
  self._gacha_id = nil
  self._activity_cfg = nil
  self._is_ten = false
  self._draw_rsp = nil
end

function M:on_create()
  base.on_create(self)
  self:_init_anim_items()
  if not_null(self._btn_mask) then
    self:bind_callback(self._btn_mask, pack(self, M._on_click_mask))
  end
  if not_null(self._btn_skip) then
    self:bind_callback(self._btn_skip, pack(self, M._on_click_skip))
  end
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_skip)
end

function M:on_enable()
  base.on_enable(self)
  self:_init_data()
end

function M:on_disable()
  base.on_disable(self)
  self:_stop_anim()
end

function M:_init_data()
  self._result_anim_state = anim_result_state.single_small
  self._ten_guarantee_count = 0
  self._show_coin_num = 0
  self._is_playing_down_anim = false
  self._pending_items = {}
  self._pending_map = {}
  self._draw_rsp = gacha_module:get_last_draw_rsp_lua()
  if self._draw_rsp == nil then
    Logger.LogError("[GachaProcessFurnitureT1Page] _draw_rsp is nil")
    return
  end
  self._gacha_id = self._draw_rsp.gacha_id
  self._activity_cfg = gacha_module:get_activity_cfg(self._gacha_id)
  if self._activity_cfg == nil then
    Logger.LogError("[GachaProcessFurnitureT1Page] _gacha_cfg is nil, " .. tostring(self._gacha_id))
    return
  end
  local result_infos = self._draw_rsp.result_infos
  self._is_ten = result_infos and 1 < #result_infos or false
  local type_state = self._is_ten and show_type_state.ten or show_type_state.single
  local is_skip_anim = gacha_module:is_skip_anim(self._gacha_id)
  type_state = is_skip_anim and show_type_state.none or type_state
  self._state_group_type:SetState(type_state)
  UIUtil.set_active(self._info_root, not is_skip_anim)
  if is_skip_anim then
    self:_refresh_skip_logic()
  else
    self:_refresh_data()
    self:_refresh_anim_item()
    self:_setup_pending_items()
    self:_refresh_shards_tips_anim(true)
  end
end

function M:_refresh_skip_logic()
  for i = 1, #self._draw_rsp.result_infos do
    local result_info = self._draw_rsp.result_infos[i]
    self:_refresh_final_anim_state(result_info)
  end
  self:_play_down_anim()
end

function M:_refresh_final_anim_state(result_info, pool_cfg)
  if result_info == nil then
    return
  end
  pool_cfg = pool_cfg or gacha_module:get_pool_cfg(self._activity_cfg.gachapoolid, result_info.SlotIndex)
  if pool_cfg == nil then
    Logger.LogError("[GachaProcessFurnitureT1Page] pool_cfg is nil, " .. tostring(self._activity_cfg.gachapoolid) .. ", " .. tostring(result_info.SlotIndex))
    return
  end
  local draw_level = pool_cfg.coingachalevel or GachaConst.fragment_draw_level.no_guarantee
  if self._is_ten then
    if draw_level <= GachaConst.fragment_draw_level.normal_guarantee then
      self._ten_guarantee_count = self._ten_guarantee_count + 1
    end
  else
    self._result_anim_state = GachaConst.fragment_draw_level.no_guarantee - draw_level
  end
end

function M:_refresh_data()
  self:_refresh_coin_num(self._show_coin_num, true)
  local coin2_id = self._activity_cfg.exchangeshopcoinid or 0
  if not_null(self._img_icon_dynamic) then
    item_module:set_item_icon(self._img_icon_dynamic, coin2_id, nil, nil, self:get_load_proxy())
  end
  local tip_text_id = self._activity_cfg.subtab == GachaConst.sub_tab.cloth and "Gacha_T1_Cloth_Gacha_Tips" or "Gacha_T1_Furniture_Gacha_Tips"
  if not_null(self._txt_item_name) then
    UIUtil.set_text_by_id(self._txt_item_name, tip_text_id)
  end
  if not_null(self._txt_prompt) then
    local coin2_path = item_module:get_item_icon(coin2_id)
    local prompt_text = UIUtil.get_text_by_id("Gacha_T1_Cloth_Num", coin2_path)
    UIUtil.set_text_with_dynamic_sprite(self._txt_prompt, prompt_text)
  end
  self:_refresh_finale_state(false)
end

function M:_refresh_shards_tips_anim(is_reset, num_add, trigger)
  if is_null(self._shards_tips_animator) then
    return
  end
  if is_reset then
    self._shards_tips_animator:SetTrigger("none")
    self._shards_tips_animator:SetTrigger("normal")
  else
    UIUtil.set_text(self._txt_coin_add_num, "+" .. tostring(num_add))
    self._shards_tips_animator:SetTrigger("add")
    if trigger == self._draw_level_to_burst_trigger[GachaConst.fragment_draw_level.huge_guarantee] then
      self._shards_tips_animator:SetTrigger("big")
    elseif trigger == self._draw_level_to_burst_trigger[GachaConst.fragment_draw_level.normal_guarantee] then
      self._shards_tips_animator:SetTrigger("mid")
    end
  end
end

function M:_refresh_coin_num(coin_count, is_init)
  if not_null(self._txt_coin_num) then
    if is_init then
      UIUtil.set_text(self._txt_coin_num, tostring(coin_count))
    else
      local current_coin_count = tonumber(self._txt_coin_num.text)
      self:_stop_coin_tween()
      self._coin_tween = UIUtil.dt_to_anim(current_coin_count, coin_count, 0.5, function(val)
        UIUtil.set_text(self._txt_coin_num, tostring(math.ceil(val)))
      end, function()
        UIUtil.set_text(self._txt_coin_num, tostring(coin_count))
      end)
    end
  end
end

function M:_init_anim_items()
  self._single_anim_item = self:_load_anim_item(self._single_item)
  self._ten_item_gos = {
    self._ten_item_1,
    self._ten_item_2,
    self._ten_item_3,
    self._ten_item_4,
    self._ten_item_5,
    self._ten_item_6,
    self._ten_item_7,
    self._ten_item_8,
    self._ten_item_9,
    self._ten_item_10
  }
  for i = 1, #self._ten_item_gos do
    self._ten_anim_items[i] = self:_load_anim_item(self._ten_item_gos[i])
  end
end

function M:_refresh_anim_item()
  UIUtil.set_active(self._single_item, not self._is_ten)
  for i = 1, #self._ten_item_gos do
    UIUtil.set_active(self._ten_item_gos[i], self._is_ten)
  end
end

function M:_load_anim_item(obj)
  if is_null(obj) then
    return
  end
  local anim_item = self:add_panel(anim_item_view_cls, obj)
  return anim_item
end

function M:_setup_pending_items()
  self._pending_items = {}
  self._pending_map = {}
  if self._draw_rsp == nil or self._draw_rsp.result_infos == nil or self._activity_cfg == nil then
    Logger.LogError("[GachaProcessFurnitureT1Page] _setup_pending_items: draw_rsp/result_infos/activity_cfg is nil")
    return
  end
  local result_infos = self._draw_rsp.result_infos
  local coin_type = self._activity_cfg.exchangeshopcoinid or 0
  local default_trigger = self._draw_level_to_burst_trigger[GachaConst.fragment_draw_level.no_guarantee]
  local on_burst_request = pack(self, M._on_item_burst)
  for i = 1, #result_infos do
    local result_info = result_infos[i]
    local item = self._is_ten and self._ten_anim_items[i] or self._single_anim_item
    if result_info == nil or item == nil then
      Logger.LogError("[GachaProcessFurnitureT1Page] _setup_pending_items: result_info or item nil, index = " .. tostring(i))
    else
      local pool_cfg = gacha_module:get_pool_cfg(self._activity_cfg.gachapoolid, result_info.SlotIndex)
      local draw_level = pool_cfg and pool_cfg.coingachalevel or GachaConst.fragment_draw_level.no_guarantee
      local trigger = self._draw_level_to_burst_trigger[draw_level] or default_trigger
      local add_coin = result_info.ItemId == coin_type and (result_info.Count or 0) or 0
      local entry = {
        index = i,
        item = item,
        result_info = result_info,
        pool_cfg = pool_cfg,
        trigger = trigger,
        add_coin = add_coin
      }
      table.insert(self._pending_items, entry)
      self._pending_map[item] = entry
      local is_big_burst = trigger == self._draw_level_to_burst_trigger[GachaConst.fragment_draw_level.huge_guarantee]
      item:setup(trigger, add_coin, is_big_burst, on_burst_request)
    end
  end
end

function M:_on_item_burst(item)
  if self._is_play_final_anim then
    return
  end
  local entry = self._pending_map[item]
  if entry == nil then
    return
  end
  self:_do_burst(entry)
end

function M:_do_burst(entry)
  if entry == nil then
    return
  end
  self:_remove_pending(entry)
  self:_refresh_final_anim_state(entry.result_info, entry.pool_cfg)
  self._show_coin_num = self._show_coin_num + entry.add_coin
  self:_refresh_coin_num(self._show_coin_num, false)
  entry.item:play_burst()
  self:_refresh_shards_tips_anim(false, entry.add_coin, entry.trigger)
  self._panel_hit_animator:SetTriggerWithCallback(entry.trigger, function()
    if #self._pending_items == 0 then
      self:_play_down_anim()
    end
  end, false)
end

function M:_remove_pending(entry)
  if entry == nil then
    return
  end
  if entry.item ~= nil then
    self._pending_map[entry.item] = nil
  end
  for i = #self._pending_items, 1, -1 do
    if self._pending_items[i] == entry then
      table.remove(self._pending_items, i)
      break
    end
  end
end

function M:_play_down_anim()
  if self._is_playing_down_anim then
    return
  end
  self._is_playing_down_anim = true
  if self._is_ten then
    if self._ten_guarantee_count >= 2 then
      self._result_anim_state = self._ten_guarantee_count >= 3 and anim_result_state.ten_big or anim_result_state.ten_mid
    else
      self._result_anim_state = anim_result_state.ten_small
    end
  end
  self._state_group_result:SetState(self._result_anim_state)
  local final_anim_trigger = final_anim_trigger_type[self._result_anim_state]
  self._panel_final_animator:SetTriggerWithCallback(final_anim_trigger, function()
    self:_show_end_logic()
  end, false)
  self:_refresh_finale_state(true)
end

function M:_stop_anim()
  self._panel_hit_animator:ClearCallback()
  self._panel_final_animator:ClearCallback()
  self:_stop_coin_tween()
end

function M:_stop_coin_tween()
  if self._coin_tween then
    self._coin_tween:Kill()
    self._coin_tween = nil
  end
end

function M:_refresh_finale_state(is_final)
  self._is_play_final_anim = is_final
  UIUtil.set_active(self._btn_mask, not is_final)
  UIUtil.set_active(self._btn_skip, not is_final)
  UIUtil.set_active(self._info_root, not is_final)
end

function M:_show_end_logic()
  gacha_module:open_draw_show_t1()
end

function M:_on_click_mask()
  if self._is_play_final_anim then
    return
  end
  local entry = self._pending_items[1]
  if entry == nil then
    self:_refresh_finale_state(true)
    self:_play_down_anim()
    return
  end
  self:_do_burst(entry)
end

function M:_on_click_skip()
  if self._is_play_final_anim then
    return
  end
  local last_entry = self._pending_items[#self._pending_items]
  for _, entry in ipairs(self._pending_items) do
    self:_refresh_final_anim_state(entry.result_info, entry.pool_cfg)
    self._show_coin_num = self._show_coin_num + entry.add_coin
    entry.item:play_burst()
    if entry.item ~= nil then
      self._pending_map[entry.item] = nil
    end
  end
  self._pending_items = {}
  self:_refresh_coin_num(self._show_coin_num, false)
  if last_entry ~= nil then
    self._panel_hit_animator:SetTriggerWithCallback(last_entry.trigger, function()
      self:_play_down_anim()
    end, false)
  else
    self:_play_down_anim()
  end
end

return M
