local M = G.Class("RabbitTabletopSettlementDialog", G.UIWindow)
local base = G.UIWindow
local coin_item_view_cls = common_ui_module.common_coin_item_view_cls
local item_v2_cls = item_module.item_v2_panel_cls_name
local AUTO_EXIT_SECONDS = 10

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/RabbitTabletop/RabbitTabletopSettlementDialog"
  self.config.type = EUIType.Dialog
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self._reward_item_entries = {}
  self._reward_item_list_binder = nil
  self._item_pool = {
    pool = {},
    active = {}
  }
  self._item_cls = "UI/RabbitTabletop/RabbitTabletopSettlementItem"
  self._coin_view = self:add_panel(coin_item_view_cls, self._obj_coin_item, {
    coin_id = back_bag_module.coin_type.galactic_bazaar,
    auto_update = false
  })
end

function M:on_enable()
  base.on_enable(self)
  local cfg = ExcelDataUtil.get_value(typeof(BUnoConstantCfg), 1)
  self._countdown = cfg and cfg.overwindowtime or AUTO_EXIT_SECONDS
  self:_refresh_ui()
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_before_close()
  base.on_before_close(self)
  local item_info_dlg = UIManagerInstance:is_show("UI/Item/ItemInfoDialog")
  if item_info_dlg then
    item_info_dlg:close_self()
  end
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if self._countdown then
    self._countdown = self._countdown - deltaTime
    if self._countdown <= 0 then
      self._countdown = nil
      self:_on_ready_for_next_game()
      return
    end
    local sec = math.ceil(self._countdown)
    if sec ~= self._last_sec then
      self._last_sec = sec
      UIUtil.set_text_by_id(self._txt_countdown, "Tabletop_Tutupai_End_ChangeState", tostring(sec))
    end
  end
end

function M:register_events()
  base.register_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Esc, self._btn_close)
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_bg, pack(self, M._on_btn_bg_click))
  self:bind_callback(self._btn_close, pack(self, M._on_btn_close_click))
end

function M:_on_btn_bg_click()
  self:_on_ready_for_next_game()
end

function M:_on_btn_close_click()
  local popup = UIUtil.get_confirm_popup()
  popup:set_texts(UIUtil.get_text_by_id("Tabletop_Tutupai_Ready_Warn2"), UIUtil.get_text_by_id("Tabletop_Tutupai_Gameplay_Confirm"), UIUtil.get_text_by_id("Tabletop_Tutupai_Gameplay_Cancel"))
  popup:set_callbacks(function()
    self._confirm_popup_guid = nil
    self:close_self()
    if self._ready_callback then
      self._ready_callback(false)
      self._ready_callback = nil
    end
  end, function()
    self._confirm_popup_guid = nil
  end)
  self._confirm_popup_guid = popup:show()
end

function M:_on_ready_for_next_game()
  if self._confirm_popup_guid then
    UIManagerInstance:close(self._confirm_popup_guid)
    self._confirm_popup_guid = nil
  end
  self:close_self()
  if self._ready_callback then
    self._ready_callback(true)
    self._ready_callback = nil
  end
end

function M:_refresh_ui()
  local extra = self:get_extra_data() or {}
  self._ready_callback = extra.ready_callback or nil
  local is_win = extra.is_winner or false
  self._state_result:SetState(is_win and 0 or 1)
  if self._state_type then
    self._state_type:SetState(extra.is_in_metro_scene and 0 or 1)
  end
  UIUtil.set_text_by_id(self._txt_title, is_win and "Tabletop_Tutupai_End_Win" or "Tabletop_Tutupai_End_Fail")
  local today = CsSceneActivityModuleUtil.BazzarTodayCoinGet()
  local coin_limit = 0
  local stage_cfg = ExcelDataUtil.get_value(typeof(BRhythmShowStageCfg), 2)
  if stage_cfg then
    coin_limit = stage_cfg.value
  end
  local left_coin = math.max(coin_limit - today, 0)
  UIUtil.set_text_by_id(self._txt_today_num, "Tabletop_Tutupai_End_JellyRemain", tostring(left_coin))
  UIUtil.set_text_by_id(self._txt_countdown, "Tabletop_Tutupai_End_ChangeState", tostring(math.ceil(self._countdown)))
  local play_count = extra.play_card_count or 0
  local draw_count = extra.draw_card_count or 0
  local reward_count = extra.reward_count or 0
  local reward_items = extra.reward_items or nil
  local card_icon_path = "UISprite/Load/RabbitTabletop/Icon_RabbitTabletop_Settlement_01"
  local result_list = {
    {
      title = UIUtil.get_text_by_id("Tabletop_Tutupai_End_CardNum"),
      num = tostring(play_count),
      is_limit = false,
      icon = card_icon_path
    },
    {
      title = UIUtil.get_text_by_id("Tabletop_Tutupai_End_GetCard"),
      num = tostring(draw_count),
      is_limit = false,
      icon = card_icon_path
    }
  }
  self:_refresh_result_list(result_list)
  self:_refresh_reward_resultend(reward_count, reward_items, extra.is_in_metro_scene)
  if self._coin_view then
    self._coin_view:refresh()
  end
  Logger.Log(string.format("[RabbitTabletopSettlementDialog] coin_limit: %d, today: %d, left_coin: %d, play_count: %d, draw_count: %d, reward_count: %d", coin_limit, today, left_coin, play_count, draw_count, reward_count))
end

function M:_refresh_result_list(result_list)
  rabbit_tabletop_module:generate_and_refresh_items(self, self._item_pool, result_list, self._trans_item, self._trans_parent, self._item_cls, function(item, data)
    item:refresh(data)
  end, self._item_resultend.transform)
end

function M:_refresh_reward_resultend(reward_count, reward_items, is_in_metro_scene)
  UIUtil.set_active(self._item_resultend, is_in_metro_scene == true)
  if not is_in_metro_scene then
    return
  end
  local final_rewards = {}
  if reward_items ~= nil and 0 < #reward_items then
    final_rewards = reward_items
  elseif 0 < reward_count then
    final_rewards = {
      {
        cfg_id = back_bag_module.coin_type.galactic_bazaar,
        num = reward_count
      }
    }
  end
  local binder = self:_get_reward_item_list_binder()
  if binder == nil then
    return
  end
  for i, reward_item in ipairs(final_rewards) do
    local entry = self._reward_item_entries[i]
    if entry == nil then
      local obj = binder:AddItem(0)
      if not_null(obj) then
        local panel = self:add_panel(item_v2_cls, obj)
        entry = {obj = obj, panel = panel}
        self._reward_item_entries[i] = entry
      end
    end
    if entry and not_null(entry.obj) and entry.panel ~= nil then
      UIUtil.set_active(entry.obj, true)
      entry.panel:set_item_data(reward_item.cfg_id, reward_item.num, nil)
      entry.panel:bind_item_info_btn(reward_item.cfg_id)
    end
  end
  for i = #final_rewards + 1, #self._reward_item_entries do
    local entry = self._reward_item_entries[i]
    if entry and not_null(entry.obj) then
      UIUtil.set_active(entry.obj, false)
    end
  end
end

function M:_get_reward_item_list_binder()
  if self._reward_item_list_binder ~= nil then
    return self._reward_item_list_binder
  end
  if self._layout_itemlist and self._layout_itemlist.AddItem ~= nil then
    self._reward_item_list_binder = self._layout_itemlist
    return self._reward_item_list_binder
  end
  return nil
end

return M
