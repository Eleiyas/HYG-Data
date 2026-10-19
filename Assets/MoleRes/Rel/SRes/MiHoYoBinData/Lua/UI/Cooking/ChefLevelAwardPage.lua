local M = G.Class("ChefLevelAwardPage", G.UIWindow)
local base = G.UIWindow
local level_item_cls = "UI/Cooking/ChefLevelAwardItem"
local level_state = {normal = 0, max = 1}

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/Cooking/ChefLevelAwardPage"
  self.config.type = EUIType.Dialog
  self._level_items = {}
  self._level_cfgs = nil
  self._scroll_rect = nil
  self._viewport = nil
  self._on_scroll_changed = nil
  self._last_red_dot_scroll_y = nil
  self._item_height = 0
  self._item_spacing = 0
  self._list_padding_top = 0
  self._reverse_arrangement = false
end

function M:on_create()
  base.on_create(self)
  self:_add_ui_listener()
  self:_init_scroll()
  self:_init_level_list()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh(true)
end

function M:on_disable()
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  self:_unbind_scroll()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnChefLevelDataNotify, function()
    self:_refresh(false)
  end)
end

function M:bind_input_action()
  base.bind_input_action(self)
  self:bind_input_and_btn(ActionType.Act.Back, self._btn_back)
end

function M:_add_ui_listener()
  self:bind_close_btn(self._btn_back)
  self:bind_callback(self._btn_help_dark, pack(self, M._on_btn_help_dark_click))
end

function M:_on_btn_help_dark_click()
  tutorial_module:open_tutorial_handbook_page_with_tutorial_id(3, 1, 1)
end

function M:_init_scroll()
  if is_null(self._scroll_rect) then
    return
  end
  if self._on_scroll_changed == nil then
    function self._on_scroll_changed()
      self:_try_refresh_red_dot_by_scroll()
    end
    
    self._scroll_rect.onValueChanged:AddListener(self._on_scroll_changed)
  end
end

function M:_unbind_scroll()
  if not_null(self._scroll_rect) and self._on_scroll_changed ~= nil then
    self._scroll_rect.onValueChanged:RemoveListener(self._on_scroll_changed)
  end
  self._on_scroll_changed = nil
  self._last_red_dot_scroll_y = nil
end

function M:_refresh(scroll_to_top)
  local level = CsCookModuleUtil.GetChefLevel() or 0
  local total_exp = CsCookModuleUtil.GetChefLevelExp() or 0
  local cfg = ExcelDataUtil.get_value(typeof(BChefLevelCfg), level)
  local exp = cooking_module:get_chef_level_display_exp(level, total_exp)
  local need_exp = cooking_module:get_chef_level_segment_required_exp(level)
  UIUtil.set_text(self._txt_cur_lv, tostring(level))
  if not is_null(cfg) then
    UIUtil.set_text(self._txt_lv_title, cfg.cheftitle or "")
    if string.is_valid(cfg.cheftitleicon) then
      UIUtil.set_image(self._img_icon, cfg.cheftitleicon, self:get_load_proxy())
    end
  end
  local is_max_level = need_exp <= 0
  if is_max_level then
    UIUtil.set_text(self._txt_exp, tostring(exp))
  else
    UIUtil.set_text(self._txt_exp, string.format("%s/%s", exp, need_exp))
  end
  self._ui_state_group_level:SetState(is_max_level and level_state.max or level_state.normal)
  self:_refresh_level_list(level, exp, need_exp)
  if scroll_to_top then
    self:_scroll_to_top()
  end
  self:_refresh_red_dot()
end

function M:_scroll_to_top()
  if is_null(self._scroll_rect) then
    return
  end
  self._scroll_rect.verticalNormalizedPosition = 1
  self._last_red_dot_scroll_y = self:_get_content_scroll_y()
end

function M:_get_content_scroll_y()
  if is_null(self._scroll_rect) or is_null(self._scroll_rect.content) then
    return 0
  end
  return self._scroll_rect.content.anchoredPosition.y
end

function M:_try_refresh_red_dot_by_scroll()
  local y = self:_get_content_scroll_y()
  if self._last_red_dot_scroll_y == nil then
    self._last_red_dot_scroll_y = y
    self:_refresh_red_dot()
    return
  end
  self:_cache_list_layout_metrics()
  local threshold = self._item_height * 0.5
  if threshold <= 0 then
    threshold = 1
  end
  if threshold > math.abs(y - self._last_red_dot_scroll_y) then
    return
  end
  self._last_red_dot_scroll_y = y
  self:_refresh_red_dot()
end

function M:_cache_list_layout_metrics()
  if not_null(self._layout) then
    self._item_spacing = self._layout.spacing or 0
    self._list_padding_top = self._layout.padding.top or 0
    self._reverse_arrangement = self._layout.reverseArrangement == true
  end
  local item = self._level_items[1]
  if item ~= nil then
    self._item_height = item:get_preferred_height()
  end
end

function M:_get_level_cfgs()
  if self._level_cfgs ~= nil then
    return self._level_cfgs
  end
  local cfg_table = ExcelDataUtil.get_table(typeof(BChefLevelCfg)) or {}
  local cfgs = {}
  for _, cfg in pairs(cfg_table) do
    if not is_null(cfg) then
      table.insert(cfgs, cfg)
    end
  end
  table.sort(cfgs, function(a, b)
    return (a.cheflevel or 0) > (b.cheflevel or 0)
  end)
  self._level_cfgs = cfgs
  return cfgs
end

function M:_init_level_list()
  local cfgs = self:_get_level_cfgs()
  for i, cfg in ipairs(cfgs) do
    local obj = self._list_item_binder:AddItem(0)
    local item = self:add_panel(level_item_cls, obj)
    self._level_items[i] = item
  end
end

function M:_refresh_level_list(current_level, exp, need_exp)
  local cfgs = self:_get_level_cfgs()
  local total = #cfgs
  local progress = 0
  if 0 < need_exp then
    progress = exp / need_exp
    if progress < 0 then
      progress = 0
    elseif 1 < progress then
      progress = 1
    end
  end
  for i, cfg in ipairs(cfgs) do
    local item = self._level_items[i]
    if item == nil then
      break
    end
    item:refresh(cfg, current_level, total)
    item:set_active(true)
    if (cfg.cheflevel or 0) == current_level then
      item:set_slider(progress)
    else
      item:set_slider(1)
    end
  end
end

function M:_refresh_red_dot()
  if is_null(self._rect_red_dot) then
    return
  end
  local show = false
  for _, item in ipairs(self._level_items) do
    if cooking_module:can_claim_chef_level_reward(item:get_level()) and self:_is_item_below_viewport(item) then
      show = true
      break
    end
  end
  UIUtil.set_active(self._rect_red_dot, show)
end

function M:_is_item_below_viewport(item)
  if is_null(item) or is_null(self._viewport) then
    return false
  end
  local item_rt = item.rect_trans or item.trans
  if is_null(item_rt) then
    return false
  end
  local item_corners = CsUIUtil.GetWorldCorners(item_rt)
  local view_corners = CsUIUtil.GetWorldCorners(self._viewport)
  if is_null(item_corners) or is_null(view_corners) then
    return false
  end
  local item_top = item_corners[1].y
  local view_bottom = view_corners[0].y
  return item_top < view_bottom
end

return M
