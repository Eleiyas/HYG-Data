local M = G.Class("PlayerIntimacyStarSelectDialog", G.UIWindow)
local base = G.UIWindow
local COUNTDOWN_SEC = 30

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Social/PlayerIntimacyStarSelectDialog"
  self.config.type = EUIType.Page
  self._item_panels = {}
  self._impression_data = nil
  self._list_inited = false
  self._selected_id = nil
  self._confirm_action = nil
  self._confirmed = false
  self._countdown_timer = nil
end

function M:on_create()
  base.on_create(self)
  self._item_cls = "UI/Social/PlayerIntimacyStarSelectItem"
  self:_add_ui_listener()
end

function M:on_enable()
  base.on_enable(self)
  self._btn_state:SetState(0)
  self._selected_id = nil
  local extra = self:get_extra_data()
  if extra and not is_null(extra) then
    if extra.confirmAction then
      self._confirm_action = extra.confirmAction
    end
    local default_id = extra.defaultId or extra.default_id
    if default_id and 0 < default_id then
      self._selected_id = tonumber(default_id)
    end
    self:set_extra_data(nil)
  end
  self._confirmed = false
  self:_set_all_items_interactable(true)
  self:_start_countdown()
  self:_refresh_impression_list()
end

function M:on_disable()
  base.on_disable(self)
  self._animator:SetTrigger("tipsout")
  self:_clear_countdown()
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  if not_null(self._circular_list) then
    self._circular_list:Close()
  end
  self:_clear_countdown()
  self._item_panels = {}
  self._impression_data = nil
  self._list_inited = false
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.LuaClosePlayerIntimacyStarSelectDialog, function()
    self:close_self()
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:update(deltaTime)
  base.update(self, deltaTime)
  if not self._countdown_timer then
    return
  end
  self._countdown_timer = self._countdown_timer - deltaTime
  self:_refresh_countdown_text()
  if self._countdown_timer <= 0 then
    self:_clear_countdown()
    if not self._selected_id then
      self:_select_fallback_impression()
    end
    if self._selected_id then
      self:_on_btn_confirm_click()
    end
    self:close_self()
  end
end

function M:_add_ui_listener()
  self:bind_callback(self._btn_confirm, pack(self, M._on_btn_confirm_click))
end

function M:_on_btn_confirm_click()
  if self._confirmed then
    return
  end
  if not self._selected_id then
    UIUtil.show_tips_by_text_id("BEST_FRIEND_RITUAL_IMPRESSION_NOT_SELECTED")
    return
  end
  self._btn_state:SetState(1)
  self:_clear_countdown()
  self._confirmed = true
  self:_set_all_items_interactable(false)
  if self._confirm_action then
    self._confirm_action(self._selected_id)
    self._confirm_action = nil
  end
end

function M:_select_fallback_impression()
  local first = self._impression_data and self._impression_data[1]
  if not first then
    return
  end
  self._selected_id = first.id
  self:_sync_all_item_toggles()
  self:_refresh_selection_visuals()
end

function M:_start_countdown()
  self._countdown_timer = COUNTDOWN_SEC
  self:_refresh_countdown_text()
end

function M:_clear_countdown()
  self._countdown_timer = nil
end

function M:_refresh_countdown_text()
  if is_null(self._txt_countdown) or not self._countdown_timer then
    return
  end
  local sec = math.max(0, math.ceil(self._countdown_timer))
  UIUtil.set_text_by_id(self._txt_countdown, "BEST_FRIEND_RITUAL_CONFIRM", tostring(sec))
end

local function _get_impression_list()
  local cfg_table = ExcelDataUtil.get_table(typeof(BImpressionCfg)) or {}
  local list = {}
  for _, cfg in pairs(cfg_table) do
    table.insert(list, cfg)
  end
  table.sort(list, function(a, b)
    return a.id < b.id
  end)
  return list
end

function M:_on_circular_item_update(go, index)
  if is_null(go) or not self._impression_data then
    return
  end
  local data = self._impression_data[index + 1]
  if not data then
    return
  end
  local instance_id = go:GetInstanceID()
  local item = self._item_panels[instance_id]
  if not item then
    item = self:add_panel(self._item_cls, go)
    self._item_panels[instance_id] = item
  end
  item:set_active(true)
  item:set_data(data, function(cfg, is_on)
    self:_on_impression_selected(cfg, is_on)
  end, self:get_load_proxy())
  item:sync_toggle_on(self._selected_id)
  item:refresh_state(self._selected_id)
  item:set_interactable(not self._confirmed)
end

function M:_refresh_selection_visuals()
  self:_refresh_all_item_states()
  self:_refresh_selected_icon()
end

function M:_refresh_all_item_states()
  for _, item in pairs(self._item_panels) do
    if item then
      item:refresh_state(self._selected_id)
    end
  end
end

function M:_sync_all_item_toggles()
  for _, item in pairs(self._item_panels) do
    if item then
      item:sync_toggle_on(self._selected_id)
    end
  end
end

function M:_set_all_items_interactable(interactable)
  for _, item in pairs(self._item_panels) do
    if item then
      item:set_interactable(interactable)
    end
  end
end

function M:_refresh_selected_icon()
  if is_null(self._img_selected) then
    return
  end
  local cfg = self:_find_impression_cfg(self._selected_id)
  if cfg == nil or not string.is_valid(cfg.impressionicon) then
    UIUtil.set_active(self._img_selected, false)
    return
  end
  UIUtil.set_active(self._img_selected, true)
  UIUtil.set_image(self._img_selected, cfg.impressionicon, self:get_load_proxy())
end

function M:_find_impression_cfg(impression_id)
  if impression_id == nil or not self._impression_data then
    return nil
  end
  for _, cfg in ipairs(self._impression_data) do
    if cfg.id == impression_id then
      return cfg
    end
  end
  return nil
end

function M:_refresh_impression_list()
  if is_null(self._circular_list) then
    return
  end
  local impression_list = _get_impression_list()
  self._impression_data = impression_list
  
  local function on_update(go, index)
    self:_on_circular_item_update(go, index)
  end
  
  if not self._list_inited then
    self._circular_list:Init(#impression_list, on_update)
    self._list_inited = true
  else
    self._circular_list:Reload(#impression_list, on_update)
  end
  if 0 < #impression_list then
    self._circular_list:SetCenterIndex(math.floor(#impression_list / 2))
  end
  self:_refresh_selected_icon()
end

function M:_on_impression_selected(cfg, is_on)
  if is_null(cfg) then
    return
  end
  if self._confirmed then
    return
  end
  if is_on then
    if self._selected_id == cfg.id then
      return
    end
    self._selected_id = cfg.id
  else
    if self._selected_id ~= cfg.id then
      return
    end
    self._selected_id = nil
  end
  self:_refresh_selection_visuals()
end

return M
