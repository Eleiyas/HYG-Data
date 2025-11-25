local LuaTimeUtil = {}
LuaTimeUtil._cname = "LuaTimeUtil"
LuaTimeUtil.SecondOfOneDay = 86400
LuaTimeUtil.SecondOfOneHour = 3600
LuaTimeUtil.SecondOfOneMin = 60

local function get_days_between_time_stamp(pre_time_stamp, last_time_stamp)
  local pre_time_date = os.date("*t", pre_time_stamp)
  local last_time_date = os.date("*t", last_time_stamp)
  local pre_time = os.time({
    year = last_time_date.year,
    month = last_time_date.month,
    day = last_time_date.day
  })
  local last_time = os.time({
    year = pre_time_date.year,
    month = pre_time_date.month,
    day = pre_time_date.day
  })
  local ret_day = math.abs(last_time - pre_time) / LuaTimeUtil.SecondOfOneDay
  return ret_day
end

local function get_cur_year()
  local date_table = os.date("*t", TimeUtil.NowTimeStampUTC)
  return date_table.year
end

local function get_cur_month()
  local date_table = os.date("*t", TimeUtil.ServerUtcTimeSeconds)
  return date_table.month
end

local function get_cur_day()
  local date_table = os.date("*t", TimeUtil.ServerUtcTimeSeconds)
  return date_table.day
end

local function get_date_time_from_timestamp(timestamp)
  local date_table = os.date("*t", timestamp)
  return date_table.year, date_table.month, date_table.day, date_table.hour, date_table.min, date_table.sec
end

local function split_time(time)
  local day = math.floor(time / LuaTimeUtil.SecondOfOneDay)
  local hour = math.floor(time % LuaTimeUtil.SecondOfOneDay / LuaTimeUtil.SecondOfOneHour)
  local min = math.floor(time % LuaTimeUtil.SecondOfOneHour / LuaTimeUtil.SecondOfOneMin)
  local sec = time % LuaTimeUtil.SecondOfOneMin
  return day, hour, min, sec
end

local function get_time_str(time)
  local time_str = ""
  local day, hour, min, sec = LuaTimeUtil.split_time(time)
  if 0 < day then
    time_str = time_str .. string.format(UIUtil.get_text_by_id("Cook_CountDown1"), day)
  end
  if 0 < hour then
    time_str = time_str .. string.format(UIUtil.get_text_by_id("Cook_CountDown2"), hour)
  end
  if 0 < day then
    return time_str
  end
  if 0 < min then
    time_str = time_str .. string.format(UIUtil.get_text_by_id("Cook_CountDown3"), min)
  end
  if 0 < hour then
    return time_str
  end
  if 0 < sec then
    time_str = time_str .. string.format(UIUtil.get_text_by_id("Cook_CountDown4"), sec)
  end
  return time_str
end

LuaTimeUtil.get_days_between_time_stamp = get_days_between_time_stamp
LuaTimeUtil.get_cur_year = get_cur_year
LuaTimeUtil.get_cur_month = get_cur_month
LuaTimeUtil.get_cur_day = get_cur_day
LuaTimeUtil.split_time = split_time
LuaTimeUtil.get_time_str = get_time_str
LuaTimeUtil.get_date_time_from_timestamp = get_date_time_from_timestamp
return LuaTimeUtil
