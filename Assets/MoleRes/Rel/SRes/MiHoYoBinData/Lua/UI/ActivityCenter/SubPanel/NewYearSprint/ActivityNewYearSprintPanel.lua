local M = G.Class("ActivityNewYearSprintPanel", "UI/ActivityCenter/SubPanel/ActivityBasePanel")
local base = G.ActivityBasePanel

function M:init()
  base.init(self)
  self._entry_cards = {}
end

function M:on_create()
  base.on_create(self)
  if is_null(self._btn_hotselling) then
    return
  end
  self:bind_callback(self._btn_hotselling, pack(self, M._on_btn_hotselling_click))
end

function M:on_enable()
  base.on_enable(self)
  new_year_sprint_activity_module:refresh_red_dot()
  self:refresh()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.OnActivityListChanged, function()
    self:refresh()
  end)
  self:add_evt_listener(EventID.TrackerUpdateNotify, pack(self, M._on_tracker_update_notify))
  self:add_lua_listener(lua_event_module.event_type.refresh_activity_center_red_point, pack(self, M._refresh_red_dot_views))
end

function M:update_time_remain()
  base.update_time_remain(self)
  if not self:is_in_show_state() then
    return
  end
  new_year_sprint_activity_module:refresh_red_dot()
  self:_refresh_entry_cards_time()
end

function M:refresh()
  base.refresh(self)
  self:_refresh_entry_cards()
  self:_refresh_hot_selling_red_dot()
end

function M:_on_activity_data_changed(activity_id)
  self:refresh()
end

function M:_on_tracker_update_notify(tracker_id)
  local module = new_year_sprint_activity_module
  if not module:is_memory_shelf_tracker(tracker_id) then
    return
  end
  if tonumber(tracker_id) == module.memory_shelf_special.start_tracker_id then
    module:refresh_memory_shelf_unlock_state()
  end
  local activity_id = module.memory_shelf_special.activity_id
  local cards = self._entry_cards
  for index = 1, #cards do
    local card = cards[index]
    if card ~= nil and card:get_activity_id() == activity_id then
      card:refresh_tracker_state()
      return
    end
  end
end

function M:_refresh_hot_selling_red_dot()
  if is_null(self._redpoint) then
    return
  end
  self._redpoint:ShowRedPoint(new_year_sprint_activity_module:get_hot_selling_red_dot_type())
end

function M:_refresh_red_dot_views()
  self:_refresh_hot_selling_red_dot()
  local cards = self._entry_cards
  for index = 1, #cards do
    local card = cards[index]
    if card ~= nil then
      card:refresh_red_dot()
    end
  end
end

function M:_on_btn_hotselling_click()
  new_year_sprint_activity_module:open_hot_selling()
end

function M:_refresh_entry_cards()
  if is_null(self._layout_list) then
    Logger.LogWarning("[NewYearSprint] _layout_list is missing on prefab.")
    return
  end
  local entries = new_year_sprint_activity_module:get_card_entries()
  for index = 1, #entries do
    local cls = self._entry_cards[index]
    if cls == nil then
      local obj = self._layout_list:AddItem(0)
      if not_null(obj) then
        cls = self:add_panel(new_year_sprint_activity_module.entry_card_class_path, obj)
        self._entry_cards[index] = cls
      end
    end
    if cls ~= nil then
      cls:refresh(entries[index])
    end
  end
end

function M:_refresh_entry_cards_time()
  local cards = self._entry_cards
  for index = 1, #cards do
    local card = cards[index]
    if card ~= nil then
      card:refresh_time()
    end
  end
end

return M
