spring_festival_activity_module = spring_festival_activity_module or {}
local CALENDAR_YEAR = 2027
local CALENDAR_TIME_TYPE = {
  normal = 0,
  new_year_eve = 1,
  spring_festival = 2,
  lantern = 3
}
spring_festival_activity_module.calendar_time_type = CALENDAR_TIME_TYPE
spring_festival_activity_module.calendar_now_state = {normal = 0, today = 1}
spring_festival_activity_module.calendar_dialog_class_path = "UI/ActivityCenter/SubPanel/SpringFestival/Dialog/SpringFestivalCalendarDialog"
spring_festival_activity_module.calendar_day_item_class_path = "UI/ActivityCenter/SubPanel/SpringFestival/Dialog/SpringFestivalCalendarDayItem"
local CALENDAR_SEGMENTS = {
  {
    month = 1,
    from_day = 25,
    to_day = 31
  },
  {
    month = 2,
    from_day = 1,
    to_day = 21
  }
}
local FESTIVAL_RANGES = {
  {
    month = 2,
    from_day = 2,
    to_day = 5,
    time_type = CALENDAR_TIME_TYPE.new_year_eve
  },
  {
    month = 2,
    from_day = 6,
    to_day = 14,
    time_type = CALENDAR_TIME_TYPE.spring_festival
  },
  {
    month = 2,
    from_day = 18,
    to_day = 21,
    time_type = CALENDAR_TIME_TYPE.lantern
  }
}
local LUNAR_TEXT_IDS = {
  [2] = {
    [5] = "SpringFestival_ActivityCalendar_01",
    [6] = "SpringFestival_ActivityCalendar_02",
    [7] = "SpringFestival_ActivityCalendar_03",
    [8] = "SpringFestival_ActivityCalendar_04",
    [9] = "SpringFestival_ActivityCalendar_05",
    [10] = "SpringFestival_ActivityCalendar_06",
    [11] = "SpringFestival_ActivityCalendar_07",
    [12] = "SpringFestival_ActivityCalendar_08",
    [20] = "SpringFestival_ActivityCalendar_09"
  }
}
local day_list_cache

local function resolve_time_type(month, day)
  for _, range in ipairs(FESTIVAL_RANGES) do
    if range.month == month and day >= range.from_day and day <= range.to_day then
      return range.time_type
    end
  end
  return CALENDAR_TIME_TYPE.normal
end

local function build_day_list()
  local list = {}
  for _, segment in ipairs(CALENDAR_SEGMENTS) do
    local lunar_ids_of_month = LUNAR_TEXT_IDS[segment.month]
    for day = segment.from_day, segment.to_day do
      table.insert(list, {
        month = segment.month,
        day = day,
        time_type = resolve_time_type(segment.month, day),
        lunar_text_id = lunar_ids_of_month ~= nil and lunar_ids_of_month[day] or nil
      })
    end
  end
  return list
end

function spring_festival_activity_module:get_calendar_day_list()
  if day_list_cache == nil then
    day_list_cache = build_day_list()
  end
  return day_list_cache
end

function spring_festival_activity_module:get_calendar_today_index()
  local cross_day_seconds = LogicTime.CrossDayTimeSpan.TotalSeconds
  local local_seconds = LogicTime.LocalTimeSeconds
  local logic_date = os.date("!*t", local_seconds - cross_day_seconds)
  local today_index = 0
  if logic_date.year == CALENDAR_YEAR then
    local list = self:get_calendar_day_list()
    for i = 1, #list do
      local data = list[i]
      if data.month == logic_date.month and data.day == logic_date.day then
        today_index = i
        break
      end
    end
  end
  local local_clock = os.date("!*t", local_seconds)
  Logger.Log(string.format("[SpringFestivalCalendar] local_time = %d-%02d-%02d %02d:%02d:%02d," .. " logic_day = %d-%02d-%02d, cross_day_offset_hour = %.1f," .. " calendar_year = %d, today_index = %d", local_clock.year, local_clock.month, local_clock.day, local_clock.hour, local_clock.min, local_clock.sec, logic_date.year, logic_date.month, logic_date.day, cross_day_seconds / 3600, CALENDAR_YEAR, today_index))
  return today_index
end

return spring_festival_activity_module
