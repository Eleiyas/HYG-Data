local M = G.Class("BlueprintArchitectAwardPage", G.UIWindow)
local base = G.UIWindow
local level_item_cls = "UI/BlueprintHabitat/BlueprintArchitect/BlueprintArchitectLevelItem"

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/BlueprintHabitat/BlueprintHabitatAwardPage"
  self.config.type = EUIType.Page
  self.config.wait_previous_window_hide_until_show = true
end

function M:on_create()
  base.on_create(self)
  self._level_items = {}
  self:bind_callbacks()
  self:_init_level_list()
end

function M:on_open()
  base.on_open(self)
end

function M:on_enable()
  base.on_enable(self)
  self:_refresh()
  CsCoroutineManagerUtil.InvokeNextFrame(function()
    self:_scroll_to_level(blueprint_habitat_module:get_architect_level())
  end)
end

function M:on_disable()
  local cfgs = blueprint_habitat_module:get_architect_level_cfgs()
  for i, cfg in ipairs(cfgs) do
    local item = self._level_items[i]
    if item == nil then
      break
    end
    item:set_active(false)
  end
  base.on_disable(self)
end

function M:on_close()
  base.on_close(self)
end

function M:on_destroy()
  base.on_destroy(self)
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnArchitectDataChanged, function()
    self:_refresh()
  end)
  self:add_evt_listener(EventID.OnGetArchitectLevelReward, function(reward_list)
    self:_show_reward_dialog(reward_list)
  end)
end

function M:bind_callbacks()
  self:bind_close_btn(self._btn_close)
  self:bind_callback(self._btn_help, function()
    common_ui_module:show_introduction_dialog(common_ui_module.introduction_dialog_type.architect_reward)
  end)
end

function M:_refresh()
  local current_level, next_diff, next_need = blueprint_habitat_module:get_architect_level()
  self:_refresh_level(current_level, next_diff, next_need)
  self:_refresh_level_list(current_level, next_diff, next_need)
end

function M:_refresh_level(current_level, next_diff, next_need)
  local cur_level = next_need - next_diff
  UIUtil.set_text_by_id(self._txt_level, "Habitat_CurrentLevel", current_level)
  UIUtil.set_text(self._txt_exp, tostring(cur_level) .. "/" .. tostring(next_need))
  local cfg = ExcelDataUtil.get_value(typeof(BHabitatLevelCfg), current_level)
  UIUtil.set_text(self._txt_lv_name, cfg.levelname)
  if next_need == 0 then
    self._state_lv_max:SetState(1)
  else
    self._state_lv_max:SetState(0)
  end
end

function M:_init_level_list()
  local cfgs = blueprint_habitat_module:get_architect_level_cfgs()
  for i, cfg in ipairs(cfgs) do
    local obj = self._list_item:AddItem(0)
    local item = self:add_panel(level_item_cls, obj)
    self._level_items[i] = item
    item:set_active(false)
    self:bind_callback(item:get_btn(), function()
      local node_level = item:get_level()
      local cur_level = blueprint_habitat_module:get_architect_level()
      if node_level <= cur_level and not blueprint_habitat_module:has_architect_level_reward_claimed(node_level) then
        blueprint_habitat_module:claim_habitat_architect_level_reward(node_level)
      end
    end)
    item.trans:SetAsFirstSibling()
  end
end

function M:_refresh_level_list(current_level, next_diff, next_need)
  local cfgs = blueprint_habitat_module:get_architect_level_cfgs()
  for i, cfg in ipairs(cfgs) do
    local item = self._level_items[i]
    if item == nil then
      break
    end
    item:refresh(cfg, current_level)
    item:set_active(true)
    if current_level == cfg.level and 0 < next_need then
      item:set_slider(1 - next_diff / next_need)
    else
      item:set_slider(1)
    end
  end
end

function M:_scroll_to_level(level)
  if level == nil or level < 2 or self._scroll_rect == nil or self._trans_view == nil then
    self._scroll_rect.verticalNormalizedPosition = 1
    return
  end
  local item_count = #self._level_items
  if item_count <= 0 then
    return
  end
  local target_bottom = 0
  local content_height = 0
  for i = 1, item_count do
    local item = self._level_items[i]
    if item == nil or item.trans == nil then
      break
    end
    content_height = content_height + self._trans_item_height:GetHeight()
    if i == level - 1 then
      target_bottom = content_height
    end
  end
  if content_height <= 0 then
    self._scroll_rect.verticalNormalizedPosition = 1
    return
  end
  local viewport_height = self._trans_view:GetHeight()
  if content_height <= viewport_height then
    self._scroll_rect.verticalNormalizedPosition = 1
    return
  end
  local scrollable_distance = content_height - viewport_height
  if scrollable_distance <= 0 then
    return
  end
  local target_distance = target_bottom - viewport_height / 2
  if target_distance < 0 then
    target_distance = 0
  elseif scrollable_distance < target_distance then
    target_distance = scrollable_distance
  end
  self._scroll_rect.verticalNormalizedPosition = 1 - target_distance / scrollable_distance
end

function M:_show_reward_dialog(reward_list)
  if is_null(reward_list) then
    return
  end
  local rewards = array_to_table(reward_list)
  local items = {}
  for k, v in ipairs(rewards) do
    table.insert(items, {
      id = v.ItemConfigId,
      num = v.Count
    })
  end
  if 0 < #items then
    common_ui_module:show_reward_dialog(nil, nil, items)
  end
end

return M
