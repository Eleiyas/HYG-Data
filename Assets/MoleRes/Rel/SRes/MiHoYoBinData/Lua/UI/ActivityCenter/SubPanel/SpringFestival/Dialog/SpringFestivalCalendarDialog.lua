local M = G.Class("SpringFestivalCalendarDialog", G.UIWindow)
local base = G.UIWindow

function M:init()
  base.init(self)
  self.config.prefab_path = "UI/MainActivity_y1/SpringFestival/SpringFestival_CalendarDialog"
  self.config.type = EUIType.Dialog
  self._day_items = {}
end

function M:on_create()
  base.on_create(self)
  self:bind_close_btn(self._btn_back)
  self:bind_close_btn(self._btn_bgback, true)
end

function M:on_enable()
  base.on_enable(self)
  self:refresh()
end

function M:register_events()
  base.register_events(self)
  self:add_evt_listener(EventID.onDailyRefresh, pack(self, M._on_daily_refresh))
end

function M:_on_daily_refresh()
  self:refresh()
end

function M:refresh()
  self:_refresh_days()
end

function M:_refresh_days()
  if is_null(self._layout_days) then
    Logger.LogWarning("[SpringFestivalCalendarDialog] _layout_days is missing on prefab.")
    return
  end
  local day_list = spring_festival_activity_module:get_calendar_day_list()
  local today_index = spring_festival_activity_module:get_calendar_today_index()
  for i = 1, #day_list do
    local item = self._day_items[i]
    if item == nil then
      local obj = self._layout_days:AddItem(0)
      if not_null(obj) then
        item = self:add_panel(spring_festival_activity_module.calendar_day_item_class_path, obj)
        self._day_items[i] = item
      end
    end
    if item ~= nil then
      item:refresh(day_list[i], i == today_index)
    end
  end
end

return M
