local M = G.Class("ComplexCodexInfoPanelBase", G.UIPanel)
local base = G.UIPanel
local state = {unlocked = 0, locked = 1}

function M:init()
  base.init(self)
end

function M:on_create()
  base.on_create(self)
  self.items = {}
  self.all_items = {}
  self._components = {}
  self._item_objs = {
    [codex_module.detail_item_type.normal_info] = self._obj_tag_normal
  }
  self._unlock_level = nil
  self:add_layout_config()
  self:_add_btn_listener()
  self:_init_quality_star_objs()
end

function M:add_layout_config()
  self._layout_config = {}
end

function M:_init_quality_star_objs()
  self._quality_star_objs = {}
  local children_count = self._trans_star_parent.childCount
  for i = 0, children_count - 1 do
    local child_obj = self._trans_star_parent:GetChild(i)
    table.insert(self._quality_star_objs, child_obj.transform)
  end
end

function M:on_enable()
  base.on_enable(self)
end

function M:on_disable()
  base.on_disable(self)
end

function M:register_events()
  base.register_events(self)
end

function M:unregister_events()
  base.unregister_events(self)
end

function M:bind_input_action()
  base.bind_input_action(self)
end

function M:_add_btn_listener()
end

function M:refresh(item_data, sequence)
  self.item_data = item_data
  self.sequence = sequence
  self._is_unlocked = self.item_data.IsUnlocked
  local sub_type_ctrl = codex_module:get_sub_type_controller(item_data.Type, item_data.SubType)
  self._unlock_level = sub_type_ctrl:get_sub_type_level()
  if self._is_unlocked then
    self._ui_state_group:SetState(state.unlocked)
    self:_set_collection_time()
    self:_set_quality()
    self:_set_unlock_sequence()
    self:_set_name()
    self:recycle_all()
    self:check_components()
    self:refresh_components()
  else
    self._ui_state_group:SetState(state.locked)
    self:_set_lock_sequence()
  end
end

function M:_set_lock_sequence()
  local sequence = self.sequence
  if sequence == nil then
    return
  end
  local seq_str = string.format("%03d", sequence)
  UIUtil.set_text(self._txt_lock_num, seq_str)
end

function M:_set_collection_time()
  local timestamp = self.item_data.ServerData.UnlockTime
  if codex_module:is_package_sub_type(self.item_data.SubType) then
    timestamp = self.item_data.ServerData.Suite.CompleteTime
  end
  if timestamp == 0 then
    UIUtil.set_active(self._trans_collection_date, false)
    return
  end
  local time = os.date("*t", timestamp)
  local time_str = string.format("%4d.%02d.%02d", time.year, time.month, time.day)
  UIUtil.set_text(self._txt_collection_date, time_str)
  UIUtil.set_active(self._trans_collection_date, true)
end

function M:_set_quality()
  self._rank_ui_state_group:SetState(self.item_data.ItemCfg.rank)
  local max_stars = self.item_data.ServerData.Creature.MaxStars
  for i = 1, #self._quality_star_objs do
    UIUtil.set_active(self._quality_star_objs[i], i <= max_stars)
  end
  UIUtil.set_active(self._trans_star_parent, true)
end

function M:_set_unlock_sequence()
  local sequence = self.sequence
  if sequence == nil then
    return
  end
  local seq_str = string.format("%03d", sequence)
  UIUtil.set_text(self._txt_num, seq_str)
end

function M:_set_name()
  UIUtil.set_text(self._txt_item_name, self.item_data.IdCfg.name)
end

function M:check_components()
  for i = 1, #self._layout_config do
    local component = self._components[i]
    if component == nil then
      self:_create_one_component(i)
    end
    component = self._components[i]
    if component then
      component:check_parent_and_sort(self._trans_content_root)
    end
  end
end

function M:refresh_components()
  for i = 1, #self._components do
    local cls = self._components[i]
    local data_extractor = self._layout_config[i].data_extractor
    if data_extractor ~= nil then
      local is_success, data = data_extractor(self, self.item_data)
      if is_success then
        cls:refresh(data)
        if cls.show then
          cls:show()
        else
          UIUtil.set_active(cls.trans, true)
        end
      elseif cls.hide then
        cls:hide()
      else
        UIUtil.set_active(cls.trans, false)
      end
    end
  end
end

function M:_create_one_component(index)
  local config = self._layout_config[index]
  local type = config.type
  local item = self:get_item(type)
  if item == nil then
    return
  end
  self._components[index] = item
end

function M:get_item(type)
  if self.items[type] == nil then
    self.items[type] = {}
  end
  local item
  if #self.items[type] > 0 then
    item = self.items[type][1]
    table.remove(self.items[type], 1)
  end
  if item == nil then
    local obj = UIUtil.load_prefab_set_parent(self._item_objs[type], self._trans_content_root)
    item = self:add_panel(codex_module.detail_item_cls[type], obj)
    if item then
      item:set_type(type)
      table.insert(self.all_items, item)
    else
      Logger.Log("图鉴item 初始化失败 type:" .. tostring(type))
    end
  end
  return item
end

function M:recycle_all()
  for _, item in ipairs(self.all_items) do
    if item then
      if not self.items[item.type] then
        self.items[item.type] = {}
      end
      table.insert(self.items[item.type], item)
    end
  end
end

return M
