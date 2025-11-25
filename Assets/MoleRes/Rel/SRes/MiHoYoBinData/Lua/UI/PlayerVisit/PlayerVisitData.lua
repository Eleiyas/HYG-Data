player_visit_module = player_visit_module or {}

function player_visit_module:get_player_visit_permission_info()
  local permission_type_cfg_tbl = list_to_table(LocalDataUtil.get_dic_table(typeof(CS.BPermissionTypeCfg))[1] or {})
  local ask_option_cfg_tbl = list_to_table(LocalDataUtil.get_dic_table(typeof(CS.BOptionsCfg))[1] or {})
  local chat_cfg_tbl = list_to_table(LocalDataUtil.get_dic_table(typeof(CS.BChatCfg))[1] or {})
  self.permission_info = {
    [1] = permission_type_cfg_tbl or {},
    [2] = ask_option_cfg_tbl or {},
    [3] = chat_cfg_tbl or {}
  }
end

function player_visit_module:_sort_visit_records_by_timestamp(record_infos)
  if not record_infos or table.count(record_infos) == 0 then
    return {}
  end
  
  local function compare_timestamp(a, b)
    if not a or not b then
      return false
    end
    local a_list = list_to_table(a or {})
    local b_list = list_to_table(b or {})
    if not (table.count(a_list) ~= 0 and table.count(b_list) ~= 0 and a_list[1]) or not b_list[1] then
      return false
    end
    return (a_list[1].VisitTimestamp or 0) > (b_list[1].VisitTimestamp or 0)
  end
  
  for i = 1, table.count(record_infos) - 1 do
    for j = 1, table.count(record_infos) - i do
      if not compare_timestamp(record_infos[j], record_infos[j + 1]) then
        record_infos[j], record_infos[j + 1] = record_infos[j + 1], record_infos[j]
      end
    end
  end
  return record_infos
end

function player_visit_module:get_player_visit_record_info()
  local record_infos = CsPlayerVisitModuleUtil.GetSocialWorldVisitRecordInfoDic() or {}
  self.record_infos = dic_to_table(record_infos) or {}
  self.record_infos = self:_sort_visit_records_by_timestamp(self.record_infos)
  return self.record_infos
end

function player_visit_module:get_player_visit_list()
  local record_infos = CsPlayerVisitModuleUtil.GetSocialWorldVisitRecordInfo() or {}
  self.record_list = list_to_table(record_infos) or {}
  return self.record_list
end

function player_visit_module:get_player_visit_record_detail_info(record_info)
  if is_null(record_info) then
    return {}
  end
  local result = {}
  for _, record in ipairs(list_to_table(record_info or {})) do
    if record then
      local visit_time = record.VisitTimestamp or 0
      local time_desc = self:get_x_day_ago_time_desc(visit_time)
      table.insert(result, time_desc)
      for _, item in ipairs(list_to_table(record.BuyItemList or {})) do
        if item and item.ItemId then
          local item_cfg = LocalDataUtil.get_value(typeof(CS.BIdCfg), item.ItemId)
          if item_cfg then
            table.insert(result, UIUtil.get_text_by_id("Visit_log_5", item_cfg.name or "", item.ItemNum or 0))
          end
        end
      end
      for _, item in ipairs(list_to_table(record.SellItemList or {})) do
        if item and item.ItemId then
          local item_cfg = LocalDataUtil.get_value(typeof(CS.BIdCfg), item.ItemId)
          if item_cfg then
            table.insert(result, UIUtil.get_text_by_id("Visit_log_8", item_cfg.name or "", item.ItemNum or 0))
          end
        end
      end
      for _, item in ipairs(list_to_table(record.ItemsTakeWayList or {})) do
        if item and item.ItemId then
          local item_cfg = LocalDataUtil.get_value(typeof(CS.BIdCfg), item.ItemId)
          if item_cfg then
            table.insert(result, UIUtil.get_text_by_id("Visit_log_12", item_cfg.name or "", item.ItemNum or 0))
          end
        end
      end
      for _, npc_id in ipairs(list_to_table(record.DialogNpcIdList or {})) do
        if npc_id then
          local npc_cfg = LocalDataUtil.get_value(typeof(CS.BNpcCfg), npc_id)
          if npc_cfg then
            table.insert(result, UIUtil.get_text_by_id("Visit_log_14", npc_cfg.name or ""))
          end
        end
      end
      local leave_time = record.LeaveTimestamp or 0
      if visit_time < leave_time then
        table.insert(result, UIUtil.get_text_by_id("Visit_log_15"))
      end
    end
  end
  return result
end

function player_visit_module:get_x_day_ago_time_desc(timestamp)
  if not timestamp then
    return ""
  end
  local now = TimeUtil.ServerUtcTimeSeconds or 0
  local today_start = now - now % 86400
  local time_desc = ""
  if timestamp >= today_start then
    time_desc = UIUtil.get_text_by_id("Visit_log_2")
  else
    local days_diff = math.floor((today_start - timestamp) / 86400) + 1
    time_desc = UIUtil.get_text_by_id("Visit_log_1", days_diff)
  end
  return time_desc
end

function player_visit_module:get_permission_map_ask_type(option_id)
  if not option_id then
    return {}
  end
  
  local function split_string(input, delimiter)
    if not input then
      return {}
    end
    local result = {}
    if delimiter == nil or delimiter == "" then
      return {input}
    end
    for match in (input .. delimiter):gmatch("(.-)" .. delimiter) do
      table.insert(result, match)
    end
    return result
  end
  
  local res = {}
  if not (self.permission_info and self.permission_info[1]) or not self.permission_info[1][option_id + 1] then
    return res
  end
  local ask_types = self.permission_info[1][option_id + 1].options
  if not string.is_valid(ask_types) then
    return res
  end
  local type_ids = split_string(ask_types, ",")
  for _, type_id in ipairs(type_ids) do
    if self.permission_info[2] and self.permission_info[2][tonumber(type_id) + 1] then
      res[tonumber(type_id)] = self.permission_info[2][tonumber(type_id) + 1].permissiondes or ""
    end
  end
  return res
end

return player_visit_module
