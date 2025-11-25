item_module = item_module or {}

function item_module:init_cfg()
  self._tbl_item_cfg = {}
  self._tbl_tool_cfg = nil
  self._tbl_fur_cfg = nil
  self._tbl_tool_and_perform_item_cfg = nil
  self._tbl_fur_classify_cfg = nil
end

function item_module:get_cfg_by_id(item_id)
  if item_id == nil or item_id < 0 then
    Logger.LogError("无效的item_id")
    return
  end
  if self._tbl_item_cfg[item_id] then
    return self._tbl_item_cfg[item_id]
  end
  local cfg = LocalDataUtil.get_value(typeof(CS.BItemCfg), item_id)
  if cfg == nil then
    Logger.LogError("未能查询到Item !!!!   itemID = " .. item_id)
    return
  end
  self._tbl_item_cfg[item_id] = cfg
  return cfg
end

function item_module:get_entity_cfg_by_id(cfg_id)
  local id_cfg = item_module:get_id_cfg_by_id(cfg_id)
  if id_cfg then
    return id_cfg.entityCfg
  end
end

function item_module:get_tool_cfg_by_id(tool_id)
  if self._tbl_tool_cfg == nil then
    self:_load_tool_cfg()
  end
  return self._tbl_tool_cfg[tool_id]
end

function item_module:_load_tool_cfg()
  self._tbl_tool_cfg = {}
  local tool_cfg = LocalDataUtil.get_table(typeof(CS.BToolCfg))
  for _, v in pairs(tool_cfg) do
    self._tbl_tool_cfg[v.id] = v
  end
end

function item_module:get_id_cfg_by_id(cfg_id)
  if cfg_id == nil or cfg_id <= 0 then
    return nil
  end
  local id_cfg = LocalDataUtil.get_value(typeof(CS.BIdCfg), cfg_id)
  return id_cfg
end

function item_module:get_fur_cfg_by_id(item_id)
  if item_id == nil or item_id <= 0 then
    return nil
  end
  if self._tbl_fur_cfg == nil then
    self._tbl_fur_cfg = {}
  end
  local ret_cfg = self._tbl_fur_cfg[item_id]
  if ret_cfg == nil then
    ret_cfg = LocalDataUtil.get_value(typeof(CS.BFurnitureCfg), item_id)
    if ret_cfg then
      self._tbl_fur_cfg[item_id] = ret_cfg
    end
  end
  return ret_cfg
end

function item_module:get_fur_classify_cfg_by_item_id(item_id)
  if item_id == nil or item_id <= 0 then
    return nil
  end
  local fur_cfg = item_module:get_fur_cfg_by_id(item_id)
  if fur_cfg == nil or 0 >= fur_cfg.classification then
    return nil
  end
  local ret_cfg = item_module:get_fur_classify_cfg_by_id(fur_cfg.classification)
  return ret_cfg
end

function item_module:get_fur_classify_cfg_by_id(id)
  if id == nil or id <= 0 then
    return nil
  end
  if self._tbl_fur_classify_cfg == nil then
    self._tbl_fur_classify_cfg = {}
  end
  local ret_cfg = self._tbl_fur_classify_cfg[id]
  if ret_cfg == nil then
    ret_cfg = LocalDataUtil.get_value(typeof(CS.BFurClassifyCfg), id)
    if ret_cfg then
      self._tbl_fur_classify_cfg[id] = ret_cfg
    end
  end
  return ret_cfg
end

function item_module:get_fur_classify_cfgs_by_sec_classify(sec_classify)
  local ret_tbl = {}
  if sec_classify == nil or sec_classify <= 0 then
    return ret_tbl
  end
  if self._fur_classify_cfg_ids == nil then
    self._fur_classify_cfg_ids = {}
    local cfgs = dic_to_table(LocalDataUtil.get_table(typeof(CS.BFurClassifyCfg)))
    for _, cfg in pairs(cfgs) do
      if self._fur_classify_cfg_ids[cfg.secclassify] == nil then
        self._fur_classify_cfg_ids[cfg.secclassify] = {}
      end
      table.insert(self._fur_classify_cfg_ids[cfg.secclassify], tonumber(_))
    end
  end
  return self._fur_classify_cfg_ids[sec_classify] or {}
end

function item_module:get_tool_and_perform_item_cfg_by_id(cfg_id)
  if cfg_id == nil then
    return nil
  end
  if self._tbl_tool_and_perform_item_cfg == nil then
    self._tbl_tool_and_perform_item_cfg = dic_to_table(LocalDataUtil.get_table(typeof(CS.BToolAndPerformItemCfg))) or {}
  end
  return self._tbl_tool_and_perform_item_cfg[cfg_id]
end

return item_module
