activity_center_module = activity_center_module or {}
local tracker_id_cache = {}
local tracker_goal_cache = {}

function activity_center_module:get_logic_cfg_row(activity_id)
  if activity_id == nil or activity_id <= 0 then
    return nil
  end
  local cfg = self:get_logic_cfg(activity_id)
  if cfg ~= nil then
    return cfg
  end
  return ExcelDataUtil.get_value(typeof(BActivityCfg), activity_id)
end

local function get_tracker_ids(activity_id)
  if activity_id == nil or activity_id <= 0 then
    return nil
  end
  local cached = tracker_id_cache[activity_id]
  if cached ~= nil then
    return cached
  end
  local cfg = activity_center_module:get_logic_cfg_row(activity_id)
  if cfg == nil then
    return nil
  end
  local ids = {
    open = cfg.opentrackerid or 0,
    close = cfg.closetrackerid or 0,
    unlock = cfg.unlocktrackerid or 0,
    finish = cfg.finishtrackerid or 0
  }
  tracker_id_cache[activity_id] = ids
  return ids
end

function activity_center_module:get_open_tracker_id(activity_id)
  local ids = get_tracker_ids(activity_id)
  return ids ~= nil and ids.open or 0
end

function activity_center_module:get_close_tracker_id(activity_id)
  local ids = get_tracker_ids(activity_id)
  return ids ~= nil and ids.close or 0
end

function activity_center_module:get_unlock_tracker_id(activity_id)
  local ids = get_tracker_ids(activity_id)
  return ids ~= nil and ids.unlock or 0
end

function activity_center_module:get_finish_tracker_id(activity_id)
  local ids = get_tracker_ids(activity_id)
  return ids ~= nil and ids.finish or 0
end

function activity_center_module:get_tracker_goal(tracker_id)
  if tracker_id == nil or tracker_id == 0 then
    return 0
  end
  local cached = tracker_goal_cache[tracker_id]
  if cached ~= nil then
    return cached
  end
  local tracker_cfg = CsTrackerModuleUtil.GetTrackerCfgById(tracker_id)
  if tracker_cfg == nil then
    return 0
  end
  local goal_list = list_to_table(tracker_cfg.goalprogresslist)
  local goal = goal_list ~= nil and goal_list[1] or 0
  if goal == nil or goal <= 0 then
    Logger.LogWarning("[ActivityCenter] tracker " .. tostring(tracker_id) .. " 的 goalprogresslist 为空或首档为 0，门控将永不满足。")
    return 0
  end
  tracker_goal_cache[tracker_id] = goal
  return goal
end

local EMPTY_LIST = {}

local function parse_id_list(raw)
  if raw == nil or not string.is_valid(raw) then
    return EMPTY_LIST
  end
  local list = {}
  for piece in string.gmatch(raw, "([^,%s]+)") do
    local value = tonumber(piece)
    if value ~= nil then
      table.insert(list, math.floor(value))
    end
  end
  return list
end

local NO_SUB_PAGE_IMAGE_ID = 0
local page_rows_cache = {}
local page_timing_activity_ids_by_order_cache = {}
local TIMING_CACHE_KEY_STRIDE = 1000

local function get_page_rows(page_id)
  if page_id == nil or page_id <= 0 then
    return EMPTY_LIST
  end
  local cached = page_rows_cache[page_id]
  if cached ~= nil then
    return cached
  end
  local raw_list = ExcelDataUtil.get_value(typeof(BActivityPageCfg), page_id)
  if raw_list == nil then
    return EMPTY_LIST
  end
  local raw_rows = list_to_table(raw_list)
  if raw_rows == nil or #raw_rows == 0 then
    return EMPTY_LIST
  end
  local rows = {}
  for index = 1, #raw_rows do
    rows[index] = raw_rows[index]
  end
  table.sort(rows, function(left, right)
    return (left.imageid or NO_SUB_PAGE_IMAGE_ID) < (right.imageid or NO_SUB_PAGE_IMAGE_ID)
  end)
  page_rows_cache[page_id] = rows
  return rows
end

local function get_page_row_by_order(page_id, order_index)
  local rows = get_page_rows(page_id)
  if order_index == nil or order_index < 1 or order_index > #rows then
    return nil
  end
  return rows[order_index]
end

local function get_page_head_row(page_id)
  return get_page_row_by_order(page_id, 1)
end

function activity_center_module:get_page_image_ids(page_id)
  local rows = get_page_rows(page_id)
  if #rows == 0 then
    return EMPTY_LIST
  end
  local ids = {}
  for index = 1, #rows do
    table.insert(ids, rows[index].imageid or NO_SUB_PAGE_IMAGE_ID)
  end
  return ids
end

function activity_center_module:get_page_row_count(page_id)
  return #get_page_rows(page_id)
end

function activity_center_module:get_page_sub_page_count(page_id)
  return self:get_page_row_count(page_id)
end

function activity_center_module:get_page_image_id_by_order(page_id, order_index)
  local row = get_page_row_by_order(page_id, order_index)
  if row == nil then
    return nil
  end
  return row.imageid or NO_SUB_PAGE_IMAGE_ID
end

function activity_center_module:get_page_title_id_by_order(page_id, order_index)
  local row = get_page_row_by_order(page_id, order_index)
  if row == nil or not string.is_valid(row.titleid) then
    return nil
  end
  return row.titleid
end

function activity_center_module:get_page_image_path_by_order(page_id, order_index)
  local row = get_page_row_by_order(page_id, order_index)
  if row == nil or not string.is_valid(row.imagepath) then
    return nil
  end
  return row.imagepath
end

function activity_center_module:get_page_background_path_by_order(page_id, order_index)
  local row = get_page_row_by_order(page_id, order_index)
  if row == nil or not string.is_valid(row.backgroundpath) then
    return nil
  end
  return row.backgroundpath
end

function activity_center_module:get_page_desc_id_by_order(page_id, order_index)
  local row = get_page_row_by_order(page_id, order_index)
  if row == nil or not string.is_valid(row.descid) then
    return nil
  end
  return row.descid
end

function activity_center_module:get_page_title_desc_task_id_by_order(page_id, order_index)
  local row = get_page_row_by_order(page_id, order_index)
  return row ~= nil and row.titleanddesctaskid or 0
end

function activity_center_module:get_page_timing_activity_ids_by_order(page_id, order_index)
  if page_id == nil or order_index == nil then
    return EMPTY_LIST
  end
  local cache_key = page_id * TIMING_CACHE_KEY_STRIDE + order_index
  local cached = page_timing_activity_ids_by_order_cache[cache_key]
  if cached ~= nil then
    return cached
  end
  local row = get_page_row_by_order(page_id, order_index)
  if row == nil then
    return EMPTY_LIST
  end
  local ids = parse_id_list(row.timingactivityid)
  page_timing_activity_ids_by_order_cache[cache_key] = ids
  return ids
end

function activity_center_module:get_page_tool_ids_by_order(page_id, order_index)
  local row = get_page_row_by_order(page_id, order_index)
  if row == nil then
    return EMPTY_LIST
  end
  return parse_id_list(row.toolid)
end

function activity_center_module:get_page_tool_task_ids_by_order(page_id, order_index)
  local row = get_page_row_by_order(page_id, order_index)
  if row == nil then
    return EMPTY_LIST
  end
  return parse_id_list(row.tooltaskid)
end

function activity_center_module:get_page_row(page_id, image_id)
  local rows = get_page_rows(page_id)
  if #rows == 1 then
    return rows[1]
  end
  image_id = image_id or NO_SUB_PAGE_IMAGE_ID
  for index = 1, #rows do
    if (rows[index].imageid or NO_SUB_PAGE_IMAGE_ID) == image_id then
      return rows[index]
    end
  end
  return nil
end

function activity_center_module:get_page_unlock_activity_ids(page_id)
  local row = get_page_head_row(page_id)
  if row == nil then
    return EMPTY_LIST
  end
  return parse_id_list(row.timingactivityid)
end

function activity_center_module:get_page_time_remain_activity_ids(page_id, image_id)
  local row = self:get_page_row(page_id, image_id)
  if row == nil then
    return EMPTY_LIST
  end
  return parse_id_list(row.timingactivityid)
end

function activity_center_module:get_page_background_path(page_id)
  local row = get_page_head_row(page_id)
  if row == nil or not string.is_valid(row.backgroundpath) then
    return nil
  end
  return row.backgroundpath
end

function activity_center_module:get_page_guide_window_id(page_id)
  local row_count = self:get_page_row_count(page_id)
  for order_index = 1, row_count do
    local row = get_page_row_by_order(page_id, order_index)
    local guide_window_id = row ~= nil and row.guidewindowid or 0
    if 0 < guide_window_id then
      return guide_window_id
    end
  end
  return 0
end

function activity_center_module:get_sub_page_guide_window_id(page_id, image_id)
  local row = self:get_page_row(page_id, image_id)
  return row ~= nil and row.guidewindowid or 0
end

function activity_center_module:get_sub_page_tool_ids(page_id, image_id)
  local row = self:get_page_row(page_id, image_id)
  if row == nil then
    return EMPTY_LIST
  end
  return parse_id_list(row.toolid)
end

function activity_center_module:get_sub_page_image_path(page_id, image_id)
  local row = self:get_page_row(page_id, image_id)
  if row == nil or not string.is_valid(row.imagepath) then
    return nil
  end
  return row.imagepath
end

function activity_center_module:get_sub_page_title_id(page_id, image_id)
  local row = self:get_page_row(page_id, image_id)
  if row == nil or not string.is_valid(row.titleid) then
    return nil
  end
  return row.titleid
end

function activity_center_module:get_sub_page_desc_id(page_id, image_id)
  local row = self:get_page_row(page_id, image_id)
  if row == nil or not string.is_valid(row.descid) then
    return nil
  end
  return row.descid
end

function activity_center_module:get_sub_page_title_desc_task_id(page_id, image_id)
  local row = self:get_page_row(page_id, image_id)
  return row ~= nil and row.titleanddesctaskid or 0
end

function activity_center_module:get_sub_page_tool_task_ids(page_id, image_id)
  local row = self:get_page_row(page_id, image_id)
  if row == nil then
    return EMPTY_LIST
  end
  return parse_id_list(row.tooltaskid)
end

function activity_center_module:has_sub_page_reward(page_id, image_id)
  return #self:get_sub_page_tool_ids(page_id, image_id) > 0 or 0 < #self:get_sub_page_tool_task_ids(page_id, image_id)
end

local tracking_memo_ids_cache = {}
local tracking_ids_by_activity_id_index

local function get_tracking_ids_by_activity_id_index()
  if tracking_ids_by_activity_id_index ~= nil then
    return tracking_ids_by_activity_id_index
  end
  local index = {}
  local raw_table = ExcelDataUtil.get_table(typeof(BActivityTrackingCfg))
  if raw_table == nil then
    return index
  end
  for tracking_id, row in pairs(raw_table) do
    local activity_id = row ~= nil and row.activityid or 0
    if 0 < activity_id then
      local ids = index[activity_id]
      if ids == nil then
        ids = {}
        index[activity_id] = ids
      end
      local insert_at = #ids + 1
      while 1 < insert_at and tracking_id < ids[insert_at - 1] do
        ids[insert_at] = ids[insert_at - 1]
        insert_at = insert_at - 1
      end
      ids[insert_at] = tracking_id
    end
  end
  tracking_ids_by_activity_id_index = index
  return index
end

function activity_center_module:get_tracking_ids_by_activity_id(activity_id)
  if activity_id == nil or activity_id <= 0 then
    return EMPTY_LIST
  end
  return get_tracking_ids_by_activity_id_index()[activity_id] or EMPTY_LIST
end

local function get_tracking_row(tracking_id)
  if tracking_id == nil or tracking_id <= 0 then
    return nil
  end
  return ExcelDataUtil.get_value(typeof(BActivityTrackingCfg), tracking_id)
end

function activity_center_module:get_tracking_activity_id(tracking_id)
  local row = get_tracking_row(tracking_id)
  return row ~= nil and row.activityid or 0
end

function activity_center_module:get_tracking_memo_ids(tracking_id)
  if tracking_id == nil or tracking_id <= 0 then
    return EMPTY_LIST
  end
  local cached = tracking_memo_ids_cache[tracking_id]
  if cached ~= nil then
    return cached
  end
  local row = get_tracking_row(tracking_id)
  if row == nil then
    return EMPTY_LIST
  end
  local ids = parse_id_list(row.memoid)
  if #ids == 0 then
    return EMPTY_LIST
  end
  tracking_memo_ids_cache[tracking_id] = ids
  return ids
end

function activity_center_module:get_tracking_json_id(tracking_id)
  local row = get_tracking_row(tracking_id)
  return row ~= nil and row.jsonid or 0
end

function activity_center_module:get_tracking_tips_id(tracking_id)
  local row = get_tracking_row(tracking_id)
  return row ~= nil and row.trackingtips or ""
end

return activity_center_module
