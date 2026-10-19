local M = G.Class("NpcImpressionHallPanel", G.UIPanel)
local base = G.UIPanel
local normal_item_cls = "UI/ThemeSeason/NpcImpressionHallNormalItem"
local premium_item_cls = "UI/ThemeSeason/NpcImpressionHallPremiumItem"
local model_preview_view_cls = "UI/CommonUI/CommonModelPreviewView"
local LEVEL_STATE = theme_season_module.LEVEL_STATE
local TIP_STATE = {
  WITH_BUY_BUTTON = 0,
  WITH_BUTTON = 1,
  NO_BUTTON = 2
}
local QUALITY_COLOR_MODE = ColorUtil.Color_Mode.Light
local ANIM_TRIGGER = theme_season_module.ANIM_TRIGGER

function M:init()
  base.init(self)
  self._cur_npc_data = nil
  self._selected_item_data = nil
  self._normal_item_panels = {}
  self._premium_item_panels = {}
  self._final_normal_panel = nil
  self._final_premium_panel = nil
  self._model_preview_view = nil
  self._last_remain_seconds = -1
  self._item_anim_queue = {}
  self._item_anim_elapsed = 0
  self._need_item_enter_anim = false
  self._txt_preview_item_name = nil
  self._txt_preview_item_title = nil
  self._txt_preview_item_content = nil
  self._btn_preview_item_info = nil
  self._btn_preview_item = nil
  self._txt_npc_title = nil
  self._txt_remain_time = nil
  self._trans_group_season = nil
  self._trans_group_normal = nil
  self._btn_buy_bp_season = nil
  self._btn_exchange_season = nil
  self._btn_get_all_season = nil
  self._trans_get_season = nil
  self._txt_tip_season = nil
  self._btn_buy_normal = nil
  self._btn_exchange_normal = nil
  self._btn_get_all_normal = nil
  self._trans_get_normal = nil
  self._txt_tip_normal = nil
  self._trans_scroll_horizontal_season_npc = nil
  self._trans_scroll_horizontal_normal_npc = nil
  self._btn_season_npc_item = nil
  self._btn_normal_npc_item = nil
  self._list_item_normal_npc = nil
  self._list_item_season_npc = nil
  self._trans_content_normal_npc = nil
  self._trans_content_season_npc = nil
  self._trans_preview_view = nil
  self._trans_coin_group_season = nil
  self._img_icon_coin_season = nil
  self._txt_exchange_nee_num_season = nil
  self._txt_btn_exchange_season = nil
  self._txt_btn_get_all_season = nil
  self._trans_coin_group_normal = nil
  self._img_icon_coin_normal = nil
  self._txt_exchange_nee_num_normal = nil
  self._txt_btn_exchange_normal = nil
  self._txt_btn_get_all_normal = nil
  self._ui_state_group_tip_season = nil
  self._ui_state_group_tip_normal = nil
  self._btn_get_all_season_red_point = nil
  self._btn_get_all_normal_red_point = nil
  self._img_quality = nil
end

function M:on_create()
  base.on_create(self)
  self:_create_model_preview_view()
  self:_create_final_items()
  self:_bind_callbacks()
  if not_null(self._btn_preview_item) then
    UIUtil.set_active(self._btn_preview_item, false)
  end
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  if self._has_binder then
    self.binder:PlayEnterAnim(nil)
  end
  self._need_item_enter_anim = true
end

function M:on_disable()
  self:_clear_item_anim_queue()
  self._need_item_enter_anim = false
  base.on_disable(self)
end

function M:play_exit_anims()
  self:_clear_item_anim_queue()
  for _, panel in ipairs(self:_collect_active_item_panels()) do
    panel:play_anim(ANIM_TRIGGER.OUT)
  end
  if self._has_binder then
    self.binder:PlayExitAnim(nil)
  end
end

function M:on_close()
  base.on_close(self)
  self._selected_item_data = nil
  self:_clear_item_anim_queue()
end

function M:on_destroy()
  self:_clear_item_anim_queue()
  self._cur_npc_data = nil
  self._selected_item_data = nil
  self._normal_item_panels = {}
  self._premium_item_panels = {}
  self._final_normal_panel = nil
  self._final_premium_panel = nil
  self._model_preview_view = nil
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_npc_goods_exchanged, pack(self, M._on_exchange_rsp))
  self:add_lua_listener(lua_event_module.event_type.on_theme_season_data_changed, pack(self, M._on_season_data_changed))
  self:add_evt_listener(EventID.UpdateCoinData, pack(self, M._on_coin_data_update))
end

function M:_on_season_data_changed()
  self._last_remain_seconds = -1
  self:_refresh_remain_time_visibility()
end

function M:_on_coin_data_update(virtual_item)
  if is_null(virtual_item) then
    return
  end
  local data = self._selected_item_data
  if not data then
    return
  end
  local cost_id = data.cost_item_id or 0
  if cost_id <= 0 or virtual_item.ConFigID ~= cost_id then
    return
  end
  self:_refresh_exchange_button_state()
end

function M:_create_model_preview_view()
  if not_null(self._trans_preview_view) then
    self._model_preview_view = self:add_panel(model_preview_view_cls, self._trans_preview_view)
  end
end

function M:_create_final_items()
  if not_null(self._btn_season_npc_item) then
    self._final_premium_panel = self:add_panel(premium_item_cls, self._btn_season_npc_item.transform)
  end
  if not_null(self._btn_normal_npc_item) then
    self._final_normal_panel = self:add_panel(normal_item_cls, self._btn_normal_npc_item.transform)
  end
end

function M:_bind_callbacks()
  if not_null(self._btn_exchange_season) then
    self:bind_callback(self._btn_exchange_season, pack(self, M._on_btn_exchange_click))
  end
  if not_null(self._btn_get_all_season) then
    self:bind_callback(self._btn_get_all_season, pack(self, M._on_btn_get_all_click))
  end
  if not_null(self._btn_buy_bp_season) then
    self:bind_callback(self._btn_buy_bp_season, pack(self, M._on_btn_buy_bp_click))
  end
  if not_null(self._btn_exchange_normal) then
    self:bind_callback(self._btn_exchange_normal, pack(self, M._on_btn_exchange_click))
  end
  if not_null(self._btn_get_all_normal) then
    self:bind_callback(self._btn_get_all_normal, pack(self, M._on_btn_get_all_click))
  end
  if not_null(self._btn_buy_normal) then
    self:bind_callback(self._btn_buy_normal, pack(self, M._on_btn_buy_bp_click))
  end
  if not_null(self._btn_preview_item) then
    self:bind_callback(self._btn_preview_item, pack(self, M._on_btn_preview_item_click))
  end
  if not_null(self._btn_preview_item_info) then
    self:bind_callback(self._btn_preview_item_info, pack(self, M._on_btn_preview_item_info_click))
  end
end

function M:_setup_active_group(is_season)
  if not_null(self._trans_group_season) then
    UIUtil.set_active(self._trans_group_season, is_season)
  end
  if not_null(self._trans_group_normal) then
    UIUtil.set_active(self._trans_group_normal, not is_season)
  end
  if is_season then
    self._active = {
      btn_buy = self._btn_buy_bp_season,
      btn_exchange = self._btn_exchange_season,
      btn_get_all = self._btn_get_all_season,
      trans_get = self._trans_get_season,
      txt_tip = self._txt_tip_season,
      trans_coin_group = self._trans_coin_group_season,
      img_icon_coin = self._img_icon_coin_season,
      txt_exchange_nee_num = self._txt_exchange_nee_num_season,
      txt_btn_exchange = self._txt_btn_exchange_season,
      txt_btn_get_all = self._txt_btn_get_all_season,
      btn_get_all_red_point = self._btn_get_all_season_red_point,
      ui_state_group_tip = self._ui_state_group_tip_season
    }
  else
    self._active = {
      btn_buy = self._btn_buy_normal,
      btn_exchange = self._btn_exchange_normal,
      btn_get_all = self._btn_get_all_normal,
      trans_get = self._trans_get_normal,
      txt_tip = self._txt_tip_normal,
      trans_coin_group = self._trans_coin_group_normal,
      img_icon_coin = self._img_icon_coin_normal,
      txt_exchange_nee_num = self._txt_exchange_nee_num_normal,
      txt_btn_exchange = self._txt_btn_exchange_normal,
      txt_btn_get_all = self._txt_btn_get_all_normal,
      btn_get_all_red_point = self._btn_get_all_normal_red_point,
      ui_state_group_tip = self._ui_state_group_tip_normal
    }
  end
end

function M:_is_season_closed()
  if not theme_season_module:is_season_active() then
    UIUtil.show_tips_by_text_id("ThemeSeason_UI_007")
    return true
  end
  return false
end

function M:_is_season_exchange_blocked()
  if not self._cur_npc_data or not self._cur_npc_data.is_season then
    return false
  end
  return self:_is_season_closed()
end

function M:_get_item_gate(data)
  if not data then
    return false, false, nil
  end
  if (data.get_state or 0) == 2 then
    return true, false, nil
  end
  if data.is_premium then
    if (data.lock_state or 0) == 1 then
      return false, true, nil
    end
    local tip = not theme_season_module:has_purchased_bp() and "ThemeSeason_UI_034" or "ThemeSeason_UI_035"
    return false, false, tip
  end
  if (data.get_state or 0) == 1 then
    return false, true, nil
  end
  return false, false, "ThemeSeason_UI_035"
end

function M:_get_claimable_premium_items()
  if not self._cur_npc_data or not self._cur_npc_data.is_season then
    return {}
  end
  local result = {}
  
  local function collect(row)
    local p = row and row.premium_item
    if p and (p.lock_state or 0) == 1 and (p.get_state or 0) == 1 and (p.cost_item_count or 0) == 0 then
      result[#result + 1] = p
    end
  end
  
  local exchange_data = theme_season_module:get_npc_exchange_data(self._cur_npc_data.config_id or 0)
  for _, row in ipairs(exchange_data.premium_items or {}) do
    collect(row)
  end
  collect(exchange_data.premium_final)
  return result
end

function M:_check_cost_enough(items)
  local need = {}
  for _, d in ipairs(items) do
    local cid = d.cost_item_id or 0
    local cc = d.cost_item_count or 0
    if 0 < cid and 0 < cc then
      need[cid] = (need[cid] or 0) + cc
    end
  end
  for cid, total in pairs(need) do
    if total > back_bag_module:get_coin_or_item_num(cid) then
      common_ui_module:show_coin_lack_dialog(cid)
      return false
    end
  end
  return true
end

function M:_build_coin_sprite_tag(cost_id)
  if not cost_id or cost_id <= 0 then
    return ""
  end
  local cfg = item_module:get_cfg_by_id(cost_id)
  local icon = cfg and cfg.icon or nil
  if not string.is_valid(icon) then
    return ""
  end
  return string.format("<dynamicsprite=%s>", icon)
end

function M:_build_exchange_confirm_text(items)
  local total_cost = 0
  local cost_id = 0
  for _, d in ipairs(items) do
    local cid = d.cost_item_id or 0
    if 0 < cid then
      if cost_id == 0 then
        cost_id = cid
      end
      if cid == cost_id then
        total_cost = total_cost + (d.cost_item_count or 0)
      end
    end
  end
  local coin_sprite = self:_build_coin_sprite_tag(cost_id)
  local coin_cfg = 0 < cost_id and item_module:get_cfg_by_id(cost_id) or nil
  local coin_name = coin_cfg and coin_cfg.name or ""
  local item_cfg = item_module:get_cfg_by_id(items[1] and items[1].item_id or 0)
  local item_name = item_cfg and item_cfg.name or ""
  return UIUtil.get_text_by_id("ThemeSeason_UI_041", coin_sprite, coin_name, tostring(total_cost), item_name)
end

function M:_confirm_exchange(items)
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(self:_build_exchange_confirm_text(items), UIUtil.get_text_by_id("Common_Yes"), UIUtil.get_text_by_id("Common_No"), nil)
  popup:set_callbacks(function()
    self:_do_exchange(items)
  end)
  popup:show()
end

function M:_do_exchange(items)
  local send_ids = {}
  local sent_id_set = {}
  for _, d in ipairs(items) do
    local cid = d.config_id
    if cid and 0 < cid and not sent_id_set[cid] then
      sent_id_set[cid] = true
      send_ids[#send_ids + 1] = cid
    end
  end
  if #send_ids == 0 then
    return
  end
  CsThemeSeasonModuleUtil.SendNpcGoodsExchangeReqBatch(send_ids)
end

function M:_on_btn_exchange_click()
  if self:_is_season_exchange_blocked() then
    return
  end
  local selected = self._selected_item_data
  if not selected or selected.is_premium and (selected.cost_item_count or 0) == 0 then
    return
  end
  self:_try_exchange_single(selected)
end

function M:_try_exchange_single(data)
  if not data then
    return
  end
  local is_obtained, is_exchangeable, lock_tip = self:_get_item_gate(data)
  if is_obtained then
    return
  end
  if not is_exchangeable then
    UIUtil.show_tips_by_text_id(lock_tip)
    return
  end
  if not self:_check_cost_enough({data}) then
    return
  end
  if 0 < (data.cost_item_count or 0) then
    self:_confirm_exchange({data})
  else
    self:_do_exchange({data})
  end
end

function M:_on_btn_get_all_click()
  if self:_is_season_exchange_blocked() then
    return
  end
  local selected = self._selected_item_data
  if not selected or not selected.is_premium then
    return
  end
  local claimables = self:_get_claimable_premium_items()
  if (selected.cost_item_count or 0) == 0 and 2 <= #claimables then
    local is_obtained, is_exchangeable = self:_get_item_gate(selected)
    if is_obtained or not is_exchangeable then
      return
    end
    self:_do_exchange(claimables)
    return
  end
  self:_try_exchange_single(selected)
end

function M:_on_exchange_rsp()
  if not self._cur_npc_data then
    return
  end
  self:_refresh_data_only()
  self:_select_default_item()
end

function M:_on_btn_buy_bp_click()
  if self:_is_season_closed() then
    return
  end
  theme_season_module:open_bp_pay_page()
end

function M:_on_btn_preview_item_click()
  if not self._selected_item_data then
    return
  end
  UIUtil.show_tips_by_text_id("ThemeSeason_UI_009")
end

function M:_on_btn_preview_item_info_click()
  if not self._selected_item_data then
    return
  end
  local item_id = self._selected_item_data.item_id or 0
  if 0 < item_id then
    item_module:open_item_info_dialog(item_id, back_bag_module:get_coin_or_item_num(item_id))
  end
end

function M:refresh(npc_data)
  local prev_npc_id = self._cur_npc_data and self._cur_npc_data.config_id or 0
  if (npc_data and npc_data.config_id or 0) ~= prev_npc_id then
    self._need_item_enter_anim = true
  end
  self._cur_npc_data = npc_data
  self._selected_item_data = nil
  self._last_remain_seconds = -1
  self:_setup_active_group(npc_data and npc_data.is_season or false)
  self:_refresh_remain_time_visibility()
  self:_refresh_npc_title()
  self:_refresh_bp_button_visibility()
  self:_refresh_exchange_line_visibility()
  self:_refresh_exchange_items()
  self:_refresh_final_items()
  self:_select_default_item()
  if self._need_item_enter_anim then
    self._need_item_enter_anim = false
    self:_schedule_item_enter_anims()
  else
    self:_sync_item_get_states()
  end
end

function M:_clear_item_anim_queue()
  self._item_anim_queue = {}
  self._item_anim_elapsed = 0
end

function M:_collect_active_item_panels()
  local ordered = {}
  if not self._cur_npc_data then
    return ordered
  end
  local is_season = self._cur_npc_data.is_season or false
  local panels = is_season and self._premium_item_panels or self._normal_item_panels
  for _, panel in ipairs(panels) do
    if panel and panel.is_active then
      ordered[#ordered + 1] = panel
    end
  end
  local final_panel = is_season and self._final_premium_panel or self._final_normal_panel
  if final_panel and final_panel.is_active then
    ordered[#ordered + 1] = final_panel
  end
  return ordered
end

function M:_schedule_item_enter_anims()
  self:_clear_item_anim_queue()
  local queue = self._item_anim_queue
  for i, panel in ipairs(self:_collect_active_item_panels()) do
    panel:prepare_enter_anim()
    queue[#queue + 1] = {
      at = (i - 1) * theme_season_module.ITEM_ENTER_STAGGER_SEC,
      panel = panel,
      trigger = ANIM_TRIGGER.IN
    }
  end
  self:_drive_item_anim_queue(0)
end

function M:_sync_item_get_states()
  if #self._item_anim_queue > 0 then
    return
  end
  for _, panel in ipairs(self:_collect_active_item_panels()) do
    local want_get = panel:is_claimable()
    local in_get = panel:get_cur_anim() == ANIM_TRIGGER.GET
    if want_get and not in_get then
      panel:play_anim(ANIM_TRIGGER.GET)
    elseif in_get and not want_get then
      panel:reset_anim()
    end
  end
end

function M:_drive_item_anim_queue(delta_time)
  local queue = self._item_anim_queue
  if #queue == 0 then
    return
  end
  self._item_anim_elapsed = self._item_anim_elapsed + delta_time
  local elapsed = self._item_anim_elapsed
  local rest = {}
  for _, entry in ipairs(queue) do
    if elapsed >= entry.at then
      if entry.panel and entry.panel.is_active then
        entry.panel:play_anim(entry.trigger)
      end
    else
      rest[#rest + 1] = entry
    end
  end
  self._item_anim_queue = rest
  if #rest == 0 then
    self._item_anim_elapsed = 0
    self:_sync_item_get_states()
  end
end

function M:_refresh_bp_button_visibility()
  local a = self._active
  if not a or is_null(a.btn_buy) then
    return
  end
  local is_premium = self._selected_item_data and self._selected_item_data.is_premium or false
  local is_bp_purchased = theme_season_module:has_purchased_bp()
  UIUtil.set_active(a.btn_buy, is_premium and not is_bp_purchased)
end

function M:_refresh_npc_title()
  if not self._cur_npc_data then
    return
  end
  if not_null(self._txt_npc_title) then
    UIUtil.set_text_by_id(self._txt_npc_title, "ThemeSeason_UI_038", self._cur_npc_data.name or "")
  end
end

function M:_refresh_exchange_line_visibility()
  local is_season = self._cur_npc_data and self._cur_npc_data.is_season or false
  if not_null(self._trans_scroll_horizontal_season_npc) then
    UIUtil.set_active(self._trans_scroll_horizontal_season_npc, is_season)
  end
  if not_null(self._trans_scroll_horizontal_normal_npc) then
    UIUtil.set_active(self._trans_scroll_horizontal_normal_npc, not is_season)
  end
  if not_null(self._btn_season_npc_item) then
    UIUtil.set_active(self._btn_season_npc_item, is_season)
  end
  if not_null(self._btn_normal_npc_item) then
    UIUtil.set_active(self._btn_normal_npc_item, not is_season)
  end
end

function M:_refresh_exchange_items()
  if not self._cur_npc_data then
    return
  end
  if self._cur_npc_data.is_season then
    self:_refresh_premium_items()
  else
    self:_refresh_normal_items()
  end
end

function M:_refresh_normal_items()
  local items = self:_get_normal_exchange_items()
  local on_click = pack(self, M._on_exchange_item_clicked)
  for i = 1, #items do
    local data = items[i]
    local panel = self._normal_item_panels[i]
    if panel == nil then
      panel = self:_create_normal_item()
      self._normal_item_panels[i] = panel
    end
    if panel then
      panel:refresh(data, i, on_click)
      panel:set_active(true)
    end
  end
  for i = #items + 1, #self._normal_item_panels do
    local panel = self._normal_item_panels[i]
    if panel then
      panel:set_active(false)
    end
  end
end

function M:_refresh_premium_items()
  local items = self:_get_premium_exchange_items()
  local on_click = pack(self, M._on_exchange_item_clicked)
  for i = 1, #items do
    local data = items[i]
    local panel = self._premium_item_panels[i]
    if panel == nil then
      panel = self:_create_premium_item()
      self._premium_item_panels[i] = panel
    end
    if panel then
      panel:refresh(data, i, on_click)
      panel:set_active(true)
    end
  end
  for i = #items + 1, #self._premium_item_panels do
    local panel = self._premium_item_panels[i]
    if panel then
      panel:set_active(false)
    end
  end
end

function M:_create_normal_item()
  if is_null(self._list_item_normal_npc) then
    return nil
  end
  local obj = self._list_item_normal_npc:AddItem(0)
  if is_null(obj) then
    return nil
  end
  return self:add_panel(normal_item_cls, obj)
end

function M:_create_premium_item()
  if is_null(self._list_item_season_npc) then
    return nil
  end
  local obj = self._list_item_season_npc:AddItem(0)
  if is_null(obj) then
    return nil
  end
  return self:add_panel(premium_item_cls, obj)
end

function M:_refresh_final_items()
  if not self._cur_npc_data then
    return
  end
  local npc_id = self._cur_npc_data.config_id or 0
  local exchange_data = theme_season_module:get_npc_exchange_data(npc_id)
  local on_click = pack(self, M._on_exchange_item_clicked)
  if self._cur_npc_data.is_season and self._final_premium_panel then
    local final_row = exchange_data.premium_final
    if final_row and final_row.premium_item then
      self._final_premium_panel:refresh_as_final(final_row, on_click)
      self._final_premium_panel:set_active(true)
    else
      self._final_premium_panel:set_active(false)
    end
  elseif not self._cur_npc_data.is_season and self._final_normal_panel then
    local final_data = exchange_data.free_final
    if final_data then
      self._final_normal_panel:refresh(final_data, final_data.level or 0, on_click)
      self._final_normal_panel:set_active(true)
    else
      self._final_normal_panel:set_active(false)
    end
  end
end

function M:_on_exchange_item_clicked(item_data)
  if not item_data then
    return
  end
  local item_id = item_data.item_id
  if not item_id or item_id <= 0 then
    return
  end
  self._selected_item_data = item_data
  self:_refresh_preview(item_id)
  self:_refresh_selection_visual()
  lua_event_module:send_event(lua_event_module.event_type.on_npc_exchange_item_selected, item_data.cost_item_id or 0)
end

function M:_refresh_selection_visual()
  local sel_id = self._selected_item_data and self._selected_item_data.config_id or nil
  for _, panel in ipairs(self._normal_item_panels) do
    if panel then
      panel:sync_selection(sel_id)
    end
  end
  for _, panel in ipairs(self._premium_item_panels) do
    if panel then
      panel:sync_selection(sel_id)
    end
  end
  if self._final_premium_panel then
    self._final_premium_panel:sync_selection(sel_id)
  end
  if self._final_normal_panel then
    self._final_normal_panel:sync_selection(sel_id)
  end
end

function M:_refresh_preview(item_id)
  self:_refresh_model_preview(item_id)
  self:_refresh_preview_info(item_id)
  self:_refresh_bp_button_visibility()
  self:_refresh_exchange_button_state()
end

function M:_refresh_model_preview(item_id)
  if self._model_preview_view then
    self._model_preview_view:show_item(item_id, self:get_load_proxy())
  end
end

function M:hide_model_preview()
  if self._model_preview_view then
    self._model_preview_view:hide_preview()
  end
end

function M:_refresh_preview_info(item_id)
  local item_cfg = item_module:get_cfg_by_id(item_id)
  local name = item_cfg and item_cfg.name or ""
  local desc = item_cfg and item_cfg.desc or ""
  if not_null(self._txt_preview_item_name) then
    UIUtil.set_text(self._txt_preview_item_name, name)
  end
  if not_null(self._txt_preview_item_title) then
    UIUtil.set_text(self._txt_preview_item_title, "")
  end
  if not_null(self._txt_preview_item_content) then
    UIUtil.set_text(self._txt_preview_item_content, desc)
  end
  self:_refresh_preview_quality(item_cfg)
end

function M:_refresh_preview_quality(item_cfg)
  if is_null(self._img_quality) then
    return
  end
  if not item_cfg then
    UIUtil.set_active(self._img_quality, false)
    return
  end
  local color = ColorUtil.get_item_quality_color(item_cfg.rank or 0, QUALITY_COLOR_MODE) or ColorUtil.get_item_quality_color(0, QUALITY_COLOR_MODE)
  UIUtil.set_image_color(self._img_quality, color)
  UIUtil.set_active(self._img_quality, true)
end

function M:_refresh_exchange_button_state()
  self:_apply_exchange_button_state()
  self:_refresh_tip_state_group()
end

function M:_is_control_active(control)
  if is_null(control) then
    return false
  end
  return control.gameObject.activeSelf
end

function M:_refresh_tip_state_group()
  local a = self._active
  if not a or is_null(a.ui_state_group_tip) then
    return
  end
  local state = TIP_STATE.NO_BUTTON
  if self:_is_control_active(a.btn_buy) then
    state = TIP_STATE.WITH_BUY_BUTTON
  elseif self:_is_control_active(a.btn_exchange) or self:_is_control_active(a.btn_get_all) or self:_is_control_active(a.trans_get) then
    state = TIP_STATE.WITH_BUTTON
  end
  a.ui_state_group_tip:SetState(state)
end

function M:_set_tip_by_id(text_id)
  local a = self._active
  if not a or is_null(a.txt_tip) then
    return
  end
  local text = string.is_valid(text_id) and UIUtil.get_text_by_id(text_id) or ""
  local has_text = string.is_valid(text)
  if has_text then
    UIUtil.set_text(a.txt_tip, text)
  end
  UIUtil.set_active(a.txt_tip, has_text)
end

function M:_apply_exchange_button_state()
  local a = self._active
  if not a then
    return
  end
  if not_null(a.btn_get_all_red_point) then
    local has_claimable = #self:_get_claimable_premium_items() > 0
    a.btn_get_all_red_point:ShowRedPoint(has_claimable and RedPointType.GiftRP or RedPointType.None)
  end
  local selected = self._selected_item_data
  if not selected then
    UIUtil.set_active(a.btn_exchange, false)
    UIUtil.set_active(a.btn_get_all, false)
    UIUtil.set_active(a.trans_get, false)
    UIUtil.set_active(a.trans_coin_group, false)
    self:_set_tip_by_id(nil)
    return
  end
  if selected.is_premium and not theme_season_module:has_purchased_bp() then
    UIUtil.set_active(a.btn_exchange, false)
    UIUtil.set_active(a.btn_get_all, false)
    UIUtil.set_active(a.trans_get, false)
    UIUtil.set_active(a.trans_coin_group, false)
    self:_set_tip_by_id("ThemeSeason_UI_034")
    return
  end
  local is_obtained, is_exchangeable, lock_tip = self:_get_item_gate(selected)
  if is_obtained then
    UIUtil.set_active(a.btn_exchange, false)
    UIUtil.set_active(a.btn_get_all, false)
    UIUtil.set_active(a.trans_get, true)
    UIUtil.set_active(a.trans_coin_group, false)
    self:_set_tip_by_id(nil)
    return
  end
  UIUtil.set_active(a.trans_get, false)
  if not is_exchangeable then
    UIUtil.set_active(a.btn_exchange, false)
    UIUtil.set_active(a.btn_get_all, false)
    UIUtil.set_active(a.trans_coin_group, false)
    self:_set_tip_by_id(lock_tip)
    return
  end
  self:_set_tip_by_id(nil)
  if selected.is_premium then
    if 0 < (selected.cost_item_count or 0) then
      UIUtil.set_active(a.btn_get_all, false)
      UIUtil.set_active(a.btn_exchange, true)
      UIUtil.set_text(a.txt_btn_exchange, UIUtil.get_text_by_id("ThemeSeason_UI_027"))
    else
      UIUtil.set_active(a.btn_exchange, false)
      UIUtil.set_active(a.btn_get_all, true)
      local claimables = self:_get_claimable_premium_items()
      local is_batch = 2 <= #claimables
      UIUtil.set_text(a.txt_btn_get_all, UIUtil.get_text_by_id(is_batch and "ThemeSeason_UI_043" or "ThemeSeason_UI_028"))
    end
  else
    UIUtil.set_active(a.btn_get_all, false)
    UIUtil.set_active(a.btn_exchange, true)
    UIUtil.set_text(a.txt_btn_exchange, UIUtil.get_text_by_id("ThemeSeason_UI_027"))
  end
  self:_refresh_exchange_coin_area()
end

function M:_refresh_exchange_coin_area()
  local a = self._active
  if not a then
    return
  end
  local data = self._selected_item_data
  if not data then
    UIUtil.set_active(a.trans_coin_group, false)
    return
  end
  local cost_count = data.cost_item_count or 0
  if cost_count == 0 then
    UIUtil.set_active(a.trans_coin_group, false)
  else
    UIUtil.set_active(a.trans_coin_group, true)
    local cost_id = data.cost_item_id or 0
    if 0 < cost_id then
      item_module:set_item_icon(a.img_icon_coin, cost_id, nil, nil, self:get_load_proxy())
    end
    local owned = 0 < cost_id and back_bag_module:get_coin_or_item_num(cost_id) or 0
    local color = cost_count <= owned and "TextBpExchange_S1" or "TextWarning_Light"
    UIUtil.set_text(a.txt_exchange_nee_num, TextMapFormatUtil.FormatInteger(cost_count), color)
  end
end

function M:_refresh_data_only()
  self._selected_item_data = nil
  self:_refresh_bp_button_visibility()
  self:_refresh_exchange_items()
  self:_refresh_final_items()
  self:_sync_item_get_states()
end

function M:_select_default_item()
  if not self._cur_npc_data then
    return
  end
  local target_item = self:_get_selectable_final_item()
  if not target_item then
    if self._cur_npc_data.is_season then
      target_item = self:_find_best_season_item()
    else
      target_item = self:_find_best_normal_item()
    end
  end
  if target_item then
    self:_on_exchange_item_clicked(target_item)
  end
end

function M:_get_selectable_final_item()
  if not self._cur_npc_data then
    return nil
  end
  local npc_id = self._cur_npc_data.config_id or 0
  local exchange_data = theme_season_module:get_npc_exchange_data(npc_id)
  if self._cur_npc_data.is_season then
    local final_row = exchange_data.premium_final
    local premium_item = final_row and final_row.premium_item or nil
    if premium_item and (premium_item.get_state or 0) == 1 then
      return premium_item
    end
  else
    local final_data = exchange_data.free_final
    if final_data and (final_data.get_state or 0) == 1 then
      return final_data
    end
  end
  return nil
end

function M:_find_best_season_item()
  local items = self:_get_premium_exchange_items()
  if #items == 0 then
    return nil
  end
  for _, d in ipairs(items) do
    if d.basic_item and d.basic_item.get_state == 1 then
      return d.basic_item
    end
    if d.premium_item and d.premium_item.lock_state == 1 and d.premium_item.get_state ~= 2 then
      return d.premium_item
    end
  end
  return items[1].basic_item or items[1].premium_item
end

function M:_find_best_normal_item()
  local items = self:_get_normal_exchange_items()
  if #items == 0 then
    return nil
  end
  local first_fallback = items[1]
  local next_level_item
  for i, d in ipairs(items) do
    if d.level_state == LEVEL_STATE.CURRENT then
      if d.get_state == 1 then
        return d
      end
      if i < #items then
        next_level_item = items[i + 1]
      end
      break
    end
  end
  return next_level_item or first_fallback
end

function M:_get_normal_exchange_items()
  local npc_id = self._cur_npc_data and self._cur_npc_data.config_id or 0
  local exchange_data = theme_season_module:get_npc_exchange_data(npc_id)
  return exchange_data.free_items
end

function M:_get_premium_exchange_items()
  local npc_id = self._cur_npc_data and self._cur_npc_data.config_id or 0
  local exchange_data = theme_season_module:get_npc_exchange_data(npc_id)
  return exchange_data.premium_items
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  self:refresh_remaining_time(theme_season_module:get_remaining_seconds())
  self:_drive_item_anim_queue(deltaTime)
end

function M:_can_show_remain_time()
  local is_season = self._cur_npc_data and self._cur_npc_data.is_season or false
  return is_season and theme_season_module:is_season_active()
end

function M:_refresh_remain_time_visibility()
  if is_null(self._txt_remain_time) then
    return
  end
  UIUtil.set_active(self._txt_remain_time, self:_can_show_remain_time())
end

function M:refresh_remaining_time(remain_seconds)
  if remain_seconds == self._last_remain_seconds then
    return
  end
  self._last_remain_seconds = remain_seconds
  if not self:_can_show_remain_time() then
    return
  end
  if not_null(self._txt_remain_time) then
    local time_text = theme_season_module:format_season_remaining_time(remain_seconds)
    UIUtil.set_text(self._txt_remain_time, time_text)
  end
end

return M
