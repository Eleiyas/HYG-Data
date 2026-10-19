local M = G.Class("ThemeSeasonGraduationDialog", G.UIWindow)
local base = G.UIWindow
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local graduation_item_cls = "UI/ThemeSeason/ThemeSeasonGraduationItem"
local model_preview_view_cls = "UI/CommonUI/CommonModelPreviewView"
local EXCHANGE_STATE = theme_season_module.GRADUATE_EXCHANGE_STATE

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BattlePass/BattlePassGraduationDialog"
  self.config.scene_prefab_path = "Scene/Map/4_UI/SceneMap_UI_BattlePassGraduation"
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
  self._graduation_item_panels = {}
  self._selected_item_data = nil
  self._coin_view = nil
  self._model_preview_view = nil
  self._last_remain_seconds = -1
  self._txt_remain_time = nil
  self._btn_buy = nil
  self._list_item = nil
  self._trans_items_content = nil
  self._toggle_group = nil
  self._btn_item_info = nil
  self._txt_item_name = nil
  self._ui_state_group_quality = nil
  self._btn_item_details = nil
  self._trans_model_preview_view = nil
  self._txt_unlock_tips = nil
  self._btn_go_to_task = nil
  self._btn_exchange = nil
  self._trans_got = nil
  self._rect_coin_item = nil
  self._btn_info_dark_1 = nil
  self._btn_close_normal = nil
  self._img_exchange_icon_coin = nil
  self._txt_exchange_num = nil
end

function M:on_create()
  base.on_create(self)
  self:_create_model_preview_view()
  self:_create_graduation_items()
  self:_create_coin_view()
  self:_bind_callbacks()
  UIUtil.set_active(self._btn_item_details, false)
end

function M:register_events()
  base.register_events(self)
  self:add_lua_listener(lua_event_module.event_type.on_theme_season_data_changed, pack(self, M._on_season_info_changed))
  self:add_lua_listener(lua_event_module.event_type.on_theme_bp_graduate_exchanged, pack(self, M._on_graduate_exchange_rsp))
  self:add_lua_listener(lua_event_module.event_type.on_theme_bp_purchased, pack(self, M.refresh))
end

function M:on_open()
  base.on_open(self)
  theme_season_module:report_page_reach(theme_season_module.REPORT_PAGE_ID.GRADUATION)
  self._selected_item_data = nil
  self:_sync_coin_ids()
end

function M:on_enable()
  base.on_enable(self)
  self._last_remain_seconds = -1
  self:refresh()
  theme_season_module:try_show_season_expired_popup()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
  self._selected_item_data = nil
end

function M:on_destroy()
  self._graduation_item_panels = {}
  self._selected_item_data = nil
  self._coin_view = nil
  self._model_preview_view = nil
  base.on_destroy(self)
end

function M:update()
  self:_refresh_remaining_time()
end

function M:_create_model_preview_view()
  self._model_preview_view = self:add_panel(model_preview_view_cls, self._trans_model_preview_view)
end

function M:_create_graduation_items()
  local items = self:_get_graduation_items()
  for i = 1, #items do
    local obj = self._list_item:AddItem(0)
    if not_null(obj) then
      local panel = self:add_panel(graduation_item_cls, obj)
      if panel then
        self._graduation_item_panels[#self._graduation_item_panels + 1] = panel
        local toggle = panel:get_toggle()
        if not_null(toggle) then
          toggle.group = self._toggle_group
        end
      end
    end
  end
end

function M:_sync_coin_ids()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  local coin_id = season_cfg and season_cfg.token2 or 0
  if self._coin_view and 0 < coin_id then
    self._coin_view:set_coin_id(coin_id)
  end
end

function M:_create_coin_view()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  local coin_id = season_cfg and season_cfg.token2 or 0
  if 0 < coin_id then
    self._coin_view = self:add_panel(coin_item_view_cls, self._rect_coin_item, {
      coin_id = coin_id,
      auto_update = true,
      show_detail = true,
      on_add_click = function()
        common_ui_module:show_coin_lack_dialog(coin_id, nil, function()
          self:close_self()
        end)
      end
    })
  end
end

function M:_bind_callbacks()
  self:bind_close_btn(self._btn_close_normal)
  self:bind_callback(self._btn_exchange, pack(self, M._on_btn_exchange_click))
  self:bind_callback(self._btn_buy, pack(self, M._on_btn_buy_click))
  self:bind_callback(self._btn_item_info, pack(self, M._on_btn_item_info_click))
  self:bind_callback(self._btn_item_details, pack(self, M._on_btn_item_details_click))
  self:bind_callback(self._btn_go_to_task, pack(self, M._on_btn_go_to_task_click))
  self:bind_callback(self._btn_info_dark_1, pack(self, M._on_btn_info_click))
end

function M:_on_btn_exchange_click()
  if not self._selected_item_data then
    return
  end
  local state = self._selected_item_data.exchange_state or EXCHANGE_STATE.LOCKED
  if state == EXCHANGE_STATE.EXCHANGED then
    return
  end
  if state == EXCHANGE_STATE.LOCKED then
    local is_bp_purchased = theme_season_module:has_purchased_bp()
    if not is_bp_purchased then
      UIUtil.show_tips_by_text_id("ThemeSeason_UI_023")
    else
      local required_count = self._selected_item_data.required_story_count or 0
      local finished_count = self._selected_item_data.finished_story_count or 0
      if 0 < required_count and required_count > finished_count then
        UIUtil.show_tips(UIUtil.get_text_by_id("ThemeSeason_UI_025", required_count))
      end
    end
    return
  end
  if state == EXCHANGE_STATE.LACKED_COIN then
    local cost_id = self._selected_item_data.cost_item_id or 0
    common_ui_module:show_coin_lack_dialog(cost_id, nil, function()
      self:close_self()
    end)
    return
  end
  local config_id = self._selected_item_data.config_id
  if not config_id or config_id <= 0 then
    return
  end
  CsThemeSeasonModuleUtil.SendGraduateExchangeReq(config_id)
end

function M:_on_btn_buy_click()
  theme_season_module:open_bp_pay_page()
end

function M:_on_btn_item_info_click()
  if not self._selected_item_data then
    return
  end
  local item_id = self._selected_item_data.item_id or 0
  if 0 < item_id then
    item_module:open_item_info_dialog(item_id, back_bag_module:get_coin_or_item_num(item_id))
  end
end

function M:_on_btn_item_details_click()
  if not self._selected_item_data then
    return
  end
  UIUtil.show_tips_by_text_id("ThemeSeason_UI_009")
end

function M:_on_btn_go_to_task_click()
  theme_season_module:open_current_chapter_detail()
end

function M:_on_btn_info_click()
  local season_cfg = theme_season_module:get_cur_season_cfg()
  local intro_id = season_cfg and season_cfg.introductionid or 0
  if 0 < intro_id then
    common_ui_module:show_introduction_dialog(intro_id)
  end
end

function M:_on_season_info_changed()
  self:refresh()
end

function M:_on_graduate_exchange_rsp()
  self:refresh()
end

function M:refresh()
  theme_season_module:update_season_time_state()
  local items = self:_get_graduation_items()
  self:_refresh_items(items)
  self:_refresh_buy_visibility()
  self:_reselect_or_default(items)
end

function M:_refresh_items(items)
  local on_click = pack(self, M._on_graduation_item_clicked)
  for i = 1, #self._graduation_item_panels do
    local panel = self._graduation_item_panels[i]
    local data = items[i]
    if panel and data then
      panel:refresh(data, i, on_click)
    end
  end
end

function M:_is_story_requirement_met()
  if not self._selected_item_data then
    return false
  end
  local required_count = self._selected_item_data.required_story_count or 0
  return required_count <= 0 or required_count <= (self._selected_item_data.finished_story_count or 0)
end

function M:_refresh_unlock_tips()
  if not self._selected_item_data then
    UIUtil.set_active(self._txt_unlock_tips, false)
    UIUtil.set_active(self._btn_go_to_task, false)
    return
  end
  local state = self._selected_item_data.exchange_state or EXCHANGE_STATE.LOCKED
  if state == EXCHANGE_STATE.EXCHANGED or state == EXCHANGE_STATE.AVAILABLE or state == EXCHANGE_STATE.LACKED_COIN then
    UIUtil.set_active(self._txt_unlock_tips, false)
    UIUtil.set_active(self._btn_go_to_task, false)
    return
  end
  UIUtil.set_active(self._txt_unlock_tips, true)
  if not self:_is_story_requirement_met() then
    UIUtil.set_text_by_id(self._txt_unlock_tips, "ThemeSeason_UI_025", self._selected_item_data.required_story_count or 0)
    UIUtil.set_active(self._btn_go_to_task, true)
  else
    UIUtil.set_text_by_id(self._txt_unlock_tips, "ThemeSeason_UI_024")
    UIUtil.set_active(self._btn_go_to_task, false)
  end
end

function M:_refresh_buy_visibility()
  local is_bp_purchased = theme_season_module:has_purchased_bp()
  UIUtil.set_active(self._btn_buy, not is_bp_purchased)
end

function M:_on_graduation_item_clicked(item_data)
  if not item_data then
    return
  end
  local item_id = item_data.item_id
  if not item_id or item_id <= 0 then
    return
  end
  if item_data == self._selected_item_data then
    return
  end
  self._selected_item_data = item_data
  self:_refresh_preview(item_id)
  self:_refresh_exchange_area()
  self:_refresh_unlock_tips()
  self:_sync_item_selection()
end

function M:_sync_item_selection()
  for i = 1, #self._graduation_item_panels do
    local panel = self._graduation_item_panels[i]
    if panel then
      panel:sync_selection(self._selected_item_data)
    end
  end
end

function M:_refresh_preview(item_id)
  if self._model_preview_view then
    self._model_preview_view:show_item(item_id, self:get_load_proxy())
  end
  local item_cfg = item_module:get_cfg_by_id(item_id)
  local name = item_cfg and item_cfg.name or ""
  UIUtil.set_text(self._txt_item_name, name)
  if not_null(self._ui_state_group_quality) then
    self._ui_state_group_quality:SetState(item_cfg and item_cfg.rank or 0)
  end
end

function M:_refresh_exchange_area()
  if not self._selected_item_data then
    return
  end
  local state = self._selected_item_data.exchange_state or EXCHANGE_STATE.LOCKED
  local is_exchanged = state == EXCHANGE_STATE.EXCHANGED
  local can_exchange = state == EXCHANGE_STATE.AVAILABLE or state == EXCHANGE_STATE.LACKED_COIN or state == EXCHANGE_STATE.LOCKED and self:_is_story_requirement_met()
  UIUtil.set_active(self._trans_got, is_exchanged)
  UIUtil.set_active(self._btn_exchange, can_exchange)
  local cost_id = self._selected_item_data.cost_item_id or 0
  local cost_count = self._selected_item_data.cost_item_count or 0
  if 0 < cost_id then
    item_module:set_item_icon(self._img_exchange_icon_coin, cost_id, nil, nil, self:get_load_proxy())
  end
  local owned = 0 < cost_id and back_bag_module:get_coin_or_item_num(cost_id) or 0
  local color = cost_count <= owned and "TextDefault_Light" or "TextWarning_Light"
  UIUtil.set_text(self._txt_exchange_num, TextMapFormatUtil.FormatInteger(cost_count), color)
end

function M:_reselect_or_default(items)
  local target
  local selected_id = self._selected_item_data and self._selected_item_data.item_id or 0
  if 0 < selected_id then
    for _, data in ipairs(items) do
      if data.item_id == selected_id then
        target = data
        break
      end
    end
  end
  if target == nil then
    for _, data in ipairs(items) do
      if (data.exchange_state or EXCHANGE_STATE.LOCKED) ~= EXCHANGE_STATE.EXCHANGED then
        target = data
        break
      end
    end
    target = target or items[1]
  end
  if target then
    self:_on_graduation_item_clicked(target)
  end
end

function M:_refresh_remaining_time()
  local remain = theme_season_module:get_remaining_seconds()
  if remain == self._last_remain_seconds then
    return
  end
  self._last_remain_seconds = remain
  local time_text = theme_season_module:format_season_remaining_time(remain)
  UIUtil.set_text(self._txt_remain_time, time_text)
end

function M:_get_graduation_items()
  return theme_season_module:get_graduation_items()
end

return M
