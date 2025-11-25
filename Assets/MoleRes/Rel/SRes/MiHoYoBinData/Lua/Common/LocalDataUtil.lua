local LocalDataUtil = {}
local local_data_list = {}

local function init()
  if local_data_list ~= nil then
    local_data_list = {}
  end
end

local function get_table(cfg_type)
  if cfg_type == nil then
    Logger.LogError("配置表类型为空")
    return {}
  end
  if local_data_list[cfg_type] == nil then
    local cfg_table = {}
    local dic = CsUIUtil.GetTable(cfg_type)
    if dic then
      for k, v in pairs(dic) do
        cfg_table[k] = v
      end
      local_data_list[cfg_type] = cfg_table
    end
  end
  return local_data_list[cfg_type]
end

local function get_dic_table(cfg_type)
  if cfg_type == nil then
    Logger.LogError("配置表类型为空")
    return {}
  end
  if local_data_list[cfg_type] == nil then
    local dic = CsUIUtil.GetTableDic(cfg_type)
    local_data_list[cfg_type] = dic_to_table(dic)
  end
  return local_data_list[cfg_type]
end

local function get_value(cfg_type, id)
  local cfg_table = get_table(cfg_type)
  return cfg_table[id]
end

LocalDataUtil.get_table = get_table
LocalDataUtil.get_dic_table = get_dic_table
LocalDataUtil.get_value = get_value
LocalDataUtil.init = init
return LocalDataUtil
